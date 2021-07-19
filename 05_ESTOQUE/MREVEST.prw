#include "rwmake.ch"                    
#include "TOPCONN.CH"

/*                                          
Programa ...: MREVEST.Prw
Uso ........: REAVALIACAO DO ESTOQUE ABASEADO NO LANCAMENTO DO INVENTARIO
Data .......: 13/11/2017
Feito por ..: Bruno Lage Ferreira
*/

User Function MREVEST(cCodProd,dDtRef) 
/********************************************************************************************
*
*
***/                  
Local aArea1    := GetArea()
Local cQuery	:= ""                        
Local cDtRef    := DtoS(dDtRef)
Local nRetMedia := 0

	cQuery	:= " SELECT MEDIA_PRODUTO  MEDIA 
	cQuery	+= " 		FROM (
	cQuery	+= " 				SELECT ROUND(SUM(VALOR) /SUM(QTD) ,2) MEDIA_PRODUTO FROM(
	cQuery	+= " 											SELECT TOP 6 ROUND(D1_CUSTO/D1_QUANT,2)VALOR,1 QTD
	cQuery	+= " 											  FROM SD1050 
	cQuery	+= " 											 WHERE D_E_L_E_T_ <> '*'
	cQuery	+= " 											   AND D1_COD = '"+AllTrim(cCodProd)+"'
	cQuery	+= " 											   AND D1_QUANT <> 0
	cQuery	+= " 											   AND D1_FILIAL = '010101'
	cQuery	+= " 											   AND D1_DTDIGIT <= '"+cDtRef+"'
	cQuery	+= " 											ORDER BY D1_DTDIGIT DESC
	cQuery	+= " 										) TB_MEDIA
	cQuery	+= " 				) TB_MEDIA

	TcQuery cQuery Alias MPROD New

	dbSelectArea("MPROD")
	dbGoTop()

	nRetMedia := MPROD->MEDIA

	dbSelectArea("MPROD")
	dbCloseArea()          

	RestArea(aArea1)

Return(nRetMedia)
