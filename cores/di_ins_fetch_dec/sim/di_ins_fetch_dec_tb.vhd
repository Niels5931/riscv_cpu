library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use STD.textio.all;


entity di_ins_fetch_dec_tb is
end entity;

architecture rtl of di_ins_fetch_dec_tb is

	function to_std_logic_vector (a: string) return std_logic_vector is
		variable size : integer := a'length*4;
		variable res: std_logic_vector(size-1 downto 0);	
	begin
		for i in size/4 downto 1 loop
			if a(i) = '0' then
				res(size-(i-1)*4-1 downto size-(i-1)*4-4) := "0000";
			elsif a(i) = '1' then
				res(size-(i-1)*4-1 downto size-(i-1)*4-4) := "0001";
			elsif a(i) = '2' then
				res(size-(i-1)*4-1 downto size-(i-1)*4-4) := "0010";
			elsif a(i) = '3' then
				res(size-(i-1)*4-1 downto size-(i-1)*4-4) := "0011";
			elsif a(i) = '4' then
				res(size-(i-1)*4-1 downto size-(i-1)*4-4) := "0100";
			elsif a(i) = '5' then
				res(size-(i-1)*4-1 downto size-(i-1)*4-4) := "0101";
			elsif a(i) = '6' then
				res(size-(i-1)*4-1 downto size-(i-1)*4-4) := "0110";
			elsif a(i) = '7' then
				res(size-(i-1)*4-1 downto size-(i-1)*4-4) := "0111";
			elsif a(i) = '8' then
				res(size-(i-1)*4-1 downto size-(i-1)*4-4) := "1000";
			elsif a(i) = '9' then
				res(size-(i-1)*4-1 downto size-(i-1)*4-4) := "1001";
			elsif a(i) = 'a' then
				res(size-(i-1)*4-1 downto size-(i-1)*4-4) := "1010";
			elsif a(i) = 'b' then
				res(size-(i-1)*4-1 downto size-(i-1)*4-4) := "1011";
			elsif a(i) = 'c' then
				res(size-(i-1)*4-1 downto size-(i-1)*4-4) := "1100";
			elsif a(i) = 'd' then
				res(size-(i-1)*4-1 downto size-(i-1)*4-4) := "1101";
			elsif a(i) = 'e' then
				res(size-(i-1)*4-1 downto size-(i-1)*4-4) := "1110";
			elsif a(i) = 'f' then
				res(size-(i-1)*4-1 downto size-(i-1)*4-4) := "1111";
			end if;
		end loop;
		return res;
	end function;
	
	component di_ins_fetch_dec is
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
	type arr is array (natural range <>) of std_logic_vector;
	signal ins_mem_arr : arr(0 to 1024)(63 downto 0);	

	signal clk_in_s:  std_logic := '0';
	signal rst_in_s:  std_logic := '1';
	signal pc_out_s:  std_logic_vector(31 downto 0);
	signal ins_mem_data_in_s:  std_logic_vector(63 downto 0);
	signal ins_mem_addr_out_s:  std_logic_vector(31 downto 0);
	signal opcode_i1_out_s:  std_logic_vector(6 downto 0);
	signal rs1_i1_out_s:  std_logic_vector(31 downto 0);
	signal rs1_i1_addr_out_s:  std_logic_vector(4 downto 0);
	signal rs2_i1_out_s:  std_logic_vector(31 downto 0);
	signal rs2_i1_addr_out_s:  std_logic_vector(4 downto 0);
	signal rd_i1_out_s:  std_logic_vector(4 downto 0);
	signal funct3_i1_out_s:  std_logic_vector(2 downto 0);
	signal funct7_i1_out_s:  std_logic_vector(6 downto 0);
	signal imm_i1_out_s:  std_logic_vector(31 downto 0);
	signal wb_i1_out_s:  std_logic;
	signal opcode_i2_out_s:  std_logic_vector(6 downto 0);
	signal rs1_i2_out_s:  std_logic_vector(31 downto 0);
	signal rs1_i2_addr_out_s:  std_logic_vector(4 downto 0);
	signal rs2_i2_out_s:  std_logic_vector(31 downto 0);
	signal rs2_i2_addr_out_s:  std_logic_vector(4 downto 0);
	signal rd_i2_out_s:  std_logic_vector(4 downto 0);
	signal funct3_i2_out_s:  std_logic_vector(2 downto 0);
	signal funct7_i2_out_s:  std_logic_vector(6 downto 0);
	signal imm_i2_out_s:  std_logic_vector(31 downto 0);
	signal wb_i2_out_s:  std_logic;
	signal data_mem_wr_en_i2_out_s:  std_logic;
	signal data_mem_rd_en_i2_out_s:  std_logic;
	signal zero_i1_in_s:  std_logic;
	signal lt_i1_in_s:  std_logic;
	signal alu_res_i1_in_s:  std_logic_vector(31 downto 0);
	signal mem_data_i1_in_s:  std_logic_vector(31 downto 0);
	signal reg_wr_en_i1_in_s:  std_logic;
	signal reg_wr_addr_i1_in_s:  std_logic_vector(4 downto 0);
	signal reg_wr_data_i1_in_s:  std_logic_vector(31 downto 0);
	signal reg_wr_en_i2_in_s:  std_logic;
	signal reg_wr_addr_i2_in_s:  std_logic_vector(4 downto 0);
	signal reg_wr_data_i2_in_s:  std_logic_vector(31 downto 0);
	signal flush_out_s:  std_logic;

