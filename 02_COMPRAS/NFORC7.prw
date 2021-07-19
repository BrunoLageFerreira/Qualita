#INCLUDE "rwmake.ch"
#include "protheus.ch"                                                                               

User Function NFORC7()

	Private cNMFORN := ""     

	DBSelectArea("SC7")
	DBGotop()
	While !Eof()
		cNMFORN := POSICIONE("SA2",1,XFILIAL("SA2")+SC7->C7_FORNECE+SC7->C7_LOJA,"SA2->A2_NREDUZ") // Retorna o nome do Fornecedor      
		RecLock("SC7",.F.)
		SC7->C7_NOMEFOR := cNMFORN
		MsUnlock()	
		DbSkip()
	End
Return Nil