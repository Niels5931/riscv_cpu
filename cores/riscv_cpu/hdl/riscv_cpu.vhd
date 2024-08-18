library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;

entity riscv_cpu is
generic (
	INS_START : std_logic_vector(31 downto 0) := x"00000000"
);
	port (
	clk_i : in std_logic;
	rst_i : in std_logic;
	---------------------
	-- INS MEMORY ---
	---------------------
	ins_mem_data_i : in std_logic_vector(31 downto 0);
	ins_mem_addr_o : out std_logic_vector(31 downto 0);
	---------------------
	-- DATA MEMORY ---
	---------------------
	data_mem_wr_en_o : out std_logic; -- data memory enable
	data_mem_wr_addr_o : out std_logic_vector(31 downto 0); -- data memory write address
	data_mem_wr_data_o : out std_logic_vector(31 downto 0); -- data memory write data
	data_mem_wr_byte_en_o : out std_logic_vector(3 downto 0); -- byte enable for data memory write
	data_mem_rd_en_o : out std_logic; -- data memory enable
	data_mem_rd_addr_o : out std_logic_vector(31 downto 0); -- data memory read address
	data_mem_rd_data_i : in std_logic_vector(31 downto 0) -- data memory read data
);
end entity;

architecture rtl of riscv_cpu is

	component ins_fetch
	generic (
		INS_START : std_logic_vector(31 downto 0) := x"00000000"
	);
		port (
		clk_i : in std_logic;
		rst_i : in std_logic;
		-- branch prediction logic
		jmp_addr_i : in std_logic_vector(31 downto 0);
		jmp_valid_i : in std_logic;
		-- instruction out
		ins_data_o : out std_logic_vector(31 downto 0);
		-- program counter
		pc_o : out std_logic_vector(31 downto 0);
		-- instruction mem interface
		ins_data_i : in std_logic_vector(31 downto 0);
		ins_addr_o : out std_logic_vector(31 downto 0)
	);
	end component;

	component ins_dec
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
		rs1_addr_o : out std_logic_vector(4 downto 0);
		rs2_o : out std_logic_vector(31 downto 0);
		rs2_addr_o : out std_logic_vector(4 downto 0);
		rd_o : out std_logic_vector(4 downto 0);
		pc_o : out std_logic_vector(31 downto 0);
		funct3_o : out std_logic_vector(2 downto 0);
		funct7_o : out std_logic_vector(6 downto 0);
		imm_o : out std_logic_vector(31 downto 0);
		wb_en_o : out std_logic; -- write back enable
		data_mem_wr_en_o : out std_logic; -- data memory enable
		data_mem_rd_en_o : out std_logic; -- data memory enable
		-- data forwarding stuff
		---------------------
		-- EXECUTE INPUTS --
		---------------------
		zero_i : in std_logic;
		lt_i : in std_logic; -- rs1 < rs2
		alu_res_i : in std_logic_vector(31 downto 0);
		---------------------
		-- MEMORY INPUTS --
		---------------------
		mem_data_i : in std_logic_vector(31 downto 0); 
		---------------------
		-- WRITE BACK INPUTS --
		---------------------
		reg_wr_en_i : in std_logic;
		reg_wr_addr_i : in std_logic_vector(4 downto 0);
		reg_wr_data_i : in std_logic_vector(31 downto 0);
		---------------------
		flush_o : out std_logic
	);
	end component;

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

	component ins_mem
	port (
		clk_i : in std_logic;
		rst_i : in std_logic;
		---------------------
		-- MEMORY INPUTS --
		---------------------
		data_mem_rd_en_i : in std_logic; -- data memory enable
		data_mem_wr_en_i : in std_logic; -- data memory enable
		wb_en_i : in std_logic; -- write back enable
		alu_res_i : in std_logic_vector(31 downto 0); -- memory address
		mem_data_i : in std_logic_vector(31 downto 0); -- data to be stored in memory
		funct3_i : in std_logic_vector(2 downto 0); -- for byte/halfword/word
		rd_i : in std_logic_vector(4 downto 0); -- destination register
		---------------------
		-- MEMORY INTERFACE --
		---------------------
		mem_wr_en_o : out std_logic; -- memory write enable
		mem_rd_en_o : out std_logic; -- memory read enable
		mem_byte_en_o : out std_logic_vector(3 downto 0); -- byte enable
		mem_wr_addr_o : out std_logic_vector(31 downto 0); -- memory write address
		mem_rd_addr_o : out std_logic_vector(31 downto 0); -- memory read address
		mem_wr_data_o : out std_logic_vector(31 downto 0); -- memory write data
		mem_rd_data_i : in std_logic_vector(31 downto 0); -- memory read data
		---------------------
		-- WRITE BACK OUTPUTS --
		---------------------
		wb_data_o : out std_logic_vector(31 downto 0); -- data forwarding to write back stage
		wb_addr_o : out std_logic_vector(4 downto 0); -- destination register
		wb_en_o : out std_logic -- write back enable
	);
	end component;

	signal ins_fecth_ins_data_s : std_logic_vector(31 downto 0);	
	signal ins_fecth_pc_s : std_logic_vector(31 downto 0);
	signal ins_fetch_addr_s : std_logic_vector(31 downto 0);

	signal ins_dec_jmp_addr_s : std_logic_vector(31 downto 0);
	signal ins_dec_jmp_valid_s : std_logic;
	signal ins_dec_opcode_s : std_logic_vector(6 downto 0);
	signal ins_dec_rs1_s : std_logic_vector(31 downto 0);
	signal ins_dec_rs1_addr_s : std_logic_vector(4 downto 0);
	signal ins_dec_rs2_s : std_logic_vector(31 downto 0);
	signal ins_dec_rs2_addr_s : std_logic_vector(4 downto 0);
	signal ins_dec_rd_s : std_logic_vector(4 downto 0);
	signal ins_dec_pc_s : std_logic_vector(31 downto 0);
	signal ins_dec_funct3_s : std_logic_vector(2 downto 0);
	signal ins_dec_funct7_s : std_logic_vector(6 downto 0);
	signal ins_dec_imm_s : std_logic_vector(31 downto 0);
	signal ins_dec_wb_en_s : std_logic;
	signal ins_dec_data_mem_wr_en_s : std_logic;
	signal ins_dec_data_mem_rd_en_s : std_logic;
	signal ins_dec_flush_s : std_logic;

	signal ins_exe_zero_s : std_logic;
	signal ins_exe_lt_s : std_logic;
	signal ins_exe_data_mem_wr_en_s : std_logic;
	signal ins_exe_data_mem_rd_en_s : std_logic;
	signal ins_exe_wb_en_s : std_logic;
	signal ins_exe_alu_res_s : std_logic_vector(31 downto 0);
	signal ins_exe_alu_res_none_pipe_s : std_logic_vector(31 downto 0);
	signal ins_exe_mem_data_s : std_logic_vector(31 downto 0);
	signal ins_exe_funct3_s : std_logic_vector(2 downto 0);
	signal ins_exe_rd_s : std_logic_vector(4 downto 0);

	signal ins_mem_mem_wr_en_s : std_logic;
	signal ins_mem_mem_rd_en_s : std_logic;
	signal ins_mem_mem_byte_en_s : std_logic_vector(3 downto 0);
	signal ins_mem_mem_wr_addr_s : std_logic_vector(31 downto 0);
	signal ins_mem_mem_rd_addr_s : std_logic_vector(31 downto 0);
	signal ins_mem_mem_wr_data_s : std_logic_vector(31 downto 0);
	signal ins_mem_mem_rd_data_s : std_logic_vector(31 downto 0);
	signal ins_mem_wb_data_s : std_logic_vector(31 downto 0);
	signal ins_mem_wb_addr_s : std_logic_vector(4 downto 0);
	signal ins_mem_wb_en_s : std_logic;

	signal flush_rst_s : std_logic;

