#INCLUDE "rwmake.ch"   
#include "protheus.ch"  
#INCLUDE "topconn.ch"

/*                                          
Programa ...: MT440GR.Prw
Uso ........: Ponto de Entrada (FINAL DA LIBERAÇÃO DO PEDIDO DE VENDA)
Data .......: 12/07/2019
Feito por ..: Bruno Lage Ferreira.
*/

User Function MT440GR()
***********************************************************************************************************
*  
*
***    
Local nRet     := PARAMIXB[1]
Local aMT440GR := GetArea()	  
Local nX       := 1 	

If nRet == 1
    
	For nX := 1 To Len(aCols)
		GdFieldPut("C6_XMOTBLQ","",nX)
	Next nX
	
	TCSPExec("SP_MLIBPV",M->C5_FILIAL, M->C5_NUM , SUBSTR(CUSUARIO,7,15))
	Aviso("Liberado!","Pedido de venda liberado!")		
EndIf


RestArea(aMT440GR)

Return(nRet)
