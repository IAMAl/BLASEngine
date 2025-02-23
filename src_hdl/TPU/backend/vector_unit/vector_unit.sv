///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	Vector_Unit
///////////////////////////////////////////////////////////////////////////////////////////////////

module Vector_Unit
	import pkg_tpu::NUM_LANES;
	import pkg_tpu::*;
	import pkg_mpu::*;
(
	input						clock,
	input						reset,
	input	v_1b_t				I_En_Lane,				//Enable to Execution on Lane
	input	id_t				I_ThreadID,				//SIMT Thread-ID
	input	pipe_index_t		I_Command,				//Comamnd to Execute
	input	data_t				I_Scalar_Data,			//Scalar Data
	output	data_t				O_Scalar_Data,			//Scalar Data
	output	v_ldst_t			O_LdSt,					//Load Request
	input	v_ldst_data_t		I_Ld_Data,				//Loaded Data
	output	v_ldst_data_t		O_St_Data,				//Storing Data
	input	v_2b_t				I_Ld_Ready,				//Flag: Ready
	input	v_2b_t				I_Ld_Grant,				//Flag: Grant
	input	v_2b_t				I_St_Ready,				//Flag: Ready
	input	v_2b_t				I_St_Grant,				//Flag: Grant
	input	v_2b_t				I_End_Access,			//Flag: End of Access
	output						O_Commit_Req,			//Commit Request
	output	issue_no_t			O_Commit_No,			//Commit No
	input	logic				I_Commit_Grant,			//Grant for Commit
	output	v_1b_t				O_Status				//Status on Lane
);


	lane_t						Lane_Data_Src1;
	lane_t						Lane_Data_Src2;
	lane_t						Lane_Data_Src3;
	lane_t						Lane_Data_WB;

	v_1b_t						Commit_Req;
	v_issue_no_t				Commit_No;

	logic						Commit_Full;

	lane_t						Scalar_Data;


	assign O_Scalar_Data		= Scalar_Data[ I_Scalar_Data[$clog2(NUM_LANES)-1:0] ];


	CommitAgg_Unit #(
		//.NUM_LANES(			NUM_LANES				),
		.BUFF_SIZE(			4						)
	) CommitAgg_Unit
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_En_Lane(			I_En_Lane				),
		.I_Req(				I_Command.v				),
		.I_Issue_No(	I_Command.command.issue_no	),
		.I_Commit_Req(		Commit_Req				),
		.I_Commit_No(		Commit_No				),
		.O_Commit_Req(		O_Commit_Req			),
		.O_Commit_No(		O_Commit_No				),
		.I_Commit_Grant(	I_Commit_Grant			),
		.O_Full(			Commit_Full				)
	);


	//Vector-Lane Generation
	for ( genvar i=0; i<NUM_LANES; ++i ) begin
		Lane_Unit #(
			.NUM_LANES(			NUM_LANES				),
			.LANE_ID(			i						)
		) Lane_Unit
		(
			.clock(				clock					),
			.reset(				reset					),
			.I_Commit_Grant(	I_Commit_Grant			),//ToDo Must come from CommitAgg_Unit as "Commit_Grant[ i ]"
			.I_En_Lane(			I_En_Lane[ i ]			),
			.I_ThreadID(		I_ThreadID				),
			.I_Command(			I_Command				),
			.I_Scalar_Data(		I_Scalar_Data			),
			.O_Scalar_Data(		Scalar_Data[ i ]		),
			.O_LdSt(			O_LdSt[ i ]				),
			.I_Ld_Data(			I_Ld_Data[ i ]			),
			.O_St_Data(			O_St_Data[ i ]			),
			.I_Ld_Ready(		I_Ld_Ready[ i ]			),
			.I_Ld_Grant(		I_Ld_Grant[ i ]			),
			.I_St_Ready(		I_St_Ready[ i ]			),
			.I_St_Grant(		I_St_Grant[ i ]			),
			.I_End_Access(		I_End_Access[ i ]		),
			.O_Commit_Req(		Commit_Req[ i ]			),
			.O_Commit_No(		Commit_No[ i ]			),
			.I_Lane_Data_Src1(	Lane_Data_Src1			),
			.I_Lane_Data_Src2(	Lane_Data_Src2			),
			.I_Lane_Data_Src3(	Lane_Data_Src3			),
			.I_Lane_Data_WB(	Lane_Data_WB			),
			.O_Lane_Data_Src1(	Lane_Data_Src1[ i ]		),
			.O_Lane_Data_Src2(	Lane_Data_Src2[ i ]		),
			.O_Lane_Data_Src3(	Lane_Data_Src3[ i ]		),
			.O_Lane_Data_WB(	Lane_Data_WB[ i ]		),
			.O_Status(			O_Status[ i ]			)
		);
	end

endmodule