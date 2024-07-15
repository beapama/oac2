----------------------------------------------------------------------------------------------------
-------------MODULO ESTAGIO DE EXECUÇAO-------------------------------------------------------------
----------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_signed.all;

library work;
use work.tipos.all;

-- Especificaçao do estagio Executa - ex: declaraçao de entidade
-- Neste estágio sao executadas as instruçoes do tipo RR e calculado os endereços 
-- das instruçoes de load e store.
-- O módulo que implementa a antecipaçao de valores (Forwarding) é feita neste estágio 
-- num módulo separado dentro do estágio ex.
-- A unidade lógica e aritmética - ULA - fica neste estágio.
-- Os multiplexadores de estrada da ULA que selecionam os valores corretos dependendo 
-- da antecipaç±ao ficam neste estágio.
-- A definiç±ao do sinais de entrada e saída do estágio EX encontram-se na declaraçao 
-- da entidade estágio_ex e sao passados pelo registrador BEX

entity estagio_ex is
    port(
		-- Entradas
		clock				: in 	std_logic;					  		-- Relógio do Sistema
      	BEX					: in 	std_logic_vector (151 downto 0);  	-- Dados vindos do id
		COP_ex				: in 	instruction_type;				  	-- Mnemônico no estágio ex
		ula_mem				: in 	std_logic_vector (031 downto 0);	-- ULA no estágio de Memória
		rs1_id_ex			: in	std_logic_vector (004 downto 0);    -- rs1 no estágio id para o ex
		rs2_id_ex			: in	std_logic_vector (004 downto 0);    -- rs2 no estágio id para o ex
		MemRead_mem			: in 	std_logic;					  		-- Leitura na memória no  mem
		RegWrite_mem		: in 	std_logic;					  		-- Escrita nos regs. no  mem
		rd_mem				: in 	std_logic_vector (004 downto 0);	-- Destino nos regs. mem
		RegWrite_wb			: in	Std_logic;							-- Escrita nos regs no estagio wb
		rd_wb				: in	std_logic_vector (004 downto 0);	-- Destino no rges no estágio wb
		writedata_wb		: in 	std_logic_vector (031 downto 0);	-- Dado a ser escrito no regs.
		Memval_mem			: in	std_logic_vector (031 downto 0);	-- Saída da memória no mem
		
		-- Saídas
		MemRead_ex			: out	std_logic;							-- Leitura da memória no ex 
		rd_ex				: out	std_logic_vector (004 downto 0);	-- Destino dos regs no ex
		ULA_ex				: out	std_logic_vector (031 downto 0);	-- ULA no estágio ex
		ex_fw_A_Branch		: out 	std_logic_vector (001 downto 0);	-- Dado comparado em A no id 
																		-- em desvios com forward
        ex_fw_B_Branch		: out 	std_logic_vector (001 downto 0);	-- Dado comparado em B no id 
																		-- em desvios com forward
        BMEM				: out 	std_logic_vector (115 downto 0) := (others => '0'); -- dados para mem
		COP_mem				: out 	instruction_type := NOP			  	-- Mnemônico no estágio mem
		
		);
end entity;