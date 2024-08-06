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
	input	ack_ld_t			I_Ack_Ld,				//Acknowledge fro Loading
	output	v_address_t			O_Address,				//Data Memory Address
	output	v_store_t			O_St,					//Store Request
	output	v_load_req_t		O_Ld,					//Load Request
	input	v_load_t			I_Ld,					//Loaded Data
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
		Lane_Unit (
			.clock(				clock					),
			.reset(				reset					),
			.I_En(				I_En_Lane[ i ]			),
			.I_LaneID(			i						),
			.I_ThreadID(		I_ThreadID				),
			.I_Command(			I_Command				),
			.I_Scalar_Data(		I_Scalar_Data			),
			.O_Scalar_Data(		Scalr_Data[ i ]			),
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