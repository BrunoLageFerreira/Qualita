#Include "rwmake.ch"
#Include "Colors.ch"
#Include "Protheus.ch" 
#Include "Topconn.ch"


/*
Programa ...: LCD530S7.Prw
Uso ........: Contabilidade Siga CTB
Data .......: 18/10/2021
Feito por ..: Bruno Lage Ferreira / Arlindo
Copyright @1998-2001,2021
Atualizado..: 24/08/2021


Nome do Arquivo:
L   = Lancamento Padrao
CD  = Historio do Lancamento
530 = Lancamento codigo 530
S7 = Sequencia 007
*/    

User Function LCD530S7(cTipo)
*************************************************************************************************
* /*C=CONTA  OU N NATUREZA*/
*
***    
Local LCD530  := GetArea()
Local cRet   := ""
Local cQuery := ""

    cQuery := " SELECT TOP 1 ED_CONTA,ED_CODIGO FROM "+ RetSqlName("SE5") +" SE5, "+ RetSqlName("SED") +" SED
    cQuery += "  WHERE SE5.D_E_L_E_T_ <> '*'
    cQuery += "    AND SED.D_E_L_E_T_ <> '*'
    cQuery += "    AND SE5.E5_NATUREZ = SED.ED_CODIGO
    cQuery += "    AND SE5.E5_NATUREZ = '"+SE5->E5_NATUREZ  +"'

    TCQUERY cQuery NEW ALIAS "TRBLCD"  
    dbSelectArea("TRBLCD")

    IF UPPER(cTipo) = "C"
        cRet   := AllTrim(TRBLCD->ED_CONTA)
    Else
        cRet   := AllTrim(TRBLCD->ED_CODIGO)
    EndIF

    dbSelectArea("TRBLCD")
    dbCloseArea("TRBLCD")
    
    RestArea(LCD530)

Return(cRet)
