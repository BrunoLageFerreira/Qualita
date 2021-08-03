#INCLUDE "Rwmake.ch"
#INCLUDE "topconn.ch"

/*            
BRUNO LAGE FERREIRA
SIGAWISE

12/08/2019 - 
*/            

User Function GM460FIM()
*****************************************************************************************
* Gravar o Numero da Carga no Contas a Receber SE1
*
****
Local aM460FIM := GetArea()
Local cQuery   := ""         
Local aPeso    := {}
Local nResult  := 0     
Local cBoleto  := ""
Local cMsgNota := ""                             
Local cNotas   := ""

/*
Autor.....: Bruno Lage Ferreira
Data/Hora.: 14/11/2011 14:57 

Gera titulo de Abatimento Automatico para os clientes A1_ABFIN
Criado apos a rotina de boletos do banco.
*/
//MABFINCL()     

IF SubString(CNUMEMP,1,2) == "01"
	/*
	LIMPA AS POSIÇÕES DE ENDEREÇAMENTO APOS O FATURAMENTO
	*/
	cQuery := " UPDATE SB8010
	cQuery += "    SET B8_XDTMOVE ='',B8_XENDERE='',B8_XPUSUAR=''
	cQuery += "   	FROM SB8010 SB8 INNER JOIN SD2010 SD2
	cQuery += " 	  ON (B8_PRODUTO = D2_COD AND B8_LOTECTL = D2_LOTECTL AND B8_NUMLOTE = D2_NUMLOTE)
	cQuery += "  WHERE SB8.D_E_L_E_T_ = ''
	cQuery += "    AND SD2.D_E_L_E_T_ = ''
	cQuery += "    AND LEFT(B8_PRODUTO,2) IN ('CH','AM') 
	cQuery += "    AND D2_DOC   = '"+SF2->F2_DOC  +"'
	cQuery += "    AND D2_SERIE = '"+SF2->F2_SERIE+"'
	
	TcSQLExec(cQuery)
	
	/*
	DEFINE O NOME DO USUÁRIO NO MOMENTO DO FATURAMENTO
	*/
	cQuery := " UPDATE SD2010
    cQuery += "    SET D2_NOMEUSR = '"+ SUBSTR(CUSUARIO,7,15) +"'
    cQuery += "   FROM SD2010
    cQuery += "  WHERE D_E_L_E_T_ = ''
    cQuery += "    AND D2_DOC     ='"+ SF2->F2_DOC     +"'
    cQuery += "    AND D2_SERIE   ='"+ SF2->F2_SERIE   +"' 
    cQuery += "    AND D2_EMISSAO ='"+ dtoS(SF2->F2_EMISSAO) +"'
	
	TcSQLExec(cQuery)
	
	/*
	PREENCHE O VOLUME 2  DA NOTA FISCAL DE SAIDA
	
	cQuery := " UPDATE SF2010 
	cQuery += " SET F2_VOLUME2 = C5_VOLUME2
	cQuery += "   FROM SC5010 SC5 INNER JOIN SF2010 SF2 ON (C5_NOTA = F2_DOC AND C5_SERIE = F2_SERIE)
	cQuery += "  WHERE SC5.D_E_L_E_T_ = ''  
	cQuery += "    AND SF2.D_E_L_E_T_ = '' 
	cQuery += "    AND C5_TIPO = 'N' 
	cQuery += "    AND C5_NOTA  = '"+SF2->F2_DOC  +"' 
	cQuery += "    AND C5_SERIE = '"+SF2->F2_SERIE+"'
	
	TcSQLExec(cQuery)
	*/
	
	/*
	PREENCHE O VOLUME 1 SOMANDO VOLUME 2
	*/
	cQuery := " UPDATE SF2010 
	cQuery += " SET F2_VOLUME1 = C5_VOLUME1 + C5_VOLUME2
	cQuery += "   FROM SC5010 SC5 INNER JOIN SF2010 SF2 ON (C5_NOTA = F2_DOC AND C5_SERIE = F2_SERIE)
	cQuery += "  WHERE SC5.D_E_L_E_T_ = ''  
	cQuery += "    AND SF2.D_E_L_E_T_ = '' 
	cQuery += "    AND C5_TIPO = 'N' 
	cQuery += "    AND C5_NOTA  = '"+SF2->F2_DOC  +"' 
	cQuery += "    AND C5_SERIE = '"+SF2->F2_SERIE+"'
	
	TcSQLExec(cQuery)
	
	/*
	Verificar o valor financeiro Vs Valor Faturado para faturamento em outras moedas
	*/

	VFATXFIN()
