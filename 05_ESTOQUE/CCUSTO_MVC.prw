#Include "TOTVS.ch"
#Include "FWMVCDEF.ch"
/*
{Protheus.doc} CCUSTO_MVC
rotina cadastro valor centro de custos
@author Nilton (TOTVS)
@since 14/07/2022
@version 1.0
*/
User Function CCUSTO_MVC()
	Local oBrowse := FwLoadBrw("CCUSTO_MVC")
	oBrowse:Activate()
Return (NIL)
/*
{Protheus.doc} BrowseDef
@author Nilton (TOTVS)
@since 14/07/2022
@version 1.0
*/
Static Function BrowseDef()
	Local oBrowse := FwMBrowse():New()
	oBrowse:SetAlias("SZF")
	oBrowse:SetDescription("Periodo")
	oBrowse:SetMenuDef("CCUSTO_MVC")
Return (oBrowse)
/*
{Protheus.doc} MenuDef
@author Nilton (TOTVS)
@since 14/07/2022
@version 1.0
*/
Static Function MenuDef()
	Local aRotina := FwMVCMenu("CCUSTO_MVC")
Return (aRotina)
/*
{Protheus.doc} ModelDef
@author Nilton (TOTVS)
@since 14/07/2022
@version 1.0
*/
Static Function ModelDef()
	Local oModel   := MPFormModel():New("CCUSTOM")
	Local oStruSZF := FwFormStruct(1, "SZF")
	Local oStruSZG := FwFormStruct(1, "SZG")
	oModel:AddFields("SZFMASTER", NIL, oStruSZF)
	oModel:AddGrid("SZGDETAIL", "SZFMASTER", oStruSZG)
	oModel:SetRelation("SZGDETAIL", {{"ZG_FILIAL", "FwXFilial('SZG')"}, {"ZG_PERIODO", "ZF_PERIODO"}}, SZG->(IndexKey( 1 )))
	oModel:SetDescription("Centros de Custos" )
	oModel:GetModel("SZFMASTER"):SetDescription("Periodo")
	oModel:GetModel("SZGDETAIL"):SetDescription("Centros de Custos")
	oModel:SetPrimaryKey( {"ZF_FILIAL","ZF_PERIODO"} )
	oModel:GetModel( 'SZGDETAIL' ):SetUniqueLine( { 'ZG_CCUSTO' } )
Return (oModel)
/*
{Protheus.doc} ViewDef
@author Nilton (TOTVS)
@since 14/07/2022
@version 1.0
*/
Static Function ViewDef()
	Local oView := FwFormView():New()
	Local oStruSZF := FwFormStruct(2, "SZF")
	Local oStruSZG := FwFormStruct(2, "SZG")
	Local oModel := FwLoadModel("CCUSTO_MVC")
	oStruSZG:RemoveField("ZG_PERIODO")
	oView:SetModel(oModel)
	oView:AddField("VIEW_SZF", oStruSZF, "SZFMASTER")
	oView:AddGrid("VIEW_SZG", oStruSZG, "SZGDETAIL")
	oView:CreateHorizontalBox("SUPERIOR", 20)
	oView:CreateHorizontalBox("INFERIOR", 80)
	oView:SetOwnerView("VIEW_SZF", "SUPERIOR")
	oView:SetOwnerView("VIEW_SZG", "INFERIOR")
	oView:EnableTitleView("VIEW_SZG","Centros de Custos")
	oView:AddUserButton("Busca centros de custos [Ctrl+T]","",{|| fconCC(oView,omodel)},,K_CTRL_T,{MODEL_OPERATION_INSERT,MODEL_OPERATION_UPDATE})
Return (oView)
/*
{Protheus.doc} fconCC
@author Nilton (TOTVS)
@since 14/07/2022
@version 1.0
*/
Static Function fconCC(oview,omodel)
	Local oModelSZG  := oModel:GetModel("SZGDETAIL")
	Local aretorno   := {}
	Local ncont      := 0
	Local cfiltro    := ""
	DbSelectArea("SB1")
	cfiltro := "@B1_FILIAL = '"+xFilial("SB1")+"'"
	cfiltro += " and D_E_L_E_T_ = ' ' "
	cfiltro += " and B1_CCCUSTO <> ' '" 
	Set Filter to &(cfiltro)
	DbGotop()
	Do While !Eof()
		If Ascan(aretorno,Alltrim(SB1->B1_CCCUSTO)) == 0
			Aadd(aretorno,Alltrim(SB1->B1_CCCUSTO))
		EndIf 
		DbSkip()
	EndDo 
	Set filter to
	ASort(aretorno) 	
	If Len(aRetorno) > 0
		For ncont := 1 to Len(aRetorno)
			If !oModelSZG:SeekLine( {{"ZG_CCUSTO",aRetorno[ncont]}}, .F./*lDeleted*/, .T. /*lLocate*/ )
				oModelSZG:addline()
				oModelSZG:SetValue('ZG_CCUSTO',  aRetorno[ncont])
			EndIf	
		Next
	EndIf
	oModelSZG:Goline(1)
	oView:Refresh()
Return
