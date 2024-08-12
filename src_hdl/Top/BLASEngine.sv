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


	s_ldst_t					TPU_S_Ld_LdSt	[TPU_ROWS-1:0][TPU_CLMS-1:0][1:0];
	v_ldst_t					TPU_V_Ld_LdSt	[TPU_ROWS-1:0][TPU_CLMS-1:0][1:0];

	s_ldst_t					RAM_S_Ld_LdSt	[TPU_ROWS+1:0][TPU_CLMS-1:0][1:0];
	v_ldst_t					RAM_V_Ld_LdSt	[TPU_ROWS+1:0][TPU_CLMS-1:0][1:0];


	data_t						TPU_S_Ld_Data	[TPU_ROWS-1:0][TPU_CLMS-1:0][1:0];
	data_t						TPU_S_St_Data	[TPU_ROWS-1:0][TPU_CLMS-1:0][1:0];

	v_data_t					TPU_V_Ld_Data	[TPU_ROWS-1:0][TPU_CLMS-1:0][1:0];
	v_data_t					TPU_V_St_Data	[TPU_ROWS-1:0][TPU_CLMS-1:0][1:0];

	data_t						RAM_S_Ld_Data	[TPU_ROWS+1:0][TPU_CLMS-1:0][1:0];
	data_t						RAM_S_St_Data	[TPU_ROWS+1:0][TPU_CLMS-1:0][1:0];

	v_data_t					RAM_V_Ld_Data	[TPU_ROWS+1:0][TPU_CLMS-1:0][1:0];
	v_data_t					RAM_V_St_Data	[TPU_ROWS+1:0][TPU_CLMS-1:0][1:0];


	logic	[1:0]				TPU_S_Ld_Ready	[TPU_ROWS-1:0][TPU_CLMS-1:0][1:0];
	logic	[1:0]				TPU_S_Ld_Grant	[TPU_ROWS-1:0][TPU_CLMS-1:0][1:0];
	logic	[1:0]				TPU_S_St_Ready	[TPU_ROWS-1:0][TPU_CLMS-1:0][1:0];
	logic	[1:0]				TPU_S_St_Grant	[TPU_ROWS-1:0][TPU_CLMS-1:0][1:0];

	v_ready_t					TPU_V_Ld_Ready	[TPU_ROWS-1:0][TPU_CLMS-1:0][1:0];
	v_grant_t					TPU_V_Ld_Grant	[TPU_ROWS-1:0][TPU_CLMS-1:0][1:0];
	v_ready_t					TPU_V_St_Ready	[TPU_ROWS-1:0][TPU_CLMS-1:0][1:0];
	v_grant_t					TPU_V_St_Grant	[TPU_ROWS-1:0][TPU_CLMS-1:0][1:0];

	logic	[1:0]				RAM_S_Ld_Ready	[TPU_ROWS+1:0][TPU_CLMS-1:0][1:0];
	logic	[1:0]				RAM_S_Ld_Grant	[TPU_ROWS+1:0][TPU_CLMS-1:0][1:0];
	logic	[1:0]				RAM_S_St_Ready	[TPU_ROWS+1:0][TPU_CLMS-1:0][1:0];
	logic	[1:0]				RAM_S_St_Grant	[TPU_ROWS+1:0][TPU_CLMS-1:0][1:0];

	v_ready_t					RAM_V_Ld_Ready	[TPU_ROWS+1:0][TPU_CLMS-1:0][1:0];
	v_grant_t					RAM_V_Ld_Grant	[TPU_ROWS+1:0][TPU_CLMS-1:0][1:0];
	v_ready_t					RAM_V_St_Ready	[TPU_ROWS+1:0][TPU_CLMS-1:0][1:0];
	v_grant_t					RAM_V_St_Grant	[TPU_ROWS+1:0][TPU_CLMS-1:0][1:0];


	MPU MPU (
		.clock(					clock					),
		.reset(					reset					),
		.I_Req_IF(				I_Req_IF				),
		.I_Data_IF(				I_Data_IF				),
		.O_Data_IF(				O_Data_IF				),
		.O_Instr(				Instr					),
		.I_Ld_Data(				),//ToDo
		.I_Data(				),//ToDo
		.O_St_Data(				),//ToDo
		.O_Data(				),//ToDo
		.I_Req_Commit(			),//ToDo
		.I_CommitNo(			),//ToDo
		.O_Wait(				O_Wait					),
		.O_Status(				O_Status				)
	);


	for ( genvar clm=0; clm<NUM_CLMS; ++clm ) begin
		for ( genvar row=0; row<NUM_ROWS; ++row ) begin
			assign RAM_S_LdSt[row][clm]			= TPU_S_Ld_LdSt[row][clm][0];
			assign RAM_S_Ld_Data[row][clm]		= TPU_S_Ld_Data[row][clm][0];
			assign RAM_S_ST_Data[row][clm]		= TPU_S_ST_Data[row][clm][0];

			assign RAM_V_LdSt[row][clm]			= TPU_V_Ld_LdSt[row][clm][0];
			assign RAM_V_Ld_Data[row][clm]		= TPU_V_Ld_Data[row][clm][0];
			assign RAM_V_ST_Data[row][clm]		= TPU_V_ST_Data[row][clm][0];

			assign RAM_S_LdSt[row+1][clm]		= TPU_S_Ld_LdSt[row][clm][1];
			assign RAM_S_Ld_Data[row+1][clm]	= TPU_S_Ld_Data[row][clm][1];
			assign RAM_S_ST_Data[row+1][clm]	= TPU_S_ST_Data[row][clm][1];

			assign RAM_V_LdSt[row+1][clm]		= TPU_V_Ld_LdSt[row][clm][1];
			assign RAM_V_Ld_Data[row+1][clm]	= TPU_V_Ld_Data[row][clm][1];
			assign RAM_V_ST_Data[row+1][clm]	= TPU_V_ST_Data[row][clm][1];

			assign TPU_S_Ld_Ready[row][clm][0]	= RAM_S_Ld_Ready[row][clm];
			assign TPU_S_Ld_Grant[row][clm][0]	= RAM_S_Ld_Grant[row][clm];
			assign TPU_S_St_Ready[row][clm][0]	= RAM_S_St_Ready[row][clm];
			assign TPU_S_St_Grant[row][clm][0]	= RAM_S_St_Grant[row][clm];

			assign TPU_S_Ld_Ready[row][clm][1]	= RAM_S_Ld_Ready[row+1][clm];
			assign TPU_S_Ld_Grant[row][clm][1]	= RAM_S_Ld_Grant[row+1][clm];
			assign TPU_S_St_Ready[row][clm][1]	= RAM_S_St_Ready[row+1][clm];
			assign TPU_S_St_Grant[row][clm][1]	= RAM_S_St_Grant[row+1][clm];

			assign TPU_V_Ld_Ready[row][clm][0]	= RAM_V_Ld_Ready[row][clm];
			assign TPU_V_Ld_Grant[row][clm][0]	= RAM_V_Ld_Grant[row][clm];
			assign TPU_V_St_Ready[row][clm][0]	= RAM_V_St_Ready[row][clm];
			assign TPU_V_St_Grant[row][clm][0]	= RAM_V_St_Grant[row][clm];

			assign TPU_V_Ld_Ready[row][clm][1]	= RAM_V_Ld_Ready[row+1][clm];
			assign TPU_V_Ld_Grant[row][clm][1]	= RAM_V_Ld_Grant[row+1][clm];
			assign TPU_V_St_Ready[row][clm][1]	= RAM_V_St_Ready[row+1][clm];
			assign TPU_V_St_Grant[row][clm][1]	= RAM_V_St_Grant[row+1][clm];
		end
	end


	for ( genvar clm=0; clm<NUM_CLMS; ++clm ) begin
		for ( genvar row=0; row<NUM_ROWS; ++row ) begin
			TPU TPU (
				.clock(			clock						),
				.reset(			reset						),
				.I_Req(			),//ToDo
				.I_Instr(		Instr						),
				.O_S_LdSt(		TPU_S_LdSt[row][clm]		),
				.I_S_Ld_Data(	TPU_S_Ld_Data[row][clm]		),
				.O_S_Ld_Data(	TPU_S_St_Data[row][clm]		),
				.I_S_Ld_Ready(	TPU_S_Ld_Ready[row][clm]	),
				.I_S_St_Ready(	TPU_S_St_Ready[row][clm]	),
				.I_S_Ld_Grant(	TPU_S_Ld_Grant[row][clm]	),
				.I_S_St_Grant(	TPU_S_St_Grant[row][clm]	),
				.O_V_LdSt(		TPU_V_LdSt[row][clm]		),
				.I_V_Ld_Data(	TPU_V_Ld_Data[row][clm]		),
				.O_V_Ld_Data(	TPU_V_St_Data[row][clm]		),
				.O_V_Ld_Ready(	TPU_V_Ld_Ready[row][clm]	),
				.O_V_St_Ready(	TPU_V_St_Ready[row][clm]	),
				.O_V_Ld_Grant(	TPU_V_Ld_Grant[row][clm]	),
				.O_V_St_Grant(	TPU_V_St_Grant[row][clm]	),
				.O_Term(		TPU_Term[row][clm]			),
				.O_Nack(		TPU_Nack[row][clm]			)
			);

			DMem_TPU DMem_TPU (
				.clock(			clock						),
				.reset(			reset						),
				.I_S_LdSt(		RAM_S_LdSt[row][clm]		),
				.O_S_Ld_Data(	RAM_S_Ld_Data[row][clm]		),
				.I_S_St_Data(	RAM_S_St_Data[row][clm]		),
				.O_S_Ld_Ready(	RAM_S_Ld_Ready[row][clm]	),
				.O_S_St_Ready(	RAM_S_St_Ready[row][clm]	),
				.O_S_Ld_Grant(	RAM_S_Ld_Grant[row][clm]	),
				.O_S_St_Grant(	RAM_S_St_Grant[row][clm]	),
				.I_V_LdSt(		RAM_V_LdSt[row][clm]		),
				.O_V_Ld_Data(	RAM_V_Ld_Data[row][clm]		),
				.I_V_St_Data(	RAM_V_St_Data[row][clm]		),
				.O_V_Ld_Ready(	RAM_V_Ld_Ready[row][clm]	),
				.O_V_St_Ready(	RAM_V_St_Ready[row][clm]	),
				.O_V_Ld_Grant(	RAM_V_Ld_Grant[row][clm]	),
				.O_V_St_Grant(	RAM_V_St_Grant[row][clm]	)
			);
		end
	end


	for ( genvar clm=0; clm<NUM_CLMS; ++clm ) begin
		DMem_TPU TDMem (
			.clock(			clock							),
			.reset(			reset							),
			.I_S_LdSt(		RAM_S_LdSt[0][clm]				),
			.O_S_Ld_Data(	RAM_S_Ld_Data[0][clm]			),
			.I_S_St_Data(	RAM_S_St_Data[0][clm]			),
			.O_S_Ld_Ready(	RAM_S_Ld_Ready[0][clm]			),
			.O_S_St_Ready(	RAM_S_St_Ready[0][clm]			),
			.O_S_Ld_Grant(	RAM_S_Ld_Grant[0][clm]			),
			.O_S_St_Grant(	RAM_S_St_Grant[0][clm]			),
			.I_V_LdSt(		RAM_V_LdSt[0][clm]				),
			.O_V_Ld_Data(	RAM_V_Ld_Data[0][clm]			),
			.I_V_St_Data(	RAM_V_St_Data[0][clm]			),
			.O_V_Ld_Ready(	RAM_V_Ld_Ready[0][clm]			),
			.O_V_St_Ready(	RAM_V_St_Ready[0][clm]			),
			.O_V_Ld_Grant(	RAM_V_Ld_Grant[0][clm]			),
			.O_V_St_Grant(	RAM_V_St_Grant[0][clm]			)
		);

		DMem_TPU BDMem (
			.clock(			clock							),
			.reset(			reset							),
			.I_S_LdSt(		RAM_S_LdSt[NUM_ROWS][clm]		),
			.O_S_Ld_Data(	RAM_S_Ld_Data[NUM_ROWS][clm]	),
			.I_S_St_Data(	RAM_S_St_Data[NUM_ROWS][clm]	),
			.O_S_Ld_Ready(	RAM_S_Ld_Ready[NUM_ROWS][clm]	),
			.O_S_St_Ready(	RAM_S_St_Ready[NUM_ROWS][clm]	),
			.O_S_Ld_Grant(	RAM_S_Ld_Grant[NUM_ROWS][clm]	),
			.O_S_St_Grant(	RAM_S_St_Grant[NUM_ROWS][clm]	),
			.I_V_LdSt(		RAM_V_LdSt[NUM_ROWS][clm]		),
			.O_V_Ld_Data(	RAM_V_Ld_Data[NUM_ROWS][clm]	),
			.I_V_St_Data(	RAM_V_St_Data[NUM_ROWS][clm]	),
			.O_V_Ld_Ready(	RAM_V_Ld_Ready[NUM_ROWS][clm]	),
			.O_V_St_Ready(	RAM_V_St_Ready[NUM_ROWS][clm]	),
			.O_V_Ld_Grant(	RAM_V_Ld_Grant[NUM_ROWS][clm]	),
			.O_V_St_Grant(	RAM_V_St_Grant[NUM_ROWS][clm]	)
		);
	end

endmodule