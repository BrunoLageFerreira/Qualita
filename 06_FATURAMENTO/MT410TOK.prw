#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
#INCLUDE "topconn.ch"

/*
Programa ...: MT410TOK.Prw
Uso ........: Validação do pedido de vendas
Data .......: 26/04/2019
Feito por ..: Bruno Lage Ferreira 
MV_NDESCTP - DESCONTO NO PREÇO DE LISTA E UNITARIO
*/

User Function MT410TOK()
****************************************************************************************************************
*   /* Programa para validar o pedido de venda tabela de preço de chapas - Qualitá */
*
****
Local   lRet      := .T.
Local   oProcess
Default lEnd      := .F.


If SubString(CNUMEMP,1,2) == "01" .And. (INCLUI == .T. .Or. ALTERA == .T.) .AND. (FUNNAME() <> "GROA001")

	a410Recalc()

	oProcess := MsNewProcess():New({|lEnd| lRet := MValidPedV(@oProcess, @lEnd,@lRet) },"Validando dados..","Lendo Registros do Pedido de Vendas",.T.) 
	If !IsBlind()     
		oProcess:Activate()
	EndIf
EndIf

Return(lRet)

User Function M410LIOK()
****************************************************************************************************************
*    Libera ou bloquea linha do pedido de venda 
*
****
Local lRet := .T.
/*
LinhaOk
*/
If SubString(CNUMEMP,1,2) == "01" 
	If SubStr(AllTrim(AllTrim(GdFieldGet("C6_PRODUTO",n))) ,1,2) $ 'BL' .AND. u_MTSOEST(GdFieldGet("C6_TES",n)) 
		If Empty(GdFieldGet("C6_LOTECTL",n))
			Alert("ERRO! BLOCO SEM LOTE!")
			lRet := .F.
		EndIf
	EndIf
	If SubStr(AllTrim(AllTrim(GdFieldGet("C6_PRODUTO",n))) ,1,2) $ 'CH' .AND. (Empty(GdFieldGet("C6_LOTECTL",n)) .OR. Empty(GdFieldGet("C6_NUMLOTE",n)))  
		Alert("ERRO! CHAPA COM LOTE OU SUB-LOTE EM BRANCO!")
		lRet := .F.
	EndIf
EndIf

Return(lRet)

User Function MTSOEST(cCodTes)
****************************************************************************************************************
*    Libera ou bloquea linha do pedido de venda 
*
****
Local lRet := .F.

dbSelectArea("SF4")
dbSetOrder(1)
dbSeek(xFilial("SF4") + cCodTes)

If SF4->F4_ESTOQUE == "S"
	lRet := .T.
	ConOut("MTSOEST" +"|"+ cCodTes +"|"+ ".T." )
Else
	ConOut("MTSOEST" +"|"+ cCodTes +"|"+ ".F." )
	lRet := .F.
EndIf

Return(lRet)

User Function GM410FIM()
****************************************************************************************************************
*    Libera ou bloquea pedido de venda M410STTS 
*
****
Local lLibBlq  := .F.
Local lCalcPeso:= .F.
Local cQuery   := ""
Local cGPExec  := GetMv("MV_XGPEXE")

If SubString(CNUMEMP,1,2) == "01"  .AND. (FUNNAME() <> "GROA001")
	For nX := 1 To Len(aCols)
		If !Empty(GdFieldGet("C6_XMOTBLQ",nX))
			lLibBlq   := .T.
		EndIf
		
		dbSelectArea("SB1")
		dbSetOrder(1)
		dbSeek(xFilial("SB1")+ AllTrim(GdFieldGet("C6_PRODUTO",nX)) )
		
		IF AllTrim(SB1->B1_GRUPO) $ cGPExec		
			lCalcPeso := .T.
		EndIf
	Next nX
	
	If lLibBlq   
		RecLock("SC5",.F.)
		SC5->C5_BLQ  := '1'
		MsUnlock()	
	Endif
	
	If lCalcPeso
	
		//Soma dos pesos brutos e liquido
		cQuery   := " SELECT	ROUND(SUM(B8_YPESOLQ) + SUM(PESO_AMOSTRAS),3) PLQ, 
		cQuery   += " 		    ROUND(SUM(B8_YPESOBR) + SUM(PESO_AMOSTRAS),3) PBR 
		cQuery   += " FROM (
		cQuery   += " SELECT		ISNULL(ZGO.ZGO_INVOIC,'') AS ZGO_INVOIC, 
		cQuery   += " 			TAB_PROFORMA.* FROM (
		cQuery   += " 			 SELECT	RTRIM(LTRIM(C5_NUM)) AS C5_NUM,
		cQuery   += " 					YEAR(CAST(C5_EMISSAO AS DATE) )ANO,
		cQuery   += " 					CAST(C5_EMISSAO AS DATE) AS C5_EMISSAO,
		cQuery   += " 					RTRIM(LTRIM(A1_NOME)) AS A1_NOME,
		cQuery   += " 					RTRIM(LTRIM(A1_END)) AS A1_END,
		cQuery   += " 					RTRIM(LTRIM(A1_BAIRRO)) AS A1_BAIRRO,
		cQuery   += " 					RTRIM(LTRIM(A1_DDI)) AS A1_DDI,
		cQuery   += " 					RTRIM(LTRIM(A1_DDD)) AS A1_DDD,
		cQuery   += " 					RTRIM(LTRIM(A1_TEL)) AS A1_TEL,
		cQuery   += " 					RTRIM(LTRIM(A1_CONTATO)) AS A1_CONTATO,
		cQuery   += " 					RTRIM(LTRIM(A3_NOME)) AS A3_NOME,
		cQuery   += " 					RTRIM(LTRIM(YA_PAIS_I)) AS YA_PAIS_I,
		cQuery   += " 					RTRIM(LTRIM(C5_XSEAL)) AS C5_XSEAL,
		cQuery   += " 					RTRIM(LTRIM(C5_XBOOKIN)) AS C5_XBOOKIN,
		cQuery   += " 					RTRIM(LTRIM(C5_XVESSEL)) AS C5_XVESSEL,
		cQuery   += " 					RTRIM(LTRIM(C5_XCONTAI)) AS C5_XCONTAI,
		cQuery   += " 					RTRIM(LTRIM(C5_XTARE)) AS C5_XTARE,
		cQuery   += " 					RTRIM(LTRIM(C5_XPO)) AS C5_XPO,
		cQuery   += " 					RTRIM(LTRIM(C6_LOTECTL)) AS C6_LOTECTL,
		cQuery   += " 					RTRIM(LTRIM(C6_NUMLOTE)) AS C6_NUMLOTE,
		cQuery   += " 					C6_CF,
		cQuery   += " 					C6_XPESO AS PESO_AMOSTRAS,
		cQuery   += " 					C6_YESPLIQ * 100 AS C6_YESPLIQ,
		cQuery   += " 					RTRIM(LTRIM(B5_YCEMEIN)) AS C6_DESCRI, 
		cQuery   += " 					RTRIM(LTRIM(C6_DESCRI))  AS C6_DESCRI_P, 
		cQuery   += " 					IIF(RTRIM(LTRIM(C6_YCAVALE))='','-',RTRIM(LTRIM(C6_YCAVALE)))  AS C6_YCAVALE,
		cQuery   += " 					C6_PRCVEN,
		cQuery   += " 					ROUND(C6_PRCVEN / 10.764,2) AS PRCVEN_SQFT,
		cQuery   += " 					C5_XVLRFIN AS VALOR_FINANCEIRO,
		cQuery   += " 					C6_QTDVEN,
		cQuery   += " 					IIF(C6_NUMLOTE<>'',1,0) AS QTD_CHAPAS,
		cQuery   += " 					IIF(C6_CF='7949',0,C6_QTDVEN) AS QTD_TOTAL_FATURAR,
		cQuery   += " 					IIF(C6_UM='M2',C6_QTDVEN,0) AS QTD_TOTAL_M2,
		cQuery   += " 					IIF(C6_UM='PC',C6_QTDVEN,0) AS QTD_TOTAL_PC,
		cQuery   += " 					C6_UM,
		cQuery   += " 					C6_UNSVEN,
		cQuery   += " 					C6_VALOR,
		cQuery   += " 					IIF(C6_CF='7949',C6_VALOR,0) AS SAMPLE_DESC,
		cQuery   += " 					C6_VALDESC,
		cQuery   += " 					C6_YCOMLIQ,
		cQuery   += " 					C6_YALTLIQ,
		cQuery   += " 					C6_YTOTLIQ,
		cQuery   += " 					ISNULL((SELECT TOP 1 B8_YPESOLQ FROM SB8010 WHERE D_E_L_E_T_ = '' AND C6_LOTECTL = B8_LOTECTL AND C6_NUMLOTE = B8_NUMLOTE AND C6_YCAVALE = B8_YCAVALE AND B8_PRODUTO = C6_PRODUTO AND B8_LOCAL = C6_LOCAL) ,0) AS  B8_YPESOLQ,
		cQuery   += " 					ISNULL((SELECT TOP 1 B8_YPESOBR FROM SB8010 WHERE D_E_L_E_T_ = '' AND C6_LOTECTL = B8_LOTECTL AND C6_NUMLOTE = B8_NUMLOTE AND C6_YCAVALE = B8_YCAVALE AND B8_PRODUTO = C6_PRODUTO AND B8_LOCAL = C6_LOCAL) ,0) AS  B8_YPESOBR,
		cQuery   += " 					C5_XTESALE,
		cQuery   += " 					RTRIM(LTRIM(C5_XVALEXT)) AS C5_XVALEXT,
		cQuery   += " 					UPPER(ISNULL(CONVERT(VARCHAR(MAX), CONVERT(VARBINARY(MAX), C5_YOBSEXT)),'')) AS C5_YOBSEXT,
		cQuery   += " 					RTRIM(LTRIM(E4_DESING))  AS E4_DESING,
		cQuery   += " 					RTRIM(LTRIM(E4_DESCRI))  AS E4_DESPOR,
		cQuery   += " 					RTRIM(LTRIM(C5_XPORTLO)) AS C5_XPORTLO,
		cQuery   += " 					RTRIM(LTRIM(C5_XTPCONT)) AS C5_XTPCONT,
		cQuery   += " 					RTRIM(LTRIM(C5_XINSURA)) AS C5_XINSURA,
		cQuery   += " 					RTRIM(LTRIM(C5_XFIMDES)) AS C5_XFIMDES,
		cQuery   += " 					RTRIM(LTRIM(C5_XFRFORW)) AS C5_XFRFORW,
		cQuery   += " 					C5_XWLIMIT,
		cQuery   += " 					CASE 
		cQuery   += " 						WHEN RTRIM(LTRIM(C6_YCLASSI)) = 'S' THEN 'STANDARD'
		cQuery   += " 						WHEN RTRIM(LTRIM(C6_YCLASSI)) = 'C' THEN 'COMMERCIAL'
		cQuery   += " 						WHEN RTRIM(LTRIM(C6_YCLASSI)) = 'P' THEN 'PREMIUM'
		cQuery   += " 						WHEN RTRIM(LTRIM(C6_YCLASSI)) = '' AND C6_CF='7949' THEN 'SAMPLE'
		cQuery   += " 						WHEN RTRIM(LTRIM(C6_YCLASSI)) = ''  THEN '' 
		cQuery   += " 						WHEN RTRIM(LTRIM(C6_YCLASSI)) = 'A' THEN 'SAMPLE'
		cQuery   += " 					END C6_YCLASSI,
		cQuery   += " 					C5_XTOTAL,
		cQuery   += " 					C5_XDESCON,
		cQuery   += " 					C5_XPDESTI,
		cQuery   += " 					ISNULL((SELECT B8_LOTEFOR FROM SB8010 WHERE D_E_L_E_T_ = '' AND B8_LOTECTL = C6_LOTECTL AND B8_NUMLOTE = '' AND SUBSTRING(B8_PRODUTO,1,2) ='BL' ),'') AS LOTE_FORNECEDOR
		cQuery   += " 			 FROM SC6010 SC6 INNER JOIN SC5010 SC5
		cQuery   += " 				   ON (C6_FILIAL = C5_FILIAL AND C6_NUM = C5_NUM )
		cQuery   += " 				   INNER JOIN SA1010 SA1
		cQuery   += " 				   ON (A1_COD = C5_CLIENTE AND A1_LOJA = C5_LOJACLI )
		cQuery   += " 				   INNER JOIN SYA010 SYA
		cQuery   += " 				   ON (A1_PAIS = YA_CODGI)
		cQuery   += " 				   INNER JOIN SA3010
		cQuery   += " 				   ON (A1_VEND=A3_COD)
		cQuery   += " 				   INNER JOIN SB5010 SB5
		cQuery   += " 				   ON (C6_PRODUTO = B5_COD)
		cQuery   += " 				   INNER JOIN SE4010 SE4
		cQuery   += " 				   ON (E4_CODIGO = C5_CONDPAG)
		cQuery   += " 			 WHERE SC6.D_E_L_E_T_ = ''
		cQuery   += " 			   AND SC5.D_E_L_E_T_ = ''
		cQuery   += " 			   AND SA1.D_E_L_E_T_ = ''
		cQuery   += " 			   AND SYA.D_E_L_E_T_ = ''
		cQuery   += " 			   AND SB5.D_E_L_E_T_ = ''
		cQuery   += " 			   AND SE4.D_E_L_E_T_ = ''
		//cQuery   += " 			   AND SC5.C5_BLQ <> '1'
		cQuery   += " 			   AND C5_NUM = '"+SC5->C5_NUM+"'
		cQuery   += " )TAB_PROFORMA
		cQuery   += " 	 FULL OUTER JOIN ZGO010 ZGO
		cQuery   += " 	   ON (C5_NUM = ZGO_PEDIDO)
		cQuery   += " WHERE C5_NUM <> ''
		cQuery   += "   AND ISNULL(ZGO_INVOIC,'') LIKE '%%'
		cQuery   += " )TB_PESO
		                                                          
		tcQuery cQuery alias TRB new
		dbSelectArea("TRB")
		dbgotop()
		
		IF !M->C5_TIPO $ "D/B" .And. LEFT(AllTrim(GdFieldGet("C6_PRODUTO",1)),2) <> 'BL'
			IF !EOF()
				dbSelectArea("SC5")		
				If RecLock("SC5",.f.)
					Replace SC5->C5_PESOL  With TRB->PLQ
					Replace SC5->C5_PBRUTO With TRB->PBR
					/*
					IF TRB->PLQ > SC5->C5_PBRUTO 
						Alert("Peso bruto esta menor que peso líquido. Favor corrigir!")
						Replace SC5->C5_PBRUTO With 0
					EndIf
					*/
					MsUnLock()
				EndIf	
			EndIf
		EndIf				
		dbSelectArea("TRB") 
		dbCloseArea()
		
		//Soma da quantidade de bandos
		cQuery   := " SELECT COUNT(*) QTD FROM (
		cQuery   += " SELECT DISTINCT C6_YCAVALE FROM (
		cQuery   += " SELECT		ISNULL(ZGO.ZGO_INVOIC,'') AS ZGO_INVOIC, 
		cQuery   += " 			TAB_PROFORMA.* FROM (
		cQuery   += " 			 SELECT	RTRIM(LTRIM(C5_NUM)) AS C5_NUM,
		cQuery   += " 					YEAR(CAST(C5_EMISSAO AS DATE) )ANO,
		cQuery   += " 					CAST(C5_EMISSAO AS DATE) AS C5_EMISSAO,
		cQuery   += " 					RTRIM(LTRIM(A1_NOME)) AS A1_NOME,
		cQuery   += " 					RTRIM(LTRIM(A1_END)) AS A1_END,
		cQuery   += " 					RTRIM(LTRIM(A1_BAIRRO)) AS A1_BAIRRO,
		cQuery   += " 					RTRIM(LTRIM(A1_DDI)) AS A1_DDI,
		cQuery   += " 					RTRIM(LTRIM(A1_DDD)) AS A1_DDD,
		cQuery   += " 					RTRIM(LTRIM(A1_TEL)) AS A1_TEL,
		cQuery   += " 					RTRIM(LTRIM(A1_CONTATO)) AS A1_CONTATO,
		cQuery   += " 					RTRIM(LTRIM(A3_NOME)) AS A3_NOME,
		cQuery   += " 					RTRIM(LTRIM(YA_PAIS_I)) AS YA_PAIS_I,
		cQuery   += " 					RTRIM(LTRIM(C5_XSEAL)) AS C5_XSEAL,
		cQuery   += " 					RTRIM(LTRIM(C5_XBOOKIN)) AS C5_XBOOKIN,
		cQuery   += " 					RTRIM(LTRIM(C5_XVESSEL)) AS C5_XVESSEL,
		cQuery   += " 					RTRIM(LTRIM(C5_XCONTAI)) AS C5_XCONTAI,
		cQuery   += " 					RTRIM(LTRIM(C5_XTARE)) AS C5_XTARE,
		cQuery   += " 					RTRIM(LTRIM(C5_XPO)) AS C5_XPO,
		cQuery   += " 					RTRIM(LTRIM(C6_LOTECTL)) AS C6_LOTECTL,
		cQuery   += " 					RTRIM(LTRIM(C6_NUMLOTE)) AS C6_NUMLOTE,
		cQuery   += " 					C6_CF,
		cQuery   += " 					C6_XPESO AS PESO_AMOSTRAS,
		cQuery   += " 					C6_YESPLIQ * 100 AS C6_YESPLIQ,
		cQuery   += " 					RTRIM(LTRIM(B5_YCEMEIN)) AS C6_DESCRI, 
		cQuery   += " 					RTRIM(LTRIM(C6_DESCRI))  AS C6_DESCRI_P, 
		cQuery   += " 					IIF(RTRIM(LTRIM(C6_YCAVALE))='','-',RTRIM(LTRIM(C6_YCAVALE)))  AS C6_YCAVALE,
		cQuery   += " 					C6_PRCVEN,
		cQuery   += " 					ROUND(C6_PRCVEN / 10.764,2) AS PRCVEN_SQFT,
		cQuery   += " 					C5_XVLRFIN AS VALOR_FINANCEIRO,
		cQuery   += " 					C6_QTDVEN,
		cQuery   += " 					IIF(C6_NUMLOTE<>'',1,0) AS QTD_CHAPAS,
		cQuery   += " 					IIF(C6_CF='7949',0,C6_QTDVEN) AS QTD_TOTAL_FATURAR,
		cQuery   += " 					IIF(C6_UM='M2',C6_QTDVEN,0) AS QTD_TOTAL_M2,
		cQuery   += " 					IIF(C6_UM='PC',C6_QTDVEN,0) AS QTD_TOTAL_PC,
		cQuery   += " 					C6_UM,
		cQuery   += " 					C6_UNSVEN,
		cQuery   += " 					C6_VALOR,
		cQuery   += " 					IIF(C6_CF='7949',C6_VALOR,0) AS SAMPLE_DESC,
		cQuery   += " 					C6_VALDESC,
		cQuery   += " 					C6_YCOMLIQ,
		cQuery   += " 					C6_YALTLIQ,
		cQuery   += " 					C6_YTOTLIQ,
		cQuery   += " 					ISNULL((SELECT TOP 1 B8_YPESOLQ FROM SB8010 WHERE D_E_L_E_T_ = '' AND  C6_LOTECTL = B8_LOTECTL AND C6_NUMLOTE = B8_NUMLOTE AND C6_YCAVALE = B8_YCAVALE AND B8_PRODUTO = C6_PRODUTO) ,0) AS  B8_YPESOLQ,
		cQuery   += " 					ISNULL((SELECT TOP 1 B8_YPESOBR FROM SB8010 WHERE D_E_L_E_T_ = '' AND C6_LOTECTL = B8_LOTECTL AND C6_NUMLOTE = B8_NUMLOTE AND C6_YCAVALE = B8_YCAVALE AND B8_PRODUTO = C6_PRODUTO) ,0) AS  B8_YPESOBR,
		cQuery   += " 					C5_XTESALE,
		cQuery   += " 					RTRIM(LTRIM(C5_XVALEXT)) AS C5_XVALEXT,
		cQuery   += " 					UPPER(ISNULL(CONVERT(VARCHAR(MAX), CONVERT(VARBINARY(MAX), C5_YOBSEXT)),'')) AS C5_YOBSEXT,
		cQuery   += " 					RTRIM(LTRIM(E4_DESING))  AS E4_DESING,
		cQuery   += " 					RTRIM(LTRIM(E4_DESCRI))  AS E4_DESPOR,
		cQuery   += " 					RTRIM(LTRIM(C5_XPORTLO)) AS C5_XPORTLO,
		cQuery   += " 					RTRIM(LTRIM(C5_XTPCONT)) AS C5_XTPCONT,
		cQuery   += " 					RTRIM(LTRIM(C5_XINSURA)) AS C5_XINSURA,
		cQuery   += " 					RTRIM(LTRIM(C5_XFIMDES)) AS C5_XFIMDES,
		cQuery   += " 					RTRIM(LTRIM(C5_XFRFORW)) AS C5_XFRFORW,
		cQuery   += " 					C5_XWLIMIT,
		cQuery   += " 					CASE 
		cQuery   += " 						WHEN RTRIM(LTRIM(C6_YCLASSI)) = 'S' THEN 'STANDARD'
		cQuery   += " 						WHEN RTRIM(LTRIM(C6_YCLASSI)) = 'C' THEN 'COMMERCIAL'
		cQuery   += " 						WHEN RTRIM(LTRIM(C6_YCLASSI)) = 'P' THEN 'PREMIUM'
		cQuery   += " 						WHEN RTRIM(LTRIM(C6_YCLASSI)) = '' AND C6_CF='7949' THEN 'SAMPLE'
		cQuery   += " 						WHEN RTRIM(LTRIM(C6_YCLASSI)) = ''  THEN '' 
		cQuery   += " 						WHEN RTRIM(LTRIM(C6_YCLASSI)) = 'A' THEN 'SAMPLE'
		cQuery   += " 					END C6_YCLASSI,
		cQuery   += " 					C5_XTOTAL,
		cQuery   += " 					C5_XDESCON,
		cQuery   += " 					C5_XPDESTI,
		cQuery   += " 					ISNULL((SELECT B8_LOTEFOR FROM SB8010 WHERE D_E_L_E_T_ = '' AND B8_LOTECTL = C6_LOTECTL AND B8_NUMLOTE = '' AND SUBSTRING(B8_PRODUTO,1,2) ='BL' ),'') AS LOTE_FORNECEDOR
		cQuery   += " 			 FROM SC6010 SC6 INNER JOIN SC5010 SC5
		cQuery   += " 				   ON (C6_FILIAL = C5_FILIAL AND C6_NUM = C5_NUM )
		cQuery   += " 				   INNER JOIN SA1010 SA1
		cQuery   += " 				   ON (A1_COD = C5_CLIENTE AND A1_LOJA = C5_LOJACLI )
		cQuery   += " 				   INNER JOIN SYA010 SYA
		cQuery   += " 				   ON (A1_PAIS = YA_CODGI)
		cQuery   += " 				   INNER JOIN SA3010
		cQuery   += " 				   ON (A1_VEND=A3_COD)
		cQuery   += " 				   INNER JOIN SB5010 SB5
		cQuery   += " 				   ON (C6_PRODUTO = B5_COD)
		cQuery   += " 				   INNER JOIN SE4010 SE4
		cQuery   += " 				   ON (E4_CODIGO = C5_CONDPAG)
		cQuery   += " 			 WHERE SC6.D_E_L_E_T_ = ''
		cQuery   += " 			   AND SC5.D_E_L_E_T_ = ''
		cQuery   += " 			   AND SA1.D_E_L_E_T_ = ''
		cQuery   += " 			   AND SYA.D_E_L_E_T_ = ''
		cQuery   += " 			   AND SB5.D_E_L_E_T_ = ''
		cQuery   += " 			   AND SE4.D_E_L_E_T_ = ''
	  //cQuery   += "              --AND SC5.C5_BLQ <> '1'
		cQuery   += " 			   AND C5_NUM = '"+SC5->C5_NUM+"'
		cQuery   += " 
		cQuery   += " )TAB_PROFORMA
		cQuery   += " 	 FULL OUTER JOIN ZGO010 ZGO
		cQuery   += " 	   ON (C5_NUM = ZGO_PEDIDO)
		cQuery   += " WHERE C5_NUM <> ''
	   //cQuery  += "   --AND ISNULL(ZGO_INVOIC,'') LIKE '%'+@INVOICE+'%'
		cQuery   += " )TB_TOTAL_CAV
		cQuery   += " WHERE C6_YCAVALE <> '-'
		cQuery   += " )TB_QTD_CAV
		
		
		tcQuery cQuery alias TRB new
		dbSelectArea("TRB")
		dbgotop()
		
		IF !EOF()
			dbSelectArea("SC5")		
			If RecLock("SC5",.f.)
				Replace SC5->C5_VOLUME1  With TRB->QTD  
				MsUnLock()
			EndIf	
		EndIf
						
		dbSelectArea("TRB") 
		dbCloseArea()
		
		If RecLock("SC5",.f.)
			IF SC5->C5_VOLUME1 == 0
				SC5->C5_VOLUME1 := 1
			EndIf
			MsUnLock()
		EndIf	
		
	EndIf

