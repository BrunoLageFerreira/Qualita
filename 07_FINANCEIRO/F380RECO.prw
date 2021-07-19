#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
#INCLUDE "topconn.ch"          

/*
Programa ...: F380RECO.Prw 
Data .......: 08/10/2020
Feito por ..: Bruno Lage Ferreira
Copyright @1998-2001,2020

MV_USUREC customizado para usuarios nao validar a data limite
MV_DATAREC data limite da rec 
*/ 

User Function F380VLD()
/**********************************************************************************************************************
*
*
*
***/
Local lRet := .T.
/*
Local dDataLim := PARAMIXB[1]
Local dDataIni := PARAMIXB[2]
Local dDataFim := PARAMIXB[3]
Local cUsua    := AllTrim(GetMv("MV_USUREC"))

Local cEdit1	 := GetMV("MV_DATAREC")
Local oEdit1

// Variaveis Private da Funcao
Private _oDlg				// Dialog Principal
// Variaveis que definem a Acao do Formulario                    


IF (RetCodUsr() $ cUsua )
	DEFINE MSDIALOG _oDlg TITLE " Data limíte da concilição Bancária: (MV_DATAREC)"   FROM u_MGETTELA(223),u_MGETTELA(173) TO u_MGETTELA(359),u_MGETTELA(520) PIXEL
	
		// Cria as Groups do Sistema
		@ u_MGETTELA(003),u_MGETTELA(005) TO u_MGETTELA(044),u_MGETTELA(168) LABEL "" PIXEL OF _oDlg
	
		// Cria Componentes Padroes do Sistema
		@ u_MGETTELA(016),u_MGETTELA(014) Say "Confirme a data limíte:" Size u_MGETTELA(066),u_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlg
		@ u_MGETTELA(025),u_MGETTELA(014) MsGet oEdit1 Var cEdit1 Size u_MGETTELA(130),u_MGETTELA(009)  COLOR CLR_BLACK PIXEL OF _oDlg
		@ u_MGETTELA(047),u_MGETTELA(131) Button "Ok" Size u_MGETTELA(037),u_MGETTELA(012)  ACTION( Close(_oDlg))  PIXEL OF _oDlg
		//@ u_MGETTELA(050),u_MGETTELA(007) Say "Os códigos devem ser separados por [,]! "  Size u_MGETTELA(113),u_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlg
	
	ACTIVATE MSDIALOG _oDlg CENTERED
	
	
	If !Empty(cEdit1)
		PutMV("MV_DATAREC",cEdit1) 
	Else
		Alert("Parâmetro alterado sem data limíte!")
		PutMV("MV_DATAREC",StoD('19800101')) 
	EndIf
	
EndIf
*/
Return(lRet)


                                                                                                                                                                                                                      