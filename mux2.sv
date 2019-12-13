module mux2 #(parameter width = 32)
(
	input sel,
	input [width-1:0] in0, in1,
	output logic [width-1:0] out
);

always_comb
begin
	if (sel == 0)
		out = in0;
	else
		out = in1;
end

endmodule : mux2

