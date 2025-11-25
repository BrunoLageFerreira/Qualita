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
    cSql := cSql +" AND EXISTS ( SELECT 1 RET FROM SIGAEIS..APP005_OP_OCO OCO INNER JOIN SIGAEIS..APP005_OP_OCO_DLS DLS ON (OCO.OCO_ID = DLS.DLS_OCO_ID) WHERE OCO_TIPOOCOR = 'Quebra' AND OCO_TIPOQUEBRA ='Total' AND  OCO_D_E_L_E_T_ = '' AND DLS_D_E_L_E_T_ = '' AND TRIM(SB8.B8_LOTECTL) = TRIM(DLS_LOTE) AND TRIM(SB8.B8_NUMLOTE) = TRIM(DLS_CHAPA)  )"
    cSql := cSql +" ORDER BY SB8.B8_FILIAL, SB8.B8_LOCAL, SB8.B8_PRODUTO, SB8.B8_LOTECTL, SB8.B8_NUMLOTE "
    //cSql := " AND TRIM(SB8.B8_LOTECTL) + TRIM(SB8.B8_NUMLOTE) IN ('007644001','007644002','007644003')"

Else

    IF !Empty(oModel:GetValue("ALIMASTER", "ZG3_XIDIMP")) 
        If MsgYesNo("Deseja filtrar os dados usando o ID do SIP - Inspeção e Liberação de Cavaletes. Sim?")
            //Alert("Implementação do filtro para somente chapas de perdas!")
            cSql := StrTran(cSql, "ORDER BY SB8.B8_FILIAL,              SB8.B8_LOCAL,               SB8.B8_PRODUTO,             SB8.B8_LOTECTL,             SB8.B8_NUMLOTE ", "")
            cSql := cSql +" AND EXISTS ( SELECT 1 RET FROM SIGAEIS..APP006_LIC_CAB CAB (NOLOCK) INNER JOIN SIGAEIS..APP006_LIC_ITENS ITENS (NOLOCK) ON (CAB.LIC_ID = ITENS.LIC_ID) INNER JOIN DADOSADV_Q..ZG3010 ZG3 (NOLOCK) ON (ZG3_XIDIMP <> CAB.LIC_ID) WHERE ZG3.D_E_L_E_T_ = '' AND CAB.LIC_ID = "+ AllTrim(Str(oModel:GetValue("ALIMASTER", "ZG3_XIDIMP"))) +" AND TRIM(SB8.B8_LOTECTL) = TRIM(ITENS.LIC_LOTE) AND TRIM(SB8.B8_NUMLOTE) = TRIM(ITENS.LIC_CHAPA)  )"
            cSql := cSql +" ORDER BY SB8.B8_FILIAL, SB8.B8_LOCAL, SB8.B8_PRODUTO, SB8.B8_LOTECTL, SB8.B8_NUMLOTE "
            //cSql := " AND TRIM(SB8.B8_LOTECTL) + TRIM(SB8.B8_NUMLOTE) IN ('007644001','007644002','007644003')"
        EndIf
    EndIf

EndIf

Return cSql
