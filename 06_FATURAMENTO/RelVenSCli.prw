#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
#INCLUDE "TOPCONN.CH" 

User Function MRELVENSCLI
	//+--------------------------------------------------------------------+
	//| Declaracao de Variaveis                                            |
	//+--------------------------------------------------------------------+

	Local cQuery	:= ""
	Local cPerg 	:= ""

	//+--------------------------------------------------------------------+
	//| Define os estilos de fonte a serem utilizados                      |
	//+--------------------------------------------------------------------+
	Private oFont1 := TFont():New( "Arial",,10,,.F.,,,,.F.,.F. )
	Private oFont2 := TFont():New( "Arial",,10,,.T.,,,,.F.,.F. )
	Private oFont3 := TFont():New( "Arial",,16,,.F.,,,,.F.,.F. )
	Private oFont4 := TFont():New( "Arial",,08,,.T.,,,,.F.,.F. )

	Private nColIni := 0
	Private nLimite	:= 2350
	Private nColFim := 2330
	Private nLin	:= 0
	Private cEmpresa := ""

	oPrn := TMSPrinter():New("Relatorio de Vendas por Bloco - Sintético")

	oPrn:SetPaperSize(9) // A4
	oPrn:SetLandScape(.T.)//Paisagem
	//oPrn:setPortrait() // Retrato
	oPrn:Setup()

	Pergunte("RELVENSCLI",.T.)

	/*
	Perguntas Relatorio:

	Filial De? = mv_par01
	Filial Ate? = mv_par02
	Dt.Fat. De? = mv_par03
	Dt.Fat. Ate? = mv_par04
	Produto De? = mv_par05
	Produto Ate? = mv_par06
	Cliente De? = mv_par07
	Cliente Ate? = mv_par08
	CFOP? = mv_par09
	Gera Dupl ? = mv_par10
	Mov.Est.? = mv_par11
	Class? 	1=1ª = mv_par12
	2=CO
	3=Todas
	*/

	ImpDados()
	ImpRodape()

	oPrn:Preview()

Return

/*/
+----------+------------+----------------------------+------+------------+
|Funcao    | ImpDados   | Marcio - Adaptado por Myrella| Data | 27/05/08 |
+----------+------------+----------------------------+------+------------+
|Descricao | Imprime o Rodape do relatorio                               |
+----------+-------------------------------------------------------------+
|Uso       | MSLR001                                                     |
+----------+-------------------------------------------------------------+
/*/

