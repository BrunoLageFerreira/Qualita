#INCLUDE "PROTHEUS.CH"
#INCLUDE "RESTFUL.CH"
#include "rwmake.ch"
#include "tbiconn.ch"
#INCLUDE "TOPCONN.CH"

/*
Criado por: Bruno
Data......: 12/01/2018
Uso.......: 

http://administrador:xpacD99label@189.50.0.33:10530/ReportServer/Pages/ReportViewer.aspx?%2fItinga_reports%2fRQ0056&rs:Command=Render
*/
#define SW_SHOWNA           8 // Esconde a barra de tarefas
#define SW_SHOWNORMAL       1 // Normal

WSRESTFUL WSTOTVSXRS DESCRIPTION "Api de segurança entre Protheus e Report Server"
*****************************************************************************************************************
*
*
****
    WSDATA cPSWRET    AS STRING  OPTIONAL

	WSMETHOD POST RSXUSER  DESCRIPTION 'Consulta Usuários para RServer'   WSSYNTAX '/RSXUSER'   PATH 'RSXUSER'    PRODUCES APPLICATION_JSON

END WSRESTFUL

WSMETHOD POST RSXUSER WSRECEIVE WSRESTFUL WSTOTVSXRS
*****************************************************************************************************************
* /*Inclusão ou abertura de um novo produto*/
*
****
Local lRet  := .T.
Local aArea := GetArea()
Local cQuery := ""
Local oJson
Local cPSW,cEmail

Local cJson     := Self:GetContent()
Local cError    

    //Definindo o conteúdo como JSON, e pegando o content e dando um parse para ver se a estrutura está ok
    Self:SetContentType("application/json")
    oJson   := JsonObject():New()
    cError  := oJson:FromJson(cJson)
 
    //Se tiver algum erro no Parse, encerra a execução
    IF !Empty(cError)
        SetRestFault(500,'Parser Json Error. (Erro no Json)"')
        lRet    := .F.
    Else
	    cEmail    := EncodeUTF8(AllTrim(Upper(oJson:GetJsonObject('email'))))
		
        cQuery:= "SELECT REPLACE(ZSR_USR ,' ','') +':'+ REPLACE( ZSR_PSW,'@','%40') DADOS,ZSR_PSW FROM " + RetSQLName("ZSR") + " WHERE D_E_L_E_T_ = '' AND UPPER(ZSR_EMAIL) = '" + cEmail + "'"

		TcQuery cQuery Alias cQryUSR2 New
		dbSelectArea("cQryUSR2")
		dbgotop()

		If !Eof()
			cPSW  := EncodeUTF8(AllTrim(cQryUSR2->DADOS))
		EndIf

		dbSelectArea("cQryUSR2")
		DBCLOSEAREA()

        FreeObj(oJson)
        Self:SetContentType("application/json")
        oJson   := JsonObject():New()

        oJson['usuario:'] := cPSW
        
        cJson:= FwJsonSerialize( oJson )
        Self:SetResponse( cJson ) //-- Seta resposta

        lRet    := .T.
    EndIf

    RestArea(aArea)
    FreeObj(oJson)
Return(lRet)

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
	@ u_MGETTELA(046),u_MGETTELA(039) MsGet oEdit3 Var cEdit3 Size u_MGETTELA(101),u_MGETTELA(009) PASSWORD COLOR CLR_BLACK PIXEL OF _oDlg
	@ u_MGETTELA(047),u_MGETTELA(016) Say "Senha:" Size u_MGETTELA(019),u_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlg
	@ u_MGETTELA(069),u_MGETTELA(112) Button "OK" action(MUpdDB(cEdit1,cEdit2,cEdit3),close(_oDlg)) Size u_MGETTELA(037),u_MGETTELA(012) PIXEL OF _oDlg

ACTIVATE MSDIALOG _oDlg CENTERED 

Return(.T.)

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

