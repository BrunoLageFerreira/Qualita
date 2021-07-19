#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
#INCLUDE "TOPCONN.CH"

User Function RelPdv

	//+--------------------------------------------------------------------+
	//| Declaracao de Variaveis                                            |
	//+--------------------------------------------------------------------+

	Local cQuery	:= ""  
	Local cPerg 	:= ""

	//+--------------------------------------------------------------------+
	//| Define os estilos de fonte a serem utilizados                      |
	//+--------------------------------------------------------------------+
	Private oFont1 := TFont():New( "Arial",,10,,.F.,,,,.F.,.F. ) 
	Private oFont2 := TFont():New( "Arial",,10,,.T.,,,,.F.,.F. ) 
	Private oFont3 := TFont():New( "Arial",,16,,.F.,,,,.F.,.F. )
	Private oFont4 := TFont():New( "Arial",,08,,.T.,,,,.F.,.F. ) 

	Private nColIni := 0
	Private nLimite	:= 2330
	Private nColFim := 2350 

	Private	cEmpresa := ""
	oprn:=TMSPrinter():New("Pedido de Venda")   

	oPrn:SetPaperSize(9) // A4
	oPrn:setPortrait()   // Retrato
	oPrn:Setup()

	Pergunte("RELPDV",.T.)

	cFil	:= mv_par01
	cPed	:= mv_par02

	ImpDados()
	ImpRodape()

	oPrn:Preview()

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

	cQuery :=	"SELECT C5_FILIAL,C5_TIPO,C5_NUM,C5_CLIENTE,C5_LOJACLI,C5_EMISSAO,C5_TRANSP,C5_CONDPAG,C5_TPFRETE,C5_VEND1,C5_OBS,C5_MOEDA,"
	cQuery +=	" C6_CLASS,C6_ITEM,C6_PRODUTO,C6_LOTECTL,C6_DESCRI,C6_COMPLIQ,C6_ALTLIQ,C6_LARGLIQ,C6_UM,C6_QTDVEN,C6_PRCVEN,C6_VALOR FROM"
	cQuery +=	" SC5050 INNER JOIN SC6050 ON"
	cQuery +=	" SC5050.C5_FILIAL = SC6050.C6_FILIAL AND SC5050.C5_NUM = SC6050.C6_NUM AND"
	cQuery +=	" SC5050.D_E_L_E_T_ = '' AND SC6050.D_E_L_E_T_ = ''"
	cQuery +=	" WHERE C5_FILIAL = '"+cFil+"' AND C5_NUM = '"+cPed+"' AND SC6050.D_E_L_E_T_ = '' ORDER BY C5_NUM"

	TcQuery cQuery Alias PED New

	DbSelectArea("PED")
	DbGoTop()

	oprn:StartPage()  
	//DADOS CLIENTE

	cFil:= Alltrim(SM0->M0_NOMECOM)+ " - " + Alltrim(SM0->M0_FILIAL)
	dEmis	:= Substr(PED->C5_EMISSAO,7,2)+"/"+Substr(PED->C5_EMISSAO,5,2)+"/"+Substr(PED->C5_EMISSAO,1,4)
	cDDD	:= Posicione("SA1",1,xFilial("SA1")+PED->C5_CLIENTE+C5_LOJACLI,"A1_DDD")
	cTel	:= Posicione("SA1",1,xFilial("SA1")+PED->C5_CLIENTE+C5_LOJACLI,"A1_TEL")
	cNome 	:= Posicione("SA1",1,xFilial("SA1")+PED->C5_CLIENTE+C5_LOJACLI,"A1_NOME")
	cContato:= Posicione("SA1",1,xFilial("SA1")+PED->C5_CLIENTE+C5_LOJACLI,"A1_CONTATO")
	cBairro := Posicione("SA1",1,xFilial("SA1")+PED->C5_CLIENTE+C5_LOJACLI,"A1_BAIRRO")
	cCidade := Posicione("SA1",1,xFilial("SA1")+PED->C5_CLIENTE+C5_LOJACLI,"A1_MUN")
	cUf 	:= Posicione("SA1",1,xFilial("SA1")+PED->C5_CLIENTE+C5_LOJACLI,"A1_EST")
	cCep	:= Posicione("SA1",1,xFilial("SA1")+PED->C5_CLIENTE+C5_LOJACLI,"A1_CEP")
	cCnpj :=  Posicione("SA1",1,xFilial("SA1")+PED->C5_CLIENTE+C5_LOJACLI,"A1_CGC")
	cIE 	:= Posicione("SA1",1,xFilial("SA1")+PED->C5_CLIENTE+C5_LOJACLI,"A1_INSCR")
	cEnd 	:= Posicione("SA1",1,xFilial("SA1")+PED->C5_CLIENTE+C5_LOJACLI,"A1_END")

	cMoeda	:= IIF(PED->C5_MOEDA == 1,"R$","US$")
	cTransp	:= IIF(Alltrim(PED->C5_TRANSP) == "","",Posicione("SA4",1,xFilial("SA4")+Alltrim(PED->C5_TRANSP),"A4_NOME"))
	cVend	:= Posicione("SA3",1,xFilial("SA3")+Alltrim(PED->C5_VEND1),"A3_NOME")
	cCond	:= Posicione("SE4",1,xFilial("SE4")+PED->C5_CONDPAG,"E4_DESCRI")
	cFrete	:= IIF(Alltrim(PED->C5_TPFRETE) == "C","(CIF)","(FOB)")
	cObs    := PED->C5_OBS

	//+--------------------------------------------------------+
	//| Preparacao para impressão do cabeçalho                 |
	//+--------------------------------------------------------+

	oPrn:Say( 0000 , 0010 , cFil , oFont2 )
	oPrn:Say( 0000 , 1950 , Substr(DtoS(date()),7,2)+"/"+Substr(DtoS(date()),5,2)+"/"+Substr(DtoS(date()),1,4)+" - "+time()  , oFont2 )

	oPrn:Say( 0070 , 0600 , "Pedido de Venda" , oFont3 )
	oPrn:Say( 0070 , 1100 , " - Nº." , oFont3 )	
	oPrn:Say( 0070 , 1250 , Alltrim(PED->C5_NUM) , oFont3 )

	oPrn:Say( 0200 , 0010 , "Cliente:", oFont2)
	oPrn:Say( 0200 , 0200 ,Alltrim(PED->C5_CLIENTE)+" / "+Alltrim(PED->C5_LOJACLI)+" - "+Alltrim(cNome), oFont1)

	oPrn:Say( 0250 , 0010 , "Contato:", oFont2)
	oPrn:Say( 0250 , 0200 ,Alltrim(cContato), oFont1)	

	oPrn:Say( 0300 , 0010 , "Bairro:", oFont2)
	oPrn:Say( 0300 , 0200 ,Alltrim(cBairro), oFont1)	

	oPrn:Say( 0300 , 0700 , "Cidade:", oFont2)
	oPrn:Say( 0300 , 0900 ,Alltrim(cCidade), oFont1)	

	oPrn:Say( 0300 , 1400 , "UF:", oFont2)
	oPrn:Say( 0300 , 1500 ,cUf, oFont1)	

	oPrn:Say( 0350 , 0010 , "Cep:", oFont2)
	oPrn:Say( 0350 , 0200 ,Alltrim(cCep), oFont1)	

	oPrn:Say( 0350 , 0400 , "CPF/CNPJ:", oFont2)
	oPrn:Say( 0350 , 0600 ,	IIF(Len(Alltrim(cCnpj))<13,Transform(cCnpj,"@R 999.999.999-99"),Transform(cCnpj,"@R 99.999.999/999999")), oFont1)

	oPrn:Say( 0350 , 1100 , "I.E.:", oFont2)
	oPrn:Say( 0350 , 1200 ,Alltrim(cIE), oFont1)		

	oPrn:Say( 0400 , 0010 , "Endereco:", oFont2)
	oPrn:Say( 0400 , 0200 , Alltrim(cEnd), oFont1)	


	oPrn:Say( 0200 , 1800 , "Data:", oFont2)
	oPrn:Say( 0200 , 2100 ,Alltrim(dEmis), oFont1)	

	oPrn:Say( 0250 , 1800 , "Data Prev Ent.:", oFont2)	

	oPrn:Say( 0300 , 1800 , "Data Entrega:", oFont2)	

	oPrn:Say( 0350 , 1800 , "Telefone:", oFont2)	
	oPrn:Say( 0350 , 2100 , Alltrim(cDDD)+"-"+Alltrim(cTel), oFont1)	

	//----------------------------------------------------------------------------------------------------	
	//Dados Transportador


	oPrn:Say( 0550 , 0010 , "Motorista:", oFont2)	
	oPrn:Say( 0550 , 0250 ,	cTransp,oFont1)    

	oPrn:Say( 0600 , 0010 , "Vendedor:", oFont2)		
	oPrn:Say( 0600 , 0250 ,	cVend,oFont1)    

	oPrn:Say( 0650 , 0010 , "Cond.Pgto:", oFont2)	
	oPrn:Say( 0650 , 0250 ,	cCond,oFont1)    

	oPrn:Say( 0700 , 0010 , "Frete:", oFont2)	
	oPrn:Say( 0700 , 0250 ,	cFrete, oFont1)    

	oPrn:Say( 0750 , 0010 , "Observações:", oFont2)	
	oPrn:Say( 0750 , 0250 ,	Substr(cOBS,1,100),oFont1)    
	oPrn:Say( 0800 , 0010 ,	Substr(cOBS,101,110),oFont1)    



	//----------------------------------------------------------------------------------------------------	
	//Cabecalho dos Itens

	oPrn:Say( 0900 , 0010 , "Código / Lote"			,oFont2)	
	oPrn:Say( 0900 , 0330 , "Descrição"				,oFont2)		
	oPrn:Say( 0900 , 1200 , "Class."				,oFont2)	
	oPrn:Say( 0900 , 1350 , "Unidade"				,oFont2)	
	oPrn:Say( 0900 , 1530 , "Quantidade"			,oFont2)	
	oPrn:Say( 0900 , 1850 , "Vlr.Unit.("+cMoeda+")"	,oFont2)	
	oPrn:Say( 0900 , 2200 , "Sub-Total"				,oFont2)	

	nLin := 1000	                                                                                                

	//----------------------------------------------------------------------------------------------------			
	//Itens        
	nCont	:= 0
	nM3  	:= 0
	nTotal	:= 0
	cUM 	:= PED->C6_UM
	While (!Eof())

		nLin1:= 0
		cComp:=Alltrim(Transform(PED->C6_COMPLIQ,"@E 99,999.999"))
		cAlt :=Alltrim(Transform(PED->C6_ALTLIQ,"@E 99,999.999"))
		cLarg:=Alltrim(Transform(PED->C6_LARGLIQ,"@E 99,999.999"))

		cProd := Alltrim(PED->C6_DESCRI)
		cProd1:= "CxAxL : "+cComp+" x "+cAlt+" x "+cLarg

		oPrn:Say( nLin , 0010 , Alltrim(PED->C6_PRODUTO)+" - "+Alltrim(PED->C6_LOTECTL)		,oFont1)	

		oPrn:Say( nLin , 0330 ,	cProd,oFont1)    
		IF(Len(cProd1)> 1)
			oPrn:Say( nLin + 50 , 0330 , cProd1,oFont1)
			nLin1 := 50
		Endif    

		oPrn:Say( nLin , 1200 , PED->C6_CLASS		    ,oFont1)	
		oPrn:Say( nLin , 1350 , PED->C6_UM				,oFont1)	
		oPrn:Say( nLin , 1530 , TRANSFORM(PED->C6_QTDVEN,"@E 9,999,999.999")	,oFont1)	
		oPrn:Say( nLin , 1850 , TRANSFORM(PED->C6_PRCVEN,"@E 9,999,999.999")	,oFont1)
		oPrn:Say( nLin , 2150 , TRANSFORM(PED->C6_VALOR ,"@E 9,999,999.999")	,oFont1)

		nLin+= 50 + nLin1  
		If nLin >= 3300
			Reiniciapag() 
			nLin := 70
		Endif		
		nCont	+= 1
		nM3  	+= PED->C6_QTDVEN
		nTotal	+= PED->C6_VALOR

		DbSkip()
	End
	//----------------------------------------------------------------------------------------------------			
	//Fim Itens - Blocos
	nLin += 50       //3100
	oPrn:Say( nLin , 1700 , "Total:"		,oFont2)	
	oPrn:Say( nLin , 2070 , cMoeda+" "+Transform(nTotal,"@E 999,999,999.99"),oFont1)	

	oPrn:Say( nLin , 0010 , "Blocos:"	,oFont2)
	oPrn:Say( nLin , 0200 , "Qtde: "	,oFont2)	
	oPrn:Say( nLin , 0330 , TRANSFORM(nCont,"@E 99999")	,oFont1)		
	nLin+= 50
	oPrn:Say( nLin , 0200 , Alltrim(cUM)+": "		,oFont2)	
	oPrn:Say( nLin , 0330 , TRANSFORM(nM3,"@E 999,999.999")	,oFont1)		
	nLin+= 50
	oPrn:Say( nLin , 1700 , "Total a Pagar:"		,oFont2)	
	oPrn:Say( nLin , 2070 , cMoeda+" "+Transform(nTotal,"@E 999,999,999.99"),oFont1)	
	nLin+= 50
	oPrn:Line( nLin , 00010 , nLin , 2390)
	nLin+= 50
	If nLin >= 2900
		Reiniciapag() 
		nLin := 70
	Endif

	oPrn:Say( nLin , 0010 , "CONDIÇÕES DE FORNECIMENTO QUE FAZEM PARTE INTEGRANTE DESTE PEDIDO:",oFont4)
	nLin+= 50
	oPrn:Say( nLin , 0010 , "1)O prazo será vigente no dia do embarque;",oFont4)
	nLin+= 50
	oPrn:Say( nLin , 0010 , "2)As datas fixadas para entrega da mercadoria poderão ser antecipadas ou postergadas sempre que ocorrer motivos de natureza operacional;",oFont4)
	nLin+= 50
	oPrn:Say( nLin , 0010 , "3)Esse pedido está sujeito a confirmação da gerência de vendas e aprovação do setor de crédito e cobrança;",oFont4)
	nLin+= 50
	oPrn:Say( nLin , 0010 , "4)O signatário assume a qualidade de Fiador e principalmente pagador das Duplicatas emitidas em consequências do presente pedido sem qualquer ressalva;",oFont4)
	nLin+= 50                         

	oPrn:Box ( nLin , 0010 , nLin+250 , 2390 )
	oPrn:Line( nLin , 0600 , nLin+250 , 0600 )
	oPrn:Line( nLin , 1200 , nLin+250 , 1200 )
	oPrn:Line( nLin , 1800 , nLin+250 , 1800 )


	nLin+= 50                         
	oPrn:Say( nLin , 0050 , "CLIENTE ____/____/_______" ,oFont2)
	oPrn:Say( nLin + 100 , 0050 , "__________________________" ,oFont2)	

	oPrn:Say( nLin , 0650 , "VENDAS ____/____/_______" ,oFont2) 
	oPrn:Say( nLin + 100 , 0650 , "__________________________" ,oFont2)	

	oPrn:Say( nLin , 1250 , "CRÉDITO ____/____/_______" ,oFont2)
	oPrn:Say( nLin + 100 , 1250 , "__________________________" ,oFont2)	

	oPrn:Say( nLin , 1850 , "APROVAÇÃO ____/____/_______" ,oFont2)
	oPrn:Say( nLin + 100 , 1850 , "__________________________" ,oFont2)	
	DBSELECTAREA("PED")
	DBCloseArea()

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

//Iniciar uma nova pagina
Static Function ReiniciaPag()

	oPrn:EndPage()
	oPrn:StartPage()

Return