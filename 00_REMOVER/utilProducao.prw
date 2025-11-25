#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "FWMVCDEF.CH"
//Para encontrar o fonte Function utilProducao
/*/{Protheus.doc} 
function aStatusOp
Atualiza o status da ordem de produção e tabelas auxiliares.
@type user function
@author Kenny Roger Martins
@since 27/12/2017
@version ALL
@param cNumOp
@return boolean
/*/
User Function ASTATUSOP(cNumOp)

	Local aAreaANT  := GetArea()
	Local aAreaZGH  := ZGH->(GetArea())
	Local aAreaSC2  := SC2->(GetArea())
	Local lRet      := .T.
	Local cStsEncer := ""
	Local cStsApont := ""
	Local cStsOrdem := ""

	// U_TOTVSES()

	//---------------------------------------------------
	// Verifica status do encerramento de produção.
	//---------------------------------------------------

	ErrorBlock( {|e| u_GRChecEr(e)})

	Begin Sequence

		ZGM->(DbSetOrder(1))
		ZGM->(DbSeek(xFilial("ZGM") + cNumOp))

		While ZGM->(!Eof()) .And. ZGM->(ZGM_FILIAL + ZGM_OP) == xFilial("ZGM") + cNumOp

			cStsEncer += If(ZGM->ZGM_STATUS $ cStsEncer, "", ZGM->ZGM_STATUS)

			ZGM->(DbSkip())

		EndDo

		//---------------------------------------------------
		// Verifica status do apontamento de produção.
		//---------------------------------------------------

		ZGH->(DbSetOrder(1))
		ZGH->(DbSeek(xFilial("ZGH") + cNumOp))

		While ZGH->(!Eof()) .And. ZGH->(ZGH_FILIAL + ZGH_OP) == xFilial("ZGH") + cNumOp

			If !Empty(StrTran(ZGH->ZGH_HORINI, ":", "")) .and. Empty(StrTran(ZGH->ZGH_HORFIM, ":", ""))

				RecLock("ZGH", .F.)
				ZGH->ZGH_STATUS := "I"
				ZGH->(MsUnLock())

			ElseIf !Empty(StrTran(ZGH->ZGH_HORINI, ":", "")) .and. !Empty(StrTran(ZGH->ZGH_HORFIM, ":", ""))

				RecLock("ZGH", .F.)
				ZGH->ZGH_STATUS := "E"
				ZGH->(msUnLock())

			Else

				RecLock("ZGH", .F.)
				ZGH->ZGH_STATUS := "P"
				ZGH->(msUnLock())

			EndIf

			cStsApont += If(ZGH->ZGH_STATUS $ cStsApont, "", ZGH->ZGH_STATUS)

			ZGH->(DbSkip())

		EndDo

		//---------------------------------------------------
		// Atualiza o status da ordem de produção.
		//---------------------------------------------------

		// ZGM - ENCERRAMENTO
		// A=Pendente;P=Produzida

		// ZGH - APONTAMENTO
		// P=Prevista;I=Iniciada;E=Encerrada

		// Possíveis situações para SC2 / ZH7
		// P=Prevista; I=Iniciada; A=Apontada; E=Encerrada; S=Encerr.s/Apont.; L=Parcial s/Apont.

		Do Case

		Case  "P" == cStsEncer .And. "E" == cStsApont                        ; cStsOrdem := "E" // Encerrado
		Case                         "E" == cStsApont                        ; cStsOrdem := "A" // Apontada
		Case  Empty(cStsEncer) .And. "P" == cStsApont                        ; cStsOrdem := "P" // Prevista
		Case  "A" == cStsEncer .And. "P" == cStsApont                        ; cStsOrdem := "P" // Prevista
		Case  "A" == cStsEncer .And. Empty(cStsApont)                        ; cStsOrdem := "P" // Prevista
		Case  Empty(cStsEncer) .And. Empty(cStsApont)                        ; cStsOrdem := "P" // Prevista
		Case  "A" == cStsEncer .And. "E" <> cStsApont .And. "I" $  cStsApont ; cStsOrdem := "I" // Iniciado
		Case  "P" == cStsEncer .And. "P" == cStsApont                        ; cStsOrdem := "S" // Encerrado sem apontamento
		Case  "P" == cStsEncer .And. Empty(cStsApont)                        ; cStsOrdem := "S" // Encerrado sem apontamento
		Case  "A" $  cStsEncer .And. "P" $  cStsEncer .And. "P" == cStsApont ; cStsOrdem := "L" // Encerrado parcial sem apontamento
		Case  "A" $  cStsEncer .And. "P" $  cStsEncer .And. Empty(cStsApont) ; cStsOrdem := "L" // Encerrado parcial sem apontamento
		OTHERWISE                                                            ; cStsOrdem := "I" // Iniciado

			// Case  ("P"  $ cStsEncer) .And. "E" == cStsApont; cStsOrdem := "A" // Apontado
			// Case  ("P"  $ cStsEncer) .And. "A"  $ cStsEncer .And. "E" <> cStsApont; cStsOrdem := "L" // Parcial .s/Apont.
			// Case  ("P"  $ cStsEncer) .And. "E" <> cStsApont; cStsOrdem := "S" // Encerr.s/Apont.
			// Case !("P"  $ cStsEncer) .And. "E" == cStsApont; cStsOrdem := "A" // Apontada
			// Case !("P"  $ cStsEncer) .And. "I"  $ cStsApont; cStsOrdem := "I" // Iniciada
			// Case !("P"  $ cStsEncer) .And. "P" == cStsApont; cStsOrdem := "P" // Prevista
			// Case !("P"  $ cStsEncer) .And. ""  == cStsApont; cStsOrdem := "P" // Prevista

		End Case

		SC2->(DbSetOrder(1))
		SC2->(DbSeek(xFilial("SC2") + cNumOp))

		While SC2->(!Eof()) .And. SC2->(C2_FILIAL + C2_NUM) == xFilial("SC2") + cNumOp

			RecLock("SC2", .F.)
			SC2->C2_YSITUAC := cStsOrdem
			SC2->(MsUnLock())

			SC2->(DbSkip())

		EndDo

		DbSelectArea("SX2")
		SX2->(DbSetOrder(1))
		If SX2->(DbSeek("ZH7"))
			ZH7->(DbSetOrder(1))
			If ZH7->(DbSeek(xFilial("ZH7") + cNumOp))
				RecLock("ZH7", .F.)
				ZH7->ZH7_SITUAC := cStsOrdem
				ZH7->(MsUnLock())
			EndIf
		EndIf

		RestArea(aAreaANT)
		RestArea(aAreaZGH)
		RestArea(aAreaSC2)
		ErrorBlock(ErrorBlock())

	End Sequence

Return lRet


/*/{Protheus.doc} utilProducao
function AMEDSB8
Atualiza medidas das chapas na tabela SB8.
@author Kenny Roger Martins
@since 28/02/2019
@version ALL
/*/
User Function AMEDSB8(aMaterial)

	Local cLoteFor	:= ""
	Local cYDoc    	:= ""
	Local cYCavale 	:= ""
	Local aRet		:= {}
	Local cYmp		:= ""
	Local cYLoteMp	:= ""
	Local cYLocaMp	:= ""
	Local cYNumLMp	:= ""
	Local cYSerie	:= ""
	Local cOperac	:= ""
	Local nYPesoBr  := ""
	Local nYPesoLq  := ""
	Local cMessage  := ""
	Local nX        := 0
	Local nAjuste	:= 0
	Local cDocOri	:= ""			//Solicitação ticket https://totvsleste.freshdesk.com/a/tickets/5471
	Local cYProdR	:= ""
	Local cClifor   := ""
	Local cLojaB8   := ""
	Local nQtdLiq   := 0

	Default aMaterial := nil

	ErrorBlock( {|e| u_GRChecEr(e)})

	Begin Sequence

		If ValType(aMaterial) != "A"
			cMessage := "Atenção: A versão dos fontes GROA027, GROA044, encerramentoProducao e utilProducao não são compatíveis." + Chr(10) + Chr(10)
			cMessage += "Favor solicitar ao Suporte do GrPlus os fontes mais atuais para evitar inconsistências na base."
			ConOut(cMessage)
			If isBlind()
				setRestFault(500, oUtil:pText(cMessage))
			Else
				MsgStop(cMessage)
			EndIf
		EndIf

		//----------------------------------------------------------------
		// https://totvsleste.freshdesk.com/a/tickets/1945
		// Kenny Roger - 24/02/2021
		// Importante, se a chapa já estava produzida não deve atualizar
		// as medidas pois a mesma já pode ter sofrido alguma alteração
		// na tela de manutenção de bloco e chapa.
		//----------------------------------------------------------------
		For nX := 1 To Len(aMaterial)

			ZGM->(DbSetOrder(1))
			ZGM->(MsSeek(xFilial("ZGM") + aMaterial[nX][1]))

			While ZGM->(!Eof()) .and. ZGM->(ZGM_FILIAL + ZGM_OP + ZGM_ITEM + ZGM_SEQUEN + ZGM_PRODUT + ZGM_LOTECT + ZGM_NUMLOT) == xFilial("ZGM") + aMaterial[nX][1]

				SB8->(DbSetOrder(3))

				If SB8->(MsSeek(xFilial("SB8") + ZGM->(ZGM_PRODUT + ZGM_LOCAL + ZGM_LOTECT + ZGM_NUMLOT)))

					// Tratamento para posicionar e retornar os registros da Materia Prima .
					cYmp       := Posicione("SC2", 9, xFilial("SC2") + ZGM->ZGM_OP + ZGM->ZGM_ITEM + SB8->B8_PRODUTO , "C2_YMP")
					cOperac    := Posicione("SC2", 9, xFilial("SC2") + ZGM->ZGM_OP + ZGM->ZGM_ITEM + SB8->B8_PRODUTO , "C2_YTIPO")
					cYLoteMp   := Posicione("SC2", 9, xFilial("SC2") + ZGM->ZGM_OP + ZGM->ZGM_ITEM + SB8->B8_PRODUTO , "C2_YLOTECT")
					cYLocaMp   := Posicione("SC2", 9, xFilial("SC2") + ZGM->ZGM_OP + ZGM->ZGM_ITEM + SB8->B8_PRODUTO , "C2_YLOCMP")
					cYNumLMp   := Posicione("SC2", 9, xFilial("SC2") + ZGM->ZGM_OP + ZGM->ZGM_ITEM + SB8->B8_PRODUTO , "C2_YNUMLOT")
					aRet 	   := GetAdvFVal("SB8", {"B8_LOTEFOR" , "B8_YDOC", "B8_YCAVALE", "B8_YSERIE", "B8_YPESOBR", "B8_YPESOLQ", "B8_CLIFOR", "B8_LOJA"}, xFilial("SB8") + cYmp + cYLoteMp + cYNumLMp , 5 ,"Erro") //Retorna campos posicionados e atribui ao array [Giliard].

					cLoteFor   := aRet[1]
					cYDoc      := aRet[2]
					cYCavale   := aRet[3]
					cYSerie    := aRet[4]
					nYPesoBr   := aRet[5]
					nYPesoLq   := aRet[6]
					cClifor    := aRet[7]
					cLojaB8    := aRet[8]

					//Gera rastro SB8 na tabela ZR9 se o endereço enviado for diferente do ja cadastrado.
					u_REGENDER(ZGM->ZGM_ENDERE)

					IF cOperac == 'R'
						//´Como o recortado pode ter o mesmo produto, precisa pegar o valor que foi produzido
						nQtdLiq := SB8->B8_SALDO
					Else
						nQtdLiq := ZGM->ZGM_TOTLIQ
					EndIf
					// Atualiza SB8
					RecLock("SB8", .F.)
					SB8->B8_YENDERE := ZGM->ZGM_ENDERE
					SB8->B8_YCAVALE := IF(EMPTY(ZGM->ZGM_CAVALE), cYCavale, ZGM->ZGM_CAVALE)
					SB8->B8_YCLASSI := ZGM->ZGM_CLASSI
					SB8->B8_YCLAPRO := ZGM->ZGM_CLAPRO
					SB8->B8_YCOMBRU := ZGM->ZGM_COMBRU
					SB8->B8_YALTBRU := ZGM->ZGM_ALTBRU
					SB8->B8_YESPBRU := ZGM->ZGM_ESPBRU
					SB8->B8_YTOTBRU := ZGM->ZGM_TOTBRU
					SB8->B8_YCOMLIQ := ZGM->ZGM_COMLIQ
					SB8->B8_YALTLIQ := ZGM->ZGM_ALTLIQ
					SB8->B8_YESPLIQ := ZGM->ZGM_ESPLIQ
					SB8->B8_YTOTLIQ := nQtdLiq
					SB8->B8_YDEFOBS := ZGM->ZGM_DEFEIT
					SB8->B8_LOTEFOR := cLoteFor
					SB8->B8_CLIFOR  := cClifor
					SB8->B8_LOJA	:= cLojaB8

					//Caso de retorno para industrialização, quando a chapa tem seu nascimento fora da empresa.
					If SX3->(DbSeek("D1_YBLORIG"))

						nAjuste := TamSX3("D1_YOP")[1] - Len(ZGM->(ZGM_OP + ZGM_ITEM + ZGM_SEQUEN)) //Detectada diferença no tamanho do campo. Feito para ajustar o tamanho da string e não interferir no posicione.
						cDocOri := Posicione("SD1", 24, xFilial("SD1") + ZGM->(ZGM_OP + ZGM_ITEM + ZGM_SEQUEN) + Space(nAjuste) + SB8->B8_PRODUTO + SB8->B8_LOTECTL + SB8->B8_NUMLOTE, "D1_YBLORIG", "OPINDUSTRI")

					EndIf

					If !Empty(AllTrim(cDocOri))

						cYDoc := cDocOri

					Endif

					SB8->B8_YDOC    := cYDoc
					SB8->B8_YSERIE  := cYSerie

					//Giliard trasferencia de pesos MP para PA (Operação B/T)
					//https://totvsleste.freshdesk.com/a/tickets/1768
					cYtipo := Posicione("SC2", 9, xFilial("SC2") + ZGM->ZGM_OP + ZGM->ZGM_ITEM + SB8->B8_PRODUTO , "C2_YTIPO")

					If ( cYtipo == "B" .OR. cYtipo == "T" )
						SB8->B8_YPESOBR  := If(ZGM->ZGM_PESBRU > 0, ZGM->ZGM_PESBRU, nYPesoBr)
						SB8->B8_YPESOLQ  := If(ZGM->ZGM_PESLIQ > 0, ZGM->ZGM_PESLIQ, nYPesoLq)
					EndIf

					SB8->(MsUnLock())

					// Retira o rastro do numero do cavalete da materia prima.
					//https://totvsleste.freshdesk.com/a/tickets/1562 (referente ao retrabalho) //Beneficiamento com produto igual  https://totvsleste.freshdesk.com/a/tickets/1614
					IF  !EMPTY(SB8->B8_YCAVALE) .AND. (Alltrim(cYmp) <> Alltrim(SB8->B8_PRODUTO))
						u_LIMPYCAVALE(cYmp, SB8->B8_LOTECTL, SB8->B8_NUMLOTE,cYLocaMp)
					ElseIf !EMPTY(SB8->B8_YCAVALE)
						//Limpa o cavalete da MP para OPs de retrabalho.
						cYProdR := Alltrim(cYmp) + GETNEWPAR("GR_SIGLARE", "R", xFilial("SB8"))
						cYProdR += Space(Len(cYmp) - Len(Alltrim(cYmp)) - LEN(GETNEWPAR("GR_SIGLARE", "R", xFilial("SB8"))))		//Formatação da string pro MsSeek funcionar.
						u_LIMPYCAVALE(cYProdR, SB8->B8_LOTECTL, SB8->B8_NUMLOTE,cYLocaMp)
					Endif

					//------------------------------------------------------------
					// Ponto de entrada que permite alterar a tabela SB8.
					//------------------------------------------------------------
					If ExistBlock("MEDSB8GR")
						ExecBlock("MEDSB8GR", .f., .f., {} )
					EndIf

				EndIf

				ZGM->(dbSkip())

			EndDo

		Next


		ErrorBlock(ErrorBlock())

	End Sequence


Return Nil


