///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	MapMan_MPU
///////////////////////////////////////////////////////////////////////////////////////////////////

module MapMan_MPU
	import pkg_mpu::*;
(
	input						clock,
	input						reset,
	input						I_Req_St,						//Request from Instruction Memory (Storing)
	input	id_t				I_ThreadID_St,					//Thread-ID from Instruction Memory
	input	t_address_t			I_Length_St,					//Storing Size of Program
	output						O_Ack_St,						//Ack to Instruction Memory
	input	id_t				I_ThreadID_Ld,					//Thread-ID from Dispatch Unit
	output	t_address_t			O_Used_Size,					//Already Used Instruction Memory Size
	input						I_Req_Lookup,					//Request from Dispatch Unit
	output						O_Ack_Lookup,					//Ack to Dispatch Unit
	output	lookup_t			O_ThreadInfo,					//Thread Info to Dispatch Unit
	output						O_Full							//Flag: Map-Table is Fully Used
);


	logic							Found;

	logic							We;
	logic							Re;
	logic	[WIDTH_TAB_MAPMAN-1:0]	WNo;
	logic	[WIDTH_TAB_MAPMAN-1:0]	RNo;
	logic							Full;
	logic							Empty;

	logic	[SIZE_TAB_MAPMAN-1:0]	Valid;
	logic	[SIZE_TAB_MAPMAN-1:0]	is_Matched;

	t_address_t						R_Address_Ld;
	t_address_t						R_Length_Ld;
	t_address_t						R_Used_Size;

	fsm_mapman_st					FSM_St;
	fsm_mapman_ld					FSM_Ld;


	assign O_Full           = R_Used_Size >= (SIZE_THREAD_MEM-1);

	assign Found			= |(~Valid)

	// Send Ack and Used-size to InstrMem Unit
	assign O_Ack_St			= ~FSM_St & Found;
	assign O_Used_Size		= R_Used_Size;

	// Send Back Information to Dispatch UNit
	assign O_Ack_Lookup			= FSM_Ld;
	assign O_ThreadInfo.length	= R_Length_Ld;
	assign O_ThreadInfo.address	= R_Address_ld;

	// Update Used Size
	assign Update           = O_Ack_St | FSM_Ld;
	assign UpdateAmount     = (    O_Ack_St &  O_Ack_Lookup ) ?	I_Length_St - O_Length_Ld :
								(  O_Ack_St & ~O_Ack_Lookup ) ?	I_Length_St :
								( ~O_Ack_St &  O_Ack_Lookup ) ?	-O_Length_Ld :
																0;

	// Table Handling
	assign WError			= I_Req_St & ~Full &  TabInstr[ WNo ].Valid;
	assign We				= I_Req_St & ~Full & ~TabInstr[ WNo ].Valid;
	assign Re				= I_Req_Lookup & ~Empty;


	always_comb begin
		for ( int i=0; SIZE_TAB_MAPMAN; ++i ) begin
			assign Valid[ i ]		= TabInstr[ i ].Valid;
			assign is_Matched[ i ]	= Valid[ i ] & ( TanInstr[ WNo ].ThreadID == I_ThreadID_Ld );
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Length_Ld		<= 0;
		end
		else if ( I_Req_Lookup & ~FSM_Ld ) begin
			R_Length_Ld		<= TabInstr[ RNo ].Length
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Length_Ld		<= 0;
		end
		else if ( I_Req_Lookup & ~FSM_Ld ) begin
			R_Address_Ld	<= TabInstr[ RNo ].Address
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Used_Size		<= 0;
		end
		else if ( Update ) begin
			R_Used_Size		<= R_Used_Size + UpdateAmount;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			TabInstr			<= '0;
		end
		else if ( I_Req_St | I_Req_Lookup ) begin
			if ( I_Req_St ) begin
				TabInstr[ WNo ].Valid		<= 1'b1;
				TanInstr[ WNo ].ThreadID	<= I_ThreadID_St;
				TabInstr[ WNo ].Length		<= I_Length_St;
				TabInstr[ WNo ].Address		<= R_Used_Size;
			end

			if ( I_Req_Lookup ) begin
				TabInstr[ RNo ].Valid		<= 1'b0;
			end
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			FSM_St			<= FSM_MAPMAN_ST_INIT;
		end
		else case ( FSM_St )
			FSM_MAPMAN_ST_INIT: begin
				if ( Found ) begin
					FSM_St			<= FSM_MAPMAN_ST_RUN;
				end
				else begin
					FSM_St			<= FSM_MAPMAN_ST_INIT;
				end
			end
			FSM_MAPMAN_ST_RUN: begin
				if ( I_Req_St ) begin
					FSM_St			<= FSM_MAPMAN_ST_INIT;
				end
				else begin
					FSM_St			<= FSM_MAPMAN_ST_RUN;
				end
			end
		endcase
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			FSM_Ld			<= FSM_MAPMAN_LD_INIT;
		end
		else case ( FSM_Ld )
			FSM_MAPMAN_LD_RUN: begin
				if ( I_Req_Lookup ) begin
					FSM_Ld			<= FSM_MAPMAN_LD_INIT;
				end
				else begin
					FSM_Ld			<= FSM_MAPMAN_LD_RUN;
				end
			end
			FSM_MAPMAN_LD_INIT: begin
				FSM_Ld			<= FSM_MAPMAN_LD_RUN;
			end
		endcase
	end


	//// Module: Ring-Buffer Controller
	RingBuffCTRL #(
		.NUM_ENTRY(			DEPTH_BUFF				)
	) IMemMan
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_We(				We						),
		.I_Re(				Re						),
		.I_Offset(			0						),
		.O_WAddr(			WNo						),
		.O_RAddr(									),
		.O_Full(			Full					),
		.O_Empty(			Empty					),
		.O_Num(										)
	);


	//// Module: Encoder
	//	Get Table Entry Number
	Encoder #(
		.NUM_ENTRY(			SIZE_TAB_MAMAN			)
	) LoadEntry
	(
		.I_Data(			is_Matched				),
		.O_Enc(				RNo						)
	);

endmodule