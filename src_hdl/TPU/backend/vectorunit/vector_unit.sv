module vector_unit (
	input						clock,
	input						reset,
	input	v_commant_t			I_Command,
	input	instr_t				I_ThreadID_SIMT,
	input	data_t				I_Scalar_Data,
	output	data_t				O_Scalar_Data,
	output	v_address_t			O_Address,
	output	v_store_t			O_St,
	output	v_load_req_t		O_Ld,
	input	v_load_t			I_Ld,
	output	v_stat				O_Status
);


	for ( genvar i=0; i<NUM_LANE; ++i ) begin
		lane_unit (
			.clock(				clock					),
			.reset(				reset					),
			.I_En(				Lane_En[ i ]			),
			.I_ThreadID_Scalar(	i						),
			.I_ThreadID_SIMT(	I_ThreadID_SIMT			),
			.I_Command(			I_Command				),
			.I_Scalar_Data(		I_Scalar_Data			),
			.O_Scalar_Data(		Scalr_Data[ i ]			),
			.I_Path_Odd(		Path[ i + 1 ]			),
			.I_Path_Even(		Path[ i + 2 ]			),
			.O_Address1(		O_Address[0][ i ]		),
			.O_Address2(		O_Address[1][ i ]		),
			.O_Ld_Req1(			O_Ld[0].Req[ i ]		),
			.O_Ld_Req2(			O_Ld[1].Req[ i ]		),
			.I_Ld_Data1(		I_Ld[0].Data[ i ]		),
			.I_Ld_Data2(		I_Ld[1].Data[ i ]		),
			.O_St_Req1(			O_St[0].Req[ i ]		),
			.O_St_Req2(			O_St[1].Req[ i ]		),
			.O_St_Data1(		O_St[0].Data[ i ]		),
			.O_St_Data2(		O_St[0].Data[ i ]		),
			.O_Status(			O_Status[ i ]			)
		);
	end

endmodule