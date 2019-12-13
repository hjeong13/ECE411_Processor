//import rv32i_types::*; /* Import types defined in rv32i_types.sv */

module sext
(
	input logic [31:0] data,
	output logic [159:0] imm
);

logic [31:0] i_imm;
logic [31:0] s_imm;
logic [31:0] b_imm;
logic [31:0] u_imm;
logic [31:0] j_imm;

always_comb 
begin
	i_imm = {{21{data[31]}}, data[30:20]};
	s_imm = {{21{data[31]}}, data[30:25], data[11:7]};
	b_imm = {{20{data[31]}}, data[7], data[30:25], data[11:8], 1'b0};
	u_imm = {data[31:12], 12'h000};
	j_imm = {{12{data[31]}}, data[19:12], data[20], data[30:21], 1'b0};
	
	imm = {i_imm, u_imm, b_imm, s_imm, j_imm}; // Concatenation - 160bit
end
	
endmodule : sext