Static Function ImpDados

	// QUERY RELATORIO DE VENDAS

	cQuery:= "SELECT C6_FILIAL, C6_NUM, C6_DATFAT, C6_NOTA, C6_SERIE, A1_NOME, C6_LOTECTL, C6_DESCRI, C6_CLASS, C6_COMPLIQ, "
	cQuery+= "			C6_ALTLIQ, C6_LARGLIQ, C6_QTDVEN, C6_UM, C6_PRCVEN*M2_MOEDA2 AS PRCVEN, C6_PRCVEN*1 AS PRCVEN1, "
	cQuery+= "			C6_VALOR*M2_MOEDA2 AS TOTAL, C6_VALOR*1 AS TOTAL1 "
	cQuery+= "FROM SC6050 "

	// FILTRAR SE GERAR ESTOQUE E FINANCEIRO
	cQuery+= " INNER JOIN SF4050 ON F4_CODIGO = C6_TES"

	// PEGAR VALOR DA COTACAO DO DOLAR NO DIA
	cQuery+= " INNER JOIN SM2050 ON M2_DATA = C6_DATFAT"

	// BUSCAR NOME DO CLIENTE PARA FACILITAR EXIBICAO.
	cQuery+= " INNER JOIN SA1050 ON A1_COD = C6_CLI AND A1_LOJA = C6_LOJA"

	cQuery+= " WHERE C6_FILIAL BETWEEN '"+mv_par01+"' AND '"+mv_par02+"' AND C6_DATFAT BETWEEN '"+DTOS(mv_par03)+"' AND '"+DToS(mv_par04)+"'"
	cQuery+= " AND C6_NOTA <> '' AND SC6050.D_E_L_E_T_ = '' AND SM2050.D_E_L_E_T_ = '' AND C6_PRODUTO BETWEEN '"+mv_par05+"' AND '"+mv_par06+"' AND C6_CLI BETWEEN '"+mv_par07+"' AND '"+mv_par08+"'"

	//IF VARIAVEL IGUAL VAZIO BUSCA TODOS, SENAO SOMENTE A LISTA.
	cQuery+= " AND C6_CF BETWEEN '"+mv_par09+"' AND '"+mv_par10+"'" 
	cQuery+= "AND C6_CF <> '5922' AND C6_CF <> '6922'"
	cQuery+= " AND C6_BLQ <> 'R'"

	// IF SIM  NAO OU AMBOS
	If mv_par11 == 1

		cQuery+= " AND F4_ESTOQUE = 'S'"

	ElseIf mv_par11 == 2

		cQuery+= " AND F4_ESTOQUE = 'N'"

	Else

		cQuery+= " AND F4_ESTOQUE <> ''"

	EndIf

	// IF SIM  NAO OU AMBOS
	If mv_par12 == 1

		cQuery+= " AND F4_DUPLIC = 'S'"

	ElseIf mv_par12 == 2

		cQuery+= " AND F4_DUPLIC = 'N'"

	Else

		cQuery+= " AND F4_DUPLIC <> ''"

	EndIf

	// PROBLEMA, POIS NEM TODOS OS PEDIDOS ESTAO COM CLASSIFICACAO. VERIFICAR COM HARLEI.
	// A PRINCIPIO SERA UTILIZADO TODOS NO FILTRO, DEPOIS 1 OU 2

	If mv_par13 == 1

		cQuery+= " AND C6_CLASS = '1ª'"

	ElseIf mv_par13 == 2

		cQuery+= " AND C6_CLASS = 'CO'"

	Else

		cQuery+= " AND C6_CLASS IN ('','1ª','CO','2ª')"

	EndIF

	// INIBIR NOTAS FISCAIS DE DEVOLUCAO. - COMENTADO PARA QUE AS REVENDAS DE BLOCO APARECAM NO RELATORIO - AINDA EM TESTE
	//	cQuery+= " AND C6_NFORI = ''"   


	// APENAS OS PRODUTOS COM DESCRICAO INICIAL "BL"
	cQuery+= " AND SUBSTRING(C6_DESCRI,1,2) = 'BL'"

	//ORDEM DO RELATORIO, 1 , 2 OU 3
	If mv_par14 == 1

		cQuery+= " ORDER BY C6_FILIAL,C6_PRODUTO"

	ElseIf mv_par14 == 2

		cQuery+= " ORDER BY C6_FILIAL,C6_CLI"

	Else

		cQuery+= " ORDER BY C6_FILIAL,C6_NOTA"

	EndIf

	TcQuery cQuery Alias VDAS New

	DbSelectArea("VDAS")
	DbGoTop()

	ImpCabec()
	ImpCabec1()

	nCont	:= 0
	nM3  	:= 0
	nTotal	:= 0
	cUM 	:= VDAS->C6_UM

	While (!Eof())

		IF(nLin >= 2200)
			ReiniciaPag()
			ImpCabec1()
		EndIf

		nLin1:= 0
		cComp :=Alltrim(Transform(VDAS->C6_COMPLIQ,"@E 99,999.999"))
		cAlt  :=Alltrim(Transform(VDAS->C6_ALTLIQ, "@E 99,999.999"))
		cLarg :=Alltrim(Transform(VDAS->C6_LARGLIQ,"@E 99,999.999"))
		cQuant:=Alltrim(Transform(VDAS->C6_QTDVEN, "@E 99,999.999"))

		oPrn:Say( nLin , 0010 , Alltrim(VDAS->C6_FILIAL)+" / "+Alltrim(VDAS->C6_NUM)		,oFont1)
		oPrn:Say( nLin , 0310 , Substr(VDAS->C6_DATFAT,7,2)+"/"+Substr(VDAS->C6_DATFAT,5,2)+"/"+Substr(VDAS->C6_DATFAT,1,4),oFont1)	
		oPrn:Say( nLin , 0550 , VDAS->C6_NOTA +"- "+VDAS->C6_SERIE ,oFont1)		

		//Quebrar linha na descrição do clinte	
		//Ocultando coluna CLiente - Myrella 05/06/2014
		/*oPrn:Say( nLin , 0850 ,	Substr(Alltrim(VDAS->A1_NOME),1,23),oFont1)

		IF(Len(VDAS->A1_NOME)>23)
		oPrn:Say( nLin + 50 , 0850 , Substr(Alltrim(VDAS->A1_NOME),24,23) ,oFont1)
		nLin1 := 50
		Endif*/

		oPrn:Say( nLin , 1455 , VDAS->C6_LOTECTL								,oFont1)	
		oPrn:Say( nLin , 1700 ,	Substr(Alltrim(VDAS->C6_DESCRI),1,28),oFont1)

		IF(Len(VDAS->C6_DESCRI)>28)
			oPrn:Say( nLin + 50 , 1700 , Substr(Alltrim(VDAS->C6_DESCRI),29,28) ,oFont1)
			nLin1 := 50
		Endif

		oPrn:Say( nLin , 2280 , VDAS->C6_CLASS									,oFont1)
		oPrn:Say( nLin , 2470 , cComp+" x "+cAlt+" x "+cLarg+" = "+cQuant		,oFont1)

		//Ocultando colunas Valor M3 e Valor de blocos - Myrella 05/06/2014
		//MONTAR TESTE SE MOEDA 1 OU 2.
		/*cMoeda:= POSICIONE("SC5",1,VDAS->C6_FILIAL+VDAS->C6_NUM,"SC5->C5_MOEDA")

		If cMoeda == 1
		oPrn:Say( nLin , 2970 , TRANSFORM(VDAS->PRCVEN1,"@E 99,999.999")	,oFont1)
		oPrn:Say( nLin , 3160 , TRANSFORM(VDAS->TOTAL1 ,"@E 9999,999.999")	,oFont1)
		nTotal	+= VDAS->TOTAL1
		Else

		If VDAS->PRCVEN > 0

		oPrn:Say( nLin , 2970 , TRANSFORM(VDAS->PRCVEN,"@E 99,999.999")	,oFont1)
		oPrn:Say( nLin , 3160 , TRANSFORM(VDAS->TOTAL ,"@E 9999,999.999")	,oFont1)

		Else 

		oPrn:Say( nLin, 2970 , "SEM MOEDA CADASTRADA")

		EndIf

		nTotal	+= VDAS->TOTAL

		EndIf*/

		nLin    += 50 + nLin1
		nCont	+= 1
		nM3  	+= VDAS->C6_QTDVEN

		DbSkip()

	EndDo
	//----------------------------------------------------------------------------------------------------
	//Fim Itens - Blocos

	nLin += 50
	oPrn:Say( nLin , 0010 , "Total de Blocos:"		,oFont2)
	oPrn:Say( nLin , 0330 , TRANSFORM(nCont,"@E 999999")	,oFont1)

	//Ocultando valor total de M3 e valor total de bloco - Myrella 05/06/2014
	oPrn:Say( nLin , 2550 , Alltrim(cUM)+": "		,oFont2)
	oPrn:Say( nLin , 2650 , TRANSFORM(nM3,"@E 999,999.999")	,oFont1)

	/*	oPrn:Say( nLin , 2930 , "Valor Total :"		,oFont2)
	oPrn:Say( nLin , 3120 , Transform(nTotal,"@E 999,999,999.99"),oFont1) */ 



	DBSELECTAREA("VDAS")
	DBCloseArea()

