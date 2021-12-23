#include "RWMAKE.ch"
#include "Colors.ch"
#include "Font.ch"
#Include "HBUTTON.CH"
#include "Topconn.ch"
#Include "Protheus.ch"
#include "tbiconn.ch"
#include "totvs.ch"

/*
Programa ...: WFMOBGRAN.Prw
Uso ........: Importaçao de Pedidos MobGran
Data .......: 09/11/2021
Feito por ..: Bruno Lage Ferreira   (33)8402-2125
Email.......: sigawise@gmail.com
Copyright ..: @1998-2001,2014

FATURADO  - AZUL      - 3
CANCELADO - VERMELHO  - 4
IMPORTADO - LARANJA   - 5
*/

User Function WFMOBGRAN()
************************************************************************************************
*
* /* Programa Princial*/
***

Local cNRotina     := ProcName()

Private _aCabecalho := {}
Private _aItens		:= {}
Private lMsHelpAuto := .T.
Private lMsErroAuto := .F.

COnOut("*********************************************")
COnOut(" Prg [WFMOBGRAN]         (SIGAWISE)          ")
COnOut("*********************************************")

/*
Este recurso foi criado para executar a chamada na [FILIAL 01]
*/
If MTRotina(cNRotina)
	MfEnvir("1",1,"010101")
Else
	ConOut("Processo em execucao! [u_WFMOBGRAN], Adiado para o próximo minuto.")
EndIf

Return()


Static Function MTRotina(cNomeRotina)
************************************************************************************************
*
* /* Programa para verificar se a rotina esta sendo executada */
***
Local   aInfo    := GetUserInfoArray()
Local   lRet     := .T.
Local   nCNPross := 0
Local   nI       := 0

For nI := 1 to len(aInfo)
	If upper(AllTrim(cNomeRotina)) $ upper(AllTrim(aInfo[nI][11]))
		nCNPross := nCNPross + 1
	EndIf
Next nI

If nCNPross > 1
	lRet := .F.
EndIf

Return(lRet)

User Function MFQueryC()
************************************************************************************************
*
* /* Importação de Clientes */
***
Local aCli  := {}

//Local nOpcAuto  := MODEL_OPERATION_INSERT
Local lRet      := .T.
Local cQuery    := ""
Local cNumCli   := ""
Local cCodMun   := ""

Local   cDescErro   := ""
Private lMsErroAuto := .F.

ConOut("[Importaçao de Clientes] INICIO!")

cQuery := " SELECT 
cQuery += "		ZSE_FILIAL,
cQuery += "		ZSE_COD,
cQuery += "		ZSE_LOJA,
cQuery += "		ZSE_PESSOA,
cQuery += "		ZSE_CGC,
cQuery += "		ZSE_NOME,
cQuery += "		ZSE_ENDER,
cQuery += "		ZSE_TIPO,
cQuery += "		ZSE_EST,
cQuery += "		ZSE_CODMUN,
cQuery += "		ZSE_MUNIC,
cQuery += "		ZSE_BAIRRO,
cQuery += "		ZSE_PAIS,
cQuery += "		ZSE_INSCRI,
cQuery += "		ZSE_VEND1,
cQuery += "		ZSE_CDPAIS,
cQuery += "		ZSE_LAT,
cQuery += "		ZSE_LONG,
cQuery += "		ZSE_MOEDA,
cQuery += "		ZSE_STATUS,
cQuery += "		ZSE_DDD,
cQuery += "		ZSE_DDI,
cQuery += "		ZSE_TELL,
cQuery += "		ZSE_EMAIL,
cQuery += "		ZSE_CEP,
cQuery += "		ZSE_ERRO,
cQuery += "		R_E_C_N_O_ RECNO
cQuery += "	   FROM ZSE010 
cQuery += "	  WHERE D_E_L_E_T_ = ''
cQuery += "	    AND ZSE_STATUS = 'P'

TCQUERY cQuery ALIAS "TRB_CLI" NEW

