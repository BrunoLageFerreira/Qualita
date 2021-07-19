#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
#INCLUDE "topconn.ch"

/*
Programa ...: GR002COL.Prw
Uso ........: Ponto de entrada que permite alterar o conteúdo da aCols 
			  da consulta de produto do fonte GROA002.PRW
Data .......: 25/04/2019
Feito por ..: Bruno Lage Ferreira 
MV_NDESCTP - DESCONTO NO PREÇO DE LISTA E UNITARIO
*/

User Function GR002COL()
/*****************************************************************************************************
*
*
*
***/
Local aHeader := PARAMIXB[1]
Local aCols   := PARAMIXB[2]    
Local nPosPrc := aScan(aHeader, {|x| AllTrim(x[2]) == "C6_PRCVEN" }) //Preço de venda
Local nPosPun := aScan(aHeader, {|x| AllTrim(x[2]) == "C6_PRUNIT" }) //Preço de tabela
Local nPosPro := aScan(aHeader, {|x| AllTrim(x[2]) == "C6_PRODUTO"}) //Preço de venda
Local nPosCla := aScan(aHeader, {|x| AllTrim(x[2]) == "C6_YCLASSI"}) //Preço de tabela
Local nPosTes := aScan(aHeader, {|x| AllTrim(x[2]) == "C6_TES"    }) //TES

Local nPosSUBL := aScan(aHeader, {|x| AllTrim(x[2]) == "C6_NUMLOTE"}) //Lote
Local nPosLOTE := aScan(aHeader, {|x| AllTrim(x[2]) == "C6_LOTECTL"}) //SubLote

Local cQuery  := ""

Local nX      := 0
Local cClassif:= ""

dbSelectArea("SA1")
dbSetOrder(1)
dbSeek(xFilial("SA1") + M->C5_CLIENTE + M->C5_LOJACLI )

For nX := 1 To Len(aCols)

	If (FUNNAME() <> "GROA001") .and. (FUNNAME() <> "GROA013")
		If Empty(M->C5_TABELA)
			If Empty(aCols[nX][nPosCla])
				cClassif := "P"
			Else
				cClassif := aCols[nX][nPosCla]
			EndIf
					
			cQuery  := " SELECT DA1_PRCVEN 
			cQuery  += "   FROM DA0010 DA0 
			cQuery  += "        INNER JOIN DA1010 DA1 
			cQuery  += " ON (DA0_CODTAB = DA1_CODTAB)
			
			If SubStr(AllTrim(aCols[nX][nPosPro]) ,1,2) <> 'AM'
				cQuery  += "  WHERE DA0_YCLASS IN ('"+ cClassif +"')
				cQuery  += "    AND DA1_CODPRO = '"+aCols[nX][nPosPro]+"'
			Else
				cQuery  += "  WHERE DA1_CODPRO = '"+aCols[nX][nPosPro]+"'
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
			
		    aCols[nX][nPosPrc] := IIF(EMPTY(TRB->DA1_PRCVEN),0,TRB->DA1_PRCVEN) 
		    aCols[nX][nPosPun] := IIF(EMPTY(TRB->DA1_PRCVEN),0,TRB->DA1_PRCVEN) // BRUNO TESTE TB_PREÇO 23/09/2019
		    
		    /*
		    Classificação Amostra
		    */
		    If AllTrim(cClassif) $ 'A'
		    	aCols[nX][nPosTes] := "525"
		    EndIf
		    
		    /*
		    Produto Amostra
		    */
		    If SubStr(AllTrim(aCols[nX][nPosPro]) ,1,2) == 'AM'
		    	aCols[nX][nPosTes] := "525"
		    EndIf
			
			dbSelectArea("TRB") 
			dbCloseArea()
		Else
		
			If Empty(aCols[nX][nPosCla])
				cClassif := "P"
			Else
				cClassif := aCols[nX][nPosCla]
			EndIf
		
			cQuery  := " SELECT DA1_PRCVEN 
			cQuery  += "   FROM DA0010 DA0 
			cQuery  += "        INNER JOIN DA1010 DA1 
			cQuery  += " ON (DA0_CODTAB = DA1_CODTAB)
			
			If SubStr(AllTrim(aCols[nX][nPosPro]) ,1,2) <> 'AM'
				cQuery  += "  WHERE DA1_CODTAB IN ('"+ M->C5_TABELA +"')
				cQuery  += "    AND DA1_CODPRO = '"+aCols[nX][nPosPro]+"'
			Else
				cQuery  += "  WHERE DA1_CODPRO = '"+aCols[nX][nPosPro]+"'
			EndIf
	
			cQuery  += "    AND DA0.D_E_L_E_T_ = ''
			cQuery  += "    AND DA1.D_E_L_E_T_ = ''
			
			tcQuery cQuery alias TRB new
			dbSelectArea("TRB")
			dbgotop()
			
		    aCols[nX][nPosPrc] := IIF(EMPTY(TRB->DA1_PRCVEN),0,TRB->DA1_PRCVEN) 
		    aCols[nX][nPosPun] := IIF(EMPTY(TRB->DA1_PRCVEN),0,TRB->DA1_PRCVEN) //BRUNO TESTE TB_PREÇO 23/09/2019
			
			/*
		    Classificação Amostra
		    */
		    If AllTrim(cClassif) $ 'A'
		    	aCols[nX][nPosTes] := "525"	
		    EndIf
		    
		    /*
		    Produto Amostra
		    */
		    If SubStr(AllTrim(aCols[nX][nPosPro]) ,1,2) == 'AM'
		    	aCols[nX][nPosTes] := "525"
		    EndIf
		    
			dbSelectArea("TRB") 
			dbCloseArea()
		EndIf
	Else
	//Se for pedido de venda para terceiros 
	//SEMPRE TABELA 100
	
		cQuery  := " SELECT DA1_PRCVEN 
		cQuery  += "   FROM DA0010 DA0 
		cQuery  += "        INNER JOIN DA1010 DA1 
		cQuery  += " ON (DA0_CODTAB = DA1_CODTAB)
		cQuery  += "  WHERE DA1_CODTAB IN ('100')
		cQuery  += "    AND DA1_CODPRO = '"+aCols[nX][nPosPro]+"'
		cQuery  += "    AND DA0.D_E_L_E_T_ = ''
		cQuery  += "    AND DA1.D_E_L_E_T_ = ''
		
		tcQuery cQuery alias TRB new
		dbSelectArea("TRB")
		dbgotop()
		
		aCols[nX][nPosPrc] := IIF(EMPTY(TRB->DA1_PRCVEN),0,TRB->DA1_PRCVEN) 
		//aCols[nX][nPosRef] := IIF(EMPTY(TRB->DA1_PRCVEN),0,TRB->DA1_PRCVEN)
		aCols[nX][nPosPun] := IIF(EMPTY(TRB->DA1_PRCVEN),0,TRB->DA1_PRCVEN) ////BRUNO TESTE TB_PREÇO 23/09/2019
		aCols[nX][nPosTes] := GETMV("GR_TSREMES")
		
		dbSelectArea("TRB") 
		dbCloseArea()
	
	EndIf


Next nX

Return(aCols)