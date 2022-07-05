#Include "rwmake.ch"
#Include "Colors.ch"
#Include "Protheus.ch"  
#Include "Topconn.ch"
    
/*
Programa ...: MCT1CLI.Prw
Uso ........: Contabilidade Siga CTB/FATURAMENTO
Data .......: 24/11/2021
Feito por ..: Bruno Lage Ferreira
Copyright @1998-2001,2021
Atualizado..: 

Nome do Arquivo:
*/     
User Function M030Inc()  
/*****************************
*   Ponto de entrada apos gravacao dos dados do SA1
*   // INCLUSAO
*/                
  
/*
Chamada para o item contabil
*/
If PARAMIXB # 3
	//If SubString(CNUMEMP,1,2) == "01"
		U_MCT1CLI()
	//EndIf
EndIf

Return(.T.)

User Function MCT1CLI()
************************************************************************************************
* // Vinculo ao ponto de entrada M030INC()
* // 
***  
	//+----------------------------------------------------------+
	//| Declaração de Variáveis                                  |
	//+----------------------------------------------------------+
	Local aAreaOld	:= GetArea()
	Local cBaseCTA	:= "11201"
	Local cUltCTA	:= ""
	Local cUltRed	:= ""
	Local cQuery	:= ""
	Local cQueryA1	:= ""
	
	Local cCtaRef	:= PadR("1.01.02.02.01",TamSx3("CVD_CTAREF")[1])
	Local cCtaSup	:= PadR("1.01.02.02"   ,TamSx3("CVD_CTAREF")[1])

	Local cMsgStop	:= ""
	Local lGravou	:= .T.

	//+----------------------------------------------------------+
	//| Fecha areas de trabalho abertas                          |
	//+----------------------------------------------------------+	
	If Select("MAXCTA") > 0
		dbSelectArea("MAXCTA")
		dbCloseArea()
	EndIf

	If Select("CTACLI") > 0
		dbSelectArea("CTACLI")
		dbCloseArea()
	EndIf

	//+----------------------------------------------------------+
	//| Verifica se ja tem cliente com esta base de CNPJ         |
	//| para pegar a conta contabil dele                         |
	//+----------------------------------------------------------+	
	cQueryA1 := "SELECT A1_CONTA " + CRLF
	cQueryA1 += "FROM " + RetSqlName("SA1") + " SA1 " + CRLF
	cQueryA1 += "WHERE D_E_L_E_T_ <> '*' "  + CRLF
	cQueryA1 += " AND ((A1_TIPO = 'J' AND SUBSTR(A1_CGC,1,8) = '"+Substr(SA1->A1_CGC,1,8)+"') OR (A1_TIPO <> 'J' AND A1_CGC = '"+SA1->A1_CGC+"')) "

	//+---------------------------------------------------+
	//| Grava a query no log                              |
	//+---------------------------------------------------+
	//MemoWrite(CLOGPATH+'RCTBM001_MCT1CLI.sql',cQueryA1)


	//TcQuery cQueryA1 New Alias "CTACLI"
	
	//dbSelectArea("CTACLI")
	//dbGoTop()

	/*
	If CTACLI->(!Eof()) .AND. !Empty(CTACLI->A1_CONTA)

		cUltCTA := CTACLI->A1_CONTA

	Else 
	*/
	cQuery := " SELECT TOP 1 * FROM (
	cQuery += " SELECT ROW_NUMBER() OVER(ORDER BY REPLACE(CT1_CONTA,'11201','') ) AS ROW1,
	cQuery += " 		CT1_CONTA ULCTA, 
	cQuery += " 		CAST(REPLACE(CT1_CONTA,'11201','') AS INTEGER) COD_INTEIRO,
	cQuery += " 		REPLACE(CT1_CONTA,'11201','') CODIGO,
	cQuery += " 		(SELECT MAX(CT1_RES) FROM " + RetSqlName("CT1") + " (nolock) WHERE D_E_L_E_T_ = '' ) ULTRES  
	cQuery += "   FROM " + RetSqlName("CT1") + " (nolock) CT1 
	cQuery += "  WHERE D_E_L_E_T_ <> '*' 
	cQuery += "    AND SUBSTRING(CT1_CONTA,1,5) = '11201'
	cQuery += "    AND REPLACE(CT1_CONTA,'11201','') <> ''
	cQuery += "    AND Len(REPLACE(CT1_CONTA,'11201',''))=4
	cQuery += "  )TAB
 	cQuery += " WHERE ROW1<>COD_INTEIRO

	//MemoWrite(CLOGPATH+'RCTBM001_MCT1CLI1.sql',cQuery)

	TcQuery cQuery New Alias MAXCTA

	dbSelectArea("MAXCTA")
	dbGoTop()
	
	//+----------------------------------------------------------+
	//| Se trouxer resultados, coleta e grava na CT1             |
	//+----------------------------------------------------------+
	If MAXCTA->(!Eof())
		
		cUltCTA	:= STRZERO(MAXCTA->ROW1 , 4)
		cUltRED	:= SOMA1(Alltrim(MAXCTA->ULTRES))

		//+---------------------+
		//| Grava os Dados      |
		//+---------------------+
		dbSelectArea("CT1")

		If  Reclock("CT1",.T.)
		
			CT1_FILIAL	:= xFilial("CT1")
			CT1_CONTA	:= cBaseCTA+cUltCTA
			CT1_CTASUP  := cBaseCTA
			CT1_DESC01	:= SA1->A1_NOME
			CT1_RES		:= cUltRED
			CT1_CLASSE	:= '2'
			CT1_DTEXIS	:= CTOD("01/01/1980")
			CT1_BLOQ	:= '2'
			CT1_NORMAL	:= '1'
			CT1_NTSPED	:= '01'
			CT1_NATCTA	:= '01'
			MsUnlock("CT1")
			
			//+----------------------------------------------------------+
			//| Dados da Amarracao Conta x Referencial                   |
			//+----------------------------------------------------------+	
			If Reclock("CVD",.T.)
				CVD->CVD_FILIAL := xFilial('CVD')
				CVD->CVD_CONTA 	:= cUltCTA     
				CVD->CVD_ENTREF := PadR('10',TamSx3('CVD_ENTREF')[1])         
				CVD->CVD_CTAREF	:= cCtaRef 
				CVD->CVD_TPUTIL := 'A' 	
				CVD->CVD_CODPLA := PadR('001',TamSx3('CVD_CODPLA')[1])       
				CVD->CVD_CLASSE := '2'
				CVD->CVD_NATCTA := '02'
				CVD->CVD_CTASUP := cCtaSup
				CVD->CVD_CUSTO	:= '' 

				MsUnlock("CVD")
			Else
				cMsgStop := "Não conseguiu gravar amarracao plano de contas x referencial" 
				ConOut(cMsgStop)
				MsgStop(cMsgStop)
			EndIf
			

		Else

			lGravou := .F.
			cMsgStop := "Nao conseguiu gravar conta contabil e amarracao plano de contas x Referencial"
			ConOut(cMsgStop)
			MsgStop(cMsgStop)
		EndIf	
	
	EndIf
	/*
	EndIf
	*/
	//+----------------------------------------------------+
	//| Grava a conta contabil no fornecedor               |
	//+----------------------------------------------------+
	If lGravou

		If Reclock("SA1",.F.)
		
			SA1->A1_CONTA	:= cBaseCTA+cUltCTA
			
			SA1->(MsUnlock())

		Else

			cMsgStop := "Nao foi possivel gravar a conta contabil no cadastro do fornecedor (A1_CONTA)"
			ConOut(cMsgStop)
			MsgStop(cMsgStop)
		
		EndIf

	EndIf	
	
   	//+----------------------------------------------------------+
	//| Fecha areas de trabalho abertas                          |
	//+----------------------------------------------------------+	
	If Select("MAXCTA") > 0
		dbSelectArea("MAXCTA")
		dbCloseArea()
	EndIf

	If Select("CTACLI") > 0
		dbSelectArea("CTACLI")
		dbCloseArea()
	EndIf		

	//+----------------------------------------------------------+
	//| Restaura a posição de memoria e ponteiro de arquivos     |
	//+----------------------------------------------------------+	
	RestArea(aAreaOld) 
	
	//+----------------------------------------------------------+
	//| Limpa Variaveis e memoria                                |
	//+----------------------------------------------------------+
	aAreaOld := aSize(aAreaOld,0)
	aAreaOld := Nil		

Return
