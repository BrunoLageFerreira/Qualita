#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "COLORS.CH"

STATIC dDataLimite := GetMv("MV_ULMES")

/*
	MTA103AA - Reteio do custo da nota fiscal de serviço.
*/

/*/{Protheus.doc} GROA015
Rateio do custo da nota fiscal de serviço. 

@author Kenny Roger Martins
@since 21/02/2017
@version 1.0

@example GROA015()
@obs 

@return Nil
/*/

User Function GROA015

	Local aAreaANT     := GetArea()
	Local aAreaSD1     := SD1->(GetArea())

	Local cTitulo      := "Produtos para Retorno"
	Local lCheck       := .F.
	Local lValida      := .F.
	Local aButtons     := {}
	Local aHeader      := U_GETHEADER("SF1", .T., .T.)
	Local aAlter       := {}
	Local aCols        := ()
	Local aCoors       := FWGetDialogSize(oMainWnd)
	Local oDlg         := Nil
	Local oPanelMaster := Nil
	Local oPanelClient := Nil
	Local oGetDados    := Nil

	U_TOTVSES()

	//---------------------------------------------------------
	// Verifica se documento pode ter rateio
	//---------------------------------------------------------

	Processa({|| lValida := getValida()}, "Aguarde...", "Processando registros...", .F.)

	If !lValida

		MsgStop("Esse documento não pode ter o custo rateado.")

		Return Nil

	EndIf

	//---------------------------------------------------------
	// Verifica se existe nota de retorno de beneficiamento
	//---------------------------------------------------------

	Processa({|| aCols := getAcols(aHeader, @lValida)}, "Aguarde...", "Processando registros...", .F.)

	If !lValida

		MsgStop("Documento já possui rateio com data em período encerrado. Não é possível refazer o rateio.")

		Return Nil

	EndIf

	If Len(aCols) == 0

		MsgStop("Nenhum documento foi encontrado para receber o rateio do custo.")

		Return Nil

	EndIf

	//---------------------------------------------------------
	// Verifica se está dentro do período de fechamento
	//---------------------------------------------------------

	If SF1->F1_EMISSAO <= dDataLimite

		MsgStop("Documento com data em período encerrado.")

		Return Nil

	EndIf

	//---------------------------------------------------------
	// Verifica se documento já foi rateado
	//---------------------------------------------------------

	SD1->(DbOrderNickName("GRNOTASERV"))

	If SD1->(MsSeek(SF1->(F1_FILIAL + F1_FORNECE + F1_LOJA + F1_DOC + F1_SERIE)))

		If !(MsgYesNo("Já existe rateio para essa nota fiscal, deseja continuar?" + Chr(10) + Chr(10) + ;
				"Atenção, caso deseje continuar o rateio anterior será refeito."))

			MsgStop("Operação cancelada pelo usuário.")

			Return Nil

		EndIf

	EndIf

	//---------------------------------------------------------
	// Carrega tela de seleção
	//---------------------------------------------------------

	DEFINE MSDIALOG oDlg TITLE cTitulo FROM aCoors[1], aCoors[2] TO aCoors[3]-160, aCoors[4]-160 COLORS 0, 16777215 PIXEL

	@ 000, 000 MSPANEL oPanelMaster SIZE 000, 000 OF oDlg         COLORS 0, 16777215 RAISED
	@ 000, 000 MSPANEL oPanelClient SIZE 000, 000 OF oPanelMaster COLORS 0, 16777215 RAISED

	oPanelMaster:Align := CONTROL_ALIGN_ALLCLIENT
	oPanelClient:Align := CONTROL_ALIGN_ALLCLIENT

	oGetDados := MsNewGetDados():New( 002, 002, 500, 500, GD_UPDATE, "AllwaysTrue", "AllwaysTrue", "", aAlter, 0, 999, "AllwaysTrue", "", "AllwaysTrue", oPanelClient, aHeader, aCols, {|| })

	oGetDados:oBrowse:bLDblClick   := {|| Inverte(@oGetDados)}
	oGetDados:oBrowse:bHeaderClick := {|oBrw, nCol, aDim| oBrw:nColpos := nCol, InverAll(@oGetDados, @lCheck)}

	// Alinha os browse
	oGetDados:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	oGetDados:Refresh()
	oGetDados:oBrowse:Refresh()

	ACTIVATE MSDIALOG oDlg CENTERED ON INIT (EnchoiceBar(oDlg, {|| Processa({|| Confirma(oGetDados, aHeader)}, "Aguarde...", "Processando registros...", .F.), oDlg:End()}, {||oDlg:End()},, @aButtons,,, .F., .F., .F., .T., .F., cTitulo ))

	RestArea(aAreaANT)
	RestArea(aAreaSD1)

