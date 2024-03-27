module cpu
import types::*; // NOTE: leave this as types, just "types" does not work
(
    // CP1 I/O

    /*
    
    input   clk,
    input   rst,
    input   logic               imem_resp,    
    input   logic       [31:0]  imem_rdata,
    input   rv32i_word          dmem_rdata,
    output  logic       [31:0]  imem_address,
    output  logic               imem_read,
    output  logic               dmem_read,
    output  logic               dmem_write,
    output  rv32i_word          dmem_address,
    output  logic       [3:0]   dmem_wmask,
    output  rv32i_word          dmem_wdata,
    input   logic               dmem_resp,
    output rvfi_signals_fwd     rvfi_cpu_out

    */

    // possible new I/O, prune useless ports as needed

    input clk,
    input rst,

    input   logic               imem_resp,
    output  logic               imem_read,
    output  logic               imem_write,
    output  logic       [31:0]  imem_address,
    input   logic       [31:0]  addr_in,

    output  logic       [31:0]  imem_wdata,
    input   logic       [31:0]  imem_rdata,
    output  logic       [3:0]   imem_wmask,

    input   logic               dmem_resp,
    output  logic               dmem_read,
    output  logic               dmem_write,
    output  logic       [31:0]  dmem_address,

    output  logic       [31:0]  dmem_wdata,
    input   logic       [31:0]  dmem_rdata,
    output  logic       [3:0]   dmem_wmask,

    output  rvfi_signals_fwd    rvfi_cpu_out

);

assign imem_write = 1'b0;
assign imem_wdata = '0;
assign imem_wmask = '0;

//Local variables
logic               reg_write;
logic       [4:0]   rd_addr;
rv32i_word          rd_data;
logic       [31:0]  counter;/////// Using counter to populate the order of the instruction. We increment counter everytime we see 
logic               pc_write;
logic               ifid_write;
logic               is_load;
logic               control_mux_switch_dec,control_mux_switch_dec_next,control_mux_switch_ex,control_mux_switch_ex_next,control_mux_switch_mem,control_mux_switch_mem_next,control_mux_switch_wb ;
logic               dside_stall_n;
logic               control_mux_switch_wb_next;
logic               is_branching_decode;//// Bit used for sending signal to flush instr in Dec if there's a branch.
logic               is_branching_fetch;//// Bit used for sending signal to flush instr in Fetch if there's a branch
logic               is_branching_fetch_to_decode;
logic               is_branching_fetch_to_decode_next;
logic    [31:0]     pc_out;
logic               istall_n;
logic               br_bubble_n;
//Struct Variables
ifid_fwd    ifid, next_ifid;
idex_fwd    idex, next_idex;
exmem_fwd   exmem, next_exmem;
memwb_fwd   memwb, next_memwb;
rvfi_signals_fwd rvfi_ifid, rvfi_ifid_next, rvfi_idex,rvfi_idex_next, rvfi_exmem,rvfi_exmem_next,rvfi_memwb,rvfi_memwb_next;


//Instantiate modules here
fetch FET (
    .clk            (clk                ),
    .rst            (rst                ),
    .imem_resp      (imem_resp          ),
    .imem_address   (imem_address       ),
    .br_bubble_n    (br_bubble_n        ),
    .ifid_out       (next_ifid          ),
    .pc_src         (is_branching_fetch ),
    .pc_write       (pc_write           ),
    .is_branching_fetch(is_branching_fetch),
    .exmem_pc       (pc_out             ),
    .imem_read      (imem_read          ),
    .imem_rdata     (imem_rdata         ),
    .rvfi_ifid      (rvfi_ifid_next     ),
    .dside_stall_n  (dside_stall_n      ),
    .istall_n       (istall_n           ),
    .addr_in        (addr_in            )
);

decode DEC(
    .clk        (clk            ),
    .rst        (rst            ),
    .ifid_i     (ifid           ),
    .rvfi_ifid_i(rvfi_ifid      ),
    .idex_mem_rd(idex.m[1]      ),
    .rd_addr    (rd_addr        ),
    .rd_data    (rd_data        ),
    .reg_write  (reg_write      ),
    .idex_rd    (idex.rd_addr   ),
    .is_branching(is_branching_decode),
    .ifid_write (ifid_write     ),
    .pc_write   (pc_write       ),
    .idex_o     (next_idex      ),
    .control_mux_switch_ex_next(control_mux_switch_ex_next),
    .rvfi_idex_o(rvfi_idex_next),
    .dside_stall_n(dside_stall_n),
    .istall_n       (istall_n   ),
    .br_bubble_n    (br_bubble_n)
);

