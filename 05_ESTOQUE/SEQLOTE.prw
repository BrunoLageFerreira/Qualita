#INCLUDE "PROTHEUS.CH"

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³ SEQLOTE  ³ Autor ³ Marco Tulio           ³ Data ³ 13/09/12 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ SEQUENCIAL DE LOTES POR PRODUTO                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ SIGAEST                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
User Function SEQLOTE()
	Local aArea    := GetArea()                   

	Private cCod := ""
	Private nSeqLote := 0
	Private cLote  := ""
	Private cQuery:= ""

	If SubString(CNUMEMP,1,2) == "05"

		cCod := Alltrim(M->C2_PRODUTO)
		nSeqLote := SB1->B1_SEQLT

		CQuery:= " SELECT C2_LOTECTL 
		CQuery+= " FROM " + RetSqlName("SC2") + " SC2 
		CQuery+= " WHERE R_E_C_N_O_ = ( SELECT MAX(R_E_C_N_O_ ) 
		CQuery+= " 				  FROM " + RetSqlName("SC2")  
		CQuery+= " 				 WHERE C2_PRODUTO= '"+cCod+"' 
		CQuery+= " 				  AND D_E_L_E_T_ = '' 
		CQuery+= " 				  AND C2_FILIAL = '"+xFilial("SC2")+"'
		CQuery+= " 			  )

		Query := ChangeQuery(cQuery)

		dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), 'TSTC2', .T., .F.)

		DBSeleCtArea("TSTC2")
		dbGoTop()
		While ! TSTC2->(Eof())                                                  
			cLote := Strzero(Val(SubStr(TSTC2->C2_LOTECTL,1,5))+1,5) + Substr(TSTC2->C2_LOTECTL,6,2)
			dbSkip()
		End      
		DbSeleCtArea("TSTC2")
		DbCloseArea() 
	ENDIF
	
	RestArea(aArea)

Return (cLote)



//Local cLote := Space(7)
//Local cPar, cNewpar

//cPar := "MV_SEQLT" + Strzero(SB1->B1_SEQLT,2,0)

//cLote := GETMV(cPar)

//cNewpar := Strzero(Val(SubStr(cLote,1,5))+1,5)+Substr(cLote,6,2)

//PUTMV(cPar, cNewpar )

//Return cLote
