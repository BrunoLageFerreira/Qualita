#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"

/*/{Protheus.doc} GROXFUN()
Fonte contendo conjunto de funções utilizadas no módulo Gestão de Rochas

@author Kenny Roger Martins
@since 21/02/2017
@version 1.0

@example
@obs 

@return
/*/
User Function GROXFUN(cFuncao, aParam)

	Local aReturn := {}

	Default cFuncao := ""
	Default aParam  := {}

	Do Case

	Case Upper(AllTrim(cFuncao)) == Upper("getLoteAuto"); aReturn := getLoteAut()
	Case Upper(AllTrim(cFuncao)) == Upper("setCusto"); setCusto(aParam)
	Case Upper(AllTrim(cFuncao)) == Upper("addTransferencia"); addTransfe(aParam)
	Case Upper(AllTrim(cFuncao)) == Upper("delTransferencia"); delTransfe(aParam)
	Case Upper(AllTrim(cFuncao)) == Upper("addRetrabalho"); addRetraba(aParam)
	Case Upper(AllTrim(cFuncao)) == Upper("delRetrabalho"); delRetraba(aParam)
	Case Upper(AllTrim(cFuncao)) == Upper("getConsultEng"); aReturn := getConsult(aParam)

	EndCase

Return aReturn


/*/{Protheus.doc} getLoteAut()
Função responsável por gerar número de lote sequencial.

@author Kenny Roger Martins
@since 08/08/2017
@version 1.0

@return
/*/
Static Function getLoteAut()

	Local aAreaANT := GetArea()
	Local aAreaSB1 := SB1->(GetArea())
	Local cLoteCtl := ""
	Local cRastro  := AllTrim(Posicione("SB1", 1, xFilial("SB1") + GDFIELDGET('D1_COD'), "B1_RASTRO"))
	Local lLoteAut := GetNewPar("GR_LOTEAUT", .f.) // Habilita sequenciamento automático do lote

	If cRastro $ "L" .And. lLoteAut

		If Empty(GDFIELDGET('D1_LOTECTL'))

			cLoteCtl := GetSxeNum("SD1", "D1_LOTECTL")

			// ConfirmSX8()

		EndIf

	EndIf

	RestArea(aAreaSB1)
	RestArea(aAreaANT)

Return cLoteCtl


/*/{Protheus.doc} setCusto()
Função responsável por calcularo custo da OP conforme tabela SD3

@author Kenny Roger Martins
@since 08/08/2017
@version 1.0

@return
/*/
Static Function setCusto(aParam)

	Local cNumOp   := ""
	Local aAreaANT := GetArea()
	Local aAreaSD3 := SD3->(GetArea())
	Local nDivisor := 0
	Local nCusto1  := 0
	Local nCusto2  := 0
	Local nCusto3  := 0
	Local nCusto4  := 0
	Local nCusto5  := 0
	Local qCUSTO   := Nil
	Local cSql     := ""

	Default aParam := {}

	cNumOp := If(Len(aParam) > 0, aParam[1], "")

	If !(Empty(cNumOp))

		//--------------------------------------------
		// Retorna quantidade produtos produzidos.
		//--------------------------------------------
		cSql := "  SELECT COALESCE(NULLIF(COUNT(D3_FILIAL),0),1) AS DIVISOR" + Chr(10)
		cSql += "	  FROM " + RetSqlName("SD3")+ " SD3" + Chr(10)
		cSql += "	 WHERE D3_FILIAL   = '" + xFilial("SD3") + "'" + Chr(10)
		cSql += "	   AND D3_CF BETWEEN 'PR ' AND 'PRZ'" + Chr(10)
		cSql += "	   AND D3_OP       = '" + cNumOp + "'" + Chr(10)
		cSql += "	   AND D3_ESTORNO  = ' '" + Chr(10)
		cSql += "	   AND D_E_L_E_T_  = ' '" + Chr(10)

		TCQUERY cSql NEW ALIAS qCUSTO

		nDivisor := qCUSTO->DIVISOR

		qCUSTO->(DbCloseArea())

		//--------------------------------------------
		// Retorna o custo total da produção.
		//--------------------------------------------
		cSql := " SELECT COALESCE(SUM(D3_YCUSTO1),0) AS CUSTO1," + Chr(10)
		cSql += "        COALESCE(SUM(D3_YCUSTO2),0) AS CUSTO2," + Chr(10)
		cSql += "        COALESCE(SUM(D3_YCUSTO3),0) AS CUSTO3," + Chr(10)
		cSql += "        COALESCE(SUM(D3_YCUSTO4),0) AS CUSTO4," + Chr(10)
		cSql += "        COALESCE(SUM(D3_YCUSTO5),0) AS CUSTO5 " + Chr(10)
		cSql += "   FROM " + RetSqlName("SD3") + " SD3" + Chr(10)
		cSql += "  WHERE D3_FILIAL   = '" + xFilial("SD3") + "'" + Chr(10)
		cSql += "    AND D3_CF BETWEEN 'RE ' AND 'REZ'" + Chr(10)
		cSql += "    AND D3_OP       = '" + cNumOp + "'" + Chr(10)
		cSql += "    AND D3_ESTORNO  = ' '" + Chr(10)
		cSql += "    AND D_E_L_E_T_  = ' '" + Chr(10)

		TCQUERY cSql NEW ALIAS qCUSTO

		nCusto1 := qCUSTO->CUSTO1 / nDivisor
		nCusto2 := qCUSTO->CUSTO2 / nDivisor
		nCusto3 := qCUSTO->CUSTO3 / nDivisor
		nCusto4 := qCUSTO->CUSTO4 / nDivisor
		nCusto5 := qCUSTO->CUSTO5 / nDivisor

		qCUSTO->(DbCloseArea())

		SD3->(DbSetOrder())

		SD3->(DbSetOrder(1))

		SD3->(MsSeek(xFilial("SD3") + cNumOp))

		While SD3->(!EoF()) .And. SD3->(D3_FILIAL + D3_OP) == xFilial("SD3") + cNumOp

			If SubStr(SD3->D3_CF,1,2) == "PR" .And. Empty(SD3->D3_ESTORNO)

				RecLock("SD3", .F.)

				SD3->D3_YCUSTO1 := Round(nCusto1, TamSx3("D3_YCUSTO1")[2])
				SD3->D3_YCUSTO2 := Round(nCusto2, TamSx3("D3_YCUSTO2")[2])
				SD3->D3_YCUSTO3 := Round(nCusto3, TamSx3("D3_YCUSTO3")[2])
				SD3->D3_YCUSTO4 := Round(nCusto4, TamSx3("D3_YCUSTO4")[2])
				SD3->D3_YCUSTO5 := Round(nCusto5, TamSx3("D3_YCUSTO5")[2])

				SD3->(MsUnLock())

			EndIf

			SD3->(DbSkip())

		EndDo

	EndIf

	RestArea(aAreaANT)
	RestArea(aAreaSD3)

Return Nil


/*/{Protheus.doc} delTransfe
Função utilizada para excluir transferência de entera.

@author Kenny Roger Martins
@since 10/08/2017
@version 1.0

@return
/*/
Static Function delTransfe(aParam)

	Local aAreaANT    := GetArea()
	Local aAreaSD3    := SD3->(GetArea())
	Local aAreaSC2    := SC2->(GetArea())

	Local cProduto    := ""
	Local cLocal      := ""
	Local cLoteCtl    := ""
	Local cNumLote    := ""
	Local dDataLanc   := STOD("")
	Local cNumOp      := ""
	Local cLoteNew    := ""
	Local cSql        := ""
	Local qTransf     := Nil
	Local aAuto       := {}
	Local lRet        := .T.

	Local cCodOrig    := ""
	Local nRecOrig    := 0
	Local cCodDest    := ""
	Local nRecDest    := 0
	Local nQuant260	:= 0
	Local nQuant260D	:= 0
	Local lEstorno    := .T.

	Local cLocOrig    := nil
	Local cLoclzOrig  := nil
	Local cDocto      := nil
	Local dEmis260    := nil
	Local cLoteDigi   := nil
	Local dDtValid    := nil
	Local cNumSerie   := nil
	Local cLocDest    := nil
	Local cLocLzDest  := nil
	Local cLoteDest   := nil
	Local cPrograma   := nil
	Local cEstFis     := nil
	Local cServico    := nil
	Local cTarefa     := nil
	Local cAtividade  := nil
	Local cAnomalia   := nil
	Local cEstDest    := nil
	Local cEndDest    := nil
	Local cHrInicio   := nil
	Local cAtuEst     := nil
	Local cCarga      := nil
	Local cUnitiza    := nil
	Local cOrdTar     := nil
	Local cOrdAti     := nil
	Local cRHumano    := nil
	Local cRFisico    := nil
	Local nPotencia   := nil

	Private cCusMed   := GetMv("MV_CUSMED")
	//https://totvsleste.freshdesk.com/a/tickets/1322
	//variaveis para a função a260Processa não apresentar erro
	Private lCriaHeader := .F.
	PRIVATE cLoteEst
	PRIVATE cArquivo		// Nome do arquivo contra prova
	PRIVATE nHdlPrv
	PRIVATE nTotal := 0 	// Total dos lancamentos contabeis


	If cCusMed == "O"
		lCriaHeader := .T.
	Endif

	Default aParam    := {}

	cProduto  := If(Len(aParam) > 0, aParam[1], "")
	cLocal    := If(Len(aParam) > 1, aParam[2], "")
	cLoteCtl  := If(Len(aParam) > 2, aParam[3], "")
	cNumLote  := If(Len(aParam) > 3, aParam[4], "")
	dDataLanc := If(Len(aParam) > 4, aParam[5], StoD(""))
	cNumOp    := If(Len(aParam) > 5, aParam[6], "")
	cLoteNew  := If(Len(aParam) > 6, aParam[7], "")

	//-----------------------------------------------------------
	// Exclui transferência do saldo do produto original para o
	// produto retrabalho.
	//-----------------------------------------------------------

	//---------------------------------------------
	// Consulta produto Original
	//---------------------------------------------

	cSql := "  SELECT *"
	cSql += "    FROM " + RetSqlName("SD3") + " SD3"
	cSql += "   WHERE D3_FILIAL  = '" + xFilial("SD3") + "'"
	cSql += "     AND D3_COD     = '" + AllTrim(cProduto) + "'"
	cSql += "     AND D3_LOCAL   = '" + cLocal   + "'"
	cSql += "     AND D3_LOTECTL = '" + cLoteCtl + "'"
	// cSql += "     AND D3_NUMLOTE = '" + cNumLote + "'"
	// cSql += "     AND D3_EMISSAO = '" + DTOS(dDataLanc) + "'"
	cSql += "     AND D3_YOPRETR = '" + cNumOp   + "'"
	cSql += "     AND D3_ESTORNO = ' '"
	cSql += "     AND D_E_L_E_T_ = ' '"

	TCQUERY cSql NEW ALIAS qTransf

	While qTransf->(!Eof())

		cCodOrig  := qTransf->D3_COD
		nRecOrig  := qTransf->R_E_C_N_O_
		nQuant260 := qTransf->D3_QUANT

		qTransf->(DbSkip())

	EndDo

	qTransf->(DbCloseArea())

	//---------------------------------------------
	// Consulta produto entera
	//---------------------------------------------
	cSql := "  SELECT D3_COD, D3_EMISSAO, D3_QUANT, R_E_C_N_O_"
	cSql += "    FROM " + RetSqlName("SD3") + " SD3"
	cSql += "   WHERE D3_FILIAL  = '" + xFilial("SD3") + "'"
	cSql += "     AND D3_COD     = '" + AllTrim(cProduto) + "'"
	cSql += "     AND D3_LOCAL   = '" + cLocal   + "'"
	cSql += "     AND D3_LOTECTL = '" + cLoteNew + "'"
	// cSql += "     AND D3_NUMLOTE = '" + cNumLote + "'"
	// cSql += "     AND D3_EMISSAO = '" + DTOS(dDataLanc) + "'"
	cSql += "     AND D3_YOPRETR = '" + cNumOp   + "'"
	cSql += "     AND D3_ESTORNO = ' '"
	cSql += "     AND D_E_L_E_T_ = ' '"

	TCQUERY cSql NEW ALIAS qTransf

	While qTransf->(!Eof())

		dEmis260  := qTransf->D3_EMISSAO
		cCodDest  := qTransf->D3_COD
		nRecDest  := qTransf->R_E_C_N_O_

		qTransf->(DbSkip())

	EndDo

	qTransf->(DbCloseArea())

	SD3->(dbSetOrder(2))

	SD3->(DbGoTo(nRecOrig))

	If nRecOrig > 0 .And. nRecDest > 0

		cLoteCtl  := Nil

		lMsErroAuto := !a260Processa(cCodOrig,cLocOrig,nQuant260,cDocto,dEmis260,nQuant260D,cNumLote,cLoteDigi,;
			dDtValid,cNumSerie,cLoclzOrig,cCodDest,cLocDest,cLocLzDest,lEstorno,nRecOrig,nRecDest,;
			cPrograma,cEstFis,cServico,cTarefa,cAtividade,cAnomalia,cEstDest,cEndDest,cHrInicio,;
			cAtuEst,cCarga,cUnitiza,cOrdTar,cOrdAti,cRHumano,cRFisico,nPotencia,cLoteDest)

	EndIf

	RestArea(aAreaANT)
	RestArea(aAreaSC2)
	RestArea(aAreaSD3)

Return Nil


