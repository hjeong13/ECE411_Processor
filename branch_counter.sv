module branch_counter
(
	input result,
	input [1:0] state,

	output logic [1:0] counter
);

always_comb 
begin
	case(state)
		2'b00: begin
			if (result)
				counter = 2'b01;
			else
				counter = 2'b00;
		end

		2'b01: begin
			if (result)
				counter = 2'b10;
			else
				counter = 2'b00;
		end

		2'b10: begin
			if (result)
				counter = 2'b11;
			else
				counter = 2'b01;
		end

		2'b11: begin
			if (result)
				counter = 2'b11;
			else
				counter = 2'b10;
		end

		default : ;
	endcase
end

endmodule : branch_counter
