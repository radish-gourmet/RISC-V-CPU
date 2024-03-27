module mp4
import types::*;
(
    input   logic           clk,
    input   logic           rst,

    // Use these for CP1 (magic memory)
    // output  logic   [31:0]  imem_address,
    // output  logic           imem_read,      ///// Not being read
    // input   logic   [31:0]  imem_rdata,
    // input   logic           imem_resp,     /////// Imem Resp not being used
    // output  logic   [31:0]  dmem_address,
    // output  logic           dmem_read,
    // output  logic           dmem_write,
    // output  logic   [3:0]   dmem_wmask,
    // input   logic   [31:0]  dmem_rdata,
    // output  logic   [31:0]  dmem_wdata,
    // input   logic           dmem_resp

    // Use these for CP2+ (with caches and burst memory)
    output  logic   [31:0]  bmem_address,
    output  logic           bmem_read,
    output  logic           bmem_write,
    input   logic   [63:0]  bmem_rdata,
    output  logic   [63:0]  bmem_wdata,
    input   logic           bmem_resp
);

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
            logic   [31:0]  addr_in;
            rvfi_signals_fwd rvfi_cpu_out;

cpu cpu(.*);
// TODO: max check if wildcard assings still work or if we need explicit port hookup

/*--CPU <=> Cache wires (signals that bypass data adaptor)--------------*/

    // I-section
    logic imem_resp;
    logic imem_read;
    logic imem_write;
    logic [31:0] imem_address; 
    // NOTE: shared with BUS

    // D-section
    logic dmem_resp;
    logic dmem_read;
    logic dmem_write;
    logic [31:0] dmem_address;
    // NOTE: shared with BUS

/*----------------------------------------------------------------------*/

/*--CPU <=> Bus wires---------------------------------------------------*/

    // I-Section
    // logic [31:0] imem_address; 
    // NOTE: shared with CACHE
    logic [31:0] imem_wdata;
    logic [31:0] imem_rdata;
    logic [3:0] imem_wmask;

    // D-Section
    // logic [31:0] dmem_address; 
    // NOTE: shared with CACHE
    logic [31:0] dmem_wdata;
    logic [31:0] dmem_rdata;
    logic [3:0] dmem_wmask;

/*----------------------------------------------------------------------*/

/*--Bus <=> Cache wires-------------------------------------------------*/

    // I-section
    logic [255:0] ibus_wdata256;
    logic [255:0] ibus_rdata256;
    logic [31:0] ibus_mem_byte_enable_256;

    // D-section
    logic [255:0] dbus_wdata256;
    logic [255:0] dbus_rdata256;
    logic [31:0] dbus_mem_byte_enable_256;

/*----------------------------------------------------------------------*/

/*--Cache <=> Arbiter wires---------------------------------------------*/

    // I-Cache
    logic [31:0] iaddress;
    logic [255:0] iline_i;
    logic iread;
    logic iwrite;
    logic [255:0] iline_o;
    logic iresp;

    // D-Cache
    logic [31:0] daddress;
    logic [255:0] dline_i;
    logic dread;
    logic dwrite;
    logic [255:0] dline_o;
    logic dresp;

    logic   [255:0] line_i;
    logic   [255:0] line_o;
    logic   [31:0]  address_i;
    logic           read_i;
    logic           write_i;
    logic           resp_o;

/*----------------------------------------------------------------------*/

/*--BUS ADAPTER---------------------------------------------------------*/

    // I-ADAPTOR
    bus_adapter i_bus(
        .address                (imem_address               ), // from cpu      // ***
        .mem_wdata256           (ibus_wdata256              ), // to cache
        .mem_rdata256           (ibus_rdata256              ), // from cache
        .mem_wdata              (imem_wdata                 ), // from cpu      // ***
        .mem_rdata              (imem_rdata                 ), // to cpu        // ***
        .mem_byte_enable        (imem_wmask                 ), // from cpu      // ***
        .mem_byte_enable256     (ibus_mem_byte_enable_256   )  // to cache
    );

    // D-ADAPTOR
    bus_adapter d_bus(
        .address                (dmem_address               ), // same as I-bus // ***
        .mem_wdata256           (dbus_wdata256              ),
        .mem_rdata256           (dbus_rdata256              ),
        .mem_wdata              (dmem_wdata                 ),                  // ***
        .mem_rdata              (dmem_rdata                 ),                  // ***
        .mem_byte_enable        (dmem_wmask                 ),                  // ***
        .mem_byte_enable256     (dbus_mem_byte_enable_256   )
    );

/*----------------------------------------------------------------------*/

