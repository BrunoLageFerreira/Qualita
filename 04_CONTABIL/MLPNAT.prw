#include "RWMAKE.ch"
#include "Colors.ch"
#include "Font.ch"
#Include "HBUTTON.CH"
#include "Topconn.ch"
#Include "Protheus.ch"
#include "tbiconn.ch"

/*   
Programa ...: MLPNAT.Prw
Uso ........: Lancamento padrao Natureza vs conta contabil
Data .......: 14/10/2013
Feito por ..: Bruno Lage Ferreira
Copyright ..: @1998-2001,2013
Atualizado..: 24/08/2020
*/

User Function MLPNAT() 
**********************************************************************************************************************************************************
*  /* */
*                                                                     
***  

Local cRet := ""

dbSelectArea("SE2")
dbSetOrder(6)
If dbSeek(xFilial("SE2") + SF1->F1_FORNECE + SF1->F1_LOJA + SF1->F1_PREFIXO + SF1->F1_DUPL )                
	dbSelectArea("SED")
	dbSetOrder(1)
	dbSeek(xFilial("SED")+SE2->E2_NATUREZ ) 
	cRet := SED->ED_CONTA
EndIf

Return(cRet)