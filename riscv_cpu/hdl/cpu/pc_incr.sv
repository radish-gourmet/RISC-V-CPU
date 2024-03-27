module pc_imm
import types::*;
(
    //input alu_ops aluop, Commenting out because it's only one operation
    input [31:0] pc, imm_gen,
    output logic [31:0] f
);

always_comb
begin
    f = pc + (imm_gen<<1); ///shifting left by 1, based on Fig 4.49, Pg 569
end

endmodule : pc_imm