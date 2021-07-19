#INCLUDE "TOTVS.CH"
//#INCLUDE "XMLCSVCS.CH"
#INCLUDE "xmlxfun.ch"  
 
user function MSENDWHATS()

Local cUrl := "http://ptsv2.com/t/totvstests/post"
Local nTimeOut := 120
Local aHeadOut := {}
Local cHeadRet := ""
Local sPostRet := ""
aadd(aHeadOut,'User-Agent: Mozilla/4.0 (compatible; Protheus '+GetBuild()+')')
//aadd(Content-Type: multipart/form-data; boundary=TotvsBoundaryTest')                                      //Se desejar informar o boundary
aadd(aHeadOut,'Content-Type: multipart/form-data')
  
cPostParms := 'Content-Disposition: form-data; name="FileTextExample"; filename="\Teste.txt" ' + CRLF     //Envio de Arquivo especificando o Content-Type
cPostParms += 'Content-Type: text/plain;' + CRLF
cPostParms += 'Content-Disposition: form-data; name="FileTextExample"; filename="\Teste.txt"' + CRLF      //Envio de Arquivo sem espeficar o Content-Type
cPostParms += 'Content-Disposition: form-data; name="someParam"' + CRLF + CRLF                            //Envio de paramentos. Obrigatório Linha em branco antes do conteúdo
cPostParms += 'someParamValue'                                                                            //Conteúdo do Parametro

//cPostParms := 'Content-Disposition: form-data; name="FileTextExample"; filename="\ixblog\TESTE.TXT" Content-Type: text/plain; Content-Disposition: form-data; name="someParam"'
//sPostRet := HttpPost('http://192.168.1.101:10530/reportserver/Pages/ReportViewer.aspx?%2fItinga_reports%2fRQ0020&NUMCAVALETE=000300','','',nTimeOut,,@cHeadRet)
   
sPostRet := HttpPost(cUrl,'','',nTimeOut,,@cHeadRet)
if !empty(sPostRet)
  conout("HttpPost Ok ")
  varinfo("WebPage", sPostRet)
else
  conout("HttpPost Failed.")
  varinfo("Header", cHeadRet)
Endif

Return

User function  MPWhats()

//ShellExecute( "Open", "%PROGRAMFILES%\Internet Explorer\iexplore.exe", "https://web.whatsapp.com", "C:\", 1 )
/*
DEFINE MSDIALOG oDlg FROM 0,0 TO 650,1000 PIXEL TITLE 'Consulta Sefaz' 
     oTIBrowser:= TIBrowser():New(0,0,500,300,'https://web.whatsapp.com/',oDlg ) 
          oButton:= TButton():New(310,0070,'OK',oDlg,{||oDlg:End(),lContinue := .T.},40,10,,,,.T.)      
          oButton:= TButton():New(310,0150,'Cancela',oDlg,{||oDlg:End(),lContinue :=.F.},40,10,,,,.T.)      
     ACTIVATE MSDIALOG oDlg CENTERED 
    */ 
Return    