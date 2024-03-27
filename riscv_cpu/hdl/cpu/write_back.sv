module write_back
import types::*;
(
    input   clk,
    input   rst,
    input   memwb_fwd       memwb_i,
    input   rvfi_signals_fwd rvfi_memwb_i,
    input   logic           control_mux_switch_wb,
    input   logic           dside_stall_n,
    input   logic           istall_n,
    output  logic           reg_write,
    output  logic   [4:0]   rd_addr,
    output  logic   [31:0]  counter,
    output  rv32i_word      reg_wdata,
    output  logic           is_load,
    output rvfi_signals_fwd rvfi_cpu_out
);

    logic [63:0] order;
    logic [31:0] monitor_mem_rdata;
    
    assign rd_addr      = memwb_i.rd_addr;
    assign reg_write    = memwb_i.wb[1];
    assign is_load      = memwb_i.wb[0];
    assign rvfi_cpu_out.monitor_pc_rdata = rvfi_memwb_i.monitor_pc_rdata;
    assign rvfi_cpu_out.monitor_pc_wdata = rvfi_memwb_i.monitor_pc_wdata;
    assign rvfi_cpu_out.monitor_rs1_rdata = rvfi_memwb_i.monitor_rs1_rdata;
    assign rvfi_cpu_out.monitor_rs2_rdata = rvfi_memwb_i.monitor_rs2_rdata;
    assign rvfi_cpu_out.monitor_rs1_addr = rvfi_memwb_i.monitor_rs1_addr;
    assign rvfi_cpu_out.monitor_rs2_addr = rvfi_memwb_i.monitor_rs2_addr;
    assign rvfi_cpu_out.monitor_rd_addr = rvfi_memwb_i.monitor_rd_addr;
    assign rvfi_cpu_out.monitor_mem_addr = rvfi_memwb_i.monitor_mem_addr;
    assign rvfi_cpu_out.monitor_mem_wdata = rvfi_memwb_i.monitor_mem_wdata;
    assign rvfi_cpu_out.monitor_mem_rdata = memwb_i.wb[0] ? memwb_i.line : '0; ////////////////////////// TODO: Change it not valid for bubbles
    assign rvfi_cpu_out.monitor_valid = dside_stall_n ? ( istall_n ? rvfi_memwb_i.monitor_valid : '0) : '0;//control_mux_switch_wb? rvfi_memwb_i.monitor_valid : '0; /////////////// TODO: Nitish uncomment it
    assign rvfi_cpu_out.monitor_mem_rmask = rvfi_memwb_i.monitor_mem_rmask;
    assign rvfi_cpu_out.monitor_mem_wmask = rvfi_memwb_i.monitor_mem_wmask;
    assign rvfi_cpu_out.monitor_inst = rvfi_memwb_i.monitor_inst;
    assign rvfi_cpu_out.monitor_rd_wdata  = reg_write? reg_wdata: '0;
    assign rvfi_cpu_out.monitor_order = order;

    always @(posedge clk) begin
         if(rvfi_cpu_out.monitor_valid == 1'b1)
            order <= order + 1;
         if(rst) order <=0; 
    end

    always_comb begin
        if(rst) begin
            reg_wdata = '0;
        end
        else begin
            unique case(memwb_i.wb[0])
                1'b1 : reg_wdata = memwb_i.read_data;
                1'b0 : reg_wdata = memwb_i.alu_result;
                default : ;
            endcase
        end
        

    end


endmodule : write_back