/*/{Protheus.doc} utilProducao
function EMITENFT
Emite nota fiscal de entrada transformação - NFT.
@author Kenny Roger Martins
@since 28/02/2019
@version ALL
/*/
User Function EMITENFT(cNumOp,lGeraNf)

	Local lRet         := .T.
	Local cFornece	   := getMv("GR_SERFORN") // Nota Fiscal - Fornecedor
	Local cTesAux	   := getMv("GR_SERTESE") // Nota Fiscal - Tipo de Entrada
	Local cSerie	   := getMv("GR_SERIENF") // Série do documento
	Local cSerinft	   := GETNEWPAR("GR_SERINFT", "") // Série do documento Somente para NFT quando preenchido, cliente deseja alterar e não utilizar a serie padrão
	Local cCpoObs	   := getMv("GR_SF1COBS") // Campos observação
	Local cTipoSeq	   := getmv("MV_TPNRNFS")
	Local cTipoPrc	   := GETNEWPAR("GR_SERPRCV", "C") // Preço de Pauta ou Custo
	Local cTpPrcNf	   := GETNEWPAR("GR_SERPRNF", "") // Preço de Pauta ou Custo somente para NFT caso esteja preenchido
	Local lPorBloco	   := GETNEWPAR("GR_NFTLOTE", .F.) // Gera NFT individual por bloco
	Local cEspecie	   := GETNEWPAR("GR_SERESPE", "SPED") // Nota Fiscal - Fornecedor
	Local lCusEntrada  := GETNEWPAR("GR_HCUSENT", .F.) // Caso não tenha custo na SB8 busca da nota de entrada
	Local lNotaPodr3   := GETNEWPAR("GR_HNOTPD3", .F.) // Gera nota de transformação para produtos que estão em poder de terceiro, o parametro como .F. não gera porque tem a nota SMB e não leva em consideração o formulario proprio como S
	Local cNFTDesdob   := GETNEWPAR("GR_ENNFTDE","") // Engenharia para gerar NFT de desdobramento. devido o cliente criar desdobramento para envelopar um bloco ticket :2656
	Local lForMsgPad   := GETNEWPAR("GR_FORPAD",.T.) // .T. Informa se vai incluir a formuma no F1_MENPAD ou não .F.
	Local cForMsgPad   := GETNEWPAR("GR_FORPADC","") // Informa a fórmula utilizada para a mensagem padrão no NFT ticket: 3015
	Local nGnftcs0     := GETNEWPAR("GR_GNFTCS0",0) //Parametro para gerar nft se for :0 - O parametro não faz nada/ 1 - sempre gera nota de transformação desconsiderando o parametro GR_SERGENF/ 2 - nunca gera nota de transformação desconsiderando o parametro GR_SERGENF/ 3 - somente se for material proprio
	Local cMenPad	   := ""
	Local cLoja		   := ""
	Local cCond		   := ""
	Local aAutoSF1	   := {}
	Local aAutoSD1	   := {}
	Local aChaveTmp    := {}
	Local nPreco	   := 0
	Local cNumero	   := ""
	Local cMsgObs	   := ""
	Local qQUERY	   := ""
	Local qQUERYD1	   := ""
	Local cSql		   := ""
	Local nPosTotal    := 0
	Local nPosPreco    := 0
	Local nPosQtde     := 0
	Local nX           := 0
	Local nCustoNota   := 0
	Local nCustoReal   := 0
	Local nCustoTotal  := 0
	Local nCustoEntera := 0
	Local nPrecoTotal  := 0
	Local nPrecoUnit   := 0
	Local oUtil        := util():new()
	Local qOPBLOCO     := ""
	Local lValidPauta  := .T.
	Local aRet		   := {}
	Local aCustoBloco  := {}
	Local nPosBloco    := 0
	Local cPkBloco     := ""
	Local lNftExS01    := .T. //variavel de controle se vai gerar op com saldo proprio
	Local dDtnota      := StoD("")
	Local dtBold	   := dDataBase
	Local aRetDtNft	   := {}
	Local lSelecDat	   := .f.
	Local cLotInt      := ""
	Local cTes		   := ""
	Local aTesAux	   := {}
	Local cOperac 	   := ""
	Local aRetPrec     := {}

	Private lMsErroAuto	   := .F.
	Private lMsHelpAuto	   := .T.
	Private lAutoErrNoFile := .T.
	Private lGrPlus        := .T.

	ErrorBlock( {|e| u_GRChecEr(e)})

	Begin Sequence

		//Ajuste para quando o usuário deseja criar a nota via chamada de função
		//https://totvsleste.freshdesk.com/a/tickets/5896
		If lGeraNf <> nil
			nGnftcs0 := if(lGeraNf,1,0) // variavel que controla a geração da nota.
		EndIf

		//https://totvsleste.freshdesk.com/a/tickets/1730
		Default lGeraNf	   	   := getMv("GR_SERGENF") // Nota Fiscal - Gera ou Não

		aTesAux :=  STRTOKARR(cTesAux, ",")

		if len(aTesAux) == 1
			cTes    := cTesAux
		ElseIf len(aTesAux) > 1
			cTes    := aTesAux[1]
			cOperac := aTesAux[2]
		EndIf

		//Verificar se existe tes no parametro e se a tes esta cadastrada - https://totvsleste.freshdesk.com/a/tickets/1245
		If lGeraNf .and. (Empty(cTes) .or. Empty(posicione("SF4", 1, xFilial("SF4") + cTes, "F4_CODIGO")))
			Return {.F., "Tes invalida, favor verificar o parametro GR_SERTESE e o cadastro da tes " + cTes}
		EndIf

		//Para não acontecer erro de alias aberto
		If Select( "qOPBLOCO" ) > 0
			qOPBLOCO->(DbCloseArea())
		EndIf

		If Select( "qQUERY" ) > 0
			qQUERY->(DbCloseArea())
		EndIf

		If Select( "qOP" ) > 0
			qOP->(DbCloseArea())
		EndIf

		//Preço de pauta ou custo somente para NFT
		//https://totvsleste.freshdesk.com/a/tickets/5793
		If !empty(cTpPrcNf)
			cTipoPrc := cTpPrcNf
		EndIf

		//Cliente deseja alterar a serie da nota fiscal para nota NFT
		//https://totvsleste.freshdesk.com/a/tickets/5792
		iF !Empty(cSerinft)
			cSerie := cSerinft
		EndIF

		//https://totvsleste.freshdesk.com/a/tickets/5791
		//0 - não faz nada/1 - sempre gera/2 - nunca gera/3 - somente se for propria
		If nGnftcs0 == 1
			lGeraNf := .t.
		ElseIf nGnftcs0 == 3
			lNftExS01 := .f. // Incluido como faso para somente ficar .t. para notas que possuem S0.. que são as de poder de terceiro
			lGeraNf   := .t.
		elseif nGnftcs0 == 2
			lGeraNf := .F.
		EndIF

		// U_TOTVSES()
		//Tes da nota de transformação não pode alimentar estoque.
		If lGeraNf .and. (Empty(cTes) .or. posicione("SF4", 1, xFilial("SF4") + cTes, "ALLTRIM(F4_ESTOQUE)") <> 'N')
			Return {.F., "1- Tes invalida, favor verificar o parametro GR_SERTESE.A tes esta para movimentar estoque, porem ela não pode movimentar estoque. Tes: " + cTes}
		EndIf

		If lPorBloco // Gera nota individual por bloco.

			cSql := "   SELECT C2_NUM, C2_ITEM, C2_DATRF "
			cSql += "     FROM " + RetSqlName("SC2") + " SC2 "
			cSql += "    WHERE SC2.C2_FILIAL  = '" + xFilial("SC2") + "' "
			cSql += "      AND SC2.C2_NUM     = '" + cNumOp + "' "
			cSql += "      AND SC2.D_E_L_E_T_ = ' ' "
			cSql += " GROUP BY C2_NUM, C2_ITEM, C2_DATRF "
			cSql += " ORDER BY C2_NUM, C2_ITEM, C2_DATRF "

			TCQUERY cSql NEW ALIAS qOPBLOCO

			While qOPBLOCO->(!Eof())

				cNumOp    := qOPBLOCO->(C2_NUM + C2_ITEM)
				aAutoSF1  := {}
				aAutoSD1  := {}
				aChaveTmp := {}

				SC2->(dbSetOrder(1))
				SC2->(msSeek(xFilial("SC2") + cNumOp))

				If ExistBlock("GRCRINFT")
					lGeraNf := ExecBlock("GRCRINFT", .F., .F., {cNumOp})
				EndIf

				If (lGeraNf .And. (SC2->C2_YTIPO $ "S" .OR. (SC2->C2_YTIPO $ "D" .AND. ALLTRIM(SC2->C2_YENGENH) $ cNFTDesdob)) .And. SC2->C2_TPPR <> "E" .And. SC2->C2_YSITUAC $ "E/S")

					ConOut("GrPlus => Gerando NFT da OP No. " + AllTrim(cNumOp) + ". " + AllTrim(DtoC(Date())) + " " + AllTrim(Time()) + ".")

					cFornece := getMv("GR_SERFORN") // necessario visto que o sistema estava retirando os dois caracteres do fornecedor
					cCond    := posicione("SA2", 1, xFilial("SA2") + cFornece, "A2_COND")
					cLoja	 := substr(cFornece,TamSX3("F1_FORNECE")[1] + 1,TAMSX3("A2_LOJA")[1])
					cFornece := substr(cFornece,1,TamSX3("F1_FORNECE")[1])

					aAdd(aAutoSF1, {"F1_FILIAL",  xFilial("SF1"),    nil})
					aAdd(aAutoSF1, {"F1_HORA",    Time(),            nil})
					aAdd(aAutoSF1, {"F1_TIPO",    "N",               nil})
					aAdd(aAutoSF1, {"F1_FORMUL",  "S",               nil})
					aAdd(aAutoSF1, {"F1_FORNECE", cFornece,          nil})
					aAdd(aAutoSF1, {"F1_LOJA",    cLoja,             nil})
					aAdd(aAutoSF1, {"F1_SERIE",   cSerie,            nil})
					aAdd(aAutoSF1, {"F1_COND",    cCond,             nil})
					aAdd(aAutoSF1, {"F1_ESPECIE", cEspecie,          nil})
					aAdd(aAutoSF1, {cCpoObs,      cMsgObs,           nil})
					aAdd(aAutoSF1, {"F1_YDOCEXT", "_OP" + cNumOp,    nil})
					aAdd(aAutoSF1, {"F1_TPFRETE", "S",               nil})

					//---------------------------------------------------------------
					// Depois de verificar se existe nota fiscal efetiva os itens
					// que devem emitir nota fiscal de entrada
					//---------------------------------------------------------------

					While SC2->(!Eof()) .And. SC2->(C2_FILIAL + C2_NUM + C2_ITEM) == xFilial("SC2") + cNumOp

						SD3->(dbSetOrder(1))
						SD3->(msSeek(xFilial("SD3") + SC2->(C2_NUM + C2_ITEM + C2_SEQUEN + C2_ITEMGRD)))

						While SD3->(!eof()) .and. SD3->(D3_FILIAL + D3_OP) == xFilial("SD3") + SC2->(C2_NUM + C2_ITEM + C2_SEQUEN + C2_ITEMGRD)

							If SD3->D3_CF == "PR0" .and. empty(SD3->D3_ESTORNO)

								SF1->(DbOrderNickName("DOCEXTSER"))

								If SF1->(DbSeek(xFilial("SF1") + "_OP" + cNumOp))

									SD1->(dbSetOrder(11))

									// verifica se já existe nota fiscal para essa OP

									While SF1->(!eof()) .and. SF1->(F1_FILIAL + F1_YDOCEXT) == xFilial("SF1") + "_OP" + cNumOp

										//So entra aqui se for poder de terceiro que possui nota S01
										If nGnftcs0 == 3
											lNftExS01 := .T.
										EndIF

										If !lNotaPodr3 .OR. (lNotaPodr3 .and. SF1->F1_FORMUL == 'S')

											// caso exista nota fiscal verifica se é da chapa produzida

											If SD1->(DbSeek(xFilial("SD1") + SF1->(F1_DOC + F1_SERIE + F1_FORNECE + F1_LOJA) + SD3->(D3_COD + D3_LOTECTL + D3_NUMLOTE)))

												If aScan(aChaveTmp, {|x| x[1] == SD3->(D3_COD + D3_LOCAL+ D3_LOTECTL + D3_NUMLOTE)}) == 0

													aAdd(aChaveTmp, {SD3->(D3_COD + D3_LOCAL + D3_LOTECTL + D3_NUMLOTE)})

												EndIf

											EndIf
										EndIf

										SF1->(dbSkip())

									EndDo

								EndIf

							EndIf

							SD3->(dbSkip())

						EndDo

						SC2->(DbSkip())

					EndDo

					cSql := "   SELECT C2_NUM,     C2_ITEM,    C2_YMP,     C2_YLOCMP,  C2_YLOTECT, C2_YNUMLOT, C2_YTOTITL, "
					cSql += "          C2_YCOMITB, C2_YALTITB, C2_YESPITB, C2_YTOTITB, C2_YCOMITL, C2_YALTITL, C2_YESPITL,
					cSql += "          C2_YCOMPLE "
					cSql += "     FROM " + RetSqlName("SC2") + " SC2 "
					cSql += "    WHERE SC2.C2_FILIAL  = '" + xFilial("SC2") + "' "
					cSql += "      AND SC2.C2_NUM  = '" + SubStr(cNumOp, 1, TamSX3("C2_NUM")[1]) + "' "
					cSql += "      AND SC2.C2_ITEM = '" + SubStr(cNumOp,TamSX3("C2_NUM")[1] + 1) + "' "
					cSql += "      AND SC2.D_E_L_E_T_ = ' ' "
					cSql += " GROUP BY C2_NUM,     C2_ITEM,    C2_YMP,     C2_YLOCMP,  C2_YLOTECT, C2_YNUMLOT, C2_YTOTITL, "
					cSql += "          C2_YCOMITB, C2_YALTITB, C2_YESPITB, C2_YTOTITB, C2_YCOMITL, C2_YALTITL, C2_YESPITL, "
					cSql += "          C2_YCOMPLE  "
					cSql += " ORDER BY C2_NUM,     C2_ITEM "

					TCQUERY cSql NEW ALIAS qOP

					While qOP->(!Eof())

						// Verifica se tem sobra de Entera para incluir na nota fiscal
						nCustoNota := 0

						If qOP->C2_YTOTITL == 0
							nCustoEntera := 0
						EndIf

						If qOP->C2_YTOTITL > 0

							//---------------------------------------------------------------
							// Verifica se o bloco é de terceiros caso seja pega o custo
							// da tabela SB6.
							//---------------------------------------------------------------

							cSql := "     SELECT COALESCE(B6_PRUNIT, 0) B6_PRUNIT, COALESCE(B6_QUANT, 0) B6_QUANT "
							cSql += "       FROM " + RetSqlName("SD1") + " SD1 "
							cSql += " INNER JOIN " + RetSqlName("SB6") + " SB6 "
							cSql += "         ON SB6.B6_FILIAL  = '" + xFilial("SB6") + "'"
							cSql += "        AND SB6.B6_DOC     = SD1.D1_DOC "
							cSql += "        AND SB6.B6_SERIE   = SD1.D1_SERIE "
							cSql += "        AND SB6.B6_CLIFOR  = SD1.D1_FORNECE "
							cSql += "        AND SB6.B6_LOJA    = SD1.D1_LOJA "
							cSql += "        AND SB6.B6_PRODUTO = SD1.D1_COD "
							cSql += "        AND SB6.B6_IDENT   = SD1.D1_IDENTB6 "
							cSql += "        AND SB6.B6_SALDO   > 0 "
							cSql += "        AND SB6.B6_TIPO    = 'D' "
							cSql += "        AND SB6.D_E_L_E_T_ = ' ' "
							cSql += " INNER JOIN " + RetSqlName("SF1") + " SF1  "
							cSql += "         ON SF1.F1_FILIAL  = '" + xFilial("SF1") + "'"
							cSql += "        AND SF1.F1_DOC     = SD1.D1_DOC "
							cSql += "        AND SF1.F1_SERIE   = SD1.D1_SERIE "
							cSql += "        AND SF1.F1_FORNECE = SD1.D1_FORNECE "
							cSql += "        AND SF1.F1_LOJA    = SD1.D1_LOJA "
							cSql += "        AND SF1.D_E_L_E_T_ = ' ' "
							cSql += "      WHERE SD1.D1_FILIAL  = '" + xFilial("SD1")  + "'"
							cSql += "        AND SD1.D1_COD     = '" + SC2->C2_YMP     + "'"
							cSql += "        AND SD1.D1_LOCAL   = '" + SC2->C2_YLOCMP  + "'"
							cSql += "        AND SD1.D1_LOTECTL = '" + SC2->C2_YLOTECT + "'"
							cSql += "        AND SD1.D1_NUMLOTE = '" + SC2->C2_YNUMLOT + "'"
							cSql += "        AND SD1.D_E_L_E_T_ = ' '"

							TCQUERY cSql NEW ALIAS qQUERY

							nCustoEntera := qQUERY->B6_PRUNIT * qQUERY->B6_QUANT

							qQUERY->(DbCloseArea())

							If cTipoPrc == "P"

								SB5->(DbGoTop())
								nPreco := Posicione("SB5", 1, xFilial("SB5") + qOP->C2_YMP, "B5_YVLRPTA")

								// https://totvsleste.freshdesk.com/a/tickets/1245
								If nPreco <= 0

									aRetPrec := GetPauta(qOP->C2_YMP)

									if aRetPrec[1]
										nPreco := aRetPrec[2]
									Else
										Return {.F., aRetPrec[3]}
									EndIf

								EndIf

							ElseIf nCustoEntera > 0
								nPreco := nCustoEntera / Posicione("SB8", 3, xFilial("SB8") + qOP->(C2_YMP+C2_YLOCMP+C2_YLOTECT+C2_YNUMLOT), "B8_QTDORI")
							Else
								nPreco := Posicione("SB8", 3, xFilial("SB8") + qOP->(C2_YMP+C2_YLOCMP+C2_YLOTECT+C2_YNUMLOT), "B8_YCUSTO") / ;
									Posicione("SB8", 3, xFilial("SB8") + qOP->(C2_YMP+C2_YLOCMP+C2_YLOTECT+C2_YNUMLOT), "B8_QTDORI")
							EndIf

							If nPreco <= 0
								Return {.F., "1) O preço do produto não pode ser Zero!" + Chr(10) + Chr(10) + "Favor conferir o custo B8_YCUSTO ou o preço de pauta B5_YVLRPTA."}
							EndIf

							nCustoEntera := Round(qOP->C2_YTOTITL * nPreco, TamSx3("D1_TOTAL")[2])
							nCustoNota   += nCustoEntera

							If RETITE(qOP->C2_YLOTECT, qOP->C2_YMP, qOP->C2_YLOCMP)
								cLotInt := SubStr(alltrim(qOP->C2_YLOTECT),1,len(alltrim(qOP->C2_YLOTECT))-1) + qOP->C2_YCOMPLE
							Else
								cLotInt := If(Len(AllTrim(qOP->C2_YLOTECT)) < TamSX3("C2_YLOTECT")[1], AllTrim(qOP->C2_YLOTECT) + qOP->C2_YCOMPLE, SubStr(AllTrim(qOP->C2_YLOTECT), 2, Len(AllTrim(qOP->C2_YLOTECT))) + qOP->C2_YCOMPLE)
							EndIf

							aAutoLin := {}
							aAdd(aAutoLin, {"D1_COD",     qOP->C2_YMP,     nil})
							if !empty(cOperac)
								aAdd(aAutoLin, {"D1_OPER",     cOperac,            nil})
							EndIf
							aAdd(aAutoLin, {"D1_TES",     cTes,            nil})
							aAdd(aAutoLin, {"D1_LOCAL",   qOP->C2_YLOCMP,  nil})
							aAdd(aAutoLin, {"D1_LOTECTL", cLotInt, nil})
							aAdd(aAutoLin, {"D1_NUMLOTE", "",              nil})
							aAdd(aAutoLin, {"D1_YCOMBRU", qOP->C2_YCOMITB, nil})
							aAdd(aAutoLin, {"D1_YALTBRU", qOP->C2_YALTITB, nil})
							aAdd(aAutoLin, {"D1_YESPBRU", qOP->C2_YESPITB, nil})
							aAdd(aAutoLin, {"D1_YTOTBRU", qOP->C2_YTOTITB, nil})
							aAdd(aAutoLin, {"D1_YCOMLIQ", qOP->C2_YCOMITL, nil})
							aAdd(aAutoLin, {"D1_YALTLIQ", qOP->C2_YALTITL, nil})
							aAdd(aAutoLin, {"D1_YESPLIQ", qOP->C2_YESPITL, nil})
							aAdd(aAutoLin, {"D1_YTOTLIQ", qOP->C2_YTOTITL, nil})
							aAdd(aAutoLin, {"D1_QUANT",   qOP->C2_YTOTITL, nil})
							aAdd(aAutoLin, {"D1_VUNIT",   Round(nCustoEntera / qOP->C2_YTOTITL, TamSx3("D1_VUNIT")[2]), nil})
							aAdd(aAutoLin, {"D1_TOTAL",   nCustoEntera,    nil})
							aAdd(aAutoLin, {"D1_YINTERA", "S",    nil})
							aAdd(aAutoSD1, aAutoLin)

						EndIf

						cSql := " SELECT SUM(D3_QUANT) AS D3_QUANT "
						cSql += "   FROM " + RetSqlName("SD3") + " SD3"
						cSql += "  WHERE SD3.D3_FILIAL  = '" + xFilial("SD3") + "'"
						cSql += "    AND SD3.D3_OP      BETWEEN '" + qOP->(C2_NUM + C2_ITEM) + "' AND '" + qOP->(C2_NUM + C2_ITEM) + "ZZZZZZ' "
						cSql += "    AND SD3.D3_CF      = 'PR0'"
						cSql += "    AND SD3.D3_ESTORNO = ' '"
						cSql += "    AND SD3.D_E_L_E_T_ = ' '"

						TCQUERY cSql NEW ALIAS qQUERY

						nCustoTotal := Posicione("SB8", 3, xFilial("SB8") + qOP->(C2_YMP + C2_YLOCMP + C2_YLOTECT + C2_YNUMLOT), "B8_YCUSTO") - nCustoEntera
						nPrecoUnit  := Round(nCustoTotal / qQUERY->D3_QUANT, TamSX3("D1_VUNIT")[2])

						// https://totvsleste.freshdesk.com/a/tickets/1939
						// Caso não tenha custo na SB8 pergunta se o usuário quer buscar na nota de entrada
						If lCusEntrada .And. cTipoPrc == "C" .And. nPrecoUnit <= 0
							If AllTrim(Posicione("SB8", 3, xFilial("SB8") + qOP->(C2_YMP + C2_YLOCMP + C2_YLOTECT + C2_YNUMLOT), "B8_ORIGLAN")) == "NF"
								If !isBlind()
									If MsgYesNo("Não foi encontrado custo na tabela SB8 para o material " + AllTrim(qOP->C2_YMP) + " deseja utilizar o custo da nota de entrada?" + chr(10) + chr(10) + "Caso não tenha certeza favor entrar em contato com o Administrador do Sistema!")
										MsgStop("Atenção: Após emissão da nota fiscal favor conferir se os valores estão corretos!")

										nCustoTotal := GetCustoNf(qOP->C2_YMP, qOP->C2_YLOTECT, qOP->C2_YNUMLOT) - nCustoEntera
										nPrecoUnit  := Round(nCustoTotal / qQUERY->D3_QUANT, TamSX3("D1_VUNIT")[2])
									EndIf
								Else
									nCustoTotal := GetCustoNf(qOP->C2_YMP, qOP->C2_YLOTECT, qOP->C2_YNUMLOT) - nCustoEntera
									nPrecoUnit  := Round(nCustoTotal / qQUERY->D3_QUANT, TamSX3("D1_VUNIT")[2])
								EndIf
							EndIf
						EndIf

						qQUERY->(DbCloseArea())

						SD3->(dbSetOrder(1))
						SD3->(msSeek(xFilial("SD3") + qOP->(C2_NUM + C2_ITEM)))

						While SD3->(!eof()) .And. SD3->(D3_FILIAL + SubString(D3_OP, 1, 8)) == xFilial("SD3") + qOP->(C2_NUM + C2_ITEM)

							If SD3->D3_CF == "PR0" .And. Empty(SD3->D3_ESTORNO)

								If lNftExS01 .And. aScan(aChaveTmp, {|x| x[1] == SD3->(D3_COD + D3_LOCAL + D3_LOTECTL + D3_NUMLOTE)}) == 0

									If cTipoPrc == "C"

										nPrecoTotal := Round(nPrecoUnit * SD3->D3_QUANT, TamSX3("D1_TOTAL")[2])
										nCustoNota  += nPrecoTotal

									ElseIf cTipoPrc == "P"

										SB5->(DbGoTop())
										nPrecoUnit  := Posicione("SB5", 1, xFilial("SB5") + SD3->D3_COD, "B5_YVLRPTA")

										// https://totvsleste.freshdesk.com/a/tickets/1245
										If (nPrecoUnit <= 0)

											aRetPrec := GetPauta(SD3->D3_COD)

											if aRetPrec[1]
												nPrecoUnit := aRetPrec[2]
											Else
												Return {.F., aRetPrec[3]}
											EndIf

										EndIf

										nPrecoTotal := Round(nPrecoUnit * SD3->D3_QUANT, TamSX3("D1_TOTAL")[2])

									EndIf

									If nPrecoUnit <= 0
										Return {.F., "2) O preço do produto não pode ser Zero!" + Chr(10) + Chr(10) + "Favor conferir o custo B8_YCUSTO ou o preço de pauta B5_YVLRPTA."}
									EndIf

									//Validar se ja existe a nota no sistema.
									cSql := " SELECT COUNT(*) QUANTIDADE  "
									cSql += "   FROM " + RetSqlName("SD1") + " SD1 "
									cSql += "  INNER JOIN " + RetSqlName("SF1") + " SF1 "
									cSql += "   	ON "
									cSql += "   	SD1.D1_FILIAL      = SF1.F1_FILIAL "
									cSql += "   	AND SD1.D1_DOC     = SF1.F1_DOC "
									cSql += "   	AND SD1.D1_SERIE   = SF1.F1_SERIE "
									cSql += "   	AND SD1.D1_FORNECE = SF1.F1_FORNECE "
									cSql += "   	AND SF1.D_E_L_E_T_ = ' ' "
									cSql += "  WHERE SD1.D1_FILIAL   = '" + xFilial("SD1") +"'"
									cSql += "    AND SD1.D1_COD      = '" + SD3->D3_COD    +"'"
									cSql += "    AND SD1.D1_LOCAL    = '" + SD3->D3_LOCAL  +"'"
									cSql += "    AND SD1.D1_LOTECTL  = '" + SD3->D3_LOTECTL+"'"
									cSql += "    AND SD1.D1_NUMLOTE  = '" + SD3->D3_NUMLOTE+"'"
									cSql += "    AND SD1.D_E_L_E_T_  = ' '"
									cSql += "    AND SF1.F1_YDOCEXT  LIKE '%" + SUBSTR(cNumOp,1,6) + "%'"
									cSql += "    AND SF1.F1_FORNECE  =  '" + cFornece + "'"
									cSql += "    AND SF1.F1_LOJA     =  '" + cLoja    + "'"
									cSql += "    AND SF1.F1_SERIE    =  '" + cSerie   + "'"

									TCQUERY cSql NEW ALIAS qQUERYD1

									If (qQUERYD1->QUANTIDADE > 0 )

										qQUERYD1->(DbCloseArea())
										SD3->(DbSkip())
										LOOP

									EndIf

									qQUERYD1->(DbCloseArea())

									aAutoLin := {}
									aAdd(aAutoLin, {"D1_COD",     SD3->D3_COD,     nil})
									if !empty(cOperac)
										aAdd(aAutoLin, {"D1_OPER",     cOperac,            nil})
									EndIf
									aAdd(aAutoLin, {"D1_TES",     cTes,            nil})
									aAdd(aAutoLin, {"D1_LOCAL",   SD3->D3_LOCAL,   nil})
									aAdd(aAutoLin, {"D1_LOTECTL", SD3->D3_LOTECTL, nil})
									aAdd(aAutoLin, {"D1_NUMLOTE", SD3->D3_NUMLOTE, nil})
									aAdd(aAutoLin, {"D1_YCAVALE", SD3->D3_YCAVALE, nil})
									aAdd(aAutoLin, {"D1_YENDERE", SD3->D3_YENDERE, nil})
									aAdd(aAutoLin, {"D1_YCLASSI", SD3->D3_YCLASSI, nil})
									aAdd(aAutoLin, {"D1_YCLAPRO", SD3->D3_YCLAPRO, nil})
									aAdd(aAutoLin, {"D1_YCOMBRU", SD3->D3_YCOMBRU, nil})
									aAdd(aAutoLin, {"D1_YALTBRU", SD3->D3_YALTBRU, nil})
									aAdd(aAutoLin, {"D1_YESPBRU", SD3->D3_YESPBRU, nil})
									aAdd(aAutoLin, {"D1_YTOTBRU", SD3->D3_YTOTBRU, nil})
									aAdd(aAutoLin, {"D1_YCOMLIQ", SD3->D3_YCOMLIQ, nil})
									aAdd(aAutoLin, {"D1_YALTLIQ", SD3->D3_YALTLIQ, nil})
									aAdd(aAutoLin, {"D1_YESPLIQ", SD3->D3_YESPLIQ, nil})
									aAdd(aAutoLin, {"D1_YTOTLIQ", SD3->D3_YTOTLIQ, nil})
									aAdd(aAutoLin, {"D1_YVOLUME", 1, nil})
									aAdd(aAutoLin, {"D1_QUANT",   SD3->D3_QUANT,   nil})
									aAdd(aAutoLin, {"D1_VUNIT",   nPrecoUnit,      nil})
									aAdd(aAutoLin, {"D1_TOTAL",   nPrecoTotal,     nil})
									aAdd(aAutoSD1, aAutoLin)

								EndIf

							EndIf

							SD3->(DbSkip())

						EndDo

						// If !Empty(qOP->C2_DATRF) .And. Len(aAutoSD1) > 0 .And. cTipoPrc == "C"

						// 	nPosQtde    := aScan(aAutoSD1[Len(aAutoSD1)], {|x| AllTrim(x[1]) == "D1_QUANT"})
						// 	nPosPreco   := aScan(aAutoSD1[Len(aAutoSD1)], {|x| AllTrim(x[1]) == "D1_VUNIT"})
						// 	nPosTotal   := aScan(aAutoSD1[Len(aAutoSD1)], {|x| AllTrim(x[1]) == "D1_TOTAL"})
						// 	nPrecoTotal := Round((nCustoTotal + nCustoEntera) - (nCustoNota - nPrecoTotal), TamSx3("D1_TOTAL")[2])
						// 	nPrecoUnit  := Round(nPrecoTotal / aAutoSD1[Len(aAutoSD1)][nPosQtde][2], TamSX3("D1_VUNIT")[2])

						// 	aAutoSD1[Len(aAutoSD1)][nPosPreco][2] := nPrecoUnit
						// 	aAutoSD1[Len(aAutoSD1)][nPosTotal][2] := nPrecoTotal

						// EndIf

						qOP->(DbSkip())

					EndDo

					qOP->(DbCloseArea())

					If Len(aAutoSD1) > 0

						If cTipoPrc == "C"

							nPosQtde    := aScan(aAutoSD1[Len(aAutoSD1)], {|x| AllTrim(x[1]) == "D1_QUANT"})
							nPosPreco   := aScan(aAutoSD1[Len(aAutoSD1)], {|x| AllTrim(x[1]) == "D1_VUNIT"})
							nPosTotal   := aScan(aAutoSD1[Len(aAutoSD1)], {|x| AllTrim(x[1]) == "D1_TOTAL"})
							nPrecoTotal := Round((nCustoTotal + nCustoEntera) - (nCustoNota - nPrecoTotal), TamSx3("D1_TOTAL")[2])
							nPrecoUnit  := Round(nPrecoTotal / aAutoSD1[Len(aAutoSD1)][nPosQtde][2], TamSX3("D1_VUNIT")[2])

							aAutoSD1[Len(aAutoSD1)][nPosPreco][2] := nPrecoUnit
							aAutoSD1[Len(aAutoSD1)][nPosTotal][2] := nPrecoTotal

						EndIf

						If lForMsgPad
							if Empty(cForMsgPad)
								cMenPad := Posicione("SF4", 1, xFilial("SF4") + cTes, "F4_FORMULA")
							Else
								cMenPad := cForMsgPad
							endIf
						EndIf

						cNumero  := getNumFS(cSerie,cTipoSeq) // função para retornar o numero da NF de entrada formulario proprio

						aAdd(aAutoSF1, {"F1_DOC",     cNumero,  nil})
						aAdd(aAutoSF1, {"F1_MENPAD",  cMenPad,  nil})

						//Mensagem vai aparecer soemnte uma vez para o usuário selecionar
						if !lSelecDat

							aRetDtNft := .t.

							aRetDtNft := u_valdDtNt(StoD(qOPBLOCO->(C2_DATRF)),Date())

							if aRetDtNft[1]
								dDtnota := aRetDtNft[3]
							Else
								RETURN {.F., aRetDtNft[2]}
							EndIF

							aAdd(aAutoSF1, {"F1_EMISSAO", dDtnota,nil})

							dtBold := ddatabase
							ddatabase := dDtnota
						EndIf

						aAutoSF1 := FWVetByDic(aAutoSF1, "SF1")

						msExecAuto({|x,y,z| mata103(x,y,z)}, aAutoSF1, aAutoSD1, 3)

						ddatabase := dtBold

						//Notas geradas a partir da SD5 o numero fica como 0000000
						IF cTipoSeq == "3"

							cNumero  := SF1->F1_DOC

						EndIf

						If lMsErroAuto
							qOPBLOCO->(DbCloseArea())
							cMsgErro := oUtil:getAutoError()
							Return {.F., cMsgErro}
						EndIf

						SB8->(dbSetOrder(3))
						SD1->(DbSetOrder(1))
						SD1->(DbGoTop())
						SD1->(DbSeek(xFilial("SD1") + PADR(cNumero,TAMSX3("D1_DOC")[1]) + PADR(cSerie,TAMSX3("D1_SERIE")[1]) + PADR(cFornece,TAMSX3("D1_FORNECE")[1])  + PADR(cLoja,TAMSX3("D1_LOJA")[1])))

						While SD1->(!Eof()) .And. SD1->(D1_FILIAL + D1_DOC + D1_SERIE + D1_FORNECE + D1_LOJA) == xFilial("SD1") + PADR(cNumero,TAMSX3("D1_DOC")[1]) + PADR(cSerie,TAMSX3("D1_SERIE")[1]) + PADR(cFornece,TAMSX3("D1_FORNECE")[1])  + PADR(cLoja,TAMSX3("D1_LOJA")[1])

							If SB8->(msSeek(xFilial("SB8") + SD1->(D1_COD + D1_LOCAL + D1_LOTECTL + D1_NUMLOTE)))

								ConOut("GrPlus => Atribuindo numero da NFT na chapa " + SD1->(D1_COD + D1_LOCAL + D1_LOTECTL + D1_NUMLOTE) + ". " + AllTrim(DtoC(Date())) + " " + AllTrim(Time()) + ".")
								RecLock("SB8", .F.)
								SB8->B8_YDOC   := cNumero
								SB8->B8_YSERIE := cSerie
								SB8->(MsUnLock())

							Else

								ConOut("GrPlus => Chapa " + SD1->(D1_COD + D1_LOCAL + D1_LOTECTL + D1_NUMLOTE) + " não encontrada para atribuicao do numero da NFT. " + AllTrim(DtoC(Date())) + " " + AllTrim(Time()) + ".")

							EndIf

							SD1->(DbSkip())

						EndDo

					EndIf

					ConOut("GrPlus => NFT No. " + AllTrim(SF1->F1_DOC) + "/" + AllTrim(SF1->F1_SERIE) + " da OP No. " + AllTrim(cNumOp) + " gerada com sucesso. " + AllTrim(DtoC(Date())) + " " + AllTrim(Time()) + ".")

				EndIf

				qOPBLOCO->(DbSkip())

			EndDo

			qOPBLOCO->(DbCloseArea())

		Else

			SC2->(dbSetOrder(1))
			SC2->(msSeek(xFilial("SC2") + cNumOp))

			If ExistBlock("GRCRINFT")
				lGeraNf := ExecBlock("GRCRINFT", .F., .F., {cNumOp})
			EndIf

			If (lGeraNf .And. (SC2->C2_YTIPO $ "S" .OR. (SC2->C2_YTIPO $ "D" .AND. ALLTRIM(SC2->C2_YENGENH) $ cNFTDesdob)) .And. SC2->C2_TPPR <> "E" .And. SC2->C2_YSITUAC $ "E/S")

				ConOut("GrPlus => Gerando NFT da OP No. " + AllTrim(cNumOp) + ". " + AllTrim(DtoC(Date())) + " " + AllTrim(Time()) + ".")

				cCond    := posicione("SA2", 1, xFilial("SA2") + cFornece, "A2_COND")
				cLoja	 := substr(cFornece,TamSX3("F1_FORNECE")[1] + 1,TAMSX3("A2_LOJA")[1])
				cFornece := substr(cFornece,1,TamSX3("F1_FORNECE")[1])

				aAdd(aAutoSF1, {"F1_FILIAL",  xFilial("SF1"),    nil})
				aAdd(aAutoSF1, {"F1_HORA",    Time(),            nil})
				aAdd(aAutoSF1, {"F1_TIPO",    "N",               nil})
				aAdd(aAutoSF1, {"F1_FORMUL",  "S",               nil})
				aAdd(aAutoSF1, {"F1_SERIE",   cSerie,            nil})
				aAdd(aAutoSF1, {"F1_ESPECIE", cEspecie,          nil})
				aAdd(aAutoSF1, {"F1_FORNECE", cFornece,          nil})
				aAdd(aAutoSF1, {"F1_LOJA",    cLoja,             nil})
				aAdd(aAutoSF1, {"F1_COND",    cCond,             nil})
				aAdd(aAutoSF1, {cCpoObs,      cMsgObs,           nil})
				aAdd(aAutoSF1, {"F1_YDOCEXT", "_OP" + cNumOp,    nil})
				aAdd(aAutoSF1, {"F1_TPFRETE", "S",               nil})

				//---------------------------------------------------------------
				// Depois de verificar se existe nota fiscal efetiva os itens
				// que devem emitir nota fiscal de entrada
				//---------------------------------------------------------------

				While SC2->(!Eof()) .And. SC2->(C2_FILIAL + C2_NUM) == xFilial("SC2") + cNumOp

					SD3->(dbSetOrder(1))
					SD3->(msSeek(xFilial("SD3") + SC2->(C2_NUM + C2_ITEM + C2_SEQUEN + C2_ITEMGRD)))

					While SD3->(!eof()) .and. SD3->(D3_FILIAL + D3_OP) == xFilial("SD3") + SC2->(C2_NUM + C2_ITEM + C2_SEQUEN + C2_ITEMGRD)

						If SD3->D3_CF == "PR0" .and. empty(SD3->D3_ESTORNO)

							SF1->(DbOrderNickName("DOCEXTSER"))

							If SF1->(DbSeek(xFilial("SF1") + "_OP" + cNumOp))

								SD1->(DbSetOrder(11))

								// verifica se já existe nota fiscal para essa OP

								While SF1->(!eof()) .and. SF1->(F1_FILIAL + F1_YDOCEXT) == xFilial("SF1") + "_OP" + cNumOp

									//So entra aqui se for poder de terceiro que possui nota S01
									If nGnftcs0 == 3
										lNftExS01 := .T.
									EndIF

									If !lNotaPodr3 .OR. (lNotaPodr3 .and. SF1->F1_FORMUL == 'S')

										// caso exista nota fiscal verifica se é da chapa produzida

										If SD1->(DbSeek(xFilial("SD1") + SF1->(F1_DOC + F1_SERIE + F1_FORNECE + F1_LOJA) + SD3->(D3_COD + D3_LOTECTL + D3_NUMLOTE)))

											If aScan(aChaveTmp, {|x| x[1] == SD3->(D3_COD + D3_LOCAL+ D3_LOTECTL + D3_NUMLOTE)}) == 0

												aAdd(aChaveTmp, {SD3->(D3_COD + D3_LOCAL + D3_LOTECTL + D3_NUMLOTE)})

											EndIf

										EndIf
									EndIf

									SF1->(dbSkip())

								EndDo

							EndIf

						EndIf

						SD3->(dbSkip())

					EndDo

					SC2->(DbSkip())

				EndDo

				cSql := "   SELECT C2_NUM,     C2_ITEM,    C2_YMP,     C2_YLOCMP,  C2_YLOTECT, C2_YNUMLOT, C2_YTOTITL, "
				cSql += "          C2_YCOMITB, C2_YALTITB, C2_YESPITB, C2_YTOTITB, C2_YCOMITL, C2_YALTITL, C2_YESPITL,
				cSql += "          C2_YCOMPLE "
				cSql += "     FROM " + RetSqlName("SC2") + " SC2 "
				cSql += "    WHERE SC2.C2_FILIAL  = '" + xFilial("SC2") + "' "
				cSql += "      AND SC2.C2_NUM     = '" + cNumOp + "' "
				cSql += "      AND SC2.D_E_L_E_T_ = ' ' "
				cSql += " GROUP BY C2_NUM,     C2_ITEM,    C2_YMP,     C2_YLOCMP,  C2_YLOTECT, C2_YNUMLOT, C2_YTOTITL, "
				cSql += "          C2_YCOMITB, C2_YALTITB, C2_YESPITB, C2_YTOTITB, C2_YCOMITL, C2_YALTITL, C2_YESPITL, "
				cSql += "          C2_YCOMPLE "
				cSql += " ORDER BY C2_NUM,     C2_ITEM "

				TCQUERY cSql NEW ALIAS qOP

				While qOP->(!Eof())

					// Verifica se tem sobra de Entera para incluir na nota fiscal
					nCustoNota := 0

					//------------------------------------------------------
					// https://totvsleste.freshdesk.com/a/tickets/1966
					// Kenny Roger Martins - 25/02/2021
					// O custo da nota só funciona se os blocos forem da
					// mesma nota de origem, necessário incluir array.
					//------------------------------------------------------
					If aScan(aCustoBloco, {|x| x[1] == qOP->(C2_YLOTECT)}) == 0
						aAdd(aCustoBloco, {qOP->(C2_YLOTECT), 0, 0, 0})
					EndIf

					If qOP->C2_YTOTITL == 0
						nCustoEntera := 0
					EndIf

					If qOP->C2_YTOTITL > 0

						//---------------------------------------------------------------
						// Verifica se o bloco é de terceiros caso seja pega o custo
						// da tabela SB6.
						//---------------------------------------------------------------

						cSql := "     SELECT COALESCE(B6_PRUNIT, 0) B6_PRUNIT, COALESCE(B6_QUANT, 0) B6_QUANT "
						cSql += "       FROM " + RetSqlName("SD1") + " SD1 "
						cSql += " INNER JOIN " + RetSqlName("SB6") + " SB6 "
						cSql += "         ON SB6.B6_FILIAL  = '" + xFilial("SB6") + "'"
						cSql += "        AND SB6.B6_DOC     = SD1.D1_DOC "
						cSql += "        AND SB6.B6_SERIE   = SD1.D1_SERIE "
						cSql += "        AND SB6.B6_CLIFOR  = SD1.D1_FORNECE "
						cSql += "        AND SB6.B6_LOJA    = SD1.D1_LOJA "
						cSql += "        AND SB6.B6_PRODUTO = SD1.D1_COD "
						cSql += "        AND SB6.B6_IDENT   = SD1.D1_IDENTB6 "
						cSql += "        AND SB6.B6_SALDO   > 0 "
						cSql += "        AND SB6.B6_TIPO    = 'D' "
						cSql += "        AND SB6.D_E_L_E_T_ = ' ' "
						cSql += " INNER JOIN " + RetSqlName("SF1") + " SF1  "
						cSql += "         ON SF1.F1_FILIAL  = '" + xFilial("SF1") + "'"
						cSql += "        AND SF1.F1_DOC     = SD1.D1_DOC "
						cSql += "        AND SF1.F1_SERIE   = SD1.D1_SERIE "
						cSql += "        AND SF1.F1_FORNECE = SD1.D1_FORNECE "
						cSql += "        AND SF1.F1_LOJA    = SD1.D1_LOJA "
						cSql += "        AND SF1.D_E_L_E_T_ = ' ' "
						cSql += "      WHERE SD1.D1_FILIAL  = '" + xFilial("SD1")  + "'"
						cSql += "        AND SD1.D1_COD     = '" + SC2->C2_YMP     + "'"
						cSql += "        AND SD1.D1_LOCAL   = '" + SC2->C2_YLOCMP  + "'"
						cSql += "        AND SD1.D1_LOTECTL = '" + SC2->C2_YLOTECT + "'"
						cSql += "        AND SD1.D1_NUMLOTE = '" + SC2->C2_YNUMLOT + "'"
						cSql += "        AND SD1.D_E_L_E_T_ = ' '"

						TCQUERY cSql NEW ALIAS qQUERY

						nCustoEntera := qQUERY->B6_PRUNIT * qQUERY->B6_QUANT

						qQUERY->(DbCloseArea())

						If cTipoPrc == "P"

							SB5->(DbGoTop())
							nPreco := Posicione("SB5", 1, xFilial("SB5") + qOP->C2_YMP, "B5_YVLRPTA")

							// https://totvsleste.freshdesk.com/a/tickets/1245
							If nPreco <= 0

								aRetPrec := GetPauta(qOP->C2_YMP)

								if aRetPrec[1]
									nPreco := aRetPrec[2]
								Else
									Return {.F., aRetPrec[3]}
								EndIf

							EndIf

						ElseIf nCustoEntera > 0

							nPreco := nCustoEntera / Posicione("SB8", 3, xFilial("SB8") + qOP->(C2_YMP+C2_YLOCMP+C2_YLOTECT+C2_YNUMLOT), "B8_QTDORI")

						Else

							nPreco := Posicione("SB8", 3, xFilial("SB8") + qOP->(C2_YMP+C2_YLOCMP+C2_YLOTECT+C2_YNUMLOT), "B8_YCUSTO") / ;
								Posicione("SB8", 3, xFilial("SB8") + qOP->(C2_YMP+C2_YLOCMP+C2_YLOTECT+C2_YNUMLOT), "B8_QTDORI")

							// https://totvsleste.freshdesk.com/a/tickets/1939
							// Caso não tenha custo na SB8 pergunta se o usuário quer buscar na nota de entrada
							If lCusEntrada .And. cTipoPrc == "C" .And. nPreco <= 0
								If AllTrim(Posicione("SB8", 3, xFilial("SB8") + qOP->(C2_YMP + C2_YLOCMP + C2_YLOTECT + C2_YNUMLOT), "B8_ORIGLAN")) == "NF"
									If !isBlind()
										If MsgYesNo("Não foi encontrado custo na tabela SB8 para o material " + AllTrim(qOP->C2_YMP) + " deseja utilizar o custo da nota de entrada?" + chr(10) + chr(10) + "Caso não tenha certeza favor entrar em contato com o Administrador do Sistema!")
											MsgStop("Atenção: Após emissão da nota fiscal favor conferir se os valores estão corretos!")

											nPreco := GetCustoNf(qOP->C2_YMP, qOP->C2_YLOTECT, qOP->C2_YNUMLOT) / ;
												Posicione("SB8", 3, xFilial("SB8") + qOP->(C2_YMP+C2_YLOCMP+C2_YLOTECT+C2_YNUMLOT), "B8_QTDORI")
										EndIf
									Else
										nPreco := GetCustoNf(qOP->C2_YMP, qOP->C2_YLOTECT, qOP->C2_YNUMLOT) / ;
											Posicione("SB8", 3, xFilial("SB8") + qOP->(C2_YMP+C2_YLOCMP+C2_YLOTECT+C2_YNUMLOT), "B8_QTDORI")
									EndIf
								EndIf
							EndIf

						EndIf

						If nPreco <= 0
							Return {.F., "3) O preço do produto não pode ser Zero!" + Chr(10) + Chr(10) + "Favor conferir o custo B8_YCUSTO ou o preço de pauta B5_YVLRPTA."}
						EndIf

						nCustoEntera := Round(qOP->C2_YTOTITL * nPreco, TamSx3("D1_TOTAL")[2])
						nCustoNota   += nCustoEntera

						//------------------------------------------------------
						// https://totvsleste.freshdesk.com/a/tickets/1966
						// Kenny Roger Martins - 25/02/2021
						// O custo da nota só funciona se os blocos forem da
						// mesma nota de origem, necessário incluir array.
						//------------------------------------------------------
						nPosBloco := aScan(aCustoBloco, {|x| x[1] == qOP->(C2_YLOTECT)})
						aCustoBloco[nPosBloco][2] += nCustoEntera // Custo da Nota
						aCustoBloco[nPosBloco][4] := nCustoEntera // Custo da Entera

						aAutoLin := {}
						aAdd(aAutoLin, {"D1_COD",     qOP->C2_YMP,     nil})
						if !empty(cOperac)
							aAdd(aAutoLin, {"D1_OPER",     cOperac,            nil})
						EndIf
						aAdd(aAutoLin, {"D1_TES",     cTes,            nil})
						aAdd(aAutoLin, {"D1_LOCAL",   qOP->C2_YLOCMP,  nil})
						aAdd(aAutoLin, {"D1_LOTECTL", If(Len(AllTrim(qOP->C2_YLOTECT)) < TamSX3("C2_YLOTECT")[1], AllTrim(qOP->C2_YLOTECT) + qOP->C2_YCOMPLE, SubStr(AllTrim(qOP->C2_YLOTECT), 2, Len(AllTrim(qOP->C2_YLOTECT))) + qOP->C2_YCOMPLE), nil})
						aAdd(aAutoLin, {"D1_NUMLOTE", "",              nil})
						aAdd(aAutoLin, {"D1_YCOMBRU", qOP->C2_YCOMITB, nil})
						aAdd(aAutoLin, {"D1_YALTBRU", qOP->C2_YALTITB, nil})
						aAdd(aAutoLin, {"D1_YESPBRU", qOP->C2_YESPITB, nil})
						aAdd(aAutoLin, {"D1_YTOTBRU", qOP->C2_YTOTITB, nil})
						aAdd(aAutoLin, {"D1_YCOMLIQ", qOP->C2_YCOMITL, nil})
						aAdd(aAutoLin, {"D1_YALTLIQ", qOP->C2_YALTITL, nil})
						aAdd(aAutoLin, {"D1_YESPLIQ", qOP->C2_YESPITL, nil})
						aAdd(aAutoLin, {"D1_YTOTLIQ", qOP->C2_YTOTITL, nil})
						aAdd(aAutoLin, {"D1_QUANT",   qOP->C2_YTOTITL, nil})
						aAdd(aAutoLin, {"D1_VUNIT",   Round(nCustoEntera / qOP->C2_YTOTITL, TamSx3("D1_VUNIT")[2]), nil})
						aAdd(aAutoLin, {"D1_TOTAL",   nCustoEntera,    nil})
						aAdd(aAutoSD1, aAutoLin)

					EndIf

					cSql := " SELECT SUM(D3_QUANT) AS D3_QUANT "
					cSql += "   FROM " + RetSqlName("SD3") + " SD3"
					cSql += "  WHERE SD3.D3_FILIAL  = '" + xFilial("SD3") + "'"
					cSql += "    AND SD3.D3_OP      BETWEEN '" + qOP->(C2_NUM + C2_ITEM) + "' AND '" + qOP->(C2_NUM + C2_ITEM) + "ZZZZZZ' "
					cSql += "    AND SD3.D3_CF      = 'PR0'"
					cSql += "    AND SD3.D3_ESTORNO = ' '"
					cSql += "    AND SD3.D_E_L_E_T_ = ' '"

					TCQUERY cSql NEW ALIAS qQUERY

					nCustoTotal := Posicione("SB8", 3, xFilial("SB8") + qOP->(C2_YMP + C2_YLOCMP + C2_YLOTECT + C2_YNUMLOT), "B8_YCUSTO") - nCustoEntera
					nPrecoUnit  := Round(nCustoTotal / qQUERY->D3_QUANT, TamSX3("D1_VUNIT")[2])

					// https://totvsleste.freshdesk.com/a/tickets/1939
					// Caso não tenha custo na SB8 pergunta se o usuário quer buscar na nota de entrada
					If lCusEntrada .And. cTipoPrc == "C" .And. nPrecoUnit <= 0
						If AllTrim(Posicione("SB8", 3, xFilial("SB8") + qOP->(C2_YMP + C2_YLOCMP + C2_YLOTECT + C2_YNUMLOT), "B8_ORIGLAN")) == "NF"
							If !isBlind()
								If MsgYesNo("Não foi encontrado custo na tabela SB8 para o material " + AllTrim(qOP->C2_YMP) + " deseja utilizar o custo da nota de entrada?" + chr(10) + chr(10) + "Caso não tenha certeza favor entrar em contato com o Administrador do Sistema!")
									MsgStop("Atenção: Após emissão da nota fiscal favor conferir se os valores estão corretos!")

									nCustoTotal := GetCustoNf(qOP->C2_YMP, qOP->C2_YLOTECT, qOP->C2_YNUMLOT) - nCustoEntera
									nPrecoUnit  := Round(nCustoTotal / qQUERY->D3_QUANT, TamSX3("D1_VUNIT")[2])
								EndIf
							Else
								nCustoTotal := GetCustoNf(qOP->C2_YMP, qOP->C2_YLOTECT, qOP->C2_YNUMLOT) - nCustoEntera
								nPrecoUnit  := Round(nCustoTotal / qQUERY->D3_QUANT, TamSX3("D1_VUNIT")[2])
							EndIf
						EndIf
					EndIf

					qQUERY->(DbCloseArea())

					//------------------------------------------------------
					// https://totvsleste.freshdesk.com/a/tickets/1966
					// Kenny Roger Martins - 25/02/2021
					// O custo da nota só funciona se os blocos forem da
					// mesma nota de origem, necessário incluir array.
					//------------------------------------------------------
					nPosBloco := aScan(aCustoBloco, {|x| x[1] == qOP->(C2_YLOTECT)})
					aCustoBloco[nPosBloco][3] := nCustoTotal // Custo Total

					SD3->(dbSetOrder(1))
					SD3->(msSeek(xFilial("SD3") + qOP->(C2_NUM + C2_ITEM)))

					While SD3->(!eof()) .And. SD3->(D3_FILIAL + SubString(D3_OP, 1, 8)) == xFilial("SD3") + qOP->(C2_NUM + C2_ITEM)

						If SD3->D3_CF == "PR0" .And. Empty(SD3->D3_ESTORNO)

							If lNftExS01 .And. aScan(aChaveTmp, {|x| x[1] == SD3->(D3_COD + D3_LOCAL + D3_LOTECTL + D3_NUMLOTE)}) == 0

								If cTipoPrc == "C"

									nPrecoTotal := Round(nPrecoUnit * SD3->D3_QUANT, TamSX3("D1_TOTAL")[2])
									nCustoNota  += nPrecoTotal

									//------------------------------------------------------
									// https://totvsleste.freshdesk.com/a/tickets/1966
									// Kenny Roger Martins - 25/02/2021
									// O custo da nota só funciona se os blocos forem da
									// mesma nota de origem, necessário incluir array.
									//------------------------------------------------------
									nPosBloco := aScan(aCustoBloco, {|x| x[1] == qOP->(C2_YLOTECT)})
									aCustoBloco[nPosBloco][2] += nPrecoTotal // Custo da Nota

								ElseIf cTipoPrc == "P"

									SB5->(DbGoTop())
									nPrecoUnit  := Posicione("SB5", 1, xFilial("SB5") + SD3->D3_COD, "B5_YVLRPTA")

									//https://totvsleste.freshdesk.com/a/tickets/1245
									If nPrecoUnit <= 0

										aRetPrec := GetPauta(SD3->D3_COD)

										if aRetPrec[1]
											nPrecoUnit := aRetPrec[2]
										Else
											Return {.F., aRetPrec[3]}
										EndIf

									EndIf

									nPrecoTotal := Round(nPrecoUnit * SD3->D3_QUANT, TamSX3("D1_TOTAL")[2])

								EndIf

								If nPrecoUnit <= 0
									Return {.F., "4) O preço do produto não pode ser Zero!" + Chr(10) + Chr(10) + "Favor conferir o custo B8_YCUSTO ou o preço de pauta B5_YVLRPTA."}
								EndIf

								aAutoLin := {}
								aAdd(aAutoLin, {"D1_COD",     SD3->D3_COD,     nil})
								if !empty(cOperac)
									aAdd(aAutoLin, {"D1_OPER",     cOperac,            nil})
								EndIf
								aAdd(aAutoLin, {"D1_TES",     cTes,            nil})
								aAdd(aAutoLin, {"D1_LOCAL",   SD3->D3_LOCAL,   nil})
								aAdd(aAutoLin, {"D1_LOTECTL", SD3->D3_LOTECTL, nil})
								aAdd(aAutoLin, {"D1_NUMLOTE", SD3->D3_NUMLOTE, nil})
								aAdd(aAutoLin, {"D1_YCAVALE", SD3->D3_YCAVALE, nil})
								aAdd(aAutoLin, {"D1_YENDERE", SD3->D3_YENDERE, nil})
								aAdd(aAutoLin, {"D1_YCLASSI", SD3->D3_YCLASSI, nil})
								aAdd(aAutoLin, {"D1_YCLAPRO", SD3->D3_YCLAPRO, nil})
								aAdd(aAutoLin, {"D1_YCOMBRU", SD3->D3_YCOMBRU, nil})
								aAdd(aAutoLin, {"D1_YALTBRU", SD3->D3_YALTBRU, nil})
								aAdd(aAutoLin, {"D1_YESPBRU", SD3->D3_YESPBRU, nil})
								aAdd(aAutoLin, {"D1_YTOTBRU", SD3->D3_YTOTBRU, nil})
								aAdd(aAutoLin, {"D1_YCOMLIQ", SD3->D3_YCOMLIQ, nil})
								aAdd(aAutoLin, {"D1_YALTLIQ", SD3->D3_YALTLIQ, nil})
								aAdd(aAutoLin, {"D1_YESPLIQ", SD3->D3_YESPLIQ, nil})
								aAdd(aAutoLin, {"D1_YTOTLIQ", SD3->D3_YTOTLIQ, nil})
								aAdd(aAutoLin, {"D1_YVOLUME", 1, nil})
								aAdd(aAutoLin, {"D1_QUANT",   SD3->D3_QUANT,   nil})
								aAdd(aAutoLin, {"D1_VUNIT",   nPrecoUnit,      nil})
								aAdd(aAutoLin, {"D1_TOTAL",   nPrecoTotal,     nil})
								aAdd(aAutoSD1, aAutoLin)

							EndIf

						EndIf

						SD3->(DbSkip())

					EndDo

					// If !Empty(qOP->C2_DATRF) .And. Len(aAutoSD1) > 0 .And. cTipoPrc == "C"

					// 	nPosQtde    := aScan(aAutoSD1[Len(aAutoSD1)], {|x| AllTrim(x[1]) == "D1_QUANT"})
					// 	nPosPreco   := aScan(aAutoSD1[Len(aAutoSD1)], {|x| AllTrim(x[1]) == "D1_VUNIT"})
					// 	nPosTotal   := aScan(aAutoSD1[Len(aAutoSD1)], {|x| AllTrim(x[1]) == "D1_TOTAL"})
					// 	nPrecoTotal := Round((nCustoTotal + nCustoEntera) - (nCustoNota - nPrecoTotal), TamSx3("D1_TOTAL")[2])
					// 	nPrecoUnit  := Round(nPrecoTotal / aAutoSD1[Len(aAutoSD1)][nPosQtde][2], TamSX3("D1_VUNIT")[2])

					// 	aAutoSD1[Len(aAutoSD1)][nPosPreco][2] := nPrecoUnit
					// 	aAutoSD1[Len(aAutoSD1)][nPosTotal][2] := nPrecoTotal

					// EndIf

					qOP->(DbSkip())

				EndDo

				qOP->(DbCloseArea())

				If Len(aAutoSD1) > 0

					If cTipoPrc == "C"

						//------------------------------------------------------
						// https://totvsleste.freshdesk.com/a/tickets/1966
						// Kenny Roger Martins - 25/02/2021
						// O custo da nota só funciona se os blocos forem da
						// mesma nota de origem, necessário incluir array.
						//------------------------------------------------------
						nPosCod     := aScan(aAutoSD1[Len(aAutoSD1)], {|x| AllTrim(x[1]) == "D1_COD"})
						nPosLoteCtl := aScan(aAutoSD1[Len(aAutoSD1)], {|x| AllTrim(x[1]) == "D1_LOTECTL"})
						nPosQtde    := aScan(aAutoSD1[Len(aAutoSD1)], {|x| AllTrim(x[1]) == "D1_QUANT"})
						nPosPreco   := aScan(aAutoSD1[Len(aAutoSD1)], {|x| AllTrim(x[1]) == "D1_VUNIT"})
						nPosTotal   := aScan(aAutoSD1[Len(aAutoSD1)], {|x| AllTrim(x[1]) == "D1_TOTAL"})

						If Len(aCustoBloco) > 0

							For nX := 1 To Len(aAutoSD1)

								nPosBloco := aScan(aCustoBloco, {|x| x[1] == aAutoSD1[nX][nPosLoteCtl][2]})

								If nPosBloco > 0

									nPrecoTotal := Round((aCustoBloco[nPosBloco][3] + aCustoBloco[nPosBloco][4]) - (aCustoBloco[nPosBloco][2] - aAutoSD1[nX][nPosTotal][2]), TamSx3("D1_TOTAL")[2])
									nPrecoUnit  := Round(nPrecoTotal / aAutoSD1[nX][nPosQtde][2], TamSX3("D1_VUNIT")[2])

									If cPkBloco <> aAutoSD1[nX][nPosLoteCtl][2]
										cPkBloco := aAutoSD1[nX][nPosLoteCtl][2]
										aAutoSD1[nX][nPosPreco][2] := nPrecoUnit
										aAutoSD1[nX][nPosTotal][2] := nPrecoTotal
									EndIf

								EndIf

							Next

						Else

							nPrecoTotal := Round((nCustoTotal + nCustoEntera) - (nCustoNota - nPrecoTotal), TamSx3("D1_TOTAL")[2])
							nPrecoUnit  := Round(nPrecoTotal / aAutoSD1[Len(aAutoSD1)][nPosQtde][2], TamSX3("D1_VUNIT")[2])

							aAutoSD1[Len(aAutoSD1)][nPosPreco][2] := nPrecoUnit
							aAutoSD1[Len(aAutoSD1)][nPosTotal][2] := nPrecoTotal

						EndIf

					EndIf

					If lForMsgPad
						if Empty(cForMsgPad)
							cMenPad := Posicione("SF4", 1, xFilial("SF4") + cTes, "F4_FORMULA")
						Else
							cMenPad := cForMsgPad
						endIf
					EndIf

					cNumero  := getNumFS(cSerie,cTipoSeq) // função para retornar o numero da NF de entrada formulario proprio

					aAdd(aAutoSF1, {"F1_DOC",     cNumero,  nil})
					aAdd(aAutoSF1, {"F1_MENPAD",  cMenPad,  nil})

					//Mensagem vai aparecer soemnte uma vez para o usuário selecionar
					if !lSelecDat

						aRetDtNft := .t.

						aRetDtNft := u_valdDtNt(SC2->C2_DATRF,Date())

						if aRetDtNft[1]
							dDtnota := aRetDtNft[3]
						Else
							RETURN {.F., aRetDtNft[2]}
						EndIF

						aAdd(aAutoSF1, {"F1_EMISSAO", dDtnota,nil})

						dtBold := ddatabase
						ddatabase := dDtnota

					EndIf

					aAutoSF1 := FWVetByDic(aAutoSF1, "SF1")

					msExecAuto({|x,y,z| mata103(x,y,z)}, aAutoSF1, aAutoSD1, 3)

					ddatabase := dtBold

					If lMsErroAuto
						cMsgErro := oUtil:getAutoError()
						Return {.F., cMsgErro}
					EndIf

					SB8->(dbSetOrder(3))
					SD1->(DbSetOrder(1))
					SD1->(DbGoTop())
					SD1->(DbSeek(xFilial("SD1") + SF1->(F1_DOC + F1_SERIE + F1_FORNECE + F1_LOJA)))

					While SD1->(!Eof()) .And. SD1->(D1_FILIAL + D1_DOC + D1_SERIE + D1_FORNECE + D1_LOJA) == xFilial("SD1") + SF1->(F1_DOC + F1_SERIE + F1_FORNECE + F1_LOJA)

						If SB8->(msSeek(xFilial("SB8") + SD1->(D1_COD + D1_LOCAL + D1_LOTECTL + D1_NUMLOTE)))

							ConOut("GrPlus => Atribuindo numero da NFT na chapa " + SD1->(D1_COD + D1_LOCAL + D1_LOTECTL + D1_NUMLOTE) + ". " + AllTrim(DtoC(Date())) + " " + AllTrim(Time()) + ".")
							RecLock("SB8", .F.)
							SB8->B8_YDOC   := SF1->F1_DOC
							SB8->B8_YSERIE := SF1->F1_SERIE
							SB8->(MsUnLock())

						Else

							ConOut("GrPlus => Chapa " + SD1->(D1_COD + D1_LOCAL + D1_LOTECTL + D1_NUMLOTE) + " não encontrada para atribuicao do numero da NFT. " + AllTrim(DtoC(Date())) + " " + AllTrim(Time()) + ".")

						EndIf

						SD1->(DbSkip())

					EndDo

				EndIf

				ConOut("GrPlus => NFT No. " + AllTrim(SF1->F1_DOC) + "/" + AllTrim(SF1->F1_SERIE) + " da OP No. " + AllTrim(cNumOp) + " gerada com sucesso. " + AllTrim(DtoC(Date())) + " " + AllTrim(Time()) + ".")

			EndIf

		EndIf

		if oUtil <> nil
			oUtil:destroy()
		endIf

		ErrorBlock(ErrorBlock())

	End Sequence

