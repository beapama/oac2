----------------------------------------------------------------------------------------------------------------------------------
-------------------------------Bancada de teste do estagio de Busca - rotina swap modificada--------------------------------------
----------------------------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;
 
entity tb_if is
end entity; 

architecture tb of tb_if is
component estagio_if is
    generic(
        imem_init_file: string := "imem.txt"
    );
    port(
        --Entradas
        clock 			: in  	std_logic;	-- Base de tempo vinda da bancada de teste
        id_hd_hazard	: in 	std_logic;	-- Sinal de controle que carrega 0's na parte do RI do registrador de saï¿½da do if_stage
		id_Branch_nop	: in 	std_logic;	-- Sinal que indica inser4ï¿½ao de NP devido a desviou pulo
		id_PC_Src		: in 	std_logic;	-- Seleï¿½ao do mux da entrada do PC
		id_Jump_PC		: in 	std_logic_vector(31 downto 0);			-- Endereco do Jump ou desvio realizado
		keep_simulating	: in	Boolean := True;
			
			-- Saida
        BID				: out 	std_logic_vector(63 downto 0) := x"0000000000000000"	--Registrador de saï¿½da do if_stage-if_id
    );
end component;

	constant clock_period	: time 		:= 10 ns;
	signal clock			: std_logic := '1';
	signal BID				: std_logic_vector (63 downto 0); 
	signal id_hd_hazard		: std_logic;
	signal id_Branch_nop	: std_logic;
	signal id_PC_Src		: std_logic;
	signal id_Jump_PC		: std_logic_vector(31 downto 0);
	signal Keep_simulating	: boolean 	:= true;

