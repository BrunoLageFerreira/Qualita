#INCLUDE "PROTHEUS.CH"
#INCLUDE "RWMAKE.CH"


//+----------+-----------+----------+-------------------------+------+-----------+
//|Programa  |RELCUSTO   | Autor    |Marco Tulio M. Vianna    |Data  |30.10.2012 |
//+----------+-----------+----------+-------------------------+------+-----------+  
//|Descricao | Relatorio de Custos                                               |
//+----------+-------------------------------------------------------------------+
//| USO      | Estoque e Custos                                                  |
//+----------+-------------------------------------------------------------------+
//|                    ALTERACOES FEITAS DESDE A CRIACAO                         |
//+----------+-----------+-------------------------------------------------------+
//|Autor     | Data      | DescriГЦo                                             |
//+----------+-----------+-------------------------------------------------------+
//|          |           |                                                       |
//+----------+-----------+-------------------------------------------------------+


User Function Relcusto()

	//	Local oBTNCancelar
	//	Local oBTNOk
	//	Local oGETData
	//	Local dGETDatade := Date()
	//	Local dGETDataate := Date()
	//	Local oGPRImpCP
	//	Local oLBLData
	//	Static oDLGImpCP

	//  	DEFINE MSDIALOG oDLGImpCP FROM 000, 000  TO 150, 400 COLORS 0, 16777215 PIXEL

	//    @ 005, 005 GROUP oGPRImpCP TO 069, 193 PROMPT "Monta Tabelas Para RelatСrio de Custos" OF oDLGImpCP COLOR 0, 16777215 PIXEL
	//    @ 046, 044 BUTTON oBTNOk PROMPT "&OK" SIZE 037, 012 OF oDLGImpCP ACTION (MsgRun("Rel. Custos","Aguarde",{||fImporta(dGETDatade,dGetDataate)}),oDLGImpCP:End())  PIXEL 
	//    @ 045, 106 BUTTON oBTNCancelar PROMPT "&Cancelar" SIZE 037, 012 OF oDLGImpCP ACTION oDLGImpCP:End() PIXEL
	//    @ 026, 009 SAY oLBLData PROMPT "Data de: " SIZE 048, 007 OF oDLGImpCP COLORS 0, 16777215 PIXEL
	//    @ 023, 054 MSGET oGETData VAR dGETDatade SIZE 060, 010 OF oDLGImpCP COLORS 0, 16777215 PIXEL
	//    @ 036, 009 SAY oLBLData PROMPT "Data ate: " SIZE 048, 007 OF oDLGImpCP COLORS 0, 16777215 PIXEL
	//    @ 033, 054 MSGET oGETData VAR dGETDataate SIZE 060, 010 OF oDLGImpCP COLORS 0, 16777215 PIXEL

	//  	ACTIVATE MSDIALOG oDLGImpCP CENTERED

	//Return

	//здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд©
	//Ё Define Variaveis                                             Ё
	//юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддды
	LOCAL CbTxt
	LOCAL cString:= "SD2"
	LOCAL CbCont,cabec1,cabec2
	LOCAL titulo := OemToAnsi("Relatorio de Custos")	//"Relatorio de Custos"
	LOCAL cDesc1 := OemToAnsi("Emissao do Relatorio de Custos")	//"Emissao do Relatorio de Custos "
	LOCAL cDesc2 := OemToAnsi(" ")	//""
	LOCAL cDesc3 := OemToAnsi(" ")	//""
	LOCAL tamanho:= "G" 
	LOCAL nTipo    := 0
	LOCAL limite := 65
	LOCAL lImprime := .T.
	cGrtxt := SPACE(11)
	PRIVATE aReturn := { "REL. CUSTOS", 1,"REL. CUSTOS", 1, 2, 1, "",1 }		//"Zebrado"###"Administracao"
	PRIVATE nomeprog:="RELCUSTO"
	PRIVATE nLastKey := 0
	PRIVATE cPerg   :="RELCUSTO"  

	//здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд©
	//Ё Variaveis utilizadas para Impressao do Cabecalho e Rodape    Ё
	//юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддды
	cbtxt    := SPACE(10)
	cbcont   := 00
	li       := 132
	m_pag    := 01
	//здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд©
	//Ё Verifica as perguntas selecionadas                           Ё
	//юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддды
	//AjustaSX1()
	pergunte("RELCUSTO",.T.)
	//здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд©
	//Ё Variaveis utilizadas para parametros                         Ё
	//Ё mv_par01      A partir de                                    Ё
	//Ё mv_par02      Ate a Data                                     Ё
	//Ё mv_par03      Centro de Custo de                             Ё
	//Ё mv_par04      Centro de Custo AtИ                            Ё
	//  mv_par05      Filial de                                      Ё 
	//  mv_par06      Filial ate                                     Ё
	//юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддды

	//здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд©
	//Ё Envia controle para a funcao SETPRINT                        Ё
	//юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддды
	wnrel:="RELCUSTO"            //Nome Default do relatorio em Disco

	//aOrd :={STR0007,STR0008,STR0009,STR0010,STR0011,STR0036}		//"Por Tp/Saida+Produto"###"Por Tipo    "###"Por Grupo  "###"P/Ct.Contab."###"Por Produto " ### "Por Tp Saida + Serie + Nota "
	aOrd :={"NATUREZA"}		
	//wnrel:=SetPrint(cString,wnrel,cPerg,titulo,cDesc1,cDesc2,cDesc3,.T.,aOrd,,Tamanho)
	wnrel:=SetPrint(,wnrel,cPerg,titulo,cDesc1,cDesc2,cDesc3,.T.,aOrd,,Tamanho)

	If nLastKey==27
		dbClearFilter()
		Return
	Endif

	SetDefault(aReturn,cString)

	If nLastKey==27
		dbClearFilter()
		Return
	Endif

	RptStatus({|lEnd| fImprime(@lEnd,wnRel,cString)},Titulo)

