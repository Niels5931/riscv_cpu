library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use STD.textio.all;

library work;
use work.types.all;

entity riscv_cpu_tb is
end entity;

architecture rtl of riscv_cpu_tb is

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

	component riscv_cpu is
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
	end component;

	signal ins_mem_arr : arr(0 to 1023)(31 downto 0);	
	signal data_mem : arr(0 to 1023)(31 downto 0);

	signal clk_in_s: std_logic := '0';
	signal rst_in_s: std_logic := '1';
	signal ins_mem_data_in_s:  std_logic_vector(31 downto 0);
	signal ins_mem_addr_out_s:  std_logic_vector(31 downto 0);
	signal data_mem_wr_en_out_s:  std_logic;
	signal data_mem_wr_addr_out_s:  std_logic_vector(31 downto 0);
	signal data_mem_wr_data_out_s:  std_logic_vector(31 downto 0);
	signal data_mem_wr_byte_en_out_s:  std_logic_vector(3 downto 0);
	signal data_mem_rd_en_out_s:  std_logic;
	signal data_mem_rd_addr_out_s:  std_logic_vector(31 downto 0);
	signal data_mem_rd_data_in_s:  std_logic_vector(31 downto 0); -- data memory read data;

	signal instr_cnt : integer := 0;

begin

	DUT: riscv_cpu port map (
		clk_i => clk_in_s,
		rst_i => rst_in_s,
		ins_mem_data_i => ins_mem_data_in_s,
		ins_mem_addr_o => ins_mem_addr_out_s,
		data_mem_wr_en_o => data_mem_wr_en_out_s,
		data_mem_wr_addr_o => data_mem_wr_addr_out_s,
		data_mem_wr_data_o => data_mem_wr_data_out_s,
		data_mem_wr_byte_en_o => data_mem_wr_byte_en_out_s,
		data_mem_rd_en_o => data_mem_rd_en_out_s,
		data_mem_rd_addr_o => data_mem_rd_addr_out_s,
		data_mem_rd_data_i => data_mem_rd_data_in_s
	);

	process
	begin
		clk_in_s <= not clk_in_s;
		wait for 5 ns;
	end process;

	rst_in_s <= '0' after 20 ns;
	
	-- read instructions
	process
		file f : text open read_mode is "/home/niels/riscv_cpu/cores/riscv_cpu/sim/ins_mem.txt";
		variable l : line;
		variable ins : string (1 to 8);
		variable i : integer := 0;
	begin
		while not endfile(f) loop
			readline(f, l);
			read(l, ins);
			ins_mem_arr(i) <= to_std_logic_vector(ins);
			i := i + 1;
		end loop;
		for j in i to 1023 loop
			ins_mem_arr(j) <= (others => '0');
		end loop;
		instr_cnt <= i;
		wait;
	end process;

	-- simulation
	process
		variable i : integer := 0;
	begin
		wait until rising_edge(clk_in_s) and rst_in_s = '0';
		while i < instr_cnt loop
			wait until rising_edge(clk_in_s);
			i := i + 1;
		end loop;
		wait for 50 ns; -- allow the last instruction to be executed
		std.env.stop(0);
	end process;

	-- instruction memory
	process
	begin
		loop
			wait until rising_edge(clk_in_s);
			ins_mem_data_in_s <= ins_mem_arr(to_integer(unsigned(ins_mem_addr_out_s))/4);
		end loop;
	end process;

	-- data memory
	process
	begin
		loop 
			wait until rising_edge(clk_in_s);
			if data_mem_wr_en_out_s = '1' then
				if data_mem_wr_byte_en_out_s = "0001" then
					data_mem(to_integer(unsigned(data_mem_wr_addr_out_s)))(7 downto 0) <= data_mem_wr_data_out_s(7 downto 0);
				elsif data_mem_wr_byte_en_out_s = "0011" then
					data_mem(to_integer(unsigned(data_mem_wr_addr_out_s)))(15 downto 0) <= data_mem_wr_data_out_s(15 downto 0);
				elsif data_mem_wr_byte_en_out_s = "1111" then
					data_mem(to_integer(unsigned(data_mem_wr_addr_out_s))) <= data_mem_wr_data_out_s;
				end if;
			end if;
			if data_mem_rd_en_out_s = '1' then
				data_mem_rd_data_in_s <= data_mem(to_integer(unsigned(data_mem_rd_addr_out_s)));
			end if;
		end loop;
	end process;


end architecture;
