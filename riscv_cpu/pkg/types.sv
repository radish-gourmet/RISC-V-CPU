package pcmux;
typedef enum bit [1:0] {
    pc_plus4  = 2'b00
    ,alu_out  = 2'b01
    ,alu_mod2 = 2'b10
} pcmux_sel_t;
endpackage

package marmux;
typedef enum bit {
    pc_out = 1'b0
    ,alu_out = 1'b1
} marmux_sel_t;
endpackage

package cmpmux;
typedef enum bit {
    rs2_out = 1'b0
    ,i_imm = 1'b1
} cmpmux_sel_t;
endpackage

package alumux;
typedef enum bit {
    rs1_out = 1'b0
    ,pc_out = 1'b1
} alumux1_sel_t;

typedef enum bit [2:0] {
    i_imm    = 3'b000
    ,u_imm   = 3'b001
    ,b_imm   = 3'b010
    ,s_imm   = 3'b011
    ,j_imm   = 3'b100
    ,rs2_out = 3'b101
} alumux2_sel_t;
endpackage

package regfilemux;
typedef enum bit [3:0] {
    alu_out   = 4'b0000
    ,br_en    = 4'b0001
    ,u_imm    = 4'b0010
    ,lw       = 4'b0011
    ,pc_plus4 = 4'b0100
    ,lb        = 4'b0101
    ,lbu       = 4'b0110  // unsigned byte
    ,lh        = 4'b0111
    ,lhu       = 4'b1000  // unsigned halfword
} regfilemux_sel_t;
endpackage

package types;
// Mux types are in their own packages to prevent identiier collisions
// e.g. pcmux::pc_plus4 and regfilemux::pc_plus4 are seperate identifiers
// for seperate enumerated types
import pcmux::*;
import marmux::*;
import cmpmux::*;
import alumux::*;
import regfilemux::*;

typedef logic [31:0] rv32i_word;
typedef logic [4:0] rv32i_reg;
typedef logic [3:0] rv32i_mem_wmask;

typedef enum bit [6:0] {
    op_lui   = 7'b0110111, //load upper immediate (U type)
    op_auipc = 7'b0010111, //add upper immediate PC (U type)
    op_jal   = 7'b1101111, //jump and link (J type)
    op_jalr  = 7'b1100111, //jump and link register (I type)
    op_br    = 7'b1100011, //branch (B type)
    op_load  = 7'b0000011, //load (I type)
    op_store = 7'b0100011, //store (S type)
    op_imm   = 7'b0010011, //arith ops with register/immediate operands (I type)
    op_reg   = 7'b0110011, //arith ops with register operands (R type)
    op_csr   = 7'b1110011  //control and status register (I type)
} rv32i_opcode;

typedef enum bit [2:0] {
    beq  = 3'b000,
    bne  = 3'b001,
    blt  = 3'b100,
    bge  = 3'b101,
    bltu = 3'b110,
    bgeu = 3'b111
} branch_funct3_t;

typedef enum bit [2:0] {
    lb  = 3'b000,
    lh  = 3'b001,
    lw  = 3'b010,
    lbu = 3'b100,
    lhu = 3'b101
} load_funct3_t;

typedef enum bit [2:0] {
    sb = 3'b000,
    sh = 3'b001,
    sw = 3'b010
} store_funct3_t;

typedef enum bit [2:0] {
    add  = 3'b000, //check bit30 for sub if op_reg opcode
    sll  = 3'b001,
    slt  = 3'b010,
    sltu = 3'b011,
    axor = 3'b100,
    sr   = 3'b101, //check bit30 for logical/arithmetic
    aor  = 3'b110,
    aand = 3'b111
} arith_funct3_t;

typedef enum bit [3:0] {
    alu_add = 4'b0000,
    alu_sll = 4'b0001,
    alu_sra = 4'b0010,
    alu_sub = 4'b0011,
    alu_xor = 4'b0100,
    alu_srl = 4'b0101,
    alu_or  = 4'b0110,
    alu_and = 4'b0111,
    alu_pc  = 4'b1000,
    alu_lui = 4'b1001,
    alu_slt = 4'b1010,
    alu_sltu = 4'b1011
} alu_ops;

typedef struct packed {
    logic [31:0]    pc;
    logic [31:0]    instr;
} ifid_fwd;

typedef struct packed {
    logic   [1:0]   wb;
    logic   [2:0]   m;
    logic   [2:0]   ex;
    logic   [31:0]  pc;
    logic   [4:0]   rs1;
    logic   [4:0]   rs2;
    rv32i_word      rs1_out;
    rv32i_word      rs2_out;
    logic   [31:0]  imm;
    logic   [3:0]   funct3;
    logic   [4:0]   rd_addr;
    rv32i_opcode    opcode;
    logic   [4:0]   rs1_addr;
    logic   [4:0]   rs2_addr;
    } idex_fwd;

typedef struct packed {
    logic   [1:0]   wb;
    logic   [2:0]   m;
    logic   [31:0]  pc;
    logic           zero;
    rv32i_word      alu_result;
    rv32i_word      rs2_out;
    logic   [4:0]   rd_addr;
    logic   [31:0]  imm;
    logic   [2:0]   funct3;    
} exmem_fwd;

typedef struct packed{
    logic   [1:0]   wb;
    rv32i_word      alu_result;
    logic   [4:0]   rd_addr;
    logic   [31:0]  imm;
    logic   [2:0]   funct3;
    logic   [31:0]  read_data;
    logic   [255:0] line;
} memwb_fwd;

typedef struct packed{
    logic   [31:0]  mem_address;
    logic           mem_read;
    logic           mem_write;
    logic   [31:0]  mem_byte_enable;
    logic   [255:0] mem_wdata;
    logic   [3:0]   set;
    logic   [23:0]  tag;
} caac_fwd;

typedef struct packed{            
            logic           monitor_valid;
            logic   [63:0]  monitor_order;
            logic   [31:0]  monitor_inst;
            logic   [4:0]   monitor_rs1_addr;
            logic   [4:0]   monitor_rs2_addr;
            logic   [31:0]  monitor_rs1_rdata;
            logic   [31:0]  monitor_rs2_rdata;
            logic   [4:0]   monitor_rd_addr;
            logic   [31:0]  monitor_rd_wdata;
            logic   [31:0]  monitor_pc_rdata;
            logic   [31:0]  monitor_pc_wdata;
            logic   [31:0]  monitor_mem_addr;
            logic   [3:0]   monitor_mem_rmask;
            logic   [3:0]   monitor_mem_wmask;
            logic   [31:0]  monitor_mem_rdata;
            logic   [31:0]  monitor_mem_wdata;
} rvfi_signals_fwd;

endpackage : types