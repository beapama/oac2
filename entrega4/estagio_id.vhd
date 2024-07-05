----------------------------------------------------------------------------------------------
----------MODULO ESTAGIO DE DECODIFICA�AO E REGISTRADORES-------------------------------------
----------------------------------------------------------------------------------------------
library ieee; 
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_signed.all;

library work;
use work.tipos.all;

-- O est�gio de decodifica�ao e leitura de registradores (id) deve realizar a decodifica�ao 
-- da instru�ao lida no est�gio de
-- busca (if) e produzir os sinais de controle necess�rios para este est�gio, assim como para todos os 
-- demais est�gios a seguir.
-- Al�m disso ele deve realizar a descisao dos desvios condicionais assim como calcular o endere�o de 
-- destino para executar essas instru�oes.
-- Lembrar que no Pipeline com detec�ao de Hazards e antecipa�ao ("Forwarding"), existirao sinais que
-- influenciarao as decisoes tomadas neste est�gio.
-- Neste est�gio deve ser feita tamb�m a gera�ao dos valores imediatos para todas as instru�oes. 
-- Aten�ao especial deve ser dada a esses imediatos pois o RISK-V optou por embaralhar os 
-- imediatos para manter todos os endere�os de regostradores nas instru�oes nas mesmas posi�oes 
-- na instru�ao. 
-- As informa�oes passadas deste est�gio para os seguintes devem ser feitas por meio de um 
-- registrador (BID). Para
-- identificar claramente cada campo desse registrador pode-se utilizar o mecanismo do VHDL de defini�ao 
-- de apelidos ("alias").
-- Foi adicionado um sinal para fins de ilustra�ao chamado COP_id que identifica a instru�ao sendo 
-- processada pelo est�gio.
-- Neste est�gio deve ser implementado tamb�m o m�dulo de detec�ao de conflitos - Hazards.
-- Devem existir diversos sinais vindos do outros m�dulos que sao necess�rios para a reliza�ao das 
-- fun�oes alocadas a este est�gio de decodifica�ao - id.
-- A defini�ao dos sinais vindos de outros m�dulos encontra-se nos coment�rios da declara�ao de 
-- entidade do est�gio id.

entity estagio_id is
    port(
		-- Entradas
		clock				: in 	std_logic; 						-- Base de tempo- bancada de teste
		BID					: in 	std_logic_vector(063 downto 0);	-- Informa�oes vindas est�gio Busca
		MemRead_ex			: in	std_logic;						-- Leitura de mem�ria no estagio ex
		rd_ex				: in	std_logic_vector(004 downto 0);	-- Destino nos regs. no est�gio ex
		ula_ex				: in 	std_logic_vector(031 downto 0);	-- Sa�da da ULA no est�gio Ex
		MemRead_mem			: in	std_logic;						-- Leitura na mem�ria no est�gio mem
		rd_mem				: in	std_logic_vector(004 downto 0);	-- Escrita nos regs. no est'agio mem
		ula_mem				: in 	std_logic_vector(031 downto 0);	-- Sa�da da ULA no est�gio Mem 
		NPC_mem				: in	std_logic_vector(031 downto 0); -- Valor do NPC no estagio mem
        RegWrite_wb			: in 	std_logic; 						-- Escrita no RegFile vindo de wb
        writedata_wb		: in 	std_logic_vector(031 downto 0);	-- Valor escrito no RegFile - wb
        rd_wb				: in 	std_logic_vector(004 downto 0);	-- Endere�o do registrador escrito
        ex_fw_A_Branch		: in 	std_logic_vector(001 downto 0);	-- Sele�ao de Branch forwardA
        ex_fw_B_Branch		: in 	std_logic_vector(001 downto 0);	-- Sele�ao de Branch forwardB 
		
		-- Sa�das
		id_Jump_PC			: out	std_logic_vector(031 downto 0) := x"00000000";-- Destino JUmp/Desvio
		id_PC_src			: out	std_logic := '0';				-- Seleciona a entrado do PC
		id_hd_hazard		: out	std_logic := '0';				-- Preserva o if_id e nao inc. PC
		id_Branch_nop		: out	std_logic := '0';				-- Inser�ao de um NOP devido ao Branch. 
																	-- limpa o if_id.ri
		rs1_id_ex			: out	std_logic_vector(004 downto 0);	-- Endere�o rs1 no est�gio id
		rs2_id_ex			: out	std_logic_vector(004 downto 0);	-- Endere�o rs2 no est�gio id
		BEX					: out 	std_logic_vector(151 downto 0) := (others => '0');-- Sa�da do ID > EX
		COP_id				: out	instruction_type  := NOP;		-- Instrucao no estagio id
		COP_ex				: out 	instruction_type := NOP			-- Instru�ao no est�gio id passada> EX
    );
end entity;

architecture Behavioral of estagio_id is
    -- Declaração de sinais internos
    signal opcode : std_logic_vector(6 downto 0);
    signal funct3 : std_logic_vector(2 downto 0);
    signal funct7 : std_logic_vector(6 downto 0);
    signal rs1, rs2, rd : std_logic_vector(4 downto 0);
    signal imm : std_logic_vector(31 downto 0);
    signal instruction : std_logic_vector(31 downto 0);
    signal RegWrite_id, MemRead_id, MemWrite_id, AluSrc_id, MemToReg_id : std_logic;
    signal AluOp_id : std_logic_vector(2 downto 0);
    signal PC_id : std_logic_vector(31 downto 0);
    signal RA_id, RB_id : std_logic_vector(31 downto 0);

