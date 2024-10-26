///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	ALU
///////////////////////////////////////////////////////////////////////////////////////////////////

module ALU
	import pkg_tpu::*;
#(
	parameter type TYPE			= pipe_exe_tmp_t,
	parameter int INT_UNIT		= 1
)(
	input						clock,
	input						reset,
	input	issue_no_t			I_Issue_No,				//Current Issue No
	input						I_Stall,				//Stall Request
	input						I_Req,					//Request from Network Stage
	input	command_t			I_Command,				//Command
	input	data_t				I_Src_Data1,			//Source Data
	input	data_t				I_Src_Data2,			//Source Data
	input	data_t				I_Src_Data3,			//Source Data
	input						I_Re_p0,				//Read-Enable for Pipeline Register
	input						I_Re_p1,				//Read-Enable for Pipeline Register
	output	TYPE				O_WB_Token,				//Write-Back Information
	output	data_t				O_WB_Data,				//Write-Back Data
	output						O_ALU_Done				//Executed
);


	logic						En_MA;
	logic						En_iDiv;
	logic						En_Cnvt;
	logic						En_SRL;


	issue_no_t					Life_MA;
	issue_no_t					Life_iDiv;
	issue_no_t					Life_Cnvt;
	issue_no_t					Life_SRL;

	issue_no_t					Life_MA_iDiv;
	issue_no_t					Life_Cnvt_SRL;
	issue_no_t					Life;

	logic	[1:0]				Sel_MA_iDiv;
	logic	[1:0]				Sel_Cnvt_SRL;
	logic	[1:0]				Sel;


	logic						is_Arith;
	logic						is_SRL;

	logic						is_Adder;
	logic						is_Mult;
	logic						is_Div;
	logic						is_Cnvt;


	data_t						MA_Data1;
	data_t						MA_Data2;
	data_t						MA_Data3;
	data_t						iDIV_Data1;
	data_t						iDIV_Data2;
	data_t						Cnvt_Data1;
	data_t						SRL_Data1;
	data_t						SRL_Data2;

	TYPE						MA_Token;
	TYPE						iDiv_Token;
	TYPE						Cnvt_Token;
	TYPE						SRL_Token;


	logic						Valid_MA;
	logic						Valid_iDiv;
	logic						Valid_Cnvt;
	logic						Valid_SRL;

	data_t						Data_MA;
	data_t						Data_iDiv;
	data_t						Data_Cnvt;
	data_t						Data_SRL;

	TYPE						Token_MA;
	TYPE						Token_iDiv;
	TYPE						Token_Cnvt;
	TYPE						Token_SRL;


	assign is_Arith				= I_Req & ( I_Command.instr.op.OpType == 2'b00 );
	assign is_SRL				= I_Req & ( I_Command.instr.op.OpType == 2'b10 );

	assign is_Adder				= I_Command.instr.op.OpClass == 2'b00;
	assign is_Mult				= I_Command.instr.op.OpClass == 2'b01;
	assign is_Div				= I_Command.instr.op.OpClass == 2'b10;
	assign is_Cnvt				= I_Command.instr.op.OpClass == 2'b11;


	assign En_MA				= is_Arith & ( is_Adder | is_Mult );
	assign En_iDiv				= is_Arith & is_Div;
	assign En_Cnvt				= is_Arith & is_Cnvt;

	assign En_SRL				= is_SRL;


	assign MA_Token.v			= ( En_MA & ~I_Stall ) ?	I_Req : 					'0;
	assign MA_Token.op			= ( En_MA & ~I_Stall ) ?	I_Command.instr.op :		'0;
	assign MA_Token.dst			= ( En_MA & ~I_Stall ) ?	I_Command.instr.dst :	 	'0;
	assign MA_Token.slice_len	= ( En_MA & ~I_Stall ) ?	I_Command.instr.slice_len : '0;
	assign MA_Token.path		= ( En_MA & ~I_Stall ) ?	I_Command.instr.path :		'0;
	assign MA_Token.issue_no	= ( En_MA & ~I_Stall ) ?	I_Command.issue_no : 		'0;

	assign iDiv_Token.v			= ( En_iDiv & ~I_Stall ) ?	I_Req : 					'0;
	assign iDiv_Token.op		= ( En_iDiv & ~I_Stall ) ?	I_Command.instr.op :		'0;
	assign iDiv_Token.dst		= ( En_iDiv & ~I_Stall ) ?	I_Command.instr.dst :	 	'0;
	assign iDiv_Token.slice_len	= ( En_iDiv & ~I_Stall ) ?	I_Command.instr.slice_len : '0;
	assign iDiv_Token.path		= ( En_iDiv & ~I_Stall ) ?	I_Command.instr.path :		'0;
	assign iDiv_Token.issue_no	= ( En_iDiv & ~I_Stall ) ?	I_Command.issue_no : 		'0;

	assign Cnvt_Token.v			= ( En_Cnvt & ~I_Stall ) ?	I_Req : 					'0;
	assign Cnvt_Token.op		= ( En_Cnvt & ~I_Stall ) ?	I_Command.instr.op :		'0;
	assign Cnvt_Token.dst		= ( En_Cnvt & ~I_Stall ) ?	I_Command.instr.dst :	 	'0;
	assign Cnvt_Token.slice_len	= ( En_Cnvt & ~I_Stall ) ?	I_Command.instr.slice_len : '0;
	assign Cnvt_Token.path		= ( En_Cnvt & ~I_Stall ) ?	I_Command.instr.path :		'0;
	assign Cnvt_Token.issue_no	= ( En_Cnvt & ~I_Stall ) ?	I_Command.issue_no : 		'0;

	assign SRL_Token.v			= ( En_SRL & ~I_Stall ) ?	I_Req : 					'0;
	assign SRL_Token.op			= ( En_SRL & ~I_Stall ) ?	I_Command.instr.op :		'0;
	assign SRL_Token.dst		= ( En_SRL & ~I_Stall ) ?	I_Command.instr.dst :	 	'0;
	assign SRL_Token.slice_len	= ( En_SRL & ~I_Stall ) ?	I_Command.instr.slice_len : '0;
	assign SRL_Token.path		= ( En_SRL & ~I_Stall ) ?	I_Command.instr.path :		'0;
	assign SRL_Token.issue_no	= ( En_MA & ~I_Stall ) ?	I_Command.issue_no : 		'0;


	assign MA_Data1				= ( En_MA & ~I_Stall ) ?	I_Src_Data1 : 0;
	assign MA_Data2				= ( En_MA & ~I_Stall ) ?	I_Src_Data2 : 0;
	assign MA_Data3				= ( En_MA & ~I_Stall ) ?	I_Src_Data3 : 0;

	assign iDIV_Data1			= ( En_iDiv & ~I_Stall ) ?	I_Src_Data1 : 0;
	assign iDIV_Data2			= ( En_iDiv & ~I_Stall ) ?	I_Src_Data2 : 0;

	assign Cnvt_Data1			= ( En_Cnvt & ~I_Stall ) ?	I_Src_Data1 : 0;

	assign SRL_Data1			= ( En_SRL & ~I_Stall ) ?	I_Src_Data1 : 0;
	assign SRL_Data2			= ( En_SRL ) & ~I_Stall ?	I_Src_Data2 : 0;


	assign Life_MA				= I_Issue_No - Token_MA.issue_no;
	assign Life_iDiv			= I_Issue_No - Token_iDiv.issue_no;
	assign Life_Cnvt			= I_Issue_No - Token_Cnvt.issue_no;
	assign Life_SRL				= I_Issue_No - Token_SRL.issue_no;

	assign Sel_MA_iDiv			= ( Life_MA > Life_iDiv ) ? 	2'b00 : 2'b01;
	assign Sel_Cnvt_SRL			= ( Life_Cnvt > Life_SRL ) ?	2'b10 : 2'b11;


	always_comb begin
		case ( { Sel_Cnvt_SRL, Sel_MA_iDiv } )
			4'b1000: begin
				Sel		= ( Life_Cnvt > Life_MA ) ?		2'b10 : 2'b00;
			end
			4'b1001: begin
				Sel		= ( Life_Cnvt > Life_iDiv ) ?	2'b10 : 2'b01;
			end
			4'b1100: begin
				Sel		= ( Life_iDiv > Life_MA ) ?		2'b11 : 2'b00;
			end
			4'b1101: begin
				Sel		= ( Life_iDiv > Life_iDiv ) ?	2'b11 : 2'b01;
			end
			default: begin
				Sel		= 2'b00;
			end
		endcase
	end


	assign O_ALU_Done			= (   ( Sel == 2'b00 ) & Valid_MA ) |
									( ( Sel == 2'b01 ) & Valid_iDiv ) |
									( ( Sel == 2'b10 ) & Valid_Cnvt ) |
									( ( Sel == 2'b11 ) & Valid_SRL );

	assign O_WB_Token			= (   Sel == 2'b00 ) ?	Token_MA :
									( Sel == 2'b01 ) ?	Token_iDiv :
									( Sel == 2'b10 ) ?	Token_Cnvt :
									( Sel == 2'b11 ) ?	Token_SRL :
														0;

	assign O_WB_Data			= (   Sel == 2'b00 ) ?	Data_MA :
									( Sel == 2'b01 ) ?	Data_iDiv :
									( Sel == 2'b10 ) ?	Data_Cnvt :
									( Sel == 2'b11 ) ?	Data_SRL :
														0;


	MA_Unit #(
		.DEPTH_MLT(			3						),
		.DEPTH_ADD(			1						),
		.TYPE(				TYPE					),
		.INT_UNIT(			INT_UNIT				)
	) MA_Unit
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_En(				En_MA					),
		.I_Data1(			MA_Data1				),
		.I_Data2(			MA_Data2				),
		.I_Data3(			MA_Data3				),
		.I_Re_p0(			I_Re_p0					),
		.I_Re_p1(			I_Re_p1					),
		.I_Token(			MA_Token				),
		.O_Valid(			Valid_MA				),
		.O_Data(			Data_MA					),
		.O_Token(			Token_MA				)
	);


	iDiv_Unit iDiv_Unit
	(
		//.clock(				clock					),
		//.reset(				reset					),
		.I_En(				En_iDiv					),
		.I_Data1(			iDIV_Data1				),
		.I_Data2(			iDIV_Data2				),
		.I_Token(			iDiv_Token				),
		.O_Valid(			Valid_iDiv				),
		.O_Data(			Data_iDiv				),
		.O_Token(			Token_iDiv				)
	);


	Cnvt_Unit Cnvt_Unit
	(
		//.clock(				clock					),
		//.reset(				reset					),
		.I_En(				En_Cnvt					),
		.I_Token(			Cnvt_Token				),
		.I_Data1(			Cnvt_Data1				),
		.O_Valid(			Valid_Cnvt				),
		.O_Data(			Data_Cnvt				),
		.O_Token(			Token_Cnvt				)
	);


	SRL_Unit #(
		.TYPE(				TYPE					)
	) SRL_Unit
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_En(				En_SRL					),
		.I_Data1(			SRL_Data1				),
		.I_Data2(			SRL_Data2				),
		.I_Token(			SRL_Token				),
		.O_Valid(			Valid_SRL				),
		.O_Data(			Data_SRL				),
		.O_Token(			Token_SRL				)
	);

endmodule