begin

	flush_rst_s <= rst_i or ins_dec_flush_s;

	ins_fetch_i0 : ins_fetch
	generic map (
		INS_START => INS_START
	)
	port map (
		clk_i => clk_i,
		rst_i => rst_i,
		jmp_addr_i => ins_dec_jmp_addr_s,
		jmp_valid_i => ins_dec_jmp_valid_s,
		ins_data_o => ins_fecth_ins_data_s,
		pc_o => ins_fecth_pc_s,
		ins_data_i => ins_mem_data_i,
		ins_addr_o => ins_mem_addr_o
	);

	ins_dec_i0 : ins_dec
	port map (
		clk_i => clk_i,
		rst_i => rst_i,
		ins_data_i => ins_fecth_ins_data_s,
		pc_i => ins_fecth_pc_s,
		jmp_addr_o => ins_dec_jmp_addr_s,
		jmp_valid_o => ins_dec_jmp_valid_s,
		opcode_o => ins_dec_opcode_s,
		rs1_o => ins_dec_rs1_s,
		rs1_addr_o => ins_dec_rs1_addr_s,
		rs2_o => ins_dec_rs2_s,
		rs2_addr_o => ins_dec_rs2_addr_s,
		rd_o => ins_dec_rd_s,
		pc_o => ins_dec_pc_s,
		funct3_o => ins_dec_funct3_s,
		funct7_o => ins_dec_funct7_s,
		imm_o => ins_dec_imm_s,
		wb_en_o => ins_dec_wb_en_s,
		data_mem_wr_en_o => ins_dec_data_mem_wr_en_s,
		data_mem_rd_en_o => ins_dec_data_mem_rd_en_s,
		zero_i => ins_exe_zero_s,
		lt_i => ins_exe_lt_s,
		alu_res_i => ins_exe_alu_res_none_pipe_s,
		mem_data_i => ins_mem_mem_wr_data_s,
		reg_wr_en_i => ins_mem_wb_en_s,
		reg_wr_addr_i => ins_mem_wb_addr_s,
		reg_wr_data_i => ins_mem_wb_data_s,
		flush_o => ins_dec_flush_s
	);

	ins_exe_i0 : ins_exe
	port map (
		clk_i => clk_i,
		rst_i => flush_rst_s,
		opcode_i => ins_dec_opcode_s,
		rs1_i => ins_dec_rs1_s,
		rs1_addr_i => ins_dec_rs1_addr_s,
		rs2_i => ins_dec_rs2_s,
		rs2_addr_i => ins_dec_rs2_addr_s,
		rd_i => ins_dec_rd_s,
		pc_i => ins_dec_pc_s,
		funct3_i => ins_dec_funct3_s,
		funct7_i => ins_dec_funct7_s,
		imm_i => ins_dec_imm_s,
		wb_en_i => ins_dec_wb_en_s,
		data_mem_wr_en_i => ins_dec_data_mem_wr_en_s,
		data_mem_rd_en_i => ins_dec_data_mem_rd_en_s,
		zero_o => ins_exe_zero_s,
		lt_o => ins_exe_lt_s,
		data_mem_wr_en_o => ins_exe_data_mem_wr_en_s,
		data_mem_rd_en_o => ins_exe_data_mem_rd_en_s,
		wb_en_o => ins_exe_wb_en_s,
		alu_res_o => ins_exe_alu_res_s,
		alu_res_none_pipe_o => ins_exe_alu_res_none_pipe_s,
		mem_data_o => ins_exe_mem_data_s,
		funct3_o => ins_exe_funct3_s,
		rd_o => ins_exe_rd_s,
		wb_rd_data_i => ins_mem_wb_data_s
	);

	ins_mem_i0 : ins_mem
	port map (
		clk_i => clk_i,
		rst_i => rst_i,
		data_mem_rd_en_i => ins_exe_data_mem_rd_en_s,
		data_mem_wr_en_i => ins_exe_data_mem_wr_en_s,
		wb_en_i => ins_exe_wb_en_s,
		alu_res_i => ins_exe_alu_res_s,
		mem_data_i => ins_exe_mem_data_s,
		funct3_i => ins_exe_funct3_s,
		rd_i => ins_exe_rd_s,
		mem_wr_en_o => data_mem_wr_en_o,
		mem_rd_en_o => data_mem_rd_en_o,
		mem_byte_en_o => data_mem_wr_byte_en_o,
		mem_wr_addr_o => data_mem_wr_addr_o,
		mem_rd_addr_o => data_mem_rd_addr_o,
		mem_wr_data_o => ins_mem_mem_wr_data_s,
		mem_rd_data_i => data_mem_rd_data_i,
		wb_data_o => ins_mem_wb_data_s,
		wb_addr_o => ins_mem_wb_addr_s,
		wb_en_o => ins_mem_wb_en_s
	);

	data_mem_wr_data_o <= ins_mem_mem_wr_data_s;

end architecture;
