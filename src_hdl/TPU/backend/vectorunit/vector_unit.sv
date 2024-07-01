module vector_unit
	import pkg_tpu::*;
(
	input						clock,
	input						reset,
	input	[NUM_LANE-1:0]		I_En_Lane,				//Enable to Execution on Lane
	input	v_commant_t			I_Command,				//Comamnd to Execute
	input	[WIDTH_LANE-1:0]	I_Rotate_Amount1,		//Rotation Amount
	input	[WIDTH_LANE-1:0]	I_Rotate_Amount2,		//Rotation Amount
	input	instr_t				I_ThreadID_SIMT,		//SIMT Thread-ID
	input	data_t				I_Scalar_Data,			//Scalar Data
	output	data_t				O_Scalar_Data,			//Scalar Data
	input	ack_ld_t			I_Ack_Ld,				//Acknowledge fro Loading
	output	v_address_t			O_Address,				//Data Memory Address
	output	v_store_t			O_St,					//Store Request
	output	v_load_req_t		O_Ld,					//Load Request
	input	v_load_t			I_Ld,					//Loaded Data
	output	logic				O_Commmit_Req,			//Commit Request
	output	v_stat				O_Status				//Status on Lane
);


	rot_srcs_t					RotSrc_Data1;
	rot_srcs_t					RotSrc_Data2;
	rot_srcs_t					RotDst_Data1;
	rot_srcs_t					RotDst_Data2;

	logic	[NUM_LANE-1:0]		Commit;


	assign O_Commmit_Req		= &( ~( I_En_Lane ^ Commit ) );


	Rotate Rotate1 (
		.I_Rotate_Amount(		I_Rotate_Amount1		),
		.I_Srcs(				RotSrc_Data1			),
		.O_Srcs(				RotDst_Data1			)
	);

	Rotate Rotate1 (
		.I_Rotate_Amount(		I_Rotate_Amoun2			),
		.I_Srcs(				RotSrc_Data2			),
		.O_Srcs(				RotDst_Data2			)
	);


	//Vector-Lane Generation
	for ( genvar i=0; i<NUM_LANE; ++i ) begin
		lane_unit (
			.clock(				clock					),
			.reset(				reset					),
			.I_En(				Lane_En[ i ]			),
			.I_LaneID(			i						),
			.I_ThreadID_SIMT(	I_ThreadID_SIMT			),
			.I_Command(			I_Command				),
			.I_Scalar_Data(		I_Scalar_Data			),
			.O_Scalar_Data(		Scalr_Data[ i ]			),
			.O_Rotate_Src_Data1(RotSrc_Data1[ i ]		),
			.O_Rotate_Src_Data2(RotSrc_Data2[ i ]		),
			.I_Rotate_Src_Data1(RotDat_Data1[ i ]		),
			.I_Rotate_Src_Data2(RotDst_Data2[ i ]		),
			.I_Path_Odd(		Path[ i + 1 ]			),
			.I_Path_Even(		Path[ i + 2 ]			),
			.O_Address1(		O_Address[0][ i ]		),
			.O_Address2(		O_Address[1][ i ]		),
			.O_Ld_Req1(			O_Ld[0].Req[ i ]		),
			.O_Ld_Req2(			O_Ld[1].Req[ i ]		),
			.I_Ack_Ld1(			I_Ack_Ld[0][ i ]		),
			.I_Ack_Ld1(			I_Ack_Ld[1][ i ]		),
			.I_Ld_Data1(		I_Ld[0].Data[ i ]		),
			.I_Ld_Data2(		I_Ld[1].Data[ i ]		),
			.O_St_Req1(			O_St[0].Req[ i ]		),
			.O_St_Req2(			O_St[1].Req[ i ]		),
			.O_St_Data1(		O_St[0].Data[ i ]		),
			.O_St_Data2(		O_St[0].Data[ i ]		),
			.O_Commit(			Commit[ i ]				),
			.O_Status(			O_Status[ i ]			)
		);
	end

endmodule