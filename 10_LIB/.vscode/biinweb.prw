#INCLUDE "PROTHEUS.CH"
#INCLUDE "RESTFUL.CH"
#include "rwmake.ch"
#include "tbiconn.ch"
#INCLUDE "TOPCONN.CH"

/*
Criado por: Bruno
Data......: 12/01/2018
Uso.......: 
*/

Static Function MUSRRP(cIdUsuario,cEndEmail)
*******************************************************************************
*  
*
***
// Variaveis Locais da Funcao
Local cEdit1	 := cIdUsuario
Local cEdit2	 := AllTrim(cEndEmail)
Local cEdit3	 := Space(25)

Local oEdit1
Local oEdit2
Local oEdit3

Local cQuery     := ""

// Variaveis Private da Funcao
Private _oDlg	
Private lLibBt   := .f.

cQuery:= "SELECT RTRIM(LTRIM(ZSR_USR)) +':'+ REPLACE( ZSR_PSW,'@','%40') DADOS,ZSR_PSW FROM " + RetSQLName("ZSR") + " WHERE D_E_L_E_T_ = '' AND ZSR_USR = '" + AllTrim(aInfUsr[1][2]) + "'"

TcQuery cQuery Alias cQryUSR1 New
dbSelectArea("cQryUSR1")
dbgotop()

If !Eof()
	cEdit3 := cQryUSR1->ZSR_PSW
EndIf

dbSelectArea("cQryUSR1")
DBCLOSEAREA()
                       
DEFINE MSDIALOG _oDlg TITLE "Usuário dos Relatórios" FROM u_MGETTELA(212),u_MGETTELA(178) TO u_MGETTELA(399),u_MGETTELA(495) PIXEL

	// Cria as Groups do Sistema
	@ u_MGETTELA(004),u_MGETTELA(007) TO u_MGETTELA(066),u_MGETTELA(151) LABEL "" PIXEL OF _oDlg

	// Cria Componentes Padroes do Sistema
	@ u_MGETTELA(012),u_MGETTELA(039) MsGet oEdit1 Var cEdit1 when(.F.) Size u_MGETTELA(102),u_MGETTELA(009) COLOR CLR_BLACK PIXEL OF _oDlg
	@ u_MGETTELA(013),u_MGETTELA(016) Say "Login:" 	Size u_MGETTELA(016),u_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlg
	@ u_MGETTELA(029),u_MGETTELA(039) MsGet oEdit2 Var cEdit2 Size u_MGETTELA(102),u_MGETTELA(009) COLOR CLR_BLACK PIXEL OF _oDlg
	@ u_MGETTELA(030),u_MGETTELA(016) Say "e-Mail:" Size u_MGETTELA(017),u_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlg
	@ u_MGETTELA(046),u_MGETTELA(039) MsGet oEdit3 Var cEdit3 valid(lLibBt:=MValidCPO(cEdit3,lLibBt)) Size u_MGETTELA(101),u_MGETTELA(009) PASSWORD COLOR CLR_BLACK PIXEL OF _oDlg
	@ u_MGETTELA(047),u_MGETTELA(016) Say "Senha:" Size u_MGETTELA(019),u_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlg
	@ u_MGETTELA(069),u_MGETTELA(112) Button "OK" action(MUpdDB(cEdit1,cEdit2,cEdit3),close(_oDlg)) when(lLibBt) Size u_MGETTELA(037),u_MGETTELA(012) PIXEL OF _oDlg

ACTIVATE MSDIALOG _oDlg CENTERED 

Return(.T.)


Static Function MValidCPO(cEdit3,lLibBt)
*******************************************************************************
*  
*
***
Local cSenhaPSW := AllTrim(cEdit3)

Local lPSWBlank := .F.
Local lPSWTaman := .F.

Local lPSWMaius := .F.
Local lPSWMinus := .F.
Local lPSWNumer := .F.

Local nX        := 0

/*
Verifica se tem registros.
*/
If !Empty(cSenhaPSW)
	lPSWBlank := .T.
EndIf
/*
Verifica se tem minimo de 6 digitos
*/
If Len(cSenhaPSW) >=6
	lPSWTaman := .T.
EndIf