EndIf

Return()

/*
User Function MDesTot()
****************************************************************************************************************
*    Programa dar o desconto  
*
****
Local nValorTemp := 0

For nX := 1 To Len(aCols)
		GdFieldPut("C6_DESCONT",M->C5_DESC1,nX) 
Next nX

Return(.T.) 
*/

Static Function MValidPedV(oProcess, lEnd,lRet)
****************************************************************************************************************
*   /* Programa para validar o pedido de venda tabela de preço de chapas - Qualitá */
*
****

Local cQuery := ""

Local nPosCava := aScan(aHeader, {|x| AllTrim(x[2]) == "C6_YCAVALE"}) //Cavalete
Local nPosLOTE := aScan(aHeader, {|x| AllTrim(x[2]) == "C6_LOTECTL"}) //SubLote
Local nPosSUBL := aScan(aHeader, {|x| AllTrim(x[2]) == "C6_NUMLOTE"}) //Lote
Local nPosLOCA := aScan(aHeader, {|x| AllTrim(x[2]) == "C6_LOCAL"})    //Lote
Local cGPExec  := GetMv("MV_XGPEXE")

Local aMsgPrc  := {}

oProcess:SetRegua1(7)

/*
Somente para Qualitá
*/
ConOut(FUNNAME())
If SubString(CNUMEMP,1,2) == "01" .And. (INCLUI == .T. .Or. ALTERA == .T.) .AND. (FUNNAME() <> "GROA001")


	/*
	Somente para Mercado Externo
	Validação mercado interno campos FollowUp
	*/
	If M->C5_YTIPO $ "ME/MI"
		IF M->C5_XSHOWFO == "S"
			If Empty(M->C5_XFOLLST) .Or. Empty(M->C5_XPENDEN) .Or. Empty(M->C5_XDTLIBF)
				Alert("FollowUp='SIM'! O P.Venda não pode ser salvo sem as informações de Pendência/Situação/Data de Liberação. ")	
				Return(.F.)
			EndIf
		EndIf
	EndIf

	cDesMoed := ""
	oFont := TFont():New('Arial Black',,-18,.T.)
	
	If     M->C5_MOEDA == 1
		cDesMoed := "1 - (R$)   R E A L"
	ElseIf M->C5_MOEDA == 2
		cDesMoed := "2 - ($)    D O L A R"
	ElseIf M->C5_MOEDA == 3
		cDesMoed := "3 - (€)    E U R O"
	EndIf

	DEFINE MSDIALOG _oDlgMoeda TITLE "Moeda" FROM u_MGETTELA(178),u_MGETTELA(181) TO u_MGETTELA(342),u_MGETTELA(577) PIXEL
		// Cria as Groups do Sistema
		@ u_MGETTELA(001),u_MGETTELA(003) TO u_MGETTELA(062),u_MGETTELA(195) LABEL "" PIXEL OF _oDlgMoeda
	
		// Cria Componentes Padroes do Sistema
		@ u_MGETTELA(009),u_MGETTELA(010) Say "Pedido sendo salvo na moeda:" Size u_MGETTELA(075),u_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlgMoeda
		@ u_MGETTELA(033),u_MGETTELA(078) Say cDesMoed 						 Size u_MGETTELA(090),u_MGETTELA(080) COLOR CLR_HMAGENTA FONT oFont PIXEL OF _oDlgMoeda
		@ u_MGETTELA(064),u_MGETTELA(156) Button "OK" ACTION(Close(_oDlgMoeda)) Size u_MGETTELA(037),u_MGETTELA(012) PIXEL OF _oDlgMoeda
	ACTIVATE MSDIALOG _oDlgMoeda CENTERED 

	ConOut("******************************************" )
	ConOut("Inicio P.E = MT410TOK Qualitá" )
	ConOut("******************************************" )	
	/*
	****************************************************************
	Conferencia da tabela de preço com o desconto cadastrado por classificação comercial
	****************************************************************
	*/
	dbSelectArea("SA1")
	dbSetOrder(1)
	dbSeek(xFilial("SA1") + M->C5_CLIENTE + M->C5_LOJACLI )
	
	If !Empty(SA1->A1_INFDESC)
		Alert("Aviso! Este cliente possui um desconto padrão! Verifique sempre pela tela [F5].")
	EndIf
	
	oProcess:IncRegua1("[1-7] - Conferência da tabela de preço com o desconto cadastrado!")  
	
	IF M->C5_TIPO $ "D/B"
		Return(.T.)
	EndIf
	
	For nX := 1 To Len(aCols)
		/*
		Regra geral de tabela de preços 
		*/
		//EXECUTAR SOMENTE PARA ESTES GRUPOS 
		//"0005/0006/0034/0035/0036"
		dbSelectArea("SB1")
		dbSetOrder(1)
		dbSeek(xFilial("SB1")+ AllTrim(GdFieldGet("C6_PRODUTO",nX)) )
				
		IF AllTrim(SB1->B1_GRUPO) $ cGPExec		
	
			If Empty(SA1->A1_TABELA)

				If Empty(GdFieldGet("C6_YCLASSI",nX))
					cClassif := "P"
				Else
					cClassif := AllTrim(GdFieldGet("C6_YCLASSI",nX))
				EndIf
						
				cQuery  := " SELECT DA1_CODTAB,DA0_DESCRI,DA0_DESGER ,DA1_PRCVEN , CASE WHEN DA1_PERDES=0  THEN 1 WHEN DA1_PERDES<>0 THEN DA1_PERDES END  DA1_PERDES 
				cQuery  += "   FROM DA0010 DA0 
				cQuery  += "        INNER JOIN DA1010 DA1 
				cQuery  += " ON (DA0_CODTAB = DA1_CODTAB)
				
				If SubStr(AllTrim(AllTrim(GdFieldGet("C6_PRODUTO",nX))) ,1,2) <> 'AM'
					cQuery  += "  WHERE DA0_YCLASS IN ('"+ cClassif +"')
					cQuery  += "    AND DA1_CODPRO = '" + AllTrim(GdFieldGet("C6_PRODUTO",nX))+"'"		
				Else
					cQuery  += "  WHERE DA1_CODPRO = '" + AllTrim(GdFieldGet("C6_PRODUTO",nX))+"'"	
				EndIf
						
				IF !EMPTY(SA1->A1_MULTTAB)
					cQuery  += "    AND DA0_CODTAB IN ("+AllTrim(SA1->A1_MULTTAB)+")"
				ELSE
					cQuery  += "    AND DA0_CODTAB IN ('000','001','002','003')
				EndIf
				cQuery  += "    AND DA0.D_E_L_E_T_ = ''
				cQuery  += "    AND DA1.D_E_L_E_T_ = ''
				
				tcQuery cQuery alias TRB new
				dbSelectArea("TRB")
				dbgotop()
				
				If Empty(TRB->DA1_PRCVEN) .and. !GDDeleted(nX) 
					Alert("[C6_PRCVEN] - Tabela de preço não encontrada! Linha:(" + Alltrim(str(nX)) +") Confira a classif. do produto ou Mult.Tabelas preços no Cad. Cliente." )
					lRet := .F.
					//sleep(300)	
					M->C5_BLQ  := '1'
				EndIf
				
				If GdFieldGet("C6_PRCVEN",nX) <  ((TRB->DA1_PRCVEN * TRB->DA0_DESGER)) .and. !GDDeleted(nX)
					//aAdd(aMsgPrc,"[C6_PRCVEN] - Preço menor que o permitido para esse produto. Linha:" + Alltrim(str(nX))+" Tabela de Preço:" + AllTrim(TRB->DA1_CODTAB) + "-"+ AllTrim(TRB->DA0_DESCRI))  
					aAdd(aMsgPrc,"Cavalete:"+GdFieldGet("C6_YCAVALE",nX)+" Tabela de Preço:" + AllTrim(TRB->DA1_CODTAB) + "-"+ AllTrim(TRB->DA0_DESCRI) )
					//lRet := .F.
					ConOut("******************************************")
					ConOut("[C6_PRCVEN] - Preço menor que o permitido para esse produto. Linha:" + Alltrim(str(nX)))
					ConOut("******************************************")
					//sleep(300)
					M->C5_BLQ  := '1'	
					GdFieldPut("C6_XMOTBLQ","PREÇO MENOR QUE A TABELA DE PREÇO:"+ AllTrim(TRB->DA1_CODTAB),nX)	
				ELSE
				  	GdFieldPut("C6_XMOTBLQ","",nX)
				EndIf
				/*
				If GdFieldGet("C6_PRUNIT",nX) <  ((TRB->DA1_PRCVEN * TRB->DA0_DESGER)) .and. !GDDeleted(nX)
					Alert("[C6_PRUNIT] - Preço menor que o permitido para esse produto. Linha:" + Alltrim(str(nX))+" Tabela de Preço:" + AllTrim(TRB->DA1_CODTAB) + "-"+ AllTrim(TRB->DA0_DESCRI) ) 
					lRet := .F.
					ConOut("******************************************" )
					ConOut("[C6_PRUNIT] - Preço menor que o permitido para esse produto. Linha:" + Alltrim(str(nX)))
					ConOut("******************************************" )
					sleep(300)	
				EndIf	
				*/
				//GdFieldPut("C6_PRUNIT",0,nX)
				//GdFieldPut("C6_PRUNIT",0,nX) // 23/09/2019
				GdFieldPut("C6_PRCREF",TRB->DA1_PRCVEN,nX)
				
				dbSelectArea("TRB") 
				dbCloseArea()
				
				IF lRet == .F.
					Return(lRet)
				EndIf
			Else
				/*
				Usado para definir uma tabela de preço especifica para o cliente
				*/
	
				cQuery  := " SELECT DA1_CODTAB,DA0_DESCRI,DA0_DESGER,DA1_PRCVEN , CASE WHEN DA1_PERDES=0  THEN 1 WHEN DA1_PERDES<>0 THEN DA1_PERDES END  DA1_PERDES
				cQuery  += "   FROM DA0010 DA0 
				cQuery  += "        INNER JOIN DA1010 DA1 
				cQuery  += " ON (DA0_CODTAB = DA1_CODTAB)
				
				If SubStr(AllTrim(AllTrim(GdFieldGet("C6_PRODUTO",nX))) ,1,2) <> 'AM'
					cQuery  += "  WHERE DA1_CODTAB IN ('"+ M->C5_TABELA +"')
					cQuery  += "    AND DA1_CODPRO = '"+AllTrim(GdFieldGet("C6_PRODUTO",nX))+"'
				Else
					//TABELA PADRÃO DE AMOSTRAS
					cQuery  += "  WHERE DA1_CODPRO = '"+AllTrim(GdFieldGet("C6_PRODUTO",nX))+"'
					cQuery  += "    AND DA0_CODTAB IN ('000')
				EndIf
		
				cQuery  += "    AND DA0.D_E_L_E_T_ = ''
				cQuery  += "    AND DA1.D_E_L_E_T_ = ''
				
				
				tcQuery cQuery alias TRB new
				dbSelectArea("TRB")
				dbgotop()
				
				If Empty(TRB->DA1_PRCVEN) .and. !GDDeleted(nX)
					Alert("[C6_PRCVEN] - Tabela de preço não encontrada! Linha:(" + Alltrim(str(nX)) +") Confira a classif. do produto ou Mult.Tabelas preços no Cad. Cliente." )
					lRet := .F.
					//sleep(300)
					M->C5_BLQ  := '1'
				EndIf
				
			    If GdFieldGet("C6_PRCVEN",nX) <  ((TRB->DA1_PRCVEN * TRB->DA0_DESGER)) .and. !GDDeleted(nX)
					aAdd(aMsgPrc,"Cavalete:"+GdFieldGet("C6_YCAVALE",nX)+" Tabela de Preço:" + AllTrim(TRB->DA1_CODTAB) + "-"+ AllTrim(TRB->DA0_DESCRI) ) 
					//lRet := .F.
					ConOut("******************************************" )
					ConOut("[C6_PRCVEN] - Preço menor que o permitido para esse produto. Linha:" + Alltrim(str(nX)))
					ConOut("******************************************" )
					//sleep(300)	
					M->C5_BLQ  := '1'
					GdFieldPut("C6_XMOTBLQ","Preço menor que a tabela:"+ AllTrim(TRB->DA1_CODTAB),nX)	
				ELSE
				  	GdFieldPut("C6_XMOTBLQ","",nX)
				EndIf
				/*
				If GdFieldGet("C6_PRUNIT",nX) <  ((TRB->DA1_PRCVEN * TRB->DA0_DESGER)) .and. !GDDeleted(nX)
					Alert("[C6_PRUNIT] - Preço menor que o permitido para esse produto. Linha:" + Alltrim(str(nX))+" Tabela de Preço:" + AllTrim(TRB->DA1_CODTAB) + "-"+ AllTrim(TRB->DA0_DESCRI) ) 
					lRet := .F.
					ConOut("******************************************" )
					ConOut("[C6_PRUNIT] - Preço menor que o permitido para esse produto. Linha:" + Alltrim(str(nX)))
					ConOut("******************************************" )
					sleep(300) 
				EndIf	
				*/
				//GdFieldPut("C6_PRUNIT",0,nX) //23/09/2019
				GdFieldPut("C6_PRCREF",TRB->DA1_PRCVEN,nX)
				
				dbSelectArea("TRB") 
				dbCloseArea()
				
				IF lRet == .F.
					Return(lRet)
				EndIf
			
			EndIf
				
		EndIf
	Next nX
	
	cMSG := ""
	
	For nX:=1 to Len(aMsgPrc)
			If Empty(cMSG)
				cMSG := "[C6_PRCVEN] - Preço menor que o permitido para esse produto. Linha:" + chr(13)+chr(10) 
			EndIf
			cMSG += aMsgPrc[nX] + chr(13)+chr(10)   
	Next nX
	
	
	If !Empty(cMSG)
		Alert(cMSG) 
	EndIf
	
	
	/*
	***************************************************************************************
	Verifica o erro do saldo no cavalete e no pedido 
	***************************************************************************************
	
	nQtdPedVend := 0
	
	For nX := 1 To Len(aCols)
	
		dbSelectArea("SB1")
		dbSetOrder(1)
		dbSeek(xFilial("SB1")+ AllTrim(GdFieldGet("C6_PRODUTO",nX)) )
	
		nQtdPedVend := GdFieldGet("C6_QTDVEN",nX))
		
		IF AllTrim(SB1->B1_GRUPO) $ cGPExec 
			If !GDDeleted(nX)
				
			EndIf
		EndIf
		
	Next nX
	*/
	
	ConOut("******************************************" )
	ConOut("P.E = MT410TOK Qualitá Validação de cavaletes" )
	ConOut("******************************************" )

	/*
	****************************************************************
	Conferencia do cavaletes duplicados no proprio pedido 
	****************************************************************
	*/
	aNumCav 	:= {}		
	aTodCav 	:= {}
    aGriCav 	:= {}
    aGriCavDup 	:= {}
    aGriLSPv    := {}
    aLSPvLoca   := {}	
    aCavZero    := {}
    aNumCavPro  := {}
    
	For nX := 1 To Len(aCols)
	
		//EXECUTAR SOMENTE PARA ESTES GRUPOS 
		//"0005/0006/0034/0035/0036"
		dbSelectArea("SB1")
		dbSetOrder(1)
		dbSeek(xFilial("SB1")+ AllTrim(GdFieldGet("C6_PRODUTO",nX)) )
		
		//ALERT(SB1->B1_COD +"||"+ SB1->B1_GRUPO)
		
		IF AllTrim(SB1->B1_GRUPO) $ cGPExec 
	
			If !Empty(GdFieldGet("C6_YCAVALE",nX)) .and. !GDDeleted(nX) 
				If Empty( aScan(aNumCav,GdFieldGet("C6_YCAVALE",nX)) )
				 	aAdd(aNumCav   ,GdFieldGet("C6_YCAVALE",nX))
				 	aAdd(aNumCavPro,{GdFieldGet("C6_YCAVALE",nX),GdFieldGet("C6_PRODUTO",nX)})
				EndIf
			EndIf
			If !GDDeleted(nX)
				If Empty(aScan(aGriCav,AllTrim(GdFieldGet("C6_PRODUTO",nX)) + GdFieldGet("C6_YCAVALE",nX) + GdFieldGet("C6_LOTECTL",nX) + GdFieldGet("C6_NUMLOTE",nX)) )
					aAdd(aGriCav , AllTrim(GdFieldGet("C6_PRODUTO",nX)) + GdFieldGet("C6_YCAVALE",nX) + GdFieldGet("C6_LOTECTL",nX) + GdFieldGet("C6_NUMLOTE",nX)  )
					aAdd(aGriLSPv, {GdFieldGet("C6_LOTECTL",nX) , GdFieldGet("C6_NUMLOTE",nX) , AllTrim(GdFieldGet("C6_PRODUTO",nX))} )
				Else
					IF LEFT(AllTrim(GdFieldGet("C6_PRODUTO",nX)),2)<>'AM'
						aAdd(aGriCavDup, AllTrim(GdFieldGet("C6_PRODUTO",nX))+GdFieldGet("C6_YCAVALE",nX) + GdFieldGet("C6_LOTECTL",nX) + GdFieldGet("C6_NUMLOTE",nX)  )
					EndIf
				EndIf
			EndIf
			
		EndIf
		
	Next nX
	
	cMSG := ""
	For nX:=1 to Len(aGriCavDup)
			If Empty(cMSG)
				cMSG := "Duplicados no pedido atual:" + chr(13)+chr(10) 
			EndIf
			cMSG += "O item: " + aGriCavDup[nX] + chr(13)+chr(10)   
	Next nX
	
	If !Empty(cMSG)
		Alert(cMSG)
		lRet := .F.
		//sleep(300)	
		Return(lRet)
		//sleep(300) 
	EndIf
	
	/*
	****************************************************************
	Conferencia se todos os itens do cavales estao completos (Se estiverem em cavaletes)
	Cavalete apagado por completo
	A mesma rotina confere se existe produtos sem saldo.
	****************************************************************
	*/
	
	oProcess:IncRegua1("[2-7] - Teste de cavales completos,apagados e sem saldo!")
	
	
	/*
	SOMENTE SE O PEDIDO NAO ESTIVER FATURADO 
	*/
	IF LEN(AllTrim(M->C5_NOTA)) <> 9
	
		/*
		VALIDAÇÃO DO CAMPO DA ULTIMA ATUALIZAÇÃO DO FOLLOWUP
		*/
		M->C5_XULDTAU := DDATABASE

		For nX := 1 To Len(aNumCavPro)
		
			//EXECUTAR SOMENTE PARA ESTES GRUPOS 
			//"0005/0006/0034/0035/0036"
			dbSelectArea("SB1")
			dbSetOrder(1)
			dbSeek(xFilial("SB1")+ aNumCavPro[nX][2] )
			
			IF AllTrim(SB1->B1_GRUPO) $ cGPExec
		
			 	cQuery  := "  SELECT B8_PRODUTO,B1_DESC,B8_YCAVALE,B8_LOTECTL,B8_NUMLOTE,B8_YCAVALE+B8_LOTECTL+B8_NUMLOTE+B8_LOCAL CHAVE,B8_LOCAL,B8_SALDO 
			 	cQuery  += "    FROM SB8010 SB8 INNER JOIN SB1010 SB1 ON (B8_PRODUTO = B1_COD)
			 	cQuery  += "   WHERE SB8.D_E_L_E_T_ = ''
			 	cQuery  += "     AND SB1.D_E_L_E_T_ = ''
			 	cQuery  += "     AND B8_YCAVALE = '"+aNumCavPro[nX][1]+"'
			 	cQuery  += "     AND B8_PRODUTO = '"+aNumCavPro[nX][2]+"'
			 	cQuery  += "     AND B8_ORIGLAN = 'BD'
			 	cQuery  += "     AND B8_SALDO   <> 0
			 	
			 	tcQuery cQuery alias TRB new
				dbSelectArea("TRB")
				dbgotop()
				Do While !EOF()
				
					/*
					cavaletes incompletos
					*/
					IF !aScan(aCols,{|x|x[nPosCava]+x[nPosLOTE]+x[nPosSUBL]+x[nPosLOCA] == TRB->CHAVE })  
						aAdd(aTodCav,{ TRB->CHAVE , AllTrim(TRB->B1_DESC) , aNumCav[nX] , TRB->B8_LOTECTL , TRB->B8_NUMLOTE , TRB->B8_LOCAL} )
					Else
						if GDDeleted(aScan(aCols,{|x|x[nPosCava]+x[nPosLOTE]+x[nPosSUBL]+x[nPosLOCA] == TRB->CHAVE }))
							aAdd(aTodCav,{ TRB->CHAVE , AllTrim(TRB->B1_DESC) , aNumCav[nX] , TRB->B8_LOTECTL , TRB->B8_NUMLOTE,TRB->B8_LOCAL} )
						EndIf 
					EndIf
					
					/*
					Sem Saldo
					*/
					If TRB->B8_SALDO == 0  
						aAdd(aCavZero,{ TRB->CHAVE ,AllTrim(TRB->B8_PRODUTO)+"-"+ AllTrim(TRB->B1_DESC) , aNumCav[nX] , TRB->B8_LOTECTL , TRB->B8_NUMLOTE, TRB->B8_LOCAL} )
					EndIf
					
					dbSelectArea("TRB") 
					dbSkip()
				EndDo
				
				
				/*
				Cavalete apagado
				*/
				dbSelectArea("TRB")
				dbgotop()
				If EOF() .And.  !Empty(aNumCav[nX])
				
					IF !aScan(aCols,{|x|x[nPosCava]+x[nPosLOTE]+x[nPosSUBL]+x[nPosLOCA] == TRB->CHAVE })  
						aAdd(aTodCav,{ TRB->CHAVE , AllTrim(TRB->B1_DESC) , aNumCav[nX] , TRB->B8_LOTECTL , TRB->B8_NUMLOTE, TRB->B8_LOCAL} )
					Else
						if GDDeleted(aScan(aCols,{|x|x[nPosCava]+x[nPosLOTE]+x[nPosSUBL]+x[nPosLOCA] == TRB->CHAVE }))
							aAdd(aTodCav,{ TRB->CHAVE , AllTrim(TRB->B1_DESC) , aNumCav[nX] , TRB->B8_LOTECTL , TRB->B8_NUMLOTE , TRB->B8_LOCAL} )
						EndIf 
					EndIf
					
				EndIf
				
				dbSelectArea("TRB") 
				dbCloseArea()
			EndIf
			
		Next nX
		
		/*
		Incompletos/Apagado
		*/
		cMSG := ""
		For nX:=1 to Len(aTodCav)
			If Empty(cMSG)
				cMSG := "Cavaletes incompletos/Apagado:" + chr(13)+chr(10) 
			EndIf			
			cMSG +=     "  ->" + AllTrim(aTodCav[nX][2]) + " Cav.[" + Alltrim(aTodCav[nX][3]) + "] Lote[" + Alltrim(aTodCav[nX][4]) + "] SubLote[" + Alltrim(aTodCav[nX][5]) + "] Local ["+ Alltrim(aTodCav[nX][6]) +"]."+ chr(13)+chr(10)   
		Next nX
		
		If !Empty(cMSG)
			Alert(cMSG)
			//AVISO("Cavaletes incompletos:", cMSG , { "Fechar" }, 3)
			lRet := .F.
			//sleep(300)	
			Return(lRet) 
		EndIf
	
		/*
		Sem Saldo
		*/
		cMSG := ""
		For nX:=1 to Len(aCavZero)
			If Empty(cMSG)
				cMSG := "Produtos sem saldo:" + chr(13)+chr(10) 
			EndIf			
			cMSG +=     "  ->" + AllTrim(aCavZero[nX][2]) + " Cav.[" + Alltrim(aCavZero[nX][3]) + "] Lote[" + Alltrim(aCavZero[nX][4]) + "] SubLote.[" + Alltrim(aCavZero[nX][5]) + "]"+ chr(13)+chr(10)   
		Next nX
		
		If !Empty(cMSG)
			IF (!Empty(C5_NOTA).Or.C5_LIBEROK=='E' .And. Empty(C5_BLQ))
				Alert(cMSG)
			ELse 
				Alert(cMSG)
				//AVISO("Cavaletes incompletos:", cMSG , { "Fechar" }, 3)
				lRet := .F.
				//sleep(300)	
				Return(lRet) 
			EndIf
		EndIf
		
	EndIf
	
	/*
	****************************************************************
	Conferencia se existe estes Lote/SubLotes em um PVenda salvo
	****************************************************************
	*/
	
	oProcess:IncRegua1("[3-7] - Conferência se existe  Lote/SubLotes em um P.Venda salvo!")
	
	For nX := 1 To Len(aGriLSPv)
		 	
		//EXECUTAR SOMENTE PARA ESTES GRUPOS 
		//"0005/0006/0034/0035/0036"
		dbSelectArea("SB1")
		dbSetOrder(1)
		dbSeek(xFilial("SB1")+ AllTrim(aGriLSPv[nX][3]) )
		
		IF AllTrim(SB1->B1_GRUPO) $ cGPExec .AND. !Empty(aGriLSPv[nX][1])
		 	cQuery  := " SELECT C6_NUM,C6_ITEM,C6_LOTECTL,C6_NUMLOTE ,C6_DESCRI 
		 	cQuery  += "   FROM SC6010 SC6 INNER JOIN SC5010 SC5 ON (C5_FILIAL = C6_FILIAL AND C5_NUM = C6_NUM)
		 	cQuery  += "  WHERE SC6.D_E_L_E_T_ = ''
		 	cQuery  += "    AND SC5.D_E_L_E_T_ = ''
		 	cQuery  += "    AND C5_TIPO = 'N'
		 	cQuery  += "    AND C6_NOTA = ''
		 	cQuery  += " 	AND C6_LOTECTL = '"+aGriLSPv[nX][1]+"'
		 	cQuery  += " 	AND C6_NUMLOTE = '"+aGriLSPv[nX][2]+"'
		 	cQuery  += "    AND C6_NUM <> '"+AllTrim(M->C5_NUM)+"'
		 	
		 	tcQuery cQuery alias TRB new
			dbSelectArea("TRB")
			dbgotop()
			Do While !EOF()
			
				If !aScan(aLSPvLoca,{|x|alltrim(x[1]) == AllTrim(TRB->C6_NUM) })
					aAdd(aLSPvLoca,{ AllTrim(TRB->C6_NUM) , TRB->C6_ITEM,TRB->C6_LOTECTL , TRB->C6_NUMLOTE , AllTrim(TRB->C6_DESCRI) } )
				Else
					aLSPvLoca[aScan(aLSPvLoca,{|x|alltrim(x[1]) == AllTrim(TRB->C6_NUM) })][2] := aLSPvLoca[aScan(aLSPvLoca,{|x|alltrim(x[1]) == AllTrim(TRB->C6_NUM) })][2] + "," + TRB->C6_ITEM
				EndIf
				
				dbSelectArea("TRB") 
				dbSkip()
			EndDo
			
			dbSelectArea("TRB") 
			dbCloseArea()
		
		EndIf
		
	Next nX
	
	cMSG := ""
	For nX:=1 to Len(aLSPvLoca)
			If Empty(cMSG)
				cMSG := "Itens encontrados em outro P.Venda:" + chr(13)+chr(10) 
			EndIf
			cMSG += "  -> P.Venda:" + aLSPvLoca[nX][1] +" Item:"+ aLSPvLoca[nX][2] +" Prod.:" + aLSPvLoca[nX][5] + chr(13)+chr(10)   
	Next nX
	
	If !Empty(cMSG)
		Alert(cMSG)
		//AVISO("Itens encontrados em outro P.Venda:", cMSG , { "Fechar" }, 3)
		//sleep(300)	
		lRet := .F.
		Return(lRet) 
	EndIf
	
	/*
	*******************************************
	Validação Valores fiscais e descontos e totais
	*******************************************
	*/

	oProcess:IncRegua1("[4-7] - Conferência fiscal, descontos e valores!")

	aDadosGrv := FCalImp(@oProcess)
	
	If LEN(aDadosGrv)>0
		M->C5_XVALEXT := AllTrim(Extenso(aDadosGrv[3],.f.,M->C5_MOEDA,,"3",.t.,.f.))
		M->C5_XTOTAL  := aDadosGrv[1] -  M->C5_DESCONT
		M->C5_XDESCON := aDadosGrv[2] +  M->C5_DESCONT
		M->C5_XVLRFIN := aDadosGrv[3] -  M->C5_DESCONT
		//M->C5_XDESPES := aDadosGrv[4]
		//M->C5_XSEGURO := aDadosGrv[5]
	EndIf 
	
		
	/*
	*******************************************
	Validação do peso para Amostras 
	*******************************************
	*/
	oProcess:IncRegua1("[5-7] - Validação do peso para Amostras!")
	
	cMSG := ""
	
	For nX := 1 To Len(aCols)
	
		//EXECUTAR SOMENTE PARA ESTES GRUPOS 
		//"0005/0006/0034/0035/0036"
		dbSelectArea("SB1")
		dbSetOrder(1)
		dbSeek(xFilial("SB1")+ AllTrim(GdFieldGet("C6_PRODUTO",nX)) )
		
		IF AllTrim(SB1->B1_GRUPO) $ cGPExec
	
			If Empty(GdFieldGet("C6_XPESO",nX)) .and. !GDDeleted(nX) .and. SubStr(AllTrim(AllTrim(GdFieldGet("C6_PRODUTO",nX))) ,1,2) == 'AM'
			
				If Empty(cMSG)
					cMSG := "Amostras sem Peso:" + chr(13)+chr(10) 
				EndIf
				cMSG += "  -> Item do PV:" + GdFieldGet("C6_ITEM",nX) + " Prod.:" + AllTrim(GdFieldGet("C6_DESCRI",nX)) + chr(13)+chr(10)  
								
			EndIf
			
			
			If !GDDeleted(nX) .and. (SubStr(AllTrim(AllTrim(GdFieldGet("C6_PRODUTO",nX))) ,1,2) == 'AM' .Or. AllTrim(GdFieldGet("C6_YCLASSI",nX)) == "A")
				M->C5_BLQ  := '1'
				GdFieldPut("C6_XMOTBLQ","Produto Amostra! Requer aprovação." ,nX)
			EndIf
			
			If M->C5_DESCONT  <> 0
				M->C5_BLQ  := '1'
				GdFieldPut("C6_XMOTBLQ", GdFieldGet("C6_XMOTBLQ",nX) + "// Ped. Venda com desconto de indenização." ,nX)
			EndIf
			
		EndIf
	Next nX
	
	If M->C5_DESCONT  <> 0
		cMSG += (chr(13)+chr(10)) + (chr(13)+chr(10)) + "O Campo de desconto de indenização foi preenchido. Ped. Venda requer aprovação." + chr(13)+chr(10)
	EndIf
	
	IF !EMPTY(cMSG)
		If MsgYesNo(cMSG + chr(13)+chr(10)+ "Deseja continuar?" )
			lRet := .t.
		Else
			lRet := .F.
			//sleep(300)	
			Return(lRet)
		EndIf
	EndIf
	
	/*
	*******************************************
	Validação para não permitir salvar o pedido com chapas sem cavaletes 
	*******************************************
	*/
	oProcess:IncRegua1("[6-7] - Chapas sem cavaletes!")
	
	cMSG := ""
	
	/*
	Não validar para filial de SP 
	não validar para Pedidos de Transferencia
	*/
	IF M->C5_YTIPO <> "TF" .AND. SubString(CNUMEMP,1,8) == "01010101" 

		For nX := 1 To Len(aCols)
		
			//EXECUTAR SOMENTE PARA ESTES GRUPOS 
			//"0005/0006/0034/0035/0036"
			dbSelectArea("SB1")
			dbSetOrder(1)
			dbSeek(xFilial("SB1")+ AllTrim(GdFieldGet("C6_PRODUTO",nX)) )  
			
			IF AllTrim(SB1->B1_GRUPO) $ cGPExec
		
				If Empty(GdFieldGet("C6_YCAVALE",nX)) .and. !GDDeleted(nX) .and. SubStr(AllTrim(AllTrim(GdFieldGet("C6_PRODUTO",nX))) ,1,2) == 'CH'
				
					If Empty(cMSG)
						cMSG := "Chapas sem cavaletes:" + chr(13)+chr(10) 
					EndIf
					cMSG += "  -> Item do PV:" + GdFieldGet("C6_ITEM",nX) + " Prod.:" + AllTrim(GdFieldGet("C6_DESCRI",nX)) + chr(13)+chr(10)  
					
				EndIf
			EndIf
		Next nX
		
		If !Empty(cMSG)
			Alert(cMSG)
			lRet := .F.
			Return(lRet) 
		EndIf

	EndIf

	/*
	*******************************************
	Validação para não permitir salvar o pedido fora dos almoxarificados ou locais determinados 
	*******************************************
	*/
	oProcess:IncRegua1("[7-7] - Almoxarifado não permitido !")
	
	cMSG := ""
	
	For nX := 1 To Len(aCols)
	
		//EXECUTAR SOMENTE PARA ESTES GRUPOS 
		//"0005/0006/0034/0035/0036"
		dbSelectArea("SB1")
		dbSetOrder(1)
		dbSeek(xFilial("SB1")+ AllTrim(GdFieldGet("C6_PRODUTO",nX)) )
		
		IF AllTrim(SB1->B1_GRUPO) $ cGPExec
	
			If !GdFieldGet("C6_LOCAL",nX) $ "03/05"  .and. !GDDeleted(nX) .and. SubStr(AllTrim(AllTrim(GdFieldGet("C6_PRODUTO",nX))) ,1,2) $ 'CH/AM'
			
				If Empty(cMSG)
					cMSG := "Almoxarifado não permitido ! " + chr(13)+chr(10) 
				EndIf
				cMSG += "  -> Item do PV:" + GdFieldGet("C6_ITEM",nX) + " Prod.:" + AllTrim(GdFieldGet("C6_DESCRI",nX)) + chr(13)+chr(10)  
				
			EndIf
		EndIf
	Next nX
	
	If !Empty(cMSG)
		Alert(cMSG)
		lRet := .F.
		Return(lRet) 
	EndIf
	
	/*
	Valor de indenização
	IF M->C5_DESCONT <> 0
		Alert("Este pedido possui desconto indenizatório de valor. O pedido será bloqueado!")
		M->C5_BLQ  := '1'
	EndIf
	*/
	/*
	VALIDAÇÃO DO MOBGRAN
	*/
	If  FunName() $ "GROA014" .And. INCLUI == .T.
		
		If !Empty(M->C5_XIDMOB)

			/*
			Verifica se existe a chave no mobgran.
			*/
			cQuery  := " SELECT * FROM ZSA010 WHERE D_E_L_E_T_ = '' AND ZSA_IDMOBP = '"+AllTrim(M->C5_XIDMOB)+"' AND ZSA_STATUS ='ATIVA'
			
			tcQuery cQuery alias TRB new
			dbSelectArea("TRB")
			dbgotop()
			
			If EOF() 
				lRet := .F.
			EndIf

			If TRB->ZSA_STATUS <> 'ATIVA'
				lRet := .F.
			EndIf
			
			If lRet == .F.
				Alert("Chave não encontrada ou Status:(>>"+ TRB->ZSA_STATUS +"<<) no MobGran!")
				Return(lRet)	
			EndIf

			dbSelectArea("TRB") 
			dbCloseArea()	

		Else
			
			lRet := .F.
			Alert("Chave do MobGran em branco! Favor informar um código.")
			Return(lRet)

		EndIf

	ElseIf FunName() $ "GROA013" 
		If AllTrim(M->C5_XIDMOB) == '-'
			lRet := .T.
		else
			cQuery  := " SELECT * FROM ZSA010 WHERE D_E_L_E_T_ = '' AND ZSA_IDMOBP = '"+AllTrim(M->C5_XIDMOB)+"' AND ZSA_STATUS ='ATIVA'
			
			tcQuery cQuery alias TRB new
			dbSelectArea("TRB")
			dbgotop()
			
			If EOF() 
				lRet := .F.
			EndIf

			If TRB->ZSA_STATUS <> 'ATIVA'
				lRet := .F.
			EndIf

			If lRet == .F.
				Alert("Chave não encontrada ou Status:(>>"+ TRB->ZSA_STATUS +"<<) no MobGran!")
				Return(lRet)	
			EndIf			
			
			dbSelectArea("TRB") 
			dbCloseArea()	
			

		EndIf
	EndIf
	
	ConOut("******************************************" )
	ConOut("Final P.E = MT410TOK Qualitá" )
	ConOut("******************************************" )
	
	SetKey(VK_F5,)
	SetKey(VK_F6,)