Return Nil

/*---------+----------+-------+-----------------------+------+------------+
|Função    |Confirma  | Autor |KENNY ROGER MARTINS    | Data | 03.02.2017 |
+----------+----------+-------+-----------------------+------+------------+
|Descrição |Confirma produtos e carrega na aCols do pedido.               |
+----------+--------------------------------------------------------------+
|Uso       |Gestão de Granito (GrPlus)                                    |
+----------+-------------------------------------------------------------*/
Static Function Confirma(oGetDados, aHeader)

	Local nX        := 0
	Local nY        := 0
	Local nTotal    := 0
	Local nQtde1    := 0
	Local nQtde2    := 0
	Local cChave    := ""
	Local aServico  := {}
	Local aServicos := {}
	Local aOrdens   := {}	
	Local cSql      := ""
	Local qQuery    := ""
	Local nTotNot   := 0
			
	ProcRegua(0)	
	IncProc("Processando rateios...")
	IncProc(1)	
	IncProc(1)
	
	SD1->(DbSetOrder(1))	

	//---------------------------------------------------------
	// Carrega os serviços do documento de entrada
	//---------------------------------------------------------
	
	cChave := SF1->F1_FILIAL
	cChave += SF1->F1_DOC
	cChave += SF1->F1_SERIE
	cChave += SF1->F1_FORNECE
	cChave += SF1->F1_LOJA
	
	SD1->(DbGoTop())
	
	SD1->(MsSeek(cChave))
	
	Begin Transaction
			
		While SD1->(!Eof()) .And. SD1->(D1_FILIAL + D1_DOC + D1_SERIE + D1_FORNECE + D1_LOJA) == cChave
							
			//---------------------------------------------------------
			// Caso já exista rateio estorna
			//---------------------------------------------------------
										
			delRateio()
													
			aServico := {}
							
			aAdd(aServico, {"D1_COD",     SD1->D1_COD})
			aAdd(aServico, {"D1_DOC",     SD1->D1_DOC})
			aAdd(aServico, {"D1_EMISSAO", SD1->D1_EMISSAO})
			aAdd(aServico, {"D1_UM",      SD1->D1_UM})
			aAdd(aServico, {"D1_QUANT",   SD1->D1_QUANT})
			aAdd(aServico, {"D1_SEGUM",   SD1->D1_SEGUM})
			aAdd(aServico, {"D1_QTSEGUM", SD1->D1_QTSEGUM})
			aAdd(aServico, {"D1_NUMSEQ",  SD1->D1_NUMSEQ})		
			aAdd(aServico, {"D1_GRUPO",   SD1->D1_GRUPO})
			aAdd(aServico, {"D1_TP",      SD1->D1_TP})
			aAdd(aServico, {"D1_CONTA",   SD1->D1_CONTA})
			aAdd(aServico, {"D1_NUMLOTE", SD1->D1_NUMLOTE})
			aAdd(aServico, {"D1_LOTECTL", SD1->D1_LOTECTL})
			aAdd(aServico, {"D1_DTVALID", SD1->D1_DTVALID})									
			aAdd(aServico, {"D1_CUSTO",   SD1->D1_CUSTO})
			aAdd(aServico, {"D1_CUSTO2",  SD1->D1_CUSTO2})
			aAdd(aServico, {"D1_CUSTO3",  SD1->D1_CUSTO3})
			aAdd(aServico, {"D1_CUSTO4",  SD1->D1_CUSTO4})
			aAdd(aServico, {"D1_CUSTO5",  SD1->D1_CUSTO5})
			aAdd(aServico, {"D1_LOCAL",   SD1->D1_LOCAL})

			nTotNot += SD1->D1_QUANT

			aAdd(aServicos, aServico)
			
			SD1->(DbSkip())
		
		EndDo	
		
		//---------------------------------------------------------
		// Desfaz amarração da nota de serviço
		//---------------------------------------------------------
		
		cSql := "     SELECT * " + Chr(10)
		cSql += "       FROM " + RetSqlName("SD1") + " SD1 "   + Chr(10)
		cSql += "      WHERE SD1.D1_FILIAL  = '" + SF1->F1_FILIAL  + "' " + Chr(10) 
		cSql += "        AND SD1.D1_FORNECE = '" + SF1->F1_FORNECE + "' " + Chr(10) 
		cSql += "        AND SD1.D1_LOJA    = '" + SF1->F1_LOJA    + "' " + Chr(10) 
		cSql += "        AND SD1.D1_YNOTSER = '" + SF1->F1_DOC     + "' " + Chr(10) 
		cSql += "        AND SD1.D1_YSERSER = '" + SF1->F1_SERIE   + "' " + Chr(10) 
		cSql += "        AND SD1.D_E_L_E_T_ = '' " + Chr(10)
		
		TCQUERY cSql NEW ALIAS qQuery
			
		While qQuery->(!Eof())
		
			SD1->(DbGoTo(qQuery->(R_E_C_N_O_)))
													
			RecLock("SD1", .F.)
			
			SD1->D1_YNOTSER := ""
			SD1->D1_YSERSER := ""
			
			SD1->(MsUnLock())
			
			qQuery->(DbSkip())							
		
		EndDo		
		
		qQuery->(DbCloseArea())

		//---------------------------------------------------------
		// Carrega a quantidade total dos produtos
		//---------------------------------------------------------
		
		For nX := 1 To Len(oGetDados:aCols)
	
			If oGetDados:aCols[nX,1] == "LBOK"			
				
				cChave := oGetDados:aCols[nX, aScan(aHeader, {|x| AllTrim(x[2]) == "F1_FILIAL"})]
				cChave += oGetDados:aCols[nX, aScan(aHeader, {|x| AllTrim(x[2]) == "F1_DOC"})]
				cChave += oGetDados:aCols[nX, aScan(aHeader, {|x| AllTrim(x[2]) == "F1_SERIE"})]
				cChave += oGetDados:aCols[nX, aScan(aHeader, {|x| AllTrim(x[2]) == "F1_FORNECE"})]
				cChave += oGetDados:aCols[nX, aScan(aHeader, {|x| AllTrim(x[2]) == "F1_LOJA"})]
						
				SD1->(DbSetOrder(1))	
						
				SD1->(MsSeek(cChave))
						
				While SD1->(!Eof()) .And. SD1->(D1_FILIAL + D1_DOC + D1_SERIE + D1_FORNECE + D1_LOJA) == cChave
				
					nTotal += SD1->D1_QUANT
					
					SD1->(DbSkip())
				
				EndDo
				
			EndIf
			
		Next
		
		//---------------------------------------------------------
		// Faz o rateio do custo dos serviços
		//---------------------------------------------------------
		
		For nY := 1 To Len(aServicos)
						
			For nX := 1 To Len(oGetDados:aCols)
								
				If oGetDados:aCols[nX,1] == "LBOK"			
					
					cChave := oGetDados:aCols[nX, aScan(aHeader, {|x| AllTrim(x[2]) == "F1_FILIAL"})]
					cChave += oGetDados:aCols[nX, aScan(aHeader, {|x| AllTrim(x[2]) == "F1_DOC"})]
					cChave += oGetDados:aCols[nX, aScan(aHeader, {|x| AllTrim(x[2]) == "F1_SERIE"})]
					cChave += oGetDados:aCols[nX, aScan(aHeader, {|x| AllTrim(x[2]) == "F1_FORNECE"})]
					cChave += oGetDados:aCols[nX, aScan(aHeader, {|x| AllTrim(x[2]) == "F1_LOJA"})]
							
					SD1->(DbSetOrder(1))	
					
					SD1->(DbGoTop())
														
					SD1->(MsSeek(cChave))
							
					While SD1->(!Eof()) .And. SD1->(D1_FILIAL + D1_DOC + D1_SERIE + D1_FORNECE + D1_LOJA) == cChave
													
						RecLock("SD1", .F.)
						
						SD1->D1_YNOTSER := SF1->F1_DOC
						SD1->D1_YSERSER := SF1->F1_SERIE
						
						SD1->(MsUnLock())			
						
						nPosOp := aScan(aOrdens, {|x| x[1] + x[2] + x[7] == SD1->(D1_YOP + D1_LOCAL) + aServicos[nY][1][2]})
						
						If nPosOp > 0
						
							aOrdens[nPosOp, 04] += SD1->D1_QUANT
							aOrdens[nPosOp, 05] += SD1->D1_QTSEGUM 
						
						Else
						
							aAdd(aOrdens, {;
								SD1->D1_YOP,;         // 01
								aServicos[nY][20][2],;// 02    //Incluido armazem do serviço. O sistema estava pegando o armazem das chapas
								nTotal,;              // 03
								SD1->D1_QUANT,;       // 04
								SD1->D1_QTSEGUM,;     // 05
								aServicos[nY],;       // 06 - Array contendo os serviços
								aServicos[nY][1][2],;// 07 - Código do Produto Serviço
								nTotNot}) // 08 - Valor total da nota de serviço
						
						EndIf
																											
						SD1->(DbSkip())
					
					EndDo
														
				EndIf
				
			Next		
		
		Next
		
		setRateio(aOrdens)
				
	End Transaction
		
	MsgInfo("Rateio concluído com sucesso.")