If 	lPSWBlank == .T. .And.; 
	lPSWTaman == .T.
	
	For nX := 1 to Len(cSenhaPSW)

		If	lPSWMaius == .F. .and.;
			ISUPPER(SubStr(cSenhaPSW,nX,1)) == .T.
			lPSWMaius := .T.
		EndIf

		If	lPSWMinus == .F. .and.;
			ISLOWER(SubStr(cSenhaPSW,nX,1)) == .T.
			lPSWMinus := .T.
		EndIf

		If	lPSWNumer == .F. .and.;
			IsDigit(SubStr(cSenhaPSW,nX,1)) == .T.
			lPSWNumer := .T.
		EndIf

	Next nX

EndIf

/*
Valida todas as questões de testes da senha
*/
If 	lPSWBlank == .T. .and.;
	lPSWMaius == .T. .and.;
	lPSWMinus == .T. .and.;
	lPSWNumer == .T. .and.;
	lPSWTaman == .T.

	lLibBt := .T.
else
	Alert("Algum requisito de sua senha não foi atendido. Mínimo de 6 Dígitos, conter números, letras maiúsculas e minúsculas.")
	lLibBt := .F.
EndIf

Return(lLibBt)

Static Function MUpdDB(cEdit1,cEdit2,cEdit3)
*******************************************************************************
*  
*
***
Local cQuery := ""

cQuery := " UPDATE " + RetSQLName("ZSR")
cQuery += "    SET D_E_L_E_T_ = '*' , ZSR_DTDEL = cast(replace(cast(getdate() as date),'-','') as varchar(8)), R_E_C_D_E_L_ = R_E_C_N_O_
cQuery += "  WHERE ZSR_USR = '" + AllTrim(cEdit1) + "'
cQuery += "    AND D_E_L_E_T_ = ''
                   
TcSQLExec(cquery)

cQuery := " INSERT INTO " + RetSQLName("ZSR") 
cQuery += " 	(ZSR_USR,
cQuery += " 	ZSR_EMAIL,
cQuery += " 	ZSR_PSW,
cQuery += " 	ZSR_DTINC,
cQuery += " 	ZSR_DTDEL,
cQuery += " 	R_E_C_N_O_)
cQuery += " VALUES (
cQuery += " 		'" + AllTrim(cEdit1) + "',
cQuery += " 		'" + AllTrim(cEdit2) + "',
cQuery += " 		'" + AllTrim(cEdit3) + "',
cQuery += " 		cast(replace(cast(getdate() as date),'-','') as varchar(8)),
cQuery += " 		'',
cQuery += " 		isnull((SELECT MAX(R_E_C_N_O_) FROM " + RetSQLName("ZSR") + "),0) + 1
cQuery += " 	   )

TcSQLExec(cquery)

TCSPExec("USER_REPORT",AllTrim(cEdit1) , AllTrim(cEdit3))

Return()

User Function BIInWEB(cPrograma,cDescri,cParam,cTipo)
*******************************************************************************
*  
*
***
Default cPrograma  := ""
Default cDescri    := ""
Default cParam     := ""
Default cTipo      := ""
Default cLinkIe    := ""

Private cLink      := ""
Private cLinkInt   := ""
Private aInfoGeral := {}

Private aInfUsr    := {}

Private oDlg1, oTIBrw

Private aSize	   := MsAdvSize()
Private aInfo	   := {}
Private aObj	   := {}
Private aPObj	   := {}

