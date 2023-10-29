`timescale 1 ns / 1 ps

module picorv32_pcpi_sha256_tb();

    /* constant and parameter definitions */
    parameter CLK_HALF_PERIOD = 2;
    parameter CLK_PERIOD = 2 * CLK_HALF_PERIOD;

    /* register and wire declarations */
    reg [31 : 0] tc_ctr;

	/* uut inputs */
    reg        clk_tb;
    reg        reset_n_tb;

	reg        pcpi_valid_tb;
	reg [31:0] pcpi_insn_tb;
	reg [31:0] pcpi_rs1_tb;
	reg [31:0] pcpi_rs2_tb;

    /* uut outputs */
    wire        pcpi_wr_tb;
	wire [31:0] pcpi_rd_tb;
	wire        pcpi_wait_tb;
	wire        pcpi_ready_tb;


    /* unit under test */
    picorv32_pcpi_sha256 uut (
        .clk        (clk_tb),
        .reset_n    (reset_n_tb),

        .pcpi_valid (pcpi_valid_tb),
        .pcpi_insn  (pcpi_insn_tb),
        .pcpi_rs1   (pcpi_rs1_tb),
        .pcpi_rs2   (pcpi_rs2_tb),

        .pcpi_wr    (pcpi_wr_tb),
        .pcpi_rd    (pcpi_rd_tb),
        .pcpi_wait  (pcpi_wait_tb),
        .pcpi_ready (pcpi_ready_tb)
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


    /* initialize pcpi inputs to defined values */
    task reset_pcpi_inputs;
        begin
        pcpi_valid_tb = 0;
        pcpi_insn_tb = 32'b0000000_00000_00000_000_00000_0000000;
        pcpi_rs1_tb = 0;
        pcpi_rs2_tb = 0;
        end
    endtask


    /* initialize all inputs to defined values */
    task init_inputs;
        begin
        clk_tb = 1;
        reset_n_tb = 1;
        reset_pcpi_inputs();
        end
    endtask


    /* wait for the pcpi ready flag */
    task wait_ready;
        begin
        while (!pcpi_ready_tb)
            begin
            #(CLK_PERIOD);
            end
        end
    endtask


    /* 000 crypto.sha256_lw r1, r2 */
    task sha256_lw (input [32 : 0] rs1,
                    input [32 : 0] rs2);
        begin
        pcpi_valid_tb = 1;
        pcpi_insn_tb = 32'b0000000_00000_00000_000_00000_0001011;
        pcpi_rs1_tb = rs1;
        pcpi_rs2_tb = rs2;
        wait_ready();
        reset_pcpi_inputs();
        end
    endtask


    /* 001 crypto.sha256_init */
    task sha256_init;
        begin
        pcpi_valid_tb = 1;
        pcpi_insn_tb = 32'b0000000_00000_00000_001_00000_0001011;
        pcpi_rs1_tb = 0;
        pcpi_rs2_tb = 0;
        wait_ready();
        reset_pcpi_inputs();
        end
    endtask


    /* 010 crypto.sha256_next */
    task sha256_next;
        begin
        pcpi_valid_tb = 1;
        pcpi_insn_tb = 32'b0000000_00000_00000_010_00000_0001011;
        pcpi_rs1_tb = 0;
        pcpi_rs2_tb = 0;
        wait_ready();
        reset_pcpi_inputs();
        end
    endtask


    /* 011 crypto.sha256_digest r2, rd */
    task sha256_digest (input [32 : 0] rs2);
        begin
        pcpi_valid_tb = 1;
        pcpi_insn_tb = 32'b0000000_00000_00000_011_00000_0001011;
        pcpi_rs1_tb = 0;
        pcpi_rs2_tb = rs2;
        wait_ready();
        reset_pcpi_inputs();
        end
    endtask


    /* 100 crypto.sha256_reset */
    task sha256_reset;
        begin
        pcpi_valid_tb = 1;
        pcpi_insn_tb = 32'b0000000_00000_00000_100_00000_0001011;
        pcpi_rs1_tb = 0;
        pcpi_rs2_tb = 0;
        wait_ready();
        reset_pcpi_inputs();
        end
    endtask


    /* load SHA-256 block */
    task load_block (input [511 : 0] block);
        begin
        sha256_lw(block[511:480],0);
        #(CLK_PERIOD);
        
        sha256_lw(block[479:448],1);
        #(CLK_PERIOD);
        
        sha256_lw(block[447:416],2);
        #(CLK_PERIOD);
        
        sha256_lw(block[415:384],3);
        #(CLK_PERIOD);
        
        sha256_lw(block[383:352],4);
        #(CLK_PERIOD);
        
        sha256_lw(block[351:320],5);
        #(CLK_PERIOD);
        
        sha256_lw(block[319:288],6);
        #(CLK_PERIOD);
        
        sha256_lw(block[287:256],7);
        #(CLK_PERIOD);

        sha256_lw(block[255:224],8);
        #(CLK_PERIOD);

        sha256_lw(block[223:192],9);
        #(CLK_PERIOD);

        sha256_lw(block[191:160],10);
        #(CLK_PERIOD);
        
        sha256_lw(block[159:128],11);
        #(CLK_PERIOD);
        
        sha256_lw(block[127:96],12);
        #(CLK_PERIOD);
    
        sha256_lw(block[95:64],13);
        #(CLK_PERIOD);
    
        sha256_lw(block[63:32],14);
        #(CLK_PERIOD);
        
        sha256_lw(block[31:0],15);
        #(CLK_PERIOD);

        end
    endtask


    /* SHA-256 digest */
    task digest;
        begin
        sha256_digest(0);
        #(CLK_PERIOD);

        sha256_digest(1);
        #(CLK_PERIOD);
        
        sha256_digest(2);
        #(CLK_PERIOD);
        
        sha256_digest(3);
        #(CLK_PERIOD);
        
        sha256_digest(4);
        #(CLK_PERIOD);
        
        sha256_digest(5);
        #(CLK_PERIOD);
        
        sha256_digest(6);
        #(CLK_PERIOD);
        
        sha256_digest(7);
        #(CLK_PERIOD);
        end
    endtask


    /* single data block test case */
    task single_block_test(input [7 : 0]   tc_number,
                           input [511 : 0] block,
                           input [255 : 0] expected);
        begin
        tc_ctr = tc_ctr + 1;

        load_block(block);

        sha256_init();
        #(CLK_PERIOD);

        digest();
        end
    endtask


    /* double data block test case */
    task double_block_test(input [7 : 0]   tc_number,
                           input [511 : 0] block1,
                           input [255 : 0] expected1,
                           input [511 : 0] block2,
                           input [255 : 0] expected2);
        begin
        tc_ctr = tc_ctr + 1;

        load_block(block1);

        sha256_init();
        #(CLK_PERIOD);

        digest();

        load_block(block2);

        sha256_next();
        #(CLK_PERIOD);

        digest();
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

        sha256_reset();
        #(CLK_PERIOD);

        single_block_test(1, tc1, res1);

        // TC2: double block message: "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"
        tc2_1 = 512'h6162636462636465636465666465666765666768666768696768696A68696A6B696A6B6C6A6B6C6D6B6C6D6E6C6D6E6F6D6E6F706E6F70718000000000000000;
        res2_1 = 256'h85E655D6417A17953363376A624CDE5C76E09589CAC5F811CC4B32C1F20E533A;

        tc2_2 = 512'h000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001C0;
        res2_2 = 256'h248D6A61D20638B8E5C026930C3E6039A33CE45964FF2167F6ECEDD419DB06C1;

        sha256_reset();
        #(CLK_PERIOD);

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

        sha256_reset();
        #(CLK_PERIOD);

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