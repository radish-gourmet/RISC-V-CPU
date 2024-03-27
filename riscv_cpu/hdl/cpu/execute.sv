module execute
import types::*;
(
    input logic clk,
    input logic rst,
    input idex_fwd idex,
    input rvfi_signals_fwd rvfi_idex_i,
    input  logic [4:0] mem_wb_rd,
    input  logic mem_wb_regwrite,
    input  logic ex_mem_regwrite,
    input  logic [4:0] ex_mem_rd,
    input  logic [31:0] exmem_alu_result,
    input  logic [31:0] mem_wb_mux_d_out,
    input  logic        control_mux_switch_ex,
    input  logic        dside_stall_n,
    input  logic        istall_n,
    output logic control_mux_switch_mem_next,
    output exmem_fwd exmem,
    output rvfi_signals_fwd rvfi_exmem_o,
    output is_branching_decode,
    output is_branching_fetch,
    output logic [31:0] pc_out
); 
    alu_ops alu_control_out;
    logic [31:0] a,pc, imm_gen; //////////////////////Do you want to use imm_gen or which immediate you want to use
    logic [31:0] i_imm;
    logic [31:0] s_imm;
    logic [31:0] b_imm;
    logic [31:0] u_imm;
    logic [31:0] j_imm;
    logic [31:0] alu_out, pc_alu_out;
    logic alumux2_sel;
    logic [1:0] ALUop;
    logic [2:0] funct3;
    logic  [2:0] cmp_input;
    logic funct7_msb;
    branch_funct3_t cmpop;
    logic cmp_o;
    arith_funct3_t arith_funct3;
    branch_funct3_t branch_funct3;
    rv32i_opcode opcode;
    rv32i_word alu_input_2;
    rv32i_word forwardB_out;
    logic [1:0] ForwardB_sel;
    rv32i_word alu_input_1;
    logic [1:0] ForwardA_sel;
    logic [4:0] id_ex_rs1_addr;
    logic [4:0] id_ex_rs2_addr;
 
 forward_module forward(.*);

    assign rvfi_exmem_o.monitor_order = '0;
    assign rvfi_exmem_o.monitor_rd_wdata = '0;
    assign rvfi_exmem_o.monitor_mem_rmask = '0;
    assign rvfi_exmem_o.monitor_mem_wmask = '0;
    assign rvfi_exmem_o.monitor_mem_rdata = '0;

    assign control_mux_switch_mem_next = control_mux_switch_ex;
    assign opcode      = idex.opcode;
    assign is_branching_decode = (opcode == op_jalr)? 1: (opcode == op_jal)? 1: (cmp_o && idex.m[2]); ////exmem.zero && exmem.m[2]); 
    assign is_branching_fetch  = (opcode == op_jalr)? 1: (opcode == op_jal)? 1: (cmp_o && idex.m[2]);
    //assign control_mux_switch_mem_next = control_mux_switch_ex;
    assign alumux2_sel = idex.ex[0];
    assign ALUop = idex.ex[2:1];
    assign funct3 = idex.funct3[2:0];
    assign arith_funct3 = arith_funct3_t'(funct3);
    assign branch_funct3 = branch_funct3_t'(funct3);
    assign funct7_msb = idex.funct3[3];
    assign pc = idex.pc;
    assign id_ex_rs1_addr = idex.rs1_addr;
    assign id_ex_rs2_addr = idex.rs2_addr;
    assign rvfi_exmem_o.monitor_pc_rdata    = rvfi_idex_i.monitor_pc_rdata;
    assign rvfi_exmem_o.monitor_pc_wdata    = is_branching_fetch ? exmem.pc : rvfi_idex_i.monitor_pc_wdata; ////// TODO: Use better naming here. Essentially we are assigining PC WData pc+4 or pc+x based on whether it's branch instr or not
    assign rvfi_exmem_o.monitor_inst        = rvfi_idex_i.monitor_inst;
    //assign rvfi_exmem_o.monitor_rs1_rdata   = alu_input_1;
    //assign rvfi_exmem_o.monitor_rs2_rdata   = exmem.rs2_out;
    assign rvfi_exmem_o.monitor_rs1_addr    = rvfi_idex_i.monitor_rs1_addr;
    assign rvfi_exmem_o.monitor_rs2_addr    = rvfi_idex_i.monitor_rs2_addr;
    assign rvfi_exmem_o.monitor_rd_addr     = rvfi_idex_i.monitor_rd_addr;
    assign rvfi_exmem_o.monitor_mem_wdata   = idex.rs2_out;
    assign rvfi_exmem_o.monitor_valid       = rvfi_idex_i.monitor_valid;
    assign rvfi_exmem_o.monitor_mem_addr = alu_out;
