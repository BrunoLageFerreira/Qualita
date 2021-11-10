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
Local cAssunto     := "[Importaçao de Pedido MobGran]"
Local cCodProcesso := "WFMOBGRAN"
Local cNRotina     := ProcName()

Private _aCabecalho := {}
Private _aItens		:= {}
Private lMsHelpAuto := .T.
Private lMsErroAuto := .F.


COnOut("*********************************************")
COnOut(" Prg [WFMOBGRAN]         (SIGAWISE)            ")
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

For nI := 1 to len(aInfo)
	If upper(AllTrim(cNomeRotina)) $ upper(AllTrim(aInfo[nI][11]))
		nCNPross := nCNPross + 1
	EndIf
Next nI

If nCNPross > 1
	lRet := .F.
EndIf

Return(lRet)

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
u_MFQueryP( "010101" , "001" )

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
Local cPerg     := "MFQueryP"
Local aPerg     := {}
Local lExecManu := .F.


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
cQuery := " SELECT  	tipo_venda															AS C5_TIPO		,
cQuery += " 			LEFT(codigo_cliente,6)												AS C5_CLIENTE	,
cQuery += " 			RIGHT(codigo_cliente,2) 											AS C5_LOJACLI	,
cQuery += " 			LEFT(codigo_cliente,6)												AS C5_CLIENT	,
cQuery += " 			RIGHT(codigo_cliente,2) 											AS C5_LOJAENT	,

cQuery += " 			REPLACE(CONVERT(VARCHAR(10),getdate(),112),'-','') 					AS C5_EMISSAO	,

cQuery += " 			codigo_planopagamento					   							AS C5_CONDPAG	,
cQuery += "   			'000001'															AS C5_TRANSP	,
cQuery += " 			codigo_vendedor														AS C5_VEND1		,
cQuery += " 			0																	AS C5_DESC1		,
cQuery += " 			0																	AS C5_DESC2		,
cQuery += " 			0																	AS C5_DESC3		,
cQuery += " 			0																	AS C5_DESC4		,
cQuery += " 			codigo_tabela														AS C5_TABELA	,
cQuery += " 			codigo_pedido														AS C5_COTACAO	,
cQuery += " 			''																	AS C5_TPFRETE	,
cQuery += " 			upper(observacao)													AS C5_MENNOTA	,
cQuery += " 			desconto_petalao												   	AS C5_DESCONT   ,
cQuery += " 			codigo_pedido														AS C5_NUM   	,
cQuery += " 			CONVERT(VARCHAR(5),CONVERT(smalldatetime,getdate(),110),8)	    	AS C5_HORA   	,
cQuery += " 			codigo_cobranca														AS C5_XFORMA
cQuery += "   FROM POLIBRAS..polibras_pedcab" + cCodTab
cQuery += "  WHERE importado  in (1,0)
cQuery += "    AND tipo_venda In ('" + cPara02 + "')
cQuery += "    AND orgvenda   = '" + cPara01 + "'

/*
Geraçao do arquivo de Temporario de cabecalho
*/
TCQUERY cQuery ALIAS "TRB_CAB" NEW
//dbUseArea(.T.,"TOPCONN",cQuery,"TRB_CAB",.F.,.T.)
//dbUseArea( .T., "TOPCONN", TcGenQry(,,cQuery), "TRB_CAB", .T., .F. )

/*
MobGran_pedcorp
*/
cQuery := " SELECT		RTRIM(LTRIM(codigo_produto))									    AS C6_PRODUTO	,
cQuery += " 			quantidade															AS C6_QTDVEN	,
cQuery += " 			preco_venda															AS C6_PRUNIT	,
cQuery += " 			100 - ROUND( preco_venda / preco_base ,4 ) * 100 					AS C6_DESCONT	,
cQuery += " 			preco_base															AS C6_PRCVEN	,

cQuery += " 			REPLACE(CONVERT(VARCHAR(10),getdate(),112),'-','') 					AS C6_ENTREG	,

