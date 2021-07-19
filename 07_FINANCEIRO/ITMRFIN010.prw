#INCLUDE "MATR540.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ MATR540  ³ Autor ³ Marco Bianchi            ³ Data ³ 23/05/06 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Relatorio de Comissoes.                                       ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ MATR540(void)                                                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Generico                                                      ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/

User Function ITMRFIN010()

	Local oReport
	Private cAliasQry := GetNextAlias()

	#IFDEF TOP
	Private cAlias    := cAliasQry
	#ELSE
	Private cAlias    := "SE3"
	#ENDIF

	Matr540R3()

Return

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ MATR540R3³ Autor ³ Claudinei M. Benzi       ³ Data ³ 13.04.92 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Relatorio de Comissoes.                                       ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ MATR540(void)                                                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Generico                                                      ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±± 
±±ÚÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³ DATA   ³ BOPS ³Programad.³ALTERACAO                                      ³±±
±±ÃÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³05.02.03³XXXXXX³Eduardo Ju³Inclusao de Queries para filtros em TOPCONNECT.³±±
±±ÀÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/

Static Function Matr540R3()
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Define Variaveis                                             ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	Local wnrel
	Local titulo    := STR0001  //"Relatorio de Comissoes"
	Local cDesc1    := STR0002  //"Emissao do relatorio de Comissoes."
	Local tamanho   := "G"
	Local limite    := 220
	Local cString   := "SE3"
	Local cAliasAnt := Alias()
	Local cOrdemAnt := IndexOrd()
	Local nRegAnt   := Recno()
	Local cDescVend := " "

	Private aReturn := { OemToAnsi(STR0003), 1,OemToAnsi(STR0004), 1, 2, 1, "",1 }  //"Zebrado"###"Administracao"
	Private nomeprog:= "ITMRFIN010"
	Private aLinha  := { },nLastKey := 0
	Private cPerg   := "MTR540"

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica as perguntas selecionadas                           ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	AjustaSX1()
	Pergunte("MTR540",.F.)
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Variaveis utilizadas para parametros                          ³
	//³ mv_par01        	// Pela <E>missao,<B>aixa ou <A>mbos      ³
	//³ mv_par02        	// A partir da data                       ³
	//³ mv_par03        	// Ate a Data                             ³
	//³ mv_par04 	    	// Do Vendedor                            ³
	//³ mv_par05	     	// Ao Vendedor                            ³
	//³ mv_par06	     	// Quais (a Pagar/Pagas/Ambas)            ³
	//³ mv_par07	     	// Incluir Devolucao ?                    ³
	//³ mv_par08	     	// Qual moeda                             ³
	//³ mv_par09	     	// Comissao Zerada ?                      ³
	//³ mv_par10	     	// Abate IR Comiss                        ³
	//³ mv_par11	     	// Quebra pag.p/Vendedor                  ³
	//³ mv_par12	     	// Tipo de Relatorio (Analitico/Sintetico)³
	//³ mv_par13	     	// Imprime detalhes origem                ³
	//³ mv_par14         // Nome cliente							  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Envia controle para a funcao SETPRINT                        ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	wnrel := "ITMRFIN010"
	wnrel := SetPrint(cString,wnrel,cPerg,titulo,cDesc1,"","",.F.,"",.F.,Tamanho)

	If nLastKey==27
		dbClearFilter()
		Return
	Endif
	SetDefault(aReturn,cString)
	If nLastKey ==27
		dbClearFilter()
		Return
	Endif

	RptStatus({|lEnd| C540Imp(@lEnd,wnRel,cString)},Titulo)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Retorna para area anterior, indice anterior e registro ant.  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	DbSelectArea(caliasAnt)
	DbSetOrder(cOrdemAnt)
	DbGoto(nRegAnt)
