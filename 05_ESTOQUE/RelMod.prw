#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
#INCLUDE "TOPCONN.CH"

User Function RelMod

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

	Pergunte("RELMOD001",.T.)

	oPrn := TMSPrinter():New("Saída de Produtos - Estoque")

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
|Funcao    | ImpDados   | Myrella| Data | 01/06/16   |
+----------+------------+----------------------------+------+------------+
|Descricao | Imprime o Rodape do relatorio                               |
+----------+-------------------------------------------------------------+
|Uso       | MSLR001                                                     |
+----------+-------------------------------------------------------------+
/*/

Static Function ImpDados

	// QUERY RELATORIO DE VENDAS

	cQuery:= "SELECT D3_FILIAL, D3_COD, B1_DESC, D3_QUANT, D3_DOC, D3_CUSTO1, D3_USUARIO, D3_TM 
	cQuery+= "FROM SD3050 INNER JOIN SB1050 ON B1_COD = D3_COD WHERE D3_DOC BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'

	//	cQuery+= " WHERE D3_DOC BETWEEN '"+mv_par01+"' AND '"mv_par02"'"

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
		oPrn:Say( nLin , 1700 , "Usuário"											,oFont2)  										
		*/ 
		nLin+= 70

		oPrn:Say( nLin , 0010 , Alltrim(VDAS->D3_FILIAL)		,oFont1)
		oPrn:Say( nLin , 0210 , Alltrim(VDAS->D3_DOC)           ,oFont1)	
		oPrn:Say( nLin , 0450 , TRANSFORM(VDAS->D3_QUANT,"@E 99,999.999"),oFont1)	
		oPrn:Say( nLin , 0650 , VDAS->D3_COD ,oFont1)	
		oPrn:Say( nLin , 0850 , VDAS->B1_DESC,oFont1)			
		oPrn:Say( nLin , 1650 ,	TRANSFORM(VDAS->D3_CUSTO1,"@E 99,999.999"),oFont1)		
		oPrn:Say( nLin , 1950 , VDAS->D3_USUARIO			,oFont1)
		oPrn:Say( nLin , 2150 , VDAS->D3_TM			,oFont1)


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

//Imprime Cabeçalho
Static Function ImpCabec()

	oprn:StartPage()

	oPrn:Say( 0000 , 1150 , Substr(DtoS(date()),7,2)+"/"+Substr(DtoS(date()),5,2)+"/"+Substr(DtoS(date()),1,4)+" - "+time()  , oFont2 )
	oPrn:Say( 0030 , 0450 , "Saída de Produtos - Estoque" , oFont3 )

	nLin:= 130

Return        

//Imprime Cabeçalho
Static Function ImpCabec1()

	oPrn:Say( nLin , 0010 , "Filial"				,oFont2)
	oPrn:Say( nLin , 0210 , "Documento"				,oFont2)
	oPrn:Say( nLin , 0450 , "Quant."			,oFont2)
	oPrn:Say( nLin , 0650 , "Produto"				,oFont2)
	oPrn:Say( nLin , 0850 , "Descrição"				,oFont2)	
	oPrn:Say( nLin , 1650 , "Custo"					,oFont2)
	oPrn:Say( nLin , 1950 , "Usuário"				,oFont2)  										
	oPrn:Say( nLin , 2150 , "TM"       				,oFont2)		

	nLin+= 70               


Return

//Iniciar uma nova pagina
Static Function ReiniciaPag()

	oPrn:EndPage()
	oPrn:StartPage()
	nLin := 0

Return 