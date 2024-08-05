---------------------------------------------------------------------------------------------------
------------MODULO BANCADA DE TESTE---------------------------------------------------------------
---------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_signed.all;
use std.textio.all;	

library design;
use design.tipos.all;

-- Bancada de teste do RISK-V Pipeline com todos os m�dulos que o compoem: estagio if, 
-- id, ex, mem e wb, m�dulos: hazard Detection, Forwarding,
-- RAM, Data RAM, ULA, Register File, unidade de controle.
-- Os arquivos de conte�dos das mem�ria de instru�oes - imem.txt (Cache de instru�oes) e 
-- da de dados dmem.txt( cache de Dados) encontram-se definidos
-- na declara�ao da entidade fd_if_id_ex_mem_wb	e sao chamados: "imem.txt" e "dmem.txt"	
-- Esta bancada de teste possui o processo estatistica que coleta todos os �ndices 
-- necess�rios para avalia�ao de desempenho do processador
-- Este bancda de teste tamb�m possui um processo chamado estimulo para controlar o fim 
-- da simula�ao quando uma instru�ao de halt for executada.

entity tb_if_id_ex_mem_wb_13 is
    generic(
        imem_init_file: string := "imem.txt";-- Arquivo com programa a ser executado
        dmem_init_file: string := "dmem.txt" -- Arquivo mem�ria de dados 
    );
end entity;

