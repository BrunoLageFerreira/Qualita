#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
#INCLUDE "TOPCONN.CH"

User Function RelPedC

	//+--------------------------------------------------------------------+
	//| Declaracao de Variaveis                                            |
	//+--------------------------------------------------------------------+

	Local cQuery	:= ""
	Local cPerg 	:= ""

	//+--------------------------------------------------------------------+
	//| Define os estilos de fonte a serem utilizados                      |
	//+--------------------------------------------------------------------+
	Private oFont1 := TFont():New( "Verdana",,10,,.F.,,,,.F.,.F. )
	Private oFont2 := TFont():New( "Verdana",,10,,.T.,,,,.F.,.F. )
	Private oFont3 := TFont():New( "Verdana",,16,,.F.,,,,.F.,.F. )
	Private oFont4 := TFont():New( "Verdana",,08,,.T.,,,,.F.,.F. )

	Private nColIni := 0
	Private nLimite	:= 2350
	Private nColFim := 2330
	Private nLin	:= 0
	Private cEmpresa := ""

	Pergunte("RELPEDC",.T.)

	oPrn := TMSPrinter():New("Entrada de Produtos - Estoque")

	oPrn:SetPaperSize(9) // A4
	//oPrn:SetLandScape(.T.)//Paisagem
	oPrn:setPortrait(.T.) // Retrato
	oPrn:Setup()



	/*
	Perguntas Relatorio:

	Documento De? = mv_par01
	Documento Ate? = mv_par02
	Dt.Emi. De? = mv_par03  
	Dt.Emi. Ate? = mv_par04
	Produto De? = mv_par05
	Produto Ate? = mv_par06
	Cliente De? = mv_par07
	Cliente Ate? = mv_par08
	CFOP? = mv_par09
	Gera Dupl ? = mv_par10
	Mov.Est.? = mv_par11
	Class? 	1=1� = mv_par12
	2=CO
	3=Todas
	*/

	ImpDados()
	ImpRodape()

	oPrn:Preview()

Return

/*/
+----------+------------+----------------------------+------+------------+
|Funcao    | ImpDados   | Myrella| Data | 01/06/16   |
+----------+------------+----------------------------+------+------------+
|Descricao | Imprime o Rodape do relatorio                               |
+----------+-------------------------------------------------------------+
|Uso       | MSLR001                                                     |
+----------+-------------------------------------------------------------+
/*/

Static Function ImpDados

	// QUERY RELATORIO DE VENDAS

	cQuery:= "SELECT C7_FILIAL, C7_PRODUTO, B1_DESC, C7_NUM, A2_NREDUZ, C7_USER
	cQuery+= " FROM SC7050 INNER JOIN SB1050 ON B1_COD = C7_PRODUTO
	cQuery+= " INNER JOIN SA2050 ON A2_COD = C7_FORNECE WHERE C7_NUM BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'


	TcQuery cQuery Alias VDAS New

	DbSelectArea("VDAS")
	DbGoTop()

	ImpCabec()
	ImpCabec1()

	nCont	:= 0
	//nM3  	:= 0
	//nTotal	:= 0
	//cUM 	:= VDAS->C6_UM

	While (!Eof())

		IF(nLin >= 3100)
			ReiniciaPag()
			ImpCabec1()
		EndIf

		nLin1:= 0
		//cComp :=Alltrim(Transform(VDAS->C6_COMPLIQ,"@E 99,999.999"))
		//cAlt  :=Alltrim(Transform(VDAS->C6_ALTLIQ, "@E 99,999.999"))
		//cLarg :=Alltrim(Transform(VDAS->C6_LARGLIQ,"@E 99,999.999"))
		//cQuant:=Alltrim(Transform(VDAS->C6_QTDVEN, "@E 99,999.999"))

		//D3_FILIAL, D3_COD, D3_QUANT, D3_DOC, D3_CUSTO1, D3_USUARIO                                                          	
		/*
		oPrn:Say( nLin , 0010 , "Filial"									,oFont2)
		oPrn:Say( nLin , 0310 , "Produto"											,oFont2)
		oPrn:Say( nLin , 0550 , "Quantidade"									,oFont2)
		oPrn:Say( nLin , 0850 , "Documento"											,oFont2)
		oPrn:Say( nLin , 1450 , "Custo"											,oFont2)
		oPrn:Say( nLin , 1700 , "Usu�rio"											,oFont2)  										
		*/ 
		nLin+= 70

		//oPrn:Say( nLin , 0010 , Alltrim(VDAS->C74_FILIAL)		,oFont1)
		//oPrn:Say( nLin , 0210 , Alltrim(VDAS->C7_NUM)           ,oFont1)	
		oPrn:Say( nLin , 0010 , VDAS->C7_PRODUTO ,oFont1)	
		oPrn:Say( nLin , 0210 , "_______",oFont1)  
		oPrn:Say( nLin , 0410 , VDAS->B1_DESC,oFont1)  
		//oPrn:Say( nLin , 1450 , VDAS->A2_NREDUZ			,oFont1)


		nLin    += 50 + nLin1


		DbSelectArea("VDAS")		
		DbSkip()
	EndDo
	//----------------------------------------------------------------------------------------------------
	//Fim Itens - Blocos

	nLin += 50


	DBSELECTAREA("VDAS")
	DBCloseArea()

Return

/*/
+----------+------------+----------------------------+------+------------+
|Funcao    | ImpRodape  |  MYRELLA GOMES DE SOUSA    | Data | 01/06/16   |
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

//Imprime Cabe�alho
Static Function ImpCabec()

	oprn:StartPage()

	oPrn:Say( 0000 , 1150 , Substr(DtoS(date()),7,2)+"/"+Substr(DtoS(date()),5,2)+"/"+Substr(DtoS(date()),1,4)+" - "+time()  , oFont2 )
	oPrn:Say( 0030 , 0450 , "Entrada de Produtos - Estoque" , oFont3 )

	nLin:= 130

Return        

//Imprime Cabe�alho
Static Function ImpCabec1()

	//	oPrn:Say( nLin , 0010 , "Filial"				,oFont2)
	oPrn:Say( nLin , 0010 , "Pedido: " + VDAS->C7_NUM			,oFont1)
	oPrn:Say( nLin , 0700 , "Fornecedor: " + Alltrim(VDAS->A2_NREDUZ)           ,oFont1)
	//	oPrn:Say( nLin , 0210 , "Pedido"				,oFont2)
	//	oPrn:Say( nLin , 0450 , "Produto"			,oFont2)
	//	oPrn:Say( nLin , 0650 , "Descri��o"				,oFont2)
	//	oPrn:Say( nLin , 1450 , "Fornecedor"				,oFont2)	

	nLin+= 70               


Return

//Iniciar uma nova pagina
Static Function ReiniciaPag()

	oPrn:EndPage()
	oPrn:StartPage()
	nLin := 0

Return 