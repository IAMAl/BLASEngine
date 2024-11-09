///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	ReorderBuff_V
///////////////////////////////////////////////////////////////////////////////////////////////////

module ReorderBuff_V
	import pkg_tpu::*;
#(
	parameter NUM_ENTRY 		= 16
)(
	input						clock,
	input						reset,
	input                       I_En_Lane,
	input						I_Commit_Grant,
	input						I_Store,				//Store Issue No
	input	issue_no_t			I_Issue_No,				//Storing Issue Number
	input						I_Slice,				//Flag Use of Slicing
	input						I_Commit_Req_LdSt1,		//Commit Request from LdSt Unit-1
	input						I_Commit_Req_LdSt2,		//Commit Request from LdSt Unit-2
	input						I_Commit_Req_Math,		//Commit Request from Math Unit
	input						I_Commit_Req_Mv,		//Commit Request from Reg Move
    input   issue_no_t          I_Commit_No_LdSt1,		//Commit No from LdSt Unit-1
    input   issue_no_t          I_Commit_No_LdSt2,		//Commit No from LdSt Unit-2
    input   issue_no_t          I_Commit_No_Math,		//Commit No from Math Unit
    input   issue_no_t          I_Commit_No_Mv,			//Commit No from Reg Move
	output						O_Commit_Grant,			//Commit Grant
	output						O_Commit_Req,			//Commit Request to Hazard Unit
	output	issue_no_t			O_Commit_No,			//Commit Number
	output						O_Full,					//State in Full
	output						O_Empty,				//State in Empty
	output						O_Stall					//Stall Request
);


	localparam WIDTH_ENTRY		= $clog2(NUM_ENTRY);

	commit_tab_t				Commit	[NUM_ENTRY-1:0];

	logic	[NUM_ENTRY-1:0]		is_Slice;

	logic						Valid_Commit;
	logic	[NUM_ENTRY-1:0]		Set_Commit;

	logic						We;
	logic						Re;
	logic	[WIDTH_ENTRY-1:0]	WNo;
	logic	[WIDTH_ENTRY-1:0]	RNo;
	logic						Empty;
	logic						Full;


	// Send Commit Request
	assign O_Commit_Req			= Re;
	assign O_Commit_No			= Commit[RNo].issue_no;

	// State of Buffer
	assign O_Full				= Full;
	assign O_Empty				= Empty;

	// Commit Grant
	assign O_Commit_Grant		= Re;

	// Stall Request
	assign O_Stall				= |is_Slice;

	// Buffer Handling
	assign Re					= I_En_Lane & I_Commit_Grant;
	assign We					= I_Store & ~Full;


	always_comb begin
		for ( int i=0; i<NUM_ENTRY; ++i ) begin
			Set_Commit[ i ]	= Commit[ i ].v & (
										( ( Commit[ i ].issue_no == I_Commit_No_LdSt1 ) & I_Commit_Req_LdSt1 ) |
										( ( Commit[ i ].issue_no == I_Commit_No_LdSt2 ) & I_Commit_Req_LdSt2 ) |
										( ( Commit[ i ].issue_no == I_Commit_No_Math )  & I_Commit_Req_Math ) |
										( ( Commit[ i ].issue_no == I_Commit_No_Mv )	& I_Commit_Req_Mv )
									);
		end
	end

	always_comb begin
		for ( int i=0; i<NUM_ENTRY; ++i ) begin
			is_Slice[ i ]	= Commit[ i ].v & Commit[ i ].opt & ( i != RNo )  & ( i != WNo );
		end
	end


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Valid_Commit		<= 1'b0;
		end
		else begin
			Valid_Commit		<= Commit[ RNo ].v & Commit[ RNo ].commit;
		end
	end


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			for ( int i=0; i<NUM_ENTRY; ++i ) begin
				Commit[i]		<= '0;
			end
		end
		else if ( I_Store | ( |Set_Commit ) | Valid_Commit ) begin
			if ( I_Store ) begin
				Commit[ WNo ].v			<= 1'b1;
				Commit[ WNo ].issue_no	<= I_Issue_No;
				Commit[ WNo ].commit	<= 1'b0;
				Commit[ WNo ].opt		<= I_Slice;
			end

			for ( int i=0; i<NUM_ENTRY; ++i ) begin
				Commit[ i ].commit		<= Commit[ i ].commit | Set_Commit[ i ];
			end

			if ( Valid_Commit ) begin
				Commit[ RNo ].v			<= 1'b0;
				Commit[ RNo ].commit	<= 1'b0;
				Commit[ RNo ].opt		<= 1'b0;
			end
		end
	end


	//// Module: Ring-Buffer Controller
	RingBuffCTRL #(
		.NUM_ENTRY(			NUM_ENTRY				)
	) RingBuffCTRL
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