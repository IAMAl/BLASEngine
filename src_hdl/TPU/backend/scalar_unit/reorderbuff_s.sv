///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	ReorderBuff_S
///////////////////////////////////////////////////////////////////////////////////////////////////

module ReorderBuff_S
	import pkg_tpu::*;
#(
	parameter NUM_ENTRY 		= 16
)(
	input						clock,
	input						reset,
	input						I_Store,				//Store Issue No
	input	issue_no_t			I_Issue_No,				//Storing Issue Number
	input						I_Commit_Req_LdSt1,		//Commit Request from LdSt Unit-1
	input						I_Commit_Req_LdSt2,		//Commit Request from LdSt Unit-2
	input						I_Commit_Req_Math,		//Commit Request from Math Unit
	input						I_Commit_Req_Mv,		//Commit Request from Reg Move
    input   issue_no_t          I_Commit_No_LdSt1,		//Commit No from LdSt Unit-1
    input   issue_no_t          I_Commit_No_LdSt2,		//Commit No from LdSt Unit-2
    input   issue_no_t          I_Commit_No_Math,		//Commit No from Math Unit
    input   issue_no_t          I_Commit_No_Mv,			//Commit No from Reg Move
	output						O_Commit_Grant,			//Commit Grant
	input						I_Commit_Req_V,			//Commit Request from Vector Unit
	input	issue_no_t			I_Commit_No_V,			//Commit No from Vector Unit
	output						O_Commit_Grant_V,		//Commit Grant to Vector Unit
	output						O_Commit_Req,			//Commit Request to Hazard Unit
	output	issue_no_t			O_Commit_No,			//Commit Number
	output						O_Full,					//State in Full
	output						O_Empty					//State in Empty
);


	localparam WIDTH_ENTRY		= $clog2(NUM_ENTRY);

	commit_tab_s				Commit	[NUM_ENTRY-1:0];

	logic	[NUM_ENTRY-1:0]		Clr_Valid;
	logic	[NUM_ENTRY-1:0]		Set_Commit;

	logic						En_Commit;

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
	assign O_Commit_Grant		=;//ToDo
	assign O_Commit_Grant_V		=;//ToDo

	// Buffer Handling
	assign En_Commit			= Commit[RNo].v & Commit[RNo].commit;
	assign Re					= En_Commit & I_Commit_Grant;
	assign We					= I_Store & ~Full;


	always_comb begin
		for ( int i=0; i<NUM_ENTRY; ++i ) begin
			Set_Commit[ i ]	= Commit[ i ].v & (
										(   Commit[ i ].issue_no == I_Commit_No_LdSt1 ) |
										(   Commit[ i ].issue_no == I_Commit_No_LdSt2 ) |
										(   Commit[ i ].issue_no == I_Commit_No_Math ) |
										( ( Commit[ i ].issue_no == I_Commit_No_V ) & I_Commit_Req_V )
									);
		end
	end

    always_comb begin
        for ( int i=0; i<NUM_ENTRY; ++i ) begin
            Clr_Valid[ i ]     = Commit[ i ].v & Commit[ i ].commit;
        end
    end


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			for ( int i=0; i<NUM_ENTRY; ++i ) begin
				Commit[i]		<= '0;
			end
		end
		else if ( I_Store | ( Set_Commit != 0) | ( Clr_Valid != 0 ) ) begin
			if ( I_Store ) begin
				Commit[ WNo ].v			<= 1'b1;
				Commit[ WNo ].issue_no	<= I_Issue_No;
				Commit[ WNo ].commit	<= 1'b0;
			end

			for ( int i=0; i<NUM_ENTRY; ++i ) begin
				Commit[ i ].commit		<= Commit[ i ].commit | Set_Commit[ i ];
			end

			for ( int i=0; i<NUM_ENTRY; ++i ) begin
				Commit[ i ].v			<= Commit[ i ].v &  ~Clr_Valid[ i ];
				Commit[ i ].commit		<= Commit[ i ].commit & ~Clr_Valid[ i ];
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