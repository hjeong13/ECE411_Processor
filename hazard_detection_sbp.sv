module hazard_detection_sbp
(
	input clk,
	input logic [6:0] ID_EX_opcode_out,
	input logic ID_EX_invalidate_prev_out,
	input logic ID_EX_invalidate_curr_out,
	input logic br_en,
	
	output logic IF_ID_invalidate,
	output logic ID_EX_invalidate,
	
	input logic [6:0] opcode,
	input logic [4:0] rs1,
	input logic [4:0] rs2,
	input logic [4:0] ID_EX_rd_out,
	input logic [4:0] ID_EX_rs1_out,
	input logic [4:0] ID_EX_rs2_out,
	input logic [4:0] EX_MEM_rd_out,	
	input logic icache_stall,
	input logic dcache_stall,
	input logic [6:0] EX_MEM_opcode_out,
	input logic ID_EX_load_forwarding_stall_out,
	
	output logic load_forwarding_stall
);

logic IF_ID_invalidate_next;
logic ID_EX_invalidate_next;

always_comb
begin
	//IF_ID_invalidate = IF_ID_invalidate_next;
	//ID_EX_invalidate = ID_EX_invalidate_next;
	
	if ((br_en == 1'b1 && ID_EX_opcode_out == 7'b1100011) && (ID_EX_invalidate_prev_out == 1'b0) && (ID_EX_invalidate_curr_out == 1'b0) && (opcode == 7'b1101111 || opcode == 7'b1100111)) begin
		IF_ID_invalidate = 1'b1;
		ID_EX_invalidate = 1'b1;
	end
	else begin
		IF_ID_invalidate = 1'b0;
		ID_EX_invalidate = 1'b0;
	end

	
	/*
	if ((opcode != 7'b0010111) && ID_EX_opcode_out == 7'b0000011 && (ID_EX_rd_out != 5'b0) && (ID_EX_rd_out == rs1 || ID_EX_rd_out == rs2))
		load_forwarding_stall = 1'b1;
	else
		load_forwarding_stall = 1'b0;
	*/	
	if ((EX_MEM_opcode_out == 7'b0000011) && (EX_MEM_rd_out != 5'b0) && (EX_MEM_rd_out == ID_EX_rs1_out || EX_MEM_rd_out == ID_EX_rs2_out) && icache_stall == 1'b0)
		load_forwarding_stall = 1'b1;
	else
		load_forwarding_stall = 1'b0;
	
end

always_ff @(posedge clk)
begin
	if ((br_en == 1'b1) && (ID_EX_opcode_out == 7'b1100011)) begin
		IF_ID_invalidate_next <= 1'b1;
		ID_EX_invalidate_next <= 1'b1;
	end
	else begin
		IF_ID_invalidate_next <= 1'b0;
		ID_EX_invalidate_next <= 1'b0;
	end
end

endmodule

