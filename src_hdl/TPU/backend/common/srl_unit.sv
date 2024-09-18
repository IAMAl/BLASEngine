///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	SRL_Unit
///////////////////////////////////////////////////////////////////////////////////////////////////

module SRL_Unit
	import pkg_tpu::*;
(
	input						I_En,
	input   opt_t 				I_OP,
	input   data_t				I_Data1,
	input   data_t				I_Data2,
	input   issue_no_t			I_Issue_No,
	output  data_t				O_Valid,
	output  data_t				O_Data,
	output  issue_no_t			O_Issue_No
);

	logic						En_Shift;
	logic						En_Rotate;
	logic						En_Logic;

	logic						Valid_Shift;
	logic						Valid_Rotate;
	logic						Valid_Logic;

	data_t						Data_Shift;
	data_t						Data_Rotate;
	data_t						Data_Logic;

	issue_not					Issue_No_Shift;
	issue_not					Issue_No_Rotate;
	issue_not					Issue_No_Logic;

	data_t						ResultData;
	issue_no_t					ResultINo;

	logic						Valid;
	data_t						C2;
	issue_no_t					Issue_No;


	assign En_Shift				=  I_En & ( I_Op.OpClass == 2'b00 );
	assign En_Rotate			=  I_En & ( I_Op.OpClass == 2'b01 );
	assign En_Logic				=  I_En & ( I_Op.OpClass == 2'b10 );

	assign Data_Shift1			= ( I_En & ( I_Op.OpClass == 2'b00 ) ) ? I_Data1 : 0;
	assign Data_Shift2			= ( I_En & ( I_Op.OpClass == 2'b00 ) ) ? I_Data2 : 0;
	assign Data_Rotate1			= ( I_En & ( I_Op.OpClass == 2'b01 ) ) ? I_Data1 : 0;
	assign Data_Rotate2			= ( I_En & ( I_Op.OpClass == 2'b11 ) ) ? I_Data2 : 0;
	assign Data_Logic1			= ( I_En & ( I_Op.OpClass == 2'b10 ) ) ? I_Data1 : 0;
	assign Data_Logic2			= ( I_En & ( I_Op.OpClass == 2'b10 ) ) ? I_Data2 : 0;


	assign O_Valid				= Valid;
	assign O_Data				= C2;
	assign O_Issue_No			= Issue_No;


	always_comb begin
		case ( I_Op.OpClass )
			2'b00: assign ResultData	= Data_Shift;
			2'b01: assign ResultData	= Data_Rotate;
			2'b10: assign ResultData	= Data_Logic;
			default: assign ResultData	= '0;
		endcase
	end

	always_comb begin
		case ( I_Op.OpClass )
			2'b00: assign ResultINo		= Issue_No_Shift;
			2'b01: assign ResultINo		= Issue_No_Roate;
			2'b10: assign ResultINo		= Issue_No_Logic;
			default: assign ResultINo	= '0;
		endcase
	end


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Valid			<= 1'b0;
			Issue_No		<= 0;
			C2				<= 0;
		end
		else if ( I_En ) begin
			Valid			<= 1'b0
			Issue_No		<= ResultINo;
			C2				<= ResultData;
		end
		else begin
			Valid			<= 1'b0;
			Issue_No		<= 0;
			C2				<= 0;
		end
	end


	Shift_Unit Shift_Unit (
		.I_En(				En_Shift				),
		.I_OP(				I_Op					),
		.I_Data1(			Data_Shift1				),
		.I_Data2(			Data_Shift2				),
		.I_Issue_No(		I_Issue_No				),
		.O_Valid(			Valid_Shift				),
		.O_Data(			Data_Shift				),
		.O_Issue_No(		Issue_No_Shift			)
	);

	Logic_Unit Logic_Unit (
		.I_En(				En_Rotate				),
		.I_OP(				I_Op					),
		.I_Data1(			Data_Rotate				),
		.I_Data2(			Data_Rotate				),
		.I_Issue_No(		I_Issue_No				),
		.O_Valid(			Valid_Rotate			),
		.O_Data(			Data_Rotate				),
		.O_Issue_No(		Issue_No_Rotate			)
	);

	Logic_Unit Logic_Unit (
		.I_En(				En_Logic				),
		.I_OP(				I_Op					),
		.I_Data1(			Data_Logic1				),
		.I_Data2(			Data_Logic2				),
		.I_Issue_No(		Issue_No_Logic			),
		.O_Valid(			Valid_Logic				),
		.O_Data(			Data_Logic				),
		.O_Issue_No(		Issue_No_Logic			)
	);

endmodule