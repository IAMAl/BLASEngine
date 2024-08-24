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
	input						O_Rt_Req,				//Request to Router
	input	data_t				O_Rt_Data,				//Data to Router
	input	s_ldst_t			I_LdSt,					//Load/Store Command
	output	s_ld_data			O_Ld_Data,				//Loaded Data, to TPU Core
	input	s_st_data			I_St_Data,				//Storing Data, from TPU Core
	output	[1:0]				O_Ld_Ready,				//Flag: Ready to Service
	output	[1:0]				O_Ld_Grant,				//Flag: Grant for Request
	output	[1:0]				O_St_Ready,				//Flag: Ready to Service
	output	[1:0]				O_St_Grant				//Flag: Grant for Request
	);

	DMem_Body DMem_Body (
		.clock(				clock						),
		.reset(				reset						),
		.I_Rt_Req(			I_Rt_Req					),
		.I_Rt_Data(			I_Rt_Data					),
		.O_Rt_Req(			O_Rt_Req					),
		.O_Rt_Data(			O_Rt_Data					),
		.I_St_Req1(			I_LdSt[0].st.req			),
		.I_St_Req2(			I_LdSt[1].st.req			),
		.I_Ld_Req1(			I_LdSt[0].ld.req			),
		.I_Ld_Req2(			I_LdSt[1].ld.req			),
		.I_St_Length1(		I_LdSt[0].st.len			),
		.I_St_Stride1(		I_LdSt[1].st.stride			),
		.I_St_Base_Addr1(	I_LdSt[0].st.base			),
		.I_St_Length2(		I_LdSt[1].st.len			),
		.I_St_Stride2(		I_LdSt[1].st.stride			),
		.I_St_Base_Addr2(	I_LdSt[1].st.base			),
		.I_Ld_Length1(		I_LdSt[0].ld.len			),
		.I_Ld_Stride1(		I_LdSt[0].ld.stride			),
		.I_Ld_Base_Addr1(	I_LdSt[0].ld.base			),
		.I_Ld_Length2(		I_LdSt[1].ld.len			),
		.I_Ld_Stride2(		I_LdSt[1].ld.stride			),
		.I_Ld_Base_Addr2(	I_LdSt[1].ld.base			),
		.I_St_Valid1(		I_LdSt[0].st.v				),
		.I_St_Valid2(		I_LdSt[1].st.v				),
		.I_Ld_Valid1(		I_LdSt[0].ld.v				),
		.I_Ld_Valid2(		I_LdSt[1].ld.v				),
		.I_St_Data1(		I_St_Data[0]				),
		.I_St_Data2(		I_St_Data[1]				),
		.O_Ld_Data1(		O_Ld_Data[0]				),
		.O_Ld_Data2(		O_Ld_Data[1]				),
		.O_St_Grant1(		O_St_Grant[0]				),
		.O_St_Grant2(		O_St_Grant[1]				),
		.O_Ld_Grant1(		O_Ld_Grant[0]				),
		.O_Ld_Grant2(		O_Ld_Grant[1]				),
		.O_St_Ready1(		O_St_Ready[0]				),
		.O_St_Ready2(		O_St_Ready[1]				),
		.O_Ld_Ready1(		O_Ld_Ready[0]				),
		.O_Ld_Ready2(		O_Ld_Ready[1]				)
	);

endmodule