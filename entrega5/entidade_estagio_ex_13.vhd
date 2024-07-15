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

architecture estagio_ex_arch_13 of estagio_ex_13 is
    -- Sinais internos
    signal rs1, rs2 : std_logic_vector(31 downto 0);
    signal result_ula : std_logic_vector(31 downto 0);
    signal ex_forward_A, ex_forward_B : std_logic_vector(31 downto 0);
    signal ex_mem_read, ex_reg_write : std_logic;
    
    -- Aliases para facilitar a leitura de sinais dentro do BEX
    alias rs1_id_ex_alias is BEX(4 downto 0);
    alias rs2_id_ex_alias is BEX(9 downto 5);
    alias imm_alias is BEX(31 downto 10);
    alias npc_ex_alias is BEX(110 downto 79);
    alias ula_op_alias is BEX(3 downto 0);

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

	component forwarding_unit_13 is
		port (
		  -- Entradas
		  rs1_id_ex : in std_logic_vector(4 downto 0); -- Registrador fonte 1
		  rs2_id_ex : in std_logic_vector(4 downto 0); -- Registrador fonte 2
		  rd_mem : in std_logic_vector(4 downto 0); -- Registrador destino do estágio MEM
		  rd_wb : in std_logic_vector(4 downto 0); -- Registrador destino do estágio WB
		  regwrite_mem : in std_logic; -- Sinal de escrita no registrador no estágio MEM
		  regwrite_wb : in std_logic; -- Sinal de escrita no registrador no estágio WB
		  result_mem : in std_logic_vector(31 downto 0); -- Resultado da ULA no estágio MEM
		  result_wb : in std_logic_vector(31 downto 0); -- Resultado da ULA no estágio WB
		  -- Saídas
		  forward_a : out std_logic_vector(1 downto 0); -- Seleção de encaminhamento para operando A
		  forward_b : out std_logic_vector(1 downto 0)  -- Seleção de encaminhamento para operando B
		);
	end component forwarding_unit_13;

begin

    -- Comportamento do estágio de execução
    process(clock)
    begin
        if rising_edge(clock) then
            -- Seleciona os operandos para a ULA (forwarding ou valores atuais)
            if (RegWrite_mem = '1' and rd_mem = rs1_id_ex) then
                ex_forward_A <= ula_mem;
            elsif (RegWrite_wb = '1' and rd_wb = rs1_id_ex) then
                ex_forward_A <= writedata_wb;
            else
                ex_forward_A <= rs1; -- Aqui rs1 precisa ser definido adequadamente
            end if;

            if (RegWrite_mem = '1' and rd_mem = rs2_id_ex) then
                ex_forward_B <= ula_mem;
            elsif (RegWrite_wb = '1' and rd_wb = rs2_id_ex) then
                ex_forward_B <= writedata_wb;
            else
                ex_forward_B <= rs2; -- Aqui rs2 precisa ser definido adequadamente
            end if;

            -- Operação da ULA
            case COP_ex is
                when "0000" => -- ADD
                    result_ula <= ex_forward_A + ex_forward_B;
                when "0001" => -- SUB
                    result_ula <= ex_forward_A - ex_forward_B;
                when "0010" => -- AND
                    result_ula <= ex_forward_A and ex_forward_B;
                when "0011" => -- OR
                    result_ula <= ex_forward_A or ex_forward_B;
                when "0100" => -- SLLI (Shift Left Logical Immediate)
                    result_ula <= ex_forward_A sll to_integer(unsigned(imm_alias));
                when "0101" => -- LW (Load Word)
                    result_ula <= ex_forward_A + ex_forward_B;
                when "0110" => -- SW (Store Word)
                    result_ula <= ex_forward_A + ex_forward_B;
                when "0111" => -- BEQ (Branch if Equal)
                    if (ex_forward_A = ex_forward_B) then
                        result_ula <= npc_ex_alias + imm_alias;
                    else
                        result_ula <= npc_ex_alias;
                    end if;
                -- Adicionar outras operações conforme necessário
                when others =>
                    result_ula <= (others => '0');
            end case;

            -- Atribuição das saídas
            ULA_ex <= result_ula;
            MemRead_ex <= MemRead_mem;
            rd_ex <= rs2_id_ex;

            -- Atribuição de BMEM
            BMEM(115 downto 114) <= "00"; -- Placeholder for MemToReg_ex
            BMEM(113) <= RegWrite_mem;
            BMEM(112) <= '0'; -- Placeholder for MemWrite_ex
            BMEM(111) <= MemRead_mem;
            BMEM(110 downto 79) <= npc_ex_alias;
            BMEM(78 downto 47) <= result_ula;
            BMEM(46 downto 15) <= (others => '0'); -- Placeholder for dado_arma_ex
            BMEM(14 downto 10) <= rs1_id_ex;
            BMEM(9 downto 5) <= rs2_id_ex;
            BMEM(4 downto 0) <= rs2_id_ex;

            -- Atribuição de COP_mem
            COP_mem <= COP_ex;
        end if;
    end process;
end architecture;