begin

	DUT: di_ins_fetch_dec port map (
		clk_i => clk_in_s,
		rst_i => rst_in_s,
		pc_o => pc_out_s,
		ins_mem_data_i => ins_mem_data_in_s,
		ins_mem_addr_o => ins_mem_addr_out_s,
		opcode_i1_o => opcode_i1_out_s,
		rs1_i1_o => rs1_i1_out_s,
		rs1_i1_addr_o => rs1_i1_addr_out_s,
		rs2_i1_o => rs2_i1_out_s,
		rs2_i1_addr_o => rs2_i1_addr_out_s,
		rd_i1_o => rd_i1_out_s,
		funct3_i1_o => funct3_i1_out_s,
		funct7_i1_o => funct7_i1_out_s,
		imm_i1_o => imm_i1_out_s,
		wb_i1_o => wb_i1_out_s,
		opcode_i2_o => opcode_i2_out_s,
		rs1_i2_o => rs1_i2_out_s,
		rs1_i2_addr_o => rs1_i2_addr_out_s,
		rs2_i2_o => rs2_i2_out_s,
		rs2_i2_addr_o => rs2_i2_addr_out_s,
		rd_i2_o => rd_i2_out_s,
		funct3_i2_o => funct3_i2_out_s,
		funct7_i2_o => funct7_i2_out_s,
		imm_i2_o => imm_i2_out_s,
		wb_i2_o => wb_i2_out_s,
		data_mem_wr_en_i2_o => data_mem_wr_en_i2_out_s,
		data_mem_rd_en_i2_o => data_mem_rd_en_i2_out_s,
		zero_i1_i => zero_i1_in_s,
		lt_i1_i => lt_i1_in_s,
		alu_res_i1_i => alu_res_i1_in_s,
		mem_data_i1_i => mem_data_i1_in_s,
		reg_wr_en_i1_i => reg_wr_en_i1_in_s,
		reg_wr_addr_i1_i => reg_wr_addr_i1_in_s,
		reg_wr_data_i1_i => reg_wr_data_i1_in_s,
		reg_wr_en_i2_i => reg_wr_en_i2_in_s,
		reg_wr_addr_i2_i => reg_wr_addr_i2_in_s,
		reg_wr_data_i2_i => reg_wr_data_i2_in_s,
		flush_o => flush_out_s
	);

	process
	begin
		clk_in_s <= not clk_in_s;
		wait for 5 ns;
	end process;

	rst_in_s <= '0' after 20 ns;

	-- read instructions
	process
		file f : text open read_mode is "/home/niels/riscv_cpu/cores/di_ins_fetch_dec/sim/ins_mem.txt";
		--file f : text open read_mode is "/home/niels/dtu/sum24/riscv_cpu/cores/riscv_cpu/sim/c_function.txt";
		variable l : line;
		variable ins : string (1 to 8);
		variable idx : unsigned(0 downto 0);
		variable i : unsigned(63 downto 0) := (others => '0');
		variable k : integer := 0;
	begin
		while not endfile(f) loop
			readline(f, l);
			read(l, ins);
			ins_mem_arr(to_integer(i))(31 downto 0) <= to_std_logic_vector(ins);
			readline(f, l);
			read(l, ins);
			ins_mem_arr(to_integer(i))(63 downto 32) <= to_std_logic_vector(ins);
			i := i + 1;
			k := k + 1;
		end loop;
		for j in k to 1023 loop
			ins_mem_arr(j) <= (others => '0');
		end loop;
		wait;
	end process;

	process
	begin
		loop
			wait until rising_edge(clk_in_s) and rst_in_s = '0';
			ins_mem_data_in_s <= ins_mem_arr(to_integer(unsigned(ins_mem_addr_out_s))/8);
		end loop;
	end process;

	-- simulation
	process
		variable i : integer := 0;
	begin
		wait until rising_edge(clk_in_s) and rst_in_s = '0';
		loop
			if ins_mem_data_in_s = x"00000073" then
				exit;
			end if;
			wait until rising_edge(clk_in_s);
		end loop;
		wait for 40 ns; -- allow the last instruction to be executed
		std.env.stop(0);
	end process;

end architecture;
