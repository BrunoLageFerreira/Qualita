#INCLUDE "protheus.CH"
#INCLUDE "FWMVCDEF.CH"
#Include "Parmtype.ch"
#INCLUDE "TOTVS.CH"
#INCLUDE "FWEditPanel.CH"
#INCLUDE "TOPCONN.CH"

// //Variáveis Estáticas
Static cTitulo   := "Apontamento de Insumos"
Static cTiposZHL := U_HABZGH() // Variavel para apresentar os produtos acabados e a aba de produtos acabado no apontamento

Static lIncluiOp := SuperGetMv("GR_INCAPON",.F.,.F.) .and. !IsBlind()

/*/{Protheus.doc} GROA045
APONTAMENTO DE INSUMOS
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
User Function GROA045()

	Local aArea   := GetArea()
	Local oBrowse

	Local __cChave := STRTRAN(TIME(), ":", "") + GETHARDWAREID() + DTOS(DATE())
	If __cChave <> U_TOTVSES(SubString(__cChave,1,6))
		Return Nil
	EndIf

	Private __lUtiBrow := .t.
	private __cRotUtil := "" //Necessario porque o funname estava apresentando somente RPC quando utilizado via rest
	Private __cProcess := ""

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("ZH7")
	oBrowse:SetDescription(cTitulo)
	oBrowse:SetCacheView(.F.)
	oBrowse:SetFilterDefault("ZH7->ZH7_TIPOOP == 'F'")
	oBrowse:Activate()

	RestArea(aArea)

Return
/*/{Protheus.doc} MenuDef
APONTAMENTO DE PRODUÇÃO
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

Static Function MenuDef()

	Local aRot     := {}
	Local lOpcReap := SuperGetMv("GR_REAPON",.F.,.F.) //Parametro criadao para o usuário conseguir reapontar o processo. Isso foi necessário porque na thor eles criaram os apontamentos e as horas ficaram erradas. com isso foi necessário realizar um ajuste de todas as ops do mes.

	If lIncluiOp
		aAdd(aRot, {'Incluir',     'VIEWDEF.GROA045', 0, 3, 0, Nil})
	EndIf

	aAdd(aRot, {'Apontamento', 'VIEWDEF.GROA045', 0, 4, 0, Nil})
	aAdd(aRot, {'Visualizar',  'VIEWDEF.GROA045', 0, 1, 0, Nil})
	aAdd(aRot, {'Pesquisar',   'VIEWDEF.GROA045', 0, 1, 0, Nil})

	IF lOpcReap
		aAdd(aRot, {'Reapontamento especifico', 'U_REFAPONT()', 0, 4, 0, Nil})
	EndIf

	If ExistBlock("GR045MEN")
		aRot := ExecBlock("GR045MEN", .f., .f., aRot  )
	EndIf

Return aRot