architecture tb_arch of tb_if_id_ex_mem_wb_13 is
	-- Estagio de Busca de instru�oes - if com buffer de sa�da - BID
    component estagio_if_13
        generic(
            imem_init_file: string := "imem.txt"
        );
        port(
			-- Entradas
			clock			: in 	std_logic;	-- Base de tempo vinda da bancada de teste
        	id_hd_hazard	: in 	std_logic;	-- Sinal de controle que carrega 0's na parte do RI do 
												-- registrador de sa�da do if_stage
			id_Branch_nop	: in 	std_logic;	-- Sinal que indica inser4�ao de NP devido a desviou pulo
			id_PC_Src		: in 	std_logic;	-- Sele�ao do mux da entrada do PC
			id_Jump_PC		: in 	std_logic_vector(31 downto 0) := x"00000000";-- Endere�o do Jump
			keep_simulating	: in	Boolean := True;-- Sinal de continue a simula�ao
			
			-- Sa�das
			--Registrador de sa�da do if_stage-if_id
        	BID				: out 	std_logic_vector(63 downto 0) := x"0000000000000000"
        );
    end component;
	
	-- Est�gio de decodifica�ao e leitura de registradores -id com buffer BEX
    component estagio_id_13
        port(
			-- Entradas
			clock				: in 	std_logic; 						--  Base de tempo
			BID					: in 	std_logic_vector(063 downto 0);	-- Informa�oes vindas do if
			MemRead_ex			: in	std_logic;						-- Leitura de mem�ria no ex
			rd_ex				: in	std_logic_vector(004 downto 0);	-- Destino noa regs. no ex
			ula_ex				: in 	std_logic_vector(031 downto 0);	-- ULA no est�gio Ex
			MemRead_mem			: in	std_logic;						-- Leitura na mem�ria no mem
			rd_mem				: in	std_logic_vector(04 downto 0);	-- Escrita nos regs. no mem	
			ula_mem				: in 	std_logic_vector(031 downto 0);	-- ULA no est�gio Mem
			NPC_mem				: in	std_logic_vector(031 downto 0);	-- NPC no estagio mem
        	RegWrite_wb			: in 	std_logic; 						-- Escrita no RegFile vindo de wb
        	writedata_wb		: in 	std_logic_vector(031 downto 0);	-- Escrito no RegFile vindo de wb
        	rd_wb				: in 	std_logic_vector(004 downto 0);	-- Registrador escrito
        	ex_fw_A_Branch		: in 	std_logic_vector(001 downto 0);	-- Sele�ao de Branch forwardA
        	ex_fw_B_Branch		: in 	std_logic_vector(001 downto 0);	-- Sele�ao de Branch forwardB
			
			-- Sa�das
			-- Endere�o destino do JUmp ou Desvio
			id_Jump_PC			: out	std_logic_vector(031 downto 0) := x"00000000";		
			id_PC_src			: out	std_logic := '0';				-- Seleciona a entrado do PC
			id_hd_hazard		: out	std_logic := '0';				-- Preserva o BID nao inc. o PC
			id_Branch_nop		: out	std_logic := '0';				-- Inser�ao de NOP devido Branch  
																		-- limpa o if_id.ri
			rs1_id_ex			: out	std_logic_vector(004 downto 0);	-- Endere�o rs1 no est�gio id
			rs2_id_ex			: out	std_logic_vector(004 downto 0);	-- Endere�o rs2 no est�gio id
			BEX					: out 	std_logic_vector(151 downto 0) := (others => '0'); 	-- ID > EX 
			COP_id				: out	instruction_type := NOP;-- Instrucao no id
			COP_ex				: out 	instruction_type := NOP	-- Instru�ao no EX
		);
    end component;
	
	-- Est�gio de execu�ao e calculo de endere�os - ex, combuffer de sa�da para o est�giomem chamado BMEM
	component estagio_ex_13
		port (
			clock				: in 	std_logic;					  		-- Rel�gio do Sistema
      		BEX					: in 	std_logic_vector (151 downto 0);  	-- Dados vindos do ide
			COP_ex				: in 	instruction_type;				  	-- Mnem�nico no est�gio ex
			ula_mem				: in 	std_logic_vector (031 downto 0);	-- ULA no mem
			rs1_id_ex			: in	std_logic_vector (004 downto 0);    -- rs1 no id passado para o ex
			rs2_id_ex			: in	std_logic_vector (004 downto 0);    -- rs2 no id passado para o ex
			MemRead_mem			: in 	std_logic;					  		-- Leitura na mem�ria no mem
			RegWrite_mem		: in 	std_logic;					  		-- Escrita nos regs. no mem
			rd_mem				: in 	std_logic_vector (04 downto 0);		-- Destino nos regs. no mem
			writedata_wb		: in 	std_logic_vector (031 downto 0);	-- Dado escrito no reg. destino
			RegWrite_wb			: in	Std_logic;							-- Escrita nos regs no  wb
			rd_wb				: in	std_logic_vector (004 downto 0);	-- Destino no rges no  wb
			MemVal_mem			: in	std_logic_vector (031 downto 0);	-- Sa�da da mem�ria no mem
		
			-- Sa�das
			MemRead_ex			: out	std_logic;							-- Leitura da mem�ria no ex 
			rd_ex				: out	std_logic_vector(04 downto 0);		-- Destino dos regs no ex
			ula_ex				: out	std_logic_vector(31 downto 0);		-- ULA no est�gio ex
			ex_fw_A_Branch		: out 	std_logic_vector (001 downto 0);	-- Dado comparado em A no id 
																			-- em desvios com forward
        	ex_fw_B_Branch		: out 	std_logic_vector (001 downto 0);	-- Dado a ser comparado 
																			-- no id em desvios forward
        	BMEM				: out 	std_logic_vector (115 downto 0) := (others => '0'); -- Sa�da mem
			COP_mem				: out 	instruction_type := NOP			  	-- Mnem�nico \no mem
		);
	end component; 
	
	-- Est�gio de Mem�ria mem, com buffer de sa�da para o est�gio wb chamado BWB
	component estagio_mem_13
		generic(
        	dmem_init_file: string := "dmem.txt"		  -- Nome do arquivo inicializar mem�ria de dados
    	);
    	port(
        	clock		: in std_logic;						 	-- Base de tempo
        	BMEM		: in std_logic_vector(115 downto 0); 	-- Informa�oes vindas do est�gio ex
			COP_mem		: in instruction_type;					-- Mnem�nico processada no mem
		
			-- Sa�das
        	BWB			: out std_logic_vector(103 downto 0) := (others => '0');-- Informa�oes para wb
			COP_wb 		: out instruction_type := NOP;			-- Mnem�nico dprocessada pelo  wb
			RegWrite_mem: out std_logic;						-- Escrita em regs no  mem
			MemRead_mem	: out std_logic;						-- Leitura da mem�ria de dados no mem 
			MemWrite_mem: out std_logic;						-- Escrita na memoria de dados no mem
			MemVal_mem	: out std_logic_vector(031 downto 0);	-- mem�ria no est�gio mem
			rd_mem		: out std_logic_vector(004 downto 0);	-- Destino nos regs. no  mem
			ula_mem		: out std_logic_vector(031 downto 0);	-- ULA no mem para o mem
			NPC_mem		: out std_logic_vector(031 downto 0)	-- NPC no  mem
		);
	end component;
	
	-- Estagio de Write-Back - wb cominforma�oes de saida para os demais est�gios \
	component estagio_wb_13
		port (
			-- Entradas
			BWB				: in std_logic_vector(103 downto 0); -- Informa�oes vindas do mem
			COP_wb			: in instruction_type;				 -- Mnem�nico da instru�ao no wb
		
			-- Sa�das
        	writedata_wb	: out std_logic_vector(31 downto 0); -- Valor a ser escrito em reg.
        	rd_wb			: out std_logic_vector(04 downto 0); -- Registrador a ser escrito
			RegWrite_wb		: out std_logic						 -- Escrita nos registradores
		);
	end component;

    --Sinais internos para conexao das portas de if
	signal clock			: std_logic := '1';	-- Base de tempo fornecida pela bancad de teste
    signal id_hd_hazard		: std_logic := '0';	-- Sinal de controle que carrega 0's em RI 
												-- do registrador de sa�da do if_stage
	signal id_Branch_nop	: std_logic := '0';	-- Sinal de inser�ao de nop devido 
												-- a desvio ou pulo
	signal id_PC_Src		: std_logic := '0';	-- Sele�ao do mux do PC
	signal id_Jump_PC		: std_logic_vector(31 downto 0) := x"00000000";	-- Endere�o Jump
     
	
	-- Per�odo do rel�gio do Pipeline
	constant clock_period		: time := 10 ns;

    --buffers entre os est�gios da pipeline
    signal BID: 	std_logic_vector(063 downto 0) := (others => '0');
    signal BEX: 	std_logic_vector(151 downto 0) := (others => '0');
	signal BMEM: 	std_logic_vector(115 downto 0) := (others => '0');
	signal BWB: 	std_logic_vector(103 downto 0) := (others => '0'); 
	
	-- Sinais para auxilio da depura�ao
	signal 		COP_id		: instruction_type 	:= NOP;
	signal 		COP_ex		: instruction_type 	:= NOP;
	signal 		COP_mem		: instruction_type 	:= NOP;
	signal 		COP_wb		: instruction_type 	:= NOP; 
 

    --sinais que conectam sa�da dos est�gios aos buffers 
	signal writedata_wb		: std_logic_vector(031 downto 0) := (others => '0');
	signal Memval_mem		: std_logic_vector(031 downto 0) := (others => '0');
    signal rd_wb			: std_logic_vector(004 downto 0) := (others => '0'); 
	signal RegWrite_wb		: std_logic;
	signal ula_mem			: std_logic_vector(31 downto 0);
	signal NPC_mem			: std_logic_vector(31 downto 0);
	signal MemRead_ex		: std_logic;
	signal rd_ex			: std_logic_vector(04 downto 0);
	signal rs1_id_ex		: std_logic_vector(04 downto 0);
	signal rs2_id_ex		: std_logic_vector(04 downto 0);
	signal ula_ex			: std_logic_vector(31 downto 0);
	signal ex_fw_A_branch	: std_logic_vector(01 downto 0);
	signal ex_fw_B_branch	: std_logic_vector(01 downto 0);
	signal MemRead_mem		: std_logic;
	signal MemWrite_mem		: std_logic;
	signal RegWrite_mem		: std_logic;
	signal rd_mem			: std_logic_vector(04 downto 0); 
	signal keep_simulating	: boolean := True; 
	signal eof           	:	std_logic 	:= '0';
