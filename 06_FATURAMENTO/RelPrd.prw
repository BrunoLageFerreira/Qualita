#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
#INCLUDE "TOPCONN.CH"

User Function RelPrd

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
	Private nLin1	:= 0
	Private cUM		:= ""
	Private	cEmpresa := ""
	oprn:=TMSPrinter():New("Relatorio de Produtos nao Faturados Por Bloco")

	oPrn:SetPaperSize(9) // A4
	oPrn:SetLandScape(.T.)//Paisagem
	//oPrn:setPortrait() // Retrato
	oPrn:Setup()

	Pergunte("RELPRD",.T.)

	/* 
	Perguntas para relatorio.

	Filial De? = mv_par01
	Filial Ate? = mv_par02
	Dt.Emiss De? = mv_par03
	Dt.Emiss Ate? = mv_par04
	Produto De? = mv_par05
	Produto Ate? = mv_par06
	Cliente De? = mv_par07
	Cliente Ate? = mv_par08 
	Faturados? = mv_par09
	*/

	ImpDados()
	ImpRodape()

	oPrn:Preview()

Return

/*/
+----------+------------+----------------------------+------+------------+
|Funcao    | ImpDados   |  Rafael de Castro Almeida  | Data | 27/05/08   |
+----------+------------+----------------------------+------+------------+
|Descricao | Imprime o Rodape do relatorio                               |
+----------+-------------------------------------------------------------+
|Uso       | MSLR001                                                     |
+----------+-------------------------------------------------------------+
/*/

