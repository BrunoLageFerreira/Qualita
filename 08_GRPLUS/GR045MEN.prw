#Include "Totvs.ch"
#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
#INCLUDE "topconn.ch"

/*
Programa ...: GR045MEN.Prw
Uso ........: MENU DE IMPORTAÇÃO DE DADOS NO APONTAMENTO 
Data .......: 2024-03-08
Feito por ..: Bruno Lage Ferreira 
*/

User Function GR045MEN()
********************************************************************************************************
* /*MENU*/
*
****
Local aRotina := PARAMIXB
//http://192.168.1.103:8030/rest/FWMODEL/GROA045/?filter=ZH7_NUM=039984&ZH7_FILIAL=010101

//aAdd(aRotina, {"Import. Apontamento" ,"u_APIGRGET('http://192.168.1.103:8030/rest/FWMODEL/GROA045/',u_fParApi(),'{}')" , 0 , 3, 0,nil})
aAdd(aRotina, {"Rel. Beneficiamento (RQ0158)" ,"U_RELINWEB('RQ0158','Rel. de Beneficiamento','u_fParR158()')" , 0 , 3, 0,nil})

Return(aRotina)


User Function fParApi()
****************************************************************************************************************
*    
*
****
Local cRet := ""

cRet := '?filter=ZH7_NUM='+Trim(ZH7_NUM)+'&ZH7_FILIAL='+ZH7_FILIAL'

//Alert(cRet)

Return(cRet)


User Function fParR158()
****************************************************************************************************************
*    
*
****
Local cRet := ""

cRet := '&RECURSO="' + AllTrim(ZH7->ZH7_DESCRE) + '"'

Return(cRet)
