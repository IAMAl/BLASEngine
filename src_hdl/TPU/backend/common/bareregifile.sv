///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	BareRegFile
///////////////////////////////////////////////////////////////////////////////////////////////////

module BareRegFile
import pkg_tpu::*;
(
input						clock,
input						reset,
input						I_We,							//Flag: Write-Enable
input						I_Re1,							//Flag: Read-Enable for Source-1
input						I_Re2,							//Flag: Read-Enable for Source-2
input	index_t				I_Index_Dst,					//Write Index for Destination
input	data_t				I_Data,							//Write-Back Data
input	index_t				I_Index_Src1,					//Read Index for Source-1
input	index_t				I_Index_Src2,					//Read Index for Source-2
output	data_t				O_Data_Src1,					//Data of Source-1
output	data_t				O_Data_Src2						//Data of Source-2
);


index_t						Index_Src1;
index_t						Index_Src2;

data_t						src_data1;
data_t						src_data2;

data_t						RegFile	[NUM_ENTRY_REGFILE-1:0];


assign Index_Src1			= ( I_Re1 ) ? I_Index_Src1 : 0;
assign Index_Src2			= ( I_Re2 ) ? I_Index_Src2 : 0;

assign O_Data_Src1			= src_data1;
assign O_Data_Src2			= src_data2;


always_ff @( posedge clock ) begin
	if ( reset ) begin
		src_data1			<= 0;
	end
	else if ( I_Re1	) begin
		src_data1			<= RegFile[ Index_Src1 ];
	end
end

always_ff @( posedge clock ) begin
	if ( reset ) begin
		src_data2			<= 0;
	end
	else if ( I_Re2	) begin
		src_data2			<= RegFile[ Index_Src2 ];
	end
end

always_ff @( posedge clock ) begin
	if ( reset) begin
		for ( int i=0; i<NUM_RF_ENTRY; ++i ) begin
			RegFile			<= 0;
		end
	end
	else if ( I_We ) begin
		RegFile[ I_Index_Dst ]	<= I_Data;
	end
end

endmodule