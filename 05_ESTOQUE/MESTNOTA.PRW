#include "Topconn.ch"
#include "rwmake.ch"

/*
+----------+-----------+----------+-------------------------+------+-----------+
|Programa  | CRYS_24   | Autor    | BRUNO LAGE FERREIRA     |Data  |21.05.2019 |
+----------+-----------+----------+-------------------------+------+-----------+
|Descricao | Impressão de Relatorio Estatistico de Lançamento de Notas Usuario |
+----------+-------------------------------------------------------------------+
| USO      | Compras				                     					   |
+----------+-------------------------------------------------------------------+
|           ALTERACOES FEITAS DESDE A CRIACAO                                  |
+----------+-----------+-------------------------------------------------------+
|Autor     | Data      | Descricao                                             |
+----------+-----------+-------------------------------------------------------+
|          |           |                                                       |
+----------+-----------+-------------------------------------------------------+
*/

User Function MESTNOTA(nOpcao)
*********************************************************************************
* Monta Janela para Parametros
*
****

Local cQuery    := ""
Local aCampDt   := {""}	// Campos Data para a Nova Estrutura do Arquivo a ser criado
//Local cArqDBF	:= "\cry_dbf\CRY_03.DBF"

// Parametros do Relatorio
Local nTipoRelatorio := 0
Local cDeFunc	   	 := ""
Local cAteFunc       := ""
Local cDeFornecedor  := ""
Local cAteFornecedor := ""
Local dDeData    := CToD("")
Local dAteData   := CToD("")
//Local nTipoData := 0
// Parametros da integração do Relatorio Crystal
Private cReport := ""
Private cOpcoes := "1;0;1;Estatisticas de Lançamento de NF"
Private cParam  := ""

AjustaSX1()
 

