#include "protheus.ch"
#include "rwmake.ch"
#include "tbiconn.ch"  
#INCLUDE "TOTVS.CH"

/*                                          
Programa ...: MT150ROT.Prw
Uso ........: Ponto de Entrada (tela de aleta na rotina de atualização dos cotações de compras)
Data .......: 09/11/16
Feito por ..: Bruno Lage Ferreira.

Q-Liberação Faturamento
5527995295180-1587589430@g.us

Q-N2 - Liberação Compras
5527995295180-1594316108@g.us

Q-N1 - Liberação Compras
5527995295180-1587589523@g.us
*/

User Function MT150ROT()
***********************************************************************************************************
*  
*
***    
Local aMenu   := aRotina
Local aSubMnu := {}

If SubString(CNUMEMP,1,2) == "01" 
	AAdd(aSubMnu,	{ "Nível 01" , "U_fMPWAAPP('1')", 0 , 6, 0, nil})  	    //"MAPA DE COTAÇÃO"
	AAdd(aSubMnu,	{ "Nível 02" , "U_fMPWAAPP('2')", 0 , 6, 0, nil})  		//"MAPA DE COTAÇÃO"
	
	AAdd(aRotina,	{ "Mapa de Cotação" , "u_RELINWEB('RQ0025_V','Rel. Mapa de Contação','u_fParR25()')", 0 , 6, 0, nil})  	    //"MAPA DE COTAÇÃO"
	AAdd(aRotina,	{ "Enviar Mapa Cot. WhatsApp" , aSubMnu, 0 , 6, 0, nil})  		   											//"MAPA DE COTAÇÃO"
Else

	AAdd(aRotina,	{ "Mapa de Cotação"    , "u_RELINWEB('RIM0030','Rel. Mapa de Contação' ,'u_fParR25()')", 0 , 6, 0, nil})  	    //"MAPA DE COTAÇÃO"
	AAdd(aRotina,	{ "Mapa p/ Fornecedor" , "u_RELINWEB('RIM0030_XLS','Mapa p/ Fornecedor','u_fParR25()')", 0 , 6, 0, nil})
EndIf

Return(aMenu)

User Function fParR25()
****************************************************************************************************************
*    
*
****
Local cRet := ""

cRet := "&cCotacao=" + SC8->C8_FILIAL+SC8->C8_NUM

Return(cRet)


User Function fMPWAAPP(cOpcao)
****************************************************************************************************************
*    
*
****

