module decoder
(
	input sel,
	input in,
	output logic out0,
	output logic out1
);

always_comb
begin
	if (sel == 0) begin
		out0 = in;
		out1 = 0;
	end
	else begin
		out0 = 0;
		out1 = in;
	end
end

endmodule : decoder