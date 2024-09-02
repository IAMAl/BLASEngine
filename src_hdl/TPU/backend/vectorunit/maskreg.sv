///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	MaskReg
///////////////////////////////////////////////////////////////////////////////////////////////////

module MaskReg
	import pkg_tpu::*;
(
	input						clock,
	input						reset,
	input						I_We,					//Write-Enable the Mask Register
	input	index_t				I_Index,				//Mask-Bit Address (Index)
	input	cond_t				I_Cond,					//Condition to Gnerate Flag
	input	stat_v_t			I_Status,				//Status of Comparing
	input						I_Re,					//Read-Enable
	output	mask_t				O_Mask_Data				//Mask Data
);


	mask_t						Mask;


	assign O_Mask_Data			= ( I_Re ) ? Mask : '0;


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Mask			<= '0;
		end
		else if ( I_We ) begin
			Mask[ I_Index ]	<= I_Status[ I_Cond ];
		end
	end

endmodule