Static Function ImpDados
	// QUERY RELATORIO DE VENDAS
	cQuery:= "SELECT C6_FILIAL,C6_NUM,C6_LOTECTL,C6_DESCRI,C5_EMISSAO,"
	cQuery+= " C6_COMPLIQ,C6_ALTLIQ,C6_LARGLIQ,C6_QTDVEN,C6_UM,C6_CLASS,A1_NOME,C6_PRCVEN,C6_VALOR FROM SC6050"
	//RELACIONAR EMISSAO DOS PEDIDOS PARA IMPRESSAO E FILTRO
	cQuery+= " INNER JOIN SC5050 ON"
	cQuery+= " C5_FILIAL = C6_FILIAL AND C5_NUM = C6_NUM AND"
	cQuery+= " SC5050.D_E_L_E_T_ = ''"
	// FILTRAR SE GERAR ESTOQUE E FINANCEIRO
	cQuery+= " INNER JOIN SF4050 ON"
	cQuery+= " F4_CODIGO = C6_TES"
	// BUSCAR NOME DO CLIENTE PARA FACILITAR EXIBICAO.
	cQuery+= " INNER JOIN SA1050 ON"
	cQuery+= " A1_COD = C6_CLI AND A1_LOJA = C6_LOJA"
	cQuery+= " WHERE C6_FILIAL BETWEEN '"+mv_par01+"' AND '"+mv_par02+"' AND C5_EMISSAO BETWEEN '"+DTOS(mv_par03)+"' AND '"+DTOS(mv_par04)+"'"
	//FILTRAR SOMENTE PEDIDOS NAO FATURADOS 
	cQuery+= " AND C6_BLQ <> 'R'"
	If mv_par09 == 1
		cQuery+= " AND C6_NOTA <> ''"  
	ElseIf mv_par09 == 2
		cQuery+= " AND C6_NOTA = ''"  
	Endif
	cQuery+= " AND SC6050.D_E_L_E_T_ = '' AND C6_PRODUTO BETWEEN '"+mv_par05+"' AND '"+mv_par06+"' AND C6_CLI BETWEEN '"+mv_par07+"' AND '"+mv_par08+"'"
	//IF VARIAVEL IGUAL VAZIO BUSCA TODOS, SENAO SOMENTE A LISTA.
	cQuery+= " AND C6_CF <> ''"
	// IF SIM OU NAO
	cQuery+= " AND F4_ESTOQUE = 'S'"
	// IF SIM OU NAO
	cQuery+= " AND F4_DUPLIC = 'S'"
	// PROBLEMA, POIS NEM TODOS OS PEDIDOS ESTAO COM CLASSIFICACAO. VERIFICAR COM HARLEI.
	// A PRINCIPIO SERA UTILIZADO TODOS NO FILTRO, DEPOIS 1 OU 2
	cQuery+= " AND C6_CLASS IN ('','1ª','CO')"
	// INIBIR NOTAS FISCAIS DE DEVOLUCAO.
	cQuery+= " AND C6_NFORI = ''"
	//ORDEM DO RELATORIO, 1 , 2 OU 3
	cQuery+= " ORDER BY C6_FILIAL,C6_PRODUTO"
	//cQuery+= " ORDER BY C6_FILIAL,C6_CLI"
	//cQuery+= " ORDER BY C6_FILIAL,C6_NOTA"

	TcQuery cQuery Alias PRD New

	DbSelectArea("PRD")
	DbGoTop()

	ImpCabec()
	ImpCabec1()

	nCont	:= 0
	nM3  	:= 0
	nTotal	:= 0
	cUM 	:= PRD->C6_UM

	While (!Eof())

		IF(nLin >= 2200)
			ReiniciaPag()
			ImpCabec1()
		EndIf

		nLin1:= 0
		cComp :=Alltrim(Transform(PRD->C6_COMPLIQ,"@E 99,999.999"))
		cAlt  :=Alltrim(Transform(PRD->C6_ALTLIQ, "@E 99,999.999"))
		cLarg :=Alltrim(Transform(PRD->C6_LARGLIQ,"@E 99,999.999"))
		cQuant:=Alltrim(Transform(PRD->C6_QTDVEN, "@E 99,999.999"))

		oPrn:Say( nLin , 0010 , Alltrim(PRD->C6_FILIAL)+" / "+Alltrim(PRD->C6_NUM)		,oFont1)
		oPrn:Say( nLin , 0310 , PRD->C6_LOTECTL								,oFont1)	
		//Descricao do Produto
		oPrn:Say( nLin , 0540 ,	Substr(Alltrim(PRD->C6_DESCRI),1,30),oFont1)
		IF(Len(PRD->C6_DESCRI)>30)
			oPrn:Say( nLin + 50 , 0540 , Substr(Alltrim(PRD->C6_DESCRI),31,30) ,oFont1)
			nLin1 := 50
		Endif	
		oPrn:Say( nLin , 1150 , Substr(PRD->C5_EMISSAO,7,2)+"/"+Substr(PRD->C5_EMISSAO,5,2)+"/"+Substr(PRD->C5_EMISSAO,1,4),oFont1)	
		oPrn:Say( nLin , 1400 , cComp	,oFont1)
		oPrn:Say( nLin , 1550 , cAlt	,oFont1)
		oPrn:Say( nLin , 1700 , cLarg	,oFont1)
		oPrn:Say( nLin , 1900 , cQuant	,oFont1)	
		oPrn:Say( nLin , 2150 , PRD->C6_CLASS									,oFont1)
		//Quebrar linha na descrição do clinte	
		oPrn:Say( nLin , 2350 ,	Substr(Alltrim(PRD->A1_NOME),1,40),oFont1)
		IF(Len(PRD->A1_NOME)>40)
			oPrn:Say( nLin + 50 , 2350 , Substr(Alltrim(PRD->A1_NOME),41,30) ,oFont1)
			nLin1 := 50
		Endif

		nLin    += 50 + nLin1
		nCont	+= 1
		nM3  	+= PRD->C6_QTDVEN

		DbSkip()
	End
	//----------------------------------------------------------------------------------------------------
	//Fim Itens - Blocos

	IF(nLin >= 1500)
		ReiniciaPag()
	EndIf

	nLin += 50
	oPrn:Say( nLin , 0010 , "Total de Blocos:"		,oFont2)
	oPrn:Say( nLin , 0330 , TRANSFORM(nCont,"@E 999999")	,oFont1)
	nLin += 50
	oPrn:Say( nLin , 0010 , "Total de "+Alltrim(cUM)+": "		,oFont2)
	oPrn:Say( nLin , 0330 , TRANSFORM(nM3,"@E 999,999.999")	,oFont1)
	nLin += 50                                                                              
	nUM := Alltrim(PRD->C6_UM)
	oPrn:Say( nLin , 0010 , "Resumo da Listagem por Filial / Classificação:"		,oFont2)
	oPrn:Say( nLin , 0910 , "Resumo da Listagem por Classificação:"		,oFont2)
	nLin += 50

	oPrn:Say( nLin , 0010 , "Filial"							,oFont2)
	oPrn:Say( nLin , 0210 , "Classif."							,oFont2)
	oPrn:Say( nLin , 0410 , "Medida "+nUM						,oFont2)
	oPrn:Say( nLin , 0610 , "Porcent.(%)"						,oFont2)


	oPrn:Say( nLin , 0910 , "Classif."							,oFont2)
	oPrn:Say( nLin , 1110 , "Medida "+nUM						,oFont2)
	oPrn:Say( nLin , 1310 , "Porcent.(%)"						,oFont2)

	DBSELECTAREA("PRD")
	DBCloseArea()

	//-- QUERY RELATORIO DE PRODUTOS NAO FATURADOS POR CLASSIFICACAO
	cQuery := "SELECT C6_FILIAL,C6_CLASS,SUM(C6_QTDVEN) AS QTDVEN FROM SC6050"
	cQuery += " INNER JOIN SC5050 ON"
	cQuery += " C5_FILIAL = C6_FILIAL AND C5_NUM = C6_NUM AND"
	cQuery += " SC5050.D_E_L_E_T_ = ''"
	//-- FILTRAR SE GERAR ESTOQUE E FINANCEIRO
	cQuery += " INNER JOIN SF4050 ON"
	cQuery += " F4_CODIGO = C6_TES"
	//-- BUSCAR NOME DO CLIENTE PARA FACILITAR EXIBICAO.
	cQuery += " INNER JOIN SA1050 ON"
	cQuery += " A1_COD = C6_CLI AND A1_LOJA = C6_LOJA"
	cQuery += " WHERE C6_FILIAL BETWEEN '"+mv_par01+"' AND '"+mv_par02+"' AND C5_EMISSAO BETWEEN '"+DTOS(mv_par03)+"' AND '"+DTOS(mv_par04)+"'"
	cQuery += " AND SC6050.D_E_L_E_T_ = '' AND C6_PRODUTO BETWEEN '"+mv_par05+"' AND '"+mv_par06+"' AND C6_CLI BETWEEN '"+mv_par07+"' AND '"+mv_par08+"'"
	//--IF VARIAVEL IGUAL VAZIO BUSCA TODOS, SENAO SOMENTE A LISTA.
	cQuery += " AND C6_BLQ <> 'R'"
	If mv_par09 == 1
		cQuery+= " AND C6_NOTA <> ''"  
	ElseIf mv_par09 == 2
		cQuery+= " AND C6_NOTA = ''"  
	Endif
	cQuery += " AND C6_CF <> ''"
	//-- IF SIM OU NAO
	cQuery += " AND F4_ESTOQUE = 'S'"
	//-- IF SIM OU NAO
	cQuery += " AND F4_DUPLIC = 'S'"
	//-- PROBLEMA, POIS NEM TODOS OS PEDIDOS ESTAO COM CLASSIFICACAO. VERIFICAR COM HARLEI.
	//-- A PRINCIPIO SERA UTILIZADO TODOS NO FILTRO, DEPOIS 1 OU 2
	cQuery += " AND C6_CLASS IN ('','1ª','CO')"
	//-- INIBIR NOTAS FISCAIS DE DEVOLUCAO.
	cQuery += " AND C6_NFORI = ''"        
	//--ORDEM DO RELATORIO, 1 , 2 OU 3
	cQuery += " GROUP BY C6_FILIAL,C6_CLASS"

	TcQuery cQuery Alias CLAS New

	DbSelectArea("CLAS")
	DbGoTop()
	nClas  := 0
	nClas0 := 0
	nClas1 := 0
	nClas2 := 0
	nLin1  := nLin
	While (!Eof())
		nLin += 50
		oPrn:Say( nLin , 0010 , CLAS->C6_FILIAL									,oFont1)
		oPrn:Say( nLin , 0210 , CLAS->C6_CLASS									,oFont1)
		oPrn:Say( nLin , 0410 , TRANSFORM(CLAS->QTDVEN,"@E 999,999.999")		,oFont1)
		oPrn:Say( nLin , 0610 , TRANSFORM((CLAS->QTDVEN/nM3)*100,"@E 999,999.999")	,oFont1)
		IF(Alltrim(CLAS->C6_CLASS) = '')
			nClas0 += CLAS->QTDVEN
		ElseIF(CLAS->C6_CLASS = '1ª')
			nClas1 += CLAS->QTDVEN
		ElseIF(CLAS->C6_CLASS = 'CO')
			nClas2 += CLAS->QTDVEN
		EndIf
		nClas += CLAS->QTDVEN
		DbSkip()
	End
	nLin += 50
	oPrn:Say( nLin , 0210 , "Total :"	,oFont2)
	oPrn:Say( nLin , 0410 , TRANSFORM(nClas,"@E 999,999.999")	,oFont2)
	oPrn:Say( nLin , 0610 , TRANSFORM((nClas/nM3)*100,"@E 999,999.999")	,oFont2)
	nLin1 += 50
	oPrn:Say( nLin1 , 0910 , ""				,oFont1)
	oPrn:Say( nLin1 , 1110 , TRANSFORM(nClas0,"@E 999,999.999")			,oFont1)
	oPrn:Say( nLin1 , 1310 , TRANSFORM((nClas0/nM3)*100,"@E 999,999.999")		,oFont1)
	nLin1 += 50   
	oPrn:Say( nLin1 , 0910 , "1ª"				,oFont1)
	oPrn:Say( nLin1 , 1110 , TRANSFORM(nClas1,"@E 999,999.999")			,oFont1)
	oPrn:Say( nLin1 , 1310 , TRANSFORM((nClas1/nM3)*100,"@E 999,999.999")		,oFont1)
	nLin1 += 50
	oPrn:Say( nLin1 , 0910 , "CO"				,oFont1)
	oPrn:Say( nLin1 , 1110 , TRANSFORM(nClas2,"@E 999,999.999")			,oFont1)
	oPrn:Say( nLin1 , 1310 , TRANSFORM((nClas2/nM3)*100,"@E 999,999.999")		,oFont1)

	nLin1 += 50
	nTot:= nClas0+nClas1+nClas2
	oPrn:Say( nLin1 , 0910 , "Total :"	,oFont2)
	oPrn:Say( nLin1 , 1110 , TRANSFORM(nTot,"@E 999,999.999")		,oFont2)
	oPrn:Say( nLin1 , 1310 , TRANSFORM((nTot/nM3)*100,"@E 999,999.999")		,oFont2)

	DBSELECTAREA("CLAS")
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
	oPrn:Say( 0030 , 0850 , "Relatorio de Produtos nao Faturados Por Bloco" , oFont3 )

	nLin:= 130
Return        

//Imprime Cabeçalho
Static Function ImpCabec1()

	oPrn:Say( nLin , 0010 , "Filial / Pedido"									,oFont2)
	oPrn:Say( nLin , 0310 , "Cód.Bloco"											,oFont2)
	oPrn:Say( nLin , 0540 , "Descrição"											,oFont2)
	oPrn:Say( nLin , 1150 , "Data"												,oFont2)
	oPrn:Say( nLin , 1400 , "Compr."											,oFont2)
	oPrn:Say( nLin , 1550 , "Altuta"											,oFont2)
	oPrn:Say( nLin , 1700 , "Largura"											,oFont2)
	oPrn:Say( nLin , 1900 , "Medida "+Alltrim(cUM)									,oFont2)
	oPrn:Say( nLin , 2150 , "Class."											,oFont2)
	oPrn:Say( nLin , 2350 , "Cliente"	  										,oFont2)
	nLin+= 70

Return

//Iniciar uma nova pagina
Static Function ReiniciaPag()

	oPrn:EndPage()
	oPrn:StartPage()
	nLin := 0
	nLin1 := 0

Return 