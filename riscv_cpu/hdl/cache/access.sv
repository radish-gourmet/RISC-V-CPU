module access
import types::*;
(
    input               clk,
    input               rst,
    input   caac_fwd    caac_i,
    input  logic   [255:0] data_o,
    input  logic   [23:0]  tag_o,
    input  logic           valid_o,

    /*CPU side signals*/
    input   logic           mem_read,
    output  logic           mem_resp,
    output  logic   [255:0] mem_rdata,
    output  logic   [31:0]  addr_in,

    /* Memory side signals */
    input   logic           pmem_resp,  
    output  logic   [31:0]  pmem_address,
    output  logic           pmem_read,
    output  logic           pmem_write,
    output  logic   [255:0] pmem_wdata,

    output  logic           stall,
    output  logic           data_web,
    output  logic           tag_web,
    output  logic           valid_web
);

    logic   stall;
    logic   cache_hit;
    assign  addr_in = caac_i.mem_address;

    function void set_defaults();
        cache_hit       = '0;
        mem_rdata       = '0;
        mem_resp        = '0;
        pmem_address    = '0;
        pmem_read       = '0;
        pmem_write      = '0;
        pmem_wdata      = '0;
        stall           = '0;
        data_web        = '0;
        tag_web         = '0;
        valid_web       = '0;
    endfunction

    always_comb begin
        set_defaults();

        if(rst) begin
            cache_hit = 1'b0;
        end
        else begin
            //Tag computation
            if(caac_i.mem_read && (tag_o == caac_i.tag) && valid_o) begin
                cache_hit   = 1'b1;
                mem_rdata   = data_o;
                mem_resp    = 1'b1;
            end
            else if (caac_i.mem_read) begin
                //Hold signals until there is response
                pmem_address        = caac_i.mem_address;
                pmem_read           = 1'b1;

                //Disabling writes for now
                pmem_write          = 1'b0;
                pmem_wdata          = '0;
                if(pmem_resp) begin
                    data_web            = 1'b1;
                    tag_web             = 1'b1;
                    valid_web           = 1'b1;
                    stall               = 1'b0;
                end
                else 
                    stall               = 1'b1;
            end
        end
    end


endmodule