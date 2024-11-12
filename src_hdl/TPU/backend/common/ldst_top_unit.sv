///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	LdStUnit
///////////////////////////////////////////////////////////////////////////////////////////////////

module LdStUnit
	import	pkg_tpu::*;
	import	pkg_tpu::command_t;
#(
	parameter int DEPTH_BUFF_LDST	= 8,
	parameter type TYPE				= pipe_exe_tmp_t
)(
	input						clock,
	input						reset,
	input						I_Stall,				//Stall Request
	input						I_Commit_Grant,			//Grant of Commit
	input	issue_no_t			I_Issue_No,				//Current Issue No
	input						I_Req,					//Request from Network Stage
	input	command_t			I_Command,				//Command
	input	data_t				I_Src_Data1,			//Source Data
	input	data_t				I_Src_Data2,			//Source Data
	input	data_t				I_Src_Data3,			//Source Data
	output	ldst_t				O_LdSt,					//Load/Store Command
	input	data_t				I_Ld_Data,				//Loaded Data
	output	data_t				O_St_Data,				//Storing Data
	input						I_Ld_Ready,				//Ready to Load
	input						I_Ld_Grant,				//Grant for Loading
	input						I_St_Ready,				//Ready to Store
	input						I_St_Grant,				//Grant for Storing
	input						I_End_Access,			//End of Access
	output	TYPE				O_WB_Token,				//Command
	output	data_t				O_WB_Data,				//Write-Back Data
	output						O_Ld_Stall,				//Stall Request from Loading
	output						O_St_Stall,				//Stall Request from Storing
	output						O_LdSt_Done 			//Access Done
);


	logic						Ld_Req;
	logic						St_Req;

	logic						Ld_Req_;
	logic						St_Req_;

	data_t						Ld_Data;
	data_t						St_Data;

	address_t					Ld_Length;
	address_t					St_Length;
	stride_t					Ld_Stride;
	stride_t					St_Stride;
	address_t					Ld_Base;
	address_t					St_Base;

	logic						Ld_Stall;
	logic						St_Stall;


	TYPE						Ld_Token;
	TYPE						St_Token;

	TYPE						Ld_Commit_Token;
	TYPE						St_Commit_Token;


	logic	[WIDTH_ENTRY_HAZARD:0]	DiffLd;
	logic	[WIDTH_ENTRY_HAZARD:0]	DiffSt;

	issue_no_t					LifeLd;
	issue_no_t					LifeSt;

	logic						Ld_Term;
	logic						St_Term;


	logic						Ld_Valid;
	logic						St_Valid;

	logic						Ld_Commit_Grant;
	logic						St_Commit_Grant;


	logic [WIDTH_SIZE_DMEM-1:0]	Length;
	stride_t					Stride;
	logic [WIDTH_SIZE_DMEM-1:0]	Base_Address;


	assign Length				= I_Src_Data1[WIDTH_SIZE_DMEM-1:0];
	assign Stride				= I_Src_Data1[WIDTH_DATA-1:WIDTH_DATA-WIDTH_STRIDE];
	assign Base_Address			= I_Src_Data2[WIDTH_SIZE_DMEM-1:0];


	assign DiffLd				= I_Issue_No - Ld_Commit_Token.issue_no;
	assign DiffSt				= I_Issue_No - St_Commit_Token.issue_no;

	assign LifeLd				= ( DiffLd[WIDTH_ENTRY_HAZARD] ) ?	 ~DiffLd[WIDTH_ENTRY_HAZARD-1:0] + 1'b1 :
																	  DiffLd[WIDTH_ENTRY_HAZARD-1:0] ;
	assign LifeSt				= ( DiffSt[WIDTH_ENTRY_HAZARD] ) ?	 ~DiffSt[WIDTH_ENTRY_HAZARD-1:0] + 1'b1 :
																	  DiffSt[WIDTH_ENTRY_HAZARD-1:0] ;

	assign Ld_Req				= I_Req & ( I_Command.instr.op.OpType == 2'b11 ) & ~I_Command.instr.op.OpClass[1];
	assign St_Req				= I_Req & ( I_Command.instr.op.OpType == 2'b11 ) &  I_Command.instr.op.OpClass[1];


	assign Ld_Valid				= Ld_Req;//ToDo
	assign St_Valid				= St_Req;//ToDo


	assign Ld_Term				= I_End_Access;
	assign St_Term				= I_End_Access;

	assign Ld_Commit_Grant		= I_Commit_Grant;
	assign St_Commit_Grant		= I_Commit_Grant;


	assign O_Ld_Stall			= Ld_Stall;
	assign O_St_Stall			= St_Stall;


	assign Ld_Token.v			= Ld_Req;
	assign Ld_Token.op			= I_Command.instr.op;
	assign Ld_Token.dst			= I_Command.instr.dst;
	assign Ld_Token.slice_len	= I_Command.instr.slice_len;
	assign Ld_Token.path		= I_Command.instr.path;
	assign Ld_Token.mread		= I_Command.instr.mread;
	assign Ld_Token.issue_no	= I_Command.issue_no;

	assign St_Token.v			= St_Req;
	assign St_Token.op			= I_Command.instr.op;
	assign St_Token.dst			= I_Command.instr.dst;
	assign St_Token.slice_len	= I_Command.instr.slice_len;
	assign St_Token.path		= I_Command.instr.path;
	assign St_Token.mread		= I_Command.instr.mread;
	assign St_Token.issue_no	= I_Command.issue_no;

	assign St_Data				= I_Src_Data3;


	assign O_LdSt.ld.req		= Ld_Req_;
	assign O_LdSt.ld.len		= Ld_Length;
	assign O_LdSt.ld.stride		= Ld_Stride;
	assign O_LdSt.ld.base		= Ld_Base;

	assign O_LdSt.st.req		= St_Req_;
	assign O_LdSt.st.len		= St_Length;
	assign O_LdSt.st.stride		= St_Stride;
	assign O_LdSt.st.base		= St_Base;


	assign O_WB_Token			= (  LifeLd >  LifeSt ) ?	Ld_Commit_Token :
															St_Commit_Token;

	assign O_WB_Data			= Ld_Data;

	assign O_LdSt_Done			= Ld_Term | St_Term;


	ldst_unit #(
		.DEPTH_BUFF(		16							),
		.DEPTH_BUFF_LDST(	DEPTH_BUFF_LDST				),
		.TYPE(				TYPE						)
	) ld_unit
	(
		.clock(				clock						),
		.reset(				reset						),
		.I_Stall(			I_Stall						),
		.I_Commit_Grant(	Ld_Commit_Grant				),
		.I_Access_Grant(	I_Ld_Grant					),
		.I_Valid(			Ld_Valid					),
		.I_Data(			I_Ld_Data					),
		.O_Data(			Ld_Data						),
		.I_Term(			Ld_Term						),
		.I_Req(				Ld_Req						),
		.I_Length(			Length						),
		.I_Stride(			Stride						),
		.I_Base(			Base_Address				),
		.O_Req(				Ld_Req_						),
		.O_Length(			Ld_Length					),
		.O_Stride(			Ld_Stride					),
		.O_Base(			Ld_Base						),
		.I_Ready(			I_Ld_Ready					),
		.I_Token(			Ld_Token					),
		.O_Token(			Ld_Commit_Token				),
		.O_Stall(			Ld_Stall					)
	);


	ldst_unit #(
		.DEPTH_BUFF(		16							),
		.DEPTH_BUFF_LDST(	DEPTH_BUFF_LDST				),
		.TYPE(				TYPE						)
	) st_unit
	(
		.clock(				clock						),
		.reset(				reset						),
		.I_Stall(			I_Stall						),
		.I_Commit_Grant(	St_Commit_Grant				),
		.I_Access_Grant(	I_St_Grant					),
		.I_Valid(			St_Valid					),
		.I_Data(			St_Data						),
		.O_Data(			O_St_Data					),
		.I_Term(			St_Term						),
		.I_Req(				St_Req						),
		.I_Length(			Length						),
		.I_Stride(			Stride						),
		.I_Base(			Base_Address				),
		.O_Req(				St_Req_						),
		.O_Length(			St_Length					),
		.O_Stride(			St_Stride					),
		.O_Base(			St_Base						),
		.I_Ready(			I_St_Ready					),
		.I_Token(			St_Token					),
		.O_Token(			St_Commit_Token				),
		.O_Stall(			St_Stall					)
	);

endmodule