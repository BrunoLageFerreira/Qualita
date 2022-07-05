#INCLUDE "rwmake.ch"   
#include "protheus.ch"  
#INCLUDE "topconn.ch"
#INCLUDE "TBICONN.CH"

/*                                          
Programa ...: MT100TOK.Prw
Uso ........: Ponto de Entrada (DOCUMENTO DE ENTRADA VALIDACAO DO PEDIDO DE COMPRAS)
Data .......: 09/11/16
Feito por ..: Bruno Lage Ferreira.
ITINGA ITINGA ITINGA ITINGA ITINGA ITINGA ITINGA ITINGA ITINGA ITINGA ITINGA ITINGA ITINGA 
*/

User Function MT100TOK()
***********************************************************************************************************
*  
*
***    
Local lRet        := .t.
Local nVRNF       := MaFisRet(,"NF_TOTAL")              
Local nVlr        := 0
Local nPVlr       := 0
Local nMoedaLocal := 0
Local aMT100TOK   := GetArea()

Local nVTC        := 0
Local nX          := 0
                     
/*
Parametro foi  customizado 
para Itinga 
*/
Local cProFora := SuperGetMV("MV_EXCPROD", ," ")   
 
/*
Parametro para definir quais tes nao devem ser consideradas 
para exigir o pedido de compras         
Trabalha em conjunto com MV_PCNFE
*/
Local cTesFora := SuperGetMV("MV_TESPCNF", ," ") 
	
	/*
	Nota fiscal manual de saída
	*/
	IF FUNNAME() <> "MATA920"
		/*
		Obriga o usuario a lançar um centro de custos na janela de rateios
		*/
		IF gdFieldGet("D1_COD") <> NIL
		
			If (!SubString(gdFieldGet("D1_COD"),1,2) $ "BL/CH" .And. AllTrim(CA100FOR) <> '000165') .Or. (cEspecie=="CTE")
				If Len(aBackCOLSSDE)==0 
					lRet := .F.
					Aviso("Aviso!","Preencha o centro de custos na tela de rateios! OUTRAS AÇOES > RAT CC ",{"OK"})
					ConOut("VALIDAÇÃO | Preencha o centro de custos na tela de rateios! OUTRAS AÇOES > RAT CC ")
					Return(lRet)
				EndIf
			EndIf
			
			For nX:=1 to Len(aCols) 
				dbSelectArea("SF4")
				dbSetOrder(1)
				If dbSeek(xFilial("SF4")+AllTrim(acols[nX][aScan(aHeader,{|x|alltrim(x[2])=="D1_TES"})]))
					If SF4->F4_DUPLIC =='S'
						If EMPTY(MaFisRet(,"NF_NATUREZA"))
								lRet := .F.
								Aviso("Aviso!","Preencha o campo de natureza abaixo da condição de pagamento!",{"OK"})
								ConOut("VALIDAÇÃO | Preencha o campo de natureza abaixo da condição de pagamento!")
								Return(lRet)
						EndIf
					EndIf
				EndIf
			Next nX
			
			For nX:=1 to Len(aCols) 
		
				If !AllTrim(acols[nX][aScan(aHeader,{|x|alltrim(x[2])=="D1_COD"})]) $ AllTrim(cProFora) 
					If !AllTrim(acols[nX][aScan(aHeader,{|x|alltrim(x[2])=="D1_TES"})]) $ AllTrim(cTesFora)
		
						/*
						Validação de quantidade
						*/
						If !Empty(acols[nX][aScan(aHeader,{|x|alltrim(x[2])=="D1_PEDIDO"})] )
							dbSelectArea("SC7")	                       
							dbSetOrder(4)
							If dbSeek(cfilant + acols[nX][aScan(aHeader,{|x|alltrim(x[2])=="D1_COD"})] + acols[nX][aScan(aHeader,{|x|alltrim(x[2])=="D1_PEDIDO"})] + acols[nX][aScan(aHeader,{|x|alltrim(x[2])=="D1_ITEMPC"})] )
								
								nMoedaLocal := SC7->C7_MOEDA
		
								If acols[nX][len(aHeader)+1] <> .T.
									If acols[nX][aScan(aHeader,{|x|alltrim(x[2])=="D1_QUANT"})] > (SC7->C7_QUANT  - SC7->C7_QUJE)
										lRet := .F.
										Aviso("Aviso!","Quantidade do item diferente do pedido de compras! Pedido nº:["+acols[nX][aScan(aHeader,{|x|alltrim(x[2])=="D1_PEDIDO"})]+"] Item: ["+acols[nX][aScan(aHeader,{|x|alltrim(x[2])=="D1_ITEM"})]+"]",{"OK"})
									EndIf 
		
									//Somando valores totais do pedido de compras   
									nPVlr := nPVlr + ((SC7->C7_QUANT  - SC7->C7_QUJE) * SC7->C7_PRECO) + SC7->C7_VALIPI + SC7->C7_VALICM     
		
									//Somando valores totais da nota fiscal de Entrada
									nVlr  := nVlr  + acols[nX][aScan(aHeader,{|x|alltrim(x[2])=="D1_TOTAL"})]  + acols[nX][aScan(aHeader,{|x|alltrim(x[2])=="D1_VALIPI"})] + acols[nX][aScan(aHeader,{|x|alltrim(x[2])=="D1_VALICM"})]
								EndIf					                                                   
		
							Else
								Aviso("Aviso!","Itens não encontrado no pedido de compras!",{"OK"})
							EndIf
						EndIf        
		
					EndIf
		
				EndIf
		
			Next nX
		
			/*
			Validação de Total da Nota Fiscal
			MV_ALTPRCC estava como 1 abilitado 
			e foi alterado para 0 desabilitado
			*/        
			lRepet := .T.
		
			For nX:=1 to Len(aCols) 
				If !Empty(acols[nX][aScan(aHeader,{|x|alltrim(x[2])=="D1_PEDIDO"})] )
					If !AllTrim(acols[nX][aScan(aHeader,{|x|alltrim(x[2])=="D1_COD"})]) $ AllTrim(cProFora)  
		
						If !AllTrim(acols[nX][aScan(aHeader,{|x|alltrim(x[2])=="D1_TES"})]) $ AllTrim(cTesFora)
		
							If acols[nX][len(aHeader)+1] <> .T. .and. (nMoedaCor == 0) 
								nVTC  := (nPVlr * 0.01)
		
								If 	(nVlr > (nPVlr + nVTC)) 	            
									If lRepet == .T.
										lRet := .F.	
										Aviso("Aviso!","Valor total da Nota Fiscal esta ([1%] Maior) comparado com o pedido de compras nº:["+acols[1][aScan(aHeader,{|x|alltrim(x[2])=="D1_PEDIDO"})]+"] Total R$" + Alltrim(Transform(nPVlr,"@E 999,999,999.99")),{"OK"})
									EndIf				
								EndIf
		
								If (nVlr < (nPVlr - nVTC))
									If lRepet == .T.
										If MsgYesNo("Valor total da Nota Fiscal esta ([1%] Menor) comparado com o pedido de compras nº:["+acols[1][aScan(aHeader,{|x|alltrim(x[2])=="D1_PEDIDO"})]+"] Total R$" + Alltrim(Transform(nPVlr,"@E 999,999,999.99"))+". Deseja continuar?" )
											lRet := .T.  
											lRepet := .F.
										Else
											lRet := .F.
											lRepet := .F.	
										EndIf			
									EndIf
								EndIf                                         
							EndIf 
		
						EndIf	
		
					EndIf
				EndIf
			Next nX   
			
		EndIf
		
		If lRet 
			lRet := U_GTPE005()
		EndIf
		
	EndIf
	
RestArea(aMT100TOK)
	
Return(lRet)
