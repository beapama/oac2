library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;

entity forwarding_unit_13 is
  port (
    -- Entradas
    rs1_id_ex : in std_logic_vector(4 downto 0); -- Registrador fonte 1
    rs2_id_ex : in std_logic_vector(4 downto 0); -- Registrador fonte 2
    rd_mem : in std_logic_vector(4 downto 0); -- Registrador destino do estágio MEM
    rd_wb : in std_logic_vector(4 downto 0); -- Registrador destino do estágio WB
    regwrite_mem : in std_logic; -- Sinal de escrita no registrador no estágio MEM
    regwrite_wb : in std_logic; -- Sinal de escrita no registrador no estágio WB
    result_mem : in std_logic_vector(31 downto 0); -- Resultado da ULA no estágio MEM
    result_wb : in std_logic_vector(31 downto 0); -- Resultado da ULA no estágio WB
    -- Saídas
    forward_a : out std_logic_vector(1 downto 0); -- Seleção de encaminhamento para operando A
    forward_b : out std_logic_vector(1 downto 0)  -- Seleção de encaminhamento para operando B
  );
end forwarding_unit_13;

architecture forwarding_unit_arch_13 of forwarding_unit_13 is
begin
  process(rs1_id_ex, rs2_id_ex, rd_mem, rd_wb, regwrite_mem, regwrite_wb)
  begin
    -- Inicializa os sinais de forwarding com '00' (sem encaminhamento)
    forward_a <= "00";
    forward_b <= "00";

    -- Verifica necessidade de encaminhamento para rs1_id_ex (operando A)
    if regwrite_mem = '1' and rd_mem /= "00000" and rd_mem = rs1_id_ex then
      forward_a <= "10"; -- Encaminha resultado do estágio MEM
    elsif regwrite_wb = '1' and rd_wb /= "00000" and rd_wb = rs1_id_ex then
      forward_a <= "01"; -- Encaminha resultado do estágio WB
    end if;

    -- Verifica necessidade de encaminhamento para rs2_id_ex (operando B)
    if regwrite_mem = '1' and rd_mem /= "00000" and rd_mem = rs2_id_ex then
      forward_b <= "10"; -- Encaminha resultado do estágio MEM
    elsif regwrite_wb = '1' and rd_wb /= "00000" and rd_wb = rs2_id_ex then
      forward_b <= "01"; -- Encaminha resultado do estágio WB
    end if;
  end process;
end forwarding_unit_arch_13;