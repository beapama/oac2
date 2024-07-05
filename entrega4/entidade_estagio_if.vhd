								---------------------------------------------------------------------------------------------------------
---------------MOD�LO DE BUSCA - IF -------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;

library work;
use work.tipos.all;

-- Especifica�ao do est�gio de BUSCA - if
-- Est�gio de Busca de Instru�oes - if: neste est�gio se encontra o PC(PC_if) (Contador de Programa) 
-- o Registrador de Instru�oes ri_if,o registrador  
-- NPC (NPC_if = PC incrementado de 4), a mem�ria Cache de instru�oes - iMEM e um conjunto de informa�oes 
-- passadas ao est�gio de decodifica�ao-id.
-- Essas informa�oes sao passadas por um sinal chamado BID (Buffer para o est�gio id). Este buffer � de 
-- sa�do do est�gio if 
-- e de entrada no est�gio id. Este est�gio recebe sinais vindos de outros est�gios, a saber:
--		clock; Sinal vindo da Bancada de teste que implementa o rel�gio do Pipeline;
-- 		id_hd_hazard: Sinal de controle vindo do est�gio id, no m�dulo hd, que carrega 0's na parte do ri  
-- 			do registrador de sa�da do est�gio de Busca (BID) quando da ocorr�ncia de um conflito;
-- 		id_hd_Branch_nop:Sinal vindo do est�gio id, do m�dulo hd, que indica inser�ao de NoP devido  
--          a desvio ou pulo;
-- 		id_PC_Src: Sinal vindo do est�gio id que define a sele�ao do multiplexador da entrada 
--		do registrador PC;
-- 		id_Jump_PC: Sinal vindo do est�gio id com o endere�o destino ("target") dos Pulos ou desvios  
--			a serem realizados.
--		keep_simulating: sinal que indica continua�ao (true) ou parada (false) da simula�ao.
-- O BID possui 64 bits alocados da seguinte forma: o ri_if nas posi�oes de 0 a 31 e o PC_if de 32 a 63.

entity estagio_if is
    generic(
        imem_init_file: string := "imem.txt"	--Nome do arquivo com o conte�do da memoria de programa
    );
    port(
			--Entradas
			clock			: in 	std_logic;	-- Base de tempo vinda da bancada de teste
        	id_hd_hazard	: in 	std_logic;	-- Sinal de controle que carrega 0's na parte do RI do 
												-- registrador de sa�da BID
			id_Branch_nop	: in 	std_logic;	-- Sinal que determina inser�ao de NOP- desvio ou pulo
			id_PC_Src		: in 	std_logic;	-- Sele�ao do mux da entrada do PC
			id_Jump_PC		: in 	std_logic_vector(31 downto 0) := x"00000000";	-- Endere�o do Jump ou 
																					-- desvio realizado
			keep_simulating	: in	Boolean := True; -- Sinal que indica a continua�ao da simula�ao
			
			-- Sa�da
        	BID				: out 	std_logic_vector(63 downto 0) := x"0000000000000000"--Reg. de sa�da 
																						-- if para id
    );
end entity;

architecture estagio_if_arch of estagio_if is
	signal COP_if 		: instruction_type;
	signal COP_id 		: instruction_type;
	signal COP_ex 		: instruction_type;
	signal COP_mem 		: instruction_type;
	signal COP_wb 		: instruction_type;
	signal clock_sim	: std_logic;
	signal PC_if  		: std_logic_vector(31 downto 0) := x"00000000";
	signal NPC_if  		: std_logic_vector(31 downto 0) := x"00000000";
	signal ri_if  		: std_logic_vector(31 downto 0);
	signal if_id  		: std_logic_vector(63 downto 0);

	component ram is
		generic(
			address_bits	: integer 	:= 32;		  -- N�mero de biots de endere�o da mem�ria
			size			: integer 	:= 4096;		  -- Tamanho da mem�ria em bytes
			ram_init_file	: string 	:= "imem.txt" -- Arquivo que contem o conte�do da mem�ria
		);
		port (
			-- Entradas
			clock 	: in  std_logic;								-- Base de tempo, mem�ria s�ncrona para escrita
			write 	: in  std_logic;								-- Sinal de escrita na mem�ria
			address : in  std_logic_vector(address_bits-1 downto 0);-- Entrada de endere�o da mem�ria
			data_in : in  std_logic_vector(address_bits-1 downto 0);-- Entrada de dados na mem�ria
			
			-- Sa�da
			data_out: out std_logic_vector(address_bits-1 downto 0)	-- Sa�da de dados da mem�ria
		);
	end component ram;

	begin
		clock_sim <= clock when keep_simulating else
					 clock_sim;
		
		-- process
		-- begin
		-- 	if(COP_if=HALT) then
		-- 		wait;
		-- 	end if;
		-- end process;

		COP_if <= NOP when if_id(31 downto 0)=x"00000000" else
				  HALT when if_id(31 downto 0)=x"0000006F" else
				  ADD when if_id(6 downto 0)="0110011" and if_id(14 downto 12)="000" else
				  SLT when if_id(6 downto 0)="0110011" and if_id(14 downto 12)="010" else
				  ADDI when if_id(6 downto 0)="0010011" and if_id(14 downto 12)="000" else
				  SLTI when if_id(6 downto 0)="0010011" and if_id(14 downto 12)="010" else
				  SLLI when if_id(6 downto 0)="0010011" and if_id(14 downto 12)="001" else
				  SRLI when if_id(6 downto 0)="0010011" and if_id(14 downto 12)="101" and if_id(31 downto 25)="0000000" else
				  SRAI when if_id(6 downto 0)="0010011" and if_id(14 downto 12)="101" and if_id(31 downto 25)="0100000" else
				  LW when if_id(6 downto 0)="0000011" and if_id(14 downto 12)="010" else
				  SW when if_id(6 downto 0)="0100011" and if_id(14 downto 12)="010" else
				  BEQ when if_id(6 downto 0)="1100011" and if_id(14 downto 12)="000" else
				  BNE when if_id(6 downto 0)="1100011" and if_id(14 downto 12)="001" else
				  BLT when if_id(6 downto 0)="1100011" and if_id(14 downto 12)="100" else
				  JAL when if_id(6 downto 0)="1101111" else
				  JALR when if_id(6 downto 0)="1100111" and if_id(14 downto 12)="000" else
				  NOINST;

		process(clock_sim)
		begin
			if(rising_edge(clock_sim)) then
				PC_if <= NPC_if when id_hd_hazard='0' else
						 PC_if;
				BID <= if_id;
			end if;

			if(falling_edge(clock_sim)) then
				NPC_if <= PC_if + 4 when id_hd_hazard='0' and id_PC_Src='0' and id_Branch_nop='0' else
						  id_Jump_PC when id_hd_hazard='0' and id_PC_Src='1' and id_Branch_nop='0' else
						  NPC_if;
				if_id(63 downto 32) <= PC_if;
				if_id(31 downto 0) <= x"0000006F" when PC_if=x"00000400" else
									  ri_if when id_Branch_nop='0' else
									  x"00000000";
			end if;

		end process;

		imem : ram port map (
			clock => clock_sim,
			write => '0',
			address => PC_if,
			data_in => x"00000000",
			data_out => ri_if
		);
	end estagio_if_arch;