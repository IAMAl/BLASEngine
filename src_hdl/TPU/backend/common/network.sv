module Network
	import pkg_tpu::*;
#(
	parameter int NUM_LANES		= 16,
	parameter int WIDTH_LANES	= $clog2(NUM_LANES);
)(
	input	[8:0]				I_Config_Path,					//Path Selects
	input	issue_no_t			I_Issue_No,						//Issue No from Reg Read Pipe
	input	issue_no_t			I_Issue_No_WB1,					//Commit No from Write-Back-1
	input	issue_no_t			I_Issue_No_WB2,					//Commit No from Write-Back-2
	input	data_t				I_Path_Data,					//From Hop Length Path
	input	data_t				I_Scalar_Data,					//From Scalar Unit
	input	data_t				I_Src_Data1,					//From RegFile after Rotation Path
	input	data_t				I_Src_Data2,					//From RegFile after Rotation Path
	input	data_t				I_Src_Data3,					//From RegFile after Rotation Path
	input	index_t				I_WB_Index1,					//From ALU
	input	index_t				I_WB_Index2,					//From ALU
	input	data_t				I_WB_Data1,						//From ALU
	input	data_t				I_WB_Data2,						//From ALU
	output	data_t				O_Src_Data1,					//To Exec Unit
	output	data_t				O_Src_Data2,					//To Exec Unit
	output	data_t				O_Src_Data3,					//To Exec Unit
	output	data_t				O_Src_Data4,					//To Exec Unit
	output	index_t				O_WB_Index1,					//To RegFile
	output	index_t				O_WB_Index2,					//To RegFile
	output	data_t				O_WB_Data1,						//To RegFile
	output	data_t				O_WB_Data2,						//To RegFile
	output	address_t			O_Address,						//To Load/Store Unit
	output	address_t			O_Stride,						//To Load/Store Unit
	output	address_t			O_Length						//To Load/Store Unit
);


	logic						Sel_Data1;
	logic						Sel_Data2;
	logic						Sel_Data3;

	logic						Sel_Bypass11;
	logic						Sel_Bypass12;
	logic						Sel_Bypass13;

	logic						Sel_Bypass21;
	logic						Sel_Bypass22;
	logic						Sel_Bypass23;

	logic						Sel_Scalar1;
	logic						Sel_Scalar2;
	data_t						Path_Data;

	logic						Sel_Addr_Data1;
	logic						Sel_Addr_Data2;
	logic						Sel_Addr_Data3;
	logic						Sel_Stride_Data1;
	logic						Sel_Stride_Data2;
	logic						Sel_Stride_Data3;
	logic						Sel_Length_Data1;
	logic						Sel_Length_Data2;
	logic						Sel_Length_Data3;

	logic						Sel_WB_Data11;
	logic						Sel_WB_Data12;
	logic						Sel_WB_Data13;
	logic						Sel_WB_Data21;
	logic						Sel_WB_Data22;
	logic						Sel_WB_Data23;
	logic						Sel_WB_Bypass11;
	logic						Sel_WB_Bypass12;
	logic						Sel_WB_Bypass21;
	logic						Sel_WB_Bypass22;
	logic						Sel_Path_Odd1;
	logic						Sel_Path_Odd2;
	logic						Sel_Path_Even1;
	logic						Sel_Path_Even2;


	assign O_Src_Data1			= ( Bypass_Data1 ) ? I_WB_Data1 : Src_Data1;
	assign O_Src_Data2			= ( Bypass_Data2 ) ? I_WB_Data2 : Src_Data2;
	assign O_Src_Data3			= ( Bypass_Data3 ) ? I_WB_Data1 : Src_Data3;


	// Source Operands
	assign Sel_Data1			= I_Config_Path[0];
	assign Sel_Data2			= I_Config_Path[1];
	assign Sel_Data3			= I_Config_Path[2];

	// Scalar Data
	assign Sel_Scalar1			= I_Config_Path[4:3] == 0;
	assign Sel_Scalar2			= I_Config_Path[4:3] == 1;
	assign Sel_Scalar3			= I_Config_Path[4:3] == 2;

	// Bypass
	assign Sel_Bypass11			= I_Bypass_Path == 4'h0;
	assign Sel_Bypass12			= I_Bypass_Path == 4'h1;
	assign Sel_Bypass13			= I_Bypass_Path == 4'h2;

	assign Sel_Bypass21			= I_Bypass_Path == 4'h4;
	assign Sel_Bypass22			= I_Bypass_Path == 4'h5;
	assign Sel_Bypass23			= I_Bypass_Path == 4'h6;

	// Write-Back
	assign Sel_WB_Scalar1		= I_Config_Path[6:5] == 3'h0;
	assign Sel_WB_Path1			= I_Config_Path[6:5] == 3'h1;
	assign Sel_WB_Bypass11		= I_Config_Path[6:5] == 3'h2;
	assign Sel_WB_Bypass12		= I_Config_Path[6:5] == 3'h3;

	assign Sel_WB_Scalar2		= I_Config_Path[8:7] == 3'h0;
	assign Sel_WB_Path2			= I_Config_Path[8:7] == 3'h1;
	assign Sel_WB_Bypass21		= I_Config_Path[8:7] == 3'h2;
	assign Sel_WB_Bypass22		= I_Config_Path[8:7] == 3'h3;

	// Source Operands
	assign Src_Data			= {
									I_Scalar_Data,
									I_Src_Data2,
									I_Src_Data3,
									I_WB_Data1,
									I_WB_Data2,
									I_Scalar_Data,
									I_Path_Data
								};


	always_comb: begin
		if ( Sel_Data1 )			assign Sel_Src_Data1= 0;
		else if ( Sel_Bypass13 )	assign Sel_Src_Data1= 3;
		else if ( Sel_Bypass23 )	assign Sel_Src_Data1= 4;
		else if ( Sel_Scalar1 )		assign Sel_Src_Data1= 5;
		else 						assign Sel_Src_Data1= 6;
	end

	always_comb: begin
		if ( Sel_Data2 )			assign Sel_Src_Data2= 1;
		else if ( Sel_Bypass12 )	assign Sel_Src_Data2= 3;
		else if ( Sel_Bypass22 )	assign Sel_Src_Data2= 4;
		else if ( Sel_Scalar2 )		assign Sel_Src_Data2= 5;
		else 						assign Sel_Src_Data2= 6;
	end

	always_comb: begin
		if ( Sel_Data3 )			assign Sel_Src_Data3= 2;
		else if ( Sel_Bypass13 )	assign Sel_Src_Data3= 3;
		else if ( Sel_Bypass23 )	assign Sel_Src_Data3= 4;
		else if ( Sel_Scalar3 )		assign Sel_Src_Data3= 5;
		else 						assign Sel_Src_Data3= 6;
	end

	// Write-Back
	assign WB_Data_Src			= {
									I_Scalar_Data,
									I_Path_Data,
									I_WB_Data1,
									I_WB_Data2
								};

	assign WB_Index_Src			= {
									I_Scalar_Index,
									I_Path_Index,
									I_WB_Index1,
									I_WB_Index2
								};

	always_comb: begin
		if ( Sel_WB_Scalar1 )		assign Sel_WB_Data1	= 0;
		else if ( Sel_WB_Path1 )	assign Sel_WB_Data1	= 1;
		else if ( Sel_WB_Bypass21 )	assign Sel_WB_Data1	= 2;
		else if ( Sel_WB_Bypass22 )	assign Sel_WB_Data1	= 3;
		else 						assign Sel_WB_Data1	= 0;
	end

	always_comb: begin
		if ( Sel_WB_Scalar2 )		assign Sel_WB_Data2	= 0;
		else if ( Sel_WB_Path2 )	assign Sel_WB_Data2	= 1;
		else if ( Sel_WB_Bypass21 )	assign Sel_WB_Data2	= 2;
		else if ( Sel_WB_Bypass22 )	assign Sel_WB_Data2	= 3;
		else 						assign Sel_WB_Data2	= 0;
	end

	// Load/Store Unit
	assign Data_Src_LdSt		= {
									I_Src_Data1,
									I_Src_Data2,
									I_Src_Data3
								};

	always_comb: begin
		case ( I_Bypass_Path )
		4'h8:	assign Sel_Addr_Data	= 0;
		4'h9:	assign Sel_Addr_Data	= 1;
		4'ha:	assign Sel_Addr_Data	= 2;
		4'hc:	assign Sel_Addr_Data	= 0;
		4'hd:	assign Sel_Addr_Data	= 1;
		4'he:	assign Sel_Addr_Data	= 2;
		default:assign Sel_Addr_Data	= 0;
		endcase
	end

	always_comb: begin
		case ( I_Bypass_Path )
		4'h8:	assign Sel_Stride_Data	= 1;
		4'h9:	assign Sel_Stride_Data	= 2;
		4'hb:	assign Sel_Stride_Data	= 0;
		4'hc:	assign Sel_Stride_Data	= 2;
		4'he:	assign Sel_Stride_Data	= 0;
		4'hf:	assign Sel_Stride_Data	= 1;
		default:assign Sel_Stride_Data	= 0;
		endcase
	end

	always_comb: begin
		case ( I_Bypass_Path )
		4'h8:	assign Sel_Length_Data	= 2;
		4'ha:	assign Sel_Length_Data	= 0;
		4'hb:	assign Sel_Length_Data	= 1;
		4'hd:	assign Sel_Length_Data	= 2;
		4'he:	assign Sel_Length_Data	= 1;
		4'hf:	assign Sel_Length_Data	= 0;
		default:assign Sel_Length_Data	= 0;
		endcase
	end


	path_sel #(
		.NUM_ENTRY(			NUM_ENTRY_ROUTE				),
		.WIDTH_NUM_SRC(		3							),
		.TYPE_DEF(			data_t						)
	) Path_Sel_Src_Data1
	(
		.clock(				clock						),
		.reset(				reset						),
		.I_En_WB(			1							),
		.I_Stall(			I_Stall						),
		.I_Store(			I_Req						),
		.I_Sel(				Sel_Src_Data1				),
		.I_Issue_No(		I_Issue_No					),
		.I_Issue_No_WB(		I_Issue_No_WB1				),
		.I_Data(			Src_Data					),
		.O_Data(			Src_Data1					),
		.O_Bypass(			Bypass_Data1				),
		.O_Re(				Re_Src_Data1				)
	);

	path_sel #(
		.NUM_ENTRY(			NUM_ENTRY_ROUTE				),
		.WIDTH_NUM_SRC(		3							),
		.TYPE_DEF(			data_t						)
	) Path_Sel_Src_Data2
	(
		.clock(				clock						),
		.reset(				reset						),
		.I_En_WB(			1							),
		.I_Stall(			I_Stall						),
		.I_Store(			I_Req						),
		.I_Sel(				Sel_Src_Data2				),
		.I_Issue_No(		I_Issue_No					),
		.I_Issue_No_WB(		I_Issue_No_WB2				),
		.I_Data(			Src_Data					),
		.O_Data(			Src_Data2					),
		.O_Bypass(			Bypass_Data2				),
		.O_Re(				Re_Src_Data2				)
	);

	path_sel #(
		.NUM_ENTRY(			NUM_ENTRY_ROUTE				),
		.WIDTH_NUM_SRC(		3							),
		.TYPE_DEF(			data_t						)
	) Path_Sel_Src_Data3
	(
		.clock(				clock						),
		.reset(				reset						),
		.I_En_WB(			1							),
		.I_Stall(			I_Stall						),
		.I_Store(			I_Req						),
		.I_Sel(				Sel_Src_Data3				),
		.I_Issue_No(		I_Issue_No					),
		.I_Issue_No_WB(		I_Issue_No_WB1				),
		.I_Data(			WB_Index_Src				),
		.O_Data(			Src_Data3					),
		.O_Bypass(			Bypass_Data3				),
		.O_Re(				Re_Src_Data3				)
	);

	path_sel #(
		.NUM_ENTRY(			NUM_ENTRY_ROUTE				),
		.WIDTH_NUM_SRC(		2							),
		.TYPE_DEF(			index_t						)
	) Path_Sel_WB_Index1
	(
		.clock(				clock						),
		.reset(				reset						),
		.I_En_WB(			0							),
		.I_Stall(			I_Stall						),
		.I_Store(			I_Req						),
		.I_Sel(				Sel_WB_Data1				),
		.I_Issue_No(		0							),
		.I_Issue_No_WB(		0							),
		.I_Data(			WB_Index_Src				),
		.O_Data(			O_WB_Index1					),
		.O_Bypass(										),
		.O_Re(											)
	);

	path_sel #(
		.NUM_ENTRY(			NUM_ENTRY_ROUTE				),
		.WIDTH_NUM_SRC(		2							),
		.TYPE_DEF(			index_t						)
	) Path_Sel_WB_Index2
	(
		.clock(				clock						),
		.reset(				reset						),
		.I_En_WB(			0							),
		.I_Stall(			I_Stall						),
		.I_Store(			I_Req						),
		.I_Sel(				Sel_WB_Data2				),
		.I_Issue_No(		0							),
		.I_Issue_No_WB(		0							),
		.I_Data(			WB_Data_Src					),
		.O_Data(			O_WB_Index2					),
		.O_Bypass(										),
		.O_Re(											)
	);

	path_sel #(
		.NUM_ENTRY(			NUM_ENTRY_ROUTE				),
		.WIDTH_NUM_SRC(		2							),
		.TYPE_DEF(			data_t						)
	) Path_Sel_WB_Data1
	(
		.clock(				clock						),
		.reset(				reset						),
		.I_En_WB(			0							),
		.I_Stall(			I_Stall						),
		.I_Store(			I_Req						),
		.I_Sel(				Sel_WB_Data1				),
		.I_Issue_No(		0							),
		.I_Issue_No_WB(		0							),
		.I_Data(			WB_Data_Src					),
		.O_Data(			O_WB_Data1					),
		.O_Bypass(										),
		.O_Re(											)
	);

	path_sel #(
		.NUM_ENTRY(			NUM_ENTRY_ROUTE				),
		.WIDTH_NUM_SRC(		2							),
		.TYPE_DEF(			data_t						)
	) Path_Sel_WB_Data2
	(
		.clock(				clock						),
		.reset(				reset						),
		.I_En_WB(			0							),
		.I_Stall(			I_Stall						),
		.I_Store(			I_Req						),
		.I_Sel(				Sel_WB_Data2				),
		.I_Issue_No(		0							),
		.I_Issue_No_WB(		0							),
		.I_Data(			WB_Data_Src					),
		.O_Data(			O_WB_Data2					),
		.O_Bypass(										),
		.O_Re(											)
	);

	path_sel #(
		.NUM_ENTRY(			NUM_ENTRY_ROUTE				),
		.WIDTH_NUM_SRC(		2							),
		.TYPE_DEF(			data_t						)
	) Path_Sel_Address
	(
		.clock(				clock						),
		.reset(				reset						),
		.I_En_WB(			0							),
		.I_Stall(			I_Stall						),
		.I_Store(			I_Req						),
		.I_Sel(				Sel_Addr_Data				),
		.I_Issue_No(		0							),
		.I_Issue_No_WB(		0							),
		.I_Data(			Data_Src_LdSt				),
		.O_Data(			O_Address					),
		.O_Bypass(										),
		.O_Re(											)
	);

	path_sel #(
		.NUM_ENTRY(			NUM_ENTRY_ROUTE				),
		.WIDTH_NUM_SRC(		2							),
		.TYPE_DEF(			data_t						)
	) Path_Sel_Stride
	(
		.clock(				clock						),
		.reset(				reset						),
		.I_En_WB(			0							),
		.I_Stall(			I_Stall						),
		.I_Store(			I_Req						),
		.I_Sel(				Sel_Stride_Data				),
		.I_Issue_No(		0							),
		.I_Issue_No_WB(		0							),
		.I_Data(			Data_Src_LdSt				),
		.O_Data(			O_Stride					),
		.O_Bypass(										),
		.O_Re(											)
	);

	path_sel #(
		.NUM_ENTRY(			NUM_ENTRY_ROUTE				),
		.WIDTH_NUM_SRC(		2							),
		.TYPE_DEF(			data_t						)
	) Path_Sel_Length
	(
		.clock(				clock						),
		.reset(				reset						),
		.I_WNo(				WNo							),
		.I_RNo(				RNo							),
		.I_En_WB(			0							),
		.I_Stall(			I_Stall						),
		.I_Store(			I_Req						),
		.I_Sel(				Sel_Length_Data				),
		.I_Issue_No(		0							),
		.I_Issue_No_WB(		0							),
		.I_Data(			Data_Src_LdSt				),
		.O_Data(			O_Length					),
		.O_Bypass(										),
		.O_Re(											)
		);


		//// Module: Ring-Buffer Controller
		assign We					= I_Store & ~Full;
		assign Re					= ;//ToDo
		RingBuffCTRL #(
		.NUM_ENTRY(			NUM_ENTRY					)
	) RingBuffCTRL
	(
		.clock(				clock						),
		.reset(				reset						),
		.I_We(				We							),
		.I_Re(				Re							),
		.O_WAddr(			WNo							),
		.O_RAddr(			RNo							),
		.O_Full(			Full						),
		.O_Empty(			Empty						),
		.O_Num(											)
	);

endmodule