/*/{Protheus.doc} ModelDef
APONTAMENTO DE PRODUÇÃO
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
Static Function ModelDef()

	//Criação do objeto do modelo de dados
	Local oModel  := Nil

	//Criação da estrutura de dados utilizada na interface
	Local oStZH7  := FWFormStruct(1, 'ZH7') // Ordem de Produção
	Local oStZGH  := FWFormStruct(1, 'ZGH') // Operação

	Local oStZHL  := FWFormStruct(1, 'ZHL') // Operação x Produto Acabado
	Local oStZGI  := FWFormStruct(1, 'ZGI') // Operação x Insumos
	Local oStMOD  := FWFormStruct(1, 'ZGI') // Operação x MOD
	Local oStZGK  := FWFormStruct(1, 'ZGK') // Operação x Mão de Obra
	Local oStZGL  := FWFormStruct(1, 'ZGL') // Operação x Ferramenta
	Local oStSH6  := FWFormStruct(1, 'SH6') // Hora Improdutiva
	Local oStZS3  := FWFormStruct(1, 'ZS3') // Conferência do Corte
	Local oStZS7  := FWFormStruct(1, 'ZS7') // Fio/Lâmina do Corte

	Local oStZH8  := Nil
	Local oStZH9  := Nil

	Local cQuery  := ""
	Local aAuxGat := {}
	Local aTipo   := {}

	Local aCampZGK := {}

	if lIncluiOp
		oStZH8  := FWFormStruct(1, 'ZH8') // Materia prima
		oStZH9  := FWFormStruct(1, 'ZH9') // Produto acabado

		oStZH9:AddField( 'SubLote Inicial'  ,'SubLote Inicial' , 'ZH9_SUBINI'     , 'C' ,TamSX3("ZH9_NUMLOT")[1])

		oStZH8:AddField( 'Compl.Lote'  ,'Compl.Lote' , 'ZH8_COMPLE'     , 'C' ,TamSX3("C2_YCOMPLE")[1])
		oStZH8:AddField( 'Com.Liq.Entera'  ,'Com.Liq.Entera' , 'ZH8_COMITL'     , 'N' ,TamSX3("C2_YCOMITL")[1],TamSX3("C2_YCOMITL")[2])
		oStZH8:AddField( 'Alt.Liq.Entera'  ,'Alt.Liq.Entera' , 'ZH8_ALTITL'     , 'N' ,TamSX3("C2_YALTITL")[1],TamSX3("C2_YALTITL")[2])
		oStZH8:AddField( 'Esp.Liq.Entera'  ,'Esp.Liq.Entera' , 'ZH8_ESPITL'     , 'N' ,TamSX3("C2_YESPITL")[1],TamSX3("C2_YESPITL")[2])
		oStZH8:AddField( 'Com.Bru.Entera'  ,'Com.Bru.Entera' , 'ZH8_COMITB'     , 'N' ,TamSX3("C2_YCOMITB")[1],TamSX3("C2_YCOMITB")[2])
		oStZH8:AddField( 'Alt.Bru.Entera'  ,'Alt.Bru.Entera' , 'ZH8_ALTITB'     , 'N' ,TamSX3("C2_YALTITB")[1],TamSX3("C2_YALTITB")[2])
		oStZH8:AddField( 'Esp.Bru.Entera'  ,'Esp.Bru.Entera' , 'ZH8_ESPITB'     , 'N' ,TamSX3("C2_YESPITB")[1],TamSX3("C2_YESPITB")[2])

	EndIf

	// Inclui campo checkbox
	// oStZHL:DeActivate()
	// oStZHL:AddField('SELECT', ' ', 'SELECT', 'L', 1, 0, , , {}, .F.,FWBuildFeature( STRUCT_FEATURE_INIPAD, ".F."))
	// oStZHL:Activate()

	SX3->(DbSetOrder(2))
	SX3->(DbSeek("H6_TIPO"))

	aTipo := aClone(oStSH6:AFIELDS[1])
	aTipo[1] := AllTrim(SX3->X3_TITULO)
	aTipo[2] := AllTrim(SX3->X3_DESCRIC)
	aTipo[3] := AllTrim(SX3->X3_CAMPO)
	aTipo[4] := AllTrim(SX3->X3_TIPO)
	aTipo[5] := SX3->X3_TAMANHO

	aAdd(oStSH6:AFIELDS, aTipo)

	aAuxGat := FwStruTrigger("ZH7_RECURS","ZH7_DESCRE","POSICIONE('SH1', 1, XFILIAL('SH1') + FWFLDGET('ZH7_RECURS'), 'H1_DESCRI')",.F.,Nil,Nil,Nil)
	oStZH7:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])

	aAuxGat := FwStruTrigger("ZH7_CODMOT", "ZH7_DESMOT", 'POSICIONE("ZH6", 1, XFILIAL("ZH6") + M->ZH7_CODMOT, "ZH6_DESCRI")',.F.,NIL,NIL,NIL)
	oStZH7:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])

	if lIncluiOp
		// Inicializador de campos
		if type("__cProcess") == "C"
			oStZH7:SetProperty('ZH7_PROCES', MODEL_FIELD_INIT, FwBuildFeature(STRUCT_FEATURE_INIPAD, '__cProcess'))
		EndIf

	EndIf

	oModel := MPFormModel():New('UGROA045',U_GRPRE045()/*bPre*/ ,/*bPos*/,{|oModel| Grava(oModel)},/*bCancel*/)

	//Atribuindo formulários para o modelo
	oModel:AddFields('ZH7MASTER',/*cOwner*/,oStZH7)

	//Atribuindo Grid ao modelo
	oModel:AddGrid('ZGHDETAIL', 'ZH7MASTER', oStZGH, {|oModel, nLine, cOperation| PosLine(oModel, nLine, cOperation)})
	oModel:AddGrid('SH6DETAIL', 'ZH7MASTER', oStSH6, {|oModel, nLine, cOperation| PosLine(oModel, nLine, cOperation)})
	oModel:AddGrid('ZS3DETAIL', 'ZH7MASTER', oStZS3, {|oModel, nLine, cOperation| PosLine(oModel, nLine, cOperation)})

	oModel:AddGrid('ZS7DETAIL', 'ZGHDETAIL', oStZS7, {|oModel, nLine, cOperation| PosLine(oModel, nLine, cOperation)})
	oModel:AddGrid('ZHLDETAIL', 'ZGHDETAIL', oStZHL, {|oModel, nLine, cOperation| PosLine(oModel, nLine, cOperation)})
	oModel:AddGrid('ZGIDETAIL', 'ZGHDETAIL', oStZGI, {|oModel, nLine, cOperation| PosLine(oModel, nLine, cOperation)})
	oModel:AddGrid('MODDETAIL', 'ZGHDETAIL', oStMOD, {|oModel, nLine, cOperation| PosLine(oModel, nLine, cOperation)})
	oModel:AddGrid('ZGKDETAIL', 'ZGHDETAIL', oStZGK, {|oModel, nLine, cOperation| PosLine(oModel, nLine, cOperation)})
	oModel:AddGrid('ZGLDETAIL', 'ZGHDETAIL', oStZGL, {|oModel, nLine, cOperation| PosLine(oModel, nLine, cOperation)})

	if lIncluiOp
		oModel:AddGrid('ZH8DETAIL', 'ZH7MASTER', oStZH8, {|oModel, nLine, cOperation| PosLine(oModel, nLine, cOperation)})
		oModel:AddGrid('ZH9DETAIL', 'ZH7MASTER', oStZH9, {|oModel, nLine, cOperation| PosLine(oModel, nLine, cOperation)})
	EndIf

	//------------------------------------------------
	// Gatilho tabela ZGH - OPERAÇÃO
	//------------------------------------------------
	aAuxGat := FwStruTrigger("ZGH_OPERAC","ZGH_DESCRI","POSICIONE('ZG6', 1, XFILIAL('ZG6') + FWFLDGET('ZGH_OPERAC'), 'ZG6_DESCRI')",.F.,Nil,Nil,Nil)
	oStZGH:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZGH_OPERAC","ZGH_OPERAC","U_GRCZHL()",.F.,Nil,Nil,Nil)
	oStZGH:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZGH_DATINI","ZGH_TOTHRA",;
		"If(EMPTY(FWFldGet('ZGH_DATINI')) .OR. EMPTY(FWFldGet('ZGH_HORINI')) .OR. EMPTY(FWFldGet('ZGH_DATFIM')) .OR. EMPTY(FWFldGet('ZGH_HORFIM')), ' '," +;
		"U_GA680Cal(FWFldGet('ZGH_RECURS'),FWFldGet('ZGH_DATINI'),FWFldGet('ZGH_HORINI'),FWFldGet('ZGH_DATFIM'),FWFldGet('ZGH_HORFIM')))",.F.,Nil,Nil,Nil)
	oStZGH:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZGH_HORINI","ZGH_TOTHRA",;
		"If(EMPTY(FWFldGet('ZGH_DATINI')) .OR. EMPTY(FWFldGet('ZGH_HORINI')) .OR. EMPTY(FWFldGet('ZGH_DATFIM')) .OR. EMPTY(FWFldGet('ZGH_HORFIM')), ' '," +;
		"U_GA680Cal(FWFldGet('ZGH_RECURS'),FWFldGet('ZGH_DATINI'),FWFldGet('ZGH_HORINI'),FWFldGet('ZGH_DATFIM'),FWFldGet('ZGH_HORFIM')))",.F.,Nil,Nil,Nil)
	oStZGH:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZGH_DATFIM","ZGH_TOTHRA",;
		"If(EMPTY(FWFldGet('ZGH_DATINI')) .OR. EMPTY(FWFldGet('ZGH_HORINI')) .OR. EMPTY(FWFldGet('ZGH_DATFIM')) .OR. EMPTY(FWFldGet('ZGH_HORFIM')), ' '," +;
		"U_GA680Cal(FWFldGet('ZGH_RECURS'),FWFldGet('ZGH_DATINI'),FWFldGet('ZGH_HORINI'),FWFldGet('ZGH_DATFIM'),FWFldGet('ZGH_HORFIM')))",.F.,Nil,Nil,Nil)
	oStZGH:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZGH_HORFIM","ZGH_TOTHRA",;
		"If(EMPTY(FWFldGet('ZGH_DATINI')) .OR. EMPTY(FWFldGet('ZGH_HORINI')) .OR. EMPTY(FWFldGet('ZGH_DATFIM')) .OR. EMPTY(FWFldGet('ZGH_HORFIM')), ' '," +;
		"U_GA680Cal(FWFldGet('ZGH_RECURS'),FWFldGet('ZGH_DATINI'),FWFldGet('ZGH_HORINI'),FWFldGet('ZGH_DATFIM'),FWFldGet('ZGH_HORFIM')))",.F.,Nil,Nil,Nil)
	oStZGH:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZGH_DATINI","ZGH_TOTHOR",;
		"If(EMPTY(FWFldGet('ZGH_DATINI')) .OR. EMPTY(FWFldGet('ZGH_HORINI')) .OR. EMPTY(FWFldGet('ZGH_DATFIM')) .OR. EMPTY(FWFldGet('ZGH_HORFIM')), ' '," +;
		"U_UIntToHor(FWFldGet('ZGH_TOTHRA')))",.F.,Nil,Nil,Nil)
	oStZGH:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZGH_HORINI","ZGH_TOTHOR",;
		"If(EMPTY(FWFldGet('ZGH_DATINI')) .OR. EMPTY(FWFldGet('ZGH_HORINI')) .OR. EMPTY(FWFldGet('ZGH_DATFIM')) .OR. EMPTY(FWFldGet('ZGH_HORFIM')), ' '," +;
		"U_UIntToHor(FWFldGet('ZGH_TOTHRA')))",.F.,Nil,Nil,Nil)
	oStZGH:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZGH_DATFIM","ZGH_TOTHOR",;
		"If(EMPTY(FWFldGet('ZGH_DATINI')) .OR. EMPTY(FWFldGet('ZGH_HORINI')) .OR. EMPTY(FWFldGet('ZGH_DATFIM')) .OR. EMPTY(FWFldGet('ZGH_HORFIM')), ' '," +;
		"U_UIntToHor(FWFldGet('ZGH_TOTHRA')))",.F.,Nil,Nil,Nil)
	oStZGH:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZGH_HORFIM","ZGH_TOTHOR",;
		"If(EMPTY(FWFldGet('ZGH_DATINI')) .OR. EMPTY(FWFldGet('ZGH_HORINI')) .OR. EMPTY(FWFldGet('ZGH_DATFIM')) .OR. EMPTY(FWFldGet('ZGH_HORFIM')), ' '," +;
		"U_UIntToHor(FWFldGet('ZGH_TOTHRA')))",.F.,Nil,Nil,Nil)
	oStZGH:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])

	//------------------------------------------------
	// Gatilho tabela SH6 - PARADAS
	//------------------------------------------------
	aAuxGat := FwStruTrigger("H6_DATAINI","H6_TEMPO",;
		"If(EMPTY(FWFldGet('H6_DATAINI')) .OR. EMPTY(FWFldGet('H6_HORAINI')) .OR. EMPTY(FWFldGet('H6_DATAFIN')) .OR. EMPTY(FWFldGet('H6_HORAFIN')), ' '," +;
		"IntToHora(SubtHoras(FWFldGet('H6_DATAINI'),FWFldGet('H6_HORAINI'),FWFldGet('H6_DATAFIN'),FWFldGet('H6_HORAFIN')), 3))",.F.,Nil,Nil,Nil)
	oStSH6:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("H6_HORAINI","H6_TEMPO",;
		"If(EMPTY(FWFldGet('H6_DATAINI')) .OR. EMPTY(FWFldGet('H6_HORAINI')) .OR. EMPTY(FWFldGet('H6_DATAFIN')) .OR. EMPTY(FWFldGet('H6_HORAFIN')), ' '," +;
		"IntToHora(SubtHoras(FWFldGet('H6_DATAINI'),FWFldGet('H6_HORAINI'),FWFldGet('H6_DATAFIN'),FWFldGet('H6_HORAFIN')), 3))",.F.,Nil,Nil,Nil)
	oStSH6:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("H6_DATAFIN","H6_TEMPO",;
		"If(EMPTY(FWFldGet('H6_DATAINI')) .OR. EMPTY(FWFldGet('H6_HORAINI')) .OR. EMPTY(FWFldGet('H6_DATAFIN')) .OR. EMPTY(FWFldGet('H6_HORAFIN')), ' '," +;
		"IntToHora(SubtHoras(FWFldGet('H6_DATAINI'),FWFldGet('H6_HORAINI'),FWFldGet('H6_DATAFIN'),FWFldGet('H6_HORAFIN')), 3))",.F.,Nil,Nil,Nil)
	oStSH6:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("H6_HORAFIN","H6_TEMPO",;
		"If(EMPTY(FWFldGet('H6_DATAINI')) .OR. EMPTY(FWFldGet('H6_HORAINI')) .OR. EMPTY(FWFldGet('H6_DATAFIN')) .OR. EMPTY(FWFldGet('H6_HORAFIN')), ' '," +;
		"IntToHora(SubtHoras(FWFldGet('H6_DATAINI'),FWFldGet('H6_HORAINI'),FWFldGet('H6_DATAFIN'),FWFldGet('H6_HORAFIN')), 3))",.F.,Nil,Nil,Nil)
	oStSH6:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])

	//------------------------------------------------
	// Gatilho tabela ZGI - INSUMOS
	//------------------------------------------------
	aAuxGat := FwStruTrigger("ZGI_PRODUT","ZGI_DESCRI","POSICIONE('SB1', 1, XFILIAL('SB1') + FWFldGet('ZGI_PRODUT'), 'B1_DESC')",.F.,Nil,Nil,Nil)
	oStZGI:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZGI_PRODUT","ZGI_UM","POSICIONE('SB1', 1, XFILIAL('SB1') + FWFldGet('ZGI_PRODUT'), 'B1_UM')",.F.,Nil,Nil,Nil)
	oStZGI:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZGI_PRODUT","ZGI_LOCAL","IF(ExistBlock('GRLOCINS'),U_GRLOCINS('ID',{FWFldGet('ZGI_SEQUEN'),FWFldGet('ZGI_PRODUT'),FWFldGet('ZGI_QTDE'),FWFldGet('ZGI_UM'),FWFldGet('ZGI_LOCAL')}),POSICIONE('SB1', 1, XFILIAL('SB1') + FWFldGet('ZGI_PRODUT'), 'B1_LOCPAD'))",.F.,Nil,Nil,Nil)
	oStZGI:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])

	//------------------------------------------------
	// Gatilho tabela ZGI - CUSTO INDIRETO
	//------------------------------------------------
	aAuxGat := FwStruTrigger("ZGI_PRODUT","ZGI_DESCRI","POSICIONE('SB1', 1, XFILIAL('SB1') + FWFldGet('ZGI_PRODUT'), 'B1_DESC')",.F.,Nil,Nil,Nil)
	oStMOD:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZGI_PRODUT","ZGI_UM","POSICIONE('SB1', 1, XFILIAL('SB1') + FWFldGet('ZGI_PRODUT'), 'B1_UM')",.F.,Nil,Nil,Nil)
	oStMOD:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZGI_PRODUT","ZGI_LOCAL","IF(ExistBlock('GRLOCINS'),U_GRLOCINS('II',{FWFldGet('ZGI_SEQUEN'),FWFldGet('ZGI_PRODUT'),FWFldGet('ZGI_QTDE'),FWFldGet('ZGI_UM'),FWFldGet('ZGI_LOCAL')}),POSICIONE('SB1', 1, XFILIAL('SB1') + FWFldGet('ZGI_PRODUT'), 'B1_LOCPAD'))",.F.,Nil,Nil,Nil)
	oStMOD:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])

	//------------------------------------------------
	// Gatilho tabela ZGK - MAO DE OBRA
	//------------------------------------------------
	aAuxGat := FwStruTrigger("ZGK_FUNCIO","ZGK_NOME","POSICIONE('SRA', 1, XFILIAL('SRA') + FWFldGet('ZGK_FUNCIO'), 'RA_NOME')",.F.,Nil,Nil,Nil)
	oStZGK:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZGK_DATINI","ZGK_TOTHOR",;
		"If(EMPTY(FWFldGet('ZGK_DATINI')) .OR. EMPTY(FWFldGet('ZGK_HORINI')) .OR. EMPTY(FWFldGet('ZGK_DATFIM')) .OR. EMPTY(FWFldGet('ZGK_HORFIM')), ' '," +;
		"U_UIntToHor(U_GA680Cal(FWFldGet('ZGH_RECURS'),FWFldGet('ZGK_DATINI'),FWFldGet('ZGK_HORINI'),FWFldGet('ZGK_DATFIM'),FWFldGet('ZGK_HORFIM'))))",.F.,Nil,Nil,Nil)
	oStZGK:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZGK_HORINI","ZGK_TOTHOR",;
		"If(EMPTY(FWFldGet('ZGK_DATINI')) .OR. EMPTY(FWFldGet('ZGK_HORINI')) .OR. EMPTY(FWFldGet('ZGK_DATFIM')) .OR. EMPTY(FWFldGet('ZGK_HORFIM')), ' '," +;
		"U_UIntToHor(U_GA680Cal(FWFldGet('ZGH_RECURS'),FWFldGet('ZGK_DATINI'),FWFldGet('ZGK_HORINI'),FWFldGet('ZGK_DATFIM'),FWFldGet('ZGK_HORFIM'))))",.F.,Nil,Nil,Nil)
	oStZGK:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZGK_DATFIM","ZGK_TOTHOR",;
		"If(EMPTY(FWFldGet('ZGK_DATINI')) .OR. EMPTY(FWFldGet('ZGK_HORINI')) .OR. EMPTY(FWFldGet('ZGK_DATFIM')) .OR. EMPTY(FWFldGet('ZGK_HORFIM')), ' '," +;
		"U_UIntToHor(U_GA680Cal(FWFldGet('ZGH_RECURS'),FWFldGet('ZGK_DATINI'),FWFldGet('ZGK_HORINI'),FWFldGet('ZGK_DATFIM'),FWFldGet('ZGK_HORFIM'))))",.F.,Nil,Nil,Nil)
	oStZGK:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZGK_HORFIM","ZGK_TOTHOR",;
		"If(EMPTY(FWFldGet('ZGK_DATINI')) .OR. EMPTY(FWFldGet('ZGK_HORINI')) .OR. EMPTY(FWFldGet('ZGK_DATFIM')) .OR. EMPTY(FWFldGet('ZGK_HORFIM')), ' '," +;
		"U_UIntToHor(U_GA680Cal(FWFldGet('ZGH_RECURS'),FWFldGet('ZGK_DATINI'),FWFldGet('ZGK_HORINI'),FWFldGet('ZGK_DATFIM'),FWFldGet('ZGK_HORFIM'))))",.F.,Nil,Nil,Nil)
	oStZGK:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])

	//------------------------------------------------
	// Gatilho tabela ZGL - FERRAMENTA
	//------------------------------------------------
	aAuxGat := FwStruTrigger("ZGL_FERRAM","ZGL_DESCRI","POSICIONE('SH4', 1, XFILIAL('SH4') + FWFldGet('ZGL_FERRAM'), 'H4_DESCRI')",.F.,Nil,Nil,Nil)
	oStZGL:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])

	//------------------------------------------------
	// Gatilho tabela ZS7 - FIO/LÂMINA
	//------------------------------------------------
	aAuxGat := FwStruTrigger("ZS7_PRODUT","ZS7_DESCRI","POSICIONE('SB1', 1, XFILIAL('SB1') + FWFldGet('ZS7_PRODUT'), 'B1_DESC')",.F.,Nil,Nil,Nil)
	oStZS7:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZS7_PRODUT","ZS7_UM","POSICIONE('SB1', 1, XFILIAL('SB1') + FWFldGet('ZS7_PRODUT'), 'B1_UM')",.F.,Nil,Nil,Nil)
	oStZS7:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])

	aAuxGat := FwStruTrigger("ZS7_QTDFIO","ZS7_QUANT","U_GR38CONS(FWFldGet('ZH7_NUM'), FWFldGet('ZH7_RECURS'), FWFldGet('ZS7_QTDFIO'), FWFldGet('ZS7_QLAMIN'), FWFldGet('ZS7_LAMINI'), FWFldGet('ZS7_LAMFIM'))",.F.,Nil,Nil,Nil)
	oStZS7:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZS7_QLAMIN","ZS7_QUANT","U_GR38CONS(FWFldGet('ZH7_NUM'), FWFldGet('ZH7_RECURS'), FWFldGet('ZS7_QTDFIO'), FWFldGet('ZS7_QLAMIN'), FWFldGet('ZS7_LAMINI'), FWFldGet('ZS7_LAMFIM'))",.F.,Nil,Nil,Nil)
	oStZS7:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZS7_LAMINI","ZS7_QUANT","U_GR38CONS(FWFldGet('ZH7_NUM'), FWFldGet('ZH7_RECURS'), FWFldGet('ZS7_QTDFIO'), FWFldGet('ZS7_QLAMIN'), FWFldGet('ZS7_LAMINI'), FWFldGet('ZS7_LAMFIM'))",.F.,Nil,Nil,Nil)
	oStZS7:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZS7_LAMFIM","ZS7_QUANT","U_GR38CONS(FWFldGet('ZH7_NUM'), FWFldGet('ZH7_RECURS'), FWFldGet('ZS7_QTDFIO'), FWFldGet('ZS7_QLAMIN'), FWFldGet('ZS7_LAMINI'), FWFldGet('ZS7_LAMFIM'))",.F.,Nil,Nil,Nil)
	oStZS7:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])

	//------------------------------------------------
	// Inicializadores padrão
	//------------------------------------------------
	oStSH6:SetProperty('*',          MODEL_FIELD_INIT, FwBuildFeature(STRUCT_FEATURE_INIPAD, ""))
	oStZGH:SetProperty("ZGH_DESCRI", MODEL_FIELD_INIT, FwBuildFeature(STRUCT_FEATURE_INIPAD, "If(INCLUI, ' ', POSICIONE('ZG6', 1, XFILIAL('ZG6') + ZGH->ZGH_OPERAC, 'ZG6_DESCRI'))"))
	oStSH6:SetProperty('H6_DESCRI',  MODEL_FIELD_INIT, FwBuildFeature(STRUCT_FEATURE_INIPAD, "If(INCLUI, ' ', POSICIONE('CYN', 1, XFILIAL('CYN') + SH6->H6_MOTIVO, 'CYN_DSSP'))"))
	oStSH6:SetProperty("H6_RECURSO", MODEL_FIELD_INIT, FwBuildFeature(STRUCT_FEATURE_INIPAD, "ZH7->ZH7_RECURS"))
	oStZGK:SetProperty('ZGK_NOME',   MODEL_FIELD_INIT, FwBuildFeature(STRUCT_FEATURE_INIPAD, "If(INCLUI, ' ', POSICIONE('SRA', 1, XFILIAL('SRA') + ZGK->ZGK_FUNCIO, 'RA_NOME'))"))
	oStZGL:SetProperty('ZGL_DESCRI', MODEL_FIELD_INIT, FwBuildFeature(STRUCT_FEATURE_INIPAD, "If(INCLUI, ' ', POSICIONE('SH4', 1, XFILIAL('SH4') + ZGL->ZGL_FERRAM, 'H4_DESCRI'))"))

	//------------------------------------------------
	// Validação de campos.
	//------------------------------------------------

	//inserido algumas validações referente a mascara das horas e data, principalmente foi inserido referente a SH6 que era retirada todas as
	//validações pelo mvc abaixo.Não deixei para pegar da SX3 devido a funçoa A680Hora()   esta dando erro.
	//https://totvsleste.freshdesk.com/a/tickets/1005

	oStSH6:SetProperty('*',          MODEL_FIELD_VALID, {|| .T. })
	oStSH6:SetProperty('H6_HORAINI', MODEL_FIELD_VALID,	{|| (If(AllTrim(M->H6_HORAINI)==":" .OR. EMPTY(AllTrim(M->H6_HORAINI)) , .T. ,  AtVldHora(M->H6_HORAINI))) })
	oStSH6:SetProperty('H6_HORAFIN', MODEL_FIELD_VALID, {|| (If(AllTrim(M->H6_HORAFIN)==":" .OR. EMPTY(AllTrim(M->H6_HORAFIN)) , .T. ,  AtVldHora(M->H6_HORAFIN))) })
	oStSH6:SetProperty('H6_TEMPO'  , MODEL_FIELD_VALID, {|| VldTemp(oModel:GetModel("SH6DETAIL"):GetValue("H6_TEMPO") , oModel:GetModel("SH6DETAIL"):GetValue("H6_HORAINI") , oModel:GetModel("SH6DETAIL"):GetValue("H6_HORAFIN"))})

	oStZH7:SetProperty('ZH7_RECURS', MODEL_FIELD_VALID, FwBuildFeature(STRUCT_FEATURE_VALID, 'Vazio() .Or. (ExistCpo("SH1", FwFldGet("ZH7_RECURS")) .And. U_GR38RECU())'))

	oStZGI:SetProperty('ZGI_PRODUT', MODEL_FIELD_VALID, {|| VldZGI(oModel) })
	oStMOD:SetProperty('ZGI_PRODUT', MODEL_FIELD_VALID, {|| VldMOD(oModel) })
	oStZGI:SetProperty('ZGI_UM',     MODEL_FIELD_VALID, {|| U_ValidUM( oModel, 'ZGIDETAIL', 'ZGI_PRODUT', 'ZGI_UM') })
	oStMOD:SetProperty('ZGI_UM',     MODEL_FIELD_VALID, {|| U_ValidUM( oModel, 'MODDETAIL', 'ZGI_PRODUT', 'ZGI_UM') })
	oStZGH:SetProperty('ZGH_RECURS', MODEL_FIELD_VALID, FwBuildFeature(STRUCT_FEATURE_VALID, 'Vazio() .Or. U_GRA045F2(FwFldGet("ZGH_RECURS"))'))
	oStZGH:SetProperty('ZGH_DATFIM', MODEL_FIELD_VALID, {|| VldZGH(oModel) })
	oStZGH:SetProperty('ZGH_DATAPO', MODEL_FIELD_VALID, {|| VldZGH(oModel) })
	oStZGH:SetProperty('ZGH_DATINI', MODEL_FIELD_VALID, {|| VldZGH(oModel) })
	oStZGH:SetProperty('ZGH_HORINI', MODEL_FIELD_VALID, {|| If(AllTrim(M->ZGH_HORINI)==":" .OR. EMPTY(AllTrim(M->ZGH_HORINI)), .T. ,  AtVldHora(M->ZGH_HORINI)) })
	oStZGH:SetProperty('ZGH_HORINI', MODEL_FIELD_VALID, {|| VldZGH(oModel)})
	oStZGH:SetProperty('ZGH_HORFIM', MODEL_FIELD_VALID, {|| If(AllTrim(M->ZGH_HORFIM)==":" .OR. EMPTY(AllTrim(M->ZGH_HORFIM)), .T. ,  AtVldHora(M->ZGH_HORFIM)) })
	oStZGH:SetProperty('ZGH_HORFIM', MODEL_FIELD_VALID, {|| VldZGH(oModel)})
	oStZGH:SetProperty('ZGH_TOTHOR', MODEL_FIELD_VALID, {|| VldTemp(oModel:GetModel("ZGHDETAIL"):GetValue("ZGH_TOTHOR") , oModel:GetModel("ZGHDETAIL"):GetValue("ZGH_HORINI") , oModel:GetModel("ZGHDETAIL"):GetValue("ZGH_HORFIM"))})
	oStZGK:SetProperty('ZGK_HORINI', MODEL_FIELD_VALID, {|| If(AllTrim(M->ZGK_HORINI)==":" .OR. EMPTY(AllTrim(M->ZGK_HORINI)), .T. ,  AtVldHora(M->ZGK_HORINI))})
	oStZGK:SetProperty('ZGK_HORFIM', MODEL_FIELD_VALID, {|| If(AllTrim(M->ZGK_HORFIM)==":" .OR. EMPTY(AllTrim(M->ZGK_HORFIM)), .T. ,  AtVldHora(M->ZGK_HORFIM))})
	oStZGK:SetProperty('ZGK_TOTHOR', MODEL_FIELD_VALID, {|| VldTemp(oModel:GetModel("ZGKDETAIL"):GetValue("ZGK_TOTHOR") , oModel:GetModel("ZGKDETAIL"):GetValue("ZGK_HORINI") , oModel:GetModel("ZGKDETAIL"):GetValue("ZGK_HORFIM"))})
	oStSH6:SetProperty('H6_DATAFIN', MODEL_FIELD_VALID, {|| VldSH6(oModel)})
	oStSH6:SetProperty('H6_HORAFIN', MODEL_FIELD_VALID, {|| VldSH6(oModel)})
	oStSH6:SetProperty('H6_DTAPONT', MODEL_FIELD_VALID, {|| VldSH6(oModel)})
	oStSH6:SetProperty('H6_DATAINI', MODEL_FIELD_VALID, {|| VldSH6(oModel)})
	oStSH6:SetProperty('H6_HORAINI', MODEL_FIELD_VALID, {|| VldSH6(oModel)})
	//------------------------------------------------
	// Campos Obrigatórios
	//------------------------------------------------
	oStSH6:SetProperty('*',          MODEL_FIELD_OBRIGAT, .F.)
	oStZGH:SetProperty('ZGH_OP',     MODEL_FIELD_OBRIGAT, .F.)
	oStZGI:SetProperty('ZGI_PRODUT', MODEL_FIELD_OBRIGAT, .T.)
	oStZGI:SetProperty('ZGI_QTDE',   MODEL_FIELD_OBRIGAT, .T.)
	oStZGI:SetProperty('ZGI_UM',     MODEL_FIELD_OBRIGAT, .T.)
	oStZGI:SetProperty('ZGI_LOCAL',  MODEL_FIELD_OBRIGAT, .T.)
	oStZGI:SetProperty('ZGI_OP',     MODEL_FIELD_OBRIGAT, .F.)
	oStZGI:SetProperty('ZGI_SEQUEN', MODEL_FIELD_OBRIGAT, .F.)
	oStMOD:SetProperty('ZGI_OP',     MODEL_FIELD_OBRIGAT, .F.)
	oStMOD:SetProperty('ZGI_SEQUEN', MODEL_FIELD_OBRIGAT, .F.)
	oStZGK:SetProperty('ZGK_OP',     MODEL_FIELD_OBRIGAT, .F.)
	oStZGK:SetProperty('ZGK_SEQUEN', MODEL_FIELD_OBRIGAT, .F.)
	oStZGL:SetProperty('ZGL_OP',     MODEL_FIELD_OBRIGAT, .F.)
	oStZGL:SetProperty('ZGL_SEQUEN', MODEL_FIELD_OBRIGAT, .F.)
	oStZHL:SetProperty('ZHL_CHECK',  MODEL_FIELD_OBRIGAT, .F.)
	oStZS3:SetProperty('ZS3_NUM',    MODEL_FIELD_OBRIGAT, .F.)
	oStZS7:SetProperty('ZS7_NUM',    MODEL_FIELD_OBRIGAT, .F.)
	oStZS7:SetProperty('ZS7_SEQUEN', MODEL_FIELD_OBRIGAT, .F.)

	// Custo Indireto - Filtra apenas produtos MOD ou B1_CCUSTO preenchido
	cSGBD := TCGetDB()

	if (cSGBD $ "ORACLE")
		cQuery := " ( SELECT B1_COD FROM " + RetSqlName('SB1')  + " SB1 WHERE SB1.B1_FILIAL = '" + FwXFilial("SB1") + "' AND SB1.B1_COD = ZGI.ZGI_PRODUT AND SB1.D_E_L_E_T_ =' ' AND ( SB1.B1_CCCUSTO <> ' ' OR SUBSTR(SB1.B1_COD,1,3) = 'MOD' ))"
	Else
		cQuery := " ( SELECT B1_COD FROM " + RetSqlName('SB1')  + " SB1 WHERE SB1.B1_FILIAL = '" + FwXFilial("SB1") + "' AND SB1.B1_COD = ZGI.ZGI_PRODUT AND SB1.D_E_L_E_T_ = ' ' AND ( SB1.B1_CCCUSTO <> ' ' OR SUBSTRING(SB1.B1_COD,1,3) = 'MOD' ))"
	EndIf

	//cQuery := ChangeQuery(cQuery) //apresentou erro na base SQL

	oModel:GetModel( 'MODDETAIL' ):SetLoadFilter( , " EXISTS " + cQuery )
	// Insumo - Filtra apenas produtos dIferente MOD ou B1_CCUSTO vazio

	cSGBD := TCGetDB()

	if (cSGBD $ "ORACLE")
		cQuery := " (SELECT B1_COD FROM " + RetSqlName('SB1')  + " SB1 WHERE SB1.B1_FILIAL = '" + FwXFilial("SB1") + "' AND SB1.B1_COD = ZGI.ZGI_PRODUT AND SB1.D_E_L_E_T_ =' ' AND  SB1.B1_CCCUSTO = ' ' AND SUBSTR(SB1.B1_COD,1,3) <> 'MOD' )"
	Else
		cQuery := " (SELECT B1_COD FROM " + RetSqlName('SB1')  + " SB1 WHERE SB1.B1_FILIAL = '" + FwXFilial("SB1") + "' AND SB1.B1_COD = ZGI.ZGI_PRODUT AND SB1.D_E_L_E_T_ = ' ' AND  SB1.B1_CCCUSTO = ' ' AND SUBSTRING(SB1.B1_COD,1,3) <> 'MOD' )"
	EndIf

	//cQuery := ChangeQuery(cQuery) //apresentou erro na base SQL

	oModel:GetModel( 'ZGIDETAIL' ):SetLoadFilter( , " EXISTS " + cQuery )
	// Hora Improdutiva - Filtra apenas registros de horas improdutivas
	oModel:GetModel( 'SH6DETAIL' ):SetLoadFilter( , " H6_TIPO = 'I' " )

	//------------------------------------------------
	// Setando a chave primária da rotina
	//------------------------------------------------
	oModel:SetPrimaryKey({'ZH7_FILIAL', 'ZH7_NUM'})

	// Ordem de Produção x Operação
	oModel:SetRelation('ZGHDETAIL', {{'ZGH_FILIAL','FwXFilial("ZGH")'}, {'ZGH_OP','ZH7_NUM'}}, ZGH->( IndexKey( 1 ) ) )
	// Operação x Produto Acabado
	oModel:SetRelation('ZHLDETAIL', {{'ZHL_FILIAL','FwXFilial("ZHL")'}, {'ZHL_OP','ZH7_NUM'}, {'ZHL_SEQUEN','ZGH_SEQUEN'} }, ZHL->( IndexKey( 1 ) ) )
	// Operação x Insumo
	oModel:SetRelation('ZGIDETAIL', {{'ZGI_FILIAL','FwXFilial("ZGI")'}, {'ZGI_OP','ZH7_NUM'}, {'ZGI_SEQUEN','ZGH_SEQUEN'} }, ZGI->( IndexKey( 1 ) ) )
	// Operação x Custo Indireto
	oModel:SetRelation('MODDETAIL', {{'ZGI_FILIAL','FwXFilial("ZGI")'}, {'ZGI_OP','ZH7_NUM'}, {'ZGI_SEQUEN','ZGH_SEQUEN'} }, ZGI->( IndexKey( 1 ) ) )
	// Operação x Mão de Obra
	oModel:SetRelation('ZGKDETAIL', {{'ZGK_FILIAL','FwXFilial("ZGK")'}, {'ZGK_OP','ZH7_NUM'}, {'ZGK_SEQUEN','ZGH_SEQUEN'} }, ZGK->( IndexKey( 1 ) ) )
	// Operação x Ferramentas
	oModel:SetRelation('ZGLDETAIL', {{'ZGL_FILIAL','FwXFilial("ZGL")'}, {'ZGL_OP','ZH7_NUM'}, {'ZGL_SEQUEN','ZGH_SEQUEN'} }, ZGL->( IndexKey( 1 ) ) )
	// Ordem de Produção x Hora Improdutiva
	oModel:SetRelation('SH6DETAIL', {{'H6_FILIAL','FwXFilial("SH6")'}, {'H6_YOP','ZH7_NUM'}}, SH6->( IndexKey( 1 ) ) )
	// Ordem de Produção x Conferência do Corte
	oModel:SetRelation('ZS3DETAIL', {{'ZS3_FILIAL','FwXFilial("ZS3")'}, {'ZS3_NUM','ZH7_NUM'}}, ZS3->( IndexKey( 1 ) ) )
	// Ordem de Produção x Fio/Lâmina do Corte
	oModel:SetRelation('ZS7DETAIL', {{'ZS7_FILIAL','FwXFilial("ZS7")'}, {'ZS7_NUM','ZH7_NUM'}, {'ZS7_SEQUEN','ZGH_SEQUEN'}}, ZS7->( IndexKey( 1 ) ) )

	if lIncluiOp
		oModel:SetRelation('ZH8DETAIL', {{'ZH8_FILIAL','FwXFilial("ZH8")'}, {'ZH8_NUM','ZH7_NUM'}}, ZH8->( IndexKey( 1 ) ) )
		oModel:SetRelation('ZH9DETAIL', {{'ZH9_FILIAL','FwXFilial("ZH9")'}, {'ZH9_NUM','ZH7_NUM'}}, ZH9->( IndexKey( 1 ) ) )
	EndIf

	//------------------------------------------------
	// Linhas unicas
	//------------------------------------------------
	aCampZGK :=  {'ZGK_FILIAL','ZGK_OP','ZGK_SEQUEN','ZGK_FUNCIO','ZGK_DATINI'}
	If ExistBlock("GR045UNI")
		aCampZGK := ExecBlock("GR045UNI", .f., .f., {aCampZGK} )[1]
	EndIf

	oModel:GetModel('ZGHDETAIL'):SetUniqueLine({'ZGH_FILIAL','ZGH_OP','ZGH_SEQUEN'})
	oModel:GetModel('ZHLDETAIL'):SetUniqueLine({'ZHL_FILIAL','ZHL_OP','ZHL_SEQUEN','ZHL_ITEM','ZHL_SEQOP'})
	oModel:GetModel('ZGIDETAIL'):SetUniqueLine({'ZGI_FILIAL','ZGI_OP','ZGI_SEQUEN','ZGI_PRODUT','ZGI_LOCAL','ZGI_LOTECT','ZGI_NUMLOT'})
	oModel:GetModel('MODDETAIL'):SetUniqueLine({'ZGI_FILIAL','ZGI_OP','ZGI_SEQUEN','ZGI_PRODUT','ZGI_LOCAL','ZGI_LOTECT','ZGI_NUMLOT'})
	oModel:GetModel('ZGKDETAIL'):SetUniqueLine(aCampZGK)
	oModel:GetModel('ZGLDETAIL'):SetUniqueLine({'ZGL_FILIAL','ZGL_OP','ZGL_SEQUEN','ZGL_FERRAM'})
	oModel:GetModel('SH6DETAIL'):SetUniqueLine({'H6_FILIAL', 'H6_YOP', 'H6_DATAINI','H6_HORAINI','H6_MOTIVO'})
	oModel:GetModel('ZS3DETAIL'):SetUniqueLine({'ZS3_FILIAL', 'ZS3_NUM', 'ZS3_SEQCON'})
	oModel:GetModel('ZS7DETAIL'):SetUniqueLine({'ZS7_FILIAL', 'ZS7_NUM', 'ZS7_SEQUEN', 'ZS7_SEQLAN'})

	If lIncluiOp
		// Define que o submodelo não será gravado, ele é apenas usado para consulta.
		// Se um submodelo é onlyquery e possui submodelos abaixo dele, os filhos serão
		// gravaveis por padrão. Mesmo o pai sendo onlyquery, os filhos irão
		// fazer a gravação, exceto se o(s) submodelo(s) filho for definido como
		// setonlyquery verdadeiro.

		oModel:GetModel('ZH8DETAIL'):SetOnlyQuery(.T.)
		oModel:GetModel('ZH9DETAIL'):SetOnlyQuery(.T.)

		If INCLUI
			oModel:GetModel('ZH7MASTER'):SetOnlyQuery(.T.)
		Else
			//Não permite incluir nem excluir as linhas
			oModel:GetModel('ZH8DETAIL'):SetNoDeleteLine(.T.)
			oModel:GetModel('ZH8DETAIL'):SetNoInsertLine(.T.)
			oModel:GetModel('ZH9DETAIL'):SetNoDeleteLine(.T.)
			oModel:GetModel('ZH9DETAIL'):SetNoInsertLine(.T.)
		EndIf

	EndIf

	//------------------------------------------------
	// Permite salvar o GRID sem dados.
	//------------------------------------------------
	IF lIncluiOp
		oModel:GetModel('ZGHDETAIL'):SetOptional( .T. ) // Quando inclui precisamos deletar todas as operações da engenharia. Criado automatica para informar somente as da tela.
	Else
		oModel:GetModel('ZGHDETAIL'):SetOptional( .F. ) // Sempre deve existir uma operação
	EndIf

	oModel:GetModel('ZHLDETAIL'):SetOptional( .T. )
	oModel:GetModel('ZGIDETAIL'):SetOptional( .T. )
	oModel:GetModel('MODDETAIL'):SetOptional( .T. )
	oModel:GetModel('ZGKDETAIL'):SetOptional( .T. )
	oModel:GetModel('ZGLDETAIL'):SetOptional( .T. )
	oModel:GetModel('SH6DETAIL'):SetOptional( .T. )
	oModel:GetModel('ZS3DETAIL'):SetOptional( .T. )
	oModel:GetModel('ZS7DETAIL'):SetOptional( .T. )

	//------------------------------------------------
	// Adicionando descrição ao modelo
	//------------------------------------------------
	oModel:SetDescription(cTitulo)

	//------------------------------------------------
	// Setando a descrição do formulário
	//------------------------------------------------
	oModel:GetModel('ZGHDETAIL'):SetDescription('Operações')
	oModel:GetModel('ZHLDETAIL'):SetDescription('Produtos Acabados')
	oModel:GetModel('ZGIDETAIL'):SetDescription('Insumos')
	oModel:GetModel('MODDETAIL'):SetDescription('Custo Indireto')
	oModel:GetModel('ZGKDETAIL'):SetDescription('Mão de Obra')
	oModel:GetModel('ZGLDETAIL'):SetDescription('Ferramentas')
	oModel:GetModel('SH6DETAIL'):SetDescription('Paradas')
	oModel:GetModel('ZS3DETAIL'):SetDescription('Conferência do Corte')
	oModel:GetModel('ZS7DETAIL'):SetDescription('Fio/Lâmina do Corte')

Return oModel

