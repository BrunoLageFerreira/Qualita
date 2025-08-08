#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "PARMTYPE.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#Include 'TBICONN.ch'
//----------------------------------------------------------
/*/{Protheus.doc} GROA064
Rotina para chamar o MATA300. O padrão esta retirando o B8_ORIGLAN, 
e não foi possivel encontrar um ponto de entrada na finalização do processo para atender a demanda.

@type User Function
@author Pedro luiz
@since 09/03/2021
@version version
/*/
//----------------------------------------------------------
User Function GROA064()

	Local nB8Bundle := GetNewPar("GR_B8BUNDL", 0) // parametro igual a 2 o sublote e igual ao cavalete. o parametro igual a 1 o lote e igual ao BUND + CAVALETE
	Local cSql      := ""
	Local nStatus   := 0
	Local cMsgErro  := ""
	Local cFunBkp := FunName()

	SETFUNNAME("MATA300")
	MATA300()
	SETFUNNAME(cFunBkp)

	If nB8Bundle == 2 //.AND.  alltrim(SB8->B8_NUMLOTE) == ALLTRIM(SB8->B8_YCAVALE) .AND. SB8->B8_YCAVALE <> ' '

		cSql := " UPDATE " + RetSqlName("SB8")
		cSql += "    SET B8_ORIGLAN = 'BD' "
		cSql += "  WHERE
		cSql += "    B8_NUMLOTE = B8_YCAVALE "
		cSql += "    AND B8_YCAVALE <> ' ' "
		cSql += "    AND B8_ORIGLAN  = ' ' "
		cSql += "    AND D_E_L_E_T_ = ' ' "

		nStatus := TCSqlExec(cSql)

		If (nStatus < 0)
			cMsgErro := "M300SB8 => nB8Bundle = 2 TCSQLError: " + TCSQLError()
			ConOut(cMsgErro)
			MsgStop(cMsgErro)
			Return Nil
		EndIf

	ElseIf nB8Bundle == 1 //.AND.  alltrim(SB8->B8_LOTECTL) == "BUND" + ALLTRIM(SB8->B8_YCAVALE) .AND. SB8->B8_YCAVALE <> ' '

		cSql := " UPDATE " + RetSqlName("SB8")
		cSql += "    SET B8_ORIGLAN = 'BD' "
		cSql += "  WHERE
		cSql += "     TRIM(B8_LOTECTL) = 'BAND'  + TRIM(B8_YCAVALE) "
		cSql += "     AND B8_YCAVALE <> ' ' "
		cSql += "     AND B8_ORIGLAN  = ' ' "
		cSql += "     AND D_E_L_E_T_  = ' ' "

		nStatus := TCSqlExec(cSql)

		If (nStatus < 0)
			cMsgErro := "M300SB8 => nB8Bundle = 1 TCSQLError: " + TCSQLError()
			ConOut(cMsgErro)
			MsgStop(cMsgErro)
			Return Nil
		EndIf
	EndIF

Return nil
