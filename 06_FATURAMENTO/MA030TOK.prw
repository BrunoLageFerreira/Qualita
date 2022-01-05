#include "rwmake.ch"
#include "TOPCONN.CH"

/*                                          
Programa ...: MA030TOK.Prw
Uso ........: Ponto de Entrada (MA030TOK)
Data .......: 14/11/17
Feito por ..: Bruno Lage Ferreira.

Validação do CNPJ para Exportação
TIPO X
*/                                                                	

User Function MA030TOK()
*************************************************************************************************************
*
*
***        
Local lRet := .T.  

If M->A1_TIPO <> "X" .And. Empty(M->A1_CGC)
	Alert("CNPJ é parte de um campo obrigatorio!")
	lRet := .F.
Else
	If M->A1_TIPO = "X" .AND. M->A1_CGC == "00000000000000"
		lRet := .T.      
	ElseIf M->A1_TIPO $ "F/R/J"
		lRet := .T.	
	Else           
		Alert("CNPJ é parte de um campo obrigatorio!")
		lRet := .F.
	EndIf
EndIf

Return(lRet)
