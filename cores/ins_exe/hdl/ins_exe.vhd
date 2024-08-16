library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;

entity ins_exe is
	port (
		clk_i : in std_logic;
		rst_i : in std_logic;
		---------------------
		-- DECODE INPUTS --
		---------------------
		opcode_i : in std_logic_vector(6 downto 0);
		rs1_i : in std_logic_vector(31 downto 0);
		rs1_addr_i : in std_logic_vector(4 downto 0);
		rs2_i : in std_logic_vector(31 downto 0);
		rs2_addr_i : in std_logic_vector(4 downto 0);
		rd_i : in std_logic_vector(4 downto 0);	
		pc_i : in std_logic_vector(31 downto 0);
		funct3_i : in std_logic_vector(2 downto 0);
		funct7_i : in std_logic_vector(6 downto 0);
		imm_i : in std_logic_vector(31 downto 0);
		wb_en_i : in std_logic; -- write back enable
		data_mem_wr_en_i : in std_logic; -- data memory enable
		data_mem_rd_en_i : in std_logic; -- data memory enable
		---------------------
		-- DECODE OUTPUTS --
		---------------------
		zero_o : out std_logic;
		lt_o : out std_logic; -- rs1 < rs2
		---------------------
		-- MEMORY OUTPUTS --
		---------------------
		data_mem_wr_en_o : out std_logic; -- data memory enable
		data_mem_rd_en_o : out std_logic; -- data memory enable
		wb_en_o : out std_logic; -- write back enable
		alu_res_o : out std_logic_vector(31 downto 0);
		mem_data_o : out std_logic_vector(31 downto 0); -- register to be stored in memory
		funct3_o : out std_logic_vector(2 downto 0); -- for byte/halfword/word
		rd_o : out std_logic_vector(4 downto 0); -- destination register
		---------------------
		-- WRITE BACK INPUTS --
		---------------------
		wb_rd_data_i : in std_logic_vector(31 downto 0) -- data forwarding from write back stage
	);
end entity;

architecture rtl of ins_exe is

	signal zero_s : std_logic;
	signal lt_s : std_logic;
	signal alu_res_s : std_logic_vector(31 downto 0);
	signal mem_data_s : std_logic_vector(31 downto 0);
	
	signal alu_op_1_s : std_logic_vector(31 downto 0);
	signal alu_op_2_s : std_logic_vector(31 downto 0);
	signal alu_res_reg : std_logic_vector(31 downto 0);
	signal funct3_reg : std_logic_vector(2 downto 0);
	signal reg_wr_en_reg : std_logic;
	signal rd_reg : std_logic_vector(4 downto 0);
	signal rd_reg_reg : std_logic_vector(4 downto 0); 
	signal mem_data_reg : std_logic_vector(31 downto 0);
	signal data_mem_wr_en_reg : std_logic;
	signal data_mem_rd_en_reg : std_logic;
	signal wb_en_reg : std_logic;

