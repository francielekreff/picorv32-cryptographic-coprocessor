`default_nettype none

module picorv32_pcpi_sha256 (
    input wire        clk,
    input wire        reset_n,

    /* Pico Co-Processor Interface (PCPI) */
	input wire        pcpi_valid,
	input wire [31:0] pcpi_insn,
	input wire [31:0] pcpi_rs1,
	input wire [31:0] pcpi_rs2,
	output reg        pcpi_wr,
	output reg [31:0] pcpi_rd,
	output reg        pcpi_wait,
	output reg        pcpi_ready
);  
    localparam BLOCK_SIZE = 512;
    localparam BLOCK_MIN_WORD = 0;
    localparam BLOCK_MAX_WORD = 15;

    localparam DIGEST_SIZE = 256;
    localparam DIGEST_MIN_WORD = 0;
    localparam DIGEST_MAX_WORD = 7;

    localparam MODE_SHA_256   = 1;

	/* SHA-256 coprocessor instructions */
    reg instr_sha256_lw, instr_sha256_init, instr_sha256_next, instr_sha256_digest, instr_sha256_reset;
	wire instr_any_sha256 = |{instr_sha256_lw, instr_sha256_init, instr_sha256_next, instr_sha256_digest, instr_sha256_reset};


    reg init;
    reg init_q;
    wire core_init = init && !init_q;

    reg next;
    reg next_q;
    wire core_next = next && !next_q;

    reg reset;
    reg reset_q;
    wire core_reset_n = reset && !reset_q;

    wire core_ready;
    wire core_digest_valid;

    reg [31 : 0] block  [0 : BLOCK_MAX_WORD];
    reg [31 : 0] digest [0 : DIGEST_MAX_WORD];

    wire [BLOCK_SIZE  -1 : 0] core_block;
    wire [DIGEST_SIZE -1 : 0] core_digest;
    wire  [DIGEST_SIZE -1 : 0] core_digest_q;

    assign core_block = {block[00], block[01], block[02], block[03],
                         block[04], block[05], block[06], block[07],
                         block[08], block[09], block[10], block[11],
                         block[12], block[13], block[14], block[15]};

    assign core_digest_q = {digest[00], digest[01], digest[02], digest[03],
                          digest[04], digest[05], digest[06], digest[07]};


    /* core instantiation */
    sha256_core core(
        .clk            (clk),
        .reset_n        (reset_n),

        .init           (core_init),
        .next           (core_next),
        .mode           (MODE_SHA_256),
        .block          (core_block),

        .ready          (core_ready),
        .digest         (core_digest),
        .digest_valid   (core_digest_valid)
    );


    /* instruction decoding */
	always @(posedge clk) begin
		instr_sha256_lw <= 0;
		instr_sha256_init <= 0;
		instr_sha256_next <= 0;
		instr_sha256_digest <= 0;
        instr_sha256_reset <= 0;

		if (reset_n && pcpi_valid && pcpi_insn[6:0] == 7'b0001011 && pcpi_insn[31:25] == 7'b0000000) begin 
			case (pcpi_insn[14:12])
				3'b000: instr_sha256_lw <= 1;
				3'b001: instr_sha256_init <= 1;
				3'b010: instr_sha256_next <= 1;
				3'b011: instr_sha256_digest <= 1;
                3'b100: instr_sha256_reset <= 1;
			endcase
		end
        pcpi_wait <= instr_any_sha256;

        init <= instr_sha256_init;
	    init_q <= init;

        next <= instr_sha256_next;
		next_q <= next;

        reset <= instr_sha256_reset;
		reset_q <= reset;
	end


    /* block write */
    always @(posedge clk) begin
        if (instr_sha256_lw)
        begin
            if ((pcpi_rs2 >= BLOCK_MIN_WORD) && (pcpi_rs2 <= BLOCK_MAX_WORD))
                block[pcpi_rs2] <= pcpi_rs1;
        end
    end

    /* digest read */
    always @(posedge clk) begin
        if (instr_sha256_digest)
        begin
            if ((pcpi_rs2 >= DIGEST_MIN_WORD) && (pcpi_rs2 <= DIGEST_MAX_WORD))
                pcpi_rd <= digest[pcpi_rs2];
        end
    end

    always @ (posedge clk) begin
        pcpi_ready <= core_ready;
    end

endmodule