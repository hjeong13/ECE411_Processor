
module cache_control (
	input clk,
	
	input logic [31:0] mem_address,
	input logic mem_read,
	input logic mem_write,
	input logic mem_read_reg_out,
	input logic mem_write_reg_out,
	output logic mem_resp,
	
	output logic [31:0] pmem_address,
	output logic pmem_read,
	output logic pmem_write,
	input logic pmem_resp,

	output logic [1:0] data_read_in,
	output logic [1:0] tag_read_in,
	output logic [1:0] valid_read_in,
	output logic [1:0] dirty_read_in,
	output logic lru_read_in,
	
	output logic [1:0] load_tag,
	output logic [1:0] load_valid,
	output logic [1:0] load_dirty,
	output logic load_lru,
	
	input logic [1:0][23:0] tag_out,
	input logic [1:0] dirty_out,
	input logic lru_out,
	
	input logic [1:0] hit,
	input logic [1:0] miss,
	
	output logic lru_in,
	
	output logic line_in_mux_sel,
	output logic [1:0] line_out_mux_sel,
	
	output logic dirty_in_mux_sel,
	output logic pmem_wdata_mux_sel,
	output logic [2:0] write_en_mux_sel,
	output logic load_stage,
	
	input logic [2:0] index_reg_out,
	input logic [31:0] mem_address_reg_out,
	output logic update_valid_tag,
	input logic dcache_stall,
	output logic rindex_mux_sel
); 

enum int unsigned {
    /* List of states */
	first_load,
	hit_miss_check,
	read_1,
	write_1
} state, next_state;

always_comb 
begin : state_action
	mem_resp = 1'b0;
	
	pmem_address = mem_address_reg_out & 32'hfffffff8;
	pmem_read = 1'b0;
	pmem_write = 1'b0;
	
	data_read_in = 2'b0;
	tag_read_in = 2'b0;
	valid_read_in = 2'b0;
	dirty_read_in = 2'b0;
	lru_read_in = 1'b0;
	
	load_tag = 2'b0;
	load_valid = 2'b0;
	load_dirty = 2'b0;
	load_lru = 1'b0;

	line_in_mux_sel = 1'b0;
	line_out_mux_sel = 2'b00;
	dirty_in_mux_sel = 1'b0;
	pmem_wdata_mux_sel  = 1'b0;
	write_en_mux_sel = 3'b0;
	
	lru_in = 1'b0;	
	load_stage = 1'b0;
	update_valid_tag = 1'b0;
	rindex_mux_sel = 1'b0;
	
	case(state)		
		/* Check for hit or miss */
		first_load: begin
			/* STAGE 1*/
			data_read_in = 2'b11;
			tag_read_in = 2'b11;
			valid_read_in = 2'b11;
			dirty_read_in = 2'b11;
			lru_read_in = 1'b1;
			load_stage = 1'b1;
		end
		
		hit_miss_check : begin
			/* STAGE 2*/
			/* Cache Hit */
			if(~mem_read_reg_out & ~mem_write_reg_out) begin
				mem_resp = 1'b1;
				load_stage = 1'b1;
				data_read_in = 2'b11;
				tag_read_in = 2'b11;
				valid_read_in = 2'b11;
				dirty_read_in = 2'b11;
				lru_read_in = 1'b1;
			end
			else if(hit[0] | hit[1]) begin
				line_out_mux_sel = hit;
				load_lru = 1'b1;
				
				if(hit[0] == 1)
					lru_in = 1'b1;
				else
					lru_in = 1'b0;
	
				if(mem_write_reg_out) begin
					dirty_in_mux_sel = 1'b1;
					load_dirty = {hit[1], hit[0]};					
					write_en_mux_sel = {1'b1, {hit[1]}, {hit[0]}};
				end
				
				if(~dcache_stall) begin
					mem_resp = 1'b1;
					load_stage = 1'b1;
					data_read_in = 2'b11;
					tag_read_in = 2'b11;
					valid_read_in = 2'b11;
					dirty_read_in = 2'b11;
					lru_read_in = 1'b1;
				end
			end
		end
	
		read_1 : begin
			/* STAGE 2*/
			pmem_read = 1'b1;
			line_in_mux_sel = 1'b1;
			write_en_mux_sel = {1'b0, {lru_out}, {~lru_out}};
			load_valid = {lru_out, ~lru_out};
			load_tag = {lru_out, ~lru_out};
			load_dirty = {lru_out, ~lru_out};
			update_valid_tag = 1'b1;
			
			rindex_mux_sel = 1'b1;
			data_read_in = 2'b11;
			tag_read_in = 2'b11;
			valid_read_in = 2'b11;
			dirty_read_in = 2'b11;
			lru_read_in = 1'b1;			
		end
		
		// Eviction (Write Back)
		write_1 : begin
			/* STAGE 2*/
			pmem_wdata_mux_sel  = lru_out;
			pmem_address = {tag_out[lru_out], index_reg_out, 5'b0};
			pmem_write = 1'b1;
		end
		
	endcase
	
end

always_comb
begin : next_state_logic
	next_state = state;
	
	case(state)
		first_load: begin
			if(mem_read | mem_write)
				next_state = hit_miss_check;
		end
		
		hit_miss_check : begin
			if(mem_read_reg_out | mem_write_reg_out) begin
				if(miss == 2'b11) begin
					if(dirty_out[lru_out])
						next_state = write_1;
					else
						next_state = read_1;
				end
				else
					next_state = hit_miss_check;
			end
		end
		
		read_1 : begin
			if(pmem_resp) begin
				next_state = hit_miss_check;
			end
		end

		write_1 : begin
			if(pmem_resp)
				next_state = read_1;
		end
	endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
	 state <= next_state;
end

endmodule : cache_control

