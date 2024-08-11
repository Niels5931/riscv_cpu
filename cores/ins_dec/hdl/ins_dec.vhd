library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;

entity ins_dec is
port (
	clk_i : in std_logic;
	rst_i : in std_logic;
	---------------------
	-- INS FECTH INPUTS --
	---------------------
	ins_data_i : in std_logic_vector(31 downto 0);
	pc_i : in std_logic_vector(31 downto 0);
	---------------------
	-- BRANCH PREDICTION --
	---------------------
	jmp_addr_o : out std_logic_vector(31 downto 0);
	jmp_valid_o : out std_logic;
	---------------------
	-- DECODED OUTPUTS --
	---------------------
	opcode_o : out std_logic_vector(6 downto 0);
	rs1_o : out std_logic_vector(31 downto 0);
	rs2_o : out std_logic_vector(31 downto 0);
	rd_o : out std_logic_vector(31 downto 0);
	funct3_o : out std_logic_vector(2 downto 0);
	funct7_o : out std_logic_vector(6 downto 0);
	imm_o : out std_logic_vector(31 downto 0);
	wb_en_o : out std_logic; -- write back enable
	-- data forwarding stuff
	---------------------
	-- EXECUTE INPUTS --
	---------------------
	zero_i : in std_logic;
	---------------------
	-- WRITE BACK INPUTS --
	---------------------
	reg_wr_en_i : in std_logic;
	reg_wr_addr_i : in std_logic_vector(4 downto 0);
	reg_wr_data_i : in std_logic_vector(31 downto 0)
);
end entity;

architecture rtl of ins_dec is

	function sign_ext (val : std_logic; amount : integer) return std_logic_vector is
		variable res : std_logic_vector(amount-1 downto 0);
	begin
		if val = '1' then
			res := (others => '1');
		else
			res := (others => '0');
		end if;
		return res;
	end function;

	type state_t is (TAKEN_ONE, TAKEN_TWO, NOT_TAKEN_ONE, NOT_TAKEN_TWO);
	signal state_reg, next_state : state_t;

	signal is_r_instr : std_logic;
	signal is_i_instr : std_logic;
	signal is_s_instr : std_logic;
	signal is_b_instr : std_logic;
	signal is_u_instr : std_logic;
	signal is_j_instr : std_logic;

	signal opcode_s : std_logic_vector(6 downto 0);
	signal funct3_s : std_logic_vector(2 downto 0);
	signal funct7_s : std_logic_vector(6 downto 0);
	signal rs1_s : std_logic_vector(31 downto 0);
	signal rs2_s : std_logic_vector(31 downto 0);
	signal rd_s : std_logic_vector(31 downto 0);
	signal imm_s : std_logic_vector(31 downto 0);

	signal opcode_reg : std_logic_vector(6 downto 0);
	signal funct3_reg : std_logic_vector(2 downto 0);
	signal funct7_reg : std_logic_vector(6 downto 0);
	signal rs1_reg : std_logic_vector(31 downto 0);
	signal rs2_reg : std_logic_vector(31 downto 0);
	signal rd_reg : std_logic_vector(31 downto 0);
	signal imm_reg : std_logic_vector(31 downto 0);

	signal jmp_addr_s : std_logic_vector(31 downto 0);
	signal jmp_valid_s : std_logic;

	signal jmp_addr_buf : std_logic_vector(31 downto 0); -- store jump address when predicting not taken
	signal jmp_addr_buf_en : std_logic; -- enable jump address buffer
	signal pc_buf : std_logic_vector(31 downto 0); -- store pc when predicting taken
	signal pc_buf_en : std_logic; -- enable pc buffer
	signal is_b_instr_ex_s : std_logic; -- is branch instruction in execute stage
	signal branch_taken_s : std_logic; -- branch taken signal

	signal wb_en_s : std_logic; -- write back enable
	signal wb_en_reg : std_logic; -- write back enable register

	signal reg_file : arr(0 to 31)(31 downto 0);

