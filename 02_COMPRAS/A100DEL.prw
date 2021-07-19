#INCLUDE "TopConn.CH"
#INCLUDE "RWMAKE.CH"
#INCLUDE "PROTHEUS.CH"   
#INCLUDE "TBICONN.CH"
            
/*
Programa ...: A100DEL.Prw
Uso ........: A100DEL.Prw - Alerta de msg para exclusão da NF-e. 
Data .......: 29/01/2020
Feito por ..: Bruno Lage Ferreira
Copyright @1998-2001,2020
*/ 

User Function A100DEL()
************************************************************************************************
*
*
****
Local lRet := .T.

IF dDatabase <> SF1->F1_DTDIGIT
	Alert("Você não pode excluir a NF fora da data de entrada original. Data digitada:" + dToC(SF1->F1_DTDIGIT))
	lRet := .F.
EndIf

Return(lRet)
