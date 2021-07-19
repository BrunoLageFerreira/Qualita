#include 'TopConn.CH'
#include 'RWMAKE.CH'
#include 'TbiConn.CH'
#INCLUDE "PROTHEUS.CH"    
  
/*                                          
Programa ...: A093ACOD.Prw
Uso ........: PROGRAMA PARA VALIDACAO DO CODIGO INTELIGENTE
Data .......: 14/01/19
Feito por ..: Bruno Lage Ferreira 
*/

User Function A093ACOD()
***********************************************************************************************************
*  validacao do codigo inteligente
*
*** 

Local cCodPrd := PARAMIXB[1]
Local cDesPrd := PARAMIXB[2]
Local aCod    := PARAMIXB[3]
Local aCodGrd := PARAMIXB[4]
Local lGera   := PARAMIXB[5]
Local aArea   := GetArea()
Local cNewCod := Nil       
Local cQuery  := ""

cQuery := " SELECT ISNULL(MAX(B1_COD),'"+Substr(cCodPrd,1,4)+"0000') AS B1_COD
cQuery += "   FROM SB1010
cQuery += "  WHERE D_E_L_E_T_ <> '*'
cQuery += "    AND LEFT(B1_COD,4) = '"+Substr(cCodPrd,1,4) +"'
         
TcQuery cQuery Alias TRB_COD New

dbSelectArea("TRB_COD")
dbGoTop()

cNewCod := Soma1(alltrim(TRB_COD->B1_COD))

dbSelectArea("TRB_COD")
dbCloseArea()
     
RestArea(aArea)

Return(cNewCod)