execute EX(
    .clk    (clk                        ),
    .rst    (rst                        ),
    .idex   (idex                       ),
    .rvfi_idex_i(rvfi_idex              ),
    .mem_wb_rd(memwb.rd_addr            ),
    .mem_wb_regwrite(memwb.wb[1]        ),
    .ex_mem_regwrite(exmem.wb[1]        ),
    .ex_mem_rd(exmem.rd_addr            ),
    .exmem_alu_result(exmem.alu_result  ),
    .mem_wb_mux_d_out(rd_data           ),
    .control_mux_switch_ex(control_mux_switch_ex),
    .control_mux_switch_mem_next(control_mux_switch_mem_next),
    .exmem  (next_exmem                 ),
    .rvfi_exmem_o(rvfi_exmem_next       ),
    .is_branching_decode(is_branching_decode),
    .is_branching_fetch(is_branching_fetch),
    .dside_stall_n(dside_stall_n        ),
    .pc_out(pc_out                         ),
    .istall_n       (istall_n           )
);

memory_stage MEM (
    .clk                    (clk                ),
    .rst                    (rst                ),
    .exmem                  (exmem              ),
    .rvfi_exmem_i           (rvfi_exmem         ),
    .memwb_rdata            (rd_data            ),
    .reg_write              (reg_write          ),
    .is_load                (is_load            ),
    .wb_rd_addr             (rd_addr            ),
    .dmem_resp              (dmem_resp          ),
    .dmem_rdata             (dmem_rdata         ),
    .control_mux_switch_mem (control_mux_switch_mem),
    .control_mux_switch_wb_next(control_mux_switch_wb_next),
    .dmem_address           (dmem_address       ),
    .dmem_read              (dmem_read          ),
    .dmem_write             (dmem_write         ),
    .dmem_wdata             (dmem_wdata         ),
    .dmem_wmask             (dmem_wmask         ),
    .istall_n               (istall_n           ),
    .memwb                  (next_memwb         ),
    .rvfi_memwb_o           (rvfi_memwb_next    ),
    .dside_stall_n          (dside_stall_n      )
);

write_back WB (
    .clk(clk),
    .rst(rst),
    .memwb_i(memwb),
    .rvfi_memwb_i(rvfi_memwb),
    .control_mux_switch_wb(control_mux_switch_wb),
    .dside_stall_n(dside_stall_n),
    .reg_write(reg_write),
    .rd_addr(rd_addr),
    .counter(counter),
    .reg_wdata(rd_data),
    .is_load(is_load),
    .rvfi_cpu_out(rvfi_cpu_out),
    .istall_n       (istall_n)
);

always_ff @(posedge clk) begin
    if(rst) begin
        ifid    <= '0;
        idex    <= '0;
        exmem   <= '0;
        memwb   <= '0;
        rvfi_ifid <= '0;
        rvfi_idex <= '0;
        rvfi_exmem <= '0;
        rvfi_memwb <= '0;
        control_mux_switch_ex <= '0;
        control_mux_switch_mem <= '0;
        control_mux_switch_wb <= '0;
        is_branching_fetch_to_decode <= '0;

    end
    else begin
        if(dside_stall_n && istall_n) begin
            ifid        <= ifid_write ? next_ifid : ifid;
            control_mux_switch_ex <= control_mux_switch_ex_next;
            control_mux_switch_mem <= control_mux_switch_mem_next;
            control_mux_switch_wb <= control_mux_switch_wb_next;
            is_branching_fetch_to_decode <= is_branching_fetch_to_decode_next;
            idex        <= next_idex;
            exmem       <= next_exmem;
            memwb       <= next_memwb;
        end
        if(dside_stall_n && istall_n) begin
            rvfi_ifid   <= ifid_write ? rvfi_ifid_next : rvfi_ifid;
            rvfi_idex   <= rvfi_idex_next;
            rvfi_exmem  <= rvfi_exmem_next;
            rvfi_memwb  <= rvfi_memwb_next;
        end
        // else begin
        //     ifid        <= ifid;
        //     rvfi_ifid   <= rvfi_ifid;
        //     rvfi_idex   <= rvfi_idex;
        //     rvfi_exmem  <= rvfi_exmem;
        //     rvfi_memwb  <= rvfi_memwb;
        //     control_mux_switch_ex <= control_mux_switch_ex;
        //     control_mux_switch_mem <= control_mux_switch_mem;
        //     control_mux_switch_wb <= control_mux_switch_wb;
        //     is_branching_fetch_to_decode <= is_branching_fetch_to_decode;
        //     idex        <= idex;
        //     exmem       <= exmem;
        //     memwb       <= memwb;
        // end
    end
end

endmodule : cpu