--    file fptr				: 	text;
--	file fptr1				:	text;
	-- Para execucao com numero diferente de elementos deve mudar o nome do arquivo na linha seguinte e recompilar
	constant C_FILE_NAME_indices 	:	string  	:= "IndicesOut10.txt";
	constant C_FILE_NAME_perfil		:	string		:= "PerfilOut10.txt";
	
begin
	-- Conectando os sinais do est�gio if
    fetch : estagio_if_13
        generic map(
            imem_init_file => "imem.txt"
        )
        port map(
			-- Entradas
			clock				=> clock,
        	id_hd_hazard		=> id_hd_hazard,
			id_Branch_nop		=> id_Branch_nop,
			id_PC_Src			=> id_PC_Src,
			id_Jump_PC			=> id_Jump_PC,
			keep_simulating		=> keep_simulating,
			
			-- Sa�da
        	BID					=> BID
        );
	
	-- Conectando os sinais do est�gio id
    decode : estagio_id_13
        port map(
			-- Entradas
			clock				=> clock, 						--  Base de tempo
			BID					=> BID,							-- Informa�oes vindas  Busca
			MemRead_ex			=> MemRead_ex,					-- Leitura de mem�ria no ex
			rd_ex				=> rd_ex,						-- Destino noa regs. no ex
			ula_ex				=> ULA_ex,						-- ULA no est�gio Ex
			MemRead_mem			=> MemRead_mem,					-- Leitura na mem�ria no mem
			rd_mem				=> rd_mem,						-- Escrita nos regs no mem
			ula_mem				=> ULA_mem,						-- Sa�da da ULA no est�gio Mem 
			NPC_mem				=> NPC_mem,
        	RegWrite_wb			=> RegWrite_wb,					-- Escrita no RegFile no wb
        	writedata_wb		=> writedata_wb,				-- Escrito no RegFile no wb
        	rd_wb				=> rd_wb,						-- Registrador escrito
        	ex_fw_A_Branch		=> ex_fw_A_Branch,				-- Sele�ao de Branch forwardA
        	ex_fw_B_Branch		=> ex_fw_B_Branch,				-- Sele�ao de Branch forwardB 
			
			-- Sa�das
			id_Jump_PC			=> id_Jump_PC,					-- Endere�o destino do JUmp/Desvio
			id_PC_src			=> id_PC_src,					-- Seleciona a entrado do PC
			id_hd_hazard		=> id_hd_hazard,				-- Preserva o if_id e nao inc. PC
			id_Branch_nop		=> id_Branch_nop,				-- Sinaliza a inser�ao de um NOP 
																-- devido ao Branch. limpa o if_id.ri	
			rs1_id_ex			=> rs1_id_ex,					-- Endere�o rs1 no est�gio id
			rs2_id_ex			=> rs2_id_ex,					-- Endere�o rs2 no est�gio id
			BEX					=> BEX,							-- Sa�da do ID para o EX
			COP_id				=> COP_id,						-- Instrucao no est�gio id
			COP_ex				=> COP_ex						-- Instru�ao passada para EX
        );
		
	-- Conectando os sinais do est�gio ex	
	executa: estagio_ex_13
		port map(
			-- Entradas
			clock				=> clock,			-- Rel�gio do Sistema
      		BEX					=> BEX, 			-- Dados vindos do est�gio Decode
			COP_ex				=> COP_ex,			-- Mnem�nico no est�gio ex
			ula_mem				=> ula_mem,			-- ULA no est�gio de Mem�ria
			rs1_id_ex			=> rs1_id_ex,   	-- rs1 no id passado o ex
			rs2_id_ex			=> rs2_id_ex,   	-- rs2 no id passado o ex
			MemRead_mem			=> MemRead_mem,		-- Leitura na mem�ria no est�gio mem
			RegWrite_mem		=> RegWrite_mem,	-- Escrita nos regs. no est�gio mem
			rd_mem				=> rd_mem,			-- Destino nos regs. no est�gio mem
			writedata_wb		=> writedata_wb,	-- Dado a ser escrito no reg. destino
			MemVal_mem			=> MemVal_mem,		-- Sa�da da mem�ria no mem
			RegWrite_wb			=> RegWrite_wb,		-- Sinal de escrita nos regs no wb
			rd_wb				=> rd_wb,			-- endere�o de destino no rges no wb
		
			-- Sa�das
			MemRead_ex			=> MemRead_ex,		-- Leitura da mem�ria no ex 
			rd_ex				=> rd_ex,			-- Destino dos regs no ex
			ULA_ex				=> ULA_ex,			-- Sa�da da ULA no est�gio ex
			ex_fw_A_Branch		=> ex_fw_A_Branch,	-- Comparado em A no id-desvios-forward
        	ex_fw_B_Branch		=> ex_fw_B_Branch,	-- Dado comparado em B no id desvios-forward
        	BMEM				=> BMEM, 			-- Sa�da para o est�gio de Mem�ria
			COP_mem				=> COP_mem			 -- Mnem�nico da instru�ao mem
		);
		
	-- Conectando os sinais do est�gio mem	
	memoria:estagio_mem_13
		generic map (
        	dmem_init_file  => "dmem.txt" -- Nome do arquivo para inicializar a mem�ria de dados
    	)
   		port map (
		   	-- Entradas
		   	clock			=> clock,		-- Base de tempo
        	BMEM			=> BMEM,		-- Informa�oes vindas do est�gio ex
			COP_mem			=> COP_mem,		-- Mnem�nico da instru�ao sendo processada no est�gio mem
		
			-- Sa�das
       	 	BWB				=> BWB,			-- Informa�oes sendo enviadas para o est�gio wb
			COP_wb 			=> COP_wb,		-- Mnem�nico da instru�ao a ser processada pelo est�gio wb
			RegWrite_mem 	=> RegWrite_mem,-- Sinal de escrita em regs no est�gio mem
			MemRead_mem		=> MemRead_mem,	-- Sinal de leitura da mem�ria de daods no est�gio mem 
			MemWrite_mem	=> MemWrite_mem, -- Sinal de escrita na memoria de dados no estagio mem
			MemVal_mem		=> MemVal_mem,	-- Sa�da da mem�ria no estagio mem
			rd_mem			=> rd_mem,		-- Endere�o de destino nos rges. no est�gio mem
			ula_mem			=> ula_mem,		-- Sa�da da ULA no est�go mem para o est�gio mem
			NPC_mem			=> NPC_mem		-- Valor do NPC no estagio mem
    	);
		
	-- Conectando os sinais do est�gio wb	
	writeback: estagio_wb_13
		port map (
			-- Entradas
			BWB				=> BWB, 			-- Informa�oes vindas do estagi mem
			COP_wb			=> COP_wb,			-- Mnem�nico da instru�ao no estagio wb
			
			-- Sa�das
        	writedata_wb	=> writedata_wb, 	-- Valor a ser escrito emregistradores
        	rd_wb			=> rd_wb, 			-- Endere�o do registrador a ser escrito
			RegWrite_wb		=> RegWrite_wb		-- Sinal de escrita nos registradores
		);
	
	-- Rel�gio do Pipeline comper�odo definido pela constnate clock_period
 	clock <= not clock after clock_period / 2 when Keep_simulating = true else
		     clock after clock_period;
 