/*/{Protheus.doc} ViewDef
ViewDef
@type Static Function
@author Totvs Vitoria - Mauricio Silva
@since 27/06/19
@version version
/*/
Static Function ViewDef()

	//Criação do objeto do modelo de dados da Interface do Cadastro de Autor/Interprete
	Local oModel := FWLoadModel("GROA045")

	//Criação da estrutura de dados utilizada na interface do cadastro de Autor
	Local oStZH7 := FWFormStruct(2, 'ZH7') // Ordem de Produção
	Local oStZGH := FWFormStruct(2, 'ZGH') // Operação
	Local oStZHL := FWFormStruct(2, 'ZHL') // Operação vs Produto Acabado
	Local oStZGI := FWFormStruct(2, 'ZGI') // Insumos
	Local oStMOD := FWFormStruct(2, 'ZGI') // Custo Indireto
	Local oStZGK := FWFormStruct(2, 'ZGK') // Mão de Obra
	Local oStZGL := FWFormStruct(2, 'ZGL') // Ferramenta
	Local oStSH6 := FWFormStruct(2, 'SH6') // Horas Improdutivas
	Local oStZS3 := FWFormStruct(2, 'ZS3') // Conferência do Corte
	Local oStZS7 := FWFormStruct(2, 'ZS7') // Fio/Lâmina do Corte
	Local oStZH8 := NIL
	Local oStZH9 := NIL

	Local aCamp  := StrTokArr(GETNEWPAR("GR_CAMPSH6",""),",") // Informar o campo para apresentar na grid exem "H6_CAMP1,H6_CAMP2"

	//Criando oView como nulo
	Local oView     := Nil
	Local cProcesso := ""

	Local aFieldSH6 := {'H6_RECURSO','H6_MOTIVO','H6_DESCRI','H6_DTAPONT','H6_DATAINI','H6_HORAINI','H6_DATAFIN','H6_HORAFIN','H6_TEMPO','H6_OPERADO','H6_OBSERVA'}
	Local aFieldDel := {}
	Local aFieldAdd := {}
	Local nPosition := 0
	Local aFieldTmp := {}
	Local nX,nK		:= 0
	Local cRotCria  := ""
	Local lRotNova  := .f.
	Local lHabOpPa  := GETNEWPAR("GR_HABOPPA", .F.) // Habilita aba para vincular Operação ao Produto Acabado.
	Local cHabCorte := GETNEWPAR("GR_HABCORT", "0") // Habilita controle de corte.
	Local cGruRec   := ""
	Local cTipRec   := ""

	If lIncluiOp .and. Inclui

		aRet := AskProcess()

		If !aRet[1]
			MsgInfo("Processo cancelado pelo usuário!")
			Return .f.
		EndIf

		If aRet[1]
			__cProcess := aRet[2][1]
		EndIf

	EndIf

	IF (ZH7->(FieldPos("ZH7_ROTINA"))> 0)
		cRotCria   := ZH7->ZH7_ROTINA
	EndIF

	lRotNova  :=  alltrim(cRotCria) $ "GROA060/GROA062"

	if lRotNova
		lHabOpPa := .t.
	EndIf

	//Caso o usuário tenha mais campos para apresentar na grid
	for nK := 1 to len(aCamp)
		Aadd(aFieldSH6,aCamp[nK])
	next

	// Ativa o Modelo provisoriamente para recurar o
	// código do processo e a situação.
	oModel:Activate()
	If lIncluiOp .and. Inclui
		cProcesso := __cProcess
		cGruRec   := ""
	Else
		cProcesso := oModel:GetModel("ZH7MASTER"):GetValue("ZH7_PROCES")
		cGruRec   := Posicione("SH1", 1, xFilial("SH1") + oModel:GetModel("ZH7MASTER"):GetValue('ZH7_RECURS'), "H1_YGRUPO")
	EndIf

	cTipRec   := Posicione("ZGF", 1, xFilial("ZGF") + cGruRec, "ZGF_TIPO")
	oModel:DeActivate()

	//Criando a view que será o retorno da função e setando o modelo da rotina
	oView := FWFormView():New()

	//Seta o modelo
	oView:SetModel(oModel)

	// Habilita aba para apontamento da operação informando o produto acabado.
	If lHabOpPa .And. cProcesso $ cTiposZHL
		oView:SetAfterViewActivate( {|oView| SetAfter(oView)} )
	EndIf

	//------------------------------------------------
	// Não permite alteração so campos
	//------------------------------------------------
	oStZH7:SetProperty("*",        MVC_VIEW_CANCHANGE, .F.)

	oStSH6:SetProperty("H6_TEMPO", MVC_VIEW_CANCHANGE, .F.)

	//------------------------------------------------
	// Campos permitidos alteração
	//------------------------------------------------
	If cProcesso == "S" .And. cHabCorte == "1"
		oStZH7:SetProperty("ZH7_RECURS", MVC_VIEW_CANCHANGE, .F.)
	Else
		oStZH7:SetProperty("ZH7_RECURS", MVC_VIEW_CANCHANGE, .T.)
	EndIf

	If cProcesso $ "B/T"
		oStZH7:SetProperty("ZH7_CODMOT", MVC_VIEW_CANCHANGE, .T.)
	EndIf

	//INCLUIR DADOS OP.
	If lIncluiOp

		oStZH8 := FWFormStruct(2, 'ZH8') // Materia prima
		oStZH9 := FWFormStruct(2, 'ZH9') // Produto acabado

		if inclui

			If cProcesso == "S"

				oStZH9:AddField( 'ZH9_SUBINI' 	,'05', 'SubLote Inicial'  		, 'SubLote Inicial'   	  ,,'C' )

				//Dados da entera. Campos virtuais
				oStZH8:AddField( 'ZH8_COMPLE' 	,'93' , 'Compl.Lote'  		    , 'Compl.Lote'   	      ,,'C' ,X3Picture( "C2_YCOMPLE" ))
				oStZH8:AddField( 'ZH8_COMITL' 	,'94' , 'Com.Liq.Entera'  		, 'Com.Liq.Entera'  	  ,,'N' ,X3Picture( "C2_YCOMITL" ))
				oStZH8:AddField( 'ZH8_ALTITL' 	,'95' , 'Alt.Liq.Entera'  		, 'Alt.Liq.Entera' 	      ,,'N' ,X3Picture( "C2_YALTITL" ))
				oStZH8:AddField( 'ZH8_ESPITL' 	,'96' , 'Esp.Liq.Entera'  		, 'Esp.Liq.Entera'   	  ,,'N' ,X3Picture( "C2_YESPITL" ))
				oStZH8:AddField( 'ZH8_COMITB' 	,'97' , 'Com.Bru.Entera'  		, 'Com.Bru.Entera'   	  ,,'N' ,X3Picture( "C2_YCOMITB" ))
				oStZH8:AddField( 'ZH8_ALTITB' 	,'98' , 'Alt.Bru.Entera'  		, 'Alt.Bru.Entera'  	  ,,'N' ,X3Picture( "C2_YALTITB" ))
				oStZH8:AddField( 'ZH8_ESPITB' 	,'99' ,  'Esp.Bru.Entera'  		, 'Esp.Bru.Entera'  	  ,,'N' ,X3Picture( "C2_YESPITB" ))

			EndIf

			oStZH7:SetProperty("ZH7_RECURS", MVC_VIEW_CANCHANGE, .T.)
			oStZH7:SetProperty("ZH7_EMISSA", MVC_VIEW_CANCHANGE, .T.)
			oStZH7:SetProperty("ZH7_DATPRI", MVC_VIEW_CANCHANGE, .T.)
			oStZH7:SetProperty("ZH7_DATPRF", MVC_VIEW_CANCHANGE, .T.)
			oStZH7:SetProperty("ZH7_TIPOOP", MVC_VIEW_CANCHANGE, .T.)

		Else
			oStZH8:SetProperty("*",        MVC_VIEW_CANCHANGE, .F.)
			oStZH9:SetProperty("*",        MVC_VIEW_CANCHANGE, .F.)
		EndIf

		oStZH8:RemoveField('ZH8_NUM')
		oStZH9:RemoveField('ZH9_NUM')
		oStZH9:RemoveField('ZH9_CODMAT')
		oStZH9:RemoveField('ZH9_ENGENH')

	EndIf

	//Ponto de entrada para dar possibilidade de liberar alteração de campos da ZH7.
	//Obs, ideal alterar os campos customizados dos clientes os padrões podem acontecer situações indevidas.
	If ExistBlock("GRCPO451")
		ExecBlock("GRCPO451", .F., .F., {@oStZH7,@oStZH8,@oStZH9})
	EndIf

	//------------------------------------------------
	// Remove campos da tela
	//------------------------------------------------
	oStZH7:RemoveField('ZH7_ENGENH')
	oStZH7:RemoveField('ZH7_DESCEN')
	oStZH7:RemoveField('ZH7_BLOCO')
	// oStZGH:RemoveField('ZGH_RECURS')
	oStSH6:RemoveField('H6_OPERAC')
	oStSH6:RemoveField('H6_FERRAM')
	oStMOD:RemoveField('ZGI_LOTECT')
	oStMOD:RemoveField('ZGI_NUMLOT')

	If cProcesso == "E"

		oStZH7:RemoveField('ZH7_CODMOT')
		oStZH7:RemoveField('ZH7_DESMOT')
		oStZH7:RemoveField('ZH7_COECOR')

	ElseIf cProcesso == "S"

		oStZH7:RemoveField('ZH7_FRENTE')
		oStZH7:RemoveField('ZH7_DESCFR')
		oStZH7:RemoveField('ZH7_CODMOT')
		oStZH7:RemoveField('ZH7_DESMOT')

	ElseIf cProcesso == "B"

		oStZH7:RemoveField('ZH7_FRENTE')
		oStZH7:RemoveField('ZH7_DESCFR')
		oStZH7:RemoveField('ZH7_COECOR')

	ElseIf cProcesso == "R"

		oStZH7:RemoveField('ZH7_FRENTE')
		oStZH7:RemoveField('ZH7_DESCFR')
		oStZH7:RemoveField('ZH7_CODMOT')
		oStZH7:RemoveField('ZH7_DESMOT')
		oStZH7:RemoveField('ZH7_COECOR')

	ElseIf cProcesso == "T"

		oStZH7:RemoveField('ZH7_FRENTE')
		oStZH7:RemoveField('ZH7_DESCFR')
		//oStZH7:RemoveField('ZH7_CODMOT') // https://totvsleste.freshdesk.com/a/tickets/5701
		//oStZH7:RemoveField('ZH7_DESMOT')
		oStZH7:RemoveField('ZH7_COECOR')

	ElseIf cProcesso == "D"

		oStZH7:RemoveField('ZH7_FRENTE')
		oStZH7:RemoveField('ZH7_DESCFR')
		oStZH7:RemoveField('ZH7_CODMOT')
		oStZH7:RemoveField('ZH7_DESMOT')

	EndIf

	oStZGH:SetProperty('ZGH_RECURS', MVC_VIEW_LOOKUP, 'GRZH7B')
	oStZGI:SetProperty("ZGI_PRODUT", MVC_VIEW_LOOKUP, "GRSB1A")
	oStMOD:SetProperty("ZGI_PRODUT", MVC_VIEW_LOOKUP, "GRSB1B")

	// Remove todos os campos Horas Improdutivas
	For nX := 1 To Len(oStSH6:aFields)
		If aScan(aFieldSH6, {|x| AlLTrim(x) == AllTrim(oStSH6:aFields[nX][1])}) > 0
			aAdd(aFieldAdd, oStSH6:aFields[nX])
		EndIf
		aAdd(aFieldDel, oStSH6:aFields[nX][1])
	Next

	// Remove todos os campos para incluir na sequencia correta
	For nX := 1 To Len(aFieldDel)
		oStSH6:RemoveField(aFieldDel[nX])
	Next

	// Inclui campos na sequencia correta
	cOrdem := "00"
	FOR nX := 1 To Len(aFieldSH6)

		If aFieldSH6[nX] <> "H6_DTAPONT"

			If aFieldSH6[nX] == "H6_DATAINI"
				aFieldTmp := aClone(aFieldAdd[aScan(aFieldAdd, {|x| AlLTrim(x[1]) == aFieldSH6[nX]})])
				cOrdem := Soma1(cOrdem)

				aFieldTmp[1] := "H6_DTAPONT"
				aFieldTmp[2] := cOrdem
				aFieldTmp[3] := "Data Apont."
				aFieldTmp[4] := "Data Apont."
				aFieldTmp[10] := .T.
				aFieldTmp[15] := ""
				aFieldTmp[16] := .T.
				aFieldTmp[18] := .F.
				aFieldTmp[20] := .F.

				aAdd(oStSH6:aFields, aClone(aFieldTmp))
			EndIf

			cOrdem    := Soma1(cOrdem)
			nPosition := aScan(aFieldAdd, {|x| AlLTrim(x[1]) == aFieldSH6[nX]})

			If nPosition > 0
				aFieldAdd[nPosition][2] := cOrdem
				aAdd(oStSH6:aFields, aClone(aFieldAdd[nPosition]))
			EndIf
		EndIf
	NEXT

	//Atribuindo formulários para interface
	oView:AddField("VIEW_ZH7", oStZH7, "ZH7MASTER")
	oView:AddGrid("VIEW_ZGH",  oStZGH, "ZGHDETAIL")

	// Habilita aba para apontamento da operação informando o produto acabado.
	If lHabOpPa .And. cProcesso $ cTiposZHL
		oView:AddGrid("VIEW_ZHL",  oStZHL, "ZHLDETAIL") // Operação vs Produto Acabado
	EndIf

	oView:AddGrid("VIEW_ZGI",  oStZGI, "ZGIDETAIL")
	oView:AddGrid("VIEW_MOD",  oStMOD, "MODDETAIL")
	oView:AddGrid("VIEW_ZGK",  oStZGK, "ZGKDETAIL")
	oView:AddGrid("VIEW_ZGL",  oStZGL, "ZGLDETAIL")
	oView:AddGrid("VIEW_SH6",  oStSH6, "SH6DETAIL")

	If cProcesso $ "S" .And. cHabCorte == "1" .And. cTipRec $ "T/M/N/B"
		oView:AddGrid("VIEW_ZS3",  oStZS3, "ZS3DETAIL")
		oView:AddGrid("VIEW_ZS7",  oStZS7, "ZS7DETAIL")
	EndIf

	// Colocar Filtro e Pesquisa nos Grids
	oView:SetViewProperty("*", "GRIDFILTER", {.T.})
	oView:SetViewProperty("*", "GRIDSEEK"  , {.T.})

	// Coloca ordenacao do grid
	oView:SetViewProperty( "*", "GRIDNOORDER")

	//Criando um container com nome tela com 100%
	oView:CreateHorizontalBox("SUPERIOR",20)
	oView:CreateHorizontalBox("INFERIOR",80)

	// Pasta que conterá cada uma das guias
	oView:CreateFolder('FOLDER','INFERIOR')

	//INCLUIR DADOS OP.
	If lIncluiOp

		oView:AddGrid("VIEW_ZH8" 	, oStZH8	, "ZH8DETAIL")
		oView:AddGrid("VIEW_ZH9" 	, oStZH9	, "ZH9DETAIL")

		oView:AddSheet('FOLDER', 'MATPRIMA', 'Matéria-Prima' )

		// MATERIA - PRIMA
		//Separa em Horizontal na aba dentro da MATERIA-PRIMA para aparecer Produto Acabado
		oView:CreateHorizontalBox("BOX_MATP_1" , 040 ,,, 'FOLDER', 'MATPRIMA')
		oView:CreateHorizontalBox("BOX_MATP_2" , 060 ,,, 'FOLDER', 'MATPRIMA')

		oView:SetOwnerView('VIEW_ZH8','BOX_MATP_1') 	   // Engenharia x Materia-Prima

		//Cria as abas Insumo/Recursos/Mao-de-Obra/Ferramentas
		oView:CreateFolder('FOL_MATP1','BOX_MATP_2')
		oView:AddSheet('FOL_MATP1'	  ,'FOL_MATP1_PA', 'Produto Acabado' )

		// Cria os BOX de 100% para cada pastas dentro da operacão
		oView:CreateHorizontalBox("FOL_MATP1_PA_BOX1" , 100 ,,, 'FOL_MATP1', 'FOL_MATP1_PA')

		oView:SetOwnerView('VIEW_ZH8','BOX_MATP_1') 	   // Engenharia x Materia-Prima
		oView:SetOwnerView('VIEW_ZH9','FOL_MATP1_PA_BOX1') // Engenharia x Materia-Prima x Produto Acabado

	EndIf

	oView:AddSheet('FOLDER','OPERACAO','Operações' )
	oView:AddSheet('FOLDER','HORAIMPR','Paradas' )

	If cProcesso $ "S" .And. cHabCorte == "1" .And. cTipRec $ "T/M/N/B"
		oView:AddSheet('FOLDER','CONFERENCIA','Controle de Corte' )
	EndIf

	// OPERAÇÕES
	//Separa em Horizontal na aba dentro da OPERACOES para aparecer Insumo/Recursos/Mao-de-Obra/Ferramentas
	oView:CreateHorizontalBox("BOX_OPER_1",040,,,'FOLDER','OPERACAO')
	oView:CreateHorizontalBox("BOX_OPER_2",060,,,'FOLDER','OPERACAO')

	//Cria as abas Insumo/Recursos/Mao-de-Obra/Ferramentas
	oView:CreateFolder('FOL_OPER1','BOX_OPER_2')

	// Habilita aba para apontamento da operação informando o produto acabado.
	If lHabOpPa .And. cProcesso $ cTiposZHL
		oView:AddSheet('FOL_OPER1','FOL_OPER1_PA','Produto Acabado')
	EndIf

	oView:AddSheet('FOL_OPER1','FOL_OPER1_IN','Insumos')
	oView:AddSheet('FOL_OPER1','FOL_OPER1_CI','Custo Indireto')
	oView:AddSheet('FOL_OPER1','FOL_OPER1_MO','Mão-de-Obra')
	oView:AddSheet('FOL_OPER1','FOL_OPER1_FE','Ferramentas')

	// Cria os BOX de 100% para cada pastas dentro da operacão

	// Habilita aba para apontamento da operação informando o produto acabado.
	If lHabOpPa .And. cProcesso $ cTiposZHL
		oView:CreateHorizontalBox("FOL_OPER1_PA_BOX1",100,,,'FOL_OPER1','FOL_OPER1_PA')
	EndIf

	oView:CreateHorizontalBox("FOL_OPER1_IN_BOX1",100,,,'FOL_OPER1','FOL_OPER1_IN')
	oView:CreateHorizontalBox("FOL_OPER1_CI_BOX1",100,,,'FOL_OPER1','FOL_OPER1_CI')
	oView:CreateHorizontalBox("FOL_OPER1_MO_BOX1",100,,,'FOL_OPER1','FOL_OPER1_MO')
	oView:CreateHorizontalBox("FOL_OPER1_FE_BOX1",100,,,'FOL_OPER1','FOL_OPER1_FE')

	// HORAS IMPRODUTIVAS
	//Separa em Horizontal na aba dentro da GRUPO DE USUARIOS
	oView:CreateHorizontalBox("GRID_HI", 100,,, 'FOLDER', 'HORAIMPR')

	If cProcesso $ "S" .And. cHabCorte == "1" .And. cTipRec $ "T/M/N/B"
		oView:CreateHorizontalBox("GRID_ZS3", 50,,, 'FOLDER', 'CONFERENCIA')
		oView:CreateHorizontalBox("GRID_ZS7", 50,,, 'FOLDER', 'CONFERENCIA')
	EndIf

	// Coloca as grids nos espaços destinados
	oView:SetOwnerView('VIEW_ZH7','SUPERIOR')   	   // Ordem de Produção
	oView:SetOwnerView('VIEW_ZGH','BOX_OPER_1') 	   // Operacao

	// Habilita aba para apontamento da operação informando o produto acabado.
	If lHabOpPa .And. cProcesso $ cTiposZHL
		oView:SetOwnerView('VIEW_ZHL','FOL_OPER1_PA_BOX1') // Operacao x Produto Acabado
	EndIf

	oView:SetOwnerView('VIEW_ZGI','FOL_OPER1_IN_BOX1') // Operacao x Insumo
	oView:SetOwnerView('VIEW_MOD','FOL_OPER1_CI_BOX1') // Operacao x Custo Indireto
	oView:SetOwnerView('VIEW_ZGK','FOL_OPER1_MO_BOX1') // Operacao x Mao-de-obra
	oView:SetOwnerView('VIEW_ZGL','FOL_OPER1_FE_BOX1') // Operacao x Ferramentas

	oView:SetOwnerView('VIEW_SH6','GRID_HI')  		   // Horas Improdutivas

	If cProcesso $ "S" .And. cHabCorte == "1" .And. cTipRec $ "T/M/N/B"
		oView:SetOwnerView('VIEW_ZS3','GRID_ZS3') 	   // Conferência do Corte
		oView:SetOwnerView('VIEW_ZS7','GRID_ZS7') 	   // Fio/Lâmina do Corte

		oView:EnableTitleView('VIEW_ZS3', 'Conferência do Corte')

		If cTipRec $ "T"
			oView:EnableTitleView('VIEW_ZS7', 'Lâmina de Corte')
		Else
			oView:EnableTitleView('VIEW_ZS7', 'Fio Diamantado')
		EndIf
	EndIf

	//Fechar a tela após confirmarad
	oView:SetCloseOnOk({||.T.})

	// Incrementaçõ automatica
	oView:addIncrementField("VIEW_ZGH","ZGH_SEQUEN")
	oView:addIncrementField("VIEW_ZGH","ZGH_ORDEM")

	//Remove os campos de ligação
	oStZGH:RemoveField('ZGH_FILIAL'); oStZGH:RemoveField('ZGH_OP')
	oStZHL:RemoveField('ZHL_FILIAL'); oStZHL:RemoveField('ZHL_OP'); oStZHL:RemoveField('ZHL_SEQUEN')
	oStZGI:RemoveField('ZGI_FILIAL'); oStZGI:RemoveField('ZGI_OP'); oStZGI:RemoveField('ZGI_SEQUEN'); If(FieldPos("ZGI_ORIGEM") > 0 , oStZGI:RemoveField('ZGI_ORIGEM'),"")
	oStMOD:RemoveField('ZGI_FILIAL'); oStMOD:RemoveField('ZGI_OP'); oStMOD:RemoveField('ZGI_SEQUEN')
	oStZGK:RemoveField('ZGK_FILIAL'); oStZGK:RemoveField('ZGK_OP'); oStZGK:RemoveField('ZGK_SEQUEN')
	oStZGL:RemoveField('ZGL_FILIAL'); oStZGL:RemoveField('ZGL_OP'); oStZGL:RemoveField('ZGL_SEQUEN')
	oStSH6:RemoveField('H6_FILIAL');  oStSH6:RemoveField('H6_OP');  oStSH6:RemoveField('H6_YOP')

	If cProcesso $ "S" .And. cHabCorte == "1" .And. cTipRec $ "T/M/N/B"

		oView:addIncrementField("VIEW_ZS3","ZS3_SEQCON")
		oView:addIncrementField("VIEW_ZS7","ZS7_SEQLAN")

		oStZS3:RemoveField('ZS3_FILIAL')
		oStZS3:RemoveField('ZS3_NUM')

		oStZS7:RemoveField('ZS7_FILIAL')
		oStZS7:RemoveField('ZS7_NUM')
		oStZS7:RemoveField('ZS7_SEQUEN')

		oStZGH:RemoveField('ZGH_RECURS')
		oStZGH:RemoveField('ZGH_OPEREP')

		If cTipRec $ "M/N/B"

			oStZS7:RemoveField('ZS7_QLAMIN')
			oStZS7:RemoveField('ZS7_LAMINI')
			oStZS7:RemoveField('ZS7_LAMFIM')

		ElseIf cTipRec $ "T"

			oStZS3:RemoveField('ZS3_CALA')
			oStZS3:RemoveField('ZS3_AMPERA')
			oStZS3:RemoveField('ZS3_VELPER')

			oStZS7:RemoveField('ZS7_LOTECT')
			oStZS7:RemoveField('ZS7_NOTFIO')
			oStZS7:RemoveField('ZS7_QTDFIO')
			oStZS7:RemoveField('ZS7_ESPFIO')
			oStZS7:RemoveField('ZS7_COMFIO')

		EndIf

		oStZS7:SetProperty("ZS7_PRODUT", MVC_VIEW_LOOKUP, "GRSB1A")

	ElseIf cProcesso $ "S" .And. cHabCorte == "1"

		oStZGH:RemoveField('ZGH_RECURS')
		oStZGH:RemoveField('ZGH_OPEREP')

	Else

		oStZGH:RemoveField('ZGH_HRINIC')
		oStZGH:RemoveField('ZGH_HRFINA')

	EndIf

	oView:AddUserButton("F5 - Zerar Apont. Operação", "MAGIC_BMP",{|| GROA045A()}, "Zerar Apont. Operação")
	SetKey(VK_F5, {|| GROA045A()})

	If cProcesso $ "S" .And. cHabCorte == "1" .And. cTipRec $ "T/M/N/B"
		oView:AddUserButton("F6 - Calcular Consumo", "", {|| U_GR38CALC(oView) }, "Calcular Consumo de Fio/Lâmina")
		SetKey(VK_F6, {|| U_GR38CALC(oView)})
	EndIf

	// Seta a cor de backgroud da linha selecionda
	cGridCSS := "QTableView { "
	cGridCSS += " selection-background-color: #B0C4DE; "
	cGridCSS += " } "

	oView:SetViewProperty("VIEW_ZGH", "SETCSS", { cGridCSS } )
	oView:SetViewProperty("VIEW_SH6", "SETCSS", { cGridCSS } )

	If cProcesso $ "S" .And. cHabCorte == "1" .And. cTipRec $ "T/M/N/B"
		oView:SetViewProperty("VIEW_ZS3", "SETCSS", { cGridCSS } )
		oView:SetViewProperty("VIEW_ZS7", "SETCSS", { cGridCSS } )
	EndIf

Return oView

