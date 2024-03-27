module decode
import types::*;
(
    input                       clk,
    input                       rst,
    input   ifid_fwd            ifid_i,
    input   rvfi_signals_fwd    rvfi_ifid_i,
    input   logic       [4:0]   rd_addr,
    input   rv32i_word          rd_data,
    input   logic               reg_write,
    input   logic               idex_mem_rd,
    input   logic       [4:0]   idex_rd,
    input  logic                dside_stall_n,
    input  logic                istall_n,
    input   logic               is_branching, ///////// This bit is set to one if the Branch condition is satisfied
    output  logic               ifid_write,
    output  logic               pc_write,
    output  idex_fwd            idex_o,
    output logic           control_mux_switch_ex_next,
    output  rvfi_signals_fwd    rvfi_idex_o,
    output  logic               br_bubble_n
);

//TODO: Rakesh - imm is 64 bits. Why is it? check and update

//IR and CONTROL
logic   [2:0]   funct3;
logic   [6:0]   funct7;
rv32i_opcode    opcode;
logic   [31:0]  i_imm;
logic   [31:0]  s_imm;
logic   [31:0]  b_imm;
logic   [31:0]  u_imm;
logic   [31:0]  j_imm;
logic   [4:0]   rs1;
logic   [4:0]   rs2;
logic   [4:0]   rd;
rv32i_word      rs1_out;
rv32i_word      rs2_out;
//control signals
logic   [2:0]   ex;
logic   [2:0]   m;
logic   [1:0]   wb;
logic           control_mux_switch;

logic           valid;
rv32i_word rs1_rdata;
rv32i_word rs2_rdata;