begin

	opcode_s <= ins_data_i(6 downto 0);
	funct3_s <= ins_data_i(14 downto 12);
	funct7_s <= ins_data_i(31 downto 25);

	-- decode instruction type
	is_r_instr <= '1' when opcode_s = "0110011" else '0';
	is_i_instr <= '1' when opcode_s = "0010011" or opcode_s = "0000011" or opcode_s = "1100111" else '0';
	is_s_instr <= '1' when opcode_s = "0100011" else '0';
	is_b_instr <= '1' when opcode_s = "1100011" else '0';
	is_u_instr <= '1' when opcode_s = "0110111" or opcode_s = "0010111" else '0';
	is_j_instr <= '1' when opcode_s = "1101111" else '0';
	is_b_instr_ex <= '1' when opcode_reg = "1100011" else '0';

	-- immediate assignment
	process(all)
	begin
			if is_i_instr = '1' then
				imm_s <= sign_ext(ins_data_i(31),21) & ins_data_i(30 downto 20);
			elsif is_s_instr = '1' then
				imm_s <= sign_ext(ins_data_i(31), 21) & ins_data_i(30 downto 25) & ins_data_i(11 downto 7);
			elsif is_b_instr = '1' then
				imm_s <= sign_ext(ins_data_i(31), 21) & ins_data_i(7) & ins_data_i(30 downto 25) & ins_data_i(11 downto 8) & "0";
			elsif is_u_instr = '1' then
				imm_s <= ins_data_i(31 downto 12) & "000000000000";
			elsif is_j_instr = '1' then
				imm_s <= sign_ext(ins_data_i(31), 12) & ins_data_i(19 downto 12) & ins_data_i(20) & ins_data_i(30 downto 21) & "0";
			else
				imm_s <= (others => '0');
			end if;
		end process;

	-- regfile thingy
	process(clk_i, rst_i)
	begin
		rs1_s <= reg_file(TO_INTEGER(unsigned(ins_data_i(19 downto 15))));
		rs2_s <= reg_file(TO_INTEGER(unsigned(ins_data_i(24 downto 20))));
		rd_s <= reg_file(TO_INTEGER(unsigned(ins_data_i(11 downto 7))));
		if rising_edge(clk_i) then
			if rst_i = '1' then
				for i in 0 to 31 loop
					reg_file(i) <= (others => '0');
				end loop;
			else
				if reg_wr_en_i = '1' then
					reg_file(TO_INTEGER(unsigned(reg_wr_addr_i))) <= reg_wr_data_i;
				end if;
			end if;
		end if;
	end process;

	-- state register
	process(clk_i, rst_i)
	begin
		if rising_edge(clk_i) then
			if rst_i = '1' then
				state_reg <= NOT_TAKEN_ONE;
			else
				state_reg <= next_state;
			end if;
		end if;
	end process;

	-- branch result
	process(all)
	begin
		case is_b_instr_ex is =>
			when '1' =>
				if 

	-- branch prediction statemachine
	process(all)
	begin
		jump_addr_s <= pc_i + imm_s;
		-- when jump instruction assign jump address and make valid
		if is_j_instr = '1' then
			jmp_valid_s <= '1';
		elsif is_b_instr = '1' then
			case state_reg is
				when NOT_TAKEN_TWO => 
					if is_j_instr_reg = '1' and



		 


	-- branch prediction buffers; store jump address and pc to correct for mispredictions
	process(clk_i, rst_i)
	begin
		if rising_edge(clk_i) then
			if rst_i = '1' then
				jmp_addr_buf <= (others => '0');
				pc_buf <= (others => '0');
				is_b_instr_reg <= '0';
			else
				if jmp_addr_buf_en = '1' then
					jmp_addr_buf <= jmp_addr_s;
				end if;
				if pc_buf_en = '1' then
					pc_buf <= pc_i;
				end if;
				is_b_instr_reg <= is_b_instr;
			end if;
		end if;
	end process;

	-- output register assignment
	process(clk_i, rst_i)
	begin
		if rising_edge(clk_i) then
			if rst_i = '1' then
				opcode_reg <= (others => '0');
				funct3_reg <= (others => '0');
				funct7_reg <= (others => '0');
				rs1_reg <= (others => '0');
				rs2_reg <= (others => '0');
				rd_reg <= (others => '0');
				imm_reg <= (others => '0');
				wb_en_reg <= '0';
			else
				opcode_reg <= opcode_s;
				funct3_reg <= funct3_s;
				funct7_reg <= funct7_s;
				rs1_reg <= rs1_s;
				rs2_reg <= rs2_s;
				rd_reg <= rd_s;
				imm_reg <= imm_s;
				wb_en_reg <= wb_en_s;
			end if;
		end if;
	end process;

	-- output assignment
	opcode_o <= opcode_reg;
	funct3_o <= funct3_reg;
	funct7_o <= funct7_reg;
	rs1_o <= rs1_reg;
	rs2_o <= rs2_reg;
	rd_o <= rd_reg;
	imm_o <= imm_reg;
	jmp_addr_o <= jmp_addr_s;
	jmp_valid_o <= jmp_valid_s;

end architecture;