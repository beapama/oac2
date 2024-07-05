----------------------------------------------------------------------------------------------
--------------MODULO ULA - UNIDADE LOGICA E ARITMETICA----------------------------------------
----------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_signed.all;

entity alu is
    port(
		-- Entradas
		in_a		: in 	std_logic_vector(31 downto 0);
        in_b		: in 	std_logic_vector(31 downto 0);
        ALUOp		: in 	std_logic_vector(02 downto 0);
		
		-- Saídas
        ULA			: out 	std_logic_vector(31 downto 0);
        zero		: out 	std_logic
    );
end entity;

architecture alu_arch of alu is	
	-- Sinais internops a ULA
    signal alu_out: std_logic_vector(31 downto 0) := (others => '0');
    constant zeros: std_logic_vector(31 downto 0) := (others => '0');  
	
begin
	-- Realizando as operaçoes da ULA
    alu_out <= in_a + in_b 					when ALUOp = "000" 	else --add
               in_a - in_b 					when ALUOp = "001" 	 else --subtract
               (0 => '1', others => '0') 	when ALUOp = "010" and (to_integer(signed(in_a))) <  
			   									 (to_integer(signed(in_b))) else --set less than
               (others => '0') 				when ALUOp = "010" and (to_integer(signed(in_a))) >= 
												 (to_integer(signed(in_b))) else --set less than
               std_logic_vector(shift_left(unsigned(in_a), 	to_integer(unsigned(in_b)))) 
											when ALUOp = "011" else --shift left logical
               std_logic_vector(shift_right(unsigned(in_a), to_integer(unsigned(in_b)))) 
											when ALUOp = "100" else --shift right logical
               std_logic_vector(shift_right(unsigned(in_a), to_integer(unsigned(in_b)))) 
											when ALUOp = "101" else --shift right arithmetic
               (others => '0'); --operaçao nao definida
	
			   -- Disponibilizando os snais de resultados nas saídas		   
    ULA 	<= 	alu_out;
    zero 	<= 	'1' when alu_out = zeros else
				'0';
		
end architecture;
