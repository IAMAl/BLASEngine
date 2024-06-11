module BLASEngine (
	input						clock,
	input						reset,
	input						I_St_Req,
	output						O_St_Req,
	input	instr_t				I_Instr,
	input	top_data_t			I_Data,
	output	top_data_t			O_Data,
	output	top_stat_t			O_Status
);

	mpu mpu (
		.clock(					clock					),
		.reset(					reset					),
		.I_Req_St(				I_St_Req				),
		.O_Req_St(				O_St_Req				),
		.I_Instr(				I_Instr					),
		.O_Instr(				Instr					),
		.O_Wait(				),
		.O_Status(				)
	);


	for ( genvar clm=0; clm<NUM_CLMS; ++clm ) begin
		for ( genvar row=0; row<NUM_ROWS; ++row ) begin
			assign RAM_S_Ld_Req[row][clm]	= TPU_S_Ld_Req[][];
			assign RAM_S_St[row][clm]		= TPU_S_St[][];
			assign RAM_V_Address[row][clm]	= TPU_V_Address[][];
			assign RAM_V_St[row][clm]		= TPU_V_St[][];
			assign RAM_V_Ld_Req[row][clm]	= TPU_V_Ld_Req[][];
			assign TPU_S_Ld_Data[row][clm]	= RAM_S_Ld_Data[][];
			assign TPU_V_Ld[row][clm]		= RAM_V_Ld[][];
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
				.I_V_Ld(			TPU_V_Ld[row][clm]		)
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

endmodule