User Function RelInWEB(cPrograma,cDescri,cParam,cTipo)
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

	//If GetEnvServer() == "PRODUCAO"
	
	cLink		:= "http://189.50.0.33:10530/reportserver/Pages/ReportViewer.aspx?%2fItinga_reports%2f"+ cPrograma //+"&rs:Command=Render"+ cParam
	cLinkInt	:= "http://189.50.0.33:10530/reportserver/Pages/ReportViewer.aspx?%2fItinga_reports%2f"+ cPrograma
	
	cLinkIe   	:= "http://189.50.0.33:10530/reportserver/Pages/ReportViewer.aspx?%2fItinga_reports%2f"+ cPrograma

	//cLink		:= "http://189.50.0.33:10530/ReportServer/Pages/ReportViewer.aspx?%2fItinga_reports%2fRIM0019&rs:Command=Render"
	//EndIf
	//http://192.168.0.201/report_server?%2fsup_brasil%2fRSB0027&DTINI=2018/1/1&DTFIM=2018/12/31&NATINI=0&NATFIM=ZZZZZZ&TIPOPREV=2&rs:Format=MHTML" -O '+ @Filename +''

	//Alert(GetEnvServer())

	PswOrder(1) 
	If ( PswSeek(__cUserId, .T.) )
		aInfUsr := Pswret(1)
	endif

	If TYPE('cQryUSR') <> 'U'
		dbSelectArea("cQryUSR")
		dbgotop()
	EndIf

	cQuery:= "SELECT RTRIM(LTRIM(ZSR_USR)) +':'+ REPLACE( ZSR_PSW,'@','%40') DADOS FROM " + RetSQLName("ZSR") + " WHERE D_E_L_E_T_ = '' AND ZSR_USR = '" + AllTrim(aInfUsr[1][2]) + "'"

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

	If "COMPI" $ upper(GetEnvServer())  	
		cLink		:= 'http://'+cSenhas+'@192.168.1.104:10530/ReportServer/Pages/ReportViewer.aspx?%2fItinga_reports%2f'+ cPrograma
		cLinkIe   	:= 'http://'+cSenhas+'@192.168.1.104:10530/ReportServer/Pages/ReportViewer.aspx?%2fItinga_reports%2f'+ cPrograma
	EndIf
	
	/*
	cLink		:= "http://192.168.1.23:10520/reportserver/Pages/ReportViewer.aspx?%2fMARIZA%2f"+ cPrograma //+"&rs:Command=Render"+ cParam
  	
	If GetEnvServer() == "REMOTO"
		cLink		:= "http://proteus.marizaalimentos.com.br:10520/reportserver/Pages/ReportViewer.aspx?%2fMARIZA%2f"+ cPrograma
	EndIf
	*/
	
	/*
	teste
	If GetClientIP() == "192.168.1.101"
		cLink		:= "http://192.168.1.101:10530/reportserver/Pages/ReportViewer.aspx?%2fItinga_reports%2f"+ cPrograma
	EndIf
	*/

	If !Empty(cParam)
		cParam      := &cParam 
		cLink		:= cLink    + cParam
		cLinkInt    := cLinkInt + cParam  
		cLinkIe     := cLinkIe  + cParam  
	EndIf
		
	//Na versão 12, houve uma mudança na função que reversa 30pixels na janela
	
	If AllTrim(cversao)=="12"
		aSize[2] := 0
	EndIf

	aInfo := { aSize[1], aSize[2], aSize[3], aSize[4], 0, 05 }
	aAdd( aObj, { 000, 000, .T., .T. }) //MenuBar
	aPObj := MsObjSize( aInfo, aObj ) 

	aRethora := FwTimeUF("MG")

	//If aRethora[1] >= "20220101" //*<------------cofigurar a validade e trocar as datas abaixo
	//	Alert("SIGAWISE! Atualize os relatórios.")      
	//	Return()
	//EndIf