Return Nil

/*---------+----------+-------+-----------------------+------+------------+
|Função    |getValida | Autor |KENNY ROGER MARTINS    | Data | 29.06.2017 |
+----------+----------+-------+-----------------------+------+------------+
|Descrição |Retorna dados para o array                                    |
+----------+--------------------------------------------------------------+
|Uso       |Gestão de Granito (GrPlus)                                    |
+----------+-------------------------------------------------------------*/
Static Function getValida(aHeader)

	Local cSql    := ""
	Local qQuery  := ""
	Local aLinha  := {}
	Local aCols   := {}
	Local nX      := 0
	Local lRet    := .F.
	
	ProcRegua(0)	
	IncProc("Validando dados...")
	IncProc(1)	
	IncProc(1)	
	
	cSql := "     SELECT * " + Chr(10)
	cSql += "       FROM " + RetSqlName("SF1") + " SF1 "   + Chr(10)
	cSql += " INNER JOIN " + RetSqlName("SD1") + " SD1 "   + Chr(10)
	cSql += "         ON SD1.D1_FILIAL  = SF1.F1_FILIAL "  + Chr(10)
	cSql += "        AND SD1.D1_FORNECE = SF1.F1_FORNECE " + Chr(10)
	cSql += "        AND SD1.D1_LOJA    = SF1.F1_LOJA "    + Chr(10)
	cSql += "        AND SD1.D1_DOC     = SF1.F1_DOC "     + Chr(10)
	cSql += "        AND SD1.D1_SERIE   = SF1.F1_SERIE "   + Chr(10)
	cSql += "        AND SD1.D1_LOTECTL = '' " + Chr(10)
	cSql += "        AND SD1.D1_IDENTB6 = '' " + Chr(10)
	cSql += "        AND SD1.D1_OP      = '' " + Chr(10)
	cSql += "        AND SD1.D1_YOP     = '' " + Chr(10)
	cSql += "        AND SD1.D_E_L_E_T_ = '' " + Chr(10)
	cSql += "      WHERE SF1.F1_FILIAL  = '" + SF1->F1_FILIAL  + "' " + Chr(10) 
	cSql += "        AND SF1.F1_FORNECE = '" + SF1->F1_FORNECE + "' " + Chr(10)
	cSql += "        AND SF1.F1_LOJA    = '" + SF1->F1_LOJA    + "' " + Chr(10)
	cSql += "        AND SF1.F1_DOC     = '" + SF1->F1_DOC     + "' " + Chr(10)
	cSql += "        AND SF1.F1_SERIE   = '" + SF1->F1_SERIE   + "' " + Chr(10)
	cSql += "        AND SF1.D_E_L_E_T_ = '' " + Chr(10)
	
	TCQUERY cSql NEW ALIAS qQuery
	
	While qQuery->(!Eof())
	
		lRet := .T.
								
		qQuery->(DbSkip())
		
	EndDo
		
	qQuery->(DbCloseArea())

