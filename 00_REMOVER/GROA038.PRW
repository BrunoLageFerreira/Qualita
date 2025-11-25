#INCLUDE "protheus.CH"
#INCLUDE "FWMVCDEF.CH"
#Include "Parmtype.ch"
#INCLUDE "TOTVS.CH"
#INCLUDE "FWEditPanel.CH"
#INCLUDE "TOPCONN.CH"
#include "tbiconn.ch"

// //Variáveis Estáticas
Static cTitulo    := "Ordem de Produção"
Static cTiposZHL  := U_HABZGH()  // Variavel para apresentar os produtos acabados e a aba de produtos acabado no apontamento

/*/{Protheus.doc} GROA038
Tela MVC da Ordem de Produção.
@type User Function
@author Totvs Vitoria
@since 08/08/2019
@version version
/*/
User Function GROA038()

	Local aArea   := GetArea()
	Local oBrowse := NIL

	Local __cChave := STRTRAN(TIME(), ":", "") + GETHARDWAREID() + DTOS(DATE())
	If __cChave <> U_TOTVSES(SubString(__cChave,1,6))
		Return Nil
	EndIf

	Private __cProcess := ""
	Private __lAuto    := .F.
	Private __aEngen   := {}
	Private __lAutoOp  := .F.

	//---------------------------------------------------------------
	// Caso a tabela ZH7 esteja vazia carrega as informações da
	// tabela SC2 de ordens de produção
	//---------------------------------------------------------------
	DbSelectArea("ZH7")
	ZH7->(DbGoTop())
	/*
	If ZH7->(RECCOUNT()) <= 0
	//	u_LoadZH7()
	EndIf
	*/
	ZH7->(DbCloseArea())

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("ZH7")
	oBrowse:SetDescription(cTitulo)
	oBrowse:SetCacheView(.F.)
	oBrowse:Activate()

	RestArea(aArea)

Return

/*/{Protheus.doc} MenuDef
MenuDef da Ordem de Produção.
@type Static Function
@author Totvs Vitoria
@since 08/08/2019
@version version
/*/
Static Function MenuDef()

	Local aRotina := {}

	aAdd(aRotina, {'Pesquisar',  'VIEWDEF.GROA038', 0, 1, 0, NIL})
	aAdd(aRotina, {'Inclusão',   'VIEWDEF.GROA038', 0, 3, 0, NIL})
	aAdd(aRotina, {'Visualizar', 'VIEWDEF.GROA038', 0, 2, 0, NIL})
	aAdd(aRotina, {'Alterar',    'VIEWDEF.GROA038', 0, 4, 0, NIL})
	aAdd(aRotina, {'Excluir',    'VIEWDEF.GROA038', 0, 5, 0, NIL})

	If ExistBlock("GR038MEN")
		aRotina := ExecBlock("GR038MEN", .f., .f., aRotina  )
	EndIf

Return aRotina

/*/{Protheus.doc} ModelDef
ModelDef da Ordem de Produção.
@type Static Function
@author Totvs Vitoria
@since 08/08/2019
@version version
/*/
Static Function ModelDef()

	//Criação do objeto do modelo de dados
	Local oModel := NIL

	//Criação da estrutura de dados utilizada na interface
	Local oStZH7   := FWFormStruct(1, "ZH7")
	Local oStZH8   := FWFormStruct(1, "ZH8")
	Local oStZH9   := FWFormStruct(1, "ZH9")
	Local aAuxGat  := {}
	Local lSugQtde := GetNewPar("GR_SUGQTCH", .F.) // Habilita sugestão de quantidade de chapas na serrada.

	Local aRet     := {}

	//Instanciando o modelo, não é recomendado colocar nome da user function (por causa do u_), respeitando 10 caracteres
	oModel := MPFormModel():New("MGROA038",/*bPre*/,/*bPos*/,{|oModel| SaveModel(oModel)},/*bCancel*/)

	// Validações do mode de edição de campos
	oStZH7:SetProperty('ZH7_PROCES', MODEL_FIELD_WHEN,  FwBuildFeature(STRUCT_FEATURE_WHEN,  'INCLUI'))
	oStZH7:SetProperty('ZH7_EMISSA', MODEL_FIELD_WHEN,  FwBuildFeature(STRUCT_FEATURE_WHEN,  'INCLUI'))

	oStZH7:SetProperty('ZH7_RECURS', MODEL_FIELD_VALID, FwBuildFeature(STRUCT_FEATURE_VALID, 'U_GR38CORT()'))

	// Validações de campos
	oStZH8:SetProperty('ZH8_CODMAT', MODEL_FIELD_VALID, FwBuildFeature(STRUCT_FEATURE_VALID, 'If(isBlind(), .T., U_GRA038V1()) .And. IIF(__lAutoOp,.T.,ExistCpo("SB1", FwFldGet("ZH8_CODMAT")))'))
	oStZH8:SetProperty('ZH8_ENGENH', MODEL_FIELD_VALID, FwBuildFeature(STRUCT_FEATURE_VALID, 'If(isBlind(), .T., U_GRA038V2()) .And. IIF(__lAutoOp,.T.,ExistCpo("ZG7", FwFldGet("ZH8_ENGENH")))'))
	oStZH9:SetProperty('ZH9_CODPA' , MODEL_FIELD_VALID, FwBuildFeature(STRUCT_FEATURE_VALID, 'U_GRA038V3() .And. IIF(__lAutoOp,.T.,ExistCpo("SB1", FwFldGet("ZH9_CODPA")))'))
	oStZH9:SetProperty('ZH9_UM'    , MODEL_FIELD_VALID, FwBuildFeature(STRUCT_FEATURE_VALID, 'U_GRA038V5() .And. IIF(__lAutoOp,.T.,ExistCpo("SAH", FwFldGet("ZH9_UM")))'))
	oStZH9:SetProperty('ZH9_LOTECT', MODEL_FIELD_VALID, FwBuildFeature(STRUCT_FEATURE_VALID, 'U_GRA038V6()'))
	oStZH9:SetProperty('ZH9_QUANTI', MODEL_FIELD_VALID, FwBuildFeature(STRUCT_FEATURE_VALID, 'U_GRA038V7()'))

	// Remove obrigatoriedade
	oStZH8:SetProperty( 'ZH8_NUM'    , MODEL_FIELD_OBRIGAT , .F. )
	oStZH9:SetProperty( 'ZH9_NUM'    , MODEL_FIELD_OBRIGAT , .F. )
	oStZH9:SetProperty( 'ZH9_ITEM'   , MODEL_FIELD_OBRIGAT , .F. )
	oStZH9:SetProperty( 'ZH9_ENGENH' , MODEL_FIELD_OBRIGAT , .F. )
	oStZH9:SetProperty( 'ZH9_CODMAT' , MODEL_FIELD_OBRIGAT , .F. )
	//Remove obrigatoriedade quando for Recortado
	// https://projetostotvses.freshdesk.com/a/tickets/2745
	oStZH9:SetProperty( 'ZH9_TOTLIQ' , MODEL_FIELD_OBRIGAT, IIF(__cProcess == 'R',.T.,.F.) )
	// Inicializador de campos
	oStZH7:SetProperty('ZH7_PROCES', MODEL_FIELD_INIT, FwBuildFeature(STRUCT_FEATURE_INIPAD, '__cProcess'))

	If __cProcess $ 'E/B/T/R'

		aAuxGat := FwStruTrigger("ZH9_CODPA", "ZH9_QUANTI", "1", .F., NIL, NIL, NIL)
		oStZH9:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])

	ElseIf __cProcess $ 'S' .And. lSugQtde

		aAuxGat := FwStruTrigger("ZH9_CODPA", "ZH9_QUANTI", "U_GRA038V8()", .F., NIL, NIL, NIL)
		oStZH9:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])

	EndIf

	//-----------------------------------------------
	// Gatilhos tabela ZH7.
	//-----------------------------------------------
	aAuxGat := FwStruTrigger("ZH7_RECURS", "ZH7_DESCRE", 'POSICIONE("SH1", 1, XFILIAL("SH1") + M->ZH7_RECURS, "H1_DESCRI")',.F.,NIL,NIL,NIL)
	oStZH7:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZH7_FRENTE", "ZH7_DESCFR", 'POSICIONE("ZG2", 1, XFILIAL("ZG2") + M->ZH7_FRENTE, "ZG2_DESCRI")',.F.,NIL,NIL,NIL)
	oStZH7:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZH7_CODMOT", "ZH7_DESMOT", 'POSICIONE("ZH6", 1, XFILIAL("ZH6") + M->ZH7_CODMOT, "ZH6_DESCRI")',.F.,NIL,NIL,NIL)
	oStZH7:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])

	//-----------------------------------------------
	// Gatilhos tabela ZH8.
	//-----------------------------------------------
	aAuxGat := FwStruTrigger("ZH8_CODMAT", "ZH8_DESCMT", 'POSICIONE("SB1", 1, XFILIAL("SB1") + M->ZH8_CODMAT, "B1_DESC")',.F.,NIL,NIL,NIL)
	oStZH8:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZH8_ENGENH", "ZH8_DESCEN", 'POSICIONE("ZG7", 1, XFILIAL("ZG7") + M->ZH8_ENGENH, "ZG7_DESCRI")',.F.,NIL,NIL,NIL)
	oStZH8:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])

	If isBlind()

		aAuxGat := FwStruTrigger("ZH8_CODMAT", "ZH8_COMLIQ", 'POSICIONE("SB8", 3, XFILIAL("SB8") + M->(ZH8_CODMAT + ZH8_LOCAL + ZH8_LOTECT + ZH8_NUMLOT), "B8_YCOMLIQ")',.F.,NIL,NIL,NIL)
		oStZH8:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
		aAuxGat := FwStruTrigger("ZH8_CODMAT", "ZH8_ALTLIQ", 'POSICIONE("SB8", 3, XFILIAL("SB8") + M->(ZH8_CODMAT + ZH8_LOCAL + ZH8_LOTECT + ZH8_NUMLOT), "B8_YALTLIQ")',.F.,NIL,NIL,NIL)
		oStZH8:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
		aAuxGat := FwStruTrigger("ZH8_CODMAT", "ZH8_ESPLIQ", 'POSICIONE("SB8", 3, XFILIAL("SB8") + M->(ZH8_CODMAT + ZH8_LOCAL + ZH8_LOTECT + ZH8_NUMLOT), "B8_YESPLIQ")',.F.,NIL,NIL,NIL)
		oStZH8:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])

		aAuxGat := FwStruTrigger("ZH8_CODMAT", "ZH8_COMBRU", 'POSICIONE("SB8", 3, XFILIAL("SB8") + M->(ZH8_CODMAT + ZH8_LOCAL + ZH8_LOTECT + ZH8_NUMLOT), "B8_YCOMBRU")',.F.,NIL,NIL,NIL)
		oStZH8:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
		aAuxGat := FwStruTrigger("ZH8_CODMAT", "ZH8_ALTBRU", 'POSICIONE("SB8", 3, XFILIAL("SB8") + M->(ZH8_CODMAT + ZH8_LOCAL + ZH8_LOTECT + ZH8_NUMLOT), "B8_YALTBRU")',.F.,NIL,NIL,NIL)
		oStZH8:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
		aAuxGat := FwStruTrigger("ZH8_CODMAT", "ZH8_ESPBRU", 'POSICIONE("SB8", 3, XFILIAL("SB8") + M->(ZH8_CODMAT + ZH8_LOCAL + ZH8_LOTECT + ZH8_NUMLOT), "B8_YESPBRU")',.F.,NIL,NIL,NIL)
		oStZH8:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])

		aAuxGat := FwStruTrigger("ZH8_LOCAL", "ZH8_COMLIQ", 'POSICIONE("SB8", 3, XFILIAL("SB8") + M->(ZH8_CODMAT + ZH8_LOCAL + ZH8_LOTECT + ZH8_NUMLOT), "B8_YCOMLIQ")',.F.,NIL,NIL,NIL)
		oStZH8:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
		aAuxGat := FwStruTrigger("ZH8_LOCAL", "ZH8_ALTLIQ", 'POSICIONE("SB8", 3, XFILIAL("SB8") + M->(ZH8_CODMAT + ZH8_LOCAL + ZH8_LOTECT + ZH8_NUMLOT), "B8_YALTLIQ")',.F.,NIL,NIL,NIL)
		oStZH8:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
		aAuxGat := FwStruTrigger("ZH8_LOCAL", "ZH8_ESPLIQ", 'POSICIONE("SB8", 3, XFILIAL("SB8") + M->(ZH8_CODMAT + ZH8_LOCAL + ZH8_LOTECT + ZH8_NUMLOT), "B8_YESPLIQ")',.F.,NIL,NIL,NIL)
		oStZH8:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])

		aAuxGat := FwStruTrigger("ZH8_LOTECT", "ZH8_COMLIQ", 'POSICIONE("SB8", 3, XFILIAL("SB8") + M->(ZH8_CODMAT + ZH8_LOCAL + ZH8_LOTECT + ZH8_NUMLOT), "B8_YCOMLIQ")',.F.,NIL,NIL,NIL)
		oStZH8:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
		aAuxGat := FwStruTrigger("ZH8_LOTECT", "ZH8_ALTLIQ", 'POSICIONE("SB8", 3, XFILIAL("SB8") + M->(ZH8_CODMAT + ZH8_LOCAL + ZH8_LOTECT + ZH8_NUMLOT), "B8_YALTLIQ")',.F.,NIL,NIL,NIL)
		oStZH8:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
		aAuxGat := FwStruTrigger("ZH8_LOTECT", "ZH8_ESPLIQ", 'POSICIONE("SB8", 3, XFILIAL("SB8") + M->(ZH8_CODMAT + ZH8_LOCAL + ZH8_LOTECT + ZH8_NUMLOT), "B8_YESPLIQ")',.F.,NIL,NIL,NIL)
		oStZH8:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])

		aAuxGat := FwStruTrigger("ZH8_NUMLOT", "ZH8_COMLIQ", 'POSICIONE("SB8", 3, XFILIAL("SB8") + M->(ZH8_CODMAT + ZH8_LOCAL + ZH8_LOTECT + ZH8_NUMLOT), "B8_YCOMLIQ")',.F.,NIL,NIL,NIL)
		oStZH8:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
		aAuxGat := FwStruTrigger("ZH8_NUMLOT", "ZH8_ALTLIQ", 'POSICIONE("SB8", 3, XFILIAL("SB8") + M->(ZH8_CODMAT + ZH8_LOCAL + ZH8_LOTECT + ZH8_NUMLOT), "B8_YALTLIQ")',.F.,NIL,NIL,NIL)
		oStZH8:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
		aAuxGat := FwStruTrigger("ZH8_NUMLOT", "ZH8_ESPLIQ", 'POSICIONE("SB8", 3, XFILIAL("SB8") + M->(ZH8_CODMAT + ZH8_LOCAL + ZH8_LOTECT + ZH8_NUMLOT), "B8_YESPLIQ")',.F.,NIL,NIL,NIL)
		oStZH8:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])

	EndIf

	// Gatilho para atualizar o TOTAL LIQUIDO M2
	aAuxGat := FwStruTrigger("ZH8_COMLIQ","ZH8_TOTLIQ","ROUND(M->ZH8_COMLIQ * M->ZH8_ALTLIQ, TAMSX3('ZH8_TOTLIQ')[2])",.F.,NIL,NIL,NIL,"AllTrim(M->ZH8_UM) == 'M2'")
	oStZH8:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZH8_ALTLIQ","ZH8_TOTLIQ","ROUND(M->ZH8_COMLIQ * M->ZH8_ALTLIQ, TAMSX3('ZH8_TOTLIQ')[2])",.F.,NIL,NIL,NIL,"AllTrim(M->ZH8_UM) == 'M2'")
	oStZH8:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZH8_ESPLIQ","ZH8_TOTLIQ","ROUND(M->ZH8_COMLIQ * M->ZH8_ALTLIQ, TAMSX3('ZH8_TOTLIQ')[2])",.F.,NIL,NIL,NIL,"AlLTrim(M->ZH8_UM) == 'M2'")
	oStZH8:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])

	// Gatilho para atualizar o TOTAL LIQUIDO M3
	aAuxGat := FwStruTrigger("ZH8_COMLIQ","ZH8_TOTLIQ","ROUND(M->ZH8_COMLIQ * M->ZH8_ALTLIQ * M->ZH8_ESPLIQ, TAMSX3('ZH8_TOTLIQ')[2])",.F.,NIL,NIL,NIL,"AllTrim(M->ZH8_UM) == 'M3'")
	oStZH8:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZH8_ALTLIQ","ZH8_TOTLIQ","ROUND(M->ZH8_COMLIQ * M->ZH8_ALTLIQ * M->ZH8_ESPLIQ, TAMSX3('ZH8_TOTLIQ')[2])",.F.,NIL,NIL,NIL,"AlLTrim(M->ZH8_UM) == 'M3'")
	oStZH8:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZH8_ESPLIQ","ZH8_TOTLIQ","ROUND(M->ZH8_COMLIQ * M->ZH8_ALTLIQ * M->ZH8_ESPLIQ, TAMSX3('ZH8_TOTLIQ')[2])",.F.,NIL,NIL,NIL,"AlLTrim(M->ZH8_UM) == 'M3'")
	oStZH8:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])

	// Gatilho para atualizar os campos das medidas BRUTAS
	aAuxGat := FwStruTrigger("ZH8_COMLIQ","ZH8_COMBRU","M->ZH8_COMLIQ",.F.,NIL,NIL,NIL)
	oStZH8:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZH8_ALTLIQ","ZH8_ALTBRU","M->ZH8_ALTLIQ",.F.,NIL,NIL,NIL)
	oStZH8:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZH8_ESPLIQ","ZH8_ESPBRU","M->ZH8_ESPLIQ",.F.,NIL,NIL,NIL)
	oStZH8:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])

	// Gatilho para atualizar o TOTAL BRUTO M2
	aAuxGat := FwStruTrigger("ZH8_COMBRU","ZH8_TOTBRU","ROUND(M->ZH8_COMBRU * M->ZH8_ALTBRU, TAMSX3('ZH8_TOTBRU')[2])",.F.,NIL,NIL,NIL,"AlLTrim(M->ZH8_UM) == 'M2'")
	oStZH8:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZH8_ALTBRU","ZH8_TOTBRU","ROUND(M->ZH8_COMBRU * M->ZH8_ALTBRU, TAMSX3('ZH8_TOTBRU')[2])",.F.,NIL,NIL,NIL,"AlLTrim(M->ZH8_UM) == 'M2'")
	oStZH8:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZH8_ESPBRU","ZH8_TOTBRU","ROUND(M->ZH8_COMBRU * M->ZH8_ALTBRU, TAMSX3('ZH8_TOTBRU')[2])",.F.,NIL,NIL,NIL,"AlLTrim(M->ZH8_UM) == 'M2'")
	oStZH8:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])

	// Gatilho para atualizar o TOTAL BRUTO M3
	aAuxGat := FwStruTrigger("ZH8_COMBRU","ZH8_TOTBRU","ROUND(M->ZH8_COMBRU * M->ZH8_ALTBRU * M->ZH8_ESPBRU, TAMSX3('ZH8_TOTBRU')[2])",.F.,NIL,NIL,NIL,"AlLTrim(M->ZH8_UM) == 'M3'")
	oStZH8:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZH8_ALTBRU","ZH8_TOTBRU","ROUND(M->ZH8_COMBRU * M->ZH8_ALTBRU * M->ZH8_ESPBRU, TAMSX3('ZH8_TOTBRU')[2])",.F.,NIL,NIL,NIL,"AlLTrim(M->ZH8_UM) == 'M3'")
	oStZH8:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZH8_ESPBRU","ZH8_TOTBRU","ROUND(M->ZH8_COMBRU * M->ZH8_ALTBRU * M->ZH8_ESPBRU, TAMSX3('ZH8_TOTBRU')[2])",.F.,NIL,NIL,NIL,"AlLTrim(M->ZH8_UM) == 'M3'")
	oStZH8:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])

	//-----------------------------------------------
	// Gatilhos tabela ZH9.
	//-----------------------------------------------
	aAuxGat := FwStruTrigger("ZH9_CODPA",  "ZH9_DESCPA", 'POSICIONE("SB1", 1, XFILIAL("SB1") + M->ZH9_CODPA,  "B1_DESC")',.F.,NIL,NIL,NIL)
	oStZH9:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZH9_CODPA",  "ZH9_UM", 'POSICIONE("SB1", 1, XFILIAL("SB1") + M->ZH9_CODPA,  "B1_UM")',.F.,NIL,NIL,NIL)
	oStZH9:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZH9_CODPA",  "ZH9_LOCAL", 'POSICIONE("SB1", 1, XFILIAL("SB1") + M->ZH9_CODPA,  "B1_LOCPAD")',.F.,NIL,NIL,NIL)
	oStZH9:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZH9_CODPA",  "ZH9_ESPLIQ", 'POSICIONE("SB5", 1, XFILIAL("SB5") + M->ZH9_CODPA,  "B5_ESPESS")',.F.,NIL,NIL,NIL,"AlLTrim(M->ZH9_UM) == 'M2'")
	oStZH9:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZH9_CODPA",  "ZH9_ESPBRU", 'POSICIONE("SB5", 1, XFILIAL("SB5") + M->ZH9_CODPA,  "B5_ESPESS")',.F.,NIL,NIL,NIL,"AlLTrim(M->ZH9_UM) == 'M2'")
	oStZH9:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZH9_CODPA",  "ZH9_SEGUM", 'POSICIONE("SB1", 1, XFILIAL("SB1") + M->ZH9_CODPA,  "B1_SEGUM")',.F.,NIL,NIL,NIL)
	oStZH9:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])

	// Gatilho para atualizar o TOTAL LIQUIDO M2
	aAuxGat := FwStruTrigger("ZH9_CODPA","ZH9_TOTLIQ","ROUND(M->ZH9_COMLIQ * M->ZH9_ALTLIQ, TAMSX3('ZH9_TOTLIQ')[2])",.F.,NIL,NIL,NIL)
	oStZH9:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZH9_COMLIQ","ZH9_TOTLIQ","ROUND(M->ZH9_COMLIQ * M->ZH9_ALTLIQ, TAMSX3('ZH9_TOTLIQ')[2])",.F.,NIL,NIL,NIL,"AlLTrim(M->ZH9_UM) == 'M2'")
	oStZH9:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZH9_ALTLIQ","ZH9_TOTLIQ","ROUND(M->ZH9_COMLIQ * M->ZH9_ALTLIQ, TAMSX3('ZH9_TOTLIQ')[2])",.F.,NIL,NIL,NIL,"AlLTrim(M->ZH9_UM) == 'M2'")
	oStZH9:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZH9_ESPLIQ","ZH9_TOTLIQ","ROUND(M->ZH9_COMLIQ * M->ZH9_ALTLIQ, TAMSX3('ZH9_TOTLIQ')[2])",.F.,NIL,NIL,NIL,"AlLTrim(M->ZH9_UM) == 'M2'")
	oStZH9:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])

	// Gatilho para atualizar o TOTAL LIQUIDO M3
	aAuxGat := FwStruTrigger("ZH9_CODPA","ZH9_TOTLIQ","ROUND(M->ZH9_COMLIQ * M->ZH9_ALTLIQ * M->ZH9_ESPLIQ, TAMSX3('ZH9_TOTLIQ')[2])",.F.,NIL,NIL,NIL,"AlLTrim(M->ZH9_UM) == 'M3'")
	oStZH9:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZH9_COMLIQ","ZH9_TOTLIQ","ROUND(M->ZH9_COMLIQ * M->ZH9_ALTLIQ * M->ZH9_ESPLIQ, TAMSX3('ZH9_TOTLIQ')[2])",.F.,NIL,NIL,NIL,"AlLTrim(M->ZH9_UM) == 'M3'")
	oStZH9:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZH9_ALTLIQ","ZH9_TOTLIQ","ROUND(M->ZH9_COMLIQ * M->ZH9_ALTLIQ * M->ZH9_ESPLIQ, TAMSX3('ZH9_TOTLIQ')[2])",.F.,NIL,NIL,NIL,"AlLTrim(M->ZH9_UM) == 'M3'")
	oStZH9:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZH9_ESPLIQ","ZH9_TOTLIQ","ROUND(M->ZH9_COMLIQ * M->ZH9_ALTLIQ * M->ZH9_ESPLIQ, TAMSX3('ZH9_TOTLIQ')[2])",.F.,NIL,NIL,NIL,"AlLTrim(M->ZH9_UM) == 'M3'")
	oStZH9:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])

	// Gatilho para atualizar os campos das medidas BRUTAS
	aAuxGat := FwStruTrigger("ZH9_COMLIQ","ZH9_COMBRU","M->ZH9_COMLIQ",.F.,NIL,NIL,NIL)
	oStZH9:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZH9_ALTLIQ","ZH9_ALTBRU","M->ZH9_ALTLIQ",.F.,NIL,NIL,NIL)
	oStZH9:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZH9_ESPLIQ","ZH9_ESPBRU","M->ZH9_ESPLIQ",.F.,NIL,NIL,NIL)
	oStZH9:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])

	// Gatilho para atualizar o TOTAL BRUTO M2
	aAuxGat := FwStruTrigger("ZH9_CODPA","ZH9_TOTBRU","ROUND(M->ZH9_COMBRU * M->ZH9_ALTBRU, TAMSX3('ZH9_TOTBRU')[2])",.F.,NIL,NIL,NIL,"AlLTrim(M->ZH9_UM) == 'M2'")
	oStZH9:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZH9_COMBRU","ZH9_TOTBRU","ROUND(M->ZH9_COMBRU * M->ZH9_ALTBRU, TAMSX3('ZH9_TOTBRU')[2])",.F.,NIL,NIL,NIL,"AlLTrim(M->ZH9_UM) == 'M2'")
	oStZH9:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZH9_ALTBRU","ZH9_TOTBRU","ROUND(M->ZH9_COMBRU * M->ZH9_ALTBRU, TAMSX3('ZH9_TOTBRU')[2])",.F.,NIL,NIL,NIL,"AlLTrim(M->ZH9_UM) == 'M2'")
	oStZH9:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZH9_ESPBRU","ZH9_TOTBRU","ROUND(M->ZH9_COMBRU * M->ZH9_ALTBRU, TAMSX3('ZH9_TOTBRU')[2])",.F.,NIL,NIL,NIL,"AlLTrim(M->ZH9_UM) == 'M2'")
	oStZH9:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])

	// Gatilho para atualizar o TOTAL BRUTO M3
	aAuxGat := FwStruTrigger("ZH9_CODPA","ZH9_TOTBRU","ROUND(M->ZH9_COMBRU * M->ZH9_ALTBRU * M->ZH9_ESPBRU, TAMSX3('ZH9_TOTBRU')[2])",.F.,NIL,NIL,NIL,"AlLTrim(M->ZH9_UM) == 'M3'")
	oStZH9:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZH9_COMBRU","ZH9_TOTBRU","ROUND(M->ZH9_COMBRU * M->ZH9_ALTBRU * M->ZH9_ESPBRU, TAMSX3('ZH9_TOTBRU')[2])",.F.,NIL,NIL,NIL,"AlLTrim(M->ZH9_UM) == 'M3'")
	oStZH9:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZH9_ALTBRU","ZH9_TOTBRU","ROUND(M->ZH9_COMBRU * M->ZH9_ALTBRU * M->ZH9_ESPBRU, TAMSX3('ZH9_TOTBRU')[2])",.F.,NIL,NIL,NIL,"AlLTrim(M->ZH9_UM) == 'M3'")
	oStZH9:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])
	aAuxGat := FwStruTrigger("ZH9_ESPBRU","ZH9_TOTBRU","ROUND(M->ZH9_COMBRU * M->ZH9_ALTBRU * M->ZH9_ESPBRU, TAMSX3('ZH9_TOTBRU')[2])",.F.,NIL,NIL,NIL,"AlLTrim(M->ZH9_UM) == 'M3'")
	oStZH9:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])

	If __cProcess == 'R'
		// Gatilho para atualizar o TOTAL BRUTO na Op de recortado. Isso e necessário porque o total bruto pode ser o
		aAuxGat := FwStruTrigger("ZH9_TOTLIQ","ZH9_TOTBRU","M->ZH9_TOTLIQ",.F.,NIL,NIL,NIL)
		oStZH9:AddTrigger(aAuxGat[1],aAuxGat[2],aAuxGat[3],aAuxGat[4])

	EndIf

	//Atribuindo formulários para o modelo
	oModel:AddFields("ZH7MASTER",/*cOwner*/,oStZH7)

	//Atribuindo Grid ao modelo
	oModel:AddGrid( 'ZH8DETAIL', 'ZH7MASTER' , oStZH8)

	//Atribuindo campos calculados ao modelo
	oModel:AddCalc('CALC_BORDETAIL', 'ZH7MASTER', 'ZH8DETAIL', 'ZH8_TOTLIQ', 'QTD_QUANT', 'COUNT',/*bCondition*/, /*bInitValue*/,"Quantidade de Itens",/*bFormula*/,13 /*nTamanho*/,3 /*nDecimal*/)
	oModel:AddCalc('CALC_BORDETAIL', 'ZH7MASTER', 'ZH8DETAIL', 'ZH8_TOTLIQ', 'QTD_TOTALM', 'SUM',/*bCondition*/, /*bInitValue*/,"Total Metros (Liquido)",/*bFormula*/,13 /*nTamanho*/,TAMSX3('ZH8_TOTLIQ')[2] /*nDecimal*/)

	If __cProcess == 'R'
		oModel:AddGrid( 'ZH9DETAIL', 'ZH7MASTER' , oStZH9)
	Else
		oModel:AddGrid( 'ZH9DETAIL', 'ZH8DETAIL' , oStZH9)
	EndIf

	oModel:SetRelation('ZH8DETAIL', {{'ZH8_FILIAL','FwXFilial("ZH8")'}, {'ZH8_NUM','ZH7_NUM'}}, ZH8->(IndexKey(1)))

	If __cProcess == 'R'
		oModel:SetRelation('ZH9DETAIL', {{'ZH9_FILIAL','FwXFilial("ZH9")'}, {'ZH9_NUM','ZH7_NUM'}, {'ZH9_ITEM', '"01"'}}, ZH9->(IndexKey(1)))
	Else
		oModel:SetRelation('ZH9DETAIL', {{'ZH9_FILIAL','FwXFilial("ZH9")'}, {'ZH9_NUM','ZH7_NUM'}, {'ZH9_ITEM','ZH8_ITEM'}}, ZH9->(IndexKey(1)))
	EndIf

	//Setando a chave primária da rotina
	oModel:SetPrimaryKey({"ZH7_FILIAL", "ZH7_NUM"})

	oModel:GetModel('ZH8DETAIL'):SetUniqueLine({'ZH8_CODMAT','ZH8_LOTECT','ZH8_NUMLOT'})

	//Apenas deixa preencher o codigo da materia prima se a engenharia estiver preenchida
	// oModel:AddRules( 'ZH8DETAIL', 'ZH8_ENGENH', 'ZH8DETAIL', 'ZH8_CODMAT', 1)

	//Adicionando descrição ao modelo
	oModel:SetDescription(cTitulo)

	//Verifica se realiza ativição do Modelo
	oModel:SetVldActivate( { |oModel| ValidActiv(oModel) } )

