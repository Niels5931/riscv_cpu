library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;

entity di_ins_exe is

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
end entity;

architecture rtl of di_ins_exe is

	component ins_exe
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
		alu_res_none_pipe_o : out std_logic_vector(31 downto 0);
		alu_res_o : out std_logic_vector(31 downto 0);
		mem_data_o : out std_logic_vector(31 downto 0); -- register to be stored in memory
		funct3_o : out std_logic_vector(2 downto 0); -- for byte/halfword/word
		rd_o : out std_logic_vector(4 downto 0); -- destination register
		---------------------
		-- WRITE BACK INPUTS --
		---------------------
		wb_rd_data_i : in std_logic_vector(31 downto 0) -- data forwarding from write back stage
	);
	end component;

	constant gnd : std_logic := '0';

	-- outputs from ins_exe modules
	signal zero_i1_s : std_logic;
	signal lt_i1_s : std_logic;
	signal alu_res_i1_reg : std_logic_vector(31 downto 0);
	signal wb_en_i1_reg : std_logic;
	signal funct3_i1_reg : std_logic_vector(2 downto 0);
	signal rd_i1_reg : std_logic_vector(4 downto 0);

	signal alu_res_i2_reg : std_logic_vector(31 downto 0);
	signal wb_en_i2_reg : std_logic;
	signal funct3_i2_reg : std_logic_vector(2 downto 0);
	signal rd_i2_reg : std_logic_vector(4 downto 0);
	signal mem_data_i2_reg : std_logic_vector(31 downto 0);
	signal data_mem_wr_en_i2_reg : std_logic;
	signal data_mem_rd_en_i2_reg : std_logic;

	-- cross data forwarding
	signal rs1_i1_s : std_logic_vector(31 downto 0);
	signal rs1_i1_addr_s : std_logic_vector(4 downto 0);
	signal rs2_i1_s : std_logic_vector(31 downto 0);
	signal rs2_i1_addr_s : std_logic_vector(4 downto 0);

	signal rs1_i2_s : std_logic_vector(31 downto 0);
	signal rs1_i2_addr_s : std_logic_vector(4 downto 0);
	signal rs2_i2_s : std_logic_vector(31 downto 0);
	signal rs2_i2_addr_s : std_logic_vector(4 downto 0);

	-- jump alu
	signal jmp_addr_alu_res_s : std_logic_vector(31 downto 0);

