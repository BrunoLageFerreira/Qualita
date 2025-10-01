#INCLUDE "protheus.CH"
#INCLUDE "FWMVCDEF.CH"
#Include "Parmtype.ch"
#INCLUDE "TOTVS.CH"
#INCLUDE "FWEditPanel.CH"
#INCLUDE "TOPCONN.CH"

/*
{Protheus.doc} UGROA045
@Author  (TOTVS) / Bruno Lage/ 
@since 04/11/2022
@version 2.0

Atualizado Bruno Lage 
04-08-2025
*/
User Function UGROA045()
/**************************************************************************************************************
*
*
***/
Local aArea        := GetArea()
Local aParam       := PARAMIXB
Local lRet         := .T.
Local nret         := 0
Local nI           := 0
Local nX           := 0
Local oModel       := FWModelActive()
Local oModeLZGH 
Local oModelZGI 
Local oModelSH6
Local cQuery       := ''

Local cPerg1  := "XAPPAPONTA"

Private oObj       := ''
Private cIdPonto   := ''
Private cIdModel   := ''



If aParam <> NIL
	oObj       := aParam[1]
	cIdPonto   := aParam[2]
	cIdModel   := aParam[3]


	If cIdPonto == 'MODELCOMMITNTTS'
		DbSelectArea("ZGI")
		DbSetOrder(1)
		DbSeek(xFilial("ZGI")+ZH7->ZH7_NUM)
		Do while !Eof() .and. ZGI_FILIAL==xFilial("ZGI") .and. ZGI_OP == ZH7->ZH7_NUM
			SB1->(DbSetOrder(1))
			If SB1->(DbSeek(xFilial("SB1")+ZGI->ZGI_PRODUT))
				If "MAO DE OBRA"  $ SB1->B1_DESC .and. !Empty(SB1->B1_CCCUSTO)//Produto de mao de obra com centro de custos informado
					If Alltrim(ZH7->ZH7_PROCES) == 'S'
						nret := fTempoS()
					Else
						nret := ftempo()
					EndIf
					Reclock("ZGI",.F.)
					ZGI->ZGI_QTDE := nret
					ZGI->(MsUnlock())

				EndIf
			EndIf
			/*
			Pergunte(cPerg1,.F.)	
			if !EMPTY(mv_par01)

				cQuery := " UPDATE SIGAEIS..APP005_OP_CAB
				cQuery += "    SET CAB_NUMOP = '"+ AllTrim(ZH7->ZH7_NUM) + "'"
				cQuery += "  FROM SIGAEIS..APP005_OP_CAB WHERE CAB_D_E_L_E_T_ = '' AND CAB_ID = "+AllTrim(Str(mv_par01))
				
				TcSQLExec(cQuery)
			EndIf
			*/
			DbSelectArea("ZGI")
			DbSkip()
		EndDo

	ElseIf cIdPonto == 'MODELVLDACTIVE'
		/*
		cQuery := "DELETE FROM MP_SYSTEM_PROFILE WHERE D_E_L_E_T_ = '' AND P_PROG = 'XAPPAPONTA'"
		TcSQLExec(cQuery)
		cQuery := "DELETE FROM SX1010 WHERE D_E_L_E_T_ = '' AND X1_GRUPO = 'XAPPAPONTA'"
		TcSQLExec(cQuery)
		*/
		//Private nIDGlob := 0
	ElseIf cIdPonto == 'BUTTONBAR'
			//ApMsgInfo('Adicionando Botao na Barra de Botoes (BUTTONBAR).' + CRLF + 'ID ' + cIdModel )
		lRet := { {'Import. Apontamento', 'Import. Apontamento', { || u_APPApont()}, 'Import. Apontamento' } }
	ElseIf cIdPonto == 'MODELPOS'
		//Local oModelZGH := oModel:GetModel("ZGHDETAIL") // Operações
		//Local oModelSH6 := oModel:GetModel("SH6DETAIL") // Paradas - Hora improdutiva
		//Local oModelZGI := oModel:GetModel("ZGIDETAIL") // Insumos
		//Local oModelMOD := oModel:GetModel("MODDETAIL") // Custo indireto
		//Local oModelZGK := oModel:GetModel("ZGKDETAIL") // Mão-de-Obra
		//Local oModelZGL := oModel:GetModel("ZGLDETAIL") // Ferramenta
		//Local oModelZHL := oModel:GetModel("ZGLDETAIL") // Operações x Produto Acabado
		oModeLZGH := oModel:GetModel("ZGHDETAIL") 
		oModelSH6 := oModel:GetModel("SH6DETAIL") 
		/*
		Validação do SH6 na Confirmação do apontamento
		Motivo das paradas improdutivas.
		*/		
		For nI := 1 to oModelSH6:length()
			oModelSH6:GoLine(nI)
			If !(oModelSH6:IsDeleted()) // se a linha não estiver deletada
				If !Empty(oModelSH6:GetValue("H6_TEMPO")) // se existe tempo de parada calculado
					If Empty(oModelSH6:GetValue("H6_MOTIVO")) // se o motivo estive em branco 
						//Alert("O motivo da parada deve ser sempre preenchido!")
						
						oModel:SetErrorMessage("",,oModel:GetId(),"","GROA044","O motivo da parada deve ser sempre preenchido!")

						lRet := .f.
						Return(lRet)
					EndIf
				EndIf
			EndIf
		Next


		For nI := 1 to oModeLZGH:length()

			//valida a primeira linha do apontamento para verificar a data do estoque
			oModelZGH:GoLine(1)	
			
			IF ZH7->ZH7_EMISSA > GETMV("MV_ULMES") .Or. oModeLZGH:GetValue("ZGH_DATFIM")  > GETMV("MV_ULMES")
				//ZH7->ZH7_EMISSA
				IF Alltrim(M->ZH7_PROCES) == 'S'
					IF Empty(oModeLZGH:GetValue("ZGH_HRINI")) .OR.  Empty(oModeLZGH:GetValue("ZGH_HRFIM"))
						//Alert("O horímetro inicial e final devem ser prenchidos!")
						oModel:SetErrorMessage("",,oModel:GetId(),"","GROA044","O horímetro inicial e final devem ser prenchidos!")
						lRet := .f.
						Return(lRet)
					EndIf
				EndIf 

				If Empty(oModeLZGH:GetValue("ZGH_TOTHOR"))
					oModeLZH7 := oModel:GetModel("ZH7MASTER") 
					oModelZH7:SetValue("ZH7_XID",0)
				EndIf

				//loop do linha conforme nI := ModeLZGH:length()
				oModelZGH:GoLine(nI)
					
				oModelZGI := oModel:GetModel("ZGIDETAIL")
				oView := FwViewactive()
				For nX := 1 To oModeLZGI:Length()
					oModeLZGI:GoLine(nX)
					//Aqui estamos prercorrendo os insumos da operação
					If !(oModelZGI:IsDeleted())
						lRet := u_UGR045V(oModeLZGI:GetValue("ZGI_PRODUT"),oModeLZGI:GetValue("ZGI_LOCAL"),oModeLZGI:GetValue("ZGI_QTDE"),oModel)
						If  lRet == .F.
							//FwFldPut("ZGI_QTDE", 0,nX,oModeLZGI)
							oModeLZGI:SetValue("ZGI_QTDE",0)
						EndIf
					EndIf
					//cCodProd := oModeLZGI:GetValue("ZGI_PRODUT")
					//Alert("Teste para mostrar os produtos de insumo"+cCodProd)
				Next
				oModeLZGI:GoLine(1)
				//oView:Refresh("ZGIDETAIL")
				If !isBlind()
					oView:Refresh("ZGIDETAIL")
				EndIf

			Else
				//Alert("O formulário não pode ser alterado! O estoque já encontra-se fechado.")
				oModel:SetErrorMessage("",,oModel:GetId(),"","GROA044","O formulário não pode ser alterado! O estoque já encontra-se fechado.")
				oModel:GetModel("ZGHDETAIL"):SetOnlyView(.T.) 
				oModel:GetModel("ZGHDETAIL"):SetNoDeleteLine(.T.) 
				oModel:GetModel("ZGHDETAIL"):SetNoInsertLine(.T.) 
				oModel:GetModel("ZGHDETAIL"):SetNoUpdateLine(.T.)
				lRet := .f.
			EndIf
		Next
		//if MsgYesNo("Deseja cotinuar ?")
		//	lRet := .f.
		//EndIF
	EndIf

