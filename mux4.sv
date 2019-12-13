module mux4 #(parameter width = 32)
(
	input logic [1:0] sel,
	input [width-1:0] in0, in1, in2 ,in3,
	output logic [width-1:0] out
);

always_comb
begin
	if (sel == 2'b00)
		out = in0;
	else if (sel == 2'b01)
		out = in1;
	else if (sel == 2'b10)
		out = in2;
	else
		out = in3;
end

endmodule : mux4

