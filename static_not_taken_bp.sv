module static_not_taken_bp
(
	input clk,
	input logic br_en,
	input logic [6:0] opcode,
	input logic [6:0] ID_EX_opcode_out,
	input logic IF_ID_invalidate_out,
	input logic [31:0] IF_ID_pc_out,
	
	output logic sbp_mux_sel,
	output logic sbp_prediction,
	output logic [31:0] sbp_target
);
always_comb begin
	sbp_mux_sel = 1'b0;
	sbp_prediction = 1'b0;	
	sbp_target = 32'b0;
	
	if((IF_ID_invalidate_out == 1'b0) && (ID_EX_opcode_out != 7'b1100011 || (ID_EX_opcode_out == 7'b1100011 && br_en == 1'b0)) && (opcode == 7'b1100011 || opcode == 7'b1101111 || opcode == 7'b1100111)) begin
		sbp_mux_sel = 1'b1;
		sbp_prediction = 1'b1;
		sbp_target = IF_ID_pc_out + 8;
	end
end

endmodule

