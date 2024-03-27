module ff_cache_datapath
import types::*;
(
    input clk,
    input rst,
    input   logic               mem_write,
    input   logic               mem_read,
    input   logic   [31:0]      mem_address,
    input   logic   [255:0]     mem_wdata,
    input   logic   [31:0]      mem_byte_enable,
    input   logic   [255:0]     pmem_rdata,
    input   logic               cache_write,
    input   logic               cache_en,
    input   logic               tag_en,
    input   logic               dirty_en,
    input   logic               valid_en,
    input   logic               pmem_resp,
    input   logic               invalidate,
    output  logic   [255:0]     mem_rdata,
    output  logic   [31:0]      pmem_address,
    output  logic   [255:0]     pmem_wdata,
    output  logic               dirty_val,
    output  logic               cache_hit
);

    logic   [4:0]   offset_val;
    logic   [2:0]   set_val;
    logic   [31:8]  tag_val;

    logic   [255:0] cache   [16:0];
    logic   [24:0]  tag     [16:0];
    logic           valid   [16:0];
    logic           dirty   [16:0];

    assign offset_val   = mem_address[4:0];
    assign set_val      = mem_address[7:5];
    assign tag_val      = mem_address[31:8];
    //assign pmem_address        = invalidate ? {tag[set_val], set_val, 5'b00000} : mem_address;

    //Read
    always_comb begin
        cache_hit = 1'b0;
        dirty_val = 1'b0;
        mem_rdata   = '0;
        if((tag[set_val] == tag_val) && (valid[set_val])) begin
                mem_rdata   = cache[set_val];
                cache_hit   = 1'b1;
        end
        dirty_val           = dirty[set_val];
        pmem_address        = invalidate ? {tag[set_val], set_val, 5'b00000} : mem_address;
        pmem_wdata          = cache[set_val];
    end

    //Cache Write
    always_ff @(posedge clk) begin
        if(rst) begin
            for(int i = 0; i < 16; i++) begin
                cache[i] <= '0;
                tag[i]   <= '0;
                dirty[i] <= '0;
                valid[i] <= '0;
            end
        end
        
        //Writes from CPU to cache
        if(cache_write) begin
            if(cache_en) begin
                if (mem_byte_enable[0])
                        cache[set_val] [7:0] <= mem_wdata[7:0];
                if (mem_byte_enable[1])
                        cache[set_val] [15:8] <= mem_wdata[15:8];
                if (mem_byte_enable[2])
                        cache[set_val] [23:16] <= mem_wdata[23:16];
                if (mem_byte_enable[3])
                        cache[set_val] [31:24] <= mem_wdata[31:24];
                if (mem_byte_enable[4])
                        cache[set_val] [39:32] <= mem_wdata[39:32];
                if (mem_byte_enable[5])
                        cache[set_val] [47:40] <= mem_wdata[47:40];
                if (mem_byte_enable[6])
                        cache[set_val] [55:48] <= mem_wdata[55:48];
                if (mem_byte_enable[7])
                        cache[set_val] [63:56] <= mem_wdata[63:56];
                if (mem_byte_enable[8])
                        cache[set_val] [71:64] <= mem_wdata[71:64];
                if (mem_byte_enable[9])
                        cache[set_val] [79:72] <= mem_wdata[79:72];
                if (mem_byte_enable[10])
                        cache[set_val] [87:80] <= mem_wdata[87:80];
                if (mem_byte_enable[11])
                        cache[set_val] [95:88] <= mem_wdata[95:88];
                if (mem_byte_enable[12])
                        cache[set_val] [103:96] <= mem_wdata[103:96];
                if (mem_byte_enable[13])
                        cache[set_val] [111:104] <= mem_wdata[111:104];
                if (mem_byte_enable[14])
                        cache[set_val] [119:112] <= mem_wdata[119:112];
                if (mem_byte_enable[15])
                        cache[set_val] [127:120] <= mem_wdata[127:120];
                if (mem_byte_enable[16])
                        cache[set_val] [135:128] <= mem_wdata[135:128];
                if (mem_byte_enable[17])
                        cache[set_val] [143:136] <= mem_wdata[143:136];
                if (mem_byte_enable[18])
                        cache[set_val] [151:144] <= mem_wdata[151:144];
                if (mem_byte_enable[19])
                        cache[set_val] [159:152] <= mem_wdata[159:152];
                if (mem_byte_enable[20])
                        cache[set_val] [167:160] <= mem_wdata[167:160];
                if (mem_byte_enable[21])
                        cache[set_val] [175:168] <= mem_wdata[175:168];
                if (mem_byte_enable[22])
                        cache[set_val] [183:176] <= mem_wdata[183:176];
                if (mem_byte_enable[23])
                        cache[set_val] [191:184] <= mem_wdata[191:184];
                if (mem_byte_enable[24])
                        cache[set_val] [199:192] <= mem_wdata[199:192];
                if (mem_byte_enable[25])
                        cache[set_val] [207:200] <= mem_wdata[207:200];
                if (mem_byte_enable[26])
                        cache[set_val] [215:208] <= mem_wdata[215:208];
                if (mem_byte_enable[27])
                        cache[set_val] [223:216] <= mem_wdata[223:216];
                if (mem_byte_enable[28])
                        cache[set_val] [231:224] <= mem_wdata[231:224];
                if (mem_byte_enable[29])
                        cache[set_val] [239:232] <= mem_wdata[239:232];
                if (mem_byte_enable[30])
                        cache[set_val] [247:240] <= mem_wdata[247:240];
                if (mem_byte_enable[31])
                        cache[set_val] [255:248] <= mem_wdata[255:248];
            end
            if(tag_en)      tag[set_val]    <= tag_val;
            if(dirty_en)    dirty[set_val]  <= 1'b1;
            if(valid_en)    valid[set_val]  <= 1'b1;
        end
        //Cache fill from memory
        else if (pmem_resp) begin
            if(cache_en)    cache[set_val]  <= pmem_rdata;
            if(tag_en)      tag[set_val]    <= pmem_address[31:8];
            if(dirty_en)    dirty[set_val]  <= 1'b0;
            if(valid_en)    valid[set_val]  <= 1'b1;
        end
    end

endmodule : ff_cache_datapath