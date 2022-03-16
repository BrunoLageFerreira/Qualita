#INCLUDE 'Protheus.ch'
#INCLUDE 'FWMVCDef.ch'
#INCLUDE "TOPCONN.CH"

Static cTitulo := "Montagem de Cavalete"

/*/{Protheus.doc} GROA056
Montagem de Cavalete

@type  Function
@author Kenny Roger Martins
@since 21/08/2020
@version 1.00
/*/ 
User Function GROA056()

	Local aArea   := GetArea()
	Local oBrowse := Nil

	Private _lConsulta := .T.
	Private _lCampos   := .T.
	private _lNewZPB   := .F.

	U_TOTVSES()

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("ZG3")
	oBrowse:SetDescription(cTitulo)
	oBrowse:SetCacheView(.F.)
	oBrowse:AddLegend("ZG3_STATUS == 'D'", "BR_VERDE",    "Disponível")
	oBrowse:AddLegend("ZG3_STATUS == 'O'", "BR_VERMELHO", "Ocupado")
	oBrowse:SetMenuDef("GROA056")
	oBrowse:Activate()

	RestArea(aArea)

Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} MenuDef
MenuDef do modelo MVC
@return Nil
@author Kenny Roger Martins
@since 17/06/2020
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function MenuDef()

	Local aRot := {}

	aAdd(aRot, {'Pesquisar',       'VIEWDEF.GROA056', 0, 1, 0, NIL})
	aAdd(aRot, {'Visualizar',      'VIEWDEF.GROA056', 0, 2, 0, NIL})
	aAdd(aRot, {'Incluir',         'VIEWDEF.GROA056', 0, 3, 0, NIL})
	aAdd(aRot, {'Alterar',         'VIEWDEF.GROA056', 0, 4, 0, NIL})
	aAdd(aRot, {'Excluir',         'VIEWDEF.GROA056', 0, 5, 0, NIL})

	If ExistBlock("GR056MEN")
		aRot := ExecBlock("GR056MEN", .f., .f., aRot  )
	EndIf


Return aRot

//-------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
ModelDef do modelo MVC
@return Nil
@author Kenny Roger Martins
@since 17/06/2020
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function ModelDef()

	Local oModel    := Nil
	Local oStMaster := FWFormStruct(1, 'ZG3') // 'ZG3')
	Local oStDetail := FWFormStruct(1, 'ZPB') // 'ZPB')
	Local aRelation := {}

	oStMaster:SetProperty('ZG3_TARA',   MODEL_FIELD_VALID, FwBuildFeature(STRUCT_FEATURE_VALID, 'U_GRA056V1()'))
	oStMaster:SetProperty('ZG3_PESOBR', MODEL_FIELD_VALID, FwBuildFeature(STRUCT_FEATURE_VALID, 'U_GRA056V1()'))
	oStMaster:SetProperty('ZG3_PESOLQ', MODEL_FIELD_VALID, FwBuildFeature(STRUCT_FEATURE_VALID, 'U_GRA056V1()'))

	oStDetail:SetProperty('ZPB_CAVALE', MODEL_FIELD_OBRIGAT, .F.) // Remove obrigatoriedade do campo.

	//Criando o modelo e os relacionamentos
	oModel := MPFormModel():New('GROA056M', /*bPre*/, /*bPos*/, {|oModel| Gravar(oModel)} /*bCommit*/, /*bCancel*/)
	oModel:AddFields('ALIMASTER',/*cOwner*/,oStMaster)
	oModel:AddGrid('ALIDETAIL','ALIMASTER',oStDetail, {|oModel, nLine, cOperation| PosLine(oModel, nLine, cOperation)}/*bLinePre*/, /*bLinePost*/,/*bPre - Grid Inteiro*/,/*bLoad - Carga do modelo manualmente*/)  //cOwner é para quem pertence

	//Fazendo o relacionamento entre o Pai e Filho
	aAdd(aRelation, {'ZPB_FILIAL', 'FwXFilial("ZPB")'})
	aAdd(aRelation, {'ZPB_CAVALE', 'ZG3_CODIGO'})

	oModel:SetRelation('ALIDETAIL', aRelation, ZPB->(IndexKey(1))) //IndexKey -> quero a ordenação e depois filtrado
	oModel:GetModel('ALIDETAIL'):SetUniqueLine({"ZPB_FILIAL","ZPB_CAVALE","ZPB_ITEM"}) //Não repetir informações ou combinações {"CAMPO1","CAMPO2","CAMPOX"}
	// oModel:GetModel('ALIDETAIL'):SetUniqueLine({"ZPB_FILIAL","ZPB_CAVALE","ZPB_PRODUT","ZPB_LOCAL","ZPB_LOTECT","ZPB_NUMLOT"}) //Não repetir informações ou combinações {"CAMPO1","CAMPO2","CAMPOX"}
	oModel:SetPrimaryKey({'ZG3_FILIAL','ZG3_CODIGO'})

	//Setando as descrições
	oModel:SetDescription("Montagem de Cavalete")
	oModel:GetModel('ALIMASTER'):SetDescription('Cavalete')
	oModel:GetModel('ALIDETAIL'):SetDescription('Chapas')

	// Permite salvar o GRID sem dados.
	oModel:GetModel( "ALIDETAIL" ):SetOptional( .T. )

	//Incluido a opção de salvar sem alterar nada, necessário devido a inclusão via manutenção bloco e chapa
	oModel:lModify := .T.

	//Validação apos o activate para o sistema recalcular o peso da ZPB
	//Quando for incluido por outra rotina
	oModel:SetPre( { |oModel| postes(oModel) } )

	//Verifica se realiza ativição do Modelo
	oModel:SetVldActivate( { |oModel| VldEdicao(oModel) } )

Return oModel

//-------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
ViewDef do modelo MVC
@return Nil
@author Kenny Roger Martins
@since 17/06/2020
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function ViewDef()

	Local oView      := Nil
	Local oModel     := FWLoadModel('GROA056')
	Local oStMaster  := FWFormStruct(2, 'ZG3')
	Local oStDetail  := FWFormStruct(2, 'ZPB')
	Local aParEst    := StrTokArr( superGetMv("GR_KEYEST", .F., "17,[Ctrl+Q]"), "," )
	Local cKeyEst    := aParEst[1]
	Local bGetProd   := {|| FWMsgRun(, {|| GetProd()}, "Processando", "Carregando Produtos...") }
	Local aEditPed   := StrTokArr(GetNewPar("GR_BUNDCPO", ""), ",") // Permite alterar campos do bundle mesmo estando em pedido de venda.
	Local nX         := 0

	//Criando a View
	oView := FWFormView():New()

	oView:addUserButton(aParEst[2] +" Consulta Estoque", "CONSULTA", bGetProd, "Consulta Estoque de Produtos")

	SetKey(Val(cKeyEst), bGetProd)

	oView:SetModel(oModel)

	//Adicionando os campos do cabeçalho e o grid dos filhos
	oView:AddField('VIEW_MASTER',oStMaster,'ALIMASTER')
	oView:AddGrid('VIEW_DETAIL',oStDetail,'ALIDETAIL')

	//Setando o dimensionamento de tamanho
	oView:CreateHorizontalBox('HEADER',35)
	oView:CreateHorizontalBox('GRID',65)

	//Amarrando a view com as box
	oView:SetOwnerView('VIEW_MASTER','HEADER')
	oView:SetOwnerView('VIEW_DETAIL','GRID')

	//Força o fechamento da janela na confirmação
	oView:SetCloseOnOk({||.T.})

	oView:SetViewCanActivate({|oView| VldView(oView)})

	//Adicione o incremental
	oView:AddIncrementField('VIEW_DETAIL', 'ZPB_ITEM')

	//Remove os campos de Código do Artista e CD
	oStDetail:RemoveField('ZPB_CAVALE')

	//Não permite alteração dos campos
	oStDetail:SetProperty('*', MVC_VIEW_CANCHANGE, .F.)

Return oView