--processo de coleta de estat�sticas
estatisticas: process (clock)
	-- Para execucoes com numero diferente de elemento deve mudar o vakir da variavel na linha seguinte e recompilar
	variable numelementos					: 	integer :=  10;
	variable num_inst						: 	integer :=  0;
	variable num_ciclos						:	integer := 	0;
	variable num_acessos_leitura_dmem		:	integer := 	0;
	variable num_acessos_escrita_dmem		:	integer := 	0;
	variable num_bolhas						:	integer := -4;
	variable num_add						:	integer := 	0;
	variable num_addi						:	integer := 	0;
	variable num_slli						:	integer := 	0;
	variable num_slti						:	integer := 	0;
	variable num_srli						:	integer := 	0; 
	variable num_srai						:	integer := 	0;
	variable num_slt						:	integer := 	0;
	variable num_beq						:	integer := 	0; 
	variable num_bne						:	integer := 	0;
	variable num_blt						:	integer := 	0;
	variable num_lw							:	integer := 	0;
	variable num_sw							:	integer := 	0;
	variable num_jal						:	integer := 	0;
	variable num_jalr						:	integer := 	0;
	variable num_nop						:	integer := -4;
	variable num_halt						:	integer :=  0;
	variable CPI_medio						:	real	:= 0.0;	
	variable fstatus       					:	file_open_status;
    variable file_line     					:	line;
	variable virgula						:	string (1 to 2)	:= ", ";	
	
    
	
	
