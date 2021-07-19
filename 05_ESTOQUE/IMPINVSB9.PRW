#Include "Rwmake.ch"   
#Include "totvs.ch"   
#Include "TopConn.ch"         
#Include "TbiConn.ch"

/*
Programa ...: IMPINVSB9.Prw
Uso ........: Programa para importacao do inventario e lancamento na tabela SB7
Data .......: 05/08/2019

-- Importar dados

DELETE FROM TB_IMPORT_PRODUTO3

-- Importar dados
bulk insert TB_IMPORT_PRODUTO3 from 'D:\TOTVS 12\Microsiga\protheus_data\system_q\Invet.txt' with (fieldterminator = ';', rowterminator = '\n', firstrow = 1, codepage = 'acp')

SELECT COUNT(*) FROM TB_IMPORT_PRODUTO3

*/ 
     
User Function IMPINVSB9()
/*****************************************************************************************************
*
*
***/
Local cQuery := "SELECT * FROM DADOSADV_Q..TB_IMPORT_PRODUTO3"
TcQuery cQuery New Alias "TRB"
Processa({|| RunCont() },"Processando...")
	
Return()


Static Function RunCont()
/*****************************************************************************************************
*
*
******/
Local nQtdReg := 0

dbSelectArea("TRB")
dbGoTop()
Do While ! EoF()    
    
	nQtdReg := nQtdReg + 1

	dbSelectArea("TRB")
	dbSkip()
EndDo
                             
ProcRegua(RecCount())

dbSelectArea("TRB")
dbGoTop()
Do While ! EoF()    

    IncProc("Processando: " + AllTrim(TRB->CODIGO) )

	dbSelectArea("SB1")
	dbSetOrder(1)
	If dbSeek(xFilial("SB1") + AllTrim(TRB->CODIGO))    

		RecLock("SB7",.T.)
			SB7->B7_FILIAL  := xFilial("SB7") 
			SB7->B7_COD     := TRB->CODIGO
			
			SB7->B7_DOC     := "20210117A"
			
			/*
			SB7->B7_LOTECTL := TRB->LOTE 
			SB7->B7_NUMLOTE := TRB->SUBL
			*/
			SB7->B7_LOCAL   := SB1->B1_LOCPAD
			SB7->B7_DATA    := dDataBase   
			SB7->B7_QUANT   := TRB->QUANT
			/*
			SB7->B7_YCOMLIQ := TRB->COMLIQ
			SB7->B7_YALTLIQ := TRB->ALTLIQ
			SB7->B7_YESPLIQ := TRB->ESPLIQ
			SB7->B7_YTOTLIQ := TRB->QUANT 
			
			SB7->B7_YCOMBRU := TRB->COMLIQ
			SB7->B7_YALTBRU := TRB->ALTLIQ
			SB7->B7_YESPBRU := TRB->ESPLIQ
			SB7->B7_YTOTBRU := TRB->QUANT
			
			SB7->B7_YCAVALE := TRB->CAVALE
			
			SB7->B7_YCLASSI := TRB->CLASS1
			SB7->B7_VINI1   := TRB->CUSTO1
			SB7->B7_YENDERE := ""
			*/
			//SB7->B7_DESC    := SB1->B1_DESC
		MsUnlock()      	 
	Else
		Alert("Produto não encontrado: " + AllTrim(TRB->CODIGO) )	
	EndIf
	  
	dbSelectArea("TRB")
	dbSkip()
EndDo
//Close(oLeTxt)	
dbSelectArea("TRB")
dbCloseArea("TRB")

Return()                 


User Function AJUSTEPESO()
/*****************************************************************************************************
* - Função de ajustar os pesos de todos os cavales 
*
******/
/*
u_updatePeso("015505")
u_updateBundle("015505")

ConOut("**********Atualizando bundle*************")
ConOut("***"+"015505")
ConOut("*****************************************")
*/


dbSelectArea("ZG3")
dbgotop()
Do While !EOF()

	u_updatePeso(ZG3->ZG3_CODIGO)
	u_updateBundle(ZG3->ZG3_CODIGO)
	ConOut("**********Atualizando bundle*************")
	ConOut("***"+ZG3->ZG3_CODIGO)
	ConOut("*****************************************")

	dbSelectArea("ZG3")
	dbSkip()
EndDO 

dbSelectArea("TRB") 

Return


