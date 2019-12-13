module selector
(
	input clk,
	input stall,
	input [1:0] local_state,
	input [1:0] global_state,
	input [6:0] opcode,

	output logic [1:0] counter
);

logic [1:0] next_counter;

initial
begin
	next_counter = 2'b0;
end

always_ff @(posedge clk)
begin
	if (opcode == 7'b1100011 && ~stall)
	begin
		case(next_counter)
			2'b00: begin
				if (local_state < 2 && global_state > 1)
					next_counter <= 2'b01;
				else
					next_counter <= 2'b00;
			end

			2'b01: begin
				if (local_state < 2 && global_state > 1)
					next_counter <= 2'b10;
				else if (local_state > 1 && global_state < 2)
					next_counter <= 2'b01;
				else
					next_counter <= 2'b00;
			end

			2'b10: begin
				if (local_state < 2 && global_state > 1)
					next_counter <= 2'b11;
				else if (local_state > 1 && global_state < 2)
					next_counter <= 2'b01;
				else
					next_counter <= 2'b10;
			end

			2'b11: begin
				if (local_state > 1 && global_state < 2)
					next_counter <= 2'b10;
				else
					next_counter <= 2'b11;
			end

			default: ;
		endcase
	end
end

always_comb
begin
	counter = next_counter;
end

endmodule : selector

