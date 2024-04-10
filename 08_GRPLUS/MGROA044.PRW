#Include "Totvs.ch"
#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
#INCLUDE "topconn.ch"

/*

*/
USER FUNCTION MGROA044()
**********************************************************************************************
*
*
*****
Local aArea        := GetArea()
Local aParam       := PARAMIXB
Local lRet         := .T.
Local nret         := 0
Local nI           := 0
Local nX           := 0
Local oModel       := FWModelActive()
Local oModeLZGM

Private oObj       := ''
Private cIdPonto   := ''
Private cIdModel   := ''

If aParam <> NIL
	oObj       := aParam[1]
	cIdPonto   := aParam[2]
	cIdModel   := aParam[3]

	If cIdPonto == 'MODELCOMMITNTTS'


	ElseIf cIdPonto == 'MODELPOS'
		oModeLZGM := oModel:GetModel("ZGMDETAIL")

		For nI := 1 to oModeLZGM:length()
			//valida a primeira linha do apontamento para verificar a data do estoque
			oModeLZGM:GoLine(nI)
			IF Empty(oModeLZGM:GetValue("ZGM_CLASSI") )
				Alert("Existe classificação em branco! Favor informar uma classificação antes de salvar!")
				lRet := .f.
			EndIf
		Next

	EndIf

EndIf

RestArea(aArea)
//Final deo programa
Return(lRet)
