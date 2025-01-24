///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	DMem
///////////////////////////////////////////////////////////////////////////////////////////////////

module DMem
	import pkg_tpu::*;
(
	input						clock,
	input						reset,
	input						I_Rt_Req,				//Request from Router
	input	data_t				I_Rt_Data,				//Data from Router
	input						I_Rt_Rls,				//Releas from Router
	output						O_Rt_Req,				//Request to Router
	output	data_t				O_Rt_Data,				//Data to Router
	output						O_Rt_Rls,				//Release to Router
	input	s_ldst_t			I_S_LdSt,				//Load/Store Command
	output	s_ldst_data_t		O_S_Ld_Data,			//Loaded Data, to TPU Core
	input	s_ldst_data_t		I_S_St_Data,			//Storing Data, from TPU Core
	output	[1:0]				O_S_Ld_Ready,			//Flag: Ready to Service
	output	[1:0]				O_S_Ld_Grant,			//Flag: Grant for Request
	output	[1:0]				O_S_St_Ready,			//Flag: Ready to Service
	output	[1:0]				O_S_St_Grant,			//Flag: Grant for Request
	input	v_ldst_t			I_V_LdSt,				//Load/Store Command
	output	v_ldst_data_t		O_V_Ld_Data,			//Loaded Data, to TPU Core
	input	v_ldst_data_t		I_V_St_Data,			//Storing Data, from TPU Core
	output	v_2b_t				O_V_Ld_Ready,			//Flag: Ready to Service
	output	v_2b_t				O_V_Ld_Grant,			//Flag: Grant for Request
	output	v_2b_t				O_V_St_Ready,			//Flag: Ready to Service
	output	v_2b_t				O_V_St_Grant			//Flag: Grant for Request
);


	logic					Route_Fwd_Req_S;
	logic					Route_Fwd_Rls_S;
	data_t					Route_Fwd_Data_S;
	logic					Route_Bwd_Req_S;
	logic					Route_Bwd_Rls_S;
	data_t					Route_Bwd_Data_S;

	logic	[NUM_LANES:0]	Route_Fwd_Req_V		[1:0];
	logic	[NUM_LANES:0]	Route_Fwd_Rls_V		[1:0];
	data_t	[NUM_LANES:0]	Route_Fwd_Data_V	[1:0];
	logic	[NUM_LANES:0]	Route_Bwd_Req_V		[1:0];
	logic	[NUM_LANES:0]	Route_Bwd_Rls_V		[1:0];
	data_t	[NUM_LANES:0]	Route_Bwd_Data_V	[1:0];

	Router Router_S (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				I_Rt_Req				),
		.I_Rls(				I_Rt_Rls				),
		.I_Data(			I_Rt_Data				),
		.O_Req_A(			Route_Fwd_Req_S			),
		.O_Req_B(			Route_Fwd_Req_V[0]		),
		.O_Data_A(			Route_Fwd_Data_S		),
		.O_Data_B(			Route_Fwd_Data_V[0]		),
		.O_Rls_A(			Route_Fwd_Rls_S			),
		.O_Rls_B(			Route_Fwd_Rls_V[0]		),
		.O_Req(				O_Rt_Req				),
		.O_Rls(				O_Rt_Rls				),
		.O_Data(			O_Rt_Data				),
		.I_Req_A(			Route_Bwd_Req_S			),
		.I_Req_B(			Route_Bwd_Req_V[0]		),
		.I_Rls_A(			Route_Bwd_Rls_S			),
		.I_Rls_B(			Route_Bwd_Rls_V[0]		),
		.I_Data_A(			Route_Bwd_Data_S		),
		.I_Data_B(			Route_Bwd_Data_V[0]		)
	);

	DMem_Body DMem_S (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			'0						),
		.I_Rt_Req(			Route_Fwd_Req_S			),
		.I_Rt_Data(			Route_Fwd_Data_S		),
		.I_Rt_Rls(			Route_Fwd_Rls_S			),
		.O_Rt_Req(			Route_Bwd_Req_S			),
		.O_Rt_Data(			Route_Bwd_Data_S		),
		.O_Rt_Rls(			Route_Bwd_Rls_S			),
		.I_St_Req1(			I_S_LdSt[0].st.req		),
		.I_St_Req2(			I_S_LdSt[1].st.req		),
		.I_Ld_Req1(			I_S_LdSt[0].ld.req		),
		.I_Ld_Req2(			I_S_LdSt[1].ld.req		),
		.I_St_Length1(		I_S_LdSt[0].st.len		),
		.I_St_Stride1(		I_S_LdSt[0].st.stride	),
		.I_St_Base_Addr1(	I_S_LdSt[0].st.base		),
		.I_St_Length2(		I_S_LdSt[1].st.len		),
		.I_St_Stride2(		I_S_LdSt[1].st.stride	),
		.I_St_Base_Addr2(	I_S_LdSt[1].st.base		),
		.I_Ld_Length1(		I_S_LdSt[0].ld.len		),
		.I_Ld_Stride1(		I_S_LdSt[0].ld.stride	),
		.I_Ld_Base_Addr1(	I_S_LdSt[0].ld.base		),
		.I_Ld_Length2(		I_S_LdSt[1].ld.len		),
		.I_Ld_Stride2(		I_S_LdSt[1].ld.stride	),
		.I_Ld_Base_Addr2(	I_S_LdSt[1].ld.base		),
		.I_St_Valid1(		I_S_LdSt[0].st.req		),
		.I_St_Valid2(		I_S_LdSt[1].st.req		),
		.I_Ld_Valid1(		I_S_LdSt[0].ld.req		),
		.I_Ld_Valid2(		I_S_LdSt[1].ld.req		),
		.I_St_Data1(		I_S_St_Data[0]			),
		.I_St_Data2(		I_S_St_Data[1]			),
		.O_Ld_Data1(		O_S_Ld_Data[0]			),
		.O_Ld_Data2(		O_S_Ld_Data[1]			),
		.O_St_Grant1(		O_S_St_Grant[0]			),
		.O_St_Grant2(		O_S_St_Grant[1]			),
		.O_Ld_Grant1(		O_S_Ld_Grant[0]			),
		.O_Ld_Grant2(		O_S_Ld_Grant[1]			),
		.O_St_Ready1(		O_S_St_Ready[0]			),
		.O_St_Ready2(		O_S_St_Ready[1]			),
		.O_Ld_Ready1(		O_S_Ld_Ready[0]			),
		.O_Ld_Ready2(		O_S_Ld_Ready[1]			)
	);


	for ( genvar i=0; i<NUM_LANES; ++i ) begin

		Router Router_V (
			.clock(				clock					),
			.reset(				reset					),
			.I_Req(				Route_Fwd_Req_V{i}		),
			.I_Rls(				Route_Fwd_Rls_V{i}		),
			.I_Data(			Route_Fwd_Data_V{i}		),
			.O_Req_A(			Route_Fwd_Req_V[ i+1 ]	),
			.O_Req_B(			Route_Fwd_Req_V[i]		),
			.O_Data_A(			Route_Fwd_Data_V[ i+1 ]	),
			.O_Data_B(			Route_Fwd_Data_V[i]		),
			.O_Rls_A(			Route_Fwd_Rls_V[ i+1 ]	),
			.O_Rls_B(			Route_Fwd_Rls_V[i]		),
			.O_Req(				Route_Bwd_Req_V[i]		),
			.O_Rls(				Route_Bwd_Rls_V[i]		),
			.O_Data(			Route_Bwd_Data_V[i]		),
			.I_Req_A(			Route_Bwd_Req_V[i]		),
			.I_Req_B(			Route_Bwd_Req_V[ i+1 ]	),
			.I_Rls_A(			Route_Bwd_Rls_V[i]		),
			.I_Rls_B(			Route_Bwd_Rls_V[ i+1 ]	),
			.I_Data_A(			Route_Bwd_Data_V[i]		),
			.I_Data_B(			Route_Bwd_Data_V[ i+1 ]	)
		);

		DMem_Body DMem_V (
			.clock(				clock					),
			.reset(				reset					),
			.I_Stall(			'0						),
			.I_Rt_Req(			Route_Fwd_Req_V[1]		),
			.I_Rt_Data(			Route_Fwd_Data_V[1]		),
			.I_Rt_Rls(			Route_Fwd_Rls_V[1]		),
			.O_Rt_Req(			Route_Bwd_Req_V[1]		),
			.O_Rt_Data(			Route_Bwd_Data_V[1]		),
			.O_Rt_Rls(			Route_Bwd_Rls_V[1]		),
			.I_St_Req1(			I_V_LdSt[i][0].st.req	),
			.I_St_Req2(			I_V_LdSt[i][1].st.req	),
			.I_Ld_Req1(			I_V_LdSt[i][0].ld.req	),
			.I_Ld_Req2(			I_V_LdSt[i][1].ld.req	),
			.I_St_Length1(		I_V_LdSt[i][0].st.len	),
			.I_St_Stride1(		I_V_LdSt[i][0].st.stride),
			.I_St_Base_Addr1(	I_V_LdSt[i][0].st.base	),
			.I_St_Length2(		I_V_LdSt[i][1].st.len	),
			.I_St_Stride2(		I_V_LdSt[i][1].st.stride),
			.I_St_Base_Addr2(	I_V_LdSt[i][1].st.base	),
			.I_Ld_Length1(		I_V_LdSt[i][0].ld.len	),
			.I_Ld_Stride1(		I_V_LdSt[i][0].ld.stride),
			.I_Ld_Base_Addr1(	I_V_LdSt[i][0].ld.base	),
			.I_Ld_Length2(		I_V_LdSt[i][1].ld.len	),
			.I_Ld_Stride2(		I_V_LdSt[i][1].ld.stride),
			.I_Ld_Base_Addr2(	I_V_LdSt[i][1].ld.base	),
			.I_St_Valid1(		I_V_LdSt[i][0].st.req	),
			.I_St_Valid2(		I_V_LdSt[i][1].st.req	),
			.I_Ld_Valid1(		I_V_LdSt[i][0].ld.req	),
			.I_Ld_Valid2(		I_V_LdSt[i][1].ld.req	),
			.I_St_Data1(		I_V_St_Data[i][0]		),
			.I_St_Data2(		I_V_St_Data[i][1]		),
			.O_Ld_Data1(		O_V_Ld_Data[i][0]		),
			.O_Ld_Data2(		O_V_Ld_Data[i][1]		),
			.O_St_Grant1(		O_V_St_Grant[i][0]		),
			.O_St_Grant2(		O_V_St_Grant[i][1]		),
			.O_Ld_Grant1(		O_V_Ld_Grant[i][0]		),
			.O_Ld_Grant2(		O_V_Ld_Grant[i][1]		),
			.O_St_Ready1(		O_V_St_Ready[i][0]		),
			.O_St_Ready2(		O_V_St_Ready[i][1]		),
			.O_Ld_Ready1(		O_V_Ld_Ready[i][0]		),
			.O_Ld_Ready2(		O_V_Ld_Ready[i][1]		)
		);
	end

endmodule