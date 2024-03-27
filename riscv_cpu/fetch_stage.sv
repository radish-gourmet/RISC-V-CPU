module fetch_stage
import types::*;
(

    input clk,
    input rst,

    // Control signals

    input pc_src_sel,
    input pc_write,
    // Branching signals
    input is_branching_fetch,
    // I/O vals here
    input logic        imem_resp,
    input logic [31:0] exmem_PC,
    input rv32i_word imem_rdata,
    output  is_branching_fetch_to_decode_next,
    output  logic   imem_read,
    output rv32i_word imem_address,
    output ifid_fwd ifid_out,
    output rvfi_signals_fwd rvfi_ifid,
    input  logic        dside_stall_n

);

/*-------------local vars-------------*/

logic   [31:0] pcmux_out;
logic   [31:0] PC_reg_out, pc_prev;
logic   [31:0] pcmux_sel;


/*-------------output assigns-------------*/

//assign ifid_out.PC  = imem_resp ? PC_reg_out : '0; // TODO: max change this for after CP1
assign imem_address = imem_resp ? pc_write && dside_stall_n ? pc_src_sel ? exmem_PC : PC_reg_out : ifid_out.PC : ifid_out.PC;
assign ifid_out.instr = imem_resp ? imem_rdata : ifid_out.instr;
assign is_branching_fetch_to_decode_next = is_branching_fetch;
assign rvfi_ifid.monitor_inst = imem_resp ? imem_rdata : '0 ;//pc_write ? imem_resp ? imem_rdata : '0 : rvfi_ifid.monitor_inst ;
assign imem_read      = rst ? 1'b0 : 1'b1;   //TODO: max handle this for CP2. Handle imem_resp for CP2

assign pcmux_out = imem_resp ? pc_src_sel ? exmem_PC : (PC_reg_out + 3'b100) : PC_reg_out;

/*-------------module instants-------------*/

register PC_reg (
    .clk        (clk        ),
    .rst        (rst        ),
    .load       (pc_write && dside_stall_n),
    .data_in    (pcmux_out  ),
    .data_out   (PC_reg_out )
);

/*-------------local muxes----s---------*/
always_ff @(posedge clk) begin : FETCH_MUXES // TODO: max combine this into the reg.sv file to not stall the PC updating
    //unique case (pc_src_sel)
    //    1'b1 : pcmux_out <= exmem_PC;
    //    1'b0 : pcmux_out <= PC_reg_out + 3'b100;
    //endcase
    if(rst) begin
        ifid_out.PC <= 32'h4000_0000;
    end
    else begin
        rvfi_ifid.monitor_pc_rdata   <= PC_reg_out;
        rvfi_ifid.monitor_pc_wdata   <= pcmux_out;
        ifid_out.PC    <=  imem_resp ? pc_write && dside_stall_n ? pc_src_sel ? exmem_PC : PC_reg_out + 3'b100 : pc_prev : ifid_out.PC;
    end

end

always_ff @(posedge clk) begin
    pc_prev <= PC_reg_out;
end

endmodule : fetch_stage