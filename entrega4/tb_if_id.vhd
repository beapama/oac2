library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_signed.all;
use std.textio.all;

library work;
use work.tipos.all;

entity tb_if_id_swap_halt is
    generic(
        imem_init_file: string := "imem.txt";
        dmem_init_file: string := "dmem.txt"
    );
end entity;

architecture tb_if_id_arch2 of tb_if_id_swap_halt is	

    component estagio_if
        generic(
		imem_init_file: string := "imem.txt"
        );
        port(
			--Entradas
			clock			: in 	std_logic;	-- Base de tempo vinda da bancada de teste
        	id_hd_hazard	: in 	std_logic;	-- Sinal de controle que carrega 0's na parte do RI do registrador de saída do if_stage
			id_Branch_nop	: in 	std_logic;	-- Sinal que indica inser4çao de NP devido a desviou pulo
			id_PC_Src		: in 	std_logic;	-- Seleçao do mux da entrada do PC
			id_Jump_PC		: in 	std_logic_vector(31 downto 0) := x"00000000";			-- Endereço do Jump ou desvio realizado
			keep_simulating	: in	Boolean := True;
			
			-- Saída
        	BID				: out 	std_logic_vector(63 downto 0) := x"0000000000000000"	--Registrador de saída do if_stage-if_id
        );
    end component;

    component estagio_id
        port(
			-- Entradas
			clock				: in 	std_logic; 						-- Base de tempo vindo da bancada de teste
			BID					: in 	std_logic_vector(063 downto 0);	-- Informaçoes vindas estágio Busca
			MemRead_ex			: in	std_logic;						-- Sinal de leitura de memória no estagio ex
			rd_ex				: in	std_logic_vector(004 downto 0);	-- Endereço de destino noa regs. no estágio ex
			ula_ex				: in 	std_logic_vector(031 downto 0);	-- Saída da ULA no estágio Ex
			MemRead_mem			: in	std_logic;						-- Sinal de leitura na memória no estágio mem
			rd_mem				: in	std_logic_vector(004 downto 0);	-- Endere'co de escrita nos regs. no est'agio mem
			ula_mem				: in 	std_logic_vector(031 downto 0);	-- Saída da ULA no estágio Mem 
			NPC_mem				: in	std_logic_vector(031 downto 0); -- Valor do NPC no estagio mem
        	RegWrite_wb			: in 	std_logic; 						-- Sinal de escrita no RegFile vindo de wb
        	writedata_wb		: in 	std_logic_vector(031 downto 0);	-- Valor a ser escrito no RegFile vindo de wb
        	rd_wb				: in 	std_logic_vector(004 downto 0);	-- Endereço do registrador escrito
        	ex_fw_A_Branch		: in 	std_logic_vector(001 downto 0);	-- Seleçao de Branch forwardA vindo de forward
        	ex_fw_B_Branch		: in 	std_logic_vector(001 downto 0);	-- Seleçao de Branch forwardB vindo de forward
		
			-- Saídas
			id_Jump_PC			: out	std_logic_vector(031 downto 0) := x"00000000";		-- Endereço destino do JUmp ou Desvio
			id_PC_src			: out	std_logic := '0';				-- Seleciona a entrado do PC
			id_hd_hazard		: out	std_logic := '0';				-- Sinal que preserva o if_id e nao incrementa o PC
			id_Branch_nop		: out	std_logic := '0';				-- Sinaliza a inserçao de um NOP devido ao Branch. limpa o if_id.ri
			rs1_id_ex			: out	std_logic_vector(004 downto 0);	-- Endereço rs1 no estágio id
			rs2_id_ex			: out	std_logic_vector(004 downto 0);	-- Endereço rs2 no estágio id
			BEX					: out 	std_logic_vector(151 downto 0) := (others => '0'); 	-- Saída do ID para o EX
			COP_id				: out	instruction_type  := NOP;							-- Instrucao no estagio id
			COP_ex				: out 	instruction_type := NOP								-- Instruçao no estágio id passada para EX
        );
    end component;

	-- Período do relógio do Pipeline
	constant clock_period: time := 10 ns; 
	
	-- Sinais internos para conexao das portas do estágio IF
	signal		clock			: std_logic := '1';	-- Base de tempo vinda da bancada de teste
    signal    	id_hd_hazard	: std_logic;		-- Sinal de controle que carrega 0's na parte do RI do registrador de saída do if_stage
	signal		id_PC_Src		: std_logic;		-- Seleçao do mux da entrada do PC
	signal		id_Jump_PC		: std_logic_vector(31 downto 0) := x"00000000";		-- Endereço do Jump ou desvio realizado
	signal		BID				: std_logic_vector(63 downto 0) := x"0000000000000000";--Registrador de saída do if_stage-if_id clock 
	signal		Keep_simulating	: boolean := true;	-- Continue a simulaçao
	
	
	-- Sinais internos para conexao das portas do estágio ID
	--Entradas
	signal	MemRead_ex		: std_logic;						-- Sinal de leitura de memória no estagio ex
	--signal	RegWrite_ex		: std_logic;						-- Sinal de escrita nos regs. no estágio ex
	signal	rd_ex			: std_logic_vector(004 downto 0);	-- Endereço de destino nos regs. no estágio ex
	signal	ula_ex			: std_logic_vector(031 downto 0);	-- Saída da ULA no estágio Ex
	signal	MemRead_mem		: std_logic;						-- Sinal de leitura na memória no estágio mem
	signal	ula_mem			: std_logic_vector(031 downto 0);	-- Saída da ULA no estágio Mem 
    signal  RegWrite_wb		: std_logic; 						-- Sinal de escrita no RegFile vindo de wb
    signal  writedata_wb	: std_logic_vector(031 downto 0);	-- Valor a ser escrito no RegFile vindo de wb
    signal  rd_wb			: std_logic_vector(004 downto 0);	-- Endereço do registrador escrito
    signal  ex_fw_A_Branch	: std_logic_vector(001 downto 0);	-- Seleçao de Branch forwardA vindo de forward
    signal  ex_fw_B_Branch	: std_logic_vector(001 downto 0);	-- Seleçao de Branch forwardB vindo de forward 
	signal	rd_mem			: std_logic_vector(04 downto 0); 
	signal	NPC_mem			: std_logic_vector(31 downto 0);
	signal	id_Branch_nop	: std_logic; 
	signal	rs1_id_ex		: std_logic_vector(04 downto 0);
	signal	rs2_id_ex		: std_logic_vector(04 downto 0);
	signal	COP_id			: instruction_type;
	 
			-- Saídas
	signal	BEX				: std_logic_vector(151 downto 0) := (others => '0'); 	-- Saída do ID para o EX
	signal	COP_ex			: instruction_type := NOP;						  		-- Instruçao no estágio id passada para EX
	
	--	Mostrando a alocaç±ao dos sinais no buffer de saída  id - BEX

