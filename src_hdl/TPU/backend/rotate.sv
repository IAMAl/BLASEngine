module Rotate
	import pkg_tpu::*;
#(
	import int	NUM_ENTRY	= 8,
	import int	WIDTH_ENTRY = $clog2(NUM_ENTRY)
)(
	input	[WIDTH_ENTRY-1:0]	I_Rotate_Amount,
	input	rot_srcs_t			I_Srcs,
	output	rot_srcs_t			O_Srcs
);

	logic	[WIDTH_ENTRY-1:0]	Rotate_Amount	[WIDTH_ENTRY-1:0];

	always_comb begin
		for ( int i=0; i<NUM_ENTRY; ++i ) begin
			assign Rotate_Amount[ i ]	= i + I_Rotate_Amount;
			assign O_Srcs[ i ]			= I_Srcs[ Rotate_Amount[ i ] ];
		end
	end

endmodule