/*
cBaseUrl := cLink

cHtml:= "<!DOCTYPE html>"+;
          "<html>"+;
              '<head  lang="pt-BR">'+;  
              "</head>"+;
              "<body>"+;
                  "<h1>TWebEngine com SetHtml</h1>"+;
                  "<p>"+cLink+"</p>"+;
                  "<br>"+;
                  "<img src='workplace.jpg' alt='Workplace'>"+;
                  '<div lang="pt-BR" align="center">'+;
                  	'<IFRAME src="'+cLink+'" name=Destaques width=100% marginwidth="0" height=100% marginheight="0" align="top" scrolling=no frameBorder=0 hspace="0" vspace="0" allowtransparency="true"></IFRAME>'+;
                  '</div>'+;
              "</body>"+;
          "</html>"
 
 */
 
 cHtml:= "<html><body><script language=javascript>window.open('" + cLink + "','" + cPrograma + "','resizable=1,scrollbars=1,width=760,height=680,left=2,top=2,toolbar=0,status=0,location=0,menubar=0');</script></body></HTML>"
  
 aInfoGeral := GetRmtInfo()
  
 //Alert(aInfoGeral[9]) 
  
 //AVISO("Leia com Atenção!", "Os relatórios dinâmicos serão abertos em um modelo externo ao Protheus! Para Fechar use o (ALT)+[F4]!" , { "Fechar" }, 1)
 
 //WaitRun("cmd /c start iexplore.exe -k "+ '"' + cLink +'"', SW_SHOWNA )
 //&rc:Toolbar=false
 
//DRSFile(cLink) 
 
 
 //If !Empty(cParam)
 If  ("SAFARI") $ UPPER(aInfoGeral[9])
 
 	//ShellExecute('open',cLink,"","",1)
 	//ShellExecute("Open","http://www.google.com.br", "", "C:\", 1 )

	//DRSFile("D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\"+cPrograma+"_DS.PDF", cLink  +"&rs:Format=pdf")
  
	//IF ("SAFARI") $ UPPER(aInfoGeral[9])
    /*
	DEFINE MSDIALOG oDlg1 TITLE "RELATÓRIO "+ cDescri From aSize[7],0 to aSize[6],aSize[5] of oMainWnd PIXEL
	
		
		oTBar := TBar():New( oDlg1, 25, 32, .T.,,,, .F. )
		
	  //oTBtnBmp1 := TBtnBmp2():New( 00, 00, 35, 25, 'S4WB010N',,,,      { || AVISO("Leia com Atenção!", "Os relatórios dinâmicos serão abertos em um modelo externo ao Protheus! Para Fechar use o (ALT)+[F4]!" , { "Fechar" }, 1),ShellExecute( "Open", "%PROGRAMFILES%\Internet Explorer\iexplore.exe", '-k "' + cLink +'"', "C:\", 3 ) }, oTBar, 'Imprimir',, .F., .F. )
	    //oTBtnBmp2 := TBtnBmp2():New( 00, 00, 35, 25, 'PMSEXCEL',,,,      { || WaitRunSrv( '"D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\wget\wget.exe" -t 1 "' + cLinkInt  +'&rs:Format=pdf"  -O "D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\'+cPrograma+'.PDF"'   , .T. , "D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\wget\" )         , bOk := CpyS2T( "\RELINWEB\"+cPrograma+".xlsx", "C:\TEMP" ) , ShellExecute( "Open", cPrograma+'.xlsx',"" , "C:\TEMP\", 3 )}, oTBar, 'MS Excel',, .F., .F. )
	    
	    
	    oTBtnBmp2 := TBtnBmp2():New( 00, 00, 35, 25, 'PMSEXCEL',,,,      { || oWebEngine:PrintPDF() }, oTBar, '*.pdf',, .F., .F. )
	    
	    
	    //oTBtnBmp3 := TBtnBmp2():New( 00, 00, 35, 25, 'PAPEL_ESCRITO',,,, { || WaitRunSrv( '"D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\wget\wget.exe" -t 1 "' + cLinkInt  +'&rs:Format=EXCELOPENXML" -O "D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\'+cPrograma+'.xlsx"'  , .T. , "D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\wget\" ) , bOk := CpyS2T( "\RELINWEB\"+cPrograma+".PDF" , "C:\TEMP" ) , ShellExecute( "Open", cPrograma+'.TXT' ,"" , "C:\TEMP\", 3 )}, oTBar, 'TXT',, .F., .F. )
	    //oTBtnBmp4 := TBtnBmp2():New( 00, 00, 35, 25, 'ATALHO',,,,        { || WaitRunSrv( '"D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\wget\wget.exe" -t 1 "' + cLinkInt  +'&rs:Format=CSV" -O "D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\'+cPrograma+'.txt"'  , .T. , "D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\wget\" )           , bOk := CpyS2T( "\RELINWEB\"+cPrograma+".TXT" , "C:\TEMP" ) , ShellExecute( "Open", cPrograma+'.PDF' ,"" , "C:\TEMP\", 3 )}, oTBar, 'PDF',, .F., .F. )
	    oTBtnBmp4 := TBtnBmp2():New( 00, 00, 35, 25, 'TK_REFRESH',,,,    { || oWebEngine:setHtml(cHtml, cLink) }, oTBar, 'Atualizar',, .F., .F. )
	    oTBtnBmp4 := TBtnBmp2():New( 00, 00, 35, 25, 'FINAL',,,,         { || oDlg1:end() }, oTBar, 'Sair',, .F., .F. )
	    
		//oTIBrw := TIBrowser():New( aPObj[1,1],aPObj[1,2],aPObj[1,4],aPObj[1,3], cLink, oDlg1 )
		
		PRIVATE oWebChannel := TWebChannel():New()
	 	nPort 				:= oWebChannel::connect()
	 	 	
	 	oWebEngine := TWebEngine():New(oDlg1, aPObj[1,1],aPObj[1,2],aPObj[1,4],aPObj[1,3],,)
	 	//oWebEngine := TWebEngine():New(test:Content, 0, 0, 100, 100,, nPort)
	 	
		oWebEngine:navigate(cLink)
		
		//oWebEngine:bLoadFinished := {|self,url| DRSFile(cLink) }
	 	
		//oWebEngine:setHtml(cLink, cLink)
		//oWebEngine:Align := CONTROL_ALIGN_ALLCLIENT
		//oWebEngine:bLoadFinished := {|self,url| conout("Termino da carga do pagina: " + url) }
		
	Activate MsDialog oDlg1
	*/