assign funct3           = ifid_i.instr[14:12];
assign funct7           = ifid_i.instr[31:25];
assign opcode           = rv32i_opcode'(ifid_i.instr[6:0]);
assign i_imm            = {{21{ifid_i.instr[31]}}, ifid_i.instr[30:20]};
assign s_imm            = {{21{ifid_i.instr[31]}}, ifid_i.instr[30:25], ifid_i.instr[11:7]};
assign b_imm            = {{20{ifid_i.instr[31]}}, ifid_i.instr[7], ifid_i.instr[30:25], ifid_i.instr[11:8], 1'b0};
assign u_imm            = {ifid_i.instr[31:12], 12'h000};
assign j_imm            = {{12{ifid_i.instr[31]}}, ifid_i.instr[19:12], ifid_i.instr[20], ifid_i.instr[30:21], 1'b0};
assign rs1              = ifid_i.instr[19:15];
assign rs2              = ifid_i.instr[24:20];
assign rd               = ifid_i.instr[11:7];
assign idex_o.pc        = ifid_i.pc;
assign idex_o.opcode    = opcode;
//-----------------------rvfi-----------------------//
assign rvfi_idex_o.monitor_order = '0;
assign rvfi_idex_o.monitor_rd_wdata = '0;
assign rvfi_idex_o.monitor_mem_addr = '0;
assign rvfi_idex_o.monitor_mem_rmask = '0;
assign rvfi_idex_o.monitor_mem_wmask = '0;
assign rvfi_idex_o.monitor_mem_rdata = '0;
assign rvfi_idex_o.monitor_mem_wdata = '0;

assign rvfi_idex_o.monitor_pc_rdata     = rvfi_ifid_i.monitor_pc_rdata; // ****
assign rvfi_idex_o.monitor_pc_wdata     = rvfi_ifid_i.monitor_pc_wdata; // ****
assign rvfi_idex_o.monitor_inst     = rvfi_ifid_i.monitor_inst; // ****
assign rvfi_idex_o.monitor_rs1_rdata = rs1 ? rs1_rdata :  '0; // **** TODO nitish and max check if correct
assign rvfi_idex_o.monitor_rs2_rdata = rs2 ? rs2_rdata : '0; // **** ^^^^^^
assign rvfi_idex_o.monitor_rs1_addr  = rs1; // ****
assign rvfi_idex_o.monitor_rs2_addr  = rs2; // ****
assign rvfi_idex_o.monitor_rd_addr   =  (opcode==op_br) ? '0 :rd; // ****
assign rvfi_idex_o.monitor_valid  = control_mux_switch ? ((dside_stall_n && istall_n) ? (is_branching ? 0: (rvfi_ifid_i.monitor_valid ? valid : 0)) : 0) : 0;
//-----------------------rvfi-----------------------//

assign idex_o.rs1 = rs1;
assign idex_o.rs2 = rs2;
assign idex_o.rs1_out = rs1_rdata;
assign idex_o.rs2_out = rs2_rdata;
assign control_mux_switch_ex_next = control_mux_switch ;

///////////////// Comb block for forwarding when write and Read is happening to same cycle
always_comb begin
    if((rd_addr == rs1) && (rd_addr != 0) && (reg_write)) rs1_rdata = rd_data;
    else rs1_rdata = rs1_out;
    if((rd_addr == rs2) && (rd_addr != 0) && (reg_write)) rs2_rdata = rd_data;
    else rs2_rdata = rs2_out;
end

always_comb begin
    //Flop imm field in idexstruct
    valid = 1'b1;
    case(opcode)
        op_lui : begin
            idex_o.imm      = u_imm;
            ex       = '1;
            m        = 3'b100;
            wb       = 2'b10; 
        end

        op_auipc : begin
            idex_o.imm      = u_imm;
            ex       = '1;
            m        = 3'b100;
            wb       = 2'b10;  
        end

        op_jal : begin
            idex_o.imm      = j_imm;
            ex       = '1;
            m        = 3'b100;
            wb       = 2'b10;  
        end

        op_jalr : begin
            idex_o.imm      = i_imm;
            ex       = '1;
            m        = 3'b100;
            wb       = 2'b10;  
        end

        op_br : begin
            idex_o.imm      = b_imm;
            ex       = 3'b010;
            m        = 3'b100;
            wb       = 2'b00;
        end

        op_load : begin
            idex_o.imm      = i_imm;
            ex       = 3'b001;
            m        = 3'b010;
            wb       = 2'b11;
        end

        op_store : begin
            idex_o.imm      = s_imm;
            ex       = 3'b001;
            m        = 3'b001;
            wb       = 2'b0x;       //TODO : Akula - confirm is 0 is alright
        end

        op_imm : begin
            idex_o.imm      = i_imm;
            ex       = 3'b101;
            m        = 3'b000;
            wb       = 2'b10;
        end

        op_reg : begin
            idex_o.imm      = '0;
            ex       = 3'b100;
            m        = 3'b000;
            wb       = 2'b10;
        end

        default: begin
            idex_o.imm      = '1;
            ex       = '1;
            m        = 3'b100;
            wb       = 2'b10;        //TODO: Rakesh check this default value for other cases. Working for auipc for now
            valid           = 1'b0;
        end
    endcase

    //Flop funct7 (30th bit), funct3, and rd_addr
    idex_o.funct3    = {ifid_i.instr[30], funct3};
    idex_o.rd_addr   = rd;
    idex_o.rs1_addr  = rs1;
    idex_o.rs2_addr  = rs2;
end

//Register file
//rs1_out and rs2_out fields in idex
regfile REGFILE(
    .clk(clk),
    .rst(rst),
    .load(reg_write),
    .in(rd_data),
    .src_a(rs1),
    .src_b(rs2),
    .dest(rd_addr),
    .reg_a(rs1_out),
    .reg_b(rs2_out)
);

//Hazard detection unit
always_comb begin
    if(rst == 1'b1) begin
        control_mux_switch = 1'b1;
        ifid_write  = 1'b1;
        pc_write    = 1'b1;
        idex_o.ex   = '0;
        idex_o.m    = '0;
        idex_o.wb   = '0;
        br_bubble_n = '1;
    end

    else begin
        if(is_branching == 1'b1) begin
            idex_o.ex   = '0;
            idex_o.m    = '0;
            idex_o.wb   = '0;
            ifid_write  = 1'b1;
            pc_write    = 1'b0;
            control_mux_switch = 1'b0;
            br_bubble_n = '0;
        end
        
        else begin
            //Default value - keep issuing imem_read unless there is a branch
            br_bubble_n = 1'b1;

            if((idex_mem_rd == 1'b1) && ((rs1 == idex_rd) || (rs2 == idex_rd)))
                control_mux_switch = 1'b0;
            //else if (is_branching_fetch_to_decode == 1'b1) control_mux_switch = 1'b0;
            //else if (is_branching == 1'b1) control_mux_switch = 1'b0;
            else    control_mux_switch = 1'b1;

            

            //Mux to assign control signals - for stall
            if(ifid_i.instr != 0) begin
                unique case({is_branching,(control_mux_switch && dside_stall_n && istall_n)})  //stall if either control_mux_switch or dside_stall_n goes low ; Drive ex, mem,wb to be 0 if the previous instruction was a branch
                    2'b00 : begin
                        idex_o.ex   = '0;
                        idex_o.m    = '0;
                        idex_o.wb   = '0;
                        ifid_write  = 1'b0;
                        pc_write    = 1'b0;
                    end

                    2'b01 : begin
                        idex_o.ex   = ex;
                        idex_o.m    = m;
                        idex_o.wb   = wb;
                        ifid_write  = 1'b1;
                        pc_write    = 1'b1;
                    end
                
                    2'b10 : begin
                        idex_o.ex   = '0;
                        idex_o.m    = '0;
                        idex_o.wb   = '0;
                        ifid_write  = 1'b1;
                        pc_write    = 1'b1;
                    end

                    default : begin
                        idex_o.ex   = '0;
                        idex_o.m    = '0;
                        idex_o.wb   = '0;
                        ifid_write  = 1'b0;
                        pc_write    = 1'b0;
                    end
                endcase
            end
            else begin
                ifid_write  = 1'b1;
                pc_write    = 1'b1;
                idex_o.ex   = '0;
                idex_o.m    = '0;
                idex_o.wb   = '0;
            end
        end
    end

    //Block imem_read requests if there is a branch instruction in decode.
    if(opcode == op_br) br_bubble_n = 1'b0;
end

endmodule : decode