begin

	-- ALU
	process(all)
	begin
		zero_s <= '1' when alu_res_s = x"00000000" else '0';
		lt_s <= '0';
		alu_res_s <= (others => '0');
		if opcode_i = "0110011" or opcode_i = "0010011" then
			if funct3_i = "000" then
				-- ADD or SUB
				if opcode_i = "0110011" then
					if funct7_i = "0000000" then
						alu_res_s <= std_logic_vector(signed(alu_op_1_s) + signed(alu_op_2_s));
					else
						alu_res_s <= alu_op_1_s - alu_op_2_s;
					end if;
				else
					alu_res_s <= std_logic_vector(signed(alu_op_1_s) + signed(alu_op_2_s));
				end if;
			elsif funct3_i = "001" then
				-- SLL
				alu_res_s <= std_logic_vector(shift_left(unsigned(alu_op_1_s), to_integer(unsigned(alu_op_2_s))));
			elsif funct3_i = "010" then
				-- SLT
				alu_res_s <= std_logic_vector(to_unsigned(1,32)) when (signed(alu_op_1_s) < signed(alu_op_2_s)) else std_logic_vector(to_unsigned(0,32)); 
			elsif funct3_i = "011" then
				-- SLTU
				alu_res_s <= std_logic_vector(to_unsigned(1,32)) when (unsigned(alu_op_1_s) < unsigned(alu_op_2_s)) else std_logic_vector(to_unsigned(0,32));
			elsif funct3_i = "100" then
				-- XOR
				alu_res_s <= std_logic_vector(unsigned(alu_op_1_s) xor unsigned(alu_op_2_s));
			elsif funct3_i = "101" then
				-- SRL or SRA
				if funct7_i = "0000000" then
					alu_res_s <= std_logic_vector(shift_right(unsigned(alu_op_1_s), to_integer(unsigned(alu_op_2_s))));
				else
					alu_res_s <= std_logic_vector(shift_right(signed(alu_op_1_s), to_integer(unsigned(alu_op_2_s))));
				end if;
			elsif funct3_i = "110" then
				-- OR
				alu_res_s <= std_logic_vector(unsigned(alu_op_1_s) or unsigned(alu_op_2_s));
			elsif funct3_i = "111" then
				-- AND
				alu_res_s <= std_logic_vector(unsigned(alu_op_1_s) and unsigned(alu_op_2_s));
			end if;
		elsif opcode_i = "1100011" then
			-- branch
			if funct3_i = "100" or funct3_i = "101" then
				-- blt or bge
				lt_s <= '1' when signed(alu_op_1_s) < signed(alu_op_2_s) else '0';
			elsif funct3_i = "110" or funct3_i = "111" then
				-- bltu or bgeu
				lt_s <= '1' when unsigned(alu_op_1_s) < unsigned(alu_op_2_s) else '0';
			else
				lt_s <= '0';
			end if;
		else
			alu_res_s <= alu_op_1_s + alu_op_2_s;
		end if;
	end process;

	-- ALU operand assignment
	process(all)
	begin
		alu_op_1_s <= rs1_i;
		alu_op_2_s <= rs2_i;
		case opcode_i is 
			when "0010011" | "0000011" | "0100011" => 
				-- I type
				alu_op_2_s <= imm_i;
				if rd_reg = rs1_addr_i then
					alu_op_1_s <= alu_res_reg;
				elsif rd_reg_reg = rs1_addr_i then
					alu_op_1_s <= wb_rd_data_i;
				else
					alu_op_1_s <= rs1_i;
				end if;
			when "0110011" =>
				-- R type
				if rd_reg = rs1_addr_i then
					alu_op_1_s <= alu_res_reg;
				elsif rd_reg_reg = rs1_addr_i then
					alu_op_1_s <= wb_rd_data_i;
				else
					alu_op_1_s <= rs1_i;
				end if;
				if rd_reg = rs2_addr_i then
					alu_op_2_s <= alu_res_reg;
				elsif rd_reg_reg = rs2_addr_i then
					alu_op_2_s <= wb_rd_data_i;
				else
					alu_op_2_s <= rs2_i;
				end if;
			when "0010111" =>
				-- auipc
				alu_op_1_s <= pc_i;
				alu_op_2_s <= imm_i;
			when "0110111" =>
				-- lui
				alu_op_1_s <= (others => '0');
				alu_op_2_s <= imm_i;
			when "1100111" | "1101111" =>
				-- jalr or jal
				alu_op_1_s <= pc_i;
				alu_op_2_s <= std_logic_vector(to_unsigned(4,32));
			when others =>
				-- S type
				alu_op_1_s <= rs1_i;
				alu_op_2_s <= rs2_i;
		end case;
	end process;

	-- assign mem data
	process(all)
	begin
		mem_data_s <= rs2_i;
		if rd_reg = rs2_addr_i then
			mem_data_s <= alu_res_reg;
		elsif rd_reg_reg = rs2_addr_i then
			mem_data_s <= wb_rd_data_i;
		end if;
	end process;

	--registers
	process(clk_i, rst_i)
	begin
		if rising_edge(clk_i) then
			if rst_i = '1' then
				alu_res_reg <= (others => '0');
				rd_reg <= (others => '0');
				rd_reg_reg <= (others => '0');
				funct3_reg <= (others => '0');
				mem_data_reg <= (others => '0');
				data_mem_wr_en_reg <= '0';
				data_mem_rd_en_reg <= '0';
				wb_en_reg <= '0';
			else
				alu_res_reg <= alu_res_s;
				rd_reg <= rd_i;
				rd_reg_reg <= rd_reg;
				funct3_reg <= funct3_i;
				mem_data_reg <= mem_data_s;
				data_mem_wr_en_reg <= data_mem_wr_en_i;
				data_mem_rd_en_reg <= data_mem_rd_en_i;
				wb_en_reg <= wb_en_i;
			end if;
		end if;
	end process;

	-- output assignments
	zero_o <= zero_s;
	lt_o <= lt_s;
	alu_res_o <= alu_res_reg;
	mem_data_o <= mem_data_reg;
	funct3_o <= funct3_reg;
	data_mem_wr_en_o <= data_mem_wr_en_reg;
	data_mem_rd_en_o <= data_mem_rd_en_reg;
	wb_en_o <= wb_en_reg;
	rd_o <= rd_reg;

end architecture;

	 
