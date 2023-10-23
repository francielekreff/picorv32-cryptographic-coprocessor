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

    localparam MODE_SHA_256 = 1;

    integer i;

	/* SHA-256 coprocessor instructions */
    reg instr_sha256_lw, instr_sha256_init, instr_sha256_next, instr_sha256_digest, instr_sha256_reset;
	wire instr_any_sha256 = |{instr_sha256_lw, instr_sha256_init, instr_sha256_next, instr_sha256_digest, instr_sha256_reset};

    reg instr_sha256_lw_ready, instr_sha256_init_ready, instr_sha256_next_ready, instr_sha256_digest_ready, instr_sha256_reset_ready;
    wire instr_any_sha256_ready = |{instr_sha256_lw_ready, instr_sha256_init_ready, instr_sha256_next_ready, instr_sha256_digest_ready, instr_sha256_reset_ready};

    reg sha256_init;
    reg sha256_init_q;
    wire core_init = sha256_init && !sha256_init_q;

    reg sha256_next;
    reg sha256_next_q;
    wire core_next = sha256_next && !sha256_next_q;

    reg sha256_reset;
    reg sha256_reset_q;
    reg core_reset_n;

    reg core_mode = MODE_SHA_256;

    wire core_ready;
    wire core_digest_valid;

    reg [31 : 0] block  [BLOCK_MIN_WORD : BLOCK_MAX_WORD];
    reg [31 : 0] digest [DIGEST_MIN_WORD : DIGEST_MAX_WORD];

    wire [BLOCK_SIZE  -1 : 0] core_block;
    wire [DIGEST_SIZE -1 : 0] core_digest;

    assign core_block = {block[00], block[01], block[02], block[03],
                         block[04], block[05], block[06], block[07],
                         block[08], block[09], block[10], block[11],
                         block[12], block[13], block[14], block[15]};


    /* core instantiation */
    sha256_core core(
        .clk            (clk),
        .reset_n        (core_reset_n),

        .init           (core_init),
        .next           (core_next),
        .mode           (core_mode),
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

		if (pcpi_valid && pcpi_insn[6:0] == 7'b0001011 && pcpi_insn[31:25] == 7'b0000000 && reset_n) begin 
			case (pcpi_insn[14:12])
				3'b000: instr_sha256_lw <= 1;
				3'b001: instr_sha256_init <= 1;
				3'b010: instr_sha256_next <= 1;
				3'b011: instr_sha256_digest <= 1;
                3'b100: instr_sha256_reset <= 1;
			endcase

            pcpi_wait <= instr_any_sha256;
		end

        sha256_init <= instr_sha256_init;
	    sha256_init_q <= sha256_init;

        sha256_next <= instr_sha256_next;
		sha256_next_q <= sha256_next;

        sha256_reset <= instr_sha256_reset;
		sha256_reset_q <= sha256_reset;

	end

    /* buffers and regs reset */
    always @(posedge clk) begin
        if (!reset_n) begin
            pcpi_wait <= 0;
            pcpi_rd <= 0;

            sha256_init <= 0;
            sha256_init_q <= 0;

            sha256_next <= 0;
		    sha256_next_q <= 0;

            sha256_reset <= 0;
            sha256_reset_q <= 0;

            for (i = BLOCK_MIN_WORD; i <= BLOCK_MAX_WORD; i=i+1) begin
                block[i] = 32'h00000000;
            end 

            for (i = DIGEST_MIN_WORD; i <= DIGEST_MAX_WORD; i=i+1) begin
                digest[i] = 32'h00000000;
            end 
        end
    end

    /* core init and core next */
    always @(posedge clk) begin
        instr_sha256_init_ready <= 0;
        instr_sha256_next_ready <= 0;

        if (pcpi_valid && instr_sha256_init && reset_n) begin
            if (core_ready && core_digest_valid) begin
                digest[0] = core_digest[255:224];
                digest[1] = core_digest[223:192];
                digest[2] = core_digest[191:160];
                digest[3] = core_digest[159:128];
                digest[4] = core_digest[127: 96];
                digest[5] = core_digest[ 95: 64];
                digest[6] = core_digest[ 63: 32];
                digest[7] = core_digest[ 31: 00];

                pcpi_rd <= 0;
                instr_sha256_init_ready <= 1;
            end
        end

        if (pcpi_valid && instr_sha256_next && reset_n) begin
            if (core_ready && core_digest_valid) begin
                digest[0] = core_digest[255:224];
                digest[1] = core_digest[223:192];
                digest[2] = core_digest[191:160];
                digest[3] = core_digest[159:128];
                digest[4] = core_digest[127: 96];
                digest[5] = core_digest[ 95: 64];
                digest[6] = core_digest[ 63: 32];
                digest[7] = core_digest[ 31: 00];

                pcpi_rd <= 0;
                instr_sha256_next_ready <= 1;
            end
        end
    end


    /* load word and digest */
    always @(posedge clk) begin
        instr_sha256_lw_ready <= 0;
        instr_sha256_digest_ready <= 0;

        if (pcpi_valid && instr_sha256_lw && reset_n) begin
            if ((pcpi_rs2 >= BLOCK_MIN_WORD) && (pcpi_rs2 <= BLOCK_MAX_WORD))
                block[pcpi_rs2] <= pcpi_rs1;
            
            pcpi_rd <= 0;
            instr_sha256_lw_ready <= 1; 
        end

        if (pcpi_valid && instr_sha256_digest && reset_n) begin
            if ((pcpi_rs2 >= DIGEST_MIN_WORD) && (pcpi_rs2 <= DIGEST_MAX_WORD))
                pcpi_rd <= digest[pcpi_rs2];

            instr_sha256_digest_ready <= 1;
        end
    end

    /* reset */
    always @(posedge clk) begin
        instr_sha256_reset_ready <= 0;

        core_reset_n <= reset_n;

        if (pcpi_valid && instr_sha256_reset && reset_n) begin
            /* reset buffers */
            for (i = BLOCK_MIN_WORD; i <= BLOCK_MAX_WORD; i=i+1) begin
                block[i] = 32'h00000000;
            end 

            for (i = DIGEST_MIN_WORD; i <= DIGEST_MAX_WORD; i=i+1) begin
                digest[i] = 32'h00000000;
            end 

            core_reset_n <= 0;
            instr_sha256_reset_ready <= 1;
        end
    end


    /* ready */
    always @ (posedge clk) begin
		pcpi_wr <= 0;
		pcpi_ready <= 0;

		if (pcpi_valid && instr_any_sha256_ready && reset_n) begin
			pcpi_ready <= 1;
            pcpi_wait <= 0;
		end

        if (pcpi_valid && instr_sha256_digest_ready && reset_n) begin
			pcpi_wr <= 1;
		end
    end

endmodule