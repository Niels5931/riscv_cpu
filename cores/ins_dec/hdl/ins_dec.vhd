library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;

entity ins_dec is
port (
	clk_i : in std_logic;
	rst_i : in std_logic;
	-- instruction in
	ins_data_i : in std_logic_vector(31 downto 0);
	pc_i : in std_logic_vector(31 downto 0);
	-- decoded fields out
	opcode_o : out std_logic_vector(6 downto 0);
	rs1_o : out std_logic_vector(31 downto 0);
	rs2_o : out std_logic_vector(31 downto 0);
	rd_o : out std_logic_vector(31 downto 0);
	funct3_o : out std_logic_vector(2 downto 0);
	funct7_o : out std_logic_vector(6 downto 0);
	imm_o : out std_logic_vector(31 downto 0);
	-- branch out
	jmp_addr_o : out std_logic_vector(31 downto 0);
	jmp_valid_o : out std_logic;
	-- register write back
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

	signal is_r_instr : std_logic;
	signal is_i_instr : std_logic;
	signal is_s_instr : std_logic;
	signal is_b_instr : std_logic;
	signal is_u_instr : std_logic;
	signal is_j_instr : std_logic;

	signal reg_file : arr(0 to 31)(31 downto 0);

begin

	opcode_o <= ins_data_i(6 downto 0);
	funct3_o <= ins_data_i(14 downto 12);
	funct7_o <= ins_data_i(31 downto 25);

	-- decode instruction type
	is_r_instr <= '1' when opcode_o = "0110011" else '0';
	is_i_instr <= '1' when opcode_o = "0010011" or opcode_o = "0000011" or opcode_o = "1100111" else '0';
	is_s_instr <= '1' when opcode_o = "0100011" else '0';
	is_b_instr <= '1' when opcode_o = "1100011" else '0';
	is_u_instr <= '1' when opcode_o = "0110111" or opcode_o = "0010111" else '0';
	is_j_instr <= '1' when opcode_o = "1101111" else '0';

	-- immediate assignment
	process(all)
	begin
		if is_i_instr = '1' then
			imm_o <= sign_ext(ins_data_i(31),21) & ins_data_i(30 downto 20);
		elsif is_s_instr = '1' then
			imm_o <= sign_ext(ins_data_i(31), 21) & ins_data_i(30 downto 25) & ins_data_i(11 downto 7);
		elsif is_b_instr = '1' then
			imm_o <= sign_ext(ins_data_i(31), 21) & ins_data_i(7) & ins_data_i(30 downto 25) & ins_data_i(11 downto 8) & "0";
		elsif is_u_instr = '1' then
			imm_o <= ins_data_i(31 downto 12) & "000000000000";
		elsif is_j_instr = '1' then
			imm_o <= sign_ext(ins_data_i(31), 12) & ins_data_i(19 downto 12) & ins_data_i(20) & ins_data_i(30 downto 21) & "0";
		else
			imm_o <= (others => '0');
		end if;
	end process;

	-- regfile thingy
	process(clk_i, rst_i)
	begin
		rs1_o <= reg_file(TO_INTEGER(unsigned(ins_data_i(19 downto 15))));
		rs2_o <= reg_file(TO_INTEGER(unsigned(ins_data_i(24 downto 20))));
		rd_o <= reg_file(TO_INTEGER(unsigned(ins_data_i(11 downto 7))));
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

end architecture;