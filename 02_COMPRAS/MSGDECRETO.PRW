#include "protheus.ch"
#include "rwmake.ch"
#include "tbiconn.ch"  
#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"

/*
Programa ...: MsgDecreto.Prw
Uso ........: Mensagem Automatica para nota de creto
Data .......: 28/08/2019
Feito por ..: Bruno Lage Ferreira
Copyright @1998-2001,2019
*/ 

User Function MsgDecreto()  
************************************************************************************************************
* Alert(u_MsgDecreto())
*
***
Local cQuery    := ""
Local cMsgNfDec := ""

cQuery := "  SELECT D1_DOC,
cQuery += "   		D1_SERIE,
cQuery += " 		D1_LOTECTL,
cQuery += " 		dbo.FRETCHPENT(D1_DOC,D1_SERIE,D1_LOTECTL) AS SUBLOTES
cQuery += "     FROM SD1010 A
cQuery += "   WHERE A.D_E_L_E_T_ =''
cQuery += "      AND D1_DOC   = '"+ SF1->F1_DOC   +"'
cQuery += "      AND D1_SERIE = '"+ SF1->F1_SERIE +"'
cQuery += "      AND D1_FORNECE+D1_LOJA = '00016501'
cQuery += "      AND LEFT(D1_COD,2)='CH'
cQuery += "  	 AND D1_NUMLOTE <> ''
cQuery += " GROUP BY D1_DOC,
cQuery += "  	     D1_SERIE,
cQuery += " 		 D1_LOTECTL
 
tcQuery cQuery alias TRB new
dbSelectArea("TRB")
dbGoTop()
Do While !EOF()  

	cMsgNfDec  := cMsgNfDec + "| LOTE:" + TRB->D1_LOTECTL + "CHAPAS:" +  TRB->SUBLOTES

	dbSelectArea("TRB")
	dbSkip()
EndDo    

dbSelectArea("TRB") 
dbCloseArea()

IF !EMPTY(cMsgNfDec)
	cMsgNfDec := "NF:" + SF1->F1_DOC + "/" +SF1->F1_SERIE + " " + cMsgNfDec
EndIf

Return(cMsgNfDec)