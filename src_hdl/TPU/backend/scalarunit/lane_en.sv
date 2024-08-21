///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	Lane_En
///////////////////////////////////////////////////////////////////////////////////////////////////

module Lane_En
import pkg_tpu::*;
(
input						clock,
input						reset,
input						I_We,
input	data_t				I_Data,
input						I_Re,
input						I_We_V_State,
input	lane_t				I_V_State,
output	data_t				O_Data
);


data_t						Lane_En;


assign O_Data				= ( I_Re ) ? Lane_En : 0;


always_ff @( posedge clock ) begin
	if ( reset ) begin
		Lane_En				<= 0;
	end
	else if ( I_We | I_We_V_State ) begin
		if ( I_We ) begin
			Lane_En[NUM_LANE-1:0]	<= I_Data[NUM_LANE-1:0];
		end

		if ( I_We_V_State ) begin
			Lane_En[NUM_LANE-1:0]	<= I_V_State;
		end
	end
end

endmodule