EndIf

Return(lRet)

User Function ClintToMob()
****************************************************************************************************************
* /*Gatilho C5_XIDMOB*/    
*
****
Local aArea   := GetArea() 
Local cQuery  := " SELECT * FROM ZSA010 WHERE D_E_L_E_T_ = '' AND ZSA_IDMOBP = '"+AllTrim(M->C5_XIDMOB)+" ' AND ZSA_STATUS ='ATIVA'
Local cClient := "" 

tcQuery cQuery alias TRBidMob new
dbSelectArea("TRBidMob")
dbgotop()

If !EOF()
	cClient := AllTrim(TRBidMob->ZSA_CLIENT)
Else
	cClient := M->C5_CLIENT
EndIf

dbSelectArea("TRBidMob") 
dbCloseArea()	

RestArea(aArea)

Return(cClient)

Static Function FCalImp(oProcess) 
****************************************************************************************************************
*    
*
****
************************************** 
* Calculo totais e Impostos
************************************** 
Local aArea     := GetArea() 
Local nX        := 0 
Local nPrcTot   := 0
Local _aTotalNF := {} 
Local nValDesc  := 0
Local nItem:= 0                             

//IF FunName() == Alltrim("GROA014")

	ConOut("************************************")
	ConOut("MaFisIni")                 
	ConOut("************************************")
	
	// Inicia rotina de calculo dos impostos 
	MaFisIni(Iif(Empty(M->C5_CLIENT),M->C5_CLIENTE,M->C5_CLIENT),;	// 1-Codigo Cliente/Fornecedor 
	     	M->C5_LOJAENT,;          								// 2-Loja do Cliente/Fornecedor 
	     	IIf(M->C5_TIPO$"DB","F","C"),;                    		// 3-C:Cliente , F:Fornecedor 
	     	M->C5_TIPO,;                    						// 4-Tipo da NF 
	     	M->C5_TIPOCLI,;          								// 5-Tipo do Cliente/Fornecedor 
	     	Nil,; 
	     	Nil,; 
	     	Nil,; 
	     	Nil,; 
	     	"GROA014") 
	
     If (Inclui .Or. Altera) 
               nItem:= 0
	   
			   ConOut("************************************")
			   ConOut("MaFisAdd")                                  
			   ConOut("************************************") 
			   
			   oProcess:SetRegua2(len(aCols))
			   
               For nX := 1 to len(aCols) 
                    If !GDDeleted(nX)							//Validar se o registro nao esta deletado 
                         
                         nItem:= nItem + 1 						// Quantidade para recalcular 
                         
                         // Adiciona dados dos produtos na rotina de calculo de impostos       
                         MaFisAdd( GdFieldGet("C6_PRODUTO",nX),; 
                                   GdFieldGet("C6_TES"    ,nX),; 
                                   GdFieldGet("C6_QTDVEN" ,nX),; 
                                   GdFieldGet("C6_PRCVEN" ,nX),; 
                                   0,; //GdFieldGet("C6_VALDESC",nX)
                                   "",; 
                                   "",; 
                                   0,; 
                                   0,; 
                                   0,; 
                                   0,; 
                                   0,; 
                                   GdFieldGet("C6_VALOR",nX),; 
                                   0,; 
                                   0,; 
                                   0)
                               
                         nValDesc := nValDesc + Round(GdFieldGet("C6_VALDESC",nX),2)
                      
                         oProcess:IncRegua2("Cavalete ["+GdFieldGet("C6_YCAVALE",nX)+"] Lote-Chapa: "+AllTrim(GdFieldGet("C6_LOTECTL",nX))+"-"+GdFieldGet("C6_NUMLOTE",nX)  )
                         
                         //ConOut(nValDesc)
                         //ConOut(nItem)
                    EndIf 
                
               Next nX                
     EndIf 
     
     /*
     _nIcmsRet := 0 
     For nLo:=1 To nItem           
          _nIcmsRet += MaFisRet(nLo,"LF_ICMSRET") // Retorna valor da ST  
     Next nLo       
     */
	   
	 aAdd(_aTotalNF,MaFisRet(,"NF_TOTAL"))
	 aAdd(_aTotalNF,nValDesc)
	 aAdd(_aTotalNF,MaFisRet(,"NF_BASEDUP"))
