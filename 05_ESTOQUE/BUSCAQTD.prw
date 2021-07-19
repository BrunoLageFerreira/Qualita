#INCLUDE "PROTHEUS.CH"

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³ BUSCAQTD ³ Autor ³ Marcio Chaves         ³ Data ³ 13/09/12 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Dispara gatilhos para preencher quantidade informadas na OP³±±
±±³apos informar o lote no pedido ativa o gatilho C6_LOTECTL		      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ SIGAEST                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
User Function BUSCAQTD()

	Private nQuant
	Private nOp := SB8->B8_DOC
	If (Alltrim(SX7->X7_CDOMIN) == "C6_CLASS")
		nQuant := If(Alltrim(SC6->C6_CLASS) == '',POSICIONE("SC2",1,XFILIAL("SC2")+nOp,"SC2->C2_CLASS"),SC6->C6_CLASS)
	ElseIf (Alltrim(SX7->X7_CDOMIN) == "C6_ALTLIQ")
		nQuant := If(SC6->C6_ALTLIQ == 0,POSICIONE("SC2",1,XFILIAL("SC2")+nOp,"SC2->C2_ALTLIQ"),SC6->C6_ALTLIQ)
	ElseIf (Alltrim(SX7->X7_CDOMIN) == "C6_COMPLIQ")
		nQuant := If(SC6->C6_COMPLIQ == 0,POSICIONE("SC2",1,XFILIAL("SC2")+nOp,"SC2->C2_COMPLIQ"),SC6->C6_COMPLIQ)
	ElseIf (Alltrim(SX7->X7_CDOMIN) == "C6_LARGLIQ")
		nQuant := If(SC6->C6_LARGLIQ == 0,POSICIONE("SC2",1,XFILIAL("SC2")+nOp,"SC2->C2_LARGLIQ"),SC6->C6_LARGLIQ)
	ElseIf (Alltrim(SX7->X7_CDOMIN) == "C6_QTDVEN")
		nQuant := If(SC6->C6_QTDVEN == 0,POSICIONE("SC2",1,XFILIAL("SC2")+nOp,"SC2->C2_QUANT"),SC6->C6_QTDVEN)
	ElseIf (Alltrim(SX7->X7_CDOMIN) == "C6_COMPBRU")
		nQuant := If(SC6->C6_COMPBRU == 0,POSICIONE("SC2",1,XFILIAL("SC2")+nOp,"SC2->C2_COMPBRU"),SC6->C6_COMPBRU)
	ElseIf (Alltrim(SX7->X7_CDOMIN) == "C6_ALTBRU")
		nQuant := If(SC6->C6_ALTBRU == 0,POSICIONE("SC2",1,XFILIAL("SC2")+nOp,"SC2->C2_ALTBRU"),SC6->C6_ALTBRU)
	ElseIf (Alltrim(SX7->X7_CDOMIN) == "C6_LARGBRU")
		nQuant := If(SC6->C6_LARGBRU == 0,POSICIONE("SC2",1,XFILIAL("SC2")+nOp,"SC2->C2_LARGBRU"),SC6->C6_LARGBRU)
	ElseIf (Alltrim(SX7->X7_CDOMIN) == "C6_LTREM")
		If(Alltrim(SC6->C6_LTREM) == '')
			IF(Alltrim(M->C6_LOTECTL) == '')
				nQuant:= SC6->C6_LOTECTL
			Else
				nQuant:= M->C6_LOTECTL
			Endif
		Else
			nQuant:= SC6->C6_LTREM
		EndIf
	EndIf
Return nQuant