Return oModel

/*/{Protheus.doc} ViewDef
ViewDef da Ordem de Produção.
@type Static Function
@author Totvs Vitoria
@since 08/08/2019
@version version
/*/
Static Function ViewDef()

	Local oModel   := Nil
	Local oStZH7   := FWFormStruct(2, "ZH7")
	Local oStZH8   := FWFormStruct(2, "ZH8")
	Local oStZH9   := FWFormStruct(2, "ZH9")
	Local oStBorda := Nil
	Local oView    := Nil
	Local aRet     := {}
	Local aParEst  := StrTokArr( superGetMv("GR_KEYEST", .F., "17,[Ctrl+Q]"), "," )
	Local cKeyEst  := aParEst[1]
	Local bGetProd := {|| FWMsgRun(, {|| GetProd()}, "Processando", "Carregando Produtos...") }


	//1 Analizado que o sistema realiza o modeldef primeiro e depois o viewdef, isso faz com que a operação fique em branco quando tenta realizar a primeira vez
	//https://totvsleste.freshdesk.com/a/tickets/983
	//2 Quando cancela dentro do modelo, o sistema precisa retorna um modelo. Com isso estava apresentando erro
	//3 Voltei para o viewdef porque existe 	oBrowse:SetCacheView(.F.) que faz a view sempre executar primeiro.
	//https://totvsleste.freshdesk.com/a/tickets/1687
	IF !IsBlind()
		If Inclui
			If !ValidaCampos()
				Return .f.
			EndIf

			aRet := AskProcess()

			If !aRet[1]
				MsgInfo("Processo cancelado pelo usuário!")
				Return .f.
			EndIf

			If aRet[1]
				__cProcess := aRet[2][1]
			EndIf
		Else
			__cProcess := ZH7->ZH7_PROCES
		EndIf
	EndIf


	//-----------------------------------------------------
	// O Modelo deve ser instânciado após o ParamBox
	//-----------------------------------------------------
	oModel   := FWLoadModel("GROA038")
	oStBorda := FWCalcStruct(oModel:GetModel('CALC_BORDETAIL'))

	//-----------------------------------------------------
	// Criando a view que será o retorno da função e
	// setando o modelo da rotina.
	//-----------------------------------------------------
	oView := FWFormView():New()

	oView:addUserButton(aParEst[2] +" Consulta Estoque", "CONSULTA", bGetProd, "Consulta Estoque de Produtos")

	SetKey(Val(cKeyEst), bGetProd)

	oView:SetModel(oModel)

	oStZH7:SetProperty('ZH7_ITEMRO', MVC_VIEW_CANCHANGE,.F.)

	oStZH8:SetProperty('ZH8_DESCMT', MVC_VIEW_CANCHANGE, .F.)
	oStZH8:SetProperty('ZH8_DESCEN', MVC_VIEW_CANCHANGE, .F.)
	oStZH8:SetProperty('ZH8_COMLIQ', MVC_VIEW_CANCHANGE, __cProcess $ "S/D/R")
	oStZH8:SetProperty('ZH8_ALTLIQ', MVC_VIEW_CANCHANGE, __cProcess $ "S/D/R")
	oStZH8:SetProperty('ZH8_ESPLIQ', MVC_VIEW_CANCHANGE, __cProcess $ "S/D")
	oStZH8:SetProperty('ZH8_TOTLIQ', MVC_VIEW_CANCHANGE, .F.)
	oStZH8:SetProperty('ZH8_COMBRU', MVC_VIEW_CANCHANGE, __cProcess $ "S/D/R")
	oStZH8:SetProperty('ZH8_ALTBRU', MVC_VIEW_CANCHANGE, __cProcess $ "S/D/R")
	oStZH8:SetProperty('ZH8_ESPBRU', MVC_VIEW_CANCHANGE, __cProcess $ "S/D")
	oStZH8:SetProperty('ZH8_TOTBRU', MVC_VIEW_CANCHANGE, .F.)

	oStZH9:SetProperty('ZH9_DESCPA', MVC_VIEW_CANCHANGE, .F.)
	oStZH9:SetProperty('ZH9_LOTECT', MVC_VIEW_CANCHANGE, __cProcess $ "E/S/D/R")
	oStZH9:SetProperty('ZH9_NUMLOT', MVC_VIEW_CANCHANGE, __cProcess $ "D/R") //https://totvsleste.freshdesk.com/a/tickets/5468
	oStZH9:SetProperty('ZH9_COMLIQ', MVC_VIEW_CANCHANGE, __cProcess $ "E/S/D")
	oStZH9:SetProperty('ZH9_ALTLIQ', MVC_VIEW_CANCHANGE, __cProcess $ "E/S/D")
	oStZH9:SetProperty('ZH9_ESPLIQ', MVC_VIEW_CANCHANGE, __cProcess $ "E/S/D")
	oStZH9:SetProperty('ZH9_TOTLIQ', MVC_VIEW_CANCHANGE, __cProcess $ "R")

	//Remove obrigatoriedade quando for Recortado // https://projetostotvses.freshdesk.com/a/tickets/2745

	oStZH9:SetProperty('ZH9_COMBRU', MVC_VIEW_CANCHANGE, __cProcess $ "E/S/D")
	oStZH9:SetProperty('ZH9_ALTBRU', MVC_VIEW_CANCHANGE, __cProcess $ "E/S/D")
	oStZH9:SetProperty('ZH9_ESPBRU', MVC_VIEW_CANCHANGE, __cProcess $ "E/S/D")
	oStZH9:SetProperty('ZH9_TOTBRU', MVC_VIEW_CANCHANGE, .F.)
	//oStZH9:SetProperty('ZH9_QUANTI', MVC_VIEW_CANCHANGE, __cProcess $ "R") //obrigatoriedade quando for Recortado	 // removido devido as outras operações, como operação de serrada e necessário informar a quantidade de chapas.

	oStZH7:RemoveField('ZH7_ENGENH')
	oStZH7:RemoveField('ZH7_DESCEN')
	oStZH7:RemoveField('ZH7_BLOCO')

	If ZH7->(FieldPos("ZH7_ROTINA")) > 0
		oStZH7:RemoveField('ZH7_ROTINA')
	EndIf

	If __cProcess == "E"

		// Remove campos do cabeçalho
		oStZH7:RemoveField('ZH7_CODMOT')
		oStZH7:RemoveField('ZH7_DESMOT')
		oStZH7:RemoveField('ZH7_COECOR')
		// Remove campos da grid de matéria-prima
		oStZH8:RemoveField('ZH8_LOTECT')
		oStZH8:RemoveField('ZH8_NUMLOT')
		oStZH8:RemoveField('ZH8_LOCAL')
		oStZH8:RemoveField('ZH8_COMLIQ')
		oStZH8:RemoveField('ZH8_ALTLIQ')
		oStZH8:RemoveField('ZH8_ESPLIQ')
		oStZH8:RemoveField('ZH8_TOTLIQ')
		oStZH8:RemoveField('ZH8_COMBRU')
		oStZH8:RemoveField('ZH8_ALTBRU')
		oStZH8:RemoveField('ZH8_ESPBRU')
		oStZH8:RemoveField('ZH8_TOTBRU')
		// Remove campos da grid de produto acabado
		oStZH9:RemoveField('ZH9_QUANTI')
		oStZH9:RemoveField('ZH9_NUMLOT')
		// oStZH9:RemoveField('ZH9_LOCAL')
		// Altera a consulta padrão para Pedreira
		oStZH8:SetProperty('ZH8_CODMAT', MVC_VIEW_LOOKUP, 'GRZH8C')

	ElseIf __cProcess $ "S"

		oStZH7:RemoveField('ZH7_FRENTE')
		oStZH7:RemoveField('ZH7_DESCFR')
		oStZH7:RemoveField('ZH7_CODMOT')
		oStZH7:RemoveField('ZH7_DESMOT')
		// Altera a consulta padrão para Estoque
		oStZH8:SetProperty('ZH8_CODMAT', MVC_VIEW_LOOKUP, 'GRZH8B')
		// Remove campos da grid de produto acabado
		//oStZH9:RemoveField('ZH9_LOTECT')
		oStZH9:RemoveField('ZH9_NUMLOT')
		// oStZH9:RemoveField('ZH9_LOCAL')

	ElseIf __cProcess $ "D"

		oStZH7:RemoveField('ZH7_FRENTE')
		oStZH7:RemoveField('ZH7_DESCFR')
		oStZH7:RemoveField('ZH7_CODMOT')
		oStZH7:RemoveField('ZH7_DESMOT')
		// Altera a consulta padrão para Estoque
		oStZH8:SetProperty('ZH8_CODMAT', MVC_VIEW_LOOKUP, 'GRZH8B')

		oStZH9:RemoveField('ZH9_QUANTI')

	ElseIf __cProcess == "B"

		oStZH7:RemoveField('ZH7_FRENTE')
		oStZH7:RemoveField('ZH7_DESCFR')
		//oStZH7:RemoveField('ZH7_CODMOT') //https://totvsleste.freshdesk.com/a/tickets/1386
		//oStZH7:RemoveField('ZH7_DESMOT')
		oStZH7:RemoveField('ZH7_COECOR')
		// Altera a consulta padrão para Estoque
		oStZH8:SetProperty('ZH8_CODMAT', MVC_VIEW_LOOKUP, 'GRZH8B')
		// Remove campos da grid de produto acabado
		oStZH9:RemoveField('ZH9_QUANTI')

	ElseIf __cProcess == "R"

		oStZH7:RemoveField('ZH7_FRENTE')
		oStZH7:RemoveField('ZH7_DESCFR')
		oStZH7:RemoveField('ZH7_CODMOT')
		oStZH7:RemoveField('ZH7_DESMOT')
		oStZH7:RemoveField('ZH7_COECOR')
		// Altera a consulta padrão para Estoque
		oStZH8:SetProperty('ZH8_CODMAT', MVC_VIEW_LOOKUP, 'GRZH8B')
		// Remove campos da grid de produto acabado
		// oStZH9:RemoveField('ZH9_LOTECT')
		// oStZH9:RemoveField('ZH9_NUMLOT')
		oStZH9:RemoveField('ZH9_QUANTI')
		oStZH9:RemoveField('ZH9_COMLIQ')
		oStZH9:RemoveField('ZH9_ALTLIQ')
		oStZH9:RemoveField('ZH9_ESPLIQ')
		// oStZH9:RemoveField('ZH9_TOTLIQ')
		oStZH9:RemoveField('ZH9_COMBRU')
		oStZH9:RemoveField('ZH9_ALTBRU')
		oStZH9:RemoveField('ZH9_ESPBRU')
		oStZH9:RemoveField('ZH9_TOTBRU')

	ElseIf __cProcess == "T"

		oStZH7:RemoveField('ZH7_FRENTE')
		oStZH7:RemoveField('ZH7_DESCFR')
		//oStZH7:RemoveField('ZH7_CODMOT') //https://totvsleste.freshdesk.com/a/tickets/1386
		//oStZH7:RemoveField('ZH7_DESMOT')
		// Altera a consulta padrão para Estoque
		oStZH8:SetProperty('ZH8_CODMAT', MVC_VIEW_LOOKUP, 'GRZH8B')
		// Remove campos da grid de produto acabado
		oStZH9:RemoveField('ZH9_QUANTI')

	EndIf

	// NÃO ALTERAR O VALOR PELA VIEW, UMA VEZ QUE ELE JÁ VEM PREENCHIDO
	oStZH7:SetProperty('ZH7_PROCES', MVC_VIEW_CANCHANGE, .F.)

	// Altera o tamanho da conluna na GRID
	oStZH8:SetProperty("ZH8_DESCEN", MVC_VIEW_WIDTH, 200)
	oStZH8:SetProperty("ZH8_DESCMT", MVC_VIEW_WIDTH, 200)

	//Atribuindo campos de calculos
	oView:AddField('VIEW_CALC', oStBorda,'CALC_BORDETAIL')

	//Atribuindo formulários para interface
	oView:AddField("VIEW_ZH7", oStZH7, "ZH7MASTER")
	oView:AddGrid("VIEW_ZH8",  oStZH8, "ZH8DETAIL")
	oView:AddGrid("VIEW_ZH9",  oStZH9, "ZH9DETAIL")

	oView:CreateHorizontalBox("SUPERIOR", 30)
	oView:CreateHorizontalBox("CENTRO", 30)
	oView:CreateHorizontalBox("INFERIOR", 30)
	oView:CreateHorizontalBox("BORDA", 10)

	//Força o fechamento da janela na confirmação
	oView:SetCloseOnOk({||.T.})

	//Adicione o incremental
	oView:AddIncrementField('VIEW_ZH8', 'ZH8_ITEM')
	oView:AddIncrementField('VIEW_ZH9', 'ZH9_SEQUEN')

	oStZH8:RemoveField('ZH8_NUM')
	oStZH9:RemoveField('ZH9_NUM')
	oStZH9:RemoveField('ZH9_ITEM')
	oStZH9:RemoveField('ZH9_ENGENH')
	oStZH9:RemoveField('ZH9_CODMAT')

	//Colocando título do formulário
	oView:EnableTitleView('VIEW_ZH7', 'Ordem de Produção')
	oView:EnableTitleView('VIEW_ZH8', 'Matéria-Prima')
	oView:EnableTitleView('VIEW_ZH9', 'Produto Acabado')

	oView:SetOwnerView("VIEW_ZH7","SUPERIOR")
	oView:SetOwnerView("VIEW_ZH8","CENTRO")
	oView:SetOwnerView("VIEW_ZH9","INFERIOR")
	oView:SetOwnerView("VIEW_CALC","BORDA")

Return oView

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

/*/{Protheus.doc} ConsuF5
Consulta Estoque
@type Static Function
@author Totvs Vitoria
@since 08/08/2019
@version version
/*/
Static Function ConsuF5(oViewPai,oModelPai)

	Local oMdlActive := FwModelActive()
	Local oView  	 := FWLoadView("GROA038A")
	Local oModel 	 := FWLoadModel("GROA038A")
	Local oModelMP   := oModel:GetModel("MPDETAIL")
	Local oModelZH7  := oViewPai:GetModel("ZH7MASTER")
	Local cTipEng 	 := oModelZH7:GetValue("ZH7_PROCES")
	Local aButtons 	 := {}
	Local bCommit	 := { || RecSub(oViewPai,oMdlActive,oModel), .t. }

	ZG7->(DbsetOrder(1))
	ZG7->(DbGoTop(1))

	aButtons := { {.F.,NIL},{.F.,NIL},{.F.,NIL},{.F.,NIL},{.F.,NIL}	,;
		{.F.,NIL},{.t.,"OK"},{.T.,"Fechar"},{.F.,NIL}		,;
		{.F.,NIL},{.F.,NIL},{.F.,NIL},{.F.,NIL},{.F.,NIL} }

	oModel:SetOperation(MODEL_OPERATION_UPDATE)
	oModel:GetModel( 'ZG7DETAIL' ):SetLoadFilter( { { 'ZG7_TIPO', "'" + cTipEng + "'", MVC_LOADFILTER_EQUAL } } )
	oModel:bCommit := bCommit
	oModel:Activate()

	oView:SetModel(oModel)
	oView:SetOperation(MODEL_OPERATION_UPDATE)
	oView:SetProgressBar(.t.)

	oExecView := FWViewExec():New()
	oExecView:SetButtons(aButtons)
	oExecView:SetTitle("Consulta Engenharia")
	oExecView:SetView(oView)
	//oExecView:setReduction(052)
	oExecView:SetModal(.F.)
	oExecView:OpenView(.F.)

	oModel:DeActivate()
	oModel:Destroy()

	// Tratativa para manter o model da chamada anterior sempre ativo
	If oMdlActive <> NIL
		FwModelActive(oMdlActive)
	EndIf

Return

/*/{Protheus.doc} RecSub
Função executada no commit.
@type Static Function
@author Totvs Vitoria
@since 08/08/2019
@version version
/*/
Static Function RecSub(oViewPai,oMdlActive,oModel)

	Local oModelZGA := oModel:GetModel("ZGADETAIL")
	Local oModelMP  := oModel:GetModel("MPDETAIL")
	Local oModelZG7 := oModel:GetModel("ZG7DETAIL")
	Local nLinZG7   := oModelZG7:Length()
	Local aLinZGA   := {}
	Local aLinMPC   := {}
	Local i := 0
	Local y := 0
	Local w := 0
	// Pecorre todas as engenharias
	For w:= 1 to nLinZG7

		oModelZG7:GoLine(w)

		// Busca quais foram as materias-primas que receberam modificações
		aLinMPC := oModelMP:GetLinesChanged()

		// Pecorre todas as materias primas
		For y:= 1 to len(aLinMPC)

			oModelMP:GoLine(aLinMPC[y])

			// Verifica se a materia prima foi utilizada, existe uma tratativa
			// dentro do modelo de dados no fonte GROA038A - Lengenda.
			If Alltrim(oModelMP:GetValue("B8_YLEGE")) == "BR_VERDE"
				Loop
			End If

			//Adiciona uma linha quando a linha posicionada estiver em branca
			If y != len(aLinMPC) .OR. !Empty(oMdlActive:GetModel("ZH8DETAIL"):GetValue("ZH8_ENGENH"))
				oMdlActive:GetModel("ZH8DETAIL"):AddLine()
			End if

			// Alimenta as informações da materia-prima com os dados da consulta
			oMdlActive:SetValue('ZH8DETAIL', 'ZH8_ENGENH'     , oModelMP:GetValue("ZG9_ROTEIR"))
			oMdlActive:SetValue('ZH8DETAIL', 'ZH8_CODMAT'     , oModelMP:GetValue("B8_PRODUTO"))
			oMdlActive:SetValue('ZH8DETAIL', 'ZH8_LOTECT'     , oModelMP:GetValue("B8_LOTECTL"))
			oMdlActive:SetValue('ZH8DETAIL', 'ZH8_NUMLOT'     , oModelMP:GetValue("B8_NUMLOTE"))
			oMdlActive:SetValue('ZH8DETAIL', 'ZH8_UM'     	  , oModelMP:GetValue("B1_UM"))
			oMdlActive:SetValue('ZH8DETAIL', 'ZH8_COMLIQ'     , oModelMP:GetValue("B8_YCOMLIQ"))
			oMdlActive:SetValue('ZH8DETAIL', 'ZH8_ALTLIQ'     , oModelMP:GetValue("B8_YALTLIQ"))
			oMdlActive:SetValue('ZH8DETAIL', 'ZH8_ESPLIQ'     , oModelMP:GetValue("B8_YESPLIQ"))

			oMdlActive:SetValue('ZH8DETAIL', 'ZH8_COMORI'     , oModelMP:GetValue("B8_YCOMLIQ"))
			oMdlActive:SetValue('ZH8DETAIL', 'ZH8_ALTORI'     , oModelMP:GetValue("B8_YALTLIQ"))
			oMdlActive:SetValue('ZH8DETAIL', 'ZH8_ESPORI'     , oModelMP:GetValue("B8_YESPLIQ"))
			oMdlActive:SetValue('ZH8DETAIL', 'ZH8_TOTORI'     , oModelMP:GetValue("B8_YTOTLIQ"))

			// Para esta materia-prima posicionada, busque quais são os produtos
			// acabados que receberam modificações
			aLinZGA := oModelZGA:GetLinesChanged()

			For i:= 1 to len(aLinZGA)

				oModelZGA:GoLine(aLinZGA[i])

				// Verifica os produtos acabados de foram de fato utilizados
				if oModelZGA:GetValue("TOTGERAL") > 0

					//Adiciona uma linha quando a linha posicionada estiver em branca
					If i != len(aLinZGA) .OR. !Empty(oMdlActive:GetModel("ZH9DETAIL"):GetValue("ZH9_CODPA"))
						oMdlActive:GetModel("ZH9DETAIL"):AddLine()
					EndIf

					// Preenche as informações do produto acabado com os dados da consulta.
					oMdlActive:SetValue('ZH9DETAIL', 'ZH9_CODPA' , oModelZGA:GetValue("B1_COD"))
					oMdlActive:SetValue('ZH9DETAIL', 'ZH9_UM'    , oModelZGA:GetValue("ZGA_UM"))
					oMdlActive:SetValue('ZH9DETAIL', 'ZH9_QUANTI', oModelZGA:GetValue("ZGA_QTDE"))
					oMdlActive:SetValue('ZH9DETAIL', 'ZH9_COMLIQ', oModelZGA:GetValue("B5_COMPR"))
					oMdlActive:SetValue('ZH9DETAIL', 'ZH9_ALTLIQ', oModelZGA:GetValue("B5_ALTURA"))
					oMdlActive:SetValue('ZH9DETAIL', 'ZH9_ESPLIQ', oModelZGA:GetValue("B5_ESPESS"))
					oMdlActive:SetValue('ZH9DETAIL', 'ZH9_SEGUM' , Posicione("SB1", 1, xFilial("SB1") + oModelZGA:GetValue("B1_COD")))

				End If
			Next

		Next
	Next

	// Atualiza as informações na tela
	oViewPai:Refresh()

Return

/*/{Protheus.doc} GRA038F1
Retorna apenas engenharias vinculadas à MP.
@type User Function
@author Totvs Vitoria
@since 08/08/2019
@version version
/*/
User Function GRA038F1()

	Local oModel     := FWModelActive()
	Local oView      := FWViewActive()
	Local cProcesso  := oModel:GetValue('ZH7MASTER','ZH7_PROCES')
	Local cProduto   := oModel:GetValue('ZH8DETAIL','ZH8_CODMAT')
	Local cSql       := ""
	Local qQuery     := ""
	Local lReturn    := .F.
	Local cExpZG7    := ""

	cSql := "   SELECT ZG9.ZG9_ROTEIR "
	cSql += "     FROM " + RetSqlName("ZG9") + " ZG9 "
	cSql += "    WHERE ZG9.ZG9_FILIAL = '" + xFilial("ZG9") + "' "
	cSql += "      AND ZG9.ZG9_PRODUT = '" + cProduto  + "' "
	cSql += "      AND ZG9.D_E_L_E_T_ = ' ' "
	cSql += " GROUP BY ZG9.ZG9_ROTEIR "

	TCQUERY cSql NEW ALIAS qQuery

	cExpZG7  := "ZG7_ATIVO == 'S' .AND. ZG7_TIPO == '" + cProcesso + "' .AND. ZG7_CODIGO $ '"

	While qQuery->(!Eof())

		cExpZG7 += qQuery->ZG9_ROTEIR + "-"

		qQuery->(DbSkip())

	EndDo

	cExpZG7 += "'"

	qQuery->(DbCloseArea())

	lReturn := U_GROCGEN("ZG7", cExpZG7, "Engenharias de Produção - [Matéria-Prima: " + AllTrim(cProduto) + "]")[1]

