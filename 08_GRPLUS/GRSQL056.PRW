#INCLUDE "Protheus.ch"
#INCLUDE "RwMake.ch"
#INCLUDE "topconn.ch"

/*
Programa ...: GRSQL056.Prw
Uso ........: EDIÇÃO DA QUERY NA IMPORTAÇÃO DAS CHAPAS 
Data .......: 07/08/2025
Feito por ..: Bruno Lage Ferreira
Copyright @1998-2001,2025

Exemplo:
cExpSql := ExecBlock("GRSQL056", .F., .F., {cExpSql,cTipoProd,oModelZG3:GetValue("ZG3_CODIGO")})
*/ 

User Function GRSQL056()
************************************************************************************************
*
*
*****
Local cSql      := PARAMIXB[1]
//Local cTipo     := PARAMIXB[2]
Local oModel    := FWModelActive()

IF oModel:GetValue("ALIMASTER", "ZG3_XPERDA") = "S"
    //Alert("Implementação do filtro para somente chapas de perdas!")
    cSql := StrTran(cSql, "ORDER BY SB8.B8_FILIAL,              SB8.B8_LOCAL,               SB8.B8_PRODUTO,             SB8.B8_LOTECTL,             SB8.B8_NUMLOTE ", "")
    cSql := cSql +" AND TRIM(SB8.B8_LOTECTL) + TRIM(SB8.B8_NUMLOTE) IN (SELECT TRIM(OCO_LOTE)+TRIM(OCO_CHAPA) FROM SIGAEIS..APP005_OP_OCO WHERE OCO_D_E_L_E_T_ = '' ) "
    cSql := cSql +" ORDER BY SB8.B8_FILIAL, SB8.B8_LOCAL, SB8.B8_PRODUTO, SB8.B8_LOTECTL, SB8.B8_NUMLOTE "
    //cSql := " AND TRIM(SB8.B8_LOTECTL) + TRIM(SB8.B8_NUMLOTE) IN ('007644001','007644002','007644003')"
EndIf

Return cSql
