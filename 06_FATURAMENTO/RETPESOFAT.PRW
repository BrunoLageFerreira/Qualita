#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
#INCLUDE "TOPCONN.CH"

/*                                          
Programa ...: RETPESOFAT.Prw
Uso ........: Endereçamento
Data .......: 20/09/19
Feito por ..: Bruno Lage Ferreira.
*/

User Function RETPESOFAT(cNumPedVen, cItemPv )  
************************************************************************************
*
*
***
Local nPesoIdeal := 0
Local cQuery     := ""

cQuery     := " SELECT	C6_PRODUTO,C6_XPESO PESOAMOSTRA, 
cQuery     += " 		ISNULL((SELECT TOP 1 B8_YPESOLQ FROM SB8010 WHERE D_E_L_E_T_ = '' AND B8_PRODUTO = C6_PRODUTO AND B8_LOTECTL = C6_LOTECTL AND B8_NUMLOTE = C6_NUMLOTE AND B8_YPESOLQ <> 0 ),0) PESOLQ
cQuery     += "   FROM SC6010 
cQuery     += "  WHERE D_E_L_E_T_ = '' 
cQuery     += "    AND C6_NUM     = '"+cNumPedVen+"' 
cQuery     += "    AND C6_ITEM    = '"+cItemPv+"' 

TcQuery cQuery Alias TRB New

dbSelectArea("TRB")
dbGoTop()	
While (!Eof())

	nPesoIdeal := IIF( LEFT(TRB->C6_PRODUTO,2)$"AM/BL" , TRB->PESOAMOSTRA , TRB->PESOLQ )

	dbSelectArea("TRB")
	dbSkip()
EndDo

dbSelectArea("TRB")
dbCloseArea()

Return(nPesoIdeal) 