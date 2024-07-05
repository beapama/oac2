---------------------------------------------------------------------------------------------------
--------------MODULO MEMORIA DE DADOS--------------------------------------------------------------
---------------------------------------------------------------------------------------------------
library ieee;
library std;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;
use std.textio.all;

entity data_ram is	 -- Esta é a memória de dados -dmem
    generic(
        address_bits		: integer 	:= 32;		  -- Bits de end. da memória de dados
        size				: integer 	:= 4099;	  -- Tamanho da memória de dados em Bytes
        data_ram_init_file	: string 	:= "dmem.txt" -- Arquivo da memória de dados
    );
    port (
		-- Entradas
		clock 		: in  std_logic;							    -- Base de tempo bancada de teste
        write 		: in  std_logic;								-- Sinal de escrita na memória
        address 	: in  std_logic_vector(address_bits-1 downto 0);-- Entrada de endereço da memória
        data_in 	: in  std_logic_vector(address_bits-1 downto 0);-- Entrada de dados da memória
		
		-- Saída
        data_out 	: out std_logic_vector(address_bits-1 downto 0)	-- Saída de dados da memória
    );
end entity data_ram;

architecture data_ram_arch of data_ram is
	-- Definiçao do tipo de dado para declarar a memória RAM - Cache de Dados - dmem
    type memory_type is array(size-1 downto 0) of std_logic_vector(7 downto 0);

    --Rotina que inicializa o conteúdo da memória de dados; arquivo de texto com binário
    impure function data_ram_init(file_name: string) return memory_type is
        file file_handle		: text open read_mode is file_name;
        variable current_line	: line;
        variable current_char	: character;
        variable current_word	: std_logic_vector(address_bits - 1 downto 0);
        variable data_ram		: memory_type 	:= (others => (others => '0'));
        variable i				: integer 		:= 0;
    begin
        while i < 512 loop
            exit when endfile(file_handle);
            readline(file_handle, current_line);
            for j in 0 to address_bits - 1 loop
                read(current_line, current_char);
                if current_char = '0' then
                    current_word(address_bits - 1 - j) := '0';
                else
                    current_word(address_bits - 1 - j) := '1';
                end if;
            end loop;
            data_ram(i) 	:= current_word(31 downto 24);
            data_ram(i+1) 	:= current_word(23 downto 16);
            data_ram(i+2) 	:= current_word(15 downto 8);
            data_ram(i+3) 	:= current_word(7 downto 0);
            i := i + 4;
        end loop;
        return data_ram;
    end function;
	
	-- Sinais internos ao módulo
    signal data_memory		: memory_type := data_ram_init(data_ram_init_file);
    signal address_formatted: std_logic_vector(11 downto 0); 
	
begin
    process(clock) is -- Processo que implementa a lógica da memória RAM
    begin
        if rising_edge(clock) then	-- Escrita na memória de dados é síncrona com o relógio
            if write = '1' then
                data_memory(to_integer(unsigned(address_formatted)))	<=	data_in(31 downto 24);
                data_memory(to_integer(unsigned(address_formatted))+1)	<=	data_in(23 downto 16);
                data_memory(to_integer(unsigned(address_formatted))+2)	<=	data_in(15 downto 08);
                data_memory(to_integer(unsigned(address_formatted))+3)	<=	data_in(07 downto 00);
            end if;
        end if;
    end process;
	
	-- A leitura da memória de dados é assíncrona
    data_out(31 downto 24) 	<= data_memory(to_integer(unsigned(address_formatted)));
    data_out(23 downto 16) 	<= data_memory(to_integer(unsigned(address_formatted))+1);
    data_out(15 downto 08) 	<= data_memory(to_integer(unsigned(address_formatted))+2);
    data_out(07 downto 00) 	<= data_memory(to_integer(unsigned(address_formatted))+3);

    address_formatted <= address(11 downto 0);-- Limitando o número de bits de endereço(12)
	
end architecture data_ram_arch;