EndIf

/*
GRAVAÇAO DOS DADOS NUMERAÇÃO E MARCA ITINGA E QUALITA
*/
cQuery := " UPDATE " + RetSqlName("SF2")  
cQuery += " SET F2_MARCA1 = (SELECT  DISTINCT C5_MARCA1 FROM " + RetSqlName("SC5") + "  SC5 WHERE C5_FILIAL + C5_NUM = (SELECT DISTINCT D2_FILIAL+D2_PEDIDO FROM " + RetSqlName("SD2") + " WHERE D_E_L_E_T_ = '' AND D2_DOC  = '"+SF2->F2_DOC     +"' AND D2_SERIE = '"+SF2->F2_SERIE   +"' AND D2_FILIAL = '"+SF2->F2_FILIAL  +"'))
cQuery += " FROM " + RetSqlName("SF2") + " WHERE D_E_L_E_T_ = '' AND F2_DOC  = '"+SF2->F2_DOC     +"' AND F2_SERIE = '"+SF2->F2_SERIE   +"' AND F2_FILIAL = '"+SF2->F2_FILIAL  +"'

TcSQLExec(cQuery)


cQuery := " UPDATE " + RetSqlName("SF2") 
cQuery += " SET F2_NUMER1 = (SELECT  DISTINCT C5_NUMER1 FROM " + RetSqlName("SC5") + "  SC5 WHERE C5_FILIAL + C5_NUM = (SELECT DISTINCT D2_FILIAL+D2_PEDIDO FROM " + RetSqlName("SD2") + " WHERE D_E_L_E_T_ = '' AND D2_DOC  = '"+SF2->F2_DOC     +"' AND D2_SERIE = '"+SF2->F2_SERIE   +"' AND D2_FILIAL = '"+SF2->F2_FILIAL  +"'))
cQuery += " FROM " + RetSqlName("SF2") + " WHERE D_E_L_E_T_ = '' AND F2_DOC  = '"+SF2->F2_DOC     +"' AND F2_SERIE = '"+SF2->F2_SERIE   +"' AND F2_FILIAL = '"+SF2->F2_FILIAL  +"'

TcSQLExec(cQuery)


RestArea(aM460FIM)

Return()  


Static Function VFATXFIN()
***********************************************************************************************
* // F2_VALFAT NÃO SERA ATUALIZADO PARA FINS DE AUDITORIA
* // Funcao para verificar o valor faturado Invoice Vs Valor financeiro 
* // o sistema grava em real depois salva em dolar novamente isso pode em alguns casos gerar diferenca de centavos entre os valores.
****
Local aTPadv := {}
Local cQuery := ""
Local nQtdRe := 0

