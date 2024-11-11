///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	IMem
///////////////////////////////////////////////////////////////////////////////////////////////////

module IMem
	import pkg_tpu::*;
#(
	parameter int IMEM_SIZE		= 1024
)(
	input						clock,
	input						reset,
	input						I_Req_St,				//Flag: Request to Store
	input						I_End_St,				//Flag: End of Storing
	input	instr_t				I_Instr,				//Instruction
	input						I_Req_Ld,				//Flag: Request to Store
	input						I_End_Ld,				//Flag: End of Storing
	output	instr_t				O_Instr,				//Instruction
	input	i_address_t			I_Ld_Address,			//Address for Loading
	output						O_Empty,				//State in Empty
	output						O_Full					//State in Full
);


	logic						We;
	logic						We0;
	logic						We1;
	logic						Re;
	logic						WPtr;
	logic						RPtr;
	logic						Empty;
	logic						Full;
	logic	[1:0]				Num;

	logic						End_St;
	logic						End_Ld;

	i_address_t					Ld_Address0;
	i_address_t					Ld_Address1;

	i_address_t					St_Address;

	logic	[1:0]				FSM_St;
	logic	[1:0]				FSM_Ld;

	instr_t						IMem0		[IMEM_SIZE-1:0];
	instr_t						IMem1		[IMEM_SIZE-1:0];


	assign End_Ld			= I_End_Ld & ( FSM_Ld == 2'h2 );
	assign End_St			= I_End_St & ( FSM_St == 2'h2 );

	assign We				= I_Req_St & ~Full;
	assign We0				= We & ~WPtr;
	assign We1				= We &  WPtr;

	assign Re				= I_Req_Ld & ~Empty;

	assign Ld_Address0		= ( RPtr ) ?	'0 :			I_Ld_Address;
	assign Ld_Address1		= ( RPtr ) ?	I_Ld_Address :	'0;

	assign O_Instr			= ( Re ) ?
								( RPtr == 0 ) ?	IMem0[ Ld_Address0 ] :
								( RPtr == 1 ) ?	IMem0[ Ld_Address1 ] :
												'0 :
												'0;

	assign O_Empty			= Empty;
	assign O_Full			= Full;


	always_ff @( posedge clock ) begin
		if ( We0 ) begin
			IMem0[ St_Address ]	<= I_Instr;
		end
	end

	always_ff @( posedge clock ) begin
		if ( We1 ) begin
			IMem1[ St_Address ]	<= I_Instr;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			St_Address	<= '0;
		end
		else if ( I_End_St ) begin
			St_Address	<= '0;
		end
		else if ( We0 | We1 ) begin
			St_Address	<= St_Address + 1'b1;
		end
	end


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			FSM_Ld		<= '0;
		end
		else case ( FSM_Ld )
		2'h0: begin
			if ( I_Req_Ld & ~Empty ) begin
				FSM_Ld		<= 2'h2;
			end
			else if ( I_Req_Ld & Empty ) begin
				FSM_Ld		<= 2'h1;
			end
			else begin
				FSM_Ld		<= 2'h0;
			end
		end
		2'h1: begin
			if ( Empty ) begin
				FSM_Ld		<= 2'h2;
			end
			else begin
				FSM_Ld		<= 2'h3;
			end
		end
		2'h2: begin
			if ( I_End_Ld ) begin
				FSM_Ld		<= 2'h0;
			end
			else begin
				FSM_Ld		<= 2'h2;
			end
		end
		2'h3: begin
			if ( Empty ) begin
				FSM_Ld		<= 2'h2;
			end
			else begin
				FSM_Ld		<= 2'h3;
			end
		end
		default: begin
			FSM_Ld		<= '0;
		end
		endcase
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			FSM_St		<= '0;
		end
		else case ( FSM_St )
		2'h0: begin
			if ( I_Req_St & ~Full ) begin
				FSM_St		<= 2'h2;
			end
			else if ( I_Req_St & Full ) begin
				FSM_St		<= 2'h1;
			end
			else begin
				FSM_St		<= 2'h0;
			end
		end
		2'h1: begin
			if ( Full ) begin
				FSM_St		<= 2'h3;
			end
			else begin
				FSM_St		<= 2'h2;
			end
		end
		2'h2: begin
			if ( I_End_St ) begin
				FSM_St		<= 2'h0;
			end
			else begin
				FSM_St		<= 2'h2;
			end
		end
		2'h3: begin
			if ( Full ) begin
				FSM_St		<= 2'h3;
			end
			else begin
				FSM_St		<= 2'h2;
			end
		end
		default: begin
			FSM_St		<= '0;
		end
		endcase
	end

	RingBuffCTRL #(
		.NUM_ENTRY(		2				)
	) SelPtr
	(
		.clock(			clock			),
		.reset(			reset			),
		.I_We(			End_St			),
		.I_Re(			End_Ld			),
		.O_WAddr(		WPtr			),
		.O_RAddr(		RPtr			),
		.O_Full(		Full			),
		.O_Empty(		Empty			),
		.O_Num(			Num				)
	);

endmodule