/*/{Protheus.doc} SetAfter
Executa após carregar a View.
Necessário pois alguns objetos só são instanciados após carregar a View.
@type User Function
@author Kenny Roger Martins
@since 29/03/2020
@version version
/*/
Static Function SetAfter(oView)

	oView:GetViewObj("ZHLDETAIL")[3]:oBrowse:bHeaderClick := {|oBrowse| InvertAll(oBrowse, oView)}

Return Nil

/*/{Protheus.doc} InvertAll
Inverter o checkbox dos registros da grid.
@type User Function
@author Kenny Roger Martins
@since 29/03/2020
@version version
/*/
Static Function InvertAll(oBrowse, oView)

	Local oModelZHL := oView:GetModel("ZHLDETAIL")
	Local oColumn   := oBrowse:GetColumn()
	Local i         := 0

	If oColumn:cId == "ZHL_CHECK"

		If oModelZHL:CanUpdateLine()

			For i := 1 to oModelZHL:Length()
				oModelZHL:GoLine(i)
				If oModelZHL:GetValue("ZHL_CHECK")
					oModelZHL:SetValue("ZHL_CHECK", .F.)
				Else
					oModelZHL:SetValue("ZHL_CHECK", .T.)
				EndIf
			Next

			oModelZHL:GoLine(1)

			If !isBlind()
				oView:Refresh()
			EndIf

		EndIf

	EndIf

Return Nil

/*/{Protheus.doc} VldZGI
Validação dos Itens de Insumo
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
Static Function VldZGI(oModel)

	Local cCodPro := oModel:GetModel("ZGIDETAIL"):GetValue("ZGI_PRODUT")
	Local lRet := .t.
	Local cMsg := ""
	Local cSolu := ""

	SB1->(DbsetOrder(1))

	If SB1->(DbSeek(FwXFilial("SB1") + cCodPro))

		// VerIfica se o produto é considerado como custo indireto
		If Empty(SB1->B1_CCCUSTO) .AND. SUBSTR(SB1->B1_COD,1,3) <> "MOD"
			Return .T.

		Else
			cMsg := "Produto é considerado como Custo indireto."
			cSolu:= "Favor informar o mesmo na aba CUSTO INDIRETO"
			Help(Nil, Nil, "GROA045 - ValidZGI", Nil, cMsg ,1, 0, Nil, Nil, Nil, Nil, Nil, {cSolu})
			Return .F.
		End If

	Else
		Return .F.
	End If

Return lRet


/*/{Protheus.doc} VldMOD
Validação dos Itens de Custo Direto
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
Static Function VldMOD(oModel)

	Local cCodPro := oModel:GetModel("MODDETAIL"):GetValue("ZGI_PRODUT")
	Local lRet := .t.
	Local cMsg := ""
	Local cSolu := ""

	SB1->(DbsetOrder(1))

	If SB1->(DbSeek(FwXFilial("SB1") + cCodPro))

		// VerIfica se o produto é considerado como custo indireto
		If !Empty(SB1->B1_CCCUSTO) .or. SUBSTR(SB1->B1_COD,1,3) == "MOD"
			Return .T.

		Else
			cMsg := "Produto é considerado como Insumo."
			cSolu:= "Favor informar o mesmo na aba INSUMO"
			Help(Nil, Nil, "GROA045 - ValidZGI", Nil, cMsg ,1, 0, Nil, Nil, Nil, Nil, Nil, {cSolu})
			Return .F.
		End If

	Else
		Return .F.
	End If

Return lRet

/*/{Protheus.doc} Grava
Grava o apontamento de produção.
@type User Function
@author Totvs Vitoria
@since 08/08/2019
@version version
/*/
Static Function Grava(oModel)

	Local lRet     := .T.
	Local aRet     := {.t.,""}
	Local cMsgErro := ""
	Local oView := nil
	Local lHabOpPa  := GETNEWPAR("GR_HABOPPA", .F.)   // Habilita aba para vincular Operação ao Produto Acabado.
	Local cRotCria   := ""
	Local lRotNova   := .f.
	Local cNumOp    := ""

	IF (ZH7->(FieldPos("ZH7_ROTINA"))> 0)
		cRotCria  :=	oModel:GetModel("ZH7MASTER"):GetValue("ZH7_ROTINA")
	EndIF

	lRotNova  :=  alltrim(cRotCria) $ "GROA060/GROA062"

	if lRotNova
		lHabOpPa := .t.
	EndIf

	//Criado esse if para separar quando existe a opção de incluir uma op pelo apantamento da opção normal que somente aponte
	if !isblind() .and. lIncluiOp .AND. Inclui

		Begin Transaction

			//Cria ordem de produção
			If aRet[1]
				aRet := CRIAOP(@cNumOp,oModel)
			EndIf

			//Faz o apontamento
			if aRet[1]
				FWMsgRun(, {|oSay| aRet := GravaExe(oSay,oModel)}, "Processando", "Processando apontamento de insumos de produção...")
			EndIf

			//Encerra a ordem de produção
			If aRet[1]
				aRet := ENCEROP(cNumOp,oModel)
			EndIf

			If !aRet[1]
				DisarmTransaction()
			EndIf

		End Transaction

	Else

		if aRet[1]
			FWMsgRun(, {|oSay| aRet := GravaExe(oSay,oModel)}, "Processando", "Processando apontamento de insumos de produção...")
		EndIf

	EndIf

	lRet     := aRet[1]
	cMsgErro := aRet[2]

	If !lRet
		//Coloquei esse campo porque quero alterar os apontamentos sem viewdef.
		//Quando chamo somente o modelo sem ser via rest o sistema apresenta erro
		If type("__cSemView") != "U"  .and. __cSemView == "SIM"
			oModel:SetErrorMessage("",,oModel:GetId(),"","GROA045",cMsgErro)
			// Help(NIL, NIL, "GROA045", NIL, cMsgErro, 1, 0, NIL, NIL, NIL, NIL, NIL, {""})
			ConOut(cMsgErro)
		Else
			// Ativa o Modelo provisoriamente para recurar o
			// código do processo e a situação.
			oModel:Activate()
			cProcesso := oModel:GetModel("ZH7MASTER"):GetValue("ZH7_PROCES")

			if !isBlind()
				oView := FwViewactive()
				oView:Refresh("ZGHDETAIL")


				// Habilita aba para apontamento da operação informando o produto acabado.
				If lHabOpPa .And. cProcesso $ cTiposZHL
					oView:Refresh("ZHLDETAIL")
				EndIf

				oView:Refresh("ZGIDETAIL")
				oView:Refresh("MODDETAIL")
				oView:Refresh("ZGKDETAIL")
				oView:Refresh("ZGLDETAIL")
				oView:Refresh("SH6DETAIL")
			EndIf

		EndIF

		oModel:SetErrorMessage("",,oModel:GetId(),"","GROA045",cMsgErro)
		// Help(NIL, NIL, "GROA045", NIL, cMsgErro, 1, 0, NIL, NIL, NIL, NIL, NIL, {""})
		ConOut(cMsgErro)

	EndIf

Return lRet

