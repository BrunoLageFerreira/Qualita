#INCLUDE "PROTHEUS.CH"
#INCLUDE "MNTR676.CH"
#INCLUDE "TOPCONN.CH"

/*/
   Função   : MNTR676      
   Autor    : Bruno Lage     
   Data     : 01/09/2008   
   Descrição: Chamada da impressao da ordem de servico por modelo             
   Uso      : MENU
/*/
User Function xMNTR676(lVPERG,cDEPLANO,cATEPLANO,aMATOS,aMATSX1)
//+--------------------------------------------+
//|Guarda conteudo e declara variaveis padroes |
//+--------------------------------------------+
	Local aNGBEGINPRM := NGBEGINPRM()

	Private oDlgC
	Private nOpRe   := 1
	Private nOpca   := 0
	Private lPERGUN := If(lVPERG = Nil,.T.,.F.)
	Private cNomFil := SM0->M0_FILIAL
	Private nHorz   := 100

	DEFINE MSDIALOG oDlgC FROM 00,00 TO 240,350 TITLE STR0051 PIXEL

	oPnlPai       := TPanel():New(00,00,,oDlgC,,,,,,350,300,.F.,.F.)
	oPnlPai:Align := CONTROL_ALIGN_ALLCLIENT

	@ 005,007 TO 80,170 LABEL STR0052 of oPnlPai Pixel
	@ 045,012 RADIO oRad VAR nOpRe ITEMS STR0047,STR0002,STR0049+" "+STR0053,STR0049+" "+STR0054,STR0050+" "+STR0053,STR0050+" "+STR0054 of SIZE 60,10 of oPnlPai Pixel

	Activate MsDialog oDlgC On Init EnchoiceBar(oDlgC,{|| nOPCA := 1,oDlgC:End()},{||oDlgC:End()}) Centered

	If nOpca == 0
		Return
	EndIf

	If nOpRe == 1
		MNTBA676(lPERGUN,,aMATOS)
	ElseIf nOpRe == 2
		xMNTSI676(lPERGUN,,aMATOS)
	ElseIf nOpRe == 3
		MNTR675(lPERGUN,cDEPLANO,cATEPLANO,aMATOS,1)
	ElseIf nOpRe == 4
		MNTR675(lPERGUN,cDEPLANO,cATEPLANO,aMATOS,2)
	ElseIf nOpRe == 5
		MNTR675(lPERGUN,cDEPLANO,cATEPLANO,aMATOS,3)
	Else
		MNTR675(lPERGUN,cDEPLANO,cATEPLANO,aMATOS,4)
	EndIf

	//+--------------------------------------------+
	//| Retorna conteudo de variaveis padroes      |
	//+--------------------------------------------+
	NGRETURNPRM(aNGBEGINPRM)

Return

/*/
                                                                             
                                                                             
                                                                         ?  
   Fun  o      MNTSI676   Autor  In cio Luiz Kolling      Data  02/09/2008   
                                                                         ?  
   Descri  o   Ordem de Servico Simplificada                                 
                                                                         ?  
   Parametros  _lPerg (logico) - Trava ou nao o botao de parametros          
                                                                         ?  
   Uso        MENU                                                           
                                                                          ? 
                                                                             
/*/
Static Function xMNTSI676(_lPerg,nRecOs,aMATOS) // alterado Tony

	Local cString  := "STJ"
	Local lImp     := .F.

	Private cPerg  := "MNT676"
	Private Titulo := STR0001+" "+STR0002
	Private oPrint

	Default _lPerg := .T.
	Default nRecOs := 0

	oFontMM := TFont():New("Courier New",10,10,,.T.,,,,.F.,.F.)
	oFontPN := TFont():New("Courier New",10,10,,.F.,,,,.F.,.F.)
	oFontMN := TFont():New("Courier New",10,10,,.T.,,,,.F.,.F.)
	oFontGN := TFont():New("Courier New",20,20,,.T.,,,,.F.,.F.)

	/*
	                                                              ?
	  Variaveis utilizadas para parametros                          
	  mv_par01     // De Plano de Manuten  o ?                      
	  mv_par02     // At  Plano de Manuten  o ?                     
	  mv_par03     // Do Bem                                        
	  mv_par04     // At  o Bem                                     
	  mv_par05     // Da Ordem                                      
	  mv_par06     // Ate a Ordem                                   
	  mv_par07     // Da Data                                       
	  mv_par08     // Ate a Data                                    
	  mv_par09     // Imprimir Localiza  o ?                        
	                                                                
	*/

	Pergunte(cPerg,_lPerg)

	//+--------------------------------------------------------------+
	//| Cria o Objeto o Print do TmsPrinter                          |
	//+--------------------------------------------------------------+
	oPrint := TMSPrinter():New(OemToAnsi(STR0001))
	lImp   := oPrint:Setup()
	oPrint:SetPortrait()

	If !lImp
		Return
	EndIf

	// Inicia a Impressao do Relatorio
	Processa({ |lEnd| MNTRSIMImp(oPrint,nRecOs,aMATOS)},STR0055)

Return NIL

