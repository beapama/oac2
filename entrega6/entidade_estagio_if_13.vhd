---------------------------------------------------------------------------------------------------------
---------------MODï¿½LO DE BUSCA - IF -------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;

library design;
use design.tipos.all;

-- Especificaï¿½ao do estï¿½gio de BUSCA - if
-- Estï¿½gio de Busca de Instruï¿½oes - if: neste estï¿½gio se encontra o PC(PC_if) (Contador de Programa) 
-- o Registrador de Instruï¿½oes ri_if,o registrador  
-- NPC (NPC_if = PC incrementado de 4), a memï¿½ria Cache de instruï¿½oes - iMEM e um conjunto de informaï¿½oes 
-- passadas ao estï¿½gio de decodificaï¿½ao-id.
-- Essas informaï¿½oes sao passadas por um sinal chamado BID (Buffer para o estï¿½gio id). Este buffer ï¿½ de 
-- saï¿½do do estï¿½gio if 
-- e de entrada no estï¿½gio id. Este estï¿½gio recebe sinais vindos de outros estï¿½gios, a saber:
--		clock; Sinal vindo da Bancada de teste que implementa o relï¿½gio do Pipeline;
-- 		id_hd_hazard: Sinal de controle vindo do estï¿½gio id, no mï¿½dulo hd, que carrega 0's na parte do ri  
-- 			do registrador de saï¿½da do estï¿½gio de Busca (BID) quando da ocorrï¿½ncia de um conflito;
-- 		id_hd_Branch_nop:Sinal vindo do estï¿½gio id, do mï¿½dulo hd, que indica inserï¿½ao de NoP devido  
--          a desvio ou pulo;
-- 		id_PC_Src: Sinal vindo do estï¿½gio id que define a seleï¿½ao do multiplexador da entrada 
--		do registrador PC;
-- 		id_Jump_PC: Sinal vindo do estï¿½gio id com o endereï¿½o destino ("target") dos Pulos ou desvios  
--			a serem realizados.
--		keep_simulating: sinal que indica continuaï¿½ao (true) ou parada (false) da simulaï¿½ao.
-- O BID possui 64 bits alocados da seguinte forma: o ri_if nas posiï¿½oes de 0 a 31 e o PC_if de 32 a 63.

entity estagio_if_13 is
    generic(
        imem_init_file: string := "imem.txt"	--Nome do arquivo com o conteï¿½do da memoria de programa
    );
    port(
			--Entradas
			clock			: in 	std_logic;	-- Base de tempo vinda da bancada de teste
        	id_hd_hazard	: in 	std_logic;	-- Sinal de controle que carrega 0's na parte do RI do 
												-- registrador de saï¿½da BID
			id_Branch_nop	: in 	std_logic;	-- Sinal que determina inserï¿½ao de NOP- desvio ou pulo
			id_PC_Src		: in 	std_logic;	-- Seleï¿½ao do mux da entrada do PC
			id_Jump_PC		: in 	std_logic_vector(31 downto 0) := x"00000000";	-- Endereï¿½o do Jump ou 
																					-- desvio realizado
			keep_simulating	: in	Boolean := True; -- Sinal que indica a continuaï¿½ao da simulaï¿½ao
			
			-- Saï¿½da
        	BID				: out 	std_logic_vector(63 downto 0) := x"0000000000000000"--Reg. de saï¿½da 
																						-- if para id
    );
end entity;

architecture estagio_if_arch of estagio_if_13 is
	signal COP_if 		: instruction_type := NOP;
	signal PC_if  		: std_logic_vector(31 downto 0) := x"00000000";
	signal NPC_if  		: std_logic_vector(31 downto 0) := x"00000000";
	signal ri_if  		: std_logic_vector(31 downto 0);

	component ram is
		generic(
			address_bits	: integer 	:= 32;		  -- Nï¿½mero de biots de endereï¿½o da memï¿½ria
			size			: integer 	:= 4096;		  -- Tamanho da memï¿½ria em bytes
			ram_init_file	: string 	:= "imem.txt" -- Arquivo que contem o conteï¿½do da memï¿½ria
		);
		port (
			-- Entradas
			clock 	: in  std_logic;								-- Base de tempo, memï¿½ria sï¿½ncrona para escrita
			write 	: in  std_logic;								-- Sinal de escrita na memï¿½ria
			address : in  std_logic_vector(address_bits-1 downto 0);-- Entrada de endereï¿½o da memï¿½ria
			data_in : in  std_logic_vector(address_bits-1 downto 0);-- Entrada de dados na memï¿½ria
			
			-- Saï¿½da
			data_out: out std_logic_vector(address_bits-1 downto 0)	-- Saï¿½da de dados da memï¿½ria
		);
	end component ram;

	begin		
		-- process
		-- begin
		-- 	if(COP_if=NOINST) then
		-- 		wait;
		-- 	end if;
		-- end process;

		process(clock)
		begin
			if(rising_edge(clock)) then
				BID(63 downto 32) <= PC_if;
				BID(31 downto 0) <= x"0000006F" when PC_if=x"00000400" else
									  ri_if when id_Branch_nop='0' else
									  x"00000000";
				PC_if <= NPC_if when id_hd_hazard='0' else
						 PC_if;

				COP_if <= NOP when ri_if(31 downto 0)=x"00000000" or id_Branch_nop='1' else
						HALT when ri_if(31 downto 0)=x"0000006F" else
						ADD when ri_if(6 downto 0)="0110011" and ri_if(14 downto 12)="000" else
						SLT when ri_if(6 downto 0)="0110011" and ri_if(14 downto 12)="010" else
						ADDI when ri_if(6 downto 0)="0010011" and ri_if(14 downto 12)="000" else
						SLTI when ri_if(6 downto 0)="0010011" and ri_if(14 downto 12)="010" else
						SLLI when ri_if(6 downto 0)="0010011" and ri_if(14 downto 12)="001" else
						SRLI when ri_if(6 downto 0)="0010011" and ri_if(14 downto 12)="101" and ri_if(31 downto 25)="0000000" else
						SRAI when ri_if(6 downto 0)="0010011" and ri_if(14 downto 12)="101" and ri_if(31 downto 25)="0100000" else
						LW when ri_if(6 downto 0)="0000011" and ri_if(14 downto 12)="010" else
						SW when ri_if(6 downto 0)="0100011" and ri_if(14 downto 12)="010" else
						BEQ when ri_if(6 downto 0)="1100011" and ri_if(14 downto 12)="000" else
						BNE when ri_if(6 downto 0)="1100011" and ri_if(14 downto 12)="001" else
						BLT when ri_if(6 downto 0)="1100011" and ri_if(14 downto 12)="100" else
						JAL when ri_if(6 downto 0)="1101111" else
						JALR when ri_if(6 downto 0)="1100111" and ri_if(14 downto 12)="000" else
						NOINST;
			end if;

			if(falling_edge(clock)) then
				NPC_if <= PC_if + 4 when id_hd_hazard='0' and id_PC_Src='0' else
						  id_Jump_PC when id_hd_hazard='0' and id_PC_Src='1' else
						  NPC_if;
			end if;

		end process;

		imem : ram port map (
			clock => clock,
			write => '0',
			address => PC_if,
			data_in => x"00000000",
			data_out => ri_if
		);
	end estagio_if_arch;