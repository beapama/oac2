------------------------------------------------------------------------------------------------------------
------------MODULO ESTAGIO WRITE-BACK-----------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all; 

library design;
use design.tipos.all;	

-- Especifica�ao do est�gio WRITE-BACK - wb: Declara�ao de entidade
-- Este est�gio  seleciona a informa�ao que deve ser gravada nos registradores, 
-- cuja grava�ao ser� executada no est�gio id
-- Os sinais de entrada e sa�da deste est�gio encontram-es definidos nos coment�rios 
-- da declara�ao de entidade estagio_wb.


entity estagio_wb_13 is
    port(
		-- Entradas
        BWB				: in std_logic_vector(103 downto 0); -- Informa�oes vindas do estagi mem
		COP_wb			: in instruction_type := NOP;		 -- Mnem�nico da instru�ao no estagio wb
		
		-- Sa�das
        writedata_wb	: out std_logic_vector(31 downto 0); -- Valor a ser escrito emregistradores
        rd_wb			: out std_logic_vector(04 downto 0); -- Endere�o do registrador a ser escrito
		RegWrite_wb		: out std_logic						 -- Sinal de escrita nos registradores
    );
end entity;

architecture estagio_wb_arch of estagio_wb_13 is
    -- Sinais internos
	signal MemToReg_wb	: std_logic_vector(01 downto 0);
	signal NPC_wb 	: std_logic_vector(31 downto 0);
	signal ULA_wb 	: std_logic_vector(31 downto 0);
	signal Memval_wb 	: std_logic_vector(31 downto 0);

begin
	MemToReg_wb <= BWB(103 downto 102); -- Valor que deve ser armazenado em registradores
    RegWrite_wb <= BWB(101); -- Sinal de escrita em registradores
    NPC_wb <= BWB(100 downto 69); -- End. de retorno nas chamada de sub-rotina-Jal ou JALR
    ULA_wb <= BWB(068 downto 37); -- Valor vindo da saída da ula
    Memval_wb <= BWB(036 downto 05); -- Valor da saída da memória
    rd_wb <= BWB(004 downto 00); -- Endereço do registrador a ser escrito

    -- Comportamento do estágio de writeback
    process(MemToReg_wb)
    begin
        if (MemToReg_wb = "10") then
            writedata_wb <= Memval_wb;
        elsif (MemToReg_wb = "01") then
            writedata_wb <= ULA_wb;
        else
            writedata_wb <= NPC_wb;
        end if;
    end process;
end architecture;