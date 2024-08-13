///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	StatusCtrl
///////////////////////////////////////////////////////////////////////////////////////////////////

module StatusCtrl (
		input					clock,
		input					reset,
		input					I_Req,					//Request to Update
		input	data_t			I_Diff_Data,			//Diff Value from Adder
		output	stat_v_t		O_Status				//Status Values
);


	logic						Eq;
	logic						Ne;
	logic						Gt;
	logic						Eq;

	stat_v_t					Set_Val;
	stat_v_t					Status;


	// Float Format
	//	Equal
	assign Eq					=  I_Diff_Data[WIDTH_DATA-2:0] == 0;

	//	Not-Equal
	assign Ne					=  I_Diff_Data[WIDTH_DATA-2:0] != 0;

	//	Greater than
	assign Gt					=  I_Diff_Data[WIDTH_DATA-1] & Ne;

	//	Less than or Equal
	assign Le					= ~I_Diff_Data[WIDTH_DATA-1];

	//	Pack Status
	assign Set_Val				= { Eq, Ne, Gt, Le };

	//	Output
	assign O_Status				= Status


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Status			<= '0;
		end
		else if ( I_Req ) begin
			Status			<= Set_Val;
		end
	end

endmodule