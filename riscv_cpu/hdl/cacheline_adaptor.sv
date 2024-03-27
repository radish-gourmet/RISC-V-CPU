module cacheline_adaptor
(
    input clk,
    input rst,

    // Port to LLC (Lowest Level Cache)
    input logic [255:0] line_i,
    output logic [255:0] line_o,
    input logic [31:0] address_i,
    input read_i,
    input write_i,
    output logic resp_o,

    // Port to memory
    input logic [63:0] burst_i,
    output logic [63:0] burst_o,
    output logic [31:0] address_o,
    output logic read_o,
    output logic write_o,
    input resp_i
);
    logic [7:0] state_counter;
    always_ff @(posedge clk)
    begin
        if(rst)
        begin
	    read_o=0;
	    write_o=0;
            state_counter =0;
        end
        else
        begin
            case(state_counter)
                0:
                begin
                    if(read_i == 1)
                    begin
                        read_o =1;
                        write_o=0;
                        address_o = address_i;
                        if(resp_i)
                        begin
                          state_counter=2;
                          line_o[63:0] = burst_i;
                        end
                        else
                          state_counter =1;
                    end
                    else if (write_i ==1)
                    begin
                        read_o = 1'b0;
                        write_o = 1'b1;
                        address_o = address_i;
                        state_counter = 6;
                        burst_o = line_i[63:0];
                    end
                end
                1:
                begin
                    if(resp_i == 1)
                    begin
                        line_o[63:0] = burst_i;
                        state_counter=2;
                    end
                end
                2:
                begin
                    if(resp_i == 1)
                    begin
                        line_o[127:64] = burst_i;
                        state_counter=3;
                    end
                end
                3:
                begin
                    if(resp_i == 1)
                    begin
                        line_o[191:128] = burst_i;
                        state_counter=4;
                    end
                end
                4:
                begin
                    if(resp_i ==1)
                    begin
                        line_o[255:192] = burst_i;
                        //line_o = address_i+33;
						state_counter=5;
                        resp_o =1;
						read_o=0;
                    end
                end
                5:
                begin
                    state_counter=0;
                    resp_o=0;
                    read_o=0;
                end
                6:
                begin
                    if(resp_i==1)
                      begin
                          burst_o = line_i[63:0];
                          state_counter=7;
                      end
                end
                7:
                begin
                    if(resp_i==1)
                      begin
                          burst_o = line_i[127:64];
                          state_counter=8;
                      end
                end
                8:
                begin
                    if(resp_i==1)
                      begin
                          burst_o = line_i[191:128];
                          state_counter=9;
                      end
                end
                9:
                begin
                    if(resp_i==1)
                      begin
                          burst_o = line_i[255:192];
                          resp_o = 1;
                          state_counter=10;
						  write_o=0;
                      end
                end
                10:
                begin
                          write_o =0;
                          resp_o=0;
                          state_counter=0;
                end
		default:
		begin
			read_o =0;
			write_o =0;
		end
            endcase
        end
    end

endmodule : cacheline_adaptor