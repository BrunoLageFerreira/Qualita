#INCLUDE "rwmake.ch"
#include "protheus.ch"                                                                               

User Function NFORZ2()

	Private cNMFORN := ""     

	DBSelectArea("SZ2")
	DBGotop()
	While !Eof()
		cNMFORN := POSICIONE("SA2",1,XFILIAL("SA2")+SZ2->Z2_FORNECE+SZ2->Z2_LOJA,"SA2->A2_NREDUZ") // Retorna o nome do Fornecedor      
		RecLock("SZ2",.F.)
		SZ2->Z2_NOMFOR := cNMFORN
		MsUnlock()	
		DbSkip()
	End
Return Nil