EndIf

RestArea(aArea)
//Final deo programa
Return(lRet)


User Function APPApont()
/****************************************************************************************************************
*
*
*
***/
Local oModel := FWModelActive()
Local cQuery := ""
Local cCodId := 0
Local lValid := .F.
Local nRegZGH:= 0
Local nRegSH6:= 0
Local oView  
Local nX     := 0
Local oModeLZH7
Local oModelZGI
Local nRegZGI
Local nI 
Private aPerg  := {}
Private cPerg  := "XAPPAPONTA"


Aadd(aPerg,{cPerg,"Digite o número ID?","N",9,00,"G","","","","","","","",""})     

U_Testasx1(cPerg,aPerg,.F.) 

If ! Pergunte(cPerg,.t.)
	Return
EndIf

iF !Empty(mv_par01)
    cCodId    := mv_par01    
	nIdGlobal := mv_par01
	//ZGH
    cQuery := "SELECT * FROM SIGAEIS..APP005_OP_CAB WHERE CAB_D_E_L_E_T_ = '' AND CAB_ID     = "+Trim(Str(cCodId))
    TCQUERY cQuery NEW ALIAS OP_CAB

	dbSelectArea("OP_CAB")
	dbGoTop()
	If !EOF() 
		oModeLZGH := oModel:GetModel("ZGHDETAIL")
		nRegZGH   := oModelZGH:Length()

		oView := FwViewactive()

		//If oModel:getOperation() == MODEL_OPERATION_UPDATE
			For nX := 1 To nRegZGH
				oModelZGH:GoLine(nX)

				oModelZGH:SetValue("ZGH_DATAPO",sToD(OP_CAB->CAB_DT_EMISSAO))
				oModelZGH:SetValue("ZGH_DATINI",sToD(OP_CAB->CAB_DTINI     ))
				oModelZGH:SetValue("ZGH_HORINI",AllTrim(OP_CAB->CAB_HORINI ))
				oModelZGH:SetValue("ZGH_DATFIM",sToD(OP_CAB->CAB_DTFIM     ))
				oModelZGH:SetValue("ZGH_HORFIM",AllTrim(OP_CAB->CAB_HORFIM ))

			Next
		//EndIf
			oModeLZH7 := oModel:GetModel("ZH7MASTER") 
			oModelZH7:SetValue("ZH7_XID",cCodId)
			oView:Refresh("ZH7MASTER")

			oModelZGH:GoLine(1)
			If !isBlind()
				oView:Refresh("ZGHDETAIL")
			EndIf
	Endif


    cQuery := "SELECT * FROM SIGAEIS..APP005_OP_PAR WHERE PAR_D_E_L_E_T_ = '' AND PAR_ID_CAB = "+Trim(Str(cCodId))+ " ORDER BY PAR_ID"
    TCQUERY cQuery NEW ALIAS OP_PAR

	dbSelectArea("OP_PAR")
	dbGoTop()

	If !EOF() 
		oModeLSH6 := oModel:GetModel("SH6DETAIL")
		nRegSH6   := oModelSH6:Length()

		oView := FwViewactive()
		Do While !Eof()

			nX := oModelSH6:Length()
		
			if Empty(oModelSH6:GetValue("H6_MOTIVO"))
				oModelSH6:GoLine(nX)
			Else
				oModelSH6:AddLine()
			EndIf
			
			oModelSH6:SetValue("H6_RECURSO", AllTrim(OP_PAR->PAR_RECURSO))
			oModelSH6:SetValue("H6_MOTIVO" , AllTrim(OP_PAR->PAR_CODMOTIVO))
			oModelSH6:SetValue("H6_DTAPONT", sTod(AllTrim(OP_PAR->PAR_DTAPONT)) )
			oModelSH6:SetValue("H6_DATAINI", sTod(AllTrim(OP_PAR->PAR_DATAINI)) )
			oModelSH6:SetValue("H6_HORAINI", AllTrim(OP_PAR->PAR_HORAINI))
			oModelSH6:SetValue("H6_DATAFIN", StoD(AllTrim(OP_PAR->PAR_DATAFIN)) )
			oModelSH6:SetValue("H6_HORAFIN", AllTrim(OP_PAR->PAR_HORAFIN)) 
			oModelSH6:SetValue("H6_OPERADO", AllTrim(OP_PAR->PAR_OPERADOR))
			//oModelSH6:SetValue("H6_OBSERVA", AllTrim(OP_PAR->PAR_RECURSO))

			dbSelectArea("OP_PAR")
			dbSkip()

			oModelSH6:GoLine(1)
			If !isBlind()
				oView:Refresh("SH6DETAIL")
			EndIf

		EndDo 
	EndIf

	//INSUMOS
	cQuery := "SELECT * FROM SIGAEIS..APP005_OP_INS WHERE INS_ID_CAB = "+Alltrim(Str(cCodId))+ " AND INS_D_E_L_E_T_='' ORDER BY INS_ID"
    TCQUERY cQuery NEW ALIAS OP_INS

	dbSelectArea("OP_INS")
	dbGoTop()

	If !EOF() 

		// Monta um array com os produtos retornados pela query
		aProdutos := {}

		While !EOF()
			AAdd(aProdutos, {AllTrim(OP_INS->INS_PRODUTO),OP_INS->INS_QTDTOT,.F.}) // campo do produto em OP_INS

			dbSelectArea("OP_INS")
			dbSkip()
		EndDo

		// Pega o modelo da grid
		oModelZGI := oModel:GetModel("ZGIDETAIL")
		nRegZGI   := oModelZGI:Length()

		iF nRegZGI == 1 .AND. AllTrim(oModelZGI:GetValue("ZGI_PRODUT")) == "" .And. Len(aProdutos) <> 0

			For nI := 1 To Len(aProdutos)
				If nI == 1
					oModelZGI:SetValue("ZGI_PRODUT", aProdutos[nI][1] )
					oModelZGI:SetValue("ZGI_QTDE"  , aProdutos[nI][2] )
					//oModelZGI:SetValue("ZGI_LOCAL" , "20"             )
				Else
					oModelZGI:AddLine()
					//ModelZGI:GoLine(nI)
					oModelZGI:SetValue("ZGI_PRODUT", aProdutos[nI][1] )
					oModelZGI:SetValue("ZGI_QTDE"  , aProdutos[nI][2] )
					//oModelZGI:SetValue("ZGI_LOCAL" , "20"             )
				EndIf
			Next
			oModelZGI:GoLine(1)
		Else
			// Percorre a grid de trás para frente
			For nI := nRegZGI To 1 Step -1
				oModelZGI:GoLine(nI)

				If !oModelZGI:IsDeleted()
					cProdGrid := AllTrim(oModelZGI:GetValue("ZGI_PRODUT"))

					// Busca o produto da grid dentro do array
					nPos := AScan(aProdutos, {|x| x[1] == cProdGrid })

					If nPos == 0
						// Produto não existe na query ? deletar linha
						oModelZGI:DeleteLine()
					Else
						// Produto existe ? atualizar quantidade
						oModelZGI:SetValue("ZGI_QTDE", aProdutos[nPos][2])
						aProdutos[nPos][3] := .T.
					EndIf
				EndIf
			Next

			// Depois de percorrer a grid, verifica se existe produto no array que não está na grid
			For nI := 1 To Len(aProdutos)
				// Procura o produto do array na grid
				If aProdutos[nI][3] == .F.
					// Se não encontrou na grid, precisa adicionar
					oModelZGI:AddLine()
					oModelZGI:SetValue("ZGI_PRODUT", aProdutos[nI][1])
					oModelZGI:SetValue("ZGI_QTDE"  , aProdutos[nI][2])
				EndIf
			Next
			oModelZGI:GoLine(1)

		EndIf

		// Atualiza a tela se não estiver em modo cego
		oView := FwViewActive()
		If !IsBlind()
			oView:Refresh("ZGIDETAIL")
		EndIf

	Else
		//SE NÃO HOUVER NENHUM INSUMO APONTADO NA OP 
		//O SISTEMA DEVE DELETAR TODAS AS LINHAS
		oModelZGI := oModel:GetModel("ZGIDETAIL") // Grid de Insumos
		nRegZGI   := oModelZGI:Length()           // Número de linhas

		// Loop de trás para frente para evitar problemas ao deletar linhas
		For nI := nRegZGI TO 1 STEP -1
			oModelZGI:GoLine(nI)
			If !oModelZGI:IsDeleted()
				oModelZGI:DeleteLine()  // Deleta a linha atual
			EndIf
		Next

		// Atualiza a tela se não estiver em modo cego
		oView := FwViewActive()
		If !IsBlind()
			oView:Refresh("ZGIDETAIL")
		EndIf

	EndIf

	OP_CAB->(DbCloseArea())
    OP_PAR->(DbCloseArea())
	OP_INS->(DbCloseArea())

    lValid := .T.
