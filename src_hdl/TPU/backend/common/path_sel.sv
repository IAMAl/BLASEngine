module path_sel #(
	parameter NUM_ENTRY			= 16
)(
	input						clock,
	input						reset,
	input						I_Stall,				//Stall Request
	input						I_Store,				//Store Request for Routing Data
	input	[WIDTH_NUM_SRC-1:0]	I_Sel,					//Routing Data
	input	issue_no_t			I_Issue_No,				//Issue No of Routing Data
	input	issue_no_t			I_Issue_No_WB,			//Issue No from Exec Unit (WB)
	input	data_path_t			I_Data,					//Set of Source Operands
	output	data_t				O_Data,					//Send to Pipe Reg
	output	logic				O_Bypass				//Flag: Select WB Data after Pipe Reg
);


	localparam WIDTH_ENTRY		= $clog2(NUM_ENTRY);


	logic						We;
	logic						Re;
	logic	[WIDTH_ENTRY-1:0]	WNo;
	logic	[WIDTH_ENTRY-1:0]	RNo;
	logic						Empty;
	logic						Full;

	logic	[WIDTH_NUM_SRC-1:0]	Sel_Src;


	logic	[WIDTH_NUM_SRC-1:0]	SelBuff		[NUM_ENTRY-1:0];
	issue_no_t					IssueNoBuff	[NUM_ENTRY-1:0];


	logic						is_Match;


	assign We					= I_Store & ~Full;
	assign Re					= ( ~I_Stall | is_Match ) & ~Empty;

	assign is_Match				= IssueNoBuff[RNo] == I_Issue_No_WB;

	assign Sel_Src				= SelBuff[RNo];
	assign O_Data				= I_Data[Sel_Src];

	assign O_Bypass				= is_Match & ~Empty;


	//// Module: Ring-Buffer Controller
	RingBuffCTRL #(
		.NUM_ENTRY(			NUM_ENTRY					)
	) RingBuffCTRL
	(
		.clock(				clock						),
		.reset(				reset						),
		.I_We(				We							),
		.I_Re(				Re							),
		.O_WAddr(			WNo							),
		.O_RAddr(			RNo							),
		.O_Full(			Full						),
		.O_Empty(			Empty						),
		.O_Num(											)
	);

endmodule