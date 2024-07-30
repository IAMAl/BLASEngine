module pipereg_be
	import pkg_tpu::*;
(
	input						clock,
	input						reset,
	input						I_Stall,
	input	op_t				I_Op,
	output	op_t				O_Op,
	input   index_t             I_Slice_Idx,
	input   index_t             O_Slice_Idx
);


	op_t						R_Op;
	index_t						R_Idx;


	assign O_Op				= R_Op;
	assign O_Slixe_Idx		= R_Idx;


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Op			<= '0;
			R_Idx			<= '0;
		end
		else if ( ~I_Stall ) begin
			R_Op			<= I_Op;
			R_Idx			<= I_Slize_Idx;
		end
	end

endmodule