library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity di_riscv_cpu is
generic (
	INS_START : std_logic_vector(31 downto 0) := x"00000000"
);
port (
	clk_i : in std_logic;
	rst_i : in std_logic;
	---------------------
	ins_mem_data_i : in std_logic_vector(63 downto 0);
	ins_mem_addr_o : out std_logic_vector(31 downto 0);
	---------------------
	data_mem_wr_en_o : out std_logic;
	data_mem_wr_data_o : out std_logic_vector(31 downto 0);
	data_mem_wr_addr_o : out std_logic_vector(31 downto 0);
	data_mem_wr_byte_en_o : out std_logic_vector(3 downto 0);
	data_mem_rd_en_o : out std_logic;
	data_mem_rd_addr_o : out std_logic_vector(31 downto 0);
	data_mem_rd_data_i : in std_logic_vector(31 downto 0)
);
end entity;

architecture rtl of di_riscv_cpu is

	component di_ins_fetch_dec
	generic (
		INS_START : std_logic_vector(31 downto 0) := x"00000000"
	);
	port (
		clk_i : in std_logic;
		rst_i : in std_logic;
		-- program counter
		pc_o : out std_logic_vector(31 downto 0);
		-- instruction mem interface
		ins_mem_data_i : in std_logic_vector(63 downto 0);
		ins_mem_addr_o : out std_logic_vector(31 downto 0);
		-- decoded instruction out
		opcode_i1_o : out std_logic_vector(6 downto 0);
		rs1_i1_o : out std_logic_vector(31 downto 0);
		rs1_i1_addr_o : out std_logic_vector(4 downto 0);
		rs2_i1_o : out std_logic_vector(31 downto 0);
		rs2_i1_addr_o : out std_logic_vector(4 downto 0);
		rd_i1_o : out std_logic_vector(4 downto 0);
		funct3_i1_o : out std_logic_vector(2 downto 0);
		funct7_i1_o : out std_logic_vector(6 downto 0);
		imm_i1_o : out std_logic_vector(31 downto 0);
		wb_i1_o : out std_logic;
		opcode_i2_o : out std_logic_vector(6 downto 0);
		rs1_i2_o : out std_logic_vector(31 downto 0);
		rs1_i2_addr_o : out std_logic_vector(4 downto 0);
		rs2_i2_o : out std_logic_vector(31 downto 0);
		rs2_i2_addr_o : out std_logic_vector(4 downto 0);
		rd_i2_o : out std_logic_vector(4 downto 0);
		funct3_i2_o : out std_logic_vector(2 downto 0);
		funct7_i2_o : out std_logic_vector(6 downto 0);
		imm_i2_o : out std_logic_vector(31 downto 0);
		wb_i2_o : out std_logic;
		data_mem_wr_en_i2_o : out std_logic;
		data_mem_rd_en_i2_o : out std_logic;
		-- execution stage input for branch prediction
		zero_i1_i : in std_logic;
		lt_i1_i : in std_logic;
		alu_res_i1_i : in std_logic_vector(31 downto 0);
		mem_data_i1_i : in std_logic_vector(31 downto 0); -- alu result on clock cycle later
		-- write back input
		reg_wr_en_i1_i : in std_logic;
		reg_wr_addr_i1_i : in std_logic_vector(4 downto 0);
		reg_wr_data_i1_i : in std_logic_vector(31 downto 0);
		reg_wr_en_i2_i : in std_logic;
		reg_wr_addr_i2_i : in std_logic_vector(4 downto 0);
		reg_wr_data_i2_i : in std_logic_vector(31 downto 0);
		-- flush pipeline
		flush_o : out std_logic
	);
	end component;

	component di_ins_exe
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

	component di_ins_mem
	port (
		clk_i : in std_logic;
		rst_i : in std_logic;
		---------------------
		wb_en_i1_i : in std_logic; -- write back enable
		alu_res_i1_i : in std_logic_vector(31 downto 0); -- memory address
		rd_i1_i : in std_logic_vector(4 downto 0); -- destination register
		---------------------
		wb_en_i2_i : in std_logic; -- write back enable
		alu_res_i2_i : in std_logic_vector(31 downto 0); -- memory address
		rd_i2_i : in std_logic_vector(4 downto 0); -- destination register
		data_mem_rd_en_i2_i : in std_logic; -- data memory enable
		data_mem_wr_en_i2_i : in std_logic; -- data memory enable
		mem_data_i2_i : in std_logic_vector(31 downto 0); -- data to be stored in memory
		funct3_i2_i : in std_logic_vector(2 downto 0); -- for byte/halfword/word;
		---------------------
		mem_wr_en_o : out std_logic; -- memory write enable
		mem_rd_en_o : out std_logic; -- memory read enable
		mem_byte_en_o : out std_logic_vector(3 downto 0); -- byte enable
		mem_wr_addr_o : out std_logic_vector(31 downto 0); -- memory write address
		mem_rd_addr_o : out std_logic_vector(31 downto 0); -- memory read address
		mem_wr_data_o : out std_logic_vector(31 downto 0); -- memory write data
		mem_rd_data_i : in std_logic_vector(31 downto 0); -- memory read data
		---------------------
		wb_data_i1_o : out std_logic_vector(31 downto 0); -- data forwarding to write back stage
		wb_addr_i1_o : out std_logic_vector(4 downto 0); -- destination register
		wb_en_i1_o : out std_logic; -- write back enable
		---------------------
		wb_data_i2_o : out std_logic_vector(31 downto 0); -- data forwarding to write back stage
		wb_addr_i2_o : out std_logic_vector(4 downto 0); -- destination register
		wb_en_i2_o : out std_logic -- write back enable
	);
	end component;

	signal ins_dec_pc_s : std_logic_vector(31 downto 0);
	signal ins_dec_mem_addr_s : std_logic_vector(31 downto 0);
	signal ins_dec_opcode_i1_s : std_logic_vector(6 downto 0);
	signal ins_dec_rs1_i1_s : std_logic_vector(31 downto 0);
	signal ins_dec_rs1_i1_addr_s : std_logic_vector(4 downto 0);
	signal ins_dec_rs2_i1_s : std_logic_vector(31 downto 0);
	signal ins_dec_rs2_i1_addr_s : std_logic_vector(4 downto 0);
	signal ins_dec_rd_i1_s : std_logic_vector(4 downto 0);
	signal ins_dec_funct3_i1_s : std_logic_vector(2 downto 0);
	signal ins_dec_funct7_i1_s : std_logic_vector(6 downto 0);
	signal ins_dec_imm_i1_s : std_logic_vector(31 downto 0);
	signal ins_dec_wb_i1_s : std_logic;
	signal ins_dec_opcode_i2_s : std_logic_vector(6 downto 0);
	signal ins_dec_rs1_i2_s : std_logic_vector(31 downto 0);
	signal ins_dec_rs1_i2_addr_s : std_logic_vector(4 downto 0);
	signal ins_dec_rs2_i2_s : std_logic_vector(31 downto 0);
	signal ins_dec_rs2_i2_addr_s : std_logic_vector(4 downto 0);
	signal ins_dec_rd_i2_s : std_logic_vector(4 downto 0);
	signal ins_dec_funct3_i2_s : std_logic_vector(2 downto 0);
	signal ins_dec_funct7_i2_s : std_logic_vector(6 downto 0);
	signal ins_dec_imm_i2_s : std_logic_vector(31 downto 0);
	signal ins_dec_wb_i2_s : std_logic;
	signal ins_dec_data_mem_wr_en_i2_s : std_logic;
	signal ins_dec_data_mem_rd_en_i2_s : std_logic;
	signal ins_dec_flush_s : std_logic;

	signal ins_exe_alu_res_i1_s : std_logic_vector(31 downto 0);
	signal ins_exe_jmp_addr_alu_res_s : std_logic_vector(31 downto 0);
	signal ins_exe_wb_en_i1_s : std_logic;
	signal ins_exe_rd_i1_s : std_logic_vector(4 downto 0);
	signal ins_exe_zero_i1_s : std_logic;
	signal ins_exe_lt_i1_s : std_logic;
	signal ins_exe_alu_res_i2_s : std_logic_vector(31 downto 0);
	signal ins_exe_wb_en_i2_s : std_logic;
	signal ins_exe_rd_i2_s : std_logic_vector(4 downto 0);
	signal ins_exe_funct3_i2_s : std_logic_vector(2 downto 0);
	signal ins_exe_mem_data_i2_s : std_logic_vector(31 downto 0);
	signal ins_exe_data_mem_wr_en_i2_s : std_logic;
	signal ins_exe_data_mem_rd_en_i2_s : std_logic;

	signal ins_mem_mem_wr_en_s : std_logic;
	signal ins_mem_mem_rd_en_s : std_logic;
	signal ins_mem_mem_byte_en_s : std_logic_vector(3 downto 0);
	signal ins_mem_mem_wr_addr_s : std_logic_vector(31 downto 0);
	signal ins_mem_mem_rd_addr_s : std_logic_vector(31 downto 0);
	signal ins_mem_mem_wr_data_s : std_logic_vector(31 downto 0);
	signal ins_mem_wb_data_i1_s : std_logic_vector(31 downto 0);
	signal ins_mem_wb_addr_i1_s : std_logic_vector(4 downto 0);
	signal ins_mem_wb_en_i1_s : std_logic;
	signal ins_mem_wb_data_i2_s : std_logic_vector(31 downto 0);
	signal ins_mem_wb_addr_i2_s : std_logic_vector(4 downto 0);
	signal ins_mem_wb_en_i2_s : std_logic;

