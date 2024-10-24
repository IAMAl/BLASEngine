///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	pub_domain_man
///////////////////////////////////////////////////////////////////////////////////////////////////

module pub_domain_man
	import pkg_tpu::*;
#(
	parameter int NUM_ENTRY		= 32,
	parameter int WIDTH_ENTRY	= $clog2(NUM_ENTRY)
)(
	input						clock,
	input						reset,
	input						I_Stall,				//Stall
	input	address_t			I_St_Base,				//Store Base Adress
	input	address_t			I_Ld_Base,				//Load Base Adress
	input						I_St_Grant1,			//Grant for Storing
	input						I_St_Grant2,			//Grant for Storeing
	input						I_St_Grant3,			//Grant for Storing (Extern)
	input						I_Ld_Grant1,			//Grant for Loading
	input						I_Ld_Grant2,			//Grant for Loading
	input						I_Ld_Grant3,			//Grant for Loading (Extern)
	input						I_St_End,				//End of Storing
	input						I_Ld_End,				//End of Loading
	input						I_GrantVld_St,			//Grant Validation
	input						I_GrantVld_Ld,			//Grant Validation
	input	[1:0]				I_GrantNo_St,			//Grant No
	input	[1:0]				I_GrantNo_Ld,			//Grant No
	output						O_St_Ready1,			//Ready to Store
	output						O_St_Ready2,			//Ready to Store
	output						O_St_Ready3,			//Ready to Store (Extern)
	output						O_Ld_Ready1,			//Ready to Load
	output						O_Ld_Ready2,			//Ready to Load
	output						O_Ld_Ready3,			//Ready to Load (Extern)
	output						O_Set_Config_St,		//Set Configuration
	output						O_Set_Config_Ld			//Set Configuration
);


	logic						Event_St_Grant1;
	logic						Event_St_Grant2;
	logic						Event_St_Grant3;
	logic						Event_Ld_Grant1;
	logic						Event_Ld_Grant2;
	logic						Event_Ld_Grant3;

	logic	[WIDTH_ENTRY-1:0]	SetNo;
	logic	[WIDTH_ENTRY-1:0]	ClrNo;

	logic	[NUM_ENTRY-1:0]		is_Hit_St;
	logic	[NUM_ENTRY-1:0]		is_Hit_Ld;

	logic						Hit_St;
	logic						Hit_Ld;

	logic						Ready_St;
	logic						Ready_Ld;

	logic						Set_St;
	logic						Clr_Ld;


	logic						R_St_Grant1;
	logic						R_St_Grant2;
	logic						R_St_Grant3;
	logic						R_Ld_Grant1;
	logic						R_Ld_Grant2;
	logic						R_Ld_Grant3;

	logic	[WIDTH_ENTRY-1:0]	R_SetNo;
	logic	[WIDTH_ENTRY-1:0]	R_ClrNo;

	logic	[WIDTH_ENTRY-1:0]	R_WPtr;

	logic	[NUM_ENTRY-1:0]		R_Valid;
	logic	[NUM_ENTRY-1:0]		R_Stored;
	address_t					TabBAddr	[NUM_ENTRY-1:0];


	assign Event_St_Grant1		= ~R_St_Grant1 & I_St_Grant1 & ~I_Stall;
	assign Event_St_Grant2		= ~R_St_Grant2 & I_St_Grant2 & ~I_Stall;
	assign Event_St_Grant3		= ~R_St_Grant3 & I_St_Grant3 & ~I_Stall;

	assign Event_Ld_Grant1		= ~R_Ld_Grant1 & I_Ld_Grant1 & ~I_Stall;
	assign Event_Ld_Grant2		= ~R_Ld_Grant2 & I_Ld_Grant2 & ~I_Stall;
	assign Event_Ld_Grant3		= ~R_Ld_Grant3 & I_Ld_Grant3 & ~I_Stall;

	assign Hit_St				= ( Event_St_Grant1 | Event_St_Grant2 | Event_St_Grant3 ) & ( |is_Hit_St ) & ~I_Stall;
	assign Hit_Ld				= ( Event_Ld_Grant1 | Event_Ld_Grant2 | Event_Ld_Grant3 ) & ( |is_Hit_Ld ) & ~I_Stall;

	assign Set_St				= I_St_End & ( Event_St_Grant1 | Event_St_Grant2 | Event_St_Grant3 ) & ~( |is_Hit_St ) & ~I_Stall;
	assign Clr_Ld				= I_Ld_End & Hit_Ld & ~I_Stall;

	assign Ready_St				= ~R_Stored[ SetNo ];
	assign Ready_Ld				=  R_Stored[ ClrNo ];

	assign O_St_Ready1			= ( I_GrantNo_St == 2'h0 ) & I_GrantVld_St & Ready_St;
	assign O_St_Ready2			= ( I_GrantNo_St == 2'h1 ) & I_GrantVld_St & Ready_St;
	assign O_St_Ready3			= ( I_GrantNo_St == 2'h2 ) & I_GrantVld_St & Ready_St;

	assign O_Ld_Ready1			= ( I_GrantNo_Ld == 2'h0 ) & I_GrantVld_Ld & Ready_Ld;
	assign O_Ld_Ready2			= ( I_GrantNo_Ld == 2'h1 ) & I_GrantVld_Ld & Ready_Ld;
	assign O_Ld_Ready3			= ( I_GrantNo_Ld == 2'h2 ) & I_GrantVld_Ld & Ready_Ld;

	assign O_Set_Config_St		= Hit_St;
	assign O_Set_Config_Ld		= Hit_Ld;


	always_comb begin
		for ( int i=0; i<NUM_ENTRY; ++i ) begin
			is_Hit_St[ i ]	= ( TabBAddr[ i ] == I_St_Base ) & R_Valid[ i ];
		end
	end

	always_comb begin
		for ( int i=0; i<NUM_ENTRY; ++i ) begin
			is_Hit_Ld[ i ]	= ( TabBAddr[ i ] == I_Ld_Base ) & R_Valid[ i ];
		end
	end


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_St_Grant1		<= 1'b0;
		end
		else begin
			R_St_Grant1		<= I_St_Grant1;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_St_Grant2		<= 1'b0;
		end
		else begin
			R_St_Grant2		<= I_St_Grant2;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_St_Grant3		<= 1'b0;
		end
		else begin
			R_St_Grant3		<= I_St_Grant3;
		end
	end


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Ld_Grant1		<= 1'b0;
		end
		else begin
			R_Ld_Grant1		<= I_Ld_Grant1;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Ld_Grant2		<= 1'b0;
		end
		else begin
			R_Ld_Grant2		<= I_Ld_Grant2;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Ld_Grant3		<= 1'b0;
		end
		else begin
			R_Ld_Grant3		<= I_Ld_Grant3;
		end
	end


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Valid			<= 0;
		end
		else if ( Set_St | Clr_Ld ) begin
			if ( Set_St ) begin
				R_Valid[ R_WPtr ]	<= 1'b1;
			end

			if ( Clr_Ld ) begin
				R_Valid[ R_ClrNo ]	<= 1'b0;
			end
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			for ( int i=0; i<NUM_ENTRY; ++i ) begin
				TabBAddr[ i ]	<= 0;
			end
		end
		else if ( Set_St ) begin
			TabBAddr[ R_WPtr ]	<= I_St_Base;
		end
	end


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Stored		<= 0;
		end
		else if (( Hit_St & I_St_End ) | ( Hit_Ld & I_Ld_End )) begin
			if ( Hit_St & I_St_End ) begin
				R_Stored[ R_SetNo ]	<= 1'b1;
			end

			if ( Hit_Ld & I_Ld_End ) begin
				R_Stored[ R_ClrNo ]	<= 1'b0;
			end
		end
	end

	// Capture Valid Flag No
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_SetNo			<= 0;
		end
		else if ( Hit_St ) begin
			R_SetNo			<= SetNo;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_ClrNo			<= 0;
		end
		else if ( Hit_Ld ) begin
			R_ClrNo			<= ClrNo;
		end
	end


	// Write-Pointer
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_WPtr			<= 0;
		end
		else if ( Set_St ) begin
			R_WPtr			<= R_WPtr + 1'b1;
		end
	end

endmodule