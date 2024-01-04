#INCLUDE "TopConn.CH"
#INCLUDE "RWMAKE.CH"
#INCLUDE "PROTHEUS.CH"   
#INCLUDE "TBICONN.CH"

/*                                          
Programa ...: F580CHAV.Prw
Uso ........: Ponto de Entrada (ORDENAÇÃO TELA DE LIBERAÇÃO)
Data .......: 30/05/23
Feito por ..: Bruno Lage Ferreira.
*/


User Function F580CHAV()
*************************************************************************************************************
*
*
*** 
Local  cChave		:= "E2_FILIAL+E2_NUM+E2_PARCELA+E2_TIPO"

Return(cChave)


User Function F580FAUT()
*************************************************************************************************************
*
*
*** 
Local cQueF580 := ""
Local aAreaF580:= GetArea()
Local cFilter1 := PARAMIXB[1]
Local cMail    := UsrRetMail(RetCodUsr())

cTabela   := "TB_F580DB"

If TcCanOpen(cTabela)  
   lOk := TcDelFile(cTabela)   
Else  
	conout("Talbela "+cTabela+" nao encontrada.")
Endif

cQueF580  := REPLACE(cQuery,' FROM SE2010 SE2 ',',dbo.COT_MOEDA_Q( CONVERT(VARCHAR(8),GETDATE(),112)  ,E2_MOEDA )TX_ATUAL, IIF(E2_MOEDA <>1, dbo.COT_MOEDA_Q( CONVERT(VARCHAR(8),GETDATE(),112)  ,E2_MOEDA ) * E2_SALDO,E2_SALDO) AS VLR_ATUAL  INTO TB_F580DB FROM SE2010 SE2 ')
cQueF580  := cQueF580 + ' WHERE ' + PARAMIXB[1] + " AND D_E_L_E_T_ = ''"

TcSQLExec(cQueF580)

If MsgYesNo("Deseja exportar para o e-mail os dados da tela?" )   
   WaitRunSrv( '"D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\wget\wget.exe" -t 1 "http://Administrator:xpacD99label@192.168.1.104:10530/ReportServer/Pages/ReportViewer.aspx?%2fItinga_reports%2fRQ0134&rs:Format=EXCELOPENXML" -O "D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\RQ0134.XLSX"' , .t. , "D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\wget\" )
   TCSPExec("SP_SENDMAIL",'ITINGA',Trim(cMail),'Tela Liberacao Pagamento','Relatorio em anexo.','\\192.168.1.103\d$\TOTVS 12\Microsiga\protheus_data\RELINWEB\RQ0134.XLSX')
EndIf

RestArea(aAreaF580)

Return(cFilter1)