begin
    -- Extração dos campos da instrução
    instruction <= BID(31 downto 0);
    PC_id <= BID(63 downto 32);
    opcode <= instruction(6 downto 0);
    rd <= instruction(11 downto 7);
    funct3 <= instruction(14 downto 12);
    rs1 <= instruction(19 downto 15);
    rs2 <= instruction(24 downto 20);
    funct7 <= instruction(31 downto 25);

    -- Geração dos valores imediatos
    process(opcode, instruction)
    begin
        case opcode is
            when "0010011" => -- Tipo I
                imm <= (31 downto 12 => instruction(31)) & instruction(30 downto 20);
            when "0100011" => -- Tipo S
                imm <= (31 downto 12 => instruction(31)) & instruction(30 downto 25) & instruction(11 downto 7);
            when "1100011" => -- Tipo B (Branch)
                imm <= (31 downto 12 => instruction(31)) & instruction(7) & instruction(30 downto 25) & instruction(11 downto 8) & "0";
            when "1101111" => -- Tipo J (Jal)
                imm <= (31 downto 12 => instruction(31)) & instruction(19 downto 12) & instruction(20) & instruction(30 downto 21) & "0";
            when "1100111" => -- Tipo I (Jalr)
                imm <= (31 downto 12 => instruction(31)) & instruction(30 downto 20);
            -- Adicionar mais casos conforme necessário
            when others =>
                imm <= (others => '0');
        end case;
    end process;

    -- Geração dos sinais de controle
    process(opcode, funct3, funct7)
    begin
        -- Valores padrão
        RegWrite_id <= '0';
        MemRead_id <= '0';
        MemWrite_id <= '0';
        AluSrc_id <= '0';
        MemToReg_id <= '0';
        AluOp_id <= "000";

        case opcode is
            when "0110011" => -- Tipo R
                RegWrite_id <= '1';
                AluOp_id <= "010";
            when "0010011" => -- Tipo I
                RegWrite_id <= '1';
                AluSrc_id <= '1';
                case funct3 is
                    when "000" => AluOp_id <= "000"; -- ADDI
                    when "010" => AluOp_id <= "011"; -- SLTI
                    -- Adicionar mais casos conforme necessário
                    when others => AluOp_id <= "000";
                end case;
            when "0000011" => -- LW
                RegWrite_id <= '1';
                MemRead_id <= '1';
                AluSrc_id <= '1';
                MemToReg_id <= '1';
                AluOp_id <= "000"; -- ADD
            when "0100011" => -- SW
                MemWrite_id <= '1';
                AluSrc_id <= '1';
                AluOp_id <= "000"; -- ADD
            when "1101111" => -- JAL
                RegWrite_id <= '1';
                id_Jump_PC <= std_logic_vector(signed(PC_id) + signed(imm));
                id_PC_src <= '1';
            when "1100111" => -- JALR
                RegWrite_id <= '1';
                id_Jump_PC <= std_logic_vector(signed(RA_id) + signed(imm));
                id_PC_src <= '1';
            when "1100011" => -- Branch
                -- Calculo do endereço de desvio condicional
                id_Jump_PC <= std_logic_vector(signed(PC_id) + signed(imm));
                id_PC_src <= '1';
                id_Branch_nop <= '1';
            -- Adicionar mais casos conforme necessário
            when others =>
                RegWrite_id <= '0';
                MemRead_id <= '0';
                MemWrite_id <= '0';
                AluSrc_id <= '0';
                MemToReg_id <= '0';
                AluOp_id <= "000";
        end case;
    end process;

    -- Atribuição dos endereços de registradores
    rs1_id_ex <= rs1;
    rs2_id_ex <= rs2;

    -- Atribuição dos sinais de controle ao BEX
    BEX(151 downto 150) <= MemToReg_id & MemToReg_id;
    BEX(149) <= RegWrite_id;
    BEX(148) <= MemWrite_id;
    BEX(147) <= MemRead_id;
    BEX(146) <= AluSrc_id;
    BEX(145 downto 143) <= AluOp_id;
    BEX(142 downto 138) <= rd;
    BEX(137 downto 133) <= rs2;
    BEX(132 downto 128) <= rs1;
    BEX(127 downto 96) <= std_logic_vector(unsigned(PC_id) + 4); -- PC_id_Plus4
    BEX(95 downto 64) <= imm;
    BEX(63 downto 32) <= RB_id;
    BEX(31 downto 0) <= RA_id;

    -- Atribuição dos sinais de controle ao COP
    --COP_id <= opcode; -- Exemplo simplificado, ajustar conforme necessário
    COP_ex <= COP_id;

    -- Detecção de Conflitos
    process(clock)
    begin
        if rising_edge(clock) then
            -- Inicializar sinais de hazard
            id_hd_hazard <= '0';
            id_Branch_nop <= '0';

            -- Hazard de leitura após escrita (RAW) - Confere os estágios EX e MEM
            if (MemRead_ex = '1' and (rd_ex /= "00000") and (rd_ex = rs1 or rd_ex = rs2)) then
                id_hd_hazard <= '1'; -- Hazard detectado, preservar o pipeline
            elsif (MemRead_mem = '1' and (rd_mem /= "00000") and (rd_mem = rs1 or rd_mem = rs2)) then
                id_hd_hazard <= '1'; -- Hazard detectado, preservar o pipeline
            end if;

            -- Branch Hazard
            if (opcode = "1100011") then -- Verifica instruções de branch
                id_Branch_nop <= '1'; -- Inserir NOP no próximo estágio
            end if;

        end if;
    end process;

end Behavioral;