cQuery += " 			SB1.B1_TS															AS C6_TES		,
cQuery += " 			'   '																AS C6_TESA		,
cQuery += " 			SB1.B1_LOCPAD														AS C6_LOCAL		,
cQuery += " 			PED.codigo_pedido													AS C6_PEDCLI
cQuery += "     FROM POLIBRAS..polibras_pedcorp" + cCodTab +" PED,DADOSADV"+ cCodTabP +"..SB1010 SB1,POLIBRAS..polibras_pedcab" + cCodTab + " PEDCAB
cQuery += "    WHERE (PED.importado is null)
cQuery += "      AND RTRIM(LTRIM(SB1.B1_COD)) = RTRIM(LTRIM(codigo_produto))
cQuery += "      AND D_E_L_E_T_ <> '*'
cQuery += "      AND PEDCAB.codigo_pedido = PED.codigo_pedido
cQuery += "      AND orgvenda = '" + cPara01 + "'
cQuery += "      AND tipo_venda In ('" + cPara02 + "')
cQuery += "      AND PED.importado is null

cQuery += "   ORDER BY PED.codigo_pedido,SB1.B1_GRUPO

/*
Geraçao do arquivo temporario de Itens
*/
TCQUERY cQuery ALIAS "TRB_ITEM" NEW
//dbUseArea(.T.,"TOPCONN",cQuery,"TRB_ITEM",.F.,.T.)
//dbUseArea( .T., "TOPCONN", TcGenQry(,,cQuery), "TRB_ITEM", .T., .F. )

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
	dbseek(xfilial("SA1")+TRB_CAB->C5_CLIENTE+TRB_CAB->C5_LOJACLI,.f.)
	
	/*
	Limpa todos os valores antigos
	*/
	_aCabecalho := {}
	
	/*
	Preenchimento dos Array do cabeçalho
	*/
	aAdd(_aCabecalho,"N" 							)  // C5_TIPO     1
	aAdd(_aCabecalho,AllTrim(TRB_CAB->C5_CLIENTE) 	)  // C5_CLIENTE  2
	aAdd(_aCabecalho,AllTrim(TRB_CAB->C5_LOJACLI) 	)  // C5_LOJACLI  3
	aAdd(_aCabecalho,AllTrim(SA1->A1_PESSOA) 		)  // C5_TIPOCLI  4
	aAdd(_aCabecalho,AllTrim(TRB_CAB->C5_CONDPAG)	)  // C5_CONDPAG  5
	aAdd(_aCabecalho,AllTrim(TRB_CAB->C5_TABELA)	)  // C5_TABELA   6
	aAdd(_aCabecalho,"S"							)  // C5_LIBEROK  7
	aAdd(_aCabecalho,1                     			)  // C5_MOEDA    8
	aAdd(_aCabecalho,"1"                   			)  // C5_TIPLIB   9
	aAdd(_aCabecalho,"N"        					)  // C5_BOLETO   10
	aAdd(_aCabecalho,AllTrim(TRB_CAB->C5_VEND1)		)  // C5_VEND1    11
	aAdd(_aCabecalho,AllTrim(TRB_CAB->C5_MENNOTA)	)  // C5_MENNOTA  12
	aAdd(_aCabecalho,TRB_CAB->C5_NUM				)  // C5_COTACAO  13
	aAdd(_aCabecalho,STOD(TRB_CAB->C5_EMISSAO)   	)  // C5_EMISSAO  14
	aAdd(_aCabecalho,TRB_CAB->C5_HORA				)  // C5_HORA     15
	aAdd(_aCabecalho,TRB_CAB->C5_DESCONT			)  // C5_DESCONT  16
	aAdd(_aCabecalho,TRB_CAB->C5_XFORMA 			)  // C5_XFORMA   17
	
	/*
	Na inclusao dos itens a cada loop ele zera o valor inicial
	*/
	nCodItem := 0
	_aItens	 := {}
	
	dbSelectArea("TRB_ITEM")
	dbGoTop("TRB_ITEM")
	Do While !EOF()
		
		If TRB_CAB->C5_NUM  == TRB_ITEM->C6_PEDCLI
			
			/*
			Posiciona no cadastro
			*/
			dbSelectArea("SB1")
			dbsetorder(1)
			dbseek(xfilial("SB1")+AllTrim(TRB_ITEM->C6_PRODUTO) ,.f.)
			
			/*
			Posiciona no cadastro
			*/
			dbSelectArea("SF4")
			dbsetorder(1)
			dbseek(xfilial("SF4")+AllTrim(TRB_ITEM->C6_TES) ,.f.)
			
			/*
			Soma dos itens
			*/
			nCodItem := nCodItem + 1
			
			/*
			Variais para geracao das linhas de itens do
			Pedido
			*/
			cC01 := xFilial("SC6")         			// C6_FILIAL
			cC02 := AllTrim(Str(nCodItem) ) 		// C6_ITEM
			cC03 := AllTrim(TRB_ITEM->C6_PRODUTO)  	// C6_PRODUTO
			cC04 := SB1->B1_UM  					// C6_UM
			cC05 := TRB_ITEM->C6_QTDVEN  			// C6_QTDVEN
			cC06 := TRB_ITEM->C6_PRUNIT     		// C6_PRUNIT
			cC07 := TRB_ITEM->C6_PRCVEN  			// C6_PRCVEN
			cC08 := 0
			cC09 := SA1->A1_XTES 					// C6_TES
			cC10 := SB1->B1_ORIGEM+SF4->F4_SITTRIB  // C6_SITTRIB
			cC11 := TRB_ITEM->C6_LOCAL  			// C6_LOCAL
			cC12 := dDataBase  						// C6_ENTREG
			cC13 := TRB_ITEM->C6_DESCONT  			// C6_DESCONT
			
			/*
			Criaçao da Linha de itens dos Pedidos
			*/
			aAdd( _aItens , {cC01,cC02,cC03,cC04,cC05,cC06,cC07,cC08,cC09,cC10,cC11,cC12,cC13} )
			
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
		
		If Ascan(aIdVend,AllTrim(TRB_CAB->C5_VEND1)) == 0
			
			COnOut("*********************************************")
			COnOut(" Prg [addVendArry]        (SIGAWISE)         ")
			COnOut("*********************************************")
			
			aAdd(aIdVend,AllTrim(TRB_CAB->C5_VEND1))
			
		EndIf
		
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
Local aAreasPed := GetArea()
Local _aAutoSC5 	:= {}
Local _aAutoSC6 	:= {}
Local _aLinha		:= {}
Local _aErroSC6     := {}
Local i 			:= 0
Local _cErro    	:= "00"
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
	
	/*
	Recebe o proximo numero de pedidos do Protheus
	*/
	cPedido  := GetSxeNum(_cTabela,"C5_NUM")
	
	RollBackSxE()
	
	/*
	Posiciona no cadastro
	*/
	dbSelectArea("SA1")
	dbSetOrder(1)
	If !dbSeek(xFilial("SA1") + _aCabecalho[2] + _aCabecalho[3] )
		ConOut("Cliente não econtrado!")
	EndIf
	
	/*
	Posiciona no cadastro
	*/
	dbSelectArea("SA3")
	dbSetOrder(1)
	If !dbSeek(xFilial("SA3") + _aCabecalho[11] )
		ConOut("Vendedor não econtrado!")
	EndIf
	
	/*
	Criaçao do Array especifio da inclusao do pedido de venda
	Rotina de Cabeçalho
	*/
	
	_aAutoSC5:={{"C5_NUM"    ,cPedido           			,Nil},; // Numero do pedido
	{"C5_POLIB"  ,"S"         	    			,Nil},; // POLIBRAS =S
	{"C5_TIPO"   ,"N"         	    			,Nil},; // Tipo de pedido
	{"C5_CLIENTE",_aCabecalho[2]       			,Nil},; // Codigo do cliente
	{"C5_LOJAENT",_aCabecalho[3]      			,Nil},; // Loja para entrada
	{"C5_LOJACLI",_aCabecalho[3]      			,Nil},; // Loja do cliente
	{"C5_EMISSAO",_aCabecalho[14]   	    	,Nil},; // Data de emissao
	{"C5_DTINC"  ,_aCabecalho[14]   	    	,Nil},; // Data de emissao
	{"C5_HRINC"  ,_aCabecalho[15]    			,Nil},; // Hora de inclusao
	{"C5_CONDPAG",_aCabecalho[5]       			,Nil},; // Codigo da condicao de pagamento
	{"C5_DESC1"  ,_aCabecalho[16]           	,Nil},; // Percentual de Desconto
	{"C5_INCISS" ,"N"         	    			,Nil},; // ISS Incluso
	{"C5_MOEDA"  ,1                 			,Nil},; // Moeda
	{"C5_TIPOCLI",SA1->A1_TIPO	    			,Nil},; // Tipo Cliente
	{"C5_TIPLIB" ,"1"         	    			,Nil},; // Tipo de Liberacao
	{"C5_LIBEROK","S"         	    			,Nil},; // Liberacao Total
	{"C5_BOLETO" , _aCabecalho[10]				,Nil},; // Boleto
	{"C5_VOLUME1",0								,Nil},; // Volume
	{"C5_VEND1"  ,_aCabecalho[11]          		,Nil},; // Vendedor
	{"C5_NOMEVEN",AllTrim(SA3->A3_NOME)         ,Nil},; // Nome Vendedor
	{"C5_TPCARGA","1" 			         		,Nil},; // Tipo de carga  - 21/08/2013
	{"C5_TRANSP" ,"000001"                      ,Nil},; // Transportadora
	{"C5_TABELA" ,_aCabecalho[6]                ,Nil},; // Codigo da Tabela de Preco
	{"C5_MENNOTA",AllTrim(_aCabecalho[12])      ,Nil},; // MSG
	{"C5_XFORMA" ,AllTrim(_aCabecalho[17])      ,Nil},; // Forma de pagamento
	{"C5_COTACAO",AllTrim(str(_aCabecalho[13])) ,Nil}}  // C5_NUM OU C5_COTACAO
	
	
	//
	
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
			aadd(_aLinha,{"C6_NUM"    ,cPedido                     			      	,Nil}) // Numero do Pedido
			aadd(_aLinha,{"C6_ITEM"   ,Iif(i < 100, StrZero(i,2),AllTrim(Str(i))) 	,Nil}) // Numero do Item no Pedido
			aadd(_aLinha,{"C6_PRODUTO",_aItens[i,3]                					,Nil}) // Codigo do Produto
			aadd(_aLinha,{"C6_DESCRI" ,SB1->B1_DESC                					,Nil}) // Descricao produto
			aadd(_aLinha,{"C6_QTDVEN" ,_aItens[i,5]                					,Nil}) // Quantidade Vendida
			aadd(_aLinha,{"C6_PRCVEN" ,_aItens[i,6]              				    ,Nil}) // Preco de Lista
			aadd(_aLinha,{"C6_PRUNIT" ,_aItens[i,7]                 				,Nil}) // Preco Unitario Liquido
			aadd(_aLinha,{"C6_VALOR"  ,_aItens[i,5] * _aItens[i,6]                 	,Nil}) // Preco Total
			aadd(_aLinha,{"C6_ENTREG" ,dDatabase          							,Nil}) // Data da Entrega
			aadd(_aLinha,{"C6_UM"     ,_aItens[i,4]                 				,Nil}) // Unidade de Medida Primar.
			aadd(_aLinha,{"C6_TES"    ,_aItens[i,9]                 				,Nil}) // Tipo de Entrada/Saida do Item
			aadd(_aLinha,{"C6_CLASFIS",StrZero(VAL(_aItens[i,10]),3)				,Nil,.T.}) // Tipo de Entrada/Saida do Item
			aadd(_aLinha,{"C6_LOCAL"  ,_aItens[i,11]              					,Nil}) // Armazem
			aadd(_aLinha,{"C6_DESCONT",_aItens[i,13]           						,Nil}) // Percentual de Desconto
			aadd(_aLinha,{"C6_COMIS1" ,3                           					,Nil}) // Comissao Vendedor
			aadd(_aLinha,{"C6_CLI"    ,_aCabecalho[2]               				,Nil}) // Cliente
			aadd(_aLinha,{"C6_LOJA"   ,_aCabecalho[3]              					,Nil}) // Loja do Cliente
			aadd(_aLinha,{"C6_QTDLIB" ,_aItens[i,5]                 				,Nil}) // Quantidade Liberada
			
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
	Execauto para geracao dos pedidos com validacacoes
	*/
	MSExecAuto({|x,y,Z| Mata410(x,y,Z)},_aAutoSC5,_aAutoSC6,3)
	
	/*
	Variavel complementar de apoio de erros
	*/
	cDescErro     := ""
	
	If lMsErroAuto
		cDescErro :=	MostraErro()
		
		DisarmTransaction()
		RollBackSxE()
	Else
		/*
		Confirmacao do pedido
		*/
		ConfirmSX8()

        SC6->(DbSetOrder(1))
		If SC6->(DbSeek(xFilial("SC5")+SC5->C5_NUM))

			Do While !SC6->(Eof()) .And. SC5->(C5_FILIAL+C5_NUM) == SC6->(C6_FILIAL+C6_NUM)
				
				dbSelectArea("SB1")
				dbsetorder(1)
				dbseek(xfilial("SB1")+AllTrim(SC6->C6_PRODUTO) ,.f.)
				
				/*
				Posiciona no cadastro
				*/
				dbSelectArea("SF4")
				dbsetorder(1)
				dbseek(xfilial("SF4")+AllTrim(SC6->C6_TES) ,.f.)
				
				RecLock("SC6")
				SC6->C6_CLASFIS := SB1->B1_ORIGEM+SF4->F4_SITTRIB
				MsUnLock()
				
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
		
		
		cQuery := " UPDATE "+RetSqlName("SC9")
		cQuery += "   SET C9_TPCARGA = '1'
		cQuery += "  WHERE D_E_L_E_T_ <> '*'
		cQuery += "    AND C9_TPCARGA = '3'
		cQuery += "    AND C9_PEDIDO  = '"+ cPedido +"'"
		cQuery += "    AND C9_FILIAL  = '"+ xFilial(_cTabela) +"'"
		cQuery += "    AND C9_DATALIB >= '"+ dtos(ddatabase-10) +"'"
		/*
		Execucao background do codigo sql
		*/
		TcSqlExec(cQuery)
		
		cQuery := " UPDATE POLIBRAS..polibras_pedcab" + cCodTab
		cQuery += "    SET importado = 2 , situacao_retorno = 5 , retorno = 2 , cod_ped_gestao = '"+ cPedido +"'"
		cQuery += "  WHERE codigo_pedido = "+ AllTrim(str(_aCabecalho[13]))
		/*
		Execucao background do codigo sql
		*/
		TcSqlExec(cQuery)
		
		cQuery := " UPDATE POLIBRAS..polibras_pedcorp" + cCodTab
		cQuery += "    SET importado = 2,cod_ped_gestao = '"+ cPedido +"'"
		cQuery += "  WHERE codigo_pedido = "+ AllTrim(str(_aCabecalho[13]))
		/*
		Execucao background do codigo sql
		*/
		TcSqlExec(cQuery)
		
		/*
		Atualizando no banco da polibras os intes que nao foram importados
		*/
		If !Empty(_aErroSC6)
			For nX:=1 to Len(_aErroSC6)
				
				cQuery := " UPDATE POLIBRAS..polibras_pedcorp" + cCodTab
				cQuery += "    SET importado = 3,cod_ped_gestao = '"+ cPedido +"', observacao = '" + _aErroSC6[nX][4] + "'"
				cQuery += "  WHERE codigo_pedido = "+ AllTrim(str(_aCabecalho[13]))
				cQuery += "    AND codigo_produto ='" + AllTrim(_aErroSC6[nX][3]) + "'"
				
				/*
				Execucao background do codigo sql
				*/
				TcSqlExec(cQuery)
				//ConOut(cQuery)
				
			Next nX
		EndIf
		
	Else
		
		cQuery := " UPDATE POLIBRAS..polibras_pedcab" + cCodTab
		cQuery += "    SET importado = 3, situacao_retorno=5 , retorno = 2 ,observacao_gestao = '" + cDescErro + "'"
		cQuery += "  WHERE codigo_pedido = "+ AllTrim(str(_aCabecalho[13]))
		/*
		Execucao background do codigo sql
		*/
		TcSqlExec(cQuery)
		
		cQuery := " UPDATE POLIBRAS..polibras_pedcorp" + cCodTab
		cQuery += "    SET importado = 3 "
		cQuery += "  WHERE codigo_pedido = "+ AllTrim(str(_aCabecalho[13]))
		/*
		Execucao background do codigo sql
		*/
		TcSqlExec(cQuery)
		
		/*
		Atualizando no banco da polibras os intes que nao foram importados
		*/
		If !Empty(_aErroSC6)
			For nX:=1 to Len(_aErroSC6)
				
				cQuery := " UPDATE POLIBRAS..polibras_pedcorp" + cCodTab
				cQuery += "    SET importado = 3, observacao = '" + _aErroSC6[nX][4] + "'"
				cQuery += "  WHERE codigo_pedido = "+ AllTrim(str(_aCabecalho[13]))
				cQuery += "    AND codigo_produto ='" + AllTrim(_aErroSC6[nX][3])    + "'"
				/*
				Execucao background do codigo sql
				*/
				TcSqlExec(cQuery)
				
				//ConOut(cQuery)
			Next nX
		EndIf
		
		_cErro   := "02"
		cPedido  := Space(06)
	EndIf
	
Else
	_cErro 		:= "03"
EndIf

_aRetorno := {cPedido,_cErro}
RestArea(aAreasPed)

Return(_aRetorno)