/*
                                                                              
                                                                              
                                                                          ?  
   Fun  o     MNTRSIMImp   Autor  In cio Luiz Kolling      Data  05/09/2008   
                                                                          ?  
   Descri  o   Inicializa a Impressao                                         
   Parametros  Objeto do TMS oPrint                                           
                                                                           ? 
                                                                              
                                                                              
*/
Static Function MNTRSIMImp(oPrint,nRecOs,aMATOS)

	Local xQuery    := ""
	Local nFo       := 0
	Local aArInsu   := {}
	Local aArInsR   := {}
	Local aArEtap   := {}
	Local aArOpEt   := {}
	Local nDiff     := 0 // Recebe diferenca de dias mediante a programacao de O.S.
	Local lDesloca  := .F. // Se houve alteracao na data inicial e final na programacao
	Local lMNTR675G	:= ExistBlock("MNTR675G")
	Local cT5Sequen := Space( TAMSX3("T5_SEQUENC")[1] )
	Local cT5Tarefa	:= Space(TAMSX3("T5_TAREFA")[1])
	Local oTmpTbl //Tabela Temporaria

	Private m_pag := 0
	Private nLin  := 0
	Private nHorz := If( Type( "nHorz" ) <> "N", 100,nHorz)
	//Tabela Temporaria 1
	Private cTRBSTJ := GetNextAlias()

	Default nRecOs := 0

	If nRecOs == 0
		xQuery += "SELECT TJ_FILIAL,TJ_ORDEM,TJ_PLANO,TJ_TIPOOS,TJ_CODBEM,TJ_SERVICO,TJ_SEQRELA "
		xQuery += "FROM "+RetSqlName("STJ")+" TJ "
		xQuery += "WHERE TJ_ORDEM   >= '"+MV_PAR05+"' "
		xQuery += "  AND TJ_ORDEM   <= '"+MV_PAR06+"' "
		xQuery += "  AND TJ_CODBEM  >= '"+MV_PAR03+"' "
		xQuery += "  AND TJ_CODBEM  <= '"+MV_PAR04+"' "
		xQuery += "  AND TJ_PLANO   >= '"+MV_PAR01+"' "
		xQuery += "  AND TJ_PLANO   <= '"+MV_PAR02+"' "
		If !IsInCallStack("MNTA990")
			xQuery += "  AND TJ_DTMPINI >= '"+Dtos(MV_PAR07)+"' "
			xQuery += "  AND TJ_DTMPINI <= '"+Dtos(MV_PAR08)+"' "
		EndIf
		xQuery += "  AND (TJ_TIPOOS   = 'B' OR TJ_TIPOOS = 'L') "
		//xQuery += "  AND TJ_TERMINO  = 'N' "
		If MV_PAR10 == 1
			xQuery += "  AND TJ_SITUACA  = 'L' "
		EndIf
		If MV_PAR10 == 2
			xQuery += "  AND TJ_SITUACA  = 'P' "
		EndIf
		If MV_PAR10 == 3
			xQuery += "  AND TJ_SITUACA  <> 'C' "
		EndIf
		xQuery += "  AND TJ_FILIAL   = '"+STJ->(xFilial("STJ"))+"' "
		xQuery += "  AND TJ.D_E_L_E_T_ <> '*' "
		xQuery += "ORDER BY TJ_ORDEM "
	EndIf

	If (Select(cTRBSTJ) <> 0)
		(cTRBSTJ)->(dbSelectArea(cTRBSTJ))
		(cTRBSTJ)->(dbCloseArea())
	EndIf


	If nRecOs == 0
		xQuery := ChangeQuery(xQuery)
		TCQuery xQuery NEW ALIAS (cTRBSTJ)
	Else
		dbSelectArea("STJ")
		dbGoTo(nRecOS)
		aCampos  := {}
		aAdd(aCAMPOS,{"TJ_FILIAL" ,"C",02,0})
		aAdd(aCAMPOS,{"TJ_ORDEM"  ,"C",06,0})
		aAdd(aCAMPOS,{"TJ_PLANO"  ,"C",06,0})
		aAdd(aCAMPOS,{"TJ_TIPOOS" ,"C",01,0})
		aAdd(aCAMPOS,{"TJ_CODBEM" ,"C",06,0})
		aAdd(aCAMPOS,{"TJ_SERVICO","C",06,0})
		aAdd(aCAMPOS,{"TJ_SEQRELA","C",03,0})

		//Intancia classe FWTemporaryTable (TABELA 1)
		oTmpTbl  := FWTemporaryTable():New( cTRBSTJ, aCampos )
		//Cria indices
		oTmpTbl:AddIndex( "Ind01" , {"TJ_ORDEM"}  )
		//Cria a tabela temporaria
		oTmpTbl:Create()

		dbSelectArea(cTRBSTJ)
		(cTRBSTJ)->(DbAppend())
		(cTRBSTJ)->TJ_FILIAL  := STJ->TJ_FILIAL
		(cTRBSTJ)->TJ_ORDEM   := STJ->TJ_ORDEM
		(cTRBSTJ)->TJ_PLANO   := STJ->TJ_PLANO
		(cTRBSTJ)->TJ_TIPOOS  := STJ->TJ_TIPOOS
		(cTRBSTJ)->TJ_CODBEM  := STJ->TJ_CODBEM
		(cTRBSTJ)->TJ_SERVICO := STJ->TJ_SERVICO
		(cTRBSTJ)->TJ_SEQRELA := STJ->TJ_SEQRELA
	EndIf

	(cTRBSTJ)->( dbGotop() )
	ProcRegua( LastRec() )
	While !(cTRBSTJ)->( EoF() )
		IncProc()
		dbSelectArea("STJ")
		dbSetOrder(1)
		If dbSeek(xFilial("STJ")+(cTRBSTJ)->TJ_ORDEM+(cTRBSTJ)->TJ_PLANO)
			m_pag   := 0
			Lin     := 4000
			aArInsu := {}
			aArInsR := {}
			If aMATOS <> Nil
				nPosOs := aSCAN(aMATOS, {|x| x[1]+x[2] == (cTRBSTJ)->TJ_PLANO+(cTRBSTJ)->TJ_ORDEM})

				If nPosOs > 0

					If IsInCallStack("MNTA990") // Se for chamado na rotina de programacao de OS
						If Len(aMATOS[nPosOs]) >= 3
							nDiff := aMATOS[nPosOs,3] //Indica a quantidade de dias que as datas da OS serao deslocadas
							MNTRSIMCAB(,,,nDiff)      // CABECALHO, com o parametro da diferen a em dias
							lDesloca := .T.           // Se houve alteracao na data inicial e final na programacao
						Else
							MNTRSIMCAB() // CABECALHO
						EndIf
					Else
						MNTRSIMCAB() // CABECALHO
					EndIf

					If !Empty(ST9->T9_LOCAL)
						Lin += 90
					EndIf

					If Lin > 455
						oPrint:Say(Lin+85,nHorz+20,STR0019+"..: ",oFontMN)
					Else
						oPrint:Say(Lin-85,nHorz+20,STR0019+"..: ",oFontMN)
					EndIf
					MNTRSIMMEM()
					MNTRSIMCAB()
					oPrint:Line(Lin,nHorz+0010,Lin,nHorz+2335)

					dbSelectArea("STL")
					dbSetOrder(1)
					If dbSeek(xFilial("STL")+(cTRBSTJ)->TJ_ORDEM+(cTRBSTJ)->TJ_PLANO)
						While !EoF() .And. STL->TL_FILIAL = xFILIAL('STL') .And. STL->TL_ORDEM = STJ->TJ_ORDEM .And. STL->TL_PLANO = STJ->TJ_PLANO
							dbSelectArea("ST5")
							dbSetOrder(1)
							If dbSeek(xFilial("ST5")+STJ->TJ_CODBEM+STJ->TJ_SERVICO+STJ->TJ_SEQRELA+STL->TL_TAREFA)
								cT5Sequen := cValToChar(STRZERO(T5_SEQUENC,TAMSX3("T5_SEQUENC")[1]))
							EndIf

							//TESTE
							If STL->TL_TIPOREG <> "P"
								vVETHORAS := NGTQUATINS(STL->TL_CODIGO,STL->TL_TIPOREG,STL->TL_USACALE,STL->TL_QUANTID,STL->TL_TIPOHOR,STL->TL_DTINICI,;
								STL->TL_HOINICI,STL->TL_DTFIM,STL->TL_HOFIM,STL->TL_UNIDADE)
								nQTDIns   := NGRHODSEXN(vVETHORAS[1],"D")
							Else
								nQTDIns   := STL->TL_QUANTID
							EndIf
							//FIM TESTE

							If Alltrim(STL->TL_SEQRELA) = '0'
								aAdd(aArInsu,{STL->TL_TAREFA,STL->TL_TIPOREG,STL->TL_CODIGO,STL->TL_QUANREC,nQTDIns,STL->TL_UNIDADE,STL->TL_DTINICI,STL->TL_HOINICI,;
								STL->TL_DTFIM,STL->TL_HOFIM,cT5Sequen})
							Else
								aAdd(aArInsR,{STL->TL_TAREFA,STL->TL_TIPOREG,STL->TL_CODIGO,STL->TL_QUANREC,nQTDIns,STL->TL_UNIDADE,STL->TL_DTINICI,STL->TL_HOINICI,;
								STL->TL_DTFIM,STL->TL_HOFIM,cT5Sequen})
							EndIf

							dbSelectArea("STL")
							dbSkip()
						EndDo
					EndIf

					nReal := 2

					If Len(aArInsu) >=  Len(aArInsR)
						nReal := Len(aArInsu) + 2
					Else
						nReal := Len(aArInsR) + 2
					EndIf

					If lDesloca // Se houve alteracao na data inicial e final na programacao.
						MNTRSIMITL(STR0020,If(Len(aArInsu) == 0,1,Len(aArInsu)),aArInsu, nDiff) // Passa o quarto parametro da diferenca de dias - Insumos Previstos
					Else // Se a data nao foi alterada
						MNTRSIMITL(STR0020,If(Len(aArInsu) == 0,1,Len(aArInsu)),aArInsu) // Nao passa a diferenca de dias - Insumos Previstos
					EndIf

					MNTRSIMITL(STR0021,nReal,aArInsR) // Insumos Reportados

					aArEtap := {}

					dbSelectArea("STQ")
					dbSetOrder(3)
					If dbSeek(xFilial("STQ")+(cTRBSTJ)->TJ_ORDEM+(cTRBSTJ)->TJ_PLANO)
						While !EoF() .And. STQ->TQ_FILIAL = xFILIAL('STQ') .And. STQ->TQ_ORDEM = STJ->TJ_ORDEM .And. STQ->TQ_PLANO = STJ->TJ_PLANO

							dbSelectArea("ST5")
							dbSetOrder(1)
							If dbSeek(xFilial("ST5")+STJ->TJ_CODBEM+STJ->TJ_SERVICO+STJ->TJ_SEQRELA+STQ->TQ_TAREFA)
								cT5Sequen := cValToChar(STRZERO(T5_SEQUENC,TAMSX3("T5_SEQUENC")[1]))
								cT5Tarefa := ST5->T5_TAREFA
							EndIf

							Aadd(aArEtap,{STQ->TQ_TAREFA,STQ->TQ_ETAPA,STQ->TQ_OK,STQ->TQ_SEQETA,cT5Sequen,cT5Tarefa})
							dbSelectArea("STQ")
							dbSkip()
						EndDo
					EndIf

					MNTRSIMCAB()

					MNTRSIMIET(aArEtap)

					If Len(aArEtap) > 0
						aArOpEt := {}
						For nFo := 1 To Len(aArEtap)
							dbSelectArea("TPC")
							dbSetOrder(1)
							If dbSeek(xFilial("TPC")+aArEtap[nFo,2])
								While !EoF() .And. TPC->TPC_FILIAL = xFILIAL('TPC') .And. TPC->TPC_ETAPA = aArEtap[nFo,2]

									dbSelectArea("TPQ")
									dbSetOrder(1)
									dbSeek( xFilial("TPQ") + STJ->TJ_ORDEM + STJ->TJ_PLANO + aArEtap[nFo,1] + aArEtap[nFo,2] + TPC->TPC_OPCAO)

									aAdd(aArOpEt,{aArEtap[nFo,1],aArEtap[nFo,2],TPC->TPC_OPCAO,TPC->TPC_TIPRES,TPC->TPC_FORMUL,TPQ->TPQ_RESPOS,TPQ_OK})

									dbSelectArea("TPC")
									dbSkip()
								EndDo
							EndIf
						Next nFo
						If Len(aArOpEt) > 0
							MNTRSIMOPC(aArOpEt)
						EndIf
					EndIf

					MNTRSIMCAB(45)

					MNTRMOTATR() // imprime os motivos de atraso
					If STJ->TJ_PLANO == "000000"
						MNTROCOR() // imprime ocorrencias x causa x solucao
					EndIf
					MNTRSIMCAB()
					oPrint:Say(Lin,nHorz+100,STR0039,oFontMN)
					MNTRSIMCAB()
					oPrint:Say(Lin,nHorz+100,STR0040,oFontMN)
					oPrint:EndPage()
				EndIf
			Else
				MNTRSIMCAB() // CABECALHO

				If !Empty(ST9->T9_LOCAL)
					Lin += 90
				EndIf

				//Para n o sobrescrever os campos Observa  o
				If Lin > 455
					oPrint:Say(Lin+85,nHorz+20,STR0019+"..: ",oFontMN)
				Else
					oPrint:Say(Lin-85,nHorz+20,STR0019+"..: ",oFontMN)
				EndIf

				MNTRSIMMEM()
				MNTRSIMCAB()

				oPrint:Line(Lin,nHorz+0010,Lin,nHorz+2335)

				dbSelectArea("STL")
				dbSetOrder(1)
				If dbSeek(xFilial("STL")+(cTRBSTJ)->TJ_ORDEM+(cTRBSTJ)->TJ_PLANO)
					While !EoF() .And. STL->TL_FILIAL = xFILIAL('STL') .And. STL->TL_ORDEM = STJ->TJ_ORDEM .And. STL->TL_PLANO = STJ->TJ_PLANO

						dbSelectArea("ST5")
						dbSetOrder(1)
						If dbSeek(xFilial("ST5")+STJ->TJ_CODBEM+STJ->TJ_SERVICO+STJ->TJ_SEQRELA+STL->TL_TAREFA)
							cT5Sequen := cValToChar(STRZERO(T5_SEQUENC,TAMSX3("T5_SEQUENC")[1]))
							cT5Tarefa := ST5->T5_TAREFA
						EndIf

						//TESTE
						If STL->TL_TIPOREG <> "P"
							vVETHORAS := NGTQUATINS(STL->TL_CODIGO,STL->TL_TIPOREG,STL->TL_USACALE,STL->TL_QUANTID,STL->TL_TIPOHOR,STL->TL_DTINICI,STL->TL_HOINICI,;
							STL->TL_DTFIM,STL->TL_HOFIM,STL->TL_UNIDADE)
							nQTDIns   := NGRHODSEXN(vVETHORAS[1],"D")
						Else
							nQTDIns   := STL->TL_QUANTID
						EndIf
						//FIM TESTE

						If Alltrim(STL->TL_SEQRELA) = '0'
							aAdd(aArInsu,{STL->TL_TAREFA,STL->TL_TIPOREG,STL->TL_CODIGO,STL->TL_QUANREC,nQTDIns,STL->TL_UNIDADE,STL->TL_DTINICI,STL->TL_HOINICI,;
							STL->TL_DTFIM,STL->TL_HOFIM,cT5Sequen})
						Else
							aAdd(aArInsR,{STL->TL_TAREFA,STL->TL_TIPOREG,STL->TL_CODIGO,STL->TL_QUANREC,nQTDIns,STL->TL_UNIDADE,STL->TL_DTINICI,STL->TL_HOINICI,;
							STL->TL_DTFIM,STL->TL_HOFIM,cT5Sequen})
						EndIf

						dbSelectArea("STL")
						dbSkip()
					End
				EndIf
				nReal := 2
				If Len(aArInsu) >=  Len(aArInsR)
					nReal := Len(aArInsu) + 2
				Else
					nReal := Len(aArInsR) + 2
				EndIf

				MNTRSIMITL(STR0020,If(Len(aArInsu) == 0,1,Len(aArInsu)),aArInsu)
				MNTRSIMITL(STR0021,nReal,aArInsR)

				aArEtap := {}
				dbSelectArea("STQ")
				dbSetOrder(3)
				If dbSeek(xFilial("STQ")+(cTRBSTJ)->TJ_ORDEM+(cTRBSTJ)->TJ_PLANO)
					While !EoF() .And. STQ->TQ_FILIAL = xFILIAL('STQ') .And. STQ->TQ_ORDEM = STJ->TJ_ORDEM .And. STQ->TQ_PLANO = STJ->TJ_PLANO

						dbSelectArea("ST5")
						dbSetOrder(1)
						If dbSeek(xFilial("ST5")+STJ->TJ_CODBEM+STJ->TJ_SERVICO+STJ->TJ_SEQRELA+STQ->TQ_TAREFA)
							cT5Sequen := cValToChar(STRZERO(T5_SEQUENC,TAMSX3("T5_SEQUENC")[1]))
							cT5Tarefa := ST5->T5_TAREFA
						EndIf

						Aadd(aArEtap,{STQ->TQ_TAREFA,STQ->TQ_ETAPA,STQ->TQ_OK,STQ->TQ_SEQETA,cT5Sequen,cT5Tarefa})

						dbSelectArea("STQ")
						dbSkip()
					End
				EndIf

				If !Empty(aArEtap)
					If Len(aArEtap[1]) >= 4
						aSort(aArEtap,,,{|x,y| x[5]+x[6]+x[4]+x[1]+x[2] < y[5]+y[6]+y[4]+y[1]+y[2]})
					EndIf
				EndIf

				MNTRSIMCAB()

				MNTRSIMIET(aArEtap)

				If Len(aArEtap) > 0
					aArOpEt := {}
					For nFo := 1 To Len(aArEtap)
						dbSelectArea("TPC")
						dbSetOrder(1)
						If dbSeek(xFilial("TPC")+aArEtap[nFo,2])
							While !EoF() .And. TPC->TPC_FILIAL = xFILIAL('TPC') .And. TPC->TPC_ETAPA == aArEtap[nFo,2]

								dbSelectArea("TPQ")
								dbSetOrder(1)
								dbSeek(xFilial("TPQ") + STJ->TJ_ORDEM + STJ->TJ_PLANO + aArEtap[nFo,1] + aArEtap[nFo,2] + TPC->TPC_OPCAO )

								aAdd(aArOpEt,{aArEtap[nFo,1],aArEtap[nFo,2],TPC->TPC_OPCAO,TPC->TPC_TIPRES,TPC->TPC_FORMUL,TPQ->TPQ_RESPOS,TPQ_OK})

								dbSelectArea("TPC")
								dbSkip()
							EndDo
						EndIf
					Next nFo

					If Len(aArOpEt) > 0
						MNTRSIMOPC(aArOpEt)
					EndIf
				EndIf

				MNTRSIMCAB()

				MNTRMOTATR() // imprime os motivos de atraso
				If STJ->TJ_PLANO == "000000"
					MNTROCOR() // imprime ocorrencias x causa x solucao
				EndIf
				MNTRSIMCAB()
				oPrint:Say(Lin,nHorz+100,STR0039,oFontMN)
				MNTRSIMCAB()
				oPrint:Say(Lin,nHorz+100,STR0040,oFontMN)

				If lMNTR675G //Par metro {2} indica que o relat rio   do MNTR676
					ExecBlock("MNTR675G",.F.,.F.,{2})
				EndIf

				oPrint:EndPage()
			EndIf
		EndIf

		dbSelectArea(cTRBSTJ)
		dbSkip()

	EndDo

	oPrint:Preview()
	dbSelectArea(cTRBSTJ)
	dbCloseArea()

	If nRecOs <> 0
		oTmpTbl:Delete()
	EndIf

	dbSelectArea("STJ")

