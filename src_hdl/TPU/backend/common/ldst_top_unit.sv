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
	input	ldst_t				O_LdSt,					//Load/Store Command
	input	data_t				I_Ld_Data,				//Loaded Data
	input	data_t				O_St_Data,				//Storing Data
	input						I_Ld_Ready,				//Ready to Load
	input						I_Ld_Grant,				//Grant for Loading
	input						I_St_Ready,				//Ready to Store
	input						I_St_Grant,				//Grant for Storing
	input						I_End_Access,			//End of Access
	input	TYPE				O_Token,				//Command
	input	data_t				O_WB_Data,				//Write-Back Data
	input						O_LdSt_Done 			//Access Done
);


	logic						Ld_Req;
	logic						St_Req;

	data_t						Ld_Data;
	data_t						St_Data;

	address_t					Ld_Length;
	address_t					St_Length;
	address_t					Ld_Stride;
	address_t					St_Stride;
	address_t					Ld_Base;
	address_t					St_Base;

	logic						Ld_Commit_Req;
	logic						St_Commit_Req;

	issue_no_t					Ld_Commit_No;
	issue_no_t					St_Commit_No;

	logic						Ld_Stall;
	logic						St_Stall;


	TYPE						Ld_Token;
	TYPE						St_Token;

	TYPE						Ld_Commit_Token;
	TYPE						St_Commit_Token;


	issue_no_t					LifeLd;
	issue_no_t					LifeSt;

	logic						Ld_Term;
	logic						St_Term;


	logic						Ld_Valid;
	logic						St_Valid;

	logic						Ld_Commit_Grant;
	logic						St_Commit_Grant;


	assign LifeLd				= I_Issue_No - Ld_Commit_No;
	assign LifeSt				= I_Issue_No - St_Commit_No;

	assign Ld_Valid				= Ld_Req;
	assign St_Valid				= St_Req;


	assign Ld_Term				= I_End_Access;
	assign St_Term				= I_End_Access;


	assign Ld_Commit_Grant		= I_Commit_Grant;
	assign St_Commit_Grant		= I_Commit_Grant;


	assign Ld_Token.v			= Ld_Req;
	assign Ld_Token.dst			= I_Command.instr.dst;
	assign Ld_Token.slice_len	= I_Command.instr.slice_len;
	assign Ld_Token.issue_no	= I_Command.issue_no;
	assign Ld_Token.path		= I_Command.instr.path;

	assign St_Token.v			= St_Req;
	assign St_Token.dst			= I_Command.instr.dst;
	assign St_Token.slice_len	= I_Command.instr.slice_len;
	assign St_Token.issue_no	= I_Command.issue_no;
	assign St_Token.path		= I_Command.instr.path;


	assign Sel_Ld1				= LifeLd >  LifeLd;
	assign Sel_Ld2				= LifeLd <= LifeLd;

	assign Sel_St1				= LifeSt >  LifeSt;
	assign Sel_St2				= LifeSt <= LifeSt;


	assign Ld_Req				= I_Req & ( I_Command.instr.op.OpType == 2'b11 ) & ~I_Command.instr.op.OpClass;
	assign St_Req				= I_Req & ( I_Command.instr.op.OpType == 2'b11 ) &  I_Command.instr.op.OpClass;

	assign St_Data				= I_Src_Data1;


	assign O_LdSt.ld.req		= Ld_Req;
	assign O_LdSt.ld.len		= Ld_Length;
	assign O_LdSt.ld.stride		= Ld_Stride;
	assign O_LdSt.ld.base		= Ld_Base;

	assign O_LdSt.st.req		= St_Req;
	assign O_LdSt.st.len		= St_Length;
	assign O_LdSt.st.stride		= St_Stride;
	assign O_LdSt.st.base		= St_Base;


	assign O_Token				= (  LifeLd >  LifeSt ) ?	Ld_Token :
															St_Token;

	assign O_WB_Data			= Ld_Data;

	assign O_LdSt_Done			= Ld_Commit_Req | St_Commit_Req;


	ldst_unit #(
		.DEPTH_BUFF(		16							),
		.DEPTH_BUFF_LDST(	DEPTH_BUFF_LDST				),
		.TYPE(				pipe_exe_tmp_t				)
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
		.I_Length(			I_Src_Src_Data1				),
		.I_Stride(			I_Src_Src_Data2				),
		.I_Base(			I_Src_Src_Data3				),
		.O_Req(				Ld_Req						),
		.O_Length(			Ld_Length					),
		.O_Stride(			Ld_Stride					),
		.O_Base(			Ld_Base						),
		.I_Token(			Ld_Token					),
		.O_Token(			Ld_Commit_Token				),
		.O_Stall(			Ld_Stall					)
	);


	ldst_unit #(
		.DEPTH_BUFF(		16							),
		.DEPTH_BUFF_LDST(	DEPTH_BUFF_LDST				),
		.TYPE(				pipe_exe_tmp_t				)
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
		.I_Length(			I_Src_Src_Data1				),
		.I_Stride(			I_Src_Src_Data2				),
		.I_Base(			I_Src_Src_Data3				),
		.O_Req(				St_Req						),
		.O_Length(			St_Length					),
		.O_Stride(			St_Stride					),
		.O_Base(			St_Base						),
		.I_Token(			St_Token					),
		.O_Token(			St_Commit_Token				),
		.O_Stall(			St_Stall					)
	);

endmodule