begin

	-- instruction fetch and decode
	ins_fetch_dec_i : di_ins_fetch_dec
	generic map (
		INS_START => INS_START
	) port map (
		clk_i => clk_i,
		rst_i => rst_i,
		pc_o => ins_dec_pc_s,
		ins_mem_data_i => ins_mem_data_i,
		ins_mem_addr_o => ins_mem_addr_o,
		opcode_i1_o => ins_dec_opcode_i1_s,
		rs1_i1_o => ins_dec_rs1_i1_s,
		rs1_i1_addr_o => ins_dec_rs1_i1_addr_s,
		rs2_i1_o => ins_dec_rs2_i1_s,
		rs2_i1_addr_o => ins_dec_rs2_i1_addr_s,
		rd_i1_o => ins_dec_rd_i1_s,
		funct3_i1_o => ins_dec_funct3_i1_s,
		funct7_i1_o => ins_dec_funct7_i1_s,
		imm_i1_o => ins_dec_imm_i1_s,
		wb_i1_o => ins_dec_wb_i1_s,
		opcode_i2_o => ins_dec_opcode_i2_s,
		rs1_i2_o => ins_dec_rs1_i2_s,
		rs1_i2_addr_o => ins_dec_rs1_i2_addr_s,
		rs2_i2_o => ins_dec_rs2_i2_s,
		rs2_i2_addr_o => ins_dec_rs2_i2_addr_s,
		rd_i2_o => ins_dec_rd_i2_s,
		funct3_i2_o => ins_dec_funct3_i2_s,
		funct7_i2_o => ins_dec_funct7_i2_s,
		imm_i2_o => ins_dec_imm_i2_s,
		wb_i2_o => ins_dec_wb_i2_s,
		data_mem_wr_en_i2_o => ins_dec_data_mem_wr_en_i2_s,
		data_mem_rd_en_i2_o => ins_dec_data_mem_rd_en_i2_s,
		zero_i1_i => ins_exe_zero_i1_s,
		lt_i1_i => ins_exe_lt_i1_s,
		alu_res_i1_i => ins_exe_alu_res_i1_s,
		mem_data_i1_i => ins_exe_mem_data_i2_s,
		reg_wr_en_i1_i => ins_mem_wb_en_i1_s,
		reg_wr_addr_i1_i => ins_mem_wb_addr_i1_s,
		reg_wr_data_i1_i => ins_mem_wb_data_i1_s,
		reg_wr_en_i2_i => ins_mem_wb_en_i2_s,
		reg_wr_addr_i2_i => ins_mem_wb_addr_i2_s,
		reg_wr_data_i2_i => ins_mem_wb_data_i2_s,
		flush_o => ins_dec_flush_s
	);

	-- instruction execute
	ins_exe_i : di_ins_exe
	port map (
		clk_i => clk_i,
		rst_i => rst_i,
		pc_i => ins_dec_pc_s,
		rs1_i1_i => ins_dec_rs1_i1_s,
		rs1_i1_addr_i => ins_dec_rs1_i1_addr_s,
		rs2_i1_i => ins_dec_rs2_i1_s,
		rs2_i1_addr_i => ins_dec_rs2_i1_addr_s,
		rd_i1_i => ins_dec_rd_i1_s,
		opcode_i1_i => ins_dec_opcode_i1_s,
		funct3_i1_i => ins_dec_funct3_i1_s,
		funct7_i1_i => ins_dec_funct7_i1_s,
		imm_i1_i => ins_dec_imm_i1_s,
		wb_en_i1_i => ins_dec_wb_i1_s,
		rs1_i2_i => ins_dec_rs1_i2_s,
		rs1_i2_addr_i => ins_dec_rs1_i2_addr_s,
		rs2_i2_i => ins_dec_rs2_i2_s,
		rs2_i2_addr_i => ins_dec_rs2_i2_addr_s,
		rd_i2_i => ins_dec_rd_i2_s,
		opcode_i2_i => ins_dec_opcode_i2_s,
		funct3_i2_i => ins_dec_funct3_i2_s,
		funct7_i2_i => ins_dec_funct7_i2_s,
		imm_i2_i => ins_dec_imm_i2_s,
		wb_en_i2_i => ins_dec_wb_i2_s,
		data_mem_wr_en_i2_i => ins_dec_data_mem_wr_en_i2_s,
		data_mem_rd_en_i2_i => ins_dec_data_mem_rd_en_i2_s,
		alu_res_i1_o => ins_exe_alu_res_i1_s,
		jmp_addr_alu_res_o => ins_exe_jmp_addr_alu_res_s,
		wb_en_i1_o => ins_exe_wb_en_i1_s,
		rd_i1_o => ins_exe_rd_i1_s,
		zero_i1_o => ins_exe_zero_i1_s,
		lt_i1_o => ins_exe_lt_i1_s,
		alu_res_i2_o => ins_exe_alu_res_i2_s,
		wb_en_i2_o => ins_exe_wb_en_i2_s,
		rd_i2_o => ins_exe_rd_i2_s,
		funct3_i2_o => ins_exe_funct3_i2_s,
		mem_data_i2_o => ins_exe_mem_data_i2_s,
		data_mem_wr_en_i2_o => ins_exe_data_mem_wr_en_i2_s,
		data_mem_rd_en_i2_o => ins_exe_data_mem_rd_en_i2_s,
		wb_rd_data_i1_i => ins_mem_wb_data_i1_s,
		wb_rd_addr_i1_i => ins_mem_wb_addr_i1_s,
		wb_rd_en_i1_i => ins_mem_wb_en_i1_s,
		wb_rd_data_i2_i => ins_mem_wb_data_i2_s,
		wb_rd_addr_i2_i => ins_mem_wb_addr_i2_s,
		wb_rd_en_i2_i => ins_mem_wb_en_i2_s
	);

	-- instruction memory
	ins_mem_i : di_ins_mem
	port map (
		clk_i => clk_i,
		rst_i => rst_i,
		wb_en_i1_i => ins_exe_wb_en_i1_s,
		alu_res_i1_i => ins_exe_alu_res_i1_s,
		rd_i1_i => ins_exe_rd_i1_s,
		wb_en_i2_i => ins_exe_wb_en_i2_s,
		alu_res_i2_i => ins_exe_alu_res_i2_s,
		rd_i2_i => ins_exe_rd_i2_s,
		data_mem_rd_en_i2_i => ins_exe_data_mem_rd_en_i2_s,
		data_mem_wr_en_i2_i => ins_exe_data_mem_wr_en_i2_s,
		mem_data_i2_i => ins_exe_mem_data_i2_s,
		funct3_i2_i => ins_exe_funct3_i2_s,
		mem_wr_en_o => data_mem_wr_en_o,
		mem_rd_en_o => data_mem_rd_en_o,
		mem_byte_en_o => data_mem_wr_byte_en_o,
		mem_wr_addr_o => data_mem_wr_addr_o,
		mem_rd_addr_o => data_mem_rd_addr_o,
		mem_wr_data_o => data_mem_wr_data_o,
		mem_rd_data_i => data_mem_rd_data_i,
		wb_data_i1_o => ins_mem_wb_data_i1_s,
		wb_addr_i1_o => ins_mem_wb_addr_i1_s,
		wb_en_i1_o => ins_mem_wb_en_i1_s,
		wb_data_i2_o => ins_mem_wb_data_i2_s,
		wb_addr_i2_o => ins_mem_wb_addr_i2_s,
		wb_en_i2_o => ins_mem_wb_en_i2_s
	);

end architecture;
