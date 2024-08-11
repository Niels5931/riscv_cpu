library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ins_fetch_tb is
end entity;

architecture rtl of ins_fetch_tb is
	
	component ins_fetch is
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

	signal clk_in_s : std_logic := '0';
	signal rst_in_s : std_logic := '1';
	signal jmp_addr_in_s : std_logic_vector(31 downto 0) := (others => '0');
	signal jmp_valid_in_s : std_logic := '0';
	signal ins_data_in_s : std_logic_vector(31 downto 0) := (others => '0');
	signal ins_addr_out_s : std_logic_vector(31 downto 0);
	signal ins_data_out_s : std_logic_vector(31 downto 0);
	signal pc_out_s : std_logic_vector(31 downto 0);

begin

	ins_fetch_inst : ins_fetch
	port map (
		clk_i => clk_in_s,
		rst_i => rst_in_s,
		jmp_addr_i => jmp_addr_in_s,
		jmp_valid_i => jmp_valid_in_s,
		ins_data_o => ins_data_out_s,
		pc_o => pc_out_s,
		ins_data_i => ins_data_in_s,
		ins_addr_o => ins_addr_out_s
	);

	rst_in_s <= '0' after 20 ns;

	process
	begin
		clk_in_s <= not clk_in_s;
		wait for 5 ns;
	end process;


	process
	begin
		wait for 50ns;
		jmp_addr_in_s <= x"00000500";
		jmp_valid_in_s <= '1';
		wait for 10 ns;
		jmp_valid_in_s <= '0';
	end process;

	process
	begin
		wait for 100ns;
		std.env.stop(0);
	end process;

	process
	begin
		wait until rising_edge(clk_in_s);
		report "PC: " & to_hstring(unsigned(pc_out_s));
		report "INS ADDR: " & to_hstring(unsigned(ins_addr_out_s));
	end process;

end architecture;