alias MemToReg 			is BEX(151 downto 150);
alias RegWrite 			is BEX(149);
alias Memwrite 			is BEX(148);
alias Memread  			is BEX(147);
alias AluSrc   			is BEX(146);
alias Aluop				is BEX(145 downto 143);
alias reg_rd			is BEX(142 downto 138);
alias reg_rs2			is BEX(137 downto 133);
alias reg_rs1			is BEX(132 downto 128);
alias PC_id				is BEX(127 downto 096);
alias Imed				is BEX(095 downto 064);
alias RB				is BEX(063 downto 032);
alias RA				is BEX(031 downto 000);	

alias BEX_control		is BEX(151 downto 143);
alias BEX_Data			is BEX(142 downto 000);

-- Sinais para escrever log em arquivos	
constant 	C_FILE_NAME 	:string  	:= "DataOut.txt";
signal 		eof           	:std_logic 	:= '0';
file 		fptr			: text;

	
begin
	
    fetch : estagio_if 
        generic map(
            imem_init_file => "imem.txt"
        )
        port map(
			--Entradas
			clock			=> clock,			-- Base de tempo vinda da bancada de teste
        	id_hd_hazard	=> id_hd_hazard,	-- Sinal de controle que carrega 0's na parte do RI do registrador de saída do if_stage
			id_Branch_nop	=> id_Branch_nop,	-- Sinal que indica inser4çao de NP devido a desviou pulo
			id_PC_Src		=> id_PC_Src,		-- Seleçao do mux da entrada do PC
			id_Jump_PC		=> id_Jump_PC,		-- Endereço do Jump ou desvio realizado
			keep_simulating	=> keep_simulating,	-- Continue a simulaçao
			
			-- Saída
        	BID				=> BID				--Registrador de saída do if_stage-if_id
        );

    decode : estagio_id 
        port map(
            -- Entradas
		clock				=> clock,			-- Base de tempo vindo da bancada de teste
		BID					=> BID,				-- Informaçoes vindas estágio Busca
		MemRead_ex			=> MemRead_ex,		-- Sinal de leitura de memória no estagio ex
		rd_ex				=> rd_ex,			-- Endereço de destino noa regs. no estágio ex
		ula_ex				=> ula_ex,			-- Saída da ULA no estágio Ex
		MemRead_mem			=> MemRead_mem,		-- Sinal de leitura na memória no estágio mem
		rd_mem				=> rd_mem,			-- Endereco de escrita nos regs. no estagio mem
		ula_mem				=> ula_mem,			-- Saída da ULA no estágio Mem 
		NPC_mem				=> NPC_mem, 		-- Valor do NPC no estagio mem
        RegWrite_wb			=> RegWrite_wb, 	-- Sinal de escrita no RegFile vindo de wb
        writedata_wb		=> writedata_wb,	-- Valor a ser escrito no RegFile vindo de wb
        rd_wb				=> rd_wb,			-- Endereço do registrador escrito
        ex_fw_A_Branch		=> ex_fw_A_Branch,	-- Seleçao de Branch forwardA vindo de forward
        ex_fw_B_Branch		=> ex_fw_B_Branch,	-- Seleçao de Branch forwardB vindo de forward
		
		-- Saídas
		id_Jump_PC			=> id_Jump_PC, 		-- Endereço destino do JUmp ou Desvio
		id_PC_src			=> id_PC_src,		-- Seleciona a entrado do PC
		id_hd_hazard		=> id_hd_hazard,	-- Sinal que preserva o if_id e nao incrementa o PC
		id_Branch_nop		=> id_Branch_nop,	-- Sinaliza a inserçao de um NOP devido ao Branch. limpa o if_id.ri
		rs1_id_ex			=> rs1_id_ex,		-- Endereço rs1 no estágio id
		rs2_id_ex			=> rs2_id_ex,		-- Endereço rs2 no estágio id
		BEX					=> BEX, 			-- Saída do ID para o EX
		COP_id				=> COP_id,			-- Instrucao no estagio id
		COP_ex				=> COP_ex			-- Instruçao no estágio id passada para EX
        );


	clock <= not clock after clock_period / 2;

    process(clock) 
	variable count: integer := 0; 
	variable fstatus       :file_open_status;
	variable file_line     :line;
	
    begin
		
        if rising_edge(clock) then
			   	
		   case count is  
			   when 0 => 		--Teste da primeira instrução do programa swap: addi,a0,zero,0 ==> 10 ns
			   				MemRead_ex 		<= '0';
							rd_ex			<= "00000";
							--RegWrite_ex 	<= '0';
							ULA_ex 			<= x"00000000";
							--rs1_id_ex		<= "00000";
							--rs2_id_ex		<= "01000";
							MemRead_mem 	<= '0';
							rd_mem			<= "00000";
							ula_mem 		<= x"00000000";
							NPC_mem			<= x"00000000";
			   				RegWrite_wb 	<= '1';
							writedata_wb 	<= x"00000000";
							rd_wb			<= "00000";
			   				ex_fw_A_Branch 	<= "00";
							ex_fw_B_Branch 	<= "00"; 
							file_open(fstatus, fptr, C_FILE_NAME, write_mode);
							
							report "=================================================================================  " severity warning;
							report "Count = " & to_string(count) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE1: primeira instrução: Verificando leitura de RA" severity note;
							write(file_line, "TESTE1: primeira instrução: Verificando leitura de RA", left, 5);
							writeline(fptr, file_line);
							if RA = x"00000000" then
								report "Teste 1: primeira instrução ==> ESTÁ CORRETO" severity warning;
								write(file_line, "Teste 1: primeira instrução ==> ESTÁ CORRETO", left, 5);
								writeline(fptr, file_line);
							end if;
							assert RA = x"00000000" severity error;
							report "RA = " & to_hex_string(RA) severity warning;
							write(file_line, "RA = " & to_hex_string(RA), right, 2);
							writeline(fptr, file_line);
							write(file_line,"   ", right, 2);
							writeline(fptr, file_line);
							report "=================================================================================  " severity warning;
							
							
        					report "TESTE 2: primeira instrução: Verificando leitura de RB" severity note;
							write(file_line, "TESTE 2: primeira instrução: Verificando leitura de RB", left, 5);
							writeline(fptr, file_line);
							if RB = x"00000000" then
								report "Teste 2: primeira instrução ==>  ESTÁ CORRETO" severity warning;
								write(file_line, "Teste 2: primeira instrução ==>  ESTÁ CORRETO", left, 5);
								writeline(fptr, file_line);
							end if;
							assert RB = x"00000000" severity error;
							report "RB = " & to_hex_string(RB) severity warning;
							write(file_line, "RB = " & to_hex_string(RB), right, 2);
							writeline(fptr, file_line);
							write(file_line,"   ", right, 2);
							writeline(fptr, file_line);
							report "=================================================================================  " severity warning;
							
							report "TESTE 3: primeira instrução: Verificando que Imed está no buffer de saída" severity note;
							if Imed = x"00000000" then
								report "Teste 3: primeira instrucao ==> ESTÁ CORRETO" severity warning;
							end if;
							assert Imed = x"00000000" severity error;
							report "Imed = " & to_hex_string(Imed) severity warning;
							report "=================================================================================  " severity warning;
							
			   				report "TESTE 4: primeira instrução: Verificando que PC_id está no buffer de saída: 10 ns" severity note;
							if PC_id = x"00000000" then
							report "Teste 4: primeira instrução ==> ESTÁ CORRETO" severity warning;
							end if;
							assert PC_id = x"00000000" severity error;
							report "PC_id = " & to_hex_string(PC_id) severity warning;
							report "=================================================================================  " severity warning;
							
        					report "TESTE 5: primeira instrução: Verificando que rs1 está no buffer de saída" severity note;
							if reg_rs1 = "00000" then  -- 
								report "Teste 5: primeira instrução ==> ESTÁ CORRETO" severity warning;
							end if;
							assert reg_rs1 = "00000" severity error;
							report "reg_rs1 = " & to_hex_string(reg_rs1) severity warning;
							report "=================================================================================  " severity warning;
							
        					report "TESTE 6: primeira instrução: Verificando que rs2 está no buffer de saída" severity note;
							if reg_rs2 = "00000" then
								report "Teste 6: primeira instrucao ==> ESTÁ CORRETO" severity warning;
							end if;
							assert reg_rs2 = "00000" severity error;
							report "reg_rs2 = " & to_hex_string(reg_rs2) severity warning;
							report "=================================================================================  " severity warning;
							
        					report "TESTE 7: primeira instrução: Verificando que rd está no buffer de saída" severity note;
							if reg_rd = "00000" then
								report "Teste 7: primeira instrução ==> ESTÁ CORRETO" severity warning;
							end if;
							assert reg_rd  = "00000" severity error;
							report "reg_rd = " & to_hex_string(reg_rd) severity warning;
							report "=================================================================================  " severity warning;
							
							assert BEX_Data = "00000000000000000000000000000000000000" severity error;
							report "BEX_Data= " & to_hex_string(BEX_Data) severity warning;
							report "#################################################################################  " severity warning;
							
							if BEX_control = "000000000"then
								report "Teste 8: primeira instrução Sinais de controle ==> ESTÃ0 CORRETOs" severity warning;
							else
								report "Teste 8: primeira instrução Sinais de controle ==> ESTÃ0 ERRADOS severity error" severity error;
							end if;																						 
							assert BEX_control = "000000000" severity error;
							report "BEX_control = " & to_string(BEX_control) severity warning;
							report "#################################################################################  " severity warning;
							report "#################################################################################  " severity warning;
												
				when 1 => 	--Teste da segunda instrução do programa swap: addi,a1,zero,3 ==> 20 ns
							MemRead_ex 		<= '0';
							rd_ex			<= "00000";	
							--rs2_id_ex		<= "00000";
							NPC_mem			<= x"00000004";
							report "=================================================================================  " severity warning;
							report "Count = " & to_string(count) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 1: segunda instrução: Verificando leitura de RA está no buffer de saída" severity note;
							if RA = x"00000000" then                 
       							report "Teste 1: da segunda instrução está correto" severity warning;                         
							end if;                                                     
							assert RA = x"00000000" severity error;
							report "RA = " & to_hex_string(RA) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 2: segunda instrução: Verificando leitura de RB" severity note;
							if RB = x"00000000" then
								report "Teste 2: da segunda instrução está correto" severity warning;
							end if;
        					assert RB = x"00000000" severity error;
							report "RB = " & to_hex_string(RB) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 3 segunda instrução: Verificando que Imed está no buffer de saída" severity note;
							if Imed = x"00000000" then
								report "Teste 3 da segunda instrução está correto" severity warning;
							end if;
        					assert Imed = x"00000000" severity error;
							report "Imed = " & to_hex_string(PC_id) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 4: segunda instrução: Verificando que PC_id está no buffer de saída: 20 ns" severity note;     
							if PC_id = x"00000004" then                       
								report "Teste 4: da segunda instrução está correto" severity warning;                               
        					end if;                                                      
	    					assert PC_id = x"00000004" severity error;
							report "PC_id = " & to_hex_string(PC_id) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 5: segunda instrução: Verificando que rs1 está no buffer de saída" severity note;
							if reg_rs1 = "00000" then  -- 
								report "Teste 5: da segunda instrução está correto" severity warning;
							end if;
        					assert reg_rs1 = "00000" severity error;
							report "reg_rs1 = " & to_hex_string(reg_rs1) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 6 segunda instrução: Verificando que rs2 está no buffer de saída" severity note;
							if reg_rs2 = "00000" then
								report "Teste 6 da segunda instrução está correto" severity warning;
							end if;
        					assert reg_rs2 = "00000" severity error;
							report "reg_rs2 = " & to_hex_string(reg_rs2) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 7 segunda instrução: Verificando que rd está no buffer de saída" severity note;
							if reg_rd = "00000" then
								report "Teste 7 da segunda instrução está correto" severity warning;
							end if;
        					assert reg_rd = "00000" severity error;
							report "reg_rd = " & to_hex_string(reg_rd) severity warning;
							report "=================================================================================  " severity warning;
							
							assert BEX_Data = x"00000000000004000000000000000000000000" severity warning;
							report "BEX_Data = " & to_hex_string(BEX_Data) severity warning;
							report "#################################################################################  " severity warning;
							
							if BEX_control = "000000000"then
								report "TESTE 8: segunda instrução Sinais de controle ==> ESTÃ0 CORRETOs" severity warning;
							else
								report "Teste 8: segunda instrução Sinais de controle ==> ESTÃ0 ERRADOS" severity error;
							end if;
							assert BEX_control = "000000000" severity error;
							report "BEX_control = " & to_string(BEX_control) severity warning;
							report "#################################################################################  " severity warning;
							report "#################################################################################  " severity warning;
							
							
				when 2 => 	--Teste da terceira instrução do programa swap: slli,t0,a1,2	==> 30 ns
							MemRead_ex 		<= '0';
							rd_ex			<= "01010";	
							rd_mem			<= "00001";
							report "=================================================================================  " severity warning;
							report "Count = " & to_string(count) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 1: terceira instrução: Verificando leitura de RA está no buffer de saída" severity note;
							if RA = x"00000000" then                 
       							report "Teste 1: da terceira instrução está correto" severity warning;                         
							end if;                                                     
							assert RA = x"00000000" severity error;
							report "RA = " & to_hex_string(RA) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 2: terceira instrução: Verificando leitura de RB" severity note;
							if RB = x"00000000" then
								report "Teste 2: da terceira instrução está correto" severity warning;
							end if;
        					assert RB = x"00000000" severity error;
							report "RB = " & to_hex_string(RB) severity warning;
						    report "=================================================================================  " severity warning;
						   	
							report "TESTE 3: terceira instrução: Verificando que Imed está no buffer de saída" severity note;
							if Imed = x"00000008" then
								report "Teste 3: da terceira instrução está correto" severity warning;
							end if;
        					assert Imed = x"00000008" severity error;
							report "Imed = " & to_hex_string(Imed) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 4: terceira instrução: Verificando que PC_id está no buffer de saída: 30 ns" severity note;     
							if PC_id = x"00000004" then                       
								report "Teste 4: da terceira instrução está correto" severity warning;                               
        					end if;                                                      
	    					assert PC_id = x"00000004" severity error;
							report "PC_id = " & to_hex_string(PC_id) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 5: terceira instrução: Verificando que rs1 está no buffer de saída" severity note;
							if reg_rs1 = "00000" then  -- 
								report "Teste 5: da terceira instrução está correto" severity warning;
							end if;
        					assert reg_rs1 = "00000" severity error;
							report "reg_rs1 = " & to_hex_string(reg_rs1) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 6: terceira instrução: Verificando que rs2 está no buffer de saída" severity note;
							if reg_rs2 = "01000" then
								report "Teste 6: da terceira instrução está correto" severity warning;
							else
								report "Teste 6: da terceira instrução reg_rs2 está errado" severity error;
							end if;
        					assert reg_rs2 = "01000" severity error;
							report "reg_rs2 = " & to_hex_string(reg_rs2) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 7: terceira instrução: Verificando que rd está no buffer de saída" severity note;
							if reg_rd = "00001" then
								report "Teste 7: da terceira instrução está correto" severity warning;
							end if;
        					assert reg_rd = "00001" severity error;
							report "reg_rd = " & to_hex_string(reg_rd) severity warning;
							report "=================================================================================  " severity warning;
							
							assert BEX_Data = x"050000000004000000080000000000000000" severity error;
							report "BEX_Data = " & to_hex_string(BEX_Data) severity warning;
							report "#################################################################################  " severity warning;
							
							
							if BEX_control = "101000000" then
								report "TESTE 8: terceira instrução Sinais de controle ==> ESTÃ0 CORRETOs" severity warning;
							else
								report "Teste 8: terceira instrução Sinais de controle ==> ESTÃ0 ERRADOS" severity error;
							end if;
							assert BEX_control = "101000000" severity error;
							report "BEX_control= " & to_string(BEX_control) severity warning;
							report "#################################################################################  " severity warning;
							report "#################################################################################  " severity warning;
							
							
							
				when 3 => 	--Teste da quarta instrução do programa	swap: add,t0,a0,0(t0)	==> 40 ns
							MemRead_ex 		<= '0';
							rd_ex			<= "01011";
							--rs2_id_ex		<= "00011";	
							rd_mem			<= "00000";	
							NPC_mem			<= x"00000008";
							report "=================================================================================  " severity warning;
							report "Count = " & to_string(count) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 1: quarta instrução: Verificando leitura de RA está no buffer de saída" severity note;
							if RA = x"00000000" then                 
       							report "Teste 1: da quarta instrução está correto" severity warning;                         
							end if;                                                     
							assert RA = x"00000000" severity error;
							report "RA = " & to_hex_string(RA) severity warning;
						    report "=================================================================================  " severity warning;
							
							report "TESTE 2: quarta instrução: Verificando leitura de RB" severity note;
							if RB = x"00000000" then
								report "Teste 2: da quarta instrução está correto" severity warning;
							end if;
        					assert RB = x"00000000" severity error;
							report "RB = " & to_hex_string(RB) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 3: quarta instrução: Verificando que Imed está no buffer de saída" severity note;
							if Imed = x"00000000" then
								report "Teste 3: da quarta instrução está correto" severity warning;
							end if;
        					assert Imed = x"00000000" severity error;
							report "Imed = " & to_hex_string(Imed) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 4: quarta instrução: Verificando que PC_id está no buffer de saída: 40 ns" severity note;     
							if PC_id= x"00000008" then                       
								report "Teste 4: da quarta instrução está correto" severity warning;                               
        					end if;                                                      
	    					assert PC_id = x"00000008" severity error;
							report "PC_id = " & to_hex_string(PC_id) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 5: quarta instrução: Verificando que rs1 está no buffer de saída" severity note;
							if reg_rs1 = "00000" then  -- 
								report "Teste 5: da quarta instrução está correto" severity warning;
							end if;
        					assert reg_rs1 = "00000" severity error;
							report "reg_rs1 = " & to_hex_string(reg_rs1) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 6: quarta instrução: Verificando que rs2 está no buffer de saída" severity note;
							if reg_rs2 = "00000" then
								report "Teste 6: da quarta instrução está correto" severity warning;
							end if;
        					assert reg_rs2 = "00000" severity error;
							report "reg_rs2 = " & to_hex_string(reg_rs2) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 7: quarta instrução: Verificando que rd está no buffer de saída" severity note;
							if reg_rd = "00000" then
								report "Teste 7: da quarta instrução está correto" severity warning;
							end if;
        					assert reg_rd = "00000" severity error;
							report "reg_rd = " & to_hex_string(reg_rd) severity warning;
							report "=================================================================================  " severity warning;
							
							assert BEX_Data = x"00000000000008000000000000000000000000" severity error;
							report "BEX_Data = " & to_hex_string(BEX_Data) severity warning;
							report "#################################################################################  " severity warning;
							
							report "BEX_control = " & to_hex_string(BEX_control) severity warning;
							if BEX(151 downto 143) = "000000000"then
								report "TESTE 8: quarta instrução Sinais de controle ==> ESTÃ0 CORRETOs" severity warning;
							else
								report "Teste 8: quarta instrução Sinais de controle ==> ESTÃ0 ERRADOS" severity error;
							end if;
							assert BEX_control = "000000000" severity error;
							report "BEX_control = " & to_string(BEX_control) severity warning;
							report "#################################################################################  " severity warning;
							report "#################################################################################  " severity warning;
							
				
				when 4 => 	--Teste da quinta instrução do programa swap: lw t1, 0(t0)		 ==> 50 ns 
							MemRead_ex 		<= '0';
							rd_ex			<= "01011";
							ula_ex			<= x"00000003";
							--rs1_id_ex		<= "01011";	
							--rs2_id_ex		<= "00010";  
							rd_mem			<= "01010";	  
							NPC_mem			<= x"0000000C";
							report "=================================================================================  " severity warning;
							report "Count = " & to_string(count) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 1: quinta instrução: Verificando leitura de RA está no buffer de saída" severity note;
							if RA = x"00000000" then                 
       							report "Teste 1: da quinta instrução está correto" severity warning;                         
							end if;                                                     
							assert RA = x"00000000" severity error;
							report "RA = " & to_hex_string(RA) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 2: quinta instrução: Verificando leitura de RB" severity note;
							if RB = x"00000000" then
								report "Teste 2: da quinta instrução está correto" severity warning;
							end if;
        					assert RB = x"00000000" severity error;
							report "RB = " & to_hex_string(RB) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 3: quinta instrução: Verificando que Imed está no buffer de saída" severity note;
							if Imed = x"00000000" then
								report "Teste 7\3: da quinta instrução está correto" severity warning;
							end if;
        					assert Imed = x"00000000" severity error;
							report "Imed = " & to_hex_string(Imed) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 4: quinta instrução: Verificando que PC_id está no buffer de saída: 50 ns" severity note;     
							if PC_id = x"0000000C" then                       
								report "Teste 4: da quinta instrução está correto" severity warning;                               
        					end if;                                                      
	    					assert PC_id = x"0000000C" severity error;
							report "PC_id = " & to_hex_string(PC_id) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 5: quinta instrução: Verificando que rs1 está no buffer de saída" severity note;
							if reg_rs1 = "01000" then  -- 
								report "Teste 5: da quarta instrução está correto" severity warning;
							end if;
							assert reg_rs1 = "00000" severity error;
							report "reg_rs1 = " & to_hex_string(reg_rs1) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 6: quinta instrução: Verificando que rs2 está no buffer de saída" severity note;
							if reg_rs2 = "00000" then
								report "Teste 6: da quinta instrução está correto" severity warning;
							end if;
        					assert reg_rs2 = "00000" severity error;
							report "reg_rs2 = " & to_hex_string(reg_rs2) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 7: quinta instrução: Verificando que rd está no buffer de saída" severity note; 
							if reg_rd = "01010" then
								report "Teste 7: da quinta instrução está correto" severity warning;
							end if;
        					assert reg_rd = "01010" severity error;
							report "reg_rd = " & to_hex_string(reg_rd) severity warning;
						    report "=================================================================================  " severity warning;
							
							assert BEX_Data = x"28000000000C000000000000000000000000" severity error;
							report "BEX_Data = " & to_hex_string(BEX_Data) severity warning;
							report "#################################################################################  " severity warning;
							
							report "BEX_control = " & to_hex_string(BEX_control) severity warning;
							if BEX_control = "001001000"then
								report "TESTE 8: quinta instrução Sinais de controle ==> ESTÃ0 CORRETOs" severity warning;
							else
								report "Teste 8: quinta instrução Sinais de controle ==> ESTÃ0 ERRADOS" severity error;
							end if;
							assert BEX_control = "001001000" severity error;
							report "BEX_control = " & to_string(BEX_control) severity warning;
							report "#################################################################################  " severity warning;
							report "#################################################################################  " severity warning;
							
							
				when 5 => 	 --Teste da sexta instrução do programa	swap: lw t2, 4(t0)	  ==> 60 ns
							MemRead_ex 		<= '1';
							rd_ex			<= "00101";
							ULA_ex			<= x"0000000C";
							--rs1_id_ex		<= "01010";	
							--rs2_id_ex		<= "00101";	
							rd_mem			<= "01011";
							ula_mem 		<= x"00000003";
							report "=================================================================================  " severity warning;
							report "Count = " & to_string(count) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 1: sexta instrução: Verificando leitura de RA está no buffer de saída" severity note;
							if RA = x"00000000" then                 
       							report "Teste 1: da sexta instrução está correto" severity warning;                         
							end if;                                                     
							assert RA = x"00000000" severity error; 
							report "RA = " & to_hex_string(RA) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 2: sexta instrução: Verificando leitura de RB" severity note;
							if RB = x"00000000" then
								report "Teste 2: da sexta instrução está correto" severity warning;
							end if;
        					assert RB = x"00000000" severity error;
							report "RB = " & to_hex_string(RB) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 3: sexta instrução: Verificando que Imed está no buffer de saída" severity note;
							if Imed = x"00000003" then
								report "Teste 3: da sexta instrução está correto" severity warning;
							end if;
        					assert Imed = x"00000003" severity error;
							report "Imed = " & to_hex_string(Imed) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 4: sexta instrução: Verificando que PC_id está no buffer de saída: 60 ns" severity note;     
							if PC_id = x"00000010" then                       
								report "Teste 1\4 da sexta instrução está correto" severity warning;                               
        					end if;                                                      
	    					assert PC_id = x"00000010" severity error;
							report "PC_id = " & to_hex_string(PC_id) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 5: sexta instrução: Verificando que rs1 está no buffer de saída" severity note;
							if reg_rs1 = "00000" then  -- 
								report "Teste 5: da sexta instrução está correto" severity warning;
							end if;
        					assert reg_rs1 = "00000" severity error;
							report "reg_rs1 = " & to_hex_string(reg_rs1) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 6: sexta instrução: Verificando que rs2 está no buffer de saída" severity note;
							if reg_rs2 = "00011" then
								report "Teste 6: da sexta instrução está correto" severity warning;
							end if;
        					assert reg_rs2 = "00011" severity error;
							report "reg_rs2 = " & to_hex_string(reg_rs2) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 7: sexta instrução: Verificando que rd está no buffer de saída" severity note;
							if reg_rd = "01011" then
								report "Teste 7: da sexta instrução está correto" severity warning;
							end if;
        					assert reg_rd = "01011" severity error;
							report "reg_rd = " & to_hex_string(reg_rd) severity warning;
							report "=================================================================================  " severity warning;
							
							assert BEX_Data = x"2C6000000010000000030000000000000000" severity error;
							report "BEX_Data = " & to_hex_string(BEX_Data);
							report "#################################################################################  " severity warning;
							
							report "BEX_control = " & to_hex_string(BEX_control) severity warning;
							if BEX_control = "001001000"then
								report "TESTE 8: sexta instrução Sinais de controle ==> ESTÃ0 CORRETOs" severity warning;
							else
								report "Teste 8: sexta instrução Sinais de controle ==> ESTÃ0 ERRADOS" severity error;
							end if;
							assert BEX_control = "001001000" severity error;
							report "BEX_control = " & to_string(BEX_control) severity warning;
							report "#################################################################################  " severity warning;
							report "#################################################################################  " severity warning;
							
				
				when 6 => 	--Teste da sétima instrução do programa swap: sw t2, 0(t0)	 ==> 70 ns
							MemRead_ex 		<= '1';
							rd_ex			<= "00110";
							--rs1_id_ex		<= "00101";	
							--rs2_id_ex		<= "00000";
							rd_mem			<= "00101";
							ula_mem 		<= x"0000000C";
							report "=================================================================================  " severity warning;
							report "Count = " & to_string(count) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 1: sétima instrução: Verificando leitura de RA está no buffer de saída" severity note;
							if RA = x"00000000" then                 
       							report "Teste 1: da sétima instrução está correto" severity warning;                         
							end if;                                                     
							assert RA = x"00000000" severity error;
							report "RA = " & to_hex_string(RA) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 2: sétima instrução: Verificando leitura de RB" severity note;
							if RB = x"00000000" then
								report "Teste 2: da sétima instrução está correto" severity warning;
							end if;
        					assert RB = x"00000000" severity error;
							report "RB = " & to_hex_string(RB) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 3: sétima instrução: Verificando que Imed está no buffer de saída" severity note;
							if Imed = x"00000002" then
								report "Teste 3: da sétima instrução está correto" severity warning;
							end if;
        					assert Imed = x"00000002" severity error;
							report "Imed = " & to_hex_string(Imed) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 4: sétima instrução: Verificando que PC_id está no buffer de saída: 70 ns" severity note;     
							if PC_id = x"00000014" then                       
								report "Teste 4: da sétima instrução está correto" severity warning;                               
        					end if;                                                      
	    					assert PC_id = x"00000014" severity error;
							report "PC_id = " & to_hex_string(PC_id) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 5: sétima instrução: Verificando que rs1 está no buffer de saída" severity note;
							if reg_rs1 = "01011" then
								report "Teste 5: da sétima instrução está correto" severity warning;
							end if;
        					assert reg_rs1 = "01011" severity error;
							report "reg_rs1 = " & to_hex_string(reg_rs1) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 6: sétima instrução: Verificando que rs2 está no buffer de saída" severity note; 
							if reg_rs2 = "00010" then
								report "Teste 5\6: da sétima instrução está correto" severity warning;
							end if;
        					assert reg_rs2 = "00010" severity error;
							report "reg_rs2 = " & to_hex_string(reg_rs2) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 7: sétima instrução: Verificando que rd está no buffer de saída" severity note;
							if reg_rd = "00101" then
								report "Teste 7: da sétima instrução está correto" severity warning;
							end if;
        					assert reg_rd = "00101" severity error;
							report "reg_rd = " & to_hex_string(reg_rd) severity warning;
							report "=================================================================================  " severity warning;
							
							assert BEX_Data = x"144B00000014000000020000000000000000" severity error;
							report "BEX_Data = " & to_hex_string(BEX_Data) severity warning;
							report "#################################################################################  " severity warning;
							
							report "BEX_control= " & to_hex_string(BEX_control) severity warning;
							if BEX_control = "001001011"then
								report "TESTE 8: setima instrução Sinais de controle ==> ESTÃ0 CORRETOs" severity warning;
							else
								report "Teste 8: setima instrução Sinais de controle ==> ESTÃ0 ERRADOS" severity error;
							end if;
							assert BEX_control = "001001011" severity error;
							report "BEX_control = " & to_string(BEX_control) severity warning;
							report "#################################################################################  " severity warning;
							report "#################################################################################  " severity warning;

				
				when 7 => 	--Teste da oitava instrução do programa swap: sw t1, 4(t0)	   ==> 80 ns
							MemRead_ex 		<= '1';
							rd_ex			<= "00110";	
							--rs2_id_ex		<= "00100";
							report "=================================================================================  " severity warning;
							report "Count = " & to_string(count) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 1: oitava instrução: Verificando leitura de RA está no buffer de saída" severity note;
							if RA = x"00000000" then                 
       							report "Teste 1: da oitava instrução está correto" severity warning;                         
							end if;                                                     
							assert RA = x"00000000" severity error;
							report "RA = " & to_hex_string(RA) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 2: oitava instrução: Verificando leitura de RB" severity note;
							if RB = x"00000000" then
								report "Teste 2: da oitava instrução está correto" severity warning;
							end if;
        					assert RB = x"00000000" severity error;
							report "RB = " & to_hex_string(RB) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 3: oitava instrução: Verificando que Imed está no buffer de saída" severity note;
							if Imed = x"00000000" then
								report "Teste 3: da oitava instrução está correto" severity warning;
							end if;
       						assert Imed = x"00000000" severity error; 
							report "Imed = " & to_hex_string(Imed) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 4: oitava instrução: Verificando que PC_id está no buffer de saída: 80 ns" severity note;     
							if PC_id = x"0000000018" then                       
								report "Teste 4: da oitava instrução está correto" severity warning;                               
        					end if;                                                      
	    					assert PC_id = x"00000018" severity error;
							report "PC_id = " & to_hex_string(PC_id) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 5: oitava instrução: Verificando que rs1 está no buffer de saída" severity note;
							if reg_rs1 = "01010" then  -- 
								report "Teste 5: da oitava instrução está correto" severity warning;
							end if;
        					assert reg_rs1 = "01010" severity error;
							report "reg_rs1 = " & to_hex_string(reg_rs1) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 6: oitava instrução: Verificando que rs2 está no buffer de saída" severity note;
							if reg_rs2 = "00101" then
								report "Teste 6: da oitava instrução está correto" severity warning;
							end if;
        					assert reg_rs2 = "00101" severity error;
							report "reg_rs2 = " & to_hex_string(reg_rs2) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 7: oitava instrução: Verificando que rd está no buffer de saída" severity note;
							if reg_rd = "00101" then
								report "Teste 7: da oitava instrução está correto" severity warning;
							end if;
        					assert reg_rd = "00101" severity error;
							report "reg_rd = " & to_hex_string(reg_rd) severity warning;
							report "=================================================================================  " severity warning;
							
							assert BEX_Data = x"0014AA00000018000000000000000000000000" severity error;
							report "BEX_ data = " & to_hex_string(BEX_Data) severity warning;
							report "#################################################################################  " severity warning;
							
							report "BEX_control = " & to_hex_string(BEX_control) severity warning;
							if BEX_control = "000000000"then
								report "TESTE 8: oitava instrução Sinais de controle ==> ESTÃ0 CORRETOs" severity warning;
							else
								report "Teste 8: oitava instrução Sinais de controle ==> ESTÃ0 ERRADOS" severity error;
							end if;
							assert BEX_control = "000000000" severity error;
							report "BEX_control = " & to_string(BEX_control) severity warning;
							report "#################################################################################  " severity warning;
							report "#################################################################################  " severity warning;
							
				
				when 8 => --Teste da nona instrução do programa swap: Jal zero, fim	   ==> 90 ns
							MemRead_ex 		<= '1';
							rd_ex			<= "00111";
							ULA_ex			<= x"00000010";
							--rs2_id_ex		<= "00111";
							MemRead_mem 	<= '1';
							rd_mem			<= "00110";
							report "=================================================================================  " severity warning;
							report "Count = " & to_string(count) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 1: nona instrução: Verificando leitura de RA está no buffer de saída" severity note;
							if RA = x"00000000" then                 
       							report "Teste 1: da nona instrução está correto" severity warning;                         
							end if;                                                     
							assert RA = x"00000000" severity error;
							report "RA = " & to_hex_string(RA) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 2: nona instrução: Verificando leitura de RB" severity note;
							if RB = x"00000000" then
								report "Teste 2: da nona instrução está correto" severity warning;
							end if;
        					assert RB = x"00000000" severity error;
							report "RB = " & to_hex_string(RB) severity warning;
							report "=================================================================================  " severity warning;
							report "TESTE 3: nona instrução: Verificando que Imed está no buffer de saída" severity note;
							if Imed = x"00000000" then
								report "Teste 3: da nona instrução está correto" severity warning;
							end if;
       						assert Imed = x"00000000" severity error;
							report "Imed = " & to_hex_string(Imed) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 4: nona instrução: Verificando que PC_id está no buffer de saída: 90 ns" severity note;     
							if PC_id = x"00000018" then                       
								report "Teste 4 da nona instrução está correto" severity warning;                               
        					end if;                                                      
	    					assert PC_id = x"00000018" severity error;
							report "PC_id = " & to_hex_string(PC_id) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 5: nona instrução: Verificando que rs1 está no buffer de saída" severity note;
							if reg_rs1 = "01010" then  -- 
								report "Teste 5: da nona instrução está correto" severity warning;
							end if;
        					assert reg_rs1 = "01010" severity error;
							report "reg_rs1 = " & to_hex_string(reg_rs1) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 6: nona instrução: Verificando que rs2 está no buffer de saída" severity note;
							if reg_rs2 = "00101" then
								report "Teste 6: da nona instrução está correto" severity warning;
							end if;
        					assert reg_rs2 = "00101" severity error;
							report "reg_rs2 = " & to_hex_string(reg_rs2) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 7: nona instrução: Verificando que rd está no buffer de saída" severity note;
							if reg_rd = "00101" then
								report "Teste 7: da nona instrução está correto" severity warning;
							end if;
        					assert reg_rd = "00101" severity error;
							report "reg_rd = " & to_hex_string(reg_rd) severity warning;
							report "=================================================================================  " severity warning;
							
							assert BEX_Data = x"14AA00000018000000000000000000000000" severity error;
							report "BEX_Data = " & to_hex_string(BEX_Data) severity warning;
							report "#################################################################################  " severity warning;
							
							report "BEX_control = " & to_hex_string(BEX_control) severity warning;
							if BEX_control = "001000000"then
								report "TESTE 8: nona instrução Sinais de controle ==> ESTÃ0 CORRETOs" severity warning;
							else
								report "Teste 8: nona instrução Sinais de controle ==> ESTÃ0 ERRADOS" severity error;
							end if;
							assert BEX_control = "001000000" severity error;
							report "BEX_control = " & to_string(BEX_control) severity warning;
							report "#################################################################################  " severity warning;
							report "#################################################################################  " severity warning;
							
							
				when 9 =>	--Teste da decima instrução do programa swap: Jal zero, fim	   ==> 100 ns
							MemRead_ex 		<= '0';
							rd_ex			<= "00000";
							ULA_ex			<= x"00000000"; 
							rd_mem			<= "00111";	
							ula_mem 		<= x"00000010";
							report "=================================================================================  " severity warning;
							report "Count = " & to_string(count) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 1 decima instrução: Verificando leitura de RA está no buffer de saída" severity note;
							if RA = x"00000000" then                 
       							report "Teste 1 da decima instrução está correto" severity warning;                         
							end if;                                                     
							assert RA = x"00000000" severity error;
							report "RA = " & to_hex_string(RA) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 2 decima instrução: Verificando leitura de RB" severity note;
							if RB = x"00000000" then
								report "Teste 2 da decima instrução está correto" severity warning;
							end if;
        					assert RB = x"00000000" severity error;
							report "RB = " & to_hex_string(RB) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 3 decima instrução: Verificando que Imed está no buffer de saída" severity note;
							if Imed = x"00000000" then
								report "Teste 3 da decima instrução está correto" severity warning;
							end if;
       						assert Imed = x"00000000" severity error;
							   report "Imed = " & to_hex_string(Imed) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 4 decima instrução: Verificando que PC_id está no buffer de saída: 90 ns" severity note;     
							if PC_id = x"0000001C" then                       
								report "Teste 4 da decima instrução está correto" severity warning;                               
        					end if;                                                      
	    					assert PC_id = x"0000001C" severity error;
							report "PC_id = " & to_hex_string(PC_id) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 5 decima instrução: Verificando que rs1 está no buffer de saída" severity note;
							if reg_rs1 = "00101" then  -- 
								report "Teste 5 da decima instrução está correto" severity warning;
							end if;
        					assert reg_rs1 = "00101" severity error;
							report "reg_rs1 = " & to_hex_string(reg_rs1) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 6 decima instrução: Verificando que rs2 está no buffer de saída" severity note;
							if reg_rs2 = "00000" then
								report "Teste 6 da decima instrução está correto" severity warning;
							end if;
        					assert reg_rs2 = "00000" severity error;
							report "reg_rs2 = " & to_hex_string(reg_rs2) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 7 decima instrução: Verificando que rd está no buffer de saída" severity note;
							if reg_rd = "00110" then
								report "Teste 7 da decima instrução está correto" severity warning;
							end if;
        					assert reg_rd = "00110" severity error;
							report "reg_rd = " & to_hex_string(reg_rd) severity warning;
							report "=================================================================================  " severity warning;
							
							assert BEX_Data = x"18050000001C000000000000000000000000" severity error;
							report "BEX_Data = " & to_hex_string(BEX_Data) severity warning;
							report "#################################################################################  " severity warning;
							
							report "BEX_control = " & to_hex_string(BEX_control) severity warning;
							if BEX_control = "011011000"then
								report "TESTE 8: decima instrução Sinais de controle ==> ESTÃ0 CORRETOs" severity warning;
							else
								report "Teste 8: decima instrução Sinais de controle ==> ESTÃ0 ERRADOS" severity error;
							end if;
							assert BEX_control = "011011000" severity error;
							report "BEX_control = " & to_string(BEX_control) severity warning;
							report "#################################################################################  " severity warning;
							report "#################################################################################  " severity warning;
							
							
				when 10 => 	--Terminaram as instruções do programa 
							--rs1_id_ex		<= "00000";
							--rs2_id_ex		<= "00110";
							rd_mem			<= "00000";
							MemRead_mem 	<= '0';
							ula_mem 		<= x"00000000";
							report "  ";
							report "=================================================================================  " severity warning;
							report "Count = " & to_string(count) severity warning;
							report "=================================================================================  " severity warning;
							
							null;
				
				when others => null;
			end case;
			count := count + 1;
        end if;
		eof       <= '1';
   		file_close(fptr);
		
    end process;
	
end architecture;
