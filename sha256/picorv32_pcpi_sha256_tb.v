`timescale 1 ns / 1 ps

module picorv32_pcpi_sha256_tb();

    /* constant and parameter definitions */
    parameter CLK_HALF_PERIOD = 2;
    parameter CLK_PERIOD = 2 * CLK_HALF_PERIOD;

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
        sha256_lw(32'h61626380,0);
        #(4*CLK_PERIOD);
        
        sha256_lw(32'h00000000,1);
        #(4*CLK_PERIOD);
        
        sha256_lw(32'h00000000,2);
        #(4*CLK_PERIOD);
        
        sha256_lw(32'h00000000,3);
        #(4*CLK_PERIOD);
        
        sha256_lw(32'h00000000,4);
        #(4*CLK_PERIOD);
        
        sha256_lw(32'h00000000,5);
        #(4*CLK_PERIOD);
        
        sha256_lw(32'h00000000,6);
        #(4*CLK_PERIOD);
        
        sha256_lw(32'h00000000,7);
        #(4*CLK_PERIOD);

        sha256_lw(32'h00000000,8);
        #(4*CLK_PERIOD);

        sha256_lw(32'h00000000,9);
        #(4*CLK_PERIOD);

        sha256_lw(32'h00000000,10);
        #(4*CLK_PERIOD);
        
        sha256_lw(32'h00000000,11);
        #(4*CLK_PERIOD);
        
        sha256_lw(32'h00000000,12);
        #(4*CLK_PERIOD);
    
        sha256_lw(32'h00000000,13);
        #(4*CLK_PERIOD);
    
        sha256_lw(32'h00000000,14);
        #(4*CLK_PERIOD);
        
        sha256_lw(32'h00000018,15);
        #(4*CLK_PERIOD);

        end
    endtask


    /* SHA-256 digest */
    task digest;
    begin
        sha256_digest(0);
        #(4*CLK_PERIOD);

        sha256_digest(1);
        #(4*CLK_PERIOD);
        
        sha256_digest(2);
        #(4*CLK_PERIOD);
        
        sha256_digest(3);
        #(4*CLK_PERIOD);
        
        sha256_digest(4);
        #(4*CLK_PERIOD);
        
        sha256_digest(5);
        #(4*CLK_PERIOD);
        
        sha256_digest(6);
        #(4*CLK_PERIOD);
        
        sha256_digest(7);
        #(4*CLK_PERIOD);
        end
    endtask


    /* main process */
    initial begin

        init_inputs();
        reset();

        sha256_reset();
        #(4*CLK_PERIOD);
      
        load_block(512'h61626380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018);

        sha256_init();
        #(4*CLK_PERIOD);

        digest();

        sha256_reset();
        #(4*CLK_PERIOD);
        
        $finish;
        end

endmodule