/*/{Protheus.doc} GravaExe
Grava o apontamento de produção.
@type User Function
@author Totvs Vitoria
@since 08/08/2019
@version version
/*/
Static Function GravaExe(oSay,oModel)

	local lRet      := .T.
	Local oModelZH7 := oModel:GetModel("ZH7MASTER") // Ordem de produção
	Local oModelSH6 := oModel:GetModel("SH6DETAIL") // Paradas - Hora improdutiva
	Local oModelZGH := oModel:GetModel("ZGHDETAIL") // Operações
	Local oModelZGI := oModel:GetModel("ZGIDETAIL") // Insumos
	Local oModelMOD := oModel:GetModel("MODDETAIL") // Custo indireto
	Local oModelZGK := oModel:GetModel("ZGKDETAIL") // Mão-de-Obra
	Local oModelZGL := oModel:GetModel("ZGLDETAIL") // Ferramenta
	Local oModelZHL := oModel:GetModel("ZHLDETAIL") // Operações x Produto Acabado

	Local oModelZH8 := NIL
	Local oModelZH9 := NIL

	Local aChangSH6 := oModelSH6:GetLinesChanged()
	Local aChangZGH := oModelZGH:GetLinesChanged()
	Local aChangZGI := oModelZGI:GetLinesChanged()
	Local aChangMOD := oModelMOD:GetLinesChanged()
	Local aChangZGK := oModelZGK:GetLinesChanged()
	Local aChangZGL := oModelZGL:GetLinesChanged()
	Local aChangZHL := oModelZHL:GetLinesChanged()
	Local cRecurso  := oModelZH7:GetValue("ZH7_RECURS")
	Local cNumeroOp := oModelZH7:GetValue("ZH7_NUM")
	Local cSituacao := oModelZH7:GetValue("ZH7_SITUAC")
	Local cProcesso := oModelZH7:GetValue("ZH7_PROCES")
	local cSequenOp	:= ""
	local aAutoSH6	:= {}
	local nQtdeOp	:= 0
	local nSomaOp	:= 0
	Local nAuxIns 	:= 0
	Local nQtdIns 	:= 0
	Local nInsumo   := 0
	local nSH6		:= 0
	Local dDataEnc	:= Nil
	Local cMotivo   := ""
	Local nX        := 0
	Local nY        := 0
	Local nZ        := 0
	Local nW        := 0
	Local lApontam  := GETNEWPAR("GR_APONTAM", .F.)   // Permite encerramento da Op sem apontamento.
	Local cTmRqIns  := GETNEWPAR("GR_TMRQINS", "501") // Tipo movimentação utilizado na requisição de insumo para Op.
	Local cTmRqMod  := GETNEWPAR("GR_TMRQMOD", "501") // Tipo movimentação utilizado na requisição de Mod para Op.
	Local nRecLock  := GETNEWPAR("GR_RECLOCK", 1)     // 0=Utiliza ExecAuto, 1=Utiliza Reclok.
	Local lHabOpPa  := GETNEWPAR("GR_HABOPPA", .F.)   // Habilita aba para vincular Operação ao Produto Acabado.
	Local lLisence  := GETNEWPAR("GR_LISENSE", .F.)  // Parametro para o sistema pegar o ultimo valor do lisense. O ini precisa estar gerenciando pelo lisense : checkspecialkey=1
	Local oUtil     := util():new()
	Local lAltGrid	:= .F.
	Local dDtLmte   := GetMv("MV_ULMES")
	Local aRet 		:= {}
	Local cRotCria  := ""
	Local lRotNova  := .T.
	Local lEmpenha  := GETNEWPAR("GR_HABEMPE", .F.) // Habilita aba para vincular Operação ao Produto Acabado.
	Local lGeraSH6  := GETNEWPAR("GR_GERASH6", .F.) // Habilita o apontamento pela rotina padrão MATA681 que alimenta a tabela SH6.
	Local cOperSh6  := ""
	Local aRetSH6	:= {.F.,""}
	Local cRecurSH6 := ""
	Local cHabCorte := GETNEWPAR("GR_HABCORT", "0") // Habilita controle de corte
	Local aDataZGH  := oModelZGH:ADATAMODEL
	Local nKeyZGH   := 0
	Local nRegTotal := 0
	Local nTmpTotal := 0
	Local nTempo    := 0
	Local cKeyValue := ""
	Local nZHL      := 0
	Local aAuxZHL   := {}
	Local lAltDado  := .f.

	Private lMsErroAuto	:= .F.
	Private lGrPlus     := .T.
	Private __aVetPriv  := {}

	//---------------------------------------------------
	// Variáveis utilizadas pelos gatilhos da SD3.
	//---------------------------------------------------
	Private l240 := .F.
	Private l241 := .F.
	Private l242 := .F.
	Private l261 := .F.

	If lIncluiOp
		oModelZH8 := oModel:GetModel("ZH8DETAIL") // Materia prima
		oModelZH9 := oModel:GetModel("ZH9DETAIL") // Materia prima x Produto Acabado
	EndIf

	//Quando utilizar o site para apontar o sistema deixa apontar op encerrada
	If type("__cRotUtil") != "U"  .and. __cRotUtil == "GRWEB"
		lApontam := .T.
	EndIF

	IF (ZH7->(FieldPos("ZH7_ROTINA"))> 0)
		cRotCria   := oModelZH7:GetValue("ZH7_ROTINA")
	EndIF

	lRotNova  :=  alltrim(cRotCria) $ "GROA060/GROA062"

	If lRotNova
		lHabOpPa := .t.
	EndIf

	//Se a OP estiver diferente de pendente ou iniciada, e para apontar de forma normal.
	if lEmpenha .and. !(cSituacao $  'P/I/A')
		lEmpenha := .f.
	EndIf

	ConOut("GrPlusMVC => Processo de apontamento de insumo da OP iniciado.")
	ConOut("GrPlusMVC => Data/Hora Inicio do processamento: " + AllTrim(DtoC(Date())) + " " + AllTrim(Time()) + ".")

	lAltGrid := Len(aChangSH6) <> 0 .OR. Len(aChangZGH) <> 0 .OR. Len(aChangZGI) <> 0 .OR. Len(aChangMOD) <> 0 ;
		.OR. Len(aChangZGK) <> 0 .OR. Len(aChangZGL) <> 0 .OR. Len(aChangZHL) <> 0

	Begin Transaction

		//--------------------------------------------------------
		// VerIfica se existe alguma ordem de produção encerrada.
		//--------------------------------------------------------
		If !lApontam

			If lHabOpPa .And. cProcesso $ cTiposZHL

				SC2->(DbSetOrder(1))
				if SC2->(MsSeek(xFilial("SC2") + cNumeroOp))

					For nX := 1 to oModelZGH:Length()

						oModelZGH:GoLine(nX)

						lAltDado := ((aScan(oModelZGH:GetLinesChanged(), {|x| x == nX}) <= 0);
							.And. (len(oModelZGI:GetLinesChanged()) == 0);
							.And. (len(oModelMOD:GetLinesChanged()) == 0);
							.And. (len(oModelZGK:GetLinesChanged()) == 0);
							.And. (len(oModelZGL:GetLinesChanged()) == 0);
							.And. (len(oModelZHL:GetLinesChanged()) == 0))

						//--------------------------------------------------------
						// Reprocessar somente o que foi alterado
						//--------------------------------------------------------
						if !lAltDado
							//Sistema vai deixar excluir uma operação que não foi apontada.
							ZGH->(DbSetOrder(1))
							If ZGH->(DbSeek(xFilial("ZGH") + oModelZGH:GetValue("ZGH_OP") + oModelZGH:GetValue("ZGH_SEQUEN"))) .AND. EMPTY(ZGH->ZGH_DATAPO)
								loop
							EndIf

							For nZHL := 1 to oModelZHL:Length()

								oModelZHL:GoLine(nZHL)

								cKeyValue := oModelZHL:GetValue("ZHL_OP") + oModelZHL:GetValue("ZHL_ITEM") + oModelZHL:GetValue("ZHL_SEQOP")

								SC2->(dbSetOrder(1))
								If SC2->(DbSeek(xFilial("SC2") + cKeyValue))
									//Precisa confirmar se oque esta no banco esta como verdadeiro no check, para verificar se aquela chapa ja foi apontada anteriormente.
									ZHL->(DbSetOrder(1))
									If ZHL->(DbSeek(xFilial("ZHL") + SC2->C2_NUM + oModelZGH:GetValue("ZGH_SEQUEN") + SC2->C2_ITEM + SC2->C2_SEQUEN)) .and. (ZHL->ZHL_CHECK .Or. oModelZHL:GetValue("ZHL_CHECK") )
										If SC2->C2_QUJE > 0

											cMsgErro := "1) Operação não permitida! Existe produção total ou parcial para essa Ordem de Produção." + Chr(10)
											cMsgErro += "Itens relacionado a operação abaixo foi alterada"+ Chr(10)
											cMsgErro += "Sequencia Oper.: " + oModelZGH:GetValue('ZGH_SEQUEN') + Chr(10)
											cMsgErro += "Ordem Oper.: " + oModelZGH:GetValue('ZGH_ORDEM') + Chr(10)
											cMsgErro += "Operação: " + oModelZGH:GetValue('ZGH_OPERAC') + Chr(10)
											cMsgErro += "Item cabado: " + oModelZHL:GetValue("ZHL_ITEM") + Chr(10)
											cMsgErro += "Ordem de produção: " + cKeyValue + Chr(10)

											DisarmTransaction()
											Return {.F., cMsgErro}
										EndIf
									EndIf

									SC2->(DbSkip())
								EndIf
							next
						EndIf
					next
				EndIf
			Else

				SC2->(DbSetOrder(1))
				SC2->(MsSeek(xFilial("SC2") + cNumeroOp))

				While SC2->(!(Eof())) .And. SC2->(C2_FILIAL + C2_NUM) == xFilial("SC2") + cNumeroOp

					If SC2->C2_QUJE > 0
						cMsgErro := "2) Operação não permitida! Existe produção total ou parcial para essa Ordem de Produção."  + chr(10) + chr(10)
						cMsgErro += "Op: " + SC2->C2_NUM + SC2->C2_ITEM + SC2->C2_SEQUEN + chr(10)
						cMsgErro += "Produção: " + cvaltochar(SC2->C2_QUJE) + chr(10)

						DisarmTransaction()
						Return {.F., cMsgErro}
					EndIf

					SC2->(DbSkip())
				EndDo

			EndIf
		EndIf

		//--------------------------------------------------------
		// Recalcula consumo de fio/lâmina.
		//--------------------------------------------------------
		If cHabCorte == "1" .And. oModelZH7:GetValue("ZH7_PROCES") == "S"
			U_GR38CALC()
		EndIf

		//--------------------------------------------------------
		// Atualiza campos de paradas.
		//--------------------------------------------------------
		For nX := 1 to Len(aChangSH6)
			oModelSH6:GoLine(aChangSH6[nX])
			oModelSH6:SetValue("H6_TIPO", "I")
		Next

		//----------------------------------------------------
		// Grava modelo no banco.
		//----------------------------------------------------
		FWFormCommit(oModel)

		//Caso o sistema venha da tela GROA060 e GROA062  o sistema precisa refazer os empenhos
		If !(type("lRoti06")=="L".and. lRoti06)
			lAltGrid := .T.
		EndIf

		// Validando se houve alguma alteração nos grids
		If lAltGrid
			//--------------------------------------------------------
			// Percorre todas as operações.
			//--------------------------------------------------------
			If oModelZGH:CanUpdateLine()

				For nX := 1 to oModelZGH:Length()

					If ValType(oSay) <> "U"
						oSay:SetText("Processando apontamento de insumos " + cNumeroOp + cSequenOp + "...")
						ProcessMessage()
					EndIf

					oModelZGH:GoLine(nX)

					//--------------------------------------------------------
					// Reprocessar somente o que foi alterado
					//--------------------------------------------------------
					if((aScan(oModelZGH:GetLinesChanged(), {|x| x == nX}) <= 0);
							.And. (len(oModelZGI:GetLinesChanged()) == 0);
							.And. (len(oModelMOD:GetLinesChanged()) == 0);
							.And. (len(oModelZGK:GetLinesChanged()) == 0);
							.And. (len(oModelZGL:GetLinesChanged()) == 0);
							.And. (len(oModelZHL:GetLinesChanged()) == 0))

						loop

					EndIF

					cSequenOp := oModelZGH:GetValue("ZGH_SEQUEN")

					If !CtbValiDt(nil,oModelZGH:GetValue("ZGH_DATAPO"),.F.,,,{"EST001"})
						cMsgErro := "Calendário Contábil Bloqueado. Verfique o processo. Data: " + DTOS(oModelZGH:GetValue("ZGH_DATAPO"))
						DisarmTransaction()
						ConOut(cMsgErro)
						Return {.F., cMsgErro}
					ENDIF

					//--------------------------------------------------------
					// Exclui requisições.
					//--------------------------------------------------------
					cAliasSD3 := "TMPSD3"
					ChkFile("SD3", .F., cAliasSD3)
					DbSelectArea(cAliasSD3)
					(cAliasSD3)->(DbSetOrder(1))
					(cAliasSD3)->(DbSeek(xFilial("SD3") + cNumeroOp))

					//Ticket https://totvsleste.freshdesk.com/a/tickets/6228
					If ((!EMPTY( oModelZGH:GetValue("ZGH_DATAPO")) .AND. oModelZGH:GetValue("ZGH_DATAPO") <= dDtLmte))

						(cAliasSD3)->(DbCloseArea())

						Loop
					EndIf

					While (cAliasSD3)->(!eof()) .and. (cAliasSD3)->(D3_FILIAL + SubStr(D3_OP, 1, TamSX3("C2_NUM")[1])) == xFilial("SD3") + cNumeroOp

						If ValType(oSay) <> "U"
							oSay:SetText("Processando apontamento de insumos... Excluindo requisição " + AllTrim((cAliasSD3)->D3_OP) + "...")
							ProcessMessage()
						EndIf

						If AllTrim((cAliasSD3)->D3_TRT) == AllTrim(cSequenOp) .And. (cAliasSD3)->D3_ESTORNO <> "S"

							If lApontam
								//--------------------------------------------------
								// Entra caso permite encerramento sem apontamento.
								//--------------------------------------------------
								SC2->(DbSetOrder(1))
								SC2->(DbSeek(xFilial("SC2") + (cAliasSD3)->D3_OP))

								dDataEnc := SC2->C2_DATRF

								RecLock("SC2", .F.)
								SC2->C2_DATRF := StoD("")
								SC2->(MsUnLock())
							EndIf

							aArraySD3 := {}

							aAdd(aArraySD3, {"D3_FILIAL",  (cAliasSD3)->D3_FILIAL,  Nil})
							aAdd(aArraySD3, {"D3_TM", 	   (cAliasSD3)->D3_TM,	    Nil})
							aAdd(aArraySD3, {"D3_OP", 	   (cAliasSD3)->D3_OP, 	    Nil})
							aAdd(aArraySD3, {"D3_COD", 	   (cAliasSD3)->D3_COD,     Nil})
							aAdd(aArraySD3, {"D3_UM", 	   (cAliasSD3)->D3_UM,	    Nil})
							aAdd(aArraySD3, {"D3_LOCAL",   (cAliasSD3)->D3_LOCAL,   Nil})
							aAdd(aArraySD3, {"D3_QUANT",   (cAliasSD3)->D3_QUANT,   Nil})
							aAdd(aArraySD3, {"D3_EMISSAO", (cAliasSD3)->D3_EMISSAO, Nil})
							aAdd(aArraySD3, {"D3_NUMSEQ",  (cAliasSD3)->D3_NUMSEQ,  Nil})
							aAdd(aArraySD3, {"D3_CHAVE",   (cAliasSD3)->D3_CHAVE,   Nil})
							aAdd(aArraySD3, {"D3_TRT", 	   (cAliasSD3)->D3_TRT,     Nil})

							If !CtbValiDt(nil,(cAliasSD3)->D3_EMISSAO,.F.,,,{"EST001"})
								cMsgErro := "Calendário Contábil Bloqueado. Verfique o processo. Data: " + DTOS((cAliasSD3)->D3_EMISSAO)
								DisarmTransaction()
								ConOut(cMsgErro)
								Return {.F., cMsgErro}
							ENDIF

							lMsErroAuto	:= .f.

							//--------------------------------------------------
							// Exclui Requisições
							//--------------------------------------------------
							If nRecLock == 0

								aAdd(aArraySD3, {"INDEX", 4, Nil})
								MSExecAuto({|x,y| mata240(x,y)}, aArraySD3, 5)

							Else

								SD3->(DbGoTo((cAliasSD3)->(RECNO())))

								//Paliativo erro padrão
								//https://totvsleste.freshdesk.com/a/tickets/2828
								//U_CHAMODEL()

								oModelD3 := FwLoadModel("GATA240")
								oModelD3:SetOperation(MODEL_OPERATION_DELETE)
								oModelD3:Activate()

								lMsErroAuto := !oModelD3:CommitData()

								If lMsErroAuto
									aErro    := oModelD3:GetErrorMessage()
									cMsgErro := "Mensagem do erro: "    + ' [' + cValToChar(aErro[06]) + '], '
									cMsgErro += "Mensagem da solução: " + ' [' + cValToChar(aErro[07]) + '], '
								EndIf

								oModelD3:Destroy()

							EndIf

							If lMsErroAuto
								(cAliasSD3)->(DbCloseArea())
								DisarmTransaction() // Desarmando a transação antes da tela mostrar erro. Ja vi usuários finalizando a tela de mostrar erro e o desarme não executa
								If nReclock == 0
									If (IsBlind())
										cMsgErro :=  MostraErro("/error", "error.log")
									Else
										MostraErro()
										cMsgErro := "2) Ocorreu um problema no execauto MATA240. Favor contactar o administrador do sistema. Produto:"+Alltrim(aArraySD3[4][2])+" Local:"+Alltrim(aArraySD3[5][2]) + " Lote:"+ Alltrim(aArraySD3[6][2]) + " SubLote:"+ Alltrim(aArraySD3[7][2])
									EndIf
								EndIf
								Return {.F., cMsgErro}
							EndIf

							If lApontam
								//--------------------------------------------------
								// Entra caso permite encerramento sem apontamento.
								//--------------------------------------------------
								RecLock("SC2", .F.)
								SC2->C2_DATRF := dDataEnc
								SC2->(MsUnLock())
							EndIf

						EndIf

						(cAliasSD3)->(DbSkip())

					EndDo

					(cAliasSD3)->(DbCloseArea())

					//--------------------------------------------------
					// Excluir Empenhos
					//--------------------------------------------------
					cAliasSD4 := "TMPSD4"
					ChkFile( "SD4" , .F. , cAliasSD4 )
					DbSelectArea(cAliasSD4)
					(cAliasSD4)->(dbSetOrder(2))
					(cAliasSD4)->(msSeek(xFilial("SD4") + cNumeroOp))
					While (cAliasSD4)->(!eof()) .and. (cAliasSD4)->(D4_FILIAL + D4_YOP) == xFilial("SD4") + cNumeroOp

						If ValType(oSay) <> "U"
							oSay:SetText("Processando apontamento de insumos... Excluindo empenho " + AllTrim((cAliasSD4)->D4_OP) + "...")
							ProcessMessage()
						EndIf

						If alltrim((cAliasSD4)->D4_TRT) == alltrim(cSequenOp)

							aArraySD4		:= {}

							aAdd(aArraySD4, {"D4_FILIAL", (cAliasSD4)->D4_FILIAL, Nil})
							aAdd(aArraySD4, {"D4_COD", 	  (cAliasSD4)->D4_COD,	  Nil})
							aAdd(aArraySD4, {"D4_LOCAL",  (cAliasSD4)->D4_LOCAL,  Nil})
							aAdd(aArraySD4, {"D4_OP", 	  (cAliasSD4)->D4_OP, 	  Nil})
							aAdd(aArraySD4, {"D4_TRT", 	  (cAliasSD4)->D4_TRT,	  Nil})

							lMsErroAuto	:= .f.

							//--------------------------------------------------
							// Exclui empenho
							//--------------------------------------------------
							MSExecAuto({|x,y| mata380(x,y)}, aArraySD4, 5)

							SD4->(MsUnLock("SD4"))

							If lMsErroAuto
								(cAliasSD4)->(DbCloseArea())
								// cMsgErro := MemoRead(NomeAutoLog())
								DisarmTransaction()
								If (IsBlind())
									cMsgErro :=  MostraErro("/error", "error.log")
								Else
									MostraErro()
									cMsgErro := "3) Ocorreu um problema no execauto MATA380. Favor contactar o administrador do sistema. Produto:"+ alltrim(aArraySD4[2][2]) + " Local:"+ alltrim(aArraySD4[3][2]) + " Op:" + alltrim(aArraySD4[4][2])
								EndIf
								Return {.F., cMsgErro}
							EndIf

						EndIf

						(cAliasSD4)->(DbSkip())

					EndDo

					(cAliasSD4)->(DbCloseArea())

					//--------------------------------------------------
					// Grava operação na tabela padrão do protheus
					//--------------------------------------------------
					SC2->(dbSetOrder(1))
					SC2->(msSeek(xFilial("SC2") + cNumeroOp))
					While SC2->(!eof()) .and. SC2->(C2_FILIAL + C2_NUM) == xFilial("SC2") + cNumeroOp

						If ValType(oSay) <> "U"
							oSay:SetText("Processando apontamento de insumos... Gravando operação " + AllTrim(SC2->(C2_NUM + C2_ITEM + C2_SEQUEN)) + "...")
							ProcessMessage()
						EndIf

						//--------------------------------------------------------
						// Data do apontamento não pode ser menor que a data
						// da ordem de produção e nem maior que o encerramento.
						//--------------------------------------------------------
						If lHabOpPa .And. SC2->C2_YTIPO $ cTiposZHL
							ZHL->(DbSetOrder(1))
							If ZHL->(DbSeek(xFilial("ZHL") + SC2->C2_NUM + cSequenOp + SC2->C2_ITEM + SC2->C2_SEQUEN)) .and. ZHL->ZHL_CHECK

								If ((!EMPTY( oModelZGH:GetValue("ZGH_DATAPO")) .AND. oModelZGH:GetValue("ZGH_DATAPO") < SC2->C2_EMISSAO) .Or. ( !EMPTY( oModelZGH:GetValue("ZGH_DATAPO")) .AND. oModelZGH:GetValue("ZGH_DATAPO") > SC2->C2_DATRF .And. !Empty(SC2->C2_DATRF)))

									cMsgErro := "(1) A data do apontamento não pode ser menor que a data de emissão da OP e nem maior que a data de encerramento da OP, favor verificar!" + chr(10)+ chr(10)
									cMsgErro += "Op: " + SC2->C2_NUM + SC2->C2_ITEM + SC2->C2_SEQUEN + chr(10)
									cMsgErro += "Seq Apontamento: " + cSequenOp + chr(10)
									cMsgErro += "Dt.Apontamento: "  + U_FORMTADT(oModelZGH:GetValue("ZGH_DATAPO")) + chr(10)
									cMsgErro += "Dt.Emissão: "      + U_FORMTADT(SC2->C2_EMISSAO) + chr(10)
									cMsgErro += "Dt.Encerramento: " + U_FORMTADT(SC2->C2_DATRF) + chr(10)

									DisarmTransaction()
									Return {.F., cMsgErro}

								EndIf

							EndIf
						Else

							If ((!EMPTY( oModelZGH:GetValue("ZGH_DATAPO")) .AND. oModelZGH:GetValue("ZGH_DATAPO") < SC2->C2_EMISSAO) .Or. ( !EMPTY( oModelZGH:GetValue("ZGH_DATAPO")) .AND. oModelZGH:GetValue("ZGH_DATAPO") > SC2->C2_DATRF .And. !Empty(SC2->C2_DATRF)))

								cMsgErro := "(2) A data do apontamento não pode ser menor que a data de emissão da OP e nem maior que a data de encerramento da OP, favor verificar!"
								cMsgErro += "Op: " + SC2->C2_NUM + SC2->C2_ITEM + SC2->C2_SEQUEN + chr(10)
								cMsgErro += "Seq Apontamento: " + cSequenOp + chr(10)
								cMsgErro += "Dt.Apontamento: "  + U_FORMTADT(oModelZGH:GetValue("ZGH_DATAPO")) + chr(10)
								cMsgErro += "Dt.Emissão: "      + U_FORMTADT(SC2->C2_EMISSAO) + chr(10)
								cMsgErro += "Dt.Encerramento: " + U_FORMTADT(SC2->C2_DATRF) + chr(10)

								DisarmTransaction()
								Return {.F., cMsgErro}

							EndIf

						EndIf

						SGF->(dbSetOrder(1))
						If SGF->(!msSeek(xFilial("SGF") + SC2->(C2_PRODUTO) + "GE" + cSequenOp))

							aRegistro := {}
							aAdd(aRegistro, {"GF_FILIAL",  xFilial("SGF"),  Nil})
							aAdd(aRegistro, {"GF_PRODUTO", SC2->C2_PRODUTO, Nil})
							aAdd(aRegistro, {"GF_ROTEIRO", "GE",            Nil})
							aAdd(aRegistro, {"GF_OPERAC",  cSequenOp,       Nil})
							aAdd(aRegistro, {"GF_TRT",     cSequenOp,       Nil})

							cMsgErro := oUtil:setExecAuto('SGF', aRegistro, 'GF_PRODUTO+GF_ROTEIRO+GF_OPERAC', 3)

							If !Empty(cMsgErro)
								DisarmTransaction()
								Return {.F., cMsgErro}
							Else
								SC2->(reclock("SC2", .F.))
								SC2->C2_ROTEIRO := "GE"
								SC2->(MsUnLock())
							EndIf

						EndIf

						SC2->(DbSkip())

					EndDo

					If (oModelZGH:GetValue("ZGH_DATAPO") > dDataBase .Or. ;
							oModelZGH:GetValue("ZGH_DATINI") > dDataBase .Or. ;
							oModelZGH:GetValue("ZGH_DATFIM") > dDataBase)

						cMsgErro := "A data do apontamento não pode ser maior que a data atual, favor verificar!" + chr(10) + chr(10)
						cMsgErro += "Dt.Apontamento: "  + U_FORMTADT(oModelZGH:GetValue("ZGH_DATAPO")) + chr(10)
						cMsgErro += "Dt.Atual: "        + U_FORMTADT(dDataBase) + chr(10)

						DisarmTransaction()
						Return {.F., cMsgErro}

					EndIf

					//--------------------------------------------------
					// Incluir Empenhos
					// Caso a Operação esteja encerrada faz o empenho
					//--------------------------------------------------
					If !Empty(StrTran(oModelZGH:GetValue("ZGH_HORFIM"), ":", ""))

						//--------------------------------------------------
						// Percorre insumos da operação
						//--------------------------------------------------
						ZGI->(dbSetOrder(1))
						ZGI->(msSeek(xFilial("ZGI") + cNumeroOp + cSequenOp))
						While ZGI->(!eof()) .and. ZGI->(ZGI_FILIAL + ZGI_OP + ZGI_SEQUEN) == xFilial("ZGI") + cNumeroOp + cSequenOp

							//--------------------------------------------------
							// Soma quantidade de Op para fazer o rateio da
							// quantidade de Insumo
							//--------------------------------------------------
							nSomaOp := 0
							nQtdeOp := 0
							SC2->(dbSetOrder(1))
							SC2->(msSeek(xFilial("SC2") + cNumeroOp))
							While SC2->(!eof()) .and. SC2->(C2_FILIAL + C2_NUM) == xFilial("SC2") + cNumeroOp

								If ValType(oSay) <> "U"
									oSay:SetText("Processando apontamento de insumos... Calculando total " + AllTrim(SC2->(C2_NUM + C2_ITEM + C2_SEQUEN)) + "...")
									ProcessMessage()
								EndIf


								//-----------------------------------------------------------------------
								// Caso o parâmetro de operação por produto acabado esteja habilitado,
								// o rateio deverá ocorrer apenas para os produtos acabados marcados.
								// Parâmetro válido apenas para beneficiamento e retrabalho.
								//-----------------------------------------------------------------------

								lApropria :=  If(ExistBlock("GR045EST"), ExecBlock("GR045EST", .f., .f., {}), .T.)

								If lApropria

									If lHabOpPa .And. SC2->C2_YTIPO $ cTiposZHL
										ZHL->(DbSetOrder(1))
										If ZHL->(DbSeek(xFilial("ZHL") + SC2->C2_NUM + ZGI->ZGI_SEQUEN + SC2->C2_ITEM + SC2->C2_SEQUEN))
											lApropria := ZHL->ZHL_CHECK
										Else
											lApropria := .F.
										EndIf
									EndIf

									If lApropria
										nQtdeOp++
										nSomaOp += SC2->C2_QUANT
									EndIf

								EndIf

								SC2->(DbSkip())

							EndDo

							nQtdIns := ZGI->ZGI_QTDE

							SB1->(DbSetOrder(1))
							If SB1->(DbSeek(xFilial("SB1") + ZGI->ZGI_PRODUT))
								//Conversão da 2ª Unidade de Medida para a 1ª Unidade de Medida
								If SB1->B1_SEGUM == ZGI->ZGI_UM
									nQtdIns := ConvUM(ZGI->ZGI_PRODUT, 0,  nQtdIns, 1)
								EndIf
							EndIf


							//--------------------------------------------------
							// Após a soma percorre novamente a tabela SC2
							// para fazer o empenho
							//--------------------------------------------------
							SC2->(dbSetOrder(1))
							SC2->(msSeek(xFilial("SC2") + cNumeroOp))
							While SC2->(!eof()) .and. SC2->(C2_FILIAL + C2_NUM) == xFilial("SC2") + cNumeroOp

								If ValType(oSay) <> "U"
									oSay:SetText("Processando apontamento de insumos... Gravando insumo " + AllTrim(SC2->(C2_NUM + C2_ITEM + C2_SEQUEN)) + "...")
									ProcessMessage()
								EndIf


								//-----------------------------------------------------------------------
								// Caso o parâmetro de operação por produto acabado esteja habilitado,
								// o rateio deverá ocorrer apenas para os produtos acabados marcados.
								// Parâmetro válido apenas para beneficiamento e retrabalho.
								//-----------------------------------------------------------------------

								lApropria :=  If(ExistBlock("GR045EST"), ExecBlock("GR045EST", .f., .f., {}), .T.)

								If lApropria

									If lHabOpPa .And. SC2->C2_YTIPO $ cTiposZHL
										ZHL->(DbSetOrder(1))
										If ZHL->(DbSeek(xFilial("ZHL") + SC2->C2_NUM + ZGI->ZGI_SEQUEN + SC2->C2_ITEM + SC2->C2_SEQUEN))
											lApropria := ZHL->ZHL_CHECK
										Else
											lApropria := .F.
										EndIf
									EndIf

									If lApropria

										nAuxIns++

										aArraySD3		:= {}

										cD3_OP := SC2->(C2_NUM + C2_ITEM + C2_SEQUEN)

										aAdd(aArraySD3, {"D3_FILIAL",  xFilial("SD3"), Nil})
										aAdd(aArraySD3, {"D3_EMISSAO", oModelZGH:GetValue("ZGH_DATAPO"), Nil})

										SB1->(DbSetOrder(1))
										SB1->(DbSeek(xFilial("SB1") + ZGI->ZGI_PRODUT))

										If SubStr(SB1->B1_COD, 1, 3) == "MOD" .Or. !Empty(SB1->B1_CCCUSTO)
											aAdd(aArraySD3, {"D3_TM", cTmRqIns, Nil})
										Else
											aAdd(aArraySD3, {"D3_TM", cTmRqIns, Nil})
										EndIf

										aAdd(aArraySD3, {"D3_COD", 		PadR(ZGI->ZGI_PRODUT, TamSX3("D3_COD")[1]),	Nil})
										aAdd(aArraySD3, {"D3_LOCAL",	ZGI->ZGI_LOCAL,	 Nil})
										aAdd(aArraySD3, {"D3_LOTECTL",	ZGI->ZGI_LOTECT, Nil})
										aAdd(aArraySD3, {"D3_NUMLOTE",	ZGI->ZGI_NUMLOT, Nil})
										aAdd(aArraySD3, {"D3_OP", 		PadR(cD3_OP, TamSX3("D3_OP")[1]), 				Nil})

										//--------------------------------------------------
										// Valida o calendário contábil
										//--------------------------------------------------

										If !CtbValiDt(nil,oModelZGH:GetValue("ZGH_DATAPO"),.F.,,,{"EST001"})
											cMsgErro := "Calendário Contábil Bloqueado. Verfique o processo. Data: " + DTOS(oModelZGH:GetValue("ZGH_DATAPO"))
											DisarmTransaction()
											ConOut(cMsgErro)
											Return {.F., cMsgErro}
										ENDIF

										//--------------------------------------------------
										// VerIfica se utiliza segunda unidade de medida
										//--------------------------------------------------

										If SB1->B1_SEGUM == ZGI->ZGI_UM
											If SB1->B1_TIPCONV == "M"
												If nAuxIns <> nQtdeOp
													nInsumo := NOROUND((ZGI->ZGI_QTDE * (SC2->C2_QUANT / nSomaOp) / SB1->B1_CONV), TamSX3("D3_QUANT")[2])
													nQtdIns := nQtdIns - nInsumo
												else
													nInsumo := nQtdIns
													nAuxIns := 0
												EndIf
												aAdd(aArraySD3, {"D3_QUANT", nInsumo, Nil})
											Else
												If nAuxIns <> nQtdeOp
													nInsumo := NOROUND((ZGI->ZGI_QTDE * (SC2->C2_QUANT / nSomaOp) * SB1->B1_CONV), TamSX3("D3_QUANT")[2])
													nQtdIns := nQtdIns - nInsumo
												else
													nInsumo := nQtdIns
													nAuxIns := 0
												EndIf
												aAdd(aArraySD3, {"D3_QUANT", nInsumo, Nil})
											EndIf

											aAdd(aArraySD3, {"D3_QTSEGUM", ConvUm(SB1->B1_COD,nInsumo,0,2) , Nil})

										Else
											If nAuxIns <> nQtdeOp
												nInsumo := NOROUND((ZGI->ZGI_QTDE * (SC2->C2_QUANT / nSomaOp)), TamSX3("D3_QUANT")[2])
												nQtdIns := nQtdIns - nInsumo
											else
												nInsumo := nQtdIns
												nAuxIns := 0
											EndIf

											aAdd(aArraySD3, {"D3_QUANT", nInsumo, Nil})
											aAdd(aArraySD3, {"D3_QTSEGUM", ConvUm(SB1->B1_COD,nInsumo,0,2) , Nil})

										EndIf

										aAdd(aArraySD3, {"D3_TRT", padr(ZGI->ZGI_SEQUEN, TamSX3("D3_TRT")[1]), Nil})

										lMsErroAuto	:= .F.

										//--------------------------------------------------
										// Inclui Empenho
										//--------------------------------------------------
										If lApontam
											//--------------------------------------------------
											// Entra caso permite encerramento sem apontamento.
											//--------------------------------------------------
											dDataEnc := SC2->C2_DATRF
											RecLock("SC2", .F.)
											SC2->C2_DATRF := StoD("")
											SC2->(MsUnLock())
										EndIf

										If lEmpenha
											aRetEmp := EMPENHO(aArraySD3)
											If !aRetEmp[1]
												DisarmTransaction()
												If (IsBlind())
													cMsgErro :=  MostraErro("/error", "error.log")
												Else
													MostraErro()
													cMsgErro := "1) Ocorreu um problema no empenho. Produto:"+Alltrim(aArraySD3[4][2])+" Local:"+Alltrim(aArraySD3[5][2]) + " Lote:"+ Alltrim(aArraySD3[6][2]) + " SubLote:"+ Alltrim(aArraySD3[7][2])
												EndIf
												Return {.F., cMsgErro}
											EndIf
										ElseIf nRecLock == 0

											MSExecAuto({|x,y| mata240(x,y)}, aArraySD3, 3)

										Else

											aAdd(aArraySD3, {"D3_CF",     "RE0",     Nil})
											aAdd(aArraySD3, {"D3_CHAVE",  "E0",      Nil})

											if lLisence
												aAdd(aArraySD3, {"D3_NUMSEQ", NEWPROXNUM(), Nil})
											else
												aAdd(aArraySD3, {"D3_NUMSEQ", ProxNum(), Nil})
											EndIf

											//Paliativo erro padrão
											//https://totvsleste.freshdesk.com/a/tickets/2828
											//U_CHAMODEL()

											oModelD3 := FwLoadModel("GATA240")
											oModelD3:SetOperation(MODEL_OPERATION_INSERT)
											oModelD3:Activate()

											For nY := 1 To Len(aArraySD3)
												oModelD3:SetValue("FORMSD3", aArraySD3[nY][1], aArraySD3[nY][2])
											Next

											lMsErroAuto := !oModelD3:VldData()

											If lMsErroAuto

												aErro    := oModelD3:GetErrorMessage()
												cMsgErro := cValToChar(aErro[06]) + CHR(10)
												cMsgErro += cValToChar(aErro[07])

											Else

												lMsErroAuto := !oModelD3:CommitData()

												If lMsErroAuto
													aErro    := oModelD3:GetErrorMessage()
													cMsgErro := cValToChar(aErro[06]) + CHR(10)
													cMsgErro += cValToChar(aErro[07])
												EndIf

											EndIf

											oModelD3:Destroy()

										EndIf

										If lMsErroAuto
											DisarmTransaction()
											If nRecLock == 0
												If (IsBlind())
													cMsgErro :=  MostraErro("/error", "error.log")
												Else
													MostraErro()
													cMsgErro := "1) Ocorreu um problema no execauto MATA240. Favor contactar o administrador do sistema. Produto:"+Alltrim(aArraySD3[4][2])+" Local:"+Alltrim(aArraySD3[5][2]) + " Lote:"+ Alltrim(aArraySD3[6][2]) + " SubLote:"+ Alltrim(aArraySD3[7][2])
												EndIf
											EndIf
											Return {.F., cMsgErro}
										EndIf

										If lApontam
											//--------------------------------------------------
											// Entra caso permite encerramento sem apontamento.
											//--------------------------------------------------
											RecLock("SC2", .F.)
											SC2->C2_DATRF := dDataEnc
											SC2->(MsUnLock())
										EndIf

									EndIf

								EndIf

								SC2->(DbSkip())
							EndDo

							ZGI->(DbSkip())
						EndDo

					EndIf

					//------------------------------------------------------
					// Apontamento de horas produtivas no padrão protheus.
					//------------------------------------------------------
					If lGeraSH6

						//----------------------------------------------------------------
						// Parâmetro que permite apontamento apenas de Tempo sem produção.
						//----------------------------------------------------------------
						SX1->(DbSetOrder(1))
						SX1->(DbSeek("MTA680    04"))
						RecLock("SX1", .F.)
						SX1->X1_PRESEL := 1
						SX1->(MsUnLock())

						cKeyValue := PadR(oModelZGH:GetValue("ZGH_OP"), TamSX3("H6_YOP")[1]) + oModelZGH:GetValue("ZGH_SEQUEN")

						SH6->(DbOrderNickName("GRSEQUEN"))
						SH6->(DbSeek(xFilial("SH6") + cKeyValue))

						While SH6->(!Eof()) .And. SH6->(H6_FILIAL + H6_YOP + H6_YSEQUEN) == xFilial("SH6") + cKeyValue

							If ValType(oSay) <> "U"
								oSay:SetText("Excluindo operação " + AllTrim(SH6->(H6_FILIAL + H6_YOP + H6_YSEQUEN)) + "...")
								ProcessMessage()
							EndIf

							aAutoSH6 := {}

							aAdd(aAutoSH6, {"H6_FILIAL",  SH6->H6_FILIAL,  Nil})
							aAdd(aAutoSH6, {"H6_OP",      SH6->H6_OP ,     Nil})
							aAdd(aAutoSH6, {"H6_PRODUTO", SH6->H6_PRODUTO, Nil})
							aAdd(aAutoSH6, {"H6_OPERAC",  SH6->H6_OPERAC,  Nil})
							aAdd(aAutoSH6, {"H6_RECURSO", SH6->H6_RECURSO, Nil})
							aAdd(aAutoSH6, {"H6_DTAPONT", SH6->H6_DTAPONT, Nil})
							aAdd(aAutoSH6, {"H6_DATAINI", SH6->H6_DATAINI, Nil})
							aAdd(aAutoSH6, {"H6_HORAINI", SH6->H6_HORAINI, Nil})
							aAdd(aAutoSH6, {"H6_DATAFIN", SH6->H6_DATAFIN, Nil})
							aAdd(aAutoSH6, {"H6_HORAFIN", SH6->H6_HORAFIN, Nil})
							aAdd(aAutoSH6, {"H6_PT",      SH6->H6_PT,      Nil})
							aAdd(aAutoSH6, {"H6_LOCAL",   SH6->H6_LOCAL,   Nil})
							aAdd(aAutoSH6, {"H6_LOTECTL", SH6->H6_LOTECTL, Nil})
							aAdd(aAutoSH6, {"H6_QTDPROD", SH6->H6_QTDPROD, Nil})
							aAdd(aAutoSH6, {"AUTRECNO",   SH6->(Recno()),  Nil})

							// Deletando porque a SH6 não possui opção de alterar.
							MsExecAuto({|x, y| MATA681(x, y)}, aAutoSH6, 5)

							If lMsErroAuto
								cMsgErro := "2) Erro mata mata681" + MostraErro("/error", "error.log")
								DisarmTransaction()
								Return {.F.,cMsgErro}
							EndIf

							SH6->(DbSkip())

						EndDo

					Else

						cOperSh6 := oModelZGH:GetValue("ZGH_SEQUEN")

						SC2->(dbSetOrder(1))
						SH6->(DbSetOrder(1))

						SC2->(DbSeek(xFilial("SC2") + cNumeroOp))
						While SC2->(!Eof()) .and. SC2->(C2_FILIAL + C2_NUM) == xFilial("SC2") + cNumeroOp

							While (SH6->(DbSeek(xFilial("SH6") + SC2->C2_NUM + Space(TamSX3("H6_OP")[1] - Len(SC2->C2_NUM)) + Space(TamSX3("H6_PRODUTO")[1]) + cOperSh6 + cSequenOp));
									.Or. SH6->(DbSeek(xFilial("SH6") + SC2->(C2_NUM + C2_ITEM + C2_SEQUEN + C2_ITEMGRD + C2_PRODUTO) + cOperSh6 + cSequenOp)))

								If ValType(oSay) <> "U"
									oSay:SetText("Excluindo operação " + AllTrim(SH6->(H6_FILIAL + H6_YOP + H6_YSEQUEN)) + "...")
									ProcessMessage()
								EndIf

								RecLock("SH6", .F.)
								SH6->(DbDelete())
								SH6->(MsUnLock())

							EndDo

							SC2->(DbSkip())

						EndDo

					EndIf

					If !oModelZGH:IsDeleted() .And. !Empty(oModelZGH:GetValue("ZGH_DATAPO")) .And. !Empty(oModelZGH:GetValue("ZGH_DATFIM"))

						nRegTotal := 0

						If Empty(oModelZGH:GetValue("ZGH_RECURS"))
							cRecurSH6 := oModelZH7:GetValue("ZH7_RECURS")
						Else
							cRecurSH6 := oModelZGH:GetValue("ZGH_RECURS")
						EndIf

						If lHabOpPa .AND. cProcesso $ cTiposZHL

							For nZHL := 1 to oModelZHL:Length()
								oModelZHL:GoLine(nZHL)
								If !oModelZHL:IsDeleted() .And. oModelZHL:GetValue("ZHL_CHECK")
									nRegTotal++
								EndIf
							Next

							nTmpTotal := U_TEMPTOMI(oModelZGH:GetValue("ZGH_TOTHRA"))

							For nZHL := 1 to oModelZHL:Length()
								oModelZHL:GoLine(nZHL)
								If !oModelZHL:IsDeleted() .And. oModelZHL:GetValue("ZHL_CHECK")

									cKeyValue := oModelZHL:GetValue("ZHL_OP") + oModelZHL:GetValue("ZHL_ITEM") + oModelZHL:GetValue("ZHL_SEQOP")

									SC2->(dbSetOrder(1))
									If SC2->(DbSeek(xFilial("SC2") + cKeyValue))

										If lGeraSH6

											aRetSH6 := U_GRROTE(SC2->C2_YENGENH, SC2->C2_PRODUTO)
											IF !aRetSH6[1]
												DisarmTransaction()
												cMsgErro  := "Sistema não encontrou uma operação para essa engenharia (SVI). Favor alterar a engenharia. Com esse processo de somentente alterar, o sistema cria uma operação." + chr(10) + chr(10)
												cMsgErro  += "Engenharia: "      + SC2->C2_YENGENH + chr(10)
												cMsgErro  += "Produto Acabado: " + SC2->C2_PRODUTO + chr(10)


												Return {.F.,cMsgErro}
											EndIf

											//--------------------------------------------------
											// Realizando abertura para apontar as horas SH6.
											//--------------------------------------------------
											dDataEnc := SC2->C2_DATRF
											RecLock("SC2", .F.)
											SC2->C2_ROTEIRO := aRetSH6[2]
											SC2->C2_DATRF   := StoD("")
											SC2->(MsUnLock())

											SVI->(DbOrderNickName("GROPERAC")) //VI_FILIAL+VI_YENGENH+VI_CODIGO
											If SVI->(DbSeek(xFilial("SVI") + SC2->C2_YENGENH))
												cOperSh6  := SVI->VI_CODIGO
											Else
												DisarmTransaction()
												cMsgErro  := "Sistema não encontrou uma operação para essa engenharia (SVI). Favor alterar a engenharia. Com esse processo de somentente alterar, o sistema cria uma operação." + chr(10) + chr(10)
												cMsgErro  += "Engenharia: "+ SC2->C2_YENGENH + chr(10)
												Return {.F.,cMsgErro}
											EndIf

										Else

											cOperSh6 := oModelZGH:GetValue("ZGH_SEQUEN")

										EndIf

										If nZHL < oModelZHL:Length()

											//Calculo aqui para gerar uns numeros proporcionais e não ficar todo o resto no ultimo
											nTempo := NOROUND(nTmpTotal / nRegTotal,0)
											cTempo := U_MITOTEMP(nTempo)

											nTmpTotal -= U_TEMPTOMI(cTempo)
											nRegTotal -= 1

										Else
											cTempo := U_MITOTEMP(nTmpTotal)
										EndIf

										aAutoSH6 := {}

										aAdd(aAutoSH6, {"H6_FILIAL",  xFilial("SH6"),  Nil})
										aAdd(aAutoSH6, {"H6_OP",      SC2->(C2_NUM + C2_ITEM + C2_SEQUEN), Nil})
										aAdd(aAutoSH6, {"H6_PRODUTO", SC2->C2_PRODUTO, Nil})
										aAdd(aAutoSH6, {"H6_LOCAL",   SC2->C2_LOCAL,   Nil})
										aAdd(aAutoSH6, {"H6_RECURSO", cRecurSH6,       Nil})
										aAdd(aAutoSH6, {"H6_SEQ",     oModelZGH:GetValue("ZGH_SEQUEN"), Nil})
										aAdd(aAutoSH6, {"H6_DATAINI", oModelZGH:GetValue("ZGH_DATINI"), Nil})
										aAdd(aAutoSH6, {"H6_HORAINI", oModelZGH:GetValue("ZGH_HORINI"), Nil})
										aAdd(aAutoSH6, {"H6_DATAFIN", oModelZGH:GetValue("ZGH_DATFIM"), Nil})
										aAdd(aAutoSH6, {"H6_HORAFIN", oModelZGH:GetValue("ZGH_HORFIM"), Nil})
										aAdd(aAutoSH6, {"H6_DTAPONT", oModelZGH:GetValue("ZGH_DATAPO"), Nil})
										aAdd(aAutoSH6, {"H6_DTPROD",  oModelZGH:GetValue("ZGH_DATFIM"), Nil})
										aAdd(aAutoSH6, {"H6_TEMPO",   cTempo,          Nil})
										aAdd(aAutoSH6, {"H6_OPERAC",  cOperSh6,	       Nil})
										aAdd(aAutoSH6, {"H6_YOP",     SC2->C2_NUM,     Nil})
										aAdd(aAutoSH6, {"H6_YSEQUEN", oModelZGH:GetValue("ZGH_SEQUEN"), Nil})

										If ValType(oSay) <> "U"
											oSay:SetText("Apontando operação " + AllTrim(SH6->(H6_FILIAL + H6_YOP + H6_YSEQUEN)) + "...")
											ProcessMessage()
										EndIf

										If lGeraSH6

											// Variável privada para alimentar os campos customizados da SD3.
											__aVetPriv  := {}
											Aadd(__aVetPriv, {"D3_EMISSAO", oModelZGH:GetValue("ZGH_DATAPO"), Nil})

											MSExecAuto({|x| mata681(x)}, aAutoSH6, 3) // https://centraldeatendimento.totvs.com/hc/pt-br/articles/360022717031-Cross-Segmento-TOTVS-Backoffice-Linha-Protheus-ADVPL-Exemplo-execauto-MATA681-para-inclus%C3%A3o-e-estorno

											If lMsErroAuto
												cMsgErro := "3) Erro mata681" + MostraErro("/error", "error.log")
												DisarmTransaction()
												Return {.F.,cMsgErro}
											EndIf

											RecLock("SC2", .F.)
											SC2->C2_DATRF   := dDataEnc
											SC2->(MsUnLock())

										Else

											RecLock("SH6", .T.)
											For nSH6 := 1 to Len(aAutoSH6)
												&("SH6->" + aAutoSH6[nSH6, 1]) := aAutoSH6[nSH6, 2]
											Next
											SH6->(MsUnLock())

										EndIf

									EndIf

								EndIf

							Next

						Else

							SC2->(dbSetOrder(1))
							SC2->(DbSeek(xFilial("SC2") + cNumeroOp))
							While SC2->(!Eof()) .and. SC2->(C2_FILIAL + C2_NUM) == xFilial("SC2") + cNumeroOp
								nRegTotal++
								SC2->(DbSkip())
							EndDo


							nTmpTotal := U_TEMPTOMI(oModelZGH:GetValue("ZGH_TOTHRA"))

							nTempo := NOROUND(nTmpTotal / nRegTotal,0)
							cTempo := U_MITOTEMP(nTempo)

							SC2->(DbGoTop())
							SC2->(DbSeek(xFilial("SC2") + cNumeroOp))

							While SC2->(!Eof()) .and. SC2->(C2_FILIAL + C2_NUM) == xFilial("SC2") + cNumeroOp
								
								if lGeraSH6

									aRetSH6 := U_GRROTE(SC2->C2_YENGENH, SC2->C2_PRODUTO)
									IF !aRetSH6[1]
										DisarmTransaction()
										cMsgErro  := "Sistema não encontrou uma operação para essa engenharia (SVI). Favor alterar a engenharia. Com esse processo de somentente alterar, o sistema cria uma operação." + chr(10) + chr(10)
										cMsgErro  += "Engenharia: "     + SC2->C2_YENGENH + chr(10)
										cMsgErro  += "Produto Acabado: "+ SC2->C2_PRODUTO + chr(10)

										Return {.F.,cMsgErro}
									EndIf

								EndIf

								//--------------------------------------------------
								// Realizando abertura para apontar as horas SH6.
								//--------------------------------------------------
								dDataEnc := SC2->C2_DATRF
								RecLock("SC2", .F.)
								if lGeraSH6
									SC2->C2_ROTEIRO := aRetSH6[2]
								EndIf 
								SC2->C2_DATRF   := StoD("")
								SC2->(MsUnLock())

								If lGeraSH6
									SVI->(DbOrderNickName("GROPERAC")) //VI_FILIAL+VI_YENGENH+VI_CODIGO
									If SVI->(DbSeek(xFilial("SVI") + SC2->C2_YENGENH))
										cOperSh6  := SVI->VI_CODIGO
									Else
										DisarmTransaction()
										cMsgErro := "Erro operação SH6 "+ "Não foi encontrado vinculo engenharia e operação: Favor alterar a engenharia para o sistema criar o vinculo."
										Return {.F.,cMsgErro}
									EndIf
								EndIf

								If nZHL < oModelZHL:Length()

									//Calculo aqui para gerar uns numeros proporcionais e não ficar todo o resto no ultimo
									nTempo := NOROUND(nTmpTotal / nRegTotal,0)
									cTempo := U_MITOTEMP(nTempo)

									nTmpTotal -= U_TEMPTOMI(cTempo)
									nRegTotal -= 1
								Else
									cTempo := U_MITOTEMP(nTmpTotal)
								EndIf

								aAutoSH6 := {}

								aAdd(aAutoSH6, {"H6_FILIAL",  xFilial("SH6"),  Nil})
								aAdd(aAutoSH6, {"H6_OP",      SC2->(C2_NUM + C2_ITEM + C2_SEQUEN), Nil})
								aAdd(aAutoSH6, {"H6_PRODUTO", SC2->C2_PRODUTO, Nil})
								aAdd(aAutoSH6, {"H6_LOCAL",   SC2->C2_LOCAL,   Nil})
								aAdd(aAutoSH6, {"H6_RECURSO", cRecurSH6,       Nil})
								aAdd(aAutoSH6, {"H6_SEQ",     oModelZGH:GetValue("ZGH_SEQUEN"), Nil})
								aAdd(aAutoSH6, {"H6_DATAINI", oModelZGH:GetValue("ZGH_DATINI"), Nil})
								aAdd(aAutoSH6, {"H6_HORAINI", oModelZGH:GetValue("ZGH_HORINI"), Nil})
								aAdd(aAutoSH6, {"H6_DATAFIN", oModelZGH:GetValue("ZGH_DATFIM"), Nil})
								aAdd(aAutoSH6, {"H6_HORAFIN", oModelZGH:GetValue("ZGH_HORFIM"), Nil})
								aAdd(aAutoSH6, {"H6_DTAPONT", oModelZGH:GetValue("ZGH_DATAPO"), Nil})
								aAdd(aAutoSH6, {"H6_DTPROD",  oModelZGH:GetValue("ZGH_DATFIM"), Nil})
								aAdd(aAutoSH6, {"H6_TEMPO",   cTempo,          Nil})
								aAdd(aAutoSH6, {"H6_OPERAC",  cOperSh6,	       Nil})
								aAdd(aAutoSH6, {"H6_YOP",     SC2->C2_NUM,     Nil})
								aAdd(aAutoSH6, {"H6_YSEQUEN", oModelZGH:GetValue("ZGH_SEQUEN"), Nil})

								If lGeraSH6

									// Variável privada para alimentar os campos customizados da SD3.
									__aVetPriv  := {}
									Aadd(__aVetPriv, {"D3_EMISSAO", oModelZGH:GetValue("ZGH_DATAPO"), Nil})

									MSExecAuto({|x| mata681(x)}, aAutoSH6, 3) // https://centraldeatendimento.totvs.com/hc/pt-br/articles/360022717031-Cross-Segmento-TOTVS-Backoffice-Linha-Protheus-ADVPL-Exemplo-execauto-MATA681-para-inclus%C3%A3o-e-estorno

									If lMsErroAuto
										cMsgErro :=  "1) Erro mata681" + MostraErro("/error", "error.log")
										DisarmTransaction()
										Return {.F.,cMsgErro}
									EndIf

								Else

									RecLock("SH6", .T.)
									For nSH6 := 1 to Len(aAutoSH6)
										&("SH6->" + aAutoSH6[nSH6, 1]) := aAutoSH6[nSH6, 2]
									Next
									SH6->(MsUnLock())

								EndIf

								SC2->(DbSkip())

							EndDo

						EndIf

					EndIf

				Next

			EndIf

			//------------------------------------------------------
			// Atualiza motivo de retrabalho caso haja
			//------------------------------------------------------
			SC2->(DbSetOrder(1))
			SC2->(MsSeek(xFilial("SC2") + cNumeroOp))

			While SC2->(!(Eof())) .And. SC2->(C2_FILIAL + C2_NUM) == xFilial("SC2") + cNumeroOp

				cMotivo := oModelZH7:GetValue("ZH7_CODMOT")

				If ValType(oSay) <> "U"
					oSay:SetText("Processando retrabalho... Gravando retrabalho " + AllTrim(SC2->(C2_NUM + C2_ITEM + C2_SEQUEN)) + "...")
					ProcessMessage()
				EndIf

				If !Empty(cMotivo)
					RecLock("SC2", .F.)
					SC2->C2_YCODMOT := cMotivo
					SC2->(MsUnLock())
				EndIf
				SC2->(DbSkip())
			EndDo

			//----------------------------------------------------
			// Atualiza status da OP.
			//----------------------------------------------------
			U_aStatusOp(cNumeroOp)

			If ValType(oSay) <> "U"
				oSay:SetText("Processando custo de produção... Gravando custo " + AllTrim(cNumeroOp) + "...")
				ProcessMessage()
			EndIf

			//----------------------------------------------------
			// Atualiza CUSTO da OP.
			//----------------------------------------------------
			u_AtuCusto(cNumeroOp)

		Endif

		//----------------------------------------------------------
		// Rotina para preencher o apontamento do fornecedor
		// Necessário para gerar os registos do bloco k Ticket:6289
		//----------------------------------------------------------
		aRet := u_ALTTERCE(cNumeroOp)

		If !(aRet[1])
			DisarmTransaction()
			ConOut(aRet[2])
			Return {.F., aRet[2]}
		EndIf

		//----------------------------------------------------------
		// Rotina para preencher o apontamento do fornecedor
		// Necessário para gerar os registos do bloco k Ticket:6289
		//----------------------------------------------------------
		aRet := u_VALID045(oModel)

		If !(aRet[1])
			DisarmTransaction()
			ConOut(aRet[2])
			Return {.F., aRet[2]}
		EndIf

		//----------------------------------------------------------
		// Caso o número de corte seja maior que o do cadastro
		// de recurso, atualiza.
		//----------------------------------------------------------
		SH1->(DbSetOrder(1))
		If SH1->(DbSeek(xFilial("SH1") + oModelZH7:GetValue('ZH7_RECURS')))
			If oModelZH7:GetValue('ZH7_NUMCOR') > SH1->H1_YNUMCOR
				RecLock("SH1", .F.)
				SH1->H1_YNUMCOR := oModelZH7:GetValue('ZH7_NUMCOR')
				SH1->(MsUnLock())
			EndIf
		EndIf

	End Transaction

	If oUtil <> nil
		oUtil:destroy()
	EndIf

	ConOut("GrPlusMVC => Processo de apontamento de insumo da OP concluido.")
	ConOut("GrPlusMVC => Data/Hora Final do processamento: " + AllTrim(DtoC(Date())) + " " + AllTrim(Time()) + ".")

	//Ponto de entrada fora da transação no final do apontamento
	If ExistBlock("GGROA045")
		ExecBlock("GGROA045",.F.,.F.,{cNumeroOp})
	EndIf

	ConOut("GRPlusMVC => Final apontamento de insumos de producao " + AllTrim(DtoC(Date())) + " " + AllTrim(Time()) + ".")

