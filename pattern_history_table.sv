module pattern_history_table
(
	input clk,
	input load,
	input stall,
	input [6:0] opcode,
	input [3:0] index,
	input [3:0] prev_index,
	input [1:0] in,

	output logic [1:0] out
);

logic [1:0] data [16];

initial
begin
	for (int i = 0; i < $size(data); i++)
	begin
		data[i] = 2'b11;
	end
end

always_ff @(posedge clk)
begin
	if (load && opcode == 7'b1100011 && ~stall)
	begin
		data[prev_index] <= in;
	end
end

always_comb
begin
	out = data[index];
end

endmodule : pattern_history_table