// 	 aAdd(_aTotalNF,MaFisRet(,"NF_DESPESA"))
//	 aAdd(_aTotalNF,MaFisRet(,"NF_SEGURO"))  
	
	 MaFisEnd() 	// Encerra rotina de calculo de impostos 

//EndIf

RestArea(aArea) 

Return(_aTotalNF)


User Function GMA410MNU() 
****************************************************************************************************************
*    
*
****
Local aButtons := {}

IF FunName() == Alltrim("GROA014")	
	//Gerando invoice
	aRotina[16][1] := "Gerar Invoice"
	aRotina[16][2] := 'Processa({|| u_MNumInv()},,"Gravando....")'
	
	//"Imprime Packing List"
	//aRotina[20][2] := "u_RelInWeb('RQ0002','Imprime Packing List [RQ0002]','u_fParAut(2)')"
	aRotina[17][2][5][2] := "u_RelInWeb('RQ0002','Imprime Packing List [RQ0002]','u_fParAut(2)')"
	
	//"Imprime Commercial Invoice" 
	//aRotina[19][2] := "u_RelInWeb('RQ0004','Imprime Invoice (CH/AM)[RQ0004]','u_fParAut(4)')"
	aRotina[17][2][4][2] := "u_RelInWeb('RQ0004','Imprime Invoice (CH/AM)[RQ0004]','u_fParAut(4)')"
	
	
	//"Imprime Proforma Invoice"
	//aRotina[18][2] := "u_RelInWeb('RQ0003','Imprime Proforma Invoice [RQ0003]','u_fParAut(2)')"	 
	aRotina[17][2][3][2] := "u_RelInWeb('RQ0003','Imprime Proforma Invoice [RQ0003]','u_fParAut(2)')"
	
	//aRotina[17][2] := "U_proformaInvoice()"//#Brittes Alterada chamada da Funcao
	//"Imprime Pedido de Venda"
	aRotina[17][2][1][1] := "Pre-Nota" 
	aRotina[17][2][1][2] := "u_MATR730Q()"
	
	//"Imprime Romaneio"
	aRotina[17][2][2][1] := "Imprime Invoice (BLOCOS)"
	aRotina[17][2][2][2] := "u_RelInWeb('RQ0004_BLOCK','Imprime Invoice (BLOCOS) [RQ0004_BLOCK]'    ,'u_fParAut(4)')"
	//aadd(aRotina,{'Imprime Invoice (BLOCOS)',"u_RelInWeb('RQ0004_BLOCK','Imprime Invoice (BLOCOS) [RQ0004_BLOCK]'    ,'u_fParAut(4)')" , 0 , 3,0,NIL})
	