Return

/*/
+----------+------------+----------------------------+------+------------+
|Funcao    | ImpRodape  |  Rafael de Castro Almeida  | Data | 27/05/08   |
+----------+------------+----------------------------+------+------------+
|Descricao | Imprime o Rodape do relatorio                               |
+----------+-------------------------------------------------------------+
|Uso       | MSLR001                                                     |
+----------+-------------------------------------------------------------+
/*/

Static Function ImpRodape

	oprn:EndPage()

	MS_FLUSH()

Return

//Imprime Cabeçalho
Static Function ImpCabec()

	oprn:StartPage()

	oPrn:Say( 0000 , 1950 , Substr(DtoS(date()),7,2)+"/"+Substr(DtoS(date()),5,2)+"/"+Substr(DtoS(date()),1,4)+" - "+time()  , oFont2 )
	oPrn:Say( 0030 , 0850 , "Relatorio de Vendas Por Bloco - Sintético" , oFont3 )

	nLin:= 130

Return        

//Imprime Cabeçalho
Static Function ImpCabec1()

	oPrn:Say( nLin , 0010 , "Filial / Pedido"									,oFont2)
	oPrn:Say( nLin , 0310 , "Dat. NF."											,oFont2)
	oPrn:Say( nLin , 0550 , "Num. NF  - Serie"									,oFont2)
	//oPrn:Say( nLin , 0850 , "Cliente"											,oFont2)
	oPrn:Say( nLin , 1450 , "Cód.Bloco"											,oFont2)
	oPrn:Say( nLin , 1700 , "Descrição"											,oFont2)
	oPrn:Say( nLin , 2270 , "Class."											,oFont2)
	oPrn:Say( nLin , 2470 , "Comp x Alt x Larg = "+Alltrim(VDAS->C6_UM)		    ,oFont2)
	//oPrn:Say( nLin , 2950 , "Valor "+Alltrim(VDAS->C6_UM)						,oFont2)
	//oPrn:Say( nLin , 3160 , "Valor Bloco"  										,oFont2)
	nLin+= 70

Return

//Iniciar uma nova pagina
Static Function ReiniciaPag()

	oPrn:EndPage()
	oPrn:StartPage()
	nLin := 0

Return 