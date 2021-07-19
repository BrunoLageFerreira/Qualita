#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
#INCLUDE "TOPCONN.CH"

User Function AutPagR

	//+--------------------------------------------------------------------+
	//| Declaracao de Variaveis                                            |
	//+--------------------------------------------------------------------+

	Local cQuery	:= ""  

	//+--------------------------------------------------------------------+
	//| Define os estilos de fonte a serem utilizados                      |
	//+--------------------------------------------------------------------+
	Private oFont1 := TFont():New( "Arial",,10,,.F.,,,,.F.,.F. ) 
	Private oFont2 := TFont():New( "Arial",,10,,.T.,,,,.F.,.F. ) 
	Private oFont3 := TFont():New( "Arial",,25,,.F.,,,,.F.,.F. ) 
	Private oFont4 := TFont():New( "Arial",,20,,.F.,,,,.F.,.F. )

	Private nColIni := 0
	Private nColFim := 2350 

	Private	cEmpresa := ""
	oprn:=TMSPrinter():New("Solicitação de Pagamento")  

	oPrn:SETPAPERSIZE(9) // A4
	oPrn:setPortrait()   // Retrato
	oPrn:Setup()

	ImpCabec()
	ImpEsqueleto()
	ImpDados()
	ImpRodape()

	oPrn:Preview()

Return

/*/
+----------+------------+----------------------------+------+------------+
|Funcao    | ImpCabec   |  Rafael de Castro Almeida  | Data | 27/05/08   |
+----------+------------+----------------------------+------+------------+
|Descricao | Imprime o cabecalho do relatorio                            |
+----------+-------------------------------------------------------------+
|Uso       | MSLR001                                                     |
+----------+-------------------------------------------------------------+ 
/*/

Static Function ImpCabec

	oprn:StartPage()

	//+--------------------------------------------------------+
	//| Preparacao para impressão do cabeçalho                 |
	//+--------------------------------------------------------+
	oPrn:Box ( 0060 , nColIni , 0300 , nColFim )
	oPrn:Line( 0060 , 0460 , 0300 , 0460 )
	oPrn:Line( 0060 , 1950 , 0300 , 1950 )


	//cEmpresa := "itinga.bmp"  


	oPrn:SayBitmap( 0100 , 0120 , cEmpresa , 200 , 200 )

	oPrn:Say( 0140 , 0670 , "Solicitação de Pagamento" , oFont3 )
	oPrn:Say( 0070 , 1960 , "N°" , oFont2 )	
	oPrn:Say( 0140 , 2030 , SZ2->Z2_NUM , oFont4 , , CLR_RED )	

Return

/*/
+----------+------------+----------------------------+------+------------+
|Funcao    | ImpCorpo   |  Rafael de Castro Almeida  | Data | 27/05/08   |
+----------+------------+----------------------------+------+------------+
|Descricao | Imprime o Corpo  do relatorio                               |
+----------+-------------------------------------------------------------+
|Uso       | MSLR001                                                     |
+----------+-------------------------------------------------------------+ 
/*/