Return lRet

/*---------+----------+-------+-----------------------+------+------------+
|Função    |getAcols  | Autor |KENNY ROGER MARTINS    | Data | 29.06.2017 |
+----------+----------+-------+-----------------------+------+------------+
|Descrição |Retorna dados para o array                                    |
+----------+--------------------------------------------------------------+
|Uso       |Gestão de Granito (GrPlus)                                    |
+----------+-------------------------------------------------------------*/
Static Function getAcols(aHeader, lValida)

	Local cSql     := ""
	Local qQuery   := ""
	Local cCampos  := "" 
	Local aLinha   := {}
	Local aCols    := {}
	Local nX       := 0
	Local aAreaSX3 := SX3->(GetArea())
	
	ProcRegua(0)	
	IncProc("Carregando dados...")
	IncProc(1)	
	IncProc(1)	
	
	For nX := 1 To Len(aHeader)
	
		If nX > 1 .And. nX < Len(aHeader) - 1 .And. aHeader[nX,10] <> "V"
		
			cCampos += AllTrim(aHeader[nX,2]) + ","
		
		EndIf	
	
	Next
	
	If "F1_EMISSAO" $ cCampos
	
		cCampos += "D1_YNOTSER,SF1.R_E_C_N_O_"
		
	Else
	
		cCampos += "D1_YNOTSER,F1_EMISSAO,SF1.R_E_C_N_O_"
		
	EndIf
			
	cSql := "     SELECT " + cCampos + Chr(10)
	cSql += "       FROM " + RetSqlName("SF1") + " SF1 "    + Chr(10)
	cSql += " INNER JOIN " + RetSqlName("SD1") + " SD1 "    + Chr(10)
	cSql += "         ON SD1.D1_FILIAL   = SF1.F1_FILIAL "  + Chr(10)
	cSql += "        AND SD1.D1_FORNECE  = SF1.F1_FORNECE " + Chr(10)
	cSql += "        AND SD1.D1_LOJA     = SF1.F1_LOJA "    + Chr(10)
	cSql += "        AND SD1.D1_DOC      = SF1.F1_DOC "     + Chr(10)
	cSql += "        AND SD1.D1_SERIE    = SF1.F1_SERIE "   + Chr(10)
	cSql += "        AND SD1.D1_IDENTB6  = '' " + Chr(10)
	cSql += "        AND SD1.D1_YOP     <> '' " + Chr(10)
	
	//------------------------------------------------------------------------------------
	// Verifica a inexistência da amarração ou se a próprio documento já foi vinculado
	//------------------------------------------------------------------------------------
		
	cSql += "        AND (" + Chr(10)
	cSql += "              SD1.D1_YNOTSER  = '' AND SD1.D1_EMISSAO  > '" + DtoS(dDataLimite) + "' " + Chr(10)
	cSql += "              OR (     SD1.D1_YNOTSER = '" + SF1->F1_DOC   + "'" + Chr(10)
	cSql += "                   AND SD1.D1_YSERSER = '" + SF1->F1_SERIE + "'" + Chr(10)
	cSql += "                 )" + Chr(10)
	cSql += "            )" + Chr(10)
	
	cSql += "        AND SD1.D_E_L_E_T_  = '' " + Chr(10)
	cSql += "      WHERE SF1.F1_FILIAL   = '" + SF1->F1_FILIAL    + "' " + Chr(10) 
	cSql += "        AND SF1.F1_FORNECE  = '" + SF1->F1_FORNECE   + "' " + Chr(10)
	cSql += "        AND SF1.F1_LOJA     = '" + SF1->F1_LOJA      + "' " + Chr(10)
	cSql += "        AND NOT (SF1.F1_DOC = '" + SF1->F1_DOC       + "' " + Chr(10)
	cSql += "        AND SF1.F1_SERIE    = '" + SF1->F1_SERIE     + "')" + Chr(10)
	cSql += "        AND SF1.D_E_L_E_T_  = '' " + Chr(10)	
	cSql += "   GROUP BY " + cCampos
	cSql += "   ORDER BY " + cCampos
	
	TCQUERY cSql NEW ALIAS qQuery
	
	While qQuery->(!Eof())
	
		If StoD(qQuery->(F1_EMISSAO)) <= dDataLimite
		
			lValida := .F.
			
		EndIf
		
		aLinha := {}
		
		aAdd(aLinha, If(Empty(qQuery->(D1_YNOTSER)), "LBNO", "LBOK"))
				
		For nX := 1 To Len(aHeader)
		
			If nX > 1 .And. nX < Len(aHeader) - 1
			
				If aHeader[nX,10] == "V"
				
					SX3->(DbSetOrder(2))
														
					SX3->(MsSeek(aHeader[nX,2]))
									
					aAdd(aLinha, &(SX3->X3_INIBRW))
				
				ElseIf aHeader[nX,8] == "D"
				
					aAdd(aLinha, Stod(&("qQuery->(" + AllTrim(aHeader[nX,2]) + ")")))
					
				Else
				
					aAdd(aLinha, &("qQuery->(" + AllTrim(aHeader[nX,2]) + ")"))
					
				EndIf  
		
			EndIf
			
		Next
		
		aAdd(aLinha, "SF1")
		aAdd(aLinha, qQuery->(R_E_C_N_O_))
		aAdd(aLinha, .F.)
		
		aAdd(aCols, aLinha)
						
		qQuery->(DbSkip())
		
	EndDo
		
	qQuery->(DbCloseArea())
	
	RestArea(aAreaSX3)

