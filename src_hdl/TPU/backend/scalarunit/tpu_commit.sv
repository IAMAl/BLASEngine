///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	Commit_TPU
///////////////////////////////////////////////////////////////////////////////////////////////////

module Commit_TPU
	import pkg_tpu::*;
(
	input	issue_no_t			I_Rd_Ptr,				//Read Pointer from Hazard Unit
	input						I_RB_Empty_S,			//Empty in Reorder Buffer for Scalar Unit
	input						I_RB_Empty_V,			//Empty in Reorder Buffer for Vector Unit
	input						I_Commit_Req_S,			//Commit Request from Scalar Unit
	input						I_Commit_Req_V,			//Commit Request from Vector Unit
	input	issue_no_t			I_Commit_No_S,			//Commit No from Scalar Unit
	input	issue_no_t			I_Commit_No_V,			//Commit No from Vector Unit
	output	logic				O_Commit_Grant_S,		//Commit Grant to Scalar Commit Unit
	output	logic				O_Commit_Grant_V,		//Commit Grant to Vector Commit Unit
	output	logic				O_Commit_Req,			//Commit Request to Hazard Unit
	input	issue_no_t			O_Commit_No				//Commit No to Hazard Unit
);


	issue_no_t					Lifetime_S;
	issue_no_t					Lifetime_V;
	logic						Select;
	logic						Sel_V;


	// Calculate Lifetime
	//	Larger Number is Longer Life
	assign Lifetime_S			= I_Rd_Ptr - I_Commit_No_S;
	assign Lifetime_V			= I_Rd_Ptr - I_Commit_No_V;

	// Select Signal
	assign Sel_V				= Lifetime_V > Lifetime_S;
	assign Select				= ( Sel_V & ~I_RB_Empty_S & ~I_RB_Empty_V ) |
									( I_RB_Empty_S & ~I_RB_Empty_V );


	// Commit Request
	assign O_Commit_Req			= I_Commit_Req_V | I_RB_Empty_S;
	assign O_Commit_No			= ( Select ) ?	I_Commit_Req_V : I_Commit_Req_S;

	// Send-Back Grant to Each Unit
	assign O_Commit_Grant_S		= ~Select;
	assign O_Commit_Grant_V		=  Select;

endmodule