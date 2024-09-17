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
	import	pkg_top::NUM_ROWS;
	import	pkg_top::NUM_CLMS;
(
	input						clock,
	input						reset,
	input						I_Req_IF,				//Request from External
	input	mpu_if_t			I_Data_IF,				//Data from External
	output						O_Req_IF,				//Request to External
	output	mpu_if_t			O_Data_IF,				//Data to External
	output	mpu_stat_t			O_Status,				//System Status
	output						O_Wait					//Flag: Wait for Thread Program
);


	logic						Issue_Req;
	mpu_issue_no_t				Issue_No;
	instr_t						Issue_Instr;

	tpu_row_clm_t				TPU_En_Exe;
	tpu_row_clm_t				TPU_Req;

	logic						TPU_Term			[NUM_ROWS+1:0][NUM_CLMS-1:0];
	logic						TPU_Nack			[NUM_ROWS+1:0][NUM_CLMS-1:0];
	mpu_issue_no_t				TPU_IssueNo			[NUM_ROWS+1:0][NUM_CLMS-1:0];

	logic						Commit_Req;
	mpu_issue_no_t				Commit_No;

	logic						TPU_CLM_Commit_Req	[NUM_CLMS-1:0];
	mpu_issue_no_t				TPU_CLM_Commit_No	[NUM_CLMS-1:0];


	logic						Route_I_Req		[NUM_ROWS+1:0][NUM_CLMS-1:0];
	logic						Route_O_Req		[NUM_ROWS+1:0][NUM_CLMS-1:0];

	data_t						Route_I_Data	[NUM_ROWS+1:0][NUM_CLMS-1:0];
	data_t						Route_O_Data	[NUM_ROWS+1:0][NUM_CLMS-1:0];

	logic						Route_I_Rls		[NUM_ROWS+1:0][NUM_CLMS-1:0];
	logic						Route_O_Rls		[NUM_ROWS+1:0][NUM_CLMS-1:0];


	logic						Route_Fwd_Req	[NUM_ROWS+1:0][NUM_CLMS:0];
	logic						Route_Bwd_Req	[NUM_ROWS+1:0][NUM_CLMS:0];

	data_t						Route_Fwd_Data	[NUM_ROWS+1:0][NUM_CLMS:0];
	data_t						Route_Bwd_Data	[NUM_ROWS+1:0][NUM_CLMS:0];

	logic						Route_Fwd_Rls	[NUM_ROWS+1:0][NUM_CLMS:0];
	logic						Route_Bwd_Rls	[NUM_ROWS+1:0][NUM_CLMS:0];


	s_ldst_t					TPU_S_LdSt	[NUM_ROWS-1:0][NUM_CLMS-1:0][1:0];
	v_ldst_t					TPU_V_LdSt	[NUM_ROWS-1:0][NUM_CLMS-1:0][1:0];

	s_ldst_t					RAM_S_LdSt	[NUM_ROWS+1:0][NUM_CLMS-1:0][1:0];
	v_ldst_t					RAM_V_LdSt	[NUM_ROWS+1:0][NUM_CLMS-1:0][1:0];


	data_t						TPU_S_Ld_Data	[NUM_ROWS-1:0][NUM_CLMS-1:0][1:0];
	data_t						TPU_S_St_Data	[NUM_ROWS-1:0][NUM_CLMS-1:0][1:0];

	v_data_t					TPU_V_Ld_Data	[NUM_ROWS-1:0][NUM_CLMS-1:0][1:0];
	v_data_t					TPU_V_St_Data	[NUM_ROWS-1:0][NUM_CLMS-1:0][1:0];

	data_t						RAM_S_Ld_Data	[NUM_ROWS+1:0][NUM_CLMS-1:0][1:0];
	data_t						RAM_S_St_Data	[NUM_ROWS+1:0][NUM_CLMS-1:0][1:0];

	v_data_t					RAM_V_Ld_Data	[NUM_ROWS+1:0][NUM_CLMS-1:0][1:0];
	v_data_t					RAM_V_St_Data	[NUM_ROWS+1:0][NUM_CLMS-1:0][1:0];


	logic	[1:0]				TPU_S_Ld_Ready	[NUM_ROWS-1:0][NUM_CLMS-1:0][1:0];
	logic	[1:0]				TPU_S_Ld_Grant	[NUM_ROWS-1:0][NUM_CLMS-1:0][1:0];
	logic	[1:0]				TPU_S_St_Ready	[NUM_ROWS-1:0][NUM_CLMS-1:0][1:0];
	logic	[1:0]				TPU_S_St_Grant	[NUM_ROWS-1:0][NUM_CLMS-1:0][1:0];

	v_ready_t					TPU_V_Ld_Ready	[NUM_ROWS-1:0][NUM_CLMS-1:0][1:0];
	v_grant_t					TPU_V_Ld_Grant	[NUM_ROWS-1:0][NUM_CLMS-1:0][1:0];
	v_ready_t					TPU_V_St_Ready	[NUM_ROWS-1:0][NUM_CLMS-1:0][1:0];
	v_grant_t					TPU_V_St_Grant	[NUM_ROWS-1:0][NUM_CLMS-1:0][1:0];

	logic	[1:0]				RAM_S_Ld_Ready	[NUM_ROWS+1:0][NUM_CLMS-1:0][1:0];
	logic	[1:0]				RAM_S_Ld_Grant	[NUM_ROWS+1:0][NUM_CLMS-1:0][1:0];
	logic	[1:0]				RAM_S_St_Ready	[NUM_ROWS+1:0][NUM_CLMS-1:0][1:0];
	logic	[1:0]				RAM_S_St_Grant	[NUM_ROWS+1:0][NUM_CLMS-1:0][1:0];

	v_ready_t					RAM_V_Ld_Ready	[NUM_ROWS+1:0][NUM_CLMS-1:0][1:0];
	v_grant_t					RAM_V_Ld_Grant	[NUM_ROWS+1:0][NUM_CLMS-1:0][1:0];
	v_ready_t					RAM_V_St_Ready	[NUM_ROWS+1:0][NUM_CLMS-1:0][1:0];
	v_grant_t					RAM_V_St_Grant	[NUM_ROWS+1:0][NUM_CLMS-1:0][1:0];


	MPU MPU (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req_IF(			I_Req_IF				),
		.I_Data_IF(			I_Data_IF				),
		.O_Req_IF(			O_Req_IF				),
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
		.NUM_TPU(			NUM_TPU					),
		.BUFF_SIZE(			BYPASS_BUFF_SIZE		)
	) CommitAgg
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_En_TPU(			TPU_En_Exe				),
		.I_Req(				Issue_Req				),
		.I_Issue_No(		Issue_No				),
		.I_Commit_Req(		TPU_CLM_Commit_Req		),
		.I_Commit_No(		TPU_CLM_Commit_No		),
		.O_Commit_Req(		Commit_Req				),
		.O_Commit_No(		Commit_No				),
		.O_Full(			)//ToDo
	);


	always_comb begin
		for ( int clm=0; clm<NUM_CLMS; ++clm ) begin

			TPU_CLM_Commit_Req[ clm ]	= TPU_Term[0][ clm ];//ToDo
			TPU_CLM_Commit_No[ clm ]	= TPU_IssueNo[0][ clm ];//ToDo

			for ( int row=0; row<NUM_ROWS; ++row ) begin
				RAM_S_LdSt[ row ][ clm ][0]		= TPU_S_LdSt[ row ][ clm ][0];
				RAM_S_Ld_Data[ row ][ clm ][0]	= TPU_S_Ld_Data[ row ][ clm ][0];
				RAM_S_St_Data[ row ][ clm ][0]	= TPU_S_St_Data[ row ][ clm ][0];

				RAM_V_LdSt[ row ][ clm ][0]		= TPU_V_LdSt[ row ][ clm ][0];
				RAM_V_Ld_Data[ row ][ clm ][0]	= TPU_V_Ld_Data[ row ][ clm ][0];
				RAM_V_St_Data[ row ][ clm ][0]	= TPU_V_St_Data[ row ][ clm ][0];

				RAM_S_LdSt[ row+1 ][ clm ][1]	= TPU_S_LdSt[ row ][ clm ][1];
				RAM_S_Ld_Data[ row+1 ][ clm ][1]= TPU_S_Ld_Data[ row ][ clm ][1];
				RAM_S_St_Data[ row+1 ][ clm ][1]= TPU_S_St_Data[ row ][ clm ][1];

				RAM_V_LdSt[ row+1 ][ clm ][1]	= TPU_V_LdSt[ row ][ clm ][1];
				RAM_V_Ld_Data[ row+1 ][ clm ][1]= TPU_V_Ld_Data[ row ][ clm ][1];
				RAM_V_St_Data[ row+1 ][ clm ][1]= TPU_V_St_Data[ row ][ clm ][1];

				TPU_S_Ld_Ready[ row ][ clm ][0]	= RAM_S_Ld_Ready[ row ][ clm ][0];
				TPU_S_Ld_Grant[ row ][ clm ][0]	= RAM_S_Ld_Grant[ row ][ clm ][0];
				TPU_S_St_Ready[ row ][ clm ][0]	= RAM_S_St_Ready[ row ][ clm ][0];
				TPU_S_St_Grant[ row ][ clm ][0]	= RAM_S_St_Grant[ row ][ clm ][0];

				TPU_S_Ld_Ready[ row ][ clm ][1]	= RAM_S_Ld_Ready[ row+1 ][ clm ][1];
				TPU_S_Ld_Grant[ row ][ clm ][1]	= RAM_S_Ld_Grant[ row+1 ][ clm ][1];
				TPU_S_St_Ready[ row ][ clm ][1]	= RAM_S_St_Ready[ row+1 ][ clm ][1];
				TPU_S_St_Grant[ row ][ clm ][1]	= RAM_S_St_Grant[ row+1 ][ clm ][1];

				TPU_V_Ld_Ready[ row ][ clm ][0]	= RAM_V_Ld_Ready[ row ][ clm ][0];
				TPU_V_Ld_Grant[ row ][ clm ][0]	= RAM_V_Ld_Grant[ row ][ clm ][0];
				TPU_V_St_Ready[ row ][ clm ][0]	= RAM_V_St_Ready[ row ][ clm ][0];
				TPU_V_St_Grant[ row ][ clm ][0]	= RAM_V_St_Grant[ row ][ clm ][0];

				TPU_V_Ld_Ready[ row ][ clm ][1]	= RAM_V_Ld_Ready[ row+1 ][ clm ][1];
				TPU_V_Ld_Grant[ row ][ clm ][1]	= RAM_V_Ld_Grant[ row+1 ][ clm ][1];
				TPU_V_St_Ready[ row ][ clm ][1]	= RAM_V_St_Ready[ row+1 ][ clm ][1];
				TPU_V_St_Grant[ row ][ clm ][1]	= RAM_V_St_Grant[ row+1 ][ clm ][1];
			end
		end
	end


	for ( genvar clm=0; clm<NUM_CLMS; ++clm ) begin
		for ( genvar row=0; row<NUM_ROWS; ++row ) begin
			if ( row > 0 ) begin
				Router Router (
					.clock(			clock							),
					.reset(			reset							),
					.I_Req(			Route_Fwd_Req[ row ][ clm ]		),
					.I_Rls(			Route_Fwd_Rls[ row ][ clm ]		),
					.I_Data(		Route_Fwd_Data[ row ][ clm ]	),
					.O_Req_A(		Route_I_Req[ row ][ clm ]		),
					.O_Req_B(		Route_Fwd_Req[ row ][ clm+1 ]	),
					.O_Data_A(		Route_I_Data[ row ][ clm ]		),
					.O_Data_B(		Route_Fwd_Data[ row+1 ][ clm ]	),
					.O_Rls_A(		Route_I_Rls[ row ][ clm ]		),
					.O_Rls_B(		Route_Fwd_Rls[ row ][ clm+1 ]	),
					.O_Req(			Route_Bwd_Req[ row ][ clm ]		),
					.O_Rls(			Route_Bwd_Rls[ row ][ clm ]		),
					.O_Data(		Route_Bwd_Data[ row ][ clm ]	),
					.I_Req_A(		Route_O_Req[ row ][ clm ]		),
					.I_Req_B(		Route_Bwd_Req[ row ][ clm+1 ]	),
					.I_Rls_A(		Route_O_Rls[ row ][ clm ]		),
					.I_Rls_B(		Route_Bwd_Rls[ row ][ clm+1 ]	),
					.I_Data_A(		Route_O_Data[ row ][ clm ]		),
					.I_Data_B(		Route_Bwd_Data[ row ][ clm+1 ]	)
				);
			end
			else begin
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
	end


	for ( genvar clm=0; clm<NUM_CLMS; ++clm ) begin
		for ( genvar row=0; row<NUM_ROWS; ++row ) begin
			TPU TPU (
				.clock(			clock							),
				.reset(			reset							),
				.I_En_Exe(		TPU_En_Exe[ row ][ clm ]		),
				.I_Req(			TPU_Req[ row ][ clm ]			),
				.I_Instr(		Issue_Instr						),
				.O_S_LdSt(		TPU_S_LdSt[ row ][ clm ]		),
				.I_S_Ld_Data(	TPU_S_Ld_Data[ row ][ clm ]		),
				.O_S_Ld_Data(	TPU_S_St_Data[ row ][ clm ]		),
				.I_S_Ld_Ready(	TPU_S_Ld_Ready[ row ][ clm ]	),
				.I_S_St_Ready(	TPU_S_St_Ready[ row ][ clm ]	),
				.I_S_Ld_Grant(	TPU_S_Ld_Grant[ row ][ clm ]	),
				.I_S_St_Grant(	TPU_S_St_Grant[ row ][ clm ]	),
				.O_V_LdSt(		TPU_V_LdSt[ row ][ clm ]		),
				.I_V_Ld_Data(	TPU_V_Ld_Data[ row ][ clm ]		),
				.O_V_Ld_Data(	TPU_V_St_Data[ row ][ clm ]		),
				.O_V_Ld_Ready(	TPU_V_Ld_Ready[ row ][ clm ]	),
				.O_V_St_Ready(	TPU_V_St_Ready[ row ][ clm ]	),
				.O_V_Ld_Grant(	TPU_V_Ld_Grant[ row ][ clm ]	),
				.O_V_St_Grant(	TPU_V_St_Grant[ row ][ clm ]	),
				.O_IssueNo(		TPU_IssueNo[ row ][ clm ]		),
				.O_Term(		TPU_Term[ row ][ clm ]			),
				.O_Nack(		TPU_Nack[ row ][ clm ]			)
			);

			DMem DMem_TPU (
				.clock(			clock							),
				.reset(			reset							),
				.I_Rt_Req(		Route_I_Req[ row ][ clm ]		),
				.I_Rt_Data(		Route_I_Data[ row ][ clm ]		),
				.I_Rt_Rls(		Route_I_Rls[ row ][ clm ]		),
				.O_Rt_Req(		Route_O_Req[ row ][ clm ]		),
				.O_Rt_Data(		Route_O_Data[ row ][ clm ]		),
				.O_Rt_Rls(		Route_O_Rls[ row ][ clm ]		),
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
		DMem TDMem (
			.clock(			clock							),
			.reset(			reset							),
			.I_Rt_Req(		Route_I_Req[0][ clm ]			),
			.I_Rt_Data(		Route_I_Data[0][ clm ]			),
			.I_Rt_Els(		Route_I_Rls[0][ clm ]			),
			.O_Rt_Req(		Route_O_Req[0][ clm ]			),
			.O_Rt_Data(		Route_O_Data[0][ clm ]			),
			.O_Rt_Rls(		Route_O_Rls[0][ clm ]			),
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

		DMem BDMem (
			.clock(			clock							),
			.reset(			reset							),
			.I_Rt_Req(		Route_I_Req[NUM_ROWS][ clm ]	),
			.I_Rt_Data(		Route_I_Data[NUM_ROWS][ clm ]	),
			.O_Rt_Req(		Route_O_Req[NUM_ROWS][ clm ]	),
			.O_Rt_Data(		Route_O_Data[NUM_ROWS][ clm ]	),
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