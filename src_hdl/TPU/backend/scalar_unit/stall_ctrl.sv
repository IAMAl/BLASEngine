///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	Stall_Ctrl
///////////////////////////////////////////////////////////////////////////////////////////////////

module Stall_Ctrl (
	input						I_PAC_Wait,				//Wait-State in PAC Unit
	input						I_Hazard,				//Hazard Detected
	input						I_Slice,				//Slicing is Used
	input						I_Bypass_Buff_Full,		//Buffer-Full in Network
	input						I_Ld_Stall,				//Stall for Loading
	input						I_St_Stall				//Stall for Storing
	output						O_Stall_IF,				//Stall to Fetch instruction
	output						O_Stall_IW_St,			//Stall to Store in instruction window
	output						O_Stall_IW_Ld,			//Stall to Load from instruction window
	output						O_Stall_IW,				//Stall on instruction window
	output						O_Stall_Index,			//Stall on Index Stage
	output						O_Stall_WB				//Stall on Write Back
);


	assign O_Stall_IF			= I_PAC_Wait | 	I_Slice |						I_Hazard;
	assign O_Stall_IW_St		= I_PAC_Wait | 	I_Slice;
	assign O_Stall_IW_Ld		= I_PAC_Wait | 	I_Slice | 	I_Bypass_Buff_Full;
	assign O_Stall_IW			= I_PAC_Wait |	I_Slice |	I_Bypass_Buff_Full;
	assign O_Stall_Index		= 							I_Bypass_Buff_Full	|			I_St_Stall;
	assign O_Stall_WB			= 															I_Ld_Stall;

endmodule