
User Function GMT140LOK()
Local lRet := .T.

	If FwIsInCallStack('U_GATI001')
		U_GTPE012()
	EndIf

	If !l103Auto
		// [Conteudo do Ponto de Entrada que ja existe]
	EndIf

Return lRet