WaitRunSrv( '"D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\wget\wget.exe" -t 1 "http://Administrator:xpacD99label@192.168.1.104:10530/ReportServer/Pages/ReportViewer.aspx?%2fItinga_reports%2fRQ0025_V&cCotacao=' + SC8->C8_NUM +'&rs:Format=pdf" -O "D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\RQ0025_V.PDF"' , .t. , "D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\wget\" )
																				
//Grupo de Faturamento Whatsapp
//{"root":[{"id":"5527995295180-1587589523@g.us","descricao":"Q-Liberação Compras"},{"id":"5527995295180-1587589430@g.us","descricao":"Q-Liberação Faturamento"}]}

/*
Oficial
*/
//cProt := U_SWENARWAP("5551997331669", "Aprovação Mapa de Cotação:" + AllTrim(SC8->C8_NUM)   + " Usuário:" + SUBSTR(CUSUARIO,7,15)  , "MC:" +AllTrim(SC8->C8_NUM)  ,"RQ0025_V"           ,"PDF","\RELINWEB\RQ0025_V.pdf")
                      
/*
Teste
*/

If cOpcao == "1" 
	cProt := U_SWENARWAP("5527995295180-1587589523@g.us", "(Nível 1) Aprovação Mapa de Cotação:" + AllTrim(SC8->C8_NUM)   + " Usuário:" + SUBSTR(CUSUARIO,7,15)  , "MC:" +AllTrim(SC8->C8_NUM)  ,"RQ0025_V"           ,"PDF","\RELINWEB\RQ0025_V.pdf")                     
Else
	cProt := U_SWENARWAP("5527995295180-1594316108@g.us", "(Nível 2) Aprovação sem o nível 1.  Aprovação Mapa de Cotação:" + AllTrim(SC8->C8_NUM)   + " Usuário:" + SUBSTR(CUSUARIO,7,15)  , "MC:" +AllTrim(SC8->C8_NUM)  ,"RQ0025_V"           ,"PDF","\RELINWEB\RQ0025_V.pdf")
EndIf

IF cProt = "" .or. cProt = nil 
	Alert("ERRO!!! O WhatsApp pode estar passando por alguma instabilidade no momento. Aguarde alguns instantes de tente novamente mais tarde!")
	Return()
EndIf


If  RecLock("WAM",.T.) 

	Replace WAM_FILIAL  With "" 
	Replace WAM_DATA    With Date()
	Replace WAM_HORA    With Time()
	Replace WAM_ID      With cProt
	Replace WAM_MSG     With "Aprovação Mapa de Cotação:" +AllTrim(SC8->C8_NUM)  + "Usuário:" + SUBSTR(CUSUARIO,7,15) + " Fornecedor:" + AllTrim(SC8->C8_FORNOME)
	//Replace WAM_TELL    With "5551997331669"
	//Replace WAM_TELL    With "5533984022125"
	Replace WAM_INDEX   With SC8->C8_FILIAL + SC8->C8_NUM
	Replace WAM_PERG    With "S"
	Replace WAM_NIVEL   With cOpcao
	//Replace WAM_DATAR   With ""
	//Replace WAM_HORAR   With ""
	//Replace WAM_RESPOSV With ""
	
	IF SubString(CNUMEMP,1,2) == "05"
		Replace WAM_EXEC    With 'ITINGA-MC'
	Else
		Replace WAM_EXEC    With 'QUALITA-MC'
	EndIf
	
   MsUnLock()
EndIf

/*
UPDATE NA SC8 ENVIANDO PARA APROVAÇÃO NO WHATSAPP
*/
cQuery := " UPDATE " + RetSqlName("SC8")  
cQuery += "    SET C8_LIBZAP = 'S'
cQuery += "  FROM " + RetSqlName("SC8")
cQuery += "  WHERE D_E_L_E_T_ <> '*'
cQuery += "    AND C8_NUM = '"+SC8->C8_NUM+"'
			
TcSQLExec(cQuery)

		
Alert("WhatsApp enviado com sucesso! " + cProt)

Return()

User Function MT150FIX()
***********************************************************************************************************
*  
*
***   
Local aMT150FIX := GetArea()	
If SubString(CNUMEMP,1,2) == "01" 

	Private aFixe2 		:=	{{"Status"		,"C8_STATUS"  },;
							{ "Lib.WhatsAPP","C8_LIBZAP " },;
							{ "Necessidade"	,"C8_DATPRF " },;
							{ "Num. Cotac"  ,"C8_NUM    " },;
							{ "Num. Solic"	,"C8_NUMSC"   },;
							{ "Fornecedor"	,"C8_FORNECE" },;		
							{ "Loja"		,"C8_LOJA   " },;		
							{ "Nome For."	,"C8_FORNOME" },;		
							{ "Cod.Produto"	,"C8_PRODUTO" },;		
							{ "Preco"		,"C8_PRECO"   }}	

Else

	Private aFixe2 		:=	{{"Status"		,"C8_STATUS"  },;
							{ "Necessidade"	,"C8_DATPRF " },;
							{ "Num. Cotac"  ,"C8_NUM    " },;
							{ "Num. Solic"	,"C8_NUMSC"   },;
							{ "Fornecedor"	,"C8_FORNECE" },;		
							{ "Loja"		,"C8_LOJA   " },;		
							{ "Nome For."	,"C8_FORNOME" },;		
							{ "Cod.Produto"	,"C8_PRODUTO" },;		
							{ "Preco"		,"C8_PRECO"   }}		

	//ALERT("OK")
EndIf

RestArea(aMT150FIX)

Return(aFixe2)



User Function MStatusSC1(cChave)
***********************************************************************************************************
*  01 = MAQUINA PARADA
*  02 = REQUER ATENCAO
*  03 = COMPRA NORMAL                                                                            
*  04 = IMPORTACAO 
***   
Local cRet := ""

	cRet := AllTrim(POSICIONE("SC1",1,cChave,"C1_XTIPO"))
	
	If cRet == "01"
		cRet := "MAQUINA PARADA"
	EndIf
	
	If cRet == "02"
		cRet := "REQUER ATENCAO"
	EndIf
	
	If cRet == "03"
		cRet := "COMPRA NORMAL"
	EndIf
	
	If cRet == "04"
		cRet := "IMPORTACAO"
	EndIf
	
Return(cRet) 