Return {.T., "Sucesso."}


/*/{Protheus.doc} utilProducao
function ENTRASB6
Emite nota fictícia de entrada PODER DE TERCEIRO.
@author Kenny Roger Martins
@since 28/02/2019
@version ALL
/*/
User Function ENTRASB6(cNumOp)

	Local lGeraNf      := GetNewPar("GR_SERGENF", .F.) // Nota Fiscal - Gera ou Não
	Local cTesPar      := AllTrim(GetNewPar("GR_TESTERC", ""))
	Local cTipoPrc	   := GetNewPar("GR_SERPRCV", "C")
	Local cPkNota      := ""
	Local cPkProduto   := ""
	Local cSerOrige    := ""
	Local cSerieNfe    := ""
	Local qQUERY       := ""
	Local cSql         := ""
	Local nCustoNota   := 0
	Local nCustoReal   := 0
	Local nCustoEntera := 0
	Local aAutoSD1     := {}
	Local nPosDesc     := 0
	Local nDescEntera  := 0
	Local nDescUnit    := 0
	Local nDescTotal   := 0
	Local nDesconto    := 0
	Local nYtipeOp	   := ""
	Local cOperac      := ""
	Local aTesAux	   := {}
	Local cTesDest	   := ""
	Local aRetPrec     := {}

	ErrorBlock( {|e| u_GRChecEr(e)})

	Begin Sequence

		aTesAux :=  STRTOKARR(cTesPar, "/")

		If len(aTesAux) > 1

			aTesAux :=  STRTOKARR(aTesAux[2], ",")

			if len(aTesAux) == 1
				cTesDest    := aTesAux[1]
			elseIf len(aTesAux) > 1
				cTesDest    := aTesAux[1]
				cOperac 	:= aTesAux[2]
			EndIf

		EndIf

		SC2->(dbSetOrder(1))
		SC2->(msSeek(xFilial("SC2") + cNumOp))

		If (lGeraNf .And. SC2->C2_TPPR <> "E" .And. SC2->C2_YSITUAC $ "E/S/B")

			nYtipeOp := SC2->C2_YTIPO

			ConOut("GrPlus => Gerando documento de entrada sem valor fiscal. " + AllTrim(DtoC(Date())) + " " + AllTrim(Time()) + ".")

			//---------------------------------------------------------------
			// Verifica se o material é de terceiro.
			//---------------------------------------------------------------

			cSGBD := TCGetDB()

			cSql := "     SELECT F1_DOC,     F1_SERIE,   F1_FORNECE, F1_LOJA,    F1_COND,    F1_TPFRETE, "
			cSql += "            C2_YMP,     C2_YLOCMP,  C2_YLOTECT, C2_YNUMLOT, C2_YTOTITL, D1_COD,     "
			cSql += "            C2_YCOMPLE, C2_DATRF, "

			If nYtipeOp <> "R"
				cSql += "            D1_YCOMBRU, D1_YESPBRU, D1_YTOTBRU, D1_YCOMLIQ, "
				cSql += "            D1_YALTBRU, D1_YALTLIQ, D1_YESPLIQ, D1_YTOTLIQ,  "
			EndIf

			cSql += "            D1_FILIAL,  D1_FORNECE, D1_LOJA,    D1_DOC,     D1_SERIE,   			 "

			If nYtipeOp <> "R"
				cSql += "    D1_QUANT,   D1_VUNIT,   D1_TOTAL,   "
				cSql += "    B6_PRUNIT,  B6_QUANT,   			 "
				cSql += "    D1_ITEM,  D1_VALDESC,   			 "
			Else
				cSql += "   SUM(D1_QUANT) D1_QUANT,   SUM(D1_TOTAL) D1_TOTAL,   "
				cSql += "   SUM(D1_TOTAL)/SUM(B6_QUANT) B6_PRUNIT,  SUM(B6_QUANT) B6_QUANT, SUM(D1_VALDESC) D1_VALDESC, "
			EndIf

			cSql += "            D3_OP,      D3_LOTECTL, D3_IDENT,   D3_LOCAL,   D3_NUMLOTE, D3_YCAVALE, "
			cSql += "            D3_YENDERE, D3_YCLASSI, D3_YCLAPRO, D3_YCOMBRU, D3_YALTBRU, D3_YESPBRU, "
			cSql += "            D3_YTOTBRU, D3_YCOMLIQ, D3_YALTLIQ, D3_YESPLIQ, D3_YTOTLIQ, D3_QUANT,   "
			cSql += "            D3_COD,     C2_NUM,     C2_ITEM,    C2_YCOMITB, C2_YALTITB, C2_YESPITB, "
			cSql += "            C2_YTOTITB, C2_YCOMITL, C2_YALTITL, C2_YESPITL 					 "

			cSql += "       FROM " + RetSqlName("SC2") + " SC2 "

			cSql += " INNER JOIN " + RetSqlName("SD1") + " SD1 "
			cSql += "         ON SD1.D1_FILIAL  = '" + xFilial("SD1") + "'"

			If nYtipeOp <> "R"
				cSql += "        AND SD1.D1_COD     = SC2.C2_YMP "
				//cSql += "        AND SD1.D1_LOCAL   = SC2.C2_YLOCMP "  //Retirado essa validação para o sistema validar com a SB6 // Necessario porque quando faz uma transferencia o sistema não encontra a SB6
				cSql += "        AND SD1.D1_LOTECTL = SC2.C2_YLOTECT "
				cSql += "        AND SD1.D1_NUMLOTE = SC2.C2_YNUMLOT "
			Else

				If (cSGBD $ "ORACLE")
					cSql += "   AND SD1.D1_COD || SD1.D1_LOTECTL || SD1.D1_NUMLOTE "
				Else
					cSql += "   AND SD1.D1_COD + SD1.D1_LOTECTL + SD1.D1_NUMLOTE "
				EndIf

				cSql += " IN (													 "
				cSql += "  SELECT "

				If (cSGBD $ "ORACLE")
					cSql += " D3_COD || D3_LOTECTL || D3_NUMLOTE"
				Else
					cSql += " D3_COD + D3_LOTECTL + D3_NUMLOTE"
				EndIf

				cSql += " 		FROM " + RetSqlName("SD3") + " SD3IN "
				cSql += "  	WHERE
				cSql += "      SD3IN.D3_FILIAL  = '" + xFilial("SD3") + "'"

				If (cSGBD $ "ORACLE")
					cSql += "  AND SD3IN.D3_OP = SC2.C2_NUM || SC2.C2_ITEM || SC2.C2_SEQUEN || C2_ITEMGRD "
				Else
					cSql += "  AND SD3IN.D3_OP = SC2.C2_NUM + SC2.C2_ITEM + SC2.C2_SEQUEN + C2_ITEMGRD "
				EndIf

				cSql += "  	   AND SD3IN.D3_CF LIKE 'RE%' "
				cSql += "  )

			EndIf
			cSql += "        AND SD1.D1_QUANT 	> 0 "
			cSql += "        AND SD1.D_E_L_E_T_ = ' ' "

			cSql += " INNER JOIN " + RetSqlName("SD3") + " SD3 "
			cSql += "         ON SD3.D3_FILIAL  = '" + xFilial("SD3") + "'"

			If (cSGBD $ "ORACLE")
				cSql += "    AND SD3.D3_OP = C2_NUM || C2_ITEM || C2_SEQUEN || C2_ITEMGRD "
			Else
				cSql += "    AND SD3.D3_OP = C2_NUM + C2_ITEM + C2_SEQUEN + C2_ITEMGRD "
			EndIf

			cSql += "        AND SD3.D3_CF   LIKE 'PR%' "
			cSql += "        AND SD3.D3_ESTORNO = ' ' "
			cSql += "        AND SD3.D_E_L_E_T_ = ' ' "

			cSql += " INNER JOIN " + RetSqlName("SB6") + " SB6 "
			cSql += "         ON SB6.B6_FILIAL  = '" + xFilial("SB6") + "'"
			cSql += "        AND SB6.B6_DOC     = SD1.D1_DOC "
			cSql += "        AND SB6.B6_SERIE   = SD1.D1_SERIE "
			cSql += "        AND SB6.B6_CLIFOR  = SD1.D1_FORNECE "
			cSql += "        AND SB6.B6_LOJA    = SD1.D1_LOJA "
			cSql += "        AND SB6.B6_PRODUTO = SD1.D1_COD "
			cSql += "        AND SB6.B6_IDENT   = SD1.D1_IDENTB6 "
			cSql += "        AND SB6.B6_SALDO   > 0 "
			cSql += "        AND SB6.B6_TIPO    = 'D' "
			cSql += "        AND SB6.B6_LOCAL   = SD1.D1_LOCAL   "
			cSql += "        AND SB6.D_E_L_E_T_ = ' ' "

			cSql += " INNER JOIN " + RetSqlName("SF1") + " SF1  "
			cSql += "         ON SF1.F1_FILIAL  = '" + xFilial("SF1") + "'"
			cSql += "        AND SF1.F1_DOC     = SD1.D1_DOC "
			cSql += "        AND SF1.F1_SERIE   = SD1.D1_SERIE "
			cSql += "        AND SF1.F1_FORNECE = SD1.D1_FORNECE "
			cSql += "        AND SF1.F1_LOJA    = SD1.D1_LOJA "
			cSql += "        AND SF1.D_E_L_E_T_ = ' ' "

			cSql += "      WHERE SC2.C2_FILIAL  = '" + xFilial("SC2") + "'"
			cSql += "        AND SC2.C2_NUM     = '" + cNumOp + "'"
			cSql += "        AND SC2.D_E_L_E_T_ = ' ' "

			cSql += "   GROUP BY F1_DOC,     F1_SERIE,   F1_FORNECE, F1_LOJA,    F1_COND,    F1_TPFRETE, "
			cSql += "            C2_YMP,     C2_YLOCMP,  C2_YLOTECT, C2_YNUMLOT, C2_YTOTITL, D1_COD,     "
			cSql += "            C2_YCOMPLE, C2_DATRF, "

			If nYtipeOp <> "R"
				cSql += "            D1_YCOMBRU, D1_YESPBRU, D1_YTOTBRU, D1_YCOMLIQ, "
				cSql += "            D1_YALTLIQ, D1_YALTBRU, D1_YESPLIQ, D1_YTOTLIQ, D1_QUANT,     "
			EndIf

			cSql += "            D1_FILIAL,  D1_FORNECE, D1_LOJA,    D1_DOC,     D1_SERIE,  "

			If nYtipeOp <> "R"
				cSql += "    D1_VUNIT,    "
				cSql += "    D1_TOTAL,    "
				cSql += "    D1_ITEM,     "
				cSql += "    B6_QUANT,    "
				cSql += "    D1_VALDESC,  "
				cSql += "    B6_PRUNIT,   "

			EndIf

			cSql += "            D3_OP,      D3_LOTECTL, D3_IDENT,   D3_LOCAL,   D3_NUMLOTE, D3_YCAVALE, "
			cSql += "            D3_YENDERE, D3_YCLASSI, D3_YCLAPRO, D3_YCOMBRU, D3_YALTBRU, D3_YESPBRU, "
			cSql += "            D3_YTOTBRU, D3_YCOMLIQ, D3_YALTLIQ, D3_YESPLIQ, D3_YTOTLIQ, D3_QUANT,   "
			cSql += "            D3_COD,     C2_NUM,     C2_ITEM,    C2_YCOMITB, C2_YALTITB, C2_YESPITB, "
			cSql += "            C2_YTOTITB, C2_YCOMITL, C2_YALTITL, C2_YESPITL   "

			cSql += "   ORDER BY D1_FILIAL, D1_FORNECE, D1_LOJA, D1_DOC, D1_SERIE "

			If nYtipeOp <> "R"
				cSql += "  ,D1_ITEM"
			EndIf

			TCQUERY cSql NEW ALIAS qQUERY

			While qQUERY->(!Eof())

				If (Empty(cTesDest) .or. posicione("SF4", 1, xFilial("SF4") + cTesDest, "ALLTRIM(F4_ESTOQUE)") <> 'N')
					Return {.F., "2 - Tes inválida. Favor verificar o parâmetro GR_TESTERC. A Tes está em branco ou para movimentar estoque, porém ela não pode movimentar estoque. Tes: " + cTesDest}
				EndIf

				// If qQUERY->C2_YTOTITL == 0
				// 	nCustoEntera := 0
				// EndIf

				If cPkProduto <> qQUERY->(C2_YMP + C2_YLOCMP + C2_YLOTECT + C2_YNUMLOT) .OR. nYtipeOp == "R"

					If !Empty(cPkProduto)

						If cTipoPrc == "C"

							// Posição dos campos
							nPosQtde    := aScan(aAutoSD1[Len(aAutoSD1)], {|x| AllTrim(x[1]) == "D1_QUANT"})
							nPosPreco   := aScan(aAutoSD1[Len(aAutoSD1)], {|x| AllTrim(x[1]) == "D1_VUNIT"})
							nPosTotal   := aScan(aAutoSD1[Len(aAutoSD1)], {|x| AllTrim(x[1]) == "D1_TOTAL"})
							nPosDesc    := aScan(aAutoSD1[Len(aAutoSD1)], {|x| AllTrim(x[1]) == "D1_VALDESC"})

							// Valor da variáveis
							nPrecoTotal := Round((nCustoTotal + nCustoEntera) - (nCustoNota - nPrecoTotal), TamSx3("D1_TOTAL")[2])
							nPrecoUnit  := Round(nPrecoTotal / aAutoSD1[Len(aAutoSD1)][nPosQtde][2], TamSX3("D1_VUNIT")[2])

							// Atribui valores ao Array
							aAutoSD1[Len(aAutoSD1)][nPosPreco][2] := nPrecoUnit
							aAutoSD1[Len(aAutoSD1)][nPosTotal][2] := nPrecoTotal

							If nDescTotal > 0
								aAutoSD1[Len(aAutoSD1)][nPosDesc][2] += Round(nDescTotal, TamSx3("D1_VALDESC")[2])
							EndIf

						EndIf

						nPrecoTotal  := 0
						nPrecoUnit   := 0
						nCustoEntera := 0
						nCustoNota   := 0
						// Desconto
						nDescTotal   := 0
						nDescEntera  := 0
						nDescUnit    := 0
						nDesconto    := 0

					EndIf

					//-----------------------------------------------------------------
					// Verifica se tem sobra de Entera para incluir na nota fiscal.
					//-----------------------------------------------------------------
					If qQUERY->C2_YTOTITL > 0

						// Calcula desconto Unitário
						nDescUnit := qQUERY->D1_VALDESC / Posicione("SB8", 3, xFilial("SB8") + qQUERY->(C2_YMP+C2_YLOCMP+C2_YLOTECT+C2_YNUMLOT), "B8_QTDORI")
						nDescEntera := Round(qQUERY->C2_YTOTITL * nDescUnit, TamSx3("D1_VALDESC")[2])
						nDescTotal -= nDescEntera

						If cTipoPrc == "P"

							SB5->(DbGoTop())
							nPreco := Posicione("SB5", 1, xFilial("SB5") + qQUERY->C2_YMP, "B5_YVLRPTA")

							// https://totvsleste.freshdesk.com/a/tickets/1947
							If nPreco <= 0

								aRetPrec := GetPauta(qQUERY->C2_YMP)

								if aRetPrec[1]
									nPreco := aRetPrec[2]
								Else
									Return {.F., aRetPrec[3]}
								EndIf

							EndIf

						Else

							nPreco := (qQUERY->B6_PRUNIT * qQUERY->B6_QUANT) / Posicione("SB8", 3, xFilial("SB8") + qQUERY->(C2_YMP+C2_YLOCMP+C2_YLOTECT+C2_YNUMLOT), "B8_QTDORI")

						EndIf

						If nPreco <= 0
							Return {.F., "5) O preço do produto não pode ser Zero!" + Chr(10) + Chr(10) + "Favor conferir o custo B8_YCUSTO ou o preço de pauta B5_YVLRPTA."}
						EndIf

						nCustoEntera := Round(qQUERY->C2_YTOTITL * nPreco, TamSx3("D1_TOTAL")[2])
						nCustoNota += nCustoEntera

					EndIf

					cSql := " SELECT SUM(D3_QUANT) AS D3_QUANT "
					cSql += "   FROM " + RetSqlName("SD3") + " SD3"
					cSql += "  WHERE SD3.D3_FILIAL  = '" + xFilial("SD3") + "'"
					cSql += "    AND SD3.D3_OP      BETWEEN '" + qQUERY->(C2_NUM + C2_ITEM) + "' AND '" + qQUERY->(C2_NUM + C2_ITEM) + "ZZZZZZ' "
					cSql += "    AND SD3.D3_CF      = 'PR0'"
					cSql += "    AND SD3.D3_ESTORNO = ' '"
					cSql += "    AND SD3.D_E_L_E_T_ = ' '"

					TCQUERY cSql NEW ALIAS qQUANT

					// nCustoTotal := Posicione("SB8", 3, xFilial("SB8") + qQUERY->(C2_YMP + C2_YLOCMP + C2_YLOTECT + C2_YNUMLOT), "B8_YCUSTO") - nCustoEntera
					nCustoTotal := qQUERY->B6_PRUNIT * qQUERY->B6_QUANT - nCustoEntera
					nPrecoUnit  := Round(nCustoTotal / qQUANT->D3_QUANT, TamSX3("D1_VUNIT")[2])

					// Calcula desconto unitário
					// Desconto TOTAL do ITEM
					nDescTotal := qQUERY->D1_VALDESC - nDescEntera
					nDescUnit := nDescTotal / qQUANT->D3_QUANT
					nDesconto := Round(nDescUnit * qQUERY->D3_QUANT, TamSX3("D1_VALDESC")[2])

					// If nDesconto == 0
					// 	nDesconto := 1 / VAL(PADR("1",TamSX3("D1_VALDESC")[2]+1,"0"))
					// EndIf

					// If nDescTotal < nDesconto
					// 	nDesconto := nDescTotal
					// 	nDescTotal := 0
					// Else
					// 	nDescTotal -= nDesconto
					// EndIf

					qQUANT->(DbCloseArea())

					cPkProduto := qQUERY->(C2_YMP + C2_YLOCMP + C2_YLOTECT + C2_YNUMLOT)

				EndIf

				If cPkNota <> qQUERY->(F1_DOC + F1_SERIE + F1_FORNECE + F1_LOJA)

					If !Empty(cPkNota)
						aRet := EXEENTSB6(aAutoSF1, aAutoSD1)
						If !aRet[1]
							qQUERY->(DbCloseArea())
							Return aRet
						EndIf
					EndIf

					cPkNota  := qQUERY->(F1_DOC + F1_SERIE + F1_FORNECE + F1_LOJA)
					cItemLin := "00"
					aAutoSF1 := {}
					aAutoSD1 := {}

					//-----------------------------------------------------------------
					// Verifica caso já tenha a nota da primeira serrada.
					//-----------------------------------------------------------------
					cSerOrige := qQUERY->F1_SERIE

					SF1->(DbSetOrder(1))
					If SF1->(DbSeek(xFilial("SF1") + qQUERY->(F1_DOC + F1_SERIE + F1_FORNECE + F1_LOJA)))
						If SubStr(cSerOrige, 1, 1) == "S"
							cSerieNfe := Soma1(cSerOrige)
						Else
							cSerieNfe := "S01"
						EndIf
					Else
						cSerieNfe := "S01"
					EndIf

					//-----------------------------------------------------------------
					// Como pode haver produção parcial verifica se já existe nota
					// de outra produção.
					//-----------------------------------------------------------------
					lContinue := .T.

					While lContinue
						If SF1->(DbSeek(xFilial("SF1") + qQUERY->(F1_DOC + cSerieNfe + F1_FORNECE + F1_LOJA)))
							cSerieNfe := Soma1(cSerieNfe)
						Else
							lContinue := .F.
						EndIf
					EndDo

					aAdd(aAutoSF1, {"F1_FILIAL",  xFilial("SF1"),     nil})
					aAdd(aAutoSF1, {"F1_HORA",    Time(),             nil})
					aAdd(aAutoSF1, {"F1_TIPO",    "B",                nil})
					aAdd(aAutoSF1, {"F1_FORMUL",  "N",                nil})
					aAdd(aAutoSF1, {"F1_DOC",     qQUERY->F1_DOC, 	  nil})
					aAdd(aAutoSF1, {"F1_SERIE",   cSerieNfe,          nil})
					aAdd(aAutoSF1, {"F1_EMISSAO", StoD(qQUERY->(C2_DATRF)), nil})
					aAdd(aAutoSF1, {"F1_ESPECIE", "NFE",              nil})
					aAdd(aAutoSF1, {"F1_FORNECE", qQUERY->F1_FORNECE, nil})
					aAdd(aAutoSF1, {"F1_LOJA",    qQUERY->F1_LOJA,    nil})
					aAdd(aAutoSF1, {"F1_COND",    qQUERY->F1_COND,    nil})
					aAdd(aAutoSF1, {"F1_YDOCEXT", "_OP" + cNumOp,     nil})
					aAdd(aAutoSF1, {"F1_TPFRETE", qQUERY->F1_TPFRETE, nil})

					//-----------------------------------------------------------------
					// Verifica se tem sobra de Entera para incluir na nota fiscal.
					//-----------------------------------------------------------------
					If qQUERY->C2_YTOTITL > 0

						aAutoLin := {}
						aAdd(aAutoLin, {"D1_COD",     qQUERY->C2_YMP,     nil})
						if !empty(cOperac)
							aAdd(aAutoLin, {"D1_OPER",     cOperac,            nil})
						EndIf
						aAdd(aAutoLin, {"D1_TES",     cTesDest,           nil})
						aAdd(aAutoLin, {"D1_LOCAL",   qQUERY->C2_YLOCMP,  nil})
						aAdd(aAutoLin, {"D1_LOTECTL", If(Len(AllTrim(qQUERY->C2_YLOTECT)) < TamSX3("C2_YLOTECT")[1], AllTrim(qQUERY->C2_YLOTECT) + qQUERY->C2_YCOMPLE, SubStr(AllTrim(qQUERY->C2_YLOTECT), 2, Len(AllTrim(qQUERY->C2_YLOTECT))) + qQUERY->C2_YCOMPLE), nil})
						aAdd(aAutoLin, {"D1_NUMLOTE", "",                 nil})
						aAdd(aAutoLin, {"D1_YCOMBRU", qQUERY->C2_YCOMITB, nil})
						aAdd(aAutoLin, {"D1_YALTBRU", qQUERY->C2_YALTITB, nil})
						aAdd(aAutoLin, {"D1_YESPBRU", qQUERY->C2_YESPITB, nil})
						aAdd(aAutoLin, {"D1_YTOTBRU", qQUERY->C2_YTOTITB, nil})
						aAdd(aAutoLin, {"D1_YCOMLIQ", qQUERY->C2_YCOMITL, nil})
						aAdd(aAutoLin, {"D1_YALTLIQ", qQUERY->C2_YALTITL, nil})
						aAdd(aAutoLin, {"D1_YESPLIQ", qQUERY->C2_YESPITL, nil})
						aAdd(aAutoLin, {"D1_YTOTLIQ", qQUERY->C2_YTOTITL, nil})
						aAdd(aAutoLin, {"D1_QUANT",   qQUERY->C2_YTOTITL, nil})
						aAdd(aAutoLin, {"D1_VUNIT",   Round(nCustoEntera / qQUERY->C2_YTOTITL, TamSX3("D1_VUNIT")[2]) , nil})
						aAdd(aAutoLin, {"D1_TOTAL",   nCustoEntera,       nil})
						aAdd(aAutoLin, {"D1_VALDESC", nDescEntera,        nil})
						aAdd(aAutoSD1, aAutoLin)

					EndIf

				EndIf

				If cTipoPrc == "C"

					nPrecoTotal := Round(nPrecoUnit * qQUERY->D3_QUANT, TamSX3("D1_TOTAL")[2])
					nCustoNota  += nPrecoTotal

				ElseIf cTipoPrc == "P"

					SB5->(DbGoTop())
					//O sistema estava com SF3 posicionada de forma indevida, para um produto diferente da op  https://totvsleste.freshdesk.com/a/tickets/1921
					nPrecoUnit  := Posicione("SB5", 1, xFilial("SB5") + qQUERY->D3_COD, "B5_YVLRPTA")
					nPrecoTotal := Round(nPrecoUnit * qQUERY->D3_QUANT, TamSX3("D1_TOTAL")[2])
					//https://totvsleste.freshdesk.com/a/tickets/1947
					//o sistema apresenta erro, mas o usuário não sabe de onde vem o preço
					if(nPrecoUnit == 0 )
						aRet := {.F., "2) B5_YVLRPTA - Valor de pauta esta vazio "+ qQUERY->D3_COD }
						qQUERY->(DbCloseArea()) // Ajuste, quando finalizava e tentasse novamente sem fechar a tela,o sistema apresentava erro log devido o alias estar abert.
						Return aRet
					EndIF

				EndIf

				// Calcula Desconto Proporcional
				nDesconto := Round(nDescUnit * qQUERY->D3_QUANT, TamSX3("D1_VALDESC")[2])

				If nDesconto == 0
					nDesconto := 1 / VAL(PADR("1",TamSX3("D1_VALDESC")[2]+1,"0"))
				EndIf

				If nDescTotal < nDesconto
					nDesconto := nDescTotal
					nDescTotal := 0
				Else
					nDescTotal -= nDesconto
				EndIf

				// Em caso de OP diferente de 'Serrada/Desdobramento', replica valores Unitarios, Total e Desconto
				// vindos da nota de entrada - https://totvsleste.freshdesk.com/a/tickets/6302
				If !Posicione("ZH7", 1, xFilial("ZH7") + cNumOp, "ZH7_PROCES") $ "S/D/R"
					nPrecoUnit  := qQUERY->D1_VUNIT
					nPrecoTotal := qQUERY->D1_TOTAL
					nDesconto   := qQUERY->D1_VALDESC
				EndIf

				aAutoLin := {}
				aAdd(aAutoLin, {"D1_COD",     qQUERY->D3_COD,     nil})
				if !empty(cOperac)
					aAdd(aAutoLin, {"D1_OPER",     cOperac,            nil})
				EndIf
				aAdd(aAutoLin, {"D1_TES",     cTesDest,           nil})
				aAdd(aAutoLin, {"D1_LOCAL",   qQUERY->D3_LOCAL,   nil})
				aAdd(aAutoLin, {"D1_LOTECTL", qQUERY->D3_LOTECTL, nil})
				aAdd(aAutoLin, {"D1_NUMLOTE", qQUERY->D3_NUMLOTE, nil})
				aAdd(aAutoLin, {"D1_YCAVALE", qQUERY->D3_YCAVALE, nil})
				aAdd(aAutoLin, {"D1_YENDERE", qQUERY->D3_YENDERE, nil})
				aAdd(aAutoLin, {"D1_YCLASSI", qQUERY->D3_YCLASSI, nil})
				aAdd(aAutoLin, {"D1_YCLAPRO", qQUERY->D3_YCLAPRO, nil})
				aAdd(aAutoLin, {"D1_YCOMBRU", qQUERY->D3_YCOMBRU, nil})
				aAdd(aAutoLin, {"D1_YALTBRU", qQUERY->D3_YALTBRU, nil})
				aAdd(aAutoLin, {"D1_YESPBRU", qQUERY->D3_YESPBRU, nil})
				aAdd(aAutoLin, {"D1_YTOTBRU", qQUERY->D3_YTOTBRU, nil})
				aAdd(aAutoLin, {"D1_YCOMLIQ", qQUERY->D3_YCOMLIQ, nil})
				aAdd(aAutoLin, {"D1_YALTLIQ", qQUERY->D3_YALTLIQ, nil})
				aAdd(aAutoLin, {"D1_YESPLIQ", qQUERY->D3_YESPLIQ, nil})
				aAdd(aAutoLin, {"D1_YTOTLIQ", qQUERY->D3_YTOTLIQ, nil})
				aAdd(aAutoLin, {"D1_YVOLUME", 1,                  nil})
				aAdd(aAutoLin, {"D1_QUANT",   qQUERY->D3_QUANT,   nil})
				aAdd(aAutoLin, {"D1_VUNIT",   nPrecoUnit,         nil})
				aAdd(aAutoLin, {"D1_TOTAL",   nPrecoTotal,        nil})
				aAdd(aAutoLin, {"D1_VALDESC", nDesconto,          nil})
				aAdd(aAutoSD1, aAutoLin)

				qQUERY->(DbSkip())

			EndDo

			qQUERY->(DbCloseArea())

			If !Empty(cPkNota)

				If cTipoPrc == "C"

					nPosQtde    := aScan(aAutoSD1[Len(aAutoSD1)], {|x| AllTrim(x[1]) == "D1_QUANT"})
					nPosPreco   := aScan(aAutoSD1[Len(aAutoSD1)], {|x| AllTrim(x[1]) == "D1_VUNIT"})
					nPosTotal   := aScan(aAutoSD1[Len(aAutoSD1)], {|x| AllTrim(x[1]) == "D1_TOTAL"})
					nPosDesc    := aScan(aAutoSD1[Len(aAutoSD1)], {|x| AllTrim(x[1]) == "D1_VALDESC"})

					nPrecoTotal := Round((nCustoTotal + nCustoEntera) - (nCustoNota - nPrecoTotal), TamSx3("D1_TOTAL")[2])
					nPrecoUnit  := Round(nPrecoTotal / aAutoSD1[Len(aAutoSD1)][nPosQtde][2], TamSX3("D1_VUNIT")[2])

					aAutoSD1[Len(aAutoSD1)][nPosPreco][2] := nPrecoUnit
					aAutoSD1[Len(aAutoSD1)][nPosTotal][2] := nPrecoTotal

					If nDescTotal > 0
						aAutoSD1[Len(aAutoSD1)][nPosDesc][2] += Round(nDescTotal, TamSx3("D1_VALDESC")[2])
					EndIf

				Endif

				aRet := EXEENTSB6(aAutoSF1, aAutoSD1)
				If !aRet[1]
					Return aRet
				EndIf

			EndIf

			ConOut("GrPlus => Documento de entrada sem valor fiscal gerado com sucesso! " + AllTrim(DtoC(Date())) + " " + AllTrim(Time()) + ".")

		EndIf

		ErrorBlock(ErrorBlock())

	End Sequence


