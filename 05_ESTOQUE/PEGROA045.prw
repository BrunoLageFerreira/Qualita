#include "topconn.ch"
#include "totvs.ch"

/*
{Protheus.doc} UGROA045
@Author  (TOTVS) / Bruno Lage/ Arlindo
@since 04/11/2022
@version 1.0
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
			DbSelectArea("ZGI")
			DbSkip()
		EndDo
	ElseIf cIdPonto == 'MODELPOS'

				oModeLZGH := oModel:GetModel("ZGHDETAIL") 
				//Local oModelZGH := oModel:GetModel("ZGHDETAIL") // Operações
				//Local oModelSH6 := oModel:GetModel("SH6DETAIL") // Paradas - Hora improdutiva
				//Local oModelZGI := oModel:GetModel("ZGIDETAIL") // Insumos
				//Local oModelMOD := oModel:GetModel("MODDETAIL") // Custo indireto
				//Local oModelZGK := oModel:GetModel("ZGKDETAIL") // Mão-de-Obra
				//Local oModelZGL := oModel:GetModel("ZGLDETAIL") // Ferramenta
				//Local oModelZHL := oModel:GetModel("ZGLDETAIL") // Operações x Produto Acabado

				For nI := 1 to oModeLZGH:length()
					oModelZGH:GoLine(nI)
						
					oModelZGI := oModel:GetModel("ZGIDETAIL")
					oView := FwViewactive()
					For nX := 1 To oModeLZGI:Length()
						oModeLZGI:GoLine(nX)
						//Aqui estamos prercorrendo os insumos da operação
						If !(oModelZGI:IsDeleted())
							lRet := u_UGR045V(oModeLZGI:GetValue("ZGI_PRODUT"),oModeLZGI:GetValue("ZGI_LOCAL"),oModeLZGI:GetValue("ZGI_QTDE"))
							If  lRet == .F.
								//FwFldPut("ZGI_QTDE", 0,nX,oModeLZGI)
								oModeLZGI:SetValue("ZGI_QTDE",0)
							EndIf
						EndIf
						//cCodProd := oModeLZGI:GetValue("ZGI_PRODUT")
						//Alert("Teste para mostrar os produtos de insumo"+cCodProd)
					Next
					oModeLZGI:GoLine(1)
					oView:Refresh("ZGIDETAIL")
				Next

			//if MsgYesNo("Deseja cotinuar ?")
			//	lRet := .f.
			//EndIF
	EndIf

EndIf

RestArea(aArea)
//Final deo programa
Return(lRet)


User Function UGR045V(cCodPro,cCodDep,nQtd)
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
	Alert("Quantidade indisponível!")
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
