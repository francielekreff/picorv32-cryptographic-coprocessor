`timescale 1 ns / 1 ps

module picorv32_pcpi_sha256_tb();

    /* constant and parameter definitions */
    parameter CLK_HALF_PERIOD = 2;
    parameter CLK_PERIOD = 2 * CLK_HALF_PERIOD;

    /* register and wire declarations */
    reg [31 : 0] error_ctr;
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


    /* clock generator process */
    always begin
        #CLK_HALF_PERIOD;
        clk_tb = !clk_tb;
    end


    /* toggle reset */
    task reset_uut;
        begin
        reset_n_tb = 0;
        #(2 * CLK_PERIOD);
        reset_n_tb = 1;
        end
    endtask


    /* initialize all inputs to defined values */
    task init_sim;
        begin
        clk_tb = 1;
        reset_n_tb = 1;

        pcpi_valid_tb = 0;
        pcpi_insn_tb = 32'b0000000_00000_00000_000_00000_0000000;
        pcpi_rs1_tb = 0;
        pcpi_rs2_tb = 0;
    
        end
    endtask 

    task lw_insn (input [32 : 0]   rs1,
                  input [511 : 0] rs2);
    begin
        pcpi_valid_tb = 1;
        pcpi_insn_tb = 32'b0000000_00000_00000_000_00000_0001011;
        pcpi_rs1_tb = rs1;
        pcpi_rs2_tb = rs2;
        #(10 * CLK_PERIOD);
        pcpi_valid_tb = 0;
        pcpi_insn_tb = 32'b0000000_00000_00000_000_00000_0000000;
        end
    endtask

    task init_insn;
        begin
        pcpi_valid_tb = 1;
        pcpi_insn_tb = 32'b0000000_00000_00000_001_00000_0001011;
        pcpi_rs1_tb = 0;
        pcpi_rs2_tb = 0;
        #(10 * CLK_PERIOD);

        end
    endtask

    task next_insn;
        begin
        pcpi_valid_tb = 1;
        pcpi_insn_tb = 32'b0000000_00000_00000_010_00000_0001011;
        pcpi_rs1_tb = 0;
        pcpi_rs2_tb = 0;
        
        #(10 * CLK_PERIOD);
        end
    endtask


    /* main process */
    initial begin

        init_sim();
        reset_uut();

        lw_insn(32'h61626380,0);
        #CLK_PERIOD;

        lw_insn(32'h00000000,1);
        #CLK_PERIOD;
        
        lw_insn(32'h00000000,2);
        #CLK_PERIOD;
        
        lw_insn(32'h00000000,3);
        #CLK_PERIOD;
        
        lw_insn(32'h00000000,4);
        #CLK_PERIOD;
        
        lw_insn(32'h00000000,5);
        #CLK_PERIOD;
        
        lw_insn(32'h00000000,6);
        #CLK_PERIOD;
        
        lw_insn(32'h00000000,7);
        #CLK_PERIOD;

        lw_insn(32'h00000000,8);
        #CLK_PERIOD;

        lw_insn(32'h00000000,9);
        #CLK_PERIOD;

        lw_insn(32'h00000000,10);
        #CLK_PERIOD;
        
        lw_insn(32'h00000000,11);
        #CLK_PERIOD;
        
        lw_insn(32'h00000000,12);
        #CLK_PERIOD;
    
        lw_insn(32'h00000000,13);
        #CLK_PERIOD;
    
        lw_insn(32'h00000000,14);
        #CLK_PERIOD;
        
        lw_insn(32'h00000018,15);
        #CLK_PERIOD;

        init_insn();
        #(100 * CLK_PERIOD);
        //next_insn();

        $finish;
        end

endmodule