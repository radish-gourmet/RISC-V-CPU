module calc
import types::*;
(
    input   logic   clk,
    input   logic   rst,
    input   logic   [31:0]  mem_address,
    input   logic           mem_read,
    input   logic           mem_write,
    input   logic   [31:0]  mem_byte_enable,
    input   logic   [31:0]  mem_wdata,
    input   logic           data_web,
    input   logic           tag_web,
    input   logic           valid_web,
    input   logic   [255:0] pmem_rdata,
    input   logic           stall,
    output  caac_fwd        caac_o,
    output  logic   [255:0] data_o,
    output  logic   [23:0]  tag_o,
    output  logic           valid_o
);

    logic   [23:0]  tag_d;
    logic   [3:0]   set_d;
    logic           data_web, tag_web, valid_web;
    logic           cache_hit;
    caac_fwd        prev_caac;
    logic           stall;

    assign set_d    = stall ? prev_caac.set : caac_o.set;
    assign tag_d    = stall ? prev_caac.tag : caac_o.tag;

    generate
        mp3_data_array data_array (
            .clk0       (~clk),
            .csb0       (1'b0),
            .web0       (~data_web),
            .wmask0     ('1),           //TODO : works for i-cache only
            .addr0      (set_d),
            .din0       (pmem_rdata),
            .dout0      (data_o)
        );

        mp3_tag_array tag_array (
            .clk0       (~clk),
            .csb0       (1'b0),
            .web0       (~tag_web),
            .addr0      (set_d),
            .din0       (tag_d),
            .dout0      (tag_o)
        );

        ff_array #(.s_index(1), .width(1)) valid_array(
            .clk0   (clk),
            .rst0   (rst),
            .csb0   (1'b0),
            .web0   (~valid_web),
            .addr0  (set_d),
            .din0   (1'b1),
            .dout0  (valid_o)
        );
    endgenerate

    always_comb  begin
        if(rst) begin
            caac_o.mem_address      = '0;
            caac_o.mem_read         = '0;
            caac_o.mem_write        = '0;
            caac_o.mem_byte_enable  = '0;
            caac_o.mem_wdata        = '0;
            caac_o.set              = '0;
            caac_o.tag              = '0;
        end
        else begin
            caac_o.mem_address      = mem_address;
            caac_o.mem_read         = mem_read;
            caac_o.mem_write        = mem_write;
            caac_o.mem_byte_enable  = mem_byte_enable;
            caac_o.mem_wdata        = mem_wdata;
            caac_o.set              = mem_address[8:5];
            caac_o.tag              = mem_address[31:9];
        end
    end    

    always_ff @(posedge clk) begin
        if(rst) begin
            prev_caac <= '0;
        end
        else begin
            if(~stall) begin
                prev_caac   <= caac_o;
            end
        end
    end

endmodule