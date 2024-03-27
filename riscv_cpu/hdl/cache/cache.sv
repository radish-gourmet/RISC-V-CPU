module cache
import types::*;
(
    input clk,
    input rst,
    
    /* CPU side signals */
    input   logic   [31:0]  mem_address,
    input   logic           mem_read,
    input   logic           mem_write,
    input   logic   [31:0]  mem_byte_enable,
    output  logic   [255:0] mem_rdata,
    input   logic   [255:0] mem_wdata,
    output  logic           mem_resp,
    output  logic   [31:0]  addr_in,

    /* Memory side signals */
    output  logic   [31:0]  pmem_address,
    output  logic           pmem_read,
    output  logic           pmem_write,
    input   logic   [255:0] pmem_rdata,
    output  logic   [255:0] pmem_wdata,
    input   logic           pmem_resp
);

    caac_fwd caac, caac_next;
    logic   [23:0]      tag_o;
    logic   [255:0]     data_o;
    logic               valid_o;
    logic               data_web, tag_web, valid_web;



    calc    CALC(
        .clk            (clk            ),
        .rst            (rst            ),
        .mem_address    (mem_address    ),
        .mem_read       (mem_read       ),
        .mem_write      (mem_write      ),
        .mem_byte_enable(mem_byte_enable),
        .mem_wdata      (mem_wdata      ), 
        .data_web       (data_web       ),
        .tag_web        (tag_web        ),
        .valid_web      (valid_web      ),
        .pmem_rdata     (pmem_rdata     ),
        .caac_o         (caac_next      ),
        .data_o         (data_o         ),
        .tag_o          (tag_o          ),
        .valid_o        (valid_o        ),
        .stall          (stall          )
    );

    access  ACCESS(
        .clk            (clk            ),
        .rst            (rst            ),
        .caac_i         (caac           ),
        .data_o         (data_o         ),
        .tag_o          (tag_o          ),
        .valid_o        (valid_o        ),
        .mem_read       (mem_read       ),
        .mem_resp       (mem_resp       ),
        .mem_rdata      (mem_rdata      ),
        .pmem_resp      (pmem_resp      ),
        .pmem_read      (pmem_read      ),
        .pmem_write     (pmem_write     ),
        .pmem_wdata     (pmem_wdata     ),
        .pmem_address   (pmem_address   ),
        .stall          (stall          ),
        .data_web       (data_web       ),
        .tag_web        (tag_web        ),
        .valid_web      (valid_web      ),
        .addr_in        (addr_in        )
    );

    always_ff @(posedge clk) begin
        if(rst) begin
            caac    <= '0;
        end
        else begin
            //if(~stall)
            //if(~(pmem_read && ~pmem_resp))
                caac    <= caac_next;
        end
    end

endmodule