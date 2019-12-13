module branch_target_buffer
(
	input clk,
	input load,
	input prev_hit,
	input br_en,
	input [6:0] opcode,
	input [31:0] pc,
	input [31:0] prev_pc,
	input [31:0] target_in,

	output logic hit,
	output logic [31:0] out
);

logic [31:0] pc_data [256];
logic [31:0] target [256];

initial
begin
    for (int i = 0; i < $size(pc_data); i++)
    begin
		pc_data[i] = 32'b0;
		target[i] = 32'b0;
    end
end

always_ff @(posedge clk)
begin
    if (load)
    begin
		if (prev_hit == 1 && br_en == 0 && opcode == 7'b1100011) 
			pc_data[prev_pc[9:2]] <= 32'b0;
		else if (prev_hit == 0 && br_en == 1 && opcode == 7'b1100011) begin
			pc_data[prev_pc[9:2]] <= prev_pc;
			target[prev_pc[9:2]] <= target_in;
		end
    end
end

always_comb
begin
	if (pc_data[pc[9:2]] == pc)
		hit = 1'b1;
	else
		hit = 0;
	out = target[pc[9:2]];
end

endmodule : branch_target_buffer