Return {.T., ""}

/*/{Protheus.doc} GRA045F1
Retorna o lotes de produtos que contém saldo.
@type User Function
@author Totvs Vitoria
@since 08/08/2019
@version version
/*/
User Function GRA045F1()

	Local oModel     := FWModelActive()
	Local cProduto   := oModel:GetValue('ZGIDETAIL','ZGI_PRODUT')
	Local cLocal     := oModel:GetValue('ZGIDETAIL','ZGI_LOCAL')
	Local lReturn    := .T.
	Local cExpFilter := ""

	cExpFilter := " B8_PRODUTO == '" + cProduto + "' .AND. B8_LOCAL == '" + cLocal + "' .AND. B8_SALDO > 0 .AND. B8_EMPENHO == 0 "

	lReturn := U_GROCGEN("SB8", cExpFilter, "Estoque de Materiais - GRAVAEXE")[1]

Return lReturn

/*/{Protheus.doc} VldZGH
Validação dos Itens de Insumo
@type  Function
@author Totvs Vitoria
@since 15/01/2020
@version version
@param param, param_type, param_descr
@return return, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
Static Function VldZGH(oModel)

	Local dDataFim := oModel:GetModel("ZGHDETAIL"):GetValue("ZGH_DATFIM")
	Local dDataPo  := oModel:GetModel("ZGHDETAIL"):GetValue("ZGH_DATAPO")
	Local dDataIni := oModel:GetModel("ZGHDETAIL"):GetValue("ZGH_DATINI")
	Local cHoraIni := oModel:GetModel("ZGHDETAIL"):GetValue("ZGH_HORINI")
	Local cHoraFim := oModel:GetModel("ZGHDETAIL"):GetValue("ZGH_HORFIM")
	Local dDataEmi := oModel:GetModel("ZH7MASTER"):GetValue("ZH7_EMISSA")

	Local lRet 	   := .t.
	Local cMsg     := ""
	Local cSolu    := ""
	Local dDtLmte   := GetMv("MV_ULMES")
	Local cVldHrFim := "  :  "

	// Validar a data final com a data de apontamento, usuario pode inserir data final primeiro e depois apontamento.
	If empty(dDataFim) .OR. dDataFim >= dDataPo
		lRet := .T.
	Else
		cMsg := "Data final menor que a data de apontamento."
		cSolu:= "Favor informar uma data final maior que a data de apontamento."
		Help(Nil, Nil, "GROA045 - VldZGH_1", Nil, cMsg ,1, 0, Nil, Nil, Nil, Nil, Nil, {cSolu})
		Return .F.
	End If

	// Validar a data final com a data inicial, usuario pode inserir data final primeiro e depois apontamento.
	If empty(dDataFim) .OR. dDataFim >= dDataIni
		lRet := .T.
	Else
		cMsg := "Data final menor que a data inicial."
		cSolu:= "Favor informar uma data final maior que a data inicial."
		Help(Nil, Nil, "GROA045 - VldZGH_2", Nil, cMsg ,1, 0, Nil, Nil, Nil, Nil, Nil, {cSolu})
		Return .F.
	EndIf

	If lRet .and. ((!EMPTY( dDataPo) .AND. dDataPo <= dDtLmte))
		cMsg  := "Esse periodo não pode ser alterado. Data " + CVALTOCHAR(dDataPo) +" inferior a data de fechamento de estoque " + CVALTOCHAR( dDtLmte )
		cSolu := "Favor verificar a data de fechamento de estoque"
		Help(Nil, Nil, "GROA045 - VldZGH_3", Nil, cMsg ,1, 0, Nil, Nil, Nil, Nil, Nil, {cSolu})
		Return .F.
	EndIf

	// Validar se horário inicial é maior que horário final no mesmo dia
	If ((!EMPTY(dDataIni)) .AND. (!EMPTY(dDataFim))) .AND. (dDataIni == dDataFim)
		If ((!EMPTY(cHoraFim) .AND. (cHoraFim != cVldHrFim)) .AND. (cHoraIni > cHoraFim))
			cMsg  := "O horário de início não pode ser maior que o horário final dentro do mesmo dia."
			cSolu := "Favor informar horários válidos."
			Help(Nil, Nil, "GROA045 - VldZGH_4", Nil, cMsg ,1, 0, Nil, Nil, Nil, Nil, Nil, {cSolu})
			Return .F.
		EndIf
	EndIF

	// Validar se data inicial do apontamento é menor que a data de emissão da OP
	IF !EMPTY(dDataIni) .AND. dDataIni < dDataEmi
		cMsg  := "A data inicial do apontamento não pode ser menor que a data de emissão da OP."
		cSolu := "Favor informar uma data inicial a partir da data de emissão da OP."
		Help(Nil, Nil, "GROA045 - VldZGH_5", Nil, cMsg ,1, 0, Nil, Nil, Nil, Nil, Nil, {cSolu})
		Return .F.
	EndIF

Return lRet

Static Function VldSH6(oModel)

	Local oView  	:= FwViewActive()
	Local oModelZH7 := oModel:GetModel("ZH7MASTER") // Ordem de produção
	Local oModelSH6 := oModel:GetModel("SH6DETAIL")
	Local nRegZGH   := oModelSH6:Length()
	Local dDtApont  := oModelSH6:GetValue("H6_DTAPONT")
	Local dDatIni   := oModelSH6:GetValue("H6_DATAINI")
	Local cHoraIni  := oModelSH6:GetValue("H6_HORAINI")
	Local dDataFin  := oModelSH6:GetValue("H6_DATAFIN")
	Local cHoraFin  := oModelSH6:GetValue("H6_HORAFIN")
	Local cNumeroOp := oModelZH7:GetValue("ZH7_NUM")

	Local lRet 	    := .t.
	Local cMsg      := ""
	Local cSolu     := ""
	Local dDtLmte   := GetMv("MV_ULMES")
	Local dDatIni1  := ""
	Local dDataFin1 := ""
	Local cHoraIni1 := ""
	Local cHoraFin1 := ""
	Local dDatIni2  := ""
	Local cHoraIni2 := ""
	Local cHoraFin2 := ""
	Local dDataFin2 := ""
	Local nx        := 0
	Local nY        := 0
	Local aInterval := {}
	Local lValidSH6 := GetNewPar("GR_VLDSH6", .F.)

	If lValidSH6

		For nX := 1 To nRegZGH
			oModelSH6:GoLine(nX)
			If !oModelSH6:IsDeleted()
				dDataFin := oModelSH6:GetValue("H6_DATAFIN")
				dDatIni  := oModelSH6:GetValue("H6_DATAINI")
				cHoraIni := oModelSH6:GetValue("H6_HORAINI")
				cHoraFin := oModelSH6:GetValue("H6_HORAFIN")
				AAdd(aInterval, {dDataFin, dDatIni, cHoraIni, cHoraFin})
			Endif
		Next

		For nX := 1 To Len(aInterval)

			dDataFin1 := aInterval[nX][1]
			dDatIni1  := aInterval[nX][2]
			cHoraIni1 := aInterval[nX][3]
			cHoraFin1 := aInterval[nX][4]

			For nY := nX + 1 To Len(aInterval)

				dDataFin2 := aInterval[nY][1]
				dDatIni2  := aInterval[nY][2]
				cHoraIni2 := aInterval[nY][3]
				cHoraFin2 := aInterval[nY][4]

				If ( (dDatIni2 >= dDatIni1      .And. (dDatIni2 <= dDataFin1  .And. cHoraIni2 < cHoraFin1));
						.Or. (dDatIni2 <= dDatIni1  .And. !EMPTY(dDataFin2)       .And. (dDataFin2 <= dDataFin1 .And. cHoraIni2 <= cHoraFin1) .And. cHoraIni2 <= cHoraFin1);
						.Or. (dDatIni2 <= dDatIni1  .And. (dDataFin2 >= dDataFin1 .And. cHoraFin1 <= cHoraFin2) .And. cHoraIni2 <= cHoraFin1);
						.Or. (dDatIni1 >= dDatIni2  .And. (dDataFin1 <= dDataFin2 .And. cHoraFin1 <= cHoraFin2) .And. cHoraIni2 <= cHoraFin1);
						.Or. (dDatini1 > dDatini2   .And. dDatafin1 < dDataFin2);
						.Or. (dDataFin2 == dDatIni1 .And. (dDatafin2 == dDatafin1 .And. cHoraIni2 <= cHoraFin1));
						.Or. ((cHoraFin2 > cHoraIni1.And. dDatini1 == dDataFin2)  .And. (cHoraFin2 <= cHoraFin1 .And. dDatini2 < dDatini1));
						.Or. (dDataFin2 == dDatIni1 .And. (cHoraIni2 <= cHoraini1 .And. cHoraFin2 >= cHoraini1) .And. dDataFin2 <> dDatafin1 );
						.Or. (dDatIni2 == dDatIni1  .And. dDataFin2 == dDataFin1  .And. !EMPTY(dDataFin2));
						.Or. (dDatIni2 == dDatIni1  .And. dDataFin2 >= dDataFin1  .And. !EMPTY(dDataFin2));
						.Or. (dDatIni1 >= dDatIni2  .And. (dDataFin1 <= dDataFin2 .And. cHoraIni1 <= cHoraFin2).And. cHoraIni2 <= cHoraFin1))

					//Validação extra de sobreposição com Datas Maiores (compara linha por linha)
					If ( (cHoraIni2 >= cHoraIni1     .And. (cHoraIni2 < cHoraFin1  .And. (dDatafin1 > dDatini2   .And. dDatafin2 > dDatini2)));
							.Or. ((cHoraFin2 > cHoraIni1 .And. dDatini1== dDataFin2)   .And. (cHoraFin2 <= cHoraFin1 .And. dDatini2 < dDatini1));
							.Or. (dDatini2 == dDatini1   .And. (cHoraIni2 > cHoraIni1  .And. cHoraFin2 > cHoraFin1)  .And. cHoraIni2 <= cHoraFin1);
							.Or. (dDatini2 == dDatini1   .And. cHoraFin2 > cHoraIni1   .And. cHoraIni2 <= cHoraFin1);
							.Or. (dDatini2 < dDatini1    .And. dDatafin2 > dDatini1);
							.Or. (dDatini2 <= dDatini1   .And. (dDatafin2 > dDatini1   .And. cHoraIni2 < cHoraFin2   .And. cHoraFin1 >= cHoraIni2));
							.Or. (dDatini1 < dDatini2    .And. dDatafin1 > dDatini2);
							.Or. (dDataFin2 == dDatIni1  .And. (dDatafin2 >= dDatafin1 .And. cHoraIni2 >= cHoraFin1) .And. cHoraIni2 <= cHoraFin1);
							.Or. (dDatIni1 == dDatafin2  .And. cHoraFin2 >= cHoraIni1  .And. dDataFin2 <> dDatafin1);
							.Or. (dDatini1 == dDatini2   .And. dDatafin2 > dDatafin1   .And. cHoraFin1 >= cHoraIni2);
							.Or. (dDatini1 < dDatini2    .And. (dDatafin2 >= dDatafin1 .And. cHoraFin1 < cHoraFin2)))

						cMsg := "Os horários se sobrepõem entre os registros " + Str(nX) + " e " + Str(nY)
						cSolu:= "Favor Verificar os horários das paradas"
						Help(Nil, Nil, "GROA045 - VldSH6_1", Nil, cMsg ,1, 0, Nil, Nil, Nil, Nil, Nil, {cSolu})
						Return .F.
					EndIf
				EndIf
			Next
		Next

		If !isBlind()
			oView:Refresh("SH6DETAIL")
		EndIf

		// Validar a data final com a data inicial, usuário pode inserir data final primeiro e depois apontamento.
		If empty(dDataFin) .OR. dDataFin >= dDatIni
			lRet := .T.
		Else
			cMsg := "Data final menor que a data inicial."
			cSolu:= "Favor informar uma data final maior que a data inicial."
			Help(Nil, Nil, "GROA045 - VldSH6_2", Nil, cMsg ,1, 0, Nil, Nil, Nil, Nil, Nil, {cSolu})
			Return .F.
		EndIf

		// Validar a hora final com a hora inicial se as datas forem iguais
		If  !Empty(cHoraFin) .AND. cHoraFin < cHoraIni .AND. !(dDatIni <> dDataFin)
			cMsg := "Hora final menor que a hora inicial."
			cSolu:= "Favor informar uma hora final maior que a hora inicial."
			Help(Nil, Nil, "GROA045 - VldSH6_3", Nil, cMsg ,1, 0, Nil, Nil, Nil, Nil, Nil, {cSolu})
			Return .F.
		End If

		// Validar se a data de apontamento é anterior à data de fechamento do estoque
		If lRet .and. ((!EMPTY(dDtApont) .AND. dDtApont <= dDtLmte))
			cMsg  := "Esse período não pode ser alterado. Data " + CVALTOCHAR(dDtApont) + " inferior a data de fechamento de estoque " + CVALTOCHAR(dDtLmte)
			cSolu := "Favor verificar a data de fechamento de estoque"
			Help(Nil, Nil, "GROA045 - VldSH6_4", Nil, cMsg ,1, 0, Nil, Nil, Nil, Nil, Nil, {cSolu})
			Return .F.
		End If

		// Validar a data do encerramento com a data da parada inicial/final.
		SC2->(dbSetOrder(1))
		SC2->(msSeek(xFilial("SC2") + cNumeroOp))
		If !empty(SC2->C2_DATRF) .AND. SC2->C2_DATRF < dDtApont
			cMsg := "A data do apontamento não pode ser maior que a data de Previsão de entrega da OP, favor verificar!"  + chr(10)  + chr(10)
			cMsg += "Dt.Apontamento: "  + U_FORMTADT(dDtApont) + chr(10)
			cMsg += "Dt.Atual: "        + U_FORMTADT(SC2->C2_DATRF) + chr(10)

			Help(Nil, Nil, "GROA045 - VldSH6_5", Nil, cMsg ,1, 0, Nil, Nil, Nil, Nil, Nil, {cSolu})
			Return .F.
		EndIf

	Endif

Return lRet

/*/{Protheus.doc} GR045GET
Retorna conteúdo de campo virtual
@type User Function
@author Totvs Vitoria
@since 20/02/2020
/*/
User Function GR045GET(cCampo)

	Local cRet := ""

	If cCampo == "ZHL_PRODUT"

		cRet := Posicione("SC2", 1, xFilial("SC2") + ZHL->ZHL_OP + ZHL->ZHL_ITEM + ZHL->ZHL_SEQOP, "C2_PRODUTO")

	ElseIf cCampo == "ZHL_DESCRI"

		cRet := Posicione("SC2", 1, xFilial("SC2") + ZHL->ZHL_OP + ZHL->ZHL_ITEM + ZHL->ZHL_SEQOP, "C2_PRODUTO")
		cRet := Posicione("SB1", 1, xFilial("SB1") + cRet, "B1_DESC")

	EndIf

Return cRet


/*/{Protheus.doc} GR045GET
Retorna conteúdo de campo virtual
@type User Function
@author Totvs Vitoria
@since 20/02/2020
/*/
User Function GRCZHL()

	Local lHabOpPa   := GETNEWPAR("GR_HABOPPA", .F.) // Habilita aba para vincular Operação ao Produto Acabado.
	Local oMdlActive := FWModelActive()
	Local oModelZHL  := oMdlActive:GetModel("ZHLDETAIL")
	Local oModelZGH  := oMdlActive:GetModel("ZGHDETAIL")
	Local oModelZH7  := oMdlActive:GetModel("ZH7MASTER")
	Local cNumOp     := oModelZH7:GetValue("ZH7_NUM")
	Local cProcesso  := oModelZH7:GetValue("ZH7_PROCES")
	Local cRotina    := oModelZH7:GetValue("ZH7_ROTINA")
	Local cSeqOp     := oModelZGH:GetValue("ZGH_SEQUEN")
	Local oView      := Nil
	Local oModelZH9  := Nil
	Local lRet 	     := .T.
	Local cDescPro   := ""
	Local lCheck     := .F.
	Local lRotNova   :=  alltrim(cRotina) $ "GROA060/GROA062"
	Local lZHLVazio  := oModelZHL:isEmpty() //Necessário validar se o usuário esta adicionando uma nova operação direto na tela GROA045 para op criado na tela nova.
	Local nX		 := 0
	Local lGeraZHL	 := 0

	if lRotNova
		lHabOpPa := .t.
	EndIf

	If lHabOpPa .And. cProcesso $ cTiposZHL

		if lIncluiOp .And. Inclui

			oModelZH9 := oMdlActive:GetModel("ZH9DETAIL")

			oMdlActive:GetModel("ZHLDETAIL"):ClearData()

			For nX := 1 To oModelZH9:Length()

				oModelZH9:GoLine(nX)

				If !Empty(oMdlActive:GetModel("ZHLDETAIL"):GetValue("ZHL_PRODUT"))
					oMdlActive:GetModel("ZHLDETAIL"):AddLine()
				End if

				oMdlActive:SetValue('ZHLDETAIL', 'ZHL_FILIAL'     , xFilial("ZHL") )
				oMdlActive:SetValue('ZHLDETAIL', 'ZHL_OP'   	  , cNumOp )
				oMdlActive:SetValue('ZHLDETAIL', 'ZHL_ITEM'       , oModelZH9:GetValue("ZH9_ITEM"))
				oMdlActive:SetValue('ZHLDETAIL', 'ZHL_SEQOP'      , oModelZH9:GetValue("ZH9_SEQUEN"))
				oMdlActive:SetValue('ZHLDETAIL', 'ZHL_SEQUEN'     , cSeqOp)
				oMdlActive:SetValue('ZHLDETAIL', 'ZHL_PRODUT'     , oModelZH9:GetValue("ZH9_CODPA"))
				oMdlActive:SetValue('ZHLDETAIL', 'ZHL_DESCRI'     , oModelZH9:GetValue("ZH9_DESCPA"))
				oMdlActive:SetValue('ZHLDETAIL', 'ZHL_CHECK'      , .F. )

			Next

		Else
			oView := FwViewactive()

			ZGM->(DbSetOrder(1))
			ZGM->(MsSeek(xFilial("ZGM") + cNumOp))

			While ZGM->(!(Eof())) .And. ZGM->(ZGM_FILIAL) + ZGM->(ZGM_OP) == xFilial("ZGM") + cNumOp

				//-----------------------------------------------------
				// Inclui vínculo da operação com o produto acabado.
				//-----------------------------------------------------

				// Alimenta as informações
				cDescPro   := Posicione("SB1", 1, xFilial("SB1") + ZGM->(ZGM_PRODUT), "B1_DESC")
				cDescPro   := Substr(cDescPro   ,1,TAMSX3("ZHL_DESCRI")[1])

				//Se for criado pela rotina nova o sistema não altera os dados antigos.
				IF lRotNova
					If type("__lUtiBrow") == "U"
						If(ZGM->ZGM_STATUS == 'P')
							ZGM->(DbSkip())
							LOOP
						Else
							lCheck := .T.
						EndIF
					ElseIf !lZHLVazio // Necessário porque o usuário pode alterar direto na tela.
						ZGM->(DbSkip())
						LOOP
					EndIF
				Else
					lCheck := .F.
				EndIf

				lGeraZHL := .T.

				For nX := 1 To oMdlActive:GetModel("ZHLDETAIL"):Length()
					oMdlActive:GetModel("ZHLDETAIL"):GoLine(nX)
					if oMdlActive:GetModel("ZHLDETAIL"):GetValue("ZHL_FILIAL") == ZGM->(ZGM_FILIAL);
							.and. oMdlActive:GetModel("ZHLDETAIL"):GetValue("ZHL_OP") == ZGM->(ZGM_OP) ;
							.and. oMdlActive:GetModel("ZHLDETAIL"):GetValue("ZHL_ITEM") ==  ZGM->(ZGM_ITEM);
							.and. oMdlActive:GetModel("ZHLDETAIL"):GetValue("ZHL_SEQOP") == ZGM->(ZGM_SEQUEN) ;
							.and. oMdlActive:GetModel("ZHLDETAIL"):GetValue("ZHL_SEQUEN") == cSeqOp

						lGeraZHL := .F.
						exit

					EndIF
				Next

				If lGeraZHL
					//Adiciona uma linha quando a linha posicionada estiver diferente de  branca
					If !Empty(oModelZHL:GetValue("ZHL_OP"))
						oModelZHL:AddLine()
					End if

					oMdlActive:SetValue('ZHLDETAIL', 'ZHL_FILIAL'     , ZGM->(ZGM_FILIAL))
					oMdlActive:SetValue('ZHLDETAIL', 'ZHL_OP'   	  , ZGM->(ZGM_OP))
					oMdlActive:SetValue('ZHLDETAIL', 'ZHL_ITEM'       , ZGM->(ZGM_ITEM))
					oMdlActive:SetValue('ZHLDETAIL', 'ZHL_SEQOP'      , ZGM->(ZGM_SEQUEN))
					oMdlActive:SetValue('ZHLDETAIL', 'ZHL_SEQUEN'     , cSeqOp)
					oMdlActive:SetValue('ZHLDETAIL', 'ZHL_PRODUT'     , ZGM->(ZGM_PRODUT))
					oMdlActive:SetValue('ZHLDETAIL', 'ZHL_DESCRI'     , cDescPro)
					oMdlActive:SetValue('ZHLDETAIL', 'ZHL_CHECK'      , lCheck )

				EndIf

				ZGM->(DbSkip())

			EndDo

			oModelZHL:GoLine(1)

			if(valtype(oView) <> "U" .AND. !isBlind())
				oView:Refresh("ZHLDETAIL")
			EndIF

		EndIF

	EndIf

Return lRet


//Função para validar tempo total negativo
static Function VldTemp(cTempo,cTempIni,cTempFim)

	Local lRet   := .T.
	Local cMessage   := ""
	Local cSolution  := ""

	If !EMPTY(ALLTRIM(STRTRAN(cTempIni,":"," "))) .and. !EMPTY(ALLTRIM(STRTRAN(cTempFim,":"," ")))

		If(VALTYPE(cTempo) == "C")

			If Substr(cTempo,1,1) == '-'
				lRet   := .F.
				cMessage  := "Tempo calculado esta inferior a 0"
				cSolution := "Favor verificar inicio e fim"
				Help(NIL, NIL, "GRAOA045", NIL, cMessage ,1, 0, NIL, NIL, NIL, NIL, NIL, {cSolution})
			EndIf

		elseIf(VALTYPE(cTempo) == "N")

			if(cTempo<0)
				lRet   := .F.
				cMessage  := "Tempo calculado esta inferior a 0"
				cSolution := "Favor verificar inicio e fim"
				Help(NIL, NIL, "GRAOA045", NIL, cMessage ,1, 0, NIL, NIL, NIL, NIL, NIL, {cSolution})
			EndIf

		EndIF
	EndIF
Return(lRet)



static function GROA045A()

	Local nX 	    := 0
	Local oModel    := FWModelActive()
	Local oModelZGH := oModel:GetModel("ZGHDETAIL")
	Local oView  	:= FwViewActive()
	Local nRegZGH   := oModelZGH:Length()
	Local cDatata   := Ctod("  /  /  ")
	Local cHora		:= ":"
	Local cNumeroOp := oModelZGH:GetValue("ZGH_OP")
	Local lGeraSH6  := GETNEWPAR("GR_GERASH6", .F.) // Habilita o apontamento pela rotina padrão MATA681 que alimenta a tabela SH6.

	If oModel:getOperation() == MODEL_OPERATION_UPDATE

		For nX := 1 To nRegZGH
			oModelZGH:GoLine(nX)
			oModelZGH:SetValue("ZGH_DATAPO", cDatata)
			oModelZGH:SetValue("ZGH_DATINI", cDatata)
			oModelZGH:SetValue("ZGH_HORINI", cHora)
			oModelZGH:SetValue("ZGH_DATFIM", cDatata)
			oModelZGH:SetValue("ZGH_HORFIM", cHora)
		Next

		If !isBlind()
			oView:Refresh("ZGHDETAIL")
		EndIf
	Else
		cMessage  := "Essa opção so pode ser utilizada quando clica em apontamento na tela principal"
		cSolution := "Favor clicar em fechar e clicar em apontamento na tela principal."
		Help(NIL, NIL, "GROA045A_01", NIL, cMessage ,1, 0, NIL, NIL, NIL, NIL, NIL, {cSolution})
	EndIF
Return

//-------------------------------------------------------------------
/*/{Protheus.doc} Converte
Converte total de horas em decimal para hora e minuots
@return char
@author Kenny Roger Martins
@since 11/03/2021
/*/
//-------------------------------------------------------------------
Static Function Converte(nHoras)

	Local cHoras := ""

	cHoras := cValToChar(NoRoud(nHoras, 0)) + ":" + "00"

Return cHoras


//-------------------------------------------------------------------
/*/{Protheus.doc} PosLine
Validar se o estoque esta fechado e não deixa remover linha
@type Static Function
@since 24/06/2020
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function PosLine(oModel, nLine, cOperation)

	Local lRet      := .T.
	Local oView     := FWViewActive()
	Local oMaster   := FWModelActive()
	Local oModelZGH := oMaster:GetModel("ZGHDETAIL")
	Local dDataPo  := oModelZGH:GetValue("ZGH_DATAPO")
	Local dDtLmte   := GetMv("MV_ULMES")
	Local cMessage  := ""
	Local cSolution := ""

	if (cOperation == "DELETE") .AND.  ((!EMPTY( dDataPo) .AND. dDataPo <= dDtLmte)) .and. !EMPTY( POSICIONE("ZGH", 1, XFILIAL("ZGH") + oModelZGH:GetValue("ZGH_OP")+oModelZGH:GetValue("ZGH_SEQUEN"), "ZGH_DATFIM") )
		lRet := .f.
		cMessage  := "Esse periodo não pode ser alterado. Data " + CVALTOCHAR(dDataPo) +" inferior a data de fechamento " + CVALTOCHAR( dDtLmte )
		cSolution := "Favor verificar a data de fechamento de estoque"
		Help(NIL, NIL, "GRAOA045_PosLine_1", NIL, cMessage ,1, 0, NIL, NIL, NIL, NIL, NIL, {cSolution})
	EndIf

