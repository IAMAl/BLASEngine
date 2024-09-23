module SkipCTRL
	import	pkg_tpu::*;
#(
	parameter int	NUM_ENTRY_NLZ_INDEX = 32
)(
	input						clock,
	input						reset,
	input						I_Req,					//Request to Skip
	input						I_Stall,				//Stall
	input	mask_t				I_Mask_Value,			//Mask Value
	input	index_t				I_Index_Start,			//Start Index
	input	index_t				I_Index_Length,			//Length of Access
	output						O_Req,					//Request
	output	index_t				O_Index_Offset,			//Offset Value
	output						O_End					//End of Skipping
);


	logic						Run;
	logic						End_Skip;

	mask_t						Rotated_Mask;

	index_t						NLZ_Value;

	logic						R_Req;
	logic	[NUM_ENTRY_REGFILE-1:0]	R_Mask;


	assign Run					= I_Req;

	assign Rotated_Mask			= ( I_Mask_Value >> I_Index_Start ) |
									( I_Mask_Value << ( NUM_ENTRY_REGFILE - I_Index_Start ) );

	assign End_Skip				= ( NLZ_Value >= I_Index_Length ) & Run;
	assign O_End				= End_Skip;

	assign O_Req				= Run & ~End_Skip;
	assign O_Index_Offset		= ( Run ) ? NLZ_Value : '0;


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Req			<= 1'b00;
		end
		else begin
			R_Req			<= I_Req;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Mask				<= 0;
		end
		else if ( I_Req & ~I_Stall ) begin
			R_Mask[ NLZ_Value ]	<= 1'b0;
		end
		else if ( I_Req & ~R_Req & ~I_Stall ) begin
			R_Mask				<= Rotated_Mask;
		end
	end


	NLZ32 NLZ_Index
	(
		.I_Data(			R_Mask					),
		.O_Num(				NLZ_Value				),
		.O_Valid(									)
	);

endmodule