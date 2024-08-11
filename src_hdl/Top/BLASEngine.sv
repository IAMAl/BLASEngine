///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	BLASEngine
///////////////////////////////////////////////////////////////////////////////////////////////////

module BLASEngine (
	input						clock,
	input						reset,
	input						I_Req_IF,				//Request
	output						O_St_Req,				//Request for Sending Data
	input	mpu_if_t			I_Data_IF,				//Data Input Port
	output	mpu_if_t			O_Data_IF,				//Data Output Port
	output	mpu_stat_t			O_Status,				//System Status
	output						O_Wait					//Flag: Wait for Thread Program
);


	MPU MPU (
		.clock(					clock					),
		.reset(					reset					),
		.I_Req_IF(				I_Req_IF				),
		.I_Data_IF(				I_Data_IF				),
		.O_Data_IF(				O_Data_IF				),
		.O_Instr(				Instr					),
		.I_Ld_Data(				),
		.I_Data(				),
		.O_St_Data(				),
		.O_Data(				),
		.I_Req_Commit(			),
		.I_CommitNo(			),
		.O_Wait(				O_Wait					),
		.O_Status(				O_Status				)
	);


	for ( genvar clm=0; clm<NUM_CLMS; ++clm ) begin
		for ( genvar row=0; row<NUM_ROWS; ++row ) begin
			assign RAM_S_LdSt[row][clm]			= TPU_S_Ld_Req[row][clm][0];
			assign RAM_S_Ld_Data[row][clm]		= TPU_S_Ld_Data[row][clm][0];
			assign RAM_S_ST_Data[row][clm]		= TPU_S_ST_Data[row][clm][0];

			assign RAM_V_LdSt[row][clm]			= TPU_V_Ld_Req[row][clm][0];
			assign RAM_V_Ld_Data[row][clm]		= TPU_V_Ld_Data[row][clm][0];
			assign RAM_V_ST_Data[row][clm]		= TPU_V_ST_Data[row][clm][0];

			assign RAM_S_LdSt[row+1][clm]		= TPU_S_Ld_Req[row][clm][1];
			assign RAM_S_Ld_Data[row+1][clm]	= TPU_S_Ld_Data[row][clm][1];
			assign RAM_S_ST_Data[row+1][clm]	= TPU_S_ST_Data[row][clm][1];

			assign RAM_V_LdSt[row+1][clm]		= TPU_V_Ld_Req[row][clm][1];
			assign RAM_V_Ld_Data[row+1][clm]	= TPU_V_Ld_Data[row][clm][1];
			assign RAM_V_ST_Data[row+1][clm]	= TPU_V_ST_Data[row][clm][1];
		end
	end


	for ( genvar clm=0; clm<NUM_CLMS; ++clm ) begin
		for ( genvar row=0; row<NUM_ROWS; ++row ) begin
			TPU TPU (
				.clock(			clock					),
				.reset(			reset					),
				.I_Req(			),//ToDo
				.I_Instr(		Instr					),
				.O_S_LdSt(		TPU_S_LdSt[row][clm]	),
				.I_S_Ld_Data(	TPU_S_Ld_Data[row][clm]	),
				.O_S_Ld_Data(	TPU_S_St_Data[row][clm]	),
				.O_V_LdSt(		TPU_V_LdSt[row][clm]	),
				.I_V_Ld_Data(	TPU_V_Ld_Data[row][clm]	),
				.O_V_Ld_Data(	TPU_V_St_Data[row][clm]	),
				.O_Term(		TPU_Term[row][clm]		),
				.O_Nack(		TPU_Nack[row][clm]		)
			);

			DMem_TPU DMem_TPU (
				.clock(			clock					),
				.reset(			reset					),
				.I_S_LdSt(		RAM_S_LdSt[row][clm]	),
				.O_S_Ld_Data(	RAM_S_Ld_Data[row][clm]	),
				.I_S_St_Data(	RAM_S_St_Data[row][clm]	),
				.I_V_LdSt(		RAM_V_LdSt[row][clm]	),
				.O_V_Ld_Data(	RAM_V_Ld_Data[row][clm]	),
				.I_V_St_Data(	RAM_V_St_Data[row][clm]	)
			);
		end
	end

	for ( genvar clm=0; clm<NUM_CLMS; ++clm ) begin
		DMem_TPU TDMem (
			.clock(			clock						),
			.reset(			reset						),
			.I_S_LdSt(		RAM_S_LdSt[0][clm]			),
			.O_S_Ld_Data(	RAM_S_Ld_Data[0][clm]		),
			.I_S_St_Data(	RAM_S_St_Data[0][clm]		),
			.I_V_LdSt(		RAM_V_LdSt[0][clm]			),
			.O_V_Ld_Data(	RAM_V_Ld_Data[0][clm]		),
			.I_V_St_Data(	RAM_V_St_Data[0][clm]		)
		);

		DMem_TPU BDMem (
			.clock(			clock						),
			.reset(			reset						),
			.I_S_LdSt(		RAM_S_LdSt[NUM_ROWS][clm]	),
			.O_S_Ld_Data(	RAM_S_Ld_Data[NUM_ROWS][clm]),
			.I_S_St_Data(	RAM_S_St_Data[NUM_ROWS][clm]),
			.I_V_LdSt(		RAM_V_LdSt[NUM_ROWS][clm]	),
			.O_V_Ld_Data(	RAM_V_Ld_Data[NUM_ROWS][clm]),
			.I_V_St_Data(	RAM_V_St_Data[NUM_ROWS][clm])
		);
	end

endmodule