User Function MAJUSTGERAL()
/*****************************************************************************************************
*
*
******/
Local cQuery := ""
/*
cQuery := " UPDATE SB8010 
cQuery += "   SET	B8_YALTBRU=B7_YALTBRU,
cQuery += " 		B8_YALTLIQ=B7_YALTLIQ,
cQuery += " 		B8_YESPBRU=B7_YESPBRU,
cQuery += " 		B8_YESPLIQ=B7_YESPLIQ,
cQuery += " 		B8_YCOMBRU=B7_YCOMBRU,
cQuery += " 		B8_YCOMLIQ=B7_YCOMLIQ,
cQuery += " 		B8_YCLASSI=B7_YCLASSI,
cQuery += " 		B8_YCAVALE=ISNULL((SELECT CAVALE  FROM TB_IMPORT_PRODUTO WHERE LEFT(CODIGO,2) ='CH' AND CODIGO = B8_PRODUTO AND B8_LOCAL = LOCAL AND B8_LOTECTL = LOTE AND B8_NUMLOTE = SUBL   ),''),
cQuery += " 		B8_LOTEFOR=ISNULL((SELECT BLOCO   FROM TB_IMPORT_PRODUTO WHERE LEFT(CODIGO,2) ='CH' AND CODIGO = B8_PRODUTO AND B8_LOCAL = LOCAL AND B8_LOTECTL = LOTE AND B8_NUMLOTE = SUBL   ),''),
cQuery += " 		B8_YPESOBR=ISNULL((SELECT CAST(PESOBRU AS FLOAT) FROM TB_IMPORT_PRODUTO WHERE LEFT(CODIGO,2) ='CH' AND CODIGO = B8_PRODUTO AND B8_LOCAL = LOCAL AND B8_LOTECTL = LOTE AND B8_NUMLOTE = SUBL   ),0),
cQuery += " 		B8_YPESOLQ=ISNULL((SELECT CAST(PESOLIQ AS FLOAT) FROM TB_IMPORT_PRODUTO WHERE LEFT(CODIGO,2) ='CH' AND CODIGO = B8_PRODUTO AND B8_LOCAL = LOCAL AND B8_LOTECTL = LOTE AND B8_NUMLOTE = SUBL   ),0)
cQuery += "  FROM SB7010 SB7 
cQuery += "         INNER JOIN SB8010 SB8 ON (B7_COD = B8_PRODUTO AND B7_DATA = B8_DATA AND B8_LOCAL = B7_LOCAL AND B8_LOTECTL =	B7_LOTECTL AND B8_NUMLOTE = B7_NUMLOTE)
cQuery += "  WHERE SB7.D_E_L_E_T_ = ''
cQuery += "    AND SB8.D_E_L_E_T_ = ''

TcSQLExec(cQuery)
	*/		
/*
Cria Cavaletes 
ATUALIZAR PESOLQ/PESOBR NA ZG3
*/
cQuery := " SELECT CAVALE, CAST(SUM(PESOLIQ) AS FLOAT) PESOLIQ, CAST(SUM(PESOBRU) AS FLOAT) PESOBRU, COUNT(*) QTD_CHAPAS
cQuery += "   FROM TB_IMPORT_PRODUTO2 
cQuery += "  WHERE CAVALE <>'' 
cQuery += " GROUP BY CAVALE 
cQuery += " ORDER BY CAVALE

tcQuery cQuery alias TRB new
dbSelectArea("TRB")
dbgotop()
Do While !EOF()

	Reclock("ZG3",.T.)
		ZG3->ZG3_FILIAL := xFilial("ZG3")
		ZG3->ZG3_CODIGO := TRB->CAVALE
		ZG3->ZG3_DESCRI := "CAV-"+DTOC(DATE())+"-"+TIME()                                                                                                  
		ZG3->ZG3_STATUS := "O"
		ZG3->ZG3_ATIVO  := "S"
		ZG3->ZG3_QCHAPA := TRB->QTD_CHAPAS
		ZG3->ZG3_TARA   := 55
		ZG3->ZG3_PESOBR := TRB->PESOBRU
		ZG3->ZG3_PESOLQ := TRB->PESOLIQ
	Msunlock()

	dbSelectArea("TRB")
	dbSkip()
EndDO 

dbSelectArea("TRB") 
dbCloseArea()



Return()

Static Function fCustos1(cCodProd,dDataAtua)
/*****************************************************************************************************
*
*
******/       
Local nRetCusto := 0       
Local cQuery    := ""

cQuery  :=  " SELECT AVG(D1_VUNIT) AS NMEDIA FROM SD1010
cQuery  +=  "  WHERE D_E_L_E_T_ <> '*' AND D1_TIPO='N' 
cQuery  +=  "    AND D1_COD    = '"+ cCodProd       +"'
cQuery  +=  "    AND D1_FILIAL = '"+ xFilial("SD1") +"'
cQuery  +=  "    AND D1_EMISSAO BETWEEN '"+ DtoS(dDataAtua - nDiasMed) +"' AND '"+  DtoS(dDataAtua) +"'

TcQuery cQuery New Alias "TRBAVG"

dbSelectArea("SB1")
dbSetOrder(1)
dbSeek(xFilial("SB1")+ cCodProd,.f.)
nRetCusto := SB1->B1_UPRC

dbSelectArea("TRBAVG")
nRetCusto := If(TRBAVG->NMEDIA > 0 , TRBAVG->NMEDIA , nRetCusto)  
dbSelectArea("TRBAVG")
dbCloseArea()

Return(nRetCusto)