begin
	
		if clock'event and clock = '1' then	
			if COP_wb /= NOP then 
				num_inst 		:= num_inst 	+ 1;
			end if;
			num_ciclos 		:= num_ciclos 	+ 1; 			
			if MemRead_mem = '1' 	then 
				num_acessos_leitura_dmem := num_acessos_leitura_dmem + 1; 	
			end if;
			if MemWrite_mem = '1'then
				num_acessos_escrita_dmem := num_acessos_escrita_dmem + 1;
			end if;
			if COP_wb = NOP	 then num_bolhas:= num_bolhas 	+ 1; end if;	
			if COP_wb = ADD  then num_add  	:= num_add 		+ 1; end if;
			if COP_wb = addi then num_addi 	:= num_addi 	+ 1; end if;
			if COP_wb = slli then num_slli 	:= num_slli 	+ 1; end if;
			if COP_wb = slti then num_slti 	:= num_slti 	+ 1; end if;
			if COP_wb = srli then num_srli 	:= num_srli 	+ 1; end if;
			if COP_wb = srai then num_srai 	:= num_srai 	+ 1; end if;
			if COP_wb = slt  then num_slt  	:= num_slt 		+ 1; end if;
			if COP_wb = beq  then num_beq  	:= num_beq 		+ 1; end if;
			if COP_wb = bne  then num_bne  	:= num_bne 		+ 1; end if;
			if COP_wb = blt  then num_blt  	:= num_blt 		+ 1; end if;
			if COP_wb = lw	 then num_lw   	:= num_lw 		+ 1; end if;
			if COP_wb = sw	 then num_sw   	:= num_sw 		+ 1; end if;
			if COP_wb = jal  then num_jal  	:= num_jal 		+ 1; end if;
			if COP_wb = jalr then num_jalr 	:= num_jalr 	+ 1; end if; 
			if COP_wb = nop  then num_nop	:= num_nop		+ 1; end if;
			if COP_wb = halt then num_halt  := num_halt		+ 1; end if;
		else
			null;
		end if;
		if num_inst > 0 then 
			CPI_medio := real(real(num_ciclos)/real(num_inst)); 
		else 
			CPI_medio := 0.0;
		end if;	
		-- Registro em arquivo CVS dos dados de desempenho edo processador e do perfil de instru'c~oes executadas
