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

module BLASEngine
	import	pkg_mpu::*;
	import	pkg_tpu::*;
	import	pkg_tpu::instr_t;
	import	pkg_tpu::BYPASS_BUFF_SIZE;
	import	pkg_mpu::NUM_ROWS;
	import	pkg_mpu::NUM_CLMS;
	import	pkg_mpu::NUM_TPUS;
(
	input						clock,
	input						reset,
	input						I_Req_IF,				//Request from External
	input	mpu_in_t			I_Data_IF,				//Data from External
	output	mpu_out_t			O_Data_IF,				//Data to External
	output	mpu_stat_t			O_Status,				//System Status
	output						O_Wait					//Flag: Wait for Thread Program
);


	logic						Issue_Req;
	mpu_issue_no_t				Issue_No;
	instr_t						Issue_Instr;

	tpu_row_clm_t				TPU_En_Exe;
	tpu_row_clm_t				TPU_Req;


	logic						CoomitAgg_Full;


	logic						TPU_Term			[NUM_ROWS:0][NUM_CLMS-1:0];
	logic						TPU_Nack			[NUM_ROWS:0][NUM_CLMS-1:0];
	mpu_issue_no_t				TPU_IssueNo			[NUM_ROWS:0][NUM_CLMS-1:0];

	logic						Commit_Req;
	mpu_issue_no_t				Commit_No;


	logic			[NUM_ROWS*NUM_CLMS-1:0]			TPU_Commit_Req;
	mpu_issue_no_t	[NUM_ROWS*NUM_CLMS-1:0]			TPU_Commit_No;


	logic			[NUM_ROWS:0][NUM_CLMS:0]		Route_Fwd_Req;
	logic			[NUM_ROWS:0][NUM_CLMS:0]		Route_Bwd_Req;

	data_t			[NUM_ROWS:0][NUM_CLMS:0]		Route_Fwd_Data;
	data_t			[NUM_ROWS:0][NUM_CLMS:0]		Route_Bwd_Data;

	logic			[NUM_ROWS:0][NUM_CLMS:0]		Route_Fwd_Rls;
	logic			[NUM_ROWS:0][NUM_CLMS:0]		Route_Bwd_Rls;


	s_ldst_t		[NUM_ROWS-1:0][NUM_CLMS-1:0]	TPU_S_LdSt;
	v_ldst_t		[NUM_ROWS-1:0][NUM_CLMS-1:0]	TPU_V_LdSt;

	s_ldst_t		[NUM_ROWS:0][NUM_CLMS-1:0]		RAM_S_LdSt;
	v_ldst_t		[NUM_ROWS:0][NUM_CLMS-1:0]		RAM_V_LdSt;


	s_ldst_data_t	[NUM_ROWS-1:0][NUM_CLMS-1:0]	TPU_S_Ld_Data;
	s_ldst_data_t	[NUM_ROWS-1:0][NUM_CLMS-1:0]	TPU_S_St_Data;

	v_ldst_data_t	[NUM_ROWS-1:0][NUM_CLMS-1:0]	TPU_V_Ld_Data;
	v_ldst_data_t	[NUM_ROWS-1:0][NUM_CLMS-1:0]	TPU_V_St_Data;

	s_ldst_data_t	[NUM_ROWS:0][NUM_CLMS-1:0]		RAM_S_Ld_Data;
	s_ldst_data_t	[NUM_ROWS:0][NUM_CLMS-1:0]		RAM_S_St_Data;

	v_ldst_data_t	[NUM_ROWS:0][NUM_CLMS-1:0]		RAM_V_Ld_Data;
	v_ldst_data_t	[NUM_ROWS:0][NUM_CLMS-1:0]		RAM_V_St_Data;


	tb_t			[NUM_ROWS-1:0][NUM_CLMS-1:0]	TPU_S_Ld_Ready;
	tb_t			[NUM_ROWS-1:0][NUM_CLMS-1:0]	TPU_S_Ld_Grant;
	tb_t			[NUM_ROWS-1:0][NUM_CLMS-1:0]	TPU_S_St_Ready;
	tb_t			[NUM_ROWS-1:0][NUM_CLMS-1:0]	TPU_S_St_Grant;

	v_2b_t			[NUM_ROWS-1:0][NUM_CLMS-1:0]	TPU_V_Ld_Ready;
	v_2b_t			[NUM_ROWS-1:0][NUM_CLMS-1:0]	TPU_V_Ld_Grant;
	v_2b_t			[NUM_ROWS-1:0][NUM_CLMS-1:0]	TPU_V_St_Ready;
	v_2b_t			[NUM_ROWS-1:0][NUM_CLMS-1:0]	TPU_V_St_Grant;

	tb_t			[NUM_ROWS:0][NUM_CLMS-1:0]		RAM_S_Ld_Ready;
	tb_t			[NUM_ROWS:0][NUM_CLMS-1:0]		RAM_S_Ld_Grant;
	tb_t			[NUM_ROWS:0][NUM_CLMS-1:0]		RAM_S_St_Ready;
	tb_t			[NUM_ROWS:0][NUM_CLMS-1:0]		RAM_S_St_Grant;

	v_2b_t			[NUM_ROWS:0][NUM_CLMS-1:0]		RAM_V_Ld_Ready;
	v_2b_t			[NUM_ROWS:0][NUM_CLMS-1:0]		RAM_V_Ld_Grant;
	v_2b_t			[NUM_ROWS:0][NUM_CLMS-1:0]		RAM_V_St_Ready;
	v_2b_t			[NUM_ROWS:0][NUM_CLMS-1:0]		RAM_V_St_Grant;

	tb_t			[NUM_ROWS-1:0][NUM_CLMS-1:0]	TPU_S_End_Access;
	v_2b_t			[NUM_ROWS-1:0][NUM_CLMS-1:0]	TPU_V_End_Access;


	MPU MPU (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req_IF(			I_Req_IF				),
		.I_Data_IF(			I_Data_IF				),
		.O_Data_IF(			O_Data_IF				),
		.O_Req(				Issue_Req				),
		.O_Instr(			Issue_Instr				),
		.O_IssueNo(			Issue_No				),
		.I_Req_Commit(		Commit_Req				),
		.I_CommitNo(		Commit_No				),
		.O_TPU_Req(			TPU_Req					),
		.O_TPU_En_Exe(		TPU_En_Exe				),
		.I_Ld_Req(			Route_Bwd_Req[0][0]		),
		.I_Ld_Data(			Route_Bwd_Data[0][0]	),
		.I_Ld_Rls(			Route_Bwd_Rls[0][0]		),
		.O_St_Req(			Route_Fwd_Req[0][0]		),
		.O_St_Data(			Route_Fwd_Data[0][0]	),
		.O_St_Rls(			Route_Fwd_Rls[0][0]		),
		.O_Wait(			O_Wait					),
		.O_Status(			O_Status				)
	);


	CommitAgg #(
		.NUM_TPU(			NUM_TPUS				),
		.BUFF_SIZE(			BYPASS_BUFF_SIZE		)
	) CommitAgg
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_En_TPU(			TPU_En_Exe				),
		.I_Req(				Issue_Req				),
		.I_Issue_No(		Issue_No				),
		.I_Commit_Req(		TPU_Commit_Req			),
		.I_Commit_No(		TPU_Commit_No			),
		.O_Commit_Req(		Commit_Req				),
		.O_Commit_No(		Commit_No				),
		.O_Full(			CoomitAgg_Full			)
	);


	always_comb begin
		for ( int clm=0; clm<NUM_CLMS; ++clm ) begin
			//// Boundary DMems
			//	Top-Edge DMems
			RAM_S_LdSt[0][ clm ][1]				= '0;
			RAM_S_St_Data[0][ clm ][1]			= '0;

			RAM_V_LdSt[0][ clm ]				= '0;
			RAM_V_St_Data[0][ clm ]				= '0;

			//	Bottom-Edge DMems
			RAM_S_LdSt[NUM_ROWS][ clm ][0]		= '0;
			RAM_S_St_Data[NUM_ROWS][ clm ][0]	= '0;

			RAM_V_LdSt[NUM_ROWS][ clm ]			= '0;
			RAM_V_St_Data[NUM_ROWS][ clm ]		= '0;

			for ( int row=0; row<NUM_ROWS; ++row ) begin
				// Commit Signals to Commit Aggregater
				TPU_Commit_Req[ NUM_CLMS*row + clm ]	= TPU_Term[ row ][ clm ];
				TPU_Commit_No[ NUM_CLMS*row + clm ]		= TPU_IssueNo[ row ][ clm ];

				RAM_S_LdSt[ row ][ clm ][0]				= TPU_S_LdSt[ row ][ clm ][0];
				RAM_S_LdSt[ row+1 ][ clm ][1]			= TPU_S_LdSt[ row ][ clm ][1];

				RAM_V_LdSt[ row ][ clm ][0]				= TPU_V_LdSt[ row ][ clm ][0];
				RAM_V_LdSt[ row+1 ][ clm ][1]			= TPU_V_LdSt[ row ][ clm ][1];

				RAM_S_St_Data[ row ][ clm ][0]			= TPU_S_St_Data[ row ][ clm ][0];
				RAM_S_St_Data[ row+1 ][ clm ][1]		= TPU_S_St_Data[ row ][ clm ][1];

				RAM_V_St_Data[ row ][ clm ][0]			= TPU_V_St_Data[ row ][ clm ][0];
				RAM_V_St_Data[ row+1 ][ clm ][1]		= TPU_V_St_Data[ row ][ clm ][1];

				TPU_S_Ld_Data[ row ][ clm ][0]			= RAM_S_Ld_Data[ row ][ clm ][0];
				TPU_S_Ld_Data[ row ][ clm ][1]			= RAM_S_Ld_Data[ row+1 ][ clm ][1];

				TPU_V_Ld_Data[ row ][ clm ][0]			= RAM_V_Ld_Data[ row ][ clm ][0];
				TPU_V_Ld_Data[ row ][ clm ][1]			= RAM_V_Ld_Data[ row+1 ][ clm ][1];

				TPU_S_Ld_Ready[ row ][ clm ][0]			= RAM_S_Ld_Ready[ row ][ clm ][0];
				TPU_S_Ld_Grant[ row ][ clm ][0]			= RAM_S_Ld_Grant[ row ][ clm ][0];
				TPU_S_St_Ready[ row ][ clm ][0]			= RAM_S_St_Ready[ row ][ clm ][0];
				TPU_S_St_Grant[ row ][ clm ][0]			= RAM_S_St_Grant[ row ][ clm ][0];

				TPU_S_Ld_Ready[ row ][ clm ][1]			= RAM_S_Ld_Ready[ row+1 ][ clm ][1];
				TPU_S_Ld_Grant[ row ][ clm ][1]			= RAM_S_Ld_Grant[ row+1 ][ clm ][1];
				TPU_S_St_Ready[ row ][ clm ][1]			= RAM_S_St_Ready[ row+1 ][ clm ][1];
				TPU_S_St_Grant[ row ][ clm ][1]			= RAM_S_St_Grant[ row+1 ][ clm ][1];

				TPU_V_Ld_Ready[ row ][ clm ][0]			= RAM_V_Ld_Ready[ row ][ clm ][0];
				TPU_V_Ld_Grant[ row ][ clm ][0]			= RAM_V_Ld_Grant[ row ][ clm ][0];
				TPU_V_St_Ready[ row ][ clm ][0]			= RAM_V_St_Ready[ row ][ clm ][0];
				TPU_V_St_Grant[ row ][ clm ][0]			= RAM_V_St_Grant[ row ][ clm ][0];

				TPU_V_Ld_Ready[ row ][ clm ][1]			= RAM_V_Ld_Ready[ row+1 ][ clm ][1];
				TPU_V_Ld_Grant[ row ][ clm ][1]			= RAM_V_Ld_Grant[ row+1 ][ clm ][1];
				TPU_V_St_Ready[ row ][ clm ][1]			= RAM_V_St_Ready[ row+1 ][ clm ][1];
				TPU_V_St_Grant[ row ][ clm ][1]			= RAM_V_St_Grant[ row+1 ][ clm ][1];

				TPU_S_End_Access[ row ][ clm ]			= '0;//ToDo
				TPU_V_End_Access[ row ][ clm ]			= '0;//ToDo
			end
		end
	end


	for ( genvar clm=0; clm<NUM_CLMS; ++clm ) begin
		for ( genvar row=0; row<NUM_ROWS; ++row ) begin
			TPU TPU (
				.clock(			clock							),
				.reset(			reset							),
				.I_En_Exe(		TPU_En_Exe[ row ][ clm ]		),
				.I_Req(			TPU_Req[ row ][ clm ]			),
				.I_IssueNo(		Issue_No						),
				.I_Instr(		Issue_Instr						),
				.O_S_LdSt(		TPU_S_LdSt[ row ][ clm ]		),
				.I_S_Ld_Data(	TPU_S_Ld_Data[ row ][ clm ]		),
				.O_S_St_Data(	TPU_S_St_Data[ row ][ clm ]		),
				.I_S_Ld_Ready(	TPU_S_Ld_Ready[ row ][ clm ]	),
				.I_S_St_Ready(	TPU_S_St_Ready[ row ][ clm ]	),
				.I_S_Ld_Grant(	TPU_S_Ld_Grant[ row ][ clm ]	),
				.I_S_St_Grant(	TPU_S_St_Grant[ row ][ clm ]	),
				.I_S_End_Access(TPU_S_End_Access[ row ][ clm ]	),
				.O_V_LdSt(		TPU_V_LdSt[ row ][ clm ]		),
				.I_V_Ld_Data(	TPU_V_Ld_Data[ row ][ clm ]		),
				.O_V_St_Data(	TPU_V_St_Data[ row ][ clm ]		),
				.I_V_Ld_Ready(	TPU_V_Ld_Ready[ row ][ clm ]	),
				.I_V_St_Ready(	TPU_V_St_Ready[ row ][ clm ]	),
				.I_V_Ld_Grant(	TPU_V_Ld_Grant[ row ][ clm ]	),
				.I_V_St_Grant(	TPU_V_St_Grant[ row ][ clm ]	),
				.I_V_End_Access(TPU_V_End_Access[ row ][ clm ]	),
				.O_IssueNo(		TPU_IssueNo[ row ][ clm ]		),
				.O_Term(		TPU_Term[ row ][ clm ]			),
				.O_Nack(		TPU_Nack[ row ][ clm ]			)
			);


			Router Router (
				.clock(			clock							),
				.reset(			reset							),
				.I_Req(			Route_Fwd_Req[ row ][ clm ]		),
				.I_Rls(			Route_Fwd_Rls[ row ][ clm ]		),
				.I_Data(		Route_Fwd_Data[ row ][ clm ]	),
				.O_Req_A(		Route_Fwd_Req[ row+1 ][ clm ]	),
				.O_Req_B(		Route_Fwd_Req[ row ][ clm+1 ]	),
				.O_Data_A(		Route_Fwd_Data[ row+1 ][ clm ]	),
				.O_Data_B(		Route_Fwd_Data[ row ][ clm+1 ]	),
				.O_Rls_A(		Route_Fwd_Rls[ row+1 ][ clm ]	),
				.O_Rls_B(		Route_Fwd_Rls[ row ][ clm+1 ]	),
				.O_Req(			Route_Bwd_Req[ row ][ clm ]		),
				.O_Rls(			Route_Bwd_Rls[ row ][ clm ]		),
				.O_Data(		Route_Bwd_Data[ row ][ clm ]	),
				.I_Req_A(		Route_Bwd_Req[ row+1 ][ clm ]	),
				.I_Req_B(		Route_Bwd_Req[ row ][ clm+1 ]	),
				.I_Rls_A(		Route_Bwd_Req[ row+1 ][ clm ]	),
				.I_Rls_B(		Route_Bwd_Rls[ row ][ clm+1 ]	),
				.I_Data_A(		Route_Bwd_Data[ row+1 ][ clm ]	),
				.I_Data_B(		Route_Bwd_Data[ row ][ clm+1 ]	)
			);
		end
	end


	for ( genvar clm=0; clm<NUM_CLMS; ++clm ) begin
		for ( genvar row=1; row<=NUM_ROWS; ++row ) begin
			DMem DMem_MD (
				.clock(			clock							),
				.reset(			reset							),
				//.I_Stall(		CoomitAgg_Full					),
				.I_Rt_Req(		Route_Fwd_Req[ row ][ clm ]		),
				.I_Rt_Data(		Route_Fwd_Data[ row ][ clm ]	),
				.I_Rt_Rls(		Route_Fwd_Rls[ row ][ clm ]		),
				.O_Rt_Req(		Route_Bwd_Req[ row ][ clm ]		),
				.O_Rt_Data(		Route_Bwd_Data[ row ][ clm ]	),
				.O_Rt_Rls(		Route_Bwd_Rls[ row ][ clm ]		),
				.I_S_LdSt(		RAM_S_LdSt[ row ][ clm ]		),
				.O_S_Ld_Data(	RAM_S_Ld_Data[ row ][ clm ]		),
				.I_S_St_Data(	RAM_S_St_Data[ row ][ clm ]		),
				.O_S_Ld_Ready(	RAM_S_Ld_Ready[ row ][ clm ]	),
				.O_S_St_Ready(	RAM_S_St_Ready[ row ][ clm ]	),
				.O_S_Ld_Grant(	RAM_S_Ld_Grant[ row ][ clm ]	),
				.O_S_St_Grant(	RAM_S_St_Grant[ row ][ clm ]	),
				.I_V_LdSt(		RAM_V_LdSt[ row ][ clm ]		),
				.O_V_Ld_Data(	RAM_V_Ld_Data[ row ][ clm ]		),
				.I_V_St_Data(	RAM_V_St_Data[ row ][ clm ]		),
				.O_V_Ld_Ready(	RAM_V_Ld_Ready[ row ][ clm ]	),
				.O_V_St_Ready(	RAM_V_St_Ready[ row ][ clm ]	),
				.O_V_Ld_Grant(	RAM_V_Ld_Grant[ row ][ clm ]	),
				.O_V_St_Grant(	RAM_V_St_Grant[ row ][ clm ]	)
			);
		end
	end


	for ( genvar clm=0; clm<NUM_CLMS; ++clm ) begin
		DMem DMem_UP (
			.clock(			clock							),
			.reset(			reset							),
			//.I_Stall(		CoomitAgg_Full					),
			.I_Rt_Req(		Route_Fwd_Req[0][ clm ]			),
			.I_Rt_Data(		Route_Fwd_Data[0][ clm ]		),
			.I_Rt_Rls(		Route_Fwd_Rls[0][ clm ]			),
			.O_Rt_Req(		Route_Bwd_Req[0][ clm ]			),
			.O_Rt_Data(		Route_Bwd_Data[0][ clm ]		),
			.O_Rt_Rls(		Route_Bwd_Rls[0][ clm ]			),
			.I_S_LdSt(		RAM_S_LdSt[0][ clm ]			),
			.O_S_Ld_Data(	RAM_S_Ld_Data[0][ clm ]			),
			.I_S_St_Data(	RAM_S_St_Data[0][ clm ]			),
			.O_S_Ld_Ready(	RAM_S_Ld_Ready[0][ clm ]		),
			.O_S_St_Ready(	RAM_S_St_Ready[0][ clm ]		),
			.O_S_Ld_Grant(	RAM_S_Ld_Grant[0][ clm ]		),
			.O_S_St_Grant(	RAM_S_St_Grant[0][ clm ]		),
			.I_V_LdSt(		RAM_V_LdSt[0][ clm ]			),
			.O_V_Ld_Data(	RAM_V_Ld_Data[0][ clm ]			),
			.I_V_St_Data(	RAM_V_St_Data[0][ clm ]			),
			.O_V_Ld_Ready(	RAM_V_Ld_Ready[0][ clm ]		),
			.O_V_St_Ready(	RAM_V_St_Ready[0][ clm ]		),
			.O_V_Ld_Grant(	RAM_V_Ld_Grant[0][ clm ]		),
			.O_V_St_Grant(	RAM_V_St_Grant[0][ clm ]		)
		);


		DMem DMem_BT (
			.clock(			clock							),
			.reset(			reset							),
			//.I_Stall(		CoomitAgg_Full					),
			.I_Rt_Req(		Route_Fwd_Req[NUM_ROWS][ clm ]	),
			.I_Rt_Data(		Route_Fwd_Data[NUM_ROWS][ clm ]	),
			.I_Rt_Rls(		Route_Fwd_Rls[NUM_ROWS][ clm ]	),
			.O_Rt_Req(		Route_Bwd_Req[NUM_ROWS][ clm ]	),
			.O_Rt_Data(		Route_Bwd_Data[NUM_ROWS][ clm ]	),
			.O_Rt_Rls(		Route_Bwd_Rls[NUM_ROWS][ clm ]	),
			.I_S_LdSt(		RAM_S_LdSt[NUM_ROWS][ clm ]		),
			.O_S_Ld_Data(	RAM_S_Ld_Data[NUM_ROWS][ clm ]	),
			.I_S_St_Data(	RAM_S_St_Data[NUM_ROWS][ clm ]	),
			.O_S_Ld_Ready(	RAM_S_Ld_Ready[NUM_ROWS][ clm ]	),
			.O_S_St_Ready(	RAM_S_St_Ready[NUM_ROWS][ clm ]	),
			.O_S_Ld_Grant(	RAM_S_Ld_Grant[NUM_ROWS][ clm ]	),
			.O_S_St_Grant(	RAM_S_St_Grant[NUM_ROWS][ clm ]	),
			.I_V_LdSt(		RAM_V_LdSt[NUM_ROWS][ clm ]		),
			.O_V_Ld_Data(	RAM_V_Ld_Data[NUM_ROWS][ clm ]	),
			.I_V_St_Data(	RAM_V_St_Data[NUM_ROWS][ clm ]	),
			.O_V_Ld_Ready(	RAM_V_Ld_Ready[NUM_ROWS][ clm ]	),
			.O_V_St_Ready(	RAM_V_St_Ready[NUM_ROWS][ clm ]	),
			.O_V_Ld_Grant(	RAM_V_Ld_Grant[NUM_ROWS][ clm ]	),
			.O_V_St_Grant(	RAM_V_St_Grant[NUM_ROWS][ clm ]	)
		);
	end

endmodule