library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity di_ins_exe_tb is
end entity;

architecture rtl of di_ins_exe_tb is

	component di_ins_exe is
	port (
		clk_i : in std_logic;
		rst_i : in std_logic;
		---------------------
		pc_i : in std_logic_vector(31 downto 0);
		rs1_i1_i : in std_logic_vector(31 downto 0);
		rs1_i1_addr_i : in std_logic_vector(4 downto 0);
		rs2_i1_i : in std_logic_vector(31 downto 0);
		rs2_i1_addr_i : in std_logic_vector(4 downto 0);
		rd_i1_i : in std_logic_vector(4 downto 0);
		opcode_i1_i : in std_logic_vector(6 downto 0);
		funct3_i1_i : in std_logic_vector(2 downto 0);
		funct7_i1_i : in std_logic_vector(6 downto 0);
		imm_i1_i : in std_logic_vector(31 downto 0);
		wb_en_i1_i : in std_logic;
		---------------------
		rs1_i2_i : in std_logic_vector(31 downto 0);
		rs1_i2_addr_i : in std_logic_vector(4 downto 0);
		rs2_i2_i : in std_logic_vector(31 downto 0);
		rs2_i2_addr_i : in std_logic_vector(4 downto 0);
		rd_i2_i : in std_logic_vector(4 downto 0);
		opcode_i2_i : in std_logic_vector(6 downto 0);
		funct3_i2_i : in std_logic_vector(2 downto 0);
		funct7_i2_i : in std_logic_vector(6 downto 0);
		imm_i2_i : in std_logic_vector(31 downto 0);
		wb_en_i2_i : in std_logic;
		data_mem_wr_en_i2_i : in std_logic;
		data_mem_rd_en_i2_i : in std_logic;
		---------------------
		alu_res_i1_o : out std_logic_vector(31 downto 0);
		jmp_addr_alu_res_o : out std_logic_vector(31 downto 0);
		wb_en_i1_o : out std_logic;
		rd_i1_o : out std_logic_vector(4 downto 0);
		zero_i1_o : out std_logic;
		lt_i1_o : out std_logic;
		---------------------
		alu_res_i2_o : out std_logic_vector(31 downto 0);
		wb_en_i2_o : out std_logic;
		rd_i2_o : out std_logic_vector(4 downto 0);
		funct3_i2_o : out std_logic_vector(2 downto 0);
		mem_data_i2_o : out std_logic_vector(31 downto 0);
		data_mem_wr_en_i2_o : out std_logic;
		data_mem_rd_en_i2_o : out std_logic;
		---------------------
		wb_rd_data_i1_i : in std_logic_vector(31 downto 0);
		wb_rd_addr_i1_i : in std_logic_vector(4 downto 0);
		wb_rd_en_i1_i : in std_logic;
		---------------------
		wb_rd_data_i2_i : in std_logic_vector(31 downto 0);
		wb_rd_addr_i2_i : in std_logic_vector(4 downto 0);
		wb_rd_en_i2_i : in std_logic
	);
	end component;

	signal clk_in_s :  std_logic := '0';
	signal rst_in_s :  std_logic := '1';
	signal pc_in_s :  std_logic_vector(31 downto 0);
	signal rs1_i1_in_s :  std_logic_vector(31 downto 0);
	signal rs1_i1_addr_in_s :  std_logic_vector(4 downto 0);
	signal rs2_i1_in_s :  std_logic_vector(31 downto 0);
	signal rs2_i1_addr_in_s :  std_logic_vector(4 downto 0);
	signal rd_i1_in_s :  std_logic_vector(4 downto 0);
	signal opcode_i1_in_s :  std_logic_vector(6 downto 0);
	signal funct3_i1_in_s :  std_logic_vector(2 downto 0);
	signal funct7_i1_in_s :  std_logic_vector(6 downto 0);
	signal imm_i1_in_s :  std_logic_vector(31 downto 0);
	signal wb_en_i1_in_s :  std_logic;
	signal rs1_i2_in_s :  std_logic_vector(31 downto 0);
	signal rs1_i2_addr_in_s :  std_logic_vector(4 downto 0);
	signal rs2_i2_in_s :  std_logic_vector(31 downto 0);
	signal rs2_i2_addr_in_s :  std_logic_vector(4 downto 0);
	signal rd_i2_in_s :  std_logic_vector(4 downto 0);
	signal opcode_i2_in_s :  std_logic_vector(6 downto 0);
	signal funct3_i2_in_s :  std_logic_vector(2 downto 0);
	signal funct7_i2_in_s :  std_logic_vector(6 downto 0);
	signal imm_i2_in_s :  std_logic_vector(31 downto 0);
	signal wb_en_i2_in_s :  std_logic;
	signal data_mem_wr_en_i2_in_s :  std_logic;
	signal data_mem_rd_en_i2_in_s :  std_logic;
	signal alu_res_i1_out_s :  std_logic_vector(31 downto 0);
	signal jmp_addr_alu_res_out_s :  std_logic_vector(31 downto 0);
	signal wb_en_i1_out_s :  std_logic;
	signal rd_i1_out_s :  std_logic_vector(4 downto 0);
	signal zero_i1_out_s :  std_logic;
	signal lt_i1_out_s :  std_logic;
	signal alu_res_i2_out_s :  std_logic_vector(31 downto 0);
	signal wb_en_i2_out_s :  std_logic;
	signal rd_i2_out_s :  std_logic_vector(4 downto 0);
	signal funct3_i2_out_s :  std_logic_vector(2 downto 0);
	signal mem_data_i2_out_s :  std_logic_vector(31 downto 0);
	signal data_mem_wr_en_i2_out_s :  std_logic;
	signal data_mem_rd_en_i2_out_s :  std_logic;
	signal wb_rd_data_i1_in_s :  std_logic_vector(31 downto 0);
	signal wb_rd_addr_i1_in_s :  std_logic_vector(4 downto 0);
	signal wb_rd_en_i1_in_s :  std_logic;
	signal wb_rd_data_i2_in_s :  std_logic_vector(31 downto 0);
	signal wb_rd_addr_i2_in_s :  std_logic_vector(4 downto 0);
	signal wb_rd_en_i2_in_s :  std_logic;