If Pergunte("MESTNOTA01")

	// Recebe Parametros
	nTipoRelatorio	:= mv_par01
	cDeFunc 		:= mv_par02
	cAteFunc		:= mv_par03
	cDeFornecedor   := mv_par04
	cAteFornecedor  := mv_par05
	dDeData  		:= mv_par06
	dAteData		:= mv_par07
	//nTipoData 		:= mv_par08	
	//dDeData    		:= mv_par09
	//dAteData   		:= mv_par10
	//nListaMes  		:= mv_par11
	//nListaPro  		:= mv_par12
	//nListaNF   		:= mv_par13
	//cDeFilial  		:= mv_par14
	//cAteFilial 		:= mv_par15   
	
	**************************
	**************************
	***     BRUNO LAGE    ****
	**************************
	**************************    
	
	cTabela   := "TB_R0024"
	
	If TcCanOpen(cTabela)  
	   lOk := TcDelFile(cTabela)   
	Else  
		MsgInfo("Talbela "+cTabela+" nao encontrada.")
	Endif
  	
 If nTipoRelatorio == 1
                      
	cQuery := "SELECT DTMES,A.DTANO,cast('"+ DToS(dDeData)+"' as date) DTINI, cast('"+ DToS(dAteData)+"' as date) DTFIM ,USUARIO, PEDIDO, SUM(DOC) DOC, SUM(ITENS) ITENS, SUM(MEDNF) MEDNF, SUM(DOCCAN) DOCCAN, SUM(ITENCAN) ITENCAN, SUM(MEDCAN) MEDCAN "
    cQuery += " INTO TB_R0024
	cQuery += " FROM (SELECT LEFT(F1_INCUSER,15) USUARIO, CASE WHEN D1_PEDIDO='' THEN 'N' ELSE 'S' END PEDIDO, COUNT(DISTINCT F1_DOC) DOC, COUNT(D1_ITEM) ITENS, COUNT(D1_ITEM)/COUNT(DISTINCT F1_DOC) MEDNF,0 DOCCAN, 0 ITENCAN, 0 MEDCAN ,MONTH(F1_DTDIGIT) DTMES,YEAR(F1_DTDIGIT) DTANO" 
	cQuery += " FROM " +RetSQLName("SF1")+ " SF1 " 
	cQuery += "INNER JOIN "+RetSQLName("SA2")+" SA2 ON F1_FORNECE=A2_COD AND F1_LOJA=A2_LOJA " 
	cQuery += "INNER JOIN "+RetSQLName("SD1")+" SD1 ON F1_DOC=D1_DOC AND F1_SERIE=D1_SERIE AND F1_FORNECE=D1_FORNECE WHERE F1_INCUSER <> '' "
	cQuery += "AND LEFT(A2_CGC,8) <> '02912729' AND F1_DTDIGIT BETWEEN '"+DToS(dDeData)+"' AND '"+DToS(dAteData)+"' "
	cQuery += "AND SF1.D_E_L_E_T_='' AND LEFT(F1_INCUSER,15) BETWEEN '"+cDeFunc+"' AND '"+cAteFunc+"' GROUP BY MONTH(F1_DTDIGIT),YEAR(F1_DTDIGIT),LEFT(F1_INCUSER,15), CASE WHEN D1_PEDIDO='' THEN 'N' ELSE 'S' END "
	CQuery += " UNION "
	cQuery += "SELECT LEFT(F1_INCUSER,15) USUARIO, CASE WHEN D1_PEDIDO='' THEN 'N' ELSE 'S' END PEDIDO, 0 DOC, 0 ITENS, 0 MEDNF,COUNT(DISTINCT F1_DOC) DOCCAN, COUNT(D1_ITEM) ITENCAN, COUNT(D1_ITEM)/COUNT(DISTINCT F1_DOC) MEDCAN, MONTH(F1_DTDIGIT) DTMES,YEAR(F1_DTDIGIT) DTANO "
    cQuery += " FROM " +RetSQLName("SF1")+ " SF1 " 
    cQuery += "INNER JOIN "+RetSQLName("SA2")+" SA2 ON F1_FORNECE=A2_COD AND F1_LOJA=A2_LOJA "
    cQuery += "INNER JOIN "+RetSQLName("SD1")+" SD1 ON F1_DOC=D1_DOC AND F1_SERIE=D1_SERIE AND F1_FORNECE=D1_FORNECE WHERE F1_INCUSER <> '' "
    cQuery += "AND LEFT(A2_CGC,8) <> '02912729' AND F1_DTDIGIT BETWEEN '"+DToS(dDeData)+"' AND '"+DToS(dAteData)+"' AND SF1.D_E_L_E_T_='*' AND LEFT(F1_INCUSER,15) BETWEEN '"+cDeFunc+"' AND '"+cAteFunc+"' "
    cQuery += "GROUP BY MONTH(F1_DTDIGIT),YEAR(F1_DTDIGIT),LEFT(F1_INCUSER,15), CASE WHEN D1_PEDIDO='' THEN 'N' ELSE 'S' END) A "
    cQuery += "GROUP BY USUARIO, PEDIDO,DTMES,DTANO "
    cQuery += "ORDER BY USUARIO, PEDIDO "

   Else    
   
	cQuery := "SELECT cast('"+ DToS(dDeData)+"' as date) DTINI, cast('"+ DToS(dAteData)+"' as date) DTFIM  , USUARIO, DTLANC, F1_FORNECE, A2_NOME, PEDIDO, SUM(DOC) DOC, SUM(ITENS) ITENS, SUM(MEDNF) MEDNF, SUM(DOCCAN) DOCCAN, SUM(ITENCAN) ITENCAN, SUM(MEDCAN) MEDCAN "
	cQuery += " INTO TB_R0024
	cQuery += " FROM (SELECT LEFT(F1_INCUSER,15) USUARIO, SUBSTRING(F1_INCUSER,17,8) DTLANC, F1_FORNECE, A2_NOME, CASE WHEN D1_PEDIDO='' THEN 'N' ELSE 'S' END PEDIDO, COUNT(DISTINCT F1_DOC) DOC, COUNT(D1_ITEM) ITENS, COUNT(D1_ITEM)/COUNT(DISTINCT F1_DOC) MEDNF, 0 DOCCAN, 0 ITENCAN, 0 MEDCAN " 
	cQuery += " FROM " +RetSQLName("SF1")+ " SF1 " 
	cQuery += "INNER JOIN "+RetSQLName("SA2")+" SA2 ON F1_FORNECE=A2_COD AND F1_LOJA=A2_LOJA " 
	cQuery += "INNER JOIN "+RetSQLName("SD1")+" SD1 ON F1_DOC=D1_DOC AND F1_SERIE=D1_SERIE AND F1_FORNECE=D1_FORNECE WHERE F1_INCUSER <> '' "
	cQuery += "AND LEFT(A2_CGC,8) <> '02912729' AND F1_DTDIGIT BETWEEN '"+DToS(dDeData)+"' AND '"+DToS(dAteData)+"' "
	cQuery += "AND SF1.D_E_L_E_T_='' AND LEFT(F1_INCUSER,15) BETWEEN '"+cDeFunc+"' AND '"+cAteFunc+"' AND F1_FORNECE BETWEEN '"+cDeFornecedor+"' AND '"+cAteFornecedor+"' GROUP BY LEFT(F1_INCUSER,15), SUBSTRING(F1_INCUSER,17,8), F1_FORNECE, A2_NOME, CASE WHEN D1_PEDIDO='' THEN 'N' ELSE 'S' END "
	CQuery += " UNION "
	cQuery += "SELECT LEFT(F1_INCUSER,15) USUARIO, SUBSTRING(F1_INCUSER,17,8) DTLANC, F1_FORNECE, A2_NOME, CASE WHEN D1_PEDIDO='' THEN 'N' ELSE 'S' END PEDIDO, 0 DOC, 0 ITENS, 0 MEDNF, COUNT(DISTINCT F1_DOC) DOCCAN, COUNT(D1_ITEM) ITENCAN, COUNT(D1_ITEM)/COUNT(DISTINCT F1_DOC) MEDCAN "
    //cQuery += " INTO TB_R0024
    cQuery += " FROM " +RetSQLName("SF1")+ " SF1 " 
	cQuery += "INNER JOIN "+RetSQLName("SA2")+" SA2 ON F1_FORNECE=A2_COD AND F1_LOJA=A2_LOJA " 
	cQuery += "INNER JOIN "+RetSQLName("SD1")+" SD1 ON F1_DOC=D1_DOC AND F1_SERIE=D1_SERIE AND F1_FORNECE=D1_FORNECE WHERE F1_INCUSER <> '' "
    cQuery += "AND LEFT(A2_CGC,8) <> '02912729' AND F1_DTDIGIT BETWEEN '"+DToS(dDeData)+"' AND '"+DToS(dAteData)+"' AND SF1.D_E_L_E_T_='*' AND LEFT(F1_INCUSER,15) BETWEEN '"+cDeFunc+"' AND '"+cAteFunc+"' AND F1_FORNECE BETWEEN '"+cDeFornecedor+"' AND '"+cAteFornecedor+"' " 
    cQuery += "GROUP BY LEFT(F1_INCUSER,15), SUBSTRING(F1_INCUSER,17,8), F1_FORNECE, A2_NOME, CASE WHEN D1_PEDIDO='' THEN 'N' ELSE 'S' END) A "
    cQuery += "GROUP BY USUARIO, DTLANC, F1_FORNECE, A2_NOME, PEDIDO "
    cQuery += "ORDER BY USUARIO, DTLANC, F1_FORNECE, A2_NOME, PEDIDO "
    
   EndIf                               
                         
	TcSQLExec(cQuery)	
	
	IF SubString(CNUMEMP,1,2) == "01"
		u_RelInWeb("RQ0024")
	Else
		u_RelInWeb("RIM0024")
	EndIF
	/*	
	TCQuery cQuery Alias "TRB" New

	dbSelectArea("TRB")
	dbGoTop()
    
	// Se existir conteudo
	If !Eof()
	
		// Verifica existencia do arquivo Temporario
		If ChkFile("TMP")
			dbSelectArea("TMP")
			dbCloseArea()
			Ferase(cArqTRB)
		EndIf
	
		// Transforma o resultado da Query em DBF
		cArqTRB := U_TransQuery("TRB","TMP","\cry_dbf\CRY_03.DBF",aCampDt,.T.)

		cReport	:= If(nTipoRelatorio==1,"ESTUSERNF_S","ESTUSERNF_A")
		
		// Parametros passados ao Crystal
		//cParam  := StrZero(nAgruparPor,1)+';'
		//cParam  += StrZero(nListaMes,1)+';'
		//cParam  += StrZero(nListaPro,1)+';'
		//cParam  += StrZero(nListaNF,1)+';'
		cParam  := cDeFunc+';'
		cParam  += cAteFunc+';'  
		cParam  += cDeFornecedor+';'
		cParam  += cAteFornecedor+';'
		cParam  += DToC(dDeData)+';'
		cParam  += DToC(dAteData)+';'
							    
    	// Chama do Relatório do Crystal
		CALLCRYS(cReport,cParam,cOpcoes)
	
		dbSelectArea(cArqTRB)
		dbCloseArea()
		*/
