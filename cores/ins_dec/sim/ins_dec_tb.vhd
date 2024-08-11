library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ins_dec_tb is
end entity;

architecture rtl of ins_dec_tb is
	component ins_dec is
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
	end component;

	signal clk_in_s:  std_logic := '0';
	signal rst_in_s:  std_logic := '1';
	signal ins_data_in_s:  std_logic_vector(31 downto 0);
	signal pc_in_s:  std_logic_vector(31 downto 0);
	signal opcode_out_s:  std_logic_vector(6 downto 0);
	signal rs1_out_s:  std_logic_vector(31 downto 0);
	signal rs2_out_s:  std_logic_vector(31 downto 0);
	signal rd_out_s:  std_logic_vector(31 downto 0);
	signal funct3_out_s:  std_logic_vector(2 downto 0);
	signal funct7_out_s:  std_logic_vector(6 downto 0);
	signal imm_out_s:  std_logic_vector(31 downto 0);
	signal jmp_addr_out_s:  std_logic_vector(31 downto 0);
	signal jmp_valid_out_s:  std_logic;
	signal reg_wr_en_in_s:  std_logic;
	signal reg_wr_addr_in_s:  std_logic_vector(4 downto 0);
	signal reg_wr_data_in_s:  std_logic_vector(31 downto 0);

	signal wr_done_s: std_logic := '0';

begin
	DUT: ins_dec port map (
		clk_i => clk_in_s,
		rst_i => rst_in_s,
		ins_data_i => ins_data_in_s,
		pc_i => pc_in_s,
		opcode_o => opcode_out_s,
		rs1_o => rs1_out_s,
		rs2_o => rs2_out_s,
		rd_o => rd_out_s,
		funct3_o => funct3_out_s,
		funct7_o => funct7_out_s,
		imm_o => imm_out_s,
		jmp_addr_o => jmp_addr_out_s,
		jmp_valid_o => jmp_valid_out_s,
		reg_wr_en_i => reg_wr_en_in_s,
		reg_wr_addr_i => reg_wr_addr_in_s,
		reg_wr_data_i => reg_wr_data_in_s
	);

	rst_in_s <= '0' after 20 ns;

	process
	begin
		clk_in_s <= not clk_in_s;
		wait for 5 ns;
	end process;

	process
	begin
		wait until rising_edge(clk_in_s) and rst_in_s = '0';
		for i in 0 to 31 loop
			reg_wr_en_in_s <= '1';
			reg_wr_addr_in_s <= std_logic_vector(to_unsigned(i, 5));
			reg_wr_data_in_s <= std_logic_vector(to_unsigned(i, 32));
			wait until rising_edge(clk_in_s);
		end loop;
		reg_wr_en_in_s <= '0';
		wr_done_s <= '1';
		wait;
	end process;

	process
	begin
		wait until rising_edge(clk_in_s) and wr_done_s = '1';
		ins_data_in_s <= x"024000ef";
		wait until rising_edge(clk_in_s);
		ins_data_in_s <= x"403102b3";
		wait until rising_edge(clk_in_s);
		wait for 10 ns;
		std.env.stop(0);
	end process;


end architecture;

