module forward_module
import types::*;
(
    input  logic [4:0] mem_wb_rd,
    input  logic mem_wb_regwrite,
    input  logic ex_mem_regwrite,
    input  logic [4:0] ex_mem_rd,
    input  logic [4:0] id_ex_rs1_addr,
    input  logic [4:0] id_ex_rs2_addr,
    output logic [1:0] ForwardB_sel,
    output logic [1:0] ForwardA_sel
); ///////////////// TODO: Nitish do change the register Address width
always_comb begin
    if((ex_mem_regwrite) && (ex_mem_rd!=0)) begin
        if(ex_mem_rd == id_ex_rs1_addr) ForwardA_sel = 2'b10;
        else ForwardA_sel = 2'b0;
        if(ex_mem_rd == id_ex_rs2_addr) ForwardB_sel = 2'b10;
        else ForwardB_sel = 2'b0;
    end else begin
        ForwardA_sel = 2'b0;
        ForwardB_sel = 2'b0;
    end
    if((mem_wb_regwrite) && (mem_wb_rd !=0)) begin
        if(!(((ex_mem_regwrite) && (ex_mem_rd!=0)) && (ex_mem_rd == id_ex_rs1_addr))) begin
            if(mem_wb_rd == id_ex_rs1_addr) ForwardA_sel = 2'b01;
        end
        if(!(((ex_mem_regwrite) && (ex_mem_rd!=0)) && (ex_mem_rd == id_ex_rs2_addr))) begin
            if(mem_wb_rd == id_ex_rs2_addr) ForwardB_sel = 2'b01;
        end
    end

end
endmodule