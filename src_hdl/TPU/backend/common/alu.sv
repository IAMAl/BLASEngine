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
(
	input						clock,
	input						reset,
	input	issue_no_t			I_Issue_No,
	input						I_Stall,
	input						I_Req,
	input	command_t			I_Command,
	input	data_t				I_Src_Data1,
	input	data_t				I_Src_Data2,
	input	data_t				I_Src_Data3,
	output	index_t				O_WB_Index,
	output	data_t				O_WB_Data,
	output	issue_no_t			O_WB_IssueNo,
	output						O_ALU_Done
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

	index_t						MA_Index;
	index_t						iDiv_Index;
	index_t						Cnvt_Index;
	index_t						SRL_Index;


	logic						Valid_MA;
	logic						Valid_;
	logic						Valid_Cnvt;
	logic						Valid_SRL;

	data_t						Data_MA;
	data_t						Data_iDIV;
	data_t						Data_Cnvt;
	data_t						Data_SRL;

	issue_no_t					Issue_No_MA;
	issue_no_t					Issue_No_iDIV;
	issue_no_t					Issue_No_Cnvt;
	issue_no_t					Issue_No_SRL;
	index_t						Index_MA;

	index_t						Index_iDiv;
	index_t						Index_Cnvt;
	index_t						Index_SRL;


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


	assign MA_Data1				= ( En_MA ) ?	I_Src_Data1 : 0;
	assign MA_Data2				= ( En_MA ) ?	I_Src_Data2 : 0;
	assign MA_Data3				= ( En_MA ) ?	I_Src_Data3 : 0;

	assign iDIV_Data1			= ( En_iDiv ) ? I_Src_Data1 : 0;
	assign iDIV_Data2			= ( En_iDiv ) ? I_Src_Data2 : 0;

	assign Cnvt_Data1			= ( En_Cnvt ) ? I_Src_Data1 : 0;

	assign SRL_Data1			= ( En_SRL ) ?	I_Src_Data1 : 0;
	assign SRL_Data2			= ( En_SRL ) ?	I_Src_Data2 : 0;


	assign Life_MA				= I_Issue_No - Issue_No_MA;
	assign Life_iDiv			= I_Issue_No - Issue_No_MA;
	assign Life_Cnvt			= I_Issue_No - Issue_No_MA;
	assign Life_SRL				= I_Issue_No - Issue_No_MA;

	assign Sel_MA_iDiv			= ( Life_MA > Life_iDiv ) ? 	2'b00 : 2'b01;
	assign Sel_Cnvt_SRL			= ( Life_Cnvt > Life_SRL ) ?	2'b10 : 2'b11;


	always_comb begin
		case (  { Sel_Cnvt_SRL, Sel_MA_iDiv }  )
			4'b1000: begin
				assign Sel		= ( Life_Cnvt > Life_MA ) ?		2'b10 : 2'b00;

			end
			4'b1001: begin
				assign Sel		= ( Life_Cnvt > Life_iDiv ) ?	2'b10 : 2'b01;

			end
			4'b1100: begin
				assign Sel		= ( Life_iDiv > Life_MA ) ?		2'b11 : 2'b00;

			end
			4'b1101: begin
				assign Sel		= ( Life_iDiv > Life_iDiv ) ?	2'b11 : 2'b01;

			end
		endcase
	end


	assign O_ALU_Done			= (   ( Sel == 2'b00 ) & Valid_MA ) |
									( ( Sel == 2'b01 ) & Valid_iDIV ) |
									( ( Sel == 2'b10 ) & Valid_Cnvt ) |
									( ( Sel == 2'b11 ) & Valid_SRL );

	assign O_WB_Index			= (   Sel == 2'b00 ) ?	Index_MA :
									( Sel == 2'b01 ) ?	Index_iDiv :
									( Sel == 2'b10 ) ?	Index_Cnvt :
									( Sel == 2'b11 ) ?	Index_SRL :
														0;

	assign O_WB_IssueNo			= (   Sel == 2'b00 ) ?	Issue_No_MA :
									( Sel == 2'b01 ) ?	Issue_No_iDiv :
									( Sel == 2'b10 ) ?	Issue_No_Cnvt :
									( Sel == 2'b11 ) ?	Issue_No_SRL :
														0;

	assign O_WB_Data			= (   Sel == 2'b00 ) ?	Data_MA :
									( Sel == 2'b01 ) ?	Data_iDiv :
									( Sel == 2'b10 ) ?	Data_Cnvt :
									( Sel == 2'b11 ) ?	Daat_SRL :
														0;


	MA_Unit #(
		.DEPTH_MLT(			3						),
		.DEPTH_ADD(			1						),
		.TYPE(				pipe_exe_tmp_t			),
		.INT_UNit(			true					)
	) MA_Unit
	(
		.I_En(				En_MA					),
		.I_OP(				I_Command.instr.op		),
		.I_Data1(			MA_Data1				),
		.I_Data2(			MA_Data2				),
		.I_Data3(			MA_Data3				),
		.I_Index(			MA_Index				),
		.I_Issue_No(		I_Command.issue_no		),
		.O_Valid(			Valid_MA				),
		.O_Data1(			Data_MA					),
		.O_Issue_No(		Issue_No_MA				),
		.O_Index(			Index_MA				)
	);

	iDiv_Unit iDiv_Unit
	(
		.I_En(				En_iDIV					),
		.I_OP(				I_Command.instr.op		),
		.I_Data1(			iDIV_Data1				),
		.I_Data2(			iDIV_Data2				),
		.I_Index(			iDiv_Index				),
		.I_Issue_No(		I_Command.issue_no		),
		.O_Valid(			Valid_iDIV				),
		.O_Data(			Data_iDIV				),
		.O_Issue_No(		Issue_No_iDIV			),
		.O_Index(			Index_iDiv				)
	);

	Cnvt_Unit Cnvt_Unit
	(
		.I_En(				En_Cnvt					),
		.I_OP(				I_Command.instr.op		),
		.I_Index(			Cnvt_Index				),
		.I_Data1(			Cnvt_Data1				),
		.I_Issue_No(		I_Command.issue_no		),
		.O_Valid(			Valid_Cnvt				),
		.O_Data(			Data_Cnvt				),
		.O_Issue_No(		Issue_No_Cnvt			),
		.O_Index(			Index_Cnvt				)
	);

	SRL_Unit SRL_Unit
	(
		.I_En(				En_SRL					),
		.I_OP(				I_Command.instr.op		),
		.I_Data1(			SRL_Data1				),
		.I_Data2(			SRL_Data2				),
		.I_Index(			SRL_Index				),
		.I_Issue_No(		I_Command.issue_no		),
		.O_Valid(			Valid_SRL				),
		.O_Data(			Data_SRL				),
		.O_Issue_No(		Issue_No_SRL			),
		.O_Index(			Index_SRL				)
	);

endmodule