Return {.T., "Sucesso."}


/*/{Protheus.doc} utilProducao
function EXEENTSB6
Emite nota fisctícia de entrada PODER DE TERCEIRO.
@author Kenny Roger Martins
@since 28/02/2019
@version ALL
/*/
Static Function EXEENTSB6(aAutoSF1, aAutoSD1)

	Local cMsgErro := ""
	Local nX       := 0

	Private lMsErroAuto	   := .F.
	Private lMsHelpAuto	   := .T.
	Private lAutoErrNoFile := .T.
	Private lGrPlus        := .T.

	// U_TOTVSES()

	MsExecAuto({|x,y,z| Mata103(x,y,z)}, aAutoSF1, aAutoSD1, 3)

	If lMsErroAuto

		If !(IsBlind())
			oUtil := util():new()
			cMsgErro := oUtil:getAutoError()
			oUtil:destroy()
		Else
			cMsgErro := oUtil:getAutoError()
		EndIf

		Return {.F., cMsgErro}

	Else

		For nX := 1 To Len(aAutoSD1)

			nPosCod     := aScan(aAutoSD1[nX], {|x| AllTrim(x[1]) == "D1_COD"})
			nPosLocal   := aScan(aAutoSD1[nX], {|x| AllTrim(x[1]) == "D1_LOCAL"})
			nPosLoteCtl := aScan(aAutoSD1[nX], {|x| AllTrim(x[1]) == "D1_LOTECTL"})
			nPosNumLote := aScan(aAutoSD1[nX], {|x| AllTrim(x[1]) == "D1_NUMLOTE"})
			nPosTotal   := aScan(aAutoSD1[nX], {|x| AllTrim(x[1]) == "D1_TOTAL"})

			SB8->(DbSetOrder(3))

			If SB8->(DbSeek(xFilial("SB8") + aAutoSD1[nX][nPosCod][2] + aAutoSD1[nX][nPosLocal][2] + aAutoSD1[nX][nPosLoteCtl][2] + aAutoSD1[nX][nPosNumLote][2]))

				RecLock("SB8", .F.)
				SB8->B8_YCUSTO := aAutoSD1[nX][nPosTotal][2]
				SB8->(MsUnLock())

			EndIf

		Next

	EndIf

