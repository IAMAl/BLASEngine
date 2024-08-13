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
	input						I_PAC_Wait,
	input						I_Hazard
	input						I_Slice,
	input						I_Ld_NoReady,
	output logic				O_Stall_IF,
	output logic				O_Stall_IW_St,
	output logic				O_Stall_IW_Ld
);


	assign O_Stall_IF			= I_PAC_Wait | I_Hazard | I_Slice | I_Ld_NoReady;
	assign O_Stall_IW_St		= I_PAC_Wait | I_Hazard | I_Slice | I_Ld_NoReady;
	assign O_Stall_IW_Ld		= I_PAC_Wait | I_Hazard | I_Slice | I_Ld_NoReady;

endmodule