begin

	-- instantiate ins_exe modules
	ins_exe_i1: ins_exe
	port map (
		clk_i => clk_i,
		rst_i => rst_i,
		---------------------
		opcode_i => opcode_i1_i,
		rs1_i => rs1_i1_s,
		rs1_addr_i => rs1_i1_addr_i,
		rs2_i => rs2_i1_s,
		rs2_addr_i => rs2_i1_addr_i,
		rd_i => rd_i1_i,
		pc_i => pc_i,
		funct3_i => funct3_i1_i,
		funct7_i => funct7_i1_i,
		imm_i => imm_i1_i,
		wb_en_i => wb_en_i1_i,
		data_mem_wr_en_i => gnd,
		data_mem_rd_en_i => gnd,
		---------------------
		zero_o => zero_i1_s,
		lt_o => lt_i1_s,
		---------------------
		data_mem_wr_en_o => open,
		data_mem_rd_en_o => open,
		wb_en_o => wb_en_i1_reg,
		alu_res_none_pipe_o => open,
		alu_res_o => alu_res_i1_reg,
		mem_data_o => open,
		funct3_o => funct3_i1_reg,
		rd_o => rd_i1_reg,
		---------------------
		wb_rd_data_i => wb_rd_data_i1_i
	);

	ins_exe_i2: ins_exe
	port map (
		clk_i => clk_i,
		rst_i => rst_i,
		---------------------
		opcode_i => opcode_i2_i,
		rs1_i => rs1_i2_s,
		rs1_addr_i => rs1_i2_addr_i,
		rs2_i => rs2_i2_s,
		rs2_addr_i => rs2_i2_addr_i,
		rd_i => rd_i2_i,
		pc_i => pc_i,
		funct3_i => funct3_i2_i,
		funct7_i => funct7_i2_i,
		imm_i => imm_i2_i,
		wb_en_i => wb_en_i2_i,
		data_mem_wr_en_i => data_mem_wr_en_i2_i,
		data_mem_rd_en_i => data_mem_rd_en_i2_i,
		---------------------
		zero_o => open,
		lt_o => open,
		---------------------
		data_mem_wr_en_o => data_mem_wr_en_i2_reg,
		data_mem_rd_en_o => data_mem_rd_en_i2_reg,
		wb_en_o => wb_en_i2_reg,
		alu_res_none_pipe_o => open,
		alu_res_o => alu_res_i2_reg,
		mem_data_o => mem_data_i2_reg,
		funct3_o => funct3_i2_reg,
		rd_o => rd_i2_reg,
		---------------------
		wb_rd_data_i => wb_rd_data_i2_i
	);

	-- cross data forwarding
	process(all)
	begin
		rs1_i1_s <= rs1_i1_i;
		rs1_i1_addr_s <= rs1_i1_addr_i;
		rs2_i1_s <= rs2_i1_i;
		rs2_i1_addr_s <= rs2_i1_addr_i;

		rs1_i2_s <= rs1_i2_i;
		rs1_i2_addr_s <= rs1_i2_addr_i;
		rs2_i2_s <= rs2_i2_i;
		rs2_i2_addr_s <= rs2_i2_addr_i;

		if rs1_i1_addr_i = rd_i2_reg and wb_en_i2_reg = '1' and rd_i2_reg /= "00000" then
			rs1_i1_s <= alu_res_i2_reg;
		elsif rs1_i1_addr_i = wb_rd_addr_i2_i and wb_rd_en_i2_i = '1' and wb_rd_addr_i2_i /= "00000" then
			rs1_i1_s <= wb_rd_data_i2_i;
		end if;
		if rs2_i1_addr_i = rd_i2_reg and wb_en_i2_reg = '1' and rd_i2_reg /= "00000" then
			rs2_i1_s <= alu_res_i2_reg;
		elsif rs2_i1_addr_i = wb_rd_addr_i2_i and wb_rd_en_i2_i = '1' and wb_rd_addr_i2_i /= "00000" then
			rs2_i1_s <= wb_rd_data_i2_i;
		end if;
		if rs1_i2_addr_i = rd_i1_reg and wb_en_i1_reg = '1' and rd_i1_reg /= "00000" then
			rs1_i2_s <= alu_res_i1_reg;
		elsif rs1_i2_addr_i = wb_rd_addr_i1_i and wb_rd_en_i1_i = '1' and wb_rd_addr_i1_i /= "00000" then
			rs1_i2_s <= wb_rd_data_i1_i;
		end if;
		if rs2_i2_addr_i = rd_i1_reg and wb_en_i1_reg = '1' and rd_i1_reg /= "00000" then
			rs2_i2_s <= alu_res_i1_reg;
		elsif rs2_i2_addr_i = wb_rd_addr_i1_i and wb_rd_en_i1_i = '1' and wb_rd_addr_i1_i /= "00000" then
			rs2_i2_s <= wb_rd_data_i1_i;
		end if;
	end process;

	-- jump alu
	process(all)
		variable jmp_addr_op1_s : std_logic_vector(31 downto 0);
		variable jmp_addr_op2_s : std_logic_vector(31 downto 0);
	begin
		jmp_addr_op1_s := pc_i;
		jmp_addr_op2_s := imm_i1_i;
		if opcode_i1_i = "1100111" then
			jmp_addr_op2_s := rs1_i1_s;
		end if;
		jmp_addr_alu_res_s <= jmp_addr_op1_s + jmp_addr_op2_s;
	end process;

	-- output assignments
	alu_res_i1_o <= alu_res_i1_reg;
	jmp_addr_alu_res_o <= jmp_addr_alu_res_s;
	wb_en_i1_o <= wb_en_i1_reg;
	rd_i1_o <= rd_i1_reg;
	zero_i1_o <= zero_i1_s;
	lt_i1_o <= lt_i1_s;

	alu_res_i2_o <= alu_res_i2_reg;
	wb_en_i2_o <= wb_en_i2_reg;
	rd_i2_o <= rd_i2_reg;
	funct3_i2_o <= funct3_i2_reg;
	mem_data_i2_o <= mem_data_i2_reg;
	data_mem_wr_en_i2_o <= data_mem_wr_en_i2_reg;
	data_mem_rd_en_i2_o <= data_mem_rd_en_i2_reg;

end architecture;