Return {.T., "Sucesso."}


/*/{Protheus.doc} utilProducao
function SAIDASB6
Emite nota fictícia de saída PODER DE TERCEIRO.
@author Kenny Roger Martins
@since 28/02/2019
@version ALL
/*/
User Function SAIDASB6(cNumOp)

	Local lGeraNf  := getMv("GR_SERGENF") // Nota Fiscal - Gera ou Não
	Local cTesAux  := getMv("GR_SERTESP") // Nota Fiscal - Tipo de Saída para material de terceiros
	Local cCondPed := GETNEWPAR("GR_SERCOND", "001") //Condição de pagamento caso a condição da primeira nota de entrada esteja em branco
	Local cItemLin := "00"
	Local aAutoSC5 := {}
	Local aAutoSC6 := {}
	Local cPkNota  := ""
	Local qQUERY   := ""
	Local cSql     := ""
	Local cTesPed  := ""
	Local cOperac  := ""
	Local aTesAux  := {}
	// Local nQtdSD1  := 0
	// Local nVuniSD1 := 0
	// Local nVTotSD1 := 0
	Local dDataFat := dDataBase

	// U_TOTVSES()
	ErrorBlock( {|e| u_GRChecEr(e)})

	Begin Sequence

		aTesAux :=  STRTOKARR(cTesAux, ",")

		if len(aTesAux) == 1
			cTesPed   := cTesAux
		ElseIf len(aTesAux) > 1
			cTesPed   := aTesAux[1]
			cOperac   := aTesAux[2]
		EndIf

		SC2->(dbSetOrder(1))
		SC2->(msSeek(xFilial("SC2") + cNumOp))

		If (lGeraNf .And. SC2->C2_TPPR <> "E" .And. SC2->C2_YSITUAC $ "E/S/B")

			//---------------------------------------------------------------
			// Verifica se o material é de terceiro.
			//---------------------------------------------------------------

			cSGBD := TCGetDB()

			cSql := "     SELECT F1_DOC,     F1_SERIE,   F1_FORNECE, F1_LOJA,    F1_COND,    F1_TPFRETE, "
			cSql += "            C2_YMP,     C2_YLOCMP,  C2_YLOTECT, C2_YNUMLOT, C2_YTOTITL, D1_COD,     "
			cSql += "            C2_YCOMPLE, D1_YCOMBRU, D1_YALTBRU, D1_YESPBRU, D1_YTOTBRU, D1_YCOMLIQ, "
			cSql += "            D1_YALTLIQ, D1_YESPLIQ, D1_YTOTLIQ, D1_QUANT,   D1_VUNIT,   D1_TOTAL,   "
			cSql += "            D1_FILIAL,  D1_FORNECE, D1_LOJA,    D1_DOC,     D1_SERIE,   D1_ITEM,    "
			cSql += "            D1_LOCAL,   D1_NUMSEQ,  D1_VALDESC, C2_DATRF                            "

			cSql += "       FROM " + RetSqlName("SC2") + " SC2 "

			cSql += " INNER JOIN " + RetSqlName("SD1") + " SD1 "
			cSql += "         ON SD1.D1_FILIAL  = '" + xFilial("SD1") + "'"

			If SC2->C2_YTIPO <> "R"
				cSql += "        AND SD1.D1_COD     = SC2.C2_YMP "
				//cSql += "        AND SD1.D1_LOCAL   = SC2.C2_YLOCMP "  //Retirado essa validação para o sistema validar com a SB6 // Necessario porque quando faz uma transferencia o sistema não encontra a SB6
				cSql += "        AND SD1.D1_LOTECTL = SC2.C2_YLOTECT "
				cSql += "        AND SD1.D1_NUMLOTE = SC2.C2_YNUMLOT "
			Else

				If (cSGBD $ "ORACLE")
					cSql += "   AND SD1.D1_COD || SD1.D1_LOTECTL || SD1.D1_NUMLOTE "
				Else
					cSql += "   AND SD1.D1_COD + SD1.D1_LOTECTL + SD1.D1_NUMLOTE "
				EndIf

				cSql += " IN (													 "
				cSql += "  SELECT "

				If (cSGBD $ "ORACLE")
					cSql += "   D3_COD || D3_LOTECTL || D3_NUMLOTE "
				Else
					cSql += "   D3_COD + D3_LOTECTL+ D3_NUMLOTE "
				EndIf

				cSql += " 		FROM " + RetSqlName("SD3") + " SD3IN "
				cSql += "  	WHERE
				cSql += "      SD3IN.D3_FILIAL  = '" + xFilial("SD3") + "'"

				If (cSGBD $ "ORACLE")
					cSql += "  AND SD3IN.D3_OP  = C2_NUM || C2_ITEM || C2_SEQUEN || C2_ITEMGRD "
				Else
					cSql += "  AND SD3IN.D3_OP  = C2_NUM + C2_ITEM + C2_SEQUEN + C2_ITEMGRD "
				EndIf

				cSql += "  	   AND SD3IN.D3_CF  LIKE 'RE%' "
				cSql += "  )

			EndIf

			cSql += "        AND SD1.D_E_L_E_T_ = ' ' "

			cSql += " INNER JOIN " + RetSqlName("SB6") + " SB6 "
			cSql += "         ON SB6.B6_FILIAL  = '" + xFilial("SB6") + "'"
			cSql += "        AND SB6.B6_DOC     = SD1.D1_DOC "
			cSql += "        AND SB6.B6_SERIE   = SD1.D1_SERIE "
			cSql += "        AND SB6.B6_CLIFOR  = SD1.D1_FORNECE "
			cSql += "        AND SB6.B6_LOJA    = SD1.D1_LOJA "
			cSql += "        AND SB6.B6_PRODUTO = SD1.D1_COD "
			cSql += "        AND SB6.B6_IDENT   = SD1.D1_IDENTB6 "
			cSql += "        AND SB6.B6_SALDO   > 0 "
			cSql += "        AND SB6.B6_TIPO    = 'D' "
			cSql += "        AND SB6.B6_LOCAL   = SD1.D1_LOCAL   "
			cSql += "        AND SB6.D_E_L_E_T_ = ' ' "

			cSql += " INNER JOIN " + RetSqlName("SF1") + " SF1  "
			cSql += "         ON SF1.F1_FILIAL  = '" + xFilial("SF1") + "'"
			cSql += "        AND SF1.F1_DOC     = SD1.D1_DOC "
			cSql += "        AND SF1.F1_SERIE   = SD1.D1_SERIE "
			cSql += "        AND SF1.F1_FORNECE = SD1.D1_FORNECE "
			cSql += "        AND SF1.F1_LOJA    = SD1.D1_LOJA "
			cSql += "        AND SF1.D_E_L_E_T_ = ' ' "

			cSql += "      WHERE SC2.C2_FILIAL  = '" + xFilial("SC2") + "'"
			cSql += "        AND SC2.C2_NUM     = '" + cNumOp + "'"
			cSql += "        AND SF1.F1_YDOCEXT <> '_OP" + cNumOp + "'" //Ajuste porque op de retrabalho estava pegando as duas notas
			cSql += "        AND SC2.D_E_L_E_T_ = ' ' "

			cSql += "   GROUP BY F1_DOC,     F1_SERIE,   F1_FORNECE, F1_LOJA,    F1_COND,    F1_TPFRETE, "
			cSql += "            C2_YMP,     C2_YLOCMP,  C2_YLOTECT, C2_YNUMLOT, C2_YTOTITL, D1_COD,     "
			cSql += "            C2_YCOMPLE, D1_YCOMBRU, D1_YALTBRU, D1_YESPBRU, D1_YTOTBRU, D1_YCOMLIQ, "
			cSql += "            D1_YALTLIQ, D1_YESPLIQ, D1_YTOTLIQ, D1_QUANT,   D1_VUNIT,   D1_TOTAL,   "
			cSql += "            D1_FILIAL,  D1_FORNECE, D1_LOJA,    D1_DOC,     D1_SERIE,   D1_ITEM,    "
			cSql += "            D1_LOCAL,   D1_NUMSEQ,  D1_VALDESC, C2_DATRF                            "

			cSql += "   ORDER BY D1_FILIAL, D1_FORNECE, D1_LOJA, D1_DOC, D1_SERIE, D1_ITEM "

			TCQUERY cSql NEW ALIAS qQUERY

			cItemLin  := "00"
			aAutoSC5 := {}
			aAutoSC6 := {}
			cPkNota  := ""
			dDataFat := StoD(qQUERY->C2_DATRF)

			While qQUERY->(!Eof())

				If cPkNota <> qQUERY->(F1_DOC + F1_SERIE + F1_FORNECE + F1_LOJA)

					If !Empty(cPkNota)
						aRet := EXEPEDSB6(aAutoSC5, aAutoSC6, dDataFat)
						If !aRet[1]
							qQUERY->(DbCloseArea())
							Return aRet
						EndIf
					EndIf

					cPkNota  := qQUERY->(F1_DOC + F1_SERIE + F1_FORNECE + F1_LOJA)
					cItemLin := "00"
					aAutoSC5 := {}
					aAutoSC6 := {}

					aAdd(aAutoSC5, {"C5_TIPO",    "N",                Nil})
					aAdd(aAutoSC5, {"C5_CLIENTE", qQUERY->F1_FORNECE, Nil})
					aAdd(aAutoSC5, {"C5_LOJACLI", qQUERY->F1_LOJA,    Nil})
					aAdd(aAutoSC5, {"C5_CONDPAG", If(Empty(qQUERY->F1_COND), cCondPed , qQUERY->F1_COND), Nil})
					aAdd(aAutoSC5, {"C5_EMISSAO", dDataFat,    Nil})

					iF SC5->(FieldPos("C5_YOP")) > 0
						aAdd(aAutoSC5, {"C5_YOP", cNumOp ,    Nil})
					EndIF

				EndIf

				//Quando a nota possui desconto o sistema joga como valor cheio e apresenta mensagem de ajuda informando que o valor não pode ser diferente da entrada.
				//O sistema faz um arredondamento ficando diferente do arredondamento que esta na nota  exemplo : 11,191 * 166,800 = 1.866,659, porem o protheus so aceita 1.866,660 que esta no custo da SB6
				//https://totvsleste.freshdesk.com/a/tickets/1830
				IF (qQUERY->D1_VALDESC > 0)
					//ajustado porque o sistema estava dando uma diferença de um centavo no item.
					//Retirado o no round. o sistema estava apresentando erro com o ROUND:https://totvsleste.freshdesk.com/a/tickets/2184
					//nVuniSD1 := round((qQUERY->D1_QUANT * qQUERY->D1_VUNIT - qQUERY->D1_VALDESC)/qQUERY->D1_QUANT, TamSx3("C6_PRCVEN")[2])
					nVuniSD1 := (qQUERY->D1_QUANT * qQUERY->D1_VUNIT - qQUERY->D1_VALDESC)/qQUERY->D1_QUANT

					nVTotSD1 := A410Arred(qQUERY->D1_TOTAL - qQUERY->D1_VALDESC , "C6_VALOR")
				Else
					nVuniSD1 := qQUERY->D1_VUNIT
					nVTotSD1 := qQUERY->D1_TOTAL  //5,795 * 483  Arredondamento da 2798.99 e o total da 2798.98 Comentado porque o sistem pega o mesmo valor que esta no D1_TOTAL. Porem a marcel esta com Noround no gatilho D1_TOTAL  https://totvsleste.freshdesk.com/a/tickets/2119 // A410Arred(qQUERY->D1_QUANT * qQUERY->D1_VUNIT, "C6_VALOR")
				EndIf

				sf4->(dbsetorder(1))
				If !sf4->(dbseek(xfilial("SF4") + cTesPed))
					aRet := {.f.,"Parametro:GR_SERTESP - Tipo de Saída para material de terceiros não cadastrado" + " valor:" + cTesPed}
					qQUERY->(DbCloseArea())
					Return aRet
				EndIf

				aAutoLin := {}
				cItemLin := Soma1(cItemLin)
				aAdd(aAutoLin, {"C6_ITEM",    cItemLin,           NIL})
				aAdd(aAutoLin, {"C6_PRODUTO", qQUERY->D1_COD,     NIL})
				aAdd(aAutoLin, {"C6_LOCAL",   qQUERY->D1_LOCAL,   NIL})
				if !empty(cOperac)
					aAdd(aAutoLin, {"C6_OPER",     cOperac,       NIL})
				EndIf
				aAdd(aAutoLin, {"C6_TES",     cTesPed,            NIL})
				aAdd(aAutoLin, {"C6_QTDVEN",  qQUERY->D1_QUANT,   NIL})
				aAdd(aAutoLin, {"C6_PRCVEN",  nVuniSD1		  ,   NIL})
				//aAdd(aAutoLin, {"C6_VALOR",   nVTotSD1		  ,   NIL}) Retirado daqui e incluido no final devido o sistema apresentar erro a410total quando da uma diferença que foi digitado na nota de entrada e os outros dados de retorno não estão preenchidos ao ticket :https://totvsleste.freshdesk.com/a/tickets/2617
				//aAdd(aAutoLin, {"C6_VALDESC", qQUERY->D1_VALDESC, NIL}) // retirado porque com o valor cheio para retorno de tericeiro o sistema informava que o calculo estava errado. E com o valor calculado o sistema informava que o desconto era maior que o total. ticket 1912
				aAdd(aAutoLin, {"C6_NFORI",   qQUERY->D1_DOC,     NIL})
				aAdd(aAutoLin, {"C6_SERIORI", qQUERY->D1_SERIE,   NIL})
				aAdd(aAutoLin, {"C6_IDENTB6", qQUERY->D1_NUMSEQ,  NIL})
				aAdd(aAutoLin, {"C6_ITEMORI", qQUERY->D1_ITEM,    NIL})
				aAdd(aAutoLin, {"C6_YALTBRU", qQUERY->D1_YALTBRU, NIL})
				aAdd(aAutoLin, {"C6_YCOMBRU", qQUERY->D1_YCOMBRU, NIL})
				aAdd(aAutoLin, {"C6_YESPBRU", qQUERY->D1_YESPBRU, NIL})
				aAdd(aAutoLin, {"C6_YTOTBRU", qQUERY->D1_YTOTBRU, NIL})
				aAdd(aAutoLin, {"C6_YALTLIQ", qQUERY->D1_YALTLIQ, NIL})
				aAdd(aAutoLin, {"C6_YCOMLIQ", qQUERY->D1_YCOMLIQ, NIL})
				aAdd(aAutoLin, {"C6_YESPLIQ", qQUERY->D1_YESPLIQ, NIL})
				aAdd(aAutoLin, {"C6_YTOTLIQ", qQUERY->D1_YTOTLIQ, NIL})
				aAdd(aAutoLin, {"C6_VALOR",   nVTotSD1		  ,   NIL})

				//Ordenando conforme o dicionario
				//Foi necessário retirar a ordenação porque seguindo a ordem o sistema apresenta erro
				//de a410total porque o cliente informa um valor menor que a multiplicação, porem quando inclui a TES primeiro e depois inclui o valor o sistema deixa realizar o processo.
				//Ticket:https://totvsleste.freshdesk.com/a/tickets/2617
				//aAutoLin := FWVetByDic( aAutoLin, "SC6" )

				aAdd(aAutoSC6, aAutoLin)

				qQUERY->(DbSkip())

			EndDo

			qQUERY->(DbCloseArea())

			If !Empty(cPkNota)
				aRet := EXEPEDSB6(aAutoSC5, aAutoSC6, dDataFat)
				If !aRet[1]
					Return aRet
				EndIf
			EndIf

		EndIf

		ErrorBlock(ErrorBlock())

	End Sequence

