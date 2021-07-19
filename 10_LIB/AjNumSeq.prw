#Include 'Protheus.ch'
#Include 'TopConn.ch'

User Function AjNumSeq()
	Processa({|| AjNumSeq() },"Processando...")
Return

Static Function AjNumSeq()

	Local aTodas := {}
	Local cQuery := ""


	//-----------------------------------------------------------------------------
	// SD1
	//-----------------------------------------------------------------------------
	cQuery := "SELECT 'SD1' TABELA, D1_NUMSEQ NUMSEQ, R_E_C_N_O_ RECNO FROM " + RetSqlName("SD1") + " WHERE D_E_L_E_T_ <> '*' ORDER BY NUMSEQ"

	TcQuery cQuery New Alias "TRBSD1"

	DbSelectArea("TRBSD1")
	DbGoTop()

	While !TRBSD1->(EOF())

		aAdd( aTodas , { TRBSD1->TABELA , TRBSD1->NUMSEQ , TRBSD1->RECNO , 0 } )

		TRBSD1->(DbSkip())

	EndDo

	//-----------------------------------------------------------------------------
	// SD2
	//-----------------------------------------------------------------------------
	cQuery := "SELECT 'SD2' TABELA, D2_NUMSEQ NUMSEQ, R_E_C_N_O_ RECNO FROM " + RetSqlName("SD2") + " WHERE D_E_L_E_T_ <> '*' ORDER BY NUMSEQ"

	TcQuery cQuery New Alias "TRBSD2"

	DbSelectArea("TRBSD2")
	DbGoTop()

	While !TRBSD2->(EOF())

		aAdd( aTodas , { TRBSD2->TABELA , TRBSD2->NUMSEQ , TRBSD2->RECNO , 0 } )

		TRBSD2->(DbSkip())

	EndDo

	//-----------------------------------------------------------------------------
	// SD3
	//-----------------------------------------------------------------------------
	cQuery := "SELECT 'SD3' TABELA, D3_NUMSEQ NUMSEQ, R_E_C_N_O_ RECNO FROM " + RetSqlName("SD3") + " WHERE D_E_L_E_T_ <> '*' ORDER BY NUMSEQ"

	TcQuery cQuery New Alias "TRBSD3"

	DbSelectArea("TRBSD3")
	DbGoTop()

	While !TRBSD3->(EOF())

		aAdd( aTodas , { TRBSD3->TABELA , TRBSD3->NUMSEQ , TRBSD3->RECNO , 0 } )

		TRBSD3->(DbSkip())

	EndDo


	//ordena
	aSort(aTodas,,,{ | x,y | x[2] < y[2] })

	//acerta sequencia no array
	For nX := 1 to Len(aTodas)

		aTodas[nX,4] := StrZero(nX,6)

	Next nX


	//acerta sequencia nas tabelas
	For nX := 1 to Len(aTodas)

		//Se o numero ja esta igual, nao atualiza
		If aTodas[nX,2] <> aTodas[nX,4]

			Do Case

				Case aTodas[nX,1] == "SD1"

				cQuery := "UPDATE " + RetSqlName(aTodas[nX,1]) + " SET D1_NUMSEQ = '" + aTodas[nX,4] + "' WHERE R_E_C_N_O_ = " + Str(aTodas[nX,3])

				TcSqlExec( cQuery )

				Case aTodas[nX,1] == "SD2"

				cQuery := "UPDATE " + RetSqlName(aTodas[nX,1]) + " SET D2_NUMSEQ = '" + aTodas[nX,4] + "' WHERE R_E_C_N_O_ = " + Str(aTodas[nX,3])

				TcSqlExec( cQuery )		

				Case aTodas[nX,1] == "SD3"

				cQuery := "UPDATE " + RetSqlName(aTodas[nX,1]) + " SET D3_NUMSEQ = '" + aTodas[nX,4] + "' WHERE R_E_C_N_O_ = " + Str(aTodas[nX,3])

				TcSqlExec( cQuery )

			EndCase

		EndIf		 	

	Next nX

	MsgInfo("Acabou")

Return