Return lReturn


/*/{Protheus.doc} GRA038F2
Retorna apenas produtos acabados vinculadas à Engenharia.
Ajuste na função para ela ser utilizada em outras rotinas. 
1) pode passar a engenharia e a materia prima, sem precisar passar os outros dados : cDetail,cCampEng,cCampMap
2) pode passar somente a engenharia (cEngenhar) e passar a materia prima em branco (cMatPrima)
3) pode passar domente os 3 parametros deixando engenharia e materia prima null.
@type User Function
@author Totvs Vitoria
@since 08/08/2019
@version version
/*/
User Function GRA038F2(cEngenhar,cMatPrima,cDetail,cCampEng,cCampMap)

	Local oModel    := FWModelActive()
	Local cSql      := ""
	Local qQuery    := ""
	Local lReturn   := .T.
	Local cExpSB1   := ""
	Local cExpSql   := ""
	Local aReturn   := {}
	Local lReturn   := .F.

	DEFAULT cDetail := 'ZH8DETAIL'
	DEFAULT cCampEng := 'ZH8_ENGENH'
	DEFAULT cCampMap := 'ZH8_CODMAT'

	DEFAULT cMatPrima := oModel:GetValue(cDetail,cCampMap)
	DEFAULT cEngenhar := oModel:GetValue(cDetail,cCampEng)

	cSql := " SELECT DISTINCT B1_COD , B1_DESC , B1_TIPO , B1_UM , B1_GRUPO "
	cSql += " 	FROM " + RetSqlName("SB1") + " SB1 "
	cSql += " 	INNER JOIN " + RetSqlName("ZGA") + " ZGA "
	cSql += " 		ON ZGA.ZGA_PRODUT = SB1.B1_COD  "
	cSql += " 		AND ZGA.D_E_L_E_T_= ' ' "
	cSql += " WHERE SB1.B1_FILIAL 	  = '" + xFilial("SB1") + "' "
	cSql += " 		AND SB1.D_E_L_E_T_ = ' '   "
	cSql += " 		AND SB1.B1_MSBLQL <> '1'  "
	cSql += "   	AND ZGA.ZGA_FILIAL = '" + xFilial("ZGA") + "' "
	cSql += " 		AND ZGA.ZGA_ROTEIR = '" + cEngenhar + "' "

	IF !EMPTY(cMatPrima)
		cSql += " 		AND ZGA.ZGA_PRODMP = '" + cMatPrima + "' "
	EndIF

	If isBlind()
		Return .T.
	Else
		aReturn := U_GROCGEN("SB1", cExpSB1, "Produtos Acabados - [Engenharia: " + AllTrim(cEngenhar) + "]", cSql, {"B1_COD"})[2]
	EndIf

	If Len(aReturn) > 0
		SB1->(DbSetOrder(1))
		If SB1->(DbSeek( xFilial("SB1") + aReturn[1][2] ))
			lReturn := .T.
		Else
			lReturn := .F.
		EndIf
	Else
		lReturn := .F.
	EndIf

Return lReturn

/*/{Protheus.doc} GRA038F3
Retorna apenas estoque de produtos conforme o processo selecionado.
Nome do F3 no campo: GRZH8B
@type User Function
@author Totvs Vitoria
@since 08/08/2019
@version version
/*/
User Function GRA038F3()

	Local oModel    := FWModelActive()
	Local cProcesso := oModel:GetValue('ZH7MASTER','ZH7_PROCES')
	Local cTipo     := ""
	Local lReturn   := .T.
	Local cExpSB8   := ""
	Local cExpSql   := ""
	Local aReturn   := {}
	Local cGrupoRet   := AllTrim(GetNewPar("GR_GRUPORE", ""))
	Local aRetTppr    := strtokarr(GETNEWPAR("GR_TPPRODU", "E='P';S='B';R='C','A';O='B','C'"), ";")
	Local nPosiTp     := 0

	If cProcesso $ "E"
		nPosiTp := Ascan(aRetTppr, {|x| substr(x,1,1) == "O"})
		cTipo   := substr(aRetTppr[nPosiTp],3)
	ElseIf cProcesso $ "S"
		nPosiTp := Ascan(aRetTppr, {|x| substr(x,1,1) == "S"})
		cTipo   := substr(aRetTppr[nPosiTp],3)
	ElseIf cProcesso $ "R"
		nPosiTp := Ascan(aRetTppr, {|x| substr(x,1,1) == "R"})
		cTipo   := substr(aRetTppr[nPosiTp],3)
	Else
		//Para Else eu coloque a letra O no parametro.
		nPosiTp := Ascan(aRetTppr, {|x| substr(x,1,1) == "O"})
		cTipo   := substr(aRetTppr[nPosiTp],3)
	EndIf

	cExpSql := "     SELECT SB8.B8_FILIAL,  "
	cExpSql += "            SB8.B8_LOCAL,   "
	cExpSql += "            SB8.B8_PRODUTO, "
	cExpSql += "            SB1.B1_DESC,    "
	cExpSql += "            SB8.B8_LOTECTL, "
	cExpSql += "            SB8.B8_NUMLOTE, "
	cExpSql += "            SB8.B8_SALDO,   "
	cExpSql += "            SB8.B8_DTVALID, "
	cExpSql += "            SB8.B8_YCLASSI, "
	cExpSql += "            SB8.B8_YCOMLIQ, "
	cExpSql += "            SB8.B8_YALTLIQ, "
	cExpSql += "            SB8.B8_YESPLIQ, "
	cExpSql += "            SB8.B8_YTOTLIQ  "
	cExpSql += "       FROM " + RetSqlName("SB8") + " SB8 (NOLOCK) "
	cExpSql += " INNER JOIN " + RetSqlName("SB1") + " SB1 (NOLOCK) "
	cExpSql += "         ON SB1.B1_FILIAL  = '" + xFilial("SB1") + "' "
	cExpSql += "        AND SB1.B1_COD     = SB8.B8_PRODUTO "
	cExpSql += "        AND SB1.B1_GRUPO	<> '" + cGrupoRet + "'"
	cExpSql += "        AND SB1.D_E_L_E_T_ = ' ' "
	cExpSql += " INNER JOIN " + RetSqlName("SBM") + " SBM (NOLOCK) "
	cExpSql += "         ON SBM.BM_FILIAL  = '" + xFilial("SBM") + "' "
	cExpSql += "        AND SBM.BM_GRUPO   = SB1.B1_GRUPO "
	cExpSql += "        AND SBM.BM_YTIPO  IN (" + cTipo + ") "
	cExpSql += "        AND SBM.D_E_L_E_T_ = ' ' "
	cExpSql += "      WHERE SB8.B8_FILIAL  = '" + xFilial("SB8") + "' "
	cExpSql += "        AND SB8.B8_SALDO   > 0  "
	cExpSql += "        AND SB8.B8_EMPENHO = 0  "
	cExpSql += "        AND SB8.D_E_L_E_T_ = ' ' "
	cExpSql += "   ORDER BY SB8.B8_FILIAL,  "
	cExpSql += "            SB8.B8_LOCAL,   "
	cExpSql += "            SB8.B8_PRODUTO, "
	cExpSql += "            SB8.B8_LOTECTL, "
	cExpSql += "            SB8.B8_NUMLOTE  "

	__aEngen := {}

	cSGBD := TCGetDB()

	//Somente para oracle para remover o nolock
	if (cSGBD $ "ORACLE")
		cExpSql := ChangeQuery(cExpSql)
	EndIf

	aReturn := U_GROCGEN("SB8", cExpSB8, "Estoque de Materiais - GRA038F3", cExpSql, {"B8_FILIAL","B8_PRODUTO","B8_LOCAL","B8_LOTECTL","B8_NUMLOTE"})[2]

	If Len(aReturn) > 0
		SB8->(DbSetOrder(3))
		If SB8->(DbSeek( aReturn[1][2] + aReturn[2][2] + aReturn[3][2] + aReturn[4][2] + aReturn[5][2] ))
			lReturn := .T.
		Else
			lReturn := .F.
		EndIf
	Else
		lReturn := .F.
	EndIf

Return lReturn


/*/{Protheus.doc} GRA038F4
Retorna apenas produtos do tipo pedreira.
@type User Function
@author Totvs Vitoria
@since 08/08/2019
@version version
/*/
User Function GRA038F4(cGrupo)

	Local lRet      := .F.

	SBM->(DbSetOrder(1))

	If SBM->(DbSeek(xFilial("SBM") + cGrupo))
		If SBM->BM_YTIPO == "P"
			lRet := .T.
		EndIf
	EndIf

Return lRet

/*/{Protheus.doc} GRA038F5
Retorna apenas recursos do tipo de engenharia.
@type User Function
@author Totvs Vitoria
@since 08/08/2019
@version version
/*/
User Function GRA038F5(cGrupo)

	Local oModel    := FWModelActive()
	Local oModelZH8 := Nil
	Local cProcesso := ""
	Local cSql      := ""
	Local qQUERY    := ""
	Local lRet      := .F.
	Local aAreaSH1  := SH1->(GetArea())
	Local nX        := 0
	Local cEngenha  := ""
	Local cEngAuxi  := ""

	iF oModel != NIL
		cProcesso := oModel:Getvalue('ZH7MASTER','ZH7_PROCES')
	ENDIF

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

		//O sistema so traz os processos que estão adicionados na engenharia que foi adicionado na op.
		//com base nesses processos ele verifica o recurso e apresenta em tela.
		//Para o recurso aparecer ele precisa estar cadastrado na engenharia, com o mesmo processo que esta informando na tela.
		cSql := "     SELECT COUNT(*) AS CONTADOR "
		cSql += "       FROM " + RetSqlName("ZG7") + " ZG7 "
		cSql += " INNER JOIN " + RetSqlName("ZG8") + " ZG8 "
		cSql += "         ON ZG8.ZG8_FILIAL = '" + xFilial("ZG8") + "' "
		cSql += "        AND ZG8.ZG8_ROTEIR = ZG7_CODIGO "
		cSql += "        AND ZG8.D_E_L_E_T_ = ' ' "
		cSql += " INNER JOIN " + RetSqlName("ZGC") + " ZGC "
		cSql += "         ON ZGC.ZGC_FILIAL = '" + xFilial("ZGC") + "' "
		cSql += "        AND ZGC.ZGC_ROTEIR = ZG8_ROTEIR "
		cSql += "        AND ZGC.ZGC_SEQUEN = ZG8_SEQUEN "
		cSql += "        AND ZGC.ZGC_SEQUEN = ZG8_SEQUEN "
		cSql += "        AND (ZGC.ZGC_RECURS = '" + cGrupo + "' OR ZGC.ZGC_EQUIPA = '" + SH1->H1_CODIGO + "' )"
		cSql += "        AND ZGC.D_E_L_E_T_ = ' ' "
		cSql += "      WHERE ZG7.ZG7_FILIAL = '" + xFilial("ZG7") + "' "
		cSql += "        AND ZG7.ZG7_TIPO   = '" + cProcesso + "' "
		cSql += "        AND ZG7.D_E_L_E_T_ = ' ' "

		//Pega os recursos com base nas engenharias informadas.
		if(funname() == 'GROA045')

			if inclui
				if !empty(cEngenha)
					cSql += "        AND ZG7_CODIGO IN( "
					cSql += "   		" + cEngenha
					cSql += "        ) "
				EndIf
			Else
				cSql += "        AND ZG8.ZG8_OPERAC   = '" + FWFldGet("ZGH_OPERAC") + "' "
				cSql += "        AND ZG7_CODIGO IN( "
				cSql += "       select ZH8_ENGENH "
				cSql += "            FROM " + RetSqlName("ZH8") + " ZH8 "
				cSql += "        WHERE ZH8_NUM= '" + ZH7->ZH7_NUM + "' "
				cSql += "            AND D_E_L_E_T_ = ' ' "
				cSql += "        ) "
			EndIf
		EndIF

		If ExistBlock("GRSQL504")
			cSql := ExecBlock("GRSQL504", .F., .F., {cGrupo,cProcesso,cSql})
		EndIf

		TCQUERY cSql NEW ALIAS qQUERY

		lRet := If(qQUERY->CONTADOR > 0, .T., .F.)

		qQUERY->(DbCloseArea())

	ENDIF


	RestArea(aAreaSH1)

Return lRet

/*/{Protheus.doc} GRA038F6
Retorna para os produtos como pedreira
@type User Function
@author Totvs Vitoria
@since 08/08/2019
@version version
/*/
User Function GRA038F6()

	Local oModel    := FWModelActive()
	Local cProcesso := oModel:GetValue('ZH7MASTER','ZH7_PROCES')
	Local cTipo     := ""
	Local lReturn   := .T.
	Local cExpSB1   := ""
	Local cExpSql   := ""
	Local aReturn   := {}


	cExpSql := " SELECT B1_COD,
	cExpSql += " 		B1_DESC
	cExpSql += "     FROM " + RetSqlName("SB1") + " SB1 (NOLOCK) "
	cExpSql += "     INNER JOIN " + RetSqlName("SBM") + " SBM ON SBM.BM_FILIAL='"+ xFilial("SBM") + "'"
	cExpSql += "     	AND BM_YTIPO='P'  "
	cExpSql += "     	AND SBM.BM_GRUPO = SB1.B1_GRUPO "
	cExpSql += "     	AND SBM.D_E_L_E_T_ = ' ' "
	cExpSql += "     WHERE SB1.D_E_L_E_T_ = ' '  "
	cExpSql += "     	AND B1_MSBLQL <> '1'  "
	cExpSql += "     	AND SB1.B1_FILIAL='" + xFilial("SB1") +"'"

	cSGBD := TCGetDB()

	//Somente para oracle para remover o nolock
	if (cSGBD $ "ORACLE")
		cExpSql := ChangeQuery(cExpSql)
	EndIf

	__aEngen := {}

	aReturn := U_GROCGEN("SB1", cExpSB1, "Pedreira", cExpSql, {"B1_COD"})[2]

	If Len(aReturn) > 0
		SB1->(DbSetOrder(1))
		If SB1->(DbSeek( xFilial("SB1") + aReturn[1][2] ))
			lReturn := .T.
		Else
			lReturn := .F.
		EndIf
	Else
		lReturn := .F.
	EndIf

Return lReturn

/*/{Protheus.doc} GRA038V1
Validação do campo Matéria-Prima.
Carrega engenharia.
@type User Function
@author Totvs Vitoria
@since 08/08/2019
@version version
/*/
User Function GRA038V1()

	Local oModel    := FWModelActive()
	Local cProduto  := oModel:GetValue('ZH8DETAIL','ZH8_CODMAT')
	Local cTipoOp   := oModel:GetValue('ZH7MASTER','ZH7_TIPOOP')
	Local lRet      := .T.
	Local nQtdeEng  := 0
	Local cEngenha  := ""
	Local cSql      := ""
	Local qQUERY    := ""

	//-------------------------------------------------------------
	// Tratamento necessário para não apresentar errolog caso
	// não tenha havido alteração no cabeçalho.
	//-------------------------------------------------------------
	oModel:LoadValue("ZH7MASTER", "ZH7_TIPOOP", " ")
	oModel:LoadValue("ZH7MASTER", "ZH7_TIPOOP", cTipoOp)

	//-------------------------------------------------------------
	// Caso seja preenchimento automático não entra na rotina.
	//-------------------------------------------------------------
	If __lAuto
		oModel:SetValue('ZH8DETAIL', 'ZH8_UM',     Posicione("SB1", 1, xFilial("SB1") + cProduto, "B1_UM"))

		If oModel:GetValue('ZH7MASTER','ZH7_PROCES') <> 'E'
			oModel:SetValue('ZH8DETAIL', 'ZH8_LOTECT', SB8->B8_LOTECTL)
			oModel:SetValue('ZH8DETAIL', 'ZH8_NUMLOT', SB8->B8_NUMLOTE)
			oModel:SetValue('ZH8DETAIL', 'ZH8_LOCAL',  SB8->B8_LOCAL)
			oModel:SetValue('ZH8DETAIL', 'ZH8_COMLIQ', SB8->B8_YCOMLIQ)
			oModel:SetValue('ZH8DETAIL', 'ZH8_ALTLIQ', SB8->B8_YALTLIQ)
			oModel:SetValue('ZH8DETAIL', 'ZH8_ESPLIQ', SB8->B8_YESPLIQ)
			oModel:SetValue('ZH8DETAIL', 'ZH8_COMBRU', SB8->B8_YCOMBRU)
			oModel:SetValue('ZH8DETAIL', 'ZH8_ALTBRU', SB8->B8_YALTBRU)
			oModel:SetValue('ZH8DETAIL', 'ZH8_ESPBRU', SB8->B8_YESPBRU)

			oModel:SetValue('ZH8DETAIL', 'ZH8_TOTLIQ', SB8->B8_YTOTLIQ)
			oModel:SetValue('ZH8DETAIL', 'ZH8_TOTBRU', SB8->B8_YTOTBRU)

			oModel:SetValue('ZH8DETAIL', 'ZH8_COMORI', SB8->B8_YCOMLIQ)
			oModel:SetValue('ZH8DETAIL', 'ZH8_ALTORI', SB8->B8_YALTLIQ)
			oModel:SetValue('ZH8DETAIL', 'ZH8_ESPORI', SB8->B8_YESPLIQ)
			oModel:SetValue('ZH8DETAIL', 'ZH8_TOTORI', SB8->B8_YTOTLIQ)
		EndIf

		__lAuto := .F.

		Return lRet
	EndIf

	//-------------------------------------------------------------
	// Consulta quantas engenharias existem para a MP selecionada.
	//-------------------------------------------------------------
	cSql := "     SELECT ZG7_CODIGO "
	cSql += "       FROM " + RetSqlName("ZG7") + " ZG7 "
	cSql += " INNER JOIN " + RetSqlName("ZG9") + " ZG9 "
	cSql += "         ON ZG9.ZG9_FILIAL = '" + xFilial("ZG9") + "' "
	cSql += "        AND ZG9.ZG9_ROTEIR = ZG7.ZG7_CODIGO "
	cSql += "        AND ZG9.ZG9_PRODUT = '" + cProduto + "' "
	cSql += "        AND ZG9.D_E_L_E_T_ = ' ' "
	cSql += "      WHERE ZG7.ZG7_FILIAL = '" + xFilial("ZG7") + "' "
	cSql += "        AND ZG7.ZG7_TIPO   = '" + oModel:GetValue('ZH7MASTER','ZH7_PROCES') + "' "
	cSql += "        AND ZG7.ZG7_ATIVO  = 'S' "
	cSql += "        AND ZG7.D_E_L_E_T_ = ' ' "
	TCQUERY cSql NEW ALIAS qQUERY
	While qQUERY->(!Eof())
		nQtdeEng++
		cEngenha := qQUERY->ZG7_CODIGO
		qQUERY->(DbSkip())
	EndDo
	qQUERY->(DbCloseArea())

	If nQtdeEng == 0

		lRet := .F.

		oModel:SetValue('ZH8DETAIL', 'ZH8_LOTECT', "")
		oModel:SetValue('ZH8DETAIL', 'ZH8_NUMLOT', "")
		oModel:SetValue('ZH8DETAIL', 'ZH8_LOCAL',  "")
		oModel:SetValue('ZH8DETAIL', 'ZH8_COMLIQ', 0)
		oModel:SetValue('ZH8DETAIL', 'ZH8_ALTLIQ', 0)
		oModel:SetValue('ZH8DETAIL', 'ZH8_ESPLIQ', 0)
		oModel:SetValue('ZH8DETAIL', 'ZH8_COMBRU', 0)
		oModel:SetValue('ZH8DETAIL', 'ZH8_ALTBRU', 0)
		oModel:SetValue('ZH8DETAIL', 'ZH8_ESPBRU', 0)
		oModel:SetValue('ZH8DETAIL', 'ZH8_TOTLIQ', 0)
		oModel:SetValue('ZH8DETAIL', 'ZH8_TOTBRU', 0)

		oModel:SetValue('ZH8DETAIL', 'ZH8_COMORI', 0)
		oModel:SetValue('ZH8DETAIL', 'ZH8_ALTORI', 0)
		oModel:SetValue('ZH8DETAIL', 'ZH8_ESPORI', 0)
		oModel:SetValue('ZH8DETAIL', 'ZH8_TOTORI', 0)

		If aScan(__aEngen, {|x| x == AllTrim(cProduto)}) == 0
			aAdd(__aEngen, AllTrim(cProduto))
			MsgStop("Não existe engenharia cadastrada para o produto " + AllTrim(cProduto) + "!")
		EndIf

	Else

		oModel:SetValue('ZH8DETAIL', 'ZH8_UM', Posicione("SB1", 1, xFilial("SB1") + cProduto, "B1_UM"))

		If oModel:GetValue('ZH7MASTER','ZH7_PROCES') <> 'E'
			oModel:SetValue('ZH8DETAIL', 'ZH8_LOTECT', SB8->B8_LOTECTL)
			oModel:SetValue('ZH8DETAIL', 'ZH8_NUMLOT', SB8->B8_NUMLOTE)
			oModel:SetValue('ZH8DETAIL', 'ZH8_LOCAL',  SB8->B8_LOCAL)
			oModel:SetValue('ZH8DETAIL', 'ZH8_COMLIQ', SB8->B8_YCOMLIQ)
			oModel:SetValue('ZH8DETAIL', 'ZH8_ALTLIQ', SB8->B8_YALTLIQ)
			oModel:SetValue('ZH8DETAIL', 'ZH8_ESPLIQ', SB8->B8_YESPLIQ)
			oModel:SetValue('ZH8DETAIL', 'ZH8_COMBRU', SB8->B8_YCOMBRU)
			oModel:SetValue('ZH8DETAIL', 'ZH8_ALTBRU', SB8->B8_YALTBRU)
			oModel:SetValue('ZH8DETAIL', 'ZH8_ESPBRU', SB8->B8_YESPBRU)
			oModel:SetValue('ZH8DETAIL', 'ZH8_TOTLIQ', SB8->B8_YTOTLIQ)
			oModel:SetValue('ZH8DETAIL', 'ZH8_TOTBRU', SB8->B8_YTOTBRU)

			oModel:SetValue('ZH8DETAIL', 'ZH8_COMORI', SB8->B8_YCOMLIQ)
			oModel:SetValue('ZH8DETAIL', 'ZH8_ALTORI', SB8->B8_YALTLIQ)
			oModel:SetValue('ZH8DETAIL', 'ZH8_ESPORI', SB8->B8_YESPLIQ)
			oModel:SetValue('ZH8DETAIL', 'ZH8_TOTORI', SB8->B8_YTOTLIQ)
		EndIf

		If nQtdeEng == 1
			oModel:SetValue('ZH8DETAIL', 'ZH8_ENGENH', cEngenha)
		ElseIf nQtdeEng > 1
			If ConPad1(,,, 'GRZH8A')
				oModel:SetValue('ZH8DETAIL', 'ZH8_ENGENH', ZG7->ZG7_CODIGO)
			EndIf

		EndIf

	EndIf

Return lRet

/*/{Protheus.doc} GRA038V2
Validação do campo Engenharia.
Carrega produto acabado.
@type User Function
@author Totvs Vitoria
@since 08/08/2019
@version version
/*/
User Function GRA038V2()

	Local oModel    := FWModelActive()
	Local oView     := FWViewActive()
	Local cProcesso := AllTrim(oModel:GetValue('ZH7MASTER','ZH7_PROCES'))
	Local cProdMap  := oModel:GetValue('ZH8DETAIL','ZH8_CODMAT')
	Local cEngenha  := oModel:GetValue('ZH8DETAIL','ZH8_ENGENH')
	Local oModelZH9 := oModel:GetModel("ZH9DETAIL")
	Local lRet      := .T.
	Local nQtdeAca  := 0
	Local cProdAca  := ""
	Local cSql      := ""
	Local qQUERY    := ""
	Local nX        := 0
	Local lJaExiste := .F.

	//-------------------------------------------------------------
	// Caso seja preenchimento automático não entra na rotina.
	//-------------------------------------------------------------
	If __lAuto
		__lAuto := .F.
		Return lRet
	EndIf

	//-------------------------------------------------------------
	// Consulta quantos produtos acabados existem para a MP
	// e engenharia selecionada.
	//-------------------------------------------------------------
	cSql := "     SELECT ZGA_PRODUT "
	cSql += "       FROM " + RetSqlName("ZGA") + " ZGA "
	cSql += "      WHERE ZGA.ZGA_FILIAL = '" + xFilial("ZGA") + "' "
	cSql += "        AND ZGA.ZGA_ROTEIR = '" + cEngenha + "' "
	cSql += "        AND ZGA.ZGA_PRODMP = '" + cProdMap + "' "
	cSql += "        AND ZGA.D_E_L_E_T_ = ' ' "
	TCQUERY cSql NEW ALIAS qQUERY
	While qQUERY->(!Eof())
		nQtdeAca++
		cProdAca := qQUERY->ZGA_PRODUT
		qQUERY->(DbSkip())
	EndDo
	qQUERY->(DbCloseArea())

	If nQtdeAca == 0
		lRet := .F.
		MsgStop("Não existe produto acabado cadastrado na engenharia " + AllTrim(cEngenha) + "!")
	ElseIf nQtdeAca == 1
		If cProcesso == "R"
			If !oModelZH9:isEmpty()
				For nX := 1 to oModelZH9:Length()
					oModelZH9:GoLine(nX)
					If oModelZH9:IsDeleted()
						Loop
					EndIf
					If oModelZH9:GetValue('ZH9_CODPA') == cProdAca
						lJaExiste := .T.
					EndIf
				Next

				If !lJaExiste
					oModelZH9:AddLine()
				EndIf
			EndIf
		EndIf
		oModelZH9:SetValue('ZH9_CODPA', cProdAca)
		If oModelZH9:GetValue('ZH9_TOTLIQ') == 0
			oModelZH9:SetValue('ZH9_TOTLIQ', 1)
		EndIf
		oModelZH9:GoLine(1)

		//Erro ao criar a op utilizando o modelo
		IF !(__lAutoOp)
			oView:Refresh("VIEW_ZH9")
			oView:Refresh("ZH9DETAIL")
		EndIf

	Else
		If ConPad1(,,, 'GRZH9B')
			If cProcesso == "R"
				If !oModelZH9:isEmpty()
					For nX := 1 to oModelZH9:Length()
						oModelZH9:GoLine(nX)
						If oModelZH9:IsDeleted()
							Loop
						EndIf
						If oModelZH9:GetValue('ZH9_CODPA') == cProdAca
							lJaExiste := .T.
						EndIf
					Next

					If !lJaExiste
						oModelZH9:AddLine()
					EndIf
				EndIf
			EndIf
			oModelZH9:SetValue('ZH9_CODPA', SB1->B1_COD)
			If oModelZH9:GetValue('ZH9_TOTLIQ') == 0
				oModelZH9:SetValue('ZH9_TOTLIQ', 1)
			EndIf
			oModelZH9:GoLine(1)
			//Erro ao criar a op utilizando o modelo
			IF !(__lAutoOp)
				oView:Refresh("VIEW_ZH9")
				oView:Refresh("ZH9DETAIL")
			EndIF
		EndIf
	EndIf

	If ExistBlock("GR38V2P")
		ExecBlock("GR38V2P", .F., .F., {oModel})
	EndIf