begin
    clock <= not clock after clock_period / 2;

    DUT: estagio_if 
        generic map (
            imem_init_file => "imem.txt"
        ) port map (
          --Entradas
          clock   => clock,			-- Base de tempo vinda da bancada de teste
          id_hd_hazard		=> id_hd_hazard,	-- Sinal de controle que carrega 0's na parte do RI do registrador de saï¿½da do if_stage
          id_Branch_nop		=> id_Branch_nop,	-- Sinal que indica inser4ï¿½ao de NP devido a desviou pulo
          id_PC_Src			=> id_PC_Src,		-- Seleï¿½ao do mux da entrada do PC
          id_Jump_PC		=> id_Jump_PC,		-- Endereï¿½o do Jump ou desvio realizado
          keep_simulating	=> keep_simulating,	-- Continue a simulaï¿½ao

          -- Saida
          BID  => BID  --Registrador de saï¿½da do if_stage-if_id
        );

    stim: process is
    begin
        id_hd_hazard 	<= '0';			-- Nao sinaliza conflito
		id_Branch_nop 	<= '0';		   	-- Nao insere NOP
		id_PC_Src 		<= '0';		    -- Nao ï¿½ instrucao de desvio ou pulo
		id_Jump_PC 		<= x"00000000"; -- Se tiver que pular o prï¿½ximo endereï¿½o serï¿½ x"00000000"
		keep_simulating <= true;		-- Mantenha simulacao ativa 
		
		wait for clock_period;		 -- ciclo 1 = 0 ns espera um ciclo de relogio 
		wait for clock_period/2;	 -- defasa as leitura de teste de 5 ns
		
		-- Situaçao no instante 15 ns
        report "Testando se instrucao na posicao 0 esta correta";
        assert BID(31 downto 00) = x"00000513" severity error;	 	-- Testa se esta instrucao eh: addi	a0,	zero,0
		report "RI_if = " & to_hex_string(BID(31 downto 00));	 	-- Imprime o codigo da instrucao passada para o id
		report "Testando o valor do PC enviado para o estagio id";
        assert BID(63 downto 32) = x"00000000"  severity error;	 	-- Testa se PC = x"00000000
		report "PC_id = " & to_hex_string(BID(63 downto 32));	 	-- Imprime o valor que esta no PC_id
		report " " ;											 	-- Pula uma linha no conslole de saída
	   
		-- Situaçao no instante 25 ns
        wait for clock_period;		 -- ciclo 2 = 25 ns	  leitura da 2a. instrucao do swap
        report "Testando se instrucao na posicao 1 (em palavras) esta correta";
        assert BID(31 downto 00) = x"00300593" severity error; 	 	-- Testa se esta instrucao eh: addi	a0,	zero,3
		report "RI_if = " & to_hex_string(BID(31 downto 00));	 	-- Imprime o codigo da instrucao passada para o id
        report "Testando o valor do PC enviado para o estagio id";					 	  
        assert BID(63 downto 32) = x"00000004" severity error;	 	-- Testa se PC = x"00000004"
		report " PC_id = " & to_hex_string(BID(63 downto 32)); 	 	-- Imprime o valor que esta no PC		o
		report " " ;											 	-- Pula uma linha no console de saida
		
        -- Situaçao no instante 35 ns
		wait for clock_period;		  -- ciclo 3 = 35 ns	leitura da 3a. instrucao do swap
        report "Testando se instrucao na posicao 2 esta correta";
        assert BID(31 downto 00) = x"00259293" severity error;	 -- Testa se a instrucao eh: slli t0, a1, 2 
		report "RI_if = " & to_hex_string(BID(31 downto 00));	 -- Imprime o codigo da instrucao passada para o id
        report "Testando o valor do PC enviado para o estagio id";
        assert BID(63 downto 32) = x"00000008" severity error;	 -- Testa se PC = x"00000008"
		report " PC_id = " & to_hex_string(BID(63 downto 32));	 -- Imprime o valor que esta no PC
		report " " ;											 -- Pula uma linha no console de saida
		
		-- Situaçao no instante 45 ns
        wait for clock_period;		  -- ciclo 4 = 45 ns	leitura da 4a. instrucao do swap
        report "Testando se instrucao na posicao 3 esta correta";
        assert BID(31 downto 00) = x"005502B3" severity error; 	 -- Testa se a instrucao eh: add t0,a0,t0
		report "RI_if = " & to_hex_string(BID(31 downto 00));	 -- Imprime o codigo da instrucao passada para o id
        report "Testando o valor do PC enviado para o estagio id";
        assert BID(63 downto 32) = x"0000000C" severity error; 	 -- Testando se PC = x"0000000C"
		report " PC_id = " & to_hex_string(BID(63 downto 32)); 	 -- Imprime o valor que esta no PC
		report " " ;											 -- Pula uma linha no console de saida
		
		-- Situaçao no instante 55 ns
        wait for clock_period;		  -- ciclo 5 = 55 ns	leitura da 5a. instrucao do swap
        report "Testando se instrucao na posicao 4 esta correta";
        assert BID(31 downto 00) = x"0002A303" severity error;	 -- Testa se a instrucao eh: lw t1, 0(t0)
		report "RI_if = " & to_hex_string(BID(31 downto 00));	 -- Imprime o codigo da instrucao passada para o id
        report "Testando o valor do PC enviado para o estagio id";
        assert BID(63 downto 32) = x"00000010" severity error;	 -- Testa se PC = x"00000010"
		report " PC_id = " & to_hex_string(BID(63 downto 32));	 -- Imprime o valor que esta no PC
		report " " ;											 -- Pula uma linha no console de saida
		
		-- Situaçao no instante 65 ns
        wait for clock_period;		   -- ciclo 6 = 65 ns	leitura da 6a. instrucao do swap
        report "Testando se instrucao na posicao 5 esta correta";
        assert BID(31 downto 00) = x"0042A383" severity error;	 -- Testa se a instrucao eh: lw t2, 4(t0)
		report "RI_if = " & to_hex_string(BID(31 downto 00));	 -- Imprime o codigo da instrucao passada para o id
        report "Testando o valor do PC enviado para o estagio id";
        assert BID(63 downto 32) = x"00000014" severity error;	 -- Testa se PC = x"00000014"
		report " PC_id = " & to_hex_string(BID(63 downto 32));	 -- Imprime o valor que esta no PC
		report " " ;											 -- Pula uma linha no console de saida
		
		 -- Situaçao no instante 75 ns
        wait for clock_period;		   -- ciclo 7 = 75 ns	leitura da 7a. instrucao do swap
        report "Testando se instrucao na posicao 6 esta correta";
        assert BID(31 downto 00) = x"0072A023" severity error;	 -- Testa se a instrucao eh: sw t2, 0(t0) 
		report "RI_if = " & to_hex_string(BID(31 downto 00));	 -- Imprime o codigo da instrucao passada para o id
        report "Testando o valor do PC enviado para o estagio id";
        assert BID(63 downto 32) = x"00000018" severity error; 	 -- Testa se PC = x"00000018"
		report " PC_id = " & to_hex_string(BID(63 downto 32));	 -- Imprime o valor que esta no PC
		report " " ;											 -- Pula uma linha no console de saida
		
		-- Situaçao no instante 85 ns
        wait for clock_period;		   -- ciclo 8 = 85 ns	leitura da 8a. instrucao do swap
        report "Testando se instrucao na posicao 7 esta correta";
        assert BID(31 downto 00) = x"0062A223" severity error;	 -- Testa se a instrucao eh: sw t1, 4(t0)
		report "RI_if = " & to_hex_string(BID(31 downto 00));	 -- Imprime o codigo da instrucao passada para o id
        report "Testando o valor do PC enviado para o estagio id";
        assert BID(63 downto 32) = x"0000001C" severity error;	 -- Testa se PC = x"0000001C"
		report " PC_id = " & to_hex_string(BID(63 downto 32));	 -- Imprime o valor que esta no PC
		report " " ;											 -- Pula uma linha no console de saida
		
		-- Situaçao no instante 95 ns
        wait for clock_period;		   -- ciclo 9 = 95 ns	leitura da 9a. instrucao do swap
        report "Testando se instrucao na posicao 8 esta correta";
        assert BID(31 downto 00) = x"00001013" severity error;	 -- Testa se a instrucao eh: NOP
		report "RI_if = " & to_hex_string(BID(31 downto 00));	 -- Imprime o codigo da instrucao passada para o id
        report "Testando o valor do PC enviado para o estagio id";
        assert BID(63 downto 32) = x"00000020" severity error; 	 -- Testa se PC = x"00000020"
		report " PC_id = " & to_hex_string(BID(63 downto 32));	 -- Imprime o valor que esta no PC
		report " " ;											 -- Pula uma linha no console de saida 
		
		
		wait for clock_period/2;
		-- Situaçao no instante 100 ns
		id_Jump_PC 		<= x"00000040"; -- Se tiver que pular o proximo endereco sera x"00000040"
		id_PC_Src 		<= '1';			
		
		
		-- Situaçao no instante 105 ns
		wait for clock_period/2;   		 -- ciclo 10 = 105 ns	 Teste de desvio inserindo endereco destino no PC 
        report "Testando se instrucao na posicao 9 esta correta";
        assert BID(31 downto 00) = x"00001013" severity error; 	 -- A instrucao ainda eh:	jalr zero, 0(ra) ou halt
		report "RI_if = " & to_hex_string(BID(31 downto 00));	 -- Imprime o codigo da instrucao passada para o id
        report "Testando o valor do PC enviado para o estagio id";
        assert BID(63 downto 32) = x"00000024" severity error;	 -- Testa se PC = x"00000024"
		report " PC_id = " & to_hex_string(BID(63 downto 32));	 -- Imprime o valor que esta no PC
		report " " ;											 -- Pula uma linha no console de saida
		
		-- Situaçao no instante 110 ns
		wait for clock_period/2;
		id_PC_Src <= '0';
		
		-- Situaçao no instante 115 ns
		wait for clock_period/2;		  -- ciclo 11 = 115 ns	 Teste de desvio lendo o endereco destino no PC
        report "Testando se instrucao na posicao 10 esta correta";
        assert BID(31 downto 00) = x"00001013" severity error; 	 -- A instrucao ainda eh:	jalr zero, 0(ra) ou halt
		report "RI_if = " & to_hex_string(BID(31 downto 00));	 -- Imprime o codigo da instrucao passada para o id
        report "Testando o valor do PC enviado para o estagio id";
        assert BID(63 downto 32) = x"00000028" severity error; 	 -- Testa se PC = x"00000028"
		report " PC_id = " & to_hex_string(BID(63 downto 32));	 -- Imprime o valor que esta no PC
		report " " ;											 -- Pula uma linha no console de saida
		
		-- Situaçao no instante 120 ns
		wait for clock_period/2;
		id_Branch_nop <= '1';	  -- ativa insercao de NOP no ri_if e BID
		
		-- Situaçao no instante 125 ns
		wait for clock_period/2;		  -- ciclo 12 = 125 ns	 Teste se esta inserindo NOP no ri e BID
        report "Testando se instrucao inserida esta correta posicao 11";
        assert BID(31 downto 00) = x"000001013" severity error; 	 -- A instrucao eh:	slli zero,zero, 0 == NOP
		report "RI_if = " & to_hex_string(BID(31 downto 00));	 	-- Imprime o codigo da instrucao passada para o id
        report "Testando o valor do PC enviado para o estagio id";
        assert BID(63 downto 32) = x"00000040" severity error; 	 	-- Testa se PC = x"00000044"
		report " PC_id = " & to_hex_string(BID(63 downto 32));	 	-- Imprime o valor que esta no PC
		report " " ;											 	-- Pula uma linha no console de saida	
		
		-- Situaçao no instante 130 ns
		wait for clock_period/2;
		id_Branch_nop <= '0';	 -- Desativa insercao de NOP
		
		-- Situaçao no instante 135 ns
		wait for clock_period/2;		  -- ciclo 13 = 135 ns	 Teste se estï¿½ inserindo NOP no ri e BID
        report "Testando se instrucao na posicao 12 esta correta";
        assert BID(31 downto 00) = x"000000000" severity error; 	-- A instrucao eh:	slli zero,zero, 0 == NOP
		report "RI_if = " & to_hex_string(BID(31 downto 00));	 	-- Imprime o codigo da instrucao passada para o id
        report "Testando o valor do PC enviado para o estagio id";
        assert BID(63 downto 32) = x"00000044" severity error; 	 	-- Testa se manteve o PC = x"00000040"
		report " PC_id = " & to_hex_string(BID(63 downto 32));	 	-- Imprime o valor que esta no PC
		report " " ;											 	-- Pula uma linha no console de saida
		
		-- Situaçao no instante 140 ns
		wait for clock_period/2;
		id_hd_hazard <= '1';	-- Ativa deteccao de conflito 
		
		-- Situaçao no instante 145 ns
		wait for clock_period/2;		  -- ciclo 14 = 145 ns	 Teste de deteccao de conflito com acionamento do id_hd_Hazrd
        report "Testando se instrucao na posicao 13 esta correta";
        assert BID(31 downto 00) = x"00001013" severity error; 	 -- A instrucao ainda eh: slli zero,zero, 0 == NOP
		report "RI_if = " & to_hex_string(BID(31 downto 00));	 -- Imprime o codigo da instrucao passada para o id
        report "Testando o valor do PC enviado para o estagio id";
        assert BID(63 downto 32) = x"00000044" severity error; 	 -- Testa se manteve o PC = x"00000040"
		report " PC_id = " & to_hex_string(BID(63 downto 32));	 -- Imprime o valor que esta no PC
		report " " ;											 -- Pula uma linha no console de saida	
		
		-- Situaçao no instante 150 ns
		wait for clock_period/2;
		id_hd_hazard <= '0';	-- Desativa detccao de conflito	

		
		-- Situaçao no instante 155 ns
		wait for clock_period/2;		  -- ciclo 15 = 155 ns	 Teste de deteccao de conflito sendo desativada
        report "Testando se instrucao na posicao 14 esta correta";
        assert BID(31 downto 00) = x"00001013" severity error; 	 -- A instrucao ainda eh: slli zero,zero, 0 == NOP
		report "RI_if = " & to_hex_string(BID(31 downto 00));	 -- Imprime o codigo da instrucao passada para o id
        report "Testando o valor do PC enviado para o estagio id";
        assert BID(63 downto 32) = x"00000044" severity error; 	 -- Testa se manteve o PC = x"00000044"
		report " PC_if = " & to_hex_string(BID(63 downto 32));	 -- Imprime o valor que esta no PC
		report " " ;											 -- Pula uma linha no console de saida	

    keep_simulating <= false;		-- Mantenha simulacao ativa 
        wait;
    end process;
end tb;   
