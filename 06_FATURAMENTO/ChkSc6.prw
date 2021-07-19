#Include "Rwmake.ch"
#Include "Protheus.ch"
#Include "Topconn.ch"

User Function ChkSc6

	Private nLote := ""
	Private nTst  := .T.
	Private cQuery:= ""

	nLote := M->C6_LOTECTL

	cQuery:= "SELECT C6_NUM,C6_LOTECTL FROM " + RetSqlName("SC6") + "  WHERE C6_LOTECTL = '"+nLote+"' AND D_E_L_E_T_ = ''"

	TcQuery cQuery Alias TSTC6 New

	DBSelectArea("TSTC6")
	DBGoTop()
	While (!EOF())
		IF !Empty(TSTC6->C6_LOTECTL)
			//MsgAlert("Numero de Lote já existente no pedido : "+TSTC6->C6_NUM+" .")
			If Aviso("Atenção","Numero de Lote já existente no pedido: "+TSTC6->C6_NUM+" Deseja Liberar?", {"SIM","NAO"},2) == 1
				nTst := .T.
			Else
				M->C6_LOTECTL := ""
				nTst := .F.	
			Endif	  
		Else
			nTst := .T.
		EndIf
		DbSkip()
	End
	DbSelectArea("TSTC6")
	DbCloseArea()
Return nTst
