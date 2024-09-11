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
	parameter NUM_ENTRY = 16
)(
	input						clock,
	input						reset,
	input	[NUM_ENTRY-1:0]		I_En_Lane,
	input						I_Store,				//Store Issue No
	input	issue_no_t			I_Issue_No,				//Storing Issue No
	input						I_Commit_Grant,			//Commit Grant
	input						I_Commit_Req,			//Commit Request from Vector Unit
	output	logic				O_Commit_Req,			//Commit Request
	output	issue_no_t			O_Commit_No,			//Commit No
	output	logic				O_Full,					//State in Full
	output	logic				O_Empty					//State in Empty
);


	localparam WIDTH_ENTRY		= $clog2(NUM_ENTRY);

	commit_tab_v				Commit_V	[NUM_ENTRY-1:0];

	logic	[NUM_ENTRY-1:0]		Clr_Valid;
	logic	[NUM_ENTRY-1:0]		Set_Commit;

	logic						We;
	logic						Re;
	logic	[WIDTH_ENTRY-1:0]	WNo;
	logic	[WIDTH_ENTRY-1:0]	RNo;
	logic						Empty;
	logic						Full;

	logic						En_Commit;


	// Send Commit Request
	assign O_Commit_Req			= Re;
	assign O_Commit_No			= Commit_V[ RNo ].Issue_No;

	// State of Buffer
	assign O_Full				= Full;
	assign O_Empty				= Empty;

	// Buffer Handling
	assign En_Commit			= Commit_V[ RNo ].v & Commit_V[ RNo ].commit;
	assign Re					= En_Commit & I_Commit_Grant;
	assign We					= I_Store & ~Full;


	always_comb begin
		for ( int i=0; i<NUM_ENTRY; ++i ) begin
			Set_Commit[ i ]	= Commit_V[ i ].en_lane ^ Commit_V[ i ].commit;
		end
	end

    always_comb begin
        for ( int i=0; i<NUM_ENTRY; ++i ) begin
            Clr_Valid[ i ]	= Commit_V[ i ].v & Commit_V[ i ].commit;
        end
    end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			for ( int i=0; i<NUM_ENTRY; ++i ) begin
				Commit_V[ i ]	<= '0;
			end
		end
		else if ( I_Store | I_Commit_Req | ( Set_Commit != 0 ) ) begin
			if ( I_Store ) begin
				Commit_V[ WNo ].v		<= 1'b1;
				Commit_V[ WNo ].issue_no<= I_Issue_No;
				Commit_V[ WNo ].en_lane	<= 
				Commit_V[ WNo ].commit	<= 0;
			end

			if ( I_Commit_Req ) begin
				Commit_V[ RNo ].v		<= 1'b0;
			end

			for ( int i=0; i<NUM_ENTRY; ++i ) begin
				Commit_V[ i ].commit	<= Commit_V[ i ].commit | Set_Commit[ i ];
			end

			for ( int i=0; i<NUM_ENTRY; ++i ) begin
				Commit_V[ i ].v			<= Commit_V[ i ].v &  	  ~Clr_Valid[ i ];
				Commit_V[ i ].commit	<= Commit_V[ i ].commit & ~Clr_Valid[ i ];
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