Return lRet

/*/{Protheus.doc} GRA038V3
Validação do campo produto acabado.
@type User Function
@author Totvs Vitoria
@since 08/08/2019
@version version
/*/
User Function GRA038V3()

	Local lRet      := .T.
	Local oModel    := FWModelActive()
	Local cProcesso := AllTrim(oModel:GetValue('ZH7MASTER','ZH7_PROCES'))
	Local aSufixo   := {"A","B","C","D","E","F","G","H","I","J","K","L"}
	Local nPosicao  := 0
	Local nX        := 1
	Local oModelZH9 := oModel:GetModel("ZH9DETAIL")
	Local nComLiq   := oModel:GetValue('ZH8DETAIL', 'ZH8_COMLIQ')
	Local nAltLiq   := oModel:GetValue('ZH8DETAIL', 'ZH8_ALTLIQ')
	Local nEspLiq   := oModel:GetValue('ZH8DETAIL', 'ZH8_ESPLIQ')
	Local nTotLiq   := oModel:GetValue('ZH8DETAIL', 'ZH8_TOTLIQ')
	Local nComBru   := oModel:GetValue('ZH8DETAIL', 'ZH8_COMBRU')
	Local nAltBru   := oModel:GetValue('ZH8DETAIL', 'ZH8_ALTBRU')
	Local nEspBru   := oModel:GetValue('ZH8DETAIL', 'ZH8_ESPBRU')
	Local nTotBru   := oModel:GetValue('ZH8DETAIL', 'ZH8_TOTBRU')
	Local cLoteZH8  := AllTrim(oModel:GetValue('ZH8DETAIL', 'ZH8_LOTECT'))
	Local cLoteZH9  := ""
	Local cSubLZH8  := AllTrim(oModel:GetValue('ZH8DETAIL', 'ZH8_NUMLOT'))
	Local cSubLZH9  := ""
	Local cLoteCtl  := ""
	Local cSubLCtl  := ""
	Local cTipoPro  := ""

	If cProcesso == "D"

		nPosicao := oModelZH9:GetLine()

		// cLoteZH8 := If(IsDigit(SubStr(cLoteZH8, 1, Len(cLoteZH8))), cLoteZH8, SubStr(cLoteZH8, 1, Len(cLoteZH8) - 1))

		cLoteZH8 := If(IsDigit(SubStr(cLoteZH8, Len(cLoteZH8), Len(cLoteZH8))), AllTrim(cLoteZH8), SubStr(cLoteZH8, 1, Len(cLoteZH8) - 1))
		cTipoPro := Posicione("SBM", 1, xFilial("SBM") + Posicione("SB1", 1, xFilial("SB1") + oModel:GetValue('ZH8DETAIL', 'ZH8_CODMAT'), "B1_GRUPO"), "BM_YTIPO")

		For nX := 1 to oModelZH9:Length()

			oModelZH9:GoLine(nX)

			If oModelZH9:IsDeleted() .Or. nX == nPosicao
				Loop
			EndIf

			nComLiq -= oModelZH9:GetValue("ZH9_COMLIQ")
			nAltLiq -= oModelZH9:GetValue("ZH9_ALTLIQ")
			nEspLiq -= oModelZH9:GetValue("ZH9_ESPLIQ")
			nTotLiq -= oModelZH9:GetValue("ZH9_TOTLIQ")
			nComBru -= oModelZH9:GetValue("ZH9_COMBRU")
			nAltBru -= oModelZH9:GetValue("ZH9_ALTBRU")
			nEspBru -= oModelZH9:GetValue("ZH9_ESPBRU")
			nTotBru -= oModelZH9:GetValue("ZH9_TOTBRU")

			cLoteZH9 := AllTrim(oModelZH9:GetValue("ZH9_LOTECT"))

			If cTipoPro == "B"

				// cLoteZH9 := AllTrim(oModelZH9:GetValue("ZH9_LOTECT"))
				// cLoteZH9 := If(IsDigit(SubStr(cLoteZH9, Len(cLoteZH9), Len(cLoteZH9))), cLoteZH9, SubStr(cLoteZH9, 1, Len(cLoteZH9) - 1))

				If IsDigit(SubStr(cLoteZH9, Len(cLoteZH9), Len(cLoteZH9)))
					If cLoteCtl < AllTrim(oModel:GetValue('ZH8DETAIL', 'ZH8_LOTECT')) + "A"
						cLoteCtl := AllTrim(oModel:GetValue('ZH8DETAIL', 'ZH8_LOTECT')) + "A"
					EndIf
				Else
					If cLoteCtl < SubStr(cLoteZH9, 1, Len(cLoteZH9) - 1) + aSufixo[aScan(aSufixo, {|x| x == SubStr(cLoteZH9, Len(cLoteZH9), Len(cLoteZH9))}) + 1]
						cLoteCtl := SubStr(cLoteZH9, 1, Len(cLoteZH9) - 1) + aSufixo[aScan(aSufixo, {|x| x == SubStr(cLoteZH9, Len(cLoteZH9), Len(cLoteZH9))}) + 1]
					EndIf
				EndIf

			Else

				cSubLZH9 := AllTrim(oModelZH9:GetValue("ZH9_NUMLOT"))

				If IsDigit(SubStr(cSubLZH9, Len(cSubLZH9), Len(cSubLZH9)))
					If cSubLCtl < AllTrim(oModel:GetValue('ZH8DETAIL', 'ZH8_NUMLOT')) + "A"
						cSubLCtl := AllTrim(oModel:GetValue('ZH8DETAIL', 'ZH8_NUMLOT')) + "A"
					EndIf
				Else
					If cSubLCtl < SubStr(cSubLZH9, 1, Len(cSubLZH9) - 1) + aSufixo[aScan(aSufixo, {|x| x == SubStr(cSubLZH9, Len(cSubLZH9), Len(cSubLZH9))}) + 1]
						cSubLCtl := SubStr(cSubLZH9, 1, Len(cSubLZH9) - 1) + aSufixo[aScan(aSufixo, {|x| x == SubStr(cSubLZH9, Len(cSubLZH9), Len(cSubLZH9))}) + 1]
					EndIf
				EndIf

			EndIf

		Next

		// oModelZH9:GoLine(nPosicao)

		If cTipoPro == "B"

			If Empty(cLoteCtl)
				cLoteZH8 := AllTrim(oModel:GetValue('ZH8DETAIL', 'ZH8_LOTECT'))
				If IsDigit(SubStr(cLoteZH8, Len(cLoteZH8), Len(cLoteZH8)))
					cLoteCtl := AllTrim(oModel:GetValue('ZH8DETAIL', 'ZH8_LOTECT')) + "A"
				Else
					cLoteCtl := SubStr(cLoteZH8, 1, Len(cLoteZH8) - 1) + aSufixo[aScan(aSufixo, {|x| x == SubStr(cLoteZH8, Len(cLoteZH8), Len(cLoteZH8))}) + 1]
				EndIf
			EndIf

			oModel:SetValue('ZH9DETAIL', 'ZH9_LOTECT', cLoteCtl)

		Else

			oModel:SetValue('ZH9DETAIL', 'ZH9_LOTECT', cLoteZH8)

			If Empty(cSubLCtl)
				cSubLZH8 := AllTrim(oModel:GetValue('ZH8DETAIL', 'ZH8_NUMLOT'))
				If IsDigit(SubStr(cSubLZH8, Len(cSubLZH8), Len(cSubLZH8)))
					cSubLCtl := AllTrim(oModel:GetValue('ZH8DETAIL', 'ZH8_NUMLOT')) + "A"
				Else
					cSubLCtl := SubStr(cSubLZH8, 1, Len(cSubLZH8) - 1) + aSufixo[aScan(aSufixo, {|x| x == SubStr(cSubLZH8, Len(cSubLZH8), Len(cSubLZH8))}) + 1]
				EndIf
			EndIf

			oModel:SetValue('ZH9DETAIL', 'ZH9_NUMLOT', cSubLCtl)

		EndIf

		nComLiq := If(nComLiq <= 0, oModel:GetValue('ZH8DETAIL', 'ZH8_COMLIQ'), nComLiq)
		nAltLiq := If(nAltLiq <= 0, oModel:GetValue('ZH8DETAIL', 'ZH8_ALTLIQ'), nAltLiq)
		nEspLiq := If(nEspLiq <= 0, oModel:GetValue('ZH8DETAIL', 'ZH8_ESPLIQ'), nEspLiq)
		nTotLiq := If(nTotLiq <= 0, oModel:GetValue('ZH8DETAIL', 'ZH8_TOTLIQ'), nTotLiq)
		nComBru := If(nComBru <= 0, oModel:GetValue('ZH8DETAIL', 'ZH8_COMBRU'), nComBru)
		nAltBru := If(nAltBru <= 0, oModel:GetValue('ZH8DETAIL', 'ZH8_ALTBRU'), nAltBru)
		nEspBru := If(nEspBru <= 0, oModel:GetValue('ZH8DETAIL', 'ZH8_ESPBRU'), nEspBru)
		nTotBru := If(nTotBru <= 0, oModel:GetValue('ZH8DETAIL', 'ZH8_TOTBRU'), nTotBru)

		oModel:SetValue('ZH9DETAIL', 'ZH9_COMLIQ', nComLiq)
		oModel:SetValue('ZH9DETAIL', 'ZH9_ALTLIQ', nAltLiq)
		oModel:SetValue('ZH9DETAIL', 'ZH9_ESPLIQ', nEspLiq)
		oModel:SetValue('ZH9DETAIL', 'ZH9_TOTLIQ', nTotLiq)
		oModel:SetValue('ZH9DETAIL', 'ZH9_COMBRU', nComBru)
		oModel:SetValue('ZH9DETAIL', 'ZH9_ALTBRU', nAltBru)
		oModel:SetValue('ZH9DETAIL', 'ZH9_ESPBRU', nEspBru)
		oModel:SetValue('ZH9DETAIL', 'ZH9_TOTBRU', nTotBru)

	ElseIf cProcesso <> 'R'

		oModel:SetValue('ZH9DETAIL', 'ZH9_LOTECT', oModel:GetValue('ZH8DETAIL', 'ZH8_LOTECT'))
		oModel:SetValue('ZH9DETAIL', 'ZH9_NUMLOT', oModel:GetValue('ZH8DETAIL', 'ZH8_NUMLOT'))

		oModel:SetValue('ZH9DETAIL', 'ZH9_COMLIQ', oModel:GetValue('ZH8DETAIL', 'ZH8_COMLIQ'))
		oModel:SetValue('ZH9DETAIL', 'ZH9_ALTLIQ', oModel:GetValue('ZH8DETAIL', 'ZH8_ALTLIQ'))

		oModel:SetValue('ZH9DETAIL', 'ZH9_COMBRU', oModel:GetValue('ZH8DETAIL', 'ZH8_COMBRU'))
		oModel:SetValue('ZH9DETAIL', 'ZH9_ALTBRU', oModel:GetValue('ZH8DETAIL', 'ZH8_ALTBRU'))

		If AllTrim(oModel:GetValue('ZH9DETAIL', 'ZH9_UM')) == "M3"
			oModel:SetValue('ZH9DETAIL', 'ZH9_ESPLIQ', oModel:GetValue('ZH8DETAIL', 'ZH8_ESPLIQ'))
			oModel:SetValue('ZH9DETAIL', 'ZH9_ESPBRU', oModel:GetValue('ZH8DETAIL', 'ZH8_ESPBRU'))
		EndIf

		If AllTrim(oModel:GetValue('ZH8DETAIL', 'ZH8_UM')) == AllTrim(oModel:GetValue('ZH9DETAIL', 'ZH9_UM'))
			oModel:SetValue('ZH9DETAIL', 'ZH9_TOTLIQ', oModel:GetValue('ZH8DETAIL', 'ZH8_TOTLIQ'))
			oModel:SetValue('ZH9DETAIL', 'ZH9_TOTBRU', oModel:GetValue('ZH8DETAIL', 'ZH8_TOTBRU'))
		EndIf
	Else
		// oModel:SetValue('ZH9DETAIL', 'ZH9_TOTLIQ', 0)
	EndIf

Return lRet


/*/{Protheus.doc} GRA038V4
@type User Function
@author Totvs Vitoria
@since 08/08/2019
@version version
/*/
User Function GRA038V4()

	Local lRet    := .T.

Return lRet

/*/{Protheus.doc} GRA038V4
Função para validar  o campo unidade de medida que estava endo executado antes do preenchimento da ZH9_UM
@type User Function
@author Totvs Vitoria
@since 10/01/2020
@version version
/*/
User Function GRA038V5()

	Local lRet      := .T.
	Local oModel    := FWModelActive()
	Local cProcesso := AllTrim(oModel:GetValue('ZH7MASTER','ZH7_PROCES'))

	If !(cProcesso $ 'R/D')

		If AllTrim(oModel:GetValue('ZH9DETAIL', 'ZH9_UM')) == "M3"
			oModel:SetValue('ZH9DETAIL', 'ZH9_ESPLIQ', oModel:GetValue('ZH8DETAIL', 'ZH8_ESPLIQ'))
			oModel:SetValue('ZH9DETAIL', 'ZH9_ESPBRU', oModel:GetValue('ZH8DETAIL', 'ZH8_ESPBRU'))
		EndIf

	EndIf

Return lRet



/*/{Protheus.doc} GRA038V6
Validação para alterar o valor do lote somente para bloco
@type User Function
@author Totvs Vitoria
@since 10/01/2020
@version version
/*/
User Function GRA038V6()

	Local lRet   := .T.
	Local oModel := FWModelActive()


	If AllTrim(oModel:GetValue('ZH7MASTER','ZH7_PROCES')) == 'S'

		If oModel:GetValue('ZH9DETAIL','ZH9_LOTECT') <> oModel:GetValue('ZH8DETAIL','ZH8_LOTECT')

			If oModel:GetValue('ZH9DETAIL','ZH9_CODPA') <> oModel:GetValue('ZH8DETAIL','ZH8_CODMAT')

				lRet   := .F.

			EndIf

		EndIf

	EndIf

Return lRet

/*/{Protheus.doc} GRA038V7
Validar a quantidade informada de chapas, não pode ultrapassar a medida do bloco.
@return Nil
@author Kenny Roger Martins
@since 20/08/2020
@version 1.0
/*/
User Function GRA038V7()

	Local lRet      := .T.
	Local oModel    := FWModelActive()
	Local oModelZH7 := oModel:GetModel('ZH7MASTER')
	Local oModelZH8 := oModel:GetModel('ZH8DETAIL')
	Local oModelZH9 := oModel:GetModel('ZH9DETAIL')
	Local nMedLamin := Posicione("SH1", 1, xFilial("SH1") + oModelZH7:GetValue("ZH7_RECURS"), "H1_YALTLAM")
	Local nMedBloco := oModelZH8:GetValue("ZH8_ESPLIQ")
	Local nMedChapa := 0
	Local nNumChapa := 0
	Local nX        := 0

	If AllTrim(oModelZH7:GetValue('ZH7_PROCES')) == 'S'

		If Empty(oModelZH7:GetValue("ZH7_RECURS"))

			MsgStop("Favor informr o recurso para o cálculo correto das chapas!", "Aviso Importante")

		EndIf

		For nX := 1 to oModelZH9:Length()

			If oModelZH9:IsDeleted(nX)
				Loop
			EndIf

			nMedChapa += oModelZH9:GetValue("ZH9_QUANTI", nX) * (ConvEsp(oModelZH9:GetValue("ZH9_ESPLIQ", nX)) + nMedLamin)

		Next

		If nMedChapa > nMedBloco

			MsgStop("Espessura total das Chapas é maior que a espessura do Bloco!", "Aviso Importante")

		EndIf


	EndIf

Return lRet

/*/{Protheus.doc} GRA038V8
Validar a quantidade informada de chapas, não pode ultrapassar a medida do bloco.
@return Nil
@author Kenny Roger Martins
@since 20/08/2020
@version 1.0
/*/
User Function GRA038V8()

	Local oModel     := FWModelActive()
	Local oModelZH7  := oModel:GetModel('ZH7MASTER')
	Local oModelZH8  := oModel:GetModel('ZH8DETAIL')
	Local oModelZH9  := oModel:GetModel('ZH9DETAIL')
	Local nEspessura := Posicione("SB5", 1, xFilial("SB5") + oModelZH9:GetValue("ZH9_CODPA"),  "B5_ESPESS")
	Local nMedLamin  := Posicione("SH1", 1, xFilial("SH1") + oModelZH7:GetValue("ZH7_RECURS"), "H1_YALTLAM")
	Local nMedBloco  := oModelZH8:GetValue("ZH8_ESPLIQ")
	Local nMedChapa  := 0
	Local nNumChapa  := 0
	Local nX         := 0

	If AllTrim(oModelZH7:GetValue('ZH7_PROCES')) == 'S'

		If !Empty(oModelZH7:GetValue("ZH7_RECURS"))

			For nX := 1 to oModelZH9:Length()

				If oModelZH9:IsDeleted(nX) .Or. oModelZH9:GetLine() == nX
					Loop
				EndIf

				nMedChapa += oModelZH9:GetValue("ZH9_QUANTI", nX) * (ConvEsp(oModelZH9:GetValue("ZH9_ESPLIQ", nX)) + nMedLamin)

				nMedBloco -= nMedChapa

			Next

			nNumChapa := NoRound(nMedBloco / (ConvEsp(nEspessura) + nMedLamin), 0)

		EndIf

	EndIf

Return nNumChapa

/*/{Protheus.doc} SaveModel
Na gravação do modelo atualiza os campos engenharia e número do bloco.
@type Static Function
@author Totvs Vitoria
@since 08/08/2019
@version version
/*/
Static Function SaveModel(oModel)

	Local lRet := .T.
	Local cMsgErro := "Desculpe, ocorreu um problema na gravação do registro!"

	FWMsgRun(, {|oSay| lRet := GravaExe(oSay, oModel, @cMsgErro)}, "Processando", "Processando ordem de produção...")

	If !lRet
		oModel:SetErrorMessage("",,oModel:GetId(),"","GROA038",cMsgErro)
	EndIf

Return lRet

