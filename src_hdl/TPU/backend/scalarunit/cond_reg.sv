///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	CondReg
///////////////////////////////////////////////////////////////////////////////////////////////////

module CondReg
	import pkg_tpu::*;
(
	input						clock,
	input						reset,
	input						I_Ready,				//Ready to Set
	input						I_Term,				//Termination of Compare
	input						I_We,				//Write-Enable the Mask Register
	input	cond_t				I_Cond,				//Condition to Gnerate Flag
	input	state_t				I_Status,				//Status of Comparing
	input						I_Re,				//Read-Enable
	output						O_Condition			//Condition Data
);


	logic						Mask;
	logic						Ready;


	assign O_Condition			= ( I_Re ) ? Mask : '0;


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Ready			<= 1'b0;
		end
		else if ( I_Term ) begin
			Ready			<= 1'B0;
		end
		else if ( I_Ready ) begin
			Ready			<= 1'b1;
		end
	end


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Mask			<= '0;
		end
		else if ( I_We & Ready ) begin
			Mask			<= I_Status[ I_Cond ];
		end
	end

endmodule