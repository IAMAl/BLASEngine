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
	input						I_Ld_NoReady,			//No Ready for Loading
	output	logic				O_Stall_IF,				//Stall to Fetch instruction
	output	logic				O_Stall_IW_St,			//Stall to Store in instruction window
	output	logic				O_Stall_IW_Ld,			//Stall to Load from instruction window
	output	logic				O_Stall_IW,				//Stall on instruction window
	output	logic				O_Stall_Net				//Stall on netowrk
);


	assign O_Stall_IF			= 				I_Hazard | 	I_Slice | I_Ld_NoReady | 	I_Bypass_Buff_Full;
	assign O_Stall_IW_St		= I_PAC_Wait | 				I_Slice | I_Ld_NoReady | 	I_Bypass_Buff_Full;
	assign O_Stall_IW_Ld		= I_PAC_Wait | 				I_Slice | 					I_Bypass_Buff_Full;
	assign O_Stall_IW			= I_PAC_Wait |				I_Slice | I_Ld_NoReady | 	I_Bypass_Buff_Full;
	assign O_Stall_Net			= I_PAC_Wait | 	I_Hazard | 	I_Slice | I_Ld_NoReady;

endmodule