Static Function GravaExe(oSay, oModel, cMsgErro)

	Local lReturn    := .T.
	Local nOperation := oModel:GetOperation()
	Local nOpcDet	 := oModel:GetOperation()
	Local cNumOp     := oModel:GetValue('ZH7MASTER','ZH7_NUM')
	Local cProcesso  := oModel:GetValue('ZH7MASTER','ZH7_PROCES')
	Local cItemOp    := ""
	Local cSequenOp  := ""
	Local cEngenha   := oModel:GetValue('ZH8DETAIL','ZH8_ENGENH', 1)
	Local oModelZH7  := oModel:GetModel('ZH7MASTER')
	Local oModelZH8  := oModel:GetModel('ZH8DETAIL')
	Local oModelZH9  := oModel:GetModel('ZH9DETAIL')
	Local nRegZH8    := oModelZH8:Length()
	Local nRegZH9    := oModelZH9:Length() // Esse valor aqui e com base na ZH9 que esta posicionada na tela.
	Local nX         := 0
	Local nY         := 0
	Local aLotes     := {}
	Local cLotes     := ""
	Local aArraySC2	 := {}
	Local aArraySD4  := {}
	Local oUtil      := util():new()
	Local lDelete    := .F.
	Local lHabOpPa   := GETNEWPAR("GR_HABOPPA", .F.) // Habilita aba para vincular Operação ao Produto Acabado.
	Local lDesgIns   := GETNEWPAR("GR_DESAINS", .F.) // .F. os insumos iguais são agrupados, .T. não agrupa os insumos
	Local lHabOtOp   := GETNEWPAR("GR_HABOTP",  0)   // Habilita outros tipos de op para o bloco k. 0 = somente o tipo interna. 1 = tipo interna e retrabalha(Dependendo da Engenharia de retrabalho).
	Local cHabCorte  := GETNEWPAR("GR_HABCORT", "0") // Habilita controle de corte.
	Local cNumAgru   := GETNEWPAR("GR_LOTINSD", "DUPLI000") // Numero do lote inicial para insumo duplicado. Necessario para o cliente que deseja que o sistema crie os insumos de L/s Iguais a engenharia.
	Local cLoteIns   := ""
	Local lHAltZH8   := GETNEWPAR("GR_HALTZH8", .F.) // Habilita para o sistema alterar a ZH8 quando encontrar divergencia de saldo com a SB8.https://totvsleste.freshdesk.com/a/tickets/2660
	Local cRastIns   := ""
	Local dDataOld   := dDataBase
	Local lCheckKey  := .F.
	Local nw 		 := 0
	Local cMensage   := ""
	Local qQuerySd4  := ""
	Local cRotCria   := ""
	Local nPosTer    := 0
	Local cCodTer	 := ""
	Local cLocalTer	 := ""
	Local cLoteTer	 := ""
	Local cNumLTer   := ""
	Local lContTer   := .T.
	Local aRetTer    := {}
	Local lRetSX3    := .T.
	Local lRotNova   := .T.
	Local cCondLoop  := ".F."
	Local cSiglaRet  := AllTrim(GetNewPar("GR_SIGLARE", "R"))
	Local cProdRet   := ""
	Local cGruRec    := ""
	Local cTipRec    := ""
	Local cSeqLan    := "000"
	Local lCampo22   := .F.
	Local aRet		 := {}
	Local cNumReser  := ""

	Private lGrPlus        := .T.
	Private lMsErroAuto    := .F.

	If isBlind()
		Private lMsHelpAuto    := .T.
		Private lAutoErrNoFile := .T.
	EndIf

	IF (ZH7->(FieldPos("ZH7_ROTINA"))> 0)
		cRotCria   := oModelZH7:GetValue("ZH7_ROTINA")
	EndIF

	lRotNova  :=  alltrim(cRotCria) $ "GROA060/GROA062"

	//Caso seja uma op da tela nova, e necessário apresentar a ZHL
	if lRotNova
		lHabOpPa := .T.
	ENDIF

	// https://totvsleste.freshdesk.com/a/tickets/1689
	// Tratamento para evitar numeração de OP duplicada
	If nOperation == MODEL_OPERATION_INSERT
		If ExistBlock("GR038NUM")
			cNumOp := ExecBlock("GR038NUM", .f., .f., {cNumOp,oModel,"GROA038"}  )
		Else
			SC2->(DbSetOrder(1))
			While SC2->(MsSeek(xFilial("SC2") + cNumOp))
				SC2->(ConfirmSx8())
				cNumOp := GetNumSC2()
			EndDo
		EndIf

		oModel:SetValue('ZH7MASTER', 'ZH7_NUM', cNumOp)
		oModel:SetValue('ZH8DETAIL', 'ZH8_NUM', cNumOp)
		oModel:SetValue('ZH9DETAIL', 'ZH9_NUM', cNumOp)

		lCheckKey :=  .T.

	EndIf

	//Ajuste devido cliente criar uma Op como prevista , criar outras ops e alterar as medidas e depois encerrar a op criada inicialmente
	//https://totvsleste.freshdesk.com/a/tickets/2660
	If (cProcesso $ 'B/T') .AND. nOperation == MODEL_OPERATION_UPDATE
		ZH7->(DbSetOrder(1))
		If ZH7->(DbSeek(xFilial("ZH7") + cNumOp)) .AND. ZH7->ZH7_TIPOOP == "P" // Validar se e prevista porque as outras ops estavam apresentando a mensagem tipo um B(de mesmo produto) onde o saldo fica com o retrabalho

			//validar se os dados da op
			For nX := 1 To nRegZH8

				oModelZH8:GoLine(nX)

				SB8->(DbSetOrder(3))

				If SB8->(DbSeek(xFilial("SB8") + oModelZH8:GetValue('ZH8_CODMAT') + oModelZH8:GetValue('ZH8_LOCAL') + oModelZH8:GetValue('ZH8_LOTECT') + oModelZH8:GetValue('ZH8_NUMLOT')))

					If oModelZH8:GetValue('ZH8_TOTLIQ') <>  SB8->B8_SALDO

						cMensage += "Materia prima: " + Alltrim(oModelZH8:GetValue('ZH8_CODMAT')) + " Armazem:" + alltrim(oModelZH8:GetValue('ZH8_LOCAL')) + " Lote:"+alltrim(oModelZH8:GetValue('ZH8_LOTECT')) + " SubLote:"+alltrim(oModelZH8:GetValue('ZH8_NUMLOT'))+ CHR(13) + CHR(10)
						cMensage +="Valor da materia prima:"+ CValToChar(oModelZH8:GetValue('ZH8_TOTLIQ'))+" Valor do saldo:" + CValToChar(SB8->B8_SALDO) + CHR(13) + CHR(10)+ CHR(13) + CHR(10)

						iF lHAltZH8
							oModelZH8:SetValue('ZH8_COMLIQ', SB8->B8_YCOMLIQ)
							oModelZH8:SetValue('ZH8_ALTLIQ', SB8->B8_YALTLIQ)
							oModelZH8:SetValue('ZH8_ESPLIQ', SB8->B8_YESPLIQ)
							oModelZH8:SetValue('ZH8_TOTLIQ', SB8->B8_SALDO)
							oModelZH8:SetValue('ZH8_COMBRU', SB8->B8_YCOMBRU)
							oModelZH8:SetValue('ZH8_ALTBRU', SB8->B8_YALTBRU)
							oModelZH8:SetValue('ZH8_ESPBRU', SB8->B8_YESPBRU)
							oModelZH8:SetValue('ZH8_TOTBRU', SB8->B8_YTOTBRU)
						EndIf
					EndIf
				EndIf

			NEXT

			if !Empty(cMensage) .And. !lHAltZH8 .And. isblind()
				cMsgErro := cMensage
				Return .f.
			ElseIf !Empty(cMensage)

				If lHAltZH8
					MSGSTOP(cMensage,"1)Sistema encontrou divergencia e ajustou a quantidade entre a materia prima(ZH8_TOTLIQ) e o saldo da chapas (B8_SALDO) ")
				Else
					//Se não altera automatico, e para o sistema retornar para alteração da Op
					MSGSTOP(cMensage,"2)Sistema encontrou divergencia entre a quantidade  da materia prima(ZH8_TOTLIQ) e o saldo da chapas (B8_SALDO),Favor deletar os itens e incluir novamente ")
					cMsgErro := cMensage
					Return .f.
				EndIf
			EndIF
		EndIF
	EndIf

	//Op gerada pela industrialização com lote estava apresentando a mensagem no momento de excluir.
	//https://totvsleste.freshdesk.com/a/tickets/2153
	if(INCLUI .or. ALTERA) .And. !IsBlind()
		//validando se o produto esta sem lote na ZH9 e na SB1 informando para usar lote
		If (cProcesso $ 'R')
			If(!VALIDALOTR(oModel))
				Return .f.
			EndIf
		ElseiF(cProcesso $ 'B/T/E/B')
			//validando O rastro das MA e PA
			If(!VALIDLOTE(oModel))
				Return .f.
			EndIF
		EndIf
	EndIF

	aRet := GRLIDSB8(oModel)

	If !(aRet[1])
		cMsgErro := "GRLIDSB8 " + CHR(13)+ CHR(13) + aRet[2]
		Return .f.
	EndIf

	Begin Transaction

		__aEngen := {}

		dDataBase := oModelZH7:GetValue('ZH7_EMISSA')

		//-----------------------------------------------------------
		// Exluir empenhos, transferências de retrabalho e ZGM
		// independente de alteração ou exclusão da OP.
		//-----------------------------------------------------------
		If !(type("lRoti06")=="L".and. lRoti06)
			U_DelTabZG("ZGM", cNumOp)
		EndIf

		If nOperation == MODEL_OPERATION_DELETE
			lDelete := .T.
		ElseIf nOperation == MODEL_OPERATION_UPDATE
			If isBlind() .Or. (!(type("lRoti06")=="L".and. lRoti06) .AND. MsgYesNo("Deseja refazer as operações, insumos, mão de obra e ferramentas?"))
				lDelete := .T.
			EndIf
		EndIf

		//-----------------------------------------------------------
		// ZHL Apontamento de Produção
		//-----------------------------------------------------------
		If lHabOpPa
			If nOperation == MODEL_OPERATION_DELETE
				U_DelTabZG("ZHL", cNumOp)
			Else
				IF!(lRotNova)
					U_DelTabZG("ZHL", cNumOp)
				EndIF
			EndIF
		EndIf

		//Criado para o sistema regriar os dados para o apontamento de insumo nas rotinas de beneficiamento GROA062 e Groa060
		iF (type("lRoti06")=="L".and. lRoti06)
			lDelete := .T.
		EndIF

		If lDelete

			If !isBlind()
				oSay:SetText("Atualizando Tabelas Auxiliáres...")
				ProcessMessage()
			Else
				ConOut("Atualizando Tabelas Auxiliáres...")
			EndIf

			//-----------------------------------------------------------
			// ZGH	Apontamento de Produção
			//-----------------------------------------------------------
			//Validar para a nota tela
			cCondLoop  := ".F."
			if( nOperation == MODEL_OPERATION_UPDATE )
				cCondLoop := CVALTOCHAR(IIF(lRotNova,.T.,.F.))
			EndIf

			U_DelTabZG("ZGH", cNumOp, cCondLoop)

			//-----------------------------------------------------------
			// ZGI Apontamento x Insumos
			//-----------------------------------------------------------
			//Validar para a nova tela
			cCondLoop  := ".F."
			if( nOperation == MODEL_OPERATION_UPDATE )
				cCondLoop := "alltrim(&(cTabela)->(ZGI_ORIGEM)) $ 'GROA060/GROA062'"
			EndIf

			U_DelTabZG("ZGI", cNumOp, cCondLoop)

			//-----------------------------------------------------------
			// ZGK	Apontamento x Mão de Obra
			//-----------------------------------------------------------
			U_DelTabZG("ZGK", cNumOp)

			//-----------------------------------------------------------
			// ZGL	Apontamento x Ferramentas
			//-----------------------------------------------------------
			U_DelTabZG("ZGL", cNumOp)

			//-----------------------------------------------------------
			// ZS3	Conferência do Corte
			//-----------------------------------------------------------
			U_DelTabZG("ZS3", cNumOp,, "_NUM")

			//-----------------------------------------------------------
			// ZS7	Insumos do Corte
			//-----------------------------------------------------------
			U_DelTabZG("ZS7", cNumOp,, "_NUM")

		EndIf

		If !isBlind()
			oSay:SetText("Excluindo Empenhos...")
			ProcessMessage()
		Else
			ConOut("Excluindo Empenhos...")
		EndIf

		//------------------------------------------------
		// Recortado deve atualizar tamanho da chapa.
		//------------------------------------------------
		If cProcesso == "R"

			For nX := 1 To nRegZH8

				oModelZH8:GoLine(nX)

				SB8->(DbSetOrder(3))

				If SB8->(MsSeek(xFilial("SB8") + oModelZH8:GetValue('ZH8_CODMAT') + oModelZH8:GetValue('ZH8_LOCAL') + oModelZH8:GetValue('ZH8_LOTECT') + oModelZH8:GetValue('ZH8_NUMLOT')))

					If oModelZH8:GetValue('ZH8_COMORI') > 0 .Or. oModelZH8:GetValue('ZH8_ALTORI') > 0 .Or. oModelZH8:GetValue('ZH8_ESPORI') > 0

						RecLock("SB8", .F.)
						SB8->B8_YCOMLIQ := oModelZH8:GetValue('ZH8_COMORI')
						SB8->B8_YALTLIQ := oModelZH8:GetValue('ZH8_ALTORI')
						SB8->B8_YESPLIQ := oModelZH8:GetValue('ZH8_ESPORI')
						SB8->B8_YTOTLIQ := oModelZH8:GetValue('ZH8_TOTORI')
						SB8->(MsUnLock())

					EndIf
				EndIf
			Next
		EndIf

		SC2->(DbSetOrder(1))
		SC2->(MsSeek(xFilial("SC2") + cNumOp))
		While !(type("lRoti06")=="L".and. lRoti06) .AND. SC2->(!eof()) .and. SC2->C2_FILIAL + SC2->C2_NUM == xFilial("SC2") + cNumOp

			//-----------------------------------------------------------
			// Exclui empenhos
			//-----------------------------------------------------------
			cSql := "   SELECT R_E_C_N_O_ AS recno,D4_FILIAL,D4_COD,D4_OP,D4_LOCAL "
			cSql += "     FROM " + RetSqlName("SD4") + " SD4 "
			cSql += "    WHERE SD4.D4_FILIAL = '" + xFilial("SD4") + "' "
			cSql += "      AND SD4.D4_OP = '" +  SC2->C2_NUM + SC2->C2_ITEM + SC2->C2_SEQUEN + SC2->C2_ITEMGRD   + "' "
			cSql += "      AND SD4.D_E_L_E_T_ = ' ' "

			TCQUERY cSql NEW ALIAS qQuerySd4

			qQuerySd4->(DBGOTOP())

			while qQuerySd4->(!eof())

				SD4->(DBgoto(qQuerySd4->recno))

				aArraySD4	:= {}

				aAdd(aArraySD4, {"D4_FILIAL", qQuerySd4->D4_FILIAL, NIL})
				aAdd(aArraySD4, {"D4_COD",    qQuerySd4->D4_COD,    NIL})
				aAdd(aArraySD4, {"D4_OP",     qQuerySd4->D4_OP,     NIL})

				cDadoPes := xFilial("SB2")+qQuerySd4->D4_COD+qQuerySd4->D4_LOCAL
				If U_REGBLQ("SB2",1,cDadoPes,"")
					dDataBase := dDataOld
					qQuerySd4->(DBCLOSEAREA())
					DisarmTransaction()
					Return .F.
				EndIF

				MSExecAuto({|x,y| MATA380(x,y)}, aArraySD4, 5)

				If lMsErroAuto
					ConOut("GrPlusMVC => [GROA038][ERROR][LINHA][" + cValToChar(ProcLine()) + "]")
					If isBlind()
						cMsgErro := U_GetError(.T.)
					Else
						MostraErro()
					EndIf
					dDataBase := dDataOld
					qQuerySd4->(DBCLOSEAREA())
					DisarmTransaction()
					Return .F.
				EndIf

				qQuerySd4->(DbSkip())

			EndDo

			qQuerySd4->(DBCLOSEAREA())


			//-----------------------------------------------------
			// Verifica se Ordem de Produção é Retrabalho.
			//-----------------------------------------------------
			If SC2->C2_YMP == SC2->C2_PRODUTO

				if cProcesso == "R"
					//Quando a op e de recortado, o sistema utliza o campo de C2_YLOTECT e C2_YNUMLOT para outra coisa
					ZH8->(DbSetOrder(1))
					ZH8->(MsSeek(xFilial("ZH8") + SC2->C2_NUM + SC2->C2_ITEM))

					U_GROXFUN("delRetrabalho", {SC2->C2_YMP,;
						ZH8->ZH8_LOCAL,;
						ZH8->ZH8_LOTECT,;
						ZH8->ZH8_NUMLOT,;
						SC2->C2_EMISSAO,;
						SC2->C2_NUM + SC2->C2_ITEM + SC2->C2_SEQUEN})
				else
					U_GROXFUN("delRetrabalho", {SC2->C2_YMP,;
						SC2->C2_YLOCMP,;
						SC2->C2_YLOTECT,;
						SC2->C2_YNUMLOT,;
						SC2->C2_EMISSAO,;
						SC2->C2_NUM + SC2->C2_ITEM + SC2->C2_SEQUEN})
				ENDIF

				If lMsErroAuto
					cMsgErro  := oUtil:getAutoError()
					dDataBase := dDataOld
					DisarmTransaction()
					MsgStop(cMsgErro)
					Return .F.
				EndIf
			Else

				//-----------------------------------------------------
				// Verifica se Ordem de Produção é Retrabalho. Porque o usuário pode alterar o produto acabado, apartir de uma op normal ele cria uma de retrabalho so alterando o produto acabado na tela de encerramento de ordem de produção.
				//-----------------------------------------------------
				cProdRet := AllTrim(SC2->C2_YMP) + cSiglaRet + Space(TamSx3("B1_COD")[1] - Len(AllTrim(SC2->C2_YMP) + cSiglaRet))

				SD4->(DbSetOrder(1))

				If SD4->(DbSeek(xFilial("SD4") + cProdRet + SC2->C2_NUM + SC2->C2_ITEM + SC2->C2_SEQUEN))
					//Necessário porque o usuário pode alterar o produto acabado e deletar o item.
					//quando faz essa situação em uma op de retrabalho o sistema deixa o saldo no produto retrabalho.
					U_GROXFUN("delRetrabalho", {SC2->C2_YMP,;
						SC2->C2_YLOCMP,;
						SC2->C2_YLOTECT,;
						SC2->C2_YNUMLOT,;
						SC2->C2_EMISSAO,;
						SC2->C2_NUM + SC2->C2_ITEM + SC2->C2_SEQUEN})

					If lMsErroAuto
						dDataBase := dDataOld
						If isBlind()
							cMsgErro := U_GetError(.T.)
						Else
							MostraErro()
						EndIf
						DisarmTransaction()
						Return .F.
					EndIf

				EndIf
			EndIf

			SC2->(DbSkip())
		EndDo

		If nOperation == MODEL_OPERATION_DELETE

			ZPA->(DbSetOrder(5))
			ZPA->(DbSeek(xFilial("ZPA") + cNumOp))
			While ZPA->(!Eof()) .And. ZPA->(ZPA_FILIAL + ZPA_OP) == xFilial("ZPA") + cNumOp

				cNumReser  := ZPA->(ZPA_NUMERO)

				SC0->(DbSetOrder(1))
				SC0->(DbSeek(xFilial("SC0") + ZPA->(ZPA_NUMRES + ZPA_PRODUT + ZPA_LOCAL + ZPA_LOTECT + ZPA_NUMLOT)))

				While SC0->(!Eof()) .And. SC0->(C0_FILIAL + C0_NUM + C0_PRODUTO + C0_LOCAL + C0_LOTECTL + C0_NUMLOTE)  == xFilial("SC0") + ZPA->(ZPA_NUMRES + ZPA_PRODUT + ZPA_LOCAL + ZPA_LOTECT + ZPA_NUMLOT)

					RecLock("SC0", .F.)
					SC0->C0_QUANT  := ZPA->ZPA_QUANTI
					SC0->C0_QTDPED := 0
					SC0->(MsUnLock())

					If  !IntDL(SC0->C0_PRODUTO)
						lCampo22 := !Empty(SC0->C0_LOTECTL+SC0->C0_NUMLOTE).Or.Localiza(SC0->C0_PRODUTO)
					Else
						lCampo22 := !Empty(SC0->C0_LOTECTL+SC0->C0_NUMLOTE+SC0->C0_LOCALIZ+SC0->C0_NUMSERI)
					EndIf

					GravaEmp(SC0->C0_PRODUTO,; //-- 1
					SC0->C0_LOCAL,; //-- 2
					SC0->C0_QUANT,; //-- 3
					NIL,; //-- 4
					SC0->C0_LOTECTL,; //-- 5
					SC0->C0_NUMLOTE,; //-- 6
					SC0->C0_LOCALIZ,; //-- 7
					SC0->C0_NUMSERI,; //-- 8
					Nil,; //-- 9
					Nil,; //-- 10
					SC0->C0_NUM,; //-- 11
					Nil,; //-- 12
					"SC0",; //-- 13
					Nil,; //-- 14
					Nil,; //-- 15
					Nil,; //-- 16
					.F.,; //-- 17 Remove reserva
					.F.,; //-- 18
					.T.,; //-- 19
					.F.,; //-- 20
					Nil,; //-- 21
					lCampo22) //-- 22

					SC0->(DbSkip())

				EndDo

				RecLock("ZPA", .F.)
				ZPA->ZPA_OP = ""
				ZPA->(MsUnLock())
				ZPA->(DbSeek(xFilial("ZPA") + cNumOp))

			EndDo

			//A reserva estava ficando como encerrada. Porem precisa ser aberta.
			ZP9->(DbSetOrder(1))
			If ZP9->(DbSeek(xFilial("ZP9") + cNumReser))
				RecLock("ZP9", .F.)
				ZP9->ZP9_STATUS := "A"
				ZP9->(MsUnLock())
			EndIf

			//Atualiza o Cavalete sem os produtos retrabalho a partir do número da OP antes de deleta-la na SC2.
			u_ATCAVZPB(cNumOp)

			If !isBlind()
				oSay:SetText("Excluindo Ordem de Produção...")
				ProcessMessage()
			Else
				ConOut("Excluindo Ordem de Produção...")
			EndIf

			Conout("GrPlusMVC => Excluindo OP No. " + cNumOp + ". " + AllTrim(DtoC(Date())) + " " + AllTrim(Time()) + ".")

			//-----------------------------------------------------------
			// Ordem de ordem de produção excluída.
			//-----------------------------------------------------------

			SC2->(DbSetOrder(1))
			SC2->(MsSeek(xFilial("SC2") + cNumOp))
			While SC2->(!eof()) .and. SC2->(C2_FILIAL + C2_NUM) == xFilial("SC2") + cNumOp

				aArraySC2	:= {}

				aAdd(aArraySC2, {"C2_FILIAL", SC2->C2_FILIAL, NIL})
				aAdd(aArraySC2, {"C2_NUM",    SC2->C2_NUM,    NIL})
				aAdd(aArraySC2, {"C2_ITEM",   SC2->C2_ITEM,   NIL})
				aAdd(aArraySC2, {"C2_SEQUEN", SC2->C2_SEQUEN, NIL})

				DbSelectArea("SC2")

				//-----------------------------------------------------------
				// Exclui ordem de producao
				//-----------------------------------------------------------
				MSExecAuto({|x,y| MATA650(x,y)}, aArraySC2, 5)

				If lMsErroAuto
					ConOut("GrPlusMVC => [GROA038][ERROR][LINHA][" + cValToChar(ProcLine()) + "]")
					If isBlind()
						cMsgErro := U_GetError(.T.)
					Else
						MostraErro()
					EndIf
					dDataBase := dDataOld
					DisarmTransaction()
					Return .F.
				EndIf

			EndDo

			FWFormCommit(oModel)

		Else // If  nOperation == MODEL_OPERATION_UPDATE

			If nOperation == MODEL_OPERATION_INSERT
				Conout("GrPlusMVC => Incluindo OP No. " + cNumOp + ". " + AllTrim(DtoC(Date())) + " " + AllTrim(Time()) + ".")
			ElseIf nOperation == MODEL_OPERATION_UPDATE
				Conout("GrPlusMVC => Alterando itens da OP No. " + cNumOp + ". " + AllTrim(DtoC(Date())) + " " + AllTrim(Time()) + ".")

				//Ajuste necessário porque as rotinas GROA060 e GROA062 podem ser alteradas apos encerrada.
				If ALLTRIM(oModel:GetValue('ZH7MASTER', 'ZH7_ROTINA')) $ "GROA060/GROA062"
					cLotes += ALLTRIM(oModel:GetValue('ZH7MASTER', 'ZH7_BLOCO')) + ", "
					aLotes := StrTokArr(ALLTRIM(oModel:GetValue('ZH7MASTER', 'ZH7_BLOCO')),",")
				EndIF

			EndIf

			If !isBlind()
				oSay:SetText("Atualizando Ordem de Produção...")
				ProcessMessage()
			Else
				ConOut("Atualizando Ordem de Produção...")
			EndIf

			aSC2_OP := {}

			aAdd(aSC2_OP, {"C2_NUM",     oModelZH7:GetValue('ZH7_NUM'),    NIL})
			aAdd(aSC2_OP, {"C2_YTIPO",   oModelZH7:GetValue('ZH7_PROCES'), NIL})
			aAdd(aSC2_OP, {"C2_EMISSAO", oModelZH7:GetValue('ZH7_EMISSA'), NIL})
			aAdd(aSC2_OP, {"C2_DATPRI",  oModelZH7:GetValue('ZH7_DATPRI'), NIL})
			aAdd(aSC2_OP, {"C2_DATPRF",  oModelZH7:GetValue('ZH7_DATPRF'), NIL})
			aAdd(aSC2_OP, {"C2_TPOP",    oModelZH7:GetValue('ZH7_TIPOOP'), NIL})
			aAdd(aSC2_OP, {"C2_YFRENTE", oModelZH7:GetValue('ZH7_FRENTE'), NIL})
			aAdd(aSC2_OP, {"C2_YTEAR",   oModelZH7:GetValue('ZH7_RECURS'), NIL})
			aAdd(aSC2_OP, {"C2_YSITUAC", oModelZH7:GetValue('ZH7_SITUAC'), NIL})
			aAdd(aSC2_OP, {"C2_YCOECOR", oModelZH7:GetValue('ZH7_COECOR'), NIL})
			aAdd(aSC2_OP, {"C2_YCODMOT", oModelZH7:GetValue('ZH7_CODMOT'), NIL})

			//--------------------------------------------------------
			// Percorrendo Materia-Prima
			//--------------------------------------------------------
			For nX := 1 To nRegZH8

				oModelZH8:GoLine(nX)

				aSC2_MP := aClone(aSC2_OP)

				If oModelZH8:IsDeleted()

					cItemOp := oModelZH8:GetValue('ZH8_ITEM')

					SC2->(DbSetOrder(1))
					SC2->(MsSeek(xFilial("SC2") + cNumOp + cItemOp))
					While !(type("lRoti06")=="L".and. lRoti06) .AND. SC2->(!eof()) .And. SC2->C2_FILIAL + SC2->C2_NUM + SC2->C2_ITEM == xFilial("SC2") + cNumOp + cItemOp

						aArraySC2	:= {}

						aAdd(aArraySC2, {"C2_FILIAL", SC2->C2_FILIAL, NIL})
						aAdd(aArraySC2, {"C2_NUM",    SC2->C2_NUM,    NIL})
						aAdd(aArraySC2, {"C2_ITEM",   SC2->C2_ITEM,   NIL})
						aAdd(aArraySC2, {"C2_SEQUEN", SC2->C2_SEQUEN, NIL})

						DbSelectArea("SC2")

						/* Exclui ordem de producao */
						MSExecAuto({|x,y| MATA650(x,y)}, aArraySC2, 5)

						If lMsErroAuto
							ConOut("GrPlusMVC => [GROA038][ERROR][LINHA][" + cValToChar(ProcLine()) + "]")
							If isBlind()
								cMsgErro := U_GetError(.T.)
							Else
								MostraErro()
							EndIf
							dDataBase := dDataOld
							DisarmTransaction()
							Return .F.
						EndIf

					EndDo

				Else

					//Verificar se ja foi produzido.
					If (type("lRoti06")=="L".and. lRoti06)
						iF !empty(Posicione("SC2", 9, xFilial("SC2") + cNumOp + oModelZH8:GetValue('ZH8_ITEM'), "C2_DATRF"))
							loop
						EndIf
					Endif

					//Quando usuário coloca uma seta do teclado para baixo e depois deleta ela(em branco), o sistema esta dexiando a engenharia em branco.
					//Ticket:2735
					If Empty(cEngenha)
						cEngenha   := oModelZH8:GetValue('ZH8_ENGENH')
					EndIF

					If Ascan(aLotes, {|x| AllTrim(x) == AllTrim(oModelZH8:GetValue('ZH8_LOTECT')) }) == 0
						If !oModelZH8:IsDeleted()
							cLotes += AllTrim(oModelZH8:GetValue('ZH8_LOTECT')) + ", "
							aAdd(aLotes, AllTrim(oModelZH8:GetValue('ZH8_LOTECT')))
						EndIf
					EndIf

					//----------------------------------------------
					// Recortado não precisa ficar no for do ZH8
					//----------------------------------------------
					If cProcesso <> "R"

						aAdd(aSC2_MP, {"C2_ITEM",    oModelZH8:GetValue('ZH8_ITEM'),   NIL})
						aAdd(aSC2_MP, {"C2_YENGENH", oModelZH8:GetValue('ZH8_ENGENH'), NIL})
						aAdd(aSC2_MP, {"C2_YMP",     oModelZH8:GetValue('ZH8_CODMAT'), NIL})
						aAdd(aSC2_MP, {"C2_YLOCMP",  oModelZH8:GetValue('ZH8_LOCAL'),  NIL})
						aAdd(aSC2_MP, {"C2_YUMMP",   oModelZH8:GetValue('ZH8_UM'),     NIL})
						aAdd(aSC2_MP, {"C2_YCOMMP",  oModelZH8:GetValue('ZH8_COMLIQ'), NIL})
						aAdd(aSC2_MP, {"C2_YALTMP",  oModelZH8:GetValue('ZH8_ALTLIQ'), NIL})
						aAdd(aSC2_MP, {"C2_YESPMP",  oModelZH8:GetValue('ZH8_ESPLIQ'), NIL})
						aAdd(aSC2_MP, {"C2_YTOTMP",  oModelZH8:GetValue('ZH8_TOTLIQ'), NIL})

						If !(cProcesso $ "E/R")
							aAdd(aSC2_MP, {"C2_YLOTECT", oModelZH8:GetValue('ZH8_LOTECT'), NIL})
							aAdd(aSC2_MP, {"C2_YNUMLOT", oModelZH8:GetValue('ZH8_NUMLOT'), NIL})

						EndIf

						aRetValData := U_GetValData(aSC2_MP, dDataBase)

						If !(aRetValData[1])
							cMsgErro  := aRetValData[2]
							dDataBase := dDataOld
							DisarmTransaction()
							MsgStop(cMsgErro)
							Return .F.
						EndIf

						lRetSX3 := U_X3VALID()

						If !lRetSX3
							DisarmTransaction()
							Return .F.
						EndIf

						//--------------------------------------------------------
						// Percorrendo Produto Acabado
						//--------------------------------------------------------
						nRegZH9 := oModelZH9:Length() //Pegando a quantidade da ZH9 que esta posicionada https://totvsleste.freshdesk.com/a/tickets/2090
						For nY := 1 To nRegZH9

							oModelZH9:GoLine(nY)

							aArraySC2 := aClone(aSC2_MP)

							If oModelZH9:IsDeleted()

								cItemOp   := oModelZH8:GetValue('ZH8_ITEM')
								cSequenOp := oModelZH9:GetValue('ZH9_SEQUEN')

								SC2->(DbSetOrder(1))
								SC2->(MsSeek(xFilial("SC2") + cNumOp + cItemOp + cSequenOp))
								While SC2->(!eof()) .And. SC2->C2_FILIAL + SC2->C2_NUM + SC2->C2_ITEM + SC2->C2_SEQUEN == xFilial("SC2") + cNumOp + cItemOp + cSequenOp

									aArraySC2	:= {}
									aAdd(aArraySC2, {"C2_FILIAL", SC2->C2_FILIAL, NIL})
									aAdd(aArraySC2, {"C2_NUM",    SC2->C2_NUM,    NIL})
									aAdd(aArraySC2, {"C2_ITEM",   SC2->C2_ITEM,   NIL})
									aAdd(aArraySC2, {"C2_SEQUEN", SC2->C2_SEQUEN, NIL})

									DbSelectArea("SC2")

									/* Exclui ordem de producao */
									MSExecAuto({|x,y| MATA650(x,y)}, aArraySC2, 5)

									If lMsErroAuto
										ConOut("GrPlusMVC => [GROA038][ERROR][LINHA][" + cValToChar(ProcLine()) + "]")
										If isBlind()
											cMsgErro := U_GetError(.T.)
										Else
											MostraErro()
										EndIf
										dDataBase := dDataOld
										DisarmTransaction()
										Return .F.
									EndIf

								EndDo

							Else

								aAdd(aArraySC2, {"C2_SEQUEN",  oModelZH9:GetValue('ZH9_SEQUEN'), NIL})
								aAdd(aArraySC2, {"C2_PRODUTO", oModelZH9:GetValue('ZH9_CODPA'),  NIL})
								aAdd(aArraySC2, {"C2_LOCAL",   oModelZH9:GetValue('ZH9_LOCAL'),  NIL})
								aAdd(aArraySC2, {"C2_UM",      oModelZH9:GetValue('ZH9_UM'),     NIL})
								aAdd(aArraySC2, {"C2_YQTDUNI", oModelZH9:GetValue('ZH9_QUANTI'), NIL})
								aAdd(aArraySC2, {"C2_SEGUM",   oModelZH9:GetValue('ZH9_SEGUM'),  NIL})
								aAdd(aArraySC2, {"C2_QTSEGUM", oModelZH9:GetValue('ZH9_QTDSEG'), NIL})

								//https://projetostotvses.freshdesk.com/a/tickets/2571
								If cProcesso $ "B/T"
									aAdd(aArraySC2, {"C2_QUANT", oModelZH9:GetValue('ZH9_TOTLIQ'), NIL})
								Else
									aAdd(aArraySC2, {"C2_QUANT", oModelZH9:GetValue('ZH9_QUANTI') * oModelZH9:GetValue('ZH9_TOTLIQ'), NIL})
								EndIf
								aAdd(aArraySC2, {"C2_YCOMLIQ", oModelZH9:GetValue('ZH9_COMLIQ'), NIL})
								aAdd(aArraySC2, {"C2_YALTLIQ", oModelZH9:GetValue('ZH9_ALTLIQ'), NIL})
								aAdd(aArraySC2, {"C2_YESPLIQ", oModelZH9:GetValue('ZH9_ESPLIQ'), NIL})
								aAdd(aArraySC2, {"C2_YTOTLIQ", oModelZH9:GetValue('ZH9_TOTLIQ'), NIL})
								aAdd(aArraySC2, {"C2_YCOMBRU", oModelZH9:GetValue('ZH9_COMBRU'), NIL})
								aAdd(aArraySC2, {"C2_YALTBRU", oModelZH9:GetValue('ZH9_ALTBRU'), NIL})
								aAdd(aArraySC2, {"C2_YESPBRU", oModelZH9:GetValue('ZH9_ESPBRU'), NIL})
								aAdd(aArraySC2, {"C2_YTOTBRU", oModelZH9:GetValue('ZH9_TOTBRU'), NIL})
								aAdd(aArraySC2, {"C2_YSITUAC", "P", NIL})

								If cProcesso $ "E/R"
									aAdd(aArraySC2, {"C2_YLOTECT", oModelZH9:GetValue('ZH9_LOTECT'), NIL})
									aAdd(aArraySC2, {"C2_YNUMLOT", oModelZH9:GetValue('ZH9_NUMLOT'), NIL})
								EndIf

								If __cProcess == "R"
									cItemOp   := "01"
								Else
									cItemOp   := oModelZH8:GetValue('ZH8_ITEM')
								EndIf

								cSequenOp := oModelZH9:GetValue('ZH9_SEQUEN')

								SC2->(DbSetOrder(1))
								If SC2->(MsSeek(xFilial("SC2") + cNumOp + cItemOp + cSequenOp))
									nOpcDet := 4
								Else
									nOpcDet := 3
								EndIf

								If nOpcDet == 4
									RegToMemory("SC2", .f.)
									aAreaSC2 := SC2->(GetArea())
								EndIf

								cCodTer	 	:= ""
								cLocalTer	:= ""
								cLoteTer	:= ""
								cNumLTer    := ""

								nPosTer :=  aScan(aArraySC2, {|x| AllTrim(x[1]) == "C2_YMP"})
								If nPosTer > 0
									cCodTer := aArraySC2[nPosTer,2]
								EnDiF

								nPosTer :=  aScan(aArraySC2, {|x| AllTrim(x[1]) == "C2_YLOCMP"})
								If nPosTer > 0
									cLocalTer := aArraySC2[nPosTer,2]
								EnDiF

								nPosTer :=  aScan(aArraySC2, {|x| AllTrim(x[1]) == "C2_YLOTECT"})
								If nPosTer > 0
									cLoteTer := aArraySC2[nPosTer,2]
								EnDiF

								nPosTer :=  aScan(aArraySC2, {|x| AllTrim(x[1]) == "C2_YNUMLOT"})
								If nPosTer > 0
									cNumLTer := aArraySC2[nPosTer,2]
								EnDiF

								If lHabOtOp == 0
									aAdd(aArraySC2, {"C2_TPPR ", "I", NIL})
								ElseIf lHabOtOp == 1
									If cProcesso $ "T"
										aAdd(aArraySC2, {"C2_TPPR ", "R", NIL})
									Else
										aAdd(aArraySC2, {"C2_TPPR ", "I", NIL})
									EndIF
								EndIF

								aRetTer := u_PODERTER(cCodTer,cLocalTer,cLoteTer,cNumLTer)
								If(aRetTer[1])

									aAdd(aArraySC2, {"C2_OPTERCE ", "1", NIL})

									If SC2->(FieldPos("C2_YCLITER")) > 0 .and. SC2->(FieldPos("C2_YLOJTER")) > 0

										SA1->(DbSetOrder(1))

										If SA1->(DbSeek(xFilial("SA1") + aRetTer[2] + aRetTer[3]))
											aAdd(aArraySC2, {"C2_YCLITER ", aRetTer[2], NIL})
											aAdd(aArraySC2, {"C2_YLOJTER ", aRetTer[3], NIL})
										Else
											cMsgErro  := "Não foi encontrado o cadastro de cliente para o codigo " + aRetTer[2] + " loja " + aRetTer[3] + ", favor verificar se a nota de entrada para o material esta correta. Normalmente a nota com tes de terceiro precisa estar com o tipo beneficiamento."
											dDataBase := dDataOld
											DisarmTransaction()
											MsgStop(cMsgErro)
											Return .F.
										EndIf

									elseIf lContTer
										If !MsgYesNo("1 - Não foi encontrado o campo C2_YCLITER/C2_YLOJTER necessário para os dados do bloco k. Favor executar o udponline para criar o campo. Deseja continuar a operação ?")
											ConOut("GrPlusMVC => [GROA038][ERROR][LINHA][" + cValToChar(ProcLine()) + "]")
											dDataBase := dDataOld
											DisarmTransaction()
											Return .F.
										Else
											lContTer := .F.
										EndIf
									EndIf
								EndIf

								DbSelectArea("SC2")

								aArraySC2 := OrderSC2(aArraySC2)

								/* ordem de producao */
								MSExecAuto({|x,y| MATA650(x,y)}, aArraySC2, nOpcDet)

								If nOpcDet == 4
									RestArea(aAreaSC2)
								EndIf

								If lMsErroAuto
									ConOut("GrPlusMVC => [GROA038][ERROR][LINHA][" + cValToChar(ProcLine()) + "]")
									If isBlind()
										cMsgErro := U_GetError(.T.)
									Else
										MostraErro()
									EndIf
									dDataBase := dDataOld
									DisarmTransaction()
									Return .F.
								EndIf

							EndIf

						Next

					EndIf

				EndIf

			Next

			If cProcesso == "R"

				aAdd(aSC2_MP, {"C2_ITEM",    "01",   NIL})
				aAdd(aSC2_MP, {"C2_YENGENH", oModelZH8:GetValue('ZH8_ENGENH'), NIL})
				aAdd(aSC2_MP, {"C2_YMP",     oModelZH8:GetValue('ZH8_CODMAT'), NIL})

				aRetValData := U_GetValData(aSC2_MP, dDataBase)

				If !(aRetValData[1])
					cMsgErro  := aRetValData[2]
					dDataBase := dDataOld
					DisarmTransaction()
					MsgStop(cMsgErro)
					Return .F.
				EndIf

				lRetSX3 := U_X3VALID()

				If !lRetSX3
					DisarmTransaction()
					Return .F.
				EndIf

				//--------------------------------------------------------
				// Percorrendo Produto Acabado
				//--------------------------------------------------------
				nRegZH9 := oModelZH9:Length() //Pegando a quantidade da ZH9 que esta posicionada https://totvsleste.freshdesk.com/a/tickets/2090
				For nY := 1 To nRegZH9

					oModelZH9:GoLine(nY)

					aArraySC2 := aClone(aSC2_MP)

					If oModelZH9:IsDeleted()

						cItemOp   := "01"
						cSequenOp := oModelZH9:GetValue('ZH9_SEQUEN')

						SC2->(DbSetOrder(1))
						SC2->(MsSeek(xFilial("SC2") + cNumOp + cItemOp + cSequenOp))
						While SC2->(!eof()) .And. SC2->C2_FILIAL + SC2->C2_NUM + SC2->C2_ITEM + SC2->C2_SEQUEN == xFilial("SC2") + cNumOp + cItemOp + cSequenOp

							aArraySC2	:= {}

							aAdd(aArraySC2, {"C2_FILIAL", SC2->C2_FILIAL, NIL})
							aAdd(aArraySC2, {"C2_NUM",    SC2->C2_NUM,    NIL})
							aAdd(aArraySC2, {"C2_ITEM",   SC2->C2_ITEM,   NIL})
							aAdd(aArraySC2, {"C2_SEQUEN", SC2->C2_SEQUEN, NIL})

							DbSelectArea("SC2")

							/* Exclui ordem de producao */
							MSExecAuto({|x,y| MATA650(x,y)}, aArraySC2, 5)

							If lMsErroAuto
								ConOut("GrPlusMVC => [GROA038][ERROR][LINHA][" + cValToChar(ProcLine()) + "]")
								If isBlind()
									cMsgErro := U_GetError(.T.)
								Else
									MostraErro()
								EndIf
								dDataBase := dDataOld
								DisarmTransaction()
								Return .F.
							EndIf

						EndDo

					Else

						//Alerta Campo obrigatório.
						If oModelZH9:GetValue('ZH9_TOTLIQ') == 0
							cMsgErro  := "O campo total líquido não foi preenchido - ZH9_TOTLIQ"
							dDataBase := dDataOldF
							DisarmTransaction()
							MsgStop(cMsgErro)
							Return .F.
						EndIf

						aAdd(aArraySC2, {"C2_SEQUEN",  oModelZH9:GetValue('ZH9_SEQUEN'), NIL})
						aAdd(aArraySC2, {"C2_PRODUTO", oModelZH9:GetValue('ZH9_CODPA'),  NIL})
						aAdd(aArraySC2, {"C2_LOCAL",   oModelZH9:GetValue('ZH9_LOCAL'),  NIL})
						aAdd(aArraySC2, {"C2_UM",      oModelZH9:GetValue('ZH9_UM'),     NIL})
						aAdd(aArraySC2, {"C2_YQTDUNI", oModelZH9:GetValue('ZH9_QUANTI'), NIL})
						aAdd(aArraySC2, {"C2_QUANT",   oModelZH9:GetValue('ZH9_TOTLIQ'), NIL})
						aAdd(aArraySC2, {"C2_YSITUAC", "P", NIL})
						aAdd(aArraySC2, {"C2_YLOTECT", oModelZH9:GetValue('ZH9_LOTECT'), NIL})
						aAdd(aArraySC2, {"C2_YNUMLOT", oModelZH9:GetValue('ZH9_NUMLOT'), NIL})
						aAdd(aArraySC2, {"C2_SEGUM",   oModelZH9:GetValue('ZH9_SEGUM'),  NIL})
						aAdd(aArraySC2, {"C2_QTSEGUM", oModelZH9:GetValue('ZH9_QTDSEG'), NIL})

						cItemOp   := "01"
						cSequenOp := oModelZH9:GetValue('ZH9_SEQUEN')

						SC2->(DbSetOrder(1))
						If SC2->(MsSeek(xFilial("SC2") + cNumOp + cItemOp + cSequenOp))
							nOpcDet := 4
						Else
							nOpcDet := 3
						EndIf

						If nOpcDet == 4
							RegToMemory("SC2", .f.)
							aAreaSC2 := SC2->(GetArea())
						EndIf

						DbSelectArea("SC2")

						aArraySC2 := OrderSC2(aArraySC2)

						/* ordem de producao */
						MSExecAuto({|x,y| MATA650(x,y)}, aArraySC2, nOpcDet)

						If nOpcDet == 4
							RestArea(aAreaSC2)
						EndIf

						If lMsErroAuto
							ConOut("GrPlusMVC => [GROA038][ERROR][LINHA][" + cValToChar(ProcLine()) + "]")
							If isBlind()
								cMsgErro := U_GetError(.T.)
							Else
								MostraErro()
							EndIf
							dDataBase := dDataOld
							DisarmTransaction()
							Return .F.
						EndIf

					EndIf

				Next

			EndIf

			If Len(cLotes) > 0
				cLotes := SubStr(cLotes, 1, Len(cLotes)-2)
			EndIf

			oModel:SetValue('ZH7MASTER', 'ZH7_BLOCO',  cLotes)
			oModel:SetValue('ZH7MASTER', 'ZH7_ENGENH', cEngenha)
			oModel:SetValue('ZH7MASTER', 'ZH7_DESCEN', POSICIONE("ZG7", 1, XFILIAL("ZG7") + cEngenha, "ZG7_DESCRI"))

			// O Modelo de ser gravado antes de gerar a ZGM e o Empenho
			FWFormCommit(oModel)

			If !isBlind()
				oSay:SetText("Gerando Ordem de Produção...")
				ProcessMessage()
			Else
				ConOut("Gerando Ordem de Produção...")
			EndIf

			aRetAuto := u_execautoZgm(cNumOp)

			If !(aRetAuto[1])
				cMsgErro  := decodeUTF8(aRetAuto[2])
				dDataBase := dDataOld
				DisarmTransaction()
				MsgStop(cMsgErro)
				Return .F.
			EndIf

			If !isBlind()
				oSay:SetText("Gerando Empenhos...")
				ProcessMessage()
			Else
				ConOut("Gerando Empenhos...")
			EndIf

			aRetAuto := u_GeraEmpenho(cNumOp, oModel)

			If !(aRetAuto[1])
				cMsgErro  := decodeUTF8(aRetAuto[2])
				dDataBase := dDataOld
				DisarmTransaction()
				MsgStop(cMsgErro)
				Return .F.
			EndIf

			u_ATCAVZPB(cNumOp)

		EndIf

		cMsgErro  := ""
		aOperacao := {}
		aInsumo   := {}
		aAutoCab  := {}

		If !isBlind()
			oSay:SetText("Concluíndo Processo...")
			ProcessMessage()
		Else
			ConOut("Concluíndo Processo...")
		EndIf

		ZGH->(DbSetOrder(1))
		If ZGH->(!MsSeek(xFilial("ZGH") + cNumOp))

			SC2->(DbSetOrder(1))
			SC2->(MsSeek(xFilial("SC2") + cNumOp))
			//https://totvsleste.freshdesk.com/a/tickets/1334
			//Quando utiliza duas engenharia na mesma op com operações diferentes o sistema estava
			cSequencia := "00"
			While SC2->(!eof()) .and. SC2->C2_FILIAL + SC2->C2_NUM == xFilial("SC2") + cNumOp

				cRecurso := SC2->C2_YTEAR
				//cSequencia := "00"

				ZG8->(DbSetOrder(4))
				ZG8->(MsSeek(xFilial("ZG8") + SC2->C2_YENGENH))
				While ZG8->(!eof()) .and. ZG8->ZG8_FILIAL + ZG8->ZG8_ROTEIR == xFilial("ZG8") + SC2->C2_YENGENH

					nPosReg := aScan(aOperacao, {|x| alltrim(x[2]) == alltrim(ZG8->ZG8_OPERAC)})
					If nPosReg == 0
						cSequencia := soma1(cSequencia)
						cSeqOperac := cSequencia
						aAdd(aOperacao, {cSequencia, alltrim(ZG8->ZG8_OPERAC), alltrim(ZG8->ZG8_OPEREP)})
					Else
						cSeqOperac := aOperacao[nPosReg,1]
					EndIf

					/* grava operação na tabela padrão do protheus */																				
					SGF->(DbSetOrder(1))
					If SGF->(!MsSeek(xFilial("SGF") + SC2->(C2_PRODUTO) + "GE" + cSeqOperac))

						aRegistro := {}
						aAdd(aRegistro, {"GF_FILIAL",  xFilial("SGF"),	NIL})
						aAdd(aRegistro, {"GF_PRODUTO", SC2->C2_PRODUTO,	NIL})
						aAdd(aRegistro, {"GF_ROTEIRO", "GE",			NIL})
						aAdd(aRegistro, {"GF_OPERAC",  cSeqOperac,	    NIL})
						aAdd(aRegistro, {"GF_TRT",     cSeqOperac,	    NIL})

						cMsgErro	:= oUtil:setExecAuto('SGF', aRegistro, 'GF_PRODUTO+GF_ROTEIRO+GF_OPERAC', 3)

						If !Empty(cMsgErro)
							dDataBase := dDataOld
							DisarmTransaction()
							MsgStop(cMsgErro)
							Return .F.
						Else
							RecLock("SC2", .F.)
							SC2->C2_ROTEIRO := "GE"
							SC2->(MsUnLock())
						EndIf

					EndIf

					//-----------------------------------------------------
					// Inclui vínculo da operação com o produto acabado.
					//-----------------------------------------------------
					If lHabOpPa .And. SC2->C2_YTIPO $ cTiposZHL

						lGeraZHL := .F.

						IF lRotNova
							IF ZH7->ZH7_SITUAC != 'P'
								IF !EMPTY(SC2->C2_DATRF)
									lGeraZHL := .T.
								EndIF
							else
								lGeraZHL := .T.
							EndIf
						Else
							lGeraZHL := .T.
						EndIf

						if (lGeraZHL)

							ZHL->(DbSetOrder(1))
							IF !ZHL->(MsSeek(xFilial("ZHL") + SC2->C2_NUM + cSeqOperac + SC2->C2_ITEM + SC2->C2_SEQUEN))
								RecLock("ZHL", .T.)
								ZHL->ZHL_FILIAL := xFilial("ZHL")
								ZHL->ZHL_OP     := SC2->C2_NUM
								ZHL->ZHL_ITEM   := SC2->C2_ITEM
								ZHL->ZHL_SEQOP  := SC2->C2_SEQUEN
								ZHL->ZHL_SEQUEN := cSeqOperac
								ZHL->ZHL_CHECK  := .T.
								ZHL->(MsUnLock())
							EndIf
						EndIf

					EndIf

					cLoteIns := ""
					cNumAgru := "DUPLI000"

					ZGB->(DbSetOrder(1))
					ZGB->(MsSeek(xFilial("ZGB") + ZG8->(ZG8_ROTEIR + ZG8_SEQUEN)))
					While ZGB->(!eof()) .and. ZGB->ZGB_FILIAL + ZGB->ZGB_ROTEIR + ZGB->ZGB_SEQUEN == xFilial("ZGB") + ZG8->ZG8_ROTEIR + ZG8->ZG8_SEQUEN

						//Rotina para retirar os insumos criados pela rotina nova vindo da engenharia
						If ALLTRIM(cRotCria) $ "GROA060/GROA062"
							ZGB->(dbSkip())
							Loop
						EndIf


						//Ajuste para o sistema não agrupar com lote.
						cRastIns :=  ALLTRIM(Posicione('SB1',1,xFilial('SB1')+ZGB->ZGB_PRODUT,'B1_RASTRO'))

						If lDesgIns
							cNumAgru := soma1(cNumAgru)
							cLoteIns := cNumAgru
							If cRastIns $ 'N'
								cLoteIns := ""
							EndIF
						EndIF

						nPosReg := aScan(aInsumo, {|x| x[1] + x[3] + x[4] + x[8] == cSeqOperac + ZG8->ZG8_OPERAC + ZGB->ZGB_PRODUT + cLoteIns})

						If nPosReg == 0
							aAdd(aInsumo, {cSeqOperac, ZGB->ZGB_ROTEIR, ZG8->ZG8_OPERAC, ZGB->ZGB_PRODUT, U_QTDRECUR(ZGB->ZGB_FIXVAR, ZGB->ZGB_QTDE, SC2->C2_QUANT, SC2->C2_YTEAR), ZGB->ZGB_UM, ZGB->ZGB_LOCAL, cLoteIns, ZGB->ZGB_FIXVAR})
						Else
							aInsumo[nPosReg, 5] += U_QTDRECUR(ZGB->ZGB_FIXVAR,ZGB->ZGB_QTDE,SC2->C2_QUANT,SC2->C2_YTEAR)
						EndIf

						ZGB->(dbSkip())
					EndDo

					ZG8->(dbSkip())
				EndDo

				SC2->(dbSkip())
			EndDo

			nOperacao := len(aOperacao)

			For nW := 1 to nOperacao

				aAutoCab := {}
				aAdd(aAutoCab, {"ZGH_FILIAL", xFilial("ZGH")})
				aAdd(aAutoCab, {"ZGH_OP",     cNumOp})
				aAdd(aAutoCab, {"ZGH_SEQUEN", aOperacao[nW,1]})
				aAdd(aAutoCab, {"ZGH_ORDEM",  aOperacao[nW,1]})
				aAdd(aAutoCab, {"ZGH_OPERAC", aOperacao[nW,2]})
				aAdd(aAutoCab, {"ZGH_OPEREP", aOperacao[nW,3]})
				aAdd(aAutoCab, {"ZGH_RECURS", cRecurso})
				aAdd(aAutoCab, {"ZGH_STATUS", "P"})

				cMsgErro := oUtil:setExecAuto('ZGH', aAutoCab, 'ZGH_OP+ZGH_SEQUEN', 3)

				If !Empty(cMsgErro)
					dDataBase := dDataOld
					DisarmTransaction()
					MsgStop(cMsgErro)
					Return .F.
				EndIf

			Next

			cGruRec := Posicione("SH1", 1, xFilial("SH1") + oModelZH7:GetValue('ZH7_RECURS'), "H1_YGRUPO")
			cTipRec := Posicione("ZGF", 1, xFilial("ZGF") + cGruRec, "ZGF_TIPO")
			cSeqLan := "000"

			For nW := 1 to len(aInsumo)

				//ponto de entrada para alterar o armazem do insumo // https://totvsleste.freshdesk.com/a/tickets/2098
				IF ExistBlock('GRLOCINS')
					aInsumo[nW,7] := U_GRLOCINS('IDOP',aInsumo[nW])
					If !(ExistCpo("NNR",xFilial("NNR")+aInsumo[nW,7]))
						cMsgErro  := "P.E - U_GRLOCINS - Armazem não esta cadastrado"
						dDataBase := dDataOld
						DisarmTransaction()
						MsgStop(cMsgErro)
						Return .F.
					EndIf
				EndIf

				If cHabCorte == "0"

					aAutoCab := {}

					aAdd(aAutoCab, {"ZGI_FILIAL", xFilial("ZGI"), NIL})
					aAdd(aAutoCab, {"ZGI_OP",     cNumOp,         NIL})
					aAdd(aAutoCab, {"ZGI_SEQUEN", aInsumo[nW,1],  NIL})
					aAdd(aAutoCab, {"ZGI_PRODUT", aInsumo[nW,4],  NIL})
					aAdd(aAutoCab, {"ZGI_QTDE",   aInsumo[nW,5],  NIL})
					aAdd(aAutoCab, {"ZGI_UM",     aInsumo[nW,6],  NIL})
					aAdd(aAutoCab, {"ZGI_LOCAL",  aInsumo[nW,7],  NIL})
					aAdd(aAutoCab, {"ZGI_LOTECT", aInsumo[nW,8],  NIL})
					aAdd(aAutoCab, {"ZGI_ORIGEM", cRotCria	   ,  NIL})

					cMsgErro := oUtil:setExecAuto('ZGI', aAutoCab, 'ZGI_OP+ZGI_SEQUEN+ZGI_PRODUT+ZGI_LOCAL+ZGI_LOTECT', 3, 2)

				ElseIf aInsumo[nW, 9] $ "V/F" .And. !(cTipRec $ "M/N/B") // Fio diamantado não usa insumo.

					aAutoCab := {}

					aAdd(aAutoCab, {"ZGI_FILIAL", xFilial("ZGI"), NIL})
					aAdd(aAutoCab, {"ZGI_OP",     cNumOp,         NIL})
					aAdd(aAutoCab, {"ZGI_SEQUEN", aInsumo[nW,1],  NIL})
					aAdd(aAutoCab, {"ZGI_PRODUT", aInsumo[nW,4],  NIL})
					aAdd(aAutoCab, {"ZGI_QTDE",   aInsumo[nW,5],  NIL})
					aAdd(aAutoCab, {"ZGI_UM",     aInsumo[nW,6],  NIL})
					aAdd(aAutoCab, {"ZGI_LOCAL",  aInsumo[nW,7],  NIL})
					aAdd(aAutoCab, {"ZGI_LOTECT", aInsumo[nW,8],  NIL})
					aAdd(aAutoCab, {"ZGI_ORIGEM", cRotCria	   ,  NIL})

					cMsgErro := oUtil:setExecAuto('ZGI', aAutoCab, 'ZGI_OP+ZGI_SEQUEN+ZGI_PRODUT+ZGI_LOCAL+ZGI_LOTECT', 3, 2)

				ElseIf aInsumo[nW, 9] $ "D" .And. cTipRec $ "M/N/B"

					aAutoCab := {}
					cSeqLan  := Soma1(cSeqLan)

					aAdd(aAutoCab, {"ZS7_FILIAL", xFilial("ZS7"), NIL})
					aAdd(aAutoCab, {"ZS7_NUM",    cNumOp,         NIL})
					aAdd(aAutoCab, {"ZS7_SEQUEN", aInsumo[nW,1],  NIL})
					aAdd(aAutoCab, {"ZS7_SEQLAN", cSeqLan,        NIL})
					aAdd(aAutoCab, {"ZS7_PRODUT", aInsumo[nW,4],  NIL})
					aAdd(aAutoCab, {"ZS7_UM",     aInsumo[nW,6],  NIL})
					aAdd(aAutoCab, {"ZS7_LOCAL",  aInsumo[nW,7],  NIL})
					aAdd(aAutoCab, {"ZS7_LOTECT", aInsumo[nW,8],  NIL})

					cMsgErro := oUtil:setExecAuto('ZS7', aAutoCab, 'ZS7_NUM+ZS7_SEQUEN+ZS7_SEQLAN', 3, 1)

				ElseIf aInsumo[nW, 9] $ "L" .And. cTipRec $ "T"

					aAutoCab := {}
					cSeqLan  := Soma1(cSeqLan)

					aAdd(aAutoCab, {"ZS7_FILIAL", xFilial("ZS7"), NIL})
					aAdd(aAutoCab, {"ZS7_NUM",    cNumOp,         NIL})
					aAdd(aAutoCab, {"ZS7_SEQUEN", aInsumo[nW,1],  NIL})
					aAdd(aAutoCab, {"ZS7_SEQLAN", cSeqLan,        NIL})
					aAdd(aAutoCab, {"ZS7_PRODUT", aInsumo[nW,4],  NIL})
					aAdd(aAutoCab, {"ZS7_UM",     aInsumo[nW,6],  NIL})
					aAdd(aAutoCab, {"ZS7_LOCAL",  aInsumo[nW,7],  NIL})
					aAdd(aAutoCab, {"ZS7_LOTECT", aInsumo[nW,8],  NIL})

					cMsgErro := oUtil:setExecAuto('ZS7', aAutoCab, 'ZS7_NUM+ZS7_SEQUEN+ZS7_SEQLAN', 3, 1)

				EndIf

				If !Empty(cMsgErro)
					dDataBase := dDataOld
					DisarmTransaction()
					MsgStop(DecodeUTF8(cMsgErro))
					Return .F.
				EndIf

			Next

		EndIf


		aRet := u_validSD4(cNumOp)
		//Para esse caso, foi decidido que inicialmente vamos deixar somente como mensagem.
		If !(aRet[1])
			//DisarmTransaction()
			//RollBackSx8()
			ConOut(aRet[2])
			U_HELPMSG('Alerta',aRet[2])
			//Return .F.
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

		// If nOperation <> 5

		// 	For nX := 1 To nRegZH8

		// 		oModelZH8:GoLine(nX)

		// 		If Ascan(aLotes, {|x| AllTrim(x) == AllTrim(oModelZH8:GetValue('ZH8_LOTECT')) }) == 0

		// 			If !oModelZH8:IsDeleted()

		// 				cLotes += AllTrim(oModelZH8:GetValue('ZH8_LOTECT')) + ", "
		// 				aAdd(aLotes, AllTrim(oModelZH8:GetValue('ZH8_LOTECT')))

		// 			EndIf

		// 		EndIf

		// 	Next

		// 	If Len(cLotes) > 0
		// 		cLotes := SubStr(cLotes, 1, Len(cLotes)-2)
		// 	EndIf

		// 	oModel:SetValue('ZH7MASTER', 'ZH7_BLOCO',  cLotes)
		// 	oModel:SetValue('ZH7MASTER', 'ZH7_ENGENH', cEngenha)
		// 	oModel:SetValue('ZH7MASTER', 'ZH7_DESCEN', POSICIONE("ZG7", 1, XFILIAL("ZG7") + cEngenha, "ZG7_DESCRI"))

		// EndIf

		// FWFormCommit(oModel)

		dDataBase := dDataOld

	End Transaction

	If oUtil <> NIL
		oUtil:destroy()
	EndIf

	If lCheckKey
		MsgInfo("O número da OP foi alterada para " + cNumOp + "!")
	EndIf

