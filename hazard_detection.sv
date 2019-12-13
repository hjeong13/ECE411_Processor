module hazard_detection
(
	input clk,
	input br_en,
	input tag_comp,
	input prediction,
	input icache_stall,
	input dcache_stall,
	input ID_EX_invalidate_prev_out,
	input ID_EX_invalidate_curr_out,
	input [6:0] opcode,
	input [6:0] ID_EX_opcode_out,
	input [6:0] EX_MEM_opcode_out,
	input [4:0] rs1,
	input [4:0] rs2,
	input [4:0] ID_EX_rd_out,
	input [4:0] ID_EX_rs1_out,
	input [4:0] ID_EX_rs2_out,
	input [4:0] EX_MEM_rd_out,
	input [31:0] ID_EX_pc_out,
	input [31:0] ID_EX_BTB_out,
	input [31:0] predicted_pc_out,
	output logic IF_ID_invalidate,
	output logic ID_EX_invalidate,
	output logic load_forwarding_stall,
	output logic temp
	//output logic temp1
);

logic load_forwarding_stall_next;
//logic temp2;

initial
begin
	load_forwarding_stall_next = 1'b0;
end

always_comb
begin
	temp = load_forwarding_stall_next;
	//temp1 = temp2;
	if (((br_en != prediction) && (ID_EX_invalidate_prev_out == 1'b0) && (ID_EX_invalidate_curr_out == 1'b0) && (ID_EX_opcode_out == 7'b1100011)) ||
		 (ID_EX_opcode_out == 7'b1101111 || ID_EX_opcode_out == 7'b1100111)) begin
		IF_ID_invalidate = 1'b1;
		if (br_en == 1'b1 && tag_comp == 1'b1 && ID_EX_pc_out == ID_EX_BTB_out)
			IF_ID_invalidate = 1'b0;
		end
	else
		IF_ID_invalidate = 1'b0;
	if ((((br_en != prediction) || ((br_en == prediction) && (prediction != tag_comp))) && (ID_EX_invalidate_prev_out == 1'b0) && (ID_EX_invalidate_curr_out == 1'b0) && (ID_EX_opcode_out == 7'b1100011)) ||
		 (ID_EX_opcode_out == 7'b1101111 || ID_EX_opcode_out == 7'b1100111)) 
		ID_EX_invalidate = 1'b1;
	else
		ID_EX_invalidate = 1'b0;
	
	if ((EX_MEM_opcode_out == 7'b0000011) && (EX_MEM_rd_out != 5'b0) && (EX_MEM_rd_out == ID_EX_rs1_out || EX_MEM_rd_out == ID_EX_rs2_out) && icache_stall == 1'b0)
		load_forwarding_stall = 1'b1;
	else
		load_forwarding_stall = 1'b0;
end

always_ff @(posedge clk)
begin
	//temp2 <= load_forwarding_stall_next;
	if (load_forwarding_stall_next == 1'b1 && icache_stall == 1'b0 && dcache_stall == 1'b0)
		load_forwarding_stall_next <= 1'b0;
	if ((EX_MEM_opcode_out == 7'b0000011) && (EX_MEM_rd_out != 5'b0) && (EX_MEM_rd_out == ID_EX_rs1_out || EX_MEM_rd_out == ID_EX_rs2_out) && icache_stall == 1'b0)
		load_forwarding_stall_next <= 1'b1;
end

endmodule : hazard_detection
