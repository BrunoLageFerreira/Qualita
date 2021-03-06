#include "protheus.ch"
#include "rwmake.ch"
#include "tbiconn.ch"  
#INCLUDE "TOTVS.CH"
#INCLUDE "topconn.ch"

/*
Programa ...: LIBWHATSAPP.Prw
Uso ........: Programa verifica a prova��o do pedido automaticamente pelo WhatsApp
Data .......: 23/03/2020
Feito por ..: Bruno Lage Ferreira
Copyright @1998-2001,2021

Q-Libera��o Faturamento
5527995295180-1587589430@g.us
logistica.es@qualitagroup.com;comercial.es@grupoqualita.com.br

Q-N2 - Libera��o Compras
5527995295180-1594316108@g.us
pedido.compra@grupoqualita.com.br

Q-N1 - Libera��o Compras
5527995295180-1587589523@g.us
pedido.compra@grupoqualita.com.br
*/ 

User Function LIBWHATSAPP()  
************************************************************************************************************
*
*
*
**************
Local cQuery   := ""
Local lAutoZAP := .F.

Local aLogAuto := {}

Local oJson
Local cErr     := ""
/*
Local lMsg     := ""
*/
Local cMessage := ""
Local lEnvProt := .F.
Local nAux

ConOut( ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>   WHATSAPP APROVA��O   <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<" )

If Select("SX2")==0  
	PREPARE ENVIRONMENT EMPRESA "01" FILIAL "01" TABLES "WAM","SC5"
	Conout(DtoC(dDatabase)+" - "+TIME()+" Iniciando JOB de libera��o de Retorno pelo WHATSAPP.")
	lAutoZAP := .T.
EndIf


/*
******************************************************************************************
chamada do Modulo AutoStart
TODOS OS COMANDOS VIA PROCEDUTE
*/
ConOut("*********************************************************************************")
ConOut("*********************************************************************************")
ConOut("*********************         INICIANDO AUTOSTART          **********************")
ConOut("*********************************************************************************")
ConOut("*********************************************************************************")

TCSPEXEC("WHATSAPP_AUTOSTART")
   
/*
*
******************************************************************************************
*/
cQuery :=  " SELECT  
cQuery +=  " 		WAM_FILIAL,
cQuery +=  " 		WAM_DATA,
cQuery +=  " 		WAM_HORA,
cQuery +=  " 		WAM_ID,
cQuery +=  " 		RTRIM(LTRIM(ISNULL(CONVERT(VARCHAR(2047), CONVERT(VARBINARY(2047), WAM_MSG)),''))) WAM_MSG,
cQuery +=  " 		WAM_TELL,
cQuery +=  " 		WAM_INDEX,
cQuery +=  " 		WAM_PERG,
cQuery +=  " 		WAM_DATAR,
cQuery +=  " 		WAM_HORAR,
cQuery +=  " 		WAM_RESPOS,
cQuery +=  " 		WAM_EXEC,
cQuery +=  " 		WAM_NIVEL
cQuery +=  " 		FROM WAM010 WHERE D_E_L_E_T_ = '' AND CAST(WAM_DATA AS DATE) > CAST(GETDATE()-4 AS DATE) AND WAM_PERG = 'S' AND WAM_EXEC LIKE '%QUALITA%'

dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "TRBRA", .F., .T.)
dbSelectArea("TRBRA")
dbgotop()
Do While !EOF()

	If !Empty(TRBRA->WAM_ID)	
		Conout(DtoC(dDatabase)+" - "+TIME()+"Protocolo: ["+ AllTrim(TRBRA->WAM_ID) + "] INDEX:" + TRBRA->WAM_INDEX )
		
		// Cria o objeto JSON e popula ele a partir da string
		
		oJson := JSonObject():New()
		cErr  := oJSon:fromJson(U_SWREMGWAP(AllTrim(TRBRA->WAM_ID)))
		
		sleep(100)
		
		ConOut(oJson:GetJSonObject('quote_message'))
		
		If !Empty(cErr)
		  	Conout(cErr + "Protocolo:" + AllTrim(TRBRA->WAM_ID))
		  	
		  	// Descarta o objeto 
		  	FreeObj(oJson)
		  
		  	dbSelectArea("TRBRA")
		  	dbSkip()
		Endif
		
		// Agora vamos ler as propriedades com GetJSonObject()
		 aRetMsg :=	strTokArr(U_SWREMGWAP(TRBRA->WAM_ID), ',' )
	EndIf
	
	
	/*
	**********************************************************************************************************************
	Tratamento das libera��o 
	 - Mapa de Cota��o
	 - Pedido de Compra
	 - Pedido de Vendas
	**********************************************************************************************************************
	*/
	IF AllTrim(TRBRA->WAM_EXEC) == "QUALITA-MC"
		
		/*
		***************************************************
		NIVEL 1
		***************************************************
		*/
		If AllTrim(TRBRA->WAM_NIVEL) == "1"
			
			/*
			Processamento dos retorno Mapa de cota��o-MC
			*/
			If oJson:GetJSonObject('quoted') == "true"
			
				cMessage := oJson:GetJSonObject('quote_message')
				
				//ENVIO DO PROTOCOLO 
				lEnvProt := .T.
				
				If  "APROVADO" $ Upper(cMessage) 
					dbSelectArea("SC8")
					dbSetOrder(1)
					If dbSeek(AllTrim(TRBRA->WAM_INDEX))
										
						WaitRunSrv( '"D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\wget\wget.exe" -t 1 "http://192.168.1.101:10530/ReportServer/Pages/ReportViewer.aspx?%2fItinga_reports%2fRQ0025_V&cCotacao=' + SC8->C8_NUM +'&rs:Format=pdf" -O "D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\MC-'+ SC8->C8_NUM +'.PDF"' , .t. , "D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\wget\" )
						
						
						ConOut("Gerando relat�rio! Mapa de Cota��o:" + AllTrim(SC8->C8_NUM) )
						sleep(300)
						ConOut("Gerando e-mail! Mapa de Cota��o:" + AllTrim(SC8->C8_NUM) )
						
						cProt := U_SWENARWAP("5527995295180-1594316108@g.us", "APROVADO NO NIVEL 1.  MSG(" + AllTrim(TRBRA->WAM_MSG) + ")"                                                                     ,"MC"+ SC8->C8_NUM             ,"MC-" + SC7->C7_NUM  ,"PDF","\RELINWEB\MC-"+ SC8->C8_NUM +".PDF")
						
						/*
						30 segundos
						*/
						sleep(300)
						
						IF cProt = "" .or. cProt = nil 
							ConOut("ERRO!!! O WhatsApp pode estar passando por alguma instabilidade no momento. Aguarde alguns instantes de tente novamente mais tarde! MC-"+ SC8->C8_NUM +".PDF")
							Return()
						EndIf
						
						
						If  RecLock("WAM",.T.) 
							Replace WAM_FILIAL  With "" 
							Replace WAM_DATA    With Date()
							Replace WAM_HORA    With Time()
							Replace WAM_ID      With cProt
							Replace WAM_MSG     With "APROVADO NO NIVEL 1.  MSG(" + AllTrim(TRBRA->WAM_MSG) + ")"
							Replace WAM_INDEX   With SC8->C8_FILIAL + SC8->C8_NUM
							Replace WAM_PERG    With "S"
							Replace WAM_NIVEL   With "2"
							IF SubString(CNUMEMP,1,2) == "05"
								Replace WAM_EXEC    With 'ITINGA-MC'
							Else
								Replace WAM_EXEC    With 'QUALITA-MC'
							EndIf
						   MsUnLock()
						EndIf
						
						/*
						Marcando o protocolo como j� lido. 
						*/
						cQuery := " UPDATE WAM010 
						cQuery += "    SET WAM_PERG = 'N',WAM_DATAR='"+ DToS(dDataBase) +"', WAM_HORAR='"+ LEFT(AllTrim(TIME()),5) +"', WAM_RESPOS='"+ Upper(cMessage) +"'"
						cQuery += "  FROM WAM010 
						cQuery += "  WHERE D_E_L_E_T_ <> '*'
						cQuery += "    AND WAM_ID = '"+TRBRA->WAM_ID+"'
						cQuery += "    AND WAM_NIVEL = '1'
				
						TcSQLExec(cQuery)
													
					EndIf
				Else
				
						/*
						Marcando o protocolo como j� lido
						*/
						cQuery := " UPDATE WAM010 
						cQuery += "    SET WAM_PERG = 'N',WAM_DATAR='"+ DToS(dDataBase) +"', WAM_HORAR='"+ LEFT(AllTrim(TIME()),5) +"', WAM_RESPOS='"+ Upper(cMessage) +"'"
						cQuery += "  FROM WAM010 
						cQuery += "  WHERE D_E_L_E_T_ <> '*'
						cQuery += "    AND WAM_ID = '"+TRBRA->WAM_ID+"'
						cQuery += "    AND WAM_NIVEL = '1'
				
						TcSQLExec(cQuery)
						
						/*
						Coloca a MSg mais n�o mostra data nem hora de libera��o
						*/
						cQuery := " UPDATE " + RetSqlName("SC8")  
						cQuery += "    SET C8_MSGLIB='"+ "N�O LIBERADO: " + Upper(cMessage) +"'"
						cQuery += "   FROM " + RetSqlName("SC8")
						cQuery += "  WHERE D_E_L_E_T_ <> '*'
						cQuery += "    AND C8_NUM = '"+SC8->C8_NUM+"'
						
						
						TcSQLExec(cQuery)
										
						TCSPExec("SP_SENDMAIL",'ITINGA',"pedido.compra@grupoqualita.com.br",'Mapa de Cota��o N�O Liberado! C�digo:' + TRBRA->WAM_INDEX , 'COTA��O N�O LIBERADA!'+ "<br>" + 'C�DIGO:' + TRBRA->WAM_INDEX + "<br>" + "MENSAGEM WHATSAPP:"+ Upper(cMessage),'')
						
						Conout(DtoC(dDatabase)+" - "+TIME()+" E-mail enviado (Mapa de Cota��o N�O liberado):" + TRBRA->WAM_INDEX )	
					
				EndIf
				
			EndIf
		
		EndIf
		
		
		
		/*
		***************************************************
		NIVEL 2
		***************************************************
		*/
		If AllTrim(TRBRA->WAM_NIVEL) == "2"
			
			/*
			Processamento dos retorno Mapa de cota��o-MC
			*/
			If oJson:GetJSonObject('quoted') == "true"
			
				cMessage := oJson:GetJSonObject('quote_message')
				
				//ENVIO DO PROTOCOLO 
				lEnvProt := .T.
				
				If  "APROVADO" $ Upper(cMessage) 
					dbSelectArea("SC8")
					dbSetOrder(1)
					If dbSeek(AllTrim(TRBRA->WAM_INDEX))
					
						/*
						Marcando o protocolo como ja lido 
						*/
						cQuery := " UPDATE WAM010 
						cQuery += "    SET WAM_PERG = 'N',WAM_DATAR='"+ DToS(dDataBase) +"', WAM_HORAR='"+ LEFT(AllTrim(TIME()),5) +"', WAM_RESPOS='"+ Upper(cMessage) +"'"
						cQuery += "  FROM WAM010 
						cQuery += "  WHERE D_E_L_E_T_ <> '*'
						cQuery += "    AND WAM_ID = '"+TRBRA->WAM_ID+"'
						cQuery += "    AND WAM_NIVEL = '2'
				
						TcSQLExec(cQuery)
					
						/*
						Gravando aprova��o na SC8
						*/
						cQuery := " UPDATE " + RetSqlName("SC8")  
						cQuery += "    SET C8_DATALIB='"+ DToS(dDataBase) +"',C8_HORALIB='"+ LEFT(AllTrim(TIME()),5) +"',C8_MSGLIB='"+ Upper(cMessage) +"'"
						cQuery += "  FROM " + RetSqlName("SC8")
						cQuery += "  WHERE D_E_L_E_T_ <> '*'
						cQuery += "    AND C8_NUM = '"+SC8->C8_NUM+"'
						
				
						TcSQLExec(cQuery)
					
						WaitRunSrv( '"D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\wget\wget.exe" -t 1 "http://192.168.1.101:10530/ReportServer/Pages/ReportViewer.aspx?%2fItinga_reports%2fRQ0025_V&cCotacao=' + SC8->C8_NUM +'&rs:Format=pdf" -O "D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\MC-'+ SC8->C8_NUM +'.PDF"' , .t. , "D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\wget\" )
						
						ConOut("Gerando relat�rio! Mapa de Cota��o:" + AllTrim(SC8->C8_NUM) )
						sleep(300)
						ConOut("Gerando e-mail! Mapa de Cota��o:" + AllTrim(SC8->C8_NUM) )
						
						TCSPExec("SP_SENDMAIL",'ITINGA',"pedido.compra@grupoqualita.com.br",'Mapa de Cota��o Liberado!     C�digo:' + SC8->C8_NUM       ,'COTA��O LIBERADA! C�digo:'              + SC8->C8_NUM + ', liberado!'+ "<br>" +'C�DIGO:' + SC8->C8_NUM + "<br>" + "MENSAGEM WHATSAPP:"+ Upper(cMessage),'D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\MC-'+ SC8->C8_NUM +'.PDF')
						
						Conout(DtoC(dDatabase)+" - "+TIME()+" E-mail enviado P.Venda:" + AllTrim(SC8->C8_NUM) )	
					
					EndIf
				Else
				
						/*
						Marcando o protocolo como ja lido
						*/
						cQuery := " UPDATE WAM010 
						cQuery += "    SET WAM_PERG = 'N',WAM_DATAR='"+ DToS(dDataBase) +"', WAM_HORAR='"+ LEFT(AllTrim(TIME()),5) +"', WAM_RESPOS='"+ Upper(cMessage) +"'"
						cQuery += "  FROM WAM010 
						cQuery += "  WHERE D_E_L_E_T_ <> '*'
						cQuery += "    AND WAM_ID = '"+TRBRA->WAM_ID+"'
						cQuery += "    AND WAM_NIVEL = '2'
				
						TcSQLExec(cQuery)
						
						/*
						Coloca a MSg mais n�o mostra data nem hora de libera��o
						*/
						cQuery := " UPDATE " + RetSqlName("SC8")  
						cQuery += "    SET C8_MSGLIB='"+ "N�O LIBERADO: " + Upper(cMessage) +"'"
						cQuery += "   FROM " + RetSqlName("SC8")
						cQuery += "  WHERE D_E_L_E_T_ <> '*'
						cQuery += "    AND C8_NUM = '"+SC8->C8_NUM+"'
						
						TcSQLExec(cQuery)
										
						TCSPExec("SP_SENDMAIL",'ITINGA',"pedido.compra@grupoqualita.com.br",'Mapa de Cota��o N�O Liberado! C�digo:' + TRBRA->WAM_INDEX , 'COTA��O N�O LIBERADA!'+ "<br>" + 'C�DIGO:' + TRBRA->WAM_INDEX + "<br>" + "MENSAGEM WHATSAPP:"+ Upper(cMessage),'')
						
						Conout(DtoC(dDatabase)+" - "+TIME()+" E-mail enviado (Mapa de Cota��o N�O liberado):" + TRBRA->WAM_INDEX )	
					
				EndIf
				
			EndIf
		
		EndIf

	ElseIf AllTrim(TRBRA->WAM_EXEC) == "QUALITA-PC"
	
		/*
		***************************************************
		NIVEL 1
		***************************************************
		*/
		If AllTrim(TRBRA->WAM_NIVEL) == "1"
	
			/*
			Processamento dos retorno Pedido de Compra-PC
			*/
			If oJson:GetJSonObject('quoted') == "true"
				
				
				cMessage := oJson:GetJSonObject('quote_message')
				
				//ENVIO DO PROTOCOLO 
				lEnvProt := .T.
				
				If "APROVADO" $ Upper(cMessage) 
					dbSelectArea("SC7")
					dbSetOrder(1)
					If dbSeek(AllTrim(TRBRA->WAM_INDEX))
					
											
						/*
						Gera dados do pedido 
						*/
						u_ImpPc(2)
						WaitRunSrv('"D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\wget\wget.exe" -t 1 "http://192.168.1.101:10530/ReportServer/Pages/ReportViewer.aspx?%2fItinga_reports%2fRXX0022&rs:Format=pdf" -O "D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\PC-'+SC7->C7_NUM+'.PDF"' , .t. , "D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\wget\" )						
						
						cProt := U_SWENARWAP("5527995295180-1594316108@g.us", "APROVADO NO NIVEL 1.  MSG(" + AllTrim(TRBRA->WAM_MSG) + ")"                                                                     ,"PC-2-" + SC7->C7_NUM         ,"PC-2-" + SC7->C7_NUM   ,"PDF","\RELINWEB\PC-" + SC7->C7_NUM + ".PDF")
						
						/*
						30 segundos
						*/
						sleep(300)
						        						                  
						IF cProt = "" .or. cProt = nil 
							ConOut("ERRO!!! O WhatsApp pode estar passando por alguma instabilidade no momento. Aguarde alguns instantes de tente novamente mais tarde! PC-"+SC7->C7_NUM+".PDF")
							Return()
						EndIf                 
						                      
						If  RecLock("WAM",.T.) 
							Replace WAM_FILIAL  With "" 
							Replace WAM_DATA    With Date()
							Replace WAM_HORA    With Time()
							Replace WAM_ID      With cProt
							Replace WAM_MSG     With "APROVADO NO NIVEL 1.  MSG(" + AllTrim(TRBRA->WAM_MSG) + ")" 
							Replace WAM_INDEX   With SC7->C7_FILIAL + SC7->C7_NUM
							Replace WAM_PERG    With "S"
							Replace WAM_NIVEL   With "2"
							IF SubString(CNUMEMP,1,2) == "05"
								Replace WAM_EXEC    With 'ITINGA-PC'
							Else
								Replace WAM_EXEC    With 'QUALITA-PC'
							EndIf
							
						   MsUnLock()
						EndIf

						/*
						Marcando o protocolo como ja lido 
						*/
						cQuery := " UPDATE WAM010 
						cQuery += "    SET WAM_PERG = 'N',WAM_DATAR='"+ DToS(dDataBase) +"', WAM_HORAR='"+ LEFT(AllTrim(TIME()),5) +"', WAM_RESPOS='"+ Upper(cMessage) +"'"
						cQuery += "  FROM WAM010 
						cQuery += "  WHERE D_E_L_E_T_ <> '*'
						cQuery += "    AND WAM_ID = '"+TRBRA->WAM_ID+"'
						cQuery += "    AND WAM_NIVEL = '1'
				
						TcSQLExec(cQuery)
						
					
					EndIf
				Else
					dbSelectArea("SC7")
					dbSetOrder(1)
					If dbSeek(AllTrim(TRBRA->WAM_INDEX))
					
						/*
						Marcando o protocolo como ja lido 
						*/
						cQuery := " UPDATE WAM010 
						cQuery += "    SET WAM_PERG = 'N',WAM_DATAR='"+ DToS(dDataBase) +"', WAM_HORAR='"+ LEFT(AllTrim(TIME()),5) +"', WAM_RESPOS='"+ Upper(cMessage) +"'"
						cQuery += "  FROM WAM010 
						cQuery += "  WHERE D_E_L_E_T_ <> '*'
						cQuery += "    AND WAM_ID = '"+TRBRA->WAM_ID+"'
						//cQuery += "    AND WAM_TELL = ''
				
						TcSQLExec(cQuery)
						
	
						/*
						Gravando aprova��o na SC7
						*/
						cQuery := " UPDATE " + RetSqlName("SC7")  
						cQuery += "    SET C7_MSGLIB='"+ Upper(cMessage) +"'"
						cQuery += "  FROM " + RetSqlName("SC7")
						cQuery += "  WHERE D_E_L_E_T_ <> '*'
						cQuery += "    AND C7_NUM = '"+SC7->C7_NUM+"'
						//cQuery += "    AND WAM_TELL = ''
				
						TcSQLExec(cQuery)
					
					
						/*
						Gera dados do pedido 
						*/
						//u_ImpPc(2)
						//WaitRunSrv( '"D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\wget\wget.exe" -t 1 "http://192.168.1.101:10530/ReportServer/Pages/ReportViewer.aspx?%2fItinga_reports%2fRXX0022&rs:Format=pdf" -O "D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\PC-'+SC7->C7_NUM+'.PDF"' , .t. , "D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\wget\" )
						
						//ConOut("Gerando relat�rio! Pedido de Compras:" + AllTrim(SC7->C7_NUM) )
						sleep(300)
						ConOut("Gerando e-mail! Ped. Compras:" + AllTrim(SC7->C7_NUM) )
						
						
						//TCSPExec("SP_SENDMAIL",'ITINGA',"almoxarifado@grupoqualita.com.br;emelly.couto@grupoqualita.com.br;bruno.lage@grupoqualita.com.br",'Pedido N�O Liberado! C�digo:' + SC7->C7_NUM + ', n�o liberado!'+ "<br>" +'C�DIGO:' + SC7->C7_NUM + "<br>" + "MENSAGEM WHATSAPP:"+ Upper(cMessage),'D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\RXX0022.PDF')
						TCSPExec("SP_SENDMAIL",'ITINGA','pedido.compra@grupoqualita.com.br', 'Pedido N�o Liberado! C�digo:' + SC7->C7_NUM , 'Pedido N�o Liberado' + '<br>' +'C�DIGO:' + SC7->C7_NUM +  "<br>" + "MENSAGEM WHATSAPP:"+ Upper(cMessage)     ,'')
						
						Conout(DtoC(dDatabase)+" - "+TIME()+" E-mail enviado Pedido de Compras:" + AllTrim(SC7->C7_NUM) )	
					
					EndIf
			
				EndIf	
			
			EndIf
			
		EndIf
	
	
		/*
		***************************************************
		NIVEL 2
		***************************************************
		*/
		If AllTrim(TRBRA->WAM_NIVEL) == "2"
	
			/*
			Processamento dos retorno Pedido de Compra-PC
			*/
			If oJson:GetJSonObject('quoted') == "true"
				
				
				cMessage := oJson:GetJSonObject('quote_message')
				
				//ENVIO DO PROTOCOLO 
				lEnvProt := .T.
				
				If "APROVADO" $ Upper(cMessage) 
					dbSelectArea("SC7")
					dbSetOrder(1)
					If dbSeek(AllTrim(TRBRA->WAM_INDEX))
					
					
						/*
						Marcando o protocolo como ja lido 
						*/
						cQuery := " UPDATE WAM010 
						cQuery += "    SET WAM_PERG = 'N',WAM_DATAR='"+ DToS(dDataBase) +"', WAM_HORAR='"+ LEFT(AllTrim(TIME()),5) +"', WAM_RESPOS='"+ Upper(cMessage) +"'"
						cQuery += "  FROM WAM010 
						cQuery += "  WHERE D_E_L_E_T_ <> '*'
						cQuery += "    AND WAM_ID = '"+TRBRA->WAM_ID+"'
						cQuery += "    AND WAM_NIVEL = '2'
				
						TcSQLExec(cQuery)
						
						/*
						Gravando aprova��o na SC7
						*/
						cQuery := " UPDATE " + RetSqlName("SC7")  
						cQuery += "    SET C7_DATALIB='"+ DToS(dDataBase) +"',C7_HORALIB='"+ LEFT(AllTrim(TIME()),5) +"',C7_MSGLIB='"+ Upper(cMessage) +"'"
						cQuery += "  FROM " + RetSqlName("SC7")
						cQuery += "  WHERE D_E_L_E_T_ <> '*'
						cQuery += "    AND C7_NUM = '"+SC7->C7_NUM+"'
						
						TcSQLExec(cQuery)
					
						/*
						Gera dados do pedido 
						*/
						u_ImpPc(2)
						WaitRunSrv('"D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\wget\wget.exe" -t 1 "http://192.168.1.101:10530/ReportServer/Pages/ReportViewer.aspx?%2fItinga_reports%2fRXX0022&rs:Format=pdf" -O "D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\PC-'+SC7->C7_NUM+'.PDF"' , .t. , "D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\wget\" )
						
						ConOut("Gerando relat�rio! Pedido de Compras:" + AllTrim(SC7->C7_NUM) )
						sleep(300)
						ConOut("Gerando e-mail! Ped. Compras:" + AllTrim(SC7->C7_NUM) )
						
						TCSPExec("SP_SENDMAIL",'ITINGA','pedido.compra@grupoqualita.com.br', 'Pedido Liberado! C�digo:' + SC7->C7_NUM , 'Pedido Liberado' + '<br>' +'C�DIGO:' + SC7->C7_NUM +  "<br>" + "MENSAGEM WHATSAPP:"+ Upper(cMessage)     ,'D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\PC-'+SC7->C7_NUM+'.PDF')
	
						Conout(DtoC(dDatabase)+" - "+TIME()+" E-mail enviado Pedido de Compras:" + AllTrim(SC7->C7_NUM) )
					
									
					EndIf
				Else
					dbSelectArea("SC7")
					dbSetOrder(1)
					If dbSeek(AllTrim(TRBRA->WAM_INDEX))
					
						/*
						Marcando o protocolo como ja lido 
						*/
						cQuery := " UPDATE WAM010 
						cQuery += "    SET WAM_PERG = 'N',WAM_DATAR='"+ DToS(dDataBase) +"', WAM_HORAR='"+ LEFT(AllTrim(TIME()),5) +"', WAM_RESPOS='"+ Upper(cMessage) +"'"
						cQuery += "  FROM WAM010 
						cQuery += "  WHERE D_E_L_E_T_ <> '*'
						cQuery += "    AND WAM_ID = '"+TRBRA->WAM_ID+"'
						//cQuery += "    AND WAM_TELL = ''
				
						TcSQLExec(cQuery)
						
	
						/*
						Gravando aprova��o na SC7
						*/
						cQuery := " UPDATE " + RetSqlName("SC7")  
						cQuery += "    SET C7_MSGLIB='"+ Upper(cMessage) +"'"
						cQuery += "  FROM " + RetSqlName("SC7")
						cQuery += "  WHERE D_E_L_E_T_ <> '*'
						cQuery += "    AND C7_NUM = '"+SC7->C7_NUM+"'
						//cQuery += "    AND WAM_TELL = ''
				
						TcSQLExec(cQuery)
					
					
						/*
						Gera dados do pedido 
						*/
						//u_ImpPc(2)
						//WaitRunSrv( '"D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\wget\wget.exe" -t 1 "http://192.168.1.101:10530/ReportServer/Pages/ReportViewer.aspx?%2fItinga_reports%2fRXX0022&rs:Format=pdf" -O "D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\PC-'+SC7->C7_NUM+'.PDF"' , .t. , "D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\wget\" )
						
						//ConOut("Gerando relat�rio! Pedido de Compras:" + AllTrim(SC7->C7_NUM) )
						sleep(300)
						ConOut("Gerando e-mail! Ped. Compras:" + AllTrim(SC7->C7_NUM) )
						
						
						//TCSPExec("SP_SENDMAIL",'ITINGA',"almoxarifado@grupoqualita.com.br;emelly.couto@grupoqualita.com.br;bruno.lage@grupoqualita.com.br",'Pedido N�O Liberado! C�digo:' + SC7->C7_NUM + ', n�o liberado!'+ "<br>" +'C�DIGO:' + SC7->C7_NUM + "<br>" + "MENSAGEM WHATSAPP:"+ Upper(cMessage),'D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\RXX0022.PDF')
						TCSPExec("SP_SENDMAIL",'ITINGA','pedido.compra@grupoqualita.com.br', 'Pedido N�o Liberado! C�digo:' + SC7->C7_NUM , 'Pedido N�o Liberado' + '<br>' +'C�DIGO:' + SC7->C7_NUM +  "<br>" + "MENSAGEM WHATSAPP:"+ Upper(cMessage)     ,'')
						
						Conout(DtoC(dDatabase)+" - "+TIME()+" E-mail enviado Pedido de Compras:" + AllTrim(SC7->C7_NUM) )	
					
					EndIf
			
				EndIf	
			
			EndIf
			
		EndIf
	
	
	Else
		/*
		Processamento dos retornos Pedido de Venda PV 
		*/
		If oJson:GetJSonObject('quoted') == "true"
		
			cMessage := oJson:GetJSonObject('quote_message')
			
			//ENVIO DO PROTOCOLO 
			lEnvProt := .T.
			
			If  "APROVADO" $ Upper(cMessage) 
				dbSelectArea("SC5")
				dbSetOrder(1)
				If dbSeek(AllTrim(TRBRA->WAM_INDEX))
					
					RecLock("SC5",.F.)
						SC5->C5_BLQ  := ''
					MsUnlock()	
					
					cQuery := " UPDATE WAM010 
					cQuery += "    SET WAM_PERG = 'N',WAM_DATAR='"+ DToS(dDataBase) +"', WAM_HORAR='"+ LEFT(AllTrim(TIME()),5) +"', WAM_RESPOS='"+ Upper(cMessage) +"'"
					cQuery += "  FROM WAM010 
					cQuery += "  WHERE D_E_L_E_T_ <> '*'
					cQuery += "    AND WAM_ID = '"+TRBRA->WAM_ID+"'
					//cQuery += "    AND WAM_TELL = ''
			
					TcSQLExec(cQuery)
				
					If SC5->C5_YTIPO == "ME"
						WaitRunSrv( '"D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\wget\wget.exe" -t 1 "http://192.168.1.101:10530/ReportServer/Pages/ReportViewer.aspx?%2fItinga_reports%2fRQ0003&FILIAL='+AllTrim(SC5->C5_FILIAL)+'&NUMPED='+AllTrim(SC5->C5_NUM)+'&rs:Format=pdf" -O "D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\RQ0003a.PDF"' , .t. , "D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\wget\" )
					Else
						WaitRunSrv( '"D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\wget\wget.exe" -t 1 "http://192.168.1.101:10530/ReportServer/Pages/ReportViewer.aspx?%2fItinga_reports%2fRQ0003_P&FILIAL='+AllTrim(SC5->C5_FILIAL)+'&NUMPED='+AllTrim(SC5->C5_NUM)+'&rs:Format=pdf" -O "D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\RQ0003a.PDF"' , .t. , "D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\wget\" )
					EndIf
					
					ConOut("Gerando relat�rio! Ped. Venda:" + AllTrim(SC5->C5_NUM) )
					sleep(300)
					ConOut("Gerando e-mail! Ped. Venda:" + AllTrim(SC5->C5_NUM) )
					
					TCSPExec("SP_SENDMAIL",'ITINGA',"logistica.es@qualitagroup.com;bruno.lage@grupoqualita.com.br",'Pedido Liberado! C�digo:' + SC5->C5_NUM ,'PEDIDO LIBERADO!'+ "<br>" +'C�DIGO:' + SC5->C5_NUM + "<br>" + "MENSAGEM WHATSAPP:"+ Upper(cMessage),'D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\RQ0003a.PDF')
					
					Conout(DtoC(dDatabase)+" - "+TIME()+" E-mail enviado P.Venda:" + TRBRA->WAM_INDEX )	
				EndIf
			Else
					cQuery := " UPDATE WAM010 
					cQuery += "    SET WAM_PERG = 'N',WAM_DATAR='"+ DToS(dDataBase) +"', WAM_HORAR='"+ LEFT(AllTrim(TIME()),5) +"', WAM_RESPOS='"+ Upper(cMessage) +"'"
					cQuery += "  FROM WAM010 
					cQuery += "  WHERE D_E_L_E_T_ <> '*'
					cQuery += "    AND WAM_ID = '"+TRBRA->WAM_ID+"'
					//cQuery += "    AND WAM_TELL = ''
			
					TcSQLExec(cQuery)
					
					TCSPExec("SP_SENDMAIL",'ITINGA',"logistica.es@qualitagroup.com;bruno.lage@grupoqualita.com.br",'Pedido N�O Liberado! C�digo:' + TRBRA->WAM_INDEX , 'PEDIDO N�O LIBERADO!'+ "<br>" + 'C�DIGO:' + TRBRA->WAM_INDEX + "<br>" + "MENSAGEM WHATSAPP:"+ Upper(cMessage),'')
					
					Conout(DtoC(dDatabase)+" - "+TIME()+" E-mail enviado P.Venda (N�O liberado):" + TRBRA->WAM_INDEX )	
			EndIf
		EndIf
	EndIf
	
	// Descarta o objeto 
	FreeObj(oJson)

	dbSelectArea("TRBRA")
	dbSkip()
EndDo

dbSelectArea("TRBRA") 
dbCloseArea()


/*
******************************************************************************************
chamada do Modulo AutoStart
TODOS OS COMANDOS VIA PROCEDUTE
*/
ConOut("*********************************************************************************")
ConOut("*********************************************************************************")
ConOut("*********************         INICIANDO AUTOSTART          **********************")
ConOut("*********************************************************************************")
ConOut("*********************************************************************************")

TCSPEXEC("WHATSAPP_AUTOSTART")
   

/*
******************************************************************************************
Resposta do Modulo MNT
ABERTURA E DISTRIBUI��O
*/
cQuery   := " SELECT  ISNULL((SELECT USR_ID     FROM DADOSADV_Q..SYS_USR WHERE USR_MSBLQL <> 1 AND USR_CARGO = WAM_TELL),'') ID_USUARIO,
cQuery   += " 	  	  ISNULL((SELECT USR_CODIGO FROM DADOSADV_Q..SYS_USR WHERE USR_MSBLQL <> 1 AND USR_CARGO = WAM_TELL),'') USUARIO,
cQuery   += " 	  	  R_E_C_N_O_ RECNO,
cQuery   += " 		  UPPER(RTRIM(LTRIM(SUBSTRING(dbo.FnWhatRetMSG(WAM_ID),IIF(CHARINDEX(',',UPPER(dbo.FnWhatRetMSG(WAM_ID)))=0,0,CHARINDEX(',',UPPER(dbo.FnWhatRetMSG(WAM_ID)))+1),LEN(dbo.FnWhatRetMSG(WAM_ID))  ))) ) 	  MSG,*
cQuery   += "   FROM DADOSADV_Q..WAM010
cQuery   += "  WHERE D_E_L_E_T_ = ''
cQuery   += "    AND WAM_EXEC = 'MNT'
cQuery   += "    AND WAM_PERG = 'N'
cQuery   += "    AND WAM_NIVEL = 0
//cQuery   += "  --AND dbo.FnWhatRetMSG(WAM_ID) <> ''

dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "TRBMNT", .F., .T.)
dbSelectArea("TRBMNT")
dbgotop()
Do While !EOF()

			
			Private	aSolic          :={}	
			Private lMSHelpAuto     := .T. // Nao apresenta erro em tela
			Private lMSErroAuto     := .F. //   Caso a variavel torne-se .T. apos MsExecAuto, apresenta erro em tela
			Private lAutoErrNoFile	:= .T.
			Private cErroTemp       := ""
			Private cArquivo        := ""
			Private cProt           := ""
	
			aSolic := {	{"TQB_CODBEM" , TRBMNT->WAM_RESPOS    	,Nil},;             	// Codigo do Bem a  ser  relacionado na Solicitacao de Servico
						{"TQB_DTABER" , dDataBase     			,Nil},; 		
						{"TQB_HOABER" , LEFT(TIME(), 5 )        ,Nil},; 	
						{"TQB_USUARI" , TRBMNT->USUARIO   		,Nil},; 		
						{"TQB_CDSOLI" , TRBMNT->ID_USUARIO		,Nil},; 		
						{"TQB_DESCSS" , TRBMNT->MSG 			,Nil}} 					//  Descricao da  Solicitacao

			MSExecAuto( {|x,z,y,w| MNTA280(x,z,y,w)}, , , aSolic )		

			If lMsErroAuto
				//U_SWENV("5533984022125" , Mostraerro()  , "ERRO MNT" )
				ConOut("************* ERRO MNT INICIO *************")
				//U_SWENV(TRBMNT->WAM_TELL, "Erro no cadastro da S. Servi�o!"  , "ERRO MNT" )

				//Pegando log do ExecAuto
				aLogAuto := GetAutoGRLog()

				/*
				//Percorrendo o Log e incrementando o texto (para usar o CRLF voc� deve usar a include "Protheus.ch")
				//nAux 		:= 0
				//aLogAuto    :={}
				*/	
				For nAux := 1 To Len(aLogAuto) 
					cErroTemp += aLogAuto[nAux] + CHR(13)+CHR(10)
				Next nAux

				If cErroTemp == ""
					cErroTemp := "Sem informa��es de erro."
				EndIf

				cArquivo := "\_LOGWHATSMNT\" + "MNT_ERRO" + dToS(dDataBase) +'_'+ Replace(time(),':','_') + ".txt"
				
				ConOut(cArquivo)
				ConOut(cErroTemp)

				Sleep(3000)

				//Criando o arquivo txt
				MemoWrite(cArquivo, cErroTemp )

				//cErroTemp := Mostraerro("\_LOGWHATSMNT\", cArquivo)
				
				ConOut(cErroTemp)
				Sleep(3000)

				U_SWENARWAP(AllTrim(TRBMNT->WAM_TELL),"Erro no cadastro da S. Servi�o!","Erro no cadastro da S. Servi�o!","MNT_ERRO","TXT",cArquivo)

				cQuery   := " UPDATE DADOSADV_Q..WAM010
				cQuery   += "    SET WAM_NIVEL = 3
				cQuery   += "   FROM DADOSADV_Q..WAM010  
				cQuery   += "  WHERE D_E_L_E_T_ = ''
				cQuery   += "    AND WAM_EXEC = 'MNT'
				cQuery   += "    AND WAM_PERG = 'N'
				cQuery   += "    AND WAM_NIVEL = 0

				TcSQLExec(cQuery)   

				ConOut("************* ERRO MNT FIM*************")
			Else
			
				dbSelectArea("TQB")
				cCodigoSS := TQB->TQB_SOLICI
				ConOut("************* CONFIRMA��O DA SS MNT INICIO *************")
				ConOut("****Codigo..:"+cCodigoSS)
				ConOut("********************************************************")

				U_SWENV(TRBMNT->WAM_TELL, "Solicita��o cadastrada com sucesso! C�digo:" +cCodigoSS, "SOLICITA��O DE SERVI�O" )

				Sleep(3000)

				/*
				Distriburir 
				Respons�vel pela Manuten��o
				*/
				dbSelectArea("ST9")
				dbSetOrder(1)
				dbSeek(xFilial("ST9") + TRBMNT->WAM_RESPOS)

				cErroTemp := "NOVA SOLICITA��O DE SERVI�O PARA DISTRIBUI��O" + CHR(13)+CHR(10)
				cErroTemp += "C�DIGO........:" + cCodigoSS                   + CHR(13)+CHR(10)
				cErroTemp += "DATA..........:" + dToC(dDataBase)             + CHR(13)+CHR(10)
				cErroTemp += "HORA..........:" + Replace(time(),':',':')     + CHR(13)+CHR(10)
				cErroTemp += "EQUIPAMENTO ID:" + TRBMNT->WAM_RESPOS          + CHR(13)+CHR(10)
				cErroTemp += "EQUIPAMENTO...:" + AllTrim(ST9->T9_NOME)       + CHR(13)+CHR(10)
				cErroTemp += "PROBLEMA......:" + AllTrim(TRBMNT->MSG)        + CHR(13)+CHR(10)
				cErroTemp += "COMO APROVAR..:" + "CIV/MEC/ELE/ , 1/2/3, COMPLEMENTO DA DESCRI��O DO PROBLEMA" 

				cArquivo := "\_LOGWHATSMNT\" + "MNT_DIST" + cCodigoSS + dToS(dDataBase) +'_'+ Replace(time(),':','_') + ".txt"
				MemoWrite(cArquivo, cErroTemp )

				/*
				Telefone fixo com a pessoa que vai distibuir 
				*/ 
				cNumDist := "27981188776"

				cProt := U_SWENARWAP(AllTrim(cNumDist),"Distribuir:" + cCodigoSS,"SS_"+cCodigoSS,"SS_"+cCodigoSS,"TXT",cArquivo)

				If  RecLock("WAM",.T.) 
						Replace WAM_FILIAL  With "" 
						Replace WAM_DATA    With Date()
						Replace WAM_HORA    With Time()
						Replace WAM_ID      With cProt
						Replace WAM_MSG     With cErroTemp
						Replace WAM_INDEX   With cCodigoSS
						Replace WAM_TELL    With cNumDist
						Replace WAM_PERG    With "S"
						Replace WAM_NIVEL   With "0"
						Replace WAM_EXEC    With 'MNT-DIST'
					MsUnLock()
				EndIf

				cQuery   := " UPDATE DADOSADV_Q..WAM010
				cQuery   += "    SET WAM_NIVEL = 1 , WAM_HORAR  = Left(Cast(GETDATE() as Time ),5), WAM_DATAR  = Replace(Cast(GETDATE() as date ),'-',''),WAM_INDEX = '"+AllTrim(cCodigoSS)+"'
				cQuery   += "   FROM DADOSADV_Q..WAM010  
				cQuery   += "  WHERE D_E_L_E_T_ = ''
				cQuery   += "    AND WAM_EXEC = 'MNT'
				cQuery   += "    AND WAM_PERG = 'N'
				cQuery   += "    AND WAM_NIVEL = 0

				TcSQLExec(cQuery)   


				ConOut("************* CONFIRMA��O DA SS MNT FIM *************")
				ConOut("****Codigo..:"+cCodigoSS)
				ConOut("********************************************************")
			Endif	

	dbSelectArea("TRBMNT")
	dbSkip()
EndDo



dbSelectArea("TRBMNT") 
dbCloseArea()

/**
*********************************************************************************
Retorno da DISTRIBUI��O
MNT
*/
Private aRespDist := {}

cQuery   := " SELECT UPPER(dbo.FnWhatRetMSG(WAM_ID)) DIST,
cQuery   += "        CAST(GETDATE() AS DATE)         DATA,
cQuery   += " 	     FORMAT(GETDATE(),'hh:mm')       HORA,
cQuery   += " 	     R_E_C_N_O_         			 RECNO,
cQuery   += " 		 *
cQuery   += "   FROM DADOSADV_Q..WAM010
cQuery   += "  WHERE D_E_L_E_T_ = ''
cQuery   += "    AND WAM_EXEC = 'MNT-DIST'
cQuery   += "    AND WAM_PERG = 'S'
cQuery   += "    AND UPPER(dbo.FnWhatRetMSG(WAM_ID)) <> ''
cQuery   += "    AND CAST(GETDATE()-3 AS DATE) <= CAST(WAM_DATA AS DATE)

dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "TRBMNT", .F., .T.)
dbSelectArea("TRBMNT")
dbgotop()
Do While !EOF()
	
	aRespDist := strtokarr (AllTrim(TRBMNT->DIST), ",")
	
	If Len(aRespDist) < 2
		U_SWENV(TRBMNT->WAM_TELL, "Ditribui��o errada tente novamente! Quantidade de par�metros n�o atende.", "DIST-ERRO1" )
		Sleep(10000)
	Else
		If !aRespDist[1] $ "CIV/MEC/ELE"
			U_SWENV(TRBMNT->WAM_TELL, "O primeiro par�metro deve ser [CIV/MEC/ELE]. ", "DIST-ERRO2" )
			Sleep(10000)
		Else
			If !aRespDist[2] $ "1/2/3"
				U_SWENV(TRBMNT->WAM_TELL, "O Segundo par�metro deve ser [1/2/3]. ", "DIST-ERRO3" )
				Sleep(10000)
			Else
				//U_SWENV(TRBMNT->WAM_TELL, "ok", "DIST-OK" )
				dbSelectArea("TQB")
				dbSetOrder(1)
				dbSeek(xFilial("TQB")+AllTrim(TRBMNT->WAM_INDEX) )
				If  RecLock("TQB",.F.)
					Replace TQB_CDSERV  With aRespDist[1]
					Replace TQB_CDEXEC  With "FELIPE FERREIRA"
					Replace TQB_PRIORI  With aRespDist[2]
					MsUnLock()
				EndIf

				//CONOUT(MSMM(TQB->TQB_CODMSS,80) + CHR(13)+CHR(10) + "DATA.:" + dToC(dDataBase)  + CHR(13)+CHR(10) + "HORA..:" + Replace(time(),':',':') + AllTrim(TRBMNT->DIST),80)
				MSMM(,,, MSMM(TQB->TQB_CODMSS,80) + CHR(13)+CHR(10) + "DATA.:" + dToC(dDataBase)  + CHR(13)+CHR(10) + "HORA..:" + Replace(time(),':',':') + CHR(13)+CHR(10) + AllTrim(TRBMNT->DIST),1,,,"TQB","TQB_CODMSS")
				
				cQuery   := " UPDATE DADOSADV_Q..WAM010
				cQuery   += "    SET WAM_PERG = 'N',WAM_HORAR  = Left(Cast(GETDATE() as Time ),5), WAM_DATAR  = Replace(Cast(GETDATE() as date ),'-','')
				cQuery   += "   FROM DADOSADV_Q..WAM010
				cQuery   += "  WHERE R_E_C_N_O_ = "+ AllTrim(Str(TRBMNT->RECNO))

				CONOUT(cQuery)

				TcSQLExec(cQuery) 

				U_SWENV(TRBMNT->WAM_TELL, "SS classificada com sucesso! C�digo:"+AllTrim(TRBMNT->WAM_INDEX) , "DIST-SUCESSO" )
				U_SWENV("27998282193"   , "SS classificada com sucesso! C�digo:"+AllTrim(TRBMNT->WAM_INDEX) , "DIST-SUCESSO" )
				//Sleep(10000)
			EndIf
		EndIf
	EndIf 

	dbSelectArea("TRBMNT")
	dbSkip()
EndDo

dbSelectArea("TRBMNT") 
dbCloseArea()



/*
Verifica��o de erro 
CAVALETES DIFRENTE DO PEDIDO DE VENDA
*/
cQuery   := " SELECT C6_NUM ,C6_ITEM,B8_PRODUTO,B8_LOTECTL,C6_NUMLOTE,C6_YCAVALE,B8_YCAVALE,C6_QTDVEN , B8_SALDO
cQuery   += "   FROM SC6010 SC6 INNER JOIN SB8010 SB8
cQuery   += "     ON (B8_PRODUTO = C6_PRODUTO AND B8_LOTECTL = C6_LOTECTL AND C6_NUMLOTE = B8_NUMLOTE)
cQuery   += " WHERE SC6.D_E_L_E_T_ = ''
cQuery   += " AND SB8.D_E_L_E_T_ = ''
cQuery   += " AND SC6.C6_NOTA = ''
cQuery   += " AND SB8.B8_ORIGLAN = 'BD'
cQuery   += " AND B8_LOCAL = C6_LOCAL
cQuery   += " AND C6_QTDVEN <> B8_SALDO
cQuery   += " ORDER BY B8_YCAVALE,C6_NUM,C6_ITEM
   
dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "TRBERRO", .F., .T.)
dbSelectArea("TRBERRO")
dbgotop()
Do While !EOF()

	/*
	AVISO PARA BRUNO
	*/
	U_SWENV("5533984022125", "ERRO URGENTE (DIF. DE SALDO) PEDIDO:" + AllTrim(TRBERRO->C6_NUM)   + " CAVALETE:" + TRBERRO->B8_YCAVALE  , "ERRO:" +AllTrim(TRBERRO->B8_YCAVALE)  )
	
	sleep(300)
	
	/*
	AVISO PARA ARLINDO
	*/
	U_SWENV("5527999999365", "ERRO URGENTE (DIF. DE SALDO) PEDIDO:" + AllTrim(TRBERRO->C6_NUM)   + " CAVALETE:" + TRBERRO->B8_YCAVALE  , "ERRO:" +AllTrim(TRBERRO->B8_YCAVALE)  )
	
	sleep(300)
	
	/*
	EMAIL
	*/
	TCSPExec("SP_SENDMAIL",'ITINGA',"logistica.es@qualitagroup.com;comercial.es@grupoqualita.com.br",'ERRO URGENTE ! PV:' + TRBERRO->C6_NUM , "ERRO URGENTE (DIF. DE SALDO) PEDIDO:" + AllTrim(TRBERRO->C6_NUM)   + " CAVALETE:" + TRBERRO->B8_YCAVALE ,'')

	dbSelectArea("TRBERRO")
	dbSkip()
EndDo

dbSelectArea("TRBERRO") 
dbCloseArea()

/*
Caso exista alguma aprova��o ou reprova��o 
o sistema envia o protocolo por e-mail
*/
IF lEnvProt
	//WaitRunSrv( '"D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\wget\wget.exe" -t 1 "http://192.168.1.101:10530/ReportServer/Pages/ReportViewer.aspx?%2fItinga_reports%2fRQ0060&rs:Format=pdf" -O "D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\RQ0060.PDF"' , .t. , "D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\wget\" )
	  
	//ConOut("Gerando protocolo..." )
	//Sleep(3000)
	//TCSPExec("SP_SENDMAIL",'ITINGA',"diego.sirtori@grupoqualita.com.br",'Rela�rio de Protocolo','Anexo relat�rio de protocolos!','D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\RQ0060.PDF')
EndIf

If lAutoZAP
	RpcClearEnv()
	Conout(DtoC(dDatabase)+" - "+TIME()+" FIM do JOB libera��o de Retornos pelo WHATSAPP.")
Else
	// Caso n�o seja job, informa na a atualiza��o
	Alert("Fim da libera��o de Retorno pelo WHATSAPP. (Chamada Manual)")
Endif

Return
