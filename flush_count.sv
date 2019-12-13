module flush_count
(
	input clk,
	input IF_ID_invalidate,
	input ID_EX_invalidate,
	
	output logic [31:0] flush_total
);

logic [31:0] flush_total_next;

initial
begin
	flush_total_next = 32'b0;
end

always_comb
begin
	flush_total = flush_total_next;
end


always_ff @(posedge clk)
begin
	if (IF_ID_invalidate && ID_EX_invalidate)
		flush_total_next <= flush_total_next + 2;
	else if((IF_ID_invalidate & ~ID_EX_invalidate) || (~IF_ID_invalidate & ID_EX_invalidate))
		flush_total_next <= flush_total_next + 1;
	else
		flush_total_next <= flush_total_next;
end

endmodule : flush_count