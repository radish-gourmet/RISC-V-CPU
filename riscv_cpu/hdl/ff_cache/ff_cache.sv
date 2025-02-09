module ff_cache
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

    /* Memory side signals */
    output  logic   [31:0]  pmem_address,
    output  logic           pmem_read,
    output  logic           pmem_write,
    input   logic   [255:0] pmem_rdata,
    output  logic   [255:0] pmem_wdata,
    input   logic           pmem_resp
);

logic   cache_write;
logic   cache_en;
logic   tag_en;
logic   dirty_en;
logic   valid_en;
logic   dirty_val;
logic   cache_hit;
logic   invalidate;

ff_cache_control control
(
    .*
);

ff_cache_datapath datapath
(
    .*
);

endmodule : ff_cache