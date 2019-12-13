import rv32i_types::*; /* Import types defined in rv32i_types.sv */

module forwarding_unit
(
	input logic [4:0] ID_EX_rs1_out,
	input logic [4:0] ID_EX_rs2_out,
	input logic [6:0] ID_EX_opcode_out,

	input logic EX_MEM_rdwrite,
	input logic [4:0] EX_MEM_rd_out,
	input logic [4:0] EX_MEM_rs2_out,
	
	input logic MEM_WB_rdwrite,
	input logic [4:0] MEM_WB_rd_out,

	input logic Load_Store_rdwrite,
	input logic [22:0] EX_MEM_ctrl_out,
	input logic [22:0] MEM_WB_ctrl_out,
	
	output logic [1:0] forwardAmux_sel,
	output logic [1:0] forwardBmux_sel,
	output logic store_forward_mux_sel,
	output logic [1:0] cmpforwardAmux_sel,
	output logic [1:0] cmpforwardBmux_sel
);

rv32i_opcode opcode;

assign opcode = rv32i_opcode'(ID_EX_opcode_out);

always_comb 
begin	
	forwardAmux_sel = 2'b0;
	forwardBmux_sel = 2'b0;
	store_forward_mux_sel = 1'b0;
	cmpforwardAmux_sel = 2'b0;
	cmpforwardBmux_sel = 2'b0;
	
	// Detecting EX/MEM Data Hazard 
	// 1) Previous Inst modify destination register
	// 2) Current Inst have previous inst's dest as one of source 	
	
	// EX_MEM_Data_Hazard
	// Previous MEM to current EX
	/*
	if ((EX_MEM_rdwrite == 1'b1) && (EX_MEM_rd_out != 5'b0) && (EX_MEM_rd_out == ID_EX_rs1_out) && (opcode != op_auipc))
		forwardAmux_sel = 2'b01;
	else if ((EX_MEM_rdwrite == 1'b1) && (EX_MEM_rd_out != 5'b0) && (EX_MEM_rd_out == ID_EX_rs2_out) && ((opcode == op_reg) || (opcode == op_store) || (opcode == op_br)))
		forwardBmux_sel = 2'b01;
	*/
	if ((EX_MEM_rdwrite == 1'b1) && (EX_MEM_ctrl_out != 23'b0) && (EX_MEM_rd_out != 5'b0) && (EX_MEM_rd_out == ID_EX_rs1_out))
		forwardAmux_sel = 2'b01;
	else if ((EX_MEM_rdwrite == 1'b1) && (EX_MEM_ctrl_out != 23'b0) && (EX_MEM_rd_out != 5'b0) && (EX_MEM_rd_out == ID_EX_rs2_out))
		forwardBmux_sel = 2'b01;		

	
	// MEM_WB_Data_Hazard
	// Previous WB to current EX
	/*
	if ((MEM_WB_rdwrite == 1'b1) && (MEM_WB_rd_out != 5'b0) && (MEM_WB_rd_out == ID_EX_rs1_out) && ((EX_MEM_rd_out != ID_EX_rs1_out) || (EX_MEM_rdwrite == 1'b0)))
			forwardAmux_sel = 2'b10;
	else if ((MEM_WB_rdwrite == 1'b1) && (MEM_WB_rd_out != 5'b0) && (MEM_WB_rd_out == ID_EX_rs2_out) && ((EX_MEM_rd_out != ID_EX_rs2_out) || (EX_MEM_rdwrite == 1'b0))) begin
		if (((opcode == op_reg) || (opcode == op_store || (opcode == op_br))))
			forwardBmux_sel = 2'b10;
	end
	*/
	if ((MEM_WB_rdwrite == 1'b1) && (MEM_WB_ctrl_out != 5'b0) && (MEM_WB_rd_out != 5'b0) && (MEM_WB_rd_out == ID_EX_rs1_out) && ((EX_MEM_rd_out != ID_EX_rs1_out) || (EX_MEM_rdwrite == 1'b0)))
			forwardAmux_sel = 2'b10;
	else if ((MEM_WB_rdwrite == 1'b1) && (MEM_WB_ctrl_out != 5'b0) && (MEM_WB_rd_out != 5'b0) && (MEM_WB_rd_out == ID_EX_rs2_out) && ((EX_MEM_rd_out != ID_EX_rs2_out) || (EX_MEM_rdwrite == 1'b0)))
			forwardBmux_sel = 2'b10;
	
	// Load_Store_Data_Hazard
	// Previous WB to current MEM
	
	if ((Load_Store_rdwrite == 1'b1) && (MEM_WB_rd_out == EX_MEM_rs2_out))
		store_forward_mux_sel = 1'b1;
		
		
	/*
	if(opcode == op_br) begin
		if ((EX_MEM_rdwrite == 1'b1) && (EX_MEM_rd_out == ID_EX_rs1_out))
			cmpforwardAmux_sel = 2'b01;
		else if ((EX_MEM_rdwrite == 1'b1) && (EX_MEM_rd_out == ID_EX_rs2_out))
			cmpforwardBmux_sel = 2'b01;
		
		if ((MEM_WB_rdwrite == 1'b1) && (MEM_WB_rd_out != 5'b0) && (MEM_WB_rd_out == ID_EX_rs1_out) && ((EX_MEM_rd_out != ID_EX_rs1_out) || (EX_MEM_rdwrite == 1'b0)))
			cmpforwardAmux_sel = 2'b10;
		else if ((MEM_WB_rdwrite == 1'b1) && (MEM_WB_rd_out != 5'b0) && (MEM_WB_rd_out == ID_EX_rs2_out) && ((EX_MEM_rd_out != ID_EX_rs2_out) || (EX_MEM_rdwrite == 1'b0)))
			cmpforwardBmux_sel = 2'b10;
	end
	*/	
end

endmodule: forwarding_unit

