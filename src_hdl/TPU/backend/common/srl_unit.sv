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
#(
	parameter type TYPE			= pipe_exe_tmp_t
)(
	input						clock,
	input						reset,
	input						I_En,					//Enable to Execute
	input						I_Grant,				//Grant for End of Exec
	input	TYPE				I_Token,				//Command
	input   data_t				I_Data1,				//Source Operand
	input   data_t				I_Data2,				//Source Operand
	output  data_t				O_Valid,				//Output Valid
	output	TYPE				O_Token,				//Command
	output  data_t				O_Data					//Output Data
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

	TYPE						Token_Shift;
	TYPE						Token_Rotate;
	TYPE						Token_Logic;

	data_t						ResultData;
	TYPE						ResultToken;

	logic						Valid;
	data_t						C2;
	TYPE						Token;


	assign En_Shift				= I_En & ( I_Token.op.OpClass == 2'b00 ) & ~( Valid & I_Grant );
	assign En_Rotate			= I_En & ( I_Token.op.OpClass == 2'b01 ) & ~( Valid & I_Grant );
	assign En_Logic				= I_En & ( I_Token.op.OpClass == 2'b10 ) & ~( Valid & I_Grant );

	assign Data_Shift1			= ( En_Shift ) ?	I_Data1 : 0;
	assign Data_Shift2			= ( En_Shift ) ?	I_Data2 : 0;
	assign Data_Rotate1			= ( En_Rotate ) ?	I_Data1 : 0;
	assign Data_Rotate2			= ( En_Rotate ) ?	I_Data2 : 0;
	assign Data_Logic1			= ( En_Logic ) ?	I_Data1 : 0;
	assign Data_Logic2			= ( En_Logic ) ?	I_Data2 : 0;


	assign O_Valid				= Valid;
	assign O_Data				= C2;
	assign O_Token				= Token;


	always_comb begin
		case ( I_Token.op.OpClass )
			2'b00: ResultData	= Data_Shift;
			2'b01: ResultData	= Data_Rotate;
			2'b10: ResultData	= Data_Logic;
			default: ResultData	= '0;
		endcase
	end

	always_comb begin
		case ( I_Token.op.OpClass )
			2'b00: ResultToken	= Token_Shift;
			2'b01: ResultToken	= Token_Rotate;
			2'b10: ResultToken	= Token_Logic;
			default: ResultToken	= '0;
		endcase
	end


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Valid			<= 1'b0;
			Token			<= 0;
			C2				<= 0;
		end
		else if ( I_En ) begin
			Valid			<= 1'b1;
			Token			<= ResultToken;
			C2				<= ResultData;
		end
		else if ( I_Grant ) begin
			Valid			<= 1'b0;
			Token			<= 0;
			C2				<= 0;
		end
	end


	Shift_Unit #(
		.TYPE(				TYPE					)
	) Shift_Unit
	(
		.I_En(				En_Shift				),
		.I_Token(			I_Token					),
		.I_Data1(			Data_Shift1				),
		.I_Data2(			Data_Shift2				),
		.O_Valid(			Valid_Shift				),
		.O_Data(			Data_Shift				),
		.O_Token(			Token_Shift				)
	);


	Rotate_Unit #(
		.TYPE(				TYPE					)
	) Rotate_Unit
	(
		.I_En(				En_Rotate				),
		.I_Token(			I_Token					),
		.I_Data1(			Data_Rotate				),
		.I_Data2(			Data_Rotate				),
		.O_Valid(			Valid_Rotate			),
		.O_Data(			Data_Rotate				),
		.O_Token(			Token_Rotate			)
	);


	Logic_Unit #(
		.TYPE(				TYPE					)
	) Logic_Unit
	(
		.I_En(				En_Logic				),
		.I_Token(			I_Token					),
		.I_Data1(			Data_Logic1				),
		.I_Data2(			Data_Logic2				),
		.O_Valid(			Valid_Logic				),
		.O_Data(			Data_Logic				),
		.O_Token(			Token_Logic				)
	);

endmodule