Private aRethora   := {}

	If Empty(cPrograma) .and. Empty(cDescri)
		cPrograma	:= SubString(FunDesc(), 1+At("[",FunDesc()) , At("]",FunDesc())  - At("[",FunDesc()) -1  )
		cDescri		:= Upper(SubString(FunDesc(), 1 , At("[",FunDesc()) - 1 ))
		If len(strTokArr(FunDesc(), ',' )) == 2
			cTipo       := IIf(empty(strTokArr(FunDesc(), ',' )[2]) , '' , strTokArr(FunDesc(), ',' )[2]) 
		EndIF
	EndIf

	If UPPER(SubString(cPrograma,1,3)) == "RIM" .AND. SubString(CNUMEMP,1,2) == "01"
		Alert("Este relatório não pertence a essa empresa!")
		Return()
	EndIf


	PswOrder(1) 
	If ( PswSeek(__cUserId, .T.) )
		aInfUsr := Pswret(1)
	endif

	If TYPE('cQryUSR') <> 'U'
		dbSelectArea("cQryUSR")
		dbgotop()
	EndIf

	//SIGAEIS.dbo.UrlEncode(ZSR_USR) + ':' + SIGAEIS.dbo.UrlEncode(ZSR_PSW)
	cQuery:= "SELECT RTRIM(LTRIM(ZSR_USR)) +':'+ REPLACE( REPLACE( ZSR_PSW,'@','%40'),'#','%23') DADOS FROM " + RetSQLName("ZSR") + " WHERE D_E_L_E_T_ = '' AND ZSR_USR = '" + AllTrim(aInfUsr[1][2]) + "'"

	TcQuery cQuery Alias cQryUSR New
	dbSelectArea("cQryUSR")
	dbgotop()

	If !Eof()
		cSenhas := AllTrim(cQryUSR->DADOS)
	else
		MUSRRP(AllTrim(aInfUsr[1][2]) , AllTrim(aInfUsr[1][14]) )

		Return()
	EndIf

	dbSelectArea("cQryUSR")
	DBCLOSEAREA()

	If SubString(CNUMEMP,1,2) == "01"
		cLink		:= 'http://' + cSenhas + '@189.50.0.33:10530/Report/powerbi/BI/'+ cPrograma 
		cLinkInt	:= 'http://' + cSenhas + '@189.50.0.33:10530/Report/powerbi/BI/'+ cPrograma
		cLinkIe   	:= 'http://' + cSenhas + '@189.50.0.33:10530/Report/powerbi/BI/'+ cPrograma
	else
		cLink		:= 'http://' + cSenhas + '@189.50.0.33:10530/Report/powerbi/BI/'+ cPrograma
		cLinkInt	:= 'http://' + cSenhas + '@189.50.0.33:10530/Report/powerbi/BI/'+ cPrograma
		cLinkIe   	:= 'http://' + cSenhas + '@189.50.0.33:10530/Report/powerbi/BI/'+ cPrograma	
	EndIf
	
	If "COMPI" $ upper(GetEnvServer())
		cLink		:= 'http://'+cSenhas+'@192.168.1.104:10530/Report/powerbi/BI/'+ cPrograma
		cLinkIe   	:= 'http://'+cSenhas+'@192.168.1.104:10530/Report/powerbi/BI/'+ cPrograma
	EndIf
	
	If !Empty(cParam)
		cParam      := &cParam 
		cLink		:= cLink    + cParam 
		cLinkInt    := cLinkInt + cParam 
		cLinkIe     := cLinkIe  + cParam 
	EndIf
		
    cLink	    := cLink    + '?rs:Command=Render&rc:Toolbar=false'
	cLinkInt    := cLinkInt + '?rs:Command=Render&rc:Toolbar=false'
	cLinkIe     := cLinkIe  + '?rs:Command=Render&rc:Toolbar=false'

	//Na versão 12, houve uma mudança na função que reversa 30pixels na janela
	If AllTrim(cversao)=="12"
		aSize[2] := 0
	EndIf

	aInfo := { aSize[1], aSize[2], aSize[3], aSize[4], 0, 05 }
	aAdd( aObj, { 000, 000, .T., .T. }) //MenuBar
	aPObj := MsObjSize( aInfo, aObj ) 

	aRethora := FwTimeUF("MG")

	
 
 cHtml:= "<html><body><script language=javascript>window.open('" + cLink + "','" + cPrograma + "','resizable=1,scrollbars=1,width=760,height=680,left=2,top=2,toolbar=0,status=0,location=0,menubar=0');</script></body></HTML>"
  
 aInfoGeral := GetRmtInfo()
  

SetKey(VK_F12,{|| MUSRRP(AllTrim(aInfUsr[1][2]) , AllTrim(aInfUsr[1][14]) )} )
SetKey(VK_F11,{|| cLink := FwInputBox("Link:", cLink), oWebEngine:navigate(cLink)} )



If Upper(cTipo) == "[IE]" .OR. "WEB_APP" $ upper(GetEnvServer())

	ShellExecute( "Open", cLinkIe ,"","", 1 )

Else

	DEFINE MSDIALOG oDlg1 TITLE "RELATÓRIO "+ cDescri From aSize[7],0 to aSize[6],aSize[5] of oMainWnd PIXEL	 	 	
	 	oWebEngine := TWebEngine():New(oDlg1, aPObj[1,1],aPObj[1,2],aPObj[1,4],aPObj[1,3],,)
		oWebEngine:cLang := "pt-BR"
		oWebEngine:navigate(cLink)
		oWebEngine:Align := CONTROL_ALIGN_ALLCLIENT
	Activate MsDialog oDlg1

EndIf


Return

Static Function MGUrlMain(cUrlNow)
*******************************************************************************
*  
*
***

MsgAlert(cUrlNow)
oWebEngine:goBack()

Return()
 