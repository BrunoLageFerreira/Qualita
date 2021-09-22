#Include "rwmake.ch"
#Include "Colors.ch"
#Include "Protheus.ch"  
#Include "Topconn.ch"
    
/*
Programa ...: MCT1FOR.Prw
Uso ........: Contabilidade Siga CTB/COMPRAS
Data .......: 16/09/2021
Feito por ..: Bruno Lage Ferreira
Copyright @1998-2001,2021
Atualizado..: 

Nome do Arquivo:
*/     

User Function MCT1FOR()
************************************************************************************************
* // Vinculo ao ponto de entrada M020INC()
* // 
***  
	//+----------------------------------------------------------+
	//| Declaração de Variáveis                                  |
	//+----------------------------------------------------------+
	Local aAreaOld	:= GetArea()
	Local cBaseCTA	:= "21101"
	Local cUltCTA	:= ""
	Local cUltRed	:= ""
	Local cQuery	:= ""
	Local cQueryA2	:= ""
	Local cCtaRef	:= PadR("2.01.01.03.01",TamSx3("CVD_CTAREF")[1])
	Local cCtaSup	:= PadR("2.01.01.03",TamSx3("CVD_CTAREF")[1])
	Local cMsgStop	:= ""
	Local lGravou	:= .T.

	//+----------------------------------------------------------+
	//| Fecha areas de trabalho abertas                          |
	//+----------------------------------------------------------+	
	If Select("MAXCTA") > 0
		dbSelectArea("MAXCTA")
		dbCloseArea()
	EndIf

	If Select("CTAFOR") > 0
		dbSelectArea("CTAFOR")
		dbCloseArea()
	EndIf

	//+----------------------------------------------------------+
	//| Verifica se ja tem fornecedor com esta base de CNPJ      |
	//| para pegar a conta contabil dele                         |
	//+----------------------------------------------------------+	
	cQueryA2 := "SELECT A2_CONTA " + CRLF
	cQueryA2 += "FROM " + RetSqlName("SA2") + " SA2 " + CRLF
	cQueryA2 += "WHERE D_E_L_E_T_ <> '*' "  + CRLF
	cQueryA2 += " AND ((A2_TIPO = 'J' AND SUBSTR(A2_CGC,1,8) = '"+Substr(SA2->A2_CGC,1,8)+"') OR (A2_TIPO <> 'J' AND A2_CGC = '"+SA2->A2_CGC+"')) "

	//+---------------------------------------------------+
	//| Grava a query no log                              |
	//+---------------------------------------------------+
	MemoWrite(CLOGPATH+'RCTBM001_MCT1FOR.sql',cQueryA2)


	TcQuery cQueryA2 New Alias "CTAFOR"
	
	DbSelectArea("CTAFOR")
	DbGoTop()

	If CTAFOR->(!Eof()) .AND. !Empty(CTAFOR->A2_CONTA)

		cUltCTA := CTAFOR->A2_CONTA

	Else 

		//+----------------------------------------------------------+
		//| Query para buscar ultimos CT1_CONTA e CT1_RES            |
		//| Foram feitos filtros para tratar lixos na base           |
		//+----------------------------------------------------------+
		cQuery := "SELECT MAX(CT1_CONTA) ULCTA, MAX(CT1_RES) ULTRES " + CRLF
		cQuery += "FROM " + RetSqlName("CT1")+ " CT1 " + CRLF 
		cQuery += "WHERE D_E_L_E_T_ <> '*' " + CRLF  
		//cQuery += "	AND SUBSTR(CT1_CONTA,5) = '"+cBaseCTA+"' " + CRLF 
		cQuery += "	AND SUBSTR(CT1_CONTA,1,5) = '"+cBaseCTA+"' " + CRLF  
		cQuery += "	AND CT1_CONTA NOT IN ('211010465','2110109999')  " + CRLF 


	    MemoWrite(CLOGPATH+'RCTBM001_MCT1FOR1.sql',cQuery)

		TcQuery cQuery New Alias MAXCTA
		
		DbSelectArea("MAXCTA")
		DbGoTop()
		
		//+----------------------------------------------------------+
		//| Se trouxer resultados, coleta e grava na CT1             |
		//+----------------------------------------------------------+
		If MAXCTA->(!Eof())
			
			cUltCTA	:= Soma1(Alltrim(MAXCTA->ULCTA))
			cUltRED	:= Soma1(Alltrim(MAXCTA->ULTRES)) 

			//+---------------------+
			//| Grava os Dados      |
			//+---------------------+
			DbSelectArea("CT1")

			If Reclock("CT1",.T.)
			
				CT1_FILIAL	:= xFilial("CT1")
				CT1_CONTA	:= cUltCTA
				CT1_CTASUP  := "21101"  //MAX: 18/01/2018
				CT1_DESC01	:= SA2->A2_NOME
				CT1_RES		:= cUltRED
				CT1_CLASSE	:= '2'
				CT1_DTEXIS	:= CTOD("01/01/1980")
				CT1_BLOQ	:= '2'
				CT1_NORMAL	:= '2'
				CT1_NTSPED	:= '02'
				CT1_NATCTA	:= '02'
				MsUnlock("CT1")
				
				//+----------------------------------------------------------+
				//| Dados da Amarracao Conta x Referencial                   |
				//+----------------------------------------------------------+	
				/*
                If Reclock("CVD",.T.)


					CVD->CVD_FILIAL := xFilial('CVD')
					CVD->CVD_CONTA 	:= cUltCTA     
					CVD->CVD_ENTREF := PadR('10',TamSx3('CVD_ENTREF')[1])         //MAX: 18/01/2018
					CVD->CVD_CTAREF	:= cCtaRef 
					CVD->CVD_TPUTIL := 'A' 	
					CVD->CVD_CODPLA := PadR('004',TamSx3('CVD_CODPLA')[1])        //MAX: 18/01/2018   
					CVD->CVD_CLASSE := '2'
					CVD->CVD_NATCTA := '02'
					CVD->CVD_CTASUP := cCtaSup
					CVD->CVD_CUSTO	:= '' 

					MsUnlock("CVD")

				Else

					cMsgStop := "Nao conseguiu gravar amarracao plano de contas x Referencial" 
					ConOut(cMsgStop)
					MsgStop(cMsgStop)

				EndIf
                */

			Else

				lGravou := .F.
				cMsgStop := "Nao conseguiu gravar conta contabil e amarracao plano de contas x Referencial"
				ConOut(cMsgStop)
				MsgStop(cMsgStop)

			EndIf	
		
		EndIf

	EndIf

	//+----------------------------------------------------+
	//| Grava a conta contabil no fornecedor               |
	//+----------------------------------------------------+
	If lGravou

		If Reclock("SA2",.F.)
		
			SA2->A2_CONTA	:= cUltCTA
			
			SA2->(MsUnlock())

		Else

			cMsgStop := "Nao foi possivel gravar a conta contabil no cadastro do fornecedor (A2_CONTA)"
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

	If Select("CTAFOR") > 0
		dbSelectArea("CTAFOR")
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
