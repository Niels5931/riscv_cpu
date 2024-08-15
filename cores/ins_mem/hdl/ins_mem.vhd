library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;

entity ins_mem is
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
end entity;

architecture rtl of ins_mem is

	signal mem_data_ext_s : std_logic_vector(31 downto 0); -- memory data extended to 32 bits for lb/lbu/lh/lhu
	signal mem_byte_en_s : std_logic_vector(3 downto 0); -- byte enable for memory write
	signal wb_data_sel_s : std_logic; -- select between alu_res and mem_data for write back
	signal wb_data_s : std_logic_vector(31 downto 0); -- data to be written back

	signal alu_res_reg : std_logic_vector(31 downto 0);
	signal funct3_reg : std_logic_vector(2 downto 0);
	signal data_mem_rd_en_reg : std_logic;
	signal rd_reg : std_logic_vector(4 downto 0);
	signal wb_en_reg : std_logic;

begin

	wb_data_s <= mem_data_ext_s when data_mem_rd_en_reg = '1' else alu_res_reg;

	-- byteenable for memory write
	process(funct3_i)
	begin
		case funct3_i is
			when "000" =>
				mem_byte_en_s <= "0001";
			when "001" =>
				mem_byte_en_s <= "0011";
			when "010" =>
				mem_byte_en_s <= "1111";
			when others =>
				mem_byte_en_s <= "0000";
		end case;
	end process;

	-- memory data extension
	process(mem_rd_data_i, funct3_reg)
	begin
		case funct3_reg is
			when "100" =>
			-- LBU
				mem_data_ext_s <= sign_ext(mem_rd_data_i(7), 24) & mem_rd_data_i(7 downto 0);
			when "101" =>
			-- LHU
				mem_data_ext_s <= sign_ext(mem_rd_data_i(15), 16) & mem_rd_data_i(15 downto 0);
			when others =>
				mem_data_ext_s <= mem_rd_data_i;
		end case;
	end process;

	-- registers
	process(clk_i, rst_i)
	begin
		if rising_edge(clk_i) then
			if rst_i = '1' then
				alu_res_reg <= (others => '0');
				funct3_reg <= (others => '0');
				data_mem_rd_en_reg <= '0';
				rd_reg <= (others => '0');
				wb_en_reg <= '0';
			else
				alu_res_reg <= alu_res_i;
				funct3_reg <= funct3_i;
				data_mem_rd_en_reg <= data_mem_rd_en_i;
				rd_reg <= rd_i;
				wb_en_reg <= wb_en_i;
			end if;
		end if;
	end process;

	mem_wr_en_o <= data_mem_wr_en_i;
	mem_rd_en_o <= data_mem_rd_en_i;
	mem_byte_en_o <= mem_byte_en_s;
	mem_wr_addr_o <= alu_res_reg;
	mem_rd_addr_o <= alu_res_reg;
	mem_wr_data_o <= mem_data_i;

	wb_data_o <= wb_data_s;
	wb_addr_o <= rd_reg;
	wb_en_o <= wb_en_reg;

end architecture;
