///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	NLZ8
///////////////////////////////////////////////////////////////////////////////////////////////////

module NLZ32
(
	input	[32-1:0]			I_Data,				//Data
	output	[4:0]				O_Num,				//Number
	output	logic				O_Valid				//Flag: Validation
);

	logic						Valid0;
	logic						Valid1;
	logic						Valid2;
	logic						Valid3;

	logic	[2:0]				Num0;
	logic	[2:0]				Num1;
	logic	[2:0]				Num2;
	logic	[2:0]				Num3;

	NLZ8 NLZ0 (
		.I_Data(			I_Data[7:0]					),
		.O_Num(				Num0						),
		.O_Valid(			Valid0						)
	);

	NLZ8 NLZ1 (
		.I_Data(			I_Data[15:8]				),
		.O_Num(				Num1						),
		.O_Valid(			Valid1						)
	);

	NLZ8 NLZ2 (
		.I_Data(			I_Data[23:16]				),
		.O_Num(				Num2						),
		.O_Valid(			Valid2						)
	);

	NLZ8 NLZ3 (
		.I_Data(			I_Data[31:24]				),
		.O_Num(				Num0						),
		.O_Valid(			Valid3						)
	);

	assign O_Valid			= Valid0 | Valid1 | Valid2 | Valid3;
	assign O_Num			= ( Valid0 ) ?		{2{0}, NUm0 } :
								( Valid1 ) ?	{2{0}, NUm1 } + 5'h08 :
								( Valid2 ) ?	{2{0}, NUm2 } + 5'h10 :
								( Valid3 ) ?	{2{0}, NUm3 } + 5'h18 :
												'0;

endmodule