/*
 SELECT  SE1.R_E_C_N_O_ AS RECNO1 ,
 	    E1_NUM,
 	   	E1_SERIE,
 	   	C5_NUM,
		F2_EMISSAO,
 	   	E1_VENCREA ,
 	   	E1_CLIENTE,
 	   	E1_LOJA,
 	   	E1_VALOR,
 	   	E1_TIPO,
 	   	E1_SALDO,
 	   	C5_XVLRFIN,
 	   	F2_VALFAT,
 	   	ROUND(E1_VALOR - C5_XVLRFIN ,2) DIFERENCA

--UPDATE SE1010
--   SET E1_VALOR  = C5_XVLRFIN,
--	   E1_SALDO  = C5_XVLRFIN
	   
   FROM SE1010 SE1 INNER JOIN SC5010 SC5 ON (C5_NOTA = E1_NUM AND E1_PREFIXO = C5_SERIE AND C5_CLIENTE = E1_CLIENTE AND C5_LOJACLI = E1_LOJA )
     	              INNER JOIN SF2010 SF2 ON (E1_NUM  = F2_DOC AND E1_PREFIXO = F2_SERIE AND F2_CLIENTE = E1_CLIENTE AND F2_LOJA    = E1_LOJA )
  WHERE SE1.D_E_L_E_T_ = ''
    AND SC5.D_E_L_E_T_ = ''
    AND SF2.D_E_L_E_T_ = ''
    AND (E1_VALOR - C5_XVLRFIN) <> 0
    --AND E1_NUM     = '000006612'
    --AND E1_TIPO    = 'NF'
    --AND E1_PREFIXO = '0'
    --AND E1_CLIENTE = '000114'
    --AND E1_LOJA    = '01'
   -- AND E1_TIPO    = '"+ SE1->E1_TIPO    +"'
 ORDER BY E1_FILIAL, E1_PREFIXO, E1_NUM, E1_PARCELA, E1_TIPO
*/

dbSelectArea("SE1")
dbSetOrder(1) 
If dbSeek(xFilial("SE1")+SE1->E1_PREFIXO+SF2->F2_DOC+SE1->E1_PARCELA+SE1->E1_TIPO+SF2->F2_CLIENTE+SF2->F2_LOJA)

	cQuery := " SELECT  SE1.R_E_C_N_O_ AS RECNO1 ,
	cQuery += " 	    E1_NUM,
	cQuery += " 	   	E1_SERIE,
	cQuery += " 	   	C5_NUM,
	cQuery += " 	   	E1_VENCREA,
	cQuery += "         C5_CONDPAG,
	cQuery += "         C5_YINVOIC,
	cQuery += " 	   	E1_CLIENTE,
	cQuery += " 	   	E1_LOJA,
	cQuery += " 	   	E1_VALOR,
	cQuery += " 	   	E1_TIPO,
	cQuery += " 	   	E1_SALDO,
	cQuery += " 	   	C5_XVLRFIN,
	cQuery += " 	   	F2_VALFAT,
	cQuery += " 	   	ROUND(C5_XVLRFIN - F2_VALFAT  ,2) DIFERENCA
	cQuery += "   FROM SE1010 SE1 INNER JOIN SC5010 SC5 ON (C5_NOTA = E1_NUM AND E1_PREFIXO = C5_SERIE AND C5_CLIENTE = E1_CLIENTE AND C5_LOJACLI = E1_LOJA )
    cQuery += " 	              INNER JOIN SF2010 SF2 ON (E1_NUM  = F2_DOC AND E1_PREFIXO = F2_SERIE AND F2_CLIENTE = E1_CLIENTE AND F2_LOJA    = E1_LOJA )
    cQuery += "  WHERE SE1.D_E_L_E_T_ = ''
    cQuery += "    AND SC5.D_E_L_E_T_ = ''
    cQuery += "    AND SF2.D_E_L_E_T_ = ''
    //cQuery += "    AND (C5_XVLRFIN - F2_VALFAT) <> 0
	cQuery += "    AND E1_NUM     = '" + SF2->F2_DOC + "'
	cQuery += "    AND E1_TIPO    = 'NF'
	cQuery += "    AND E1_PREFIXO = '"+ SE1->E1_PREFIXO +"'
	cQuery += "    AND E1_CLIENTE = '"+ SF2->F2_CLIENTE +"'
	cQuery += "    AND E1_LOJA    = '"+ SF2->F2_LOJA    +"'
	cQuery += "    AND E1_TIPO    = '"+ SE1->E1_TIPO    +"'
	cQuery += " ORDER BY E1_FILIAL, E1_PREFIXO, E1_NUM, E1_PARCELA, E1_TIPO
	
	TcQuery cQuery Alias TMPABFIN New
		
	dbSelectArea("TMPABFIN")     
	dbGoTop()
	
	aTPadv := Condicao(TMPABFIN->C5_XVLRFIN,TMPABFIN->C5_CONDPAG,,SF2->F2_EMISSAO,) 
	
	If Len(aTPadv) <> Contar("TMPABFIN","!Eof()")
		Alert("Erro! Condição de pagamento diferente entre pedido de venda [PV] e Faturamento. Verifique!")
		Return()
	EndIf
	
	dbSelectArea("TMPABFIN")     
	dbGoTop()
	Do While !EOF() 
		
		nQtdRe := nQtdRe + 1
		
	    dbSelectArea("SE1")
		dbGoTo(TMPABFIN->RECNO1)
		    
		If aTPadv[nQtdRe][2] <> SE1->E1_VALOR 
				RecLock( "SE1",.F. )
					Replace SE1->E1_VALOR   With aTPadv[nQtdRe][2]
					Replace SE1->E1_SALDO   With aTPadv[nQtdRe][2]
					Replace SE1->E1_XINVOIC With TMPABFIN->C5_YINVOIC
				MsUnLock()
		EndIf
				
		dbSelectArea("TMPABFIN")
		dbSkip()
	EndDo                    

	dbSelectArea("TMPABFIN")
	dbCloseArea()
