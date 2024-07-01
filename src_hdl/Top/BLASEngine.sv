module BLASEngine (
	input						clock,
	input						reset,
	input						I_St_Req,				//Request for Storing Threadd
	output						O_St_Req,				//Request for Sending Data
	input	instr_t				I_Instr,				//Threadd Program Port
	input	top_data_t			I_Data,					//Data Input Port
	output	top_data_t			O_Data,					//Data Output Port
	output	top_stat_t			O_Status,				//System Status
	output						O_Wait					//Flag: Wait for Thread Program
);


	mpu mpu (
		.clock(					clock					),
		.reset(					reset					),
		.I_Req_St(				I_St_Req				),
		.I_Instr(				I_Instr					),
		.O_Instr(				Instr					),
		.I_Req_Commit(			),
		.I_CommitNo(			),
		.O_Wait(				O_Wait					),
		.O_Status(				O_Status				)
	);


	for ( genvar clm=0; clm<NUM_CLMS; ++clm ) begin
		for ( genvar row=0; row<NUM_ROWS; ++row ) begin
			assign RAM_S_Ld_Req[row][clm][0]	= TPU_S_Ld_Req[row+0][clm];
			assign RAM_S_Ld_Req[row][clm][1]	= TPU_S_Ld_Req[row+1][clm];
			assign RAM_S_St[row][clm][0]		= TPU_S_St[row+0][clm];
			assign RAM_S_St[row][clm][1]		= TPU_S_St[row+1][clm];
			assign RAM_V_Address[row][clm][0]	= TPU_V_Address[row+0][clm];
			assign RAM_V_Address[row][clm][1]	= TPU_V_Address[row+1][clm];
			assign RAM_V_St[row][clm][0]		= TPU_V_St[row+0][clm];
			assign RAM_V_St[row][clm][1]		= TPU_V_St[row+1][clm];
			assign RAM_V_Ld_Req[row][clm][0]	= TPU_V_Ld_Req[row+0][clm];
			assign RAM_V_Ld_Req[row][clm][1]	= TPU_V_Ld_Req[row+1][clm];
			assign TPU_S_Ld_Data[row][clm][0]	= RAM_S_Ld_Data[row+0][clm];
			assign TPU_S_Ld_Data[row][clm][1]	= RAM_S_Ld_Data[row+1][clm];
			assign TPU_V_Ld[row][clm][0]		= RAM_V_Ld[row+0][clm];
			assign TPU_V_Ld[row][clm][1]		= RAM_V_Ld[row+1][clm];
		end
	end


	for ( genvar clm=0; clm<NUM_CLMS; ++clm ) begin
		for ( genvar row=0; row<NUM_ROWS; ++row ) begin
			tpu tpu (
				.clock(				clock					),
				.reset(				reset					),
				.I_Instr(			Instr					),
				.O_S_Ld_Req(		TPU_S_Ld_Req[row][clm]	),
				.I_S_Ld_Data(		TPU_S_Ld_Data[row][clm]	),
				.O_S_St(			TPU_S_St[row][clm]		),
				.O_V_Address(		TPU_V_Address[row][clm]	),
				.O_V_St(			TPU_V_St[row][clm]		),
				.O_V_Ld(			TPU_V_Ld_Reqt[row][clm]	),
				.I_V_Ld(			TPU_V_Ld[row][clm]		),
				.O_Term(			TPU_Term[row][clm]		),
				.O_Nack(			TPU_Nack[row][clm]		)
			);

			tpu_dmem tpu_vram (
				.clock(				clock					),
				.reset(				reset					),
				.I_S_Ld_Req(		RAM_S_Ld_Req[row][clm]	),
				.O_S_Ld_Data(		RAM_S_Ld_Data[row][clm]	),
				.I_S_St(			RAM_S_St[row][clm]		),
				.I_V_Address(		RAM_V_Address[row][clm]	),
				.I_V_St(			RAM_V_St[row][clm]		),
				.I_V_Ld(			RAM_V_Ld_Req[row][clm]	),
				.O_V_Ld(			RAM_V_Ld[row][clm]		)
			);
		end
	end


	for ( genvar clm=0; clm<NUM_CLMS; ++clm ) begin
		tpu_dmem tpu_vram_e (
			.clock(			clock						),
			.reset(			reset						),
			.I_S_Ld_Req(	RAM_S_Ld_Req[NUM_ROWS][clm]	),
			.O_S_Ld_Data(	RAM_S_Ld_Data[NUM_ROWS][clm]),
			.I_S_St(		RAM_S_St[NUM_ROWS][clm]		),
			.I_V_Address(	RAM_V_Address[NUM_ROWS][clm]),
			.I_V_St(		RAM_V_St[NUM_ROWS][clm]		),
			.I_V_Ld(		RAM_V_Ld_Req[NUM_ROWS][clm]	),
			.O_V_Ld(		RAM_V_Ld[NUM_ROWS][clm]		)
		);
	end

endmodule