Return aCols

/*---------+----------+-------+-----------------------+------+------------+
|Função    |setRateio | Autor |KENNY ROGER MARTINS    | Data | 30.06.2017 |
+----------+----------+-------+-----------------------+------+------------+
|Descrição |Atualiza o rateio.                                            |
+----------+--------------------------------------------------------------+
|Uso       |Gestão de Granito (GrPlus)                                    |
+----------+-------------------------------------------------------------*/
Static Function setRateio(aOrdens)

	Local aServico  := {}
	Local nX		:= 0
	Local nTotAuxS  := 0
	Local nQuantSe  := 0
	//Incluido porque com essa movimentação de serviço que não alimenta estoque esta deixando o estoque 
	//negativo e quando isso acontece o sistema deleta a movimentação na SD3
	// Nessa rotina aqui  que o sistema deleta a movimentação invalida : B2AtuComD3
	Local cTipoMov := GetNewPar("GR_TMCUSTS", "999")


	For nX := 1 To Len(aOrdens)
	
		aServico := aOrdens[nX][6]

		//Ajuste realizado para o sistema não deixar residuo	
		If nX == 1 
			nTotAuxS := aOrdens[nX][8] // Incluindo a soma dos serviços
			nQuantSe := Round(aOrdens[nX][4] / aOrdens[nX][3] * u_getValField("D1_QUANT", aServico), TamSX3("D3_QUANT")[2])  // variavel para apontar o serviço utilizado
			nTotAuxS -= nQuantSe //retirando do total o valor utilizado
		ElseIf nX == Len(aOrdens)
			nQuantSe := nTotAuxS
		else
			nQuantSe := Round(aOrdens[nX][4] / aOrdens[nX][3] * u_getValField("D1_QUANT", aServico), TamSX3("D3_QUANT")[2]) 
			nTotAuxS -= nQuantSe
		EndIF

		RecLock("SD3",.T.)		
		
		SD3->D3_FILIAL		:= xFilial("SD3")
		SD3->D3_COD			:= u_getValField("D1_COD", aServico)
		SD3->D3_QUANT		:=  nQuantSe //Round(aOrdens[nX][4] / aOrdens[nX][3] * u_getValField("D1_QUANT", aServico), TamSX3("D3_QUANT")[2]) 
		SD3->D3_TM			:= cTipoMov
		SD3->D3_OP			:= aOrdens[nX][1]
		SD3->D3_LOCAL		:= aOrdens[nX][2]
		SD3->D3_DOC			:= u_getValField("D1_DOC",     aServico)
		SD3->D3_EMISSAO		:= u_getValField("D1_EMISSAO", aServico)
		SD3->D3_NUMSEQ		:= u_getValField("D1_NUMSEQ",  aServico)
		SD3->D3_UM			:= u_getValField("D1_UM",      aServico)
		SD3->D3_GRUPO		:= u_getValField("D1_GRUPO",   aServico)
		SD3->D3_TIPO		:= u_getValField("D1_TIPO",    aServico)
		SD3->D3_SEGUM		:= u_getValField("D1_SEGUM",   aServico)
		SD3->D3_CONTA		:= u_getValField("D1_CONTA",   aServico)
		SD3->D3_CF			:= "RE5"
		SD3->D3_QTSEGUM		:= Round(aOrdens[nX][4] / aOrdens[nX][3] * u_getValField("D1_QTSEGUM", aServico), TamSX3("D3_QTSEGUM")[2])
		SD3->D3_USUARIO     := cUserName //SubStr(cUsuario,7,15)//verificado outros fontes e o sistema pe
		
		SD3->D3_CUSTO1		:= Round(aOrdens[nX][4] / aOrdens[nX][3] * u_getValField("D1_CUSTO",  aServico), TamSX3("D3_CUSTO1")[2])
		SD3->D3_CUSTO2		:= Round(aOrdens[nX][4] / aOrdens[nX][3] * u_getValField("D1_CUSTO2", aServico), TamSX3("D3_CUSTO2")[2])
		SD3->D3_CUSTO3		:= Round(aOrdens[nX][4] / aOrdens[nX][3] * u_getValField("D1_CUSTO3", aServico), TamSX3("D3_CUSTO3")[2])
		SD3->D3_CUSTO4		:= Round(aOrdens[nX][4] / aOrdens[nX][3] * u_getValField("D1_CUSTO4", aServico), TamSX3("D3_CUSTO4")[2])
		SD3->D3_CUSTO5		:= Round(aOrdens[nX][4] / aOrdens[nX][3] * u_getValField("D1_CUSTO5", aServico), TamSX3("D3_CUSTO5")[2])

		SD3->D3_YCUSTO1		:= Round(aOrdens[nX][4] / aOrdens[nX][3] * u_getValField("D1_CUSTO",  aServico), TamSX3("D3_CUSTO1")[2])
		SD3->D3_YCUSTO2		:= Round(aOrdens[nX][4] / aOrdens[nX][3] * u_getValField("D1_CUSTO2", aServico), TamSX3("D3_CUSTO2")[2])
		SD3->D3_YCUSTO3		:= Round(aOrdens[nX][4] / aOrdens[nX][3] * u_getValField("D1_CUSTO3", aServico), TamSX3("D3_CUSTO3")[2])
		SD3->D3_YCUSTO4		:= Round(aOrdens[nX][4] / aOrdens[nX][3] * u_getValField("D1_CUSTO4", aServico), TamSX3("D3_CUSTO4")[2])
		SD3->D3_YCUSTO5		:= Round(aOrdens[nX][4] / aOrdens[nX][3] * u_getValField("D1_CUSTO5", aServico), TamSX3("D3_CUSTO5")[2])

		SD3->D3_NUMLOTE		:= u_getValField("D1_NUMLOTE", aServico)
		SD3->D3_LOTECTL		:= u_getValField("D1_LOTECTL", aServico)
		SD3->D3_DTVALID		:= u_getValField("D1_DTVALID", aServico)
		
		SC2->(dbSetOrder(1))
		
		If SC2->(MsSeek(xFilial("SC2") + SD1->D1_OP))
		
			SD3->D3_CC			:= SC2->C2_CC
			SD3->D3_ITEMCTA	:= SC2->C2_ITEMCTA
			SD3->D3_CLVL		:= SC2->C2_CLVL
			
		EndIf
			
		SD3->(MsUnLock())
		
		//----------------------------------------
		// Rotina para atualizar o custo na SD3
		//----------------------------------------
		U_GROXFUN("setCusto", {aOrdens[nX][1]})								
				
		B2AtuComD3({SD3->D3_CUSTO1,SD3->D3_CUSTO2,SD3->D3_CUSTO3,SD3->D3_CUSTO4,SD3->D3_CUSTO5},,.T./*lShowHelp*/)
		C2AtuComD3({SD3->D3_CUSTO1,SD3->D3_CUSTO2,SD3->D3_CUSTO3,SD3->D3_CUSTO4,SD3->D3_CUSTO5})		
		
	Next
	