Return lRet




/*/{Protheus.doc} GRA038F2
Conculta padrão GRZH7B(novo) criada para substituir GRZH7A(antigo)
Consulta criada para restornar os insumos sem passar por toda a tabela. quando passa por toda a tabela ela deixa muito lento quando o cliente possui muitos dados. 

@type User Function
@author Totvs Vitoria
@since 08/08/2019
@version version
/*/
User Function GRA045F2(cCod)

	Local oModel    := FWModelActive()
	Local cSql      := ""
	Local qQueryH1  := ""
	Local cExpSH1   := ""
	Local aReturn   := {}
	Local lReturn   := .F.
	Local nQtdREg 	:= 0
	Local aRetPE    := {}
	Local lExecPEQ  := .T.
	Local lRotNova  := .F.
	Local cRotCria  := ""
	Local oModelZH8 := Nil
	Local nX 		:= 0
	Local cEngAuxi  := ""
	Local cEngenha  := ""

	Default cCod        := ""

	iF oModel != NIL
		cProcesso := oModel:Getvalue('ZH7MASTER','ZH7_PROCES')
	ENDIF

	IF (ZH7->(FieldPos("ZH7_ROTINA"))> 0)
		cRotCria   := oModel:Getvalue('ZH7MASTER','ZH7_ROTINA')
	EndIF


	lRotNova := alltrim(cRotCria) $ "GROA060/GROA062"

	if !empty(cProcesso)

		//Pega os recursos com base nas engenharias informadas.
		if(funname() == 'GROA045')
			if inclui
				oModelZH8 := oModel:GetModel("ZH8DETAIL")
				For nX := 1 To oModelZH8:Length()

					oModelZH8:GoLine(nX)

					If oModelZH8:IsDeleted()
						Loop
					EndIf

					cEngAuxi := oModelZH8:GetValue("ZH8_ENGENH")

				Next

				If cEngAuxi $ cEngenha
					if !empty(cEngenha)
						cEngenha += ","
					EndIf

					cEngenha += "'"+cEngAuxi+"'"
					cEngAuxi := ""

				EndIf

			EndIf
		EndIF

		cSql := "     SELECT H1_CODIGO, H1_DESCRI "
		cSql += "       FROM " + RetSqlName("ZG7") + " ZG7 "
		cSql += " INNER JOIN " + RetSqlName("ZG8") + " ZG8 "
		cSql += "         ON ZG8.ZG8_FILIAL = '" + xFilial("ZG8") + "' "
		cSql += "        AND ZG8.ZG8_ROTEIR = ZG7_CODIGO "
		cSql += "        AND ZG8.D_E_L_E_T_ = ' ' "
		cSql += " INNER JOIN " + RetSqlName("ZGC") + " ZGC "
		cSql += "         ON ZGC.ZGC_FILIAL = '" + xFilial("ZGC") + "' "
		cSql += "        AND ZGC.ZGC_ROTEIR = ZG8_ROTEIR "
		cSql += "        AND ZGC.ZGC_SEQUEN = ZG8_SEQUEN "
		cSql += "        AND ZGC.D_E_L_E_T_ = ' ' "
		cSql += " INNER JOIN " + RetSqlName("SH1") + " SH1 "
		cSql += "         ON SH1.H1_FILIAL = '" + xFilial("SH1") + "' "
		cSql += "        AND  (SH1.H1_CODIGO = ZGC_EQUIPA  OR SH1.H1_YGRUPO = ZGC.ZGC_RECURS) "
		If !Empty(cCod)
			cSql += "        AND  SH1.H1_CODIGO = '" + cCod + "' "
		EndIf
		cSql += "        AND SH1.D_E_L_E_T_ = ' ' "
		cSql += "      WHERE ZG7.ZG7_FILIAL = '" + xFilial("ZG7") + "' "
		If !lRotNova
			cSql += "        AND ZG7.ZG7_TIPO   = '" + cProcesso + "' "
		EndIf
		cSql += "        AND (ZG8.ZG8_OPERAC   = '" + FWFldGet("ZGH_OPERAC") + "' "
		cSql += "          OR ZG8.ZG8_OPEREP   = '" + FWFldGet("ZGH_OPERAC") + "') "
		cSql += "        AND ZG7.D_E_L_E_T_ = ' ' "

		if inclui
			if !empty(cEngenha)
				cSql += "        AND ZG7_CODIGO IN( "
				cSql += "   		" + cEngenha
				cSql += "        ) "
			EndIf
		Else
			cSql += "        AND ZG7_CODIGO IN ( "
			cSql += "                           SELECT ZH8_ENGENH "
			cSql += "                             FROM " + RetSqlName("ZH8") + " ZH8 "
			cSql += "                            WHERE ZH8_NUM = '" + M->ZH7_NUM + "' "
			cSql += "                              AND D_E_L_E_T_ = ' ' "
			cSql += "                         GROUP BY ZH8_ENGENH "
			cSql += "        ) "
		EndIf

	EndIF

	IF ExistBlock('GRRECURS')
		aRetPE := ExecBlock("GRRECURS", .F., .F., {cProcesso,cCod,M->ZH7_NUM,cSql})
		lReturn   := aRetPE[1]
		lExecPEQ  := aRetPE[2]
		cSql 	  := aRetPE[3]
	EndIF

	if lExecPEQ
		If EMPTY( cCod )
			aReturn := U_GROCGEN("SH1", cExpSH1, "Recursos liberados na engenharia", cSql, {"H1_CODIGO"})[2]
			If Len(aReturn) > 0
				SH1->(DbSetOrder(1))
				If SH1->(DbSeek( xFilial("SH1") + aReturn[1][2] ))
					lReturn := .T.
				Else
					lReturn := .F.
				EndIf
			Else
				lReturn := .F.
			EndIf
		Else
			TCQUERY cSql NEW ALIAS qQueryH1
			Count To nQtdReg
			qQueryH1->(DbCloseArea())

			if nQtdReg > 0
				lReturn := .T.
			else
				lReturn := .F.
			EndIF
		EndIF
	EndIF

Return lReturn


