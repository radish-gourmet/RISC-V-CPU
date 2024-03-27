module ff_cache_control
import types::*;
(
    input clk,
    input rst,
    input   logic       cache_hit,
    input   logic       dirty_val,
    input   logic       mem_read,
    input   logic       mem_write,
    input   logic       pmem_resp,
    output  logic       mem_resp,
    output  logic       pmem_read, 
    output  logic       pmem_write,
    output  logic       cache_en,
    output  logic       tag_en,
    output  logic       dirty_en,
    output  logic       valid_en,
    output  logic       cache_write,
    output  logic       invalidate
);

enum int unsigned {
    /* List of states */
    idle,
    compare,
    allocate,
    write_back
} state, next_state;

function void set_defaults();
    cache_en    = 1'b0;
    tag_en      = 1'b0;
    dirty_en    = 1'b0;
    valid_en    = 1'b0;
    cache_write = 1'b0;
    pmem_write  = 1'b0;
    mem_resp    = 1'b0;
    invalidate  = 1'b0;
    pmem_read   = 1'b0;
endfunction

//Current state functions
always_comb begin
    set_defaults();
    unique case (state)
        idle : ;
        compare: begin
            if(cache_hit) begin
                if(mem_write) begin
                    cache_en        = 1'b1;
                    tag_en          = 1'b1;
                    dirty_en        = 1'b1;
                    valid_en        = 1'b1;
                    cache_write     = 1'b1;
                    mem_resp = 1'b1;
                end
                else if(mem_read)
                    mem_resp = 1'b1;
                else
                    mem_resp = 1'b0;
            end
        end

        allocate : begin
            cache_en        = 1'b1;
            tag_en          = 1'b1;
            dirty_en        = 1'b1;
            valid_en        = 1'b1;
            pmem_read       = 1'b1;
        end

        write_back : begin
            invalidate = 1'b1;
            pmem_write = 1'b1;
        end
    endcase
end

//Next state transition
always_comb begin
    if(rst) next_state = compare;
    else begin
        unique case(state)
            idle    : next_state = compare;
            compare : begin
                if(mem_read || mem_write) begin
                    if(cache_hit)                   next_state = compare;
                    else if (dirty_val)             next_state = write_back;
                    else if (mem_read | mem_write)  next_state = allocate;
                    else                            next_state = compare;
                end
                else
                    next_state = compare;
            end

            allocate : begin
                if(pmem_resp) next_state = compare;
                else          next_state = allocate;
            end

            write_back : begin
                if(pmem_resp) next_state = allocate;
                else          next_state = write_back;
            end
            default : next_state = compare;
        endcase
    end
end

always_ff @(posedge clk) begin
    if(rst) state <= compare;
    else begin
        state <= next_state;
    end
end

endmodule : ff_cache_control