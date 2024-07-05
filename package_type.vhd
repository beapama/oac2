---------------------------------------------------------------------------------------
----------Pacote para declaraçao do tipo de instruçoes---------------------------------
---------------------------------------------------------------------------------------

-- Sessao de daclaraçao do package de tipos de instruçoes
	package tipos is
		--tipo e mnemônicos de instruçao
    type instruction_type is (ADD, SLT,                     --tipo R
                              ADDI, SLTI, SLLI, SRLI, SRAI, --tipo I
                              LW,                           --tipo load
                              SW,                           --tipo Store
                              BEQ, BNE, BLT,                --tipo Branchs
                              JAL, JALR,                 	--tipo Jumps
							  NOP,							--tipo inventado
							  NOINST,						--tipo nao existente 
							  HALT							--PARE
		);	
	end package tipos;

	