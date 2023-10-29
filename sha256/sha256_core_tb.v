`timescale 1 ns / 1 ps

module sha256_core_tb();

    /* constant and parameter definitions */
    parameter CLK_HALF_PERIOD = 2;
    parameter CLK_PERIOD = 2 * CLK_HALF_PERIOD;

    parameter MODE_SHA_256 = 1;

    /* register and wire declarations */
    reg [31 : 0] error_ctr;
    reg [31 : 0] tc_ctr;

	/* uut inputs */
    reg            clk_tb;
    reg            reset_n_tb;
    reg            init_tb;
    reg            next_tb;
    reg            mode_tb;
    
    reg [511 : 0]  block_tb;

    /* uut outputs */
    wire           ready_tb;
    wire [255 : 0] digest_tb;
    wire           digest_valid_tb;


    /* unit under test */
    sha256_core uut (
        .clk            (clk_tb),
        .reset_n        (reset_n_tb),

        .init           (init_tb),
        .next           (next_tb),
        .mode           (mode_tb),
        .block          (block_tb),

        .ready          (ready_tb),
        .digest         (digest_tb),
        .digest_valid   (digest_valid_tb)
    );


    /* clock generator */
    always begin
        #CLK_HALF_PERIOD;
        clk_tb = !clk_tb;
    end


    /* toggle reset */
    task reset;
        begin
        reset_n_tb = 0;
        #(2 * CLK_PERIOD);
        reset_n_tb = 1;
        end
    endtask


    /* initialize all inputs to defined values */
    task init_inputs;
        begin
        error_ctr = 0;
        tc_ctr = 0;

        clk_tb = 0;
        reset_n_tb = 1;

        init_tb = 0;
        next_tb = 0;
        mode_tb = MODE_SHA_256;

        block_tb = 512'h00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
        end
    endtask 


    /* wait for the ready flag in the dut to be set */
    task wait_ready;
        begin
        while (!ready_tb)
            begin
            #(CLK_PERIOD);
            end
        end
    endtask



    /* single data block test case */
    task single_block_test(input [7 : 0]   tc_number,
                           input [511 : 0] block,
                           input [255 : 0] expected);
    begin
        tc_ctr = tc_ctr + 1;

        block_tb = block;
        init_tb = 1;
        #(CLK_PERIOD);
        init_tb = 0;
        wait_ready();

        if (digest_tb == expected)
        begin
            $display("*** test case %0d successful.", tc_number);
            $display("");
        end
        else
        begin
            $display("*** ERROR: test case %0d NOT successful.", tc_number);
            $display("");

            error_ctr = error_ctr + 1;
        end
    end
    endtask


    /* double data block test case */
    task double_block_test(input [7 : 0]   tc_number,
                           input [511 : 0] block1,
                           input [255 : 0] expected1,
                           input [511 : 0] block2,
                           input [255 : 0] expected2);

        reg [255 : 0] db_digest1;
        reg [255 : 0] db_digest2;
        reg           db_error;
    begin
        db_error = 0;
        tc_ctr = tc_ctr + 1;

        block_tb = block1;
        init_tb = 1;
        #(CLK_PERIOD);
        init_tb = 0;
        wait_ready();
        db_digest1 = digest_tb;

        block_tb = block2;
        next_tb = 1;
        #(CLK_PERIOD);
        next_tb = 0;
        wait_ready();
        db_digest2 = digest_tb;

        if (db_digest1 == expected1)
        begin
            $display("*** test case %0d first block successful", tc_number);
            $display("");
        end
        else
        begin
            $display("*** ERROR: test case %0d first block NOT successful", tc_number);
            $display("");

            db_error = 1;
        end

        if (db_digest2 == expected2)
        begin
            $display("*** test case %0d second block successful", tc_number);
            $display("");
        end
        else
        begin
            $display("*** ERROR: test case %0d second block NOT successful", tc_number);
            $display("");

            db_error = 1;
        end

        if (db_error)
        begin
            error_ctr = error_ctr + 1;
        end
    end
    endtask


    /* Test cases taken from:
       http://csrc.nist.gov/groups/ST/toolkit/documents/Examples/SHA256.pdf */
    task sha256_test;
        reg [511 : 0] tc1;
        reg [255 : 0] res1;
        reg [511 : 0] tc2_1;
        reg [255 : 0] res2_1;
        reg [511 : 0] tc2_2;
        reg [255 : 0] res2_2;
        begin : sha256_test
        // TC1: single block message: "abc".
        tc1 = 512'h61626380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018;
        res1 = 256'hBA7816BF8F01CFEA414140DE5DAE2223B00361A396177A9CB410FF61F20015AD;
        single_block_test(1, tc1, res1);

        // TC2: double block message: "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"
        tc2_1 = 512'h6162636462636465636465666465666765666768666768696768696A68696A6B696A6B6C6A6B6C6D6B6C6D6E6C6D6E6F6D6E6F706E6F70718000000000000000;
        res2_1 = 256'h85E655D6417A17953363376A624CDE5C76E09589CAC5F811CC4B32C1F20E533A;

        tc2_2 = 512'h000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001C0;
        res2_2 = 256'h248D6A61D20638B8E5C026930C3E6039A33CE45964FF2167F6ECEDD419DB06C1;
        double_block_test(2, tc2_1, res2_1, tc2_2, res2_2);
        end
    endtask

    /* Test case for the message "Hello, World!"*/
    task sha256_hello_world_test;
        reg [511 : 0] tc;
        reg [255 : 0] res;
        begin : sha256_test
        tc = 512'h48656c6c6f2c20576f726c6421800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000068;
        res = 256'hdffd6021bb2bd5b0af676290809ec3a53191dd81c7f70a4b28688a362182986f;
        single_block_test(3, tc, res);
        end
    endtask


    /* main process */
    initial begin
        init_inputs();
        reset();

        sha256_test();
        sha256_hello_world_test();

        $finish;
        end

endmodule
