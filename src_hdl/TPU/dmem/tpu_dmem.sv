///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	DMem_Body
///////////////////////////////////////////////////////////////////////////////////////////////////

module DMem_Body
	import pkg_tpu::*;
(
	input						clock,
	input						reset,
	input						I_St_Req1,						//Flag Store Request
	input						I_St_Req2,						//Flag Store Request
	input						I_Ld_Req1,						//Flag Load Request
	input						I_Ld_Req2,						//Flag Load Reques
	input	address_t			I_St_Length1,					//Access Length
	input	address_t			I_St_Stride1,					//Stride Factor
	input	address_t			I_St_Base_Addr1,				//Base Address
	input	address_t			I_St_Length2,					//Access Length
	input	address_t			I_St_Stride2,					//Stride Factor
	input	address_t			I_St_Base_Addr2,				//Base Address
	input	address_t			I_Ld_Length1,					//Access Length
	input	address_t			I_Ld_Stride1,					//Stride Factor
	input	address_t			I_Ld_Base_Addr1,				//Base Address
	input	address_t			I_Ld_Length2,					//Access Length
	input	address_t			I_Ld_Stride2,					//Stride Factor
	input	address_t			I_Ld_Base_Addr2,				//Base Address
	input						I_St_Valid1,					//Flag: Storing Data Validation
	input						I_St_Valid2,					//Flag: Storing Data Validation
	input						I_Ld_Valid1,					//Flag: Loading Data Validation
	input						I_Ld_Valid2,					//Flag: Loading Data Validation
	input	data_t				I_St_Data1,						//Store Data
	input	data_t				I_St_Data2,						//Store Data
	output	data_t				O_Ld_Data1,						//Load Data
	output	data_t				O_Ld_Data2,						//Load Data
	output	logic				O_St_Grant1,					//Grant for Store Req
	output	logic				O_St_Grant2,					//Grant for Store Req
	output	logic				O_Ld_Grant1,					//Grant for Load Req
	output	logic				O_Ld_Grant2,					//Grant for Load Req
	output	logic				O_St_Ready1,					//Ready to Store
	output	logic				O_St_Ready2,					//Ready to Store
	output	logic				O_Ld_Ready1,					//Ready to Load
	output	logic				O_Ld_Ready2						//Ready to Load
);


	logic						Ld_Req;
	logic						ST_Req;

	logic						Ld_GrantVld;
	logic						St_GrantVld;
	logic						Ld_GrantNo;
	logic						St_GrantNo;

	logic						St_Grant1;
	logic						St_Grant2;
	logic						Ld_Grant1;
	logic						Ld_Grant2;

	logic						St_Public;
	logic						Ld_Public;

	logic						St_Valid;
	logic						Ld_Valid;

	logic						St_Offset;
	logic						Ld_Offset;

	address_t					St_Base;
	address_t					Ld_Base;

	address_t					Length_St;
	address_t					Length_Ld;
	address_t					Stride_St;
	address_t					Stride_Ld;
	address_t					Base_Addr_St;
	address_t					Base_Addr_Ld;

	logic						Set_Cfg_St;
	logic						Set_Cfg_Ld;
	logic						Set_Config_St;
	logic						Set_Config_Ld;

	data_t						DataMem	[SIZE_DATA_MEM-1:0];


	assign St_Public		= St_Ready1 | St_Ready2;
	assign Ld_Public		= Ld_Ready1 | Ld_Ready2;

	assign St_Private		= ~Base_Addr_St[POS__MSB_DMEM_ADDR+1] & St_GrantVld;
	assign Ld_Private		= ~Base_Addr_Ld[POS__MSB_DMEM_ADDR+1] & Ld_GrantVld;

	assign St_Grant1		= St_GrantVld & ~St_GrantNo;
	assign St_Grant2		= St_GrantVld &  St_GrantNo;
	assign Ld_Grant1		= Ld_GrantVld & ~Ld_GrantNo;
	assign Ld_Grant2		= Ld_GrantVld &  Ld_GrantNo;


	assign St_Offset		= ~St_Public & St_GrantVld & St_GrantNo;
	assign Ld_Offset		= ~Ld_Public & Ld_GrantVld & Ld_GrantNo;

	assign St_Valid			= ( I_St_Valid1 & O_St_Grant1 ) | ( I_St_Valid2 & O_St_Grant2 );
	assign Ld_Valid			= ( I_Ld_Valid1 & O_Ld_Grant1 ) | ( I_Ld_Valid2 & O_Ld_Grant2 );
	assign St_Base			= { St_Public, St_Offset, Base_Addr_St[POS__MSB_DMEM_ADDR:0] };
	assign Ld_Base			= { Ld_Public, Ld_Offset, Base_Addr_Ld[POS__MSB_DMEM_ADDR:0] };

	assign Set_Cfg_St		= Set_Config_St | ( ~R_St_Private & St_Private );
	assign Set_Cfg_Ld		= Set_Config_Ld | ( ~R_Ld_Private & Ld_Private );


	assign St_Data			= (   St_Grant1 ) ?	I_St_Data1 :
								( St_Grant2 ) ?	I_St_Data2 :
												0;

	assign O_Ld_Data1		= (  Ld_Grant1 ) ?	Ld_Data : 0;
	assign O_Ld_Data2		= (  Ld_Grant2 ) ?	Ld_Data : 0;


	assign O_St_Grant1		= St_Grant1;
	assign O_St_Grant2		= St_Grant2;
	assign O_Ld_Grant1		= Ld_Grant1;
	assign O_Ld_Grant2		= Ld_Grant2;

	assign O_St_Ready1		= St_Ready1 | ( R_St_Private & St_Grant1 );
	assign O_St_Ready2		= St_Ready2 | ( R_St_Private & St_Grant2 );
	assign O_Ld_Ready1		= Ld_Ready1 | ( R_Ld_Private & Ld_Grant1 );
	assign O_Ld_Ready2		= Ld_Ready2 | ( R_Ld_Private & Ld_Grant2 );


	always_ff @( posedge clock ) begin
		if ( Req_St ) begin
			DataMem[ Address_St ]	<= St_Data;
		end
	end

	always_ff @( posedge clock ) begin
		if ( Req_Ld ) begin
			Ld_Data		<= DataMem[ Address_Ld ];
		end
	end


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_St_Private		<= 1'b0;
		end
		else if ( End_St ) begin
			R_St_Private		<= 1'b0;
		end
		else if ( St_Private ) begin
			R_St_Private		<= 1'b1;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Ld_Private		<= 1'b0;
		end
		else if ( End_Ld ) begin
			R_Ld_Private		<= 1'b0;
		end
		else if ( Ld_Private ) begin
			R_Ld_Private		<= 1'b1;
		end
	end


	ReqHandle_St ReqHandle_St
	(
		.clock(				clock						),
		.reset(				reset						),
		.I_St_Req1(			I_St_Req1					),
		.I_St_Req2(			I_St_Req2					),
		.I_Length1(			I_St_Length1				),
		.I_Stride1(			I_St_Stride1				),
		.I_Base_Addr1(		I_St_Base_Addr1				),
		.I_Length2(			I_St_Length2				),
		.I_Stride2(			I_St_Stride2				),
		.I_Base_Addr2(		I_St_Base_Addr2				),
		.O_Length(			Length_St					),
		.O_Stride(			Stride_St					),
		.O_Base_Addr(		Base_Addr_St				),
		.O_Grant1(			O_St_Grant1					),
		.O_Grant2(			O_St_Grant2					),
		.O_St_Req(			St_Req						),
		.O_GranndVld(		St_GrantVld					),
		.O_GrantNo(			St_GrantNo					)
	);

	ReqHandle_Ld ReqHandle_Ld
	(
		.clock(				clock						),
		.reset(				reset						),
		.I_Ld_Req1(			I_Ld_Req1					),
		.I_Ld_Req2(			I_Ld_Req2					),
		.I_Length1(			I_Ld_Length1				),
		.I_Stride1(			I_Ld_Stride1				),
		.I_Base_Addr1(		I_Ld_Base_Addr1				),
		.I_Length2(			I_Ld_Length2				),
		.I_Stride2(			I_Ld_Stride2				),
		.I_Base_Addr2(		I_Ld_Base_Addr2				),
		.O_Length(			Length_Ld					),
		.O_Stride(			Stride_Ld					),
		.O_Base_Addr(		Base_Addr_Ld				),
		.O_Grant1(			O_Ld_Grant1					),
		.O_Grant2(			O_Ld_Grant2					),
		.O_Ld_Req(			Ld_Req						),
		.O_GranndVld(		Ld_GrantVld					),
		.O_GrantNo(			Ld_GrantNo					)
	);

	PubDomain_Man #(
		.NUM_ENTRY(			32							)
	) PubDomain_Man
	(
		.clock(				clock						),
		.reset(				reset						),
		.I_St_Base(			St_Base						),
		.I_Ld_Base(			Ld_Base						),
		.I_St_Grant1(		St_Grant1					),
		.I_St_Grant2(		St_Grant2					),
		.I_Ld_Grant1(		Ld_Grant1					),
		.I_Ld_Grant2(		Ld_Grant2					),
		.I_St_End(			End_St						),
		.I_Ld_End(			End_Ld						),
		.I_GrantVld_St(		St_GrantVld					),
		.I_GrantVld_Ld(		Ld_GrantVld					),
		.I_GrantNo_St(		St_GrantNo					),
		.I_GrantNo_Ld(		Ld_GrantNo					),
		.O_St_Ready1(		St_Ready1					),
		.O_St_Ready2(		St_Ready2					),
		.O_Ld_Ready1(		Ld_Ready1					),
		.O_Ld_Ready2(		Ld_Ready2					),
		.O_Set_Config_St(	Set_Config_St				),
		.O_Set_Config_Ld(	Set_Config_Ld				)
	);

	AGU AGU_St (
		.clock(				clock						),
		.reset(				reset						),
		.I_Req(				Set_Cfg_St					),
		.I_Stall(			~St_Valid					),
		.I_Length(			Length_St					),
		.I_Stride(			Strude_St					),
		.I_Base_Addr(		St_Base						),
		.O_Address(			Address_St					),
		.O_Req(				Req_St						),
		.O_End_Access(		End_St						)
	);

	AGU AGU_Ld (
		.clock(				clock						),
		.reset(				reset						),
		.I_Req(				Set_Cfg_Ld					),
		.I_Stall(			~Ld_Valid					),
		.I_Length(			Length_Ld					),
		.I_Stride(			Strude_Ld					),
		.I_Base_Addr(		Ld_Base						),
		.O_Address(			Address_Ld					),
		.O_Req(				Req_Ld						),
		.O_End_Access(		End_Ld						)
	);

endmodule