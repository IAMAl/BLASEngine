module DMem
	import pkg_tpu::*;
(
	input						clock,
	input						reset,
	input						I_Rt_Req,				//Request from Router
	input	data_t				I_Rt_Data,				//Data from Router
	input	logic				I_Rt_Rls,				//Release Token from Router
	input						O_Rt_Req,				//Request to Router
	input	data_t				O_Rt_Data,				//Data to Router
	input						O_Rt_Rls,				//Release Token to Router
	input						I_St_Req1,				//Flag Store Request
	input						I_St_Req2,				//Flag Store Request
	input						I_Ld_Req1,				//Flag Load Request
	input						I_Ld_Req2,				//Flag Load Reques
	input	address_t			I_St_Length1,			//Access Length
	input	address_t			I_St_Stride1,			//Stride Factor
	input	address_t			I_St_Base_Addr1,		//Base Address
	input	address_t			I_St_Length2,			//Access Length
	input	address_t			I_St_Stride2,			//Stride Factor
	input	address_t			I_St_Base_Addr2,		//Base Address
	input	address_t			I_Ld_Length1,			//Access Length
	input	address_t			I_Ld_Stride1,			//Stride Factor
	input	address_t			I_Ld_Base_Addr1,		//Base Address
	input	address_t			I_Ld_Length2,			//Access Length
	input	address_t			I_Ld_Stride2,			//Stride Factor
	input	address_t			I_Ld_Base_Addr2,		//Base Address
	input						I_St_Valid1,			//Flag: Storing Data Validation
	input						I_St_Valid2,			//Flag: Storing Data Validation
	input						I_Ld_Valid1,			//Flag: Loading Data Validation
	input						I_Ld_Valid2,			//Flag: Loading Data Validation
	input	data_t				I_St_Data1,				//Store Data
	input	data_t				I_St_Data2,				//Store Data
	output	data_t				O_Ld_Data1,				//Load Data
	output	data_t				O_Ld_Data2,				//Load Data
	output	logic				O_St_Grant1,			//Grant for Store Req
	output	logic				O_St_Grant2,			//Grant for Store Req
	output	logic				O_Ld_Grant1,			//Grant for Load Req
	output	logic				O_Ld_Grant2,			//Grant for Load Req
	output	logic				O_St_Ready1,			//Ready to Store
	output	logic				O_St_Ready2,			//Ready to Store
	output	logic				O_Ld_Ready1,			//Ready to Load
	output	logic				O_Ld_Ready2				//Ready to Load
);


	logic						Ld_Req;
	logic						ST_Req;

	logic						Ld_GrantVld;
	logic						St_GrantVld;
	logic						Ld_GrantNo;
	logic						St_GrantNo;

	logic						St_Grant1;
	logic						St_Grant2;
	logic						St_Grant3;
	logic						Ld_Grant1;
	logic						Ld_Grant2;
	logic						Ld_Grant3;

	logic						St_Public;
	logic						Ld_Public;

	logic						St_Valid;
	logic						Ld_Valid;

	logic						St_Offset;
	logic						Ld_Offset;

	address_d_t					St_Base;
	address_d_t					Ld_Base;

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


	logic						Extern_Ld_Req;
	address_t					Extern_Ld_Length;
	address_t					Extern_Ld_Stride;
	address_t					Extern_Ld_Base;
	logic						Extern_Ld_Grant;
	logic						Extern_Ld_Term;

	logic						Extern_St_Req;
	address_t					Extern_St_Length;
	address_t					Extern_St_Stride;
	address_t					Extern_St_Base;
	logic						Extern_St_Grant;
	logic						Extern_St_Term;


	data_t						DataMem	[SIZE_DATA_MEM-1:0];


	assign St_Public			= St_Ready1 | St_Ready2;
	assign Ld_Public			= Ld_Ready1 | Ld_Ready2;

	assign St_Private			= ~Base_Addr_St[POS__MSB_DMEM_ADDR+1] & St_GrantVld;
	assign Ld_Private			= ~Base_Addr_Ld[POS__MSB_DMEM_ADDR+1] & Ld_GrantVld;

	assign St_Grant1			= St_GrantVld & ( St_GrantNo == 2'h0 );
	assign St_Grant2			= St_GrantVld & ( St_GrantNo == 2'h1 );
	assign St_Grant3			= St_GrantVld & ( St_GrantNo == 2'h2 );

	assign Ld_Grant1			= Ld_GrantVld & ( Ld_GrantNo == 2'h0 );
	assign Ld_Grant2			= Ld_GrantVld & ( Ld_GrantNo == 2'h1 );
	assign Ld_Grant3			= Ld_GrantVld & ( Ld_GrantNo == 2'h2 );


	assign St_Offset			= ~St_Public & St_GrantVld & St_GrantNo;
	assign Ld_Offset			= ~Ld_Public & Ld_GrantVld & Ld_GrantNo;

	assign St_Valid				= ( I_St_Valid1 & O_St_Grant1 ) | ( I_St_Valid2 & O_St_Grant2 );
	assign Ld_Valid				= ( I_Ld_Valid1 & O_Ld_Grant1 ) | ( I_Ld_Valid2 & O_Ld_Grant2 );
	assign St_Base				= { St_Public, St_Offset, Base_Addr_St[POS__MSB_DMEM_ADDR:0] };
	assign Ld_Base				= { Ld_Public, Ld_Offset, Base_Addr_Ld[POS__MSB_DMEM_ADDR:0] };

	assign Set_Cfg_St			= Set_Config_St | ( ~R_St_Private & St_Private );
	assign Set_Cfg_Ld			= Set_Config_Ld | ( ~R_Ld_Private & Ld_Private );


	assign St_Data				= (   St_Grant1 ) ?	I_St_Data1 :
									( St_Grant2 ) ?	I_St_Data2 :
									( St_Grant3 ) ?	Extern_St_Data :
													0;


	assign Extern_St_Term		= End_St;
	assign Extern_Ld_Term		= End_Ld;
	assign Extern_St_Grant		= St_Grant3;
	assign Extern_Ld_Grant		= Ld_Grant3;


	assign O_Ld_Data1			= (  Ld_Grant1 ) ?	Ld_Data : 0;
	assign O_Ld_Data2			= (  Ld_Grant2 ) ?	Ld_Data : 0;
	assign Extern_Ld_Data		= (  Ld_Grant3 ) ?	Ld_Data : 0;

	assign O_St_Grant1			= St_Grant1;
	assign O_St_Grant2			= St_Grant2;
	assign O_Ld_Grant1			= Ld_Grant1;
	assign O_Ld_Grant2			= Ld_Grant2;

	assign O_St_Ready1			= St_Ready1 | ( R_St_Private & St_Grant1 );
	assign O_St_Ready2			= St_Ready2 | ( R_St_Private & St_Grant2 );
	assign O_Ld_Ready1			= Ld_Ready1 | ( R_Ld_Private & Ld_Grant1 );
	assign O_Ld_Ready2			= Ld_Ready2 | ( R_Ld_Private & Ld_Grant2 );


	always_ff @( posedge clock ) begin
		if ( Req_St ) begin
			DataMem[ Address_St ]	<= St_Data;
		end
	end

	always_ff @( posedge clock ) begin
		if ( Req_Ld ) begin
			Ld_Data			<= DataMem[ Address_Ld ];
		end
	end


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_St_Private	<= 1'b0;
		end
		else if ( End_St ) begin
			R_St_Private	<= 1'b0;
		end
		else if ( St_Private ) begin
			R_St_Private	<= 1'b1;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Ld_Private	<= 1'b0;
		end
		else if ( End_Ld ) begin
			R_Ld_Private	<= 1'b0;
		end
		else if ( Ld_Private ) begin
			R_Ld_Private	<= 1'b1;
		end
	end


	extern_handle extern_handle (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				I_Rt_Req				),
		.I_Data(			I_Rt_Data				),
		.I_Rls(				I_Rt_Rls				),
		.O_Req(				O_Rt_Req				),
		.O_Data(			O_Rt_Data				),
		.O_Rls(				O_Rt_Rls				),
		.O_Ld_Req(			Extern_Ld_Req			),
		.O_Ld_Length(		Extern_Ld_Length		),
		.O_Ld_Stride(		Extern_Ld_Stride		),
		.O_Ld_Base(			Extern_Ld_Base			),
		.I_Ld_Grant(		Extern_Ld_Grant			),
		.I_Ld_Data(			Extern_Ld_Data			),
		.I_Ld_Term(			Extern_Ld_Term			),
		.O_St_Req(			Extern_St_Req			),
		.O_St_Length(		Extern_St_Length		),
		.O_St_Stride(		Extern_St_Stride		),
		.O_St_Base(			Extern_St_Base			),
		.I_St_Grant(		Extern_St_Grant			),
		.O_St_Data(			Extern_St_Data			),
		.I_St_Term(			Extern_St_Term			)
	);


	req_handle req_handle_st (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req1(			I_St_Req1				),
		.I_Req2(			I_St_Req2				),
		.I_Req3(			Extern_St_Req			),
		.I_Term1(			End_St					),
		.I_Term2(			End_St					),
		.I_Term3(			End_St					),
		.I_Length1(			I_St_Length1			),
		.I_Stride1(			I_St_Stride1			),
		.I_Base_Addr1(		I_St_Base_Addr1			),
		.I_Length2(			I_St_Length2			),
		.I_Stride2(			I_St_Stride2			),
		.I_Base_Addr2(		I_St_Base_Addr2			),
		.I_Length3(			Extern_St_Length		),
		.I_Stride3(			Extern_St_Stride		),
		.I_Base_Addr3(		Extern_St_Base			),
		.O_Length(			Length_St				),
		.O_Stride(			Stride_St				),
		.O_Base_Addr(		Base_Addr_St			),
		.O_Grant1(			O_St_Grant1				),
		.O_Grant2(			O_St_Grant2				),
		.O_Grant3(									),
		.O_St_Req(			St_Req					),
		.O_GranndVld(		St_GrantVld				),
		.O_GrantNo(			St_GrantNo				)
	);

	req_handle req_handle_ld (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req1(			I_Ld_Req1				),
		.I_Req2(			I_Ld_Req2				),
		.I_Req2(			Extern_Ld_Req			),
		.I_Term1(			End_Ld					),
		.I_Term2(			End_Ld					),
		.I_Term3(			End_Ld					),
		.I_Length1(			I_Ld_Length1			),
		.I_Stride1(			I_Ld_Stride1			),
		.I_Base_Addr1(		I_Ld_Base_Addr1			),
		.I_Length2(			I_Ld_Length2			),
		.I_Stride2(			I_Ld_Stride2			),
		.I_Base_Addr2(		I_Ld_Base_Addr2			),
		.I_Length3(			Extern_Ld_Length		),
		.I_Stride3(			Extern_Ld_Stride		),
		.I_Base_Addr3(		Extern_Ld_Base			),
		.O_Length(			Length_Ld				),
		.O_Stride(			Stride_Ld				),
		.O_Base_Addr(		Base_Addr_Ld			),
		.O_Grant1(			O_Ld_Grant1				),
		.O_Grant2(			O_Ld_Grant2				),
		.O_Grant3(									),
		.O_Ld_Req(			Ld_Req					),
		.O_GranndVld(		Ld_GrantVld				),
		.O_GrantNo(			Ld_GrantNo				)
	);

	pub_domain_man #(
		.NUM_ENTRY(			32						)
	) pub_domain_man
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_St_Base(			St_Base					),
		.I_Ld_Base(			Ld_Base					),
		.I_St_Grant1(		St_Grant1				),
		.I_St_Grant2(		St_Grant2				),
		.I_St_Grant3(		Ld_Grant3				),
		.I_Ld_Grant1(		Ld_Grant1				),
		.I_Ld_Grant2(		Ld_Grant2				),
		.I_Ld_Grant3(		Ld_Grant3				),
		.I_St_End(			End_St					),
		.I_Ld_End(			End_Ld					),
		.I_GrantVld_St(		St_GrantVld				),
		.I_GrantVld_Ld(		Ld_GrantVld				),
		.I_GrantNo_St(		St_GrantNo				),
		.I_GrantNo_Ld(		Ld_GrantNo				),
		.O_St_Ready1(		St_Ready1				),
		.O_St_Ready2(		St_Ready2				),
		.O_Ld_Ready1(		Ld_Ready1				),
		.O_Ld_Ready2(		Ld_Ready2				),
		.O_Set_Config_St(	Set_Config_St			),
		.O_Set_Config_Ld(	Set_Config_Ld			)
	);

	agu agu_st (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				Set_Cfg_St				),
		.I_Stall(			~St_Valid				),
		.I_Length(			Length_St				),
		.I_Stride(			Strude_St				),
		.I_Base_Addr(		St_Base					),
		.O_Address(			Address_St				),
		.O_Req(				Req_St					),
		.O_End_Access(		End_St					)
	);

	agu agu_ld (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				Set_Cfg_Ld				),
		.I_Stall(			~Ld_Valid				),
		.I_Length(			Length_Ld				),
		.I_Stride(			Strude_Ld				),
		.I_Base_Addr(		Ld_Base					),
		.O_Address(			Address_Ld				),
		.O_Req(				Req_Ld					),
		.O_End_Access(		End_Ld					)
	);

endmodule