/*/{Protheus.doc} EMPENHO(
	(long_description)
	@type  Static Function
	@author user
	@since 16/11/2023
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
/*/
Static Function EMPENHO(aArraySD3)

	Local aArraySD4		:= {}
	Local cCod 			:= aArraySD3[aScan(aArraySD3, {|x| AlLTrim(x[1]) == 'D3_COD'	}),2]
	Local cLocal 		:= aArraySD3[aScan(aArraySD3, {|x| AlLTrim(x[1]) == 'D3_LOCAL'	}),2]
	Local cLoteCtl		:= aArraySD3[aScan(aArraySD3, {|x| AlLTrim(x[1]) == 'D3_LOTECTL'}),2]
	Local cNumLote		:= aArraySD3[aScan(aArraySD3, {|x| AlLTrim(x[1]) == 'D3_NUMLOTE'}),2]
	Local cOp 			:= aArraySD3[aScan(aArraySD3, {|x| AlLTrim(x[1]) == 'D3_OP'		}),2]
	Local nQuant 		:= aArraySD3[aScan(aArraySD3, {|x| AlLTrim(x[1]) == 'D3_QUANT'	}),2]
	Local cSequenOp		:= aArraySD3[aScan(aArraySD3, {|x| AlLTrim(x[1]) == 'D3_TRT'	}),2]
	Local cMsgErro 		:= ""

	aAdd(aArraySD4, {"D4_FILIAL",  xFilial('SD4'), Nil})
	aAdd(aArraySD4, {"D4_COD", 	   cCod,	  	   Nil})
	aAdd(aArraySD4, {"D4_LOCAL",   cLocal,    	   Nil})
	if !EMPTY( cLoteCtl )
		aAdd(aArraySD4, {"D4_LOTECTL", cLoteCtl,  	   Nil})
		aAdd(aArraySD4, {"D4_NUMLOTE", cNumLote,  	   Nil})
	EndIF
	aAdd(aArraySD4, {"D4_OP", 	   cOp, 	  	   Nil})
	aAdd(aArraySD4, {"D4_YOP", 	   SubStr(cOp, 1, TamSX3("D4_YOP")[1]),	    Nil})
	aAdd(aArraySD4, {"D4_QTDEORI", nQuant,		   Nil})
	aAdd(aArraySD4, {"D4_QUANT",   nQuant,		   Nil})
	aAdd(aArraySD4, {"D4_TRT", 	   cSequenOp,	   Nil})

	MSExecAuto({|x,y| Mata380(x,y)}, aArraySD4, 3)

	If lMsErroAuto
		Return {.F.,{}}
	EndIf



Return  {.T., aArraySD4}



/*/{Protheus.doc} GA680Cal
(long_description)
Rotina criada para substituir uma rotina padrão da matriz. A rotina padrão pega os valores direto da tabela SH6. 
Porem precisamos da customizada. 
Rotina padrão que copiamos: A680Calc, fonte MATA680

@type user function
@author user
@since 03/04/2024
@version version
@param param_name, param_type, param_descr
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function GA680Cal(cRecurso,dDtIni,cHoraIni,dDtFin,cHoraFin)

	Static cTpHr
	Local cTime      :=""
	Local nTempoCen  :=0
	Local lUsaCalend := GetMV("MV_USACALE",, .F.)
	Local cForHora   := "N"
	Local nZeros     := At(":", PesqPict("SH6", "H6_TEMPO")) - 1
	Local lApsInUse  := SuperGetMv("MV_APS",.F.,"") $ "DRUMMER*TOTVS"
	Local cTimeIni   := ""
	Local cTimeFim   := ""
	Local l680		 := .F. //Variavel que valida se esta utilizando a rotina MATA680

	Default cRecurso := M->H6_RECURSO
	Default dDtIni   := M->H6_DATAINI
	Default cHoraIni := M->H6_HORAINI
	Default dDtFin   := M->H6_DATAFIN
	Default cHoraFin := M->H6_HORAFIN

	If cTpHr == Nil
		cTpHr := GetMv("MV_TPHR")
	EndIf

	If lApsInUse .And. l680
		SH1->(dbSetOrder(1))
		If SH1->(dbSeek(xFilial("SH1")+cRecurso))
			nTempoCen:=A680TimeCale(dDtIni,A680ConvHora(cHoraIni, cForHora),dDtFin,A680ConvHora(cHoraFin, cForHora),cRecurso)
		Else
			nTempoCen:=0
		EndIf
	ElseIf l680
		nTempoCen := Transform(R815Dur(cRecurso,dDtFin,A680ConvHora(cHoraFin, cForHora),dDtIni,A680ConvHora(cHoraIni, cForHora)), "")
		nTempoCen := Val(StrTran(nTempoCen, ":", "."))
	Else
		If lUsaCalend
			If !Empty(cRecurso)
				SH1->(dbSetOrder(1))
				If SH1->(dbSeek(xFilial("SH1")+cRecurso))
					nTempoCen:= A680calen(dDtIni,dDtFin,cRecurso,A680ConvHora(cHoraIni, cForHora),A680ConvHora(cHoraFin, cForHora))
				Else
					nTempoCen:=0
				EndIf
			EndIf
		Else
			cTimeIni := IIF(cForHora == "N", A680ConvHora(cHoraIni, cForHora),cHoraIni)
			cTimeFim := IIF(cForHora == "N", A680ConvHora(cHoraFin, cForHora),cHoraFin)
			nTempoCen := A680Tempo(dDtIni, cTimeIni   , dDtFin, cTimeFim )
		EndIf
	EndIf

	cTime := If(A780RetInt(nTempoCen),StrZero(nTempoCen, nZeros),StrZero(Int(nTempoCen), nZeros)) + ":" + StrZero(Mod(nTempoCen, 1) * 100, 2)

	If l680
		cTime := A680ConvHora(cTime, cTpHr, cForHora)
	Else
		cTime := A680ConvHora(cTime, "C", cForHora)
	EndIf

Return cTime


/*/{Protheus.doc} User Function IntToHora
	(long_description)
	Rotina para conseguir alterar a   
	@type  Function
	@author user
	@since 08/08/2024
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
	/*/
User Function UIntToHor(cHora)

	Local nAux    := 0
	Local cMin    := ""
	Local nValor  := 0
	Local nPosSep := 0
	Local cSep  := ':'

	Default cHora := ""

	nPosSep := RAt(cSep, cHora)
	nAux    := Val(SubStr(cHora, nPosSep+1, 2))
	nAux    := Int(Round((nAux*100)/60, 0))
	cMin    := Iif(nAux >= 10, cValToChar(nAux), "0"+cValToChar(nAux))
	nValor  := Val(SubStr(cHora, 1, nPosSep-1)+"."+cMin)

Return nValor

/*/{Protheus.doc} nomeFunction
(long_description)
Converte um tempo em horas e minutos(HH:MM) para minutos INTEIROS
@type user function
@author user
@since 03/10/2025
@version version
@param param_name, param_type, param_descr
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function TEMPTOMI(cHora)

	Local aPartes  := StrTokArr(cHora, ":")
	Local nHoras   := Val(aPartes[1])
	Local nMinutos := Val(aPartes[2])
	Local nTotMIN  := (nHoras * 60) + nMinutos

Return nTotMIN

/*/{Protheus.doc} nomeFunction
(long_description)
Converte os minutos inteiros em tempo HH:MM
@type user function
@author user
@since 03/10/2025
@version version
@param param_name, param_type, param_descr
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function MITOTEMP(nMinutos)
	Local nHoras := Int(nMinutos / 60)
	Local nRestMi := nMinutos % 60
	Local cHoForm := StrZero(nHoras, 2) + ":" + StrZero(nRestMi, 2)

Return cHoForm

/*/{Protheus.doc} GRPRE045
(long_description) Essa rotina e para as ops antigas que estava alimentando o campo H6_OP. a rotina padão não alimenta esse campo. 
Rotina padrão: MATA682 
@type user function
@author user
@since 07/04/2025
@version version
@param param_name, param_type, param_descr
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function GRPRE045()

	Local cSql 	   := ""
	Local nStatus  := 0
	Local cMsgErro := ""

	cSql := " UPDATE " + RetSqlName("SH6")
	cSql += "    SET H6_YOP     = H6_OP "
	cSql += "  WHERE H6_FILIAL  = '" + xFilial("SH6") + "' "
	cSql += "    AND H6_OP      = '" + ZH7->ZH7_NUM + "' "
	cSql += "    AND H6_YOP     = ' ' "
	cSql += "    AND H6_TIPO    = 'I' "
	cSql += "    AND D_E_L_E_T_ = ' ' "

	nStatus := TCSqlExec(cSql)

	If (nStatus < 0)
		cMsgErro := "GrPlus Error => GRPRE045: " + TCSQLError()
		oUtil:destroy()
		DisarmTransaction()
		ConOut(cMsgErro)
		MsgStop(cMsgErro)
		Return Nil
	EndIf

Return

/*/{Protheus.doc}  
(long_description)
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
User Function VALID045(oModel)

	Local aRet 		:= {.t.,""}
	Local nX   		:= 0
	Local oModelSH6 := oModel:GetModel("SH6DETAIL") // paradas
	Local oModelZH7 := oModel:GetModel("ZH7MASTER") // Ordem de produção
	Local cNum 		:= oModelZH7:GetValue("ZH7_NUM")
	Local cSql 	    := ""
	Local cMsgErro  := ""
	Local qQueryZH6 := ""

	for nX := 1 to oModelSH6:Length()

		oModelSH6:GoLine(nX)

		If !oModelSH6:IsDeleted() .and. oModelSH6:Getvalue("H6_TIPO") == "I"

			cSql := " SELECT COUNT(H6_FILIAL) CONTADOR "
			cSql += " 	FROM  " + RetSqlName("SH6")
			cSql += "  WHERE H6_FILIAL  = '" + xFilial("SH6") + "' "
			cSql += "    AND (H6_OP  = '" + cNum+ "' " + " OR " + " H6_YOP  = '" + cNum+ "' )"
			cSql += "    AND H6_TIPO = 'I' "
			cSql += "    AND D_E_L_E_T_ = ' '"

			TCQUERY cSql NEW ALIAS qQueryZH6

			If qQueryZH6->(CONTADOR) == 0

				cMsgErro := "Favor entrar em contato com o administrador do sistema. Ticket betrix24:5382"+ chr(10) //https://totvsleste.bitrix24.com.br/workgroups/group/10/tasks/task/view/5382/
				cMsgErro += "Ocorreu problema na inclusão da parada. Favor alterar o conteudo X3_RESERV do campo H6_TIPO." + chr(10)
				cMsgErro += "O X3_RESERV do campo H6_TIPO tem que ficar com o conteudo '  x             ', sem aspas simples"  + chr(10)

				aRet[1] := .F.
				aRet[2] := "Ocorreu problema na inclusão da parada."+ chr(10) //https://totvsleste.bitrix24.com.br/workgroups/group/10/tasks/task/view/5382/

				//necessario porque o sistema não estava deixando o conteudo '  x             ' com os espaços. O padrão estava comendo os espaços
				u_HELPMSG("Ocorreu problema na inclusão da parada.", cMsgErro)

			EndIf

			qQueryZH6->(DbCloseArea())

			exit

		EndIf
	next

Return aRet


/*/{Protheus.doc} REFAPONT
(long_description)
Rotina para refazer os apontamentos das ops informadas. 
@type user function
@author user
@since 07/10/2025
@version version
@param param_name, param_type, param_descr
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function REFAPONT()

	Local i,nX     := 0
	Local aNumOp   := {}
	Local dDateApo
	Local cFilOps  := cFilAnt
	Local cErrCtpo := ""
	Local aRetStr := u_HELPMSG("Informe as ops para recalcular o apontamento. Uma numero embaixo do outro","")

	Private __cRotUtil := "GRWEB"
	Private __cSemView := "SIM"

	if aRetStr[1]

		aNumOp := StrTokArr(aRetStr[2], + chr(10))

		If MsgYesNo("Deseja realmente reapontar essas ops ? "+ chr(10) + chr(10) + aRetStr[2] )

			for i := 1 to len(aNumOp)

				cNumOp := aNumOp[i]

				ZH7->(dbGoTop())

				ZH7->(DbSetOrder(1))

				If ZH7->(DbSeek(xFilial("ZH7") + cNumOp))

					//--------------------------------------------------
					// Ativo modelo do apontamento da operação.
					//--------------------------------------------------

					oModel := FWLoadModel("GROA045")

					oModel:SetOperation(4)

					If !oModel:Activate()
						aErro := oModel:GetErrorMessage()
						cErrCtpo += "1) op altera " +  cNumOp + " _ " + aErro[6] + chr(10)+ chr(10)
						loop
						//Return .F.
					EndIf

					oModelZGH := oModel:GetModel("ZGHDETAIL")

					For nX := 1 To oModelZGH:Length()

						oModelZGH:GoLine(nX)

						dDateApo := oModelZGH:GetValue("ZGH_DATAPO")
						oModelZGH:SetValue("ZGH_DATAPO", CtoD("  /  /  "))

						if !oModelZGH:SetValue("ZGH_DATAPO", dDateApo)
							cErro := "Não conseguiu inserir a data de apontamento."
							cErrCtpo += "2) op altera " +  cNumOp + " _ " + cErro + chr(10) + chr(10)
							loop
							//Return .F.
						EndIf

					Next

					If !(oModel:VldData() .And. oModel:CommitData())
						aErro := oModel:GetErrorMessage()
						oModel:DeActivate()
						cErrCtpo += "3) op altera " +  cNumOp + " _ " + aErro[6] + chr(10) + chr(10)
						loop
						//Return .F.
					EndIf

					oModel:DeActivate()
				Else
					cErrCtpo += "4) op Não encontrada " +  cNumOp + chr(10) + chr(10)
				EndIf
			next

		EndIf

	EndIf

	if !empty(cErrCtpo)
		U_HELPMSG("Erro ao reprocessar" , cErrCtpo)
	EndIf

Return

/*/{Protheus.doc}
	(long_description)
	Função para criar uma op e retornar o numero dela

	@type  Static Function
	@author user
	@since 19/10/2025
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
/*/
Static Function CRIAOP(cNumOp,oModel)

	Local lRet      := .T.
	Local oMod 		:= Nil
	Local oMod2 	:= Nil
	Local oModZH7 	:= Nil
	Local oModZH8 	:= Nil
	Local oModZH9 	:= Nil
	Local oModelZH7 := oModel:GetModel("ZH7MASTER")
	Local oModelZH8 := oModel:GetModel("ZH8DETAIL")
	Local oModelZH9 := oModel:GetModel("ZH9DETAIL")
	Local aErro     := {}
	Local aStrZH7   := {}
	Local aStrZH8   := {}
	Local aStrZH9   := {}
	Local aStZH9Aux := {}
	Local nX        := 0
	Local nY        := 0
	Local nW        := 0
	Local i         := 0

	Private oZH9    := Nil
	Private oZGH    := Nil
	Private oSH6    := Nil

	Private __cProcess := ""
	Private __lAuto    := .T.
	Private __aEngen   := {}
	Private __lAutoOp  := .T.
	Private INCLUI     := .T.
	Private ALTERA     := .F.
	Private __cProcess := oModelZH7:GetValue("ZH7_PROCES")

	Begin Transaction

		//--------------------------------------------------
		// Ativo modelo da abertura da OP.
		//--------------------------------------------------

		oMod := FWLoadModel("GROA038")

		oMod:SetOperation(MODEL_OPERATION_INSERT)

		If !oMod:Activate()
			aErro := oMod:GetErrorMessage()
			oMod:DeActivate()
			DisarmTransaction()
			Return {.f.,EncodeUTF8("0) Erro na criação da Ordem de produção" + AllTrim(aErro[6]))}
		EndIf

		oModZH7 := oMod:GetModel("ZH7MASTER")
		oModZH8 := oMod:GetModel("ZH8DETAIL")
		oModZH9 := oMod:GetModel("ZH9DETAIL")

		oModZH7:SetValue("ZH7_PROCES", oModelZH7:GetValue("ZH7_PROCES"))

		aStrZH7 := oModelZH7:getStruct():GetFields()

		For nY := 1 To Len(aStrZH7)
			__lAuto    := .T.
			oModZH7:SetValue(aStrZH7[nY][3], oModelZH7:GetValue(aStrZH7[nY][3]))
		Next


		For nX := 1 To oModelZH8:Length()

			oModelZH8:GoLine(nX)

			If !Empty(oModZH8:GetValue("ZH8_CODMAT"))
				oModZH8:AddLine()
			EndIf

			aStrZH8 := oModelZH8:getStruct():GetFields()

			aStZH8Aux := oModZH8:getStruct():GetFields()

			For nY := 1 To Len(aStrZH8)
				__lAuto := .T.

				nPos := aScan(aStZH8Aux, {|x| AllTrim(x[3]) == aStrZH8[nY][3]})

				if nPos > 0
					oModZH8:SetValue(aStrZH8[nY][3],oModelZH8:GetValue(aStrZH8[nY][3]))
				EndIf

			Next

			For nW := 1 To oModelZH9:Length()

				oModelZH9:GoLine(nW)

				If oModelZH8:GetValue("ZH8_ITEM") == oModelZH9:GetValue("ZH9_ITEM")

					If !Empty(oModZH9:GetValue("ZH9_CODPA"))
						oModZH9:AddLine()
					EndIf

					aStrZH9 := oModelZH9:getStruct():GetFields()

					aStZH9Aux := oModZH9:getStruct():GetFields()

					For nY := 1 To Len(aStrZH9)

						nPos := aScan(aStZH9Aux, {|x| AllTrim(x[3]) == aStrZH9[nY][3]})

						if nPos > 0
							oModZH9:SetValue(aStrZH9[nY][3], oModelZH9:GetValue(aStrZH9[nY][3]))
						EndIf

					Next

				EndIf

			Next

		Next

		If !(oMod:VldData() .And. oMod:CommitData())
			aErro := oMod:GetErrorMessage()
			oMod:DeActivate()
			DisarmTransaction()
			Return {.f.,EncodeUTF8("1) Erro na criação da Ordem de produção" + AllTrim(aErro[6]))}
		EndIf

		cNumOp    := oModZH7:Getvalue("ZH7_NUM")

		oMod:DeActivate()

		//Deletando todos os apontamentos criados pela rotina padrão
		oMod2 := FWLoadModel("GROA045")
		oMod2:SetOperation(4)
		oMod2:Activate()

		oZGHMod := oMod2:GetModel("ZGHDETAIL")

		For i := 1 To oZGHMod:Length()
			oZGHMod:GoLine( i )
			If !oZGHMod:IsDeleted()
				oZGHMod:DeleteLine()
			EndIf
		Next

		//Necessário porque alguns usuários estava constando como verdadeiro e com isso 
		//tentava criar a op duas vezes
		lIncluiOp := .f. 

		If !(oMod2:VldData() .And. oMod2:CommitData())
			lIncluiOp := .T. 
			aErro := oMod2:GetErrorMessage()
			oMod2:DeActivate()
			DisarmTransaction()
			Return {.f.,EncodeUTF8("2) Erro na no apontamento da Ordem de produção: " + AllTrim(aErro[6]))}
		EndIf
		
		lIncluiOp := .T. 

	End Transaction

Return {.T.,""}


/*/{Protheus.doc}
(long_description)
Função para encerrar todos os itens acabados.
@type user function
@author user
@since 19/10/2025
@version version
@param param_name, param_type, param_descr
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
Static Function ENCEROP(cOrdem,oModelAux)

	Local oModel       := Nil
	Local oModelZGM    := Nil
	Local oModelSC2    := Nil
	Local oModelZH7    := oModelAux:GetModel("ZH7MASTER")
	Local oModZH8Aux   := oModelAux:GetModel("ZH8DETAIL")
	Local oModZH9Aux   := oModelAux:GetModel("ZH9DETAIL")
	Local lDeuCerto    := .F.
	Local i			   := 0
	Local cProcess     := oModelZH7:GetValue("ZH7_PROCES")
	Local lEncontrou   := .T.
	Local cSubLot      := ""

	Begin Transaction

		ZH7->(DbSetOrder(1))
		If ZH7->(!DbSeek(xFilial("ZH7") + cOrdem))
			DisarmTransaction()
			Return {.f., EncodeUTF8("Ordem de produção não encontrada!")}
		EndIf

		// Carrega o modelo
		oModel := FWLoadModel("GROA044")
		oModel:SetOperation(4)

		If !oModel:Activate()
			aErro := oModel:GetErrorMessage()
			oModel:DeActivate()
			DisarmTransaction()
			Return {.f.,EncodeUTF8("1) Erro no encerramento da Ordem de produção" + AllTrim(aErro[6]))}
		EndIf

		// Pega o modelo master
		oModelZGM := oModel:GetModel("ZGMDETAIL")

		if cProcess == 'S'

			oModelSC2 := oModel:GetModel("SC2DETAIL")

			For i := 1 to oModZH8Aux:Length()

				oModZH8Aux:GoLine(i)

				//Percorre todos os produtos acabados que estão como pendentes.
				If oModelSC2:SeekLine({;
						{"C2_YMP",     oModZH8Aux:GetValue("ZH8_CODMAT")},;
						{"C2_YLOCMP",  oModZH8Aux:GetValue("ZH8_LOCAL")},;
						{"C2_YLOTECT", oModZH8Aux:GetValue("ZH8_LOTECT")},;
						{"C2_YNUMLOT", oModZH8Aux:GetValue("ZH8_NUMLOT")}};
						,.F.,.T.)

					oModelSC2:SetValue("C2_YCOMPLE", oModZH8Aux:GetValue("ZH8_COMPLE"))
					oModelSC2:SetValue("C2_YCOMITB", oModZH8Aux:GetValue("ZH8_COMITB"))
					oModelSC2:SetValue("C2_YALTITB", oModZH8Aux:GetValue("ZH8_ALTITB"))
					oModelSC2:SetValue("C2_YESPITB", oModZH8Aux:GetValue("ZH8_ESPITB"))
					oModelSC2:SetValue("C2_YCOMITL", oModZH8Aux:GetValue("ZH8_COMITL"))
					oModelSC2:SetValue("C2_YALTITL", oModZH8Aux:GetValue("ZH8_ALTITL"))
					oModelSC2:SetValue("C2_YESPITL", oModZH8Aux:GetValue("ZH8_ESPITL"))

				EndIf


			Next i


			For i := 1 to oModZH9Aux:Length()

				oModZH9Aux:GoLine(i)

				cSubLot := oModZH9Aux:GetValue("ZH9_SUBINI")

				lEncontrou := .T.
				while lEncontrou

					//Percorre todos os produtos acabados que estão como pendentes.
					If oModelZGM:SeekLine({;
							{"ZGM_ITEM",   oModZH9Aux:GetValue("ZH9_ITEM")},;
							{"ZGM_SEQUEN", oModZH9Aux:GetValue("ZH9_SEQUEN")},;
							{"ZGM_STATUS", "A"}};
							,.F.,.T.)

						If !empty(cSubLot)

							oModelZGM:SetValue("ZGM_NUMLOT", cSubLot)

							cSubLot := SOMA1(ALLTRIM(cSubLot))

						EndIf

						__lAuto := .T.
						oModelZGM:SetValue("ZGM_STATUS", "P")

					Else
						lEncontrou := .F.
					EndIf

				End

			Next i

		Else
			For i := 1 to oModelZGM:Length()

				oModelZGM:GoLine(i)
				__lAuto := .T.
				oModelZGM:SetValue("ZGM_STATUS", "P")

			Next i
		EndIf

		oModelZGM:GoLine(1)

		If oModel:VldData()

			If oModel:CommitData()
				lDeuCerto := .T.
			Else
				lDeuCerto := .F.
			EndIf

		Else
			lDeuCerto := .F.
		EndIf

		oModel:DeActivate()

		If !lDeuCerto
			aErro := oModel:GetErrorMessage()
			DisarmTransaction()
			Return {.f.,EncodeUTF8("1) Erro no encerramento da Ordem de produção" + AllTrim(aErro[6]))}
		EndIf

	End Transaction

Return {lDeuCerto,""}


/*/{Protheus.doc} AskProcess
Parambox para definiar o processo.
@type Static Function
@author Totvs Vitoria
@since 08/08/2019
@version version
/*/
Static Function AskProcess()

	Local aCbProcess := StrTokArr(AllTrim(Posicione("SX3",2,"ZH7_PROCES","X3_CBOX")),";")
	Local aParamBox  := {}
	Local lRet       := .T.
	Local aRet       := {}

	aAdd(aParamBox, {2, "Processo", "", aCbProcess, 100, "", .F.})

	lRet := ParamBox(aParamBox, "Alteração em Lote", aRet)

Return {lRet, aRet}
