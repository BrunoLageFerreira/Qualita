#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
#INCLUDE "topconn.ch"          

/*
Programa ...: FA60FIL.Prw
Uso ........: Filtro na Transferencia de titulos do contas a receber
Data .......: 21-06-2019
Feito por ..: Bruno Lage Ferreira
Copyright @1998-2001,2019
*/

User Function FA60FIL()
***********************************************************************************
*
*
***
Local cEdit1	 := Space(300)
Local oEdit1

// Variaveis Private da Funcao
Private _oDlg				// Dialog Principal
// Variaveis que definem a Acao do Formulario                    


DEFINE MSDIALOG _oDlg TITLE " Números de Títulos: "   FROM u_MGETTELA(223),u_MGETTELA(173) TO u_MGETTELA(359),u_MGETTELA(520) PIXEL

	// Cria as Groups do Sistema
	@ u_MGETTELA(003),u_MGETTELA(005) TO u_MGETTELA(044),u_MGETTELA(168) LABEL "" PIXEL OF _oDlg

	// Cria Componentes Padroes do Sistema
	@ u_MGETTELA(016),u_MGETTELA(014) Say "Informe os códigos:" Size u_MGETTELA(066),u_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlg
	@ u_MGETTELA(025),u_MGETTELA(014) MsGet oEdit1 Var cEdit1 Size u_MGETTELA(130),u_MGETTELA(009) picture("@!") COLOR CLR_BLACK PIXEL OF _oDlg
	@ u_MGETTELA(047),u_MGETTELA(131) Button "Ok" Size u_MGETTELA(037),u_MGETTELA(012)  ACTION( Close(_oDlg))  PIXEL OF _oDlg
	@ u_MGETTELA(050),u_MGETTELA(007) Say "Os códigos devem ser separados por [,]! "  Size u_MGETTELA(113),u_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlg

ACTIVATE MSDIALOG _oDlg CENTERED


If !Empty(cEdit1)
	cEdit1 := "(AllTrim(SE1->E1_NUM) $ ('"+cEdit1+"'))" 
Else
	cEdit1 := "!EMPTY(SE1->E1_NUM)"
EndIf

Return(cEdit1)