Return lReturn

/*/{Protheus.doc} OrderSC2
Ordena SC2 para aceitar o msexecauto.
@type Static Function
@author Totvs Vitoria
@since 08/08/2019
@version version
/*/
Static Function OrderSC2(aArrayOld)

	Local aArrayNew := {}
	Local cTabela   := "SC2"
	Local nPosical  := 0

	nPosicao := aScan(aArrayOld, {|x| AllTrim(x[1]) == "C2_FILIAL"})
	If nPosicao > 0
		aAdd(aArrayNew, aArrayOld[nPosicao])
	EndIf

	nPosicao := aScan(aArrayOld, {|x| AllTrim(x[1]) == "C2_SEQUEN"})
	If nPosicao > 0
		aAdd(aArrayNew, aArrayOld[nPosicao])
	EndIf

	nPosicao := aScan(aArrayOld, {|x| AllTrim(x[1]) == "C2_ITEM"})
	If nPosicao > 0
		aAdd(aArrayNew, aArrayOld[nPosicao])
	EndIf

	nPosicao := aScan(aArrayOld, {|x| AllTrim(x[1]) == "C2_NUM"})
	If nPosicao > 0
		aAdd(aArrayNew, aArrayOld[nPosicao])
	EndIf

	SX3->(DbSetOrder(1))
	SX3->(DbSeek(cTabela))

	While SX3->(!Eof()) .And. SX3->X3_ARQUIVO == cTabela

		If !(AllTrim(SX3->X3_CAMPO) $ "C2_FILIAL / C2_NUM / C2_ITEM / C2_SEQUEN")
			nPosicao := aScan(aArrayOld, {|x| AllTrim(x[1]) == AllTrim(SX3->X3_CAMPO)})
			If nPosicao > 0
				aAdd(aArrayNew, aArrayOld[nPosicao])
			EndIf
		EndIf

		SX3->(DbSkip())
	EndDo

