module cmp
import types::*;
(
    input branch_funct3_t cmpop,
    input rv32i_word cmp_a, cmp_b,
    output logic cmp_o
);

always_comb
begin
    unique case (cmpop)
        beq:  cmp_o = (cmp_a == cmp_b);
        bne:  cmp_o = (cmp_a != cmp_b);
        blt:  cmp_o = ($signed(cmp_a) < $signed(cmp_b));
        bge:  cmp_o = ($signed(cmp_a) >= $signed(cmp_b));
        bltu: cmp_o = (cmp_a < cmp_b);
        bgeu: cmp_o = (cmp_a >= cmp_b);
        default: cmp_o = 1'b0;
    endcase
end

endmodule : cmp