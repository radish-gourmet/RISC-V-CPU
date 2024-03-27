module memory_stage
import types::*;
(
    input                   clk,
    input                   rst,
    input   exmem_fwd       exmem,
    input   rvfi_signals_fwd      rvfi_exmem_i,
    input   logic [31:0]    memwb_rdata,/// Signal to get from WB
    input   logic           reg_write, //// Signal to get from WB
    input   logic           is_load,
    input   logic [4:0]     wb_rd_addr, //// Signal to get from WB
    input   logic           control_mux_switch_mem,
    input   logic           dmem_resp,
    input   rv32i_word      dmem_rdata,
    output  logic           control_mux_switch_wb_next,
    output  rv32i_word      dmem_address,
    output  logic           dmem_read,
    output  logic           dmem_write,
    output  rv32i_word      dmem_wdata,
    output  logic [3:0]     dmem_wmask,
    input   logic           istall_n,
    output  memwb_fwd       memwb,
    output rvfi_signals_fwd rvfi_memwb_o,
    output  logic           dside_stall_n
);

logic [3:0] rmask;
/// signals for using MEM Fwding
logic [31:0] mem_wdata;
logic [4:0] rs2_addr;

assign rvfi_memwb_o.monitor_order = '0;
assign rvfi_memwb_o.monitor_rd_wdata = '0;
assign rvfi_memwb_o.monitor_mem_rdata = '0;

assign control_mux_switch_wb_next = control_mux_switch_mem;
assign dside_stall_n    = (exmem.wb[0] | exmem.m[0]) ? dmem_resp : 1'b1;


