module fetch
import types::*;
(
    input clk,
    input rst,

    //Control signals
    input   logic   pc_src,
    input   logic   pc_write,
    input   logic   is_branching_fetch,
    input   logic   imem_resp,
    input   logic   dside_stall_n,
    
    //Data signals
    input   logic       [31:0]  exmem_pc,
    output  ifid_fwd            ifid_out,
    output  rvfi_signals_fwd    rvfi_ifid,
    //IBus
    output  logic       imem_read,
    output  rv32i_word  imem_address,
    input   rv32i_word  imem_rdata,
    input   logic       br_bubble_n,
    output  logic       istall_n,
    input   logic   [31:0]  addr_in
);

    //Local variables
    logic       [31:0]  pc_reg;
    logic       [31:0]  pc_mux_out;
    
//////////////// Assigning RVFI Signals - Instruction, pc write and read data /////////////////////////////////////////

    assign rvfi_ifid.monitor_order = '0;
    assign rvfi_ifid.monitor_rd_wdata = '0;
    assign rvfi_ifid.monitor_mem_addr = '0;
    assign rvfi_ifid.monitor_mem_rmask = '0;
    assign rvfi_ifid.monitor_mem_wmask = '0;
    assign rvfi_ifid.monitor_mem_rdata = '0;
    assign rvfi_ifid.monitor_mem_wdata = '0;
    assign rvfi_ifid.monitor_rs2_rdata = '0;
    assign rvfi_ifid.monitor_rs1_rdata = '0;
    assign rvfi_ifid.monitor_rs2_addr = '0;
    assign rvfi_ifid.monitor_rs1_addr = '0;
    assign rvfi_ifid.monitor_rd_addr = '0;

    assign rvfi_ifid.monitor_inst = ifid_out.instr;
    assign rvfi_ifid.monitor_pc_rdata = pc_reg;
    assign rvfi_ifid.monitor_valid    = istall_n ? (is_branching_fetch? 0: br_bubble_n) : '0;
    assign istall_n = ~(imem_read && ~imem_resp);
    //assign rvfi_ifid.monitor_pc_wdata = pc_mux_out;
    //Muxing between pc_plus_4 or the pc from execute stage
    always_comb begin
        unique case(pc_src)
            1'b0 : begin
                if(~br_bubble_n) begin
                    pc_mux_out                  = pc_reg;
                    rvfi_ifid.monitor_pc_wdata  = pc_reg; // ****
                end
                else begin
                    pc_mux_out                  = pc_reg + 3'b100;
                    rvfi_ifid.monitor_pc_wdata  = pc_reg + 3'b100; // ****
                end
            end

            1'b1 : begin
                pc_mux_out                  = exmem_pc;
                rvfi_ifid.monitor_pc_wdata  = exmem_pc; // ****
            end

            default : begin
                pc_mux_out                  = pc_reg + 3'b100;
                rvfi_ifid.monitor_pc_wdata  = pc_reg + 3'b100; // ****
            end
        endcase
    end

    //PC register
    always_ff @(posedge clk) begin
        if(rst) 
            pc_reg  <= 32'h4000_0000;

        else begin
            //Write to PC only if there is no stall or if there is a branch
            if(imem_resp || is_branching_fetch) begin
                if ((pc_write && dside_stall_n) || is_branching_fetch) begin
                    pc_reg  <= pc_mux_out;
                end
            end
        end
    end

    //IFID_OUT and requests to IBUS
    always_comb begin
        if(rst) begin
            imem_read       = '0;
            imem_address    = '0;
        end
        else begin
            imem_address    = {pc_reg[31:2], 2'b00};
            imem_read       = (dside_stall_n && br_bubble_n) ? 1'b1 : 1'b0;
            if(imem_resp) begin
                ifid_out.pc     = pc_reg;

                if(br_bubble_n && ~is_branching_fetch) begin
                    ifid_out.instr  = imem_rdata;
                end
                else begin
                    ifid_out.instr = 32'h00000013;
                end
            end
        end

    end

endmodule : fetch