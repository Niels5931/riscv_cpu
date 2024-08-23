library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;

entity di_ins_fetch_dec is
generic (
	INS_START : std_logic_vector(31 downto 0) := x"00000000"
);
port (
	clk_i : in std_logic;
	rst_i : in std_logic;
	-- program counter
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
	pc_i1_o : out std_logic_vector(31 downto 0);
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
	pc_i2_o : out std_logic_vector(31 downto 0);
	data_mem_wr_en_i2_o : out std_logic;
	data_mem_rd_en_i2_o : out std_logic;
	-- execution stage input for branch prediction
	zero_i1_i : in std_logic;
	lt_i1_i : in std_logic;
	alu_res_i1_i : in std_logic_vector(31 downto 0);
	jmp_addr_alu_res_i : in std_logic_vector(31 downto 0);
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
end entity;

architecture rtl of di_ins_fetch_dec is

	---------------------
	-- ins fetch signals --
	---------------------

	signal pc_next : std_logic_vector(31 downto 0);
	signal pc_incr_stall_s : std_logic;
	signal ins_mem_addr_s : std_logic_vector(31 downto 0);
	signal ins_data_i1_s : std_logic_vector(31 downto 0);
	signal ins_data_i2_s : std_logic_vector(31 downto 0);

	signal pc_reg : std_logic_vector(31 downto 0);
	signal ins_addr_i1_reg : std_logic_vector(31 downto 0);
	signal ins_addr_i2_reg : std_logic_vector(31 downto 0);

	---------------------
	-- ins two way control signals --
	---------------------

	type ins_pre_dec_state_t is (IDLE, CATCH, I1, I2);
	signal ins_pre_dec_state_reg, ins_pre_dec_state_next : ins_pre_dec_state_t;

	signal pc_incr_sz_s : std_logic := '1'; -- increment with 4 or 8 (start with 8)
	
	signal is_i1_r_instr : std_logic;
	signal is_i1_i_instr : std_logic;
	signal is_i1_j_instr : std_logic;
	signal is_i1_b_instr : std_logic;
	signal is_i1_u_instr : std_logic;
	signal is_i1_s_instr : std_logic;

	signal is_i2_r_instr : std_logic;
	signal is_i2_i_instr : std_logic;
	signal is_i2_j_instr : std_logic;
	signal is_i2_b_instr : std_logic;
	signal is_i2_u_instr : std_logic;
	signal is_i2_s_instr : std_logic;

	signal i1_valid_s : std_logic;
	signal i2_valid_s : std_logic;

	signal zero_out_i1_s : std_logic;
	signal zero_out_i2_s : std_logic;

	signal rd_i1_s : std_logic_vector(4 downto 0);
	signal rs1_i1_addr_s : std_logic_vector(4 downto 0);
	signal rs2_i1_addr_s : std_logic_vector(4 downto 0);
	signal imm_i1_s : std_logic_vector(31 downto 0);
	signal opcode_i1_s : std_logic_vector(6 downto 0);
	signal funct3_i1_s : std_logic_vector(2 downto 0);
	signal funct7_i1_s : std_logic_vector(6 downto 0);
	signal wb_en_i1_s : std_logic;

	signal rd_i2_s : std_logic_vector(4 downto 0);
	signal rs1_i2_addr_s : std_logic_vector(4 downto 0);
	signal rs2_i2_addr_s : std_logic_vector(4 downto 0);
	signal imm_i2_s : std_logic_vector(31 downto 0);
	signal opcode_i2_s : std_logic_vector(6 downto 0);
	signal funct3_i2_s : std_logic_vector(2 downto 0);
	signal funct7_i2_s : std_logic_vector(6 downto 0);
	signal wb_en_i2_s : std_logic;
	signal data_mem_wr_en_i2_s : std_logic;
	signal data_mem_rd_en_i2_s : std_logic;

	signal is_i1_j_instr_reg : std_logic;
	signal is_i1_b_instr_reg : std_logic;

	signal rd_i1_reg : std_logic_vector(4 downto 0);
	signal rs1_i1_addr_reg : std_logic_vector(4 downto 0);
	signal rs2_i1_addr_reg : std_logic_vector(4 downto 0);
	signal imm_i1_reg : std_logic_vector(31 downto 0);
	signal opcode_i1_reg : std_logic_vector(6 downto 0);
	signal funct3_i1_reg : std_logic_vector(2 downto 0);
	signal funct7_i1_reg : std_logic_vector(6 downto 0);
	signal wb_en_i1_reg : std_logic;

	signal rd_i2_reg : std_logic_vector(4 downto 0);
	signal rs1_i2_addr_reg : std_logic_vector(4 downto 0);
	signal rs2_i2_addr_reg : std_logic_vector(4 downto 0);
	signal imm_i2_reg : std_logic_vector(31 downto 0);
	signal opcode_i2_reg : std_logic_vector(6 downto 0);
	signal funct3_i2_reg : std_logic_vector(2 downto 0);
	signal funct7_i2_reg : std_logic_vector(6 downto 0);
	signal wb_en_i2_reg : std_logic;
	signal data_mem_wr_en_i2_reg : std_logic;
	signal data_mem_rd_en_i2_reg : std_logic;

	signal ins_data_i1_reg : std_logic_vector(31 downto 0);
	signal ins_data_i1_pipe : std_logic_vector(31 downto 0);
	signal ins_data_i1_buff : std_logic_vector(31 downto 0);
	signal ins_addr_i1_reg_buff : std_logic_vector(31 downto 0);
	signal ins_data_i1_buff_en : std_logic;
	signal ins_data_i2_reg : std_logic_vector(31 downto 0);
	signal ins_data_i2_pipe : std_logic_vector(31 downto 0);
	signal ins_addr_i2_reg_buff : std_logic_vector(31 downto 0);
	signal ins_data_i2_buff : std_logic_vector(31 downto 0);
	signal ins_data_i2_buff_en : std_logic;

	signal ins_addr_i1_reg_s : std_logic_vector(31 downto 0);
	signal ins_addr_i2_reg_s : std_logic_vector(31 downto 0);
	
	signal ins_addr_i1_reg_reg : std_logic_vector(31 downto 0);
	signal ins_addr_i2_reg_reg : std_logic_vector(31 downto 0);

	---------------------
	-- ins decode signals --
	---------------------

	signal reg_file : arr(0 to 31)(31 downto 0);

	signal rs1_i1_s : std_logic_vector(31 downto 0);
	signal rs2_i1_s : std_logic_vector(31 downto 0);
	
	signal rs1_i2_s : std_logic_vector(31 downto 0);
	signal rs2_i2_s : std_logic_vector(31 downto 0);

	signal rs1_i1_reg : std_logic_vector(31 downto 0);
	signal rs1_i1_addr_reg_reg : std_logic_vector(4 downto 0);
	signal rs2_i1_reg : std_logic_vector(31 downto 0);
	signal rs2_i1_addr_reg_reg : std_logic_vector(4 downto 0);
	signal rd_i1_reg_reg : std_logic_vector(4 downto 0);
	signal imm_i1_reg_reg : std_logic_vector(31 downto 0);
	signal opcode_i1_reg_reg : std_logic_vector(6 downto 0);
	signal funct3_i1_reg_reg : std_logic_vector(2 downto 0);
	signal funct7_i1_reg_reg : std_logic_vector(6 downto 0);
	signal wb_en_i1_reg_reg : std_logic;

	signal rs1_i2_reg : std_logic_vector(31 downto 0);
	signal rs1_i2_addr_reg_reg : std_logic_vector(4 downto 0);
	signal rs2_i2_reg : std_logic_vector(31 downto 0);
	signal rs2_i2_addr_reg_reg : std_logic_vector(4 downto 0);
	signal rd_i2_reg_reg : std_logic_vector(4 downto 0);
	signal imm_i2_reg_reg : std_logic_vector(31 downto 0);
	signal opcode_i2_reg_reg : std_logic_vector(6 downto 0);
	signal funct3_i2_reg_reg : std_logic_vector(2 downto 0);
	signal funct7_i2_reg_reg : std_logic_vector(6 downto 0);
	signal wb_en_i2_reg_reg : std_logic;
	signal data_mem_wr_en_i2_reg_reg : std_logic;
	signal data_mem_rd_en_i2_reg_reg : std_logic;

	signal is_i1_j_instr_reg_reg : std_logic;
	signal is_i1_b_instr_reg_reg : std_logic;
	signal jump_flush_s : std_logic;
	signal branch_flush_s : std_logic;

	signal jmp_valid_s : std_logic;
	signal jmp_addr_s : std_logic_vector(31 downto 0);
	
	signal ins_addr_i1_reg_reg_reg : std_logic_vector(31 downto 0);
	signal ins_addr_i2_reg_reg_reg : std_logic_vector(31 downto 0);

	
begin

	---------------------
	-- ins fetch logic --
	---------------------

	-- assign in statemachine
	
	pc_next <= jmp_addr_s + 8 when jmp_valid_s = '1' else pc_reg + 8;
	ins_mem_addr_s <= jmp_addr_s when jmp_valid_s = '1' else pc_reg;

	-- program counter
	process(clk_i, rst_i)
	begin
		if rising_edge(clk_i) then
			if rst_i = '1' then
				pc_reg <= INS_START;
			elsif pc_incr_stall_s = '1' then
				pc_reg <= pc_reg;
			else
				pc_reg <= pc_next;
			end if;
		end if;
	end process;

	process(clk_i, rst_i)
	begin
		if rising_edge(clk_i) then
			if rst_i = '1' then
				ins_addr_i1_reg <= (others => '0');
				ins_addr_i2_reg <= (others => '0');
			elsif pc_incr_stall_s = '1' then
				ins_addr_i1_reg <= ins_addr_i1_reg;
				ins_addr_i2_reg <= ins_addr_i2_reg;
			else
				ins_addr_i1_reg <= ins_mem_addr_s;
				ins_addr_i2_reg <= ins_mem_addr_s+4;
			end if;
		end if;
	end process;

	ins_mem_addr_o <= ins_mem_addr_s;

	---------------------
	-- ins two way logic --
	---------------------

	is_i1_b_instr <= '1' when opcode_i1_s = "1100011" else '0';
	is_i1_i_instr <= '1' when opcode_i1_s = "0010011" or opcode_i1_s = "0000011" or opcode_i1_s = "1100111" else '0';
	is_i1_j_instr <= '1' when opcode_i1_s = "1101111" else '0';
	is_i1_r_instr <= '1' when opcode_i1_s = "0110011" else '0';
	is_i1_s_instr <= '1' when opcode_i1_s = "0100011" else '0';
	is_i1_u_instr <= '1' when opcode_i1_s = "0110111" or opcode_i1_s = "0010111" else '0';

	opcode_i1_s <= ins_data_i1_s(6 downto 0);
	rd_i1_s <= ins_data_i1_s(11 downto 7);
	rs1_i1_addr_s <= ins_data_i1_s(19 downto 15);
	rs2_i1_addr_s <= ins_data_i1_s(24 downto 20);
	funct3_i1_s <= ins_data_i1_s(14 downto 12);
	funct7_i1_s <= ins_data_i1_s(31 downto 25);
	wb_en_i1_s <= '1' when is_i1_i_instr = '1' or is_i1_r_instr = '1' or is_i1_j_instr = '1' or is_i1_u_instr = '1' else '0';

	is_i2_b_instr <= '1' when opcode_i2_s = "1100011" else '0';
	is_i2_i_instr <= '1' when opcode_i2_s = "0010011" or opcode_i2_s = "0000011" or opcode_i2_s = "1100111" else '0';
	is_i2_j_instr <= '1' when opcode_i2_s = "1101111" else '0';
	is_i2_r_instr <= '1' when opcode_i2_s = "0110011" else '0';
	is_i2_s_instr <= '1' when opcode_i2_s = "0100011" else '0';
	is_i2_u_instr <= '1' when opcode_i2_s = "0110111" or opcode_i2_s = "0010111" else '0';

	opcode_i2_s <= ins_data_i2_s(6 downto 0);
	rd_i2_s <= ins_data_i2_s(11 downto 7);
	rs1_i2_addr_s <= ins_data_i2_s(19 downto 15);
	rs2_i2_addr_s <= ins_data_i2_s(24 downto 20);
	funct3_i2_s <= ins_data_i2_s(14 downto 12);
	funct7_i2_s <= ins_data_i2_s(31 downto 25);
	data_mem_wr_en_i2_s <= '1' when is_i2_s_instr = '1' else '0';
	data_mem_rd_en_i2_s <= '1' when opcode_i2_s = "0000011" else '0';
	wb_en_i2_s <= '1' when is_i2_i_instr = '1' or is_i2_r_instr = '1' or is_i2_j_instr = '1' or is_i2_u_instr = '1' else '0';

	-- immediate assignment
	process(all)
	begin
		if is_i1_i_instr = '1' then
			imm_i1_s <= sign_ext(ins_data_i1_s(31),21) & ins_data_i1_s(30 downto 20);
		elsif is_i1_s_instr = '1' then
			imm_i1_s <= sign_ext(ins_data_i1_s(31), 21) & ins_data_i1_s(30 downto 25) & ins_data_i1_s(11 downto 7);
		elsif is_i1_b_instr = '1' then
			imm_i1_s <= sign_ext(ins_data_i1_s(31), 20) & ins_data_i1_s(7) & ins_data_i1_s(30 downto 25) & ins_data_i1_s(11 downto 8) & "0";
		elsif is_i1_u_instr = '1' then
			imm_i1_s <= ins_data_i1_s(31 downto 12) & "000000000000";
		elsif is_i1_j_instr = '1' then
			imm_i1_s <= sign_ext(ins_data_i1_s(31), 12) & ins_data_i1_s(19 downto 12) & ins_data_i1_s(20) & ins_data_i1_s(30 downto 21) & "0";
		else
			imm_i1_s <= (others => '0');
		end if;
		if is_i2_i_instr = '1' then
			imm_i2_s <= sign_ext(ins_data_i2_s(31),21) & ins_data_i2_s(30 downto 20);
		elsif is_i2_s_instr = '1' then
			imm_i2_s <= sign_ext(ins_data_i2_s(31), 21) & ins_data_i2_s(30 downto 25) & ins_data_i2_s(11 downto 7);
		elsif is_i2_b_instr = '1' then
			imm_i2_s <= sign_ext(ins_data_i2_s(31), 20) & ins_data_i2_s(7) & ins_data_i2_s(30 downto 25) & ins_data_i2_s(11 downto 8) & "0";
		elsif is_i2_u_instr = '1' then
			imm_i2_s <= ins_data_i2_s(31 downto 12) & "000000000000";
		elsif is_i2_j_instr = '1' then
			imm_i2_s <= sign_ext(ins_data_i2_s(31), 12) & ins_data_i2_s(19 downto 12) & ins_data_i2_s(20) & ins_data_i2_s(30 downto 21) & "0";
		else
			imm_i2_s <= (others => '0');
		end if;
	end process;


	-- register assignment for i1
	process(clk_i, rst_i)
	begin
		if rising_edge(clk_i) then
			if rst_i = '1' or zero_out_i1_s = '1' or jump_flush_s = '1' then
				rd_i1_reg <= (others => '0');
				rs1_i1_addr_reg <= (others => '0');
				rs2_i1_addr_reg <= (others => '0');
				imm_i1_reg <= (others => '0');
				opcode_i1_reg <= (others => '0');
				funct3_i1_reg <= (others => '0');
				funct7_i1_reg <= (others => '0');
				wb_en_i1_reg <= '0';
			else
				rd_i1_reg <= rd_i1_s;
				rs1_i1_addr_reg <= rs1_i1_addr_s;
				rs2_i1_addr_reg <= rs2_i1_addr_s;
				imm_i1_reg <= imm_i1_s;
				opcode_i1_reg <= opcode_i1_s;
				funct3_i1_reg <= funct3_i1_s;
				funct7_i1_reg <= funct7_i1_s;
				wb_en_i1_reg <= wb_en_i1_s;
			end if;
		end if;
	end process;

	-- register assignment for i2
	process(clk_i, rst_i)
	begin
		if rising_edge(clk_i) then
			if rst_i = '1' or zero_out_i2_s = '1' or jump_flush_s = '1' then
				rd_i2_reg <= (others => '0');
				rs1_i2_addr_reg <= (others => '0');
				rs2_i2_addr_reg <= (others => '0');
				imm_i2_reg <= (others => '0');
				opcode_i2_reg <= (others => '0');
				funct3_i2_reg <= (others => '0');
				funct7_i2_reg <= (others => '0');
				wb_en_i2_reg <= '0';
				data_mem_wr_en_i2_reg <= '0';
				data_mem_rd_en_i2_reg <= '0';
			else
				rd_i2_reg <= rd_i2_s;
				rs1_i2_addr_reg <= rs1_i2_addr_s;
				rs2_i2_addr_reg <= rs2_i2_addr_s;
				imm_i2_reg <= imm_i2_s;
				opcode_i2_reg <= opcode_i2_s;
				funct3_i2_reg <= funct3_i2_s;
				funct7_i2_reg <= funct7_i2_s;
				wb_en_i2_reg <= wb_en_i2_s;
				data_mem_wr_en_i2_reg <= data_mem_wr_en_i2_s;
				data_mem_rd_en_i2_reg <= data_mem_rd_en_i2_s;
			end if;
		end if;
	end process;

	-- state machine
	process(all)
	begin
		ins_data_i2_s <= ins_mem_data_i(63 downto 32);
		ins_data_i1_s <= ins_mem_data_i(31 downto 0);
		pc_incr_stall_s <= '0';
		ins_data_i1_buff_en <= '0';
		ins_data_i2_buff_en <= '0';
		zero_out_i1_s <= '0';
		zero_out_i2_s <= '0';
		ins_addr_i1_reg_s <= ins_addr_i1_reg;
		ins_addr_i2_reg_s <= ins_addr_i2_reg;
		ins_pre_dec_state_next <= ins_pre_dec_state_reg;
		case ins_pre_dec_state_reg is
			when IDLE =>
				if rst_i = '1' then
					ins_pre_dec_state_next <= IDLE;
				elsif opcode_i1_s = "1101111" or opcode_i1_s = "1100111" or opcode_i1_s = "1100011" then
					-- process jump/stall such that i2 is not executed at the same time
					zero_out_i2_s <= '1';
					pc_incr_stall_s <= '1';
					ins_data_i2_buff_en <= '1';
					ins_pre_dec_state_next <= CATCH;
				elsif i1_valid_s = '0' then 
					-- move i1 to i2 and stall i2
					zero_out_i1_s <= '1';
					pc_incr_stall_s <= '1';
					ins_data_i2_buff_en <= '1';
					ins_data_i2_s <= ins_data_i1_s;
					ins_addr_i2_reg_s <= ins_addr_i1_reg;
					if i2_valid_s = '1' then
						ins_pre_dec_state_next <= CATCH;
					else 
						ins_pre_dec_state_next <= I1;
					end if;
				elsif i2_valid_s = '0' then
					-- move i2 to i1 in the next cycle
					zero_out_i2_s <= '1';
					ins_data_i2_buff_en <= '1';
					pc_incr_stall_s <= '1';
					ins_pre_dec_state_next <= I1;
				elsif i1_valid_s = '1' and i2_valid_s = '1' then
					-- check for hazards
					if ((rd_i1_s = rs1_i2_addr_s or rd_i1_s = rs2_i2_addr_s) and rd_i1_s /= "00000") or rd_i1_s = rd_i2_s then
						zero_out_i2_s <= '1';
						pc_incr_stall_s <= '1';
						ins_data_i2_buff_en <= '1';
						if i2_valid_s = '1' then
							ins_pre_dec_state_next <= CATCH;
						else
							ins_pre_dec_state_next <= I1;
						end if;
					end if;
				end if;
			when CATCH =>
				zero_out_i1_s <= '1';
				ins_data_i2_s <= ins_data_i2_buff;
				ins_addr_i2_reg_s <= ins_addr_i2_reg_buff;
				ins_pre_dec_state_next <= IDLE;
				if opcode_i2_reg = "0000011" and (rd_i2_reg = rs1_i2_addr_s or rd_i2_reg = rs2_i2_addr_s) then
					ins_pre_dec_state_next <= CATCH;
					pc_incr_stall_s <= '1';
					zero_out_i2_s <= '1';
				end if;
			when I1 =>
				ins_data_i1_s <= ins_data_i2_buff;
				ins_addr_i1_reg_s <= ins_addr_i2_reg_buff;
				zero_out_i2_s <= '1';
				ins_pre_dec_state_next <= IDLE;
			when I2 =>
				ins_data_i2_s <= ins_data_i1_buff;
				zero_out_i1_s <= '1';
				ins_pre_dec_state_next <= IDLE;
			when others =>
				ins_pre_dec_state_next <= IDLE;
		end case;
	end process;

	-- valid signals
	process(all)
	begin
		i1_valid_s <= '0';
		i2_valid_s <= '0';
		if is_i1_b_instr = '1' or is_i1_j_instr = '1' or is_i1_r_instr = '1' or is_i1_u_instr = '1' then 
			i1_valid_s <= '1';
		elsif is_i1_i_instr = '1' and opcode_i1_s /= "0000011" then
			i1_valid_s <= '1';
		end if;
		if (is_i2_i_instr = '1' and opcode_i2_s /= "1100111" ) or is_i2_r_instr = '1' or is_i2_s_instr = '1' or is_i2_u_instr = '1' then
			i2_valid_s <= '1';
		end if;
	end process;

	process(clk_i, rst_i)
	begin
		if rising_edge(clk_i) then
			if rst_i = '1' then
				ins_data_i1_buff <= (others => '0');
				ins_data_i2_buff <= (others => '0');
			else
				if ins_data_i1_buff_en = '1' then
					ins_data_i1_buff <= ins_mem_data_i(31 downto 0);
					ins_addr_i1_reg_buff <= ins_addr_i1_reg;
				end if;
				if ins_data_i2_buff_en = '1' then
					ins_data_i2_buff <= ins_mem_data_i(63 downto 32);
					ins_addr_i2_reg_buff <= ins_addr_i2_reg;
				end if;
			end if;
		end if;
	end process;

	process(clk_i,rst_i)
	begin
		if rising_edge(clk_i) then
			if rst_i = '1' then
				ins_pre_dec_state_reg <= IDLE;
			else
				ins_pre_dec_state_reg <= ins_pre_dec_state_next;
			end if;
		end if;
	end process;

	process(clk_i, rst_i)
	begin
		if rising_edge(clk_i) then
			if rst_i = '1' then
				ins_addr_i1_reg_reg <= (others => '0');
				ins_addr_i2_reg_reg <= (others => '0');
			else
				ins_addr_i1_reg_reg <= ins_addr_i1_reg_s;	
				ins_addr_i2_reg_reg <= ins_addr_i2_reg_s;
			end if;
		end if;
	end process;

	process(clk_i, rst_i)
	begin
		if rising_edge(clk_i) then
			if rst_i = '1' or zero_out_i1_s = '1' then
				is_i1_j_instr_reg <= '0';
				is_i1_b_instr_reg <= '0';
			else
				is_i1_j_instr_reg <= is_i1_j_instr;
				is_i1_b_instr_reg <= is_i1_b_instr;
			end if;
		end if;
	end process;

	---------------------
	-- ins decode logic --
	---------------------

	-- jump or branch logic
	jump_flush_s <= jmp_valid_s;
	process(all)
	begin
		jmp_valid_s <= '0';
		jmp_addr_s <= jmp_addr_alu_res_i;
		if is_i1_j_instr_reg_reg = '1' or opcode_i1_reg_reg = "1100111" then
			jmp_valid_s <= '1';
		elsif is_i1_b_instr_reg_reg = '1' then
			if funct3_i1_reg_reg = "000" and zero_i1_i = '1' then -- beq
				jmp_valid_s <= '1';
			elsif funct3_i1_reg_reg = "001" and zero_i1_i = '0' then -- bne
				jmp_valid_s <= '1';
			elsif (funct3_i1_reg_reg = "100" or funct3_i1_reg_reg = "110") and lt_i1_i = '1' then -- blt, bltu
				jmp_valid_s <= '1';
			elsif (funct3_i1_reg_reg = "101" or funct3_i1_reg_reg = "111") and lt_i1_i = '0' then -- bge, bgeu
				jmp_valid_s <= '1';
			end if;
		end if;
	end process;

	-- register file
	process(clk_i, rst_i)
	begin
		rs1_i1_s <= reg_file(to_integer(unsigned(rs1_i1_addr_reg)));
		rs2_i1_s <= reg_file(to_integer(unsigned(rs2_i1_addr_reg)));
		if reg_wr_en_i1_i = '1' and reg_wr_addr_i1_i = rs1_i1_addr_reg then
			rs1_i1_s <= reg_wr_data_i1_i;
		elsif reg_wr_en_i2_i = '1' and reg_wr_addr_i2_i = rs1_i1_addr_reg then
			rs1_i1_s <= reg_wr_data_i2_i;
		end if;
		if reg_wr_en_i1_i = '1' and reg_wr_addr_i1_i = rs2_i1_addr_reg then
			rs2_i1_s <= reg_wr_data_i1_i;
		elsif reg_wr_en_i2_i = '1' and reg_wr_addr_i2_i = rs2_i1_addr_reg then
			rs2_i1_s <= reg_wr_data_i2_i;
		end if;
		rs1_i2_s <= reg_file(to_integer(unsigned(rs1_i2_addr_reg)));
		rs2_i2_s <= reg_file(to_integer(unsigned(rs2_i2_addr_reg)));
		if reg_wr_en_i2_i = '1' and reg_wr_addr_i2_i = rs1_i2_addr_reg then
			rs1_i2_s <= reg_wr_data_i2_i;
		elsif reg_wr_en_i1_i = '1' and reg_wr_addr_i1_i = rs1_i2_addr_reg then
			rs1_i2_s <= reg_wr_data_i1_i;
		end if;
		if reg_wr_en_i2_i = '1' and reg_wr_addr_i2_i = rs2_i2_addr_reg then
			rs2_i2_s <= reg_wr_data_i2_i;
		elsif reg_wr_en_i1_i = '1' and reg_wr_addr_i1_i = rs2_i2_addr_reg then
			rs2_i2_s <= reg_wr_data_i1_i;
		end if;
		if rising_edge(clk_i) then
			if rst_i = '1' then
				reg_file(1) <= x"00000000";
				reg_file(2) <= x"000007f0";
				reg_file(3) <= x"10000000";
				for i in 3 to 31 loop
					reg_file(i) <= (others => '0');
				end loop;
			else
				if reg_wr_en_i1_i = '1' and reg_wr_en_i2_i = '1' then
					if reg_wr_addr_i1_i = reg_wr_addr_i2_i then
						reg_file(to_integer(unsigned(reg_wr_addr_i1_i))) <= reg_wr_data_i1_i;
					else
						reg_file(to_integer(unsigned(reg_wr_addr_i1_i))) <= reg_wr_data_i1_i;
						reg_file(to_integer(unsigned(reg_wr_addr_i2_i))) <= reg_wr_data_i2_i;
					end if;
				else
					if reg_wr_en_i1_i = '1' then
						reg_file(to_integer(unsigned(reg_wr_addr_i1_i))) <= reg_wr_data_i1_i;
					end if;
					if reg_wr_en_i2_i = '1' then
						reg_file(to_integer(unsigned(reg_wr_addr_i2_i))) <= reg_wr_data_i2_i;
					end if;
				end if;
			end if;
			reg_file(0) <= x"00000000";
		end if;
	end process;

	-- register assignment for i1
	process(clk_i, rst_i)
	begin
		if rising_edge(clk_i) then
			if rst_i = '1' or jump_flush_s = '1' then
				rs1_i1_reg <= (others => '0');
				rs1_i1_addr_reg_reg <= (others => '0');
				rs2_i1_reg <= (others => '0');
				rs2_i1_addr_reg_reg <= (others => '0');
				rd_i1_reg_reg <= (others => '0');
				imm_i1_reg_reg <= (others => '0');
				opcode_i1_reg_reg <= (others => '0');
				funct3_i1_reg_reg <= (others => '0');
				funct7_i1_reg_reg <= (others => '0');
				wb_en_i1_reg_reg <= '0';
			else
				rs1_i1_reg <= rs1_i1_s;
				rs1_i1_addr_reg_reg <= rs1_i1_addr_reg;
				rs2_i1_reg <= rs2_i1_s;
				rs2_i1_addr_reg_reg <= rs2_i1_addr_reg;
				rd_i1_reg_reg <= rd_i1_reg;
				imm_i1_reg_reg <= imm_i1_reg;
				opcode_i1_reg_reg <= opcode_i1_reg;
				funct3_i1_reg_reg <= funct3_i1_reg;
				funct7_i1_reg_reg <= funct7_i1_reg;
				wb_en_i1_reg_reg <= wb_en_i1_reg;
			end if;
		end if;
	end process;

	-- register assignment for i2
	process(clk_i, rst_i)
	begin
		if rising_edge(clk_i) then
			if rst_i = '1' or jump_flush_s = '1' then
				rs1_i2_reg <= (others => '0');
				rs1_i2_addr_reg_reg <= (others => '0');
				rs2_i2_reg <= (others => '0');
				rs2_i2_addr_reg_reg <= (others => '0');
				rd_i2_reg_reg <= (others => '0');
				imm_i2_reg_reg <= (others => '0');
				opcode_i2_reg_reg <= (others => '0');
				funct3_i2_reg_reg <= (others => '0');
				funct7_i2_reg_reg <= (others => '0');
				wb_en_i2_reg_reg <= '0';
				data_mem_wr_en_i2_reg_reg <= '0';
				data_mem_rd_en_i2_reg_reg <= '0';
			else
				rs1_i2_reg <= rs1_i2_s;
				rs1_i2_addr_reg_reg <= rs1_i2_addr_reg;
				rs2_i2_reg <= rs2_i2_s;
				rs2_i2_addr_reg_reg <= rs2_i2_addr_reg;
				rd_i2_reg_reg <= rd_i2_reg;
				imm_i2_reg_reg <= imm_i2_reg;
				opcode_i2_reg_reg <= opcode_i2_reg;
				funct3_i2_reg_reg <= funct3_i2_reg;
				funct7_i2_reg_reg <= funct7_i2_reg;
				wb_en_i2_reg_reg <= wb_en_i2_reg;
				data_mem_wr_en_i2_reg_reg <= data_mem_wr_en_i2_reg;
				data_mem_rd_en_i2_reg_reg <= data_mem_rd_en_i2_reg;
			end if;
		end if;
	end process;

	process(clk_i, rst_i)
	begin
		if rising_edge(clk_i) then
			if rst_i = '1' then
				ins_addr_i1_reg_reg_reg <= (others => '0');
				ins_addr_i2_reg_reg_reg <= (others => '0');
			else
				ins_addr_i1_reg_reg_reg <= ins_addr_i1_reg_reg;
				ins_addr_i2_reg_reg_reg <= ins_addr_i2_reg_reg;
			end if;
		end if;
	end process;

	process(clk_i, rst_i)
	begin
		if rising_edge(clk_i) then
			if rst_i = '1' then
				is_i1_j_instr_reg_reg <= '0';
				is_i1_b_instr_reg_reg <= '0';
			else
				is_i1_j_instr_reg_reg <= is_i1_j_instr_reg;
				is_i1_b_instr_reg_reg <= is_i1_b_instr_reg;
			end if;
		end if;
	end process;

	-- output signals
	opcode_i1_o <= opcode_i1_reg_reg;
	rs1_i1_o <= rs1_i1_reg;
	rs1_i1_addr_o <= rs1_i1_addr_reg_reg;
	rs2_i1_o <= rs2_i1_reg;
	rs2_i1_addr_o <= rs2_i1_addr_reg_reg;
	rd_i1_o <= rd_i1_reg_reg;
	funct3_i1_o <= funct3_i1_reg_reg;
	funct7_i1_o <= funct7_i1_reg_reg;
	imm_i1_o <= imm_i1_reg_reg;
	wb_i1_o <= wb_en_i1_reg_reg;
	pc_i1_o <= ins_addr_i1_reg_reg_reg;

	opcode_i2_o <= opcode_i2_reg_reg;
	rs1_i2_o <= rs1_i2_reg;
	rs1_i2_addr_o <= rs1_i2_addr_reg_reg;
	rs2_i2_o <= rs2_i2_reg;
	rs2_i2_addr_o <= rs2_i2_addr_reg_reg;
	rd_i2_o <= rd_i2_reg_reg;
	funct3_i2_o <= funct3_i2_reg_reg;
	funct7_i2_o <= funct7_i2_reg_reg;
	imm_i2_o <= imm_i2_reg_reg;
	wb_i2_o <= wb_en_i2_reg_reg;
	data_mem_wr_en_i2_o <= data_mem_wr_en_i2_reg_reg;
	data_mem_rd_en_i2_o <= data_mem_rd_en_i2_reg_reg;
	pc_i2_o <= ins_addr_i2_reg_reg_reg;

	

end architecture;
