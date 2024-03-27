module arbiter
import types::*;
(

    // I/O Here

    input clk,
    input rst,

    // I-Cache Section

    input logic [255:0] iline_i,
    input logic [31:0] iaddress,
    input logic iread_i,
    input logic iwrite_i,

    output logic [255:0] iline_o,
    output logic iresp_o,

    // D-Cache Section

    input logic [255:0] dline_i,
    input logic [31:0] daddress_i,
    input logic dread_i,
    input logic dwrite_i,

    output logic [255:0] dline_o,
    output logic dresp_o,
    
/*
    // Physical Memory Section
    input logic [63:0] burst_i,
    input logic resp_i,

    output logic [63:0] burst_o,
    output logic [31:0] address_o,
    output logic read_o,
    output logic write_o*/

    // Cache-line adaptor
    output  logic [255:0]   line_i,
    input   logic [255:0]   line_o,
    output  logic [31:0]    address_i,
    output  logic           read_i,
    output  logic           write_i,
    input   logic           resp_o
);

    typedef enum bit [1:0]{
        dreq = 2'b00,
        ireq = 2'b01,
        free = 2'b10
    } arbiter_state;

    arbiter_state arb_state;

    always_comb begin
        if(rst) begin
            read_i      = '0;
            write_i     = '0;
            address_i   = '0;
            line_i      = '0;
            dline_o     = '0;
            dresp_o     = '0;
            iline_o     = '0;
            iresp_o     = '0;
        end
        else begin
            //Forward to DBus
            if (arb_state == dreq) begin
                read_i      = dread_i;
                write_i     = dwrite_i;
                address_i   = {daddress_i[31:5], 5'b0};
                line_i      = dline_i;
                dline_o     = line_o;
                dresp_o     = resp_o;
                iresp_o     = '0;
                iline_o     = '0;          
            end
            //Forward to IBus
            else if (arb_state == ireq) begin
                read_i      = iread_i;
                write_i     = iwrite_i;
                address_i   = {iaddress[31:5], 5'b0};
                line_i      = iline_i;
                iline_o     = line_o;
                iresp_o     = resp_o;
                dresp_o     = '0;
                dline_o     = '0;
            end
            else begin
                read_i      = '0;
                write_i     = '0;
                address_i   = '0;
                line_i      = '0;
                iline_o     = '0;
                iresp_o     = '0;
                dline_o     = '0;
                dresp_o     = '0; 
            end
        end
    end

    always_ff @(posedge clk) begin
        if(rst) arb_state <= free;
        else begin
            //Acquire
            if((arb_state == free) && (dread_i || dwrite_i))
                arb_state <= dreq;
            else if ((arb_state == free) && (iread_i))
                arb_state <= ireq;

            //Release
            if(resp_o)
                arb_state <= free;
        end
    end

endmodule : arbiter