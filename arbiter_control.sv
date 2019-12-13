module arbiter_control
(
	input clk,
	input Icache_arbiter_read,
	input Dcache_arbiter_read,
	input Dcache_arbiter_write,
	input l2cache_arbiter_resp,
	
	input Icache_arbiter_resp,
	input Dcache_arbiter_resp,
	
	output logic arbiter_l2cache_read,
	output logic arbiter_l2cache_write,
	output logic arbiter_addr_mux_sel,
	output logic decoder_sel
);

enum int unsigned {
	idle,
	Icache_read,
	Dcache_read,
	Dcache_write
} state, next_state;


always_comb
begin
	arbiter_addr_mux_sel = 0;
	arbiter_l2cache_read = 0;
	arbiter_l2cache_write = 0;
	decoder_sel = 0;
	
	case(state)
		idle: ;
		Icache_read: begin
			arbiter_addr_mux_sel = 0;
			arbiter_l2cache_read = 1;
			decoder_sel = 0;
		end
		Dcache_read: begin
			arbiter_addr_mux_sel = 1;
			arbiter_l2cache_read = 1;
			decoder_sel = 1;
		end
		Dcache_write: begin
			arbiter_addr_mux_sel = 1;
			arbiter_l2cache_write = 1;
			decoder_sel = 1;
		end
	endcase
end

always_comb
begin
	next_state = state;
	case(state)
		idle: begin
			if (Icache_arbiter_read) next_state = Icache_read;
			else if (~Icache_arbiter_read & Dcache_arbiter_read) next_state = Dcache_read;
			else if (~Icache_arbiter_read & Dcache_arbiter_write) next_state = Dcache_write;
			else next_state = idle;
		end
		Icache_read: begin
			if (l2cache_arbiter_resp & ~Dcache_arbiter_read & ~Dcache_arbiter_write) next_state = idle;
			else if (l2cache_arbiter_resp & Dcache_arbiter_read & ~Dcache_arbiter_write) next_state = Dcache_read;
			else if (l2cache_arbiter_resp & ~Dcache_arbiter_read & Dcache_arbiter_write) next_state = Dcache_write;
			else next_state = Icache_read;
		end
		Dcache_read: if (l2cache_arbiter_resp) next_state = idle;
		Dcache_write: if (l2cache_arbiter_resp) next_state = idle;
		default : next_state = idle;
	endcase
end

always_ff @(posedge clk)
begin
	state <= next_state;
end

endmodule : arbiter_control