Else

		//dbSelectArea("TRB")
		//dbCloseArea()
		
	Alert("Não existe dados para geração do relatório, verifique os parâmetros!")
EndIf
				
//EndIf
	
/*
+----------+---------------------------------------------------------------+
|SINTAXE DA|CALLCRYS(<creport>,<cparam>,<copcoes>) onde                    |
|FUNÇÃO    |<creport>= Nome do relatório Crystal,localizado no diretório   |
|CALLCRYS  |          apontado por MV_CRYSTAL, sem a extensão e path.      | 
|          |<cparam> = Parƒmetros passados para o Crystal, em vez de usar  |
|          |          o SX1, separados por vírgula ou ponto e vírgula.     |
|          |<copcoes>= Conjunto de opções para nao mostrar a tela da       |
|          |           SetPrint, composta por x;y;z;w, onde                |
|          |                         x = vídeo(1) ou impressora(3)         |
|          |                         y = Atualiza(0) ou não(1) os dados    |
|          |                         z = Número de cópias                  |
|          |                         w = Título do repo                    |
+----------+---------------------------------------------------------------+
/*/

Return



Static Function AjustaSX1()
*********************************************************************************
* Gera Relatorio
*
****

Local aPerg	:= {}
Local cPerg := "MESTNOTA01"

