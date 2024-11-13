///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	IICtrl
///////////////////////////////////////////////////////////////////////////////////////////////////

module IICtrl
	import pkg_tpu::*;
#(
	LANE_ID						= 0
)(
	input						clock,
	input						reset,
	input						I_Stall,				//Stall Request
	input						I_En_II,				//Enable Initial-Interval
	input						I_Clr_II,				//Clear Initial-Interval
	output						O_Stall					//Stall Request
);


	logic						is_Match;

	logic						Run_II;
	index_t						Count;

	assign is_Match			= Count == LANE_ID;


	assign O_Stall			= ~is_Match & Run_II;


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Run_II		<= 1'b0;
		end
		else if ( I_Clr_II ) begin
			Run_II		<= 1'b0;
		end
		else if ( I_En_II ) begin
			Run_II		<= 1'b1;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Count		<= '0;
		end
		else if ( I_Clr_II ) begin
			Count		<= '0;
		end
		else if ( ~I_Stall & ( Run_II | I_En_II ) ) begin
			Count		<= Count + 1;
		end
	end

endmodule