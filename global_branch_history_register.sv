module global_branch_history_register
(
	input clk,
	input load,
	input stall,
	input in,
	input [6:0] opcode,

	output logic [3:0] out
);

logic [3:0] data;

initial
begin
	data = 1'b0;
end

always_ff @(posedge clk)
begin
	if (load && opcode == 7'b1100011 && ~stall)
	begin
		data <= {data[2:0], in};
	end
end

always_comb
begin
	out = data;
end

endmodule : global_branch_history_register