--		if COP_wb = HALT then
			-- Abre o arquivo para escrever os indices de desempenho
--			file_open(fstatus, fptr,  C_FILE_NAME_indices, write_mode);
--			file_open(fstatus, fptr1, C_FILE_NAME_perfil, write_mode);
--			For i in 1	to 1 loop
--				-- primeira linha do arquivo com o nomes das variaveis de desempenho
--				write(file_line, "num_elementos" , right, 2);
--				write(file_line, virgula, right, 2);
--				write(file_line, "num_inst" , right, 2);
--				write(file_line, virgula, right, 2);
--				write(file_line, "num_ciclos" , right, 2);
--				write(file_line, virgula, right, 2);
--				write(file_line, "num_bolhas" , right, 2);
--				write(file_line, virgula, right, 2);
--				write(file_line, "num_acessos_leitura" , right, 2);
--				write(file_line, virgula, right, 2);
--				write(file_line, "num_acessos_escrita" , right, 2);
--				write(file_line, virgula, right, 2);
--				write(file_line, "CPI_medio" , right, 2);
--				write(file_line, virgula, right, 2);
--				writeline(fptr, file_line);
--				-- segunda linha do arquivo agora com os dados
--	 	 		write(file_line, to_string(numelementos), right, 2);
--	  			write(file_line, virgula, right, 2);
--      			write(file_line, to_string(num_inst), right, 2);
--	  			write(file_line, virgula, right, 2);
--      			write(file_line, to_string(num_ciclos), right, 2);
--	  			write(file_line, virgula, right, 2);
--	  			write(file_line, to_string(num_bolhas), right, 2);
--	  			write(file_line, virgula, right, 2);
--	  			write(file_line, to_string(num_acessos_leitura_dmem), right, 2);
--	  			write(file_line, virgula, right, 2);
--	  			write(file_line, to_string(num_acessos_escrita_dmem), right, 2);
--	  			write(file_line, virgula, right, 2);
--      			write(file_line, to_string(CPI_medio), right, 2);
--	  			write(file_line, virgula, right, 2);
--      			writeline(fptr, file_line);
--			   -- primeira linha do arquivo de perfil de instrucoes
--			    write(file_line, "num_elementos" , right, 2);
--				write(file_line, virgula, right, 2);
--				write(file_line, "num_add" , right, 2);
--				write(file_line, virgula, right, 2);
--				write(file_line, "num_addi" , right, 2);
--				write(file_line, virgula, right, 2);
--				write(file_line, "num_slli" , right, 2);
--				write(file_line, virgula, right, 2);
--				write(file_line, "num_slti" , right, 2);
--				write(file_line, virgula, right, 2);
--				write(file_line, "num_srli" , right, 2);
--				write(file_line, virgula, right, 2);
--				write(file_line, "num_srai" , right, 2);
--				write(file_line, virgula, right, 2);
--				write(file_line, "num_slt" , right, 2);
--				write(file_line, virgula, right, 2);
--				write(file_line, "num_beq" , right, 2);
--				write(file_line, virgula, right, 2);
--				write(file_line, "num_bne" , right, 2);
--				write(file_line, virgula, right, 2);
--				write(file_line, "num_blt" , right, 2);
--				write(file_line, virgula, right, 2);
--				write(file_line, "num_lw" , right, 2);
--				write(file_line, virgula, right, 2);
--				write(file_line, "num_sw" , right, 2);
--				write(file_line, virgula, right, 2);
--				write(file_line, "num_jal" , right, 2);
--				write(file_line, virgula, right, 2);
--				write(file_line, "num_jalr" , right, 2);
--				write(file_line, virgula, right, 2);
--				write(file_line, "num_halt" , right, 2);
--				write(file_line, virgula, right, 2);
--				writeline(fptr1, file_line);	
--				-- escreve a segunda linha do arquivo de perfil de instrucoes
--				write(file_line, to_string(numelementos), right, 2);
--	  			write(file_line, virgula, right, 2);
--				write(file_line, to_string(num_add), right, 2);
--	  			write(file_line, virgula, right, 2);
--				write(file_line, to_string(num_addi), right, 2);
--	  			write(file_line, virgula, right, 2); 
--				write(file_line, to_string(num_slli), right, 2);
--	  			write(file_line, virgula, right, 2);
--				write(file_line, to_string(num_slti), right, 2);
--	  			write(file_line, virgula, right, 2);
--				write(file_line, to_string(num_srli), right, 2);
--	  			write(file_line, virgula, right, 2);
--				write(file_line, to_string(num_srai), right, 2);
--	  			write(file_line, virgula, right, 2);
--				write(file_line, to_string(num_slt), right, 2);
--	  			write(file_line, virgula, right, 2);
--				write(file_line, to_string(num_beq), right, 2);
--	  			write(file_line, virgula, right, 2);
--				write(file_line, to_string(num_bne), right, 2);
--	  			write(file_line, virgula, right, 2);
--				write(file_line, to_string(num_blt), right, 2);
--	  			write(file_line, virgula, right, 2);
--				write(file_line, to_string(num_lw), right, 2);
--	  			write(file_line, virgula, right, 2);
--				write(file_line, to_string(num_sw), right, 2);
--	  			write(file_line, virgula, right, 2);
--				write(file_line, to_string(num_jal), right, 2);
--	  			write(file_line, virgula, right, 2);
--				write(file_line, to_string(num_jalr), right, 2);
--	  			write(file_line, virgula, right, 2);
--				write(file_line, to_string(num_halt), right, 2);
--	  			write(file_line, virgula, right, 2);
--				writeline(fptr1, file_line);	
--   			end loop;
--		end if;
--   		eof       <= '1';
--   		file_close(fptr);
--		file_close(fptr1);   
end process; 

estimulos: process

variable inicio: boolean := true;

begin
	wait until clock'event and clock = '1';
	if inicio then
		inicio := false;
	else
		assert false report "Inicie execu�ao."severity note;
		keep_simulating 	<= true;
		wait for 4*clock_Period;
		wait until COP_wb = HALT;
		wait for clock_period;
		keep_simulating 	<= false;
		assert false report "Para execu�ao." severity note;	
		wait for clock_period;
		wait; 
	end if;
end process;
    
end architecture;