/*/{Protheus.doc} addTransfe
Função utilizada para gerar produto e transferência de entera.

@author Kenny Roger Martins
@since 21/11/2018
@version 1.0

@return
/*/
Static Function addTransfe(aParam)

	Local cProduto    := ""
	Local cProDesc    := ""
	Local cLocal      := ""
	Local cLoteCtl    := ""
	Local cNumLote    := ""
	Local dEmissao    := StoD("")
	Local nQuantidade := 0
	Local dDataValid  := StoD("")
	Local cNumOp      := ""
	Local cLoteNew    := ""

	Local aStruct     := {}
	Local aRegistro   := {}
	Local aAuto       := {}
	Local nX          := 0
	Local cSql        := ""
	Local qTransf     := Nil
	Local nOpcx       := ""
	local lDocSD3	:= GetNewPar("GR_DOCSXE",.T.)


	Private __cSublote := ""

	Default aParam    := {}

	cProduto    := If(Len(aParam) > 0, aParam[1], "")
	cLocal      := If(Len(aParam) > 1, aParam[2], "")
	cLoteCtl    := If(Len(aParam) > 2, aParam[3], "")
	cNumLote    := If(Len(aParam) > 3, aParam[4], "")
	dEmissao    := If(Len(aParam) > 4, aParam[5], StoD(""))
	nQuantidade := If(Len(aParam) > 5, aParam[6], 0)
	cNumOp      := If(Len(aParam) > 6, aParam[7], "")
	dDataValid  := If(Len(aParam) > 7, aParam[8], StoD(""))
	cLoteNew    := If(Len(aParam) > 8, aParam[9], "")

	If !Empty(cProduto)

		//-----------------------------------------------------------
		// Faz transferência do saldo do produto original para o
		// produto retrabalho.
		//-----------------------------------------------------------

		SB8->(DbSetOrder(3))

		If SB8->(DbSeek(xFilial("SB8") + cProduto + cLocal + cLoteCtl + cNumLote))

			dDataValid := SB8->B8_DTVALID

		EndIf

		aAuto     := {}
		aRegistro := {}

		If lDocSD3
			aadd(aAuto, {GetSxENum("SD3","D3_DOC",1), dEmissao }) // dDataBase}) // Cabecalho
		else
			aadd(aAuto, {SD3->(getSxeNum("SD3", "D3_DOC", xFilial("SD3") + "\DATA\" + RetSqlName("SD3"))), dEmissao}) // Cabecalho
		EndIF

		// Itens a Incluir

		__cSublote := 	cNumLote

		SB1->(DbSeek(xFilial("SB1") + PadR(cProduto, TamSx3('D3_COD') [1])))

		//Origem
		aadd(aRegistro, {"ITEM",       '001',        Nil})
		aadd(aRegistro, {"D3_COD",     cProduto,     Nil}) //Cod Produto origem
		aadd(aRegistro, {"D3_DESCRI",  SB1->B1_DESC, Nil}) //descr produto origem
		aadd(aRegistro, {"D3_UM",      SB1->B1_UM,   Nil}) //unidade medida origem
		aadd(aRegistro, {"D3_LOCAL",   cLocal,       Nil}) //armazem origem
		aadd(aRegistro, {"D3_LOCALIZ", "",           Nil}) //Informar endereço origem

		//Destino
		aadd(aRegistro, {"D3_COD",     cProduto,     Nil}) //cod produto destino
		aadd(aRegistro, {"D3_DESCRI",  SB1->B1_DESC, Nil}) //descr produto destino
		aadd(aRegistro, {"D3_UM",      SB1->B1_UM,   Nil}) //unidade medida destino
		aadd(aRegistro, {"D3_LOCAL",   cLocal,       Nil}) //armazem destino
		aadd(aRegistro, {"D3_LOCALIZ", "",           Nil}) //Informar endereço destino

		aadd(aRegistro, {"D3_NUMSERI", "",           Nil}) //Numero serie
		aadd(aRegistro, {"D3_LOTECTL", cLoteCtl,     Nil}) //Lote Origem
		aadd(aRegistro, {"D3_NUMLOTE", "",           Nil}) //sublote origem
		aadd(aRegistro, {"D3_DTVALID", dDataValid,   Nil}) //data validade
		aadd(aRegistro, {"D3_POTENCI", 0,            Nil}) // Potencia
		aadd(aRegistro, {"D3_QUANT",   nQuantidade,  Nil}) //Quantidade
		aadd(aRegistro, {"D3_QTSEGUM", 0,            Nil}) //Seg unidade medida
		aadd(aRegistro, {"D3_ESTORNO", "",           Nil}) //Estorno
		aadd(aRegistro, {"D3_NUMSEQ",  "",           Nil}) // Numero sequencia D3_NUMSEQ

		aadd(aRegistro, {"D3_LOTECTL", cLoteNew,     Nil}) //Lote destino
		aadd(aRegistro, {"D3_NUMLOTE", "",           Nil}) //sublote destino
		aadd(aRegistro, {"D3_DTVALID", dDataValid,   Nil}) //validade lote destino
		aadd(aRegistro, {"D3_ITEMGRD", "",           Nil}) //Item Grade

		aadd(aRegistro, {"D3_OBSERVA", "Entera",     Nil}) //D3_OBSERVA
		aadd(aRegistro, {"D3_CODLAN",  "",           Nil}) //cat83 prod origem
		aadd(aRegistro, {"D3_CODLAN",  "",           Nil}) //cat83 prod destino

		aadd(aAuto, aRegistro)

		MSExecAuto({|x,y| mata261(x,y)}, aAuto, 3)

		If !lMsErroAuto
			//---------------------------------------------------
			// Vincular transferência com a Ordem de Produção.
			//---------------------------------------------------

			//---------------------------------------------
			// Consulta produto Original
			//---------------------------------------------
			cSql := "  SELECT *"
			cSql += "    FROM " + RetSqlName("SD3") + " SD3"
			cSql += "   WHERE D3_FILIAL  = '" + xFilial("SD3") + "'"
			cSql += "     AND D3_COD     = '" + AllTrim(cProduto) + "'"
			cSql += "     AND D3_LOCAL   = '" + cLocal   + "'"
			cSql += "     AND D3_LOTECTL = '" + cLoteCtl + "'"
			cSql += "     AND D3_NUMLOTE = '" + cNumLote + "'"
			cSql += "     AND D3_EMISSAO = '" + DTOS(dEmissao) + "'"
			cSql += "     AND D3_ESTORNO = ' '"
			cSql += "     AND D3_YOPRETR = ' '"
			cSql += "     AND D3_CF      = 'RE4'"
			cSql += "     AND D_E_L_E_T_ = ' '"

			TCQUERY cSql NEW ALIAS qTransf

			While qTransf->(!Eof())

				SD3->(DbGoTo(qTransf->(R_E_C_N_O_)))

				RecLock("SD3", .F.)
				SD3->D3_YOPRETR := cNumOp
				SD3->(MsUnLock())

				qTransf->(DbSkip())

			EndDo

			qTransf->(DbCloseArea())

			//---------------------------------------------
			// Consulta produto
			//---------------------------------------------
			cSql := "  SELECT D3_COD, D3_QUANT, R_E_C_N_O_"
			cSql += "    FROM " + RetSqlName("SD3") + " SD3"
			cSql += "   WHERE D3_FILIAL  = '" + xFilial("SD3") + "'"
			cSql += "     AND D3_COD     = '" + AllTrim(cProduto) + "'"
			cSql += "     AND D3_LOCAL   = '" + cLocal   + "'"
			cSql += "     AND D3_LOTECTL = '" + cLoteNew + "'"
			cSql += "     AND D3_NUMLOTE = '" + cNumLote + "'"
			cSql += "     AND D3_EMISSAO = '" + DTOS(dEmissao) + "'"
			cSql += "     AND D3_ESTORNO = ' '"
			cSql += "     AND D3_YOPRETR = ' '"
			cSql += "     AND D3_CF      = 'DE4'"
			cSql += "     AND D_E_L_E_T_ = ' '"

			TCQUERY cSql NEW ALIAS qTransf

			While qTransf->(!Eof())

				SD3->(DbGoTo(qTransf->(R_E_C_N_O_)))

				RecLock("SD3", .F.)
				SD3->D3_YOPRETR := cNumOp
				SD3->(MsUnLock())

				qTransf->(DbSkip())

			EndDo

			qTransf->(DbCloseArea())

			SB8->(dbSetOrder(3))

			If SB8->(msSeek(xFilial("SB8") + cProduto + cLocal + cLoteNew + cNumLote))

				SB8->(reclock("SB8"))
				SB8->B8_YCOMBRU := SC2->C2_YCOMITB
				SB8->B8_YALTBRU := SC2->C2_YALTITB
				SB8->B8_YESPBRU := SC2->C2_YESPITB
				SB8->B8_YTOTBRU := SC2->C2_YTOTITB
				SB8->B8_YCOMLIQ := SC2->C2_YCOMITL
				SB8->B8_YALTLIQ := SC2->C2_YALTITL
				SB8->B8_YESPLIQ := SC2->C2_YESPITL
				SB8->B8_YTOTLIQ := SC2->C2_YTOTITL
				SB8->(msunlock())

			endIf

		EndIf

	EndIf

Return Nil


/*/{Protheus.doc} addRetrabalho
Função utilizada para gerar produto e transferência de retrabalho.

@author Kenny Roger Martins
@since 10/08/2017
@version 1.0

@return
/*/
Static Function addRetraba(aParam)

	Local cProduto    := ""
	Local cProDesc    := ""
	Local cLocal      := ""
	Local cLoteCtl    := ""
	Local cNumLote    := ""
	Local dEmissao    := StoD("")
	Local nQuantidade := 0
	Local dDataValid  := StoD("")
	Local cNumOp      := ""
	Local cRetrabalho := ""
	Local cRetDesc    := ""
	Local aStruct     := {}
	Local aRegistro   := {}
	Local aAuto       := {}
	Local nX          := 0
	Local cSql        := ""
	Local qTransf     := Nil
	Local cSiglaRet   := AllTrim(GetNewPar("GR_SIGLARE", "R"))
	Local cGrupoRet   := AllTrim(GetNewPar("GR_GRUPORE", ""))
	Local nB8YCOMBRU  := 0
	Local nB8YALTBRU  := 0
	Local nB8YESPBRU  := 0
	Local nB8YTOTBRU  := 0
	Local nB8YCOMLIQ  := 0
	Local nB8YALTLIQ  := 0
	Local nB8YESPLIQ  := 0
	Local nB8YTOTLIQ  := 0
	Local nB8YCUSTO   := 0
	Local cB8YDOC     := 0
	Local cB8YSERIE   := ""
	Local nB8YPESLIQ  := 0
	Local nB8YPESBRU  := 0
	local lDocSD3	  := GetNewPar("GR_DOCSXE",.T.)
	Local dFecham     := GetMv("MV_ULMES")

	Private __cSublote := ""

	Default aParam    := {}


	If type("__dAuxCalen") == "U"
		__dAuxCalen   := StoD("")
	EndIf

	cProduto    := PadR(If(Len(aParam) > 0, aParam[1], ""), TamSX3("B1_COD")[1], "")
	cLocal      := PadR(If(Len(aParam) > 1, aParam[2], ""), TamSX3("B1_LOCPAD")[1], "")
	cLoteCtl    := PadR(If(Len(aParam) > 2, aParam[3], ""), TamSX3("B8_LOTECTL")[1], "")
	cNumLote    := PadR(If(Len(aParam) > 3, aParam[4], ""), TamSX3("B8_NUMLOTE")[1], "")
	dEmissao    := If(Len(aParam) > 4, aParam[5], StoD(""))
	nQuantidade := If(Len(aParam) > 5, aParam[6], 0)
	cNumOp      := If(Len(aParam) > 6, aParam[7], "")
	dDataValid  := If(Len(aParam) > 7, aParam[8], StoD(""))

	If !Empty(cProduto)

		cRetrabalho := AllTrim(cProduto) + cSiglaRet + Space(TamSx3("B1_COD")[1] - Len(AllTrim(cProduto) + cSiglaRet))

		//-----------------------------------------------------------
		// Verificar se existe produto retrabalho cadastrado.
		//-----------------------------------------------------------

		SB1->(DbSetOrder(1))
		SB5->(DbSetOrder(1))

		If SB1->(!DbSeek(xFilial("SB1") + cRetrabalho))

			//-----------------------------------------------------------
			// Cadastro produto retrabalho na tabela SB1.
			//-----------------------------------------------------------

			If SB1->(DbSeek(xFilial("SB1") + cProduto))

				aStruct   := SB1->(DbStruct())
				aRegistro := {}

				For nX := 1 To Len(aStruct)

					If AllTrim(aStruct[nX,1]) == "B1_COD"

						aAdd(aRegistro, cRetrabalho)

					ElseIf AllTrim(aStruct[nX,1]) == "B1_DESC"

						cProDesc := AllTrim(&("SB1->" + AllTrim(aStruct[nx,1])))

						aAdd(aRegistro, AllTrim(&("SB1->" + AllTrim(aStruct[nx,1]))) + " RETRABALHO")

						cRetDesc := AllTrim(&("SB1->" + AllTrim(aStruct[nx,1]))) + " RETRABALHO"

					ElseIf AllTrim(aStruct[nX,1]) == "B1_GRUPO" .AND. !Empty(cGrupoRet)

						aAdd(aRegistro, AllTrim(cGrupoRet))

					Else

						aAdd(aRegistro, &("SB1->" + AllTrim(aStruct[nx,1])))

					EndIf

				Next

				RecLock("SB1", .T.)

				For nX := 1 to Len(aStruct)

					&("SB1->" + AllTrim(aStruct[nx,1])) := aRegistro[nX]

				Next

				SB1->(MsUnLock())

			EndIf

			//-----------------------------------------------------------
			// Cadastro produto retrabalho na tabela SB5.
			//-----------------------------------------------------------

			If SB5->(DbSeek(xFilial("SB5") + cProduto))

				aStruct   := SB5->(DbStruct())
				aRegistro := {}

				For nX := 1 To Len(aStruct)

					If AllTrim(aStruct[nX,1]) == "B5_COD"

						aAdd(aRegistro, cRetrabalho)

					ElseIf AllTrim(aStruct[nX,1]) == "B5_CEME"

						aAdd(aRegistro, AllTrim(&("SB5->" + AllTrim(aStruct[nx,1]))) + " RETRABALHO")

					Else

						aAdd(aRegistro, &("SB5->" + AllTrim(aStruct[nx,1])))

					EndIf

				Next

				RecLock("SB5", .T.)

				For nX := 1 to Len(aStruct)

					&("SB5->" + AllTrim(aStruct[nx,1])) := aRegistro[nX]

				Next

				SB5->(MsUnLock())

			EndIf

		EndIf

		//-----------------------------------------------------------
		// Cadastro produto retrabalho na tabela SB2.
		//-----------------------------------------------------------

		SB2->(dbSetOrder(1))

		If SB2->(!DbSeek(xFilial("SB2") + cRetrabalho + cLocal))

			CriaSB2(cRetrabalho, cLocal)

		EndIf

		//-----------------------------------------------------------
		// Vinculo do retrabalho com o produto original.
		//-----------------------------------------------------------

		SVK->(dbSetOrder(1))

		If SVK->(!DbSeek(xFilial("SVK") + cRetrabalho ))

			RecLock("SVK", .T.)
			SVK->VK_FILIAL  := xFilial("SVK")
			SVK->VK_COD	    := cRetrabalho
			SVK->VK_PRDORI	:= cProduto
			SVK->VK_HORFIX  := 0
			SVK->VK_RFIDKEY	:= 0
			SVK->VK_RFIDFAT := 0
			SVK->(MsUnLock())

		EndIf

		//-----------------------------------------------------------
		// Faz transferência do saldo do produto original para o
		// produto retrabalho.
		//-----------------------------------------------------------

		SB8->(DbSetOrder(3))

		If SB8->(DbSeek(xFilial("SB8") + cProduto + cLocal + cLoteCtl + cNumLote))

			dDataValid := SB8->B8_DTVALID

		EndIf

		aAuto     := {}
		aRegistro := {}

		//----------------------------------------------------
		// Altera a data de validade do produto destino
		// para resolver o problema de validação padrão.
		//----------------------------------------------------
		SB8->(DbSetOrder(3))
		If SB8->(DbSeek(xFilial("SB8") + cRetrabalho + cLocal + cLoteCtl + cNumLote))

			RecLock("SB8", .F.)
			If dEmissao < SB8->B8_DATA
				SB8->B8_DATA := dEmissao
			EndIF
			SB8->B8_DTVALID := dDataValid
			SB8->(MsUnLock())

		EndIf

		//-------------------------------------------------------------------
		// Valida se a data de emissão está dentro de um perído já fechado
		// Se estiver, coloca um dia além da data de fechamento - Ticket 7099
		//-------------------------------------------------------------------

		If dEmissao <= dFecham
			dEmissao := dFecham+1
		EndIf
		//-------------------------------------------------------------------

		//-------------------------------------------------------------------------------------
		// Valida se a data de emissão está dentro do calendário contábil fechado - Ticket 7274
		//-------------------------------------------------------------------------------------
		If !CtbValiDt(nil,dEmissao,.F.,,,{"EST001"})

			cMsgErro := "Calendário Contábil Bloqueado para a data " + DTOS(dEmissao) + chr(10)
			cMsgErro += "Deseja pegar a data base do sistema para realizar o processo da Op ?"

			If __dAuxCalen == dDataBase .or. MsgYesNo(cMsgErro)
				__dAuxCalen := dDataBase
				dEmissao  := dDataBase // a data de encerramento assume a data base do sistema
			Else
				cMsgErro := "1) Calendário Contábil Bloqueado. Verfique o processo. Data: " + DtoS(dEmissao)
				DisarmTransaction()
				ConOut(cMsgErro)
				MsgStop(cMsgErro)
				Return (.f.)
			EndIF

		EndIF
		//-------------------------------------------------------------------------------------

		If lDocSD3
			aadd(aAuto, {GetSxENum("SD3","D3_DOC",1), dEmissao}) // Cabecalho
		else
			aadd(aAuto, {SD3->(getSxeNum("SD3", "D3_DOC", xFilial("SD3") + "\DATA\" + RetSqlName("SD3"))), dEmissao}) // Cabecalho
		EndIF

		//Itens a Incluir
		__cSublote := 	cNumLote
		//Produto Origem
 		aadd(aRegistro,{"ITEM"     	, "001"      ,Nil}) // ITEM
		aadd(aRegistro,{"D3_COD"   	, cProduto   ,Nil}) // D3_COD
		aadd(aRegistro,{"D3_DESCRI"	, cProDesc   ,Nil}) // D3_DESCRI
		aadd(aRegistro,{"D3_UM"		,SB1->B1_UM  ,Nil}) // D3_UM
		aadd(aRegistro,{"D3_LOCAL"	,cLocal      ,Nil}) // D3_LOCAL
		aadd(aRegistro,{"D3_LOCALIZ",""          ,Nil}) // D3_LOCALIZ
		//Produto Destino
		aadd(aRegistro,{"D3_COD"    ,cRetrabalho ,Nil}) // D3_COD
		aadd(aRegistro,{"D3_DESCRI"	,cRetDesc    ,Nil}) // D3_DESCRI
		aadd(aRegistro,{"D3_UM"		,SB1->B1_UM  ,Nil}) // D3_UM
		aadd(aRegistro,{"D3_LOCAL"	,cLocal      ,Nil}) // D3_LOCAL  
		aadd(aRegistro,{"D3_LOCALIZ",""          ,Nil}) // D3_LOCALIZ
		//Lote + Sub Origem
		aadd(aRegistro,{"D3_NUMSERI",""          ,Nil}) // D3_NUMSERI
		aadd(aRegistro,{"D3_LOTECTL",cLoteCtl    ,Nil}) // D3_LOTECTL
		aadd(aRegistro,{"D3_NUMLOTE",cNumLote    ,Nil}) // D3_NUMLOTE
		aadd(aRegistro,{"D3_DTVALID",dDataValid  ,Nil}) // D3_DTVALID
		aadd(aRegistro,{"D3_POTENCI",0           ,Nil}) // D3_POTENCI
		aadd(aRegistro,{"D3_QUANT"	,nQuantidade ,Nil}) // D3_QUANT  
		aadd(aRegistro,{"D3_QTSEGUM",0           ,Nil}) // D3_QTSEGUM
		aadd(aRegistro,{"D3_ESTORNO",""          ,Nil}) // D3_ESTORNO
		aadd(aRegistro,{"D3_NUMSEQ"	,""          ,Nil}) // D3_NUMSEQ
		//Lote + Sub Destino
		aadd(aRegistro,{"D3_LOTECTL",cLoteCtl    ,Nil}) // D3_LOTECTL
		aadd(aRegistro,{"D3_NUMLOTE",cNumLote    ,Nil}) // D3_NUMLOTE
		aadd(aRegistro,{"D3_DTVALID",dDataValid  ,Nil}) // D3_DTVALID
		aadd(aRegistro,{"D3_ITEMGRD",""          ,Nil}) // D3_ITEMGRD
		//OBS
		aadd(aRegistro,{"D3_OBSERVA","Retrabalho",Nil}) // D3_OBSERVA
		 
		//aadd(aRegistro,"") //cat83 prod origem
		//aadd(aRegistro,"") //cat83 prod destino 

		aadd(aAuto, aRegistro)

		MSExecAuto({|x,y| mata261(x,y)}, aAuto, 3)

		If !lMsErroAuto
			//---------------------------------------------------
			// Vincular transferência com a Ordem de Produção.
			//---------------------------------------------------

			//---------------------------------------------
			// Consulta produto Original
			//---------------------------------------------

			cSql := "  SELECT *"
			cSql += "    FROM " + RetSqlName("SD3") + " SD3"
			cSql += "   WHERE D3_FILIAL  = '" + xFilial("SD3") + "'"
			cSql += "     AND D3_COD     = '" + AllTrim(cProduto) + "'"
			cSql += "     AND D3_LOCAL   = '" + cLocal   + "'"
			cSql += "     AND D3_LOTECTL = '" + cLoteCtl + "'"
			cSql += "     AND D3_NUMLOTE = '" + cNumLote + "'"
			cSql += "     AND D3_EMISSAO = '" + DTOS(dEmissao) + "'"
			cSql += "     AND D3_ESTORNO = ' '"
			cSql += "     AND D3_YOPRETR = ' '"
			cSql += "     AND D_E_L_E_T_ = ' '"

			TCQUERY cSql NEW ALIAS qTransf

			While qTransf->(!Eof())

				// If SD3->(DbGoTo(qTransf->(R_E_C_N_O_)))

				SD3->(DbGoTo(qTransf->(R_E_C_N_O_)))

				RecLock("SD3", .F.)
				SD3->D3_YOPRETR := cNumOp
				SD3->(MsUnLock())

				//----------------------------------------------
				// Atualiza produto retrabalho
				//----------------------------------------------
				If SB8->(msSeek(xFilial("SB8") + cProduto + cLocal + cLoteCtl + cNumLote))

					nB8YCOMBRU := SB8->B8_YCOMBRU
					nB8YALTBRU := SB8->B8_YALTBRU
					nB8YESPBRU := SB8->B8_YESPBRU
					nB8YTOTBRU := SB8->B8_YTOTBRU
					nB8YCOMLIQ := SB8->B8_YCOMLIQ
					nB8YALTLIQ := SB8->B8_YALTLIQ
					nB8YESPLIQ := SB8->B8_YESPLIQ
					nB8YTOTLIQ := SB8->B8_YTOTLIQ
					nB8YCUSTO  := SB8->B8_YCUSTO
					cB8YDOC    := SB8->B8_YDOC 	 //Produto retrabalho indo para o cavalete  4 - https://projetostotvses.freshdesk.com/a/tickets/2445
					cB8YSERIE  := SB8->B8_YSERIE //Produto retrabalho indo para o cavalete  4 - https://projetostotvses.freshdesk.com/a/tickets/2445
					nB8YPESLIQ := SB8->B8_YPESOLQ
					nB8YPESBRU := SB8->B8_YPESOBR

				endIf

				If SB8->(msSeek(xFilial("SB8") + cRetrabalho + cLocal + cLoteCtl + cNumLote))

					RecLock("SB8", .F.)
					SB8->B8_YCOMBRU := nB8YCOMBRU
					SB8->B8_YALTBRU := nB8YALTBRU
					SB8->B8_YESPBRU := nB8YESPBRU
					SB8->B8_YTOTBRU := nB8YTOTBRU
					SB8->B8_YCOMLIQ := nB8YCOMLIQ
					SB8->B8_YALTLIQ := nB8YALTLIQ
					SB8->B8_YESPLIQ := nB8YESPLIQ
					SB8->B8_YTOTLIQ := nB8YTOTLIQ
					SB8->B8_YCUSTO  := nB8YCUSTO
					//SB8->B8_YCAVALE := "" 	     //Produto retrabalho indo para o cavalete  4 - https://projetostotvses.freshdesk.com/a/tickets/2445
					SB8->B8_YDOC    := cB8YDOC   //Produto retrabalho indo para o cavalete  4 - https://projetostotvses.freshdesk.com/a/tickets/2445
					SB8->B8_YSERIE  := cB8YSERIE //Produto retrabalho indo para o cavalete  4 - https://projetostotvses.freshdesk.com/a/tickets/2445
					SB8->B8_YPESOLQ := nB8YPESLIQ
					SB8->B8_YPESOBR := nB8YPESBRU
					SB8->(msunlock())

				endIf

				// EndIf

				qTransf->(DbSkip())

			EndDo

			qTransf->(DbCloseArea())

			//---------------------------------------------
			// Consulta produto Retrabalho
			//---------------------------------------------
			cSql := "  SELECT D3_COD, D3_QUANT, R_E_C_N_O_"
			cSql += "    FROM " + RetSqlName("SD3") + " SD3"
			cSql += "   WHERE D3_FILIAL  = '" + xFilial("SD3") + "'"
			cSql += "     AND D3_COD     = '" + cRetrabalho + "'"
			cSql += "     AND D3_LOCAL   = '" + cLocal   + "'"
			cSql += "     AND D3_LOTECTL = '" + cLoteCtl + "'"
			cSql += "     AND D3_NUMLOTE = '" + cNumLote + "'"
			cSql += "     AND D3_EMISSAO = '" + DTOS(dEmissao) + "'"
			cSql += "     AND D3_ESTORNO = ' '"
			cSql += "     AND D3_YOPRETR = ' '"
			cSql += "     AND D_E_L_E_T_ = ' '"

			TCQUERY cSql NEW ALIAS qTransf

			While qTransf->(!Eof())

				// If SD3->(DbGoTo(qTransf->(R_E_C_N_O_)))

				SD3->(DbGoTo(qTransf->(R_E_C_N_O_)))

				RecLock("SD3", .F.)
				SD3->D3_YOPRETR := cNumOp
				//SD3->D3_YCAVALE := "" //Produto retrabalho indo para o cavalete  4 - https://projetostotvses.freshdesk.com/a/tickets/2445
				SD3->(MsUnLock())

				// EndIf

				qTransf->(DbSkip())

			EndDo

			qTransf->(DbCloseArea())

		EndIf

	EndIf

Return Nil


/*/{Protheus.doc} delRetrabalho
Função utilizada para excluir transferência de retrabalho.

@author Kenny Roger Martins
@since 10/08/2017
@version 1.0

@return
/*/
Static Function delRetraba(aParam)

	Local aAreaANT    := GetArea()
	Local aAreaSD3    := SD3->(GetArea())
	Local aAreaSC2    := SC2->(GetArea())

	Local cProduto    := ""
	Local cLocal      := ""
	Local cLoteCtl    := ""
	Local cNumLote    := ""
	Local dDataLanc   := STOD("")
	Local cNumOp      := ""
	Local cSql        := ""
	Local cCavale	  := ""
	Local qTransf     := Nil
	Local aAuto       := {}
	Local lRet        := .T.

	Local cCodOrig    := ""
	Local nRecOrig    := 0
	Local cCodDest    := ""
	Local nRecDest    := 0
	Local nQuant260	  := 0
	Local nQuant260D  := 0
	Local lEstorno    := .T.

	Local cLocOrig    := nil
	Local cLoclzOrig  := nil
	Local cDocto      := nil
	Local dEmis260    := nil
	Local cLoteDigi   := nil
	Local dDtValid    := nil
	Local cNumSerie   := nil
	Local cLocDest    := nil
	Local cLocLzDest  := nil
	Local cLoteDest   := nil
	Local cPrograma   := nil
	Local cEstFis     := nil
	Local cServico    := nil
	Local cTarefa     := nil
	Local cAtividade  := nil
	Local cAnomalia   := nil
	Local cEstDest    := nil
	Local cEndDest    := nil
	Local cHrInicio   := nil
	Local cAtuEst     := nil
	Local cCarga      := nil
	Local cUnitiza    := nil
	Local cOrdTar     := nil
	Local cOrdAti     := nil
	Local cRHumano    := nil
	Local cRFisico    := nil
	Local nPotencia   := nil
	Local cSiglaRet   := AllTrim(GetNewPar("GR_SIGLARE", "R"))

	Private cCusMed   := GetMv("MV_CUSMED")
	Private lCriaHeader := .F.
	//https://totvsleste.freshdesk.com/a/tickets/1322
	//variaveis para a função a260Processa não apresentar erro
	Private lCriaHeader := .F.
	PRIVATE cLoteEst
	PRIVATE cArquivo		// Nome do arquivo contra prova
	PRIVATE nHdlPrv
	PRIVATE nTotal := 0 	// Total dos lancamentos contabeis

	Default aParam    := {}

	If cCusMed == "O"
		lCriaHeader := .T.
	Endif

	cProduto  := If(Len(aParam) > 0, aParam[1], "")
	cLocal    := If(Len(aParam) > 1, aParam[2], "")
	cLoteCtl  := If(Len(aParam) > 2, aParam[3], "")
	cNumLote  := If(Len(aParam) > 3, aParam[4], "")
	dDataLanc := If(Len(aParam) > 4, aParam[5], StoD(""))
	cNumOp    := If(Len(aParam) > 5, aParam[6], "")

	//-----------------------------------------------------------
	// Exclui transferência do saldo do produto original para o
	// produto retrabalho.
	//-----------------------------------------------------------

	//---------------------------------------------
	// Consulta produto Original
	//---------------------------------------------

	cSql := "  SELECT *"
	cSql += "    FROM " + RetSqlName("SD3") + " SD3"
	cSql += "   WHERE D3_FILIAL  = '" + xFilial("SD3") + "'"
	cSql += "     AND D3_COD     = '" + AllTrim(cProduto) + "'"
	cSql += "     AND D3_LOCAL   = '" + cLocal   + "'"
	cSql += "     AND D3_LOTECTL = '" + cLoteCtl + "'"
	cSql += "     AND D3_NUMLOTE = '" + cNumLote + "'"
	cSql += "     AND D3_EMISSAO = '" + DTOS(dDataLanc) + "'"
	cSql += "     AND D3_YOPRETR = '" + cNumOp   + "'"
	cSql += "     AND D3_ESTORNO = ' '"
	cSql += "     AND D_E_L_E_T_ = ' '"

	TCQUERY cSql NEW ALIAS qTransf

	While qTransf->(!Eof())

		cCodOrig  := qTransf->D3_COD
		nRecOrig  := qTransf->R_E_C_N_O_
		nQuant260 := qTransf->D3_QUANT

		qTransf->(DbSkip())

	EndDo

	qTransf->(DbCloseArea())

	//---------------------------------------------
	// Consulta produto Retrabalho
	//---------------------------------------------
	cSql := "  SELECT D3_COD, D3_QUANT, D3_YCAVALE, R_E_C_N_O_"
	cSql += "    FROM " + RetSqlName("SD3") + " SD3"
	cSql += "   WHERE D3_FILIAL  = '" + xFilial("SD3") + "'"
	cSql += "     AND D3_COD     = '" + AllTrim(cProduto) + cSiglaRet + "'"
	cSql += "     AND D3_LOCAL   = '" + cLocal   + "'"
	cSql += "     AND D3_LOTECTL = '" + cLoteCtl + "'"
	cSql += "     AND D3_NUMLOTE = '" + cNumLote + "'"
	cSql += "     AND D3_EMISSAO = '" + DTOS(dDataLanc) + "'"
	cSql += "     AND D3_YOPRETR = '" + cNumOp   + "'"
	cSql += "     AND D3_ESTORNO = ' '"
	cSql += "     AND D_E_L_E_T_ = ' '"

	TCQUERY cSql NEW ALIAS qTransf

	While qTransf->(!Eof())

		cCodDest  := qTransf->D3_COD
		cCavale	  := qTransf->D3_YCAVALE
		nRecDest  := qTransf->R_E_C_N_O_

		qTransf->(DbSkip())

	EndDo

	qTransf->(DbCloseArea())

	If SC2->C2_TPOP == 'F'

		SB8->(dbSetOrder(3)) //B8_FILIAL+B8_PRODUTO+B8_LOCAL+B8_LOTECTL+B8_NUMLOTE+DTOS(B8_DTVALID)

		If SB8->(MsSeek(xFilial("SB8") + cProduto + cLocal + cLoteCtl + cNumLote))

			RecLock("SB8", .F.)
			SB8->B8_YCAVALE = cCavale
			MsUnlock("SB8")

		Endif

		If SB8->(MsSeek(xFilial("SB8") + AllTrim(cProduto) + cSiglaRet + Space(Len(cProduto) - Len(AllTrim(cProduto)) - LEN(cSiglaRet)) + cLocal + cLoteCtl + cNumLote))

			RecLock("SB8", .F.)
			SB8->B8_YCAVALE = ""
			MsUnlock("SB8")

		Endif

	EndIf

	SD3->(dbSetOrder(2))

	SD3->(DbGoTo(nRecOrig))

	If nRecOrig > 0 .And. nRecDest > 0

		//Excluindo o empenho do produto retrabalho para conseguir estornar o produto via rotina padrão
		SD4->(dbSetOrder(2))
		SD4->(msSeek(xFilial("SD4") + cNumOp))
		while SD4->(!eof()) .and. SD4->D4_FILIAL + ALLTRIM(SD4->D4_OP) == xFilial("SD4") + cNumOp

			aArraySD4	:= {}

			aAdd(aArraySD4, {"D4_FILIAL", SD4->D4_FILIAL, NIL})
			aAdd(aArraySD4, {"D4_COD",    SD4->D4_COD,    NIL})
			aAdd(aArraySD4, {"D4_OP",     SD4->D4_OP,     NIL})

			MSExecAuto({|x,y| MATA380(x,y)}, aArraySD4, 5)

			If lMsErroAuto
				MostraErro()
				Return .F.
			EndIf

			SD4->(DbSkip())
		EndDo

		// Estornando as movimentações de entrada e saida da SD3 para o retrabalho e produto origem
		// Incluindo somente os dados do produto destino foi verificado que o sistema exclui os dois
		SD3->(DBGOTOP())
		SD3->(DbGoTo(nRecDest))

		aAuto := {}
		aadd(aAuto,{"D3_DOC", SD3->D3_DOC, Nil})
		aadd(aAuto,{"D3_COD", SD3->D3_COD, Nil})

		MSExecAuto({|x,y| mata261(x,y)},aAuto,6)
		if lMsErroAuto
			MostraErro()
			Return .F.
		ENDiF

	EndIf

	RestArea(aAreaANT)
	RestArea(aAreaSC2)
	RestArea(aAreaSD3)

Return Nil


/*/{Protheus.doc} getConsult
Função utilizada para excluir transferência de retrabalho.

@author Kenny Roger Martins
@since 10/08/2017
@version 1.0

@return
/*/
Static Function getConsult(aParam)

	Local cReturn  := ""
	Local cSql     := ""
	Local qQRYZG9  := ""
	Local lFiltro  := .T.
	Local cProduto := ""

	Default aParam := ""

	if valtype(aparam) == "A" .and. (len(aparam)>1)
		cProduto := aParam[1]
		lFiltro  := aparam[2]
	else
		cProduto := aParam
	EndIF

	cSql := " SELECT ZG9_ROTEIR "
	cSql += "   FROM " + RetSqlName("ZG9") + " ZG9 "
	cSql += "  WHERE ZG9.ZG9_FILIAL = '" + xFilial("ZG9") + "'"

	IF (lFiltro)
		cSql += "    AND ZG9.ZG9_PRODUT = '" + cProduto + "'"
	EndIf

	cSql += "    AND ZG9.D_E_L_E_T_ = ' '"

	TCQUERY cSql NEW ALIAS qQRYZG9

	While qQRYZG9->(!Eof())

		cReturn += qQRYZG9->ZG9_ROTEIR + "/"

		qQRYZG9->(DbSkip())

	EndDo

	qQRYZG9->(DbCloseArea())

	DbSelectArea("ZG7")

Return cReturn


/*/{Protheus.doc} GRXTPPED()
Função que retorna o tipo de pedido de venda

@author Kenny Roger Martins
@since 21/02/2017
@version 1.0

@example GrxTpPed()
@obs 

@return cTipo
/*/
User Function GrxTpPed()

	Local cTipo := "PV"

	Do Case

	Case "GROA001" $ AllTrim(FunName()) ; cTipo := "RI" // Remessa para Industrialização
	Case "GROA003" $ AllTrim(FunName()) ; cTipo := "TF" // Transferência entre Filial
	Case "GROA013" $ AllTrim(FunName()) ; cTipo := "MI" // Mercado Interno
	Case "GROA014" $ AllTrim(FunName()) ; cTipo := "ME" // Mercado Externo
	OtherWise; cTipo := "PV" // Pedido de Venda

	EndCase

Return cTipo

/*/{Protheus.doc} getValField
Retorna conteudo do campo dentro de um Array

@author Kenny Roger Martins
@since 04/01/2017
@version ALL
/*/
User Function getValField(cCampo, aCols, aHeader)

	Local cContent := ""
	Local nPosicao := 0

	Default aHeader := {}

	If Len(aHeader) > 0

		nPosicao := aScan(aHeader, {|x| AllTrim(x[2]) == AllTrim(cCampo)})

		If nPosicao > 0

			cContent := aCols[nPosicao]

		EndIf

	Else

		nPosicao := aScan(aCols, {|x| AllTrim(x[1]) == AllTrim(cCampo)})

		If nPosicao > 0

			cContent := aCols[nPosicao, 2]

		EndIf

	EndIf

Return cContent

/*/{Protheus.doc} setValField
Altera o conteudo de um campo dentro de um Array

@author DEV
@since 04/01/2017
@version ALL
/*/
User Function setValField(cCampo, cContent, aArray)

	Local nPosicao := 0

	nPosicao := aScan(aArray, {|x| AllTrim(x[1]) == AllTrim(cCampo)})

	If nPosicao > 0

		aArray[nPosicao, 2] := cContent

	EndIf

Return Nil

/*/{Protheus.doc} tools
function GetProField

@author DEV
@since 04/01/2017
@version ALL
/*/
User Function getProField(aParams)

	Local aReturn := {}
	Local aField := {}
	Local nX := 0

	For nX := 1 To Len(aParams)

		aField  := {}
		aAdd(aField, GetSx3Cache(aParams[nX], 'X3_TITULO'))
		aAdd(aField, aParams[nX])
		aAdd(aField, GetSx3Cache(aParams[nX], 'X3_TIPO'))
		aAdd(aField, GetSx3Cache(aParams[nX], 'X3_TAMANHO'))
		aAdd(aField, GetSx3Cache(aParams[nX], 'X3_TAMANHO'))
		aAdd(aField, GetSx3Cache(aParams[nX], 'X3_PICTURE'))
		aAdd(aReturn, aField)

	Next

Return aReturn

/*/{Protheus.doc} tools
function ExistField

@author DEV
@since 04/01/2017
@version ALL
/*/
User Function ExistField(cField)

	Local lRet     := .f.
	Local aAreaANT := getArea()
	Local aAreaSX3 := SX3->(GetArea())

	SX3->(DbSetOrder(2))
	If SX3->(MsSeek(cField))
		lRet := .t.
	EndIf

	RestArea(aAreaANT)
	RestArea(aAreaSX3)

Return lRet


/*/{Protheus.doc} tools
function GetInvoice

@author DEV
@since 04/01/2017
@version ALL
/*/
User Function getInvoice()

	Local cSql := ""
	Local qQuery := ""
	Local cInvoice := ""

	cSql := " SELECT COALESCE(MAX(C5_YINVOIC),'0') AS NUMINVOICE"
	cSql += "   FROM " + retSqlName("SC5")
	cSql += "  WHERE C5_FILIAL  = '" + xFilial("SC5") + "'"
	cSql += "    AND D_E_L_E_T_ = ' '"
	TCQUERY cSql NEW ALIAS qQuery

	cInvoice := soma1(qQuery->NUMINVOICE)

	qQuery->(dbCloseArea())

Return cInvoice

/*/{Protheus.doc} tools
function OpcSel

@author DEV
@since 04/01/2017
@version ALL
/*/
User Function OpcSel(cCampo, cParam)

	Local aStruct  := {}
	Local aCpoBro  := {}
	Local oDlg     := Nil
	Local cArq     := ""
	Local nX       := 0
	local aSelecao := {}
	Local cResult  := ""
	Local lRet     := .T.
	Local lInverte := .F.
	Local cMark    := GetMark()
	Local oMark

	Default cCampo  := ""
	Default cParam  := ""

	cResult  := AllTrim(&(cParam))
	aSelecao := retSx3Box(x3CBox( posicione('SX3',2,cCampo,'X3_CBOX') ),,,1)

	//Cria um arquivo de Apoio

	AADD(aStruct,{"OK"     , "C"	,2		,0		})
	AADD(aStruct,{"SELECAO", "C"	,40		,0		})

	cArq := Criatrab(aStruct,.T.)

	DBUSEAREA(.t.,,cArq,"TTRB")

	For nX	:= 1 To Len(aSelecao)

		If !Empty(aSelecao[nX][1])

			DbSelectArea("TTRB")

			RecLock("TTRB",.T.)

			If aSelecao[nX][2] $ cResult

				TTRB->OK := cMark

			EndIf

			TTRB->SELECAO := aSelecao[nX][1]

			TTRB->(MsunLock())

		EndIf

	Next

	TTRB->(DbGoTop())

	//Define quais colunas (campos da TTRB) serao exibidas na MsSelect
	aCpoBro	:= {{ "OK",,"","@!"},;
		{ "SELECAO",,"Opções" ,"@!"}}

	//Cria uma Dialog

	DEFINE MSDIALOG oDlg TITLE "Seleção" From 9,0 To 315,500 PIXEL

	//Cria a MsSelect

	oMark := MsSelect():New("TTRB","OK","",aCpoBro,@lInverte,@cMark,{0,0,0,0},,,,,)

	oMark:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	//Exibe a Dialog

	ACTIVATE MSDIALOG oDlg CENTERED ON INIT EnchoiceBar(oDlg, {|| oDlg:End()}, {|| lRet := .F., oDlg:End()})

	If lRet

		cResult := ""

		TTRB->(DbGoTop())

		While TTRB->(!Eof())

			If TTRB->OK == cMark

				cResult += SubStr(TTRB->SELECAO,1,1) + ","

			EndIf

			TTRB->(DbSkip())

		EndDo

		cResult := If(SubStr(cResult,Len(cResult),Len(cResult))==',', SubStr(cResult,1,Len(cResult)-1), cResult)

	EndIf

	TTRB->(DbCloseArea())

	Iif(File(cArq + GetDBExtension()),FErase(cArq  + GetDBExtension()) ,Nil)

	&(cParam) := cResult

Return lRet

/*/{Protheus.doc} tools
function getCodBar
Retorna o código de barras formatado
@author DEV
@since 28/06/2018
@version ALL
/*/
User Function getCodBar(cTipo, cLote, cSub)

	Local cCodBar  := ""
	Local cMascara := u_retMask(,AllTrim(cLote))  //GetNewPar("GR_CODBARR", "TTTLLLLLLLLSSS")
	Local nTamTipo := u_getQtdCtr(cMascara, "T")
	Local nTamLote := u_getQtdCtr(cMascara, "L")
	Local nTamSub  := u_getQtdCtr(cMascara, "S")

	cTipo := PadL(AllTrim(cTipo), TamSx3("B5_YTIPMAT")[1], "0")
	cLote := PadL(AllTrim(cLote), TamSx3("B8_LOTECTL")[1], "0")

	cCodBar := PadL(SubStr(AllTrim(cTipo), Len(AllTrim(cTipo))-nTamTipo+1, Len(AllTrim(cTipo))), nTamTipo, "0")
	cCodBar += PadL(SubStr(AllTrim(cLote), Len(AllTrim(cLote))-nTamLote+1, Len(AllTrim(cLote))), nTamLote, "0")

	If !Empty(cSub)
		cCodBar += PadL(SubStr(AllTrim(cSub),  Len(AllTrim(cSub))-nTamSub+1,   Len(AllTrim(cSub))),  nTamSub,  "0")
	EndIf

Return cCodBar

/*/{Protheus.doc} tools
function getQtdCtr
Retorna a quantidade de caracteres da string
@author DEV
@since 28/06/2018
@version ALL
/*/
User Function getQtdCtr(cString, cCaractere)

	Local nQtde := 0
	Local nX    := 0

	For nX := 1 To Len(cString)

		If SubStr(cString, nX, 1) == cCaractere

			nQtde++

		EndIf

	Next

Return nQtde

/*/{Protheus.doc} tools
function getCodSql
Retorna o sql do código de barras
@author DEV
@since 28/06/2018
@version ALL
/*/
User Function getCodSql(cCpoLot, cCpoSub, lBloco)

	Local cSql := ""
	Local cMascara := GetNewPar("GR_CODBARR", "TTTLLLLLLLLSSS")

	Default cCpoLot := "B8_LOTECTL"
	Default cCpoSub := "B8_NUMLOTE"
	Default lBloco  := .F.

	cSGBD := TCGetDB()

	if (cSGBD $ "ORACLE")

		cSql += "   CASE WHEN LENGTH(RTRIM(B5_YTIPMAT)) < "  + cValToChar(U_GETQTDCTR(cMascara, "T"))
		cSql += "   THEN RTRIM(LPAD('0', " + cValToChar((U_GETQTDCTR(cMascara, "T"))) + " - LENGTH(RTRIM(B5_YTIPMAT)), '0')) ELSE NULL END"
		cSql += " || CASE WHEN LENGTH(RTRIM(B5_YTIPMAT)) > " + cValToChar(U_GETQTDCTR(cMascara, "T"))
		cSql += "   THEN SUBSTR(RTRIM(B5_YTIPMAT), LENGTH(RTRIM(B5_YTIPMAT)) - " + cValToChar(U_GETQTDCTR(cMascara, "T") - 1) + ", LENGTH(RTRIM(B5_YTIPMAT))) ELSE RTRIM(B5_YTIPMAT) END "

		cSql += " || CASE WHEN LENGTH(RTRIM(" + cCpoLot + ")) < " + cValToChar(U_GETQTDCTR(cMascara, "L"))
		cSql += "   THEN RTRIM(LPAD('0', " + cValToChar((U_GETQTDCTR(cMascara, "L"))) + " - LENGTH(RTRIM(" + cCpoLot + ")), '0')) ELSE NULL END"
		cSql += " || CASE WHEN LENGTH(RTRIM(" + cCpoLot + ")) > " + cValToChar(U_GETQTDCTR(cMascara, "L"))
		cSql += "   THEN SUBSTR(RTRIM(" + cCpoLot + "),  LENGTH(RTRIM(" + cCpoLot + ")) - " + cValToChar(U_GETQTDCTR(cMascara, "L") - 1) + ", LENGTH(RTRIM(" + cCpoLot + "))) ELSE RTRIM(" + cCpoLot + ") END "

		If !lBloco
			cSql += " || CASE WHEN LENGTH(RTRIM(" + cCpoSub + ")) < " + cValToChar(U_GETQTDCTR(cMascara, "S"))
			cSql += "   THEN RTRIM(LPAD('0', " + cValToChar((U_GETQTDCTR(cMascara, "S"))) + " - LENGTH(RTRIM(" + cCpoSub + ")), '0')) ELSE NULL END"
			cSql += " || CASE WHEN LENGTH(RTRIM(" + cCpoSub + ")) > " + cValToChar(U_GETQTDCTR(cMascara, "S"))
			cSql += "   THEN SUBSTR(RTRIM(" + cCpoSub + "),  LENGTH(RTRIM(" + cCpoSub + ")) - " + cValToChar(U_GETQTDCTR(cMascara, "S") - 1) + ", LENGTH(RTRIM(" + cCpoSub + "))) ELSE RTRIM(" + cCpoSub + ") END "
		EndIf
	Else

		cSql += "   COALESCE(REPLICATE('0', " + cValToChar(U_GETQTDCTR(cMascara, "T")) + " - LEN(RTRIM(B5_YTIPMAT))), ' ') "
		cSql += " + CASE WHEN LEN(RTRIM(B5_YTIPMAT)) > " + cValToChar(U_GETQTDCTR(cMascara, "T"))
		cSql += "   THEN SUBSTRING(RTRIM(B5_YTIPMAT),  " + cValToChar(TamSx3("B5_YTIPMAT")[1] - U_GETQTDCTR(cMascara, "T") + 1) + ", " + cValToChar(TamSx3("B5_YTIPMAT")[1]) + ") ELSE RTRIM(B5_YTIPMAT) END "

		cSql += " + COALESCE(REPLICATE('0', " + cValToChar(U_GETQTDCTR(cMascara, "L")) + " - LEN(RTRIM(" + cCpoLot + "))), ' ') "
		cSql += " + CASE WHEN LEN(RTRIM(" + cCpoLot + ")) > " + cValToChar(U_GETQTDCTR(cMascara, "L")+1)
		cSql += "   THEN SUBSTRING(RTRIM(" + cCpoLot + "),  " + cValToChar(TamSx3("" + cCpoLot + "")[1] - U_GETQTDCTR(cMascara, "L") + 1) + ", " + cValToChar(TamSx3(cCpoLot)[1]) + ") ELSE RTRIM(" + cCpoLot + ") END "

		If !lBloco
			cSql += " + COALESCE(REPLICATE('0', " + cValToChar(U_GETQTDCTR(cMascara, "S")) + " - LEN(RTRIM(" + cCpoSub + "))), ' ') "
			cSql += " + CASE WHEN LEN(RTRIM(" + cCpoSub + ")) > " + cValToChar(U_GETQTDCTR(cMascara, "S"))
			cSql += "   THEN SUBSTRING(RTRIM(" + cCpoSub + "),  " + cValToChar(TamSx3("" + cCpoSub + "")[1] - U_GETQTDCTR(cMascara, "S") + 1) + ", " + cValToChar(TamSx3(cCpoSub)[1]) + ") ELSE RTRIM(" + cCpoSub + ") END "
		EndIf
	EndIf

	cSql := " TRIM( "+ cSql+ ") "

Return cSql

/*/{Protheus.doc} tools
function getSpace
Retorna a variável com os espaços conforme SX3
@author DEV
@since 01/03/2019
@version ALL
/*/
User Function getSpace(cValue, cField)

	cValue := cValue + Space(TamSx3(cField)[1] - Len(cValue))

Return cValue

/*/{Protheus.doc} getValData
Valida se a data de entrada da MP é menor ou igual
a data da abertura da OP.
@type  User Function
@author Kenny Roger Martins
/*/
User Function getValData(aArrayMP, dDataValid)

	Local lRet     := .T.
	Local cChave   := ""
	Local cMessage := ""

	cChave := xFilial("SB8") + ;
		U_GetSpace(U_GetValField("C2_YMP",     aArrayMP), "C2_YMP") + ;
		U_GetSpace(U_GetValField("C2_YLOCMP",  aArrayMP), "C2_YLOCMP") + ;
		U_GetSpace(U_GetValField("C2_YLOTECT", aArrayMP), "C2_YLOTECT") + ;
		U_GetSpace(U_GetValField("C2_YNUMLOT", aArrayMP), "C2_YNUMLOT")

	SB8->(DbSetOrder(3))

	If SB8->(DbSeek(cChave))

		If SB8->B8_DATA > dDataValid

			lRet := .F.
			cMessage := "A data de entrada da Matéria-Prima - Data(B8_DATA): " +FWTimeStamp(2,SB8->B8_DATA,"00:00:00") + CHR(13) + CHR(10)+ " é maior que a data da Ordem de Produção. - Data: "+ FWTimeStamp(2,dDataValid,"00:00:00") + ;
				"Favor alterar a data da Ordem de Produção ou alterar a data de entrada da Matéira-Prima."

		EndIf

	EndIf

Return {lRet, cMessage}

/*/{Protheus.doc} tools
function sqlOps
Retorna o sql concatenado dos lotes da Ordem de produção
@author DEV
@since 23/04/2019
@version ALL
/*/
User Function sqlOps(cCondicao, lDefault)

	Local cQuery   := ""
	Local cBloco   := ""
	Local lSqlSD4  := GETNEWPAR("GR_QSC2SD4", .F.) // Atualiza peso da chapa pela divisão do peso do cavalete.

	Default cCondicao := ""
	Default lDefault  := .F.

	cSGBD := TCGetDB()

	DbSelectArea("ZH6")

	cQuery := "    SELECX C2_FILIAL,  C2_NUM,     C2_YTIPO,   C2_TPOP,    C2_STATUS,  C2_EMISSAO,"
	cQuery += "           C2_DATPRI,  C2_DATPRF,  C2_YTEAR,   C2_YLARTEA, C2_YALTTEA, C2_YCOMTEA,"
	cQuery += "           C2_YOCUPAC, C2_YLAMINA, H1_DESCRI,  C2_YSITUAC, C2_YFRENTE, ZG2_DESCRI,"
	cQuery += "           C2_YCODMOT, ZH6_DESCRI, C2_YCOECOR,"
	cQuery += "           MAX(C2_YENGENH) AS C2_YENGENH,"
	cQuery += "           AVG(C2_YAPROVE) AS C2_YAPROVE,"
	cQuery += "           MAX(ZG7_DESCRI) AS ZG7_DESCRI,"

	If lSqlSD4
		cBloco += " CAST(COALESCE(( " + chr(10)

		if (cSGBD $ "ORACLE")
			cBloco += "    SELECX  LISTAGG(  RTRIM(D4_LOTECTL) ,', '  )  WITHIN GROUP ( ORDER BY RTRIM(D4_LOTECTL) ) " + chr(10)
		Else
			cBloco += "    SELECX RTRIM(D4_LOTECTL) + ', ' AS [text()] " + chr(10)
		EndIf

		cBloco += "      FROX " + RetSqlName("SD4") + " BLOCO " + chr(10)
		cBloco += "     WHERE BLOCO.D4_FILIAL = '" + xFilial("SC2") + "' " + chr(10)
		cBloco += "       AND BLOCO.D4_OP     LIKE SC2.C2_NUM + '%' " + chr(10)
		cBloco += "       AND BLOCO.D_E_L_E_T_ = ' ' " + chr(10)

		if (cSGBD $ "ORACLE")
			cBloco += "  GROUX BY substr(D4_OP,1,6) " + chr(10)
		Else
			cBloco += "  GROUX BY D4_LOTECTL " + chr(10)
			cBloco += "  ORDEX BY D4_LOTECTL " + chr(10)
			cBloco += "  FOR XML PATH(''), TYPE).value('.[1]', 'VARCHAR(MAX)' " + chr(10)
		EndIf

		cBloco += "  ), ' ') AS VARCHAR(100)) " + chr(10)
	Else
		cBloco += " CAST(COALESCE(( " + chr(10)

		if (cSGBD $ "ORACLE")
			cBloco += "    SELECX  LISTAGG(  RTRIM(C2_YLOTECT) ,', '  )  WITHIN GROUP ( ORDER BY RTRIM(C2_YLOTECT) ) " + chr(10)
		Else
			cBloco += "    SELECX RTRIM(C2_YLOTECT) + ', ' AS [text()] " + chr(10)
		EndIf

		cBloco += "      FROX " + RetSqlName("SC2") + " BLOCO " + chr(10)
		cBloco += "     WHERE BLOCO.C2_FILIAL = '" + xFilial("SC2") + "' " + chr(10)
		cBloco += "       AND BLOCO.C2_NUM    = SC2.C2_NUM " + chr(10)
		cBloco += "       AND BLOCO.D_E_L_E_T_ = ' ' " + chr(10)

		if (cSGBD $ "ORACLE")
			cBloco += "  GROUX BY C2_NUM " + chr(10)
		else
			cBloco += "  GROUX BY C2_YLOTECT " + chr(10)
			cBloco += "  ORDEX BY C2_YLOTECT " + chr(10)
			cBloco += "   FOR XML PATH(''), TYPE).value('.[1]', 'VARCHAR(MAX)' " + chr(10)
		EndIf

		cBloco += "  ), ' ') AS VARCHAR(100)) " + chr(10)

	EndIf

	if (cSGBD $ "ORACLE")
		cQuery += "       SUBSTR(" + cBloco + ", 1, CASE WHEN LENGTH(" + cBloco + ") > 0 THEN LENGTH(" + cBloco + ") ELSE 0 END) AS D4_LOTECTL " + chr(10)
	Else
		cQuery += "       SUBSTRING(" + cBloco + ", 1, CASE WHEN LEN(" + cBloco + ") > 0 THEN LEN(" + cBloco + ")-1 ELSE 0 END) AS D4_LOTECTL " + chr(10)
	EndIf

	cQuery += "      FROX " + RetSqlName("SC2") + " SC2"

	cQuery += " LEFT JOIN " + RetSqlName("SH1") + " SH1"
	cQuery += "        ON SH1.H1_FILIAL  = '" + xFilial('SH1') + "' "
	cQuery += "       AND SH1.H1_CODIGO  = SC2.C2_YTEAR "
	cQuery += "       AND SH1.D_E_L_E_T_ = ' ' "

	cQuery += " LEFT JOIN " + RetSqlName("ZG2") + " ZG2"
	cQuery += "        ON ZG2.ZG2_FILIAL = '" + xFilial('ZG2') + "' "
	cQuery += "       AND ZG2.ZG2_CODIGO = SC2.C2_YFRENTE "
	cQuery += "       AND ZG2.D_E_L_E_T_ = ' ' "

	cQuery += " LEFT JOIN " + RetSqlName("ZG7") + " ZG7"
	cQuery += "        ON ZG7.ZG7_FILIAL = '" + xFilial('ZG7') + "' "
	cQuery += "       AND ZG7.ZG7_CODIGO = SC2.C2_YENGENH "
	cQuery += "       AND ZG7.D_E_L_E_T_ = ' ' "

	cQuery += " LEFT JOIN " + RetSqlName("ZH6") + " ZH6"
	cQuery += "        ON ZH6.ZH6_FILIAL = '" + xFilial('ZH6') + "' "
	cQuery += "       AND ZH6.ZH6_CODIGO = SC2.C2_YCODMOT "
	cQuery += "       AND ZH6.D_E_L_E_T_ = ' ' "

	cQuery += "     WHERE SC2.C2_FILIAL  = '" + xFilial('SC2') + "' "
	cQuery += "       AND SC2.D_E_L_E_T_ = ' ' "
	cQuery += cCondicao

	cQuery += "  GROUX BY C2_FILIAL,  C2_NUM,     C2_YTIPO,  C2_TPOP,    C2_STATUS,  C2_EMISSAO,"
	cQuery += "           C2_DATPRI,  C2_DATPRF,  C2_YTEAR,  C2_YLARTEA, C2_YALTTEA, C2_YCOMTEA,"
	cQuery += "           C2_YOCUPAC, C2_YLAMINA, H1_DESCRI, C2_YSITUAC, C2_YFRENTE, ZG2_DESCRI,"
	cQuery += "           C2_YCODMOT, ZH6_DESCRI, C2_YCOECOR"

	If lDefault
		cQuery := StrTran(cQuery, "SELECX", "SELECT")
		cQuery := StrTran(cQuery, "FROX", "FROM")
		cQuery := StrTran(cQuery, "GROUX", "GROUP")
		cQuery := StrTran(cQuery, "ORDEX", "ORDER")
	EndIf

	//Quando e oracle precisa do change query, quando e sql ele da erro ocm o change query
	if (cSGBD $ "ORACLE")
		cQuery := ChangeQuery(cQuery)
	EndIf

Return cQuery

/*/{Protheus.doc} tools
function getIndex
Retorna o número do indice do nickname
@author DEV
@since 07/05/2019
@version ALL
/*/
User Function getIndex(cTmpAlias, cTmpNick)

	Local nTmpIndex := 1
	Local aAreaANT := GetArea()
	Local aAreaAli := (&(cTmpAlias))->(GetArea())

	Default cTmpAlias := ""
	Default cTmpNick  := ""

	If !Empty(cTmpAlias) .And. !Empty(cTmpNick)
		&(cTmpAlias)->(DbOrderNickName(cTmpNick))
		nTmpIndex := &(cTmpAlias)->(IndexOrd())
	EndIf

	RestArea(aAreaAli)
	RestArea(aAreaANT)

Return nTmpIndex

/*/{Protheus.doc} tools
function udpatePeso
Atualiza o peso das chapas conforme o peso informado no cavalete
@author DEV
@since 07/05/2019
@version ALL
/*/
User Function updatePeso(cCavalete)

	Local nPesoCha  := GETNEWPAR("GR_PESOCHA", 0) // Atualiza peso da chapa pela divisão do peso do cavalete.
	Local nB8Bundle := GetNewPar("GR_B8BUNDL", 0) // Transfere  o saldo das chapas criando o bundle na SB8
	Local cSql      := NIL
	Local cQuery    := NIL
	Local nMetroTot := 0
	Local nQuantCh  := 0
	Local nContador := 0
	Local nSaldoBru := 0
	Local nSaldoLiq := 0
	Local nPesoBru  := 0
	Local nPesoLiq  := 0
	Local nUnidBru  := 0
	Local nUnidLiq  := 0
	Local __nRecno  := 0

	//------------------------------------------------------------------------------------
	// O parâmetro GR_PESOCHA foi criado inicialmente para ser boolean,
	// porém foi alterado para numérico para incluir nova opção de cálculo
	// onde 0 = Não calcula, 1 = Calcula por igual, 2 = Calcula proporcional
	//------------------------------------------------------------------------------------
	If ValType(nPesoCha) == "L"
		nPesoCha := if(nPesoCha, 1, 0)
	EndIf

	If nPesoCha == 1 .Or. nPesoCha == 2

		cSql := " SELECT * "
		cSql += "   FROM " + RetSqlName("SB8") + " SB8 "
		cSql += "  WHERE SB8.B8_FILIAL  = '" + xFilial("SB8") + "' "
		cSql += "    AND SB8.B8_YCAVALE = '" + cCavalete + "' "
		cSql += "    AND SB8.B8_ORIGLAN <> 'BD' "
		cSql += "    AND SB8.D_E_L_E_T_ = ' '"

		TCQUERY cSql NEW ALIAS qQUERY

		//------------------------------------------------------------------------------------
		// Caso o calculo seja 2 (proporcional) soma o total em metros de chapa.
		//------------------------------------------------------------------------------------
		If nPesoCha == 2
			qQuery->(DbGoTop())
			While qQUERY->(!Eof())
				nMetroTot += qQuery->B8_YTOTLIQ
				qQuery->(DbSkip())
			EndDo
		EndIf

		If ZG3->(DbSeek(xFilial("ZG3") + cCavalete))

			If ZG3->ZG3_PESOLQ > 0

				nPesoBru  := ZG3->ZG3_PESOBR
				nPesoLiq  := ZG3->ZG3_PESOLQ
				nQuantCh  := ZG3->ZG3_QCHAPA

				nSaldoBru := nPesoBru
				nSaldoLiq := nPesoLiq

				qQuery->(DbGoTop())
				While qQUERY->(!Eof())

					// If SB8->(DbGoTo(qQUERY->R_E_C_N_O_))

					SB8->(DbGoTo(qQUERY->R_E_C_N_O_))

					RecLock("SB8", .F.)

					If nPesoCha == 1 // 1 = Calcula por igual
						nContador++
						If nContador == nQuantCh
							SB8->B8_YPESOBR := nSaldoBru
							SB8->B8_YPESOLQ := nSaldoLiq
						Else
							nSaldoBru -= Round(nPesoBru / nQuantCh, TamSx3("B8_YPESOBR")[2])
							nSaldoLiq -= Round(nPesoLiq / nQuantCh, TamSx3("B8_YPESOLQ")[2])
							SB8->B8_YPESOBR := Round(nPesoBru / nQuantCh, TamSx3("B8_YPESOBR")[2])
							SB8->B8_YPESOLQ := Round(nPesoLiq / nQuantCh, TamSx3("B8_YPESOLQ")[2])
						EndIf
					ElseIf nPesoCha == 2 // 1 = Calcula proporcional
						nContador++
						If nContador == nQuantCh
							SB8->B8_YPESOBR := nSaldoBru
							SB8->B8_YPESOLQ := nSaldoLiq
						Else
							nUnidBru := nPesoBru / nMetroTot
							nUnidLiq := nPesoLiq / nMetroTot
							nSaldoBru -= Round(nUnidBru * SB8->B8_YTOTLIQ, TamSx3("B8_YPESOBR")[2])
							nSaldoLiq -= Round(nUnidLiq * SB8->B8_YTOTLIQ, TamSx3("B8_YPESOLQ")[2])
							SB8->B8_YPESOBR := Round(nUnidBru * SB8->B8_YTOTLIQ, TamSx3("B8_YPESOBR")[2])
							SB8->B8_YPESOLQ := Round(nUnidLiq * SB8->B8_YTOTLIQ, TamSx3("B8_YPESOLQ")[2])
						EndIf
					EndIf

					SB8->(MsUnLock())

					// EndIf

					qQUERY->(DbSkip())
				EndDo

			Else

				nPesoBru  := 0
				nPesoLiq  := 0
				nQuantCh  := 0

				qQuery->(DbGoTop())
				While qQUERY->(!Eof())

					// If SB8->(DbGoTo(qQUERY->R_E_C_N_O_))

					SB8->(DbGoTo(qQUERY->R_E_C_N_O_))

					nPesoBru += SB8->B8_YPESOBR
					nPesoLiq += SB8->B8_YPESOLQ
					nQuantCh++

					// EndIf

					qQUERY->(DbSkip())
				EndDo

				RecLock("ZG3", .F.)
				ZG3->ZG3_PESOBR := nPesoBru
				ZG3->ZG3_PESOLQ := nPesoLiq
				ZG3->ZG3_QCHAPA := nQuantCh
				ZG3->(MsUnLock())

			EndIf

		EndIf

		qQUERY->(DbCloseArea())

	EndIf

Return Nil

/*/{Protheus.doc} tools
function updateBundle
Atualiza o peso dos bundles na SB8
@author DEV
@since 07/05/2019
@version ALL
/*/
User Function updateBundle(cCavalete)

	Local nB8Bundle := GetNewPar("GR_B8BUNDL", 0) // Transfere  o saldo das chapas criando o bundle na SB8
	Local cSql      := NIL
	Local cQuery    := NIL

	If nB8Bundle > 0

		cSql := "   SELECT COUNT(B8_FILIAL) B8_FILIAL, "
		cSql += "          B8_PRODUTO, "
		cSql += "          B8_LOCAL, "
		cSql += "          B8_YNUMBD, "
		cSql += "          B8_YSEQBD, "
		cSql += "          SUM(B8_YPESOBR) B8_YPESOBR, "
		cSql += "          SUM(B8_YPESOLQ) B8_YPESOLQ "
		cSql += "     FROM " + RetSqlName("SB8") + " SB8 "
		cSql += "    WHERE SB8.B8_FILIAL  = '" + xFilial("SB8") + "' "
		cSql += "      AND SB8.B8_YCAVALE = '" + cCavalete + "' "
		cSql += "      AND SB8.B8_ORIGLAN <> 'BD' "
		cSql += "      AND SB8.D_E_L_E_T_ = ' '"
		cSql += " GROUP BY B8_PRODUTO, "
		cSql += "          B8_LOCAL, "
		cSql += "          B8_YNUMBD, "
		cSql += "          B8_YSEQBD "

		TCQUERY cSql NEW ALIAS qQUERY

		While qQUERY->(!Eof())

			SB8->(DbSetOrder(3))

			If SB8->(DbSeek(xFilial("SB8") + qQUERY->(B8_PRODUTO + B8_LOCAL + B8_YNUMBD + B8_YSEQBD)))

				RecLock("SB8", .F.)
				SB8->B8_YQTDBD  := qQUERY->B8_FILIAL
				SB8->B8_YPESOBR := qQUERY->B8_YPESOBR
				SB8->B8_YPESOLQ := qQUERY->B8_YPESOLQ
				SB8->(MsUnLock())

			EndIf

			qQUERY->(DbSkip())

		EndDo

		qQUERY->(DbCloseArea())

	EndIf

RETURN NIL

/*/{Protheus.doc} ArrTrfBd
function ArrTrfBd
Retorna array formatado para transferência de bundle.
@author DEV
@since 07/05/2019
@version ALL
/*/
User Function ArrTrfBd(cCavalete, cPkChapa, lMonta)

	Local aRet      := {}
	Local aLinha    := {}
	Local aAreaSB8  := SB8->(GetArea())
	Local nB8Bundle := GetNewPar("GR_B8BUNDL", 0) // Transfere  o saldo das chapas criando o bundle na SB8
	Local cLoteOri  := ""
	Local cLoteDes  := ""
	Local cSubLOri  := ""
	Local cSubLDes  := ""
	Local nQuant    := 0

	Default cCavalete := ""
	Default cPkChapa  := ""
	Default lMonta    := Nil

	SB8->(DbSetOrder(3))
	If SB8->(DbSeek(cPkChapa)) .And. !Empty(cCavalete)

		If lMonta
			nQuant   := SB8->B8_SALDO
			cLoteOri := SB8->B8_LOTECTL
			cSubLOri := SB8->B8_NUMLOTE
			cLoteDes := If(nB8Bundle == 1, "BUND" + cCavalete, AllTrim(SB8->B8_LOTECTL) + Posicione("ZG4", 1, xFilial("ZG4") + SB8->B8_YCLASSI, "ZG4_AGRUPA"))
			cSubLDes := If(nB8Bundle == 1, "CLA" + AllTrim(Posicione("ZG4", 1, xFilial("ZG4") + SB8->B8_YCLASSI, "ZG4_AGRUPA")), cCavalete)

			RecLock("SB8", .F.)
			SB8->B8_YNUMBD  := cLoteDes
			SB8->B8_YSEQBD  := cSubLDes
			SB8->B8_YQTDBD  := SB8->B8_SALDO
			SB8->(MsUnLock())
		Else
			nQuant   := SB8->B8_YQTDBD
			cLoteOri := SB8->B8_YNUMBD
			cSubLOri := SB8->B8_YSEQBD
			cLoteDes := SB8->B8_LOTECTL
			cSubLDes := SB8->B8_NUMLOTE

			RecLock("SB8", .F.)
			SB8->B8_YNUMBD  := ""
			SB8->B8_YSEQBD  := ""
			SB8->B8_YQTDBD  := 0
			SB8->(MsUnLock())
		EndIf

		aAdd(aLinha, SB8->B8_PRODUTO)
		aAdd(aLinha, SB8->B8_LOCAL)
		aAdd(aLinha, nQuant)
		aAdd(aLinha, dDataBase)
		aAdd(aLinha, nQuant)
		aAdd(aLinha, cSubLOri)
		aAdd(aLinha, cLoteOri)
		aAdd(aLinha, SB8->B8_DTVALID)
		aAdd(aLinha, SB8->B8_PRODUTO)
		aAdd(aLinha, SB8->B8_LOCAL)
		aAdd(aLinha, cLoteDes)
		aAdd(aLinha, cSubLDes)
		aAdd(aLinha, lMonta)
		aAdd(aLinha, SB8->B8_YPESOLQ)
		aAdd(aLinha, SB8->B8_YPESOBR)
		aAdd(aLinha, SB8->B8_YCLASSI)
		aAdd(aLinha, SB8->B8_YCLAPRO)
		aAdd(aLinha, SB8->B8_YENDERE)
		aAdd(aLinha, SB8->B8_YCOMLIQ)
		aAdd(aLinha, SB8->B8_YALTLIQ)
		aAdd(aLinha, SB8->B8_YESPLIQ)
		aAdd(aLinha, SB8->B8_YTOTLIQ)
		aAdd(aLinha, SB8->B8_YCOMBRU)
		aAdd(aLinha, SB8->B8_YALTBRU)
		aAdd(aLinha, SB8->B8_YESPBRU)
		aAdd(aLinha, SB8->B8_YTOTBRU)
		aAdd(aLinha, cCavalete)

		aRet := aLinha

	EndIf

	RestArea(aAreaSB8)

Return aRet

/*/{Protheus.doc} TransfBd
function TransfBd
Atualiza o peso das chapas conforme o peso informado no cavalete
@author DEV
@since 07/05/2019
@version ALL
/*/
User Function TransfBd(aParam)

	Local lRet       := .F.
	Local cCodOrig   := nil
	Local cLocOrig   := nil
	Local nQuant260  := nil
	Local dEmis260   := nil
	Local nQuant260D := nil
	Local cNumLote   := nil
	Local cLoteDigi  := nil
	Local dDtValid   := nil
	Local cCodDest   := nil
	Local cLocDest   := nil
	Local cLoteDest  := nil
	Local lMontaBD   := nil
	Local nPesoLq    := nil
	Local nPesoBr    := nil
	Local cClassi    := nil
	Local cClaPro    := nil
	Local cEndere    := nil
	Local nComLiq    := nil
	Local nAltLiq    := nil
	Local nEspLiq    := nil
	Local nTotLiq    := nil
	Local nComBru    := nil
	Local nAltBru    := nil
	Local nEspBru    := nil
	Local nTotBru    := nil
	Local cCavale    := nil
	Local cAlias	 := GetNextAlias()

	Local aAuto      := {}
	Local aLinha     := {}
	Local nX         := {}
	Local cSequen    := "000"
	Local cTMEntrada := SubStr(GetNewPar("GR_B8BDTM", "499/999"), 1, 3)
	Local cTMSaida   := SubStr(GetNewPar("GR_B8BDTM", "499/999"), 5, 3)
	Local nB8Bundle  := GetNewPar("GR_B8BUNDL", 0) // Transfere  o saldo das chapas criando o bundle na SB8
	Local aDesmBD    := {}
	Local nPos       := 0
	Local qQueryGR   := ""
	Local cNumSeq    := ""
	Local cDocSD3    := ""
	Local aValDtSD5  := ""


	Private lMsErroAuto := .F.
	Private __cSubDest  := ""
	Private __cSublote  := ""

	If Len(aParam) == 0
		ConOut("GrPlus => Montagem/Desmontagem de Bundle sem alteracao!")
		Return .T.
	EndIf

	For nX := 1 To Len(aParam)

		lMontaBD   := aParam[nX][13]

		cCodOrig   := PadR(aParam[nX][1],  TamSx3('D3_COD')[1])
		cLocOrig   := PadR(aParam[nX][2],  TamSx3('D3_LOCAL')[1])
		nQuant260  := aParam[nX][3]
		dEmis260   := aParam[nX][4]
		nQuant260D := aParam[nX][5]
		cNumLote   := PadR(aParam[nX][6],  TamSx3('D3_NUMLOTE')[1])
		cLoteDigi  := PadR(aParam[nX][7],  TamSx3('D3_LOTECTL')[1])
		dDtValid   := aParam[nX][8]
		cCodDest   := PadR(aParam[nX][9],  TamSx3('D3_COD')[1])
		cLocDest   := PadR(aParam[nX][10], TamSx3('D3_LOCAL')[1])
		cLoteDest  := PadR(aParam[nX][11], TamSx3('D3_LOTECTL')[1])
		__cSubDest := PadR(aParam[nX][12], TamSx3('D3_NUMLOTE')[1])

		If lMontaBD
			SB8->(DbSetOrder(3))
			If SB8->(DbSeek(xFilial('SB8') + cCodOrig + cLocOrig + cLoteDigi + cNumLote))
				nPesoLq := SB8->B8_YPESOLQ
				nPesoBr := SB8->B8_YPESOBR
			EndIf
		Else
			SB8->(DbSetOrder(3))
			If SB8->(DbSeek(xFilial('SB8') + cCodDest + cLocDest + cLoteDest + __cSubDest))
				nPesoLq := SB8->B8_YPESOLQ
				nPesoBr := SB8->B8_YPESOBR
			EndIf
		EndIf

		// nPesoLq    := aParam[nX][14]
		// nPesoBr    := aParam[nX][15]
		cClassi    := aParam[nX][16]
		cClaPro    := aParam[nX][17]
		cEndere    := aParam[nX][18]
		nComLiq    := aParam[nX][19]
		nAltLiq    := aParam[nX][20]
		nEspLiq    := aParam[nX][21]
		nTotLiq    := aParam[nX][22]
		nComBru    := aParam[nX][23]
		nAltBru    := aParam[nX][24]
		nEspBru    := aParam[nX][25]
		nTotBru    := aParam[nX][26]
		cCavale    := aParam[nX][27]

		// Necessário para ativar o ponto de entrada XPROXLOT
		__cSublote := cNumLote

		SB1->(DbSetOrder(1))
		SB1->(DbSeek(xFilial("SB1") + PadR(cCodOrig, TamSx3('D3_COD')[1])))

		IF nB8Bundle == 2

			if !lMontaBD

				aValDtSD5 := U_VALDTSD5(cCodOrig,cLocOrig,cLoteDigi,__cSubDest,cNumLote)

				If !aValDtSD5[1]
					U_HELPMSG(aValDtSD5[3],aValDtSD5[2])
					Return .f.
				EndIF

			EndIF

		EndIf

		//----------------------------------------------------
		// Movimento de saída do estoque.
		//----------------------------------------------------
		aLinha := {}

		aAdd(aLinha, {"D3_TM",      cTmSaida,   Nil})
		aAdd(aLinha, {"D3_COD",     cCodOrig,   Nil})
		aAdd(aLinha, {"D3_UM",      SB1->B1_UM, Nil})
		aAdd(aLinha, {"D3_LOCAL",   cLocOrig,   Nil})
		aAdd(aLinha, {"D3_LOTECTL", cLoteDigi,  Nil})
		aAdd(aLinha, {"D3_NUMLOTE", cNumLote,   Nil})
		aAdd(aLinha, {"D3_QUANT",   nQuant260,  Nil})
		aAdd(aLinha, {"D3_EMISSAO", dEmis260,   Nil})
		aAdd(aLinha, {"D3_YORIGE"  , funname(), Nil})

		MSExecAuto({|x,y| mata240(x,y)}, aLinha, 3)

		If lMsErroAuto

			If (IsBlind())
				ConOut("GrPlus Error => " + MostraErro("/error", "error.log"))
				Return .F.
			Else
				MostraErro()
				Return .F.
			EndIf

		Else
			If lMontaBD
				ConOut("GrPlus => Montagem de Bundle concluido com sucesso!")
			Else

				SB8->(DbSetOrder(3))
				If SB8->(DbSeek(xFilial("SB8") + cCodOrig + cLocOrig + cLoteDigi + cNumLote))
					RecLock("SB8", .F.)
					SB8->B8_YPESOLQ := If(SB8->B8_YPESOLQ <= 0, 0, SB8->B8_YPESOLQ - nPesoLq)
					SB8->B8_YPESOBR := If(SB8->B8_YPESOBR <= 0, 0, SB8->B8_YPESOBR - nPesoBr)
					SB8->B8_YQTDBD  := If(SB8->B8_YPESOBR <= 0, 0, SB8->B8_YQTDBD  - 1)
					SB8->(MsUnLock())
				EndIf

				If nB8Bundle == 2
					//Caso retire a chapa do BD o sistema precisa validar se os dados ficaram corretos.
					SB8->(DbSetOrder(3))
					If SB8->(DbSeek(xFilial("SB8") + cCodOrig + cLocOrig + cLoteDigi + cNumLote))
						nPos:=  aScan(aDesmBD, {|x| x == xFilial("SB8") + cCodOrig + cLocOrig + cLoteDigi + cNumLote})
						If nPos == 0
							Aadd(aDesmBD,xFilial("SB8") + cCodOrig + cLocOrig + cLoteDigi + cNumLote)
						EndIf
					EndIf
				EndIF

				ConOut("GrPlus => Desmontagem de Bundle concluido com sucesso!")
			EndIf

			cNumSeq := SD3->D3_NUMSEQ
			cDocSD3 := SD3->D3_DOC

			RecLock("SD3", .F.)
			SD3->D3_TM    := "999"
			SD3->D3_CF    := "RE4"
			SD3->D3_CHAVE := "E0"
			SD3->(MsUnLock())

			//Origem
			SB1->(DbSeek(xFilial("SB1") + PadR(cCodOrig, TamSx3('D3_COD')[1])))

			//----------------------------------------------------
			// Movimento de entrada do estoque.
			//----------------------------------------------------
			aLinha := {}

			aAdd(aLinha, {"D3_TM",      cTmEntrada, Nil})
			aAdd(aLinha, {"D3_COD",     cCodOrig,   Nil})
			aAdd(aLinha, {"D3_UM",      SB1->B1_UM, Nil})
			aAdd(aLinha, {"D3_LOCAL",   cLocDest,   Nil})
			aAdd(aLinha, {"D3_LOTECTL", cLoteDest,  Nil})
			aAdd(aLinha, {"D3_NUMLOTE", __cSubDest, Nil})
			aAdd(aLinha, {"D3_QUANT",   nQuant260,  Nil})
			aAdd(aLinha, {"D3_EMISSAO", dEmis260,   Nil})

			If lMontaBd
				// Alimenta BUNDLE
				aAdd(aLinha, {"D3_YCLASSI", cClassi, Nil})
				aAdd(aLinha, {"D3_YCAVALE", cCavale, Nil})
			Else
				// Alimenta CHAPA
				aAdd(aLinha, {"D3_YCLASSI", cClassi, Nil})
				aAdd(aLinha, {"D3_YCLAPRO", cClaPro, Nil})
				aAdd(aLinha, {"D3_YENDERE", cEndere, Nil})
				aAdd(aLinha, {"D3_YCOMLIQ", nComLiq, Nil})
				aAdd(aLinha, {"D3_YALTLIQ", nAltLiq, Nil})
				aAdd(aLinha, {"D3_YESPLIQ", nEspLiq, Nil})
				aAdd(aLinha, {"D3_YTOTLIQ", nTotLiq, Nil})
				aAdd(aLinha, {"D3_YCOMBRU", nComBru, Nil})
				aAdd(aLinha, {"D3_YALTBRU", nAltBru, Nil})
				aAdd(aLinha, {"D3_YESPBRU", nEspBru, Nil})
				aAdd(aLinha, {"D3_YTOTBRU", nTotBru, Nil})
			EndIf

			SB8->(DbSetOrder(3))
			If SB8->(DbSeek(xFilial('SB8') + cCodOrig + cLocDest + cLoteDest + __cSubDest))
				// If SB8->B8_SALDO > 0
				RecLock("SB8", .F.)
				SB8->B8_QTDORI := SB8->B8_SALDO + nQuant260
				SB8->(MsUnLock())
				// Else
				// 	RecLock("SB8", .F.)
				// 	SB8->(DbDelete())
				// 	SB8->(MsUnLock())
				// EndIf
			EndIf

			MSExecAuto({|x,y| mata240(x,y)}, aLinha, 3)

			If lMsErroAuto

				If (IsBlind())
					ConOut("GrPlus Error => " + MostraErro("/error", "error.log"))
					Return .F.
				Else
					MostraErro()
					Return .F.
				EndIf

			Else

				if !ALTD5SEQ(SD3->D3_NUMSEQ,cNumSeq,cDocSD3)
					cMsgErro := "Sistema não encontrou SD5 com D5_NUMSEQ igual " + SD3->D3_NUMSEQ
					MsgStop(cMsgErro)
					Return .F.
				EndIF

				RecLock("SD3", .F.)
				SD3->D3_TM    := "499"
				SD3->D3_CF    := "DE4"
				SD3->D3_CHAVE := "E9"
				SD3->D3_OBSERVA :=  SD3->D3_NUMSEQ +"-"+ SD3->D3_DOC
				SD3->D3_NUMSEQ	:= cNumSeq
				SD3->D3_DOC     := cDocSD3
				SD3->(MsUnLock())

				If lMontaBD

					SB8->(DbSetOrder(3))
					If SB8->(DbSeek(xFilial("SB8") + cCodOrig + cLocDest + cLoteDest + __cSubDest))
						RecLock("SB8", .F.)
						SB8->B8_ORIGLAN := "BD"
						SB8->B8_YCAVALE := cCavale
						SB8->B8_YCLASSI := cClassi
						SB8->B8_YPESOLQ += nPesoLq
						SB8->B8_YPESOBR += nPesoBr
						SB8->B8_YQTDBD++
						SB8->(MsUnLock())

						//-----------------------------------------------------------
						// Ponto de entrada para alterar alguma informação da SB8.
						//-----------------------------------------------------------
						If ExistBlock("GTRBDSB8")
							ExecBlock("GTRBDSB8", .F., .F., {})
						EndIf

					EndIf

					ConOut("GrPlus => Montagem de Bundle concluido com sucesso!")
				Else
					ConOut("GrPlus => Desmontagem de Bundle concluido com sucesso!")
				EndIf

			EndIf

			lRet := .T.
		EndIf

	Next

	cSql := "   SELECT COUNT(B8_FILIAL) B8_FILIAL,  "
	cSql += "          B8_PRODUTO, "
	cSql += "          B8_LOCAL,   "
	cSql += "          B8_YNUMBD,  "
	cSql += "          B8_YSEQBD,  "
	cSql += "          SUM(B8_YPESOBR) B8_YPESOBR, "
	cSql += "          SUM(B8_YPESOLQ) B8_YPESOLQ "
	cSql += "     FROM " + RetSqlName("SB8") + " SB8 "
	cSql += "    WHERE SB8.B8_FILIAL  = '" + xFilial("SB8") + "' "
	cSql += "      AND SB8.B8_YCAVALE = '" + cCavale + "' "
	cSql += "      AND SB8.B8_ORIGLAN <> 'BD' "
	cSql += "      AND SB8.D_E_L_E_T_ = ' '"
	cSql += " GROUP BY B8_FILIAL,  "
	cSql += "          B8_PRODUTO, "
	cSql += "          B8_LOCAL,   "
	cSql += "          B8_YNUMBD,  "
	cSql += "          B8_YSEQBD   "

	TCQUERY cSql NEW ALIAS qQueryGR

	While qQueryGR->(!Eof())

		SB8->(DbSetOrder(3))

		If SB8->(DbSeek(xFilial("SB8") + qQueryGR->(B8_PRODUTO + B8_LOCAL + B8_YNUMBD + B8_YSEQBD)))

			RecLock("SB8", .F.)
			SB8->B8_YQTDBD  := qQueryGR->B8_FILIAL
			SB8->B8_YPESOLQ := qQueryGR->B8_YPESOLQ
			SB8->B8_YPESOBR := qQueryGR->B8_YPESOBR
			SB8->(MsUnLock())

			If nB8Bundle == 2
				//Valida se o cavalete esta com os valores nas tabelas SB8 e ZPB.
				lCavValid := u_VALIDCAV(SB8->B8_PRODUTO, SB8->B8_LOCAL, cCavale, SB8->B8_LOTECTL, SB8->B8_NUMLOTE, SB8->B8_SALDO, 0,SB8->B8_YCLASSI)
				if !lCavValid[1]
					cMsgErro := lCavValid[2]
					qQueryGR->(DbCloseArea())
					MsgStop(cMsgErro)
					Return .F.
				endif
			EndIf

		EndIf

		qQueryGR->(DbSkip())

	EndDo

	qQueryGR->(DbCloseArea())

	//Realizando validação caso o usuário retire chapas do BD. Foi necessário incluir no final da operação porque o sistema retira primeiro os vinculos com a SB8 e depois retira o saldo do cavalete
	for nX := 1 to len(aDesmBD)
		SB8->(DbSetOrder(3))
		If SB8->(DbSeek(aDesmBD[nX]))
			lCavValid := u_VALIDCAV(SB8->B8_PRODUTO, SB8->B8_LOCAL, SB8->B8_YCAVALE, SB8->B8_LOTECTL, SB8->B8_NUMLOTE, SB8->B8_SALDO, 0,SB8->B8_YCLASSI)
			if !lCavValid[1]
				cMsgErro := lCavValid[2]
				MsgStop(cMsgErro)
				Return .F.
			endif
		EndIF
	next


Return lRet

/*/{Protheus.doc} ValidUM
Validação da Unidade de Medida
@type  Function
@author Totvs Vitoria
@since 08/08/2019
@version version
@param param, param_type, param_descr
@return return, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
USER Function ValidUM(oModel,cID,cCampoProd,cCampoUM)

	Local aAreaSB1 := SB1->(GetArea())
	Local cCodProd := oModel:GetValue( cID, cCampoProd)
	Local cUM 	   := oModel:GetValue( cID, cCampoUM)
	Local lExist   := .F.
	Local cMsg	   := ""
	Local cSolu	   := ""

	SB1->(DbSetOrder(1))

	If SB1->(DbSeek(FwXFilial("SB1") + cCodProd ))

		If Alltrim(SB1->B1_UM) ==  AllTrim(cUM) .or.  Alltrim(SB1->B1_SEGUM) == AllTrim(cUM)
			lExist := .T.
		Else

			cMsg  := "Esta unidade de medida informada não é valida para este produto selecionado"

			cSolu := "Favor utilizar uma das unidades abaixo: " + Chr(13) + Chr(10) + Chr(13) + Chr(10) ;
				+ "B1_UM (" + SB1->B1_UM + ") " +  Chr(13) + Chr(10) ;
				+ "B1_SEGUM (" + SB1->B1_SEGUM + ")"

			Help(NIL, NIL, "GROA045 - ValidUM", NIL, cMsg ,1, 0, NIL, NIL, NIL, NIL, NIL, {cSolu})
			lExist := .F.
		EndIf

	End If

	RestArea(aAreaSB1)

Return lExist

/*/{Protheus.doc} LoadZH7
Popula tabelas ZH7, ZH8 e ZH9 com base na tabela SC2.
@type Static Function
@author Totvs Vitoria
@since 08/08/2019
@version version
/*/
user Function LoadZH7(cNumOp)

	Local cSql    := NIL
	Local qQUERY  := NIL
	Local qITEM   := NIL
	Local qSEQUEN := NIL
	Local cCondic := NIL

	Default cNumOp := ""

	cCondic := If(Empty(cNumOp), "", " AND SC2.C2_NUM = '" + cNumOp + "' ")

	cSql := U_SQLOPS( cCondic , .T. )

	ZH7->(DbSetOrder(1))
	ZH8->(DbSetOrder(1))
	ZH9->(DbSetOrder(1))

	TCQUERY cSql NEW ALIAS qQUERY

	While (qQUERY->(!Eof()))

		If ZH7->(!DbSeek(xFilial("ZH7") + qQUERY->C2_NUM))

			RecLock("ZH7", .T.)
			ZH7->ZH7_FILIAL := xFilial("ZH7")
			ZH7->ZH7_NUM    := qQUERY->C2_NUM
			ZH7->ZH7_PROCES := qQUERY->C2_YTIPO
			ZH7->ZH7_TIPOOP := qQUERY->C2_TPOP
			ZH7->ZH7_EMISSA := StoD(qQUERY->C2_EMISSAO)
			ZH7->ZH7_DATPRI := StoD(qQUERY->C2_DATPRI)
			ZH7->ZH7_DATPRF := StoD(qQUERY->C2_DATPRF)
			ZH7->ZH7_HRPRI  := If(Empty(Posicione("SX3", 2, "ZH7_HRPRI", "X3_RELACAO")), "0000", AllTrim(StrTran(Posicione("SX3", 2, "ZH7_HRPRI", "X3_RELACAO"), '"', "")))
			ZH7->ZH7_HRPRF  := If(Empty(Posicione("SX3", 2, "ZH7_HRPRF", "X3_RELACAO")), "0000", AllTrim(StrTran(Posicione("SX3", 2, "ZH7_HRPRF", "X3_RELACAO"), '"', "")))
			ZH7->ZH7_FRENTE := qQUERY->C2_YFRENTE
			ZH7->ZH7_DESCFR := qQUERY->ZG2_DESCRI
			ZH7->ZH7_RECURS := qQUERY->C2_YTEAR
			ZH7->ZH7_DESCRE := qQUERY->H1_DESCRI
			ZH7->ZH7_ENGENH := qQUERY->C2_YENGENH
			ZH7->ZH7_DESCEN := qQUERY->ZG7_DESCRI
			ZH7->ZH7_BLOCO  := qQUERY->D4_LOTECTL
			ZH7->ZH7_SITUAC := qQUERY->C2_YSITUAC
			ZH7->ZH7_COECOR := qQUERY->C2_YCOECOR
			ZH7->ZH7_CODMOT := qQUERY->C2_YCODMOT
			ZH7->ZH7_DESMOT := qQUERY->ZH6_DESCRI
			ZH7->(MsUnLock())

			If ExistBlock("GRLODZH7")
				ExecBlock("GRLODZH7", .f., .f.,{} )
			EndIf

		EndIf

		cSql := "     SELECT C2_NUM,     C2_ITEM,    C2_YENGENH, "
		cSql += "            C2_YLOCMP,  ZG2_DESCRI, ZG7_DESCRI, "
		cSql += "            C2_YMP,     C2_YLOTECT, C2_YNUMLOT, C2_YUMMP, "
		cSql += "            C2_YCOMMP,  C2_YALTMP,  C2_YESPMP,  C2_YTOTMP "

		cSql += "       FROM " + RetSqlName("SC2") + " SC2 "

		cSql += "  LEFT JOIN " + RetSqlName("ZG2") + " ZG2 "
		cSql += "         ON ZG2.ZG2_FILIAL = '" + xFilial("ZG2") + "' "
		cSql += "        AND ZG2.ZG2_CODIGO = SC2.C2_YFRENTE "
		cSql += "        AND ZG2.D_E_L_E_T_ = ' ' "

		cSql += "  LEFT JOIN " + RetSqlName("ZG7") + " ZG7 "
		cSql += "         ON ZG7.ZG7_FILIAL = '" + xFilial("ZG7") + "' "
		cSql += "        AND ZG7.ZG7_CODIGO = SC2.C2_YENGENH "
		cSql += "        AND ZG7.D_E_L_E_T_ = ' ' "

		cSql += "      WHERE SC2.C2_FILIAL  = '" + xFilial("SC2") + "' "
		cSql += "        AND SC2.C2_NUM     = '" + qQUERY->C2_NUM + "' "
		cSql += "        AND SC2.D_E_L_E_T_ = ' ' "

		cSql += "   GROUP BY C2_NUM,     C2_ITEM,    C2_YENGENH, "
		cSql += "            C2_YLOCMP,  ZG2_DESCRI, ZG7_DESCRI, "
		cSql += "            C2_YMP,     C2_YLOTECT, C2_YNUMLOT, C2_YUMMP, "
		cSql += "            C2_YCOMMP,  C2_YALTMP,  C2_YESPMP,  C2_YTOTMP "

		TCQUERY cSql NEW ALIAS qITEM

		While qITEM->(!Eof())

			If ZH8->(!DbSeek(xFilial("ZH8") + qITEM->C2_NUM + qITEM->C2_ITEM))

				RecLock("ZH8", .T.)
				ZH8->ZH8_FILIAL := xFilial("ZH8")
				ZH8->ZH8_NUM    := qITEM->C2_NUM
				ZH8->ZH8_ITEM   := qITEM->C2_ITEM
				ZH8->ZH8_ENGENH := qITEM->C2_YENGENH
				ZH8->ZH8_CODMAT := qITEM->C2_YMP
				ZH8->ZH8_LOCAL  := qITEM->C2_YLOCMP
				ZH8->ZH8_LOTECT := qITEM->C2_YLOTECT
				ZH8->ZH8_NUMLOT := qITEM->C2_YNUMLOT
				ZH8->ZH8_UM     := qITEM->C2_YUMMP
				ZH8->ZH8_COMLIQ := qITEM->C2_YCOMMP
				ZH8->ZH8_ALTLIQ := qITEM->C2_YALTMP
				ZH8->ZH8_ESPLIQ := qITEM->C2_YESPMP
				ZH8->ZH8_TOTLIQ := qITEM->C2_YTOTMP
				ZH8->ZH8_COMBRU := qITEM->C2_YCOMMP
				ZH8->ZH8_ALTBRU := qITEM->C2_YALTMP
				ZH8->ZH8_ESPBRU := qITEM->C2_YESPMP
				ZH8->ZH8_TOTBRU := qITEM->C2_YTOTMP
				ZH8->ZH8_DESCMT := qITEM->ZG2_DESCRI
				ZH8->ZH8_DESCEN := qITEM->ZG7_DESCRI
				ZH8->(MsUnLock())

			EndIf

			cSql := "     SELECT C2_NUM,     C2_ITEM,    C2_SEQUEN,  C2_YENGENH, "
			cSql += "            C2_YMP,     C2_YLOTECT, C2_YNUMLOT, C2_YUMMP,   "
			cSql += "            C2_YCOMLIQ, C2_YALTLIQ, C2_YESPLIQ, C2_YTOTLIQ, "
			cSql += "            C2_YCOMBRU, C2_YALTBRU, C2_YESPBRU, C2_YTOTBRU, "
			cSql += "            C2_YLOCMP,  B1_DESC,    C2_PRODUTO, C2_UM,      "
			cSql += "            C2_YQTDUNI "

			cSql += "       FROM " + RetSqlName("SC2") + " SC2 "

			cSql += "  LEFT JOIN " + RetSqlName("SB1") + " SB1 "
			cSql += "         ON SB1.B1_FILIAL  = '" + xFilial("SB1") + "' "
			cSql += "        AND SB1.B1_COD     = SC2.C2_PRODUTO "
			cSql += "        AND SB1.D_E_L_E_T_ = ' ' "

			cSql += "      WHERE SC2.C2_FILIAL  = '" + xFilial("SC2") + "' "
			cSql += "        AND SC2.C2_NUM     = '" + qITEM->C2_NUM  + "' "
			cSql += "        AND SC2.C2_ITEM    = '" + qITEM->C2_ITEM + "' "
			cSql += "        AND SC2.D_E_L_E_T_ = ' ' "

			cSql += "   GROUP BY C2_NUM,     C2_ITEM,    C2_SEQUEN,  C2_YENGENH, "
			cSql += "            C2_YMP,     C2_YLOTECT, C2_YNUMLOT, C2_YUMMP,   "
			cSql += "            C2_YCOMLIQ, C2_YALTLIQ, C2_YESPLIQ, C2_YTOTLIQ, "
			cSql += "            C2_YCOMBRU, C2_YALTBRU, C2_YESPBRU, C2_YTOTBRU, "
			cSql += "            C2_YLOCMP,  B1_DESC,    C2_PRODUTO, C2_UM,      "
			cSql += "            C2_YQTDUNI "

			TCQUERY cSql NEW ALIAS qSEQUEN

			While qSEQUEN->(!Eof())

				If ZH9->(!DbSeek(xFilial("ZH9") + qSEQUEN->C2_NUM + qSEQUEN->C2_ITEM + qSEQUEN->C2_SEQUEN))

					RecLock("ZH9", .T.)
					ZH9->ZH9_FILIAL := xFilial("ZH9")
					ZH9->ZH9_NUM    := qSEQUEN->C2_NUM
					ZH9->ZH9_ITEM   := qSEQUEN->C2_ITEM
					ZH9->ZH9_SEQUEN := qSEQUEN->C2_SEQUEN
					ZH9->ZH9_ENGENH := qSEQUEN->C2_YENGENH
					ZH9->ZH9_CODMAT := qSEQUEN->C2_YMP
					ZH9->ZH9_LOCAL  := qSEQUEN->C2_YLOCMP
					ZH9->ZH9_LOTECT := qSEQUEN->C2_YLOTECT
					ZH9->ZH9_NUMLOT := qSEQUEN->C2_YNUMLOT
					ZH9->ZH9_CODPA  := qSEQUEN->C2_PRODUTO
					ZH9->ZH9_DESCPA := qSEQUEN->B1_DESC
					ZH9->ZH9_UM     := qSEQUEN->C2_UM
					ZH9->ZH9_QUANTI := qSEQUEN->C2_YQTDUNI
					ZH9->ZH9_COMLIQ := qSEQUEN->C2_YCOMLIQ
					ZH9->ZH9_ALTLIQ := qSEQUEN->C2_YALTLIQ
					ZH9->ZH9_ESPLIQ := qSEQUEN->C2_YESPLIQ
					ZH9->ZH9_TOTLIQ := qSEQUEN->C2_YTOTLIQ
					ZH9->ZH9_COMBRU := qSEQUEN->C2_YCOMBRU
					ZH9->ZH9_ALTBRU := qSEQUEN->C2_YALTBRU
					ZH9->ZH9_ESPBRU := qSEQUEN->C2_YESPBRU
					ZH9->ZH9_TOTBRU := qSEQUEN->C2_YTOTBRU
					ZH9->(MsUnLock())

				EndIf

				qSEQUEN->(DbSkip())

			EndDo

			qSEQUEN->(DbCloseArea())

			qITEM->(DbSkip())

		EndDo

		qITEM->(DbCloseArea())

		qQUERY->(DbSkip())

	EndDo

	qQUERY->(DbCloseArea())

Return Nil

/*/{Protheus.doc} GetErro
Retorna erro log.
@type Static Function
@author Totvs Vitoria
@since 08/08/2019
@version version
/*/
User Function GETERROR(lAll)

	Local aError := {}
	Local cError := ""
	Local nX     := 0

	Default lAll := .F.

	aError := GetAutoGRLog()

	For nX := 1 To Len(aError)
		If lAll
			cError += aError[nX] + chr(10)
		Else
			If SubString(aError[nX], 1, 10) == "----------"
				cError += SubString(aError[nX], 1, 56) + chr(10)
			Else
				cError += aError[nX] + chr(10)
			EndIf
		EndIf
	Next

	ConOut(cError + AllTrim(DtoC(Date())) + " " + AllTrim(Time()) + ".")

return cError

/*/{Protheus.doc} GERANFC
Gera nota fiscal complementar.
@type Static Function
@author Totvs Vitoria
@since 10/12/2019
@version version
/*/
User Function GERANFC(cNumPed)

	Local cSql        := ""
	Local qQuery      := ""
	Local qQueSD2     := ""
	Local cItem       := "00"
	Local aCabec      := {}
	Local aItens      := {}
	Local lProcTaxa   := .T.
	Local dDataTaxa   := dDataBase
	Local cMsgTaxa    := "Taxa do Dia"
	Local nTaxaNew    := 0
	Local nTaxaOld    := 0
	Local cNotaComp   := ""
	Local cMsgErro    := ""
	Local cMsgNFco    := ""
	Local cMsgSucesso := ""
	Local cTesAux 	  := GETNEWPAR("GR_NFECTES", "")  // Tes utilizada na Nfe complementar.
	Local lTesNota 	  := GETNEWPAR("GR_CTESNFE",.F.)  // Tes utilizada na Nfe complementar.
	Local cFormula 	  := GETNEWPAR("GR_NFECFOR", "")  // Fórmula para mensagem padrão utilizada na Nfe complementar.
	Local lTaxaDia 	  := GETNEWPAR("GR_TAXADIA",.F.)
	Local nValPeTot   := 0
	Local aErro 	  := {}
	Local nW 		  := 0
	Local lBlqCrd     := .F.
	Local lBlqEst     := .F.
	Local cNumDoc     := ""
	Local cSerie      := ""
	Local cClient     := ""
	Local cLoja       := ""
	Local cTesComp	  := ""
	Local cOperac 	  := ""
	Local aTesAux	  := {}

	Private lMsErroAuto	   := .F.
	Private lMsHelpAuto	   := .T.
	Private lAutoErrNoFile := .F. //.T. Variavel deixa o MOSTRAERRO() em branco e preenche a função GetAutoGrLog() https://totvsleste.freshdesk.com/a/tickets/1703
	Private lGrPlus        := .T.

	//Se for automatico não possui MOSTRAERRO()
	If (IsBlind())
		lAutoErrNoFile := .T.
	EndIf

	aTesAux :=  STRTOKARR(cTesAux, ",")

	if len(aTesAux) == 1
		cTesComp    := cTesAux
	ElseIf len(aTesAux) > 1
		cTesComp    := aTesAux[1]
		cOperac 	:= aTesAux[2]
	EndIf


	//---------------------------------------------
	// Pegar as notas fiscais geradas para esse pedido.
	//---------------------------------------------
	cSql := "  SELECT "
	cSql += "      D2_DOC, D2_SERIE, D2_CLIENTE, D2_LOJA "
	cSql += "        FROM " + RetSqlName("SD2") + " SD2 "
	cSql += "       WHERE SD2.D2_FILIAL  = '" + xFilial("SD2") + "' "
	cSql += "         AND SD2.D2_PEDIDO  = '" + cNumPed + "' "
	cSql += "         AND SD2.D2_TIPO    = 'N' "
	cSql += "         AND SD2.D_E_L_E_T_ = ' '  "
	cSql += "    GROUP BY D2_DOC,D2_SERIE,D2_CLIENTE,D2_LOJA "

	TCQUERY cSql NEW ALIAS qQueSD2

	While qQueSD2->(!Eof())

		cNumDoc  := qQueSD2->D2_DOC
		cSerie   := qQueSD2->D2_SERIE
		cClient  := qQueSD2->D2_CLIENTE
		cLoja    := qQueSD2->D2_LOJA

		//---------------------------------------------
		// Verifica se já existe nota complementar
		//---------------------------------------------
		cSql := "      SELECT SC6.C6_NUM "
		cSql += "        FROM " + RetSqlName("SC6") + " SC6 "
		cSql += "       WHERE SC6.C6_FILIAL   = '" + xFilial("SC6") + "' "
		cSql += "         AND SC6.C6_NFORI    = '" + cNumDoc 	    + "' "
		cSql += "         AND SC6.C6_SERIORI  = '" + cSerie  		+ "' "
		cSql += "         AND SC6.C6_CLI      = '" + cClient 		+ "' "
		cSql += "         AND SC6.C6_LOJA     = '" + cLoja   		+ "' "
		cSql += "         AND SC6.D_E_L_E_T_  = ' ' "
		cSql += "    GROUP BY SC6.C6_NUM "

		TCQUERY cSql NEW ALIAS qQuery

		cNotaComp := AllTrim(qQuery->C6_NUM)

		qQuery->(DbCloseArea())

		If !Empty(cNotaComp)

			cMsgNFco += "Já existe pedido de venda de complemento número " + cNotaComp + chr(10)

			qQueSD2->(DbSkip())

			loop

		EndIf

		//---------------------------------------------
		// Verifica se houve variação positiva
		//---------------------------------------------
		cSql := "      SELECT * "
		cSql += "        FROM " + RetSqlName("SD2") + " SD2 "
		cSql += "  INNER JOIN " + RetSqlname("SC9") + " SC9 "
		cSql += "          ON SC9.C9_FILIAL   = '" + xFilial("SC9") + "' "
		cSql += "         AND SC9.C9_PEDIDO   = SD2.D2_PEDIDO "
		cSql += "         AND SC9.C9_ITEM     = SD2.D2_ITEMPV "
		cSql += "         AND SC9.C9_NFISCAL  <> ' ' "
		cSql += "         AND SC9.D_E_L_E_T_  = ' ' "
		cSql += "  INNER JOIN " + RetSqlname("SF2") + " SF2   "
		cSql += "          ON SF2.F2_FILIAL   = SD2.D2_FILIAL  "
		cSql += "         AND SF2.F2_DOC      = SD2.D2_DOC     "
		cSql += "         AND SF2.F2_SERIE    = SD2.D2_SERIE   "
		cSql += "         AND SF2.F2_CLIENTE  = SD2.D2_CLIENTE "
		cSql += "         AND SF2.D_E_L_E_T_  = ' ' "
		cSql += "       WHERE SD2.D2_FILIAL   = '" + xFilial("SD2") + "' "
		cSql += "         AND SD2.D2_DOC      = '" + cNumDoc 	    + "' "
		cSql += "         AND SD2.D2_SERIE    = '" + cSerie  		+ "' "
		cSql += "         AND SD2.D2_CLIENTE  = '" + cClient 		+ "' "
		cSql += "         AND SD2.D2_LOJA     = '" + cLoja   		+ "' "
		cSql += "         AND SD2.D2_TIPO    = 'N' "
		cSql += "         AND SD2.D_E_L_E_T_ = ' ' "
		cSql += "    ORDER BY SD2.D2_ITEMPV "

		TCQUERY cSql NEW ALIAS qQuery

		//---------------------------------------------
		// Variáveis do exexauto
		//---------------------------------------------
		cItem  := "00"
		aCabec := {}
		aItens := {}

		While qQuery->(!Eof())

			SC5->(DbSetOrder(1))

			//Posicionar na SC5 porque o sistema perdia o posicionamento quando gera um novo pedido de venda.
			If SC5->(MsSeek(xFilial("SC5") + cNumPed)) .AND. qQuery->D2_TOTAL > 0

				//Reposiciona porque o sistema estava perdendo posicionamento.
				ZGO->(DbSetOrder(1))
				if ZGO->(DbSeek(xFilial("ZGO") + cNumPed))

					nTaxaNew    := 0

					nTaxaOld := qQuery->(F2_VALBRUT / F2_VALFAT)

					if(lTaxaDia)
						dDataTaxa := ZGO->ZGO_DATEMB
						cMsgTaxa  := "Taxa do Dia"
						nTaxaNew := RecMoeda(dDataTaxa, SC5->C5_MOEDA)

						If(nTaxaNew == 0 )
							cMsgTaxa := "Taxa do dia igual a 0 ou inexistente"
						EndIf

					Else

						If ZGO->ZGO_DATEMB == Date()
							dDataTaxa := ZGO->ZGO_DATEMB
							cMsgTaxa  := "Taxa do Dia"
						Else
							dDataTaxa := ZGO->ZGO_DATEMB + 1
							cMsgTaxa  := "Dia + 1"
						EndIf

						While nTaxaNew <= 0
							nTaxaNew := RecMoeda(dDataTaxa, SC5->C5_MOEDA)

							If nTaxaNew <= 0
								dDataTaxa := dDataTaxa - 1
								cMsgTaxa  := "Taxa Anterior"
							EndIf
						EndDo

					EndIf
				EndIF

				//Itens com valor total maior que zero  https://totvsleste.freshdesk.com/a/tickets/1703
				nValPeTot := Round((Round((nTaxaNew * qQuery->C9_PRCVEN * qQuery->D2_QUANT),TamSX3("C6_VALOR")[2]) - (nTaxaOld * qQuery->C9_PRCVEN * qQuery->D2_QUANT)), TamSX3("C6_VALOR")[2])

				If nTaxaNew > nTaxaOld .and. nValPeTot > 0

					aLinha := {}
					cItem := Soma1(cItem)

					//Incluir a mesma tes que foi realizado o faturamento.https://totvsleste.freshdesk.com/a/tickets/2154
					if lTesNota
						cTesComp := qQuery->D2_TES
					EndIF

					aAdd(aLinha, {"C6_ITEM",    cItem, NIL})
					aAdd(aLinha, {"C6_PRODUTO", qQuery->D2_COD, NIL})
					aAdd(aLinha, {"C6_PRCVEN",  nValPeTot, NIL})
					aAdd(aLinha, {"C6_PRUNIT",  nValPeTot, NIL})
					if !empty(cOperac)
						aAdd(aLinha, {"C6_OPER",     cOperac,            nil})
					EndIf
					aAdd(aLinha, {"C6_TES",     cTesComp, NIL})
					aAdd(aLinha, {"C6_NFORI",   qQuery->D2_DOC, NIL})
					aAdd(aLinha, {"C6_SERIORI", qQuery->D2_SERIE, NIL})
					aAdd(aLinha, {"C6_ITEMORI", qQuery->D2_ITEM, NIL})
					aAdd(aLinha, {"C6_YUFEMB",  SC5->C5_YUFEMB,  Nil})
					aAdd(aLinha, {"C6_YLOCEMB", SC5->C5_YLOCEMB, Nil})
					aAdd(aLinha, {"C6_VALOR",   nValPeTot, NIL})

					aAdd(aItens, aLinha)

				EndIf

			EndIf

			qQuery->(DbSkip())

		EndDo

		//incluido o mesmo ponto de entrada para o carregamento, visto que esta realizando a criação da nota de complemento.
		//https://totvsleste.freshdesk.com/a/tickets/1043
		If( ExistBlock("PEGERNFC"))
			aItens := ExecBlock("PEGERNFC", .F., .F., {aItens})
		EndIf

		qQuery->(DbCloseArea())

		If ZGO->(FieldPos("ZGO_TXMOED")) > 0

			RecLock("ZGO", .F.)
			ZGO->ZGO_TXMOLD := nTaxaOld
			ZGO->ZGO_TXMNEW := nTaxaNew
			ZGO->ZGO_DTMOED := dDataTaxa
			ZGO->ZGO_MSMOED := cMsgTaxa
			ZGO->(MsUnLock())

		EndIf

		If Len(aItens)

			aAdd(aCabec, {"C5_CLIENTE", SC5->C5_CLIENTE, Nil})
			aAdd(aCabec, {"C5_LOJACLI", SC5->C5_LOJACLI, Nil})
			aAdd(aCabec, {"C5_EMISSAO", ZGO->ZGO_DATEMB, Nil})
			aAdd(aCabec, {"C5_FRETE",   SC5->C5_FRETE * (nTaxaNew - nTaxaOld), Nil})
			aAdd(aCabec, {"C5_MOEDA",   1, Nil})
			aAdd(aCabec, {"C5_TXMOEDA", 0, Nil})
			aAdd(aCabec, {"C5_TIPO",    "C", Nil})
			aAdd(aCabec, {"C5_TPCOMPL", "1", Nil})
			aAdd(aCabec, {"C5_MENPAD",  cFormula, Nil})
			aAdd(aCabec, {"C5_CONDPAG", SC5->C5_CONDPAG, Nil})
			aAdd(aCabec, {"C5_NATUREZ", SC5->C5_NATUREZ, Nil})

			// Campos personalizados.
			aAdd(aCabec, {"C5_YUFEMB",  SC5->C5_YUFEMB,  Nil})
			aAdd(aCabec, {"C5_YLOCEMB", SC5->C5_YLOCEMB, Nil})
			aAdd(aCabec, {"C5_YTXMOED", nTaxaNew, Nil})
			aAdd(aCabec, {"C5_YDTMOED", dDataTaxa, Nil})
			aAdd(aCabec, {"C5_YMTMOED", cMsgTaxa, Nil})
			aAdd(aCabec, {"C5_DESC1", 0, Nil})
			aAdd(aCabec, {"C5_YINVOIC",  SC5->C5_YINVOIC,  Nil})

			//------------------------------------------------------------
			// Ponto de entrada apara alterar os campos do pedido Cabeçalho
			//------------------------------------------------------------
			If ExistBlock("GRNFCSC5")
				aCabec := ExecBlock("GRNFCSC5", .f., .f., {aCabec} )
			EndIf

			SF2->(DbCloseArea())
			SD2->(DbCloseArea())

			MSExecAuto({|x,y,z| Mata410(x,y,z)}, aCabec, aItens, 3)

			If lMsErroAuto

				RollbackSx8()

				If (IsBlind())

					//Documentação, rotina automatica (lAutoErrNoFile == .T.)não alimenta o mostra erro: https://tdn.totvs.com/pages/releaseview.action?pageId=6815090
					aErro := GetAutoGRLog()
					For nW := 1 To Len(aErro)
						cMsgErro += aErro[nW] +CRLF
					Next nW

				Else
					MostraErro()
				EndIf

				qQueSD2->(DbCloseArea())

				Return {.F., cMsgErro}
			EndIf

			//----------------------------------------------------------
			// Chama evento de liberação de regras com o SC5 posicionado
			// Necessário pois a MAGBAN bloqueia todos os pedidos por regra
			//----------------------------------------------------------
			MaAvalSC5("SC5",9)

			//----------------------------------------------------------
			// Libera pedido de venda.
			//----------------------------------------------------------
			SC6->(DbSetOrder(1))
			SC9->(dbSetOrder(1))

			SC6->(MsSeek(xFilial("SC6") + SC5->C5_NUM))

			While SC6->(!Eof()) .and. SC6->(C6_FILIAL + C6_NUM) == xFilial("SC6") + SC5->C5_NUM

				If SC9->(DbSeek(xFilial("SC9") + SC6->(C6_NUM + C6_ITEM)))
					While SC9->(!Eof()) .And. SC9->(C9_FILIAL + C9_PEDIDO + C9_ITEM) == xFilial("SC9") + SC6->(C6_NUM + C6_ITEM)
						If Empty(SC9->C9_NFISCAL)
							SC9->(a460Estorna())
						EndIf
						SC9->(DbSkip())
					EndDo
				EndIf

				MaLibDoFat( SC6->(RecNo()), SC6->C6_QTDVEN, @lBlqCrd, @lBlqEst, .t., .t., .f., .f. )
				SC6->(DbSkip())
			endDo

			//----------------------------------------------------------
			// Força liberação do pedido de venda.
			//----------------------------------------------------------
			//MaLiberOk({ SC5->C5_NUM },.t.) // Está atribuindo ao C5_NOTA o valor "XXXXXX"

			aRet := U_GRPREDOC(SC5->C5_NUM)

			If !aRet[1]
				qQueSD2->(DbCloseArea())
				RollbackSx8()
				cMsgErro := aRet[3]
				Return {.F., cMsgErro}
			EndIf

			cMsgSucesso += "Nf-e complementar número " + AllTrim(aRet[2]) + " gerada com sucesso, favor transmitir para o Sefaz!"+ chr(10)

		EndIf

		qQueSD2->(DbSkip())

	EndDo

	qQueSD2->(DbCloseArea())

	//Validar se um pedido foi incluido. Caso não tenha sido incluido o sistema retorna como erro, para não conseguir alterar o processo de exportação.
	if !empty(cMsgSucesso)
		cMsgSucesso += chr(10) + cMsgNFco
	ElseIf !empty(cMsgNFco)

		cMsgNFco +=  chr(10) + "Favor excluir os pedidos de venda caso queira alterar o Processo de Exportação!"

		Return {.F., cMsgNFco}
	EndIf

	//------------------------------------------------------------
	// Ponto de entrada após emissão da nota fiscal.
	//------------------------------------------------------------
	If ExistBlock("GRNFCFIM")
		ExecBlock("GRNFCFIM", .f., .f., {cNumPed, nTaxaNew} )
	EndIf

	if empty(cMsgSucesso)
		cMsgSucesso += "Processo salvo com sucesso!" + chr(10)
	EndIF

	If nTaxaOld > 0 .Or. nTaxaNew > 0
		cMsgSucesso += "Taxa do pedido = " + cValToChar(nTaxaOld) + chr(10)
		cMsgSucesso += "Taxa do complemento = " + cValToChar(nTaxaNew) + chr(10)
	EndIf

Return {.T., cMsgSucesso}

/*/{Protheus.doc} ATUVENC
Atualiza vencimento do título.
@type Static Function
@author Totvs Vitoria
@since 10/12/2019
@version version
/*/
User Function ATUVENC(cNumPed, dDatEmb)

	Local cSql   := ""
	Local qQuery := ""
	Local nDias  := 0

	If !Empty(dDatEmb) .And. dDatEmb <> STOD("") .And. !Empty(cNumPed)

		cSql := "    SELECT SE1.E1_EMISSAO, SE1.R_E_C_N_O_ "
		cSql += "      FROM " + RetSqlName("SD2") + " SD2 "
		cSql += " LEFT JOIN " + RetSqlName("SE1") + " SE1 "
		cSql += "        ON SE1.E1_FILIAL  = '" + xFilial("SE1") + "' "
		cSql += "       AND SE1.E1_CLIENTE = SD2.D2_CLIENTE "
		cSql += "       AND SE1.E1_LOJA    = SD2.D2_LOJA "
		cSql += "       AND SE1.E1_PREFIXO = SD2.D2_SERIE "
		cSql += "       AND SE1.E1_NUM     = SD2.D2_DOC "
		cSql += "       AND SE1.D_E_L_E_T_ = ' ' "
		cSql += "     WHERE SD2.D2_FILIAL  = '" + xFilial("SD2") + "' "
		cSql += "       AND SD2.D2_PEDIDO  = '" + cNumPed + "' "
		cSql += "       AND SD2.D_E_L_E_T_ = ' ' "
		cSql += "       AND SE1.R_E_C_N_O_ IS NOT NULL "
		cSql += "  GROUP BY SE1.E1_EMISSAO, SE1.R_E_C_N_O_ "

		TCQUERY cSql NEW ALIAS qQuery

		While qQuery->(!Eof())

			SE1->(DbGoTo(qQuery->R_E_C_N_O_))

			nDias := dDatEmb - StoD(qQuery->E1_EMISSAO)

			RecLock("SE1", .F.)
			SE1->E1_VENCTO  := SE1->E1_VENCORI + nDias
			SE1->E1_VENCREA := DataValida(SE1->E1_VENCTO, .T.)
			SE1->(MsUnLock())

			qQuery->(DbSkip())

		EndDo

		qQuery->(DbCloseArea())

	EndIf

Return Nil

/*/{Protheus.doc} QFATTTOS
Função utilizada para retornar a query quando
o parâmetro GR_FATTTOS estiver habilitado.
Essa função é executada nos pontos de entrada:
GR_M460FIL
GR_M460QRY
GR_MA410PVNF
@type Static Function
@author Kenny Roger Martins
@since 29/01/2021
@version version
/*/
User Function QFATTTOS(lAdvpl)

	Local cRet    := ""
	Local cSql    := ""

	Default lAdvpl := .F.

	If lAdvpl

		//------------------------------------------------------
		// Altera o status para processando para evitar
		// que outro usuário fature.
		//------------------------------------------------------
		cSql := " UPDATE " + RetSqlName("SC9")
		cSql += "    SET C9_YORDLIB  = 'P' "
		cSql += "  WHERE C9_FILIAL   = '" + xFilial("SC9") + "' "
		cSql += "    AND C9_YORDLIB <> ' ' "
		cSql += "    AND D_E_L_E_T_  = ' ' "

		nStatus := TCSQLEXEC( cSql )

		If (nStatus < 0)

			MsgStop("Ocorreu um erro ao processar o registro. TCSQLError() " + TCSQLError())

			If lAdvpl
				cRet += " C9_PEDIDO == '' "
			Else
				cRet += " AND C9_PEDIDO = '' "
			EndIf

			Return cRet

		EndIf

		//------------------------------------------------------
		// Altera o status para bloqueado.
		//------------------------------------------------------
		cSql := " UPDATE " + RetSqlName("SC9")
		cSql += "    SET C9_YORDLIB  = 'B' "
		cSql += "  WHERE R_E_C_N_O_ IN ("
		cSql += " SELECT SC9.R_E_C_N_O_ "
		cSql += "   FROM " + RetSqlName("SC9") + " SC9 "
		cSql += "  WHERE SC9.C9_FILIAL  = '" + xFilial("SC9") + "' "
		cSql += "    AND SC9.C9_NFISCAL = ' ' "
		cSql += "    AND SC9.C9_ORDSEP  = ' ' "
		cSql += "    AND SC9.C9_BLEST   = ' ' "
		cSql += "    AND SC9.C9_BLCRED  = ' ' "
		cSql += "    AND SC9.D_E_L_E_T_ = ' ' "
		cSql += "    AND ("

		cSql += " SELECT COUNT(*) "
		cSql += "   FROM " + RetSqlName("SC9") + " TMP "
		cSql += "  WHERE TMP.C9_FILIAL  = SC9.C9_FILIAL "
		cSql += "    AND TMP.C9_PEDIDO  = SC9.C9_PEDIDO "
		cSql += "    AND TMP.C9_ORDSEP <> ' ' "
		cSql += "    AND TMP.D_E_L_E_T_ = ' ' "
		cSql += " ) > 0)"

		nStatus := TCSQLEXEC( cSql )

		If (nStatus < 0)

			MsgStop("Ocorreu um erro ao processar o registro. TCSQLError() " + TCSQLError())

			If lAdvpl
				cRet += " C9_PEDIDO == '' "
			Else
				cRet += " AND C9_PEDIDO = '' "
			EndIf

			Return cRet

		EndIf

		//------------------------------------------------------
		// Altera o status para liberado dos demais.
		// Vazio é igual a liberado.
		//------------------------------------------------------
		cSql := " UPDATE " + RetSqlName("SC9")
		cSql += "    SET C9_YORDLIB  = ' ' "
		cSql += "  WHERE C9_FILIAL   = '" + xFilial("SC9") + "' "
		cSql += "    AND C9_YORDLIB  = 'P' "
		cSql += "    AND D_E_L_E_T_  = ' ' "

		nStatus := TCSQLEXEC( cSql )

		If (nStatus < 0)

			MsgStop("Ocorreu um erro ao processar o registro. TCSQLError() " + TCSQLError())

			If lAdvpl
				cRet += " C9_PEDIDO == '' "
			Else
				cRet += " AND C9_PEDIDO = '' "
			EndIf

			Return cRet

		EndIf

	EndIf

	If lAdvpl
		cRet += " C9_YORDLIB == ' ' "
	Else
		cRet += " AND C9_YORDLIB = ' ' "
	EndIf

Return cRet



/*/{Protheus.doc} VALIDCAV
	Função que verifica se o Saldo Lote (B8_SALDO), Quantidade (C6_QTDVEN) e a soma dos itens do cavalete são iguais ZPB.
	@type  Function
	@author Luiz Felipe Rodrigues
	@since 12/08/2021
	@version version
	/*/
User Function VALIDCAV( cProd, cLocal, cCavalete, cLoteCtl, cNumLote, nSaldo, nQtdVen,cClassi)

	Local aRet 	   := {.T., ''}
	Local cAlias   := GetNextAlias()
	Local cAlias2  := GetNextAlias()
	Local cAgrLote := ""
	Local cAgrSubL := ""
	Local cAgrZG4  := ALLTRIM(Posicione("ZG4", 1, xFilial("ZG4") + cClassi, "ZG4_AGRUPA"))
	Local cLotZPB  := LEFT(ALLTRIM(cLoteCtl),len(ALLTRIM(cLoteCtl)) - len(ALLTRIM(cAgrZG4))) // para buscar o lote na ZPB e necessário retirar o incremento do agrupador

	DEFAULT nQtdVen := 0

	BeginSql Alias cAlias

		SELECT SUM(B8_YQTDBD) B8_SOMAQTD, SUM(B8_YTOTLIQ) B8_SOMALIQ, B8_YCAVALE
			FROM %table:SB8% SB8
		WHERE SB8.%notDel%
			AND B8_FILIAL = %xFilial:SB8%
			AND B8_PRODUTO = %exp: cProd% 
			AND B8_LOCAL = %exp: cLocal%
			AND B8_YCAVALE = %exp: cCavalete%
			AND B8_ORIGLAN <> 'BD'
			AND B8_YNUMBD = %exp: cLoteCtl%
			AND B8_YSEQBD = %exp: cNumLote%
		GROUP BY B8_YCAVALE

	EndSql

	If (cAlias)->(!eof())


		// Só vai entrar na tela de pedido de venda
		If(nQtdVen > 0)

			If (cAlias)->B8_SOMAQTD <> nSaldo
				aRet[1] := .F.
				aRet[2] +=  Chr(13) + Chr(10)+'Produto : '+cProd+' Local: '+cLocal+' Cavalete: '+cCavalete+' Lote: '+cLoteCtl+' SubLote: '+cNumLote+' ';
					+'Há divergências no Saldo Lote (B8_SALDO)'+cValtochar(nSaldo)+' com a soma do saldo dos itens do cavalete (SUM(B8_YQTDBD))'+cValtochar((cAlias)->B8_SOMAQTD) + Chr(13) + Chr(10)
			EndIf

			If(nQtdVen <> nSaldo)
				aRet[1] := .F.
				aRet[2] +=  Chr(13) + Chr(10)+'Produto : '+cProd+' Local: '+cLocal+' Cavalete: '+cCavalete+' Lote: '+cLoteCtl+' SubLote: '+cNumLote+' ';
					+'Há divergências na Quantidade de venda (C6_QTDVEN)'+cValtochar(nQtdVen)+' com o saldo(B8_SALDO)'+cValtochar(nSaldo) + Chr(13) + Chr(10)
			EndIf

			If(cAlias)->B8_SOMALIQ <> nSaldo
				aRet[1] := .F.
				aRet[2] +=  Chr(13) + Chr(10)+'Produto : '+cProd+' Local: '+cLocal+' Cavalete: '+cCavalete+' Lote: '+cLoteCtl+' SubLote: '+cNumLote+' ';
					+'Há divergências no saldo (B8_SALDO)'+cValtochar(nSaldo)+' com a soma das medidas dos itens do cavalete(SUM(B8_YTOTLIQ)) '+cValtochar((cAlias)->B8_SOMALIQ) + Chr(13) + Chr(10)
			EndIf

		Else
			// tela de montagem de cavalete

			BeginSql Alias cAlias2

				SELECT SUM(ZPB_TOTLIQ) ZPB_SOMA, ZPB_CAVALE
					FROM %table:ZPB% ZPB
				WHERE ZPB.%notDel%
					AND ZPB_FILIAL = %xFilial:ZPB%
					AND ZPB_PRODUT = %exp: cProd%
					AND ZPB_LOCAL  = %exp: cLocal%
					AND ZPB_CAVALE = %exp: cCavalete%
					AND ZPB_LOTECT = %exp: cLotZPB%
					AND ZPB_CLASSI = %exp: cClassi% 
				GROUP BY ZPB_CAVALE

			EndSql

			IF (cAlias2)->(!eof())

				If (cAlias)->B8_SOMAQTD <> nSaldo
					aRet[1] := .F.
					aRet[2] +=  Chr(13) + Chr(10)+'Produto : '+cProd+' Local: '+cLocal+' Cavalete: '+cCavalete+' Lote: '+cLoteCtl+' SubLote: '+cNumLote+ Chr(13) + Chr(10);
						+'Há divergências no Saldo Lote (B8_SALDO)'+cValtochar(nSaldo)+' com a soma do saldo dos itens do cavalete (SUM(B8_YQTDBD)) '+cvaltochar((cAlias)->B8_SOMAQTD) + Chr(13) + Chr(10)
				EndIf

				If (cAlias)->B8_SOMALIQ <> nSaldo
					aRet[1] := .F.
					aRet[2] +=  Chr(13) + Chr(10)+'Produto : '+cProd+' Local: '+cLocal+' Cavalete: '+cCavalete+' Lote: '+cLoteCtl+' SubLote: '+cNumLote+ Chr(13) + Chr(10);
						+'Há divergências no saldo (B8_SALDO)'+cValtochar(nSaldo)+' com a soma das medidas dos itens do cavalete(B8_YTOTLIQ) '+cvaltochar((cAlias)->B8_SOMALIQ) + Chr(13) + Chr(10)
				EndIf

				If (cAlias2)->ZPB_SOMA <> nSaldo
					aRet[1] := .F.
					aRet[2] +=  Chr(13) + Chr(10)+'Produto : '+cProd+' Local: '+cLocal+' Cavalete: '+cCavalete+' Lote: '+cLoteCtl+' SubLote: '+cNumLote+ Chr(13) + Chr(10);
						+'Há divergências no saldo (B8_SALDO)'+cValtochar(nSaldo)+' com a soma das medidas dos itens do cavalete(SUM(ZPB_TOTLIQ)) '+cvaltochar((cAlias2)->ZPB_SOMA) + Chr(13) + Chr(10)
				EndIf

				(cAlias2)->(DBSkip())
			Else
				aRet[1] := .F.
				aRet[2] +=  Chr(13) + Chr(10)+'Produto : '+cProd+' Local: '+cLocal+' Cavalete: '+cCavalete+' Lote: '+cLoteCtl+' SubLote: '+cNumLote+ Chr(13) + Chr(10);
					+'Não foi encontrado itens na tabela ZPB' + Chr(13) + Chr(10)
			EndIf

			(cAlias2)->(DbCloseArea())

		EndIf
	Else
		If nSaldo > 0
			aRet[1] := .F.
			aRet[2] +=  Chr(13) + Chr(10)+'Produto : '+cProd+' Local: '+cLocal+' Cavalete: '+cCavalete+' Lote: '+cLoteCtl+' SubLote: '+cNumLote+ Chr(13) + Chr(10);
				+'Não foi encontrado itens na tabela SB8' + Chr(13) + Chr(10)
		EndIF
	EndIf

	(cAlias) ->(DbCloseArea())

Return aRet



/*/{Protheus.doc} AJUENGEN
Função utilizada para ajustar a engenharia e descrição da ZH7
@type Static Function
@author Pedro Luiz
@since 10/11/2021
@version version
/*/
User Function AJUENGEN()

	Local cRet    := ""
	Local cSql    := ""

	//------------------------------------------------------
	// Altera a engenharia e a descrição conforme a ZH8
	//------------------------------------------------------
	cSql := " UPDATE " + RetSqlName("ZH7")

	cSGBD := TCGetDB()

	if (cSGBD $ "ORACLE")
		cSql += "    SET ZH7_ENGENH  = (SELECT ZH8_ENGENH FROM "+RetSqlName("ZH8")+" ZH8 WHERE ZH8_NUM=ZH7_NUM AND ZH8_FILIAL=ZH7_FILIAL  AND ZH8.D_E_L_E_T_ = ' ' AND ROWNUM <= 1 ) "
		cSql += "      , ZH7_DESCEN  = (SELECT ZH8_DESCEN FROM "+RetSqlName("ZH8")+" ZH8 WHERE ZH8_NUM=ZH7_NUM AND ZH8_FILIAL=ZH7_FILIAL  AND ZH8.D_E_L_E_T_ = ' ' AND ROWNUM <= 1 ) "
	Else
		cSql += "    SET ZH7_ENGENH  = (SELECT TOP 1 ZH8_ENGENH FROM "+RetSqlName("ZH8")+" ZH8 WHERE ZH8_NUM=ZH7_NUM AND ZH8_FILIAL=ZH7_FILIAL  AND ZH8.D_E_L_E_T_ =' ') "
		cSql += "      , ZH7_DESCEN  = (SELECT TOP 1 ZH8_DESCEN FROM "+RetSqlName("ZH8")+" ZH8 WHERE ZH8_NUM=ZH7_NUM AND ZH8_FILIAL=ZH7_FILIAL  AND ZH8.D_E_L_E_T_ = ' ') "
	EndIf

	cSql += "  WHERE ZH7_ENGENH  = ' '"
	cSql += "    AND D_E_L_E_T_  = ' ' "

	nStatus := TCSQLEXEC( cSql )

	If (nStatus < 0)

		MsgStop("ZH7 - Ocorreu um erro ao processar o registro. TCSQLError() " + TCSQLError())

		Return .F.

	EndIf

Return .T.


/*/{Protheus.doc} User Function retMask
	(long_description)
	Rotina para retornar a masca com base no codigo de barras ou com base no lote
	Foi criada devido a possibilidade de desdobramento onde o sistema inclui uma letra a mais no 
	lote.
	@type  Function
	@author user
	@since 14/01/2022
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
	/*/
User Function retMask(cCodBar,clote)

	Local cMascara    := GetNewPar("GR_CODBARR", "TTTLLLLLLLLSSS")
	Local aPosFixo 	  := {"A","B","C","D","E","F","G","H","I","J","K","L"}
	Local i           := 0
	Local nQuantidade := 0
	Local cCaracter   := "L"
	Local nTotal      := 0
	Local nAtual	  := 0

	Local nTamTipo  := val(cvaltochar(u_getqtdctr(cMascara, "T")))
	Local nTamLote  := val(cvaltochar(u_getqtdctr(cMascara, "L")))
	Local cLotNovo  := ""
	Local cLotAnti  :=""

	DEFAULT cCodBar := ""
	DEFAULT clote   := ""

	If !EMPTY(cCodBar)

		//Verifica se o lote da etiqueta possui letra apos o tipo e lote
		//Se ele estiver letra e porque e um desdobramento e com isso e necessário incluir mais L para registrar.
		for i := 1 to len(aPosFixo)
			iF (aPosFixo[i] $ SubStr(cCodBar, nTamTipo+nTamLote, len(cCodBar)) )
				nQuantidade++
			EndIF
		next

	elseIf !Empty(clote) .AND. nTamLote < len(clote)

		//Verifica se o lote possui letra apos o tipo e lote
		for i := 1 to len(aPosFixo)
			iF (aPosFixo[i] $ clote )
				nQuantidade++
			EndIF
		next

	EndIf

	//Realiza a troca dos lotes antigos para o novo lote caso exista caracter
	//apos o tipo(TTT) e lote(LLLLL)
	If nQuantidade>0
		cLotNovo := PadR( "", nTamLote+nQuantidade,"L" )
		cLotAnti := PadR( "", nTamLote ,"L" )

		cMascara:= StrTran( cMascara, cLotAnti, cLotNovo )

	EndIf

Return cMascara


/*/{Protheus.doc} nomeStaticFunction
	(long_description)
	Rotina para alterar SD5 . Na transferencia os valores precisam ficar igual a origem. 
	
	@type  Static Function
	@author user
	@since 20/03/2023
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
/*/
Static Function ALTD5SEQ(cSeqOldm,cSeqNew,cDoc)

	Local lRet := .f.
	Local cSql := ""

	cSql := "    SELECT R_E_C_N_O_ "   + Chr(10)
	cSql += "    	   FROM " + RetSqlName("SD5")+ " SD5 " 			       + Chr(10)
	cSql += "    WHERE SD5.D5_FILIAL    = '" 	+ xFilial("SD5") + "' "        + Chr(10)
	cSql += "       AND SD5.D5_NUMSEQ   ='" 	+ cSeqOldm	+ "' " 		   + Chr(10)
	cSql += "       AND SD5.D_E_L_E_T_ = ' '" 							   + Chr(10)

	TCQUERY cSql NEW ALIAS qQueryD5

	If qQueryD5->(!Eof())
		SD5->(DBGOTO( qQueryD5->R_E_C_N_O_ ))
		RecLock("SD5", .F.)
		SD5->D5_NUMSEQ	:= cSeqNew
		SD5->D5_DOC	    := cDoc
		SD5->(MsUnlock())
		lRet := .t.
	EndIf

	qQueryD5->(DbCloseArea())

Return lRet

/*/{Protheus.doc} nomeStaticFunction
    (long_description)
    Tela de Mensagem de ERRO com Scroll e completa, sem cortar na tela
    
    @type  Static Function
    @author Rodolfo Salvador
    @since 20/03/2023
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    (examples)
    @see (links_or_references)
/*/
User Function HELPMSG(cTitulo, cTexto)

	Local   oDlg      := NIL
	Local   oFont     := NIL
	Local   oMemo     := NIL
	Local   lOk       := .f.
	Local 	bOK := {||lOk := .t. ,oDlg:End()}

	Default cTitulo := ''
	Default cTexto := ''

	If !isBlind()

		// Define Font oFont Name "Arial" Size 8, 12
		oFont := TFont():New('Arial',,15,,.F.,,,,.T.,.F.,.F.)

		Define MsDialog oDlg Title cTitulo From 3, 0 to 340, 417 Pixel

		@ 5, 5 Get oMemo Var cTexto Memo Size 200, 145 Of oDlg Pixel

		oMemo:bRClicked := { || AllwaysTrue() }

		oMemo:oFont     := oFont

		DEFINE SBUTTON FROM 153, 175  TYPE 1 ACTION Eval(bOk)     ENABLE  Of oDlg Pixel // Apaga

		Activate MsDialog oDlg Center

	Else
		lOk := .T.
		Conout(cTexto)
	EndIf

return {lOk,cTexto}

/*/{Protheus.doc} VLDMEDB8
Verifica se há divergência entre B8_SALDO e B8_YTOTLIQ do material. Mensagem aplicada nas rotinas GROA038, GROA060 e GROA062
@type user function
@author Renan M Botelho
@since 01/04/2025
@version 1.0
/*/
User Function VLDMEDB8(cTipo)

	Local cMessage 	:= ""
	Local cAuxSol 	:= ""
	Local lRet		:= .T.
	Default cTipo 	:= ""

	If (SB8->B8_YTOTLIQ <> SB8->B8_SALDO) .AND. (empty(cTipo) .OR. !("A" $ cTipo))

		cMessage += "A quantidade líquida (B8_YTOTLIQ): "+cvaltochar(SB8->B8_YTOTLIQ)+" está diferente do saldo (B8_SALDO): "+ cvaltochar(SB8->B8_SALDO) + ". Esse produto não será adicionado." + CHR(13) + CHR(10)
		cMessage += "Produto: " +alltrim(SB8->B8_PRODUTO) + CHR(13) + CHR(10)
		cMessage += "Local:   " +alltrim(SB8->B8_LOCAL)   + CHR(13) + CHR(10)
		cMessage += "Lote:    " +alltrim(SB8->B8_LOTECTL) + CHR(13) + CHR(10)
		cMessage += "SubLote: " +alltrim(SB8->B8_NUMLOTE) + CHR(13) + CHR(10)+ CHR(13) + CHR(10)
		cAuxSol  := "Analisar os campos B8_YTOTLIQ e B8_QUANT em Manutenção Bloco e Chapa"
		lRet	 := .F.

	EndIF

Return {lRet, cMessage, cAuxSol}

/*/{Protheus.doc} EXISTPED
Verifica se o material está contido em algum pedido de venda
@type user function
@author 
@since 
@version 1.0
/*/
User Function EXISTPED(cCod,clocal,cLote,cSubLote)

	Local cMessage 	:= ""
	Local cAuxSol 	:= ""
	Local lTemPed	:= .F.
	Local lRet		:= .T.
	Local qSQuery	:= ""
	Local cSql   	:= ""

	cSql := " SELECT C6_FILIAL, C6_PRODUTO, C6_LOCAL, C6_LOTECTL, C6_NUMLOTE, C6_NOTA "
	cSql += "   FROM " + RetSqlName("SC6") + " SC6 "
	cSql += " 	WHERE"
	cSql += "    		SC6.C6_FILIAL  	 = '" + xFilial("SC6") + "' "
	cSql += "    	AND SC6.C6_PRODUTO	 = '" + cCod + "'"
	cSql += "    	AND SC6.C6_LOCAL     = '" + clocal 	  + "'"
	cSql += "    	AND SC6.C6_LOTECTL   = '" + cLote     + "'"
	cSql += "    	AND SC6.C6_NUMLOTE   = '" + cSubLote  + "'"
	cSql += "    	AND SC6.C6_NOTA	     = ' '"
	cSql += "    	AND SC6.D_E_L_E_T_   = ' '"

	TCQUERY cSql NEW ALIAS qSQuery

	qSQuery->(DbGoTop())

	If qSQuery->(!EOF())

		lTemPed = .T.

		qSQuery->(DbSkip())

	EndIf

	qSQuery->(DbCloseArea())

	If lTemPed

		cMessage += "O produto abaixo já existe em um pedido de venda." + CHR(13) + CHR(10)
		cMessage += "Produto: " +alltrim(cCod) + CHR(13) + CHR(10)
		cMessage += "Local:   " +alltrim(clocal)   + CHR(13) + CHR(10)
		cMessage += "Lote:    " +alltrim(cLote) + CHR(13) + CHR(10)
		cMessage += "SubLote: " +alltrim(cSubLote) + CHR(13) + CHR(10)+ CHR(13) + CHR(10)
		cAuxSol  := "Favor retirar o produto do pedido de venda."
		lRet	 := .F.

	EndIf

return {lRet, cMessage, cAuxSol}

/*/{Protheus.doc} REGENDER
(long_description)Rotina para registrar a alteração do endereço em uma tabela para rastreio
@type user function
@author user
@since 02/05/2025
@version version
@param param_name, param_type, param_descr
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function REGENDER(cEndere,cCavale,cCod,cLote,cSubLot,lIncDado)

	Default cCavale  := ""
	Default lIncDado := .F.

	if empty(cCavale)

		DbSelectArea("ZR9") // necessário para o sistema criar a rotina a 1 vez

		if SB8->B8_YENDERE <> cEndere

			ZR9->(reclock("ZR9", .T.))
			ZR9->ZR9_FILIAL := xFilial("ZR9")
			ZR9->ZR9_COD   	:= if (!empty(cCod)   , cCod    ,SB8->B8_PRODUTO)
			ZR9->ZR9_LOTE   := if (!empty(cLote)  , cLote   ,SB8->B8_LOTECTL)
			ZR9->ZR9_NUMLOT := if (!empty(cSubLot), cSubLot ,SB8->B8_NUMLOTE)
			//ZR9->ZR9_CAVALE := if (!empty(cCavale), cCavale ,SB8->B8_YCAVALE) Esse campo vai ser preenchido somente se
			ZR9->ZR9_ENDERE := cEndere
			ZR9->ZR9_ROTINA := funname()
			ZR9->ZR9_CODUSE := RetCodUsr()
			ZR9->ZR9_NOMEUS := USRRETNAME(RETCODUSR())
			ZR9->ZR9_DATE   := Date()
			ZR9->ZR9_HORA   := time()
			ZR9->(MsUnLock())
		EndIf
	else

		if ZG3->ZG3_ENDERE <> cEndere .OR. lIncDado

			ZR9->(reclock("ZR9", .T.))
			ZR9->ZR9_FILIAL := xFilial("ZR9")
			ZR9->ZR9_CAVALE := cCavale
			ZR9->ZR9_ENDERE := cEndere
			ZR9->ZR9_ROTINA := funname()
			ZR9->ZR9_CODUSE := RetCodUsr()
			ZR9->ZR9_NOMEUS := USRRETNAME(RETCODUSR())
			ZR9->ZR9_DATE   := Date()
			ZR9->ZR9_HORA   := time()
			ZR9->(MsUnLock())
		EndIf

	EndIf

Return

/*/{Protheus.doc}
(long_description)
Rotina para retornar a quantidade do valor do recurso
Documentação : https://totvsleste.freshdesk.com/a/solutions/articles/22000291164

@type user function
@version version
@param param_name, param_type, param_descr
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function QTDRECUR(cTipo,nQtdInsu,nQtdProd,cRecurso)

	Local nQuant  := 0
	Local nQtdInd := 0
	Local cRotiEx := funname()
	Local aRetExe := {}

	If cTipo == "F"
		nQuant := nQtdInsu
	ElseIf cTipo == "I" .and. !empty(cRecurso)

		If SH1->(FieldPos("H1_YINDICE")) > 0
			nQtdInd := Posicione("SH1", 1, xFilial("SH1") + cRecurso , "H1_YINDICE")
		EndIf

		IF nQtdInd > 0
			nQuant  := nQtdInsu * nQtdProd * nQtdInd
		Else
			nQuant  := nQtdInsu * nQtdProd
		EndIf

	Else
		nQuant := nQtdInsu * nQtdProd
	EndIf

	If ExistBlock("GRCALINS")

		aRetExe := ExecBlock("GRCALINS", .f., .f., {cTipo,nQtdInsu,nQtdProd,cRecurso,nQuant,cRotiEx}  )

		nQuant := aRetExe[1]

	EndIf

Return nQuant

/*/{Protheus.doc} nomeStaticFunction
	(long_description)
	Rotina para apresentar o erro no begin sequence. Ela roda quando apresenta algum erro.
	@type  Static Function
	@author user
	@since 03/06/2025
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
/*/
USER Function GRChecEr(e)

	Local lRet 	   := .t.
	Local cErroMsg := ""

	IF e:gencode > 0

		cErroMsg := e:Description
		lRet:=.F.

		DisarmTransaction()

		u_HELPMSG("Erro na rotina: ",cErroMsg)

		KillApp(.T.)

	Endif
	Break
Return {lRet,cErroMsg}


/*/{Protheus.doc} 
(long_description)
Função que retorna os tipos de processo habilitados para aba de ZHL da ordem de produção
Atualmente temos esses processos: 
E=Extracao;S=Serrada;B=Beneficiamento;R=Recorte;T=Retrabalho;D=Desdobramento;B=Envelopamento     

@type user function
@author user
@since 05/06/2025
@version version
@param param_name, param_type, param_descr
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function HABZGH()

	Local cTiposZHL := "B/T/E/D"

Return cTiposZHL

/*/{Protheus.doc} getX3Box
Retorna valor do campo X3_CBOX
@author Kenny Roger Martins
@since 03/08/2025
@version 1.0
@return String
/*/
User Function getX3Box(aBox, xConteudo, nType)

	Local nPos	:= 0
	Local cRet	:= ''

	// Busca por descricao
	If nType = 1
		nPos := aScan(aBox,{|x| allTrim(upper(x[2])) == allTrim(upper(xConteudo))})
		If nPos > 0
			cRet := aBox[nPos,3]
		EndIf
		// Busca por valor
	Else
		nPos := aScan(aBox,{|x| allTrim(upper(x[3])) == allTrim(upper(xConteudo))})
		If nPos > 0
			cRet := aBox[nPos,2]
		EndIf
	EndIf

Return AllTrim(cRet)


/*/{Protheus.doc}
(long_description)
Função para verificar se esta deletando ou alterando uma com data inferiro a data base do sistema
@type user function
@author user
@since 04/08/2025
@version version
@param param_name, param_type, param_descr
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function VALDTSD5(cCod,clocal,cLote,cSubLote,cSubL2)

	Local cMessage 	:= ""
	Local cAuxSol 	:= ""
	Local lRet		:= .T.
	Local qSQuery	:= ""
	Local cSql   	:= ""


	cSql := " SELECT * "
	cSql += "   FROM " + RetSqlName("SD5") + " SD5 "
	cSql += "   INNER JOIN SD5990 SD5IN "
	cSql += "   	ON SD5IN.D5_FILIAL    = SD5.D5_FILIAL "
	cSql += "    	AND SD5IN.D5_PRODUTO  = SD5.D5_PRODUTO"
	cSql += "    	AND SD5IN.D5_LOCAL    = SD5.D5_LOCAL"
	cSql += "    	AND SD5IN.D5_LOTECTL  = SD5.D5_LOTECTL"
	cSql += "    	AND SD5IN.D5_NUMLOTE  = '" + cSubL2  + "'"
	cSql += "    	AND SD5IN.D5_DOC      = SD5.D5_DOC"
	cSql += "    	AND SD5IN.D5_OP	      = ' '"
	cSql += "    	AND SD5IN.D5_ESTORNO  = ' '"
	cSql += "    	AND SD5IN.D_E_L_E_T_  = ' '"
	cSql += " 	WHERE"
	cSql += "    		SD5.D5_FILIAL  	 = '" + xFilial("SD5") + "' "
	cSql += "    	AND SD5.D5_PRODUTO	 = '" + cCod + "'"
	cSql += "    	AND SD5.D5_LOCAL     = '" + clocal 	  + "'"
	cSql += "    	AND SD5.D5_LOTECTL   = '" + cLote     + "'"
	cSql += "    	AND SD5.D5_NUMLOTE   = '" + cSubLote  + "'"
	cSql += "    	AND SD5.D5_OP	     = ' '"
	cSql += "    	AND SD5.D5_ESTORNO	 = ' '"
	cSql += "    	AND SD5.D_E_L_E_T_   = ' '"
	cSql += "    ORDER BY SD5.R_E_C_N_O_ DESC"

	TCQUERY cSql NEW ALIAS qSQuery

	qSQuery->(DbGoTop())

	//Sistema so vai validar o ultimo registro porque esta em um recno desc.
	If qSQuery->(!EOF())
		If STOD(qSQuery->D5_DATA) > ddatabase
			cMessage += "A chapa alterada foi inserida apos a data base informada." + CHR(13) + CHR(10)
			cMessage += "Produto: " +alltrim(cCod) + CHR(13) + CHR(10)
			cMessage += "Local:   " +alltrim(clocal)   + CHR(13) + CHR(10)
			cMessage += "Lote:    " +alltrim(cLote) + CHR(13) + CHR(10)
			cMessage += "SubLote: " +alltrim(cSubLote) + CHR(13) + CHR(10)
			cMessage += "Documento: " +alltrim(qSQuery->D5_DOC) + CHR(13) + CHR(10)+ CHR(13) + CHR(10)
			cMessage += "Data da inclusão : " + U_FORMTADT(STOD(qSQuery->D5_DATA)) + CHR(13) + CHR(10)
			cMessage += "Data base : " + U_FORMTADT(ddatabase) + CHR(13) + CHR(10)+ CHR(13) + CHR(10)
			cAuxSol  := "Favor alterar o produto para uma data igual ou posterior a data Base:" + U_FORMTADT(ddatabase)
			lRet	 := .F.
		EndIf
		qSQuery->(DbSkip())

	EndIf

	qSQuery->(DbCloseArea())

return {lRet, cMessage, cAuxSol}


/*/{Protheus.doc} FORMTDT
(long_description)
@type user function
@author user
@since 04/08/2025
@version version
@param param_name, param_type, param_descr
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function FORMTADT(dData)

	Local cNewData := AllTrim(SubStr(DtoS(dData), 7, 2) + "/" + SubStr(DtoS(dData), 5, 2) + "/" + SubStr(DtoS(dData), 1, 4))

Return cNewData
