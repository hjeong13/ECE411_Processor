import rv32i_types::*; /* Import types defined in rv32i_types.sv */

module regwrite_detection
(
	input logic [6:0] EX_MEM_opcode_out,
	input logic [6:0] MEM_WB_opcode_out,
	
	output logic EX_MEM_rdwrite,
	output logic MEM_WB_rdwrite,
	output logic Load_Store_rdwrite,
	output logic MEM_WB_forward_mux_sel
	
);

rv32i_opcode EX_MEM_opcode;
rv32i_opcode MEM_WB_opcode;

always_comb 
begin
	EX_MEM_opcode = rv32i_opcode'(EX_MEM_opcode_out);
	MEM_WB_opcode = rv32i_opcode'(MEM_WB_opcode_out);
end
	
always_comb
begin
	//EX_MEM_rdwrite = 1'b1;
	//MEM_WB_rdwrite = 1'b1;
	Load_Store_rdwrite = 1'b0;
	MEM_WB_forward_mux_sel = 1'b0;
	
	EX_MEM_rdwrite = (EX_MEM_opcode == 0) ? 1'b0 : 1'b1;
	MEM_WB_rdwrite = (MEM_WB_opcode == 0) ? 1'b0 : 1'b1;

	case(EX_MEM_opcode)
		op_br : EX_MEM_rdwrite = 1'b0;
		op_load : EX_MEM_rdwrite = 1'b0;
		op_store : EX_MEM_rdwrite = 1'b0;
		op_csr : EX_MEM_rdwrite = 1'b0;
		
		default : ;
	endcase
	
	case(MEM_WB_opcode)
		op_br : MEM_WB_rdwrite = 1'b0;
		op_csr : MEM_WB_rdwrite = 1'b0;
		
		default : ;
	endcase
	
	if(rv32i_opcode'(MEM_WB_opcode_out) == op_load && rv32i_opcode'(EX_MEM_opcode_out) == op_store)
		Load_Store_rdwrite = 1'b1;
	
	if(rv32i_opcode'(MEM_WB_opcode_out) == op_load)
		MEM_WB_forward_mux_sel = 1'b1;
end

endmodule : regwrite_detection

