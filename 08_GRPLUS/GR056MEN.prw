#Include "Totvs.ch"
#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
#INCLUDE "topconn.ch"

/*
Programa ...: GR056MEN.Prw
Uso ........: MENU DO CAVALETE MOVEL
Data .......: 2024-03-08
Feito por ..: Bruno Lage Ferreira 
*/

User Function GR056MEN()
********************************************************************************************************
* 
*
****
Local aRotina := PARAMIXB

aAdd(aRotina, {"Rel. Rastreiro Bundles" ,"U_RELINWEB('RQ0143','Rel. Rastreio Bundles','u_fParR143()')" , 0 , 3, 0,nil})
aAdd(aRotina, {"Rel. L.I. Cavaletes"    ,"U_RELINWEB('RQ0162','Rel. L.I Cavaletes','')" , 0 , 3, 0,nil})

Return(aRotina)


User Function fParR143()
****************************************************************************************************************
*    
*
****
Local cRet := ""

cRet := "&REC_BUNDLE=" + AllTrim(ZG3->ZG3_CODIGO)

Return(cRet)
