#include "protheus.ch"
#include "rwmake.ch"
#include "tbiconn.ch"  
#INCLUDE "TOTVS.CH"
#INCLUDE "topconn.ch"

/*
Programa ...: LIBWHATSAPP.Prw
Uso ........: Programa verifica a provação do pedido automaticamente pelo WhatsApp
Data .......: 23/03/2020
Feito por ..: Bruno Lage Ferreira
Copyright @1998-2001,2021

Q-Liberação Faturamento
5527995295180-1587589430@g.us
logistica.es@qualitagroup.com;comercial.es@grupoqualita.com.br

Q-N2 - Liberação Compras
5527995295180-1594316108@g.us
pedido.compra@grupoqualita.com.br

Q-N1 - Liberação Compras
5527995295180-1587589523@g.us
pedido.compra@grupoqualita.com.br
*/ 

User Function LIBWHATSAPP()  
************************************************************************************************************
*
*
*
***
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

ConOut( ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>   WHATSAPP APROVAÇÃO   <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<" )

If Select("SX2")==0  
	PREPARE ENVIRONMENT EMPRESA "01" FILIAL "01" TABLES "WAM","SC5"
	Conout(DtoC(dDatabase)+" - "+TIME()+" Iniciando JOB de liberação de Retorno pelo WHATSAPP.")
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
		
		sleep(400)
		
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
	Tratamento das liberação 
	 - Mapa de Cotação
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
			Processamento dos retorno Mapa de cotação-MC
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
						
						
						ConOut("Gerando relatório! Mapa de Cotação:" + AllTrim(SC8->C8_NUM) )
						sleep(300)
						ConOut("Gerando e-mail! Mapa de Cotação:" + AllTrim(SC8->C8_NUM) )
						
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
						Marcando o protocolo como já lido. 
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
						Marcando o protocolo como já lido
						*/
						cQuery := " UPDATE WAM010 
						cQuery += "    SET WAM_PERG = 'N',WAM_DATAR='"+ DToS(dDataBase) +"', WAM_HORAR='"+ LEFT(AllTrim(TIME()),5) +"', WAM_RESPOS='"+ Upper(cMessage) +"'"
						cQuery += "  FROM WAM010 
						cQuery += "  WHERE D_E_L_E_T_ <> '*'
						cQuery += "    AND WAM_ID = '"+TRBRA->WAM_ID+"'
						cQuery += "    AND WAM_NIVEL = '1'
				
						TcSQLExec(cQuery)
						
						/*
						Coloca a MSg mais não mostra data nem hora de liberação
						*/
						cQuery := " UPDATE " + RetSqlName("SC8")  
						cQuery += "    SET C8_MSGLIB='"+ "NÃO LIBERADO: " + Upper(cMessage) +"'"
						cQuery += "   FROM " + RetSqlName("SC8")
						cQuery += "  WHERE D_E_L_E_T_ <> '*'
						cQuery += "    AND C8_NUM = '"+SC8->C8_NUM+"'
						
						
						TcSQLExec(cQuery)
										
						TCSPExec("SP_SENDMAIL",'ITINGA',"pedido.compra@grupoqualita.com.br",'Mapa de Cotação NÃO Liberado! Código:' + TRBRA->WAM_INDEX , 'COTAÇÃO NÃO LIBERADA!'+ "<br>" + 'CÓDIGO:' + TRBRA->WAM_INDEX + "<br>" + "MENSAGEM WHATSAPP:"+ Upper(cMessage),'')
						
						Conout(DtoC(dDatabase)+" - "+TIME()+" E-mail enviado (Mapa de Cotação NÃO liberado):" + TRBRA->WAM_INDEX )	
					
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
			Processamento dos retorno Mapa de cotação-MC
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
						Gravando aprovação na SC8
						*/
						cQuery := " UPDATE " + RetSqlName("SC8")  
						cQuery += "    SET C8_DATALIB='"+ DToS(dDataBase) +"',C8_HORALIB='"+ LEFT(AllTrim(TIME()),5) +"',C8_MSGLIB='"+ Upper(cMessage) +"'"
						cQuery += "  FROM " + RetSqlName("SC8")
						cQuery += "  WHERE D_E_L_E_T_ <> '*'
						cQuery += "    AND C8_NUM = '"+SC8->C8_NUM+"'
						
						TcSQLExec(cQuery)
					
						WaitRunSrv( '"D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\wget\wget.exe" -t 1 "http://192.168.1.101:10530/ReportServer/Pages/ReportViewer.aspx?%2fItinga_reports%2fRQ0025_V&cCotacao=' + SC8->C8_NUM +'&rs:Format=pdf" -O "D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\MC-'+ SC8->C8_NUM +'.PDF"' , .t. , "D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\wget\" )
						
						ConOut("Gerando relatório! Mapa de Cotação:" + AllTrim(SC8->C8_NUM) )
						sleep(300)
						ConOut("Gerando e-mail! Mapa de Cotação:" + AllTrim(SC8->C8_NUM) )
						
						TCSPExec("SP_SENDMAIL",'ITINGA',"pedido.compra@grupoqualita.com.br",'Mapa de Cotação Liberado!     Código:' + SC8->C8_NUM       ,'COTAÇÃO LIBERADA! Código:'              + SC8->C8_NUM + ', liberado!'+ "<br>" +'CÓDIGO:' + SC8->C8_NUM + "<br>" + "MENSAGEM WHATSAPP:"+ Upper(cMessage),'D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\MC-'+ SC8->C8_NUM +'.PDF')
						
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
						Coloca a MSg mais não mostra data nem hora de liberação
						*/
						cQuery := " UPDATE " + RetSqlName("SC8")  
						cQuery += "    SET C8_MSGLIB='"+ "NÃO LIBERADO: " + Upper(cMessage) +"'"
						cQuery += "   FROM " + RetSqlName("SC8")
						cQuery += "  WHERE D_E_L_E_T_ <> '*'
						cQuery += "    AND C8_NUM = '"+SC8->C8_NUM+"'
						
						TcSQLExec(cQuery)
										
						TCSPExec("SP_SENDMAIL",'ITINGA',"pedido.compra@grupoqualita.com.br",'Mapa de Cotação NÃO Liberado! Código:' + TRBRA->WAM_INDEX , 'COTAÇÃO NÃO LIBERADA!'+ "<br>" + 'CÓDIGO:' + TRBRA->WAM_INDEX + "<br>" + "MENSAGEM WHATSAPP:"+ Upper(cMessage),'')
						
						Conout(DtoC(dDatabase)+" - "+TIME()+" E-mail enviado (Mapa de Cotação NÃO liberado):" + TRBRA->WAM_INDEX )	
					
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
						Gravando aprovação na SC7
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
						
						//ConOut("Gerando relatório! Pedido de Compras:" + AllTrim(SC7->C7_NUM) )
						sleep(300)
						ConOut("Gerando e-mail! Ped. Compras:" + AllTrim(SC7->C7_NUM) )
						
						
						//TCSPExec("SP_SENDMAIL",'ITINGA',"almoxarifado@grupoqualita.com.br;emelly.couto@grupoqualita.com.br;bruno.lage@grupoqualita.com.br",'Pedido NÃO Liberado! Código:' + SC7->C7_NUM + ', não liberado!'+ "<br>" +'CÓDIGO:' + SC7->C7_NUM + "<br>" + "MENSAGEM WHATSAPP:"+ Upper(cMessage),'D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\RXX0022.PDF')
						TCSPExec("SP_SENDMAIL",'ITINGA','pedido.compra@grupoqualita.com.br', 'Pedido Não Liberado! Código:' + SC7->C7_NUM , 'Pedido Não Liberado' + '<br>' +'CÓDIGO:' + SC7->C7_NUM +  "<br>" + "MENSAGEM WHATSAPP:"+ Upper(cMessage)     ,'')
						
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
						Gravando aprovação na SC7
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
						
						ConOut("Gerando relatório! Pedido de Compras:" + AllTrim(SC7->C7_NUM) )
						sleep(300)
						ConOut("Gerando e-mail! Ped. Compras:" + AllTrim(SC7->C7_NUM) )
						
						TCSPExec("SP_SENDMAIL",'ITINGA','pedido.compra@grupoqualita.com.br', 'Pedido Liberado! Código:' + SC7->C7_NUM , 'Pedido Liberado' + '<br>' +'CÓDIGO:' + SC7->C7_NUM +  "<br>" + "MENSAGEM WHATSAPP:"+ Upper(cMessage)     ,'D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\PC-'+SC7->C7_NUM+'.PDF')
	
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
						Gravando aprovação na SC7
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
						
						//ConOut("Gerando relatório! Pedido de Compras:" + AllTrim(SC7->C7_NUM) )
						sleep(300)
						ConOut("Gerando e-mail! Ped. Compras:" + AllTrim(SC7->C7_NUM) )
						
						
						//TCSPExec("SP_SENDMAIL",'ITINGA',"almoxarifado@grupoqualita.com.br;emelly.couto@grupoqualita.com.br;bruno.lage@grupoqualita.com.br",'Pedido NÃO Liberado! Código:' + SC7->C7_NUM + ', não liberado!'+ "<br>" +'CÓDIGO:' + SC7->C7_NUM + "<br>" + "MENSAGEM WHATSAPP:"+ Upper(cMessage),'D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\RXX0022.PDF')
						TCSPExec("SP_SENDMAIL",'ITINGA','pedido.compra@grupoqualita.com.br', 'Pedido Não Liberado! Código:' + SC7->C7_NUM , 'Pedido Não Liberado' + '<br>' +'CÓDIGO:' + SC7->C7_NUM +  "<br>" + "MENSAGEM WHATSAPP:"+ Upper(cMessage)     ,'')
						
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
					
					ConOut("Gerando relatório! Ped. Venda:" + AllTrim(SC5->C5_NUM) )
					sleep(300)
					ConOut("Gerando e-mail! Ped. Venda:" + AllTrim(SC5->C5_NUM) )
					
					TCSPExec("SP_SENDMAIL",'ITINGA',"logistica.es@qualitagroup.com;bruno.lage@grupoqualita.com.br",'Pedido Liberado! Código:' + SC5->C5_NUM ,'PEDIDO LIBERADO!'+ "<br>" +'CÓDIGO:' + SC5->C5_NUM + "<br>" + "MENSAGEM WHATSAPP:"+ Upper(cMessage),'D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\RQ0003a.PDF')
					
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
					
					TCSPExec("SP_SENDMAIL",'ITINGA',"logistica.es@qualitagroup.com;bruno.lage@grupoqualita.com.br",'Pedido NÃO Liberado! Código:' + TRBRA->WAM_INDEX , 'PEDIDO NÃO LIBERADO!'+ "<br>" + 'CÓDIGO:' + TRBRA->WAM_INDEX + "<br>" + "MENSAGEM WHATSAPP:"+ Upper(cMessage),'')
					
					Conout(DtoC(dDatabase)+" - "+TIME()+" E-mail enviado P.Venda (NÃO liberado):" + TRBRA->WAM_INDEX )	
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
ABERTURA E DISTRIBUIÇÃO
*/
cQuery   := " SELECT  ISNULL((SELECT USR_ID     FROM DADOSADV_Q..SYS_USR WHERE USR_MSBLQL <> 1 AND USR_CARGO = WAM_TELL),'') ID_USUARIO,
cQuery   += " 	  	  ISNULL((SELECT USR_CODIGO FROM DADOSADV_Q..SYS_USR WHERE USR_MSBLQL <> 1 AND USR_CARGO = WAM_TELL),'') USUARIO,
cQuery   += " 	  	  R_E_C_N_O_ RECNO,
cQuery   += " 		  UPPER(RTRIM(LTRIM(SUBSTRING(RETORNO,IIF(CHARINDEX(',',UPPER(RETORNO))=0,0,CHARINDEX(',',UPPER(RETORNO))+1),LEN(RETORNO)  ))) ) 	  MSG,*
cQuery   += "   FROM DADOSADV_Q..WAM010
cQuery   += "	CROSS APPLY
cQuery   += "	(
cQuery   += "	SELECT RETORNO = dbo.FnWhatRetMSG(WAM_ID)
cQuery   += "	) x
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
				//U_SWENV(TRBMNT->WAM_TELL, "Erro no cadastro da S. Serviço!"  , "ERRO MNT" )

				//Pegando log do ExecAuto
				aLogAuto := GetAutoGRLog()

				/*
				//Percorrendo o Log e incrementando o texto (para usar o CRLF você deve usar a include "Protheus.ch")
				//nAux 		:= 0
				//aLogAuto    :={}
				*/	
				For nAux := 1 To Len(aLogAuto) 
					cErroTemp += aLogAuto[nAux] + CHR(13)+CHR(10)
				Next nAux

				If cErroTemp == ""
					cErroTemp := "Sem informações de erro."
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

				U_SWENARWAP(AllTrim(TRBMNT->WAM_TELL),"Erro no cadastro da S. Serviço!","Erro no cadastro da S. Serviço!","MNT_ERRO","TXT",cArquivo)

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
				ConOut("************* CONFIRMAÇÃO DA SS MNT INICIO *************")
				ConOut("****Codigo..:"+cCodigoSS)
				ConOut("********************************************************")

				U_SWENV(TRBMNT->WAM_TELL, "Solicitação cadastrada com sucesso! Código:" +cCodigoSS, "SOLICITAÇÃO DE SERVIÇO" )

				Sleep(3000)

				/*
				Distriburir 
				Responsável pela Manutenção
				*/
				dbSelectArea("ST9")
				dbSetOrder(1)
				dbSeek(xFilial("ST9") + TRBMNT->WAM_RESPOS)

				cErroTemp := "NOVA SOLICITAÇÃO DE SERVIÇO PARA DISTRIBUIÇÃO" + CHR(13)+CHR(10)
				cErroTemp += "CÓDIGO........:" + cCodigoSS                   + CHR(13)+CHR(10)
				cErroTemp += "DATA..........:" + dToC(dDataBase)             + CHR(13)+CHR(10)
				cErroTemp += "HORA..........:" + Replace(time(),':',':')     + CHR(13)+CHR(10)
				cErroTemp += "EQUIPAMENTO ID:" + TRBMNT->WAM_RESPOS          + CHR(13)+CHR(10)
				cErroTemp += "EQUIPAMENTO...:" + AllTrim(ST9->T9_NOME)       + CHR(13)+CHR(10)
				cErroTemp += "PROBLEMA......:" + AllTrim(TRBMNT->MSG)        + CHR(13)+CHR(10)
				cErroTemp += "COMO APROVAR..:" + "CIV/MEC/ELE/ , 1/2/3, COMPLEMENTO DA DESCRIÇÃO DO PROBLEMA" 

				cArquivo := "\_LOGWHATSMNT\" + "MNT_DIST" + cCodigoSS + dToS(dDataBase) +'_'+ Replace(time(),':','_') + ".txt"
				MemoWrite(cArquivo, cErroTemp )

				/*
				Telefone fixo com a pessoa que vai distibuir 
				*/ 
				cNumDist := "27997857938"
				                

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


				ConOut("************* CONFIRMAÇÃO DA SS MNT FIM *************")
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
Retorno da DISTRIBUIÇÃO
MNT
*/
Private aRespDist := {}

cQuery   := " SELECT UPPER(RETORNO) DIST,
cQuery   += "        CAST(GETDATE() AS DATE)         DATA,
cQuery   += " 	     FORMAT(GETDATE(),'hh:mm')       HORA,
cQuery   += " 	     R_E_C_N_O_         			 RECNO,
cQuery   += " 		 *
cQuery   += "   FROM DADOSADV_Q..WAM010
cQuery   += "	CROSS APPLY
cQuery   += "	(
cQuery   += "	SELECT RETORNO = dbo.FnWhatRetMSG(WAM_ID)
cQuery   += "	) x
cQuery   += "  WHERE D_E_L_E_T_ = ''
cQuery   += "    AND WAM_EXEC = 'MNT-DIST'
cQuery   += "    AND WAM_PERG = 'S'
cQuery   += "    AND UPPER(RETORNO) <> ''
cQuery   += "    AND CAST(GETDATE()-3 AS DATE) <= CAST(WAM_DATA AS DATE)

dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "TRBMNT", .F., .T.)
dbSelectArea("TRBMNT")
dbgotop()
Do While !EOF()
	
	aRespDist := strtokarr (AllTrim(TRBMNT->DIST), ",")
	
	If Len(aRespDist) < 2
		U_SWENV(TRBMNT->WAM_TELL, "Ditribuição errada tente novamente! Quantidade de parâmetros não atende.", "DIST-ERRO1" )
		Sleep(10000)
	Else
		If !aRespDist[1] $ "CIV/MEC/ELE"
			U_SWENV(TRBMNT->WAM_TELL, "O primeiro parâmetro deve ser [CIV/MEC/ELE]. ", "DIST-ERRO2" )
			Sleep(10000)
		Else
			If !aRespDist[2] $ "1/2/3"
				U_SWENV(TRBMNT->WAM_TELL, "O Segundo parâmetro deve ser [1/2/3]. ", "DIST-ERRO3" )
				Sleep(10000)
			Else
				//U_SWENV(TRBMNT->WAM_TELL, "ok", "DIST-OK" )
				dbSelectArea("TQB")
				dbSetOrder(1)
				dbSeek(xFilial("TQB") + AllTrim(TRBMNT->WAM_INDEX) )
				If  RecLock("TQB",.F.)
					Replace TQB_CDSERV  With aRespDist[1]
					Replace TQB_CDEXEC  With "LUAN SANTOS"
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

				U_SWENV(TRBMNT->WAM_TELL, "SS classificada com sucesso! Código:"+AllTrim(TRBMNT->WAM_INDEX) , "DIST-SUCESSO" )
				U_SWENV("27998282193"   , "SS classificada com sucesso! Código:"+AllTrim(TRBMNT->WAM_INDEX) , "DIST-SUCESSO" )
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
Verificação de erro 
CAVALETES DIFRENTE DO PEDIDO DE VENDA
*/
cQuery   := " SELECT 	'P' TIPO,
cQuery   += " 			C6_NUM,
cQuery   += " 			B8_YCAVALE
cQuery   += "   FROM (
cQuery   += "          SELECT C6_NUM ,C6_ITEM,B8_PRODUTO,B8_LOTECTL,C6_NUMLOTE,C6_YCAVALE,B8_YCAVALE,ROUND(C6_QTDVEN,4,0) C6_QTDVEN , ROUND(B8_SALDO,4,0) B8_SALDO,
cQuery   += "                         ( SELECT 
cQuery   += "                             ROUND(SUM(SB.B8_YTOTLIQ),4,0) 
cQuery   += "                                 FROM SB8010 SB 
cQuery   += "                             WHERE   SB.D_E_L_E_T_='' 
cQuery   += "                                 AND SB.B8_PRODUTO = SC6.C6_PRODUTO 
cQuery   += "                                 AND SC6.C6_LOTECTL = RTRIM(LTRIM(SB.B8_LOTECTL))+RTRIM(LTRIM(SB.B8_YCLASSI)) 
cQuery   += "                                 AND SC6.C6_NUMLOTE<>SB.B8_NUMLOTE 
cQuery   += "                                 AND SC6.C6_NUMLOTE=SB.B8_YCAVALE
cQuery   += "                          ) SALDO_CHAPA
cQuery   += "                FROM SC6010 SC6 INNER JOIN SB8010 SB8
cQuery   += "                  ON (B8_PRODUTO = C6_PRODUTO AND B8_LOTECTL = C6_LOTECTL AND C6_NUMLOTE = B8_NUMLOTE)
cQuery   += "              WHERE SC6.D_E_L_E_T_ = ''
cQuery   += "                AND SB8.D_E_L_E_T_ = ''
cQuery   += "                AND SC6.C6_NOTA = ''
cQuery   += "                AND SB8.B8_ORIGLAN = 'BD'
cQuery   += "                AND B8_LOCAL = C6_LOCAL
cQuery   += "          ) TB
cQuery   += " WHERE
cQuery   += "      (TB.C6_QTDVEN <> TB.B8_SALDO 
cQuery   += "      OR 
cQuery   += "      TB.SALDO_CHAPA<>TB.C6_QTDVEN)

cQuery   += "  UNION ALL

cQuery   += " SELECT 	'E' TIPO,
cQuery   += " 			'' C6_NUM,
cQuery   += " 			IIF(B8_YCAVALE='', B8_NUMLOTE,B8_YCAVALE) B8_YCAVALE 
cQuery   += "     FROM (
cQuery   += "             SELECT 
cQuery   += "                 ISNULL(( SELECT 
cQuery   += "                     ROUND(SUM(SB.B8_YTOTLIQ),4,0) 
cQuery   += "                         FROM SB8010 SB 
cQuery   += "                     WHERE   SB.D_E_L_E_T_='' 
cQuery   += "                         AND SB.B8_PRODUTO = SB8.B8_PRODUTO 
cQuery   += "                         AND SB8.B8_LOTECTL = RTRIM(LTRIM(SB.B8_LOTECTL))+RTRIM(LTRIM(SB.B8_YCLASSI)) 
cQuery   += "                         AND SB8.B8_NUMLOTE<>SB.B8_NUMLOTE 
cQuery   += "                         AND SB8.B8_NUMLOTE=SB.B8_YCAVALE
cQuery   += "                  ),0) SALDO_CHAPA,
cQuery   += "                  ROUND(SB8.B8_SALDO,4,0) SALDO_BUNDLE,
cQuery   += "                  * 
cQuery   += "             FROM SB8010 SB8 
cQuery   += "                     WHERE SB8.B8_FILIAL='010101' 
//cQuery   += "                     AND CAST(SB8.B8_NUMLOTE AS INT) BETWEEN 100 AND 999999 
cQuery   += "                       AND SB8.B8_NUMLOTE = SB8.B8_YCAVALE
cQuery   += "  					    AND SB8.B8_YCAVALE <> ''
cQuery   += "                       AND SB8.B8_SALDO>0 
cQuery   += "                       AND SB8.D_E_L_E_T_=''
cQuery   += "         )TB
cQuery   += "     WHERE SALDO_BUNDLE<>SALDO_CHAPA

cQuery   += "  UNION ALL 

cQuery   += "  SELECT 'F' TIPO,
cQuery   += "  	   D2_NUMLOTE B8_YCAVALE,
cQuery   += "  	   CHAVE_DOC C6_NUM
cQuery   += "    FROM (
cQuery   += "  		SELECT *,
cQuery   += "  			   (SELECT ROUND(SUM(B8_YQTDBD),5,0) FROM SB8010  WHERE D_E_L_E_T_ = '' AND D2_COD = B8_PRODUTO AND (RTRIM(LTRIM(B8_LOTECTL))+LTRIM(RTRIM(B8_YCLASSI)))=D2_LOTECTL  AND D2_NUMLOTE = B8_YCAVALE AND D2_FILIAL = B8_FILIAL  AND D2_NUMLOTE <> B8_NUMLOTE) QTD_SB8_ORI
cQuery   += "  		  FROM (
cQuery   += "  				SELECT  D2_FILIAL+D2_DOC+D2_SERIE CHAVE_DOC,
cQuery   += "  						CAST(D2_EMISSAO AS DATE) EMISSAO,
cQuery   += "  						D2_COD,
cQuery   += "  						D2_NUMLOTE ,
cQuery   += "  						D2_LOTECTL,						
cQuery   += "  						D2_FILIAL,
cQuery   += "  						ROUND(SUM(D2_QUANT),5,0) QTD_FAT
cQuery   += "  					FROM SD2010 
cQuery   += "  					WHERE D_E_L_E_T_ = '' 
cQuery   += "  					  AND D2_COD LIKE 'CH%'
cQuery   += "  					  AND D2_QTDEDEV = 0
cQuery   += "  				GROUP BY D2_FILIAL+D2_DOC+D2_SERIE,
cQuery   += "  							D2_NUMLOTE,
cQuery   += "  							D2_LOTECTL,
cQuery   += "  							D2_PEDIDO,
cQuery   += "  							D2_ITEMPV,
cQuery   += "  							D2_FILIAL,
cQuery   += "  							CAST(D2_EMISSAO AS DATE),
cQuery   += "  							D2_COD
cQuery   += "  				)TAB_BASE
cQuery   += "  		)TAB_2
cQuery   += "  WHERE  ROUND(QTD_FAT,0,0) <> ROUND(QTD_SB8_ORI,0,0)
cQuery   += "    AND CHAVE_DOC NOT IN (
cQuery   += "  						'0101010000064491',  
cQuery   += "  						'0101010000067471',  
cQuery   += "  						'0101010000070511',
cQuery   += "  						'0101010000071041',  
cQuery   += "  						'0101010000072551',  
cQuery   += "  						'0101010000077821',  
cQuery   += "  						'0101010000077821',  
cQuery   += "  						'0101010000083191',  
cQuery   += "  						'0101010000085411'  
cQuery   += "  						)

cQuery   += "  ORDER BY B8_YCAVALE,C6_NUM


/*
QUERY USADA PARA ACHAR OS VALORES SB8 <> DO FATURADO

SELECT 'F' TIPO,
	   D2_NUMLOTE B8_YCAVALE,
	   CHAVE_DOC C6_NUM
	   , *
	   ,'http://192.168.1.101:10530/ReportServer/Pages/ReportViewer.aspx?%2fItinga_reports%2fRQ0003&FILIAL='+D2_FILIAL+'&NUMPED='+D2_PEDIDO+'&rs:Format=pdf' as LINK
  FROM (
		SELECT *,
			   (SELECT RTRIM(LTRIM(B1_DESC))  FROM SB1010 WHERE D_E_L_E_T_ = ''  AND B1_COD = D2_COD) DESCRICAO,
			   (SELECT C6_PRCVEN  FROM SC6010 WHERE D_E_L_E_T_ = '' AND C6_NUM = D2_PEDIDO AND C6_ITEM = D2_ITEMPV AND D2_FILIAL = C6_FILIAL AND C6_LOTECTL = D2_LOTECTL) PRC_VEN,
			   (SELECT C6_QTDVEN  FROM SC6010 WHERE D_E_L_E_T_ = '' AND C6_NUM = D2_PEDIDO AND C6_ITEM = D2_ITEMPV AND D2_FILIAL = C6_FILIAL AND C6_LOTECTL = D2_LOTECTL) QTD_PV_NOR,
			   (SELECT ROUND(C6_QTDVEN,0,0)  FROM SC6010 WHERE D_E_L_E_T_ = '' AND C6_NUM = D2_PEDIDO AND C6_ITEM = D2_ITEMPV AND D2_FILIAL = C6_FILIAL AND C6_LOTECTL = D2_LOTECTL) QTD_PV,
			   (SELECT C6_YCLASSI  FROM SC6010 WHERE D_E_L_E_T_ = '' AND C6_NUM = D2_PEDIDO AND C6_ITEM = D2_ITEMPV AND D2_FILIAL = C6_FILIAL AND C6_LOTECTL = D2_LOTECTL) CLASSIF,
			   (SELECT C6_YCAVALE FROM SC6010 WHERE D_E_L_E_T_ = '' AND C6_NUM = D2_PEDIDO AND C6_ITEM = D2_ITEMPV AND D2_FILIAL = C6_FILIAL AND C6_LOTECTL = D2_LOTECTL) CAVALETE,
			   (SELECT SUM(B8_YQTDBD) FROM SB8010  WHERE D_E_L_E_T_ = '' AND D2_COD = B8_PRODUTO AND (RTRIM(LTRIM(B8_LOTECTL))+LTRIM(RTRIM(B8_YCLASSI)))=D2_LOTECTL  AND D2_NUMLOTE = B8_YCAVALE AND D2_FILIAL = B8_FILIAL  AND D2_NUMLOTE <> B8_NUMLOTE) QTD_SB8_ORI_NOR,
			   (SELECT ROUND(SUM(B8_YQTDBD),0,0) FROM SB8010  WHERE D_E_L_E_T_ = '' AND D2_COD = B8_PRODUTO AND (RTRIM(LTRIM(B8_LOTECTL))+LTRIM(RTRIM(B8_YCLASSI)))=D2_LOTECTL  AND D2_NUMLOTE = B8_YCAVALE AND D2_FILIAL = B8_FILIAL  AND D2_NUMLOTE <> B8_NUMLOTE) QTD_SB8_ORI
		  FROM (
				SELECT  D2_FILIAL+D2_DOC+D2_SERIE CHAVE_DOC,
						CAST(D2_EMISSAO AS DATE) EMISSAO,
						D2_COD,
						D2_NUMLOTE ,
						D2_LOTECTL,						
						D2_PEDIDO,
						D2_ITEMPV,
						D2_FILIAL,
						ROUND(SUM(D2_QUANT),0,0) QTD_FAT
					FROM SD2010 
					WHERE D_E_L_E_T_ = '' 
					 -- AND D2_DOC = '000009057' 
					  AND D2_COD LIKE 'CH%'
				GROUP BY D2_FILIAL+D2_DOC+D2_SERIE,
							D2_NUMLOTE,
							D2_LOTECTL,
							D2_PEDIDO,
							D2_ITEMPV,
							D2_FILIAL,
							CAST(D2_EMISSAO AS DATE),
							D2_COD
				)TAB_BASE
		)TAB_2
WHERE  ROUND(QTD_FAT,0,0) <> ROUND(QTD_SB8_ORI,0,0)
  AND CHAVE_DOC NOT IN (
						'0101010000064491',  
						'0101010000067471',  
						'0101010000070511',
						'0101010000071041',  
						'0101010000072551',  
						'0101010000077821',  
						'0101010000077821',  
						'0101010000083191',  
						'0101010000085411'  
						)
ORDER BY EMISSAO, CHAVE_DOC

*/

dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "TRBERRO", .F., .T.)
dbSelectArea("TRBERRO")
dbgotop()
Do While !EOF()

	IF TRBERRO->TIPO == 'P'
		/*
		AVISO PARA BRUNO
		*/
		U_SWENV("5533984022125", "ERRO URGENTE (DIF. DE SALDO) PEDIDO:" + AllTrim(TRBERRO->C6_NUM)   + " CAVALETE:" + TRBERRO->B8_YCAVALE  , "ERRO:" +AllTrim(TRBERRO->B8_YCAVALE)  )
		
		sleep(300)
		
		/*
		AVISO PARA ARLINDO
		*/
		U_SWENV("5527981187553", "ERRO URGENTE (DIF. DE SALDO) PEDIDO:" + AllTrim(TRBERRO->C6_NUM)   + " CAVALETE:" + TRBERRO->B8_YCAVALE  , "ERRO:" +AllTrim(TRBERRO->B8_YCAVALE)  )
		
		sleep(300)
		
		/*
		EMAIL
		*/
		TCSPExec("SP_SENDMAIL",'ITINGA',"ti.vix@grupoqualita.com.br;logistica.es@qualitagroup.com;sales.es@qualitagroup.com",'ERRO URGENTE ! PV:' + TRBERRO->C6_NUM , "ERRO URGENTE (DIF. DE SALDO) PEDIDO:" + AllTrim(TRBERRO->C6_NUM)   + " CAVALETE:" + TRBERRO->B8_YCAVALE ,'')
	ENDIF

	IF TRBERRO->TIPO == 'E'
		/*
		AVISO PARA BRUNO
		*/
		U_SWENV("5533984022125", "ERRO URGENTE (DIF. DE SALDO) CAVALETE -  BUNDLE:" + AllTrim(TRBERRO->B8_YCAVALE)    )
		
		sleep(300)
		
		/*
		AVISO PARA ARLINDO
		*/
		U_SWENV("5527981187553", "ERRO URGENTE (DIF. DE SALDO) CAVALETE - BUNDLE:" + AllTrim(TRBERRO->B8_YCAVALE)     )
		
		sleep(300)
		
		/*
		EMAIL
		*/
		TCSPExec("SP_SENDMAIL",'ITINGA',"ti.vix@grupoqualita.com.br;logistica.es@qualitagroup.com;sales.es@qualitagroup.com","ERRO URGENTE (DIF. DE SALDO)","ERRO URGENTE ! CAVALETE:" + TRBERRO->B8_YCAVALE ,'')
	ENDIF

	
	IF TRBERRO->TIPO == 'F'
		/*
		AVISO PARA BRUNO
		*/
		U_SWENV("5533984022125", "ERRO URGENTE (DIF. DE SALDO) NOTA FISCAL - :" + AllTrim(TRBERRO->C6_NUM)    )
		
		sleep(300)
		
		/*
		AVISO PARA ARLINDO
		*/
		U_SWENV("5527981187553", "ERRO URGENTE (DIF. DE SALDO) NOTA FISCAL - :" + AllTrim(TRBERRO->C6_NUM)     )
		
		sleep(300)
		
		/*
		EMAIL
		*/
		TCSPExec("SP_SENDMAIL",'ITINGA',"ti.vix@grupoqualita.com.br;logistica.es@qualitagroup.com;sales.es@qualitagroup.com","ERRO URGENTE (DIF. DE SALDO)","ERRO URGENTE (DIF. DE SALDO) NOTA FISCAL - :" + TRBERRO->C6_NUM ,'')
	ENDIF

	dbSelectArea("TRBERRO")
	dbSkip()
EndDo

dbSelectArea("TRBERRO") 
dbCloseArea()

/*
Caso exista alguma aprovação ou reprovação 
o sistema envia o protocolo por e-mail
*/
IF lEnvProt
	//WaitRunSrv( '"D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\wget\wget.exe" -t 1 "http://192.168.1.101:10530/ReportServer/Pages/ReportViewer.aspx?%2fItinga_reports%2fRQ0060&rs:Format=pdf" -O "D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\RQ0060.PDF"' , .t. , "D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\wget\" )
	  
	//ConOut("Gerando protocolo..." )
	//Sleep(3000)
	//TCSPExec("SP_SENDMAIL",'ITINGA',"diego.sirtori@grupoqualita.com.br",'Relaório de Protocolo','Anexo relatório de protocolos!','D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\RQ0060.PDF')
EndIf

If lAutoZAP
	RpcClearEnv()
	Conout(DtoC(dDatabase)+" - "+TIME()+" FIM do JOB liberação de Retornos pelo WHATSAPP.")
Else
	// Caso não seja job, informa na a atualização
	Alert("Fim da liberação de Retorno pelo WHATSAPP. (Chamada Manual)")
Endif

Return
