module path_sel #(
	parameter NUM_ENTRY			= 16,
	parameter WIDTH_NUM_SRC		= 4
)(
	input						clock,
	input						reset,
	input	[WIDTH_ENTRY-1:0]	I_WNo;					//Write Pointer
	input	[WIDTH_ENTRY-1:0]	I_RNo;					//Read Pointer
	input						I_En_WB,				//Enable Write-Back
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
	logic	[WIDTH_ENTRY-1:0]	RNo;
	logic						Empty;
	logic						Full;

	logic	[WIDTH_NUM_SRC-1:0]	Sel_Src;

	logic	[WIDTH_NUM_SRC-1:0]	SelBuff		[NUM_ENTRY-1:0];
	issue_no_t					IssueNoBuff	[NUM_ENTRY-1:0];

	logic						is_Match;


	assign O_Re					= ( ~I_Stall | is_Match ) & ~Empty;

	assign is_Match				= IssueNoBuff[I_RNo] == I_Issue_No_WB;

	assign Sel_Src				= SelBuff[I_RNo];
	assign O_Data				= I_Data[Sel_Src];

	assign O_Bypass				= is_Match & ~Empty & I_En_WB;


	always_ff @( posege clock ) begin
		if ( reset ) begin
			for ( int i=0; i<NUM_ENTRY; ++i ) begin
				SelBuff[i]		<= 0;
				IssueNoBuff[i]	<= 0;
			end
		end
		else if ( I_Store ) begin
			SelBuff[I_WNo]		<= I_Sel;
			IssueNoBuff[I_WNo]	<= I_Issue_No;
		end
	end

endmodule