assign rvfi_memwb_o.monitor_pc_rdata = rvfi_exmem_i.monitor_pc_rdata; // ****
assign rvfi_memwb_o.monitor_pc_wdata = rvfi_exmem_i.monitor_pc_wdata; // ****
assign rvfi_memwb_o.monitor_inst = rvfi_exmem_i.monitor_inst; // ****
assign rvfi_memwb_o.monitor_rs1_rdata = rvfi_exmem_i.monitor_rs1_rdata;
assign rvfi_memwb_o.monitor_rs2_rdata = mem_wdata;//((reg_write == 1'b1) && (wb_rd_addr == rs2_addr) && is_load)? memwb_rdata : rvfi_exmem_i.monitor_rs2_rdata;//rvfi_exmem_i.monitor_rs2_rdata;
assign rvfi_memwb_o.monitor_rs1_addr = rvfi_exmem_i.monitor_rs1_addr;
assign rvfi_memwb_o.monitor_rs2_addr = rvfi_exmem_i.monitor_rs2_addr;
assign rvfi_memwb_o.monitor_rd_addr = exmem.m[0] ? '0 : rvfi_exmem_i.monitor_rd_addr;/// Adding this because of sw instr rvfi doesnt want any RD value
assign rvfi_memwb_o.monitor_mem_addr = dmem_address;
assign rvfi_memwb_o.monitor_mem_wdata = dmem_wdata;//((reg_write == 1'b1) && (wb_rd_addr == rs2_addr) && is_load)? memwb_rdata :rvfi_exmem_i.monitor_mem_wdata;
assign rvfi_memwb_o.monitor_valid  = dside_stall_n ? (istall_n ? rvfi_exmem_i.monitor_valid : '0) : '0;
assign rvfi_memwb_o.monitor_mem_wmask  = exmem.m[0]? dmem_wmask: '0;
assign rvfi_memwb_o.monitor_mem_rmask  = exmem.m[1]? rmask: '0;
assign rs2_addr = rvfi_exmem_i.monitor_rs2_addr;


//// If there's lw x1,.... and sw x1,.... then we fwd the 1st instr data to second one
always_comb begin
    if((reg_write == 1'b1) && (wb_rd_addr == rs2_addr) && is_load) mem_wdata = memwb_rdata;
    else mem_wdata = exmem.rs2_out;
end


always_comb begin
    //Read
    if(exmem.m[1]) begin
        dmem_address    = {exmem.alu_result[31:2], 2'b00};
        dmem_read       = 1'b1;
        dmem_wmask      = '0;
        dmem_wdata      = '0;
        dmem_write      = '0;
        case(exmem.funct3)
            3'b000 : rmask = 4'b0001 << exmem.alu_result[1:0];
            3'b001 : rmask = 4'b0011 << exmem.alu_result[1:0];
            3'b100 : rmask = 4'b0001 << exmem.alu_result[1:0];
            3'b101 : rmask = 4'b0011 << exmem.alu_result[1:0];
            default : rmask = 4'b1111;
        endcase
    end
    //Write
    else if(exmem.m[0]) begin
        dmem_address    = {exmem.alu_result[31:2], 2'b00};
        dmem_wmask      = 4'b0000;             //TODO: max to update the mask for sb, sh, sw
        dmem_wdata      = mem_wdata;
        dmem_write      = 1'b1;
        dmem_read       = 1'b0;
        rmask           = 1'b0;
        case(exmem.funct3)
            3'b000 : begin
                dmem_wmask = 4'b0001 << exmem.alu_result[1:0];
                dmem_wdata = mem_wdata << exmem.alu_result[1:0]*8;
            end
            3'b001 : begin
                dmem_wmask = 4'b0011 << exmem.alu_result[1:0];
                dmem_wdata = mem_wdata << exmem.alu_result[1:0]*8;
            end
            default : dmem_wmask  = 4'b1111;
        endcase
    end
    else begin
        dmem_write      = 1'b0;
        dmem_read       = 1'b0;
        dmem_address    = exmem.alu_result;
        dmem_read       = 1'b0;
        rmask           = 1'b0;
        dmem_wmask      = 1'b0;
        dmem_wdata      = '0;
        dmem_write      = 1'b0;
    end

    //Stall until dmem_resp is received
    if(((dmem_read || dmem_write) && ~dmem_resp) == 1) begin        //Stall 
        memwb.alu_result    = '0;
        memwb.rd_addr       = '0;
        memwb.wb            = '0;
        memwb.imm           = '0;
        memwb.funct3        = '0;
        memwb.read_data     = dmem_rdata;
        memwb.line          = '0;
    end
    else begin  //Come out of stall and forward info to wb stage
        memwb.alu_result = exmem.alu_result; 
        memwb.rd_addr    = exmem.rd_addr;
        memwb.wb         = exmem.wb;
        memwb.imm        = exmem.imm;
        memwb.funct3     = exmem.funct3;
        memwb.line       = dmem_rdata;
        
        case(exmem.funct3)
            3'b000 : begin
                case(exmem.alu_result[1:0])
                    2'b00: memwb.read_data = {{24{dmem_rdata[7]}}, dmem_rdata[7:0]};
                    2'b01: memwb.read_data = {{24{dmem_rdata[15]}}, dmem_rdata[15:8]};
                    2'b10: memwb.read_data = {{24{dmem_rdata[23]}}, dmem_rdata[23:16]};
                    2'b11: memwb.read_data = {{24{dmem_rdata[31]}}, dmem_rdata[31:24]};
                    default: memwb.read_data = {{24{dmem_rdata[7]}}, dmem_rdata[7:0]};
                endcase
            end
            3'b100 : begin
                case(exmem.alu_result[1:0])
                    2'b00: memwb.read_data = {{24{0}}, dmem_rdata[7:0]};
                    2'b01: memwb.read_data = {{24{0}}, dmem_rdata[15:8]};
                    2'b10: memwb.read_data = {{24{0}}, dmem_rdata[23:16]};
                    2'b11: memwb.read_data = {{24{0}}, dmem_rdata[31:24]};
                    default: memwb.read_data = {{24{0}}, dmem_rdata[7:0]};
                endcase
            end
            3'b001 : begin
                case(exmem.alu_result[1:0])
                    2'b00: memwb.read_data = {{16{dmem_rdata[15]}}, dmem_rdata[15:0]};
                    2'b10: memwb.read_data = {{16{dmem_rdata[31]}}, dmem_rdata[31:16]};
                    default: memwb.read_data = {{16{dmem_rdata[15]}}, dmem_rdata[15:0]};
                endcase
            end
            3'b101 : begin
                case(exmem.alu_result[1:0])
                    2'b00: memwb.read_data = {{16{0}}, dmem_rdata[15:0]};
                    2'b10: memwb.read_data = {{16{0}}, dmem_rdata[31:16]};
                    default: memwb.read_data = {{16{0}}, dmem_rdata[15:0]};
                endcase
            end
            default : begin
                memwb.read_data                 = dmem_rdata;
            end
        endcase
    end
end

endmodule : memory_stage