Return


/*+----------+-----------+----------+-------------------------+------+-----------+
|Programa  |fImprime   | Autor    |Marco TЗlio M. Vianna    |Data  |29.10.2012 |
+----------+-----------+----------+-------------------------+------+-----------+
|Descricao | Programa de Impressao P/ RelatСrio de Custos                      |
+----------+-------------------------------------------------------------------+
| USO      | Financeiro                                                       |
+----------+-------------------------------------------------------------------+
|                    ALTERACOES FEITAS DESDE A CRIACAO                         |
+----------+-----------+-------------------------------------------------------+
|Autor     | Data      | DescriГЦo                                             |
+----------+-----------+-------------------------------------------------------+
|          |           |                                                       |
+----------+-----------+-------------------------------------------------------+ 
*/  	

Static Function fImprime(lEnd,WnRel,cString)

	Local cQuery 
	Local cQryFP   
	Local cQryTF
	Local cArq    := ""
	Local cArquivo:= ""
	Local cFil    := ""
	Local cDataArqde  := ""
	Local cTipoDoc:= ""
	Local cTipoFiltro := ""                
	Local dEmissao:= Ctod("")
	Local aArea   := GetArea()
	Local aSelecDocs  := {}
	Local lFiltro  := .T.
	Local nTotalFat := 0
	Local aPrdCusto := {}
	Local aPercCusto := {}
	Local aNatCusto := {}
	Local aQtdeCusto := {}
	Local aTotalCusto := {}
	Local aTotalFat := {}
	Local aNatCod := {}
	Local aNatValor := {}
	Local aFator := {}
	Local aCodDev := {}
	Local aPrdDev := {}           
	Local aPrdQTDV := {}
	Local nI := 0
	Local nJ := 0 
	Local Tamanho := "P"
	Local nTipo := 0
	//LOCAL wnrel := "RELCUSTO"
	Private cArqTmp
	Private cArqTfp
	Private cArqTtf   
	Private Li
	cDataArqde :=  Substr(DtoC(MV_PAR01),7,4)+Substr(DtoC(MV_PAR01),4,2)+Substr(DtoC(MV_PAR01),1,2)
	cDataArqate := Substr(DtoC(MV_PAR02),7,4)+Substr(DtoC(MV_PAR02),4,2)+Substr(DtoC(MV_PAR02),1,2)

	If Alltrim(MV_PAR03 ) <= ""
		MV_PAR03 := "0"
	Endif                 
	/*
	cQuery := "SELECT DISTINCT(E2_NUM+E2_FORNECE+E2_LOJA), E2_NATUREZ, DE_DOC,DE_SERIE,DE_CC,DE_CUSTO1 AS CUSTO,D1_COD from " + RetSqlName("SDE") + " SDE050, " +  RetSqlName("SD1") + " SD1050, "  +  RetSqlName("SF1") + " SF1050, " +  RetSqlName("SE2") + " SE2050 "
	cQuery += "WHERE D1_ITEM = DE_ITEMNF AND"
	cQuery += " E2_FORNECE = DE_FORNECE AND E2_LOJA = DE_LOJA AND E2_NUM = DE_DOC AND"
	cQuery += " D1_FORNECE = DE_FORNECE AND D1_LOJA = DE_LOJA AND D1_DOC = DE_DOC AND"
	cQuery += " F1_FORNECE = DE_FORNECE AND F1_LOJA = DE_LOJA AND F1_DOC = DE_DOC AND"    
	cQuery += " F1_EMINFE BETWEEN '" + cDataArqde + "' AND '" + cDataArqate + "' AND" 
	cQuery += " F1_FILIAL >= '" + MV_PAR05 + "' AND F1_FILIAL <= '" + MV_PAR06 + "' AND"
	cQuery += " DE_CC >= '" + MV_PAR03 + "' AND DE_CC <= '" + MV_PAR04 + "' AND"                                      
	cQuery += " SF1050.D_E_L_E_T_ <> '*' AND"
	cQuery += " SD1050.D_E_L_E_T_ <> '*' AND"
	cQuery += " SDE050.D_E_L_E_T_ <> '*'" 
	cQuery += " ORDER BY DE_CC, E2_NATUREZ"       
	*/        

	//Bruno Lage                           
	// COM RATEIO CDE
	cQuery := "SELECT DISTINCT(E2_NUM+E2_FORNECE+E2_LOJA), E2_NATUREZ, DE_DOC,DE_SERIE,DE_CC,DE_CUSTO1 AS CUSTO,D1_COD 
	cQuery += "  FROM " + RetSqlName("SDE") + " SDE050, " +  RetSqlName("SD1") + " SD1050, "  +  RetSqlName("SF1") + " SF1050, " +  RetSqlName("SE2") + " SE2050 "
	cQuery += "WHERE D1_ITEM        = DE_ITEMNF 
	cQuery += "      AND E2_FORNECE = DE_FORNECE                                                     
	cQuery += "      AND E2_LOJA    = DE_LOJA 
	cQuery += "      AND E2_NUM     = DE_DOC 
	cQuery += "      AND D1_FORNECE = DE_FORNECE 
	cQuery += "      AND D1_LOJA    = DE_LOJA 
	cQuery += "      AND D1_DOC     = DE_DOC 
	cQuery += "      AND F1_FORNECE = DE_FORNECE 
	cQuery += "      AND F1_LOJA    = DE_LOJA 
	cQuery += "      AND F1_DOC     = DE_DOC  
	cQuery += "      AND D1_FILIAL  = F1_FILIAL
	cQuery += "      AND E2_FILIAL  = F1_FILIAL 
	cQuery += "      AND DE_FILIAL  = F1_FILIAL     
	cQuery += "      AND E2_BAIXA  BETWEEN '" + cDataArqde + "' AND '" + cDataArqate + "' AND
	//cQuery += " F1_EMINFE BETWEEN '' AND '' AND"
	cQuery += " F1_FILIAL >= '" + MV_PAR05 + "' AND F1_FILIAL <= '" + MV_PAR06 + "' AND"
	cQuery += " DE_CC >= '" + MV_PAR03 + "' AND DE_CC <= '" + MV_PAR04 + "' AND"                                      
	cQuery += " SF1050.D_E_L_E_T_ <> '*' AND"
	cQuery += " SD1050.D_E_L_E_T_ <> '*' AND"
	cQuery += " SDE050.D_E_L_E_T_ <> '*'" 
	cQuery += " ORDER BY DE_CC, E2_NATUREZ"  


	cQuery := ChangeQuery(cQuery)


	dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), 'CSDE', .T., .F.)

	dbSelectArea("CSDE")
	CSDE->(dbgotop() )

	// ENTRADAS DE NOTAS + FRETE
	/*
	cQuery := "SELECT DISTINCT(D1_DOC+D1_SERIE+D1_FORNECE),D1_COD, D1_DOC,D1_SERIE,D1_FORNECE, E2_NATUREZ, D1_CC,(D1_TOTAL-D1_DESC) AS CUSTO from " + RetSqlName("SE2") + " SE2050, "  + RetSqlName("SD1") + " SD1050, "  +  RetSqlName("SF1") + " SF1050 "
	cQuery += "WHERE D1_FORNECE = E2_FORNECE AND D1_LOJA = E2_LOJA AND D1_DOC = E2_NUM AND"
	cQuery += " F1_FORNECE = E2_FORNECE AND F1_LOJA = E2_LOJA AND F1_DOC = E2_NUM AND"    
	cQuery += " F1_EMINFE BETWEEN '" + cDataArqde + "' AND '" + cDataArqate + "' AND"
	cQuery += " E2_FILIAL >= '" + MV_PAR05 + "' AND E2_FILIAL <= '" + MV_PAR06 + "' AND"       \
	cQuery += " D1_CC >= '" + MV_PAR03 + "' AND D1_CC <= '" + MV_PAR04 + "' AND"                                      
	cQuery += " SE2050.D_E_L_E_T_ <> '*' AND"
	cQuery += " SD1050.D_E_L_E_T_ <> '*'" 
	cQuery += " ORDER BY D1_CC,E2_NATUREZ"
	*/
	// Bruno Lage 
	// SEM RATEIO NO CDE - CENTRO DE CUSTOS        
	cQuery := " SELECT INDEX1,D1_COD,D1_DOC,D1_SERIE,D1_FORNECE,E2_NATUREZ,D1_CC,SUM(CUSTO) CUSTO FROM (           

	cQuery += " SELECT DISTINCT
	cQuery += "			(F1_DOC+F1_SERIE+F1_FORNECE) INDEX1 ,
	cQuery += "			CASE WHEN RTRIM(LTRIM(E2_NATUREZ)) = '2.3.018' THEN '001472' ELSE D1_COD END D1_COD, 
	cQuery += "			D1_DOC,
	cQuery += "			D1_SERIE,
	cQuery += "			D1_FORNECE, 
	cQuery += "			E2_NATUREZ, 
	cQuery += "			CASE WHEN RTRIM(LTRIM(D1_CC)) = '' THEN 'SEM CC' ELSE D1_CC END  D1_CC,       
	cQuery += "			CASE 
	cQuery += "				WHEN E2_SALDO = 0 THEN  (((D1_TOTAL - D1_DESC) /(F1_VALBRUT)* 100) * ((E2_VALOR - E2_DECRESC)  + E2_JUROS))/100				
	cQuery += "				WHEN E2_SALDO <> 0 THEN (((D1_TOTAL - D1_DESC) /(F1_VALBRUT)* 100) * ((E2_VALLIQ - E2_DECRESC) + E2_JUROS))/100  
	cQuery += "			END CUSTO
	cQuery += "    FROM " + RetSqlName("SE2") + " SE2050, "  + RetSqlName("SD1") + " SD1050, "  +  RetSqlName("SF1") + " SF1050 
	cQuery += "    WHERE D1_FORNECE = E2_FORNECE 
	cQuery += "      AND D1_LOJA = E2_LOJA 
	cQuery += "      AND D1_DOC = E2_NUM 
	//cQuery += "      AND F1_FORNECE = E2_FORNECE 
	//cQuery += "      AND F1_LOJA = E2_LOJA 
	cQuery += "      AND F1_DOC = E2_NUM 
	cQuery += "      AND F1_EMISSAO = D1_EMISSAO
	cQuery += "      AND F1_FILIAL = D1_FILIAL  
	cQuery += "      AND E2_FILIAL = D1_FILIAL  
	cQuery += "      AND E2_BAIXA  BETWEEN '" + cDataArqde + "' AND '" + cDataArqate + "'
	cQuery += "      AND E2_FILIAL >=  '" + MV_PAR05 + "'
	cQuery += "      AND E2_FILIAL <=  '" + MV_PAR06 + "' 
	//cQuery += "      AND D1_CC >= '" + MV_PAR03 + "'
	//cQuery += "      AND D1_CC <= '" + MV_PAR04 + "'
	cQuery += "      AND SE2050.D_E_L_E_T_ <> '*' 
	cQuery += "      AND SD1050.D_E_L_E_T_ <> '*'
	cQuery += "      AND SF1050.D_E_L_E_T_ <> '*'
	//cQuery += "      AND E2_NATUREZ <> '2.3.018'   
	cQuery += "      AND E2_VALLIQ <> 0
	cQuery += "      AND D1_RATEIO  = 2
	cQuery += " 	) TB_TBNF
	cQuery += " WHERE D1_CC >= '" + MV_PAR03 + "'
	cQuery += "   AND D1_CC <= '" + MV_PAR04 + "'    
	cQuery += " GROUP BY INDEX1,D1_COD,D1_DOC,D1_SERIE,D1_FORNECE,E2_NATUREZ,D1_CC
	cQuery += " ORDER BY D1_CC,E2_NATUREZ


	cQuery := ChangeQuery(cQuery)                                                 

	dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), 'CSD1', .T., .F.)

	dbSelectArea("CSD1")
	CSD1->(dbgotop() )


	/*
	Mov. De estoques
	*/
	cQueryD3 := " SELECT D3_COD,D3_CC,D3_DOC, D3_UM, D3_QUANT, D3_CUSTO1,B1_GRUPO from " + RetSqlName("SD3") + " SD3050, " + RetSqlName("SB1") + " SB1050"
	cQueryD3 += " WHERE SD3050.D3_EMISSAO BETWEEN '" + cDataArqde + "' AND '" + cDataArqate + "' AND"
	cQueryD3 += " SD3050.D3_FILIAL >= '" + MV_PAR05 + "' AND SD3050.D3_FILIAL <= '" + MV_PAR06 + "' AND"
	cQueryD3 += " SD3050.D_E_L_E_T_ <> '*'  AND SD3050.D3_CF >= 'RE0'AND D3_CF<= 'RE9' AND"                
	cQueryD3 += " SB1050.D_E_L_E_T_ <> '*'  AND SB1050.B1_COD = D3_COD AND SD3050.D3_ESTORNO <> 'S' AND"                
	cQueryD3 += " SD3050.D3_CC > = '" + MV_PAR03 + "' AND SD3050.D3_CC <= '" + MV_PAR04
	cQueryD3 += "' ORDER BY SD3050.D3_CC,B1_GRUPO,D3_COD"

	cQueryD3 := ChangeQuery(cQueryD3)

	dbUseArea(.T., "TOPCONN", TCGenQry(,,cQueryD3), 'CSD3', .T., .F.)

	dbSelectArea("CSD3")
	CSD3->(dbgotop() )	                                       

	//IMPOSTOS + AUTORIZACAO DE PAGAMENTOS 
	//Bruno Lage           

	cQueryZ2 := " SELECT * FROM (

	cQueryZ2 += " SELECT E2_PREFIXO,E2_NUM,E2_PARCELA,E2_NATUREZ,CASE WHEN RTRIM(LTRIM(E2_CCD)) = '' THEN 'SEM CC' ELSE E2_CCD END  E2_CCD , 
	cQueryZ2 += "			CASE 
	cQueryZ2 += "				WHEN E2_SALDO = 0 THEN  E2_VALOR  
	cQueryZ2 += "				WHEN E2_SALDO <> 0 THEN E2_VALLIQ 
	cQueryZ2 += "			END CUSTO                            
	cQueryZ2 += " FROM SE2050 SE2050"
	cQueryZ2 += " WHERE SE2050.E2_BAIXA BETWEEN '" + cDataArqde + "' AND '" + cDataArqate + "' AND"
	cQueryZ2 += " SE2050.D_E_L_E_T_ <> '*'  AND "
	cQueryZ2 += " SE2050.E2_TIPO NOT IN('PA','PF','NF') AND "                
	cQueryZ2 += " (SE2050.E2_PREFIXO IN( 'AUT','FP','FPS','FPV','INS','IRR','FGT','','SAG') ) AND
	cQueryZ2 += " SE2050.E2_FILIAL >= '" + MV_PAR05 + "' AND SE2050.E2_FILIAL <= '" + MV_PAR06 + "'"	
	cQueryZ2 += " AND E2_ARQRAT = ''  
	cQueryZ2 += " AND E2_TITPAI = ''   
	//	cQueryZ2 += " AND E2_RATEIO = 'N' 

	cQueryZ2 += " UNION ALL           

	//SELECT SE2.E2_CCD,E2_NUM,TEMP_PQ.*
	cQueryZ2 += " SELECT TEMP_PQ.PREFIXO E2_PREFIXO,
	cQueryZ2 += "        TEMP_PQ.NUM     E2_NUM,
	cQueryZ2 += "        TEMP_PQ.PARCELA E2_PARCELA,
	cQueryZ2 += "        TEMP_PQ.E2_NATUREZ E2_NATUREZ,
	cQueryZ2 += "        SE2.E2_CCD E2_CCD,
	cQueryZ2 += "        CASE 
	cQueryZ2 += "			WHEN TEMP_PQ.MULTA = 0 THEN TEMP_PQ.VALOR
	cQueryZ2 += "	   		WHEN TEMP_PQ.MULTA <> 0 AND TEMP_PQ.VALOR = TEMP_PQ.MULTA  THEN TEMP_PQ.MULTA
	cQueryZ2 += "	   		WHEN TEMP_PQ.MULTA <> 0 AND TEMP_PQ.VALOR <> TEMP_PQ.MULTA THEN TEMP_PQ.VALOR - TEMP_PQ.MULTA 
	cQueryZ2 += "		 END AS CUSTO
	cQueryZ2 += "   FROM SE2050 SE2 , SE5050 SE5 ,
	cQueryZ2 += " 								(
	cQueryZ2 += " 								SELECT DISTINCT E2_NUMLIQ NUMLIQ, E2_NATUREZ,E2_TIPO TIPO,E2_BAIXA BAIXA,E2_NUM NUM,E2_PREFIXO PREFIXO,E2_PARCELA PARCELA,E2_FORNECE FORNECE,E2_LOJA LOJA ,E2_FILIAL FILIAL,E5_VALOR VALOR,E2_MULTA MULTA
	cQueryZ2 += " 								  FROM SE2050 SE2 , SE5050 SE5
	cQueryZ2 += " 								 WHERE SE2.D_E_L_E_T_ = ''
	cQueryZ2 += " 								   AND SE5.D_E_L_E_T_ = ''
	cQueryZ2 += " 								   AND E5_NUMERO  = E2_NUM
	cQueryZ2 += " 								   AND E5_PREFIXO = E2_PREFIXO
	cQueryZ2 += " 								   AND E5_PARCELA = E2_PARCELA
	cQueryZ2 += " 								   AND E5_CLIFOR  = E2_FORNECE
	cQueryZ2 += " 								   AND E5_LOJA    = E2_LOJA
	cQueryZ2 += " 								   AND E5_FILORIG = E2_FILIAL 
	cQueryZ2 += " 								   AND E5_TIPO    IN ('PF','BOL','RC')   
	cQueryZ2 += " 								   AND E5_TIPODOC <> 'JR'
	cQueryZ2 += " 								   AND E5_RECPAG  = 'P'
	cQueryZ2 += " 								   AND E2_NUMLIQ  <> ''
	cQueryZ2 += " 								   AND E2_BAIXA   BETWEEN '" + cDataArqde + "' AND '" + cDataArqate + "'
	//cQueryZ2 += " 								 --AND E2_NUMLIQ = '000211'
	cQueryZ2 += " 								)TEMP_PQ
	cQueryZ2 += "  WHERE SE2.D_E_L_E_T_ = ''
	cQueryZ2 += "    AND SE5.D_E_L_E_T_ = ''
	cQueryZ2 += "    AND E5_NUMERO  = SE2.E2_NUM
	cQueryZ2 += "    AND E5_PREFIXO = SE2.E2_PREFIXO
	cQueryZ2 += "    AND E5_PARCELA = SE2.E2_PARCELA
	cQueryZ2 += "    AND E5_CLIFOR  = SE2.E2_FORNECE
	cQueryZ2 += "    AND E5_LOJA    = SE2.E2_LOJA
	cQueryZ2 += "    AND E5_FILORIG = SE2.E2_FILIAL 
	cQueryZ2 += "    AND E5_DOCUMEN = NUMLIQ
	cQueryZ2 += "    AND E2_FILIAL  = FILIAL 
	cQueryZ2 += "    AND E2_FORNECE = FORNECE
	cQueryZ2 += "    AND E2_LOJA    = LOJA
	cQueryZ2 += "    AND E2_PREFIXO = PREFIXO
	cQueryZ2 += "    AND E2_TIPO    = TIPO

	cQueryZ2 += " UNION ALL

	cQueryZ2 += "  SELECT E2_PREFIXO,E2_NUM,E2_PARCELA,E2_NATUREZ,CV4_CCD  E2_CCD, CV4_VALOR AS CUSTO 
	cQueryZ2 += "  FROM SE2050 SE2050 , CV4050 CV4050
	cQueryZ2 += "  WHERE SE2050.E2_BAIXA BETWEEN '" + cDataArqde + "' AND '" + cDataArqate + "'" 
	cQueryZ2 += "  AND SE2050.D_E_L_E_T_ <> '*'  
	cQueryZ2 += "  AND CV4050.D_E_L_E_T_ <> '*'
	cQueryZ2 += "  AND CV4_FILIAL+CV4_DTSEQ+CV4_SEQUEN = E2_ARQRAT
	cQueryZ2 += "  AND SE2050.E2_TIPO NOT  IN('PA','PF','NF')
	cQueryZ2 += "  AND (SE2050.E2_PREFIXO IN( 'AUT','FP','FPS','FPV','INS','IRR','FGT','','SAG')  ) 
	cQueryZ2 += "  AND SE2050.E2_FILIAL >= '" + MV_PAR05 + "' AND SE2050.E2_FILIAL <= '" + MV_PAR06 + "'" 
	cQueryZ2 += "  AND E2_ARQRAT <> ''     
	cQueryZ2 += "  AND CV4_FILIAL = E2_FILIAL

	cQueryZ2 += " UNION ALL

	cQueryZ2 += " SELECT 'MBO' E2_PREFIXO,CONVERT(VARCHAR(10),CAST(E5_DATA AS DATE),105) E2_NUM,E5_FILORIG E2_PARCELA,E5_NATUREZ E2_NATUREZ,'10101001' E2_CCD, E5_VALOR AS CUSTO 
	cQueryZ2 += " FROM SE5050 SE5050 
	cQueryZ2 += " WHERE SE5050.E5_DATA BETWEEN '" + cDataArqde + "' AND '" + cDataArqate + "'"
	cQueryZ2 += " AND D_E_L_E_T_ = ''
	cQueryZ2 += " AND E5_FILORIG BETWEEN '" + MV_PAR05 + "' AND '" + MV_PAR06 + "'"
	cQueryZ2 += " AND E5_NATUREZ = '2.6.001'             

	cQueryZ2 += " ) TB_TEMP
	cQueryZ2 += " WHERE E2_CCD >= '" + MV_PAR03 + "'"
	cQueryZ2 += " AND E2_CCD   <= '" + MV_PAR04 + "'"

	cQueryZ2 += " ORDER BY E2_CCD,E2_NATUREZ

	cQueryZ2 := ChangeQuery(cQueryZ2)

	dbUseArea(.T., "TOPCONN", TCGenQry(,,cQueryZ2), 'CSZ2', .T., .F.)

	dbSelectArea("CSZ2")
	CSZ2->(dbgotop() )	


	nlin := 70                                                                                      
	nQt := 0
	nTotalCusto := 0  
	cCusto := "cCustoRel"
	nTotCustoCC := 0
	nTotCusto := 0
	cCabec2 := "Natureza/Produto                          Documento  SИrie Qtde     Total"
	While ! CSDE->(Eof() ) .OR. ! CSD3->(Eof()) .OR. ! CSZ2->(Eof()) .OR. ! CSD1->(Eof())
		If nLin >= 58
			Cabec("Relatorio de Custos","Periodo: " + DTOC(MV_PAR01) + " a " + DTOC(MV_PAR02),cCabec2,wnrel,Tamanho,nTipo)
			//nLin := 5
			//@ nLin,  60 PSay "RelatСrio de Custos"
			//@ nLin+1,65 PSay "Periodo: " + DTOC(MV_PAR01) + " a " + DTOC(MV_PAR02)
			//@ nLin+2, 0 PSay "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"        
			//nLin := nLin + 3
			//@ nLin,  0 PSay "Natureza/Produto                          Documento  SИrie Qtde     Total"
			//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX 999999999  999   9,999.99 99,999,999.99
			//0         1         2         3         4         5         6         7         8         9
			//012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			//@ nLin+1,0 PSay   "---------------------------------------------------------------------------------"     
			//nLin := nLin + 2 
			nLin := Li
		Endif
		IF (ALLTRIM(cCusto) <> ALLTRIM(CSDE->DE_CC) .AND. ALLTRIM(cCusto) <> ALLTRIM(CSD3->D3_CC) .AND. ALLTRIM(cCusto) <> ALLTRIM(CSZ2->E2_CCD) .AND. ALLTRIM(cCusto) <> ALLTRIM(CSD1->D1_CC))
			If nTotCustoCC > 0
				@ nLin,0 PSay "---------------------------------------------------------------------------------"
				@ nLin+1,0 PSay "Total Centro de Custo ------------->"
				@ nLin+1, 66 PSay nTotCustoCC Picture "@E 9,999,999.99"
				nLin := nLin+2
			Endif  
			@ nLin,0 PSay "---------------------------------------------------------------------------------"
			If (! CSDE->(EOF())) .AND. (ALLTRIM(CSDE->DE_CC) < ALLTRIM(CSD3->D3_CC) ) .OR. ALLTRIM(CSD3->D3_CC) <= ""
				If (! CSDE->(EOF())) .AND. (ALLTRIM(CSDE->DE_CC) < ALLTRIM(CSZ2->E2_CCD) ) .OR. ALLTRIM(CSZ2->E2_CCD) = ""
					If (! CSDE->(EOF())) .AND. (ALLTRIM(CSDE->DE_CC) < ALLTRIM(CSD1->D1_CC) ) .OR. ALLTRIM(CSD1->D1_CC) = ""
						cCusto := CSDE->DE_CC
					Else
						cCusto := CSD1->D1_CC
					Endif 
				Else
					If (! CSZ2->(EOF())) .AND. (ALLTRIM(CSZ2->E2_CCD) < ALLTRIM(CSD1->D1_CC) ) .OR. ALLTRIM(CSD1->D1_CC) = ""
						cCusto := CSZ2->E2_CCD
					Else
						cCusto := CSD1->D1_CC
					Endif 
				Endif                    
			Else
				If (! CSD3->(EOF())) .AND. (ALLTRIM(CSD3->D3_CC) < ALLTRIM(CSZ2->E2_CCD) ) .OR. ALLTRIM(CSZ2->E2_CCD) = ""
					If (! CSD3->(EOF())) .AND. (ALLTRIM(CSD3->D3_CC) < ALLTRIM(CSD1->D1_CC) ) .OR. ALLTRIM(CSD1->D1_CC) = ""
						cCusto := CSD3->D3_CC
					Else
						cCusto := CSD1->D1_CC
					Endif                    
				Else
					If (! CSZ2->(EOF())) .AND. (ALLTRIM(CSZ2->E2_CCD) < ALLTRIM(CSD1->D1_CC) ) .OR. ALLTRIM(CSD1->D1_CC) = ""
						cCusto := CSZ2->E2_CCD
					Else
						cCusto := CSD1->D1_CC
					Endif 
				Endif                     
				//           Endif    
			Endif     
			@ nLin+1,0 Psay cCusto + " - " + Posicione("CTT", 1, XFilial("CTT")+cCusto, "CTT->CTT_DESC01" )
			@ nLin+2,0 PSay "---------------------------------------------------------------------------------"
			nLin := nLin + 3
			nTotCustoCC := 0
		Endif              
		lTitulo := .T. 
		nTotNat := 0
		WHILE alltrim(cCusto) == alltrim(CSDE->DE_CC )
			cNat := CSDE->E2_NATUREZ
			If nLin >= 58
				Cabec("Relatorio de Custos","Periodo: " + DTOC(MV_PAR01) + " a " + DTOC(MV_PAR02),cCabec2,wnrel,Tamanho,nTipo)
				nLin := Li
			Endif   
			If LTitulo
				nLin := nLin + 1
				@ nLin, 0 PSay "Notas Fiscais de Entrada ... "
				nLin := nLin+2         
				lTitulo := .F.
			Endif  

			@ nLin,  0 PSay substr(Posicione("SB1", 1, XFilial("SB1")+CSDE->D1_COD, "SB1->B1_DESC" ),1,40)
			@ nLin, 42 PSay CSDE->DE_DOC 
			@ nLin, 53 PSay CSDE->DE_SERIE 
			@ nLin, 66 PSay CSDE->CUSTO Picture "@E 9,999,999.99"                     

			nTotCustoCC := nTotCustoCC + CSDE->Custo
			nTotNat := nTotNat + CSDE->Custo
			nTotCusto := nTotCusto + CSDE->Custo
			nLin := nLin+1
			CSDE->(dbSkip())
			If CSDE->E2_NATUREZ <> cNAT .OR. CSDE->(eof()) .OR. aLLtRIM(CSDE->DE_CC) <> AllTrim(cCusto)
				@ nLin, 0 PSay "Total " + substr(Posicione("SED", 1, XFilial("SED")+CNAT, "SED->ED_DESCRIC" ),1,40) + "----------->"
				@ nLin,66 PSay nTotNAT Picture "@E 9,999,999.99"
				cNAT := CSDE->E2_NATUREZ
				nTotNAT := 0
				nLin := nLin+1
			Endif   

		End                               
		nTotNat := 0
		WHILE alltrim(cCusto) == alltrim(CSD1->D1_CC )
			cNat := CSD1->E2_NATUREZ
			If nLin >= 58
				Cabec("Relatorio de Custos","Periodo: " + DTOC(MV_PAR01) + " a " + DTOC(MV_PAR02),cCabec2,wnrel,Tamanho,nTipo)
				nLin := Li
			Endif   
			If LTitulo
				nLin := nLin + 1
				@ nLin, 0 PSay "Notas Fiscais de Entrada ..."
				nLin := nLin+2         
				lTitulo := .F.
			Endif  

			// @ nLin,  0 PSay substr(Posicione("SED", 1, XFilial("SED")+CSD1->E2_NATUREZ, "SED->ED_DESCRIC" ),1,40)
			@ nLin,  0 PSay substr(Posicione("SB1", 1, XFilial("SB1")+CSD1->D1_COD, "SB1->B1_DESC" ),1,40)
			@ nLin, 42 PSay CSD1->D1_DOC 
			@ nLin, 53 PSay CSD1->D1_SERIE 
			@ nLin, 66 PSay CSD1->CUSTO Picture "@E 9,999,999.99"
			nTotCustoCC := nTotCustoCC + CSD1->Custo
			nTotCusto := nTotCusto + CSD1->Custo
			nTotNat := nTotNat + CSD1->Custo
			nLin := nLin+1
			CSD1->(dbSkip())
			If Alltrim(CSD1->E2_NATUREZ) <> AllTrim(cNAT) .OR. CSD1->(eof()) .OR. aLLtRIM(CSD1->D1_CC) <> AllTrim(cCusto)
				@ nLin, 0 PSay "Total " + substr(Posicione("SED", 1, XFilial("SED")+CNAT, "SED->ED_DESCRIC" ),1,40) + "----------->"
				@ nLin,66 PSay nTotNAT Picture "@E 9,999,999.99"
				cNAT := CSD1->E2_NATUREZ
				nTotNAT := 0
				nLin := nLin+1
			Endif   
		End  	   
		lTitulo := .T.
		nTotGru := 0
		WHILE alltrim(cCusto) == alltrim(CSD3->D3_CC)
			cGrupo := CSD3->B1_GRUPO
			If nLin >= 58
				Cabec("Relatorio de Custos","Periodo: " + DTOC(MV_PAR01) + " a " + DTOC(MV_PAR02),cCabec2,wnrel,Tamanho,nTipo)
				nLin := Li
			Endif
			If LTitulo        
				nLin := nLin + 1         
				@ nLin, 0 PSay "RequisiГУes ..."
				nLin := nLin+2         
				lTitulo := .F.
			Endif  
			@ nLin,  0 PSay substr(Posicione("SB1", 1, XFilial("SB1")+CSD3->D3_COD, "SB1->B1_DESC" ),1,40)
			@ nLin, 42 PSay CSD3->D3_DOC
			@ nLin, 57 PSay CSD3->D3_QUANT Picture "@E 9,999.99"
			@ nLin, 66 PSay CSD3->D3_CUSTO1 Picture "@E 9,999,999.99"
			nTotCustoCC := nTotCustoCC + CSD3->D3_CUSTO1
			nTotCusto := nTotCusto + CSD3->D3_CUSTO1
			nTotGru := nTotGru + CSD3->D3_CUSTO1
			nLin := nLin+1
			CSD3->(dbSkip())
			If CSD3->B1_GRUPO <> cGrupo .OR. aLLtRIM(CSD3->D3_CC) <> AllTrim(cCusto) .OR. CSD3->(EOF())
				@ nLin, 0 PSay "Total " + Posicione("SBM", 1, XFilial("SBM")+cGRUPO, "SBM->BM_DESC" ) +" ------------------------------>"
				@ nLin,66 PSay nTotGru Picture "@E 9,999,999.99"
				cGrupo := CSD3->B1_GRUPO
				nTotGru := 0
				nLin := nLin+1
			Endif   
		End         
		lTitulo := .T.               
		nTotNat := 0
		WHILE alltrim(cCusto) == alltrim(CSZ2->E2_CCD)
			cNataut := CSZ2->E2_NATUREZ
			If nLin >= 58
				Cabec("Relatorio de Custos","Periodo: " + DTOC(MV_PAR01) + " a " + DTOC(MV_PAR02),cCabec2,wnrel,Tamanho,nTipo)
				nLin := Li
			Endif   
			If LTitulo
				nLin := nLin + 1         
				@ nLin, 0 PSay "AutorizaГУes de Pagamento ..."
				nLin := nLin+2         
				lTitulo := .F.
			Endif         
			@ nLin,  0 PSay Substr(Posicione("SED", 1, XFilial("SED")+CSZ2->E2_NATUREZ, "SED->ED_DESCRIC" ),1,40)
			@ nLin, 42 PSay CSZ2->E2_NUM 
			@ nLin, 53 PSay CSZ2->E2_PARCELA
			@ nLin, 66 PSay CSZ2->CUSTO Picture "@E 9,999,999.99"
			nTotCustoCC := nTotCustoCC + CSZ2->CUSTO
			nTotCusto := nTotCusto + CSZ2->CUSTO
			nTotNat := nTotNat + CSZ2->CUSTO
			nLin := nLin+1
			CSZ2->(dbSkip())
			If CSZ2->E2_NATUREZ <> cNataut .OR. aLLtRIM(CSZ2->E2_CCD) <> AllTrim(cCusto) .OR. CSZ2->(EOF())
				@ nLin, 0 PSay "Total " + Substr(Posicione("SED", 1, XFilial("SED")+cNataut, "SED->ED_DESCRIC" ),1,40) +" ------------------>"
				@ nLin,66 PSay nTotNat Picture "@E 9,999,999.99"
				cNataut := CSZ2->E2_NATUREZ
				nTotNat := 0
				nLin := nLin+1
			Endif   	     
		End  
	End              
	If nTotCustoCC > 0
		@ nLin,0 PSay "---------------------------------------------------------------------------------"
		@ nLin+1,0 PSay "Total Centro de Custo ------------->"      
		@ nLin+1, 66 PSay nTotCustoCC Picture "@E 9,999,999.99"
		nLin := nLin+2
	Endif  

	@ nLin, 0 PSay "---------------------------------------------------------------------------------"
	@ nLin+1, 0 PSay "Total Geral -------------------------------------->"
	@ nLin+2,65 PSay nTotCusto Picture "@E 99,999,999.99"
	If aReturn[5] = 1                                                                                                             
		Set Printer To
		dbCommitAll()
		ourspool(wnrel)
	Endif
	MS_FLUSH()

	CSDE->(dbCloseArea())
	CSD3->(dbCloseArea())
	CSZ2->(dbCloseArea())
	CSD1->(dbCloseArea())


Return Nil          

//=====================================================================================================================================================	
