`timescale 1ns/1ns;

module cache_dut_tb ();


    /* CPU side signals */
      logic   [31:0]  mem_address;
      logic           mem_read;
      logic           mem_write;
      logic   [31:0]  mem_byte_enable;
      logic   [255:0] mem_rdata;
      logic   [255:0] mem_wdata;
      logic           mem_resp;
    /* Memory side signals */
      logic   [31:0]  pmem_address;
      logic           pmem_read;
      logic           pmem_write;
      logic   [255:0] pmem_rdata;
      logic   [255:0] pmem_wdata;
      logic           pmem_resp;


    //----------------------------------------------------------------------
    // Waveforms.
    //----------------------------------------------------------------------
    initial begin
        $fsdbDumpfile("dump.fsdb");
        $fsdbDumpvars(0, "+all");
    end

    //----------------------------------------------------------------------
    // Generate the clock.
    //----------------------------------------------------------------------
    bit clk;
    initial clk = 1'b0;
    always #1 clk = ~clk;

    //----------------------------------------------------------------------
    // Generate the reset.
    //----------------------------------------------------------------------
    bit rst;
    task do_reset();
        rst <= 1'b1;
        repeat(5)
            @(posedge clk);
        rst <= 1'b0;
    endtask : do_reset

    //----------------------------------------------------------------------
    // Collect coverage here:
    //----------------------------------------------------------------------
    // covergroup cache_cg with function sample(...)
    //     // Fill this out!
    // endgroup
    // Note that you will need the covergroup to get `make covrep_dut` working.

    //----------------------------------------------------------------------
    // Want constrained random classes? Do that here:
    //----------------------------------------------------------------------
     class RandAddr;
        rand bit [31:0] addr;
        constraint fixed_set {addr[8:5] == 4'h4;}
        constraint fixed_tag {addr[31:9] == 23'hFF;}

    endclass : RandAddr

    //----------------------------------------------------------------------
    // Instantiate your DUT here.
    //----------------------------------------------------------------------
    cache dut (.*);

    //----------------------------------------------------------------------
    // Write your tests and run them here!
    //----------------------------------------------------------------------
    // Recommended: package your tests into tasks.

    logic [7:0] counter;
    integer wr_var;

    task constant_set(int num_reqs);
        RandAddr rand_addr;
        rand_addr = new();
            repeat(num_reqs) begin
                mem_read <= 1'b0;
                @(posedge clk);
                rand_addr.fixed_set.constraint_mode(1);
                rand_addr.fixed_tag.constraint_mode(0);
                rand_addr.randomize();
                mem_address <= rand_addr.addr;
                mem_read <= 1'b1;
                @(posedge clk iff (mem_resp));
                mem_read <= 1'b0;
            end
    endtask

    task constant_tag(int num_reqs);
        RandAddr rand_addr;
        rand_addr = new();
            repeat(num_reqs) begin
                mem_read <= 1'b0;
                @(posedge clk);
                rand_addr.fixed_set.constraint_mode(0);
                rand_addr.fixed_tag.constraint_mode(1);
                rand_addr.randomize();
                mem_address <= rand_addr.addr;
                mem_read <= 1'b1;
                @(posedge clk iff (mem_resp));
                mem_read <= 1'b0;
            end
    endtask

    task constant_set_and_tag(int num_reqs);
        RandAddr rand_addr;
        rand_addr = new();
        repeat(num_reqs) begin
            mem_read <= 1'b0;
            @(posedge clk);
            rand_addr.fixed_set.constraint_mode(1);
            rand_addr.fixed_tag.constraint_mode(1);
            rand_addr.randomize();
            mem_address <= rand_addr.addr;
            mem_read <= 1'b1;
            @(posedge clk iff (mem_resp));
            mem_read <= 1'b0;
        end
    endtask

    task write_requests(int num_reqs);
        RandAddr rand_addr;
        rand_addr = new();
        repeat(num_reqs) begin
            //mem_write <= 1'b0;
            @(posedge clk);
            rand_addr.fixed_set.constraint_mode(1);     //Keeps the line dirty
            rand_addr.fixed_tag.constraint_mode(0);     //Causes dirty line evictions
            rand_addr.randomize();
            mem_address <= rand_addr.addr;
            mem_wdata <= $urandom_range(0, 10);
            mem_byte_enable <= 32'hffffffff;
            mem_write <= 1'b0;
            @(posedge mem_resp);
        end
    endtask

    task directed();
        mem_byte_enable <= 32'hffffffff;

        //Fetch from memory
        //Load set-0 way-0 read-0
        mem_address     <= 32'h200;
        pmem_rdata      <= 256'h0;
        mem_read        <= 1'b1;
        @(posedge clk iff (mem_resp));
        mem_read        <= 1'b0;
        @(posedge clk iff (counter));

        //Load set-0 way-2 read-1
        mem_address     <= 32'h220;
        pmem_rdata      <= 32'h1;
        mem_read        <= 1'b1;
        @(posedge clk iff (mem_resp));
        mem_read        <= 1'b0;
        @(posedge clk iff (counter));

        //Load set-0 way-1 read-2
        mem_address     <= 32'h240;
        pmem_rdata      <= 32'h2;
        mem_read        <= 1'b1;
        @(posedge clk iff (mem_resp));
        mem_read        <= 1'b0;
        @(posedge clk iff (counter));

        //Load set-0 way-3 read-3
        mem_address     <= 32'h260;
        pmem_rdata      <= 32'h3;
        mem_read        <= 1'b1;
        @(posedge clk iff (mem_resp));
        mem_read        <= 1'b0;
        @(posedge clk iff (counter));

        //Cache hits
        //Load set-0 way-0 read-0
        mem_address     <= 32'h200;
        pmem_rdata      <= 256'h0;
        mem_read        <= 1'b1;
        @(posedge clk iff (mem_resp));
        //mem_read        <= 1'b0;
        @(posedge clk iff (counter));

        //Load set-0 way-2 read-1
        mem_address     <= 32'h220;
        pmem_rdata      <= 32'h1;
        mem_read        <= 1'b1;
        @(posedge clk iff (mem_resp));
        //mem_read        <= 1'b0;
        @(posedge clk iff (counter));

        //Load set-0 way-1 read-2
        mem_address     <= 32'h240;
        pmem_rdata      <= 32'h2;
        mem_read        <= 1'b1;
        @(posedge clk iff (mem_resp));
        //mem_read        <= 1'b0;
        @(posedge clk iff (counter));

        //Load set-0 way-3 read-3
        mem_address     <= 32'h260;
        pmem_rdata      <= 32'h3;
        mem_read        <= 1'b1;
        @(posedge clk iff (mem_resp));
        mem_read        <= 1'b0;
        @(posedge clk iff (counter));

        //Writes making cache-lines dirty
        //set-0 way-0 write-ab
        mem_address     <= 32'h200;
        mem_wdata       <= 32'haa;
        mem_write        <= 1'b0;
        @(posedge clk iff (mem_resp));
        mem_write        <= 1'b0;
        @(posedge clk iff (counter));

        //set-1 way-0 write-cd
        mem_address     <= 32'h220;
        mem_wdata       <= 32'hbb;
        mem_write        <= 1'b0;
        @(posedge clk iff (mem_resp));
        mem_write        <= 1'b0;
        @(posedge clk iff (counter));

        //set-2 way-0 write-ef
        mem_address     <= 32'h240;
        mem_wdata       <= 32'hcc;
        mem_write        <= 1'b0;
        @(posedge clk iff (mem_resp));
        mem_write        <= 1'b0;
        @(posedge clk iff (counter));

        //set-2 way-0 write-ef
        mem_address     <= 32'h260;
        mem_wdata       <= 32'hdd;
        mem_write        <= 1'b0;
        @(posedge clk iff (mem_resp));
        mem_write        <= 1'b0;
        @(posedge clk iff (counter));

        //set-2 way-0 write-ef
        mem_address     <= 32'h270;
        mem_wdata       <= 32'hee;
        mem_write        <= 1'b0;
        @(posedge clk iff (mem_resp));
        mem_write        <= 1'b0;
        @(posedge clk iff (counter));

        //Writes causing write back, evicting lines
        //set-0 way-0 write-ab
        mem_address     <= 32'h1200;
        mem_wdata       <= 32'hff;
        mem_write        <= 1'b0;
        @(posedge clk iff (mem_resp));
        mem_write        <= 1'b0;
        @(posedge clk iff (counter));

        //set-0 way-2 write-cd
        mem_address     <= 32'h1400;
        mem_wdata       <= 32'hff;
        mem_write        <= 1'b0;
        @(posedge clk iff (mem_resp));
        mem_write        <= 1'b0;
        @(posedge clk iff (counter));

        //set-0 way-1 write-ef
        mem_address     <= 32'h1800;
        mem_wdata       <= 32'hffff;
        mem_write        <= 1'b0;
        @(posedge clk iff (mem_resp));
        mem_write        <= 1'b0;
        @(posedge clk iff (counter));


    endtask

    initial begin
        mem_read = 1'b0;
        mem_write = 1'b0;
        wr_var = 0;
        counter = 0;
        do_reset();
        //constant_set(6);
        //constant_tag(8);
        //constant_set_and_tag(8);
        //write_requests(8);
        directed();
        $finish;
    end

    //----------------------------------------------------------------------
    // You likely want a process for pmem responses, like this:
    //----------------------------------------------------------------------

    always @(posedge clk) begin
        counter = counter + 1;
    end
    
    always @(posedge clk) begin
        if(pmem_read == 1'b1) begin
            //@(posedge clk);
            //pmem_rdata <= wr_var;
            wr_var <= wr_var + 1;
            if(counter %4 == 0)
                pmem_resp  <= 1'b1;
            else
                pmem_resp  <= 1'b0;
        end
        else if(pmem_write == 1'b1) begin
            if(counter %4 == 0)
                pmem_resp  <= 1'b1;
            else
                pmem_resp  <= 1'b0;
        end
    //     // Set pmem signals here to behaviorally model physical memory.
    end


endmodule