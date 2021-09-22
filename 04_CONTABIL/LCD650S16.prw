#Include "rwmake.ch"
#Include "Colors.ch"
#Include "Protheus.ch"  
#Include "Topconn.ch"
    
/*
Programa ...: LCD650S16.Prw
Uso ........: Contabilidade Siga CTB
Data .......: 24/01/2014
Feito por ..: Bruno Lage Ferreira
Copyright @1998-2001,2014
Atualizado..: 24/08/2020

Nome do Arquivo:
L 	= Lancamento Padrao
CD 	= Historio do Lancamento
650 = Lancamento codigo 530
S16 = Sequencia 001
*/     

User Function LCD650S16(cTipo)
*************************************************************************************************
* /*C=CONTA  OU N NATUREZA*/
*
***     
Local LCD65  := GetArea()                                         
Local cRet   := ""        
Local cQuery := ""                 
          
	cQuery := " SELECT TOP 1 ED_CONTA,ED_CODIGO FROM "+ RetSqlName("SE2") +" SE2, "+ RetSqlName("SED") +" SED   
	cQuery += "  WHERE SE2.D_E_L_E_T_ <> '*'
	cQuery += "    AND SED.D_E_L_E_T_ <> '*'
	cQuery += "    AND SE2.E2_NATUREZ = SED.ED_CODIGO
	cQuery += "    AND E2_NUM     = '"+ SF1->F1_DOC +"'
	cQuery += "    AND E2_FILORIG = '"+ SF1->F1_FILIAL +"'
	cQuery += "    AND E2_FORNECE = '"+ SF1->F1_FORNECE  +"'
	cQuery += "    AND E2_LOJA    = '"+ SF1->F1_LOJA +"'
	cQuery += "    AND E2_EMISSAO = '"+ dTos(SF1->F1_EMISSAO) +"'             
	TCQUERY cQuery NEW ALIAS "TRBLCD"  

	dbSelectArea("TRBLCD")

	IF UPPER(cTipo) = "C"
		cRet   := AllTrim(TRBLCD->ED_CONTA) 
	Else
		cRet   := AllTrim(TRBLCD->ED_CODIGO) 
	EndIF

	dbSelectArea("TRBLCD")
	dbCloseArea("TRBLCD")
	RestArea(LCD65)

Return(cRet)
