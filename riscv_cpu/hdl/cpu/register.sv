module register
import types::*;
(
    input clk,
    input rst,
    input load,
    input [31:0] data_in,
    output logic [31:0] data_out
);

logic [31:0] reg_data;

always_ff @( posedge clk ) begin : reg_update
    if (rst) begin
        reg_data <= 32'h4000_0000;
    end else if (load) begin
        reg_data <= data_in;
    end
end : reg_update

always_comb begin
    data_out = reg_data;
end

endmodule : register