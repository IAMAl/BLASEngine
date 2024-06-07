
module Pipe_RegFile (
	input						clock,
	input						reset,
);

	RegFile RegFile (
		.clock(					clock				),
		.reset(					reset				),
		.I_We(					),
		.I_Re1(					),
		.I_Re2(					),
		.I_Index_Dst(			),
		.I_Data(				),
		.I_Index_Src1(			),
		.I_Index_Src2(			),
		.O_Data_Src1(			),
		.O_Data_Src2(			)
	);

endmodule