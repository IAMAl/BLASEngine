///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	Lane_En_V
///////////////////////////////////////////////////////////////////////////////////////////////////

module Lane_En_V
	import pkg_tpu::*;
(
	input						clock,
	input						reset,
	input						I_En,				//Lane Enable
	input						I_Rst,				//Reset Control
	input						I_Set,				//Set Control
	input	index_t				I_Index,			//Select Condition
	input	state_t				I_Status,			//Condition
	output						O_State,			//Status
	output						O_En				//Lane Enable
);


	logic						W_En;

	logic						En;
	logic						Cond;
	logic						CTRL;


	assign O_En					= En;
	assign O_State				= Cond;

	assign W_En					= ~CTRL | ( CTRL & Cond );


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Cond			<= 1'b0;
		end
		else if ( I_En ) begin
			Cond			<= I_Status[ I_Index[1:0] ];
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			CTRL			<= 1'b0;
		end
		else if ( I_Rst ) begin
			CTRL			<= 1'b0;
		end
		else if ( I_Set ) begin
			CTRL			<= 1'b1;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			En				<= 1'b0;
		end
		else begin
			En				<= W_En;
		end
	end

endmodule