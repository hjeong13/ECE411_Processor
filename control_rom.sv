import rv32i_types::*; /* Import types defined in rv32i_types.sv */

module control_rom
(
	input rv32i_word ir,
	output rv32i_control_word  ctrl
);

rv32i_opcode opcode;
logic [2:0] funct3;
logic [6:0] funct7;

always_comb
begin
	opcode = rv32i_opcode'(ir[6:0]);
	funct3 = ir[14:12];
	funct7 = ir[31:25];
end

always_comb
begin
	ctrl.aluop = alu_ops'(funct3);
	ctrl.cmpop = branch_funct3_t'(funct3);
	ctrl.load_regfile = 0;
	ctrl.pc_mux_sel = 0;
	ctrl.regfilemux_sel = 0;
	ctrl.byte_mux_sel = 0;
	ctrl.half_mux_sel = 0;
	ctrl.cmpmux_sel = 0;
	ctrl.alumux1_sel = 0;
	ctrl.alumux2_sel = 0;
	
	case (opcode)
		op_lui: begin
			ctrl.load_regfile = 1;
			ctrl.regfilemux_sel = 2;
		end

		op_auipc: begin
			ctrl.load_regfile = 1;
			ctrl.alumux1_sel = 1;
			ctrl.alumux2_sel = 1;
		end
		
		op_jal: begin
			ctrl.load_regfile = 1;
			ctrl.pc_mux_sel = 1;
			ctrl.alumux1_sel = 1;
			ctrl.alumux2_sel = 4;
			ctrl.aluop = alu_add;
			ctrl.regfilemux_sel = 4;
		end
		
		op_jalr: begin
			ctrl.load_regfile = 1;
			ctrl.aluop = alu_add;
			ctrl.regfilemux_sel = 4;
			ctrl.pc_mux_sel = 1;
		end

		op_load: begin
			case(funct3)
				3'b000: begin
					ctrl.load_regfile = 1;
					ctrl.regfilemux_sel = 5;
					ctrl.byte_mux_sel = 4;
					ctrl.aluop = alu_add;
				end
				3'b001: begin
					ctrl.load_regfile = 1;
					ctrl.regfilemux_sel = 6;
					ctrl.half_mux_sel = 4;
					ctrl.aluop = alu_add;
				end
				3'b010: begin
					ctrl.load_regfile = 1;
					ctrl.regfilemux_sel = 3;
					ctrl.aluop = alu_add;
				end
				3'b100: begin
					ctrl.load_regfile = 1;
					ctrl.regfilemux_sel = 6;
					ctrl.aluop = alu_add;
				end
				3'b101: begin
					ctrl.load_regfile = 1;
					ctrl.regfilemux_sel = 5;
					ctrl.aluop = alu_add;
				end
				default: ;
			endcase
		end

		op_store: begin
			ctrl.load_regfile = 0;
			ctrl.alumux2_sel = 3;
			ctrl.aluop = alu_add;
		end

		op_imm: begin
			case(funct3)
				slt: begin
					ctrl.load_regfile = 1;
					ctrl.cmpop = blt;
					ctrl.regfilemux_sel = 1;
					ctrl.cmpmux_sel = 1;
				end
				
				sltu: begin
					ctrl.load_regfile = 1;
					ctrl.cmpop = bltu;
					ctrl.regfilemux_sel = 1;
					ctrl.cmpmux_sel = 1;
				end
				
				sr: begin
					case(funct7[5])
						1'b0: begin
							ctrl.load_regfile = 1;
							ctrl.aluop = alu_ops'(funct3);
						end
						1'b1: begin
							ctrl.load_regfile = 1;
							ctrl.aluop = alu_sra;
						end
					endcase
				end
				
				default: begin 
					ctrl.load_regfile = 1;
					ctrl.aluop = alu_ops'(funct3);
				end
			endcase 
		end

		op_reg: begin
			case(funct3)
				add: begin
					case(funct7[5])
						1'b0: begin
							ctrl.load_regfile = 1;
							ctrl.alumux2_sel = 5;
							ctrl.aluop = alu_ops'(funct3);
						end
						1'b1: begin
							ctrl.load_regfile = 1;
							ctrl.alumux2_sel = 5;
							ctrl.aluop = alu_sub;
						end
					endcase
				end
				
				slt: begin
					ctrl.load_regfile = 1;
					ctrl.cmpop = blt;
					ctrl.regfilemux_sel = 1;
				end
				
				sltu: begin
					ctrl.load_regfile = 1;
					ctrl.cmpop = bltu;
					ctrl.regfilemux_sel = 1;
				end
				
				sr: begin
					case(funct7[5])
						1'b0: begin
							ctrl.load_regfile = 1;
							ctrl.alumux2_sel = 5;
							ctrl.aluop = alu_ops'(funct3);
						end
						1'b1: begin
							ctrl.load_regfile = 1;
							ctrl.alumux2_sel = 5;
							ctrl.aluop = alu_sra;
						end
					endcase
				end
				
				default: begin 
					ctrl.load_regfile = 1;
					ctrl.alumux2_sel = 5;
					ctrl.aluop = alu_ops'(funct3);
				end
			endcase 
		end

		op_br: begin
			ctrl.pc_mux_sel = 2;
			ctrl.alumux1_sel = 1;
			ctrl.alumux2_sel = 2;
			ctrl.aluop = alu_add;
			ctrl.cmpop = branch_funct3_t'(funct3);
		end

		default: begin
			ctrl = 0;
		end
	endcase
end

endmodule : control_rom