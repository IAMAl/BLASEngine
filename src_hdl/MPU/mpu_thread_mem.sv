///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	ThreadMem_MPU
///////////////////////////////////////////////////////////////////////////////////////////////////

module ThrreadMem_MPU
	import pkg_mpu::*;
	import pkg_tpu::instr_t;
	import pkg_tpu::t_address_t;
(
	input						clock,
	input						reset,
	input						I_Req_St,				//Store Request
	output						O_Req_St,				//Send Store Request to MapMan Unit
	output	id_t				O_ThreadID_St,			//Send Thread-ID to MapMan Unit
	output	t_address_t			O_Length_St,			//Send Storing Length to MapMan Unit
	input						I_Ack_St,				//Ack from MapMan Unit
	input	instr_t				I_Instr_St,				//Storing Instructions
	input	t_address_t			I_Used_Size,			//Used Instruction Memory Size
	input						I_Req_Ld,				//Load Request from Dispatch Unit
	input	t_address_t			I_Adddress_Ld,			//Load Address from Dispatch Unit
	output	instr_t				O_Instr_Ld,				//Send Instructions to Dispatch Unit
	output						O_Req,					//Request to Next Stage
	output	id_t				O_ThreadID,				//Thread-ID to Next Stage
	output						O_Wait					//Wait: Exceeding Memory Size
);


	localparam WIDTH_THREAD_MEM	= $clog2(SIZE_THREAD_MEM);
	localparam NUM_ENTRY_ID_MEM = SIZE_THREAD_MEM/32;
	localparam WIDTH_ID_MEM 	= $clog2(NUM_ENTRY_ID_MEM);


	logic						Store;
	logic						End_Store;

	// Handling Thread Information Table
	logic						We;
	logic						Re;
	logic	[WIDTH_ID_MEM-1:0]	WNo;
	logic	[WIDTH_ID_MEM-1:0]	RNo;
	logic						Full;
	logic 						Empty;

	logic						R_Error_Size;
	instr_t						R_Instr_St;
	instr_t						R_Instr_Ld;
	instr_t						InstrMem		[SIZE_THREAD_MEM-1:0];
	id_t						ThreadIDs		[SIZE_THREAD_MEM/32-1:0];

	// Storing Thread in Instruction Memory
	t_address_t					R_Length_St;
	t_address_t					R_Adddress_St;

	logic	[WIDTH_THREAD_MEM-1:0]	R_Count;

	// Retime Request Signal
	logic						R_Req;


	logic						R_Req_Ld;
	id_t						R_ThreadID_St;


	fsm_threadmem_t				FSM_Instr_St;


	//// Send Wait Signal to Host in order to Stall Its Sending
	assign O_Wait				= R_Error_Size;


	//// Request to Next Stage
	assign O_Req				= R_Req;
	assign O_ThreadID			= ThreadIDs[ RNo ];


	//// Send Info to MapMan Unit
	assign O_Req_St				= I_Req_St & ( FSM_Instr_St == FSM_INSTR_ST_LOOKUP );
	assign O_ThreadID_St		= R_ThreadID_St;
	assign O_Length_St			= R_Length_St;


	//// Send Instructions to Dispatch Unit
	assign O_Instr_Ld			= R_Instr_Ld;


	//// Store
	// State in Storing
	assign Store				= I_Req_St & ( FSM_Instr_St == FSM_INSTR_ST_STORE );

	// End of Storing
	assign End_Store			= ( R_Length_St == 0 ) & Store;


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Count			<= 0;
		end
		else if ( ( R_Count > 0 ) & I_Req_Ld & ~R_Req_Ld ) begin
			R_Count			<= R_Count - 1'b1;
		end
		else if ( ( R_Count != (SIZE_THREAD_MEM-1) ) & End_Store ) begin
			R_Count			<= R_Count + 1'b1;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Req			<= 1'b0;
		end
		else begin
			R_Req			<= ( ( R_Count == 0 ) & End_Store ) | ( ( R_Count != 0 ) & I_Req_Ld & ~R_Req_Ld );
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Req_Ld		<= 1'b0;
		end
		else begin
			R_Req_Ld		<= I_Req_Ld;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Instr_Ld		<= 0;
		end
		else if ( I_Req_Ld ) begin
			R_Instr_Ld		<= InstrMem[ I_Adddress_Ld ];
		end
	end

	always_ff @( posedge clock ) begin
		if ( Store ) begin
			InstrMem[ R_Adddress_St ]	<= I_Instr_St;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Adddress_St	<= 0;
		end
		else if ( FSM_Instr_St == FSM_INSTR_ST_STORE ) begin
			R_Adddress_St	<= R_Adddress_St + 1'b1;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_ThreadID_St	<= 0;
		end
		else if ( FSM_Instr_St == FSM_INSTR_ST_RCVID ) begin
			R_ThreadID_St	<= I_Instr_St;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Length_St		<= 0;
		end
		else if ( FSM_Instr_St == FSM_INSTR_ST_CHECK ) begin
			R_Length_St		<= I_Instr_St;
		end
		else if ( FSM_Instr_St == FSM_INSTR_ST_STORE ) begin
			R_Length_St		<= R_Length_St - 1'b1;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Error_Size	<= 1'b0;
		end
		else if ( FSM_Instr_St == FSM_INSTR_ST_CHECK ) begin
			R_Error_Size	<= ( I_Used_Size + I_Instr_St ) > SIZE_THREAD_MEM;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			FSM_Instr_St	<= FSM_INSTR_ST_INIT;
		end
		else case ( FSM_Instr_St )
			FSM_INSTR_ST_INIT: begin
				if ( I_Req_St ) begin
					FSM_Instr_St	<= FSM_INSTR_ST_CHECK;
				end
				else begin
					FSM_Instr_St	<= FSM_INSTR_ST_INIT;
				end
			end
			FSM_INSTR_ST_CHECK: begin
				if ( I_Req_St & ~R_Error_Size ) begin
					FSM_Instr_St	<= FSM_INSTR_ST_SETUP;
				end
				else begin
					FSM_Instr_St	<= FSM_INSTR_ST_CHECK;
				end
			end
			FSM_INSTR_ST_SETUP: begin
				FSM_Instr_St	<= FSM_INSTR_ST_RCVID;
			end
			FSM_INSTR_ST_RCVID: begin
				if ( I_Req_St ) begin
					FSM_Instr_St	<= FSM_INSTR_ST_LOOKUP;
				end
				else begin
					FSM_Instr_St	<= FSM_INSTR_ST_RCVID;
				end
			end
			FSM_INSTR_ST_LOOKUP: begin
				if ( I_Ack_St ) begin
					FSM_Instr_St	<= FSM_INSTR_ST_STORE;
				end
				else begin
					FSM_Instr_St	<= FSM_INSTR_ST_LOOKUP;
				end
			end
			FSM_INSTR_ST_STORE: begin
				if ( End_Store ) begin
					FSM_Instr_St	<= FSM_INSTR_ST_INIT;
				end
				else begin
					FSM_Instr_St	<= FSM_INSTR_ST_STORE;
				end
			end
			default: begin
				FSM_Instr_St	<= FSM_INSTR_ST_INIT;
			end
		endcase
	end


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			for ( int i=0; i<SIZE_THREAD_MEM/32; ++i ) begin
				ThreadIDs[ i ]	<= '0;
			end
		end
		else if ( We ) begin
			ThreadIDs[ WNo ]	<= R_ThreadID_St;
		end
	end


	//// Module: Ring-Buffer Controller
	assign We				= I_Req_St & ( FSM_Instr_St == FSM_INSTR_ST_LOOKUP );
	assign Re				= R_Req;
	RingBuffCTRL #(
		.NUM_ENTRY(			NUM_ENTRY_ID_MEM		)
	) IMemMan
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_We(				We						),
		.I_Re(				Re						),
		.O_WAddr(			WNo						),
		.O_RAddr(			RNo						),
		.O_Full(			Full					),
		.O_Empty(			Empty					),
		.O_Num(										)
	);

endmodule