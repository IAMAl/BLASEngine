module St_InstrWindow 
	import pkg_pcu::*;
	import pkg_tpu::*;
(
	input						clock,
	input						reset,
	input						I_Req,							//Request to Work
	input						I_Valid_Dst,					//Flag: Valid for Destination
	input						I_Valid_Src1,					//Flag: Valid for Source-1
	input						I_Valid_Src2,					//Flag: Valid for Source-2
	input						I_Valid_Src3,					//Flag: Valid for Source-3
	input	index_t				I_Index_Dst,					//Index for Destination
	input	index_t				I_Index_Src1,					//Index for Source-1
	input	index_t				I_Index_Src2,					//Index for Source-2
	input	index_t				I_Index_Src3,					//Index fpr Source-3
	output	iw_t				O_Index_Entry					//Entry for Instruction Window
);

	localparam WIDTH_ENTRY		= $clog2(NUM_IW_ENTRY);

	logic						Set_Index;

	logic						R_Valid_Dst;
	logic						R_Valid_Src1;
	logic						R_Valid_Src2;
	logic						R_Valid_Src3;

	index_t						R_Index_Dst;
	index_t						R_Index_Src1;
	index_t						R_Index_Src2;
	index_t						R_Index_Src3;

	iw_t						R_Indeces;

	assign Set_Index			= We_Valid_Dst | We_Valid_Src1 | We_Valid_Src1 | We_Valid_Src2 | We_Valid_Src3;

	assign O_Index_Entry		= R_Indeces;

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			We_Valid_Dst	<= 1'b0;
		end
		else begin
			We_Valid_Dst	<= I_Valid_Dst;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			We_Valid_Src1	<= 1'b0;
		end
		else begin
			We_Valid_Src1	<= I_Valid_Src1;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			We_Valid_Src2	<= 1'b0;
		end
		else begin
			We_Valid_Src2	<= I_Valid_Src2;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			We_Valid_Src3	<= 1'b0;
		end
		else begin
			We_Valid_Src3	<= I_Valid_Src3;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reest ) begin
			R_Index_Dst		<= '0;
		end
		else begin
			R_Index_Dst		<= I_Index_Dst;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reest ) begin
			R_Index_Src1	<= '0;
		end
		else begin
			R_Index_Src1	<= I_Index_Src1;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reest ) begin
			R_Index_Src2	<= '0;
		end
		else begin
			R_Index_Src2	<= I_Index_Src2;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reest ) begin
			R_Index_Src3	<= '0;
		end
		else begin
			R_Index_Src3	<= I_Index_Src3;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Indeces		<= '0;
		end
		else if ( Set_Index ) begin
			if ( R_Valid_Dst ) begin
				R_Indeces.v_dst		<= 1'b1;
				R_Indeces.i_dst		<= R_Index_Dst;
			end
			else begin
				R_Indeces.v_dst		<= 1'b0;
			end

			if ( R_Valid_Src1 ) begin
				R_Indeces.v_src1	<= 1'b1;
				R_Indeces.i_src1	<= R_Index_Src1;
			end
			else begin
				R_Indeces.v_src1	<= 1'b0;
			end

			if ( R_Valid_Src2 ) begin
				R_Indeces.v_src2	<= 1'b1;
				R_Indeces.i_src2	<= R_Index_Src2;
			end
			else begin
				R_Indeces.v_src2	<= 1'b0;
			end

			if ( R_Valid_Src3 ) begin
				R_Indeces.v_src3	<= 1'b1;
				R_Indeces.i_src3	<= R_Index_Src3;
			end
			else begin
				R_Indeces.v_src3	<= 1'b0;
			end
		end
	end

endmodule