Return

/*/
                                                                              
                                                                              
                                                                          ?  
   Fun  o     MNTRSIMMEM   Autor  In cio Luiz Kolling      Data  05/09/2008   
                                                                          ?  
   Descri  o  Impressao do campo memo                                         
                                                                           ? 
                                                                              
                                                                              
/*/
Static Function MNTRSIMMEM()

	Local xInc   := 0
	Local i      := 0
	Local xLMemo := 0
	Local lTeme  := .F.

	If NGCADICBASE("TJ_MMSYP","A","STJ",.F.)
		cObs := Alltrim(NGMEMOSYP(STJ->TJ_MMSYP))
	Else
		cObs := Alltrim(STJ->TJ_OBSERVA)
	EndIf

	xLMemo := MlCount(cObs,80)

	For xInc := 1 To xLMemo
		If Lin == 460
			Lin-=5
		EndIf

		oPrint:Say(Lin,nHorz+400,MemoLine(cObs,80,xInc),oFontPN)
		MNTRSIMCAB(40)
		oPrint:Line(Lin,nHorz+0400,Lin,nHorz+2190)
		lTeme := .T.
	Next xInc

	For i := 1 to 5
		oPrint:Line(Lin,nHorz+0400,Lin,nHorz+2190)
		MNTRSIMCAB()
	Next i

Return lTeme

/*/
                                                                              
                                                                              
                                                                          ?  
   Fun  o     MNTRSIMITL   Autor  In cio Luiz Kolling      Data  05/09/2008   
                                                                          ?  
   Descri  o  Impressao dos insumos                                           
                                                                           ? 
                                                                              
                                                                              
/*/
Static Function MNTRSIMITL(cTIn,nVf,aVArI,nDiff)

	Local nF1   := 0
	Local nQtdI := 0

	Private cTpInsu := cTin

	Default nDiff := ""

	MNTRSIM1CA()

	If Len(aVArI) > 0

		If !Empty(aVArI)
			If Len(aVArI[1]) >= 11
				aAOrdIR := aSort(aVArI,,,{|x,y| x[11]+x[1]+x[2]+x[3] < y[11]+y[1]+y[2]+y[3]})
			Else
				aAOrdIR := aSort(aVArI,,,{|x,y| x[1]+x[2]+x[3] < y[1]+y[2]+y[3]})
			EndIf
		EndIf

		For nQtdI := 1 To  Len(aAOrdIR)
			cTarefa := aAOrdIR[nQtdI,1]
			oPrint:Say(Lin,nHorz+20,cTarefa,oFontPN)

			cTipoI  := aAOrdIR[nQtdI,2]
			oPrint:Say(Lin,nHorz+210,Substr(NGRETSX3BOX("TL_TIPOREG",cTipoI),1,3)+".",oFontPN)

			MNTRSIMVER()

			oPrint:Line(Lin,nHorz+0010,Lin,nHorz+2335)

			oPrint:Say(Lin,nHorz+0340,aAOrdIR[nQtdI,3],oFontPN)       // produto
			oPrint:Say(Lin,nHorz+0830,TransForm(aAOrdIR[nQtdI,4],"@E 999"),oFontPN)  // quandidade
			oPrint:Say(Lin,nHorz+0910,TransForm(aAOrdIR[nQtdI,5],"@E 999,999.99"),oFontPN)  // Consumo
			oPrint:Say(Lin,nHorz+1150,aAOrdIR[nQtdI,6],oFontPN)       // unidade
			oPrint:Say(Lin,nHorz+1250,If(ValType(nDiff) == "N",Dtoc(aAOrdIR[nQtdI,7]+nDiff),Dtoc(aAOrdIR[nQtdI,7])),oFontPN) // data inicio
			oPrint:Say(Lin,nHorz+1480,aAOrdIR[nQtdI,8],oFontPN)       // hora inicio
			oPrint:Say(Lin,nHorz+1700,If(ValType(nDiff) == "N",Dtoc(aAOrdIR[nQtdI,9]+nDiff),Dtoc(aAOrdIR[nQtdI,9])),oFontPN) // data fim
			oPrint:Say(Lin,nHorz+1940,aAOrdIR[nQtdI,10],oFontPN)      // hora fim
			MNTRSIMCAB(,'I',.T.)
		Next
		oPrint:Line(Lin,nHorz+0010,Lin,nHorz+2335)
	EndIf

	If Len(aVArI) == 0
		For nF1 := 1 To nVf
			MNTRSIMVER()
			MNTRSIMCAB(,'I',.T.)
			oPrint:Line(Lin,nHorz+0010,Lin,nHorz+2335)
		Next nF1
	Else
		For nF1 := 1 to (nVf-Len(aVArI))
			MNTRSIMVER()
			MNTRSIMCAB(,'I',.T.)
			oPrint:Line(Lin,nHorz+0010,Lin,nHorz+2335)
		Next nF1
	EndIf

Return

/*/
                                                                              
                                                                              
                                                                          ?  
   Fun  o     MNTRSIMIET   Autor  In cio Luiz Kolling      Data  05/09/2008   
                                                                          ?  
   Descri  o  Impressao das etapas                                            
                                                                           ? 
                                                                              
                                                                              
/*/
Static Function MNTRSIMIET(aVArI)

	Local nFv       := 0
	Local nQtdI     := 0
	Local cEtpDesc  := ""
	Local cEtpDesc2 := ""
	Local nPosi     := 0
	Local nPosi2    := 0

	MNTRSIM2CA()
	If Len(aVArI) > 0

		/* REFEITA A ATRIBUI  O ABAIXO, SEM 'ASORT', PARA QUE RESPEITASSE O NOVO  NDICE (3) DA STQ*/
		aAOrdIR := aClone(aVArI)
		For nQtdI := 1 To Len(aAOrdIR)

			cTarefa := aAOrdIR[nQtdI,1]
			oPrint:Say(Lin,nHorz+020,cTarefa,oFontPN)

			cEtapa := aAOrdIR[nQtdI,2]
			oPrint:Say(Lin,nHorz+0220,cEtapa,oFontPN)

			MNTRSIMVE2()

			oPrint:Line(Lin,nHorz+0010,Lin,nHorz+2335)

			cEtpDesc := NGSEEK("TPA",cEtapa,1,"TPA->TPA_DESCRI")
			cEtpDesc := AllTrim(cEtpDesc)

			If Len(cEtpDesc) > 130  //quebra de duas linhas

				cEtpDesc2 := SubStr(cEtpDesc,50,15)
				nPosi     := At(" ",cEtpDesc2)

				If nPosi <> 0 .And. nPosi <= 15
					nPosi += 50
				Else
					nPosi :=	65
				EndIf

				cEtpDesc2 := ""
				cEtpDesc2 := SubStr(cEtpDesc,nPosi+50,30)
				nPosi2    += At(" ",cEtpDesc2)

				If nPosi2 <> 0 .And. nPosi <= 30
					nPosi2 += 50
				Else
					nPosi2 := 65
				EndIf

				oPrint:Say(Lin,nHorz+0430,SubStr(cEtpDesc,1,nPosi-1),oFontPN)
				MNTRSIMCAB(,'E',.T.)
				MNTRSIMVE2()

				oPrint:Say(Lin,nHorz+0430,SubStr(cEtpDesc,nPosi,nPosi2),oFontPN)
				MNTRSIMCAB(,'E',.T.)
				MNTRSIMVE2()

				oPrint:Say(Lin,nHorz+0430,SubStr(cEtpDesc,nPosi+nPosi2+1,Len(cEtpDesc)),oFontPN)

			ElseIf Len(cEtpDesc) > 65 .And. Len(cEtpDesc) <= 130  //quebra de uma linha

				cEtpDesc2 := SubStr(cEtpDesc,50,Len(cEtpDesc))
				nPosi     := At(" ",cEtpDesc2)

				If nPosi <> 0 .And. nPosi <= 15
					nPosi += 50
				Else
					nPosi :=	65
				EndIf

				oPrint:Say(Lin,nHorz+0430,SubStr(cEtpDesc,1,nPosi-1),oFontPN)
				MNTRSIMCAB(,'E',.T.)
				MNTRSIMVE2()

				oPrint:Say(Lin,nHorz+0430,SubStr(cEtpDesc,nPosi,Len(cEtpDesc)),oFontPN)

			Else   //etapa com apenas uma linha
				oPrint:Say(Lin,nHorz+0430,cEtpDesc,oFontPN)
			EndIf

			If !Empty(aAOrdIR[nQtdI,3])
				oPrint:Say(Lin,nHorz+1840,STR0035,oFontPN)
			EndIf

			MNTRSIMCAB(,'E',.T.)
		Next
		oPrint:Line(Lin,nHorz+0010,Lin,nHorz+2335)
	EndIf

	For nFv := 1 To 5
		MNTRSIMVE2()
		MNTRSIMCAB(,'E',.T.)
		oPrint:Line(Lin,nHorz+0010,Lin,nHorz+2335)
	Next nF1

Return

/*/
                                                                              
                                                                              
                                                                          ?  
   Fun  o     MNTRSIMTLD   Autor  In cio Luiz Kolling      Data  05/09/2008   
                                                                          ?  
   Descri  o  Cabecalho dos insumos                                           
                                                                           ? 
                                                                              
                                                                              
/*/
Static Function MNTRSIMTLD()

	oPrint:Say(Lin,nHorz+0020,STR0022,oFontMN)
	oPrint:Say(Lin,nHorz+0210,STR0023,oFontMN)
	oPrint:Say(Lin,nHorz+0340,STR0024,oFontMN)// produto
	oPrint:Say(Lin,nHorz+0680,STR0025,oFontMN)// quandidade
	oPrint:Say(Lin,nHorz+0910,STR0080,oFontMN)// Consumo
	oPrint:Say(Lin,nHorz+1150,STR0026,oFontMN)// unidade
	oPrint:Say(Lin,nHorz+1250,STR0027,oFontMN)// data inicio
	oPrint:Say(Lin,nHorz+1480,STR0028,oFontMN)// hora inicio
	oPrint:Say(Lin,nHorz+1700,STR0029,oFontMN)// data fim
	oPrint:Say(Lin,nHorz+1940,STR0030,oFontMN)// hora fim

Return

