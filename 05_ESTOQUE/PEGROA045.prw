#include "topconn.ch"
#include "totvs.ch"

User Function UGROA045()
/**************************************************************************************************************
*
*
***/
Local aArea := GetArea()
Local aParam       := PARAMIXB
Local lRet         := .T.
Local nret         := 0
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
	EndIf
EndIf

RestArea(aArea)
//Final deo programa
Return lRet

Static Function ftempoS()
/**************************************************************************************************************
*
*
***/
Local aArea := GetArea()
Local nret  := 0

DbSelectArea("ZGH")
DbSetOrder(1)
DbSeek(xFilial("ZGH")+ZH7->ZH7_NUM)
Do while !Eof() .and. ZGH_FILIAL == xFilial("ZGH") .and. ZGH_OP == ZH7->ZH7_NUM
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
	
csql := " SELECT ZGH_TOTHOR"
csql += " from " + RetSqlName("ZGH")+" ZGH WITH(NOLOCK) "
csql +=  " where ZGH.ZGH_FILIAL =  '"+xFilial("ZGH")+"' "
csql +=  " and ZGH.ZGH_OP = '" + ZH7->ZH7_NUM +"'"
csql +=  " and ZGH.D_E_L_E_T_ = ' '  "

TcQuery csql New Alias "ctrabalho"
DbGotop()
	
Do while !Eof()
	nret :=  SomaHoras( nret, ctrabalho->ZGH_TOTHOR )
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

Return(ABS(nret))