ElseIf FunName() == Alltrim("GROA013")

	aadd(aRotina,{'Imp. Packing List',"u_RelInWeb('RQ0002_P','Imprime Packing List [RQ0002_P]'    ,'u_fParAut(2)')" , 0 , 3,0,NIL})
	aadd(aRotina,{'Imp. Proforma'    ,"u_RelInWeb('RQ0003_P','Imprime Proforma Invoice [RQ0003_P]','u_fParAut(2)')" , 0 , 3,0,NIL})	
	aadd(aRotina,{'Pre-Nota'    	 ,"u_MATR730Q()" 											  					, 0 , 3,0,NIL})	
	
EndIf

aadd(aRotina,{'Ajustes Gerais {P.Venda}',"u_AjuGerais()" , 0 , 3,0,NIL})

aadd(aRotina,{'Aprovação WhatsApp ',"u_WAppAprov()" , 0 , 3,0,NIL})

aadd(aRotina,{'Limpar FollowUp' ,"u_ClearFol()"  , 0 , 3,0,NIL})	

Return aButtons

User Function ClearFol()
****************************************************************************************************************
*    // LIMPA FOLLOWUP PELO PERIODO SOMENTE OVADOS
*
****
Local cQuery:=""

Private aPerg := {}
Private cPerg := "MLIMPAFOLL"

Aadd(aPerg,{cPerg,"Data Incial  ?"		,"D",08,00,"G","","","","","","","",""})
Aadd(aPerg,{cPerg,"Data Final   ?"		,"D",08,00,"G","","","","","","","",""})

U_Testasx1(cPerg,aPerg,.T.)

If ! Pergunte(cPerg,.T.)
	Return()
EndIf

If Empty(mv_par01)
	Alert("Data inicial não pode ficar em branco!")
	Return()
EndIf

If Empty(mv_par02)
	Alert("Data final não pode ficar em branco!")
	Return()
EndIf

cQuery :=  "  UPDATE SC5010
cQuery +=  "    SET C5_XSHOWFO =	'N'
cQuery +=  "  WHERE R_E_C_N_O_ IN(
cQuery +=  "  						SELECT REC FROM (
cQuery +=  "  										SELECT	  R_E_C_N_O_ REC,
cQuery +=  "  												  C5_FILIAL,
cQuery +=  "  												  C5_NUM ,
cQuery +=  "  												  C5_NOTA+'/'+C5_SERIE AS NF,
cQuery +=  "  												  (SELECT F2_EMISSAO FROM SF2010 WHERE D_E_L_E_T_ = '' AND F2_FILIAL = C5_FILIAL AND F2_DOC = C5_NOTA AND F2_SERIE = C5_SERIE AND F2_CLIENTE = C5_CLIENTE AND F2_LOJA = C5_LOJACLI) DATA
cQuery +=  "  										  FROM SC5010 
cQuery +=  "  										 WHERE D_E_L_E_T_ = ''
cQuery +=  "  										   AND C5_XSHOWFO IN('S')
cQuery +=  "  										   AND C5_TIPO IN ('N')
cQuery +=  "  										   AND C5_XVLRFIN <> 0
cQuery +=  "  										   AND RTRIM(LTRIM(C5_XFOLLST)) IN ('OVADO','CARREGADO','FATURADO')
cQuery +=  "  									)TB_TEMP
cQuery +=  "  						 WHERE DATA BETWEEN '"+dToS(mv_par01)+"' AND '"+dToS(mv_par02)+"'
cQuery +=  "  						)

TcSQLExec(cQuery)

Alert("FollowUp removidos com sucesso!")

Return()

User Function WAppAprov()
****************************************************************************************************************
*    
*
****
Local cProt   := ""
Local cProt2  := ""
Local cMotiv  := ""
Local cQuery  := "SELECT DISTINCT UPPER(RTRIM(LTRIM(C6_XMOTBLQ))) C6_XMOTBLQ FROM SC6010 WHERE D_E_L_E_T_ ='' AND C6_FILIAL+C6_NUM = '" + SC5->C5_FILIAL + SC5->C5_NUM + "' AND UPPER(RTRIM(LTRIM(C6_XMOTBLQ))) <> ''


tcQuery cQuery alias TRBE new
dbSelectArea("TRBE")
dbgotop()

Do While !EOF()
	
	cMotiv := cMotiv + TRBE->C6_XMOTBLQ + chr(13)+chr(10)

	dbSelectArea("TRBE") 
	dbSkip()
EndDo

dbSelectArea("TRBE") 
dbCloseArea()

