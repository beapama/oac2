---------------------------------------------------------------------------------------------------
-----------MODULO ESTAGIO DE MEMORIA---------------------------------------------------------------
---------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all; 

library design;
use design.tipos.all;	

-- O est�gio de mem�ria � respons�vel por implementar os acessos a mem�ria de dados nas 
-- instru�oes de load e Store.
-- Nas demais instru�oes este est�gio nao realiza nenhuma opera�ao e passa simplesmente 
-- os dados recebidos para o est�gio wb de forma a viabilizar
-- o armazenamento das informa�oes nos registradores do Banco de registradores.
-- Os sinais de entrada e sa�da deste est�gio encontram-se definidos na declara�ao da 
-- entidade estagio_mem.

entity estagio_mem_13 is
    generic(
        dmem_init_file: string := "dmem.txt"		  		-- Arquivo inicializar a mem�ria de dados
    );
    port(
		-- Entradas
		clock		: in std_logic;						 	-- Base de tempo
        BMEM		: in std_logic_vector(115 downto 0); 	-- Informa�oes vindas do est�gio ex
		COP_mem		: in instruction_type;					-- Mnem�nico sendo processada no est�gio mem
		
		-- Sa�das
        BWB			: out std_logic_vector(103 downto 0) := (others => '0');-- Informa�oes para o wb
		COP_wb 		: out instruction_type := NOP;			-- Mnem�nico a ser processada pelo est�gio wb
		RegWrite_mem: out std_logic;						-- Escrita em regs no est�gio mem
		MemRead_mem	: out std_logic;						-- Leitura da mem�ria no est�gio mem 
		MemWrite_mem: out std_logic;						-- Escrita na memoria de dados no est�gio mem
		rd_mem		: out std_logic_vector(004 downto 0);	-- Destino nos regs. no estagio mem
		ula_mem		: out std_logic_vector(031 downto 0);	-- ULA no est�go mem para o est�gio mem
		NPC_mem		: out std_logic_vector(031 downto 0);	-- Valor do NPC no estagio mem
		Memval_mem	: out std_Logic_vector(031 downto 0)	-- Saida da mem�ria no est�gio mem
		
    );
end entity;

architecture estagio_mem_arch of estagio_mem_13 is
    -- Sinais internos
	signal MemToReg_mem : std_logic_vector(1 downto 0);
	signal RegWrite : std_logic;
	signal dado_arma_mem : std_logic_vector(31 downto 0);
	signal rs1_mem : std_logic_vector(4 downto 0);
	signal rs2_mem : std_logic_vector(4 downto 0);
	signal Memwrite_mem_s : std_logic;
	signal Memread_mem_s : std_logic;
	signal NPC_mem_s : std_logic_vector(31 downto 0);
	signal ULA_mem_s : std_logic_vector(31 downto 0);
	signal rd_mem_s : std_Logic_vector(4 downto 0);

	component data_ram is
		generic(
			address_bits		: integer 	:= 32;		  -- Bits de end. da mem�ria de dados
			size				: integer 	:= 4099;	  -- Tamanho da mem�ria de dados em Bytes
			data_ram_init_file	: string 	:= "dmem.txt" -- Arquivo da mem�ria de dados
		);
		port (
			-- Entradas
			clock 		: in  std_logic;							    -- Base de tempo bancada de teste
			write 		: in  std_logic;								-- Sinal de escrita na mem�ria
			address 	: in  std_logic_vector(address_bits-1 downto 0);-- Entrada de endere�o da mem�ria
			data_in 	: in  std_logic_vector(address_bits-1 downto 0);-- Entrada de dados da mem�ria
			
			-- Sa�da
			data_out 	: out std_logic_vector(address_bits-1 downto 0)	-- Sa�da de dados da mem�ria
		);
	end component data_ram;

begin
	MemToReg_mem <= BMEM(115 downto 114); -- Valor será escrito nos registradores
	RegWrite <= BMEM(113); -- Sinal de escrita nos registradores
	dado_arma_mem <= BMEM(046 downto 015); -- Valor a ser armazenado
	rs1_mem <= BMEM(014 downto 010); -- endereço do registrador rs1
	rs2_mem <= BMEM(009 downto 005); -- endereço do registrador rs2
	Memwrite_mem_s <= BMEM(112); -- Sinal de escrita na memória
	Memread_mem_s <= BMEM(111); -- Sinal de leitura da memória
	NPC_mem_s <= BMEM(110 downto 079); -- Endereço de retorno nas Jal e jalr
	ULA_mem_s <= BMEM(078 downto 047); -- Valor da saída da ULA
	rd_mem_s <= BMEM(004 downto 000); -- endereço do registrador a ser escrito
	
	dmem : data_ram port map (
		-- Entradas
		clock 		=> clock,
		write 		=> Memwrite_mem_s,
		address 	=> ULA_mem_s,
		data_in 	=> dado_arma_mem,
		data_out 	=> Memval_mem
	);
	
    -- Atribuição das saídas
	RegWrite_mem <= RegWrite;
	MemRead_mem	 <= Memread_mem_s;
	MemWrite_mem <= Memwrite_mem_s;
	rd_mem		 <= rd_mem_s;
	ula_mem		 <= ULA_mem_s;
	NPC_mem		 <= NPC_mem_s;

    -- Comportamento do estágio de memória
    process(clock)
    begin
        if rising_edge(clock) then
            -- Atribuição de BWB
            BWB(103 downto 102) <= MemToReg_mem; -- Valor que deve ser armazenado em registradores
			BWB(101) <= RegWrite_mem; -- Sinal de escrita em registradores
			BWB(100 downto 69) <= NPC_mem; -- End. de retorno nas chamada de sub-rotina-Jal ou JALR
			BWB(068 downto 37) <= ULA_mem; -- Valor vindo da saída da ula
			BWB(036 downto 05) <= Memval_mem; -- Valor da saída da memória
			BWB(004 downto 00) <= rd_mem; -- Endereço do registrador a ser escrito

            -- Atribuição de COP_wb
            COP_wb <= COP_mem;
        end if;
    end process;
end architecture;