//////////////////// TODO: Nitish needs to modify RVFI signals when forwarding is happening
always_comb begin: FORWARD_B //// Code for picking which one to use as ALU Input 2. Can either be from REG stage, previous MEM and WB stages respectively.
    unique case(ForwardB_sel)
    2'b00: forwardB_out = idex.rs2_out;
    2'b10: forwardB_out = exmem_alu_result;
    2'b01: forwardB_out = mem_wb_mux_d_out;
    default: forwardB_out = idex.rs2_out;
    endcase
end: FORWARD_B

always_comb begin: FORWARD_A //// Code for picking which one to use as ALU Input 1. Can either be from REG stage, previous MEM and WB stages respectively.
unique case(ForwardA_sel)
    2'b00: begin
        alu_input_1                     = idex.rs1_out;
        rvfi_exmem_o.monitor_rs1_rdata  = idex.rs1_out; // ****
    end
    2'b01: begin
        alu_input_1                     = mem_wb_mux_d_out;
        rvfi_exmem_o.monitor_rs1_rdata  = mem_wb_mux_d_out; // ****
    end
    2'b10: begin
        alu_input_1                     = exmem_alu_result;
        rvfi_exmem_o.monitor_rs1_rdata  = exmem_alu_result; // ****
    end
    default: begin
        alu_input_1                     = idex.rs1_out;
        rvfi_exmem_o.monitor_rs1_rdata  = idex.rs1_out; // ****
    end
endcase
end: FORWARD_A
////// Code for MUX select for ALU Input 2
always_comb begin : ALU_SRC 
unique case(alumux2_sel)
        0: alu_input_2 = forwardB_out;
        1: alu_input_2 = idex.imm;
