#INCLUDE "Rwmake.ch"
#INCLUDE "topconn.ch"

/*            
BRUNO LAGE FERREIRA
SIGAWISE
ITINGA ATUALMENTE NAO FAZ NADA
16/12/2009
*/
            
User Function M460FIM()
****************************************************************************************
* 
*
****
Local aM460FIM := GetArea()
Local cQuery   := ""         
Local aPeso    := {}
Local nResult  := 0     
Local cBoleto  := ""
Local cMsgNota := ""                             
/*
Autor.....: Bruno Lage Ferreira
Data/Hora.: 14/11/2011 14:57 

Gera titulo de Abatimento Automatico para os clientes A1_ABFIN
Criado apos a rotina de boletos do banco.
*/
//MABFINCL()     



/*
cQuery := "SELECT CAST(M2_DATA AS DATE) DATA, MAX(M2_MOEDA2) 'DOLAR' , MAX(M2_MOEDA3) 'EURO'
cQuery += "  FROM SM2050
cQuery += "  WHERE D_E_L_E_T_ = ''
cQuery += "    AND M2_DATA  = '"+DToS(dDataBase)+"'
cQuery += "   GROUP BY M2_DATA

TcQuery cQuery Alias TMP_MOEDA New
dbSelectArea("TMP_MOEDA")

cMsgNota := "Cotação atual: " + StoC(DToS(dDataBase)) + " US$:" + AllTrim(STR(TMP_MOEDA->DOLAR)) + " €:" + AllTrim(STR(TMP_MOEDA->EURO))
	                   
dbSelectArea("TMP_MOEDA")
dbCloseArea()                       
*/


/*
GRAVAÇAO DOS DADOS NUMERAÇÃO E MARCA ITINGA E QUALITA

cQuery := " UPDATE " + RetSqlName("SF2")  
cQuery += " SET F2_MARCA1 = C5_MARCA1 , F2_NUMER1 = C5_NUMER1
cQuery += "   FROM " + RetSqlName("SC5") + "  SC5 INNER JOIN " + RetSqlName("SF2") + " SF2 ON (C5_NOTA = F2_DOC AND C5_SERIE = F2_SERIE AND C5_FILIAL = F2_FILIAL)
cQuery += "  WHERE SC5.D_E_L_E_T_ = ''  
cQuery += "    AND SF2.D_E_L_E_T_ = '' 
//cQuery += "    AND C5_TIPO = 'N' 
cQuery += "    AND C5_FILIAL  = '"+SF2->F2_FILIAL  +"' 
cQuery += "    AND C5_NOTA    = '"+SF2->F2_DOC     +"' 
cQuery += "    AND C5_SERIE   = '"+SF2->F2_SERIE   +"'
*/


cQuery := " UPDATE " + RetSqlName("SF2")  
cQuery += " SET F2_MARCA1 = (SELECT  DISTINCT C5_MARCA1 FROM " + RetSqlName("SC5") + "  SC5 WHERE C5_FILIAL + C5_NUM = (SELECT DISTINCT D2_FILIAL+D2_PEDIDO FROM " + RetSqlName("SD2") + " WHERE D_E_L_E_T_ = '' AND D2_DOC  = '"+SF2->F2_DOC     +"' AND D2_SERIE = '"+SF2->F2_SERIE   +"' AND D2_FILIAL = '"+SF2->F2_FILIAL  +"'))
cQuery += " FROM " + RetSqlName("SF2") + " WHERE D_E_L_E_T_ = '' AND F2_DOC  = '"+SF2->F2_DOC     +"' AND F2_SERIE = '"+SF2->F2_SERIE   +"' AND F2_FILIAL = '"+SF2->F2_FILIAL  +"'

TcSQLExec(cQuery)


cQuery := " UPDATE " + RetSqlName("SF2") 
cQuery += " SET F2_NUMER1 = (SELECT  DISTINCT C5_NUMER1 FROM " + RetSqlName("SC5") + "  SC5 WHERE C5_FILIAL + C5_NUM = (SELECT DISTINCT D2_FILIAL+D2_PEDIDO FROM " + RetSqlName("SD2") + " WHERE D_E_L_E_T_ = '' AND D2_DOC  = '"+SF2->F2_DOC     +"' AND D2_SERIE = '"+SF2->F2_SERIE   +"' AND D2_FILIAL = '"+SF2->F2_FILIAL  +"'))
cQuery += " FROM " + RetSqlName("SF2") + " WHERE D_E_L_E_T_ = '' AND F2_DOC  = '"+SF2->F2_DOC     +"' AND F2_SERIE = '"+SF2->F2_SERIE   +"' AND F2_FILIAL = '"+SF2->F2_FILIAL  +"'

TcSQLExec(cQuery)

Return          

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
