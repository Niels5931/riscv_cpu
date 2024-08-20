library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity di_ins_mem is
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
end entity;

architecture rtl of di_ins_mem is

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

	signal mem_wr_en_s : std_logic;
	signal mem_rd_en_s : std_logic;
	signal mem_byte_en_s : std_logic_vector(3 downto 0);
	signal mem_wr_addr_s : std_logic_vector(31 downto 0);
	signal mem_rd_addr_s : std_logic_vector(31 downto 0);
	signal mem_wr_data_s : std_logic_vector(31 downto 0);

	signal wb_data_i1_reg : std_logic_vector(31 downto 0);
	signal wb_addr_i1_reg : std_logic_vector(4 downto 0);
	signal wb_en_i1_reg : std_logic;

	signal wb_data_i2_reg : std_logic_vector(31 downto 0);
	signal wb_alu_res_i2_reg : std_logic_vector(31 downto 0);
	signal wb_addr_i2_reg : std_logic_vector(4 downto 0);
	signal wb_en_i2_reg : std_logic;
	signal mem_rd_en_i2_reg : std_logic;

begin

	ins_mem_i2 : ins_mem
	port map (
		clk_i => clk_i,
		rst_i => rst_i,
		data_mem_rd_en_i => data_mem_rd_en_i2_i,
		data_mem_wr_en_i => data_mem_wr_en_i2_i,
		wb_en_i => wb_en_i2_i,
		alu_res_i => alu_res_i2_i,
		mem_data_i => mem_data_i2_i,
		funct3_i => funct3_i2_i,
		rd_i => rd_i2_i,
		mem_wr_en_o => mem_wr_en_o,
		mem_rd_en_o => mem_rd_en_o,
		mem_byte_en_o => mem_byte_en_o,
		mem_wr_addr_o => mem_wr_addr_o,
		mem_rd_addr_o => mem_rd_addr_o,
		mem_wr_data_o => mem_wr_data_o,
		mem_rd_data_i => mem_rd_data_i,
		wb_data_o => wb_data_i2_reg,
		wb_addr_o => wb_addr_i2_reg,
		wb_en_o => wb_en_i2_reg
	);

	-- i1 register
	process(clk_i, rst_i)
	begin
		if rising_edge(clk_i) then
			if rst_i = '1' then
				wb_data_i1_reg <= (others => '0');
				wb_addr_i1_reg <= (others => '0');
				wb_en_i1_reg <= '0';
			else
				wb_data_i1_reg <= alu_res_i1_i;
				wb_addr_i1_reg <= rd_i1_i;
				wb_en_i1_reg <= wb_en_i1_i;
			end if;
		end if;
	end process;

	-- i2 register
	process(clk_i, rst_i)
	begin
		if rising_edge(clk_i) then
			if rst_i = '1' then
				wb_alu_res_i2_reg <= (others => '0');
				wb_addr_i2_reg <= (others => '0');
				wb_en_i2_reg <= '0';
				mem_rd_en_i2_reg <= '0';
			else
				wb_alu_res_i2_reg <= alu_res_i2_i;
				wb_addr_i2_reg <= rd_i2_i;
				wb_en_i2_reg <= wb_en_i2_i;
				mem_rd_en_i2_reg <= data_mem_rd_en_i2_i;
			end if;
		end if;
	end process;

	-- output assignments
	wb_data_i1_o <= wb_data_i1_reg;
	wb_addr_i1_o <= wb_addr_i1_reg;
	wb_en_i1_o <= wb_en_i1_reg;

	wb_data_i2_o <= wb_data_i2_reg when mem_rd_en_i2_reg = '1' else wb_alu_res_i2_reg;
	wb_addr_i2_o <= wb_addr_i2_reg;
	wb_en_i2_o <= wb_en_i2_reg;
	
end architecture;