dbSelectArea("TRB_CLI")
dbGoTop()
Do While !EOF()
	
	cNumCli  := U_MCONTNUM("SA1","01")

	aCli := {}

	cQuery := "select CC2_MUN FROM CC2010 WHERE D_E_L_E_T_ = '' AND CC2_CODMUN = '"+TRB_CLI->ZSE_CODMUN+"' AND CC2_EST = '"+TRB_CLI->ZSE_EST+"'"
	TCQUERY cQuery ALIAS "TRB_MUN" NEW

	dbSelectArea("TRB_MUN")
	dbGoTop()
	cCodMun := TRB_MUN->CC2_MUN
	dbSelectArea("TRB_MUN")
	dbCloseArea()

	aAdd(aCli, {"A1_FILIAL"  , xFilial("SA1")          	, Nil})
	aAdd(aCli, {"A1_COD"     , cNumCli                 	, Nil})
	aAdd(aCli, {"A1_LOJA"    , TRB_CLI->ZSE_LOJA    	, Nil})
	aAdd(aCli, {"A1_PESSOA"  , TRB_CLI->ZSE_PESSOA	    , Nil})
	aAdd(aCli, {"A1_NOME"    , TRB_CLI->ZSE_NOME        , Nil})
	aAdd(aCli, {"A1_NREDUZ"  , TRB_CLI->ZSE_NOME        , Nil})
	aAdd(aCli, {"A1_END"     , TRB_CLI->ZSE_ENDER       , Nil})
	aAdd(aCli, {"A1_TIPO"    , TRB_CLI->ZSE_TIPO        , NIL})
	aAdd(aCli, {"A1_EST"     , TRB_CLI->ZSE_EST         , Nil})
	aAdd(aCli, {"A1_COD_MUN" , TRB_CLI->ZSE_CODMUN      , Nil})
	aAdd(aCli, {"A1_MUN"     , cCodMun			        , Nil})
	aAdd(aCli, {"A1_BAIRRO"  , TRB_CLI->ZSE_BAIRRO      , Nil})
	aAdd(aCli, {"A1_CGC"     , TRB_CLI->ZSE_CGC         , Nil})
	aAdd(aCli, {"A1_INSCR"   , TRB_CLI->ZSE_INSCRI      , Nil})

	aAdd(aCli, {"A1_CODPAIS" , TRB_CLI->ZSE_CDPAIS      , Nil})
	aAdd(aCli, {"A1_PAIS"    , TRB_CLI->ZSE_PAIS        , Nil})
	
	aAdd(aCli, {"A1_VEND"    , TRB_CLI->ZSE_VEND1       , Nil})
	aAdd(aCli, {"A1_NATUREZ" , "1.1.02.01"              , Nil})

	aAdd(aCli, {"A1_XLAT"    , TRB_CLI->ZSE_LAT         , Nil})
	aAdd(aCli, {"A1_XLONG"   , TRB_CLI->ZSE_LONG        , Nil})
	aAdd(aCli, {"A1_YMOEDA"  , TRB_CLI->ZSE_MOEDA       , Nil})

	aAdd(aCli, {"A1_DDD"    , TRB_CLI->ZSE_DDD          , Nil})
	aAdd(aCli, {"A1_DDI"    , TRB_CLI->ZSE_DDI          , Nil})
	aAdd(aCli, {"A1_TELL"   , TRB_CLI->ZSE_TELL         , Nil})
	aAdd(aCli, {"A1_EMAIL"  , TRB_CLI->ZSE_EMAIL        , Nil})
	aAdd(aCli, {"A1_CEP"    , TRB_CLI->ZSE_CEP          , Nil})


	lMsErroAuto := .F.
	MsExecAuto({|x,y| MATA030(x,y)}, aCli, 3)
	
	If lMsErroAuto

		cDescErro :="**********************"+ CRLF 
		cDescErro += DtoC(dDatabase)+"-"+TIME()+CRLF
		cDescErro +="**********************"+ CRLF 
		cDescErro += Mostraerro("D:\TOTVS 12\Microsiga\protheus_data\_LOGINTMOB\", Replace(Replace(DtoC(dDatabase)+"_"+TIME(),":","_"),"/","_") + "_ErroCliente.log")

		ConOut(cDescErro)

		dbSelectArea('ZSE')
		dbGoTo(TRB_CLI->RECNO)
		RecLock( 'ZSE', .F. )	
			Replace ZSE->ZSE_STATUS  With "M"
			Replace ZSE->ZSE_ERRO    With cDescErro
		MsUnLock()   
	else
		Conout("Cliente incluído com sucesso!")

		dbSelectArea('ZSE')
		dbGoTo(TRB_CLI->RECNO)
		RecLock( 'ZSE', .F. )	
			Replace ZSE->ZSE_COD     With cNumCli 
			Replace ZSE->ZSE_STATUS  With "X"
			Replace ZSE->ZSE_ERRO    With ""
		MsUnLock()   
	EndIf
		
	dbSelectArea("TRB_CLI")
	dbSkip()
EndDo

/*
Fecha arquivo temporario de SQL cabeçalhos
*/
dbSelectArea("TRB_CLI")
dbCloseArea()

ConOut("[Importaçao de Clientes] Finalização!")

Return lRet


User Function MlibPV()
************************************************************************************************
*
*/* Liberação P.Venda*/
***
Local cQuery := ""

ConOut("[Liberação de Pedidos de Venda] Início!")

cQuery := "  SELECT	C5_FILIAL+C5_NUM CHAVE,
cQuery += "  		SC5.R_E_C_N_O_ REC_SC5,
cQuery += "  		ZSC.R_E_C_N_O_ REC_ZSC,
cQuery += "  		ZSC_TIPO TIPO,
cQuery += "  		ZSC_SITUAC SIT, 
cQuery += "  		CASE
cQuery += "              WHEN ZSC_SITUAC = 'L' AND ZSC_TIPO='1' THEN 'UPDATE SC5010 SET C5_BLQ='''+'2'+'''' + ' WHERE R_E_C_N_O_ = ' +RTRIM(LTRIM(SC5.R_E_C_N_O_))
cQuery += "  			 WHEN ZSC_SITUAC = 'L' AND ZSC_TIPO='2' THEN 'UPDATE SC5010 SET C5_BLQ='' '''       + ' WHERE R_E_C_N_O_ = ' +RTRIM(LTRIM(SC5.R_E_C_N_O_))
cQuery += "  		END UPDSC5,
cQuery += "  		CASE
cQuery += "              WHEN ZSC_SITUAC = 'L' AND ZSC_TIPO='1' THEN 'UPDATE ZSC010 SET ZSC_SITUAC='''+'X'+'''' + ' WHERE R_E_C_N_O_ = ' +RTRIM(LTRIM(ZSC.R_E_C_N_O_))
cQuery += "  		 	 WHEN ZSC_SITUAC = 'L' AND ZSC_TIPO='2' THEN 'UPDATE ZSC010 SET ZSC_SITUAC='''+'X'+'''' + ' WHERE R_E_C_N_O_ = ' +RTRIM(LTRIM(ZSC.R_E_C_N_O_))
cQuery += "  		END UPDZSC,
cQuery += " 		CASE
cQuery += " 			WHEN ZSC_SITUAC = 'L' AND ZSC_TIPO='1' AND (SELECT ZSC_DATA FROM ZSC010 WHERE	D_E_L_E_T_ = '' AND ZSC_CODIGO = '003940' AND ZSC_TIPO <> 'B' AND ZSC_TIPO = '2')<>''   THEN 'UPDATE SC5010 SET C5_BLQ='''+''+'''' + ' WHERE R_E_C_N_O_ = ' +RTRIM(LTRIM(SC5.R_E_C_N_O_))
cQuery += " 		END UPDSC5_LIBFIN
cQuery += "    FROM SC5010 SC5 INNER JOIN ZSC010 ZSC ON (C5_FILIAL+C5_NUM = ZSC_FILIAL+ZSC_CODIGO) 
cQuery += "   WHERE C5_BLQ     <> '' 
cQuery += "     AND ZSC_TIPO   <> 'B' 
cQuery += "     AND ZSC_SITUAC <> 'X'
cQuery += "     AND SC5.D_E_L_E_T_ = '' 
cQuery += "     AND ZSC.D_E_L_E_T_ = ''
cQuery += "     AND ZSC_TIPO   < 3

TCQUERY cQuery ALIAS "TRB_LPV" NEW

dbSelectArea("TRB_LPV")
dbGoTop()
Do While !EOF()

	If TRB_LPV->SIT = 'L'
		cQuery := TRB_LPV->UPDSC5
		TcSqlExec(cQuery)
		
		cQuery := TRB_LPV->UPDZSC
		TcSqlExec(cQuery)

		cQuery := TRB_LPV->UPDSC5_LIBFIN
		TcSqlExec(cQuery)
	EndIf

	dbSelectArea("TRB_LPV")
	dbSkip()
EndDo

/*
Fecha arquivo temporario de SQL cabeçalhos
*/
dbSelectArea("TRB_LPV")
dbCloseArea()

ConOut("[Liberação de Pedidos de Venda] Finalização!")

Return()


Static Function MfEnvir(cEmp01,nFil00,cFil01)
************************************************************************************************
*
*/* Programa de preparacao dos ambientes conforme paramentros  de filial*/
***
Local   lAuto 	   := .F.
Private aIdVend    := {}

COnOut("*********************************************")
COnOut(" Prg [MfEnvir]            (SIGAWISE)         ")
COnOut("*********************************************")

/*
Criaçao dos ambientes
*/
If Select("SX2") == 0
	PREPARE ENVIRONMENT EMPRESA "01" FILIAL cFil01 TABLES "SC5"
	Conout(DtoC(dDatabase)+" - "+TIME()+" Iniciando JOB de [Importaçao de Pedidos MobGran].")
	lAuto := .F.
EndIf

/*
Funcao princial de chamadas de rotinas
*/
u_MFQueryC()

/*
Funcao princial de chamadas de rotinas
*/
u_MFQueryL()

/*
Funcao princial de chamadas de rotinas
*/
u_MFQueryP( "010101" , "001" )

/*
Funcao princial de Liberação de Pedidos de Venda
*/
U_MlibPV()

/*
Controle de limpesa dos ambientes
*/
If lAuto
	RpcClearEnv()
	Conout(DtoC(dDatabase)+" - "+TIME()+" FIM do JOB [Importaçao de Pedidos MobGran] .")
Else
	RpcClearEnv()
	Alert("[Importaçao de Pedidos MobGran] efetuada com sucesso!")
Endif

/*
Garante o reinicio do ambientes
*/
RESET ENVIRONMENT

Return()


User Function MFQueryL()
************************************************************************************************
*
*	//Funcao especifica para geracao das SQL de Trabalho
*
***
Local cQuery := ""

Conout(DtoC(dDatabase)+" - "+TIME()+" JOB [Atualização do limites de créditos Qualitá] .")

cQuery := " UPDATE SA1010  
cQuery += "    SET A1_LC = ZSD_NVALOR
cQuery += "   FROM ZSD010 ZSD INNER JOIN SA1010 SA1 ON (A1_COD = ZSD_CLIENT AND A1_LOJA = ZSD_LOJA)
cQuery += "  WHERE ZSD.D_E_L_E_T_ = ''
cQuery += "    AND SA1.D_E_L_E_T_ = ''
cQuery += "    AND ZSD_STATUS     = 'P'

/*
Execucao background do código sql
*/
TcSqlExec(cQuery)

cQuery := " UPDATE ZSD010  
cQuery += "    SET ZSD_STATUS = 'X'
cQuery += "   FROM ZSD010 ZSD INNER JOIN SA1010 SA1 ON (A1_COD = ZSD_CLIENT AND A1_LOJA = ZSD_LOJA)
cQuery += "  WHERE ZSD.D_E_L_E_T_ = ''
cQuery += "    AND SA1.D_E_L_E_T_ = ''
cQuery += "    AND ZSD_STATUS     = 'P'

/*
Execucao background do código sql
*/
TcSqlExec(cQuery)

Conout(DtoC(dDatabase)+" - "+TIME()+" FIM DO JOB [Atualização do limites de créditos Qualitá] .")

Return()

User Function MFQueryP(cPara01,cPara02)
************************************************************************************************
*
*	//Funcao especifica para geracao das SQL de Trabalho
*
***
Local cQuery 	:= ""
Local nCodItem 	:= 0
Local cCodTab   := ""
Local cCodTabP  := ""

Private aTabTES 	:= {}
Private cNumPedPol  := ""

COnOut("*********************************************")
COnOut(" Prg u_MFQueryP(["+cPara01+"],["+cPara02+"])     (SIGAWISE)")
COnOut("*********************************************")

cCodTab  := ""
cCodTabP := ""

/*
MobGran_pedcab
*/
cQuery := " SELECT DISTINCT  
cQuery += " 	   '010101'															    AS C5_FILIAL ,
cQuery += "        'N'																	AS C5_TIPO   ,
cQuery += " 	   'N'																	AS C5_XSHOWFO,
cQuery += " 	   ZSA_IDMOBP															AS IDMOB     ,
cQuery += " 	   ZSA_CPAG																AS C5_CONDPAG,
cQuery += " 	   REPLACE(CONVERT(VARCHAR(10),getdate(),112),'-','') 					AS C5_EMISSAO,
cQuery += " 	   ''															        AS C5_TRANSP ,
cQuery += " 	   LEFT(ZSA_CLIENT ,6)													AS C5_CLIENTE,
cQuery += "        RIGHT(ZSA_CLIENT,2)													AS C5_LOJA   ,
cQuery += " 	   'ME' 																AS C5_YTIPO  ,
cQuery += " 	   (SELECT MIN(C5_NUM) FROM SC5010 WHERE C5_XIDMOB = ZSA_IDMOBP)		AS C5_NUM
cQuery += "   FROM ZSA010 ZSA LEFT JOIN SC5010 SC5 ON (C5_XIDMOB = ZSA_IDMOBP AND SC5.D_E_L_E_T_ = '' AND ZSA.D_E_L_E_T_ = '')
cQuery += "  WHERE (ZSA_IDPEND in ('P') )
//cQuery += "  WHERE (ZSA_IDPEND in ('P') OR SC5.C5_NUM ='003953')
cQuery += "    AND ZSA_STATUS = 'ATIVA'
cQuery += "    AND (ISNULL(CAST(CONVERT(VARBINARY(MAX), ZSA_MSGINT) AS VARCHAR(MAX)),'') = '' )
//cQuery += "    AND (ISNULL(CAST(CONVERT(VARBINARY(MAX), ZSA_MSGINT) AS VARCHAR(MAX)),'') = '' OR  SC5.C5_NUM ='003953')
cQuery += "    ORDER BY IDMOB
/*
Geraçao do arquivo de Temporario de cabecalho
*/
//MemoWrite("D:\TOTVS 12\Microsiga\protheus_data\_LOGINTMOB\CABEC_INT_MOG.TXT",cQuery)

TCQUERY cQuery ALIAS "TRB_CAB" NEW

/*
MobGran_pedcorp
*/
cQuery := " SELECT 'I'    ACAO     ,
cQuery += "	   '010101'   FILIAL   ,
cQuery += "	   '00'       ITEM     , 
cQuery += "	   ZSA_IDMOBP IDMOB    ,
cQuery += "	   ZSA_NUMCAV CAVALETE ,
cQuery += "	   ZSA_PROD            ,
cQuery += "	   ZSA_LOTE            ,
cQuery += "	   ZSA_CLASSI          , 
cQuery += "	   ZSA_PRCDES          ,
cQuery += "	   ZSA_LOCAL           ,
cQuery += "	   ZSA_QTDVEN          , 
cQuery += "	   ZSA_IDPEND          ,
cQuery += "	   ZSA_PRCUNT          ,
cQuery += "	   ROUND(((ZSA_QTDVEN*ZSA_PRCUNT)+ZSA_VALDES)/ZSA_QTDVEN,2)  AS ZSA_PRCTAB,
cQuery += "	   ZSA_DESCON          ,
cQuery += "	   ZSA_VALDES          ,
cQuery += "	   SC5.C5_NUM AS C5_NUM,
cQuery += "	   0 PESOAMOSTRA
cQuery += "   FROM ZSA010 ZSA LEFT JOIN SC5010 SC5 ON (C5_XIDMOB = ZSA_IDMOBP AND SC5.D_E_L_E_T_ = '' AND ZSA.D_E_L_E_T_ = '')
cQuery += " WHERE ZSA_IDPEND in ('P')
cQuery += "   AND ZSA_STATUS = 'ATIVA'
cQuery += "   AND ISNULL(CAST(CONVERT(VARBINARY(MAX), ZSA_MSGINT) AS VARCHAR(MAX)),'') = ''

cQuery += " UNION ALL

cQuery += "  SELECT 'I' ACAO    ,
cQuery += "		C6_FILIAL      ,
cQuery += "		C6_ITEM ITEM   ,
cQuery += "		C5_XIDMOB IDMOB,
cQuery += "		C6_YCAVALE     ,
cQuery += "		C6_PRODUTO     ,
cQuery += "		C6_LOTECTL     ,
cQuery += "		C6_YCLASSI     ,
cQuery += "		0              ,
cQuery += "		C6_LOCAL       ,
cQuery += "		C6_QTDVEN      ,
cQuery += "		'P'            ,
cQuery += "		C6_PRUNIT	   ,
cQuery += "		C6_PRCVEN      ,
cQuery += "		C6_DESCONT     ,
cQuery += "		C6_VALDESC     ,
cQuery += "		C6_NUM C5_NUM  ,
cQuery += "		C6_XPESO PESOAMOSTRA
cQuery += "  FROM SC6010 SC6 INNER JOIN SC5010 SC5 ON(C5_FILIAL = C6_FILIAL  AND C6_NUM=C5_NUM)
cQuery += " WHERE SC6.D_E_L_E_T_ = ''
cQuery += "   AND SC5.D_E_L_E_T_ = ''
cQuery += "   AND SC6.C6_PRODUTO  LIKE 'AM%' 
cQuery += "   AND C6_FILIAL + C6_NUM IN(
cQuery += "							 SELECT DISTINCT '010101'+ SC5.C5_NUM AS C5_NUM
cQuery += "							   FROM ZSA010 ZSA LEFT JOIN SC5010 SC5 ON (C5_XIDMOB = ZSA_IDMOBP AND SC5.D_E_L_E_T_ = '' AND ZSA.D_E_L_E_T_ = '')
cQuery += "							 WHERE ZSA_IDPEND in ('P')
cQuery += "							   AND ZSA_STATUS = 'ATIVA'
cQuery += "							   AND ISNULL(CAST(CONVERT(VARBINARY(MAX), ZSA_MSGINT) AS VARCHAR(MAX)),'') = ''
cQuery += "							  )

cQuery += " UNION ALL 

cQuery += " SELECT 'R' ACAO    ,
cQuery += "		C6_FILIAL      ,
cQuery += "		C6_ITEM ITEM   ,
cQuery += "		C5_XIDMOB IDMOB,
cQuery += "		C6_YCAVALE     ,
cQuery += "		C6_PRODUTO     ,
cQuery += "		C6_LOTECTL     ,
cQuery += "		C6_YCLASSI     ,
cQuery += "		0              ,
cQuery += "		C6_LOCAL       ,
cQuery += "		C6_QTDVEN      ,
cQuery += "		'P'            ,
cQuery += "		C6_PRUNIT	   ,
cQuery += "		C6_PRCVEN      ,
cQuery += "		C6_DESCONT     ,
cQuery += "		C6_VALDESC     ,
cQuery += "		C6_NUM C5_NUM  ,
cQuery += "		C6_XPESO PESOAMOSTRA
cQuery += "  FROM SC6010 SC6 INNER JOIN SC5010 SC5 ON(C5_FILIAL = C6_FILIAL  AND C6_NUM=C5_NUM)
cQuery += " WHERE SC6.D_E_L_E_T_ = ''
cQuery += "   AND SC5.D_E_L_E_T_ = ''
cQuery += "   AND C6_FILIAL + C6_NUM IN(
cQuery += "							 SELECT DISTINCT '010101'+ SC5.C5_NUM AS C5_NUM
cQuery += "							   FROM ZSA010 ZSA LEFT JOIN SC5010 SC5 ON (C5_XIDMOB = ZSA_IDMOBP AND SC5.D_E_L_E_T_ = '' AND ZSA.D_E_L_E_T_ = '')
cQuery += "							 WHERE ZSA_IDPEND in ('P')
cQuery += "							   AND ZSA_STATUS = 'ATIVA'
cQuery += "							   AND ISNULL(CAST(CONVERT(VARBINARY(MAX), ZSA_MSGINT) AS VARCHAR(MAX)),'') = ''
cQuery += "							  )
cQuery += " ORDER BY IDMOB,C5_NUM, ACAO DESC,ITEM

/*
Geraçao do arquivo temporario de Itens
*/
//MemoWrite("D:\TOTVS 12\Microsiga\protheus_data\_LOGINTMOB\ITENS_INT_MOG.TXT",cQuery)
TCQUERY cQuery ALIAS "TRB_ITEM" NEW

/*
Limpa os vendedores adicionados anteriomente
*/
aIdVend := {}

dbSelectArea("TRB_CAB")
dbGoTop()
Do While !EOF()
	/*
	Posiciona nos cadastro
	*/
	dbSelectArea("SA1")
	dbsetorder(1)
	dbseek(xfilial("SA1")+TRB_CAB->C5_CLIENTE+TRB_CAB->C5_LOJA,.f.)
	
	/*
	Limpa todos os valores antigos
	*/
	_aCabecalho := {}
	
	/*
	Preenchimento dos Array do cabeçalho
	*/
	aAdd(_aCabecalho,AllTrim(TRB_CAB->C5_FILIAL)	)  // C5_FILIAL   1
	aAdd(_aCabecalho,"N" 							)  // C5_TIPO     2
	aAdd(_aCabecalho,AllTrim(TRB_CAB->C5_CLIENTE) 	)  // C5_CLIENTE  3
	aAdd(_aCabecalho,AllTrim(TRB_CAB->C5_LOJA  ) 	)  // C5_LOJACLI  4
	aAdd(_aCabecalho,AllTrim(TRB_CAB->IDMOB) 		)  // C5_IDMOB    5
	aAdd(_aCabecalho,AllTrim(TRB_CAB->C5_CONDPAG)	)  // C5_CONDPAG  6
	aAdd(_aCabecalho,STOD(AllTrim(TRB_CAB->C5_EMISSAO)))  // C5_EMISSAO  7
	aAdd(_aCabecalho,TRB_CAB->C5_XSHOWFO       	    )     // C5_XSHOWFO  8
	aAdd(_aCabecalho,"ME"				       	    )     // C5_YTIPO    9
	aAdd(_aCabecalho,TRB_CAB->C5_NUM				)     // C5_COTACAO  10
	
	/*
	Na inclusao dos itens a cada loop ele zera o valor inicial
	*/
	nCodItem := 0
	_aItens	 := {}
	
	dbSelectArea("TRB_ITEM")
	dbGoTop()
	Do While !EOF()
		
		If AllTrim(TRB_CAB->IDMOB)  == AllTrim(TRB_ITEM->IDMOB)
			
			/*
			Posiciona no cadastro
			*/
			dbSelectArea("SB1")
			dbsetorder(1)
			dbseek(xfilial("SB1")+AllTrim(TRB_ITEM->ZSA_PROD) ,.f.)
			
			/*
			Posiciona no cadastro
			*/
			dbSelectArea("SF4")
			dbsetorder(1)
			dbseek(xfilial("SF4")+AllTrim(SB1->B1_TS) ,.f.)
			
			/*
			Soma dos itens
			*/
			IF TRB_ITEM->ACAO = "I"
				nCodItem := nCodItem + 1
			EndIf
			/*
			Variais para geracao das linhas de itens do
			Pedido
			*/
			cC01 := AllTrim(TRB_ITEM->FILIAL)       		// FILIAL
			cC02 := iif(TRB_ITEM->ACAO = "I", AllTrim(Str(nCodItem) ),TRB_ITEM->ITEM) 				// C6_ITEM
			cC03 := AllTrim(TRB_ITEM->ZSA_PROD)  	    	// C6_PRODUTO
			cC04 := IIF(TRB_ITEM->ZSA_PRCDES=0,'N','S')  	// C6_XOFERTA
			cC05 := AllTrim(TRB_ITEM->CAVALETE)				// C6_YCAVALE
			cC06 := AllTrim(TRB_ITEM->ZSA_CLASSI)		  	// C6_YCLASSI
			cC07 := SB1->B1_UM  							// C6_UM
			cC08 := AllTrim(TRB_ITEM->ZSA_LOTE)			    // C6_LOTECTL
			cC09 := AllTrim(TRB_ITEM->CAVALETE)			    // C6_NUMLOTE
			cC10 := AllTrim(TRB_ITEM->ZSA_LOCAL)	        // C6_LOCAL
			cC11 := TRB_ITEM->ZSA_QTDVEN  					// C6_QTDVEN
						
			cC12 := IIF(TRB_ITEM->ZSA_PRCDES=0,TRB_ITEM->ZSA_PRCUNT,TRB_ITEM->ZSA_PRCDES)  					// C6_PRCVEN PRC VENDA
			cC13 := TRB_ITEM->ZSA_PRCTAB    				// C6_PRUNIT PRC TABELA

			If AllTrim(TRB_ITEM->ZSA_CLASSI) $ 'A' .OR. SubStr(AllTrim(TRB_ITEM->ZSA_PROD) ,1,2) == 'AM'
				cC14 :=  "525"  							// C6_TES
			else
				If _aCabecalho[9]=="ME"
					cC14 :=  "511"		 						// C6_TES
				else
					cC14 :=  "511"		 						// C6_TES
				EndIf
		    EndIf

			cC15 := SB1->B1_ORIGEM + SF4->F4_SITTRIB  		// C6_SITTRIB
			cC16 := dDataBase  								// C6_ENTREG
			cC17 := TRB_ITEM->ACAO							// AÇÃO 

			cC18 := TRB_ITEM->ZSA_DESCON
			cC19 := TRB_ITEM->ZSA_VALDES
			cC20 := TRB_ITEM->PESOAMOSTRA

			//cC13 := TRB_ITEM->C6_DESCONT  				// C6_DESCONT
			
			/*
			Criaçao da Linha de itens dos Pedidos
			*/
			aAdd( _aItens , {cC01,cC02,cC03,cC04,cC05,cC06,cC07,cC08,cC09,cC10,cC11,cC12,cC13,cC14,cC15,cC16,cC17,cC18,cC19,cC20} )
			
		EndIf
		
		dbSelectArea("TRB_ITEM")
		dbSkip()
	EndDo
	
	/*
	Caso hava registros no cabeçalho
	entao a rotina de Inclusao de pedidos
	e chamada.
	*/
	If !Empty(_aCabecalho) .And. !Empty(_aItens)
		
		
		COnOut("*********************************************")
		COnOut(" Prg [Inserindo Pedidos]   (SIGAWISE)        ")
		COnOut("*********************************************")
		
		MfPedI( _aCabecalho, _aItens)
		
		/*
		If Ascan(aIdVend,AllTrim(TRB_CAB->C5_VEND1)) == 0
			COnOut("*********************************************")
			COnOut(" Prg [addVendArry]        (SIGAWISE)         ")
			COnOut("*********************************************")
			
			aAdd(aIdVend,AllTrim(TRB_CAB->C5_VEND1))
		EndIf
		*/
		
	EndIf
	
	dbSelectArea("TRB_CAB")
	dbSkip()
EndDo

/*
Envio do protocolo
*/
COnOut("*********************************************")
COnOut(" chamada [SendProtocol]  OFF  (SIGAWISE)     ")
COnOut("*********************************************")
//SendProtocol(aIdVend)

/*
Fecha arquivo temporario de SQL cabeçalhos
*/
dbSelectArea("TRB_CAB")
dbCloseArea()

/*
Fecha arquivos temporario de SQL de Itens
*/
dbSelectArea("TRB_ITEM")
dbCloseArea()

Return()

Static Function MfPedI( _aCabecalho , _aItens )
************************************************************************************************
*
*
***
Local aAreasPed     := GetArea()
Local _aAutoSC5 	:= {}
Local _aAutoSC6 	:= {}
Local _aLinha		:= {}
Local _aErroSC6     := {}
Local i 			:= 0

Local _aRetorno		:= {}
Local cCodTab   	:= ""
Local cCodTabP  	:= ""
Local cDescErro     := ""

cPedido  := ""
cCodTab  := ""
cCodTabP := ""

Private _cTabela := "SC5"

COnOut("*********************************************")
COnOut(" Prg [MfPedI]             (SIGAWISE)         ")
COnOut("*********************************************")

lMsErroAuto := .f.

If !Empty(_aCabecalho)
	
	If Empty(_aCabecalho[10]) 
		/*
		Recebe o proximo numero de pedidos do Protheus
		*/
		cPedido  := GetSxeNum(_cTabela,"C5_NUM")
		
		RollBackSxE()
	else	
		cPedido  := _aCabecalho[10]

		dbSelectArea("SC5")
		dbSetOrder(1)
		If !dbSeek("010101" + cPedido  )
			ConOut("Pedido de Venda não econtrado!")
		EndIf
	EndIf

	/*
	Posiciona no cadastro
	*/
	dbSelectArea("SA1")
	dbSetOrder(1)
	If !dbSeek(xFilial("SA1") + _aCabecalho[3] + _aCabecalho[4] )
		ConOut("Cliente não econtrado!")
	EndIf
	
	/*
	Posiciona no cadastro
	*/
	dbSelectArea("SA3")
	dbSetOrder(1)
	If !dbSeek(xFilial("SA3") + SA1->A1_VEND )
		ConOut("Vendedor não econtrado!")
	EndIf
	
	/*
	Criaçao do Array especifio da inclusao do pedido de venda
	Rotina de Cabeçalho
	*/
	_aAutoSC5:={{"C5_NUM"    ,cPedido           								,Nil},; // Numero do pedido
				{"C5_TIPO"   ,"N"         	    								,Nil},; // Tipo de pedido
				{"C5_XIDMOB" ,_aCabecalho[5]    								,Nil},; // Hora de inclusao
				{"C5_CLIENTE",_aCabecalho[3]       								,Nil},; // Codigo do cliente
				{"C5_LOJAENT",_aCabecalho[4]      								,Nil},; // Loja para entrada
				{"C5_LOJACLI",_aCabecalho[4]      								,Nil},; // Loja do cliente
				{"C5_EMISSAO",_aCabecalho[7]   	        						,Nil},; // Data de emissao
				{"C5_DTINC"  ,_aCabecalho[7] 	  	    						,Nil},; // Data de emissao
				{"C5_CONDPAG",_aCabecalho[6]       								,Nil},; // Codigo da condicao de pagamento
				{"C5_YTIPO"  ,_aCabecalho[9]             					   	,Nil},; // Percentual de Desconto
				{"C5_TIPOCLI",SA1->A1_TIPO	    			 				   	,Nil},; // Tipo Cliente
				{"C5_VEND1"  ,SA1->A1_VEND          						   	,Nil},; // Vendedor
				{"C5_XSHOWFO", IIF(Empty(_aCabecalho[10]),"N",SC5->C5_XSHOWFO) 	,Nil},; // FollowUp   
				{"C5_COTACAO",cPedido 											,Nil}}  // C5_NUM OU C5_COTACAO
		
	/*
	Erro dos itens do pedidos
	*/
	_aErroSC6 := {}

	/*
	Loop dos Itens do cadastro de produtos da Polibras
	*/
	For i := 1 to Len(_aItens)
		_aLinha := {}
		
		/*
		Posiciona no cadastro
		*/
		dbSelectArea("SB1")
		dbSetOrder(1)
		If !dbSeek(xFilial("SB1") + _aItens[i,3],.f. )
			
			aAdd(_aErroSC6 , {cPedido, StrZero(i,4), _aItens[i,3],"Produto nao econtrado" } )
			
		ElseIf SB1->B1_MSBLQL <> '1'
			
			/*
			Criaçao do Array especifio da inclusao do pedido de venda
			Rotina de Itens
			*/
			aadd(_aLinha,{"C6_NUM"    ,cPedido                     			      	  ,Nil}) // Numero do Pedido

			if _aItens[i,17] == "I"
				aadd(_aLinha,{"C6_ITEM"   ,Iif(i < 100, StrZero(i,2),AllTrim(Str(i))) ,Nil}) // Numero do Item no Pedido
			else
				aadd(_aLinha,{"LINPOS",     "C6_ITEM",     _aItens[i,02]})
      			aadd(_aLinha,{"AUTDELETA",  "S",           Nil})
			EndIf

			aadd(_aLinha,{"C6_PRODUTO",_aItens[i,3]                					,Nil}) // Codigo do Produto
			aadd(_aLinha,{"C6_DESCRI" ,AllTrim(SB1->B1_DESC)       					,Nil}) // Descricao produto
			aadd(_aLinha,{"C6_LOCAL"  ,_aItens[i,10]              					,Nil}) // Armazem
			
			aadd(_aLinha,{"C6_YCAVALE",_aItens[i,5]                					,Nil}) // cavalete
			aadd(_aLinha,{"C6_YCLASSI",_aItens[i,6]                					,Nil}) // Cassificação
			aadd(_aLinha,{"C6_LOTECTL",_aItens[i,8]                					,Nil}) // Lote 
			aadd(_aLinha,{"C6_NUMLOTE",_aItens[i,9]                					,Nil}) // Lote 
			
			aadd(_aLinha,{"C6_QTDVEN" ,_aItens[i,11]               					,Nil}) // Quantidade Vendida
	
			aadd(_aLinha,{"C6_PRCVEN" ,_aItens[i,12]               					,Nil}) // Preco Unitario Liquido CONFERIDO
			aadd(_aLinha,{"C6_PRUNIT" ,_aItens[i,13] 	             				,Nil}) // Preco de Lista         CONFERIDO
			aadd(_aLinha,{"C6_VALOR"  ,Round(_aItens[i,11] * _aItens[i,12],2)  		,Nil}) // Preco Total
			aadd(_aLinha,{"C6_VALDESC",_aItens[i,19]              			   		,Nil}) // valor do desconto

			aadd(_aLinha,{"C6_ENTREG" ,dDatabase          							,Nil}) // Data da Entrega
			aadd(_aLinha,{"C6_UM"     ,_aItens[i,7]                 				,Nil}) // Unidade de Medida Primar.
			aadd(_aLinha,{"C6_TES"    ,_aItens[i,14]                 				,Nil}) // Tipo de Entrada/Saida do Item
			
			aadd(_aLinha,{"C6_CLI"    ,_aCabecalho[3]               				,Nil}) // Cliente
			aadd(_aLinha,{"C6_LOJA"   ,_aCabecalho[4]              					,Nil}) // Loja do Cliente
			
			aadd(_aLinha,{"C6_XOFERTA",_aItens[i,4]                					,Nil}) // Oferta
			aadd(_aLinha,{"C6_XPESO"  ,_aItens[i,20]                				,Nil}) // Peso da Amostra
			
			/*
			Clone da Linha de Produtos
			*/
			AAdd( _aAutoSC6, AClone( _aLinha ) )
			
		Else
			aAdd(_aErroSC6 , {cPedido, StrZero(i,4), _aItens[i,3],"Produto Bloqueado" } )
		EndIf
		
	Next
	
	/*
	Inicializacao da variavel de Erro
	*/
	lMsErroAuto := .F.
	
	/*
	Execauto para geracao dos pedidos com validacações
	*/
	dbSelectArea("SC5")
	dbSetOrder(1)
	If !dbSeek("010101" + cPedido  )
		MSExecAuto({|x,y,Z| Mata410(x,y,Z)},_aAutoSC5,_aAutoSC6,3) //INCLUSÃO
	Else
		MSExecAuto({|x,y,Z| Mata410(x,y,Z)},_aAutoSC5,_aAutoSC6,4) //ALTERAÇÃO
	EndIf

	/*
	Variavel complementar de apoio de erros
	*/
	cDescErro     := ""
	
	If lMsErroAuto
		cDescErro :="**********************"+ CRLF 
		cDescErro += DtoC(dDatabase)+"-"+TIME()+CRLF
		cDescErro +="**********************"+ CRLF 
		cDescErro += Mostraerro("D:\TOTVS 12\Microsiga\protheus_data\_LOGINTMOB\", Replace(Replace(DtoC(dDatabase)+"_"+TIME(),":","_"),"/","_") + "_ErroPedido.log")

		ConOut(cDescErro)
		Sleep(10000)
		cQuery := " UPDATE "+RetSqlName("ZSA")
		cQuery += "    SET ZSA_IDPEND = 'M',ZSA_MSGINT= CONVERT(VARBINARY(MAX), '"+UPPER(cDescErro)+"') 
		cQuery += "   FROM ZSA010 ZSA LEFT JOIN SC5010 SC5 ON (C5_XIDMOB = ZSA_IDMOBP AND SC5.D_E_L_E_T_ = '' AND ZSA.D_E_L_E_T_ = '')
		cQuery += "  WHERE ZSA_IDMOBP = '"+ AllTrim(_aCabecalho[5]) +"'
		//cQeery += "    AND ISNULL(CAST(ZSA_MSGINT AS VARCHAR(MAX)), '') = ''

		/*
		Execucao background do codigo sql
		*/
		TcSqlExec(cQuery)

		DisarmTransaction()
		RollBackSxE()
	Else

		cQuery := " UPDATE "+RetSqlName("ZSA")
		cQuery += "    SET ZSA_IDPEND = 'M',ZSA_PEDVEN='"+AllTrim(cPedido) +"'
		cQuery += "   FROM ZSA010 ZSA LEFT JOIN SC5010 SC5 ON (C5_XIDMOB = ZSA_IDMOBP AND SC5.D_E_L_E_T_ = '' AND ZSA.D_E_L_E_T_ = '')
		cQuery += "  WHERE ZSA_IDMOBP = '"+ AllTrim(_aCabecalho[5]) +"'
		//cQuery += "    AND ZSA_PEDVEN <> '003953'
		
		/*
		Execucao background do codigo sql
		*/
		TcSqlExec(cQuery)


		/*
		Confirmacao do pedido
		*/
		ConfirmSX8()

        SC6->(DbSetOrder(1))
		If SC6->(DbSeek(xFilial("SC5")+SC5->C5_NUM))

			Do While !SC6->(Eof()) .And. SC5->(C5_FILIAL+C5_NUM) == SC6->(C6_FILIAL+C6_NUM)
				
			
				
				SC6->(DbSkip())
			EndDo
			
		EndIf
		
	EndIf
	

	/*
	Verica se o Pedido foi Inserido
	*/
	dbSelectArea(_cTabela)
	dbSetOrder(1)
	If Empty(cDescErro) .AND. dbSeek(xFilial(_cTabela)+cPedido)
		//u_MIntMGLib(cPedido,SC5->C5_XIDMOB,"SC5", SC5->C5_XMOTBLQ)		
	Else

	EndIf
	
Else

EndIf

//_aRetorno := {cPedido,_cErro}
RestArea(aAreasPed)

Return(_aRetorno)