Return Nil

/*---------+----------+-------+-----------------------+------+------------+
|Função    |delRateio | Autor |KENNY ROGER MARTINS    | Data | 30.06.2017 |
+----------+----------+-------+-----------------------+------+------------+
|Descrição |Estorna requisição do serviço.                                |
+----------+--------------------------------------------------------------+
|Uso       |Gestão de Granito (GrPlus)                                    |
+----------+-------------------------------------------------------------*/
Static Function delRateio()

	Local cSql      := ""
	Local qQuery    := ""
	Local cChave    := ""
	Local aStruct   := {}
	Local aRegistro := {}
	Local nX        := 0
		
	cSql := "     SELECT * " + Chr(10)
	cSql += "       FROM " + RetSqlName("SD3") + " SD3 "   + Chr(10)
	cSql += "      WHERE SD3.D3_FILIAL  = '" + SD1->D1_FILIAL + "' " + Chr(10) 
	cSql += "        AND SD3.D3_DOC     = '" + SD1->D1_DOC    + "' " + Chr(10)
	cSql += "        AND SD3.D3_NUMSEQ  = '" + SD1->D1_NUMSEQ + "' " + Chr(10)
	cSql += "        AND SD3.D3_ESTORNO = '' " + Chr(10)
	cSql += "        AND SD3.D3_CF      = 'RE5' " + Chr(10)
	cSql += "        AND SD3.D_E_L_E_T_ = '' " + Chr(10)
	
	TCQUERY cSql NEW ALIAS qQuery

	aStruct := SD3->(DbStruct())
	
	While qQuery->(!Eof())
	
		// If SD3->(DbGoTo(qQuery->(R_E_C_N_O_)))

			SD3->(DbGoTo(qQuery->(R_E_C_N_O_)))
		
			//-------------------------------------------------
			// Estorna registro atual
			//-------------------------------------------------
							
			RecLock("SD3", .F.)
		
			SD3->D3_ESTORNO := "S"
			
			SD3->(MsUnLock())		
			
			//----------------------------------------
			// Rotina para atualizar o custo na SD3
			//----------------------------------------
			U_GROXFUN("setCusto", {SD3->D3_OP})						
								
			//-------------------------------------------------
			// Gera registro de estorno
			//-------------------------------------------------
			
			aRegistro := {}
			
			For nX := 1 to Len(aStruct)
			
				If aStruct[nX,1] == "D3_TM"
				
					aAdd(aRegistro, "499")
					
				ElseIf aStruct[nX,1] == "D3_CF"  
			
					aAdd(aRegistro, "DE5")
					
				Else
				
					aAdd(aRegistro, &("SD3->" + AllTrim(aStruct[nx,1])))
										
				EndIf
			
			Next
			
			RecLock("SD3", .T.)
			
			For nX := 1 to Len(aStruct)
			
				&("SD3->" + AllTrim(aStruct[nx,1])) := aRegistro[nX]
			
			Next
			
			SD3->(MsUnLock())
											
			B2AtuComD3({SD3->D3_CUSTO1,SD3->D3_CUSTO2,SD3->D3_CUSTO3,SD3->D3_CUSTO4,SD3->D3_CUSTO5})
			C2AtuComD3({SD3->D3_CUSTO1,SD3->D3_CUSTO2,SD3->D3_CUSTO3,SD3->D3_CUSTO4,SD3->D3_CUSTO5})
								
		// EndIf
		
		qQuery->(DbSkip())		
	
	EndDo 		
	
	qQuery->(DbCloseArea())
	