/*--CACHES--------------------------------------------------------------*/

    // I-CACHE
    cache i_cache(
        .clk                (clk                        ),
        .rst                (rst                        ),

        // CPU signals
        .mem_address        (imem_address               ), // from CPU          // ***
        .mem_read           (imem_read                  ), // from CPU          // ***
        .mem_write          (imem_write                 ), // from CPU          // ***
        .mem_byte_enable    (ibus_mem_byte_enable_256   ), // from BUS
        .mem_rdata          (ibus_rdata256              ), // to BUS
        .mem_wdata          (ibus_wdata256              ), // from BUS
        .mem_resp           (imem_resp                  ), // to CPU            // ***

        // Arbiter signals
        .pmem_address       (iaddress   ), // to arbiter
        .pmem_read          (iread      ), // to arbiter
        .pmem_write         (iwrite     ), // to arbiter
        .pmem_rdata         (iline_o    ), // from arbiter
        .pmem_wdata         (iline_i    ), // to arbiter
        .pmem_resp          (iresp      )  // from arbiter
    );

    // D_CACHE
    ff_cache d_cache(
        .clk                (clk                        ),
        .rst                (rst                        ),

        // CPU signals
        .mem_address        (dmem_address               ), // same as i_cache   // ***
        .mem_read           (dmem_read                  ),                      // ***
        .mem_write          (dmem_write                 ),                      // ***
        .mem_byte_enable    (dbus_mem_byte_enable_256   ),
        .mem_rdata          (dbus_rdata256              ),
        .mem_wdata          (dbus_wdata256              ),
        .mem_resp           (dmem_resp                  ),                      // ***

        // Arbiter signals
        .pmem_address       (daddress   ), // same as i_cache
        .pmem_read          (dread      ),
        .pmem_write         (dwrite     ),
        .pmem_rdata         (dline_o    ),
        .pmem_wdata         (dline_i    ),
        .pmem_resp          (dresp      )
    );

/*----------------------------------------------------------------------*/

/*--ARBITER-------------------------------------------------------------*/

arbiter arbiter(
    .clk            (clk        ),
    .rst            (rst        ),

    .iline_i        (iline_i    ), // from cache
    .iaddress       (iaddress   ), // from cache
    .iread_i        (iread      ), // from cache
    .iwrite_i       (iwrite     ), // from cache
    .iline_o        (iline_o    ), // to cache
    .iresp_o        (iresp      ), // to cache

    .dline_i        (dline_i    ), // same as instr side
    .daddress_i     (daddress   ),
    .dread_i        (dread      ),
    .dwrite_i       (dwrite     ),
    .dline_o        (dline_o    ),
    .dresp_o        (dresp      ),

    //From arbiter to the cache-line
    .line_i         (line_i),
    .line_o         (line_o),
    .address_i      (address_i),
    .read_i         (read_i),
    .write_i        (write_i),
    .resp_o         (resp_o)
);

/*----------------------------------------------------------------------*/

/*--CACHE-LINE ARBITER-------------------------------------------------------------*/

cacheline_adaptor cacheline_adaptor(
    .clk        (clk),
    .rst        (rst),
    .line_i     (line_i),
    .line_o     (line_o),
    .address_i  (address_i),
    .read_i     (read_i),
    .write_i    (write_i),
    .resp_o     (resp_o),
    .burst_i    (bmem_rdata),
    .burst_o    (bmem_wdata),
    .address_o  (bmem_address),
    .read_o     (bmem_read),
    .write_o    (bmem_write),
    .resp_i     (bmem_resp)
);

/*----------------------------------------------------------------------*/


    // Fill this out
    // Only use hierarchical references here for verification
    // **DO NOT** use hierarchical references in the actual design!
    assign monitor_valid     = rvfi_cpu_out.monitor_valid;
    assign monitor_order     = rvfi_cpu_out.monitor_order;
    assign monitor_inst      = rvfi_cpu_out.monitor_inst;
    assign monitor_rs1_addr  = rvfi_cpu_out.monitor_rs1_addr;
    assign monitor_rs2_addr  = rvfi_cpu_out.monitor_rs2_addr;
    assign monitor_rs1_rdata = rvfi_cpu_out.monitor_rs1_rdata;
    assign monitor_rs2_rdata = rvfi_cpu_out.monitor_rs2_rdata;
    assign monitor_rd_addr   = rvfi_cpu_out.monitor_rd_addr;
    assign monitor_rd_wdata  = rvfi_cpu_out.monitor_rd_wdata;
    assign monitor_pc_rdata  = rvfi_cpu_out.monitor_pc_rdata;
    assign monitor_pc_wdata  = rvfi_cpu_out.monitor_pc_wdata;
    assign monitor_mem_addr  = rvfi_cpu_out.monitor_mem_addr;
    assign monitor_mem_rmask = rvfi_cpu_out.monitor_mem_rmask;
    assign monitor_mem_wmask = rvfi_cpu_out.monitor_mem_wmask;
    assign monitor_mem_rdata = rvfi_cpu_out.monitor_mem_rdata;
    assign monitor_mem_wdata = rvfi_cpu_out.monitor_mem_wdata;

endmodule : mp4
