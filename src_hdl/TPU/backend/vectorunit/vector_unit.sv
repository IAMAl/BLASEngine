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
	import pkg_tpu::*;
(
	input						clock,
	input						reset,
	input	lane_t				I_En_Lane,				//Enable to Execution on Lane
	input	id_t				I_ThreadID,				//SIMT Thread-ID
	input	v_commant_t			I_Command,				//Comamnd to Execute
	input	data_t				I_Scalar_Data,			//Scalar Data
	output	data_t				O_Scalar_Data,			//Scalar Data
	output	v_ldst_t			O_LdSt,					//Load Request
	input	v_data				I_LdData,
	output	v_data				O_StData,
	output	logic				O_Commmit_Req,			//Commit Request
	output	lane_t				O_Status				//Status on Lane
);


	lane_t						Lane_Data_Src1;
	lane_t						Lane_Data_Src2;
	lane_t						Lane_Data_Src3;

	lane_t						Commit;


	assign O_Commmit_Req		= &( ~( I_En_Lane ^ Commit ) );


	//Vector-Lane Generation
	for ( genvar i=0; i<NUM_LANE; ++i ) begin
		Lane_Unit #(
			.NUM_LANES(			NUM_LANES				),
			.LANE_ID(			i						)
		) Lane_Unit
		(
			.clock(				clock					),
			.reset(				reset					),
			.I_En(				I_En_Lane[ i ]			),
			.I_LaneID(			i						),
			.I_ThreadID(		I_ThreadID				),
			.I_Command(			I_Command				),
			.I_Scalar_Data(		I_Scalar_Data			),
			.O_Scalar_Data(		Scalr_Data[ i ]			),
			.O_LdSt1(			O_LdSt[0][ i ]			),
			.O_LdSt2(			O_LdSt[1][ i ]			),
			.I_LdData1(			I_LdData[0][ i ]		),
			.I_LdData2(			I_LdData[1][ i ]		),
			.O_St_Data1(		O_StData[0][ i ]		),
			.O_St_Data2(		O_StData[1][ i ]		),
			.O_Commit(			Commit[ i ]				),
			.I_Lane_Data_Src1(	Lane_Data_Src1			),
			.I_Lane_Data_Src2(	Lane_Data_Src2			),
			.I_Lane_Data_Src3(	Lane_Data_Src3			),
			.O_Lane_Src1(		Lane_Data_Src1[ i ]		),
			.O_Lane_Src2(		Lane_Data_Src2[ i ]		),
			.O_Lane_Src3(		Lane_Data_Src3[ i ]		),
			.O_Status(			O_Status[ i ]			)
		);
	end

endmodule