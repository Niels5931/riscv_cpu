library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;

entity ins_fetch is
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
end entity;

architecture rtl of ins_fetch is

	signal pc_reg : std_logic_vector(31 downto 0);
	signal pc_next : std_logic_vector(31 downto 0);

	signal ins_addr_s : std_logic_vector(31 downto 0);
	
	-- pipeline output reigsters
	signal ins_addr_reg : std_logic_vector(31 downto 0);

begin

	pc_next <= jmp_addr_i + 4 when jmp_valid_i = '1' else pc_reg + 4;
	ins_addr_s <= jmp_addr_i when jmp_valid_i = '1' else pc_reg; 

	-- program counter
	process(clk_i, rst_i)
	begin
		if rising_edge(clk_i) then
			if rst_i = '1' then
				pc_reg <= INS_START;
			else
				pc_reg <= pc_next;
			end if;
		end if;
	end process;

	process(clk_i, rst_i)
	begin
		if rising_edge(clk_i) then
			if rst_i = '1' then
				ins_addr_reg <= (others => '0');
			else
				ins_addr_reg <= ins_addr_s;
			end if;
		end if;
	end process;

	ins_addr_o <= ins_addr_s;
	ins_data_o <= ins_data_i;
	pc_o <= ins_addr_reg;

end architecture;