/*/
                                                                              
                                                                              
                                                                          ?  
   Fun  o     MNTRSIMVER   Autor  In cio Luiz Kolling      Data  05/09/2008   
                                                                          ?  
   Descri  o  Impressao das linhas verticais para insumos                     
                                                                           ? 
                                                                              
                                                                              
/*/
Static Function MNTRSIMVER()

	oPrint:Line(Lin,nHorz+0200,Lin+45,nHorz+0200)
	oPrint:Line(Lin,nHorz+0330,Lin+45,nHorz+0330)// produto
	oPrint:Line(Lin,nHorz+0670,Lin+45,nHorz+0670)// quandidade
	oPrint:Line(Lin,nHorz+0900,Lin+45,nHorz+0900)// Consumo
	oPrint:Line(Lin,nHorz+1140,Lin+45,nHorz+1140)// unidade
	oPrint:Line(Lin,nHorz+1240,Lin+45,nHorz+1240)// data inicio
	oPrint:Line(Lin,nHorz+1470,Lin+45,nHorz+1470)// hora inicio
	oPrint:Line(Lin,nHorz+1690,Lin+45,nHorz+1690)// data fim
	oPrint:Line(Lin,nHorz+1930,Lin+45,nHorz+1930)// hora fim

Return

/*/
                                                                              
                                                                              
                                                                          ?  
   Fun  o     MNTRSIMTQD   Autor  In cio Luiz Kolling      Data  05/09/2008   
                                                                          ?  
   Descri  o  Cabecalho das etapas                                            
                                                                           ? 
                                                                              
                                                                              
/*/
Static Function MNTRSIMTQD()

	oPrint:Say(Lin,nHorz+0020,STR0022,oFontMN)
	oPrint:Say(Lin,nHorz+0220,STR0032,oFontMN)
	oPrint:Say(Lin,nHorz+0430,STR0033,oFontMN)
	oPrint:Say(Lin,nHorz+1840,STR0034,oFontMN)

Return

/*/
                                                                              
                                                                              
                                                                          ?  
   Fun  o     MNTRSIMVE2   Autor  In cio Luiz Kolling      Data  05/09/2008   
                                                                          ?  
   Descri  o  Impressao das linhas verticais para etapas                      
                                                                           ? 
                                                                              
                                                                              
/*/
Static Function MNTRSIMVE2()

	oPrint:Line(Lin-20,nHorz+0200,Lin+45,nHorz+0200)
	oPrint:Line(Lin-20,nHorz+0405,Lin+45,nHorz+0405)
	oPrint:Line(Lin-20,nHorz+1830,Lin+45,nHorz+1830)

Return

/*/
                                                                              
                                                                              
                                                                          ?  
   Fun  o     MNTRSIMOPC   Autor  In cio Luiz Kolling      Data  05/09/2008   
                                                                          ?  
   Descri  o  Impressao das opcoes das etapas                                 
                                                                           ? 
                                                                              
                                                                              
/*/
Static Function MNTRSIMOPC( aVArOp )

	Local nQtdI := 0

	MNTRSIM3CA()

	//aAOrdIR := aSort(aVArOp,,,{|x,y| x[1]+x[2] < y[1]+y[2]})
	aAOrdIR := aVArOp

	For nQtdI := 1 To Len( aAOrdIR )
		cTarefa := aAOrdIR[nQtdI,1]
		oPrint:Say(Lin,nHorz+020,cTarefa,oFontPN)
		cEtapa := aAOrdIR[nQtdI,2]
		oPrint:Say(Lin,nHorz+0210,cEtapa,oFontPN)

		oPrint:Line(Lin,nHorz+0010,Lin,nHorz+2335)

		MNTRSIMVPC()

		oPrint:Say(Lin,nHorz+0430,aAOrdIR[nQtdI,3],oFontPN)

		oPrint:Say(Lin,nHorz+0840,NGRETSX3BOX("TPC_TIPRES",aAOrdIR[nQtdI,4]),oFontPN)

		oPrint:Say(Lin,nHorz+1140,aAOrdIR[nQtdI,5],oFontPN)

		oPrint:Say(Lin,nHorz+1520,aAOrdIR[nQtdI,6],oFontPN)

		If !Empty(aAOrdIR[nQtdI,7])
			oPrint:Say(Lin,nHorz+2050,STR0046,oFontPN)
		EndIf

		MNTRSIMCAB(,'O')
	Next

	oPrint:Line(Lin+15,nHorz+0010,Lin+15,nHorz+2335)

Return

/*/
                                                                              
                                                                              
                                                                          ?  
   Fun  o     MNTRSIMTPC   Autor  In cio Luiz Kolling      Data  05/09/2008   
                                                                          ?  
   Descri  o  Cabecalho das opcoes                                            
                                                                           ? 
                                                                              
                                                                              
/*/
User Function xMNTRSIMTPC() // alterado Tony
	oPrint:Say(Lin,nHorz+020 ,STR0022,oFontMN) //TARE
	oPrint:Say(Lin,nHorz+210 ,STR0032,oFontMN) //ETA
	oPrint:Say(Lin,nHorz+430 ,STR0042,oFontMN) //OP

	oPrint:Say(Lin,nHorz+840 ,STR0023,oFontMN) //TIP

	oPrint:Say(Lin,nHorz+1140,STR0043,oFontMN) //CONT
	oPrint:Say(Lin,nHorz+1520,STR0044,oFontMN) //RESP
	oPrint:Say(Lin,nHorz+2050,STR0045,oFontMN) //MARC
Return

/*/
                                                                              
                                                                              
                                                                          ?  
   Fun  o     MNTRSIMVPC   Autor  In cio Luiz Kolling      Data  05/09/2008   
                                                                          ?  
   Descri  o  Verticais das opcoes                                            
                                                                           ? 
                                                                              
                                                                              
/*/
Static Function MNTRSIMVPC()

	oPrint:Line(Lin-20,nHorz+200 ,Lin+60,nHorz+200)
	oPrint:Line(Lin-20,nHorz+405 ,Lin+60,nHorz+405)
	oPrint:Line(Lin-20,nHorz+800 ,Lin+60,nHorz+800)

	oPrint:Line(Lin-20,nHorz+1100,Lin+60,nHorz+1100)

	oPrint:Line(Lin-20,nHorz+1480,Lin+60,nHorz+1480)
	oPrint:Line(Lin-20,nHorz+2000,Lin+60,nHorz+2000)
Return

