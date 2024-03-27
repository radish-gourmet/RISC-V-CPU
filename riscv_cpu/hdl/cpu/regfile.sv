module regfile
import types::*;
(
    input clk,
    input rst,
    input load,
    input [31:0] in,
    input [4:0] src_a, src_b, dest,
    output logic [31:0] reg_a, reg_b
);

logic [31:0] data [32];
// 32 regs each with 32 bits of data

always_ff @(posedge clk) begin : reg_update
    
    if (rst)
    begin
        for (int i=0; i<32; i=i+1) begin
            data[i] <= '0; // clear data
        end
    end
    else if (load && dest)
    begin
        data[dest] <= in; // load new data at dest
    end

end
always_comb begin : reg_output
    reg_a = src_a ? data[src_a] : 0;
    reg_b = src_b ? data[src_b] : 0;
end

endmodule : regfile