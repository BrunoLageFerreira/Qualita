#INCLUDE "TopConn.CH"
#INCLUDE "RWMAKE.CH"
#INCLUDE "PROTHEUS.CH"   
#INCLUDE "TBICONN.CH"
            
/*
Programa ...: MT241SD3.Prw
Uso ........: MT241SD3.Prw - Grava pendencia de importação apos geração dos dados SD3 
Data .......: 29/01/2019
Feito por ..: Bruno Lage Ferreira
Copyright @1998-2001,2019
*/ 

User Function MT241SD3()
*************************************************************************************************
* 
*
***
Local aArea      := GetArea()  
Local cChavePesq := SD3->D3_FILIAL+SD3->D3_DOC
Local cEnvMail   := ""


//SOMENTE PARA ITINGA 
IF SubString(CNUMEMP,1,2) == "05"

	dbSelectArea("SD3")
	dbSetOrder(2)
	dbGoTop()
	dbSeek(cChavePesq)
	Do While (SD3->D3_FILIAL+SD3->D3_DOC == cChavePesq )
	/*
	D3_XIMPORT
	D3_RECIMPO
	*/
		If SD3->D3_TM == '610'
			IF RecLock("SD3",.F.)
				Replace SD3->D3_XIMPORT  With "S"
				MsUnLock()
			EndIf
			
			// Abilita o sistema para gerar o relatio que sera 
			// enviado por email
			cEnvMail := SD3->D3_XFILDES
			
		ElseIf SD3->D3_TM == '200'
			
			cQuery := " UPDATE SD3050 
			cQuery += "    SET D3_XIMPORT = 'F'
			cQuery += "  FROM SD3050 
			cQuery += "  WHERE D_E_L_E_T_ <> '*'
			cQuery += "    AND D3_FILIAL + D3_DOC = '"+SD3->D3_XDOC+"'

			TcSQLExec(cQuery)
			
		EndIF
		
		dbSelectArea("SD3")
		dbSkip()
	EndDo

EndIf

