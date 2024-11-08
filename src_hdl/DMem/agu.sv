///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	agu
///////////////////////////////////////////////////////////////////////////////////////////////////

module agu
	import pkg_tpu::*;
(
	input						clock,
	input						reset,
	input						I_Set_and_Run,			//Flag: Activate Load/Store Unit
	input						I_Stall,				//Force Stalling by Local Memory
	input	address_t			I_Length,				//Vector-Length for Load/Store
	input	stride_t			I_Stride,				//Stride-Factor for Load/Store
	input	address_t			I_Base_Addr,			//Load/Store Base Address
	output	logic				O_Req,					//Access-Request
	output	address_t			O_Address,				//Access-Address
	output						O_End_Access			//Flag: End of Access
);


	logic						End_Access;

	logic						R_Run;

	logic						R_We;
	logic						R_Req;
	address_t					R_Length;
	stride_t					R_Stride;
	address_t					R_Address;


	assign End_Access			= ( R_Length == 0 ) & R_Run;

    assign O_Req                = ( R_Length != 0 ) & R_Run & ~I_Stall;
	assign O_Address			= R_Address;
	assign O_End_Access			= End_Access;


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Run			<= 1'b0;
		end
        else if ( End_Access ) begin
            R_Run			<= 1'b0;
        end
		else if ( I_Set_and_Run ) begin
			R_Run			<= 1'b1;
		end
	end


    //// Access Configuration
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Length		<= 0;
		end
		else if ( R_Run & ~I_Stall ) begin
			R_Length 		<= R_Length -1'b1;
		end
		else if ( I_Set_and_Run & ~R_Run ) begin
			R_Length		<= I_Length;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Stride		<= 0;
		end
		else if ( I_Set_and_Run & ~R_Run ) begin
			R_Stride		<= I_Stride;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Address		<= 0;
		end
		else if ( R_Run & ~I_Stall ) begin
			R_Address		<= R_Address + R_Stride;
		end
		else if ( I_Set_and_Run & ~R_Run ) begin
			R_Address		<= I_Base_Addr;
		end
	end

endmodule