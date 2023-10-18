`timescale 1 ns / 1 ps

module system_tb;

	/* uut inputs */
	reg clk = 1;
	always #5 clk = ~clk;

	reg rx;
	reg [3:0] sw;

	/* uut outputs */
	wire tx;
	wire [3:0] led;


	system uut (
		.clk	(clk),
		.tx		(tx),
		.rx		(rx),
		.sw		(sw),
		.led	(led)
	);


	initial begin
		
		rx = 0;
		sw = 0;

		repeat (5000) @(posedge clk);
		$finish;
	end


endmodule