/*/
                                                                              
                                                                              
                                                                          ?  
   Fun ao      MNTRSIMCAB  Autor   Equipe NG               Data   08/07/08    
                                                                          ?  
   Descri  o    Inicializa a Impressao de uma nova pagina                     
                                                                           ? 
                                                                              
                                                                              
/*/
Static Function MNTRSIMCAB(nLSoma,cTiCa,lPrintVer, nDiff)

	Local cLoc
	Local cLogo
	Local nSoma      := If(nLSoma = Nil,45,nLSoma)
	Local cBARRAS    := If(isSRVunix(),"/","\")
	Local cRootPath  := Alltrim(GetSrvProfString("RootPath",cBARRAS))
	Local cStartPath := AllTrim(GetSrvProfString("StartPath",cBARRAS))
	Local cDirExeTh  := cRootPath+cStartPath
	Local cLocDesc   := ""
	Local cLocDesc2  := ""
	Local nPosi 	 := 1
	Local xLLoc		 := 1
	Local xInc		 := 1
	Local lPrim 	 := .F.

	Default lPrintVer := .F.
	Default nDiff     := ""

	cLogo := NGLOCLOGO()
	Lin   += nSoma

	If Lin > 3100
		nSoma := 45
		If lPrintVer
			oPrint:Line(Lin,nHorz+0010,Lin,nHorz+2335)
		EndIf
		Lin := 60
		m_pag ++
		oPrint:EndPage()
		oPrint:StartPage()
		oPrint:Box(Lin,100,3200,nHorz+2335)

		Lin += 20
		If File(cLogo)
			oPrint:SayBitMap(Lin,nHorz+40,cLogo,250,73)
		EndIf
		oPrint:Say(Lin,nHorz+0600,STR0001+"  "+STJ->TJ_ORDEM,oFontGN)
		oPrint:Say(Lin-20,nHorz+2050,STR0009+" "+Alltrim(Str(m_pag,3)),oFontMM)
		oPrint:Say(Lin+20,nHorz+2050,If(nOpRe = 1,STR0047,STR0002),oFontMM)

		Lin += 70
		oPrint:Line(Lin,nHorz+0010,Lin,nHorz+2335)

		Lin += 40
		If STJ->TJ_TIPOOS == "B"
			cLoc := NGLocComp(STJ->TJ_CODBEM,'1') //Bem
		Else
			cLoc := NGLocComp(STJ->TJ_CODBEM,'2') //Localiza  o
		EndIf

		If cLoc <> AllTrim(STJ->TJ_CODBEM)  .And. ( Type("MV_PAR09") == "N" .And. MV_PAR09 == 1) //Para tratar caso o mv_par09 seja nulo
			//Quebra de Linha para n o ultrapassar o limite da p gina
			If Len(cLoc) > 110 .And. STJ->TJ_TIPOOS <> "B" //quebra de linha

				cLocDesc2	:= SubStr(cLoc,1,Len(cLoc))
				nPosi		:= At(" ",cLocDesc2)
				If nPosi <> 0 .And. nPosi <= 95
					nPosi += 71
				Else
					nPosi := 84
				EndIf

				xLLoc := MlCount(cLoc,100)

				For xInc := 1 To xLLoc
					If Lin == 190
						Lin-=25
					EndIf

					If !lPrim
						oPrint:Say(Lin,nHorz+020,STR0056,oFontMM) //"Localiza  o.:"
						oPrint:Say(Lin,nHorz+020,Space(Len(STR0056)) + Space(1) + MemoLine(cLoc,90,xInc),oFontPN)
						oPrint:Say(Lin+45,nHorz+020,SubStr(cLoc,nPosi+19,110),oFontPN)
						lPrim := .T.
					EndIf

					Lin += nSoma
				Next xInc

			ElseIf Len(cLoc) > 85 .And. STJ->TJ_TIPOOS == "B" //quebra de linha

				cLocDesc2	:= SubStr(cLoc,1,Len(cLoc))
				nPosi		:= At(" ",cLocDesc2)
				If nPosi <> 0 .And. nPosi <= 75
					nPosi += 51
				Else
					nPosi := 64
				EndIf

				xLLoc := MlCount(cLoc,75)

				For xInc := 1 To xLLoc
					If Lin == 190
						Lin-=25
					EndIf

					If !lPrim
						oPrint:Say(Lin,nHorz+020,STR0056,oFontMM) //"Localiza  o.:"
						oPrint:Say(Lin,nHorz+020,Space(Len(STR0056)) + Space(1) + MemoLine(cLoc,75,xInc),oFontPN)
						oPrint:Say(Lin+45,nHorz+020,SubStr(cLoc,nPosi+25,110),oFontPN)
						lPrim := .T.
					EndIf

					Lin += nSoma
				Next xInc

			Else   //etapa com apenas uma linha
				oPrint:Say(Lin,nHorz+020,STR0056,oFontMM) //"Localiza  o.:"
				oPrint:Say(Lin,nHorz+020,Space(Len(STR0056)) + Space(1) + cLoc,oFontPN)
				Lin += nSoma
			EndIf
		EndIf

		If STJ->TJ_TIPOOS $ "B/M"
			oPrint:Say(Lin,nHorz+020,STR0010+".........:",oFontMN)
			oPrint:Say(lin,nHorz+020,Space(Len(STR0010+".........:"))+Space(1) + Alltrim(STJ->TJ_CODBEM)+' - '+NGSEEK('ST9',STJ->TJ_CODBEM,1,'ST9->T9_NOME'),oFontPN)
		Else
			oPrint:Say(Lin,nHorz+020,STR0024+"......:",oFontMN)
			oPrint:Say(lin,nHorz+020,Space(Len(STR0024+"......:"))+Space(1) + Alltrim(STJ->TJ_CODBEM)+' - '+NGSEEK("TAF","X2"+Substr(STJ->TJ_CODBEM,1,3),7,"SUBSTR(TAF_NOMNIV,1,40)"),oFontPN)
		EndIf

		oPrint:Say(Lin,nHorz+1650,STR0036+"...:",oFontMN)
		oPrint:Say(lin,nHorz+1650,Space(Len(STR0036+"...:"))+Space(1) + Dtoc(DdataBase)+" "+SubStr(Time(),1,5),oFontPN)

		Lin += nSoma
		oPrint:Say(Lin,nHorz+020,STR0011+".....:",oFontMN)

		oPrint:Say(Lin,nHorz+020,Space(Len(STR0011+".....:"))+Space(1) + Alltrim(STJ->TJ_SERVICO)+' - '+NGSEEK('ST4',STJ->TJ_SERVICO,1,'ST4->T4_NOME'),oFontPN)

		oPrint:Say(Lin,nHorz+1650,STR0012+".: ",oFontMN)
		oPrint:Say(Lin,nHorz+1650,Space(Len(STR0012+".: "))+Space(1) + STJ->TJ_SEQRELA,oFontPN)

		Lin += nSoma
		oPrint:Say(Lin,nHorz+020,STR0018+"........:",oFontMN)
		oPrint:Say(Lin,nHorz+020,Space(Len(STR0018+"........:"))+Space(1) + Alltrim(STJ->TJ_CODAREA)+' - '+NGSEEK('STD',STJ->TJ_CODAREA,1,'STD->TD_NOME'),oFontPN)

		oPrint:Say(Lin,nHorz+1650,STR0014+":",oFontMN)
		oPrint:Say(Lin,nHorz+1650,Space(Len(STR0014+":"))+Space(1) + If (ValType(nDiff) == "N",Dtoc(STJ->TJ_DTMPINI+nDiff),Dtoc(STJ->TJ_DTMPINI)),oFontPN)

		Lin += nSoma

		oPrint:Say(Lin,nHorz+1650,STR0015+"......:",oFontMN)
		oPrint:Say(Lin,nHorz+1650,Space(Len(STR0015+"......:"))+Space(1) + STJ->TJ_HOMPINI,oFontPN)

		oPrint:Say(Lin,nHorz+020,STR0013+"..:",oFontMN)
		oPrint:Say(Lin,nHorz+020,Space(Len(STR0013+"..:"))+Space(1) + If(STJ->TJ_PLANO <> "000000",NGSEEK('STF',STJ->TJ_CODBEM+STJ->TJ_SERVICO+STJ->TJ_SEQRELA,1,'STF->TF_NOMEMAN'),STR0017),oFontPN)

		If !Empty(ST9->T9_LOCAL)
			Lin += nSoma
			oPrint:Say(Lin,nHorz+015,STR0057,oFontPN) //"Local.......:"
			oPrint:Say(lin,nHorz+015,Space(Len(STR0057))+Space(1) + ST9->T9_LOCAL,oFonTPN)
		EndIf

		Lin += nSoma
		oPrint:Line(Lin,nHorz+0010,Lin,nHorz+2335)

		Lin := 460

		If cTiCa <> Nil
			If cTiCa == 'I'
				MNTRSIM1CA()
			ElseIf cTiCa == 'E'
				MNTRSIM2CA()
			ElseIf cTiCa == 'O'
				MNTRSIM3CA()
			EndIf
		EndIf
	EndIf

Return

/*/
                                                                              
                                                                              
                                                                          ?  
   Fun ao      MNTRSIM1CA  Autor  In cio Luiz Kolling      Data   08/07/08    
                                                                          ?  
   Descri  o    Cabecalho dos insumos                                         
                                                                           ? 
                                                                              
                                                                              
/*/
Static Function MNTRSIM1CA()
	MNTRSIMCAB()
	oPrint:Say(Lin,nHorz+0010,STR0016+" "+cTpInsu,oFontGN)
	MNTRSIMCAB(80)
	oPrint:Line(Lin,nHorz+0010,Lin,nHorz+2335)

	MNTRSIMCAB(20)
	MNTRSIMVER()

	MNTRSIMTLD()

	MNTRSIMCAB()
	oPrint:Line(Lin,nHorz+0010,Lin,nHorz+2335)
Return

/*/
                                                                              
                                                                              
                                                                          ?  
   Fun ao      MNTRSIM2CA  Autor  In cio Luiz Kolling      Data   08/07/08    
                                                                          ?  
   Descri  o    Cabecalho das etapas                                          
                                                                           ? 
                                                                              
                                                                              
/*/
Static Function MNTRSIM2CA()
	MNTRSIMCAB()
	oPrint:Say(Lin,nHorz+0010,STR0031+" "+STR0037+'/'+STR0038,oFontGN)
	MNTRSIMCAB(80)
	oPrint:Line(Lin,nHorz+0010,Lin,nHorz+2335)

	MNTRSIMCAB(20)
	MNTRSIMVE2()

	MNTRSIMTQD()

	MNTRSIMCAB()
	oPrint:Line(Lin,nHorz+0010,Lin,nHorz+2335)
Return

/*/
                                                                              
                                                                              
                                                                          ?  
   Fun ao      MNTRSIM3CA  Autor  In cio Luiz Kolling      Data   08/07/08    
                                                                          ?  
   Descri  o    Cabecalho das opcoes da etapa                                 
                                                                           ? 
                                                                              
                                                                              
/*/
Static Function MNTRSIM3CA()
	MNTRSIMCAB(80)
	oPrint:Say(Lin,nHorz+0010,STR0041,oFontGN)
	MNTRSIMCAB(80)
	oPrint:Line(Lin,nHorz+0010,Lin,nHorz+2335)

	MNTRSIMCAB(20)
	MNTRSIMVPC()

	xMNTRSIMTPC()
	MNTRSIMCAB()
	oPrint:Line(Lin,nHorz+0010,Lin,nHorz+2335)
Return

/*/
                                                                             
                                                                             
                                                                         ?  
   Fun  o     MNTBA676     Autor  Inacio Luiz Kolling     Data  04/09/2008   
                                                                         ?  
   Descri  o  Impressao da ordem de servico BASICA                           
                                                                         ?  
   Parametros  _lPerg (logico) - Trava ou nao o botao de parametros          
                                                                         ?  
   Uso        MENU                                                           
                                                                          ? 
                                                                             
                                                                             
/*/
User Function xMNTBA676(_lPerg,nRecOs,aMATOS) //alterado Tony

	Local cString  := "STJ"
	Local lImp     := .F.
	Private cPerg  := "MNT676"
	Private Titulo := STR0001+" "+STR0047
	Private oPrint

	Default _lPerg := .T.
	Default nRecOs := 0

	oFontMM := TFont():New("Courier New",10,10,,.T.,,,,.F.,.F.)
	oFontPN := TFont():New("Courier New",10,10,,.F.,,,,.F.,.F.)
	oFontMN := TFont():New("Courier New",10,10,,.T.,,,,.F.,.F.)
	oFontGN := TFont():New("Courier New",20,20,,.T.,,,,.F.,.F.)

	/*
	                                                              ?
	  Variaveis utilizadas para parametros                          
	  mv_par01     // De Plano de Manuten  o ?                      
	  mv_par02     // At  Plano de Manuten  o ?                     
	  mv_par03     // Do Bem                                        
	  mv_par04     // At  o Bem                                     
	  mv_par05     // Da Ordem                                      
	  mv_par06     // Ate a Ordem                                   
	  mv_par07     // Da Data                                       
	  mv_par08     // Ate a Data                                    
	  mv_par09     // Imprimir Localiza  o ?                        
	                                                                
	*/

	Pergunte(cPerg,_lPerg)

	//+--------------------------------------------------------------+
	//| Cria o Objeto o Print do TmsPrinter                          |
	//+--------------------------------------------------------------+
	oPrint := TMSPrinter():New(OemToAnsi(STR0001))
	lImp   := oPrint:Setup()
	oPrint:SetPortrait()

	If !lImp
		Return
	EndIf

	// Inicia a Impressao do Relatorio
	Processa({ |lEnd| MNTRBASImp(oPrint,nRecOs,aMATOS)},STR0055)

Return NIL

/*/
                                                                              
                                                                              
                                                                          ?  
   Fun  o     MNTRBASImp   Autor  In cio Luiz Kolling      Data  05/09/2008   
                                                                          ?  
   Descri  o   Inicializa a Impressao                                         
   Parametros  Objeto do TMS oPrint                                           
                                                                           ? 
                                                                              
                                                                              
/*/
Static Function MNTRBASImp(oPrint,nRecOs,aMATOS)

	Local xQuery  := ""
	Local aArInsu := {}, aArInsR := {}
	Local cTRB, aCampos
	Local nDiff 	:= 0 // Recebe diferenca de dias mediante a programacao de O.S.
	Local lDesloca 	:= .F. // Se houve alteracao na data inicial e final na programacao
	Local cT5Sequen	:= Space(TAMSX3("T5_SEQUENC")[1])
	Local oTmpTbl
	Local lMNTR675G	:= ExistBlock("MNTR675G")

	Private m_pag := 0,nLin := 0
	//Tabela Temporaria
	Private cTRBSTJ := GetNextAlias()

	Default nRecOs := 0

	If nRecOs == 0
		xQuery += "SELECT TJ_FILIAL,TJ_ORDEM,TJ_PLANO,TJ_TIPOOS,TJ_CODBEM,TJ_SERVICO,TJ_SEQRELA "
		xQuery += "FROM "+RetSqlName("STJ")+" TJ "
		xQuery += "WHERE TJ_ORDEM   >= '"+MV_PAR05+"' "
		xQuery += "  AND TJ_ORDEM   <= '"+MV_PAR06+"' "
		xQuery += "  AND TJ_CODBEM  >= '"+MV_PAR03+"' "
		xQuery += "  AND TJ_CODBEM  <= '"+MV_PAR04+"' "
		xQuery += "  AND TJ_PLANO   >= '"+MV_PAR01+"' "
		xQuery += "  AND TJ_PLANO   <= '"+MV_PAR02+"' "
		If !IsInCallStack("MNTA990")
			xQuery += "  AND TJ_DTMPINI >= '"+Dtos(MV_PAR07)+"' "
			xQuery += "  AND TJ_DTMPINI <= '"+Dtos(MV_PAR08)+"' "
		EndIf
		xQuery += "  AND (TJ_TIPOOS   = 'B' OR TJ_TIPOOS = 'L')"
		//xQuery += "  AND TJ_TERMINO  = 'N' "
		If MV_PAR10 == 1
			xQuery += "  AND TJ_SITUACA  = 'L' "
		EndIf
		If MV_PAR10 == 2
			xQuery += "  AND TJ_SITUACA  = 'P' "
		EndIf
		If MV_PAR10 == 3
			xQuery += "  AND TJ_SITUACA  <> 'C' "
		EndIf
		xQuery += "  AND TJ_FILIAL   = '"+STJ->(xFilial("STJ"))+"' "
		xQuery += "  AND TJ.D_E_L_E_T_ <> '*' "
		xQuery += "ORDER BY TJ_ORDEM "
	EndIf

	If (Select(cTRBSTJ) <> 0)
		(cTRBSTJ)->(dbSelectArea(cTRBSTJ))
		(cTRBSTJ)->(dbCloseArea())
	EndIf

	If nRecOs == 0
		xQuery := ChangeQuery(xQuery)
		TCQuery xQuery NEW ALIAS (cTRBSTJ)
	Else
		dbSelectArea("STJ")
		dbGoTo(nRecOS)
		aCampos  := {}
		aAdd(aCAMPOS,{"TJ_FILIAL" ,"C",02,0})
		aAdd(aCAMPOS,{"TJ_ORDEM"  ,"C",06,0})
		aAdd(aCAMPOS,{"TJ_PLANO"  ,"C",06,0})
		aAdd(aCAMPOS,{"TJ_TIPOOS" ,"C",01,0})
		aAdd(aCAMPOS,{"TJ_CODBEM" ,"C",06,0})
		aAdd(aCAMPOS,{"TJ_SERVICO","C",06,0})
		aAdd(aCAMPOS,{"TJ_SEQRELA","C",03,0})

		//Instancia classe FWTemporaryTable (TABELA 2)
		oTmpTbl  := FWTemporaryTable():New( cTRBSTJ, aCampos )
		//Cria indices
		oTmpTbl:AddIndex( "Ind01" , {"TJ_ORDEM"}  )
		//Cria a tabela temporaria
		oTmpTbl:Create()

		dbSelectArea(cTRBSTJ)
		(cTRBSTJ)->(DbAppend())
		(cTRBSTJ)->TJ_FILIAL  := STJ->TJ_FILIAL
		(cTRBSTJ)->TJ_ORDEM   := STJ->TJ_ORDEM
		(cTRBSTJ)->TJ_PLANO   := STJ->TJ_PLANO
		(cTRBSTJ)->TJ_TIPOOS  := STJ->TJ_TIPOOS
		(cTRBSTJ)->TJ_CODBEM  := STJ->TJ_CODBEM
		(cTRBSTJ)->TJ_SERVICO := STJ->TJ_SERVICO
		(cTRBSTJ)->TJ_SEQRELA := STJ->TJ_SEQRELA
	EndIf

	(cTRBSTJ)->(dbGotop())
	ProcRegua(LastRec())
	While !(cTRBSTJ)->(EoF())
		IncProc()
		dbSelectArea("STJ")
		dbSetOrder(1)
		If dbSeek(xFilial("STJ")+(cTRBSTJ)->TJ_ORDEM+(cTRBSTJ)->TJ_PLANO)
			If aMATOS <> Nil
				nPosOs := aSCAN(aMATOS, {|x| x[1]+x[2] == (cTRBSTJ)->TJ_PLANO+(cTRBSTJ)->TJ_ORDEM})

				If nPosOs > 0
					m_pag   := 0
					Lin     := 4000
					aArInsu := {}
					aArInsR := {}

					If IsInCallStack("MNTA990") // Se for chamado na rotina de programacao de OS
						If Len(aMATOS[nPosOs]) >= 3
							nDiff := aMATOS[nPosOs,3] //Indica a quantidade de dias que as datas da OS ser o deslocadas
							MNTRSIMCAB(,,,nDiff) // CABECALHO, com o parametro da diferen a em dias
							lDesloca := .T. // Se houve alteracao na data inicial e final na programacaoc
						Else
							MNTRSIMCAB() // CABECALHO
						EndIf
					Else
						MNTRSIMCAB() // CABECALHO
					EndIf

					If !Empty(ST9->T9_LOCAL)
						Lin += 90
					EndIf

					If Lin > 455
				  		oPrint:Say(Lin+85,nHorz+20,STR0019+"..: ",oFontMN)
			  		Else
			  	  		oPrint:Say(Lin-85,nHorz+20,STR0019+"..: ",oFontMN)
			  		EndIf

					MNTRSIMMEM()
					MNTRSIMCAB()

					oPrint:Line(Lin,nHorz+0010,Lin,nHorz+2335)

					dbSelectArea("STL")
					dbSetOrder(1)
					If dbSeek(xFilial("STL")+(cTRBSTJ)->TJ_ORDEM+(cTRBSTJ)->TJ_PLANO)
						While !EoF() .And. STL->TL_FILIAL = xFILIAL('STL') .And. STL->TL_ORDEM = STJ->TJ_ORDEM;
						.And. STL->TL_PLANO = STJ->TJ_PLANO

							//TESTE
							If STL->TL_TIPOREG <> "P"
								vVETHORAS := NGTQUATINS(STL->TL_CODIGO,STL->TL_TIPOREG,STL->TL_USACALE,;
								STL->TL_QUANTID,STL->TL_TIPOHOR,STL->TL_DTINICI,;
								STL->TL_HOINICI,STL->TL_DTFIM,STL->TL_HOFIM,STL->TL_UNIDADE)
								nQTDIns := NGRHODSEXN(vVETHORAS[1],"D")
							Else
								nQTDIns := STL->TL_QUANTID
							EndIf
							//FIM TESTE

							If Alltrim(STL->TL_SEQRELA) = '0'
								aAdd(aArInsu,{stl->tl_tarefa,stl->tl_tiporeg,stl->tl_codigo,;
								stl->tl_quanrec,nQTDIns,stl->tl_unidade,;
								stl->tl_dtinici,stl->tl_hoinici,stl->tl_dtfim,;
								stl->tl_hofim})
							Else
								aAdd(aArInsR,{stl->tl_tarefa,stl->tl_tiporeg,stl->tl_codigo,;
								stl->tl_quanrec,nQTDIns,stl->tl_unidade,;
								stl->tl_dtinici,stl->tl_hoinici,stl->tl_dtfim,;
								stl->tl_hofim})
							EndIf
							dbSkip()
						End
					EndIf

					nReal := 2
					If Len(aArInsu) >=  Len(aArInsR)
						nReal := Len(aArInsu) + 2
					Else
						nReal := Len(aArInsR) + 2
					EndIf

					If lDesloca // Se houve alteracao na data inicial e final na programacao.
						MNTRSIMITL(STR0020,If(Len(aArInsu) == 0,1,Len(aArInsu)),aArInsu, nDiff) // Passa o quarto parametro da diferenca de dias - Insumos Previstos
					Else // Se a data nao foi alterada
						MNTRSIMITL(STR0020,If(Len(aArInsu) == 0,1,Len(aArInsu)),aArInsu)  // Nao passa a diferenca de dias - Insumos Previstos
					EndIf
					MNTRSIMITL(STR0021,nReal,aArInsR)  // Insumos Reportados

					MNTRSIMCAB(100)

					oPrint:Say(Lin,nHorz+100,STR0039,oFontMN)
					MNTRSIMCAB()
					oPrint:Say(Lin,nHorz+100,STR0040,oFontMN)
				EndIf
			Else
				Lin     := 4000
				aArInsu := {}
				aArInsR := {}

				MNTRSIMCAB() // CABECALHO

				If !Empty(ST9->T9_LOCAL)
					Lin += 45
				EndIf
				If Lin > 455
			  		oPrint:Say(Lin+85,nHorz+20,STR0019+"..: ",oFontMN)
		 		Else
			  		oPrint:Say(Lin-85,nHorz+20,STR0019+"..: ",oFontMN)
		  		EndIf
				MNTRSIMMEM()
				MNTRSIMCAB()

				oPrint:Line(Lin,nHorz+0010,Lin,nHorz+2335)

				dbSelectArea("STL")
				dbSetOrder(1)
				If dbSeek(xFilial("STL")+(cTRBSTJ)->TJ_ORDEM+(cTRBSTJ)->TJ_PLANO)
					While !EoF() .And. STL->TL_FILIAL = xFILIAL('STL') .And. STL->TL_ORDEM = STJ->TJ_ORDEM;
					.And. STL->TL_PLANO = STJ->TJ_PLANO

						dbSelectArea("ST5")
						dbSetOrder(1)
						If dbSeek(xFilial("ST5")+STJ->TJ_CODBEM+STJ->TJ_SERVICO+STJ->TJ_SEQRELA+STL->TL_TAREFA)
							cT5Sequen := cValToChar(STRZERO(T5_SEQUENC,TAMSX3("T5_SEQUENC")[1]))
						EndIf

						//TESTE
						If STL->TL_TIPOREG <> "P"
							vVETHORAS := NGTQUATINS(STL->TL_CODIGO,STL->TL_TIPOREG,STL->TL_USACALE,;
							STL->TL_QUANTID,STL->TL_TIPOHOR,STL->TL_DTINICI,;
							STL->TL_HOINICI,STL->TL_DTFIM,STL->TL_HOFIM,STL->TL_UNIDADE)
							nQTDIns := NGRHODSEXN(vVETHORAS[1],"D")
						Else
							nQTDIns := STL->TL_QUANTID
						EndIf
						//FIM TESTE

						If Alltrim(STL->TL_SEQRELA) = '0'
							aAdd(aArInsu,{stl->tl_tarefa,stl->tl_tiporeg,stl->tl_codigo,;
							stl->tl_quanrec,nQTDIns,stl->tl_unidade,;
							stl->tl_dtinici,stl->tl_hoinici,stl->tl_dtfim,;
							stl->tl_hofim,cT5Sequen})
						Else
							aAdd(aArInsR,{stl->tl_tarefa,stl->tl_tiporeg,stl->tl_codigo,;
							stl->tl_quanrec,nQTDIns,stl->tl_unidade,;
							stl->tl_dtinici,stl->tl_hoinici,stl->tl_dtfim,;
							stl->tl_hofim,cT5Sequen})
						EndIf

						dbSelectArea("STL")
						dbSkip()
					EndDo
				EndIf

				nReal := 2
				If Len(aArInsu) >=  Len(aArInsR)
					nReal := Len(aArInsu) + 2
				Else
					nReal := Len(aArInsR) + 2
				EndIf

				MNTRSIMITL(STR0020,If(Len(aArInsu) == 0,1,Len(aArInsu)),aArInsu)
				MNTRSIMITL(STR0021,nReal,aArInsR)

				MNTRSIMCAB(100)

				oPrint:Say(Lin,nHorz+100,STR0039,oFontMN)
				MNTRSIMCAB()
				oPrint:Say(Lin,nHorz+100,STR0040,oFontMN)

				If lMNTR675G //Par metro {2} indica que o relat rio   do MNTR676
					ExecBlock("MNTR675G",.F.,.F.,{2})
				EndIf

			EndIf
		EndIf

		oPrint:EndPage()
		dbSelectArea(cTRBSTJ)
		dbSkip()

	End
	oPrint:Preview()
	dbSelectArea(cTRBSTJ)
	dbCloseArea()

	If nRecOs <> 0
		oTmpTbl:Delete()
	EndIf

	dbSelectArea("STJ")

Return
/*
                                                                             
                                                                             
                                                                         ?  
   Programa   MNT676SX1  Autor   Roger Rodrigues       Data    16/12/10      
                                                                         ?  
   Desc.      Faz criacao do SX1 do relatorio                                
                                                                             
                                                                         ?  
   Uso        MNTR676                                                        
                                                                         ?  
                                                                             
                                                                             
*/
User Function xMNT676SX1( cPerg ) // alterado Tony

	Local aPerg := {}
	Local aArea := GetArea()

	//-----------------------------------------------------------------------
	// Houve corre  es no fonte, e essa fun  o serve para deletar do dicion rio
	// o grupo de perguntas MNT676 caso este esteja errado
	// Importante: caso seja aumentado o n mero de perguntas desse relat rio,
	//   necess rio alterar essa fun  o para que considere os novos registros,
	// pois ela toma como base 10 perguntas para identificar se o dicion rio
	// est  incorreto ou n o.
	//-----------------------------------------------------------------------
	MNT676VERERR()

	dbSelectArea("SX1")
	dbSetOrder(1)

	//Pergunta "De plano de manuten  o ?"
	If !dbSeek(cPerg+Space(Len(SX1->X1_GRUPO)-Len(cPerg))+"01") .Or. SX1->X1_PERGUNT <> STR0058
		If NGSX1ORDEM("01",2,"MNT676")
			RecLock("SX1",.T.)
			SX1->X1_GRUPO   := cPerg
			SX1->X1_ORDEM   := "01"
			SX1->X1_PERGUNT := STR0058 // "De plano de manuten  o ?"
			SX1->X1_PERSPA  := STR0058 // "De plano de manuten  o ?"
			SX1->X1_PERENG  := STR0058 // "De plano de manuten  o ?"
			SX1->X1_VARIAVL := "MV_CH1"
			SX1->X1_TIPO    := "C"
			SX1->X1_TAMANHO := 06
			SX1->X1_GSC     := "G"
			SX1->X1_VALID   := "If(empty(mv_par01),.T.,ExistCpo('STI',mv_par01))"
			SX1->X1_VAR01   := "MV_PAR01"
			SX1->X1_CNT01   := ""
			SX1->X1_F3      := "STI"
			SX1->X1_PYME    := "N"
			MsUnLock("SX1")
			NgHelp("."+cPerg+Space(Len(SX1->X1_GRUPO)-Len(cPerg))+"01.",STR0061,.T.) //"Informe a partir de qual Plano de Manuten  o deve constar no relat rio. Pressione a tecla [F3]+[Enter] para selecionar um Plano de Manuten  o ou deixe em branco para selecionar a partir do primeiro disponivel."
		EndIf
	EndIf

	//Pergunta "At  plano de manuten  o ?"
	If !dbSeek( cPerg + Space( Len(SX1->X1_GRUPO) - Len(cPerg) ) + '02' ) .Or. SX1->X1_PERGUNT <> STR0059
		RecLock("SX1",.T.)
		SX1->X1_GRUPO   := cPerg
		SX1->X1_ORDEM   := "02"
		SX1->X1_PERGUNT := STR0059 // "At  plano de manuten  o ?"
		SX1->X1_PERSPA  := STR0059 // "At  plano de manuten  o ?"
		SX1->X1_PERENG  := STR0059 // "At  plano de manuten  o ?"
		SX1->X1_VARIAVL := "MV_CH2"
		SX1->X1_TIPO    := "C"
		SX1->X1_TAMANHO := 06
		SX1->X1_GSC     := "G"
		SX1->X1_VALID   := "If(atecodigo('STI',mv_par01,mv_par02),.T.,.F.)"
		SX1->X1_VAR01   := "MV_PAR02"
		SX1->X1_CNT01   := "ZZZZZZ"
		SX1->X1_F3      := "STI"
		SX1->X1_PYME    := "N"
		MsUnLock("SX1")
		NgHelp("."+cPerg+Space(Len(SX1->X1_GRUPO)-Len(cPerg))+"02.",STR0062,.T.) //"Informe at  qual Plano de Manuten  o deve constar no relat rio. Pressione a tecla [F3] para selecionar um Plano de Manuten  o ou digite ZZZZZZ neste campo e o acima em branco para considerar todos os Planos de Manuten  o."
	EndIf

	If !Dbseek(cPerg+Space(Len(SX1->X1_GRUPO)-Len(cPerg))+"03")
		aAdd(aPerg,{STR0003,"C",16,0,"If(empty(mv_par03),.T.,ExistCpo('ST9',mv_par03))"  ,"ST9","G","","","","","","",STR0003,STR0003}) //"De Bem?"
		aAdd(aPerg,{STR0004,"C",16,0,"If(atecodigo('ST9',mv_par03,mv_par04,16),.T.,.F.)" ,"ST9","G","","","","","","",STR0004,STR0004}) //"At  Bem?"
		aAdd(aPerg,{STR0005,"C",06,0,"If(empty(mv_par05),.T.,ExistCpo('STJ',mv_par05))"  ,"STJ","G","","","","","","",STR0005,STR0005}) //"De Ordem?"
		aAdd(aPerg,{STR0006,"C",06,0,"If(atecodigo('STJ',mv_par05,mv_par06,6),.T.,.F.)"  ,"STJ","G","","","","","","",STR0006,STR0006}) //"At  Ordem?"
		aAdd(aPerg,{STR0007,"D",08,0,"naovazio()"                                        ,""   ,"G","","","","","","",STR0007,STR0007}) //"De Data?"
		aAdd(aPerg,{STR0008,"D",08,0,"(mv_par08 >= mv_par07)"                            ,""   ,"G","","","","","","",STR0008,STR0008}) //"At  Data?"
		//----------------------------------------------------
		// O  ltimo par metro = .T., indica que se est  apenas
		// criando perguntas para um grupo j  existente,
		// e n o criando um grupo 'do zero'
		//----------------------------------------------------
		NgChkSx1(cPerg,aPerg,.T.)
	EndIf

	If dbSeek(cPerg+Space(Len(SX1->X1_GRUPO)-Len(cPerg))+"03") .And. SX1->X1_PERGUNT <> STR0003 //"De Bem?"
		RecLock("SX1",.F.)
		SX1->X1_PERGUNT := STR0003
		SX1->X1_PERSPA  := STR0003
		SX1->X1_PERENG  := STR0003
		MsUnLock("SX1")
	EndIf

	If dbSeek(cPerg+Space(Len(SX1->X1_GRUPO)-Len(cPerg))+"04") .And. SX1->X1_PERGUNT <> STR0004 //"At  Bem?"
		RecLock("SX1",.F.)
		SX1->X1_PERGUNT := STR0004
		SX1->X1_PERSPA  := STR0004
		SX1->X1_PERENG  := STR0004
		MsUnLock("SX1")
	EndIf

	If dbSeek(cPerg+Space(Len(SX1->X1_GRUPO)-Len(cPerg))+"05") .And. SX1->X1_PERGUNT <> STR0005 //"De Ordem?"
		RecLock("SX1",.F.)
		SX1->X1_PERGUNT := STR0005
		SX1->X1_PERSPA  := STR0005
		SX1->X1_PERENG  := STR0005
		MsUnLock("SX1")
	EndIf

	If dbSeek(cPerg+Space(Len(SX1->X1_GRUPO)-Len(cPerg))+"06") .And. SX1->X1_PERGUNT <> STR0006 //"At  Ordem?"
		RecLock("SX1",.F.)
		SX1->X1_PERGUNT := STR0006
		SX1->X1_PERSPA  := STR0006
		SX1->X1_PERENG  := STR0006
		MsUnLock("SX1")
	EndIf

	If dbSeek(cPerg+Space(Len(SX1->X1_GRUPO)-Len(cPerg))+"07") .And. SX1->X1_PERGUNT <> STR0007 //"De Data?"
		RecLock("SX1",.F.)
		SX1->X1_PERGUNT := STR0007
		SX1->X1_PERSPA  := STR0007
		SX1->X1_PERENG  := STR0007
		MsUnLock("SX1")
	EndIf

	If dbSeek(cPerg+Space(Len(SX1->X1_GRUPO)-Len(cPerg))+"08") .And. SX1->X1_PERGUNT <> STR0008 //"At  Data?"
		RecLock("SX1",.F.)
		SX1->X1_PERGUNT := STR0008
		SX1->X1_PERSPA  := STR0008
		SX1->X1_PERENG  := STR0008
		MsUnLock("SX1")
	EndIf

	//Pergunta "Imprimir Localiza  o ?"
	If !dbSeek(cPerg+Space(Len(SX1->X1_GRUPO)-Len(cPerg))+"09")
		RecLock("SX1",.T.)
		SX1->X1_GRUPO   := cPerg
		SX1->X1_ORDEM   := "09"
		SX1->X1_PERGUNT := STR0063
		SX1->X1_PERSPA  := STR0063
		SX1->X1_PERENG  := STR0063
		SX1->X1_VARIAVL := "MV_CH9"
		SX1->X1_TIPO    := "N"
		SX1->X1_TAMANHO := 01
		SX1->X1_PRESEL  := 0
		SX1->X1_GSC     := "C"
		SX1->X1_VALID   := "naovazio()"
		SX1->X1_DEF01   := "Sim"
		SX1->X1_DEFSPA1 := "Si"
		SX1->X1_DEFENG1 := "Yes"
		SX1->X1_DEF02   := "Nao"
		SX1->X1_DEFSPA2 := "No"
		SX1->X1_DEFENG2 := "No"
		SX1->X1_VAR01   := "MV_PAR09"
		SX1->X1_PYME    := "N"
		SX1->X1_HELP    := ".MNT67609."
		MsUnLock("SX1")
		NgHelp("."+cPerg+Space(Len(SX1->X1_GRUPO)-Len(cPerg))+"09.",STR0064+chr(13)+chr(10)+"- Sim"+chr(10)+"- N o",.T.) //STR0064: "Informe se deve imprimir a localiza  o:"
	Else

		If SX1->X1_HELP <> "."+cPerg+Space(Len(SX1->X1_GRUPO)-Len(cPerg))+"09."
			NgHelp("."+cPerg+Space(Len(SX1->X1_GRUPO)-Len(cPerg))+"09.",STR0064+chr(13)+chr(10)+"- Sim"+chr(10)+"- N o",.T.) //STR0064: "Informe se deve imprimir a localiza  o:"
		EndIf

	EndIf

	//Pergunta "Imprimir O.S. ?"
	If !dbSeek(cPerg+Space(Len(SX1->X1_GRUPO)-Len(cPerg))+"10")
		RecLock("SX1",.T.)
		SX1->X1_GRUPO   := cPerg
		SX1->X1_ORDEM   := "10"
		SX1->X1_PERGUNT := STR0060
		SX1->X1_PERSPA  := STR0060
		SX1->X1_PERENG  := STR0060
		SX1->X1_VARIAVL := "MV_CHA"
		SX1->X1_TIPO    := "N"
		SX1->X1_TAMANHO := 01
		SX1->X1_PRESEL  := 3
		SX1->X1_GSC     := "C"
		SX1->X1_VALID   := "naovazio()"
		SX1->X1_DEF01   := STR0065 //"Liberada"
		SX1->X1_DEFSPA1 := STR0065
		SX1->X1_DEFENG1 := STR0065
		SX1->X1_DEF02   := STR0066 //"Pendente"
		SX1->X1_DEFSPA2 := STR0066
		SX1->X1_DEFENG2 := STR0066
		SX1->X1_DEF03   := STR0067 //"Todas"
		SX1->X1_DEFSPA3 := STR0067
		SX1->X1_DEFENG3 := STR0067
		SX1->X1_VAR01   := "MV_PAR10"
		SX1->X1_PYME    := "N"
		SX1->X1_HELP    := ".MNT67610."
		MsUnLock("SX1")
		NgHelp("."+cPerg+Space(Len(SX1->X1_GRUPO)-Len(cPerg))+"10.",STR0068+chr(13)+chr(10)+"- "+STR0065+chr(10)+"- "+STR0066+chr(10)+"- "+STR0067,.T.)
	EndIf

	NgHelp('.'+cPerg+Space(Len(SX1->X1_GRUPO)-Len(cPerg))+"03"+'.',STR0069,.T.) //"Informe a partir de qual Bem deve constar no relat rio. Pressione a tecla [F3] para selecionar um Bem."
	NgHelp('.'+cPerg+Space(Len(SX1->X1_GRUPO)-Len(cPerg))+"04"+'.',STR0070,.T.) //"Informe at  qual Bem deve constar no relat rio. Pressione a tecla [F3] para selecionar um Bem ou digite ZZZZZZ neste campo e o acima em branco para considerar todos os Bens."
	NgHelp('.'+cPerg+Space(Len(SX1->X1_GRUPO)-Len(cPerg))+"05"+'.',STR0071,.T.) //"Informe a partir de qual Ordem de Servi o deve constar no relat rio. Pressione a tecla [F3] para selecionar uma Ordem de Servi o."
	NgHelp('.'+cPerg+Space(Len(SX1->X1_GRUPO)-Len(cPerg))+"06"+'.',STR0072,.T.) //"Informe at  qual Ordem de Servi o deve constar no relat rio. Pressione a tecla [F3] para selecionar a Ordem de Servi o desejada ou digite ZZZZZZ neste campo e o acima em branco para considerar todas as Ordens de Servi o."
	NgHelp('.'+cPerg+Space(Len(SX1->X1_GRUPO)-Len(cPerg))+"07"+'.',STR0073,.T.) //"Informe um determinado per odo de data in cio da Ordem de Servi o."
	NgHelp('.'+cPerg+Space(Len(SX1->X1_GRUPO)-Len(cPerg))+"08"+'.',STR0074,.T.) //"Informe um determinado per odo de data fim da Ordem de Servi o."

	RestArea(aArea)

Return .T.

//---------------------------------------------------------------------
/*/{Protheus.doc} MNT676VERERR
Deleta grupo MNT676 caso n o esteja correto.
(Condi  o: caso n o tenha 10 perguntas ou caso n o possua as perguntas 07
ou 08)

@author Andr  Felipe Joriatti
@since 09/10/2012
@version MP11
@parametros Nenhum
@return Nil
/*/
//---------------------------------------------------------------------
Static Function MNT676VERERR()

	Local nContSX1 := 0
	//Vari veis para armazenar o X1_TIPO da pergunta.
	Local cX1Tipo7  := "", cX1Tipo8 := ""

	dbSelectArea("SX1")
	dbSetOrder(1)
	If dbSeek("MNT676")

		While !EoF() .And. AllTrim( SX1->X1_GRUPO ) == "MNT676"
			nContSX1++
			dbSelectArea("SX1")
			dbSkip()
		EndDo
		// Verifica se existe a pergunta e adiciona o X1_TIPO dela na vari vel respons vel.
		If dbSeek("MNT676"+Space(Len(SX1->X1_GRUPO)-Len("MNT676"))+"07")
			cX1Tipo7 := SX1->X1_TIPO
		Endif
		If dbSeek("MNT676"+Space(Len(SX1->X1_GRUPO)-Len("MNT676"))+"08")
			cX1Tipo8 := SX1->X1_TIPO
		Endif

		dbSeek("MNT676")
		If nContSX1 != 10 .Or. !dbSeek("MNT676"+Space(Len(SX1->X1_GRUPO)-Len("MNT676"))+"07") .Or. !dbSeek("MNT676"+Space(Len(SX1->X1_GRUPO)-Len("MNT676"))+"08");
		.Or. cX1Tipo7 != "D" .Or. cX1Tipo8 != "D"
			dbSeek("MNT676")
			While !EoF() .And. AllTrim( SX1->X1_GRUPO ) == "MNT676"

				RecLock("SX1",.F.)
				DbDelete()
				MsUnlock("SX1")

				dbSelectArea("SX1")
				dbSkip()
			EndDo
		EndIf

	EndIf
Return
//---------------------------------------------------------------------
/*/{Protheus.doc} MNTRMOTATR
Impressao Motivos de Atrasos
@author Hamilton Soldati
@since 15/01/2015
@version MP11
@parametros Nenhum
@return Nil
/*/
//---------------------------------------------------------------------
Static Function MNTRMOTATR()
	Local nF1 := 1

	MNTRSIM4CA()
	MNTRMTVER()

	MNTRMTVER()
	MNTRSIMCAB()
	oPrint:Line(Lin,nHorz+0010,Lin,nHorz+2335)

	dbSelectArea("TPL")
	dbSetOrder(1)
	If dbSeek(xFilial("TPL")+(cTRBSTJ)->TJ_ORDEM)
		While !EoF() .And. TPL->TPL_FILIAL = xFILIAL('TPL') .And. TPL->TPL_ORDEM = STJ->TJ_ORDEM

			cDescAtr := MNTRDSCATR(TPL->TPL_CODMOT)

			oPrint:Say(Lin,nHorz+0010,TPL->TPL_CODMOT,oFontPN)       // C digo
			oPrint:Say(Lin,nHorz+0180,cDescAtr,oFontPN)              // Descri  o
			oPrint:Say(Lin,nHorz+1060,dToC(TPL->TPL_DTINIC),oFontPN) // data inicio
			oPrint:Say(Lin,nHorz+1330,TPL->TPL_HOINIC,oFontPN)       // hora inicio
			oPrint:Say(Lin,nHorz+1610,dToC(TPL->TPL_DTFIM),oFontPN)  // data fim
			oPrint:Say(Lin,nHorz+1840,TPL->TPL_HOFIM,oFontPN)        // hora fim
			MNTRMTVER()
			MNTRSIMCAB()
			oPrint:Line(Lin,nHorz+0010,Lin,nHorz+2335)

			dbSkip()
		EndDo
	EndIf

	For nF1 := 1 to 3
		MNTRMTVER()
		MNTRSIMCAB()
		oPrint:Line(Lin,nHorz+0010,Lin,nHorz+2335)
	Next nF1

Return
//---------------------------------------------------------------------
/*/{Protheus.doc} MNTRSIM4CA
Cabecalho dos motivos de atraso
@author Hamilton Soldati
@since 15/01/2015
@version MP11
@parametros Nenhum
@return Nil
/*/
//---------------------------------------------------------------------
Static Function MNTRSIM4CA()

	MNTRSIMCAB()
	oPrint:Say(Lin,nHorz+0010,STR0075,oFontGN)
	MNTRSIMCAB(80)
	oPrint:Line(Lin,nHorz+0010,Lin,nHorz+2335)
	MNTRSIMCAB(20)
	cTitSX3 := 'sx3->x3_titulo'
	#IFDEF SPANISH
	cTitSX3 := 'sx3->x3_titspa'
	#ELSE
	#IFDEF ENGLISH
	cTitSX3 := 'sx3->x3_titeng'
	#ENDIF
	#ENDIF
	oPrint:Say(Lin,nHorz+0010,NGSEEKDIC("SX3","TPL_CODMOT",2,cTitSX3),oFontMN)
	oPrint:Say(Lin,nHorz+0180,NGSEEKDIC("SX3","TPL_DESMOT",2,cTitSX3),oFontMN)
	oPrint:Say(Lin,nHorz+1060,STR0027,oFontMN)
	oPrint:Say(Lin,nHorz+1330,STR0028,oFontMN)
	oPrint:Say(Lin,nHorz+1610,STR0029,oFontMN)
	oPrint:Say(Lin,nHorz+1840,STR0030,oFontMN)

Return

//---------------------------------------------------------------------
/*/{Protheus.doc} MNTRMTVER
Impressao das linhas verticais para Motivo de Atraso
@author Hamilton Soldati
@since 15/01/2015
@version MP11
@parametros Nenhum
@return Nil
/*/
//---------------------------------------------------------------------
Static Function MNTRMTVER()

	oPrint:Line(Lin-20,nHorz+0170,Lin+45,nHorz+0170)
	oPrint:Line(Lin-20,nHorz+1050,Lin+45,nHorz+1050)
	oPrint:Line(Lin-20,nHorz+1320,Lin+45,nHorz+1320)
	oPrint:Line(Lin-20,nHorz+1600,Lin+45,nHorz+1600)
	oPrint:Line(Lin-20,nHorz+1830,Lin+45,nHorz+1830)

Return

//---------------------------------------------------------------------
/*/{Protheus.doc} MNTROCOR
Impressao OCORRECIA X CAUSA X SOLUCAO
@author Hamilton Soldati
@since 15/01/2015
@version MP11
@parametros Nenhum
@return Nil
/*/
//---------------------------------------------------------------------
Static Function MNTROCOR()
	MNTRSIM5CA()
	MNTRSIMCAB()
Return
//---------------------------------------------------------------------
/*/{Protheus.doc} MNTRSIM5CA
Cabecalho do Prob x Causa x Solucao
@author Hamilton Soldati
@since 15/01/2015
@version MP11
@parametros Nenhum
@return Nil
/*/
//---------------------------------------------------------------------
Static Function MNTRSIM5CA()

	Local nF1 := 1

	//Inicio Cabe alho do Prob x Causa x Solucao
	MNTRSIMCAB()
	oPrint:Say(Lin,nHorz+0010,STR0076,oFontGN)
	MNTRSIMCAB(80)
	//Fim Cabe alho do Prob x Causa x Solucao

	//Inicio Prob x Causa x Solucao gerado no sistema.
	dbSelectArea("STN")
	dbSetOrder(1)
	If dbSeek(xFilial("STN")+(cTRBSTJ)->TJ_ORDEM+(cTRBSTJ)->TJ_PLANO)
		While !EoF() .And. STN->TN_FILIAL = xFILIAL('STN') .And. STN->TN_ORDEM = STJ->TJ_ORDEM .And. STN->TN_PLANO = STJ->TJ_PLANO

			cDescOco := MNTRDSCCPS(STN->TN_CODOCOR,'P')
			cDescCau := MNTRDSCCPS(STN->TN_CAUSA,'C')
			cDescSol := MNTRDSCCPS(STN->TN_SOLUCAO,'S')

			oPrint:Line(Lin,nHorz+0010,Lin,nHorz+2335)
			oPrint:Say(Lin,nHorz+0020,STR0077, oFontMN)
			oPrint:Say(Lin,nHorz+0420,cDescOco,oFontPN) // Ocorr ncia
			MNTRSIMCAB()
			MNTROCORVER()
			oPrint:Line(Lin,nHorz+0010,Lin,nHorz+2335)
			oPrint:Say(Lin,nHorz+0020,STR0078, oFontMN)
			oPrint:Say(Lin,nHorz+0420,cDescCau,oFontPN) // Causa
			MNTRSIMCAB()
			MNTROCORVER()
			oPrint:Line(Lin,nHorz+0010,Lin,nHorz+2335)
			oPrint:Say( Lin, nHorz+20,STR0079, oFontMN)
			oPrint:Say(Lin,nHorz+0420,cDescSol,oFontPN) // Solu  o
			MNTRSIMCAB()
			MNTROCORVER()
			oPrint:Line(Lin,nHorz+0010,Lin,nHorz+2335)

			dbSkip()
		EndDo
	EndIf
	//Fim Prob x Causa x Solucao gerado no sistema.

	//Inicio Prob x Causa x Solucao em branco.
	For nF1 := 1 to 2
		oPrint:Line(Lin,nHorz+0010,Lin,nHorz+2335)

		If nF1 == 1
			MNTRSIMCAB(120)
		Else
			MNTRSIMCAB(80)
		EndIf

		oPrint:Line(Lin,nHorz+0010,Lin,nHorz+2335)
		oPrint:Say( Lin, nHorz+20, STR0077, oFontMN )
		MNTRSIMCAB()
		MNTROCORVER()
		oPrint:Line(Lin,nHorz+0010,Lin,nHorz+2335)
		oPrint:Say( Lin, nHorz+20, STR0078, oFontMN )
		MNTRSIMCAB()
		MNTROCORVER()
		oPrint:Line(Lin,nHorz+0010,Lin,nHorz+2335)
		oPrint:Say( Lin, nHorz+20,STR0079, oFontMN )
		MNTRSIMCAB()
		MNTROCORVER()
		oPrint:Line(Lin,nHorz+0010,Lin,nHorz+2335)
	Next nF1
	//Fim Prob x Causa x Solucao em branco.

Return
//---------------------------------------------------------------------
/*/{Protheus.doc} MNTROCORVER
Impressao das linhas verticais para ProcxCauxSol
@author Hamilton Soldati
@since 15/01/2015
@version MP11
@parametros Nenhum
@return Nil
/*/
//---------------------------------------------------------------------
Static Function MNTROCORVER()
	oPrint:Line(Lin-45,nHorz+405 ,Lin,nHorz+405)
Return

//---------------------------------------------------------------------//
/*/{Protheus.doc} MNTRDSCATR
Busca a descri  o da motivo de Atraso.
@author Maicon Andr  Pinheiro
@since 21/01/2016
@version MP11
@parametros Nenhum
@return cDescri
/*/
//---------------------------------------------------------------------//
Static Function MNTRDSCATR(cCodigo)

	dbSelectArea( "TPJ" )
	dbSetOrder( 1 )
	dbSeek( xFilial ("TPJ")+cCodigo)

	cDescri := TPJ->TPJ_DESMOT

	dbSelectArea( "TPL" )
	dbSetOrder( 1 )

Return cDescri

//---------------------------------------------------------------------//
/*/{Protheus.doc} MNTRDSCCPS
Busca a descri  o CausaXProblemaXSolu  o

@author Maicon Andr  Pinheiro
@since 21/01/2016
@version MP11
@parametros Nenhum
@return cDescri
/*/
//---------------------------------------------------------------------//

Static Function MNTRDSCCPS(cCodigo,cTipo)

	Local cDescri := ''

	dbSelectArea( "ST8" )
	dbSetOrder( 1 )
	dbSeek( xFilial ("ST8")+cCodigo+cTipo)

	If !Empty(ST8->T8_NOME)
		cDescri := Alltrim(cCodigo)+" - "+ST8->T8_NOME
	EndIf

	dbSelectArea( "TPL" )
	dbSetOrder( 1 )

Return cDescri