Return Nil

/*---------+----------+-------+-----------------------+------+------------+
|Função    |Inverte   | Autor |KENNY ROGER MARTINS    | Data | 03.02.2017 |
+----------+----------+-------+-----------------------+------+------------+
|Descrição |Inverte valor do checkbox na linha.                           |
+----------+--------------------------------------------------------------+
|Uso       |Gestão de Granito (GrPlus)                                    |
+----------+-------------------------------------------------------------*/
Static Function Inverte(oGetDados)
	
	If oGetDados:aCols[oGetDados:nAt, 1] == "LBNO"

		oGetDados:aCols[oGetDados:nAt, 1] := "LBOK"
		
	Else
	
		oGetDados:aCols[oGetDados:nAt, 1] := "LBNO"
							
	EndIf

	oGetDados:Refresh()		

Return Nil

/*---------+----------+-------+-----------------------+------+------------+
|Função    |InverAll  | Autor |KENNY ROGER MARTINS    | Data | 03.02.2017 |
+----------+----------+-------+-----------------------+------+------------+
|Descrição |Inverte valor do checkbox na linha.                           |
+----------+--------------------------------------------------------------+
|Uso       |Gestão de Granito (GrPlus)                                    |
+----------+-------------------------------------------------------------*/
Static Function InverAll(oGetDados, lCheck)

	Local nX      := 0
	Local cCor    := "BR_VERDE" 
	
	If lCheck
	
		lCheck := .F.
		
		Return Nil
		
	Else
	
		lCheck := .T.
		
	EndIf

	If oGetDados:aCols[oGetDados:nAt, 1] == "LBNO"
	
		For nX := 1 to Len(oGetDados:aCols)
				
			oGetDados:aCols[nX, 1] := "LBOK"			
			 									
		Next
		
	Else
	
		For nX := 1 to Len(oGetDados:aCols)
		
			oGetDados:aCols[nX, 1] := "LBNO"						

		Next
		
	EndIf
		
	oGetDados:Refresh()	

Return Nil
