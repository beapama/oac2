----------------------------------------------------------------------------------------------------
-------------MODULO ESTAGIO DE EXECU�AO-------------------------------------------------------------
----------------------------------------------------------------------------------------------------
library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;

library work;
use work.tipos.all;

-- Especifica�ao do estagio Executa - ex: declara�ao de entidade
-- Neste est�gio sao executadas as instru�oes do tipo RR e calculado os endere�os 
-- das instru�oes de load e store.
-- O m�dulo que implementa a antecipa�ao de valores (Forwarding) � feita neste est�gio 
-- num m�dulo separado dentro do est�gio ex.
-- A unidade l�gica e aritm�tica - ULA - fica neste est�gio.
-- Os multiplexadores de estrada da ULA que selecionam os valores corretos dependendo 
-- da antecipa�ao ficam neste est�gio.
-- A defini�ao do sinais de entrada e sa�da do est�gio EX encontram-se na declara�ao 
-- da entidade est�gio_ex e sao passados pelo registrador BEX

entity estagio_ex_13 is
    port(
		-- Entradas
		clock				: in 	std_logic;					  		-- Rel�gio do Sistema
      	BEX					: in 	std_logic_vector (151 downto 0);  	-- Dados vindos do id
		COP_ex				: in 	instruction_type;				  	-- Mnem�nico no est�gio ex
		ula_mem				: in 	std_logic_vector (031 downto 0);	-- ULA no est�gio de Mem�ria
		rs1_id_ex			: in	std_logic_vector (004 downto 0);    -- rs1 no est�gio id para o ex
		rs2_id_ex			: in	std_logic_vector (004 downto 0);    -- rs2 no est�gio id para o ex
		MemRead_mem			: in 	std_logic;					  		-- Leitura na mem�ria no  mem
		RegWrite_mem		: in 	std_logic;					  		-- Escrita nos regs. no  mem
		rd_mem				: in 	std_logic_vector (004 downto 0);	-- Destino nos regs. mem
		RegWrite_wb			: in	Std_logic;							-- Escrita nos regs no estagio wb
		rd_wb				: in	std_logic_vector (004 downto 0);	-- Destino no rges no est�gio wb
		writedata_wb		: in 	std_logic_vector (031 downto 0);	-- Dado a ser escrito no regs.
		Memval_mem			: in	std_logic_vector (031 downto 0);	-- Sa�da da mem�ria no mem
		
		-- Sa�das
		MemRead_ex			: out	std_logic;							-- Leitura da mem�ria no ex 
		rd_ex				: out	std_logic_vector (004 downto 0);	-- Destino dos regs no ex
		ULA_ex				: out	std_logic_vector (031 downto 0);	-- ULA no est�gio ex
		ex_fw_A_Branch		: out 	std_logic_vector (001 downto 0);	-- Dado comparado em A no id 
																		-- em desvios com forward
        ex_fw_B_Branch		: out 	std_logic_vector (001 downto 0);	-- Dado comparado em B no id 
																		-- em desvios com forward
        BMEM				: out 	std_logic_vector (115 downto 0) := (others => '0'); -- dados para mem
		COP_mem				: out 	instruction_type := NOP			  	-- Mnem�nico no est�gio mem
		
		);
end entity;

architecture estagio_ex_arch of estagio_ex_13 is
    -- Sinais internos
    signal rs1, rs2 : std_logic_vector(31 downto 0);
    signal result_ula : std_logic_vector(31 downto 0);
    signal ula_zero : std_logic;
    signal ex_forward_A, ex_forward_B : std_logic_vector(31 downto 0);
    
    -- Aliases para facilitar a leitura de sinais dentro do BEX
    alias rs1_id_ex_alias is BEX(132 downto 128);
    alias rs2_id_ex_alias is BEX(137 downto 133);
    alias rd_id_ex_alias is BEX(142 downto 138);
    alias imm_alias is BEX(95 downto 64);
    alias npc_ex_alias is BEX(127 downto 96);
    alias ula_op_alias is BEX(145 downto 143);

	component alu is
		port(
			-- Entradas
			in_a		: in 	std_logic_vector(31 downto 0);
			in_b		: in 	std_logic_vector(31 downto 0);
			ALUOp		: in 	std_logic_vector(02 downto 0);
			
			-- Sa�das
			ULA			: out 	std_logic_vector(31 downto 0);
			zero		: out 	std_logic
		);
	end component alu;

begin

	ula : alu port map (
		-- Entradas
		in_a => ex_forward_A,
		in_b => ex_forward_B,
		ALUOp => ula_op_alias,
		ULA	=> result_ula,
		zero => ula_zero
	);

	rs2 <= BEX(63 downto 32);
	rs1 <= BEX(31 downto 0);
    -- Comportamento do estágio de execução
    process(clock)
    begin
        if rising_edge(clock) then
            -- Seleciona os operandos para a ULA (forwarding ou valores atuais)
            if (RegWrite_mem = '1' and rd_mem = rs1_id_ex_alias) then
                ex_forward_A <= Memval_mem;
				ex_fw_A_Branch <= "10";
            elsif (RegWrite_wb = '1' and rd_wb = rs1_id_ex_alias) then
                ex_forward_A <= writedata_wb;
				ex_fw_A_Branch <= "01";
            else
                ex_forward_A <= rs1; -- Aqui rs1 precisa ser definido adequadamente
				ex_fw_A_Branch <= "00";
            end if;

            if (RegWrite_mem = '1' and rd_mem = rd_id_ex_alias) then
                ex_forward_B <= Memval_mem;
				ex_fw_B_Branch <= "10";
            elsif (RegWrite_wb = '1' and rd_wb = rd_id_ex_alias) then
                ex_forward_B <= writedata_wb;
				ex_fw_B_Branch <= "01";
            else
                ex_forward_B <= rs2; -- Aqui rs2 precisa ser definido adequadamente
				ex_fw_B_Branch <= "00";
            end if;

            -- Atribuição das saídas
            ULA_ex <= result_ula;
            MemRead_ex <= BEX(147);
            rd_ex <= rd_id_ex_alias;

            -- Atribuição de BMEM
            BMEM(115 downto 114) <= BEX(151 downto 150);
            BMEM(113) <= BEX(149);
            BMEM(112) <= BEX(148); -- Placeholder for MemWrite_ex
            BMEM(111) <= BEX(147);
            BMEM(110 downto 79) <= npc_ex_alias;
            BMEM(78 downto 47) <= result_ula;
            BMEM(46 downto 15) <= (others => '0'); -- Placeholder for dado_arma_ex
            BMEM(14 downto 10) <= rs1_id_ex_alias;
            BMEM(9 downto 5) <= rs2_id_ex_alias;
            BMEM(4 downto 0) <= rd_id_ex_alias;

            -- Atribuição de COP_mem
            COP_mem <= COP_ex;
        end if;
    end process;
end architecture;