-------------------------------------------------------------------------------------------------
-------------MODULO REGFILE - BANCO DE REGISTRADORES---------------------------------------------
-------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity regfile is
    port(
		-- Entradas
		clock			: 	in 		std_logic;						-- Base de tempo - Bancada de teste
        RegWrite		: 	in 		std_logic; 						-- Sinal de escrita no RegFile
        read_reg_rs1	: 	in 		std_logic_vector(04 downto 0);	-- Endereço do registrador na saída RA
        read_reg_rs2	: 	in 		std_logic_vector(04 downto 0);	-- Endereço do registrador na saída RB
        write_reg_rd	: 	in 		std_logic_vector(04 downto 0);	-- Endereço do registrador a ser escrito
        data_in			: 	in 		std_logic_vector(31 downto 0);	-- Valor a ser escrito no registrador
		
		-- Saídas
        data_out_a		: 	out 	std_logic_vector(31 downto 0);	-- Valor lido pelo endereço rs1
        data_out_b		: 	out 	std_logic_vector(31 downto 0) 	-- Valor lido pelo endercço rs2
    );
end entity;

architecture regfile_arch of regfile is
	-- Tipo de dado paradeclaraçao do Register File: Banco de Regiistradores
	type regfile_type is array(31 downto 0) of std_logic_vector(31 downto 0);

	-- Registradores declarados e incializados com zeros
    signal regs: regfile_type := (others => (others => '0')); 
	
begin
	
reg:process(clock) -- processo que implementa o comportamento de escrita do Banco de Registradores
    begin
	--Escrita no RegFile na descida do Clock
        if (clock'event and clock = '0') and (RegWrite = '1') then	
            if write_reg_rd /= "00000" then	-- Nao se escreve no registrador zero
                regs(to_integer(unsigned(write_reg_rd))) <= data_in;
            end if;
        end if;
    end process;
	
   --Leitura sempre realizada tanto na descida como na subida do Clock
    data_out_a <= regs(to_integer(unsigned(read_reg_rs1)));
    data_out_b <= regs(to_integer(unsigned(read_reg_rs2)));
	
end architecture;