endcase
end : ALU_SRC 
///////////// Opcode for figuring out which type of instr it is
/*always_comb begin
                case(opcode)
                    //op_lui      : next_states = lui;
                    //op_auipc    : next_states = auipc;
                    //op_br       : next_states = br;
                    //op_load     : next_states = calc_addr;
                    //op_store    : next_states = calc_addr;
                    op_imm      : next_states = imm;
                    //op_reg      : next_states = rtype;
                    //op_jal      : next_states = jal;
                    //op_jalr     : next_states = jalr;
                    default     : next_states = fetch1;
                endcase
end */
always_comb begin : CONFIG_ALU_OUT
unique case(opcode)

    op_imm: begin
        /////Either it's an add,sub, and or. R type instruction.
        ///////////// Generate the ALU operation from Funct bits
            case(arith_funct3)
                add     : begin
                    //loadRegfile(regfilemux::alu_out); Writing an equivalent of this below
                    //loadPC(pcmux::pc_plus4); This equivalent should be done by Mem signal going to AND gate of MEM stage
                        alu_control_out = alu_add;
                        cmp_input = 3'b10; /////////////////////////////////// Assiging it to 2, as it's the default value and won't give out any comperator result
                end

                sll     : begin
                    alu_control_out = alu_sll;
                    cmp_input = 3'b10;
                end

                slt     : begin
                    alu_control_out = alu_slt;
                    cmp_input = blt;
                end

                sltu    : begin
                    alu_control_out = alu_sltu;
                    cmp_input = bltu;
                end

                axor     : begin
                    alu_control_out = alu_xor;
                    cmp_input = 3'b10;
                end

                sr      : begin
                    case(funct7_msb)
                        0 : begin  
                            alu_control_out = alu_srl;
                            cmp_input = 3'b10;
                        end

                        1 : begin  
                            alu_control_out = alu_sra;
                            cmp_input = 3'b10;
                        end
                    endcase
                end

                aor     : begin
                    alu_control_out = alu_or;
                    cmp_input = 3'b10;
                end

                aand    : begin
                    alu_control_out = alu_and;
                    cmp_input = 3'b10;
                end

            endcase
    end

    op_reg: begin
        /////Either it's an add,sub, and or. R type instruction.
        ///////////// Generate the ALU operation from Funct bits
            case(arith_funct3)
                add     : begin
                    //loadRegfile(regfilemux::alu_out); Writing an equivalent of this below
                    //loadPC(pcmux::pc_plus4); This equivalent should be done by Mem signal going to AND gate of MEM stage
                    if(funct7_msb == 1'b0) begin
                        alu_control_out = alu_add;
                        cmp_input = 3'b10;
                    end
                    else begin
                        alu_control_out = alu_sub;
                        cmp_input = 3'b10;
                    end
                end

                sll     : begin
                    alu_control_out = alu_sll;
                    cmp_input = 3'b10;
                end

                slt     : begin
                    alu_control_out = alu_slt;
                    cmp_input = blt;
                end

                sltu    : begin
                    alu_control_out = alu_sltu;
                    cmp_input = bltu;
                end

                axor     : begin
                    alu_control_out = alu_xor;
                    cmp_input = 3'b10;
                end
                sr      : begin
                    case(funct7_msb)
                        0 : begin  
                            alu_control_out = alu_srl;
                            cmp_input = 3'b10;
                        end

                        1 : begin  
                            alu_control_out = alu_sra;
                            cmp_input = 3'b10;
                        end
                    endcase
                end

                aor     : begin
                    alu_control_out = alu_or;
                    cmp_input = 3'b10;
                end

                aand    : begin
                    alu_control_out = alu_and;
                    cmp_input = 3'b10;
                end

            endcase
    end
    op_load: begin
        ///////////////// Its either load or store operation. So do just addition of inputs for address calculation. Source: Pg no. 509
        alu_control_out = alu_add;
        cmp_input = 3'b10;
    end
    op_store: begin
        ///////////////// Its either load or store operation. So do just addition of inputs for address calculation. Source: Pg no. 509
        alu_control_out = alu_add;
        cmp_input = 3'b10;
    end
    op_br: begin
        ////////////////  It's a branch instruction, so check for zero flag only.
        alu_control_out = alu_add; /////////// TODO; This is not required, still putting it. Nitish
        cmp_input = branch_funct3;
        ///////////////   Doing nothing here anyways. As Cmp is taking Funct3 as an input
    end
    op_jal: begin
        ////////////////  It's a branch instruction, so check for zero flag only.
        alu_control_out = alu_add; /////////// TODO; This is not required, still putting it. Nitish
        cmp_input = 3'b10;
        ///////////////   Doing nothing here anyways. As Cmp is taking Funct3 as an input
    end
    op_jalr: begin
        ////////////////  It's a branch instruction, so check for zero flag only.
        alu_control_out = alu_add; /////////// TODO; This is not required, still putting it. Nitish
        cmp_input = 3'b10;
        ///////////////   Doing nothing here anyways. As Cmp is taking Funct3 as an input
    end
    op_auipc: begin
        alu_control_out = alu_pc;
        cmp_input = 3'b10;
    end
    op_lui: begin
        alu_control_out = alu_lui;
        cmp_input = 3'b10;
    end
    default: begin alu_control_out = alu_pc;
    cmp_input = 3'b10;
    end
endcase
end : CONFIG_ALU_OUT
always_comb begin : PC_ALU
    pc_alu_out = pc + (idex.imm);
end : PC_ALU
always_comb begin : PC_INCR
    case(opcode)
        op_br: pc_out = pc + (idex.imm);
        op_jal: pc_out = (pc_alu_out);
        op_jalr: pc_out = ({alu_out[31:1], 1'b0});
        default : pc_out = pc;
    endcase
    
end : PC_INCR
always_comb begin : ALU_CALC
    unique case (alu_control_out)
        alu_add:  alu_out = alu_input_1 + ( alu_input_2);
        alu_sll:  alu_out = alu_input_1 << alu_input_2[4:0];
        alu_sra:  alu_out = $unsigned($signed(alu_input_1) >>> alu_input_2[4:0]);
        alu_sub:  alu_out = alu_input_1 - alu_input_2;
        alu_xor:  alu_out = alu_input_1 ^ alu_input_2;
        alu_srl:  alu_out = alu_input_1 >> alu_input_2[4:0];
        alu_or:   alu_out = alu_input_1 | alu_input_2;
        alu_and:  alu_out = alu_input_1 & alu_input_2;
        alu_pc:   alu_out = pc + alu_input_2; ///////////// TODO: Remove ALU_PC for calculating AUIPC 
        alu_lui:  alu_out = alu_input_2;
        alu_slt:  alu_out = '0;
        alu_sltu: alu_out = '0;
        default : alu_out = '0;
    endcase
end : ALU_CALC
//////// Comperator for Zero flag : TODO, for Branch we have to redo this
always_comb begin  : CMP
    unique case (cmp_input)
        beq:  cmp_o = (alu_input_1 == alu_input_2);
        bne:  cmp_o = (alu_input_1 != alu_input_2);
        blt:  cmp_o = ($signed(alu_input_1) < $signed(alu_input_2));
        bge:  cmp_o = ($signed(alu_input_1) >= $signed(alu_input_2));
        bltu: cmp_o = (alu_input_1 < alu_input_2);
        bgeu: cmp_o = (alu_input_1 >= alu_input_2);
        default: cmp_o = 1'b0;
    endcase
end  : CMP

always_comb begin : EXMEM_OUT
    if(rst) begin
        exmem.wb = '0;
        exmem.m  = '0;
        rvfi_exmem_o.monitor_rs2_rdata  = '0; // **** 
        exmem.pc = '0;
        exmem.alu_result = '0;
        exmem.zero      = '0;
        exmem.rs2_out = '0;
        exmem.rd_addr = '0;
        exmem.imm = '0;
        exmem.funct3 = '0;
    end
    else begin
        if((dside_stall_n == 1'b0) || (istall_n == 1'b0)) begin     //Dside stall
            exmem.wb = '0;
            exmem.m  = '0;
            rvfi_exmem_o.monitor_rs2_rdata  = '0; // **** 
            exmem.pc = '0;
            exmem.alu_result = '0;
            exmem.zero      = '0;
            exmem.rs2_out = '0;
            exmem.rd_addr = '0;
            exmem.imm = '0;
            exmem.funct3 = '0;
        end
        else begin
            exmem.wb = idex.wb;
            exmem.m  = idex.m;
            rvfi_exmem_o.monitor_rs2_rdata  = exmem.rs2_out; // **** 
            exmem.pc = pc_out;
            exmem.zero = (opcode == op_jalr)? 1: (opcode == op_jal)? 1: cmp_o;
            if(cmp_o == 1'b1) begin
                exmem.alu_result = 32'h00000001;
            end else if(opcode == op_jalr) begin
                exmem.alu_result = pc +4;
            end else if(opcode == op_jal) begin
                exmem.alu_result = pc + 4;
            end else begin
                exmem.alu_result = alu_out;
            end
            //exmem.alu_result = cmp_o ? 32'h00000001 : (opcode == op_jalr)? (pc+4) : alu_out;
            exmem.rs2_out = forwardB_out;
            exmem.rd_addr = idex.rd_addr;
            exmem.imm = idex.imm;
            exmem.funct3 = funct3;
        end
    end
    
end : EXMEM_OUT

endmodule : execute