Local aHelpPor1  := {} 
Local aHelpPor2  := {} 
Local aHelpPor3  := {} 
Local aHelpPor4  := {} 
Local aHelpPor5  := {} 
Local aHelpPor6  := {}
Local aHelpPor7  := {} 

Local aHelpPor  := {} 
Local aHelpEng  := {}
Local aHelpSpa  := {}

Aadd( aHelpPor1, "Informe o Tipo de Operação para a       " )
Aadd( aHelpPor1, "impressão do Relatório.				 " )
Aadd( aHelpPor1, " " )

Aadd( aHelpPor2, "Informe O Funcionario Inicial para a    " )
Aadd( aHelpPor2, "impressão do Relatório.				 " )
Aadd( aHelpPor2, " " )

Aadd( aHelpPor3, "Informe O Funcionario Final para a    "  )
Aadd( aHelpPor3, "impressão do Relatório.				 " )
Aadd( aHelpPor3, " " )

Aadd( aHelpPor4, "Informe O Fornecedor Inicial para a    " )
Aadd( aHelpPor4, "impressão do Relatório.				 " )
Aadd( aHelpPor4, " " )

Aadd( aHelpPor5, "Informe O Fornecedor Final para a    " )
Aadd( aHelpPor5, "impressão do Relatório.				 " )
Aadd( aHelpPor5, " " )

Aadd( aHelpPor6, "Informe a Data Inicial para a    " )
Aadd( aHelpPor6, "impressão do Relatório.				 " )
Aadd( aHelpPor6, " " )

Aadd( aHelpPor7, "Informe a Data Final para a    " )
Aadd( aHelpPor7, "impressão do Relatório.				 " )
Aadd( aHelpPor7, " " )

/*
Aadd(aPerg,{"Tipo Relatório      ?"," "," ","mv_ch1","N",1 ,0,1,"C","",""   ,"","","mv_par01","Sintético","","","","Analítico"})  
Aadd(aPerg,{"De Funcionario   	?"," "," ","mv_ch2","C",15 ,0,1,"G","","US3","","","mv_par02","","","","","","","","","","","","","","","","",aHelpPor2,aHelpEng,aHelpSpa})
Aadd(aPerg,{"Ate Funcionario   	?"," "," ","mv_ch3","C",15 ,0,1,"G","","US3","","","mv_par03","","","","","","","","","","","","","","","","",aHelpPor3,aHelpEng,aHelpSpa})
Aadd(aPerg,{"De Fornecedor		?"," "," ","mv_ch4","C",6 ,0,1,"G","","SA2","","","mv_par04","","","","","","","","","","","","","","","","",aHelpPor4,aHelpEng,aHelpSpa})
Aadd(aPerg,{"Ate Fornecedor       ?"," "," ","mv_ch5","C",6 ,0,1,"G","","SA2","","","mv_par05","","","","","","","","","","","","","","","","",aHelpPor5,aHelpEng,aHelpSpa})
Aadd(aPerg,{"De Data          ?"," "," ","mv_ch9","D",8 ,0,1,"G","","","","","mv_par06","","","","","","","","","","","","","","","","",aHelpPor6,aHelpEng,aHelpSpa})
Aadd(aPerg,{"Ate Data         ?"," "," ","mv_cha","D",8 ,0,1,"G","","","","","mv_par07","","","","","","","","","","","","","","","","",aHelpPor7,aHelpEng,aHelpSpa})
*/
Aadd(aPerg,{cPerg,"Tipo Relatório   ?","N",08,00,"C","","","Sintético","Analítico","","","",""})  
Aadd(aPerg,{cPerg,"De Funcionario   ?","C",15,00,"G","","US3","","","","","",""})
Aadd(aPerg,{cPerg,"Ate Funcionario  ?","C",15,00,"G","","US3","","","","","",""})
Aadd(aPerg,{cPerg,"De Fornecedor	?","C",06,00,"G","","SA2","","","","","",""})
Aadd(aPerg,{cPerg,"Ate Fornecedor   ?","C",06,00,"G","","SA2","","","","","",""})
Aadd(aPerg,{cPerg,"De Data          ?","D",08,00,"G","","","","","","","",""})
Aadd(aPerg,{cPerg,"Ate Data         ?","D",08,00,"G","","","","","","","",""})

U_Testasx1(cPerg,aPerg,.T.)

Return