Else
    Alert("Código em Branco, ação não executada!")
EndIf 

Return(lValid)


User Function UGR045V(cCodPro,cCodDep,nQtd,oModel)
/**************************************************************************************************************
*  VALIDAÇÃO = ZGI_QTDE ZGI_PRODUT ZGI_LOCAL // 
*  Esta validação é chamada no campo ZGI_QTDE  para validar o estoque.
*  u_UGR045V(trim(FWFldGet("ZGI_PRODUT")),trim(FWFldGet("ZGI_LOCAL")),FWFldGet("ZGI_QTDE") )
***/
Local lRet := .T.
Local nSaldoAtu := 0

dbSelectArea("SB2")
dbSetOrder(1)
dbSeek(xFilial("SB2") + cCodPro + cCodDep) 
nSaldoAtu := CalcEst( cCodPro,cCodDep,dDataBASE,xFilial("SB2")) [1] 

If nSaldoAtu < nQtd
	lRet := .F.
	//Alert("Quantidade indisponível!")
	oModel:SetErrorMessage("",,oModel:GetId(),"","GROA044","Quantidade indisponível!")
	//VALOR ENCONTRADO NO SALDO
	FwFldPut("ZGI_QTDE", nSaldoAtu)

	If !Empty(cCodPro)
		dbSelectArea("SB1")
		dbSetOrder(1)
		dbSeek(xFilial("SB1")+ cCodPro)
		If SB1->B1_RASTRO = 'N'
			MaViewSB2(cCodPro,xFilial("SB1"))
		Else
			F4Lote(,,,   '',cCodPro,cCodDep,NIL,'',1)
		EndIf
	EndIf