Return aArrayNew

/*/{Protheus.doc} ValidActiv
Valida ativação do model.
@type Static Function
@author kenny.martins
@since 24/10/2019
@version 1.0
/*/
Static Function ValidActiv(oModel)

	Local lReturn    := .T.
	Local nOperation := oModel:GetOperation()
	Local cMessage   := ""
	Local cSolution  := ""

	//-----------------------------------------------------
	// Caso a Ordem de Produção já tenha sido iniciada
	// não permite alterar.
	//-----------------------------------------------------
	If !( type("lRoti06")=="L".and. lRoti06) .and. ZH7->ZH7_SITUAC <> "P" .And. nOperation <> MODEL_OPERATION_INSERT .And. nOperation <> MODEL_OPERATION_VIEW

		lReturn   := .F.
		cMessage  := "Somente ordem de produção prevista pode ser alterada ou  excluída!"
		cSolution := "Utilize a operação de visualização."
		Help(NIL, NIL, "GRAOA038", NIL, cMessage ,1, 0, NIL, NIL, NIL, NIL, NIL, {cSolution})

	EndIf

Return lReturn

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

	Local aSelect     := {}
	Local oView       := FWViewActive()
	Local oModel      := FWModelActive()
	Local oModelZH8   := oModel:GetModel("ZH8DETAIL")
	Local oModelZH9   := oModel:GetModel("ZH9DETAIL")
	Local nX          := 0
	Local nPos        := 0
	Local aArrProd    := {}
	Local cGrupoRet   := AllTrim(GetNewPar("GR_GRUPORE", ""))
	Local cEngenharia := ""
	Local cProdAca    := ""
	Local cItem       := ""
	Local cProcesso   := oModel:GetValue('ZH7MASTER','ZH7_PROCES')
	Local cTipo       := ""
	Local lReturn     := .T.
	Local cExpSB8     := ""
	Local cExpSql     := ""
	Local aReturn     := {}
	Local cStringKey  := ""
	Local cProduto    := ""
	Local aTotais     := {}
	Local cMessage 	  := ""
	Local cSolution   := ""
	Local cAuxSol1    := ""
	Local cAuxSol2    := ""
	Local ny 		  := 0
	Local nHabQtdSld  := GETNEWPAR("GR_QTDSALD", 0) // Habilita se produto "LADRILHO/RECORTADO/AMOSTRA" deve buscar Qtd. do Saldo.
	Local aRetTppr    := strtokarr(GETNEWPAR("GR_TPPRODU", "E='P';S='B';R='C','A';O='B','C'"), ";")
	Local nPosiTp     := 0
	Local aVldMedB8	  := {}
	Local aExistPed	  := {}
	Local cMessagePed := ""
	Local cSolucaoPed := ""
	Local cMessageVld := ""
	Local cSolucaoVld := ""


	If cProcesso $ "E"
		nPosiTp := Ascan(aRetTppr, {|x| substr(x,1,1) == "E"})
		cTipo   := substr(aRetTppr[nPosiTp],3)
	ElseIf cProcesso $ "S"
		nPosiTp := Ascan(aRetTppr, {|x| substr(x,1,1) == "S"})
		cTipo   := substr(aRetTppr[nPosiTp],3)
	ElseIf cProcesso $ "R"
		nPosiTp := Ascan(aRetTppr, {|x| substr(x,1,1) == "R"})
		cTipo   := substr(aRetTppr[nPosiTp],3)
	Else
		//Para Else eu coloque a letra O no parametro.
		nPosiTp := Ascan(aRetTppr, {|x| substr(x,1,1) == "O"})
		cTipo   := substr(aRetTppr[nPosiTp],3)
	EndIf

	cExpSql := "     SELECT "
	cExpSql += "            SB8.B8_FILIAL,  "
	cExpSql += "            SB8.B8_LOCAL,   "
	cExpSql += "            SB8.B8_PRODUTO, "
	cExpSql += "            SB1.B1_DESC,    "
	cExpSql += "            SB8.B8_LOTECTL, "
	cExpSql += "            SB8.B8_NUMLOTE, "
	cExpSql += "            SB8.B8_LOTEFOR, "
	cExpSql += "            SB8.B8_SALDO,   "
	cExpSql += "            SB8.B8_YCAVALE, "
	cExpSql += "            SB8.B8_DATA,    "
	cExpSql += "            SB8.B8_DTVALID, "
	cExpSql += "            SB8.B8_YCLASSI, "
	cExpSql += "            SB8.B8_YCOMLIQ, "
	cExpSql += "            SB8.B8_YALTLIQ, "
	cExpSql += "            SB8.B8_YESPLIQ, "
	cExpSql += "            SB8.B8_YTOTLIQ, "
	cExpSql += "            SB8.B8_YCOMBRU, "
	cExpSql += "            SB8.B8_YALTBRU, "
	cExpSql += "            SB8.B8_YESPBRU, "
	cExpSql += "            SB8.B8_YTOTBRU  "
	cExpSql += "       FROM " + RetSqlName("SB8") + " SB8 (NOLOCK) "
	cExpSql += " INNER JOIN " + RetSqlName("SB1") + " SB1 (NOLOCK) "
	cExpSql += "         ON SB1.B1_FILIAL  = '" + xFilial("SB1") + "' "
	cExpSql += "        AND SB1.B1_COD     = SB8.B8_PRODUTO "
	cExpSql += "        AND SB1.B1_GRUPO	<> '" + cGrupoRet + "'"
	cExpSql += "        AND SB1.D_E_L_E_T_ = ' ' "
	cExpSql += " INNER JOIN " + RetSqlName("SBM") + " SBM (NOLOCK) "
	cExpSql += "         ON SBM.BM_FILIAL  = '" + xFilial("SBM") + "' "
	cExpSql += "        AND SBM.BM_GRUPO   = SB1.B1_GRUPO "
	cExpSql += "        AND SBM.BM_YTIPO  IN (" + cTipo + ") "
	cExpSql += "        AND SBM.D_E_L_E_T_ = ' ' "
	cExpSql += "      WHERE SB8.B8_FILIAL  = '" + xFilial("SB8") + "' "
	cExpSql += "        AND SB8.B8_SALDO   > 0  "
	cExpSql += "        AND SB8.B8_EMPENHO = 0  "
	cExpSql += "        AND SB8.B8_ORIGLAN <> 'BD' "
	cExpSql += "        AND SB8.D_E_L_E_T_ = ' ' "

	If ExistBlock("GROA38WHE")
		cExpSql += ExecBlock("GROA38WHE", .F., .F., {cExpSql})
	EndIf

	cExpSql += "   ORDER BY SB8.B8_FILIAL,  "
	cExpSql += "            SB8.B8_LOCAL,   "
	cExpSql += "            SB8.B8_PRODUTO, "
	cExpSql += "            SB8.B8_LOTECTL, "
	cExpSql += "            SB8.B8_NUMLOTE  "

	If ExistBlock("GR038SQL")
		cExpSql := ExecBlock("GR038SQL", .f., .f., { cExpSql,cProcesso,cGrupoRet,cTipo } )
	EndIf

	cSGBD := TCGetDB()

	//Somente para oracle para remover o nolock
	if (cSGBD $ "ORACLE")
		cExpSql := ChangeQuery(cExpSql)
	EndIf

	aAdd( aTotais, {"B8_FILIAL","COUNT","Contador","@E 999,999"} )
	aAdd( aTotais, {"B8_YTOTLIQ","SUM","Total Líquido",X3Picture( "B8_YTOTLIQ" )} )
	aAdd( aTotais, {"B8_YTOTBRU","SUM","Total Bruto"  ,X3Picture( "B8_YTOTBRU" )} )

	__aEngen := {}

	aSelect := U_GROCGEN("SB8", cExpSB8, "Estoque de Materiais GetProd", cExpSql, {"B8_FILIAL","B8_PRODUTO","B8_LOCAL","B8_LOTECTL","B8_NUMLOTE"}, .T., aTotais, 100)[2]

	For nX := 1 To Len(aSelect)

		cStringKey := ""
		cProduto   := ""

		For nY := 1 To Len(aSelect[nX])
			cStringKey += aSelect[nX][nY][2]
			If AllTrim(aSelect[nX][nY][1]) == "B8_PRODUTO"
				cProduto := aSelect[nX][nY][2]
			EndIf
		Next

		nPos := aScan(aArrProd, { |x| x[1] == cProduto })

		cEngenharia := ""
		cProdAca    := ""

		If nPos > 0 .And. oModelZH8:GetValue("ZH8_CODMAT") == cProduto
			cEngenharia := oModelZH8:GetValue("ZH8_ENGENH")
			cProdAca    := oModelZH9:GetValue("ZH9_CODPA")
		EndIf

		SB8->(DbSetOrder(3))

		If SB8->(DbSeek( cStringKey ))

			aExistPed := U_EXISTPED(SB8->B8_PRODUTO, SB8->B8_LOCAL, SB8->B8_LOTECTL, SB8->B8_NUMLOTE)

			If !aExistPed[1]
				cMessagePed += aExistPed[2]
				cSolucaoPed := aExistPed[3]
				loop
			EndIF

			aVldMedB8 := U_VLDMEDB8(cTipo)

			If !aVldMedB8[1]
				cMessageVld += aVldMedB8[2]
				cSolucaoVld := aVldMedB8[3]
				loop
			EndIF

			If !oModelZH8:isEmpty()
				oModelZH8:AddLine()
			EndIf

			aAdd(aArrProd, { cProduto })

			If !Empty(cEngenharia) .And. !Empty(cProdAca)
				__lAuto := .T.
			EndIf

			oModelZH8:SetValue('ZH8_CODMAT', SB8->B8_PRODUTO)
			oModelZH8:SetValue('ZH8_NUMLOT', SB8->B8_NUMLOTE)
			oModelZH8:SetValue('ZH8_LOTECT', SB8->B8_LOTECTL)
			oModelZH8:SetValue('ZH8_NUMLOT', SB8->B8_NUMLOTE)
			oModelZH8:SetValue('ZH8_LOCAL',  SB8->B8_LOCAL)

			If nHabQtdSld == 1
				cTipoGrupo := Posicione("SBM", 1, xFilial("SBM") + Posicione("SB1", 1, xFilial("SB1") + SB8->B8_PRODUTO, "B1_GRUPO"), "BM_YTIPO")

				If cTipoGrupo $ "L/A"
					oModelZH8:SetValue('ZH8_TOTLIQ', SB8->B8_SALDO)
				EndIf
			EndIf

			If !Empty(cEngenharia)
				__lAuto := .T.
				oModelZH8:SetValue('ZH8_ENGENH', cEngenharia)
			EndIf

			If !Empty(cProdAca)
				oModelZH9:SetValue('ZH9_CODPA', cProdAca)
			EndIf

			U_GRA038V3()

		EndIf

		oView:Refresh("VIEW_ZH8")
		oView:Refresh("VIEW_ZH9")

	Next

	If !empty(cMessagePed)
		U_HELPMSG(cSolucaoPed,cMessagePed)
	EndIf

	If !empty(cMessageVld)
		U_HELPMSG(cSolucaoVld,cMessageVld)
	EndIf
	//oModelZH8:GoLine(1) // removido estava dando problema na grid, ela não estava entendendo bem: https://totvsleste.freshdesk.com/a/tickets/7413

	// Local oModelCAL := oModel:GetModel('CALC_BORDETAIL')

	oView:Refresh("VIEW_CALC")
	oView:Refresh("VIEW_ZH8")
	oView:Refresh("VIEW_ZH9")

Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} ConvEsp
Converte espessura
@return Nil
@author Kenny Roger Martins
@since 31/10/2019
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function ConvEsp(nEspessura)

	If NoRound(nEspessura, 0) > 0

		nEspessura := nEspessura / 100

	EndIf

Return nEspessura

//-------------------------------------------------------------------
/*/{Protheus.doc} VALIDALOTR
Validando o lote para recortado
@return Nil
@author Kenny Roger Martins
@since 31/10/2019
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function VALIDALOTR(oModel)

	Local lRet	     := .T.
	Local cProcesso  := oModel:GetValue('ZH7MASTER','ZH7_PROCES')

	Local oModelZH8  := oModel:GetModel('ZH8DETAIL')
	Local oModelZH9  := oModel:GetModel('ZH9DETAIL')

	Local nX 	    := 0
	Local ny 	    := 0
	Local nRegZH8   := 0
	Local nRegZH9   := 0
	Local cVerLot   := ""

	if(cProcesso $ 'R')
		nRegZH8    := oModelZH8:Length()
		nRegZH9    := oModelZH9:Length()
		For nX := 1 To nRegZH8

			oModelZH8:GoLine(nX)
			nRegZH9    := oModelZH9:Length()

			If !oModelZH8:IsDeleted()

				For nY := 1 To nRegZH9
					oModelZH9:GoLine(nY)
					If !oModelZH9:IsDeleted()
						cVerLot := Posicione("SB1", 1, xFilial("SB1") + oModelZH9:GetValue("ZH9_CODPA"), "B1_RASTRO")

						If cVerLot == "N" .AND. !Empty(oModelZH9:GetValue("ZH9_LOTECT"))

							lRet   := .F.
							cMsg  := "Produto com Lote informado : " +  oModelZH9:GetValue("ZH9_CODPA")
							cSolu := "Retire o lote"
							Help(NIL, NIL, "GROA038 - PreGrava", NIL, cMsg ,1, 0, NIL, NIL, NIL, NIL, NIL, {cSolu})
							Return .F.

						ElseIf cVerLot <> "N"
							iF Empty(oModelZH9:GetValue("ZH9_LOTECT")) .OR. (cVerLot=="S" .AND. Empty(oModelZH9:GetValue("ZH9_NUMLOT")))
								lRet  := .F.
								cMsg  := "Produto com rastro "+cVerLot+" Lote ou SubLote em branco : " +  oModelZH9:GetValue("ZH9_CODPA")
								cSolu := "Informe o Lote ou Sublote conforme o valor do rastro"
								Help(NIL, NIL, "GROA038 - PreGrava", NIL, cMsg ,1, 0, NIL, NIL, NIL, NIL, NIL, {cSolu})
								Return .F.
							EndIf

						EndIf
					EndIf
				Next
			EndIf
		Next
	EndIF

Return lRet



//-------------------------------------------------------------------
/*/{Protheus.doc} VALIDLOTE
Validando o lote
https://totvsleste.freshdesk.com/a/tickets/2087

@return Nil
@author Pedro Luiz
@since 19/03/2021
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function VALIDLOTE(oModel)

	Local lRet	     := .T.
	Local cProcesso  := oModel:GetValue('ZH7MASTER','ZH7_PROCES')

	Local oModelZH8  := oModel:GetModel('ZH8DETAIL')
	Local oModelZH9  := oModel:GetModel('ZH9DETAIL')

	Local nX 	    := 0
	Local ny 	    := 0
	Local nRegZH8   := 0
	Local nRegZH9   := 0
	Local cVerLotPA := ""
	Local cVerLotMA := ""

	nRegZH8    := oModelZH8:Length()
	nRegZH9    := oModelZH9:Length()
	For nX := 1 To nRegZH8

		oModelZH8:GoLine(nX)
		nRegZH9    := oModelZH9:Length()
		cVerLotMA  := Posicione("SB1", 1, xFilial("SB1") + oModelZH8:GetValue("ZH8_CODMAT"), "B1_RASTRO")

		If !oModelZH8:IsDeleted()

			For nY := 1 To nRegZH9
				oModelZH9:GoLine(nY)
				If !oModelZH9:IsDeleted()
					cVerLotPA := Posicione("SB1", 1, xFilial("SB1") + oModelZH9:GetValue("ZH9_CODPA"), "B1_RASTRO")

					if(cProcesso $ 'B/T')
						If cVerLotPA <> cVerLotMA

							lRet   := .F.
							cMsg  := "MA com rastro diferente do Pa - Materia prima: " + oModelZH8:GetValue("ZH8_CODMAT") + " com rastro: " + cVerLotMA +" e o Produto acabado: " + oModelZH9:GetValue("ZH9_CODPA") + " com rastro: " + cVerLotPA
							cSolu := "Verifique o rastro dos produtos "
							Help(NIL, NIL, "GROA038 - PreGrava", NIL, cMsg ,1, 0, NIL, NIL, NIL, NIL, NIL, {cSolu})
							Return .F.

						EndIf
					ElseIf(cProcesso $ 'E')
						// Atenção:
						// Não entendi essa regra, pois a extração é feito com a MP sendo a pedreira,
						// que no caso não tem Lote

						// If cVerLotPA <> "L" .OR. cVerLotMA <>'L'

						// 	lRet   := .F.
						// 	cMsg  := "MA ou PA com rastro diferente de lote - Materia prima: " + oModelZH8:GetValue("ZH8_CODMAT") + " com rastro: " + cVerLotMA +" e o Produto acabado: " + oModelZH9:GetValue("ZH9_CODPA") + " com rastro: " + cVerLotPA
						// 	cSolu := "Verifique o rastro dos produtos "
						// 	Help(NIL, NIL, "GROA038 - PreGrava", NIL, cMsg ,1, 0, NIL, NIL, NIL, NIL, NIL, {cSolu})
						// 	Return .F.

						// EndIF

						If cVerLotPA <> "L"
							lRet   := .F.
							cMsg  := "No processo de extração o Prouto Acabado deve ser controlar por Lote."
							cSolu := "Verifique o rastro do produto"
							Help(NIL, NIL, "GROA038 - PreGrava", NIL, cMsg ,1, 0, NIL, NIL, NIL, NIL, NIL, {cSolu})
							Return .F.
						EndIF

					ElseIf(cProcesso $ 'S')
						If cVerLotPA <> "S" .OR. cVerLotMA <>'L'

							lRet   := .F.
							cMsg  := "MA com rastro diferente de lote ou PA diferente de SubLote - Materia prima: " + oModelZH8:GetValue("ZH8_CODMAT") + " com rastro: " + cVerLotMA +" e o Produto acabado: " + oModelZH9:GetValue("ZH9_CODPA") + " com rastro: " + cVerLotPA
							cSolu := "Verifique o rastro dos produtos "
							Help(NIL, NIL, "GROA038 - PreGrava", NIL, cMsg ,1, 0, NIL, NIL, NIL, NIL, NIL, {cSolu})
							Return .F.

						EndIF
					EndIf
				EndIf
			Next
		EndIf
	Next


Return lRet

/*/{Protheus.doc} User Function INSINDIR
	(long_description)
	Validar se o produto e insumo indireto
	Retorna .t. se for insumo indireto, .f. se não for insumo indireto
	@type  Function
	@author user
	@since 11/07/2022
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
	/*/
User Function INSINDIR(cProduto)

	Local lRet 		 := .f.
	Local cSql       := ""
	Local qQueryGR   := ""

	cSql := "    SELECT B1_COD  "
	cSql += "     FROM " + RetSqlName("SB1") + " SB1 "
	cSql += "    WHERE SB1.B1_FILIAL = '" + xFilial("SB1") + "' "
	cSql += "      AND SB1.B1_COD = '" + cProduto  + "' "
	cSql += "      AND SB1.D_E_L_E_T_ = ' ' "

	cSGBD := TCGetDB()

	if (cSGBD $ "ORACLE")
		cSql += "	   AND ( SB1.B1_CCCUSTO <> ' ' OR SUBSTR(SB1.B1_COD,1,3) = 'MOD' ) "
	Else
		cSql += "	   AND ( SB1.B1_CCCUSTO <> ' ' OR SUBSTRING(SB1.B1_COD,1,3) = 'MOD' ) "
	EndIf

	TCQUERY cSql NEW ALIAS qQueryGR

	qQueryGR->(DbGoTop())

	if qQueryGR->(!EOF())

		lRet = .T.

		qQueryGR->(DbSkip())

	Endif

	qQueryGR->(DbCloseArea())


Return lRet

/*/{Protheus.doc} User Function ATCAVZPB
	(long_description)
	Recria o cavalete na ZPB pelos itens da OP, resgatando os valores a partir da SB8.
	@type  Function
	@author Lucas Cunha de Souza
	@since 27/09/2022
	@version version
	@param cNumOp
	@return nill
	/*/

User Function ATCAVZPB(cNumOp)

	Local cCavalet := ""
	Local aCavalet := {}
	Local nC := 0
	Local cProdRet := ""
	Local cTagRet  := alltrim(GETNEWPAR("GR_SIGLARE", "R", xFilial("SB8")))

	SC2->(DbSetOrder(1))

	If	SC2->(MsSeek(xFilial("SC2") + cNumOp))

		While ((SC2->(!eof())) .AND. SC2->C2_FILIAL + SC2->C2_NUM == xFilial("SC2") + cNumOp)
			//Atualiza o Cavalete após a alteração de todos os Produtos Retrabalho na SB8
			If SC2->C2_YMP == SC2->C2_PRODUTO

				cCavalet := (Posicione("SB8", 3, xFilial("SB8") + SC2->C2_PRODUTO + SC2->C2_YLOCMP + SC2->C2_YLOTECT + SC2->C2_YNUMLOT, "B8_YCAVALE"))
				If SB8->B8_SALDO == 0
					cProdRet := Alltrim(SC2->C2_PRODUTO) + cTagRet + Space(Len(SC2->C2_PRODUTO) - Len(Alltrim(SC2->C2_PRODUTO)) - len(cTagRet))
					cCavalet := (Posicione("SB8", 3, xFilial("SB8") + cProdRet + SC2->C2_YLOCMP + SC2->C2_YLOTECT + SC2->C2_YNUMLOT, "B8_YCAVALE"))
				Endif

				If (AScan(aCavalet, cCavalet)) == 0
					aAdd(aCavalet, cCavalet)
				Endif
			Endif
			SC2->(dbSkip())
		EndDo
	Endif

	For nC := 1 to Len(aCavalet)
		If !Empty(aCavalet[nC])
			u_RECPZPB(aCavalet[nC])
		Endif
	Next

Return


 /*/{Protheus.doc} nomeFunction
	(long_description)
	@type  Function
	@author user
	@since 18/04/2023
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
	/*/
user Function PODERTER(cCod,cLocal,cLote,cNumLote)

	Local cSql 		:= ""
	Local qQeryTer  := ""
	Local lPoderTe  := .f.
	Local nQtdReg   := 0
	Local cCliTer   := ""
	Local cLojaTer  := ""

	cSql := "     SELECT COALESCE(B6_PRUNIT, 0) B6_PRUNIT, COALESCE(B6_QUANT, 0) B6_QUANT ,B6_CLIFOR, B6_LOJA "
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
	cSql += "        AND SD1.D1_COD     = '" + cCod     + "'"
	cSql += "        AND SD1.D1_LOCAL   = '" + cLocal   + "'"
	cSql += "        AND SD1.D1_LOTECTL = '" + cLote    + "'"
	cSql += "        AND SD1.D1_NUMLOTE = '" + cNumLote + "'"
	cSql += "        AND SD1.D_E_L_E_T_ = ' '"

	TCQUERY cSql NEW ALIAS qQeryTer

	If(qQeryTer->(!Eof()))
		lPoderTe := .T.
		cCliTer  := qQeryTer->B6_CLIFOR
		cLojaTer := qQeryTer->B6_LOJA
	EndIf

	qQeryTer->(DbCloseArea())