Return {.T., "Sucesso."}


/*/{Protheus.doc} utilProducao
function EXEPEDSB6
Emite e fatura pedido de venda para BAIXAR PODER DE TERCEIRO.
@author Kenny Roger Martins
@since 28/02/2019
@version ALL
/*/
Static Function EXEPEDSB6(aAutoSC5, aAutoSC6, dDataFat)

	Local aPvlNfs   := {}
	Local lBlqCrd   := .F.
	Local lBlqEst   := .F.
	Local cMsgErro  := ""
	Local cNumNota  := ""
	Local aBloqueio := {}
	Local cSeriePDT := superGetMv("GR_SERIPDT", .F., "SMB") // Parametro para serie da nota que baixa poder de terceiro. (Se der problema de Problema Numeracao NF pode estar relacionado a serie.) https://totvsleste.freshdesk.com/a/tickets/1385
	Local dDataOld  := dDataBase

	Private lMsErroAuto	   := .F.
	Private lMsHelpAuto	   := .T.
	Private lAutoErrNoFile := .T.
	Private lGrPlus        := .T.

	Default dDataFat := dDataBase

	dDataBase := dDataFat

	//Em teste o sistema apresenta a mensagem e fecha totalmente: Problema Numeracao NF
	/*
	iF 	!ExistCpo("SX5","01" + cSeriePDT)
		cMsgErro := "GR_SERIPDT - Serie da nota("+cSeriePDT+") não cadastrada na SX5 "
		Return {.F., cMsgErro}
	EndIF
	*/

	// U_TOTVSES()
	MsExecAuto({|x,y,z| mata410(x,y,z)}, aAutoSC5, aAutoSC6, 3)

	If lMsErroAuto

		dDataBase := dDataOld

		If !(IsBlind())
			oUtil := util():new()
			cMsgErro := oUtil:getAutoError()
			oUtil:destroy()
		Else
			cMsgErro := oUtil:getAutoError()
		EndIf

		Return {.F., cMsgErro}

	EndIf

	//----------------------------------------------------------
	// Chama evento de liberacao de regras com o SC5 posicionado
	// Necessário pois a magban bloqueia todos os pedidos por regra
	//----------------------------------------------------------
	MaAvalSC5("SC5",9)

	//----------------------------------------------------------
	// Libera pedido de venda.
	//----------------------------------------------------------
	SC6->(DbSetOrder(1))
	SC6->(MsSeek(xFilial("SC6") + SC5->C5_NUM))
	While SC6->(!Eof()) .and. SC6->(C6_FILIAL + C6_NUM) == xFilial("SC6") + SC5->C5_NUM
		MaLibDoFat( SC6->(RecNo()), SC6->C6_QTDVEN, @lBlqCrd, @lBlqEst, .t., .t., .f., .f. )
		SC6->(DbSkip())
	endDo

	//----------------------------------------------------------
	// Força liberação do pedido de venda.
	//----------------------------------------------------------
	ConOut("GrPlus => Liberando pedido " + AllTrim(SC5->C5_NUM) + "! " + AllTrim(DtoC(Date())) + " " + AllTrim(Time()) + ".")
	MaLiberOk({ SC5->C5_NUM },.t.)

	SE4->(dbSetOrder(1))
	SE4->(msSeek(xFilial("SE4") + SC5->C5_CONDPAG))

	SC9->(dbSetOrder(1))
	SC9->(msSeek(xFilial("SC9") + SC5->C5_NUM))

	SC6->(dbSetOrder(1))
	SF4->(dbSetOrder(1))
	SB1->(dbSetOrder(1))
	SB2->(dbSetOrder(1))

	while SC9->(!eof()) .and. SC9->(C9_FILIAL + C9_PEDIDO) == xFilial("SC9") + SC5->C5_NUM

		SC6->(msSeek(xFilial("SC6") + SC5->C5_NUM + SC9->(C9_ITEM + C9_PRODUTO)))
		SF4->(msSeek(xFilial("SF4") + SC6->C6_TES))
		SB1->(msSeek(xFilial("SB1") + SC9->C9_PRODUTO))
		SB2->(msSeek(xFilial("SB2") + SC9->(C9_PRODUTO + C9_LOCAL)))

		aAdd(aPvlNfs,{;
			SC9->C9_PEDIDO,;
			SC9->C9_ITEM,;
			SC9->C9_SEQUEN,;
			SC9->C9_QTDLIB,;
			SC9->C9_PRCVEN,;
			SC9->C9_PRODUTO,;
			.F.,;
			SC9->(RecNo()),;
			SC5->(RecNo()),;
			SC6->(RecNo()),;
			SE4->(RecNo()),;
			SB1->(RecNo()),;
			SB2->(RecNo()),;
			SF4->(RecNo())})

		SC9->(dbSkip())

	endDo

	aBloqueio := {}
	Ma410LbNfs(2,aPvlNfs,aBloqueio)
	cNumNota := MaPvlNfs(aPvlNfs, cSeriePDT , .F., .F., .F., .T., .F., 0, 0, .F., .F.)

	If lMsErroAuto

		dDataBase := dDataOld

		cMsgErro := oUtil:getAutoError()
		Return {.F., cMsgErro}
	EndIf

	ConOut("GrPlus => Documento de saida sem valor fiscal " + AllTrim(cNumNota) + " gerado com sucesso! " + AllTrim(DtoC(Date())) + " " + AllTrim(Time()) + ".")

	SC5->(recLock("SC5", .F.))
	SC5->C5_YSTATUS := "F"
	SC5->(msUnLock())

	dDataBase := dDataOld

Return {.T., "Sucesso"}


/*/{Protheus.doc} utilProducao
function TRASFINT
Transferência do saldo de Entera.
@author Kenny Roger Martins
@since 28/02/2019
@version ALL
/*/
User Function TRASFINT(cNumOp)

	Local cSql     := ""
	Local qQUERY   := ""
	Local cMsgErro := ""
	Local oUtil    := util():new()
	Local cDoc	   := ""
	Local lDocEnt  := GetNewPar("GR_DOCENT", .f.) //Pega o numero da NFT e adiciona a entera.
	Local aRet     := {}
	Local cSerie   := ""
	Local cLotInt  := ""
	Local cLetra   := ""
	Local nEnteraAuto := GetNewPar("GR_HABAUTO", 0) // Complemento da entera automático.

	Private lMsErroAuto	   := .F.
	Private lMsHelpAuto	   := .T.
	Private lAutoErrNoFile := .T.
	Private lGrPlus        := .T.

	ErrorBlock( {|e| u_GRChecEr(e)})

	Begin Sequence

		// U_TOTVSES()

		cSql := "     SELECT C2_NUM,     C2_ITEM,    C2_DATRF,   C2_YMP,     C2_YLOCMP,  C2_YLOTECT, "
		cSql += "            C2_YCOMITL, C2_YCOMITB, C2_YALTITL, C2_YALTITB, C2_YESPITL, C2_YESPITB, "
		cSql += "            C2_YTOTITL, C2_YTOTITB, C2_YCOMPLE, B8_YCUSTO,  B8_YDOC,    B8_YSERIE,  "
		cSql += "            C2_YTOTMP "
		cSql += "       FROM " + RetSqlName("SC2") + " SC2 "

		cSql += " INNER JOIN " + RetSqlName("SB8") + " SB8 "
		cSql += "         ON SB8.B8_FILIAL  = '" + xFilial("SB8") + "' "
		cSql += "        AND SB8.B8_PRODUTO = SC2.C2_YMP "
		cSql += "        AND SB8.B8_LOCAL   = SC2.C2_YLOCMP "
		cSql += "        AND SB8.B8_LOTECTL = SC2.C2_YLOTECT "
		cSql += "        AND SB8.B8_NUMLOTE = SC2.C2_YNUMLOT "
		cSql += "        AND SB8.D_E_L_E_T_ = ' ' "

		cSql += "      WHERE SC2.C2_FILIAL  = '" + xFilial("SC2") + "' "
		cSql += "        AND SC2.C2_NUM     = '" + cNumOp + "' "
		cSql += "        AND SC2.C2_YTIPO   = 'S' "
		cSql += "        AND SC2.D_E_L_E_T_ = ' ' "

		cSql += "   GROUP BY C2_NUM,     C2_ITEM,    C2_DATRF,   C2_YMP,     C2_YLOCMP,  C2_YLOTECT, "
		cSql += "            C2_YCOMITL, C2_YCOMITB, C2_YALTITL, C2_YALTITB, C2_YESPITL, C2_YESPITB, "
		cSql += "            C2_YTOTITL, C2_YTOTITB, C2_YCOMPLE, B8_YCUSTO,  B8_YDOC,    B8_YSERIE,  "
		cSql += "            C2_YTOTMP "

		TCQUERY cSql NEW ALIAS qQUERY

		While qQUERY->(!Eof())

			//-----------------------------------------------------
			// Caso exista transferência estorna.
			//-----------------------------------------------------

			If nEnteraAuto == 1

				cLetra := SubStr(AllTrim(qQUERY->C2_YLOTECT), Len(AllTrim(qQUERY->C2_YLOTECT)), Len(AllTrim(qQUERY->C2_YLOTECT)))

				If cLetra $ "0123456789"
					cLotInt := Alltrim(qQUERY->C2_YLOTECT) + qQUERY->C2_YCOMPLE
				Else
					cLotInt := SubStr(Alltrim(qQUERY->C2_YLOTECT), 1, Len(AllTrim(qQUERY->C2_YLOTECT)) - 1) + qQUERY->C2_YCOMPLE
				EndIf

			ElseIf RETITE(qQUERY->C2_YLOTECT, qQUERY->C2_YMP, qQUERY->C2_YLOCMP) // Retirando o complemento do lote da entera no lugar de incrementar

				cLotInt := SubStr(Alltrim(qQUERY->C2_YLOTECT), 1, Len(AllTrim(qQUERY->C2_YLOTECT)) - 1) + qQUERY->C2_YCOMPLE

			Else

				cLotInt := If(Len(AllTrim(qQUERY->C2_YLOTECT)) < TamSX3("C2_YLOTECT")[1], AllTrim(qQUERY->C2_YLOTECT) + qQUERY->C2_YCOMPLE, SubStr(AllTrim(qQUERY->C2_YLOTECT), 2, Len(AllTrim(qQUERY->C2_YLOTECT))) + qQUERY->C2_YCOMPLE)

			EndIf

			ConOut("GrPlus => Estornando transferencia da Entera. " + AllTrim(DtoC(Date())) + " " + AllTrim(Time()) + ".")

			U_GROXFUN("delTransferencia", {;
				qQUERY->C2_YMP, ;
				qQUERY->C2_YLOCMP, ;
				qQUERY->C2_YLOTECT, ;
				"", ;
				qQUERY->C2_DATRF, ;
				qQUERY->(C2_NUM + C2_ITEM), ;
				cLotInt;
				})

			If lMsErroAuto
				qQUERY->(DbCloseArea())
				cMsgErro  := oUtil:getAutoError()
				ConOut(cMsgErro + AllTrim(DtoC(Date())) + " " + AllTrim(Time()) + ".")

				If oUtil <> nil
					oUtil:destroy()
				EndIf

				Return {.F., cMsgErro}
			EndIf

			If !Empty(qQUERY->C2_DATRF)

				//-----------------------------------------------------
				// Gera transferência para produto Entera.
				//-----------------------------------------------------

				If qQUERY->C2_YTOTITL > 0

					ConOut("GrPlus => Transferindo saldo da Entera. " + AllTrim(DtoC(Date())) + " " + AllTrim(Time()) + ".")

					U_GROXFUN("addTransferencia", {;
						qQUERY->C2_YMP, ;
						qQUERY->C2_YLOCMP, ;
						qQUERY->C2_YLOTECT, ;
						"", ;
						STOD(qQUERY->C2_DATRF), ;
						qQUERY->C2_YTOTITL, ;
						qQUERY->(C2_NUM + C2_ITEM), ;
						StoD(""), ;
						cLotInt ;
						})

					If lMsErroAuto
						qQUERY->(DbCloseArea())
						cMsgErro  := oUtil:getAutoError()
						ConOut(cMsgErro + AllTrim(DtoC(Date())) + " " + AllTrim(Time()) + ".")

						If oUtil <> nil
							oUtil:destroy()
						EndIf

						Return {.F., cMsgErro}
					EndIf

					SB8->(dbSetOrder(3))

					If SB8->(msSeek(xFilial("SB8") + qQUERY->(C2_YMP + C2_YLOCMP) + PadR(cLotInt, TamSx3("B8_LOTECTL")[1]) + Space(TamSx3("B8_NUMLOTE")[1])))

						ConOut("GrPlus => Inicio gravacao Entera " + AllTrim(qQUERY->(C2_YMP + C2_YLOCMP)) + PadR(cLotInt, TamSx3("B8_LOTECTL")[1]) + Space(TamSx3("B8_NUMLOTE")[1]) + ". " + AllTrim(DtoC(Date())) + " " + AllTrim(Time()) + ".")

						//Serrada (Entera): Não pega o numero da NFT
						//https://projetostotvses.freshdesk.com/a/tickets/2445
						//-----------------------------------------------------
						// Melhoria solicitada pela Magban - chamado 2445
						//-----------------------------------------------------
						aRet := RETDOC(SB8->B8_PRODUTO,SB8->B8_LOTECTL,SB8->B8_NUMLOTE)

						if(len(aRet)>0)
							cDoc   := If(lDocEnt,aRet[1],qQUERY->B8_YDOC)
							cSerie := If(lDocEnt,aRet[2],qQUERY->B8_YSERIE)
						Else
							cDoc   := qQUERY->B8_YDOC
							cSerie := qQUERY->B8_YSERIE
						endIf

						SB8->(reclock("SB8", .F.))
						SB8->B8_YCOMBRU := qQUERY->C2_YCOMITB
						SB8->B8_YALTBRU := qQUERY->C2_YALTITB
						SB8->B8_YESPBRU := qQUERY->C2_YESPITB
						SB8->B8_YTOTBRU := qQUERY->C2_YTOTITB
						SB8->B8_YCOMLIQ := qQUERY->C2_YCOMITL
						SB8->B8_YALTLIQ := qQUERY->C2_YALTITL
						SB8->B8_YESPLIQ := qQUERY->C2_YESPITL
						SB8->B8_YTOTLIQ := qQUERY->C2_YTOTITL
						SB8->B8_YDOC    := cDoc
						SB8->B8_YSERIE  := cSerie
						SB8->B8_YCUSTO  := qQUERY->B8_YCUSTO * qQUERY->C2_YTOTITL / qQUERY->C2_YTOTMP
						SB8->(msunlock())

						ConOut("GrPlus => Fim gravacao Entera " + AllTrim(qQUERY->(C2_YMP + C2_YLOCMP)) + PadR(cLotInt, TamSx3("B8_LOTECTL")[1]) + Space(TamSx3("B8_NUMLOTE")[1]) + ". " + AllTrim(DtoC(Date())) + " " + AllTrim(Time()) + ".")

					EndIf

				EndIf

			EndIf

			qQUERY->(DbSkip())

		EndDo

		qQUERY->(DbCloseArea())

		ErrorBlock(ErrorBlock())

	End Sequence

