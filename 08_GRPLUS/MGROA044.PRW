#INCLUDE "protheus.CH"
#INCLUDE "FWMVCDEF.CH"
#Include "Parmtype.ch"
#INCLUDE "TOTVS.CH"
#INCLUDE "FWEditPanel.CH"
#INCLUDE "TOPCONN.CH"

/*                                          
Programa ...: MGROA044.Prw
Uso ........: ENCERRAMENTO 
Data .......: 04/05/2025
Feito por ..: Bruno Lage Ferreira.
*/

USER FUNCTION MGROA044()
**********************************************************************************************
*
*
*****
Local aArea        := GetArea()
Local aParam       := PARAMIXB
Local xRet         := .T.
//Local nret         := 0
Local nI           := 0
//Local nX           := 0
Local cMsgErro     := ""
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

	ElseIf cIdPonto == 'BUTTONBAR'
			//ApMsgInfo('Adicionando Botao na Barra de Botoes (BUTTONBAR).' + CRLF + 'ID ' + cIdModel )
			xRet := { {'Import. Encerramento', 'Import. Encerramento', { || u_APPEncerra()}, 'Import. Encerramento' } }


	ElseIf cIdPonto == 'MODELPOS'
		oModeLZGM := oModel:GetModel("ZGMDETAIL")

		For nI := 1 to oModeLZGM:length()
			//valida a primeira linha do apontamento para verificar a data do estoque
			oModeLZGM:GoLine(nI)
			IF Empty(oModeLZGM:GetValue("ZGM_CLASSI") )
				//Alert("Existe classificação em branco! Favor informar uma classificação antes de salvar!")
				cMsgErro := cMsgErro + AllTrim(oModeLZGM:GetValue("ZGM_LOTECT")) + '-' + AllTrim(oModeLZGM:GetValue("ZGM_NUMLOT")) + ', '
				//lRet := .f.
			EndIf
		Next

		If !Empty(cMsgErro)
			cMsgErro := "Existe classificação em branco! Favor informar uma classificação antes de salvar! " + cMsgErro + " Deseja continuar mesmo assim?"
			If !( xRet := ApMsgYesNo( cMsgErro  ) )
				Help( ,, 'Help',, 'Erro de classificação de produtos.', 1, 0 )				
			EndIf 
		EndIf 

	EndIf

EndIf

RestArea(aArea)

Return(xRet)



User Function APPEncerra()
/**************************************************************************************************************************************
*
*
***/
Local oModel  := FWModelActive()
Local cQuery  := ""
Local cCodId  := 0
Local lValid  := .F.
Local oView  
Local nX      := 0
Local nChAlt  := 0
Local cMsg    := ""

iF !Empty(M->ZH7_XID)
    cCodId := M->ZH7_XID

	cQuery := "SELECT * FROM SIGAEIS..APP005_OP_DLS WHERE DLS_ID_CAB = "+Trim(Str(cCodId))+ " ORDER BY DLS_ID_CAB,DLS_LOTE,DLS_CHAPA"
    TCQUERY cQuery NEW ALIAS OP_DLS

	dbSelectArea("OP_DLS")
	dbGoTop()

	If !EOF() 
		oModeLZGM := oModel:GetModel("ZGMDETAIL")
		oView := FwViewactive()

		Do While !Eof()
			For nX := 1 to oModeLZGM:length()
				
				oModeLZGM:GoLine(nX)
				iF AllTrim(oModeLZGM:GetValue("ZGM_LOTECT")) ==  ALLTRIM(OP_DLS->DLS_LOTEORI) .AND.; 
				   AllTrim(oModeLZGM:GetValue("ZGM_NUMLOT")) ==  ALLTRIM(OP_DLS->DLS_CHAPA)

					oModeLZGM:SetValue("ZGM_STATUS", AllTrim("P"))
					oModeLZGM:SetValue("ZGM_CLASSI", AllTrim("P"))
					oModeLZGM:SetValue("ZGM_COMLIQ", OP_DLS->DLS_COMLIQ)
					oModeLZGM:SetValue("ZGM_ALTLIQ", OP_DLS->DLS_ALTLIQ)

					lValid := .T.
					nChAlt := nChAlt + 1

					nX := oModeLZGM:length()
				EndIf
	
			Next

			dbSelectArea("OP_DLS")
			dbSkip()
		EndDo

		oModeLZGM:GoLine(1)
		If !isBlind()
			oView:Refresh("ZGMDETAIL")
		EndIf
		
		If lValid 
			cMsg := "Quantidade de linhas: [ " + AllTrim(Str(oModeLZGM:length())) + " ]"+CHR(13)+CHR(10)+"Importadas: [ " + AllTrim(Str(nChAlt)) + " ]"
			Aviso("Sucesso!", cMsg, {"OK"}, 2, "Verifique os dados importados...", , , , 5000)	
		Else
			Alert("Não houve importação de dados!")
		EndIf
	EndIf

	dbSelectArea("OP_DLS")
	OP_DLS->(DbCloseArea())

Else
	Alert("Não foi encontrado código de importação da ficha! O código é salvo na tela de apontamento.")
EndIf 

Return()
