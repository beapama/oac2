----------------------------------------------------------------------------------------------
------------Módulo RAM para ser utilizado no Cache de instruçoes------------------------------
----------------------------------------------------------------------------------------------
library ieee;
library std;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;
use std.textio.all;

entity ram is
    generic(
        address_bits	: integer 	:= 32;		  -- Número de biots de endereço da memória
        size			: integer 	:= 4096;		  -- Tamanho da memória em bytes
        ram_init_file	: string 	:= "imem.txt" -- Arquivo que contem o conteúdo da memória
    );
    port (
		-- Entradas
		clock 	: in  std_logic;								-- Base de tempo, memória síncrona para escrita
        write 	: in  std_logic;								-- Sinal de escrita na memória
        address : in  std_logic_vector(address_bits-1 downto 0);-- Entrada de endereço da memória
        data_in : in  std_logic_vector(address_bits-1 downto 0);-- Entrada de dados na memória
		
		-- Saída
        data_out: out std_logic_vector(address_bits-1 downto 0)	-- Saída de dados da memória
    );
end entity ram;

architecture ram_arch of ram is

    type memory_type is array(size-1 downto 0) of std_logic_vector(7 downto 0);

    --rotina que inicializa conteúdo da ram a partir de um arquivo de texto com binário
    impure function ram_init(file_name: string) return memory_type is
	
        file file_handle		: text open read_mode is file_name;
        variable current_line	: line;
        variable current_char	: character;
        variable current_word	: std_logic_vector(address_bits - 1 downto 0);
        variable ram_content	: memory_type := (others => (others => '0'));
        variable i				: integer := 0;
		
    begin
		-- Lendo o arquivo com o conteúdo da memória
        while i < 100000 loop
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
			-- Escrevendo byte a byte na memória
            ram_content(i) 		:= current_word(31 downto 24);
            ram_content(i+1) 	:= current_word(23 downto 16);
            ram_content(i+2) 	:= current_word(15 downto 08);
            ram_content(i+3) 	:= current_word(07 downto 00);
            i := i + 4;
        end loop;
        return ram_content;
    end function;
	-- Declaraç±ao da memória a ser utilizada no projeto
    signal memory				: memory_type := ram_init(ram_init_file);
    signal address_formatted	: std_logic_vector(11 downto 0);
	
begin
	
    process(clock) is -- Processo que implementa a memória RAM
    begin
        if rising_edge(clock) then -- As escrita na memória sao sincronizadas com a descida do relógio
            if write = '1' then
                memory(to_integer(unsigned(address_formatted)))		<=	data_in(31 downto 24);
                memory(to_integer(unsigned(address_formatted))+1)	<=	data_in(23 downto 16);
                memory(to_integer(unsigned(address_formatted))+2)	<=	data_in(15 downto 08);
                memory(to_integer(unsigned(address_formatted))+3)	<=	data_in(07 downto 00);
            end if;
        end if;
    end process;
	
	-- A leitura da memória é assíncrona, nao depende do relógio
    data_out(31 downto 24) 	<= memory(to_integer(unsigned(address_formatted)));
    data_out(23 downto 16) 	<= memory(to_integer(unsigned(address_formatted))+1);
    data_out(15 downto 08) 	<= memory(to_integer(unsigned(address_formatted))+2);
    data_out(07 downto 00) 	<= memory(to_integer(unsigned(address_formatted))+3);

    address_formatted <= address(11 downto 0);-- LImitando o tamanho da memória a 12 bits de endereço-4Kbytes
	
end architecture;