Return {.T., "Sucesso."}


/*/{Protheus.doc} utilProducao
function DelTabZG
Exclui registros das tabelas ZG
@author Kenny Roger Martins
@since 09/05/2017
@version ALL
/*/
User Function DelTabZG(cTabela, cIndice, cCondLop, cCampo)

	Local cAliasTMP := "TMP" + cTabela

	Default cCondLop := ".F."
	Default cCampo   := "_OP"

	// U_TOTVSES()

	DbSelectArea(cTabela)

	ChkFile( cTabela , .F. , cAliasTMP )

	DbSelectArea(cAliasTMP)

	(cAliasTMP)->(DbSetOrder(1))

	(cAliasTMP)->(MsSeek(xFilial(cTabela) + cIndice))

	While (cAliasTMP)->(!(Eof())) .And. (cAliasTMP)->(&(cTabela + "_FILIAL + " + cTabela + cCampo)) == xFilial(cTabela) + cIndice

		&(cTabela)->(DbGoTo((cAliasTMP)->(Recno())))

		//Criado para as ops alteradas nessa tela não retirar todos os insumos.
		if(&(cCondLop))
			(cAliasTMP)->(DbSkip())
			loop
		EndIf

		RecLock(cTabela, .F.)
		&(cTabela)->(DbDelete())
		&(cTabela)->(MsUnLock())

		(cAliasTMP)->(DbSkip())

	EndDo

	(cAliasTMP)->(DbCloseArea())

Return Nil


/*/{Protheus.doc} utilProducao
function GeraEmpenho
Gera empenho de matéria-prima
@author Kenny Roger Martins
@since 28/02/2019
@version ALL
/*/
User Function GeraEmpenho(cNumOp, oModel)

	Local cSql          := ""
	Local qQUERY        := ""
	Local qTOTACA       := ""
	Local cSiglaRet     := AllTrim(GetNewPar("GR_SIGLARE", "R"))
	Local nTotalEmpenho := 0
	Local oUtil         := util():new()
	Local aArraySD4     := {}
	Local oModelZH7     := Nil
	Local oModelZH8     := Nil
	Local oModelZH9     := Nil
	Local nRegZH8       := Nil
	Local nRegZH9       := Nil
	Local nX            := 0
	Local nTotalPa      := 0
	Local nQtdeEmpenho  := 0
	Local nQtdSC2       := 0
	Local aArrayQtqEmpe := {}
	Local cTipoOp 	    := ""

	Private lMsErroAuto	   := .F.
	Private lMsHelpAuto	   := .T.
	Private lAutoErrNoFile := .T.
	Private lGrPlus        := .T.
	Private	__dAuxCalen    := StoD("")

	Default oModel := ""

	if oModel <> ""

		oModelZH7   := oModel:GetModel('ZH7MASTER')
		cTipoOp 	:= oModelZH7:GetValue("ZH7_PROCES")

	EndIf

	// U_TOTVSES()

	// Atualiza empenho do bloco na SD4

	If cTipoOp == "S"
		cSql := " SELECT "
		cSql += " C2_QUANT * C2_YESPLIQ as C2_QUANT "  //Ajuste serrada o sistema precisa levar em consideração a espessura da chapa.
		cSql += " ,C2_DATRF,C2_PRODUTO,C2_YMP, C2_YTIPO, C2_TPOP,C2_NUM, C2_ITEM ,C2_EMISSAO ,  C2_YTOTMP , C2_SEQUEN ,C2_YLOCMP, C2_YLOTECT,C2_YNUMLOT"
	Else
		cSql := " SELECT * "
	EndIF

	cSql += "   FROM " + RetSqlName("SC2") + " SC2 "
	cSql += "  WHERE C2_FILIAL  = '" + xFilial("SC2") + "'"
	cSql += "    AND C2_NUM     = '" + cNumOp         + "'"
	cSql += "    AND D_E_L_E_T_ = ' '"
	cSql += " ORDER BY C2_NUM, C2_ITEM, C2_SEQUEN "	//Inserdio, porque se o usuário excluir o primeiro colocando um maior depois ele estava posicionando no ultimo registro https://totvsleste.freshdesk.com/a/tickets/1298

	TCQUERY cSql NEW ALIAS qQUERY

	While qQUERY->(!Eof())

		//Verificar se ja foi produzido.
		If (type("lRoti06")=="L".and. lRoti06)
			iF !empty(qQUERY->C2_DATRF)
				qQUERY->(DbSkip())
				Loop
			EndIf
		Endif

		cGrupo := Posicione("SB1", 1, xFilial("SB1") + qQUERY->C2_YMP, "B1_GRUPO")
		cTipo  := Posicione("SBM", 1, xFilial("SBM") + cGrupo, "BM_YTIPO")

		//----------------------------------------------------------
		// Tipo pedreira não existe empenho e OP FIRME.
		//----------------------------------------------------------
		If cTipo <> "P" .And. qQUERY->C2_TPOP == "F" .And. qQUERY->C2_YTIPO <> "R"

			If cTipoOp == "S"
				cSql := " SELECT SUM(C2_QUANT * C2_YESPLIQ) C2_QUANT, MAX(C2_SEQUEN) C2_SEQUEN "  //Ajuste serrada o sistema precisa levar em consideração a espessura da chapa.
			Else
				cSql := " SELECT SUM(C2_QUANT) C2_QUANT, MAX(C2_SEQUEN) C2_SEQUEN "
			EndIF

			cSql += "   FROM " + RetSqlName("SC2") + " SC2 "
			cSql += "  WHERE C2_FILIAL  = '" + xFilial("SC2") + "'"
			cSql += "    AND C2_NUM     = '" + qQUERY->C2_NUM    + "'"
			cSql += "    AND C2_ITEM    = '" + qQUERY->C2_ITEM   + "'"
			cSql += "    AND D_E_L_E_T_ = ' '"

			TCQUERY cSql NEW ALIAS qTOTACA

			//Realizado o noround devido testes na magban e a multiplicação das casas decimais estava deixando um pequeno saldo
			//https://totvsleste.freshdesk.com/a/tickets/925
			//Alterado por Kenny Roger Martins, o Noround estava deixando a quantidade empenhada diferete do correto.
			nQtdeEmpenho := Round(qQUERY->C2_QUANT / qTOTACA->C2_QUANT * qQUERY->C2_YTOTMP, TamSx3("D4_QUANT")[2])

			If qQUERY->C2_SEQUEN == qTOTACA->C2_SEQUEN
				nQtdeEmpenho  := qQUERY->C2_YTOTMP - nTotalEmpenho
				nTotalEmpenho := 0
			Else
				nTotalEmpenho += nQtdeEmpenho
			EndIf

			qTOTACA->(DbCloseArea())

			cProduto := qQUERY->C2_YMP

			//-----------------------------------------------------
			// Gera transferência para produto Retrabalho.
			//-----------------------------------------------------
			If qQUERY->C2_PRODUTO == qQUERY->C2_YMP

				cProduto := AllTrim(qQUERY->C2_YMP) + cSiglaRet + Space(TamSx3("B1_COD")[1] - Len(AllTrim(qQUERY->C2_YMP) + cSiglaRet))

				//-----------------------------------------------------
				// Igualado a quantidade transferida com a empenhada
				// caso contrário falta ou sobre saldo no estoque.
				//-----------------------------------------------------
				U_GROXFUN("addRetrabalho", {qQUERY->C2_YMP,;
					qQUERY->C2_YLOCMP,;
					qQUERY->C2_YLOTECT,;
					qQUERY->C2_YNUMLOT,;
					STOD(qQUERY->C2_EMISSAO),;
					nQtdeEmpenho /*qQUERY->C2_QUANT*/,;
					qQUERY->(C2_NUM + C2_ITEM + C2_SEQUEN)})

				If lMsErroAuto
					qQUERY->(DbCLoseArea())
					cMsgErro := oUtil:getAutoError()
					Return {.F., cMsgErro}
				EndIf

			EndIf

			//-----------------------------------------------------------
			// Empenha materia-prima.
			//-----------------------------------------------------------
			aArraySD4 := {}

			aAdd(aArraySD4, {"D4_FILIAL", 	xFilial("SD4"),	    nil})
			aAdd(aArraySD4, {"D4_COD", 		cProduto,           nil})
			aAdd(aArraySD4, {"D4_LOCAL",	qQUERY->C2_YLOCMP,	nil})
			aAdd(aArraySD4, {"D4_OP", 		qQUERY->(C2_NUM + C2_ITEM + C2_SEQUEN), nil})
			aAdd(aArraySD4, {"D4_YOP", 		qQUERY->C2_NUM,		nil})
			aAdd(aArraySD4, {"D4_YITEM", 	qQUERY->C2_ITEM, 	nil})
			aAdd(aArraySD4, {"D4_YSEQUEN", 	qQUERY->C2_SEQUEN,	nil})
			aAdd(aArraySD4, {"D4_LOTECTL", 	qQUERY->C2_YLOTECT,	nil})
			aAdd(aArraySD4, {"D4_NUMLOTE", 	qQUERY->C2_YNUMLOT,	nil})
			aAdd(aArraySD4, {"D4_QTDEORI", 	nQtdeEmpenho,		nil})
			aAdd(aArraySD4, {"D4_QUANT", 	nQtdeEmpenho,		nil})

			MSExecAuto({|x,y| Mata380(x,y)}, aArraySD4, 3)

			If lMsErroAuto
				qQUERY->(DbCLoseArea())
				cMsgErro := oUtil:getAutoError()
				Return {.F., cMsgErro}
			EndIf

		ElseIf qQUERY->C2_YTIPO == "R" .And. qQUERY->C2_TPOP == "F" .And. ValType(oModel) == "O"

			// Soma total de produto acabado
			nTotalPa := 0

			oModelZH9 := oModel:GetModel('ZH9DETAIL')
			nRegZH9   := oModelZH9:Length()

			For nX := 1 To nRegZH9
				oModelZH9:GoLine(nX)
				If oModelZH9:IsDeleted()
					Loop
				EndIf
				nTotalPa += oModelZH9:GetValue('ZH9_TOTLIQ')
			Next

			oModelZH8 := oModel:GetModel('ZH8DETAIL')
			nRegZH8   := oModelZH8:Length()

			//Soma para verificar o ultimo empenho e não arredondar mas pegar o valor que falta
			nQtdSC2++

			For nX := 1 To nRegZH8

				oModelZH8:GoLine(nX)

				If oModelZH8:IsDeleted()
					if(nQtdSC2 < nRegZH9)
						aAdd(aArrayQtqEmpe, {"SOMA_QUANT",0 ,nil})
					EndIf
					Loop
				EndIf

				nQtdeEmpenho := Round(oModelZH8:GetValue('ZH8_TOTLIQ') * (qQUERY->C2_QUANT / nTotalPa), TamSX3("D4_QUANT")[2])

				//Validação para não ficar um saldo pequeno na ultima MP - https://totvsleste.freshdesk.com/a/tickets/1232
				if(nQtdSC2 < nRegZH9)
					if(nQtdSC2 == 1 )
						aAdd(aArrayQtqEmpe, {"SOMA_QUANT",nQtdeEmpenho ,nil})
					Else
						aArrayQtqEmpe[nX][2] += nQtdeEmpenho
					EndIf
				else
					if(nQtdSC2 == 1 )
						nQtdeEmpenho := oModelZH8:GetValue('ZH8_TOTLIQ')
					Else
						nQtdeEmpenho := oModelZH8:GetValue('ZH8_TOTLIQ') - aArrayQtqEmpe[nX][2]
					EndIf
				EndIf

				//-----------------------------------------------------
				// Gera transferência para produto Retrabalho.
				//-----------------------------------------------------
				cProduto := qQUERY->C2_YMP

				If qQUERY->C2_PRODUTO == qQUERY->C2_YMP

					cProduto := AllTrim(qQUERY->C2_YMP) + cSiglaRet + Space(TamSx3("B1_COD")[1] - Len(AllTrim(qQUERY->C2_YMP) + cSiglaRet))
					//-----------------------------------------------------
					// Igualado a quantidade transferida com a empenhada
					// caso contrário falta ou sobre saldo no estoque.
					//-----------------------------------------------------
					U_GROXFUN("addRetrabalho", {qQUERY->C2_YMP,;
						oModelZH8:GetValue('ZH8_LOCAL'),;
						oModelZH8:GetValue('ZH8_LOTECT'),;
						oModelZH8:GetValue('ZH8_NUMLOT'),;
						STOD(qQUERY->C2_EMISSAO),;
						nQtdeEmpenho /*qQUERY->C2_QUANT*/,;
						qQUERY->(C2_NUM + C2_ITEM + C2_SEQUEN)})

					If lMsErroAuto
						qQUERY->(DbCLoseArea())
						cMsgErro := oUtil:getAutoError()
						Return {.F., cMsgErro}
					EndIf

				EndIf

				//-----------------------------------------------------------
				// Empenha materia-prima.
				//-----------------------------------------------------------
				aArraySD4 := {}

				aAdd(aArraySD4, {"D4_FILIAL", 	xFilial("SD4"),                         nil})
				aAdd(aArraySD4, {"D4_COD", 		cProduto						,       nil})
				aAdd(aArraySD4, {"D4_LOCAL",	oModelZH8:GetValue('ZH8_LOCAL'),        nil})
				aAdd(aArraySD4, {"D4_OP", 		qQUERY->(C2_NUM + C2_ITEM + C2_SEQUEN), nil})
				aAdd(aArraySD4, {"D4_YOP", 		qQUERY->C2_NUM,                         nil})
				aAdd(aArraySD4, {"D4_YITEM", 	qQUERY->C2_ITEM,                        nil})
				aAdd(aArraySD4, {"D4_YSEQUEN", 	qQUERY->C2_SEQUEN,                      nil})
				aAdd(aArraySD4, {"D4_LOTECTL", 	oModelZH8:GetValue('ZH8_LOTECT'),       nil})
				aAdd(aArraySD4, {"D4_NUMLOTE", 	oModelZH8:GetValue('ZH8_NUMLOT'),       nil})
				aAdd(aArraySD4, {"D4_QTDEORI", 	nQtdeEmpenho,		                    nil})
				aAdd(aArraySD4, {"D4_QUANT", 	nQtdeEmpenho,		                    nil})

				MSExecAuto({|x,y| Mata380(x,y)}, aArraySD4, 3)

				If lMsErroAuto

					qQUERY->(DbCLoseArea())
					cMsgErro := oUtil:getAutoError()
					Return {.F., cMsgErro}

				Else

					//------------------------------------------------
					// Recortado deve atualizar tamanho da chapa.
					//------------------------------------------------
					SB8->(DbSetOrder(3))

					If SB8->(MsSeek(xFilial("SB8") + oModelZH8:GetValue('ZH8_CODMAT') + oModelZH8:GetValue('ZH8_LOCAL') + oModelZH8:GetValue('ZH8_LOTECT') + oModelZH8:GetValue('ZH8_NUMLOT')))

						If oModelZH8:GetValue('ZH8_COMLIQ') <> SB8->B8_YCOMLIQ .Or. oModelZH8:GetValue('ZH8_ALTLIQ') <> SB8->B8_YALTLIQ.Or. oModelZH8:GetValue('ZH8_ESPLIQ') <> SB8->B8_YESPLIQ

							RecLock("SB8", .F.)
							SB8->B8_YCOMLIQ := IF(oModelZH8:GetValue('ZH8_COMLIQ') <> SB8->B8_YCOMLIQ, SB8->B8_YCOMLIQ - oModelZH8:GetValue('ZH8_COMLIQ'), SB8->B8_YCOMLIQ)
							SB8->B8_YALTLIQ := IF(oModelZH8:GetValue('ZH8_ALTLIQ') <> SB8->B8_YALTLIQ, SB8->B8_YALTLIQ - oModelZH8:GetValue('ZH8_ALTLIQ'), SB8->B8_YALTLIQ)
							SB8->B8_YESPLIQ := IF(oModelZH8:GetValue('ZH8_ESPLIQ') <> SB8->B8_YESPLIQ, SB8->B8_YESPLIQ - oModelZH8:GetValue('ZH8_ESPLIQ'), SB8->B8_YESPLIQ)
							SB8->B8_YTOTLIQ := IF(oModelZH8:GetValue('ZH8_TOTLIQ') <> SB8->B8_YTOTLIQ, SB8->B8_YTOTLIQ - oModelZH8:GetValue('ZH8_TOTLIQ'), SB8->B8_YTOTLIQ)
							SB8->(MsUnLock())

						EndIf

					EndIf

				EndIf

			Next

		EndIf

		qQUERY->(DbSkip())

	EndDo

	qQUERY->(DbCloseArea())

	If oUtil <> nil
		oUtil:destroy()
	EndIf

Return {.T., "Sucesso."}


//---------------------------------------------
// Consulta nota fiscal
//---------------------------------------------

Static function RETDOC(cProduto,cLote,cSubL)  //pedro

	Local qTransf := Nil
	Local aRet    := {} //gd

	cSql := " SELECT D1_DOC, D1_SERIE
	cSql += "  FROM "+ RetSqlName("SD1") + " SD1"
	cSql += "  WHERE  D1_FILIAL	='" + xFilial("SD3") + "'"
	cSql += "  AND D1_COD 			='" + AllTrim(cProduto) + "'"
	cSql += "  AND D1_LOTECTL	='" + cLote   + "'"
	cSql += "  AND D1_NUMLOTE	='" + cSubL   + "'"
	cSql += "  AND D_E_L_E_T_	= ' '"

	TCQUERY cSql NEW ALIAS qTransf

	While qTransf->(!Eof())
		//-----------------------------
		// Magban chamado 2445 - Giliard
		AADD(aRet,qTransf->D1_DOC )
		AADD(aRet,qTransf->D1_SERIE)
		//------------------------------
		qTransf->(DbSkip())

	EndDo

	qTransf->(DbCloseArea())

Return aRet


//---------------------------------------------
// Restorna lote da entera, verifica se é uma entera de uma entera
//---------------------------------------------

Static function RETITE(cLote, cCod, cLocal)

	Local aRet    	  := .F.
	Local cAliasTMP   := Nil
	Local cComple     := ''
	Local lIntera     := SuperGetMV("GR_MODINT",.F.,.F.) // Como .t., exemplo de 3 enterar(LOTE = 123) sucessivas com complemento A,B,C 1) 123A    2)123B   3) 123C    ; parametro como .F. os 3 lotes ficaram 123A ; 123AB ; 123ABC

	IF(lIntera)

		cAliasTMP   := GetNextAlias()
		cComple 	:= SubStr(alltrim(cLote),len(alltrim(cLote)),1)
		cLote   	:= SubStr(alltrim(cLote),1,len(alltrim(cLote))-1)


		BeginSql Alias cAliasTMP
			SELECT * 
				FROM %Table:SC21% SC2 
			WHERE 
					SC2.C2_YLOTECT = %Exp:cLote% 
				AND SC2.C2_YCOMPLE = %Exp:cComple%
				AND SC2.%NotDel%
		
		EndSQL

		If (cAliasTMP)->(!Eof())
			aRet := .T.
		EndIf

		(cAliasTMP)->(dbCloseArea())

		BeginSql Alias cAliasTMP
			SELECT
				D1_COD
			FROM 
				%Table:SD1% SD1 
			WHERE 
				D1_YINTERA = 'S'
				AND D1_COD = %Exp:cCod%
				AND D1_LOTECTL = %Exp:cLote + cComple%
				AND D1_LOCAL = %Exp:cLocal%
				AND SD1.%NotDel%
		EndSQL

		If (cAliasTMP)->(!Eof())
			aRet := .T.
		EndIf

		(cAliasTMP)->(dbCloseArea())

		BeginSql Alias cAliasTMP
			SELECT
				D3_COD 
			FROM 
				%Table:SD3% SD3 
			WHERE 
				D3_YINTERA = 'S'
				AND D3_COD = %Exp:cCod%
				AND D3_LOTECTL = %Exp:cLote + cComple%
				AND D3_LOCAL = %Exp:cLocal%
				AND SD3.%NotDel%
		EndSQL

		If (cAliasTMP)->(!Eof())
			aRet := .T.
		EndIf

		(cAliasTMP)->(dbCloseArea())

	ENDIF

Return aRet

// Retira o rastro do numero do cavalete da materia prima.
// https://projetostotvses.freshdesk.com/a/tickets/2596
user function LIMPYCAVALE(cYmp,clote,cSubL,cLocal)

	Local aliarSB8  := SB8->(GetArea())

	SB8->(DbSetOrder(3)) //Indice 3  // Ajustado porque pode ter chapas em armazem diferentes

	IF SB8->(MsSeek(xFilial("SB8") + cYmp + cLocal + clote + cSubL ))
		RecLock("SB8", .F.)
		SB8->B8_YCAVALE := ""
		SB8->(MsUnLock())
	EndIf

	restArea(aliarSB8)

Return


//---------------------------------------------
// Alterar preço de pauta
// https://totvsleste.freshdesk.com/a/tickets/1245
//---------------------------------------------
Static function GetPauta(cProduto)

	Local aPergs   := {}
	Local aRet	   := {}
	Local lRet     := .T.
	Local lRetDado := .T.
	Local nValor   := 0
	Local cMensag  := ""

	If !IsBlind()

		aAdd( aPergs, {1, "Produto", cProduto, "", ".F.", "", ".F.", TAMSX3("B5_COD")[1] * 5, .F.})
		aAdd( aPergs, {1, "Novo valor de pauta", nValor, PesqPict("SB5", "B5_YVLRPTA"),'Positivo()',,'.T.',TAMSX3("B5_YVLRPTA")[1] * 5,.t.})

		lRet := ParamBox(aPergs ,"Valor de pauta esta igual a zero, Informe um novo valor de pauta",aRet)

		If lRet
			nValor := aRet[2]

			If nValor > 0 .And. SB5->(DbSeek(xFilial("SB5") + cProduto))
				RecLock("SB5", .F.)
				SB5->B5_YVLRPTA := nValor
				SB5->(MsUnLock())
			EndIf
		EndIF

		lRetDado := .T.

	Else

		lRetDado    := .F.
		cMensag := "O valor de pauta do produto " + ALLTRIM(cProduto) + " está igual a zero, Informe um novo valor de pauta no protheus B5_YVLRPTA"

	EndIf

Return {lRetDado, nValor, cMensag}