EndIf

Return() 
      
      
/*
Static Function fVerifBolet(cRecno1)
***********************************************************************************************
*
*
****                               
Local cRet   := ""                                                
Local cQuery := ""

	cQuery := " SELECT IsNull( (
	cQuery += " 			   SELECT DISTINCT C5_BOLETO FROM " + RetSqlName("SC5") +" SC5,  " + RetSqlName("SE1") + " SE1 
	cQuery += " 				WHERE SC5.C5_FILIAL = '" + xFilial("SC5")  + "'"
	cQuery += " 				  AND SC5.C5_NUM=E1_PEDIDO 
	cQuery += "                   AND SC5.D_E_L_E_T_<>'*'
	cQuery += "                   AND SE1.D_E_L_E_T_ <> '*'
	cQuery += "                   AND SC5.D_E_L_E_T_ <> '*'
	cQuery += "                   AND SE1.R_E_C_N_O_ = "+ cRecno1 
	cQuery += " 				),'N') AS TIPO1
	
	TcQuery cQuery Alias TMPBOLETO New
	dbSelectArea("TMPBOLETO")
	
	cRet := TMPBOLETO->TIPO1
	                   
	dbSelectArea("TMPBOLETO")
	dbCloseArea()

Return(cRet)
*/
/*
Static Function MABFINCL()
***********************************************************************************************
* 
* // Funcao da inclusao do titulo AB- (ABATIMENTO FINANCEIRO)
* //
****
Local aVetor := {}
Local cQuery := ""

dbSelectArea("SE1")
dbSetOrder(1) 
If dbSeek(xFilial("SE1")+SE1->E1_PREFIXO+SF2->F2_DOC+SE1->E1_PARCELA+SE1->E1_TIPO+SF2->F2_CLIENTE+SF2->F2_LOJA)

	IF SA1->A1_ABFIN <> 0
		                       
		cQuery := " SELECT R_E_C_N_O_ AS RECNO1 ,E1_PREFIXO,E1_NUM,E1_PARCELA,E1_TIPO,E1_PREFIXO,E1_CLIENTE,E1_LOJA 
		cQuery += "   FROM SE1010
		cQuery += "  WHERE D_E_L_E_T_ <> '*'
		cQuery += "    AND E1_NUM       = '" + SF2->F2_DOC + "'
		cQuery += "    AND E1_TIPO <> 'AB-'
		cQuery += "    AND E1_PREFIXO = '"+ SE1->E1_PREFIXO +"'
		cQuery += "    AND E1_CLIENTE = '"+ SF2->F2_CLIENTE +"'
		cQuery += "    AND E1_LOJA    = '"+ SF2->F2_LOJA    +"'
		cQuery += "    AND E1_TIPO    = '"+ SE1->E1_TIPO    +"'
		cQuery += " ORDER BY E1_FILIAL, E1_PREFIXO, E1_NUM, E1_PARCELA, E1_TIPO
		
		TcQuery cQuery Alias TMPABFIN New
		
		dbSelectArea("TMPABFIN")     
		dbGoTop()
		Do While !EOF()         
		
			dbSelectArea("SE1")
			dbGoTo(TMPABFIN->RECNO1)
  		                                                                                                                
			aadd(aVetor, {"E1_FILIAL"	, xFilial("SE1")									,	 	nil })
	        aadd(aVetor, {"E1_TIPO"		, "AB-"												,       nil })
	        aadd(aVetor, {"E1_VALOR"	, Round((SE1->E1_VALOR  * SA1->A1_ABFIN) /100,2)	,       nil })
	        aadd(aVetor, {"E1_SALDO"	, Round((SE1->E1_VALOR  * SA1->A1_ABFIN) /100,2)	,       nil })
	        aadd(aVetor, {"E1_VLCRUZ"	, Round((SE1->E1_VALOR  * SA1->A1_ABFIN) /100,2)	,      	nil })
			
			lMSErroAuto	:= .f.  
			
			dbSelectArea("SE1")
			dbGoTo(TMPABFIN->RECNO1)
  		    
			MSExecAuto({|x,y| Fina040(x,y)},aVetor,3)
			
			If lMsErroAuto
	        	mostraerro()
	      	Endif   
				
			dbSelectArea("TMPABFIN")
			dbSkip()
		EndDo                    

		dbSelectArea("TMPABFIN")
		dbCloseArea()
		
	EndIf

EndIf
  
Return()                           
*/
/*
User Function MS520VLD()
****************************************************************************************
* //Ponto de entrada para excluir a "AB-" na excluisao da Nota Fiscal de Saida
*
**** 
Local cQuery := ""                                                                         

cQuery := " SELECT R_E_C_N_O_ AS RECNO1 ,E1_PREFIXO,E1_NUM,E1_PARCELA,E1_TIPO,E1_PREFIXO,E1_CLIENTE,E1_LOJA 
cQuery += "   FROM SE1010
cQuery += "  WHERE D_E_L_E_T_ <> '*'
cQuery += "    AND E1_NUM       = '" + SF2->F2_DOC    +"'
cQuery += "    AND E1_PREFIXO   = '" + SF2->F2_SERIE  +"'
cQuery += "    AND E1_TIPO      = 'AB-'
cQuery += "    AND E1_CLIENTE   = '"+ SF2->F2_CLIENTE +"'
cQuery += "    AND E1_LOJA      = '"+ SF2->F2_LOJA    +"'
cQuery += " ORDER BY E1_FILIAL, E1_PREFIXO, E1_NUM, E1_PARCELA, E1_TIPO

TcQuery cQuery Alias TMPABFIND New

dbSelectArea("TMPABFIND")     
dbGoTop()
Do While !EOF()         

	dbSelectArea("SE1")
	dbGoTo(TMPABFIND->RECNO1)

	If SF2->F2_CLIENTE+SF2->F2_LOJA  == SE1->E1_CLIENTE+SE1->E1_LOJA                                                          
		RecLock( "SE1",.F.,.T. )
		DbDelete()      
	EndIf	
		
	dbSelectArea("TMPABFIND")
	dbSkip()
EndDo                    

dbSelectArea("TMPABFIND")
dbCloseArea()


Return(.T.)
*/