If !Empty(cEnvMail)
	
	dbSelectArea("SX5")
	dbSetOrder(1)
	dbSeek(xFilial("SX5")+ "Z1" +cEnvMail )
	/*
	Geração do arquivo PDF na pasta destinada
	Necessario para processo de envio de email.
	*/
	WaitRunSrv( '"D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\wget\wget.exe" -t 1 "http://Administrator:xpacD99label@192.168.1.104:10530/reportserver/Pages/ReportViewer.aspx?%2fItinga_reports%2fRIM0023&cFilDest='+AllTrim(cEnvMail)+'&rs:Format=pdf" -O "D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\RIM0023.PDF"' , .t. , "D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\wget\" )
	
	/*
	Storage de procedure para envio de e-mails.
	A procedure esta localizada no SQL e recebe os parametros para envio do email. Arquivo PDF
	O envio do email automatico pelo Prothues apresentou falha e lentidão.
	*/
	TCSPExec("SP_SENDMAIL",'ITINGA',SX5->X5_DESCSPA,'Nova Transferência','Anexo relatório','\\192.168.1.103\d$\TOTVS 12\Microsiga\protheus_data\RELINWEB\RIM0023.pdf')
	
	//U_SWENARWAP(SX5->X5_DESCENG,"Nova Transferência","Nova Transferência","RIM0023","PDF","D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\RIM0023.pdf")
	//U_SWENARWAP("5533984022125","Nova Transferência","Nova Transferência","RIM0023","PDF","\RELINWEB\RIM0023.pdf")
	
	Alert("Email enviado com sucesso!")
	
EndIf

RestArea(aArea)

Return()


User Function MT241EST()
*************************************************************************************************
* /*especifico para o estono P.Entrada*/
*
***
Local aArea      := GetArea()  
Local cChavePesq := SD3->D3_FILIAL+SD3->D3_DOC

//SOMENTE PARA ITINGA 
IF SubString(CNUMEMP,1,2) == "05"

	dbSelectArea("SD3")
	dbSetOrder(2)
	dbGoTop()
	dbSeek(cChavePesq)
	Do While (SD3->D3_FILIAL+SD3->D3_DOC == cChavePesq )
	/*
	D3_XIMPORT
	D3_RECIMPO
	*/
		//If SD3->D3_TM == '610'
			IF RecLock("SD3",.F.)
				Replace SD3->D3_XIMPORT  With "E"
				MsUnLock()
			EndIf
			
			cQuery := " UPDATE SD3050 
			cQuery += "    SET D3_XIMPORT = 'S'
			cQuery += "  FROM SD3050 
			cQuery += "  WHERE D_E_L_E_T_ <> '*'
			cQuery += "    AND D3_FILIAL + D3_DOC = '"+SD3->D3_XDOC+"'

			TcSQLExec(cQuery)
			
		//EndIF
		dbSelectArea("SD3")
		dbSkip()
	EndDo

EndIf

RestArea(aArea)

Return

User Function MT241TOK()
*************************************************************************************************
* /*validação do movimento tipo 200*/,
*
***
Local lRet := .T.
Local nX   := 0

//somente para itinga 
IF SubString(CNUMEMP,1,2) == "05"   
	If IsBlind()     
	      Conout("Automático")
	      //Executa Rotina pelo Schedule (prepare environment) 
	Else
		IF cTM == "200"
			lRet := .F.
			Alert("O Tipo de movimentação 200 deve ser gerado atravez da rotina de importação automática.")
		EndIf
		
		// Validação da linha de filial de destino.
		For nX := 1 to Len(aCols)
			if gdFieldGet("D3_XFILDES",1) <> gdFieldGet("D3_XFILDES",nX)
					lRet := .F.
					Alert("A filial/empresa de destino na linha ," + AllTrim(str(nX))+ " não esta igual da primeira linha." )
			EndIf
		Next nX

	Endif
EndIf

Return lRet

User Function TMATA241()
*************************************************************************************************
* /*Importação automatica*/
*
***
Local _aCab1 := {}
Local _aItem := {}
Local _atotitem:={}
Local cCodigoTM:="200"

Private lMsHelpAuto := .t. // se .t. direciona as mensagens de help
Private lMsErroAuto := .f. //necessario a criacao

Private aPerg := {}
Private cPerg := "MPIMPMOVAT"
       
             
//Aadd(aPerg,{cPerg,"Empresa/Filial Destino?","C",06,00,"G","","SM0","","","","","",""})     
Aadd(aPerg,{cPerg,"Almoxarifiado Destino?","C",02,00,"G","","NNR","","","","","",""})
Aadd(aPerg,{cPerg,"Empresa/Filial Origem?","C",06,00,"G","","SM0","","","","","",""})     
Aadd(aPerg,{cPerg,"Documento de Origem?","C",09,00,"G","","","","","","","",""})

U_Testasx1(cPerg,aPerg,.t.) 

If ! Pergunte(cPerg,.T.)
	Return
EndIf

dbSelectArea("SD3")
dbSetOrder(2)
dbGoTop()
If !dbSeek(mv_par02+AllTrim(mv_par03))
	Alert("Documento não encontrado na origem!")
	Return
EndIf

IF SD3->D3_XIMPORT <> 'S'
	Alert("Documento já importado ou estornado e não poderá ser processado novamente!")
	Return
EndIF

If !EMPTY(SD3->D3_XFILDES)
	If SD3->D3_XFILDES <> SubString(CNUMEMP,3,6)
			Alert("A filial/empresa de destino do documento original, não é a filial/empresa de importação atual.")
		Return()
	EndIF
EndIf

Private _acod:={"1","MP1"}
//PREPARE ENVIRONMENT EMPRESA "05" FILIAL mv_par01 TABLES "SD3"

dbSelectArea("SD3")
dbSetOrder(2)
dbGoTop()
dbSeek(mv_par02+AllTrim(mv_par03))

_aCab1 := { {"D3_TM" ,cCodigoTM , NIL},;
			{"D3_FILIAL" ,xFilial("SD3") , NIL},;
			{"D3_CC" ,SD3->D3_CC , NIL},;
			{"D3_EMISSAO" ,ddatabase, NIL}} 
				
Do While (mv_par02+AllTrim(mv_par03) == SD3->D3_FILIAL +AllTrim(SD3->D3_DOC))

	_aItem := {}
	
	_aItem :={  {"D3_COD"    ,SD3->D3_COD                ,NIL},;
				{"D3_UM"     ,SD3->D3_UM                 ,NIL},; 
				{"D3_QUANT"  ,SD3->D3_QUANT              ,NIL},;
				{"D3_CUSTO1" ,SD3->D3_CUSTO1             ,NIL},;
				{"D3_XDOC"   ,mv_par02+AllTrim(mv_par03) ,NIL},;
				{"D3_XFILDES",xFilial("SD3")			 ,NIL},;
				{"D3_LOCAL"  ,AllTrim(mv_par01)          ,NIL}}			
				
	aadd(_atotitem,_aitem ) 	
	
	dbSelectArea("SD3")
	dbSkip()
EndDo

MSExecAuto({|x,y,z| MATA241(x,y,z)},_aCab1,_atotitem,3)

If lMsErroAuto 
	Mostraerro() 
	DisarmTransaction() 
	break
Else
	Alert("Dados importados com sucesso!")
EndIf

Return

User Function MTA241MNU()
*************************************************************************************************
* /*Especifico para o estorno do processo no menu*/
*
***

/*
private aRotina	:=  {	{OemToAnsi(STR0005),"AxPesqui"  , 0 , 1,0,.F.},;		//"Pesquisar"
						{OemToAnsi(STR0006),"A241Visual", 0 , 2,0,nil},;		//"Visualizar"
						{OemToAnsi(STR0007),"A241Inclui", 0 , 3,0,nil},;		//"Incluir"
						{OemToAnsi(STR0008),"A241Estorn", 0 , 6,0,nil},;		//"Estornar"
						{OemToAnsi(STR0052),"CTBC662"   , 0 , 7,0,Nil},;		//"Tracker Contábil"
						{OemToAnsi(STR0034),"A240Legenda", 0 , 2,0,.F.} }		//"Legenda"
If ExistBlock ("MTA241MNU")
	Execblock ("MTA241MNU",.F.,.F.)
Endif
*/

IF SubString(CNUMEMP,1,2) == "05"
	/*
	ITINGA
	*/
	aRotina	:=  {	{OemToAnsi("Pesquisar") 		,"AxPesqui"  				, 0 , 1,0,.F.},;		//"Pesquisar"
					{OemToAnsi("Visualizar")		,"A241Visual"				, 0 , 2,0,nil},;		//"Visualizar"
					{OemToAnsi("Incluir")   		,"A241Inclui"				, 0 , 3,0,nil},;		//"Incluir"
					{OemToAnsi("Estornar")  		,"u_MEstEs"  				, 0 , 6,0,nil},;		//"Estornar"
					{OemToAnsi("Rel.Saída Mat.") 	,"u_RELINWEB('RIM0019','Rel. Saída de Material','u_fParR19()','[IE]')"  	, 0 , 6,0,nil},;		//"Rel. Saida de Material"
					{OemToAnsi("Rel.Em Transito")	,"u_RELINWEB('RIM0023')"  	, 0 , 6,0,nil},;		//"Rel.Em Transito"
					{OemToAnsi("Importa Dados") 	,"u_TMATA241()"  			, 0 , 3,0,nil},;		//"Importa dados"
					{OemToAnsi("Tracker Contábil")	,"CTBC662"   				, 0 , 7,0,Nil},;		//"Tracker Contábil"
					{OemToAnsi("Legenda")			,"A240Legenda"				, 0 , 2,0,.F.} }		//"Legenda"
			
Else
	/*
	QUALITA
	*/
	aRotina	:=  {	{OemToAnsi("Pesquisar") 		,"AxPesqui"  				, 0 , 1,0,.F.},;		//"Pesquisar"
					{OemToAnsi("Visualizar")		,"A241Visual"				, 0 , 2,0,nil},;		//"Visualizar"
					{OemToAnsi("Incluir")   		,"A241Inclui"				, 0 , 3,0,nil},;		//"Incluir"
					{OemToAnsi("Estornar")			,"A241Estorn"				, 0 , 6,0,nil},;		//"Estornar"
					{OemToAnsi("Rel.Saída Mat.") 	,"u_RELINWEB('RQ0019','Rel. Saída de Material','u_fParR19()','[IE]')"   	, 0 , 6,0,nil},;		//"Rel. Saida de Material"
					{OemToAnsi("Tracker Contábil")	,"CTBC662"   				, 0 , 7,0,Nil},;		//"Tracker Contábil"
					{OemToAnsi("Legenda")			,"A240Legenda"				, 0 , 2,0,.F.} }		//"Legenda"
		
EndIf

Return()

User Function fParR19()
****************************************************************************************************************
*    
*
****
Local cRet := ""

cRet := "&cCodDoc=" + SD3->D3_DOC

Return(cRet)

User Function MEstEs()
*************************************************************************************************
* /*Especifico para o estorno do processo*/
*
***
Local aArea      := GetArea()  
Local lRet       := .T.
Local cChavePesq := SD3->D3_FILIAL+SD3->D3_DOC

//SOMENTE PARA ITINGA 
IF SubString(CNUMEMP,1,2) == "05"

	dbSelectArea("SD3")
	dbSetOrder(2)
	dbGoTop()
	dbSeek(cChavePesq)
	Do While (SD3->D3_FILIAL+SD3->D3_DOC == cChavePesq ) 

		IF SD3->D3_TM = '200'
			//If !EMPTY(SD3->D3_X)
				lRet := .T.
			//EndIf
		ELSEIF SD3->D3_TM = '610'
			If SD3->D3_XIMPORT == "F"
				lRet := .F.
			EndIF
		EndIF
			
		dbSelectArea("SD3")
		dbSkip()
	EndDo
EndIf

RestArea(aArea)

If lRet == .F.
	Alert("Este registro já foi importado na filial de destino e não poderá ser excluído ou alterado!")
Else
	dbSelectArea("SD3")
	a241Estorn("SD3",Recno(),0 , 6,0,nil)
EndIf

Return()
