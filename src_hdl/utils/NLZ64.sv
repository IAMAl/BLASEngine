///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	NLZ64
///////////////////////////////////////////////////////////////////////////////////////////////////

module NLZ64
(
	input	[64-1:0]			I_Data,				//Data
	output	[5:0]				O_Num,				//Number
	output						O_Valid				//Flag: Validation
);


	logic						Valid0;
	logic						Valid1;
	logic						Valid2;
	logic						Valid3;

	logic	[2:0]				Num0;
	logic	[2:0]				Num1;
	logic	[2:0]				Num2;
	logic	[2:0]				Num3;
	logic	[2:0]				Num4;
	logic	[2:0]				Num5;
	logic	[2:0]				Num6;
	logic	[2:0]				Num7;


	assign O_Valid				= Valid0 | Valid1 | Valid2 | Valid3 |Valid4 | Valid5 | Valid6 | Valid7;
	assign O_Num				= ( Valid0 ) ?		Num0 | 6'h00 :
									( Valid1 ) ?	Num1 | 6'h08 :
									( Valid2 ) ?	Num2 | 6'h10 :
									( Valid3 ) ?	Num3 | 6'h18 :
									( Valid4 ) ?	Num4 | 6'h20 :
									( Valid5 ) ?	Num5 | 6'h28 :
									( Valid6 ) ?	Num6 | 6'h30 :
									( Valid7 ) ?	Num7 | 6'h38 :
													'0;


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
		.O_Num(				Num3						),
		.O_Valid(			Valid3						)
	);


	NLZ8 NLZ4 (
		.I_Data(			I_Data[39:32]				),
		.O_Num(				Num4						),
		.O_Valid(			Valid4						)
	);


	NLZ8 NLZ5 (
		.I_Data(			I_Data[47:40]				),
		.O_Num(				Num5						),
		.O_Valid(			Valid5						)
	);


	NLZ8 NLZ6 (
		.I_Data(			I_Data[55:48]				),
		.O_Num(				Num6						),
		.O_Valid(			Valid6						)
	);


	NLZ8 NLZ7 (
		.I_Data(			I_Data[63:56]				),
		.O_Num(				Num7						),
		.O_Valid(			Valid7						)
	);

endmodule