//-----------------------------------------------------------------
/*/{Protheus.doc} GetCustoNf
Retorna o custo da nota fiscal de compra
@author Kenny Roger Martins
@since 22/02/2021
@version ALL
/*/
//-----------------------------------------------------------------
Static Function GetCustoNf(cProduto, cLote, cSubLote)

	Local nValor := 0
	Local cSql   := ""
	Local qCusto := ""

	cSGBD := TCGetDB()

	if (cSGBD $ "ORACLE")
		cSql := "  SELECT D1_CUSTO "
	Else
		cSql := "  SELECT TOP 1 D1_CUSTO "
	EndIf

	cSql += "    FROM " + RetSqlName("SD1") + " SD1 "
	cSql += "   WHERE SD1.D1_FILIAL  = '" + xFilial("SD1") + "' "
	cSql += "     AND SD1.D1_COD     = '" + cProduto + "' "
	cSql += "     AND SD1.D1_LOTECTL = '" + cLote + "' "
	cSql += "     AND SD1.D1_NUMLOTE = '" + cSubLote + "' "
	cSql += "     AND SD1.D_E_L_E_T_ = ' ' "

	if (cSGBD $ "ORACLE")
		cSql += " AND ROWNUM <= 1 "
	EndIf

	TCQUERY cSql NEW ALIAS qCusto

	nValor := qCusto->D1_CUSTO

	qCusto->(DbCloseArea())

Return nValor

//-----------------------------------------------------------------
/*/{Protheus.doc} MOVPOSPR
Verifica se houve movimento do manterial depois da produção, 
pois não deve permitir estorno de produção caso o material 
tenha movimentado estoque
@author Kenny Roger Martins
@since 22/02/2021
@version ALL
/*/
//-----------------------------------------------------------------
User Function MovPosPr(cOrdem, cProduto, cLocal, cLoteCtl, cNumLote)

	Local lRet     := .F.
	Local nRecno   := 0
	Local cSql     := ""
	Local qMovTmp  := ""
	Local cTpMovLi := GETNEWPAR("GR_MOVESTO", "")
	Local nQuant   := 0

	//---------------------------------------------
	// Produtos sem lote não pode validar alteração posterior
	//---------------------------------------------
	IF ALLTRIM(Posicione('SB1',1,xFilial('SB1')+cProduto,'B1_RASTRO')) == "N"
		return  lRet
	EndIf

	//---------------------------------------------
	// Procura o recno da ordem de produção.
	//---------------------------------------------
	cSGBD := TCGetDB()

	if (cSGBD $ "ORACLE")
		cSql := " SELECT R_E_C_N_O_ ,D3_QUANT,D3_TM "
	Else
		cSql := " SELECT TOP 1 R_E_C_N_O_ ,D3_QUANT,D3_TM "
	EndIf

	cSql += "   FROM " + RetSqlName("SD3") + " SD3 "
	cSql += "  WHERE SD3.D3_FILIAL  = '" + xFilial("SD3") + "' "
	cSql += "    AND SD3.D3_OP      = '" + cOrdem + "' "
	cSql += "    AND SD3.D3_ESTORNO = ' ' "
	cSql += "    AND SD3.D_E_L_E_T_ = ' ' "

	if (cSGBD $ "ORACLE")
		cSql += " AND ROWNUM <= 1 "
	EndIf

	cSql += "    ORDER BY SD3.R_E_C_N_O_ DESC "

	TCQUERY cSql NEW ALIAS qMovTmp

	nRecno := qMovTmp->R_E_C_N_O_

	nQuant   := qMovTmp->D3_QUANT

	qMovTmp->(DbCloseArea())

	IF !EMPTY(cTpMovLi)

		//---------------------------------------------
		// Procura o recno da entrada para ajuste da Op, necessário caso o cliente tenha encerrado a op e depois precisa ajustar a nota de entrada.
		// https://totvsleste.freshdesk.com/a/tickets/2846
		//---------------------------------------------
		cSGBD := TCGetDB()

		if (cSGBD $ "ORACLE")
			cSql := " SELECT R_E_C_N_O_ "
		Else
			cSql := " SELECT TOP 1 R_E_C_N_O_ "
		EndIf

		cSql += "   FROM " + RetSqlName("SD3") + " SD3 "
		cSql += "  WHERE SD3.D3_FILIAL  = '" + xFilial("SD3") + "' "
		cSql += "    AND SD3.D3_COD     = '" + cProduto + "' "
		cSql += "    AND SD3.D3_LOCAL   = '" + cLocal   + "' "
		cSql += "    AND SD3.D3_LOTECTL = '" + cLoteCtl + "' "
		cSql += "    AND SD3.D3_NUMLOTE = '" + cNumLote + "' "
		cSql += "    AND SD3.D3_ESTORNO = ' ' "
		cSql += "    AND SD3.D3_TM 	    = '"+ AllTrim(cTpMovLi) +"'"
		cSql += "    AND SD3.D3_YMENNOT = 'AJUSTEOP' "
		cSql += "    AND SD3.R_E_C_N_O_ > " + cValToChar(nRecno)
		cSql += "    AND SD3.D_E_L_E_T_ = ' ' "

		if (cSGBD $ "ORACLE")
			cSql += " AND ROWNUM <= 1 "
		EndIf

		TCQUERY cSql NEW ALIAS qMovTmp

		//Caso tenha um ajuste de saldo posterior ao recno da op o sistema pega esse novo recno para buscar lançamentos posterior ao mesmo.
		If (qMovTmp->R_E_C_N_O_ > nRecno)
			nRecno := qMovTmp->R_E_C_N_O_
		EndIf

		qMovTmp->(DbCloseArea())

	ENDIF

	//---------------------------------------------
	// Verifica se houve movimento após produção.
	//---------------------------------------------
	cSGBD := TCGetDB()

	if (cSGBD $ "ORACLE")
		cSql := " SELECT R_E_C_N_O_ "
	Else
		cSql := " SELECT TOP 1 R_E_C_N_O_ "
	EndIf

	cSql += "   FROM " + RetSqlName("SD3") + " SD3 "
	cSql += "  WHERE SD3.D3_FILIAL  = '" + xFilial("SD3") + "' "
	cSql += "    AND SD3.D3_COD     = '" + cProduto + "' "
	cSql += "    AND SD3.D3_LOCAL   = '" + cLocal + "' "
	cSql += "    AND SD3.D3_LOTECTL = '" + cLoteCtl + "' "
	cSql += "    AND SD3.D3_NUMLOTE = '" + cNumLote + "' "
	cSql += "    AND SD3.D3_ESTORNO = ' ' "
	cSql += "    AND SD3.D3_OP NOT LIKE '" + substr(cOrdem,1,6) + "%' "
	cSql += "    AND SD3.D3_CF NOT IN  ('RE4','DE4','DE6') "   // Retirado as transferencias gerais('RE4','DE4') , liberado DE6 que e a devolução manual.
	cSql += "    AND SD3.R_E_C_N_O_ > " + cValToChar(nRecno)
	cSql += "    AND SD3.D_E_L_E_T_ = ' ' "

	if (cSGBD $ "ORACLE")
		cSql += " AND ROWNUM <= 1 "
	EndIf

	cSql := ChangeQuery(cSql)

	TCQUERY cSql NEW ALIAS qMovTmp

	While qMovTmp->(!Eof())
		lRet := .T.
		qMovTmp->(DbSkip())
	EndDo

	qMovTmp->(DbCloseArea())

	If ExistBlock("GMOVPOSP")
		lRet := ExecBlock("GMOVPOSP", .F., .F., lRet)
	EndIf

Return lRet


//-----------------------------------------------------------------
/*/{Protheus.doc} 
Exclusão de Documentos passando a OP
@author Diego Christ / Maycon Bianchine
@since 08/06/2021
@version ALL

Melhoria
https://totvsleste.freshdesk.com/a/tickets/1916
/*/
//-----------------------------------------------------------------
User Function ExDadosOP(cOp)

	Local _alias := GetArea()
	Local lRet   := .T.
	Local cQuery := ""
	Default cOp  := ' '

	If Empty(cOp)
		Return .F.
	EndIf

	BEGIN TRANSACTION

		If lRet

			cQuery := U_SqlPedOp(cOp)

			TCQuery cQuery New Alias "TFSAIDA"

			While ! TFSAIDA->(EOF()) .and. lRet

				FWMsgRun(, {|| lRet := U_DelNotaS(TFSAIDA->D1_DOC,TFSAIDA->D1_SERIE) }, "Processando", "Excluindo Doc. Saida... " + AllTrim(TFSAIDA->D1_DOC) + "/" +TFSAIDA->D1_SERIE)

				//Desarmando conexão caso apresente erro na exclusão da nota de saida
				IF !lRet
					TFSAIDA->(dbCloseArea())
					DisarmTransaction()
					Return .F.
				End If

				if lRet .AND. !Empty(TFSAIDA->D1_PEDIDO)
					FWMsgRun(, {|| lRet := U_DelPedido(TFSAIDA->D1_PEDIDO) }, "Processando", "Excluindo Pedido de Venda... " + TFSAIDA->D1_PEDIDO)
				EndIF

				//Desarmando conexão caso apresente erro na exclusão pedido de venda
				IF !lRet
					TFSAIDA->(dbCloseArea())
					DisarmTransaction()
					Return .F.
				End If

				TFSAIDA->(DbSkip())

			EndDo

			TFSAIDA->(dbCloseArea())

		EndIf

		If lRet

			cQuery := U_SqlNotaOp(cOp)

			if Select("TF1") <> 0
				TF1->(dbCloseArea())
			End if

			TCQuery cQuery New Alias "TF1"

			TF1->( dbGoTop() )

			While !TF1->(EOF()) .AND. lRet

				FWMsgRun(, {|| lRet := U_DelNotaE(TF1->D1_DOC,TF1->D1_SERIE,TF1->F1_FORNECE,TF1->F1_LOJA) }, "Processando", "Excluindo Doc. Entrada... " + AllTrim(TF1->D1_DOC) + "/" + TF1->D1_SERIE)

				//Desarmando conexão caso apresente erro na exclusão da nota de saida
				IF !lRet
					TF1->(dbCloseArea())
					DisarmTransaction()
					Return .F.
				End If

				TF1->(DbSkip())

			EndDo

			TF1->(dbCloseArea())

		EndIf

	END TRANSACTION

	If lRet
		FWMsgRun(, {|| Sleep(2000) }, "Sucesso", "Exclusão Relizada com Sucesso!")
	EndIf

	RestArea(_alias)

Return lRet


//===============================================================================
//MONTA SQL QUE RETORNA PEDIDOS E NOTA FISCAL DE UMA OP COM PODER DE TERCEIROS	=
//===============================================================================
USER Function SqlPedOp(cNumOp)

	Local cSqlRet

	cSqlRet := "SELECT " + Chr(10)
	cSqlRet += "'Ped.Venda/Doc.Saida'	AS TIPO_DOC	, " + Chr(10)
	cSqlRet += "SD2.D2_PEDIDO			AS D1_PEDIDO		, " + Chr(10)
	cSqlRet += "SD2.D2_DOC				AS D1_DOC			, " + Chr(10)
	cSqlRet += "SD2.D2_SERIE			AS D1_SERIE			, " + Chr(10)
	cSqlRet += "SD2.D2_EMISSAO			AS D1_EMISSAO		, " + Chr(10)
	cSqlRet += "SUM(SD2.D2_QUANT) 		AS D1_QUANT			, " + Chr(10)
	cSqlRet += "SUM(SD2.D2_TOTAL) 	    AS D1_TOTAL			, " + Chr(10)
	cSqlRet += "SD2.D2_CLIENTE, SD2.D2_LOJA " + Chr(10)

	cSqlRet += "FROM " + RetSqlName("SD2") + " SD2 " + Chr(10)

	cSqlRet += "INNER JOIN " + RetSqlName("SC5") + " SC5 " + Chr(10)
	cSqlRet += "ON " + Chr(10)
	cSqlRet += "   SC5.C5_FILIAL  = SD2.D2_FILIAL AND " + Chr(10)
	cSqlRet += "   SC5.C5_NOTA    = SD2.D2_DOC    AND " + Chr(10)
	cSqlRet += "   SC5.C5_SERIE   = SD2.D2_SERIE  AND " + Chr(10)
	cSqlRet += "   SC5.D_E_L_E_T_ = ' ' " + Chr(10)
	cSqlRet += "WHERE " + Chr(10)
	cSqlRet += "	  SC5.C5_FILIAL  = '" + xFilial("SC2") + "' AND " + Chr(10)
	cSqlRet += "      SC5.C5_YOP     = '" + cNumOp         +"'  AND " + Chr(10)
	cSqlRet += "      SC5.D_E_L_E_T_ = ' ' 						AND  " + Chr(10)
	cSqlRet += "      SD2.D_E_L_E_T_ = ' ' " + Chr(10)
	cSqlRet += "GROUP BY SC5.C5_NUM, SD2.D2_DOC, SD2.D2_SERIE, SD2.D2_EMISSAO, " + Chr(10)
	cSqlRet += "SD2.D2_PEDIDO, SD2.D2_CLIENTE, SD2.D2_LOJA "

Return cSqlRet


//=======================================================
//MONTA SQL QUE RETORNA NOTA FISCAL DE ENTRADA DA OP	=
//=======================================================
USER Function SqlNotaOp(cNumOp)

	Local cSqlRet

	cSqlRet := "SELECT " + Chr(10)
	cSqlRet += "'Doc.Entrada'           AS TIPO_DOC	, " + Chr(10)
	cSqlRet += "SD1.D1_PEDIDO			AS D1_PEDIDO		, " + Chr(10)
	cSqlRet += "SF1.F1_DOC 				AS D1_DOC			, " + Chr(10)
	cSqlRet += "SF1.F1_SERIE			AS D1_SERIE			, " + Chr(10)
	cSqlRet += "SF1.F1_EMISSAO			AS D1_EMISSAO		, " + Chr(10)
	cSqlRet += "SUM(SD1.D1_QUANT) 		AS D1_QUANT			, " + Chr(10)
	cSqlRet += "SUM(SD1.D1_TOTAL) 		AS D1_TOTAL 		, " + Chr(10)
	cSqlRet += "SF1.F1_FORNECE, SF1.F1_LOJA " + Chr(10)
	cSqlRet += "FROM " + RetSqlName("SF1") + " SF1 " + Chr(10)

	cSqlRet += "INNER JOIN " + RetSqlName("SD1") + " SD1 " + Chr(10)
	cSqlRet += "ON " + Chr(10)
	cSqlRet += "   SD1.D1_FILIAL  = SF1.F1_FILIAL  AND " + Chr(10)
	cSqlRet += "   SD1.D1_DOC     = SF1.F1_DOC     AND " + Chr(10)
	cSqlRet += "   SD1.D1_SERIE   = SF1.F1_SERIE   AND " + Chr(10)
	cSqlRet += "   SD1.D1_FORNECE = SF1.F1_FORNECE AND " + Chr(10)
	cSqlRet += "   SD1.D1_LOJA    = SF1.F1_LOJA    AND " + Chr(10)
	cSqlRet += "   SD1.D_E_L_E_T_ = ' ' " + Chr(10)

	cSqlRet += "WHERE " + Chr(10)
	cSqlRet += "      SF1.F1_FILIAL  = '"    + xFilial("SF1") + "' AND " + Chr(10)
	cSqlRet += "      SF1.F1_YDOCEXT = '_OP" + cNumOp         + "' AND " + Chr(10)
	cSqlRet += "      SF1.D_E_L_E_T_ = ' ' " + Chr(10)
	cSqlRet += "GROUP BY SF1.F1_DOC, SF1.F1_SERIE, SF1.F1_EMISSAO, " + Chr(10)
	cSqlRet += "SD1.D1_PEDIDO, SF1.F1_FORNECE, SF1.F1_LOJA"

Return cSqlRet


//===========================
//Esclusão Doc. de Entrada	=
//===========================
User Function DelNotaE(cNumero,cSerie,cFornece,cLojaF)

	Local aCab 	  := {}
	Local aItens  := {}
	Local nOpc 	  := 5
	Local lExclui := .T.
	Local _alias  := GetArea()

	Private lMSHelpAuto := .F. // para mostrar os erro na tela
	Private lMsErroAuto := .F.
	Private _lInclui    := .F.

	Conout("Inicio: " + Time())

	aCab := {}
	aItens := {}
	aLinha := {}

	if !EMPTY(DTOS(Posicione("SF1", 1, xFilial("SF1") + cNumero + cSerie + cFornece + cLojaF, "F1_DAUTNFE"))) ;
			.AND. !MsgNoYes( "Nota de entrada já transmitida, deseja continuar ?", "Deletar nota entrada" )

		Return .f.
	EndIF

	//PREENCHENDO O CABECLHO DA NOTA FISCAL (SF1)
	aadd(aCab, {"F1_DOC"	,cNumero	,Nil,Nil})
	aadd(aCab, {"F1_SERIE"	,cSerie		,Nil,Nil})
	aadd(aCab, {"F1_FORNECE",cFornece	,Nil,Nil})
	aadd(aCab, {"F1_LOJA"	,cLojaF		,Nil,Nil})

	//Buscar todos os itens referentes a essa nota
	cQuery := " SELECT D1_DOC, D1_SERIE, D1_FORNECE, D1_LOJA, D1_COD, D1_ITEM, D1_IDENTB6 FROM " + RetSqlName("SD1")
	cQuery += "    WHERE D1_DOC   = '" + cNumero + "'"
	cQuery += "    AND D1_FILIAL  = '" + xFilial('SD1') + "'"
	cQuery += "    AND D1_SERIE   = '" + cSerie + "'"
	cQuery += "    AND D1_FORNECE = '" + cFornece + "'"
	cQuery += "    AND D1_LOJA    = '" + cLojaF + "'"
	cQuery += "    AND D_E_L_E_T_ = ' '"

	if Select("TD1") <> 0
		TD1->(dbCloseArea())
	End if

	TCQuery cQuery New Alias "TD1"

	While ! TD1->(EOF())

		aLinha := {}

		aadd(aLinha, {"D1_FILIAL"	,xFilial("SD1")	,Nil,Nil})
		aadd(aLinha, {"D1_DOC"		,TD1->D1_DOC	,Nil,Nil})
		aadd(aLinha, {"D1_SERIE"	,TD1->D1_SERIE	,Nil,Nil})
		aadd(aLinha, {"D1_FORNECE"	,TD1->D1_FORNECE,Nil,Nil})
		aadd(aLinha, {"D1_LOJA"		,TD1->D1_LOJA	,Nil,Nil})
		aadd(aLinha, {"D1_COD"		,TD1->D1_COD	,Nil,Nil})
		aAdd(aLinha, {"D1_ITEM"    	,TD1->D1_ITEM 	,Nil})
		aAdd(aLinha, {"D1_IDENTB6"  ,TD1->D1_IDENTB6,Nil})

		aadd(aItens, aLinha)

		TD1->(DbSkip())
	End Do

	TD1->(dbCloseArea())

	//3-Inclusão / 4-Classificação / 5-Exclusão
	MSExecAuto({|x,y,z| MATA103(x,y,z)},aCab,aItens,nOpc)

	If lMsErroAuto
		MostraErro()
		lExclui := .F.
	EndIf

	RestArea(_alias)

Return (lExclui)


//=======================
//Exclusão Doc. Saida	=
//=======================
User Function DelNotaS(cDoc, cSerie)

	Local aArea   := GetArea()
	Local aHeader := {}
	Local lRet    := .T.

	Private lMsErroAuto := .F.
	Private lMsHelpAuto := .F.


	if !EMPTY(Posicione("SF2", 1, xFilial("SF2") + cDoc + cSerie , "F2_CHVNFE"));
			.AND. !MsgNoYes( "Nota de saida já transmitida, deseja continuar ?", "Deletar nota saida" )

		Return .f.
	EndIF

	aAdd(aHeader, {"F2_DOC"		,PadR(cDoc	,TamSX3("F2_DOC")[1])	,NIL}) // NÚMERO DA NOTA
	aAdd(aHeader, {"F2_SERIE"	,PadR(cSerie,TamSX3("F2_SERIE")[1])	,NIL}) // SÉRIE

	// REALIZA A OPERAÇÃO
	MsExecAuto({|x| MATA520(x)}, aHeader)

	// VERIFICA STATUS FINAL
	If lMsErroAuto
		MostraErro()
		lRet := .F.
	EndIf

	RestArea(aArea)

Return lRet


//===============================
//Esclusão do Pedido de Venda	=
//===============================
User Function DelPedido(cNum)

	Local _alias := GetArea()
	Local aItens := {}
	Local aCabec := {}
	Local LRET   := .T.

	Private lMSHelpAuto := .F. // para mostrar os erro na tela
	Private lMsErroAuto := .F.

	SC6->(DbSetOrder(1))
	SC9->(dbSetOrder(1))
	SC6->(DbGoTop())
	SC6->(DbSeek(xFilial("SC6") + cNum))

	While SC6->(!Eof()) .And. SC6->C6_FILIAL + SC6->C6_NUM == xFilial("SC6") + cNum

		If SC9->(MsSeek(xFilial("SC9") + SC6->(C6_NUM + C6_ITEM)))
			While SC9->(!Eof()) .And. SC9->(C9_FILIAL + C9_PEDIDO + C9_ITEM) == xFilial("SC9") + SC6->(C6_NUM + C6_ITEM)
				If Empty(SC9->C9_NFISCAL)
					SC9->(a460Estorna())
				EndIf
				SC9->(DbSkip())
			EndDo
		EndIf

		SC6->(DbSkip())

	EndDo

	lMsErroAuto := .F.

	aAdd(aCabec, {"C5_FILIAL"	,xFilial("SC5")	,Nil})
	aAdd(aCabec, {"C5_NUM"		,cNum			,Nil})

	MSExecAuto({|x,y,z| Mata410(x,y,z)}, aCabec, aItens, 5)

	If lMsErroAuto
		MostraErro()
		lRet := .F.
	EndIf

	RestArea(_alias)

Return lRet


/*/{Protheus.doc} User Function valdDtNt
	(long_description)
	Função para validar se pode criar nft com data anterior a data do servidor (data atual ). Isso e necessário porque alguns clientes 
 	@type  Function
	@author user
	@since 24/02/2023
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
	/*/
User Function valdDtNt(dtUtili,dtValid)

	Local nDtnota  := GETNEWPAR("GR_DTNOTA", 1) // 1 = apresenta mensagem pro usuário escolher se deseja continua ; 2 = sempre cria nota com a data base ; 3 = sepre cria nota com a data do servidor.
	Local aRet     := {.t.,"",dtUtili}
	Local cMsgErro := ""

	If nDtnota == 1 .and. dtUtili < dtValid .and. (!isBlind() .AND. !MsgYesNo("Data da NFT "+CVALTOCHAR( dtUtili )+" menor que a do Sistema "+CVALTOCHAR( dtValid )+", deseja prosseguir mesmo assim?"))
		cMsgErro := "Data da NFT menor que a do Sistema"
		aRet := {.F., cMsgErro,dtUtili}
	elseif nDtnota == 2
		aRet := {.T., cMsgErro,dtUtili}
	elseif nDtnota == 3
		dtUtili := dtValid
		aRet := {.T., cMsgErro,dtUtili}
	EndIf

Return aRet


/*/{Protheus.doc} getNumFS
	(long_description)
	Função para pegar o proximo numero quando for formulario proprio igual a sim 
	@type  Static Function
	@author user
	@since 16/08/2023
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
/*/
Static Function getNumFS(cSerie,cTipoSeq)
	Local cNumero := ""

	If cTipoSeq == "3"	// Alterado pois a funcao NxtSx5Nota nao trata MV_TPNRNFS = 3 (SD9)
		//Necessário incluir o numero da nota como 00000000, porque o sistema
		//busca a proxima numeração quando e formulario sim e MV_TPNRNFS igual a 3
		//Obs: Se deixar o numero vazio o sistema limpa a serie. Tem que passar qualquer numeração, eu escolhi 0000000.
		//Ticket na matrix: 17440243, 					//Se executar a rotina MA461NumNf , o sistema vai pular uma numeração
		cNumero := "000000000" //MA461NumNf(.T., cSerie)

	ElseIf cTipoSeq == "2" // https://totvsleste.freshdesk.com/a/tickets/6547 // atualemte temos uma issue DMANMAT02-44332
		cNumero  := NxtSx5Nota(cSerie, .T., cTipoSeq)

	ElseIf cTipoSeq == "1"
		cNumero  := NxtSx5Nota(cSerie, .T., cTipoSeq) // Estava duplicando a numeração para o novo fonte mata103, para o antigo e necessário passar o proximo numero ainda.
	EndIf

Return cNumero