Else

	//AVISO("Leia com Atenção!", "Os relatórios dinâmicos serão abertos em um modelo externo ao Protheus! Para Fechar use o (ALT)+[F4]!" , { "Fechar" }, 1)
	//ShellExecute( "Open", "%PROGRAMFILES%\Internet Explorer\iexplore.exe", '-k "' + cLink +'"', "C:\", 3 )
	//ShellExecute( "Open", "%PROGRAMFILES%\Internet Explorer\iexplore.exe", cHtml, "C:\", 3 )

EndIf
   
// Prepara o conector WebSocket

SetKey(VK_F12,{|| MUSRRP(AllTrim(aInfUsr[1][2]) , AllTrim(aInfUsr[1][14]) )} )

If Upper(cTipo) == "[IE]"

	AVISO("Leia com Atenção!", "Os relatórios dinâmicos serão abertos em um modelo externo ao Protheus! Para Fechar use o (ALT)+[F4]!" , { "Fechar" }, 1)
	ShellExecute( "Open", "%PROGRAMFILES%\Internet Explorer\iexplore.exe", '-k "' + cLinkIe +'"', "C:\", 3 )
	
Else

	DEFINE MSDIALOG oDlg1 TITLE "RELATÓRIO "+ cDescri From aSize[7],0 to aSize[6],aSize[5] of oMainWnd PIXEL
		//oTIBrw := TIBrowser():New( aPObj[1,1],aPObj[1,2],aPObj[1,4],aPObj[1,3], cLink, oDlg1 )
		
		//PRIVATE oWebChannel := TWebChannel():New()
	 	//nPort 			  := oWebChannel::connect()
	 	 	
	 	oWebEngine := TWebEngine():New(oDlg1, aPObj[1,1],aPObj[1,2],aPObj[1,4],aPObj[1,3],,)
		oWebEngine:cLang := "pt-BR"
	 	//oWebEngine := TWebEngine():New(test:Content, 0, 0, 100, 100,, nPort)
	 	
		oWebEngine:navigate(cLink)
		//oWebEngine:bDlStatus := {|self,nStatus,sPath| conout( "Status do download: " + Str(nStatus) + " (" + sPAth + ")" )}
		//oWebEngine:bLoadFinished := {|self,url| DRSFile(cLink) }
	 	
		//oWebEngine:setHtml(cHtml, cBaseUrl)
		oWebEngine:Align := CONTROL_ALIGN_ALLCLIENT
		//oWebEngine:bLoadFinished := {|self,url| conout("Termino da carga do pagina: " + url) }

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
 
Static Function DRSFile()
*******************************************************************************
*  
*
***
//local cLocalFile := "D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\test_bruno.pdf"
//local cURL1      := "http://192.168.1.101:10530/reportserver/Pages/ReportViewer.aspx?%2fItinga_reports%2fRIM0023&cFilDest=&rs:Format=pdf"

    Local cURL    := "http://192.168.1.101:10530"                      // URL DO SERVIÇO
    Local cPath   := "/reportserver/Pages/ReportViewer.aspx?%2fItinga_reports%2fRIM0023&cFilDest=&rs:Format=pdf" // RECURSO DA URI
    Local aHeader := {}                                           // CABEÇALHO DE INFORMAÇÕ?ES DA REQUISIÇÃO
    Local oRest   := NIL                                          // CLIENTE PARA CONSUMO
    Local nHandle := 00                                           // CÓDIGO DE SUPORTE AO ARQUIVO

        // INSTANCIA O CLIENTE REST
        oRest := FwRest():New(cURL)

        // INFORMA O RECURSO E O BODY
        oRest:SetPath(cPath)

        // ENVIA A REQUISIÇÃO E VALIDA O RESULTADO
        If (oRest:Get(aHeader))
            // CRIA O NOME DO ARQUIVO (FUNÇÕES UTILIZADAS PARA EVITAR CONFLITO DE NOME)
            nHandle := FCreate("\dirdoc\" + StrTran(DToS(Date()) + "_" + Time() + "_DOCUMENT.pdf", ":", ""))
            FWrite(nHandle, oRest:GetResult())
            FClose(nHandle)

            // VERIFICA SE O ARQUIVO FOI CRIADO CORRETAMENTE
            If (!File("\dirdoc\" + cFileName))
                ConOut("@ADVPL: Couldn't generate *.PDF file")
            EndIf
        Else
            ConOut("@ADVPL: Couldn't consume API")
        EndIf


/*local cUserPwd   := "" //"john.doe@example.com:my_password"
local aInfo      := {}
local nRet       := 0
local cFileName  := ""
         
Local cURL    := "http://192.168.1.101:10530"                      // URL DO SERVIÇO
Local cPath   := "/reportserver/Pages/ReportViewer.aspx?%2fItinga_reports%2fRIM0023&cFilDest=&rs:Format=pdf" // RECURSO DA URI
Local aHeader := {}                                           // CABEÇALHO DE INFORM
Local oRest   := NIL                                          // CLIENTE PARA CONSUMO
Local nHandle := 00                                           // CÓDIGO DE SUPORTE AO ARQUIVO

// PREPARAÇÃO DE AMBIENTE (REMOVER SE EXECUTADO VIA GUI)

// INSTANCIA O CLIENTE REST
oRest := FwRest():New(cURL)

// INFORMA O RECURSO E O BODY
oRest:SetPath(cPath)

// ENVIA A REQUISIÇÃO E VALIDA O RESULTADO
If (oRest:Get(aHeader))
    // CRIA O NOME DO ARQUIVO (FUNÇÕES UTILIZADAS PARA EVITAR CONFLITO DE NOME)
    nHandle := FCreate("\RELINWEB\" + StrTran(DToS(Date()) + "_" + Time() + "_DOCUMENT.pdf", ":", ""))
    FWrite(nHandle, oRest:GetResult())
    FClose(nHandle)

    // VERIFICA SE O ARQUIVO FOI CRIADO CORRETAMENTE
    If (!File("\RELINWEB\" + cFileName))
        ConOut("@ADVPL: Couldn't generate *.PDF file")
    EndIf
Else
    ConOut("@ADVPL: Couldn't consume API")
EndIf
         */
/* 
conout("* fazendo download do arquivo " + cLocalFile)
         
nRet = WDClient("GET", cLocalFile, cURL1, "", cUserPwd, @aInfo)
 
if nRet == 0
   conout("* download bem sucedido, verifique nos arquivos locais")
else
   conout(cLocalFile)
   conout(cURL1)
   conout("* erro " + AllTrim(Str(nRet)) + " no download")
   conout("* httpRespCode=" + AllTrim(Str(aInfo[1])))
   conout("* erro2=" + AllTrim(Str(aInfo[2])))
   conout("* erro3=" + AllTrim(Str(aInfo[3])))
endif
*/


Return()