begin

	DUT: di_ins_exe port map (
		clk_i => clk_in_s,
		rst_i => rst_in_s,
		pc_i => pc_in_s,
		rs1_i1_i => rs1_i1_in_s,
		rs1_i1_addr_i => rs1_i1_addr_in_s,
		rs2_i1_i => rs2_i1_in_s,
		rs2_i1_addr_i => rs2_i1_addr_in_s,
		rd_i1_i => rd_i1_in_s,
		opcode_i1_i => opcode_i1_in_s,
		funct3_i1_i => funct3_i1_in_s,
		funct7_i1_i => funct7_i1_in_s,
		imm_i1_i => imm_i1_in_s,
		wb_en_i1_i => wb_en_i1_in_s,
		rs1_i2_i => rs1_i2_in_s,
		rs1_i2_addr_i => rs1_i2_addr_in_s,
		rs2_i2_i => rs2_i2_in_s,
		rs2_i2_addr_i => rs2_i2_addr_in_s,
		rd_i2_i => rd_i2_in_s,
		opcode_i2_i => opcode_i2_in_s,
		funct3_i2_i => funct3_i2_in_s,
		funct7_i2_i => funct7_i2_in_s,
		imm_i2_i => imm_i2_in_s,
		wb_en_i2_i => wb_en_i2_in_s,
		data_mem_wr_en_i2_i => data_mem_wr_en_i2_in_s,
		data_mem_rd_en_i2_i => data_mem_rd_en_i2_in_s,
		alu_res_i1_o => alu_res_i1_out_s,
		jmp_addr_alu_res_o => jmp_addr_alu_res_out_s,
		wb_en_i1_o => wb_en_i1_out_s,
		rd_i1_o => rd_i1_out_s,
		zero_i1_o => zero_i1_out_s,
		lt_i1_o => lt_i1_out_s,
		alu_res_i2_o => alu_res_i2_out_s,
		wb_en_i2_o => wb_en_i2_out_s,
		rd_i2_o => rd_i2_out_s,
		funct3_i2_o => funct3_i2_out_s,
		mem_data_i2_o => mem_data_i2_out_s,
		data_mem_wr_en_i2_o => data_mem_wr_en_i2_out_s,
		data_mem_rd_en_i2_o => data_mem_rd_en_i2_out_s,
		wb_rd_data_i1_i => wb_rd_data_i1_in_s,
		wb_rd_addr_i1_i => wb_rd_addr_i1_in_s,
		wb_rd_en_i1_i => wb_rd_en_i1_in_s,
		wb_rd_data_i2_i => wb_rd_data_i2_in_s,
		wb_rd_addr_i2_i => wb_rd_addr_i2_in_s,
		wb_rd_en_i2_i => wb_rd_en_i2_in_s
	);

	rst_in_s <= '0' after 20 ns;

	process
	begin
		clk_in_s <= not clk_in_s;
		wait for 5 ns;
	end process;

end architecture;
