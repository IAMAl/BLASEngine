module Counter #(
	import int	WIDHT_COUNT	= 64;
)(
	input						clock,
	input						reset,
	input						I_Clr,
	input						I_En,
	output	[WIDHT_COUNT-1:0]	O_CountVal
);

	logic	[WIDHT_COUNT-1:0]	R_CountVal;


	assign O_CountVal			= R_CountVal;

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_CountVal		<= 0;
		end
		else ( I_Clr ) begin
			R_CountVal		<= 0;
		end
		else if ( I_En ) begin
			R_CountVal		<= O_CountVal + 1'b1;
		end
	end

endmodule