Return {lPoderTe,cCliTer,cLojaTer}

Static Function ValidaCampos()
	Local lReturn   := .T.
	Local aCampos   := {}
	Local aTamSX3   := {}
	Local aTamanho  := {}
	Local nI 			  := 0
	Local cMsg      := ""

	aAdd(aCampos, "A5_QUANT01")
	aAdd(aCampos, "AF2_QUANT")
	aAdd(aCampos, "AF3_QUANT")
	aAdd(aCampos, "AFA_QUANT")
	aAdd(aCampos, "AFC_QUANT")
	aAdd(aCampos, "B1_EMIN")
	aAdd(aCampos, "B1_ESTSEG")
	aAdd(aCampos, "B1_LE")
	aAdd(aCampos, "B1_LM")
	aAdd(aCampos, "B2_NAOCLAS")
	aAdd(aCampos, "B2_QACLASS")
	aAdd(aCampos, "B2_QATU")
	aAdd(aCampos, "B2_QEMP")
	aAdd(aCampos, "B2_QEMPN")
	aAdd(aCampos, "B2_QEMPN2")
	aAdd(aCampos, "B2_QFIM")
	aAdd(aCampos, "B2_QFIM2")
	aAdd(aCampos, "B2_QFIMFF")
	aAdd(aCampos, "B2_QNPT")
	aAdd(aCampos, "B2_QPEDVE2")
	aAdd(aCampos, "B2_QPEDVEN")
	aAdd(aCampos, "B2_QTER")
	aAdd(aCampos, "B2_QTNP")
	aAdd(aCampos, "B2_QTSEGUM")
	aAdd(aCampos, "B2_RESERV2")
	aAdd(aCampos, "B2_RESERVA")
	aAdd(aCampos, "B2_SALPEDI")
	aAdd(aCampos, "B3_MEDIA")
	aAdd(aCampos, "B3_Q01")
	aAdd(aCampos, "B6_QTSEGUM")
	aAdd(aCampos, "B6_QUANT")
	aAdd(aCampos, "B6_QULIB")
	aAdd(aCampos, "B6_SALDO")
	aAdd(aCampos, "B7_QTSEGUM")
	aAdd(aCampos, "B7_QUANT")
	aAdd(aCampos, "B7_YTOTBRU")
	aAdd(aCampos, "B7_YTOTLIQ")
	aAdd(aCampos, "B8_EMPENH2")
	aAdd(aCampos, "B8_EMPENHO")
	aAdd(aCampos, "B8_QACLAS2")
	aAdd(aCampos, "B8_QACLASS")
	aAdd(aCampos, "B8_QEMPPRE")
	aAdd(aCampos, "B8_QEPRE2")
	aAdd(aCampos, "B8_QTDORI")
	aAdd(aCampos, "B8_QTDORI2")
	aAdd(aCampos, "B8_SALDO")
	aAdd(aCampos, "B8_YQTDBD")
	aAdd(aCampos, "B8_YTOTBRU")
	aAdd(aCampos, "B8_YTOTLIQ")
	aAdd(aCampos, "B9_QINI")
	aAdd(aCampos, "B9_QISEGUM")
	aAdd(aCampos, "BC_QTDDES2")
	aAdd(aCampos, "BC_QTDDEST")
	aAdd(aCampos, "BC_QTSEGUM")
	aAdd(aCampos, "BC_QUANT")
	aAdd(aCampos, "BD_QFIM")
	aAdd(aCampos, "BD_QFIM2UM")
	aAdd(aCampos, "BD_QINI")
	aAdd(aCampos, "BD_QINI2UM")
	aAdd(aCampos, "BD_QT2UM")
	aAdd(aCampos, "BD_QUANT")
	aAdd(aCampos, "BF_EMPEN2")
	aAdd(aCampos, "BF_EMPENHO")
	aAdd(aCampos, "BF_QEMPPRE")
	aAdd(aCampos, "BF_QEPRE2")
	aAdd(aCampos, "BF_QTSEGUM")
	aAdd(aCampos, "BF_QUANT")
	aAdd(aCampos, "BH_QUANT")
	aAdd(aCampos, "BJ_QINI")
	aAdd(aCampos, "BJ_QISEGUM")
	aAdd(aCampos, "BK_QINI")
	aAdd(aCampos, "BK_QISEGUM")
	aAdd(aCampos, "BZ_EMIN")
	aAdd(aCampos, "BZ_ESTSEG")
	aAdd(aCampos, "BZ_LE")
	aAdd(aCampos, "BZ_LM")
	aAdd(aCampos, "C0_QTDELIM")
	aAdd(aCampos, "C0_QTDORIG")
	aAdd(aCampos, "C0_QTDPED")
	aAdd(aCampos, "C0_QUANT")
	aAdd(aCampos, "C1_QTSEGUM")
	aAdd(aCampos, "C1_QUANT")
	aAdd(aCampos, "C1_QUJE")
	aAdd(aCampos, "C2_PERDA")
	aAdd(aCampos, "C2_QTSEGUM")
	aAdd(aCampos, "C2_QTUPROG")
	aAdd(aCampos, "C2_QUANT")
	aAdd(aCampos, "C2_QUJE")
	aAdd(aCampos, "C2_YTOTBRU")
	aAdd(aCampos, "C2_YTOTITB")
	aAdd(aCampos, "C2_YTOTITL")
	aAdd(aCampos, "C2_YTOTLIQ")
	aAdd(aCampos, "C2_YTOTMP")
	aAdd(aCampos, "C3_QUANT")
	aAdd(aCampos, "C3_QUJE")
	aAdd(aCampos, "C4_QUANT")
	aAdd(aCampos, "C6_QTDEMP")
	aAdd(aCampos, "C6_QTDEMP2")
	aAdd(aCampos, "C6_QTDENT")
	aAdd(aCampos, "C6_QTDENT2")
	aAdd(aCampos, "C6_QTDLIB")
	aAdd(aCampos, "C6_QTDLIB2")
	aAdd(aCampos, "C6_QTDRESE")
	aAdd(aCampos, "C6_QTDVEN")
	aAdd(aCampos, "C6_SLDALIB")
	aAdd(aCampos, "C6_UNSVEN")
	aAdd(aCampos, "C6_YQTDORI")
	aAdd(aCampos, "C6_YQTDPRO")
	aAdd(aCampos, "C6_YTOTBRU")
	aAdd(aCampos, "C6_YTOTLIQ")
	aAdd(aCampos, "C7_QTDACLA")
	aAdd(aCampos, "C7_QTSEGUM")
	aAdd(aCampos, "C7_QUANT")
	aAdd(aCampos, "C7_QUJE")
	aAdd(aCampos, "C8_QTDCTR")
	aAdd(aCampos, "C8_QTSEGUM")
	aAdd(aCampos, "C8_QUANT")
	aAdd(aCampos, "C9_QTDLIB")
	aAdd(aCampos, "C9_QTDLIB2")
	aAdd(aCampos, "C9_QTDRESE")
	aAdd(aCampos, "CE_QUANT")
	aAdd(aCampos, "CK_QTDVEN")
	aAdd(aCampos, "CL_QTDVEN")
	aAdd(aCampos, "CL_QUANT")
	aAdd(aCampos, "CNB_QTDMED")
	aAdd(aCampos, "CNB_QTDORI")
	aAdd(aCampos, "CNB_QTRDAC")
	aAdd(aCampos, "CNB_QTRDRZ")
	aAdd(aCampos, "CNB_QTREAD")
	aAdd(aCampos, "CNB_QUANT")
	aAdd(aCampos, "CNB_SLDMED")
	aAdd(aCampos, "CNB_SLDREC")
	aAdd(aCampos, "CNE_QTAMED")
	aAdd(aCampos, "CNE_QTDORI")
	aAdd(aCampos, "CNE_QTDSOL")
	aAdd(aCampos, "CNE_QUANT")
	aAdd(aCampos, "CNS_DISTSL")
	aAdd(aCampos, "CNS_PRVQTD")
	aAdd(aCampos, "CNS_RLZQTD")
	aAdd(aCampos, "CNS_SLDQTD")
	aAdd(aCampos, "CNS_TOTQTD")
	aAdd(aCampos, "D1_QTDEDEV")
	aAdd(aCampos, "D1_QTDPEDI")
	aAdd(aCampos, "D1_QTSEGUM")
	aAdd(aCampos, "D1_QUANT")
	aAdd(aCampos, "D1_YTOTBRU")
	aAdd(aCampos, "D1_YTOTLIQ")
	aAdd(aCampos, "D2_QTDAFAT")
	aAdd(aCampos, "D2_QTDEDEV")
	aAdd(aCampos, "D2_QTSEGUM")
	aAdd(aCampos, "D2_QUANT")
	aAdd(aCampos, "D3_PERDA")
	aAdd(aCampos, "D3_QTSEGUM")
	aAdd(aCampos, "D3_QUANT")
	aAdd(aCampos, "D3_YTOTBRU")
	aAdd(aCampos, "D3_YTOTLIQ")
	aAdd(aCampos, "D3K_QTDE")
	aAdd(aCampos, "D4_QSUSP")
	aAdd(aCampos, "D4_QTDEORI")
	aAdd(aCampos, "D4_QTSEGUM")
	aAdd(aCampos, "D4_QUANT")
	aAdd(aCampos, "D4_SLDEMP")
	aAdd(aCampos, "D4_SLDEMP2")
	aAdd(aCampos, "D4_YQTDORI")
	aAdd(aCampos, "D5_QTSEGUM")
	aAdd(aCampos, "D5_QUANT")
	aAdd(aCampos, "D6_QUANT")
	aAdd(aCampos, "D7_QTDE")
	aAdd(aCampos, "D7_QTSEGUM")
	aAdd(aCampos, "D7_SALDO")
	aAdd(aCampos, "D7_SALDO2")
	aAdd(aCampos, "D8_QFIMDEV")
	aAdd(aCampos, "D8_QT2UM")
	aAdd(aCampos, "D8_QTDDEV")
	aAdd(aCampos, "D8_QUANT")
	aAdd(aCampos, "DA_EMP2")
	aAdd(aCampos, "DA_EMPENHO")
	aAdd(aCampos, "DA_QTDORI")
	aAdd(aCampos, "DA_QTDORI2")
	aAdd(aCampos, "DA_QTSEGUM")
	aAdd(aCampos, "DA_SALDO")
	aAdd(aCampos, "DB_EMP2")
	aAdd(aCampos, "DB_EMPENHO")
	aAdd(aCampos, "DB_QTDLID")
	aAdd(aCampos, "DB_QTDORI")
	aAdd(aCampos, "DB_QTSEGUM")
	aAdd(aCampos, "DB_QUANT")
	aAdd(aCampos, "DC_QTDORIG")
	aAdd(aCampos, "DC_QUANT")
	aAdd(aCampos, "DD_QTDORIG")
	aAdd(aCampos, "DD_QTSEGUM")
	aAdd(aCampos, "DD_QUANT")
	aAdd(aCampos, "DD_SALDO")
	aAdd(aCampos, "DD_SALDO2")
	aAdd(aCampos, "DHQ_QTORI")
	aAdd(aCampos, "DHQ_QTREC")
	aAdd(aCampos, "DT_QUANT")
	aAdd(aCampos, "EE8_QTDFIX")
	aAdd(aCampos, "EE8_QTDLOT")
	aAdd(aCampos, "EE8_SLDATU")
	aAdd(aCampos, "EE8_SLDINI")
	aAdd(aCampos, "EE8_YTOTBR")
	aAdd(aCampos, "EE8_YTOTLI")
	aAdd(aCampos, "EE9_QE")
	aAdd(aCampos, "EE9_QT_AC")
	aAdd(aCampos, "EE9_SALISE")
	aAdd(aCampos, "EE9_SLDINI")
	aAdd(aCampos, "EEK_QTDE")
	aAdd(aCampos, "EEO_QTDE")
	aAdd(aCampos, "EES_QTDE")
	aAdd(aCampos, "EX8_SLDATU")
	aAdd(aCampos, "EX8_SLDINI")
	aAdd(aCampos, "EXR_QE")
	aAdd(aCampos, "EXR_QTDEMB")
	aAdd(aCampos, "EXR_SLDINI")
	aAdd(aCampos, "EXS_QTD")
	aAdd(aCampos, "EXS_QTDEMB")
	aAdd(aCampos, "EXS_QTDVND")
	aAdd(aCampos, "EXT_QTD")
	aAdd(aCampos, "EXU_QTD")
	aAdd(aCampos, "EXV_QTD")
	aAdd(aCampos, "EY5_SLDATU")
	aAdd(aCampos, "EY5_SLDINI")
	aAdd(aCampos, "EY6_SLDINI")
	aAdd(aCampos, "EY6_SLDINI")
	aAdd(aCampos, "EY7_SLDINI")
	aAdd(aCampos, "G1_QUANT")
	aAdd(aCampos, "G4_QUANT")
	aAdd(aCampos, "H6_PERDANT")
	aAdd(aCampos, "H6_QTDPER")
	aAdd(aCampos, "H6_QTDPERD")
	aAdd(aCampos, "H6_QTDPRO2")
	aAdd(aCampos, "H6_QTDPROD")
	aAdd(aCampos, "H8_QUANT")
	aAdd(aCampos, "HC_QUANT")
	aAdd(aCampos, "HD_QUANT")
	aAdd(aCampos, "J3_QUAO01")
	aAdd(aCampos, "J3_QUAR01")
	aAdd(aCampos, "L2_QUANT")
	aAdd(aCampos, "L3_QUANT01")
	aAdd(aCampos, "UB_QUANT")
	aAdd(aCampos, "ZG9_QTDE")
	aAdd(aCampos, "ZGA_QTDE")
	aAdd(aCampos, "ZGB_QTDE")
	aAdd(aCampos, "ZGI_QTDE")
	aAdd(aCampos, "ZGM_QTDTOT")
	aAdd(aCampos, "ZGM_TOTBRU")
	aAdd(aCampos, "ZGM_TOTLIQ")
	aAdd(aCampos, "ZGO_MEDID2")
	aAdd(aCampos, "ZGO_MEDIDA")
	aAdd(aCampos, "ZGP_QUANT")
	aAdd(aCampos, "ZH1_SALDO")
	aAdd(aCampos, "ZH1_TOTBRU")
	aAdd(aCampos, "ZH1_TOTLIQ")
	aAdd(aCampos, "ZH2_SALDO")
	aAdd(aCampos, "ZH2_TOTBRU")
	aAdd(aCampos, "ZH2_TOTLIQ")
	aAdd(aCampos, "ZH3_SALDO")
	aAdd(aCampos, "ZH3_TOTBRU")
	aAdd(aCampos, "ZH3_TOTLIQ")
	aAdd(aCampos, "ZH8_TOTBRU")
	aAdd(aCampos, "ZH8_TOTLIQ")
	aAdd(aCampos, "ZH8_TOTORI")
	aAdd(aCampos, "ZH9_TOTBRU")
	aAdd(aCampos, "ZH9_TOTLIQ")
	aAdd(aCampos, "ZHA_QUANT")
	aAdd(aCampos, "ZHG_TOTBRU")
	aAdd(aCampos, "ZHG_TOTLIQ")
	aAdd(aCampos, "ZHH_QUANT")
	aAdd(aCampos, "ZP2_QUANTI")
	aAdd(aCampos, "ZP2_TOTBRU")
	aAdd(aCampos, "ZP2_TOTLIQ")
	aAdd(aCampos, "ZPA_QUANTI")
	aAdd(aCampos, "ZPA_TOTBRU")
	aAdd(aCampos, "ZPA_TOTLIQ")
	aAdd(aCampos, "ZPB_TOTBRU")
	aAdd(aCampos, "ZPB_TOTLIQ")
	aAdd(aCampos, "ZH9_QTDSEG")
	aAdd(aCampos, "ZGM_QTDSEG")

	cMsg := "Encontrado campo de Quantidade e/ou Total com tamanhos diferente!" + Chr(13) + Chr(10)
	cMsg += "Verifique tamanho dos seguintes campos no dicionário :" + Chr(13) + Chr(10) + Chr(13) + Chr(10)

	For nI := 1 To Len(aCampos)
		aTamSX3 := TamSX3(aCampos[nI])

		If Len(aTamSX3) > 0
			If Len(aTamanho) == 0
				aTamanho := aTamSX3
			EndIf

			If aTamSX3[1] != aTamanho[1] .Or. aTamSX3[2] != aTamanho[2]
				cMsg += aCampos[nI] + Chr(13) + Chr(10)
				lReturn := .F.
			EndIf
		EndIf
	Next

	If !lReturn
		U_HELPMSG("Tamanho Campos", cMsg)
	EndIf

Return lReturn


/*/{Protheus.doc} User Function REGBLQ
	(long_description)
	Função para verificar se o registro esta bloqueado, ele apresenta a mensagem de registro bloqueado. 

	@type  Function
	@author user
	@since 24/07/2023
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
	/*/
User Function REGBLQ(cTabela,nIndic,cDadoPes,cMsg)

	DEFAULT cMsg := ""

	(cTabela)->(dbSetOrder(nIndic))

	If (cTabela)->(dbSeek(cDadoPes))
		while !(cTabela)->(RLock((cTabela)->(RecNo())))

			if EMPTY( cMsg )
				cMsg := "O registro numero " + cValtochar((cTabela)->(RecNo())) +" do arquivo "+cTabela
				cMsg += " encontra se bloqueado por outro usuario."+CHR(13)+CHR(10)
				cMsg += "" +CHR(13)+CHR(10)
				cMsg += "Essa mensagem sera fechada em 10 segundos."+CHR(13)+CHR(10)
				cMsg += "Deseja tentar novamente ?"
			EndIf

			nOpcAv := U_MsgTimer(10, cMsg, "Registro bloqueado", "FWSKIN_ALERT_ICO.PNG", 1)
			//O aviso não aparecia na tela do GROA044, devido a isso não foi possivel utilizar ele.
			//nOpcAv := Aviso("Registro bloqueado ", cMsg, { "Não", "Sim"},3/*tamanho da tela 1,2,3*/,,,,,10/*tempo segundos*/,2)

			If nOpcAv
				Sleep(12000)
			else
				(cTabela)->(DbCloseArea())
				Return .T.
			EndIf

		Enddo
	EndIF

	(cTabela)->(DbCloseArea())

Return .F.

/*/{Protheus.doc} validSD4
(long_description)
Função criada para validar SD4. A ideia e verificar se o valor informado na ZH8 esta sendo totalmente empenhado na SD4. 
Para essa validação, nos pegamos o total liquido da ZH8 e comparamos com a soma da SD4 para aquele ZH8.
@type user function
@author Pedro Luiz
@since 07/06/2024
@version version
@param param_name, param_type, param_descr
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function validSD4(cNumOp)

	Local lRet      := .T.
	Local cMensage  := ""
	Local qSQueZH8  := ""
	Local cSql      := ""
	Local nQuantMp  := 0  // Total da materia prima ZH8
	Local nQuantPa  := 0  // Total do produto acabado SD4
	Local cCodMp    := "" //codigo para para o produto normal.
	Local cCodMpRe  := "" //codigo para retrabalho
	Local cSiglaRet := AllTrim(GetNewPar("GR_SIGLARE", "R"))
	Local cFile     := "\grplus\" + cNumOp + ".txt" //O sistema vai salvar o erro dentro da pasta: \protheus_data\grplus\
	Local lAtivSD4 := GetNewPar("GR_VALSD4", .F.) // parametro que valida SD4. FALSO ele não valida. true ele valida se os empenhos estão ficando corretos.

	If !lAtivSD4
		Return {lRet,cMensage}
	EndIf

	ZH8->(DbSetOrder(1))

	If ZH8->(MsSeek(xFilial("ZH8") + cNumOp))

		While ZH8->(!eof()) .and. ZH8->ZH8_FILIAL + ZH8->ZH8_NUM == xFilial("ZH8") + cNumOp

			nQuantMp := ZH8->ZH8_TOTLIQ
			cCodMp   := ZH8->ZH8_CODMAT
			cCodMpRe := AllTrim(cCodMp) + cSiglaRet + Space(TamSx3("B1_COD")[1] - Len(AllTrim(cCodMp) + cSiglaRet))

			cSql := " SELECT SUM(D4_QUANT) TOTALSD4"
			cSql += "   FROM " + RetSqlName("SD4") + " SD4 "
			cSql += " WHERE"
			cSql += "    SD4.D4_FILIAL   	 = '" + xFilial("SD4")  + "' "
			cSql += "    AND SD4.D4_OP    LIKE '" + cNumOp 		    + "%'"
			cSql += "    AND "
			cSql += "    ( "
			cSql += "    	SD4.D4_COD   	 = '" + cCodMp 		    + "'"
			cSql += "    	OR SD4.D4_COD    = '" + cCodMpRe 		+ "'"
			cSql += "    ) "
			cSql += "    AND SD4.D4_LOCAL    = '" + ZH8->ZH8_LOCAL  + "'"
			cSql += "    AND SD4.D4_LOTECTL  = '" + ZH8->ZH8_LOTECT + "'"
			cSql += "    AND SD4.D4_NUMLOTE  = '" + ZH8->ZH8_NUMLOT + "'"
			cSql += "    AND SD4.D_E_L_E_T_ = ' '"

			TCQUERY cSql NEW ALIAS qSQueZH8

			nQuantPa := 0

			If qSQueZH8->(!eof())

				nQuantPa :=	qSQueZH8->TOTALSD4

				qSQueZH8->(DbSkip())

			EndIf

			qSQueZH8->(DbCloseArea())

			If nQuantPa > 0 .And. nQuantMp <> nQuantPa
				lRet 	 := .f.

				cMensage += chr(10)
				cMensage += "Op: "      		+ cNumOp 	      	   + chr(10)
				cMensage += "Item: "    		+ ZH8->ZH8_ITEM   	   + chr(10)
				cMensage += "Produto empenho: " + cCodMp 	  	  	   + chr(10)
				cMensage += "Local: "   		+ ZH8->ZH8_LOCAL  	   + chr(10)
				cMensage += "Lote: "    		+ ZH8->ZH8_LOTECT 	   + chr(10)
				cMensage += "Sublote: " 		+ ZH8->ZH8_NUMLOT 	   + chr(10)
				cMensage += "Quantidade SB8: " 	+ cvaltochar(nQuantMp) + chr(10)
				cMensage += "Total empenho: " 	+ cvaltochar(nQuantPa) + chr(10)

			EndIf

			ZH8->(dbSkip())

		EndDo

	EndIf

	If !EMPTY(cMensage)

		cMensage := "Sistema encontrou divergencia na soma dos empenhos item ZH8 com SD4" + chr(10);
			+"Favar alterar a op novamente e verificar se a mensagem continua."+ chr(10);
			+"Caso continue, favor abrir um ticket na equipe da central de soluções TOTVSES."+ chr(10);
			+ chr(10) + cMensage

		nHandle  := FCREATE(cFile)

		if nHandle = -1
			cMsErro := "Erro ao criar arquivo - TotvesEs" + Str(Ferror())
			ConOut(cMsErro)
		else

			FWrite(nHandle, cMensage)
			FClose(nHandle)

		endif

	EndIf

Return {lRet,cMensage}


/*/{Protheus.doc}
(long_description)
@type user function
@author user
@since 25/04/2025
@version version
@param param_name, param_type, param_descr
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function GRROTE(cEngen,cProd)
	Local cCodAlt   := ""
	Local lRet      := .F.
	Local qQueryGR

	//Nessa query verifica se ja existe o produto para essa engenharia cadastrada. // Caso não exista ele inclui.
	cSql := u_RETSQLRO(cEngen,cProd)

	TCQUERY cSql NEW ALIAS qQueryGR

	While qQueryGR->(!(Eof()))

		cCodAlt   := qQueryGR->G2_CODIGO
		lRet      := .T.

		qQueryGR->(DbSkip())

	EndDo

	qQueryGR->(DbCloseArea())

Return {lRet,cCodAlt}

/*/{Protheus.doc} nomeStaticFunction
	(long_description)
	Função para validar os dados da SB8 antes da op ser criada.
	@type  Static Function
	@author user
	@since 19/09/2025
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
/*/
Static Function GRLIDSB8(oModel)

	Local aRet	     :={.T.,""}
	Local oModelZH8  := oModel:GetModel('ZH8DETAIL')
	Local oModelZH7  := oModel:GetModel("ZH7MASTER")
	Local dEmissao 	 := oModelZH7:GetValue("ZH7_EMISSA")
	Local nRegZH8    := oModelZH8:Length()
	Local nX 	     := 0
	Local cMensage   := ""

	For nX := 1 To nRegZH8

		oModelZH8:GoLine(nX)

		If oModelZH8:IsDeleted()
			Loop
		EndIf

		SB8->(DbSetOrder(3))

		If SB8->(DbSeek(xFilial("SB8") + oModelZH8:GetValue('ZH8_CODMAT') + oModelZH8:GetValue('ZH8_LOCAL') + oModelZH8:GetValue('ZH8_LOTECT') + oModelZH8:GetValue('ZH8_NUMLOT')))

			If SB8->B8_DATA > dEmissao

				cMensage += "Materia prima: " + Alltrim(oModelZH8:GetValue('ZH8_CODMAT')) + " Armazem:" + alltrim(oModelZH8:GetValue('ZH8_LOCAL')) + " Lote:" + alltrim(oModelZH8:GetValue('ZH8_LOTECT')) + " SubLote:" + alltrim(oModelZH8:GetValue('ZH8_NUMLOT'))+ CHR(13)+ CHR(13)
				cMensage += "A data da materia prima " + U_FORMTADT(SB8->B8_DATA)  +" é menor que a data da Ordem de produção  " + U_FORMTADT(dEmissao)  +" . A Ordem de produção não pode ser criada com data de emissão(ZH7_EMISSA) anterior a materia prima existir."+ CHR(13) + CHR(10)
				cMensage += "Solução: Altere a data da Ordem de produção " + U_FORMTADT(dEmissao)  +" para uma data posterior a materia prima " + U_FORMTADT(SB8->B8_DATA)  + CHR(13) + CHR(10)
				aRet := {.f.,cMensage}

			EndIf
		EndIf
	NEXT

Return aRet
