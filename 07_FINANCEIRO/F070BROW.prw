#include "rwmake.ch"
#include "TOPCONN.CH"
#Include 'Protheus.ch'

/*                                          
Programa ...: F070BROW.Prw
Uso ........: Ponto de Entrada (ALTERACAO DO CR) para transferencias internacionais na baixa
Data .......: 22/06/2020 
Feito por ..: Bruno Lage Ferreira.
*/

User function F070BROW()
*********************************************************************************************
*
*
***
Local nDelet := 0
If SubString(CNUMEMP,1,2) == "01" 
	For _NI := 1 To Len(aRotina)
		IF aRotina[_NI][1] == "Canc Baixa"  
			aRotina[_NI][2] := "Alert('Use a opção excluir!')" 
		EndIf
	Next  
EndIf

AAdd(aRotina,	{ "Rel Bx.Aut. Transferências" , "U_RelInWeb('RQ0064','Relatório')", 0 , 6, 0, nil})  
AAdd(aRotina,	{ "Baixa Compensação"          , "U_fBxLTCom()"                    , 0 , 6, 0, nil})
AAdd(aRotina,	{ "Estorno Transferências"     , "U_fEsLTCom()"                    , 0 , 6, 0, nil})

Return()


