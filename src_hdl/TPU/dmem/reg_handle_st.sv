///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	ReqHandle_St
///////////////////////////////////////////////////////////////////////////////////////////////////

module ReqHandle_St
import pkg_tpu::*;
(
input						clock,
input						reset,
input						I_St_Req1,						//Request Access
input						I_St_Req2,						//Request Access
input	address_t			I_Length1,						//Access Length
input	address_t			I_Stride1,						//Stride Factor
input	address_t			I_Base_Addr1,					//Base Address
input	address_t			I_Length2,						//Access Length
input	address_t			I_Stride2,						//Stride Factor
input	address_t			I_Base_Addr2,					//Base Address
output	address_t			O_Length,						//Access Length
output	address_t			O_Stride,						//Stride Factor
output	address_t			O_Base_Addr,					//Base Address
output  logic               O_Grant1,                       //Grant (to Lane)
output  logic               O_Grant2,                       //Grant (to Lane)
output  logic               O_St_Req,                       //Store Request to Man
output  logic               O_GranndVld                     //Grant Validation
output  logic               O_GrantNo                       //Grant No
);


logic						R_Grant1;
logic						R_Grant2;

assign O_GrantVld 		=  R_Grant1 | R_Grant2;
assign O_GrantNo 		= ~R_Grant1 & R_Grant2;

assign O_Grant1			= R_Grant1;
assign O_Grant2			= R_Grant2;

assign O_St_Req			= ( I_St_Req1 | I_St_Req2 ) ^ ( R_Grant1 | R_Grant2  );

assign O_Length			= ( I_St_Req1 ) ? I_Length1 :   I_Length2;
assign O_Stride			= ( I_St_Req1 ) ? I_Stride1 :   I_Stride2;
assign O_Base_Addr		= ( I_St_Req1 ) ? I_Base_Addr1 :I_Base_Addr2;


always_ff @( posedge clock ) begin
	if ( reset ) begin
		R_Grant1		<= 1'b0;
	end
	else if (  ) begin
		R_Grant1		<= 1'b0;
	end
	else if (  ) begin
		R_Grant1		<= 1'b1;
	end
end


always_ff @( posedge clock ) begin
	if ( reset ) begin
		R_Grant2		<= 1'b0;
	end
	else if (  ) begin
		R_Grant2		<= 1'b0;
	end
	else if (  ) begin
		R_Grant2		<= 1'b1;
	end
end

endmodule