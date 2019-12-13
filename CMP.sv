import rv32i_types::*;

module CMP
(
	input branch_funct3_t cmpop,
	input rv32i_word rs1_out, cmpmux_out,
	input [6:0] opcode, 
	output logic br_en
);

// a = rs1_out, b = cmpmux_out

always_comb
begin
	case (cmpop)
		//BEQ = equal
		3'b000: begin
			if(rs1_out == cmpmux_out)
				br_en = 1'b1;
			else
				br_en = 1'b0;
		end
		//BNE = not equal
		3'b001: begin
			if(rs1_out == cmpmux_out)
				br_en = 1'b0;
			else
				br_en = 1'b1;
		end
		//BLT = greater or equal(signed)
		3'b100: begin
			if($signed(rs1_out) < $signed(cmpmux_out))
				br_en = 1'b1;
			else
				br_en = 1'b0;
		end
		//BLT = less (signed)
		/*3'b100: begin
			if(rs1_out[31] == 1 && cmpmux_out[31] == 0)
				br_en = 1'b1;
			else if(rs1_out[31] == 0 && cmpmux_out[31] == 1)
				br_en = 1'b0;
			else begin
				if(rs1_out[31] == 0 && rs1_out < cmpmux_out)
					br_en = 1'b1;
				else if(rs1_out[31] == 1 && rs1_out < cmpmux_out)
					br_en = 1'b1;
				else
					br_en = 1'b0;
			end
		end*/
		//BGE = greater or equal (signed)
		3'b101: begin
			if($signed(rs1_out) < $signed(cmpmux_out))
				br_en = 1'b0;
			else
				br_en = 1'b1;
		end
		//BGE = greater or equal (signed)
		/*3'b101: begin
			if(rs1_out[31] == 1 && cmpmux_out[31] == 0)
				br_en = 1'b0;
			else if(rs1_out[31] == 0 && cmpmux_out[31] == 1)
				br_en = 1'b1;
			else begin
				if(rs1_out[31] == 0 && rs1_out < cmpmux_out)
					br_en = 1'b0;
				else if(rs1_out[31] == 1 && rs1_out < cmpmux_out)
					br_en = 1'b0;
				else
					br_en = 1'b1;
			end
		end*/
		//BLTU = less (unsigned)
		3'b110: begin
			if(rs1_out < cmpmux_out)
				br_en = 1'b1;
			else
				br_en = 1'b0;
		end
		//BGEU = greater or equal (unsigned)
		3'b111: begin
			if(rs1_out < cmpmux_out)
				br_en = 1'b0;
			else
				br_en = 1'b1;
		end
		// Not possible
		default: br_en = 1'b0;
		
	endcase
	if (opcode != 7'b1100011)
		br_en = 1'b0;
end

endmodule : CMP

