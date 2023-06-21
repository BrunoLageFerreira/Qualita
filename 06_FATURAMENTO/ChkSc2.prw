#Include "Rwmake.ch"
#Include "Protheus.ch"
#Include "Topconn.ch"

User Function ChkSc2

	Private nLote := ""
	Private nTst  := .T.
	Private cQuery:= ""

	If SubString(CNUMEMP,1,2) == "05"
		nLote := M->c2_LOTECTL

		CQuery:= "SELECT C2_NUM,C2_LOTECTL FROM "+ RetSqlName("SC2") +" WHERE C2_LOTECTL = '"+nLote+"' AND D_E_L_E_T_ = ''"

		TCQuery CQuery Alias TSTC2 New

		DBSeleCtArea("TSTC2")
		DBGoTop()                                                 
		While (!EOF())
			IF !Empty(TSTC2->C2_LOTECTL)
				nTst := .F.
				MsgAlert("Numero de Lote já existente na ordem de producão : "+TSTC2->C2_NUM+" .")
			Else
				nTst := .T.  
				PUTMV("MV_SEQLT" + Strzero(SB1->B1_SEQLT,2,0), Strzero(Val(SubStr(M->C2_LOTECTL,1,5))+1,5)+Substr(M->C2_LOTECTL,6,2))
			EndIf
			DbSkip()
		End	
		DbSeleCtArea("TSTC2")
		DbCloseArea()
	EndIf

Return nTst