//-------------------------------------------------------------------
/*/{Protheus.doc} GetProd
Consulta Estoque
@return Nil
@author Kenny Roger Martins
@since 31/10/2019
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function GetProd()

	Local cFilInter   := GetNewPar("GR_ESTINTE", "xFilial('SB8')") // Filiais para consulta de estoque.
	Local aSelect     := {}
	Local oView       := FWViewActive()
	Local oModel      := FWModelActive()
	Local oModelZG3   := oModel:GetModel("ALIMASTER")
	Local oModelZPB   := oModel:GetModel("ALIDETAIL")
	Local lAtuaZG3  := GetNewPar("GR_ATUAZG3", .T.) // Atualiza o peso do Cavalete conforme seleção de chapas
	Local nX          := 0
	Local nPesoLiq    := 0
	Local nPesoBru    := 0
	Local cExpSB8     := ""
	Local cExpSql     := ""
	Local aTotais     := {}
	Local aCpoRet     := {}
	Local aMarcados   := {}
	Local lExist      := .F.
	Local cTipoProd   := GetNewPar("GR_BUNDTIP", "'C'") // Tipo de grupo de produto que será retornado na consulta da montagem de cavalete, padrão C=Chapa
	Local lContCav    := .T.

	If _lConsulta

		cExpSql := "     SELECT "
		cExpSql += "            SB8.B8_FILIAL,  "
		cExpSql += "            SB8.B8_LOCAL,   "
		cExpSql += "            SB8.B8_PRODUTO, "
		cExpSql += "            SB1.B1_DESC,    "
		cExpSql += "            SB8.B8_LOTECTL, "
		cExpSql += "            SB8.B8_NUMLOTE, "
		cExpSql += "            SB8.B8_YCAVALE, "
		cExpSql += "            SB8.B8_YCLASSI, "
		cExpSql += "            SB8.B8_SALDO,   "
		cExpSql += "            SB8.B8_DATA,    "
		cExpSql += "            SB8.B8_DTVALID, "
		cExpSql += "            SB8.B8_YCOMLIQ, "
		cExpSql += "            SB8.B8_YALTLIQ, "
		cExpSql += "            SB8.B8_YESPLIQ, "
		cExpSql += "            SB8.B8_YTOTLIQ, "
		cExpSql += "            SB8.B8_YCOMBRU, "
		cExpSql += "            SB8.B8_YALTBRU, "
		cExpSql += "            SB8.B8_YESPBRU, "
		cExpSql += "            SB8.B8_YTOTBRU, "
		cExpSql += "            SB8.B8_YCLAPRO, "
		cExpSql += "            SB8.B8_YPESOBR, "
		cExpSql += "            SB8.B8_YPESOLQ, "
		cExpSql += "            SB8.B8_LOTEFOR  "

		cExpSql += "       FROM " + RetSqlName("SB8") + " SB8 (NOLOCK) "
		cExpSql += " INNER JOIN " + RetSqlName("SB1") + " SB1 (NOLOCK) "
		cExpSql += "         ON (SB1.B1_FILIAL  = '" + xFilial("SB1") + "' OR SB1.B1_FILIAL = SB8.B8_FILIAL) "
		cExpSql += "        AND SB1.B1_COD     = SB8.B8_PRODUTO "
		cExpSql += "        AND SB1.D_E_L_E_T_ = '' "
		cExpSql += " INNER JOIN " + RetSqlName("SBM") + " SBM (NOLOCK) "
		cExpSql += "         ON (SBM.BM_FILIAL  = '" + xFilial("SBM") + "' OR SBM.BM_FILIAL = SB8.B8_FILIAL) "
		cExpSql += "        AND SBM.BM_GRUPO   = SB1.B1_GRUPO "
		cExpSql += "        AND SBM.BM_YTIPO   IN (" + cTipoProd + ") "
		cExpSql += "        AND SBM.D_E_L_E_T_ = '' "
		cExpSql += "      WHERE SB8.B8_FILIAL  = '" + xFilial("SB8") + "' "
		cExpSql += "        AND SB8.B8_SALDO   > 0  "
		cExpSql += "        AND SB8.B8_EMPENHO = 0  "
		cExpSql += "        AND SB8.B8_YCAVALE <> '" + oModelZG3:GetValue("ZG3_CODIGO") +"'"
		cExpSql += "        AND SB8.D_E_L_E_T_ = '' "
		cExpSql += "        AND SB8.B8_ORIGLAN <> 'BD' "
		cExpSql += "   ORDER BY SB8.B8_FILIAL,  "
		cExpSql += "            SB8.B8_LOCAL,   "
		cExpSql += "            SB8.B8_PRODUTO, "
		cExpSql += "            SB8.B8_LOTECTL, "
		cExpSql += "            SB8.B8_NUMLOTE  "

		aAdd( aCpoRet, "B8_FILIAL" )
		aAdd( aCpoRet, "B8_PRODUTO" )
		aAdd( aCpoRet, "B1_DESC" )
		aAdd( aCpoRet, "B8_LOCAL" )
		aAdd( aCpoRet, "B8_LOTECTL" )
		aAdd( aCpoRet, "B8_NUMLOTE" )
		aAdd( aCpoRet, "B8_YCAVALE" )
		aAdd( aCpoRet, "B8_YCLASSI" )
		aAdd( aCpoRet, "B8_YCLAPRO" )
		aAdd( aCpoRet, "B8_YCOMLIQ" )
		aAdd( aCpoRet, "B8_YALTLIQ" )
		aAdd( aCpoRet, "B8_YESPLIQ" )
		aAdd( aCpoRet, "B8_YTOTLIQ" )
		aAdd( aCpoRet, "B8_YALTBRU" )
		aAdd( aCpoRet, "B8_YESPBRU" )
		aAdd( aCpoRet, "B8_YCOMBRU" )
		aAdd( aCpoRet, "B8_YTOTBRU" )
		aAdd( aCpoRet, "B8_YPESOBR" )
		aAdd( aCpoRet, "B8_YPESOLQ" )
		aAdd( aCpoRet, "B8_SALDO" )
		aAdd( aCpoRet, "B8_LOTEFOR" )

		aAdd( aTotais, {"B8_FILIAL","COUNT","Contador","@E 999,999"} )
		aAdd( aTotais, {"B8_YTOTLIQ","SUM","Total Líquido","@E 999,999,999.99"} )
		aAdd( aTotais, {"B8_YTOTBRU","SUM","Total Bruto","@E 999,999,999.99"} )

		aAdd(aMarcados, {{"B8_FILIAL", oModelZG3:GetValue("ZG3_FILIAL")}, {"B8_YCAVALE", oModelZG3:GetValue("ZG3_CODIGO")}})

		aSelect := U_GROCGEN("SB8", cExpSB8, "Estoque de Materiais", cExpSql, aCpoRet, .T., aTotais, 100, aMarcados, .T.)[2]

		For nX := 1 To Len(aSelect)

			lExist := oModelZPB:SeekLine({;
				{"ZPB_PRODUT", aSelect[nX][aScan(aSelect[nX], {|x| x[1] == "B8_PRODUTO"})][2]},;
				{"ZPB_LOCAL",  aSelect[nX][aScan(aSelect[nX], {|x| x[1] == "B8_LOCAL"})][2]},;
				{"ZPB_LOTECT", aSelect[nX][aScan(aSelect[nX], {|x| x[1] == "B8_LOTECTL"})][2]},;
				{"ZPB_NUMLOT", aSelect[nX][aScan(aSelect[nX], {|x| x[1] == "B8_NUMLOTE"})][2]}})

			If lExist
				Loop
			EndIf

			//https://totvsleste.freshdesk.com/a/tickets/2843
			//Apresentar mensagem quando a chapa esta em um cavalete
			If lContCav .AND. !EMPTY(aSelect[nX][aScan(aSelect[nX], {|x| x[1] == "B8_YCAVALE"})][2])
				If !MsgYesNo("Existe chapa em cavalete, deseja transferir?" )
					exit 
				ELSE
					lContCav := .F.
				EndIf

			EndIF

			If !oModelZPB:isEmpty()
				oModelZPB:AddLine()
			EndIf

			oModelZPB:SetValue('ZPB_PRODUT', aSelect[nX][aScan(aSelect[nX], {|x| x[1] == "B8_PRODUTO"})][2] )
			oModelZPB:SetValue('ZPB_DESCRI', aSelect[nX][aScan(aSelect[nX], {|x| x[1] == "B1_DESC"})][2] )
			oModelZPB:SetValue('ZPB_LOCAL',  aSelect[nX][aScan(aSelect[nX], {|x| x[1] == "B8_LOCAL"})][2] )
			oModelZPB:SetValue('ZPB_LOTECT', aSelect[nX][aScan(aSelect[nX], {|x| x[1] == "B8_LOTECTL"})][2] )
			oModelZPB:SetValue('ZPB_NUMLOT', aSelect[nX][aScan(aSelect[nX], {|x| x[1] == "B8_NUMLOTE"})][2] )
			oModelZPB:SetValue('ZPB_CLASSI', aSelect[nX][aScan(aSelect[nX], {|x| x[1] == "B8_YCLASSI"})][2] )
			oModelZPB:SetValue('ZPB_CLAPRO', aSelect[nX][aScan(aSelect[nX], {|x| x[1] == "B8_YCLAPRO"})][2] )
			oModelZPB:SetValue('ZPB_COMLIQ', aSelect[nX][aScan(aSelect[nX], {|x| x[1] == "B8_YCOMLIQ"})][2] )
			oModelZPB:SetValue('ZPB_ALTLIQ', aSelect[nX][aScan(aSelect[nX], {|x| x[1] == "B8_YALTLIQ"})][2] )
			oModelZPB:SetValue('ZPB_ESPLIQ', aSelect[nX][aScan(aSelect[nX], {|x| x[1] == "B8_YESPLIQ"})][2] )
			oModelZPB:SetValue('ZPB_TOTLIQ', aSelect[nX][aScan(aSelect[nX], {|x| x[1] == "B8_YTOTLIQ"})][2] )
			oModelZPB:SetValue('ZPB_COMBRU', aSelect[nX][aScan(aSelect[nX], {|x| x[1] == "B8_YCOMBRU"})][2] )
			oModelZPB:SetValue('ZPB_ALTBRU', aSelect[nX][aScan(aSelect[nX], {|x| x[1] == "B8_YALTBRU"})][2] )
			oModelZPB:SetValue('ZPB_ESPBRU', aSelect[nX][aScan(aSelect[nX], {|x| x[1] == "B8_YESPBRU"})][2] )
			oModelZPB:SetValue('ZPB_TOTBRU', aSelect[nX][aScan(aSelect[nX], {|x| x[1] == "B8_YTOTBRU"})][2] )
			oModelZPB:SetValue('ZPB_PESOBR', aSelect[nX][aScan(aSelect[nX], {|x| x[1] == "B8_YPESOBR"})][2] )
			oModelZPB:SetValue('ZPB_PESOLQ', aSelect[nX][aScan(aSelect[nX], {|x| x[1] == "B8_YPESOLQ"})][2] )

			oModelZG3:LoadValue("ZG3_QCHAPA", oModelZG3:GetValue("ZG3_QCHAPA") + 1)
			If lAtuaZG3
				oModelZG3:LoadValue("ZG3_PESOBR", oModelZG3:GetValue("ZG3_PESOBR") + oModelZPB:GetValue("ZPB_PESOBR"))
				oModelZG3:LoadValue("ZG3_PESOLQ", oModelZG3:GetValue("ZG3_PESOLQ") + oModelZPB:GetValue("ZPB_PESOLQ"))
			EndIf
			iF ZG3->(FieldPos("ZG3_TOTBRU")) > 0
				oModelZG3:LoadValue("ZG3_TOTLIQ", oModelZG3:GetValue("ZG3_TOTLIQ") + oModelZPB:GetValue("ZPB_TOTLIQ"))
				oModelZG3:LoadValue("ZG3_TOTBRU", oModelZG3:GetValue("ZG3_TOTBRU") + oModelZPB:GetValue("ZPB_TOTBRU"))
			EndIF


			oView:Refresh("VIEW_DETAIL")

		Next

		oModelZPB:GoLine(1)

		//Ajuste para recalcular os pesos.
		//O sistema não recalcula quando o usuário alterava o peso para o mesmo valor.
		//Incluido o valor de menos 15 porque o usuário utiliza o zero no cavalete.
		if ! lAtuaZG3
			nPesoLiq  := oModelZG3:GetValue("ZG3_PESOLQ")
			nPesoBru  := oModelZG3:GetValue("ZG3_PESOBR")
			oModelZG3:SetValue("ZG3_PESOLQ", -15)
			oModelZG3:SetValue("ZG3_PESOLQ",nPesoLiq)
			oModelZG3:SetValue("ZG3_PESOBR", -15)
			oModelZG3:SetValue("ZG3_PESOBR", nPesoBru)
		EndIf


		oView:Refresh("VIEW_DETAIL")
		oView:Refresh("VIEW_MASTER")

	Else

		MsgStop("Consulta de estoque não permitida para esse tipo de operação!")

	EndIf

Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} Gravar
Grava a reserva na tabela padrão para garantir a integridade
caso seja executado a rotina de refaz empenhos.
@return Nil
@author Kenny Roger Martins
@since 19/06/2020
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function Gravar(oModel)

	Local lRet      := .T.
	Local cCavalete := oModel:GetValue("ALIMASTER", "ZG3_CODIGO")
	Local cCavalOld := ""
	Local cEndereco := oModel:GetValue("ALIMASTER", "ZG3_ENDERE")
	Local oGrid     := oModel:GetModel("ALIDETAIL")
	Local nOper     := oModel:nOperation
	Local nPosRes   := 0
	Local aParam    := {}
	Local aLinha    := {}
	Local cStatus   := GetNewPar("GR_STCAVAL", "")
	Local nB8Bundle := GetNewPar("GR_B8BUNDL", 0) // Transfere  o saldo das chapas criando o bundle na SB8
	Local nChapas   := 0
	Local aAreaZPB  := Nil
	Local nStatus   := 0
	Local nPesoLiq := oModel:GetValue("ALIMASTER", "ZG3_PESOLQ")
	Local nPesoBru := oModel:GetValue("ALIMASTER", "ZG3_PESOBR")
	Local aReTrans := {}
	Local lExist   := .f.
	Local nX   	   := 0

	Begin Transaction

		//Realizado validação para não incluir um codigo de cavalete que existe chapas cadastrada com o mesmo codigo
		//https://totvsleste.freshdesk.com/a/tickets/2802
		If nOper == MODEL_OPERATION_INSERT

			cSql := "   SELECT count(*) QUANTIDADE "
			cSql += "     FROM " + RetSqlName("SB8") + " SB8 "
			cSql += "    WHERE SB8.B8_FILIAL  = '" + xFilial("SB8") + "' "
			cSql += "      AND SB8.B8_YCAVALE = '" + AllTrim(cCavalete) + "' "
			cSql += "      AND SB8.D_E_L_E_T_ = ''"

			TCQUERY cSql NEW ALIAS qQuery

			If qQuery->QUANTIDADE > 0
				cMsgErro := "Já existe chapas com esse codigo de cavalete na SB8. Codigo: " + cCavalete+" Favor retirar o codigo de cavalete dessas chapas via manutenção bloco e chapa"
				ConOut(cMsgErro)
				MsgStop(cMsgErro)
				DisarmTransaction()
				qQuery->(DbCloseArea())

				Return .f.
			ENDiF

			qQuery->(DbCloseArea())

		EndIf

		FWFormCommit(oModel)

		If nOper == MODEL_OPERATION_DELETE

			//----------------------------------------------------------
			// Transferência do chapa do bundle para chapa avulsa.
			//----------------------------------------------------------
			If nB8Bundle <> 0

				cSql := "   SELECT * "
				cSql += "     FROM " + RetSqlName("SB8") + " SB8 "
				cSql += "    WHERE SB8.B8_FILIAL  = '" + xFilial("SB8") + "' "
				cSql += "      AND SB8.B8_YCAVALE = '" + AllTrim(cCavalete) + "' "
				cSql += "      AND SB8.B8_SALDO   = 0 "
				cSql += "      AND SB8.B8_ORIGLAN <> 'BD' "
				cSql += "      AND SB8.D_E_L_E_T_ = ''"

				TCQUERY cSql NEW ALIAS qQuery

				While qQuery->(!Eof())

					aLinha := U_ArrTrfBd(cCavalete, qQuery->(B8_FILIAL + B8_PRODUTO + B8_LOCAL + B8_LOTECTL + B8_NUMLOTE), .F.)
					aAdd(aParam, aLinha)

					qQuery->(DbSkip())
				EndDo
				qQuery->(DbCloseArea())
			EndIf

			cSql := " UPDATE " + RetSqlName("SB8")
			cSql += "    SET B8_YCAVALE = '', "
			cSql += "        B8_YNUMBD  = '', "
			cSql += "        B8_YSEQBD  = '', "
			cSql += "        B8_YQTDBD  = 0  "
			cSql += "  WHERE B8_FILIAL  = '" + xFilial("SB8") + "' "
			cSql += "    AND B8_YCAVALE = '" + cCavalete + "' "
			cSql += "    AND D_E_L_E_T_ = ''"

			nStatus := TCSqlExec(cSql)

			If (nStatus < 0)
				cMsgErro := "GrPlus Error => TCSQLError: " + TCSQLError()
				ConOut(cMsgErro)
				MsgStop(cMsgErro)
				Return .f.
			EndIf

			//--------------------------------------------------
			// Desfaz o bundle na tabela SB8.
			//--------------------------------------------------
			If nB8Bundle <> 0
				If !(U_TransfBd(aParam))
					cMsgErro := "2-GrPlus Error => Montagem/Desmontagem do bundle na SB8."
					ConOut(cMsgErro)
					RollbackSx8()
					DisarmTransaction()
					setRestFault(500, oUtil:pText(cMsgErro))
					Return .f.
				EndIf
			EndIf

		Else

			For nX := 1 To oGrid:Length()

				oGrid:GoLine(nX)

				If oGrid:IsDeleted()

					SB8->(DbSetOrder(3))

					If SB8->(DbSeek( xFilial("SB8") + oGrid:GetValue("ZPB_PRODUT") + oGrid:GetValue("ZPB_LOCAL") + oGrid:GetValue("ZPB_LOTECT") + oGrid:GetValue("ZPB_NUMLOT") ))

						If cCavalete == SB8->B8_YCAVALE
							//Validação porque o usuário pode incluir a chapa ,deletar ela. Incluir a chapa novamente e deletar essa nova chapa. Se retornar a primeira que foi deletada o sistema limpava o cavalete.
							lExist := oGrid:SeekLine({;
								{"ZPB_PRODUT", SB8->B8_PRODUTO},;
								{"ZPB_LOCAL",  SB8->B8_LOCAL},;
								{"ZPB_LOTECT", SB8->B8_LOTECTL},;
								{"ZPB_NUMLOT", SB8->B8_NUMLOTE}})

							If lExist
								Loop
							EndIf

							//----------------------------------------------------------
							// Transferência do chapa do bundle para chapa avulsa.
							//----------------------------------------------------------
							If nB8Bundle <> 0 .And. SB8->B8_SALDO == 0

								aLinha := U_ArrTrfBd(cCavalete, SB8->(B8_FILIAL + B8_PRODUTO + B8_LOCAL + B8_LOTECTL + B8_NUMLOTE), .F.)
								aAdd(aParam, aLinha)

							EndIf

							RecLock("SB8", .F.)
							SB8->B8_YCAVALE := ""
							SB8->(MsUnLock())

						EndIf

					EndIf

				Else

					SB8->(DbSetOrder(3))

					If SB8->(DbSeek( xFilial("SB8") + oGrid:GetValue("ZPB_PRODUT") + oGrid:GetValue("ZPB_LOCAL") + oGrid:GetValue("ZPB_LOTECT") + oGrid:GetValue("ZPB_NUMLOT") ))

						//----------------------------------------------------------
						// Transferência do chapa avulsa para o bundle.
						//----------------------------------------------------------
						If nB8Bundle <> 0

							If SB8->B8_SALDO > 0
								aLinha := U_ArrTrfBd(cCavalete, SB8->(B8_FILIAL + B8_PRODUTO + B8_LOCAL + B8_LOTECTL + B8_NUMLOTE), .T.)
								aAdd(aParam, aLinha)
							EndIF

						EndIf

						If !Empty(SB8->(B8_YCAVALE)) .And. cCavalete <> SB8->B8_YCAVALE

							aAreaZPB := ZPB->(GetArea())

							ZPB->(DbSetOrder(3))

							If (ZPB->(DbSeek(xFilial("ZPB") + oGrid:GetValue("ZPB_PRODUT") + oGrid:GetValue("ZPB_LOCAL") + oGrid:GetValue("ZPB_LOTECT") + oGrid:GetValue("ZPB_NUMLOT") )))
								
								cCavalOld := ZPB->ZPB_CAVALE
								
								//Pegando os cavaletes para o sistema recalcular os seus dados do cavalete origem na transferencia.
								If !empty(cCavalOld)
									npos := aScan( aReTrans, { |x| x == cCavalOld } )
									If npos == 0
										aadd(aReTrans,cCavalOld)
									EndIf
								EndIf

								RecLock("ZPB", .F.)
								ZPB->(DbDelete())
								ZPB->(MsUnLock())

							EndIf

							RestArea(aAreaZPB)

						EndIf

						RecLock("SB8", .F.)
						SB8->B8_YCAVALE := cCavalete
						SB8->B8_YENDERE := cEndereco
						SB8->B8_YPESOBR := oGrid:GetValue("ZPB_PESOBR")
						SB8->B8_YPESOLQ := oGrid:GetValue("ZPB_PESOLQ")
						SB8->(MsUnLock())

						nChapas++

						//Ajustado porque o sistema realiza um select na sb8 com base no cavalete e devido a isso a quantidade de chapas ficava errada.
						//Quando retira uma chapa do cavelete o sistema não esta retirando o peso.
						//https://totvsleste.freshdesk.com/a/tickets/2207
						if !(u_GROA006C(cCavalOld, .f., SB8->(B8_FILIAL + B8_PRODUTO + B8_LOCAL + B8_LOTECTL + B8_NUMLOTE), "-", SB8->B8_YPESOLQ, SB8->B8_YPESOBR))
							cMsgErro := "3-GrPlus Error => Montagem/Desmontagem do bundle na SB8."
							ConOut(cMsgErro)
							RollbackSx8()
							DisarmTransaction()
							MsgStop(cMsgErro)
							Return .f.
						endif
						cCavalOld := ""
					EndIf

				EndIf

			Next

			//-----------------------------------------------------------------
			// Atualiza status e quantidade de chapas.
			//-----------------------------------------------------------------
			If !Empty(cStatus)
				cStDisp := SubString(cStatus, 1, 1)
				cStOcup := SubString(cStatus, 3, 1)
			EndIf

			If !Empty(cStatus)
				//Alterado porque o commit e executado primeiro e com isso a alteração não e executada
				//oModel:SetValue("ALIMASTER", "ZG3_STATUS", If(nChapas > 0, cStOcup, cStDisp))
				RecLock("ZG3", .F.)
				ZG3->ZG3_STATUS := If(nChapas > 0, cStOcup, cStDisp)
				ZG3->(MsUnLock())
			EndIf

			//--------------------------------------------------
			// Gera o bundle na tabela SB8.
			//--------------------------------------------------
			If nB8Bundle <> 0
				If !(U_TransfBd(aParam))
					cMsgErro := "4-GrPlus Error => Montagem/Desmontagem do bundle na SB8."
					ConOut(cMsgErro)
					RollbackSx8()
					DisarmTransaction()
					MsgStop(cMsgErro)
					Return .f.
				Else
					//https://totvsleste.freshdesk.com/a/tickets/2078
					//https://totvsleste.freshdesk.com/a/tickets/2171
					//Validação para alterar o peso conforme as chapas,Caso altere somente a ZG3
					If Len(aParam) == 0
						U_ALTPEBD(cCavalete)
					EndIf


				EndIf
			EndIf

		EndIf

	End Transaction

	//Quando realizava transferencia, o sistema não realizava o recalculo
	//do cavalete de origem para tabela ZPB
	for nX := 1 to len(aReTrans)
		if len(aReTrans) == 0
			exit
		EndIf

		cCavTras := aReTrans[1]
		aDel(aReTrans,1)
		ASIZE(aReTrans, len(aReTrans)-1)
		//Rotina que chama o GROA056 alterando para ele refazer os dados do peso
		U_RECPZPB(cCavTras)

	next

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} VldEdicao
Valida ativação do model.
@type Static Function
@author kenny.martins
@since 24/06/2020
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function VldEdicao(oModel)

	Local lReturn    := .T.
	Local nOperation := oModel:GetOperation()
	Local oModelZG3  := oModel:GetModel('ALIMASTER')
	Local oModelZPB  := oModel:GetModel('ALIDETAIL')
	Local oStMaster  := oModelZG3:GetStruct()
	Local cCavalete  := ZG3->ZG3_CODIGO
	Local cMessage   := ""
	Local cSolution  := ""
	Local cSql       := ""
	Local qQuery     := ""
	Local cPedido    := ""
	Local aEditPed   := StrTokArr(GetNewPar("GR_BUNDCPO", ""), ",") // Permite alterar campos do bundle mesmo estando em pedido de venda.
	Local lPE        := ExistBlock("GR056SQL") 


	VldOpen(oModel)

	_lCampos := .T.

	If nOperation == MODEL_OPERATION_INSERT .Or. nOperation == MODEL_OPERATION_UPDATE

		_lConsulta := .T.

	Else

		_lConsulta := .F.

	EndIf

	If nOperation <> MODEL_OPERATION_VIEW .And. nOperation <> MODEL_OPERATION_INSERT

		cSql := "   SELECT COUNT(C6_FILIAL) CONTADOR, C6_NUM "
		cSql += "     FROM " + RetSqlName("SC6") + " SC6 "
		cSql += "    WHERE SC6.C6_FILIAL  = '" + xFilial("SC6") + "' "
		cSql += "      AND SC6.C6_YCAVALE = '" + AllTrim(cCavalete) + "' "
		cSql += "      AND SC6.D_E_L_E_T_ = ''"
		cSql += " GROUP BY C6_NUM "

		If lPE
			cSql :=	ExecBlock("GR056SQL", .F., .F., {cCavalete,cSql})
		EndIf

		TCQUERY cSql NEW ALIAS qQuery

		If qQuery->CONTADOR > 0
			cPedido := qQuery->C6_NUM
		EndIf

		qQuery->(DbCloseArea())

		If !Empty(cPedido) .And. (Len(aEditPed) == 0 .Or. nOperation == MODEL_OPERATION_DELETE)

			cMsgErro  := "Ação não permitida pois o cavalete selecionado já foi informado no pedido de venda " + AllTrim(cPedido) + "!"
			cMessage  := cMsgErro
			cSolution := "Remova o cavalete do pedido de venda para tentar novamente."
			Help(NIL, NIL, "GROA056", NIL, cMessage ,1, 0, NIL, NIL, NIL, NIL, NIL, {cSolution})

			Return .F.

		elseIf  nOperation == MODEL_OPERATION_DELETE

			//------------------------------------------------------
			// Retira o vinculo do cavalete da ZGM e SD3
			//------------------------------------------------------
			u_RETVINC(cCavalete)


		ElseIf !Empty(cPedido) .And. Len(aEditPed) > 0

			MsgInfo("Apenas campos específicos serão habilitados para edição pois o cavalete selecionado já foi informado no pedido de venda " + AllTrim(cPedido) + "!")

			oModelZPB:SetNoDeleteLine(.T.)
			oModelZPB:SetNoInsertLine(.T.)

			_lConsulta := .F.
			_lCampos   := .F.

		EndIf

	EndIf

Return lReturn

//-------------------------------------------------------------------
/*/{Protheus.doc} VldView
Valida ativação da view.
@type Static Function
@author kenny.martins
@since 01/10/2020
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function VldView(oView)

	Local lRet      := .T.
	Local aEditPed  := StrTokArr(GetNewPar("GR_BUNDCPO", ""), ",") // Permite alterar campos do bundle mesmo estando em pedido de venda.
	Local nX        := 0
	Local oStMaster := oView:GetViewStruct("ALIMASTER")

	If !_lCampos

		oStMaster:SetProperty("*", MVC_VIEW_CANCHANGE, .F.)
		For nX := 1 To Len(aEditPed)
			if !Empty(aEditPed[nX]) 
				oStMaster:SetProperty(aEditPed[nX], MVC_VIEW_CANCHANGE, .T.)
			EndIF
		Next

	EndIf

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} VldOpen
Valida ativação do model.
@type Static Function
@author kenny.martins
@since 24/06/2020
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function VldOpen(oModel)

	Local nOperation := oModel:GetOperation()
	Local cCavalete  := ZG3->ZG3_CODIGO
	Local cItem      := "000"
	Local cSql       := ""
	Local qQuery     := ""

	If nOperation <> MODEL_OPERATION_INSERT .AND. !EMPTY(cCavalete)

		//-------------------------------------------------------------------------
		// Rotina de transferencia multipla não retira a ZPB
		// dessa forma se faz necessário deletar antes de abrir a tela.
		//-------------------------------------------------------------------------
		cSql := "    SELECT ZPB.R_E_C_N_O_ AS RECNO "
		cSql += "      FROM " + RetSqlName("ZPB") + " ZPB "
		cSql += " LEFT JOIN " + RetSqlName("SB8") + " SB8 "
		cSql += "        ON SB8.B8_FILIAL = '" + xFilial("SB8") + "' "
		cSql += "       AND ZPB.ZPB_CAVALE <> SB8.B8_YCAVALE "
		cSql += "       AND ZPB.ZPB_PRODUT = SB8.B8_PRODUTO "
		cSql += "       AND ZPB.ZPB_LOCAL  = SB8.B8_LOCAL "
		cSql += "       AND ZPB.ZPB_LOTECT = SB8.B8_LOTECTL "
		cSql += "       AND ZPB.ZPB_NUMLOT = SB8.B8_NUMLOTE "
		cSql += "       AND SB8.D_E_L_E_T_ = '' "

		cSql += "     WHERE ZPB.ZPB_FILIAL  = '" + xFilial("ZPB") + "' "
		cSql += "		AND SB8.B8_ORIGLAN <> 'BD'"
		cSql += "       AND SB8.B8_FILIAL IS NOT NULL "
		cSql += "       AND ZPB.ZPB_CAVALE = '" + AllTrim(cCavalete) + "' "
		cSql += "       AND ZPB.D_E_L_E_T_ = ''"

		TCQUERY cSql NEW ALIAS qQuery

		While qQuery->(!Eof())

			ZPB->(DbGoTo(qQuery->(RECNO)))

			ZPB->(RecLock("ZPB", .F.))
			ZPB->(DbDelete())
			ZPB->(MsUnLock())

			qQuery->(DbSkip())

			_lNewZPB := .T.

		EndDo

		qQuery->(DbCloseArea())


		//-------------------------------------------------------------------------
		// Outras rotinas de montagem de cavalete não populam a tabela ZPB dessa
		// forma se faz necessário vericar e popular antes de abrir a tela.
		//-------------------------------------------------------------------------
		cSql := "    SELECT SB8.* "
		cSql += "      FROM " + RetSqlName("SB8") + " SB8 "
		cSql += " LEFT JOIN " + RetSqlName("ZPB") + " ZPB "
		cSql += "        ON ZPB.ZPB_FILIAL = '" + xFilial("ZPB") + "' "
		cSql += "       AND ZPB.ZPB_CAVALE = SB8.B8_YCAVALE "

		//Ajuste Ticket 2207: quando existia uma chapa ja incluida no cavalete e incluia outra pelo manutenção bloco e chapa o sistema não criava a nova ZPB.
		cSql += "       AND ZPB.ZPB_PRODUT = SB8.B8_PRODUTO "
		cSql += "       AND ZPB.ZPB_LOCAL = SB8.B8_LOCAL "
		cSql += "       AND ZPB.ZPB_LOTECT = SB8.B8_LOTECTL "
		cSql += "       AND ZPB.ZPB_NUMLOT = SB8.B8_NUMLOTE "

		cSql += "       AND ZPB.D_E_L_E_T_ = ''"
		cSql += "     WHERE SB8.B8_FILIAL  = '" + xFilial("SB8") + "' "
		cSql += "       AND SB8.B8_YCAVALE = '" + AllTrim(cCavalete) + "' "
		cSql += "       AND SB8.D_E_L_E_T_ = ''"
		cSql += "		AND SB8.B8_ORIGLAN <> 'BD'"
		cSql += "       AND ZPB.ZPB_FILIAL IS NULL "
		cSql += "  ORDER BY SB8.B8_FILIAL, SB8.B8_PRODUTO, SB8.B8_LOCAL, SB8.B8_LOTECTL, SB8.B8_NUMLOTE "

		TCQUERY cSql NEW ALIAS qQuery

		While qQuery->(!Eof())

			cItem := Soma1(cItem)

			ZPB->(DbSetOrder(1))
			While ZPB->(DBseek(xFilial("ZPB") + cCavalete + cItem))
				cItem := Soma1(cItem)
			EndDo

			RecLock("ZPB", .T.)
			ZPB->ZPB_FILIAL := xFilial("ZPB")
			ZPB->ZPB_CAVALE := cCavalete
			ZPB->ZPB_ITEM   := cItem
			ZPB->ZPB_PRODUT := qQuery->B8_PRODUTO
			ZPB->ZPB_DESCRI := Posicione("SB1", 1, xFilial("SB1") + qQuery->B8_PRODUTO, "B1_DESC")
			ZPB->ZPB_LOCAL  := qQuery->B8_LOCAL
			ZPB->ZPB_LOTECT := qQuery->B8_LOTECTL
			ZPB->ZPB_NUMLOT := qQuery->B8_NUMLOTE
			ZPB->ZPB_CLASSI := qQuery->B8_YCLASSI
			ZPB->ZPB_CLAPRO := qQuery->B8_YCLAPRO
			ZPB->ZPB_COMLIQ := qQuery->B8_YCOMLIQ
			ZPB->ZPB_ALTLIQ := qQuery->B8_YALTLIQ
			ZPB->ZPB_ESPLIQ := qQuery->B8_YESPLIQ
			ZPB->ZPB_TOTLIQ := qQuery->B8_YTOTLIQ
			ZPB->ZPB_COMBRU := qQuery->B8_YCOMBRU
			ZPB->ZPB_ALTBRU := qQuery->B8_YALTBRU
			ZPB->ZPB_ESPBRU := qQuery->B8_YESPBRU
			ZPB->ZPB_TOTBRU := qQuery->B8_YTOTBRU
			ZPB->ZPB_PESOBR := qQuery->B8_YPESOBR
			ZPB->ZPB_PESOLQ := qQuery->B8_YPESOLQ
			ZPB->(MsUnLock())

			qQuery->(DbSkip())

			_lNewZPB := .T.

		EndDo

		qQuery->(DbCloseArea())

	EndIf

Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} GRA056V1
Ajuste devido a possibilidade do usuário incluir uma chapa via manutenção bloco e chapa e quando ele 
entra na rotina de cavalete o sistema cria a chapa ZPB mas não ajustava os pesos. 
Incluido variavel private devido a rotina sendo chamada varias vezes e apresentava erro quando incluida no activate
@type Static Function
@author Pedro Luiz
@since 28/05/2021
@version 1.0
/*/
//-------------------------------------------------------------------
static function postes(oModel)

	Local nOperation := oModel:GetOperation()
	Local lRet := .T.

	//Ajuste, quando vai deletar o sistema não  precisa recalcular.
	If nOperation == MODEL_OPERATION_UPDATE
		If _lNewZPB
			_lNewZPB := .F.
			u_GRA056V1(,,_lNewZPB)
		EndIF
	EndIf

return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} GRA056V1
Valida ativação do model.
@type Static Function
@author kenny.martins
@since 24/06/2020
@version 1.0
/*/
//-------------------------------------------------------------------
User Function GRA056V1(nRetCal,cOperac,lRefView)

	Local lRet      := .T.
	Local oView     := FWViewActive()
	Local oModel    := FWModelActive()
	Local oModelZG3 := oModel:GetModel('ALIMASTER')
	Local oModelZPB := oModel:GetModel('ALIDETAIL')
	Local nPesoCha  := GetNewPar("GR_PESOCHA", 0) // Atualiza peso da chapa pela divisão do peso do cavalete.
	Local lAtuaZG3  := GetNewPar("GR_ATUAZG3", .T.) // Atualiza o peso do Cavalete conforme seleção de chapas
	Local nX        := 0
	Local nMetroTot := 0
	Local nMetrBrTo := 0
	Local nQuantCh  := 0
	Local nContador := 0
	Local nSaldoBru := 0
	Local nSaldoLiq := 0
	Local nPesoBru  := 0
	Local nPesoLiq  := 0
	Local nUnidBru  := 0
	Local nUnidLiq  := 0
	Local nMediBru  := 0
	Local nMediLiq  := 0

	Default nRetCal  := 0
	Default COPERAC  := ""
	Default lRefView := .T.

	//------------------------------------------------------------------------------------
	// O parâmetro GR_PESOCHA foi criado inicialmente para ser boolean,
	// porém foi alterado para numérico para incluir nova opção de cálculo
	// onde 0 = Não calcula, 1 = Calcula por igual, 2 = Calcula proporcional
	//------------------------------------------------------------------------------------
	If ValType(nPesoCha) == "L"
		nPesoCha := if(nPesoCha, 1, 0)
	EndIf

	If nPesoCha == 1 .Or. nPesoCha == 2

		For nX := 1 to oModelZPB:Length()

			oModelZPB:GoLine(nX)

			//Realiza a rotina no padrão
			If empty(cOperac)  .And. oModelZPB:IsDeleted() .OR. Empty(oModelZPB:GetValue("ZPB_PRODUT"))
				Loop
			elseif   cOperac == 'DELETE' .And. ( (nRetCal == nX .And. cOperac == 'DELETE') .Or. (nRetCal <> nX .And. oModelZPB:IsDeleted()))
				//quando deleta na tela o registro não esta deletado dentro do posline
				Loop
			elseif cOperac == 'UNDELETE' .And. (nRetCal <> nX .And. oModelZPB:IsDeleted())
				//Quando volta a chapa que foi deletada no grid
				Loop
			EndIf

			nMediBru  += oModelZPB:GetValue("ZPB_TOTBRU")
			nMediLiq  += oModelZPB:GetValue("ZPB_TOTLIQ")

			nQuantCh++

			//------------------------------------------------------------------------------------
			// Caso o calculo seja 2 (proporcional) soma o total em metros de chapa.
			//------------------------------------------------------------------------------------
			If nPesoCha == 2
				nMetrBrTo += oModelZPB:GetValue("ZPB_TOTBRU")
				nMetroTot += oModelZPB:GetValue("ZPB_TOTLIQ")

			EndIf

		Next
		
		iF ZG3->(FieldPos("ZG3_TOTBRU")) > 0
			oModelZG3:SetValue("ZG3_TOTBRU", nMediBru)
			oModelZG3:SetValue("ZG3_TOTLIQ", nMediLiq)
		EndIF

		oModelZG3:SetValue("ZG3_QCHAPA", nQuantCh)

		If oModelZG3:GetValue("ZG3_PESOLQ") > 0

			nPesoBru  := oModelZG3:GetValue("ZG3_PESOBR")
			nPesoLiq  := oModelZG3:GetValue("ZG3_PESOLQ")

			nSaldoBru := nPesoBru
			nSaldoLiq := nPesoLiq

			For nX := 1 to oModelZPB:Length()

				oModelZPB:GoLine(nX)

				//Realiza a rotina no padrão
				If empty(cOperac)  .And. oModelZPB:IsDeleted() .OR. Empty(oModelZPB:GetValue("ZPB_PRODUT"))
					Loop
				elseif   cOperac == 'DELETE' .And. ( (nRetCal == nX .And. cOperac == 'DELETE') .Or. (nRetCal <> nX .And. oModelZPB:IsDeleted()))
					//quando deleta na tela o registro não esta deletado dentro do posline
					Loop
				elseif cOperac == 'UNDELETE' .And. (nRetCal <> nX .And. oModelZPB:IsDeleted())
					//Quando volta a chapa que foi deletada no grid
					Loop
				EndIf

				If nPesoCha == 1 // 1 = Calcula por igual
					nContador++
					If nContador == nQuantCh
						oModelZPB:SetValue("ZPB_PESOBR", nSaldoBru)
						if ! oModelZPB:SetValue("ZPB_PESOLQ", nSaldoLiq)
							//quando retorna a chapa o setValue não funciona porque a chapa não esta completamente deletada no posline
							oModelZPB:LoadValue("ZPB_PESOBR", nSaldoBru)
							oModelZPB:LoadValue("ZPB_PESOLQ", nSaldoLiq)
						EndIF
					Else
						nSaldoBru -= Round(nPesoBru / nQuantCh, TamSx3("ZPB_PESOBR")[2])
						nSaldoLiq -= Round(nPesoLiq / nQuantCh, TamSx3("ZPB_PESOLQ")[2])
						oModelZPB:SetValue("ZPB_PESOBR", Round(nPesoBru / nQuantCh, TamSx3("ZPB_PESOBR")[2]))
						if ! oModelZPB:SetValue("ZPB_PESOLQ", Round(nPesoLiq / nQuantCh, TamSx3("ZPB_PESOLQ")[2]))
							//quando retorna a chapa o setValue não funciona porque a chapa não esta completamente deletada no posline
							oModelZPB:LoadValue("ZPB_PESOBR", Round(nPesoBru / nQuantCh, TamSx3("ZPB_PESOBR")[2]))
							oModelZPB:LoadValue("ZPB_PESOLQ", Round(nPesoLiq / nQuantCh, TamSx3("ZPB_PESOLQ")[2]))

						EndIF
					EndIf
				ElseIf nPesoCha == 2 // 1 = Calcula proporcional
					nContador++
					If nContador == nQuantCh
						oModelZPB:SetValue("ZPB_PESOBR", nSaldoBru)
						If ! oModelZPB:SetValue("ZPB_PESOLQ", nSaldoLiq)
							//quando retorna a chapa o setValue não funciona porque a chapa não esta completamente deletada no posline
							oModelZPB:LoadValue("ZPB_PESOBR", nSaldoBru)
							oModelZPB:LoadValue("ZPB_PESOLQ", nSaldoLiq)
						EndIF
					Else
						nUnidBru := nPesoBru / nMetrBrTo
						nUnidLiq := nPesoLiq / nMetroTot
						nSaldoBru -= Round(nUnidBru * oModelZPB:GetValue("ZPB_TOTBRU"), TamSx3("ZPB_PESOBR")[2])
						nSaldoLiq -= Round(nUnidLiq * oModelZPB:GetValue("ZPB_TOTLIQ"), TamSx3("ZPB_PESOLQ")[2])
						oModelZPB:SetValue("ZPB_PESOBR", Round(nUnidBru * oModelZPB:GetValue("ZPB_TOTBRU"), TamSx3("ZPB_PESOBR")[2]))
						if ! oModelZPB:SetValue("ZPB_PESOLQ", Round(nUnidLiq * oModelZPB:GetValue("ZPB_TOTLIQ"), TamSx3("ZPB_PESOLQ")[2]))
							//quando retorna a chapa o setValue não funciona porque a chapa não esta completamente deletada no posline
							oModelZPB:LoadValue("ZPB_PESOBR", Round(nUnidBru * oModelZPB:GetValue("ZPB_TOTBRU"), TamSx3("ZPB_PESOBR")[2]))
							oModelZPB:LoadValue("ZPB_PESOLQ", Round(nUnidLiq * oModelZPB:GetValue("ZPB_TOTLIQ"), TamSx3("ZPB_PESOLQ")[2]))
						EndIF
					EndIf
				EndIf

			Next

		Else

			nPesoBru  := 0
			nPesoLiq  := 0
			nQuantCh  := 0
			nMediBru  := 0
			nMediLiq  := 0

			For nX := 1 to oModelZPB:Length()

				oModelZPB:GoLine(nX)

				//Realiza a rotina no padrão
				If empty(cOperac)  .And. oModelZPB:IsDeleted() .OR. Empty(oModelZPB:GetValue("ZPB_PRODUT"))
					Loop
				elseif   cOperac == 'DELETE' .And. ( (nRetCal == nX .And. cOperac == 'DELETE') .Or. (nRetCal <> nX .And. oModelZPB:IsDeleted()))
					//quando deleta na tela o registro não esta deletado dentro do posline
					Loop
				elseif cOperac == 'UNDELETE' .And. (nRetCal <> nX .And. oModelZPB:IsDeleted())
					//Quando volta a chapa que foi deletada no grid
					Loop
				EndIf

				nPesoBru += oModelZPB:GetValue("ZPB_PESOBR")
				nPesoLiq += oModelZPB:GetValue("ZPB_PESOLQ")
				nMediLiq += oModelZPB:GetValue("ZPB_TOTLIQ")
				nMediBru += oModelZPB:GetValue("ZPB_TOTBRU")
				nQuantCh++

				if !lAtuaZG3
					oModelZPB:SetValue("ZPB_PESOBR",0)
					if ! oModelZPB:SetValue("ZPB_PESOLQ", 0)
						//quando retorna a chapa o setValue não funciona porque a chapa não esta completamente deletada no posline
						oModelZPB:LoadValue("ZPB_PESOBR", 0)
						oModelZPB:LoadValue("ZPB_PESOLQ", 0)
					EndIF
				EndIf

			Next

			if lAtuaZG3
				oModelZG3:SetValue("ZG3_PESOLQ", nPesoLiq)
				oModelZG3:SetValue("ZG3_PESOBR", nPesoBru)
			EndIf

			iF ZG3->(FieldPos("ZG3_TOTBRU")) > 0
				oModelZG3:SetValue("ZG3_TOTBRU", nMediBru)
				oModelZG3:SetValue("ZG3_TOTLIQ", nMediLiq)
			EndIF

			oModelZG3:SetValue("ZG3_QCHAPA", nQuantCh)

		EndIf

	EndIf

	if(nRetCal > 0 )
		//Incluido validação, o grid ficava com incosistencias quando deletava e posicionava no primeiro registro
		oModelZPB:GoLine(nRetCal)
		//Chamando a rotina pela activate o view não esta montado
		If lRefView
			oView:Refresh("VIEW_DETAIL")
		EndIf

	else
		If lRefView
			//Chamando a rotina como execauto o view não e criado
			oModelZPB:GoLine(1)
			oView:Refresh("VIEW_MASTER")
			oView:Refresh("VIEW_DETAIL")
		EndIf
	EndIF

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} PosLine
Após edição da linha atualização as quantidades e pesos.
@type Static Function
@author kenny.martins
@since 24/06/2020
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function PosLine(oModelZPB, nLine, cOperation)

	Local lRet      := .T.
	Local oView     := FWViewActive()
	Local oMaster   := FWModelActive()
	Local oModelZG3 := oMaster:GetModel("ALIMASTER")
	Local lAtuaZG3  := GetNewPar("GR_ATUAZG3", .T.) // Atualiza o peso do Cavalete conforme seleção de chapas
	Local nPosicao := oModelZPB:GetLine()

	If cOperation == "DELETE" .And. !Empty(oModelZPB:GetValue("ZPB_PRODUT", nLine))

		oModelZG3:LoadValue("ZG3_QCHAPA", oModelZG3:GetValue("ZG3_QCHAPA") - 1)

		If lAtuaZG3
			oModelZG3:LoadValue("ZG3_PESOBR", oModelZG3:GetValue("ZG3_PESOBR") - oModelZPB:GetValue("ZPB_PESOBR", nLine))
			oModelZG3:LoadValue("ZG3_PESOLQ", oModelZG3:GetValue("ZG3_PESOLQ") - oModelZPB:GetValue("ZPB_PESOLQ", nLine))
		EndIf

		If ZG3->(FieldPos("ZG3_TOTBRU")) > 0
			oModelZG3:LoadValue("ZG3_TOTBRU", oModelZG3:GetValue("ZG3_TOTBRU") - oModelZPB:GetValue("ZPB_TOTBRU", nLine))
			oModelZG3:LoadValue("ZG3_TOTLIQ", oModelZG3:GetValue("ZG3_TOTLIQ") - oModelZPB:GetValue("ZPB_TOTLIQ", nLine))
		EndIF

	ElseIf cOperation <> "SETVALUE" .And. !Empty(oModelZPB:GetValue("ZPB_PRODUT", nLine))

		oModelZG3:LoadValue("ZG3_QCHAPA", oModelZG3:GetValue("ZG3_QCHAPA") + 1)

		If lAtuaZG3
			oModelZG3:LoadValue("ZG3_PESOBR", oModelZG3:GetValue("ZG3_PESOBR") + oModelZPB:GetValue("ZPB_PESOBR", nLine))
			oModelZG3:LoadValue("ZG3_PESOLQ", oModelZG3:GetValue("ZG3_PESOLQ") + oModelZPB:GetValue("ZPB_PESOLQ", nLine))
		EndIf

		If ZG3->(FieldPos("ZG3_TOTBRU")) > 0
			oModelZG3:LoadValue("ZG3_TOTBRU", oModelZG3:GetValue("ZG3_TOTBRU") + oModelZPB:GetValue("ZPB_TOTBRU", nLine))
			oModelZG3:LoadValue("ZG3_TOTLIQ", oModelZG3:GetValue("ZG3_TOTLIQ") + oModelZPB:GetValue("ZPB_TOTLIQ", nLine))
		EndIF

	EndIf

	//Quando o peso do cavalete e mais importante que o peso da chapa.
	//O sistema precisa rodar a rotina para recalcular conforme a configuração (GR_PESOCHA)
	If !lAtuaZG3

		if  cOperation == "DELETE"
			u_GRA056V1(nPosicao,"DELETE")
		elseIf cOperation == "UNDELETE"
			u_GRA056V1(nPosicao,"UNDELETE")
		EndIf

	EndIf

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} ALTPEBD
Ajustando o peso do BD gerado conforme as SB8.
Estava dando problema quando tinha um BD com mais de um lote e quando alterava somente a ZG3
@type Static Function
@author Pedro Luiz
@since 22/04/2021
@version 1.0
/*/
//Ajuste para alterar o peso na SB8
//https://totvsleste.freshdesk.com/a/tickets/2171
//-------------------------------------------------------------------

User function ALTPEBD(cCavale)

	Local qSQuery	  := ""
	Local cSql   	  := ""

	Default cCavale   :=""

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
	cSql += "      AND SB8.D_E_L_E_T_ = ''"
	cSql += " GROUP BY B8_FILIAL,  "
	cSql += "          B8_PRODUTO, "
	cSql += "          B8_LOCAL,   "
	cSql += "          B8_YNUMBD,  "
	cSql += "          B8_YSEQBD   "

	TCQUERY cSql NEW ALIAS qQUERY

	While qQuery->(!Eof())

		SB8->(DbSetOrder(3))

		If SB8->(DbSeek(xFilial("SB8") + qQuery->(B8_PRODUTO + B8_LOCAL + B8_YNUMBD + B8_YSEQBD)))

			RecLock("SB8", .F.)
			SB8->B8_YQTDBD  := qQuery->B8_FILIAL
			SB8->B8_YPESOLQ := qQuery->B8_YPESOLQ
			SB8->B8_YPESOBR := qQuery->B8_YPESOBR
			SB8->(MsUnLock())

		EndIf

		qQuery->(DbSkip())

	EndDo

	qQUERY->(DbCloseArea())

Return


/*/{Protheus.doc} User Function RETVINC
	(long_description)
	Rotina para retirar o vinculo de integridade entre o cavalete e a SD3 que foi estornada. 
	@type  Function
	@author Pedro Luiz
	@since 31/05/2021
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
	/*/
User Function RETVINC(cCavalete)

	Local lRet    := .T.
	Local cSql 	  := ""
	Local qQueEST := ""
	Local nQtdEst := 0
	Local nrecSD3  := ""
	Local nrecZGM  := ""

	//Query para pegar as SD3 e ZGM que foi estornada.
	cSql := "   SELECT  SD3.R_E_C_N_O_ AS RECNOSD3,ZGM.R_E_C_N_O_ AS RECNOZGM"
	cSql += "     FROM " + RetSqlName("SD3") + " SD3 "
	cSql += "     LEFT JOIN  " + RetSqlName("ZGM") + " ZGM "
	cSql += "      ON ZGM.ZGM_FILIAL  = '" + xFilial("ZGM") + "' "
	cSql += "      AND ZGM.ZGM_PRODUT=SD3.D3_COD"
	cSql += "      AND ZGM.ZGM_LOTECT  = SD3.D3_LOTECTL "
	cSql += "      AND ZGM.ZGM_NUMLOT  = SD3.D3_NUMLOTE"
	cSql += "      AND ZGM.D_E_L_E_T_  = ''"
	cSql += "    WHERE SD3.D3_FILIAL   = '" + xFilial("SD3") + "' "
	cSql += "      AND SD3.D3_YCAVALE = '" + AllTrim(cCavalete) + "' "
	//cSql += "      AND SD3.D3_ESTORNO  = 'S'"
	cSql += "      AND SD3.D_E_L_E_T_  = ''"

	TCQUERY cSql NEW ALIAS qQueEST

	While qQueEST->(!Eof())
		nQtdEst ++
		nrecSD3  += If(empty(nrecSD3),cvaltochar(qQueEST->(RECNOSD3)),','+cvaltochar(qQueEST->(RECNOSD3)))
		nrecZGM  += If(empty(nrecZGM),cvaltochar(qQueEST->(RECNOZGM)),','+cvaltochar(qQueEST->(RECNOZGM)))
		qQueEST->(DbSkip())

	EndDo

	qQueEST->(DbCloseArea())

	//Caso exista vinculo com SD3 que foi estornada .
	If(nQtdEst >0)

		if MsgNoYes( "Existe " + cvaltochar(nQtdEst) + " vinculos na SD3 e ZGM. Deseja retirar o vinculo para excluir o cavalete?" + CRLF )

			//Retirando vinculo com ZGM
			cSql := "     UPDATE " + RetSqlName("ZGM") + Chr(10)
			cSql += "        SET ZGM_CAVALE='' "
			cSql += "      WHERE ZGM_FILIAL  = '" + xFilial("ZGM") + "' " + Chr(10)
			cSql += "        AND R_E_C_N_O_ IN (" + nrecZGM + ") " + Chr(10)
			cSql += "        AND ZGM_CAVALE = '" +AllTrim(cCavalete)+"'"+ Chr(10)
			cSql += "        AND D_E_L_E_T_ = '' " + Chr(10)

			nStatus := TCSqlExec(cSql)

			If (nStatus < 0)
				ConOut("ZGM - Excluir CAVALETE - TCSQLError() " + TCSQLError())
			Else
				//Retirando vinculo com SD3
				cSql := "     UPDATE " + RetSqlName("SD3") + Chr(10)
				cSql += "        SET D3_OBSERVA = D3_YCAVALE +'-'+D3_OBSERVA, D3_YCAVALE='' "
				cSql += "      WHERE D3_FILIAL  = '" + xFilial("SD3") + "' " + Chr(10)
				cSql += "        AND R_E_C_N_O_ IN (" + nrecSD3 + ") " + Chr(10)
				cSql += "        AND D3_YCAVALE = '" +AllTrim(cCavalete)+"'"+ Chr(10)
				cSql += "        AND D_E_L_E_T_ = '' " + Chr(10)

				nStatus := TCSqlExec(cSql)

				If (nStatus < 0)
					ConOut("SD3 - Excluir CAVALETE-TCSQLError() " + TCSQLError())
				EndIf
			EndIf

		EndIf

	EndIf

Return lRet


User Function CHAMA056()
	ModelDef()
Return 