Static Function ImpEsqueleto 

	//	oPrn:Box ( 0320 , nColIni , 1800 , nColFim )
	
	oPrn:Say ( 0330 , nColIni + 10 , "Área Solicitante", oFont2 )
	oPrn:Line( 0320 , 1170 , 0485 , 1170 )	

	oPrn:Say ( 0330 , 1180 , "Competência", oFont2 )
	oPrn:Line( 0320 , 1560 , 0485 , 1560 )

	oPrn:Say ( 0330 , 1570 , "Valor a Pagar", oFont2 )			
	oPrn:Line( 0320 , 1950 , 0485 , 1950 )	

	oPrn:Say ( 0330 , 1960 , "Vencimento", oFont2 )
	oPrn:Line( 0485 , nColIni , 0485 , nColFim )

	oPrn:Say ( 0495 , nColIni + 10 , "Valor por Extenso", oFont2 )

	oPrn:Line( 0785 , nColIni , 0785 , nColFim )
	oPrn:Say ( 0795 , nColIni + 10 , "Favorecido", oFont2 )


	oPrn:Line( 1025 , nColIni , 1025 , nColFim )
	oPrn:Say ( 1035 , nColIni + 10 , "Descrição", oFont2 )


	/*	
	oPrn:Line( 1635 , nColIni , 1635 , nColFim )
	oPrn:Say ( 1645 , nColIni + 10 , "Data Emissão", oFont2 )
	oPrn:Line( 1635 , 0460 , 1800 , 0460 )
	oPrn:Say ( 1645 , 0470 , "Solicitante", oFont2 )
	oPrn:Line( 1635 , 1500 , 1800 , 1500 )
	oPrn:Say ( 1645 , 1510 , "Aprovação", oFont2 )
	oPrn:Box ( 1820 , nColIni , 1985 , nColFim )
	oPrn:Say ( 1830 , nColIni + 10 , "Centro de Custo" , oFont2 )
	oPrn:Line( 1820 , 1000 , 1985 , 1000 )	
	oPrn:Say ( 1830 , 1010 , "Conta Contábil" , oFont2 )
	oPrn:Line( 1890 , nColIni , 1890 , nColFim )	
	*/

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

	cAreaSol:= Alltrim(SM0->M0_NOMECOM)+ " - " + Alltrim(SM0->M0_FILIAL)
	cNomeCC := Posicione("CTT",1,xFilial("CTT")+SZ2->Z2_CCC,"CTT_DESC01")
	cNomeCT := Posicione("CT1",1,xFilial("CT1")+SZ2->Z2_CONTAD,"CT1_DESC01")                
	cBanco := Posicione("SA2",1,xFilial("SA2")+SZ2->Z2_FORNECE,"A2_BANCO")
	cAgencia := Posicione("SA2",1,xFilial("SA2")+SZ2->Z2_FORNECE,"A2_AGENCIA")
	cConta := Posicione("SA2",1,xFilial("SA2")+SZ2->Z2_FORNECE,"A2_NUMCON")
	cNomeBanco := AllTrim(Posicione("SA6",1,xFilial("SA6")+cBanco,"A6_NOME"))

	cMes	:= MesExtenso(Val(SZ2->Z2_MESBASE))

	dDataFor:= Substr(DtoS(SZ2->Z2_VENCREA),7,2)+"/"+Substr(DtoS(SZ2->Z2_VENCREA),5,2)+"/"+Substr(DtoS(SZ2->Z2_VENCREA),1,4)

	oPrn:Say ( 0403 , nColIni + 10, cAreaSol , oFont1)
	oPrn:Say ( 0403 , 1180 , cMes + "/"+SZ2->Z2_ANOBASE , oFont1)
	oPrn:Say ( 0403 , 1650 , TRANSFORM(SZ2->Z2_VALOR,"@E 999,999,999.99") , oFont1)

	oPrn:Say ( 0403 , 2100 , dDataFor , oFont1)

	cMensa 	:= Alltrim(Extenso(SZ2->Z2_VALOR))
	cLinha1 := Memoline(cMensa,110,1)
	cLinha2 := Memoline(cMensa,110,2)

	oPrn:Say ( 0570 , nColIni + 10 , cLinha1 , oFont1 )
	oPrn:Say ( 0630 , nColIni + 10 , cLinha2 , oFont1 )	

	oPrn:Say ( 0880 , nColIni + 10 , SZ2->Z2_NOMFOR , oFont1 )
	oPrn:Say ( 0930 , nColIni + 10 , "Dados Bancarios: " + cBanco + " - " + cNomeBanco + " - " + cAgencia + " - " + cConta , oFont1 )

	nLin := 1110

	For I:=1 to MlCount(SZ2->Z2_DESCRIC,110)

		cLine:= Memoline(SZ2->Z2_DESCRIC,110,i)

		If !Empty(cline)

			oPrn:Say ( nLin , nColIni + 10 , cLine , oFont1 )		

			nlin += 60

		Endif

	Next I

	dDataFor := Substr(DtoS(SZ2->Z2_EMISSAO),7,2)+"/"+Substr(DtoS(SZ2->Z2_EMISSAO),5,2)+"/"+Substr(DtoS(SZ2->Z2_EMISSAO),1,4)

	/*	oPrn:Say ( 1710 , nColIni + 60 , dDataFor , oFont1 )

	oPrn:Say ( 1710 , 0470 , SZ2->Z2_SOLICIT , oFont1 )	

	If !Empty(SZ2->Z2_APROVA)
	oPrn:Say ( 1710 , 1510 , SZ2->Z2_APROVA , oFont1 )	
	EndIf

	oPrn:Say ( 1920 , nColIni + 10, ALLTRIM(SZ2->Z2_CCC) + " - " + ALLTRIM(cNomeCC) , oFont1 )

	oPrn:Say ( 1920 , 1010, ALLTRIM(SZ2->Z2_CONTAD) + " - " + ALLTRIM(cNomeCT) , oFont1 )*/

	// Mudanças para correção quando a Observação for muito extensa.
	// Necessario utilizar a variavel no local da linha, que estava fixa.
	//--------------------------Inicio	
	nLin := nLin + 50

	oPrn:Box ( 0320 , nColIni , nLin + 165 , nColFim )

	oPrn:Line( nLin , nColIni , nLin , nColFim )

	oPrn:Say ( nLin + 10 , nColIni + 10 , "Data Emissão", oFont2 )

	oPrn:Say ( nLin + 75 , nColIni + 60 , dDataFor , oFont1 )

	oPrn:Line( nLin , 0460 , nLin + 165 , 0460 )

	oPrn:Say ( nLin + 10 , 0470 , "Solicitante", oFont2 )

	oPrn:Say ( nLin + 75 , 0470 , SZ2->Z2_SOLICIT , oFont1 )	

	oPrn:Line( nLin , 1500 , nLin + 165 , 1500 )

	oPrn:Say ( nLin + 10 , 1510 , "Aprovação", oFont2 )

	If !Empty(SZ2->Z2_APROVA)
		oPrn:Say ( nLin + 75 , 1510 , SZ2->Z2_APROVA , oFont1 )	
	EndIf

	nLin := nLin + 185

	oPrn:Box ( nLin , nColIni , nLin + 165 , nColFim )

	oPrn:Say ( nLin + 10 , nColIni + 10 , "Centro de Custo" , oFont2 )

	oPrn:Say ( nLin + 100 , nColIni + 10, ALLTRIM(SZ2->Z2_CCC) + " - " + ALLTRIM(cNomeCC) , oFont1 )	

	oPrn:Line( nLin , 1000 , nLin + 165 , 1000 )

	oPrn:Say ( nLin + 10 , 1010 , "Conta Contábil" , oFont2 )

	oPrn:Say ( nLin + 100 , 1010, ALLTRIM(SZ2->Z2_CONTAD) + " - " + ALLTRIM(cNomeCT) , oFont1 )

	oPrn:Line( nLin + 70 , nColIni , nLin + 70 , nColFim )
	//--------------------------Fim

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