IF FunName() == Alltrim("GROA014")
	WaitRunSrv( '"D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\wget\wget.exe" -t 1 "http://192.168.1.101:10530/ReportServer/Pages/ReportViewer.aspx?%2fItinga_reports%2fRQ0003&FILIAL='+AllTrim(SC5->C5_FILIAL)+'&NUMPED='+AllTrim(SC5->C5_NUM)+'&rs:Format=pdf" -O "D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\RQ0003.PDF"' , .t. , "D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\wget\" )
ElseIf FunName() == Alltrim("GROA013")
	WaitRunSrv( '"D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\wget\wget.exe" -t 1 "http://192.168.1.101:10530/ReportServer/Pages/ReportViewer.aspx?%2fItinga_reports%2fRQ0003_P&FILIAL='+AllTrim(SC5->C5_FILIAL)+'&NUMPED='+AllTrim(SC5->C5_NUM)+'&rs:Format=pdf" -O "D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\RQ0003.PDF"' , .t. , "D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\wget\" )
EndIf

sleep(4000)

/*
Limite de Credito
*/
//WaitRunSrv( '"D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\wget\wget.exe" -t 1 "http://192.168.1.101:10530/ReportServer/Pages/ReportViewer.aspx?%2fItinga_reports%2fRQ0057&CLIENTES='+AllTrim(SC5->C5_CLIENTE)+AllTrim(SC5->C5_LOJACLI)+'&rs:Format=pdf" -O "D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\RQ0057.PDF"' , .t. , "D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\wget\" )

//Grupo de Faturamento Whatsapp

/*
Teste
*/
//cProt  := U_SWENARWAP("5551997331669","Aprovação da Proforma:" +AllTrim(SC5->C5_NUM) + chr(13)+chr(10) + " Motivo:" + cMotiv + chr(13)+chr(10) + " Usuário:" + SUBSTR(CUSUARIO,7,15), "PROFORMA"+AllTrim(SC5->C5_NUM),"RQ0003","PDF","\RELINWEB\RQ0003.pdf")

/*
Oficial
*/
cProt  := U_SWENARWAP("5527995295180-1587589430@g.us","Aprovação da Proforma:" +AllTrim(SC5->C5_NUM) + chr(13)+chr(10) + " Motivo:" + cMotiv + chr(13)+chr(10) + " Usuário:" + SUBSTR(CUSUARIO,7,15), "PROFORMA"+AllTrim(SC5->C5_NUM),"RQ0003","PDF","\RELINWEB\RQ0003.pdf")

IF cProt = "" .or. cProt = nil 
	Alert("ERRO!!! O WhatsApp pode estar passando por alguma instabilidade no momento. Aguarde alguns instantes de tente novamente mais tarde!")
	Return()
EndIf

If  RecLock("WAM",.T.) 

	Replace WAM_FILIAL  With "" 
	Replace WAM_DATA    With Date()
	Replace WAM_HORA    With Time()
	Replace WAM_ID      With cProt
	Replace WAM_MSG     With "Aprovação da Proforma:" +AllTrim(SC5->C5_NUM) + "Motivo:" + cMotiv +  "Usuário:" + SUBSTR(CUSUARIO,7,15) + " Cliente: " + AllTrim(SC5->C5_XFRFORW) 
	//Replace WAM_TELL    With "5551997331669"
	//Replace WAM_TELL    With "5533984022125"
	Replace WAM_INDEX   With SC5->C5_FILIAL + SC5->C5_NUM
	Replace WAM_PERG    With "S"
	//Replace WAM_DATAR   With ""
	//Replace WAM_HORAR   With ""
	//Replace WAM_RESPOSV With ""
	
	IF SubString(CNUMEMP,1,2) == "05"
		Replace WAM_EXEC    With 'ITINGA-PV'
	Else
		Replace WAM_EXEC    With 'QUALITA-PV'
	EndIf
	

   MsUnLock()
EndIf
		
Alert("WhatsApp enviado com sucesso! " + cProt)

Return()


User Function WAppResp()
****************************************************************************************************************
*NÃO USADO     
*
**** 
Local cQuery  := "SELECT TOP 1 * FROM WAM010 WHERE D_E_L_E_T_ = '' AND WAM_INDEX = '"+SC5->C5_FILIAL + SC5->C5_NUM+"' ORDER BY R_E_C_N_O_ DESC"
				  
Local aRetMsg := ""

tcQuery cQuery alias TRB new
dbSelectArea("TRB")
dbgotop()

If !Empty(TRB->WAM_ID)
	aRetMsg :=	strTokArr(U_SWREMGWAP(TRB->WAM_ID), ',' )
EndIf

dbSelectArea("TRB") 
dbCloseArea()

If !"false" $ aRetMsg[7]
	If ("SIM" $ Upper(aRetMsg[8])) .OR. ( "APROVADO" $ Upper(aRetMsg[8]) )
	
	 
		RecLock("SC5",.F.)
			SC5->C5_BLQ  := ''
		MsUnlock()	
		/*
		dbSelectArea("SC6")
		dbSetOrder(1)
		dbSeek(SC5->C5_FILIAL + SC5->C5_NUM)
		While SC6->(!EOF()) .And. SC6->C6_FILIAL + SC6->C6_NUM == SC5->C5_FILIAL + SC5->C5_NUM
		                                      
		      MaLibDoFat(SC6->(RecNo()),SC6->C6_QTDVEN,,,.T.,.T.,.F.,.F.)
		
		   SC6->(dBSkip())
		EndDo
		*/
	EndIf
Else 
	Alert("Pedido ainda não liberado!")
EndIf

Return() 

User Function AjuGerais()
****************************************************************************************************************
*    
*
****
Private aPerg := {}
Private cPerg := "AJUSGERAIS"
Private nOpc  := 0

nOpc := Aviso("Atenção","Estes ajustes devem ser usados somente em casos especiais! Pedido: ["+SC5->C5_NUM+"] ." ,{"Confirma","Abandona"})	

If nOpc == 2
	Return()
EndIf
                  
Aadd(aPerg,{cPerg,"Alterar o peso líquido:","N",12,04,"G","","","","","","","",""})
Aadd(aPerg,{cPerg,"Alterar o peso bruto :" ,"N",12,04,"G","","","","","","","",""})

Aadd(aPerg,{cPerg,"Alterar qtd volume 1:"  ,"N",03,00,"G","","","","","","","",""})     
Aadd(aPerg,{cPerg,"Alterar qtd Box:"       ,"N",03,00,"G","","","","","","","",""})

U_Testasx1(cPerg,aPerg,.t.) 

If ! Pergunte(cPerg,.T.)
	Return()
EndIf

RecLock("SC5",.F.)
	SC5->C5_PESOL    := mv_par01
	SC5->C5_PBRUTO   := mv_par02
	SC5->C5_VOLUME1  := mv_par03
	SC5->C5_VOLUME2  := mv_par04
MsUnlock()	

Aviso("Atualização:","Pedido: ["+SC5->C5_NUM+"] atualizado com sucesso!" ,{"Ok"})

Return()


User Function MNumInv()
****************************************************************************************************************
*    
*
****
Local cNumInvo := GetMv("MV_XNUMINV")
Local cQuery   := ""

IF EMPTY(SC5->C5_YINVOIC)
	
	ProcRegua(3) 
	
	PutMv("MV_XNUMINV",Soma1(cNumInvo))
	
	IncProc("Criando Invoice:" + cNumInvo) 
	Sleep( 1000 ) 
	
	IncProc("Salvando..." + cNumInvo)
	Sleep( 1000 ) 
	
	IncProc("Liberando...." + cNumInvo)
	SC5->(reclock("SC5", .F.))
	SC5->C5_YINVOIC := cNumInvo									
	SC5->(msUnLock())
	Sleep( 1000 )
	
	AVISO("Invoice", "Invoice gerada com sucesso! Número=" + cNumInvo  , { "Fechar" }, 1)
	
	//U_GROA014A()
	//AxInclui("SZO")
	
	dbSelectArea("ZGO")
	dbSetOrder(1)
	If dbSeek(xFilial("ZGO") + SC5->C5_NUM + SC5->C5_CLIENTE + SC5->C5_LOJACLI)
		ZGO->(reclock("ZGO", .F.))
		ZGO->ZGO_INVOIC := cNumInvo									
		ZGO->(msUnLock())
		//U_GROA014A()
	Else
		ZGO->(reclock("ZGO", .T.))
		ZGO->ZGO_FILIAL := xFilial("ZGO")
		ZGO->ZGO_INVOIC := cNumInvo	
		ZGO->ZGO_PEDIDO := SC5->C5_NUM
		ZGO->ZGO_CLIENT := SC5->C5_CLIENTE
		ZGO->ZGO_LOJA	:= SC5->C5_LOJACLI						
		ZGO->(msUnLock())
	EndIf
	
	cQuery := "SELECT CAST(M2_DATA AS DATE) DATA, MAX(M2_MOEDA2) 'DOLAR' , MAX(M2_MOEDA3) 'EURO'
	cQuery += "  FROM SM2010
	cQuery += "  WHERE D_E_L_E_T_ = ''
	cQuery += "    AND M2_DATA  = '"+DToS(dDataBase)+"'
	cQuery += "   GROUP BY M2_DATA
	
	TcQuery cQuery Alias TMP_MOEDA New
	dbSelectArea("TMP_MOEDA")
	
	SC5->(reclock("SC5", .F.))
	SC5->C5_MENNOTA := AllTrim(SC5->C5_MENNOTA) + " //INVOICE:" + SC5->C5_YINVOIC + "-" + LEFT(DToS(dDataBase),4) +  "  TAXA DO DOLAR R$:" + AllTrim(STR(TMP_MOEDA->DOLAR)) + " CNTR:" + AllTrim(SC5->C5_XCONTAI) 
	SC5->(msUnLock())
	
	dbSelectArea("TMP_MOEDA")
	dbCloseArea()            
Else 

	AVISO("Invoice", "Já existe invoice para esse pedido! Número=" + SC5->C5_YINVOIC  , { "Fechar" }, 1)

EndIf	

Return()


User Function fParAut(nTipo)
****************************************************************************************************************
*    
*
****
Local cRet := ""

If nTipo = 2
	cRet :=  "&FILIAL=" + AllTrim(SC5->C5_FILIAL) +"&NUMPED=" + AllTrim(SC5->C5_NUM) 
Else
	dbSelectArea("ZGO")
	dbSetorder(1)
	If dbSeek(xFilial("ZGO")+AllTrim(SC5->C5_NUM))
		cRet := "&FILIAL=" + AllTrim(ZGO->ZGO_FILIAL) +"&INVOICE=" + AllTrim(ZGO->ZGO_INVOIC)
	Else
		Alert("Pedido de venda sem Invoice!")
	EndIf
EndIf

Return(cRet)


User Function GA410CONS() 
****************************************************************************************************************
*    
*
****
Local aButtons := {}

SetKey(VK_F5,{||u_MCONSUTDET()})
SetKey(VK_F6,{||u_GERAMSGPAD()})

aAdd(aButtons, {"", {|| u_MCONSUTDET()}, "[F5] Consulta GrPlus", "[F5] Consulta GrPlus"})
aAdd(aButtons, {"", {|| u_GERAMSGPAD()}, "[F6] Gera Msg Padrão", "[F6] Gera Msg Padrão"})

Return aButtons

User Function GERAMSGPAD()
****************************************************************************************************************
*    
*
****
Local cQuery   := ""         
Local aPeso    := {}
Local nResult  := 0     
Local cBoleto  := ""
Local cMsgNota := ""    
Local cMsgNota2:= ""                         
Local cNotas   := ""
Local aGriCavDW:= {}
Local cGPExec  := GetMv("MV_XGPEXE")
Local cInCavDw := ""

/*
Mensagem foi retirada de uso conforme chamado numero 1109
Controle de drawback em tempo Real.
*/
IF TYPE("aCols") == "A"
	For nX := 1 To Len(aCols)
		dbSelectArea("SB1")
		dbSetOrder(1)
		dbSeek(xFilial("SB1")+ AllTrim(GdFieldGet("C6_PRODUTO",nX)) )
		IF AllTrim(SB1->B1_GRUPO) $ cGPExec 
			If !GDDeleted(nX) .and. LEFT(GdFieldGet("C6_LOTECTL",nX),2)=='DW'
				If Empty(aScan(aGriCavDW,GdFieldGet("C6_LOTECTL",nX)) )
					aAdd(aGriCavDW , GdFieldGet("C6_LOTECTL",nX)  )
				EndIf
			EndIf
		EndIf
	Next nX
	If !Empty(aGriCavDW)
		For nX := 1 To Len(aGriCavDW)		
			aGriCavDW[nX] := LEFT(AllTrim(aGriCavDW[nX]),8)
			cInCavDw := cInCavDw +  "'"+AllTrim(aGriCavDW[nX])+"',"
		Next nX
		cInCavDw := Left(cInCavDw,Len(cInCavDw)-1)
	EndIf
	

	If !Empty(cInCavDw)
		
		cQuery := " SELECT DISTINCT DOC ,
		cQuery += " 				EMISSAO
		cQuery += "   FROM(
 		cQuery += " 	 SELECT
 		cQuery += " 			LOTE,
		cQuery += " 			IIF(EMISSAO<>'',EMISSAO,ISNULL((SELECT TOP 1 D1_EMISSAO FROM SD1010 WHERE D_E_L_E_T_ = '' AND D1_LOTECTL = LEFT(LOTE, LEN(RTRIM(LTRIM(LOTE)))-1) AND LEFT(D1_COD,2) = 'BL'),'')) EMISSAO,
 		cQuery += " 			IIF(DOC<>'',DOC,ISNULL((SELECT TOP 1 D1_DOC FROM SD1010 WHERE D_E_L_E_T_ = '' AND D1_LOTECTL = LEFT(LOTE, LEN(RTRIM(LTRIM(LOTE)))-1) AND LEFT(D1_COD,2) = 'BL'),'')) DOC
 		cQuery += " 	   FROM (
 		cQuery += " 			SELECT	LOTE,
 		cQuery += " 					IIF(FORNECE<>'000011','', DOC) DOC,
 		cQuery += " 					EMISSAO,
		cQuery += " 					D1_SERIE,
 		cQuery += " 					FORNECE
 		cQuery += " 					FROM (	
 		cQuery += " 							SELECT DISTINCT D1_LOTECTL LOTE, 				
 		cQuery += " 											D1_DOC DOC,
		cQuery += " 											D1_EMISSAO EMISSAO, 
 		cQuery += " 											D1_SERIE,
 		cQuery += " 											D1_FORNECE  FORNECE
 		cQuery += " 							FROM SD1010 
 		cQuery += " 							WHERE D_E_L_E_T_ = '' 
 		cQuery += " 							AND D1_LOTECTL IN ("+cInCavDw+")
 		cQuery += " 						 )TB_TEMP
 		cQuery += " 		  )TAB_TEMP
 		cQuery += " 	)TAB_TEMP_FIM
 		cQuery += " WHERE DOC <> ''
		
		TcQuery cQuery Alias TMP_NOTA New
		dbSelectArea("TMP_NOTA")
		
		Do While !EOF()
		
			cNotas := cNotas + AllTrim(TMP_NOTA->DOC) + "-" + dtoc(STOd(TMP_NOTA->EMISSAO))+ " ,"  
		
			dbSelectArea("TMP_NOTA")
			dbSkip()
		EndDo
		
		dbSelectArea("TMP_NOTA")
		dbCloseArea()
	
		//cMsgNota += "ESTA NOTA FISCAL CONTEM INSUMOS IMPORTADOS ADQUIRIDOS DE ITINGA MINERACAO LTDA. PELA NF:"+cNOtas+" AMPARADO PELO REGIME DRAWBACK INTEGRADO - MODALIDADE SUSPENSAO, TIPO INTERMEDIARIO ATO CONCESSÓRIO Nº 20190019344 DE 08/05/2019.///"   
	EndIf
	
	cQuery := "SELECT CAST(M2_DATA AS DATE) DATA, MAX(M2_MOEDA2) 'DOLAR' , MAX(M2_MOEDA3) 'EURO'
	cQuery += "  FROM SM2010
	cQuery += "  WHERE D_E_L_E_T_ = ''
	cQuery += "    AND M2_DATA  = '"+DToS(dDataBase)+"'
	cQuery += "  GROUP BY M2_DATA 
	
	TcQuery cQuery Alias TMP_MOEDA New
	dbSelectArea("TMP_MOEDA")
	
	cMsgNota += "INVOICE:" + AllTrim(M->C5_YINVOIC) + "-" + LEFT(DToS(dDataBase),4) +  "  TAXA DO DOLAR R$:" + AllTrim(STR(TMP_MOEDA->DOLAR)) + " CNTR:" + AllTrim(M->C5_XCONTAI) + " LACRE:" + AllTrim(M->C5_XSEAL)
		        
	dbSelectArea("TMP_MOEDA")
	dbCloseArea()                       
	
	If !Empty(m->C5_MENNOTA)
		If MsgYesNo("O campo [C5_MENNOTA], já possui informção. Deseja subistituir a mensagem original?" )
			m->C5_MENNOTA := memoline(AllTrim(cMsgNota),254,1,,.T.)
			m->C5_MSG2    := memoline(AllTrim(cMsgNota),254,2,,.T.)
		EndIf		
	Else
		m->C5_MENNOTA := memoline(AllTrim(cMsgNota),254,1,,.T.)
		m->C5_MSG2    := memoline(AllTrim(cMsgNota),254,2,,.T.)
	EndIf
	
Else

	SetKey(VK_F5,)
	SetKey(VK_F6,)

EndIf

Return



Static Function MAltVlrAut(cNumItem,cNumChapa) 
****************************************************************************************************************
*    
*
****
Local nEdit1	 := 0
Local oEdit1

Local nEdit2	 := 0
Local oEdit2

Local nEdit3	 := SA1->A1_INFDESC
Local oEdit3

Local nEdit4	 := 0
Local oEdit4

Local lNExec     := .F.
Local lNDele     := .F.

// Variaveis Private da Funcao
Private _oDlgVlr				// Dialog Principal

// Variaveis que definem a Acao do Formulario                    
DEFINE MSDIALOG _oDlgVlr TITLE " ITEM " + cNumItem   FROM u_MGETTELA(223),u_MGETTELA(173) TO u_MGETTELA(359),u_MGETTELA(520) PIXEL

	// Cria as Groups do Sistema
	@ u_MGETTELA(003),u_MGETTELA(005) TO u_MGETTELA(044),u_MGETTELA(168) LABEL "" PIXEL OF _oDlgVlr

	// Cria Componentes Padroes do Sistema
	@ u_MGETTELA(010),u_MGETTELA(008) Say "Valor Negociado:" Size u_MGETTELA(066),u_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlgVlr
	@ u_MGETTELA(010),u_MGETTELA(050) MsGet oEdit1 Var nEdit1            Size u_MGETTELA(35)  ,u_MGETTELA(009) picture("@E 9,999,999.99999") COLOR CLR_BLACK PIXEL OF _oDlgVlr
	
	@ u_MGETTELA(010),u_MGETTELA(085) Say "Desconto padrão: {%}" Size u_MGETTELA(066),u_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlgVlr
	@ u_MGETTELA(010),u_MGETTELA(130) MsGet oEdit3 Var nEdit3            Size u_MGETTELA(35) ,u_MGETTELA(009) when(.f.) picture("@E 99.99") COLOR CLR_BLACK PIXEL OF _oDlgVlr
	
	@ u_MGETTELA(028),u_MGETTELA(008) Say "Novo desconto: {%}" Size u_MGETTELA(066),u_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlgVlr
	@ u_MGETTELA(028),u_MGETTELA(050) MsGet oEdit2 Var nEdit2            Size u_MGETTELA(35) ,u_MGETTELA(009) picture("@E 99.99999") COLOR CLR_BLACK PIXEL OF _oDlgVlr
	
	//@ u_MGETTELA(028),u_MGETTELA(085) Say "Desconto: {Vlr}" Size u_MGETTELA(066),u_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlgVlr
	//@ u_MGETTELA(028),u_MGETTELA(130) MsGet oEdit4 Var nEdit4            Size u_MGETTELA(35) ,u_MGETTELA(009) picture("@E 9999.99") COLOR CLR_BLACK PIXEL OF _oDlgVlr
	
	@ u_MGETTELA(047),u_MGETTELA(131) Button "Ok" 		Size u_MGETTELA(037),u_MGETTELA(012)  ACTION( lNExec := .T. , Close(_oDlgVlr))  PIXEL OF _oDlgVlr
	//@ u_MGETTELA(047),u_MGETTELA(085) Button "Deletar" 	Size u_MGETTELA(037),u_MGETTELA(012)  ACTION( lNDele := .T. , Close(_oDlgVlr))  PIXEL OF _oDlgVlr
	
	//@ u_MGETTELA(050),u_MGETTELA(007) Say "O valor irá subistituir todas as chapas do cavalete! "  Size u_MGETTELA(113),u_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlgVlr

ACTIVATE MSDIALOG _oDlgVlr CENTERED


If lNDele
	For nX := 1 To Len(aCols)
		If AllTrim(GdFieldGet("C6_YCAVALE",nX)) == AllTrim(cNumCav)			
			 aCols[nX][Len(aHeader)+1] := .T.
		EndIf
	Next nX
EndIf

If lNExec
	
	If !Empty(nEdit1) .Or. !Empty(nEdit2)
		For nX := 1 To Len(aCols)
		
			If !Empty(nEdit1)
				If AllTrim(GdFieldGet("C6_ITEM",nX)) == AllTrim(cNumItem)			
						GdFieldPut("C6_DESCONT" ,nEdit2,nX)
						GdFieldPut("C6_VALDESC" ,Round(GdFieldGet("C6_QTDVEN",nX) * (iif(Empty(nEdit1),GdFieldGet("C6_PRCVEN",nX) ,nEdit1) * nEdit2) /100,2),nX)
						GdFieldPut("C6_PRCVEN"  ,IIF(nEdit2==0,nEdit1,GdFieldGet("C6_PRCVEN",nX) - (iif(Empty(nEdit1),GdFieldGet("C6_PRCVEN",nX) ,nEdit1) * nEdit2) /100 )  ,nX)
						GdFieldPut("C6_PRUNIT"  ,IIF(nEdit2==0,nEdit1,GdFieldGet("C6_PRCVEN",nX) - (iif(Empty(nEdit1),GdFieldGet("C6_PRCVEN",nX) ,nEdit1) * nEdit2) /100 )  ,nX) //C6_PRUNIT 23/09/2019
						GdFieldPut("C6_VALOR"   ,Round(GdFieldGet("C6_PRCVEN",nX) * GdFieldGet("C6_QTDVEN",nX),2),nX)
				EndIf
			Else
				If AllTrim(GdFieldGet("C6_ITEM",nX)) == AllTrim(cNumItem)			
						GdFieldPut("C6_DESCONT" ,nEdit2,nX)
						GdFieldPut("C6_VALDESC" ,Round(GdFieldGet("C6_QTDVEN",nX) * (iif(Empty(nEdit1),GdFieldGet("C6_PRCVEN",nX) ,nEdit1) * nEdit2) /100,2),nX)
						GdFieldPut("C6_PRCVEN"  ,IIF(nEdit2==0,nEdit1,GdFieldGet("C6_PRCVEN",nX) - (iif(Empty(nEdit1),GdFieldGet("C6_PRCVEN",nX) ,nEdit1) * nEdit2) /100 )  ,nX)
						//GdFieldPut("C6_PRUNIT"  ,IIF(nEdit2==0,nEdit1,GdFieldGet("C6_PRCVEN",nX) - (iif(Empty(nEdit1),GdFieldGet("C6_PRCVEN",nX) ,nEdit1) * nEdit2) /100 )  ,nX) //C6_PRUNIT 23/09/2019
						GdFieldPut("C6_VALOR"   ,Round(GdFieldGet("C6_PRCVEN",nX) * GdFieldGet("C6_QTDVEN",nX),2),nX)
				EndIf			
			EndIf
		Next nX
	EndIf
	
	/*
	If !Empty(nEdit1) .Or. !Empty(nEdit2) .Or. !Empty(nEdit4)
		For nX := 1 To Len(aCols)
			If Empty(nEdit4 )
				If AllTrim(GdFieldGet("C6_ITEM",nX)) == AllTrim(cNumItem)			
						GdFieldPut("C6_DESCONT" ,nEdit2,nX)
						GdFieldPut("C6_VALDESC" ,Round(GdFieldGet("C6_QTDVEN",nX) * (iif(Empty(nEdit1),GdFieldGet("C6_PRCVEN",nX) ,nEdit1) * nEdit2) /100,2),nX)
						GdFieldPut("C6_PRCVEN"  ,IIF(nEdit2==0,nEdit1,GdFieldGet("C6_PRCVEN",nX) - (iif(Empty(nEdit1),GdFieldGet("C6_PRCVEN",nX) ,nEdit1) * nEdit2) /100 )  ,nX)
						GdFieldPut("C6_PRUNIT"  ,IIF(nEdit2==0,nEdit1,GdFieldGet("C6_PRCVEN",nX) - (iif(Empty(nEdit1),GdFieldGet("C6_PRCVEN",nX) ,nEdit1) * nEdit2) /100 )  ,nX) //C6_PRUNIT 23/09/2019
						GdFieldPut("C6_VALOR"   ,Round(GdFieldGet("C6_PRCVEN",nX) * GdFieldGet("C6_QTDVEN",nX),2),nX)
				EndIf
			Else 
				If AllTrim(GdFieldGet("C6_ITEM",nX)) == AllTrim(cNumItem)			
						
						//nEdit4 := round(nEdit4 / cNumChapa,2)
						
						nEdit2 := (nEdit4*100)/GdFieldGet("C6_VALOR",nX)  
				
						GdFieldPut("C6_DESCONT" ,nEdit2,nX)
						GdFieldPut("C6_VALDESC" ,Round(GdFieldGet("C6_QTDVEN",nX) * (iif(Empty(nEdit1),GdFieldGet("C6_PRCVEN",nX) ,nEdit1) * nEdit2) /100,2),nX)
						GdFieldPut("C6_PRCVEN"  ,IIF(nEdit2==0,nEdit1,GdFieldGet("C6_PRCVEN",nX) - (iif(Empty(nEdit1),GdFieldGet("C6_PRCVEN",nX) ,nEdit1) * nEdit2) /100 )  ,nX)
						GdFieldPut("C6_VALOR"   ,Round(GdFieldGet("C6_PRCVEN",nX) * GdFieldGet("C6_QTDVEN",nX),2),nX)
				EndIf
			EndIf
		Next nX
	Else
		If !Empty(nEdit3)
			
			//For nX := 1 To Len(aCols)
			//	If AllTrim(GdFieldGet("C6_YCAVALE",nX)) == AllTrim(cNumCav)			
			//			GdFieldPut("C6_DESCONT" ,nEdit3,nX)
			//			GdFieldPut("C6_VALDESC" ,Round(GdFieldGet("C6_QTDVEN",nX) * (iif(Empty(nEdit1),GdFieldGet("C6_PRCREF",nX) ,nEdit1) * nEdit3) /100,2),nX)
			//			GdFieldPut("C6_PRCVEN"  ,GdFieldGet("C6_PRCREF",nX) - (iif(Empty(nEdit1),GdFieldGet("C6_PRCREF",nX) ,nEdit1) * nEdit2) /100   ,nX)
			//			GdFieldPut("C6_VALOR"   ,Round(GdFieldGet("C6_PRCVEN",nX) * GdFieldGet("C6_QTDVEN",nX),2),nX)
			//	EndIf
			//Next nX
			
		EndIf
	EndIf
	*/
	 
EndIf


Return 


User Function MCONSUTDET()
****************************************************************************************************************
*    
*
****
// Variaveis Locais da Funcao
Local cEdit1	 := Space(100)
Local cEdit2	 := Space(100)
Local cEdit3	 := Space(100)
Local oEdit1
Local oEdit2
Local oEdit3

// Variaveis Private da Funcao
Private _oDlg				// Dialog Principal
// Variaveis que definem a Acao do Formulario
Private VISUAL := .F.                        
Private INCLUI := .F.                        
Private ALTERA := .F.                        
Private DELETA := .F.                        
// Privates das ListBoxes
Private aListBox1 := {}
Private oListBox1
Private aFlist   := {}
/*
Inicializando Variaveis 
*/

iF TYPE("aCols") == "A"

	IF !(M-> C5_TIPO $ "D,B")   //Se for nota de devolucao
		cEdit1  := Posicione("SA1",1,XFilial("SA1")+M->C5_CLIENTE+M->C5_LOJACLI,"A1_NOME")                   // Retorna o nome do Cliente
	ELSE
		cEdit1  := POSICIONE("SA2",1,XFILIAL("SA2")+M->C5_CLIENTE+M->C5_LOJACLI,"A2_NOME")					 // Retorna o nome do Fornecedor      
	ENDIF
	cEdit2 := Posicione("SE4",1,XFilial("SE4")+M->C5_CONDPAG,"E4_DESCRI") 
	cEdit3 := Posicione("SA3",1,XFilial("SA3")+M->C5_VEND1,"A3_NOME") 
	
	DEFINE MSDIALOG _oDlg TITLE "CONSULTA DETALHADA GRPLUS" FROM u_MGETTELA(333),u_MGETTELA(275) TO u_MGETTELA(734),u_MGETTELA(795) PIXEL
	
	// Cria Componentes Padroes do Sistema
	@ u_MGETTELA(006),u_MGETTELA(005) Say "NOME DO CLIENTE:" Size u_MGETTELA(042),u_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlg
	@ u_MGETTELA(006),u_MGETTELA(052) MsGet oEdit1 Var cEdit1 when(.f.) Size u_MGETTELA(200),u_MGETTELA(009) COLOR CLR_BLACK PIXEL OF _oDlg
	@ u_MGETTELA(021),u_MGETTELA(006) Say "COND. PAGAMENTO:" Size u_MGETTELA(046),u_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlg
	@ u_MGETTELA(021),u_MGETTELA(052) MsGet oEdit2 Var cEdit2 when(.f.) Size u_MGETTELA(057),u_MGETTELA(009) COLOR CLR_BLACK PIXEL OF _oDlg
	@ u_MGETTELA(021),u_MGETTELA(114) Say "NOME VENDEDOR:" Size u_MGETTELA(055),u_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlg
	@ u_MGETTELA(021),u_MGETTELA(165) MsGet oEdit3 Var cEdit3 when(.f.) Size u_MGETTELA(087),u_MGETTELA(009) COLOR CLR_BLACK PIXEL OF _oDlg
	@ u_MGETTELA(180),u_MGETTELA(215) Button "OK"  Size u_MGETTELA(037),u_MGETTELA(012) ACTION(Close(_oDlg)) PIXEL OF _oDlg
	
	@ u_MGETTELA(035),u_MGETTELA(006) ListBox oListBox1 Fields ;
		HEADER "ITEM","CAVALETE","P.LIQUIDO","P.BRUTO","QTD CHAPAS","QTD RECORTE/AMOSTRAS";
		Size u_MGETTELA(247),u_MGETTELA(140) Of _oDlg Pixel;
		ColSizes 05,80,50,50,50,20

		oListBox1:bLDblClick := {||  MAltVlrAut(aFlist[oListBox1:nAT,01],aFlist[oListBox1:nAT,04]) }

	// Chamadas das ListBox do Sistema
	fListBox1()
	
	
	
	For nX := 1 To Len(aFlist)
		If AllTrim(aFlist[nX][1]) == AllTrim(GdFieldGet("C6_ITEM",n))
			//oListBox1:Select(nX)
			//oListBox1:bLine := { || aFlist[ oListBox1:nX ] }
			oListBox1:nAt := Nx
		EndIf
	Next Nx
	
	
	
	ACTIVATE MSDIALOG _oDlg CENTERED 

Else

	//Alert("ok")
	SetKey(VK_F5,)
	SetKey(VK_F6,)
EndIf

Return(.T.)


Static Function fListBox1()
****************************************************************************************************************
*    
*
****
Local nPos     := 0
Local nTotBr   := 0
Local nTotLQ   := 0
Local nTotCh   := 0
Local nTotDF   := 0
Local nTotAM   := 0
Local cGPExec  := GetMv("MV_XGPEXE")


oListBox1:SetArray(aFlist)

/*
Preenche o dados de peso bruto e peso liquido por cavaletes
 e quantidade de chapas
*/
For nX := 1 To Len(aCols)

	//EXECUTAR SOMENTE PARA ESTES GRUPOS 
	//"0005/0006/0034/0035/0036"
	dbSelectArea("SB1")
	dbSetOrder(1)
	dbSeek(xFilial("SB1")+ AllTrim(GdFieldGet("C6_PRODUTO",nX)) )
	
	IF AllTrim(SB1->B1_GRUPO) $ cGPExec
		If !GDDeleted(nX) 
			/*
			If !aScan(aFlist,{|x|alltrim(x[1]) == GdFieldGet("C6_YCAVALE",nX)  })		
				Aadd(aFlist,{GdFieldGet("C6_YCAVALE",nX) ,;
							 IIF(AllTrim(GdFieldGet("C6_YCAVALE",nX))=="",GdFieldGet("C6_XPESO",nX) ,fPqLotSub(GdFieldGet("C6_LOTECTL",nX),GdFieldGet("C6_NUMLOTE",nX),"B8_YPESOLQ"))    ,;
							 IIF(AllTrim(GdFieldGet("C6_YCAVALE",nX))=="",GdFieldGet("C6_XPESO",nX) ,fPqLotSub(GdFieldGet("C6_LOTECTL",nX),GdFieldGet("C6_NUMLOTE",nX),"B8_YPESOBR"))  ,;
							 IIF(AllTrim(GdFieldGet("C6_YCAVALE",nX))=="",0, fPqLotSub(GdFieldGet("C6_LOTECTL",nX),GdFieldGet("C6_NUMLOTE",nX),"B8_YQTDBD") ),;
							 IIF(AllTrim(GdFieldGet("C6_YCAVALE",nX))=="",GdFieldGet("C6_QTDVEN",nX),0 )  })
			Else
				nPos := aScan(aFlist,{|x|alltrim(x[1])==GdFieldGet("C6_YCAVALE",nX) })
			 	aFlist[nPos][2] := aFlist[nPos][2] + IIF(AllTrim(GdFieldGet("C6_YCAVALE",nX))=="",0,fPqLotSub(GdFieldGet("C6_LOTECTL",nX),GdFieldGet("C6_NUMLOTE",nX),"B8_YPESOLQ"))
			 	aFlist[nPos][3] := aFlist[nPos][3] + IIF(AllTrim(GdFieldGet("C6_YCAVALE",nX))=="",GdFieldGet("C6_XPESO",nX),fPqLotSub(GdFieldGet("C6_LOTECTL",nX),GdFieldGet("C6_NUMLOTE",nX),"B8_YPESOBR"))
			 	aFlist[nPos][4] := aFlist[nPos][4] + IIF(AllTrim(GdFieldGet("C6_YCAVALE",nX))=="",0, fPqLotSub(GdFieldGet("C6_LOTECTL",nX),GdFieldGet("C6_NUMLOTE",nX),"B8_YQTDBD") )
			 	aFlist[nPos][5] := aFlist[nPos][5] + IIF(AllTrim(GdFieldGet("C6_YCAVALE",nX))=="",GdFieldGet("C6_QTDVEN",nX), IIF(AllTrim(GdFieldGet("C6_YCLASSI",nX))=="A" .AND. Empty(AllTrim(GdFieldGet("C6_YCAVALE",nX))),1,0 )) //
			EndIf
			*/
			
			Aadd(aFlist,{GdFieldGet("C6_ITEM",nX) ,;
						 GdFieldGet("C6_YCAVALE",nX) ,; 
						 IIF(AllTrim(GdFieldGet("C6_YCAVALE",nX))=="",GdFieldGet("C6_XPESO",nX) ,fPqLotSub(GdFieldGet("C6_LOTECTL",nX),GdFieldGet("C6_NUMLOTE",nX),GdFieldGet("C6_PRODUTO",nX),GdFieldGet("C6_LOCAL",nX),"B8_YPESOLQ"))    ,;
						 IIF(AllTrim(GdFieldGet("C6_YCAVALE",nX))=="",GdFieldGet("C6_XPESO",nX) ,fPqLotSub(GdFieldGet("C6_LOTECTL",nX),GdFieldGet("C6_NUMLOTE",nX),GdFieldGet("C6_PRODUTO",nX),GdFieldGet("C6_LOCAL",nX),"B8_YPESOBR"))  ,;
						 IIF(AllTrim(GdFieldGet("C6_YCAVALE",nX))=="",0, fPqLotSub(GdFieldGet("C6_LOTECTL",nX),GdFieldGet("C6_NUMLOTE",nX),GdFieldGet("C6_PRODUTO",nX),GdFieldGet("C6_LOCAL",nX),"B8_YQTDBD") ),;
						 IIF(AllTrim(GdFieldGet("C6_YCAVALE",nX))=="",GdFieldGet("C6_QTDVEN",nX),0 )  })
			
		EndIf
	Else 
	
	//IIF(AllTrim(GdFieldGet("C6_YCLASSI",nX))=="A" .AND. Empyt(AllTrim(GdFieldGet("C6_YCAVALE",nX))),1,0)
	
	Aadd(aFlist,{     "-",;
					  "-",;
				 	   0 ,;
				       0 ,;
				       0 ,;
				       0  })
	
	EndIf
Next Nx

If Len(aFlist)>0
	For nX := 1 To Len(aFlist)
		If Alltrim(aFlist[nX][2]) = ""
			aFlist[nX][2] := "RECORTES" 
		EndIf
	Next Nx
	
	For nX := 1 To Len(aFlist)
		nTotLQ := nTotLQ + aFlist[nX][3]
		nTotBr := nTotBr + aFlist[nX][4]
		nTotCh := nTotCh + aFlist[nX][5]
		nTotAM := nTotAM + aFlist[nX][6]
	Next Nx
	
	Aadd(aFlist,{"---------","--------------------------------------------","----------------------------------","----------------------------------","----------------------------------","------------------------------------------"})
	Aadd(aFlist,{"(=)","  Total:",nTotLQ,nTotBr,nTotCh,nTotAM})
	Aadd(aFlist,{"(=)","  Weigth Limit: "+ AllTrim(Str(M->C5_XWLIMIT)),M->C5_XWLIMIT - nTotLQ  ,M->C5_XWLIMIT - nTotBr,"",""})
EndIf

oListBox1:bLine := {|| {;
					aFlist[oListBox1:nAT,01],;
					aFlist[oListBox1:nAT,02],;
					aFlist[oListBox1:nAT,03],;
					aFlist[oListBox1:nAT,04],;
					aFlist[oListBox1:nAT,05],;
					aFlist[oListBox1:nAT,06]}}
	
Return        
           

Static Function fPqLotSub(cLote,cSubLote,cCodProd,cCodLocal,cTipRet)
****************************************************************************************************************
*    //fPqCvlt(GdFieldGet("C6_YCAVALE",nX)) -- quantiade de cavaletes amostras
*    //
****
Local nVlrRest := 0

cQuery  := " SELECT "+ cTipRet +" VLRET"
cQuery  += "   FROM SB8010 
cQuery  += "  WHERE D_E_L_E_T_ = ''
cQuery  += "    AND B8_LOTECTL = '"+ AllTrim(cLote)     +"' 
cQuery  += "    AND B8_NUMLOTE = '"+ AllTrim(cSubLote)  +"'
cQuery  += "    AND B8_PRODUTO = '"+ AllTrim(cCodProd)  +"'
cQuery  += "    AND B8_LOCAL   = '"+ AllTrim(cCodLocal) +"'
cQuery  += "    AND B8_SALDO <> 0

tcQuery cQuery alias TRB new
dbSelectArea("TRB")
dbgotop()

nVlrRest := TRB->VLRET

dbSelectArea("TRB") 
dbCloseArea()

Return nVlrRest


Static Function fPqCvlt(cCavalete)
****************************************************************************************************************
*    //fPqLotSub(GdFieldGet("C6_LOTECTL",nX),GdFieldGet("C6_NUMLOTE",nX),"B8_YPESOBR")
*    
****
Local nVlrRest := 0

cQuery  := " SELECT COUNT(*) AS VLR_CONT
cQuery  += "    FROM SB8010 
cQuery  += "   WHERE D_E_L_E_T_ = ''
cQuery  += "     AND B8_YCAVALE = '"+AllTrim(cCavalete)+"'
cQuery  += "     AND B8_YCLASSI = 'A'
cQuery  += "     AND B8_SALDO <> 0

tcQuery cQuery alias TRB new
dbSelectArea("TRB")
dbgotop()

nVlrRest := TRB->VLR_CONT

dbSelectArea("TRB") 
dbCloseArea()

Return nVlrRest


User Function MINFORFIN(dSetDate,cSetCodPG)
****************************************************************************************************************
*    //Informações Financeiras 
*    
****
Private _oInforFin				// Dialog Principal
                       
Private oPG    := LoadBitmap(GetResources(), "BR_VERMELHO")
Private oNPG   := LoadBitmap(GetResources(), "BR_VERDE")
Private oNADA  := LoadBitmap(GetResources(), "BR_CINZA")

// Privates das ListBoxes
Private aListBoxFin := {}
Private oListBoxFin

DEFINE MSDIALOG _oInforFin TITLE "Informações Financeiras" FROM u_MGETTELA(178),u_MGETTELA(181) TO u_MGETTELA(403),u_MGETTELA(967) PIXEL

	// Cria Componentes Padroes do Sistema
	@ u_MGETTELA(093),u_MGETTELA(308) Button "Cancelar" Size u_MGETTELA(037),u_MGETTELA(012) ACTION(Close(_oInforFin)) PIXEL OF _oInforFin
	@ u_MGETTELA(093),u_MGETTELA(351) Button "Salvar" Size u_MGETTELA(037),u_MGETTELA(012)   ACTION(fSaveDtBl(),Close(_oInforFin)) PIXEL OF _oInforFin

		@ u_MGETTELA(003),u_MGETTELA(005) ListBox oListBoxFin Fields ;
		HEADER "","RECNO","PREFIXO","NUMERO","TIPO","PARCELA","VALOR","EMISSAO NF","VENCIMENTO","DATA BAIXA","VENCIMENTO B/L","VENCIMENTO B/L REAL" ;
		Size u_MGETTELA(383),u_MGETTELA(088) Of _oInforFin Pixel;
		ColSizes 08,20,40,40,40,40,40,40,40,40,50,40
		
		//oListBoxFin:bLDblClick := {||  MAltVlrAut(aFlist[oListBoxFin:nAT,01]) } alterar a função
		

	// Chamadas das ListBox do Sistema
	fListFin1(dSetDate,cSetCodPG)

ACTIVATE MSDIALOG _oInforFin CENTERED 

Return(.T.)


Static Function fSaveDtBl()
****************************************************************************************************************
* //
* //
* 
****
Local lGravou  := .F.
Local cCodTitu := ""

For nX:=1 to Len(aListBoxFin)
	If !Empty(aListBoxFin[nX][12])
		
		dbSelectArea("SE1")
		dbGoto(aListBoxFin[nX][2]) 
		SE1->(reclock("SE1", .F.))
			SE1->E1_VENCTO  := aListBoxFin[nX][11] 
			SE1->E1_VENCREA := aListBoxFin[nX][12]
		SE1->(msUnLock())
		
		lGravou:=.T.
		cCodTitu := cCodTitu + aListBoxFin[nX][04]+"-"+aListBoxFin[nX][06]+ " | " + chr(13)+chr(10) 
		
	EndIf
Next nX

If lGravou
	AVISO("Títulos gravados com sucesso:", cCodTitu , { "Fechar" }, 3)
EndIF

Return()

Static Function fListFin1(dSetDate,cSetCodPG)
****************************************************************************************************************
* //
* //
* 
****
Local cQuery  := ""
Local aTPAVA  := {}
Local aRetAva := ""

dbSelectArea("SF2")
dbSetOrder(2)
IF dbSeek(xFilial("SF2") + M->C5_CLIENTE + M->C5_LOJACLI + M->C5_NOTA + M->C5_SERIE + "N")

	aTPadv := Condicao(M->C5_XVLRFIN,cSetCodPG,,SF2->F2_EMISSAO,) //FSepCond(M->C5_XVLRFIN,cSetCodPG,SF2->F2_EMISSAO)

	dbSelectArea("SE4")
	dbSetOrder(1)
	If dbSeek(xFilial("SE4")+ cSetCodPG )
		aRetAva := strtokarr (AllTrim(SE4->E4_TPAVA), ",")
	EndIf

	If Len(aRetAva) <> 0
		If Len(aRetAva) <> Len(aTPadv)
			Alert("Verifique a condição de pagamento: (" + AllTrim(cSetCodPG) + "). O campo tp. avançado está diferente das quantidade de parcelas." )
		EndIf
	EndIf

	cQuery := " 	SELECT	R_E_C_N_O_ RECNO, 
	cQuery += " 			E1_FILIAL,
	cQuery += " 			E1_PREFIXO,
	cQuery += " 			E1_TIPO,
	cQuery += " 			E1_NUM,
	cQuery += " 			E1_PARCELA,
	cQuery += " 			E1_EMISSAO,
	cQuery += " 			E1_VENCREA,
	cQuery += " 			E1_BAIXA,
	cQuery += " 			E1_VALOR
	cQuery += " 	  FROM SE1010 
	cQuery += " 	 WHERE E1_NUM     = '"+M->C5_NOTA+"'
	cQuery += " 	   AND D_E_L_E_T_ = ''
	//cQuery += " 	   AND E1_BAIXA   = ''
	cQuery += " 	   AND E1_EMISSAO = '"+dtoS(SF2->F2_EMISSAO)+"'
	cQuery += " 	   AND E1_TIPO IN ('NF')
	cQuery += " 	   AND E1_CLIENTE = '"+M->C5_CLIENTE+"'
	cQuery += " 	   AND E1_LOJA    = '"+M->C5_LOJACLI+"'
	cQuery += " 	   AND E1_SERIE   = '"+M->C5_SERIE+"' 

	TcQuery cQuery Alias TMP_FIM New
	dbSelectArea("TMP_FIM")
	
	nPosAt := 0
	cTipoAvan := ""
	
	Do While !EOF()
	
		nPosAt := nPosAt + 1
		If Len(aRetAva)<>0
			cTipoAvan := aRetAva[nPosAt] 
			
			If AllTrim(cTipoAvan) <> "A"
				aTPadv := Condicao(M->C5_XVLRFIN,cSetCodPG,,dSetDate+1,)
			EndIf
		EndIf
		
		Aadd(aListBoxFin,{	iif(!Empty(aRetAva),IIF(EMPTY(TMP_FIM->E1_BAIXA),oNPG,oPG),oNADA),;
							TMP_FIM->RECNO,;
							TMP_FIM->E1_PREFIXO,;
							TMP_FIM->E1_NUM,;
							TMP_FIM->E1_TIPO,;
							TMP_FIM->E1_PARCELA,;
							TMP_FIM->E1_VALOR,;
							StoD(TMP_FIM->E1_EMISSAO),;
							StoD(TMP_FIM->E1_VENCREA),;
							StoD(TMP_FIM->E1_BAIXA),;
							iif(!Empty(aRetAva),IIf(Empty(TMP_FIM->E1_BAIXA), aTPadv[nPosAt][1]             ,sToD("") ),sToD("")),;
							iif(!Empty(aRetAva),IIf(Empty(TMP_FIM->E1_BAIXA), DataValida(aTPadv[nPosAt][1]) ,sToD("") ),sToD(""));
							})
							
		dbSelectArea("TMP_FIM")
		dbSkip()
	EndDo
	
	dbSelectArea("TMP_FIM")
	dbCloseArea()

	if Empty(aListBoxFin)
	
		Aadd(aListBoxFin,{		oNADA,;
								"",;
								"",;
								"",;
								"",;
								"",;
								"",;
								StoD(""),;
								StoD(""),;
								StoD(""),;
								StoD(""),;
								sToD("");
								})
	
	EndIf 

	oListBoxFin:SetArray(aListBoxFin)
	
	oListBoxFin:bLine := {|| {;
					aListBoxFin[oListBoxFin:nAT,01],;
					aListBoxFin[oListBoxFin:nAT,02],;
					aListBoxFin[oListBoxFin:nAT,03],;
					aListBoxFin[oListBoxFin:nAT,04],;
					aListBoxFin[oListBoxFin:nAT,05],;
					aListBoxFin[oListBoxFin:nAT,06],;
					aListBoxFin[oListBoxFin:nAT,07],;
					aListBoxFin[oListBoxFin:nAT,08],;
					aListBoxFin[oListBoxFin:nAT,09],;
					aListBoxFin[oListBoxFin:nAT,10],;
					aListBoxFin[oListBoxFin:nAT,11],;
					aListBoxFin[oListBoxFin:nAT,12]}}
	

EndIf

Return()