EndIf

Return(lRet)


Static Function ftempoS()
/**************************************************************************************************************
*
*
***/
Local aArea := GetArea()
Local nret  := 0

DbSelectArea("ZGH")
DbSetOrder(1)
DbSeek(xFilial("ZGH")+ZGI->ZGI_OP+ZGI->ZGI_SEQUEN )
Do while !Eof() .and. ZGH_FILIAL == xFilial("ZGH") .and. ZGH_OP == ZGI->ZGI_OP .and. ZGH_SEQUEN == ZGI->ZGI_SEQUEN
	nret += ZGH->ZGH_HRFIM - ZGH->ZGH_HRINI
	DbSkip()
EndDo
RestArea(aArea)

Return(ABS(nret))

Static Function ftempo()
/**************************************************************************************************************
*
*
***/
Local aArea := GetArea()
Local cSql  := ""
Local nret  := 0
	
csql := " SELECT ZGH_TOTHRA"
csql += " from " + RetSqlName("ZGH")+" ZGH WITH(NOLOCK) "
csql +=  " where ZGH.ZGH_FILIAL =  '"+xFilial("ZGH")+"' "
csql +=  " and ZGH.ZGH_OP = '" + ZGI->ZGI_OP +"'"
csql +=  " and ZGH.ZGH_SEQUEN = '" + ZGI->ZGI_SEQUEN +"'"
csql +=  " and ZGH.D_E_L_E_T_ = ' '  "

TcQuery csql New Alias "ctrabalho"
DbGotop()
	
Do while !Eof()
	nret :=  SomaHoras( nret, ctrabalho->ZGH_TOTHRA )
	DbSkip()
EndDo

ctrabalho->(DbCloseArea())
csql := " SELECT H6_TEMPO,H6_TIPO  "
csql += " from " + RetSqlName("SH6")+" SH6 WITH(NOLOCK)"
csql +=  " where SH6.H6_FILIAL =  '"+xFilial("SH6")+"' "
csql +=  " and SH6.H6_OP = '" + ZH7->ZH7_NUM +"'"
csql +=  " and SH6.D_E_L_E_T_ = ' '  "
TcQuery csql New Alias "ctrabalho"
DbGotop()

Do while !Eof()
	If ctrabalho->H6_TIPO="I"
		nret :=  SubHoras( nret, ctrabalho->H6_TEMPO )
	EndIf
	DbSkip()
EndDo
ctrabalho->(DbCloseArea())
RestArea(aArea)

Return(ABS( ((((nret - int(nret)) * 100)/60) )  + int(nret) ))