Return

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ C540IMP  ³ Autor ³ Rosane Luciane Chene  ³ Data ³ 09.11.95 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Chamada do Relatorio                                       ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MATR540			                                          ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function C540Imp(lEnd,WnRel,cString)
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Define Variaveis                                             ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	Local CbCont,cabec1,cabec2
	Local tamanho  := "G"
	Local limite   := 220
	Local nomeprog := "ITMRFIN010"
	Local imprime  := .T.
	Local cPict    := ""
	Local cTexto,j :=0,nTipo:=0
	Local cCodAnt,nCol:=0
	Local nAc1:=0,nAc2:=0,nAg1:=0,nAg2:=0,nAc3:=0,nAg3:=0,nAc4:=0,nAg4:=0,lFirstV:=.T.
	Local nTregs,nMult,nAnt,nAtu,nCnt,cSav20,cSav7
	Local lContinua:= .T.
	Local cNFiscal :=""
	Local aCampos  :={}
	Local lImpDev  := .F.
	Local cBase    := ""
	Local cNomArq, cCondicao, cFilialSE1, cFilialSE3, cChave, cFiltroUsu
	Local nDecs    := GetMv("MV_CENT"+(IIF(mv_par08 > 1 , STR(mv_par08,1),"")))
	Local nBasePrt :=0, nComPrt:=0 
	Local aStru    := SE3->(dbStruct()), ni
	Local nDecPorc := TamSX3("E3_PORC")[2]
	Local nVlrTitulo := 0

	Local cDocLiq   := ""
	Local cTitulo  := "" 
	Local dEmissao := CTOD( "" ) 
	Local nTotLiq  := 0
	Local aLiquid  := {}
	Local aValLiq  := {}
	Local aLiqProp := {}
	Local ny
	Local aColuna := IIF(cPaisLoc <> "MEX",{15,19,42,46,83,95,107,119,130,137,153,169,176,195,203},{28,35,58,62,99,111,123,135,146,153,169,185,192,211,219})
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Variaveis utilizadas para Impressao do Cabecalho e Rodape    ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	cbtxt    := Space(10)
	cbcont   := 00
	li       := 80
	m_pag    := 01
	imprime  := .T.

	nTipo := IIF(aReturn[4]==1,15,18)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Definicao dos cabecalhos                                     ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If mv_par12 == 1
		If mv_par01 == 1
			titulo := OemToAnsi(STR0005)+OemToAnsi(STR0006)+" ("+OemToAnsi(STR0019)+") "+ " - " + GetMv("MV_MOEDA" + STR(mv_par08,1)) //"RELATORIO DE COMISSOES "###"(PGTO PELA EMISSAO)"
		Elseif mv_par01 == 2
			titulo := OemToAnsi(STR0005)+OemToAnsi(STR0007)+" ("+OemToAnsi(STR0019)+") "+ " - " + GetMv("MV_MOEDA" + STR(mv_par08,1))  //"RELATORIO DE COMISSOES "###"(PGTO PELA BAIXA)"
		Else
			titulo := OemToAnsi(STR0008)+" ("+OemToAnsi(STR0019)+") "+ " - " + GetMv("MV_MOEDA" + STR(mv_par08,1))  //"RELATORIO DE COMISSOES"
		Endif

		cabec1:=OemToAnsi(STR0009)	//"PRF NUMERO   PARC. CODIGO DO              LJ  NOME                                 DT.BASE     DATA        DATA        DATA       NUMERO          VALOR           VALOR      %           VALOR    TIPO"
		cabec2:=OemToAnsi(STR0010)	//"    TITULO         CLIENTE                                                         COMISSAO    VENCTO      BAIXA       PAGTO      PEDIDO         TITULO            BASE               COMISSAO   COMISSAO"
		// XXX XXXXXXxxxxxx X XXXXXXxxxxxxxxxxxxxx   XX  012345678901234567890123456789012345 XX/XX/XXxx  XX/XX/XXxx  XX/XX/XXxx  XX/XX/XXxx XXXXXX 12345678901,23  12345678901,23  99.99  12345678901,23     X       AJUSTE
		// 0         1         2         3         4         5         6         7         8         9         10        11        12        13        14        15        16        17        18        19        20        21
		// 0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789
		If cPaisLoc == "MEX"
			Cabec1 := Substr(Cabec1,1,10) + Space(16) + Substr(Cabec1,11)
			Cabec2 := Substr(Cabec2,1,10) + Space(16) + Substr(Cabec2,11)
		EndIf								
	Else
		If mv_par01 == 1
			titulo := OemToAnsi(STR0005)+OemToAnsi(STR0006)+" ("+OemToAnsi(STR0020)+") "+ " - " + GetMv("MV_MOEDA" + STR(mv_par08,1)) //"RELATORIO DE COMISSOES "###"(PGTO PELA EMISSAO)"
		Elseif mv_par01 == 2
			titulo := OemToAnsi(STR0005)+OemToAnsi(STR0007)+" ("+OemToAnsi(STR0020)+") "+ " - " + GetMv("MV_MOEDA" + STR(mv_par08,1))  //"RELATORIO DE COMISSOES "###"(PGTO PELA BAIXA)"
		Else
			titulo := OemToAnsi(STR0008)+" ("+OemToAnsi(STR0020)+") "+ " - " + GetMv("MV_MOEDA" + STR(mv_par08,1))  //"RELATORIO DE COMISSOES"
		Endif
		cabec1:=OemToAnsi(STR0021) //"CODIGO VENDEDOR                                           TOTAL            TOTAL      %            TOTAL           TOTAL           TOTAL"
		cabec2:=OemToAnsi(STR0022) //"                                                         TITULO             BASE                COMISSAO              IR          (-) IR"
		//"XXXXXX XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX 123456789012,23  123456789012,23  99.99  123456789012,23 123456789012,23 123456789012,23
		//"0         1         2         3         4         5         6         7         8         9         10        11        12        13        14        15        16        17        18        19        20        21
		//"0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Monta condicao para filtro do arquivo de trabalho            ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	DbSelectArea("SE3")	// Posiciona no arquivo de comissoes
	DbSetOrder(2)			// Por Vendedor
	cFilialSE3 := xFilial()
	cNomArq :=CriaTrab("",.F.)

	cCondicao := "SE3->E3_FILIAL=='" + cFilialSE3 + "'"
	cCondicao += ".And.SE3->E3_VEND>='" + mv_par04 + "'"
	cCondicao += ".And.SE3->E3_VEND<='" + mv_par05 + "'"
	cCondicao += ".And.DtoS(SE3->E3_EMISSAO)>='" + DtoS(mv_par02) + "'"
	cCondicao += ".And.DtoS(SE3->E3_EMISSAO)<='" + DtoS(mv_par03) + "'" 

	If mv_par01 == 1
		cCondicao += ".And.SE3->E3_BAIEMI!='B'"  // Baseado pela emissao da NF
	Elseif mv_par01 == 2
		cCondicao += " .And.SE3->E3_BAIEMI=='B'"  // Baseado pela baixa do titulo
	Endif 

	If mv_par06 == 1 		// Comissoes a pagar
		cCondicao += ".And.Dtos(SE3->E3_DATA)=='"+Dtos(Ctod(""))+"'"
	ElseIf mv_par06 == 2 // Comissoes pagas
		cCondicao += ".And.Dtos(SE3->E3_DATA)!='"+Dtos(Ctod(""))+"'"
	Endif

	If mv_par09 == 1 		// Nao Inclui Comissoes Zeradas
		cCondicao += ".And.SE3->E3_COMIS<>0"
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Cria expressao de filtro do usuario                          ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If ( ! Empty(aReturn[7]) )
		cFiltroUsu := &("{ || " + aReturn[7] +  " }")
	Else
		cFiltroUsu := { || .t. }
	Endif

	nAg1 := nAg2 := nAg3 := nAg4 := 0

	#IFDEF TOP
	If TcSrvType() != "AS/400"
		cOrder := SqlOrder(SE3->(IndexKey()))

		cQuery := "SELECT * "
		cQuery += "  FROM "+	RetSqlName("SE3")
		cQuery += " WHERE E3_FILIAL = '" + xFilial("SE3") + "' AND "
		cQuery += "	E3_VEND >= '"  + mv_par04 + "' AND E3_VEND <= '"  + mv_par05 + "' AND " 
		cQuery += "	E3_EMISSAO >= '" + Dtos(mv_par02) + "' AND E3_EMISSAO <= '"  + Dtos(mv_par03) + "' AND " 

		If mv_par01 == 1
			cQuery += "E3_BAIEMI <> 'B' AND "  //Baseado pela emissao da NF
		Elseif mv_par01 == 2
			cQuery += "E3_BAIEMI =  'B' AND "  //Baseado pela baixa do titulo  
		EndIf	

		If mv_par06 == 1 		//Comissoes a pagar
			cQuery += "E3_DATA = '" + Dtos(Ctod("")) + "' AND "
		ElseIf mv_par06 == 2 //Comissoes pagas
			cQuery += "E3_DATA <> '" + Dtos(Ctod("")) + "' AND "
		Endif 

		If mv_par09 == 1 		//Nao Inclui Comissoes Zeradas
			cQuery+= "E3_COMIS <> 0 AND "
		EndIf  

		cQuery += "D_E_L_E_T_ <> '*' "   

		cQuery += " ORDER BY "+ cOrder

		cQuery := ChangeQuery(cQuery)

		dbSelectArea("SE3")
		dbCloseArea()
		dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), 'SE3', .F., .T.)

		For ni := 1 to Len(aStru)
			If aStru[ni,2] != 'C'
				TCSetField('SE3', aStru[ni,1], aStru[ni,2],aStru[ni,3],aStru[ni,4])
			Endif
		Next 
	Else

		#ENDIF	
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Cria arquivo de trabalho                                     ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		cChave := IndexKey()
		cNomArq :=CriaTrab("",.F.)
		IndRegua("SE3",cNomArq,cChave,,cCondicao, OemToAnsi(STR0016)) //"Selecionando Registros..."
		nIndex := RetIndex("SE3")
		DbSelectArea("SE3") 
		#IFNDEF TOP
		DbSetIndex(cNomArq+OrdBagExT())
		#ENDIF
		DbSetOrder(nIndex+1)

		#IFDEF TOP
	EndIf
	#ENDIF	

	SetRegua(RecCount())		// Total de Elementos da regua 
	DbGotop()
	While !Eof()
		IF lEnd
			@Prow()+1,001 PSAY OemToAnsi(STR0011)  //"CANCELADO PELO OPERADOR"
			lContinua := .F.
			Exit
		EndIF
		IncRegua()
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Processa condicao do filtro do usuario                       ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If ! Eval(cFiltroUsu)
			Dbskip()
			Loop
		Endif

		nAc1 := nAc2 := nAc3 := nAc4 := 0
		lFirstV:= .T.
		cVend  := SE3->E3_VEND

		While !Eof() .AND. SE3->E3_VEND == cVend
			IncRegua()
			cDocLiq:= ""
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Processa condicao do filtro do usuario                       ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If ! Eval(cFiltroUsu)
				Dbskip()
				Loop
			Endif  

			If li > 55
				cabec(titulo,cabec1,cabec2,nomeprog,tamanho,nTipo)
			EndIF

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Seleciona o Codigo do Vendedor e Imprime o seu Nome          ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			IF lFirstV
				dbSelectArea("SA3")
				dbSeek(xFilial()+SE3->E3_VEND)
				If mv_par12 == 1
					cDescVend := SE3->E3_VEND + " " + A3_NOME 
					@li, 00 PSAY OemToAnsi(STR0012) + cDescVend //"Vendedor : "
					li+=2
				Else
					@li, 00 PSAY SE3->E3_VEND
					@li, 07 PSAY A3_NOME 
				EndIf
				dbSelectArea("SE3")
				lFirstV := .F.
			EndIF

			dbSelectArea("SE1")
			dbSetOrder(1)
			dbSeek(xFilial()+SE3->E3_PREFIXO+SE3->E3_NUM+SE3->E3_PARCELA+SE3->E3_TIPO)

			// Se nao imprime detalhes da origem, desconsidera titulos faturados
			If mv_par13 <> 1 .And. !Empty(SE1->E1_FATURA) .And. SE1->E1_FATURA <> "NOTFAT"
				SE3->( dbSkip() )
				Loop
			EndIf

			If mv_par12 == 1
				@li, 00 PSAY SE3->E3_PREFIXO
				@li, 04 PSAY SE3->E3_NUM
				@li, aColuna[1] PSAY SE3->E3_PARCELA
				@li, aColuna[2] PSAY SE3->E3_CODCLI
				@li, aColuna[3] PSAY SE3->E3_LOJA

				dbSelectArea("SA1")
				dbSeek(xFilial()+SE3->E3_CODCLI+SE3->E3_LOJA)
				@li, aColuna[4] PSAY IF(mv_par14 == 1,Substr(SA1->A1_NREDUZ,1,35),Substr(SA1->A1_NOME,1,35))

				dbSelectArea("SE3")
				@li, aColuna[5] PSAY SE3->E3_EMISSAO
			EndIf

			dbSelectArea("SE1")
			dbSetOrder(1)
			dbSeek(xFilial()+SE3->E3_PREFIXO+SE3->E3_NUM+SE3->E3_PARCELA+SE3->E3_TIPO)
			nVlrTitulo := Round(xMoeda(SE1->E1_VALOR,SE1->E1_MOEDA,MV_PAR08,SE1->E1_EMISSAO,nDecs+1),nDecs)
			dVencto    := SE1->E1_VENCTO  
			dEmissao   := SE1->E1_EMISSAO 
			aLiquid	  := {}
			aValLiq		:= {}
			aLiqProp	  	:= {}
			nTotLiq		:= 0
			If mv_par13 == 1 .And. !Empty(SE1->E1_NUMLIQ) .And. FindFunction("FA440LIQSE1")
				cLiquid := SE1->E1_NUMLIQ			
				cDocLiq := SE1->E1_NUMLIQ
				// Obtem os registros que deram origem ao titulo gerado pela liquidacao
				Fa440LiqSe1(SE1->E1_NUMLIQ,@aLiquid,@aValLiq)
				For ny := 1 to Len(aValLiq)
					nTotLiq += aValLiq[ny,2]
				Next
				For ny := 1 to Len(aValLiq)
					aAdd(aLiqProp,(nVlrTitulo/nTotLiq)*aValLiq[ny,2])
				Next
			Endif
			/*
			Nas comissoes geradas por baixa pego a data da emissao da comissao que eh igual a data da baixa do titulo.
			Isto somente dara diferenca nas baixas parciais
			*/	 

			If SE3->E3_BAIEMI == "B"
				dBaixa     := SE3->E3_EMISSAO
			Else
				dBaixa     := SE1->E1_BAIXA
			Endif

			If Eof()

				dbSelectArea("SF1")
				dbSetOrder(1)

				dbSelectArea("SF2")
				dbSetorder(1)

				If AllTrim(SE3->E3_TIPO) == "NCC"
					SF1->(dbSeek(xFilial("SF1")+SE3->E3_NUM+SE3->E3_PREFIXO+SE3->E3_CODCLI+SE3->E3_LOJA,.t.))
					nVlrTitulo := Round(xMoeda(SF1->F1_VALMERC,SF1->F1_MOEDA,mv_par07,SF1->F1_DTDIGIT,nDecs+1,SF1->F1_TXMOEDA),nDecs)
					dEmissao   := SF1->F1_DTDIGIT
				Else
					dbSeek(xFilial()+SE3->E3_NUM+SE3->E3_PREFIXO)       
					nVlrTitulo := Round(xMoeda(F2_VALFAT,SF2->F2_MOEDA,mv_par07,SF2->F2_EMISSAO,nDecs+1,SF2->F2_TXMOEDA),nDecs)
					dEmissao   := SF2->F2_EMISSAO
				EndIf

				dVencto    := " "
				dBaixa     := " "

				dEmissao   := SF2->F2_EMISSAO 

				If Eof()
					nVlrTitulo := 0
					dbSelectArea("SE1")
					dbSetOrder(1)
					cFilialSE1 := xFilial()
					dbSeek(cFilialSE1+SE3->E3_PREFIXO+SE3->E3_NUM)
					While ( !Eof() .And. SE3->E3_PREFIXO == SE1->E1_PREFIXO .And.;
					SE3->E3_NUM == SE1->E1_NUM .And.;
					SE3->E3_FILIAL == cFilialSE1 )
						If ( SE1->E1_TIPO == SE3->E3_TIPO  .And. ;
						SE1->E1_CLIENTE == SE3->E3_CODCLI .And. ;
						SE1->E1_LOJA == SE3->E3_LOJA )
							nVlrTitulo += Round(xMoeda(SE1->E1_VALOR,SE1->E1_MOEDA,MV_PAR08,SE1->E1_EMISSAO,nDecs+1),nDecs)
							dVencto    := " "
							dBaixa     := " "
							If Empty(dEmissao)
								dEmissao := SE1->E1_EMISSAO
							EndIf
						EndIf
						dbSelectArea("SE1")
						dbSkip()
					EndDo
				EndIf
			Endif


			If Empty(dEmissao)
				dEmissao := NIL
			EndIf

			//Preciso destes valores para pasar como parametro na funcao TM(), e como 
			//usando a xmoeda direto na impressao afetaria a performance (deveria executar
			//duas vezes, uma para imprimir e outra para pasar para a picture), elas devem]
			//ser inicializadas aqui. Bruno.

			nBasePrt:=	Round(xMoeda(SE3->E3_BASE ,1,MV_PAR08,dEmissao,nDecs+1),nDecs)
			nComPrt :=	Round(xMoeda(SE3->E3_COMIS,1,MV_PAR08,dEmissao,nDecs+1),nDecs)

			If nBasePrt < 0 .And. nComPrt < 0
				nVlrTitulo := nVlrTitulo * -1
			Endif	

			dbSelectArea("SE3")

			If mv_par12 == 1
				@ li,aColuna[6]  PSAY dVencto
				@ li,aColuna[7]  PSAY dBaixa
				@ li,aColuna[8]  PSAY SE3->E3_DATA
				@ li,aColuna[9]  PSAY SE3->E3_PEDIDO	Picture "@!"
				@ li,aColuna[10] PSAY nVlrTitulo		Picture tm(nVlrTitulo,14,nDecs)
				@ li,aColuna[11] PSAY nBasePrt 			Picture tm(nBasePrt,14,nDecs)
				If cPaisLoc<>"BRA"
					@ li,aColuna[12] PSAY SE3->E3_PORC		Picture tm(SE3->E3_PORC,6,nDecPorc)
				Else
					@ li,aColuna[12] PSAY SE3->E3_PORC		Picture tm(SE3->E3_PORC,6)
				Endif
				@ li,aColuna[13] PSAY nComPrt			Picture tm(nComPrt,14,nDecs)
				@ li,aColuna[14] PSAY SE3->E3_BAIEMI

				If ( SE3->E3_AJUSTE == "S" .And. MV_PAR07==1)
					@ li,aColuna[15] PSAY STR0018 //"AJUSTE "
				EndIf
				li++
				// Imprime titulos que deram origem ao titulo gerado por liquidacao
				If mv_par13 == 1
					For nI := 1 To Len(aLiquid)
						If li > 55
							cabec(titulo,cabec1,cabec2,nomeprog,tamanho,nTipo)
						EndIF
						If nI == 1
							@ ++li, 0 PSAY __PrtThinLine()
							@ ++li, 0 PSAY STR0023 +SE1->E1_NUMLIQ // "Detalhes : Titulos de origem da liquidação "
							@ ++li,10 PSAY STR0024 // "Prefixo    Numero          Parc    Tipo    Cliente   Loja    Nome                                       Valor Titulo      Data Liq.         Valor Liquidação      Valor Base Liq."
							//         Prefixo    Numero          Parc    Tipo    Cliente   Loja    Nome                                       Valor Titulo      Data Liq.         Valor Liquidação      Valor Base Liq.
							//         XXX        XXXXXXXXXXXX    XXX     XXXX    XXXXXXXXXXXXXX    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  999999999999999     99/99/9999          999999999999999      999999999999999 
							@ ++li, 0 PSAY __PrtThinLine()
							li++
						Endif
						cDocLiq  := SE1->E1_NUMLIQ
						SE1->(MsGoto(aLiquid[nI]))
						SA1->(MsSeek(xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA))
						@li,  10 PSAY SE1->E1_PREFIXO
						@li,  21 PSAY SE1->E1_NUM
						@li,  37 PSAY SE1->E1_PARCELA
						@li,  45 PSAY SE1->E1_TIPO
						@li,  53 PSAY SE1->E1_CLIENTE
						@li,  64 PSAY SE1->E1_LOJA
						@li,  71 PSAY IF(mv_par14 == 1,Substr(SA1->A1_NREDUZ,1,35),Substr(SA1->A1_NOME,1,35))
						@li, 111 PSAY SE1->E1_VALOR PICTURE Tm(SE1->E1_VALOR,15,nDecs)
						@li, 132 PSAY aValLiq[nI,1] 
						@li, 151 PSAY aValLiq[nI,2] PICTURE Tm(SE1->E1_VALOR,15,nDecs)
						@li, 172 PSAY aLiqProp[nI] PICTURE Tm(SE1->E1_VALOR,15,nDecs)
						li++
					Next
					// Imprime o separador da ultima linha
					If Len(aLiquid) >= 1
						@ li++, 0 PSAY __PrtThinLine()
					Endif
				Endif	
			EndIf
			nAc1 += nBasePrt
			nAc2 += nComPrt
			If cTitulo <> SE3->E3_PREFIXO+SE3->E3_NUM+SE3->E3_PARCELA+SE3->E3_TIPO+SE3->E3_VEND+SE3->E3_CODCLI+SE3->E3_LOJA  .And. Empty(cDocLiq)
				nAc3   += nVlrTitulo
				cTitulo:= SE3->E3_PREFIXO+SE3->E3_NUM+SE3->E3_PARCELA+SE3->E3_TIPO+SE3->E3_VEND+SE3->E3_CODCLI+SE3->E3_LOJA
				cDocLiq:= ""
			EndIf

			//<TLM> Márcio Chaves - Impressao dos Itens Referente a NF da comissão gerada.
			cQuery :=	"SELECT D2_FILIAL,D2_COD,D2_UM,D2_QUANT,D2_DOC,D2_SERIE,D2_LOTECTL FROM SD2050"
			cQuery +=	" WHERE D2_FILIAL = '"+xFilial()+"' AND D2_DOC = '"+SE3->E3_NUM+"' AND D2_SERIE = '"+SE3->E3_PREFIXO+"'"
			cQuery +=	" AND D_E_L_E_T_ = '' ORDER BY D2_ITEM"

			TcQuery cQuery Alias ITNF New

			DbSelectArea("ITNF")
			DbGoTop()
			//+------------------------------------------------+
			//| Se nao existir dados para gerar o relatorio    |
			//+------------------------------------------------+
			If ITNF->(EOF())
				ITNF->(DbCloseArea())
			Else
				@li, 10 PSAY 	"Itens NF       Bloco nº        Qtd. "+Alltrim(ITNF->D2_UM)+"    Nome do material"
				li++   
				While (!Eof())
					@li, 10 Psay ITNF->D2_DOC
					@li, 25 Psay ITNF->D2_LOTECTL
					@li, 43 Psay Alltrim(Transform(ITNF->D2_QUANT, "@E 99,999.999"))
					@li, 52 Psay Posicione("SB1",1,xFilial("SB1")+Alltrim(ITNF->D2_COD),"SB1->B1_DESC")
					li++			
					DBSKIP()
				End
				ITNF->(DbCloseArea())			
			EndIf

			dbSelectArea("SE3")
			dbSkip()
		EndDo

		If mv_par12 == 1
			li++

			If li > 55
				cabec(titulo,cabec1,cabec2,nomeprog,tamanho,nTipo)
			EndIF
			@ li, 00  PSAY OemToAnsi(STR0013)+cDescVend  //"TOTAL DO VENDEDOR --> "
			@ li,aColuna[10]-1  PSAY nAc3 	PicTure tm(nAc3,15,nDecs)
			@ li,aColuna[11]-1  PSAY nAc1 	PicTure tm(nAc1,15,nDecs)

			If nAc1 != 0
				If cPaisLoc=="BRA"
					@ li, aColuna[12] PSAY NoRound((nAc2/nAc1)*100,2)   PicTure "999.99"
				Else
					@ li, aColuna[12] PSAY NoRound((nAc2/nAc1)*100)   PicTure "999.99"
				Endif
			Endif

			@ li, aColuna[13]-1  PSAY nAc2 PicTure tm(nAc2,15,nDecs)
			li++

			If mv_par10 > 0 .And. (nAc2 * mv_par10 / 100) > GetMV("MV_VLRETIR") //IR
				@ li, 00  PSAY OemToAnsi(STR0015)  //"TOTAL DO IR       --> "
				nAc4 += (nAc2 * mv_par10 / 100)				
				@ li, aColuna[13]-1  PSAY nAc4 PicTure tm(nAc2 * mv_par10 / 100,15,nDecs)
				li ++
				@ li, 00  PSAY OemToAnsi(STR0017)  //"TOTAL (-) IR      --> "
				@ li, aColuna[13]-1 PSAY nAc2 - nAc4 PicTure tm(nAc2,15,nDecs)
				li ++
			EndIf

			@ li, 00  PSAY __PrtThinLine()

			If mv_par11 == 1  // Quebra pagina por vendedor (padrao)
				li := 60  
			Else
				li+= 2
			Endif
		Else
			If li > 55
				cabec(titulo,cabec1,cabec2,nomeprog,tamanho,nTipo)
			EndIF
			@ li,048  PSAY nAc3 	PicTure tm(nAc3,15,nDecs)
			@ li,065  PSAY nAc1 	PicTure tm(nAc1,15,nDecs)
			If nAc1 != 0
				If cPaisLoc=="BRA"
					@ li, 081 PSAY NoRound((nAc2/nAc1)*100,2)  PicTure "999.99"
				Else
					@ li, 081 PSAY NoRound((nAc2/nAc1)*100)   PicTure "999.99"
				Endif
			Endif
			@ li, 089  PSAY nAc2 PicTure tm(nAc2,15,nDecs)
			If mv_par10 > 0 .And. (nAc2 * mv_par10 / 100) > GetMV("MV_VLRETIR") //IR
				nAc4 += (nAc2 * mv_par10 / 100)
				@ li, 105  PSAY nAc4 PicTure tm(nAc2 * mv_par10 / 100,15,nDecs)
				@ li, 121 PSAY nAc2 - nAc4 PicTure tm(nAc2,15,nDecs)
			EndIf
			li ++
		EndIf

		dbSelectArea("SE3")
		nAg1 += nAc1
		nAg2 += nAc2
		nAg3 += nAc3
		nAg4 += nAc4
	EndDo

	If (nAg1+nAg2+nAg3+nAg4) != 0
		If li > 55
			cabec(titulo,cabec1,cabec2,nomeprog,tamanho,nTipo)
		Endif

		If mv_par12 == 1
			@li,  00 PSAY OemToAnsi(STR0014)  //"TOTAL  GERAL      --> "
			@li, aColuna[10]-1 PSAY nAg3	Picture tm(nAg3,15,nDecs)
			@li, aColuna[11]-1 PSAY nAg1	Picture tm(nAg1,15,nDecs)
			If cPaisLoc=="BRA"
				@li, aColuna[12] PSAY NoRound((nAg2/nAg1)*100,2) Picture "999.99"
			Else
				@li, aColuna[12] PSAY NoRound((nAg2/nAg1)*100) Picture "999.99"
			Endif
			@li, aColuna[13]-1 PSAY nAg2 Picture tm(nAg2,15,nDecs)
			If mv_par10 > 0 .And. (nAg2 * mv_par10 / 100) > GetMV("MV_VLRETIR")//IR
				li ++
				@ li, 00  PSAY OemToAnsi(STR0015)  //"TOTAL DO IR       --> "
				@ li, 175  PSAY nAg4 PicTure tm((nAg2 * mv_par10 / 100),15,nDecs)
				li ++
				@ li, 00  PSAY OemToAnsi(STR0017)  //"TOTAL (-) IR       --> "
				@ li, 175  PSAY nAg2 - nAg4 Picture tm(nAg2,15,nDecs)
			EndIf
		Else
			@li,000  PSAY __PrtThinLine()
			li ++
			@li,000 PSAY OemToAnsi(STR0014)  //"TOTAL  GERAL      --> "
			@li,048 PSAY nAg3	Picture tm(nAg3,15,nDecs)
			@li,065 PSAY nAg1	Picture tm(nAg1,15,nDecs)
			If cPaisLoc=="BRA"
				@li,081 PSAY NoRound((nAg2/nAg1)*100,2) Picture "999.99"
			Else
				@li,081 PSAY NoRound((nAg2/nAg1)*100) Picture "999.99"
			Endif
			@li,089 PSAY nAg2 Picture tm(nAg2,15,nDecs)
			If mv_par10 > 0 .And. (nAg2 * mv_par10 / 100) > GetMV("MV_VLRETIR")//IR
				@ li,105  PSAY nAg4 PicTure tm((nAg2 * mv_par10 / 100),15,nDecs)
				@ li,121  PSAY nAg2 - nAg4 Picture tm(nAg2,15,nDecs)
			EndIf
		EndIf
		roda(cbcont,cbtxt,"G")
	EndIF

	#IFDEF TOP
	If TcSrvType() != "AS/400"
		dbSelectArea("SE3")
		DbCloseArea()
		chkfile("SE3")
	Else	
		#ENDIF
		fErase(cNomArq+OrdBagExt())
		#IFDEF TOP
	Endif
	#ENDIF

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Restaura a integridade dos dados                             ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	DbSelectArea("SE3")
	RetIndex("SE3")
	DbSetOrder(2)
	dbClearFilter()

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Se em disco, desvia para Spool                               ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If aReturn[5] = 1
		Set Printer To
		dbCommitAll()
		ourspool(wnrel)
	Endif

	MS_FLUSH()

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³AjustaSX1 ºAutor  ³Ana Paula N. Silva  º Data ³  20/09/07   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³                                                            º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ MATR540                                                    º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function AjustaSX1()
	Local aHelpPor := {}
	Local aHelpEng := {}
	Local aHelpSpa := {}
	Local aAreaSX1 := GetArea()

	DbSelectArea("SX1")
	DbSetOrder(1)

	DbSeek(PadR("MTR540",Len(SX1->X1_GRUPO)) + "09")
	RecLock("SX1",.F.)
	Replace X1_PRESEL With 1
	Replace X1_DEF01 With "Não"
	Replace X1_DEFSPA1 With "No"
	Replace X1_DEFENG1 With "No" 

	Replace X1_DEF02 With " "
	Replace X1_DEFSPA2 With " "
	Replace X1_DEFENG2 With " " 

	aHelpPor := {}
	aHelpEng := {}
	aHelpSpa := {}
	AADD(aHelpPor,'Indica que não será impresso')
	AADD(aHelpPor,'comissões zeradas.')
	AADD(aHelpSpa,'Indica que no se imprimirán') 
	AADD(aHelpSpa,'comisiones en cero.')
	AADD(aHelpEng,'Indicates the system will not')
	AADD(aHelpEng,'print commissions zeroed.')


	PutSX1Help("P.MTR54009.",aHelpPor,aHelpEng,aHelpSpa)

	aHelpPor := {}
	aHelpEng := {}
	aHelpSpa := {}
	AADD(aHelpPor,'Informe os códigos dos vendedores dos ')
	AADD(aHelpPor,'quais se deseja emitir a relação de ')
	AADD(aHelpPor,'comissões.')
	AADD(aHelpPor,'Tecla [F3] disponível para consultar ')
	AADD(aHelpPor,'o Cadastro de Vendedores.')
	AADD(aHelpEng,'Informe os códigos dos vendedores dos ')
	AADD(aHelpPor,'quais se deseja emitir a relação de ')
	AADD(aHelpPor,'comissões.')
	AADD(aHelpEng,'Tecla [F3] disponível para consultar ')
	AADD(aHelpEng,'o Cadastro de Vendedores.')
	AADD(aHelpSpa,'Informe os códigos dos vendedores dos ')
	AADD(aHelpPor,'quais se deseja emitir a relação de ')
	AADD(aHelpPor,'comissões.')
	AADD(aHelpSpa,'Tecla [F3] disponível para consultar ')
	AADD(aHelpSpa,'o Cadastro de Vendedores.')
	PutSX1Help("P.MTR540P9R104.",aHelpPor,aHelpEng,aHelpSpa)

	aHelpPor := {}
	aHelpEng := {}
	aHelpSpa := {}
	AADD(aHelpPor,'Informe se saltará por vendedor.')
	AADD(aHelpSpa,'Informe se saltará por vendedor.') 
	AADD(aHelpEng,'Informe se saltará por vendedor.')
	PutSX1Help("P.MTR540P9R109.",aHelpPor,aHelpEng,aHelpSpa)

	SX1->(MsUnLock())
	RestArea(aAreaSX1)

Return