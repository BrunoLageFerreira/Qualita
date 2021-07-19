#INCLUDE "rwmake.ch"
#include "protheus.ch"                                                                               

User Function NFORE2()

	Private cNMFORN := ""     

	DBSelectArea("SE2")
	DBGotop()
	While !Eof()
		cNMFORN := POSICIONE("SA2",1,XFILIAL("SA2")+SE2->E2_FORNECE+SE2->E2_LOJA,"SA2->A2_NREDUZ") // Retorna o nome do Fornecedor      
		RecLock("SE2",.F.)
		SE2->E2_NOMFOR := cNMFORN
		MsUnlock()	
		DbSkip()
	End
Return Nil