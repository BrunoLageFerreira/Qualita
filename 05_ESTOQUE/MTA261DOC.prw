#Include "Totvs.ch"
#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
#INCLUDE "topconn.ch"

#DEFINE USADO CHR(0)+CHR(0)+CHR(1)

/*
Programa ...: MTA261DOC.Prw
Uso ........: Validação do documento de transferencia
Data .......: 07/08/2019
Feito por ..: Bruno Lage Ferreira 
*/

User Function MTA261DOC()
***********************************************
* /* Proibe o usuario alterar o numero do doc*/
*
****
Local lRet := .F.

Return(lRet)

User Function MSAtuaL()
***********************************************
* 
*
****
Local nSalEstL1 := 0
Local nSalEstL2 := 0
Local cQuery    := ""

If SubString(CNUMEMP,1,2) == "01" .And. FUNNAME() == "MATA261"
	If !Empty(GdFieldGet("D3_LOTECTL",n)) .And. !Empty(GdFieldGet("D3_NUMLOTE",n))
	
		cQuery := "SELECT B8_SALDO,B8_SALDO2 FROM SB8010 WHERE D_E_L_E_T_ = '' AND B8_FILIAL = '" + xFilial("SB8") +  "' AND B8_SALDO <> 0 AND B8_PRODUTO = '"+GdFieldGet("D3_COD",n)+"' and B8_LOCAL = '"+GdFieldGet("D3_LOCAL",n)+"' AND B8_LOTECTL = '"+GdFieldGet("D3_LOTECTL",n)+"' AND B8_NUMLOTE = '"+GdFieldGet("D3_NUMLOTE",n)+"'
	
		tcQuery cQuery alias TRBEST new
		dbSelectArea("TRBEST")
		dbgotop()
		
		nSalEstL1 := TRBEST->B8_SALDO
		nSalEstL2 := TRBEST->B8_SALDO2
		
		dbSelectArea("TRBEST") 
		dbCloseArea()
		
		GdFieldPut("D3_QUANT"   ,nSalEstL1,n)
		GdFieldPut("D3_QTSEGUM" ,nSalEstL2,n)
		GdFieldPut("D3_YCAVALE" ,MCavaleAtu(GdFieldGet("D3_COD",n) , GdFieldGet("D3_LOCAL",n) , GdFieldGet("D3_LOTECTL",n), GdFieldGet("D3_NUMLOTE",n)) ,n)
	EndIf
EndIf

Return(.T.)


Static Function MCavaleAtu(cCodPro,cLocal,cLote,cSubLote)
***************************************************
* // 
*
****
Local cCodCvte := ""
Local cQuery   := ""

cQuery   := "SELECT B8_YCAVALE FROM SB8010 WHERE D_E_L_E_T_ = '' AND B8_FILIAL = '" + xFilial("SB8") +  "' AND B8_LOTECTL = '"+cLote+"' AND B8_NUMLOTE = '"+cSubLote+"' AND B8_PRODUTO = '"+cCodPro+"' AND B8_LOCAL = '"+cLocal+"'

tcQuery cQuery alias TRB new
dbSelectArea("TRB")
dbgotop()

cCodCvte := TRB->B8_YCAVALE

dbSelectArea("TRB") 
dbCloseArea()


Return(cCodCvte)

User Function GMA261CP()
****************************************************
* // Manipulação pelo usuário do aHeader e aCols para inclusão de campos na getdados.
* // MA261CPO
****
Local aTam1 := {}
Local aTam2 := {}

aTam1 := TamSX3('D3_YCAVALE')  
aTam2 := TamSX3('D3_OBSERVA')  

If AllTrim(FUNNAME()) <> "GROA038"
	Aadd(aHeader, {'Cavalete' , 'D3_YCAVALE'   , PesqPict('SD3', 'D3_YCAVALE' ), aTam1[1]  , aTam1[2], '' , USADO, 'C', 'SD3', ''})
	Aadd(aHeader, {'OBS'      , 'D3_OBSERVA '  , PesqPict('SD3', 'D3_OBSERVA '), aTam2[1]  , aTam2[2], '' , USADO, 'C', 'SD3', ''})
EndIf

Return Nil


User Function GR261TOK()
****************************************************
* // Tudo OK?
* // A261TOK
****
Local lRet 	   := .T.
Local nX       := 0 

Local nPosCava := aScan(aHeader, {|x| AllTrim(x[2]) == "D3_YCAVALE"}) //Cavalete
Local nPosLOTE := aScan(aHeader, {|x| AllTrim(x[2]) == "D3_LOTECTL"}) //SubLote
Local nPosSUBL := aScan(aHeader, {|x| AllTrim(x[2]) == "D3_NUMLOTE"}) //Lote
Local cGPExec  := GetMv("MV_XGPEXE")


If IsBlind() 
	//COLOCADO PARA NAO VALIDAR NO MOMENTO DO ENCERRAMENTO DA OP NO GRPLUS
	ConOut("IsBlind()=.T.")
	Return(lRet)
Else
	ConOut("IsBlind()=.F. seguindo...")
EndIf

/*
****************************************************************
Validação para permitir que somente alguns usuários façam 
transferencias entre materiais, lotes para outros lotes
e sublotes para os mesmo outros sublotes.
CHAMADO = #5443
usuários liberados: Bruno/Arlindo/Eliana/Sara/Administrador
****************************************************************
*/
IF FUNNAME() == "MATA261"
	For nX := 1 To Len(aCols)
		If !GDDeleted(nX) .And. !__cUserID $ "000000/000056/000057/000125/000059"
			/*********************
			Produto diferentes
			Origem e Destino D3_COD
			**********************/
			If AllTrim(aCols[nX][1]) <> AllTrim(aCols[nX][6])
				lRet 	   := .F.
			Endif
			/**********************
			Lote e Sublotes diferentes
			Origem e Destino D3_LOTE + D3_SUBLOTE
			***********************/
			If AllTrim(aCols[nX][12])+AllTrim(aCols[nX][13]) <> AllTrim(aCols[nX][20])+AllTrim(aCols[nX][23])
				lRet 	   := .F.
			EndIf
		EndIf
	Next nX

	If lRet == .F.
		Alert("Você está tentando realizar uma alteração não permitida para seu usuário! [PE_GR261TOK]")
		Return(lRet)
	EndIf 
EndIf

/*
****************************************************************
Conferência dos cavaletes duplicados no proprio formulário
****************************************************************
*/
aNumCav 	:= {}		
aTodCav 	:= {}
aGriCav 	:= {}
aGriCavDup 	:= {}
aGriLSPv    := {}
aLSPvLoca   := {}	
aCavZero    := {}

For nX := 1 To Len(aCols)

	//EXECUTAR SOMENTE PARA ESTES GRUPOS 
	//"0005/0006/0034/0035/0036"
	dbSelectArea("SB1")
	dbSetOrder(1)
	dbSeek(xFilial("SB1")+ AllTrim(GdFieldGet("D3_COD",nX)) )
	
	IF AllTrim(SB1->B1_GRUPO) $ cGPExec 

		If !Empty(GdFieldGet("D3_YCAVALE",nX)) .and. !GDDeleted(nX)
			If Empty( aScan(aNumCav,GdFieldGet("D3_YCAVALE",nX)) )
			 	aAdd(aNumCav,GdFieldGet("D3_YCAVALE",nX))
			EndIf
		EndIf
		If !GDDeleted(nX)
			If Empty(aScan(aGriCav,GdFieldGet("D3_YCAVALE",nX) + GdFieldGet("D3_LOTECTL",nX) + GdFieldGet("D3_NUMLOTE",nX)) )
				aAdd(aGriCav , GdFieldGet("D3_YCAVALE",nX) + GdFieldGet("D3_LOTECTL",nX) + GdFieldGet("D3_NUMLOTE",nX)  )
				aAdd(aGriLSPv, {GdFieldGet("D3_LOTECTL",nX) , GdFieldGet("D3_NUMLOTE",nX) } )
			Else
				If !Empty(GdFieldGet("D3_YCAVALE",nX) + GdFieldGet("D3_LOTECTL",nX) + GdFieldGet("D3_NUMLOTE",nX))
					aAdd(aGriCavDup, GdFieldGet("D3_YCAVALE",nX) + GdFieldGet("D3_LOTECTL",nX) + GdFieldGet("D3_NUMLOTE",nX)  )
				EndIf
			EndIf
		EndIf
		
	EndIf
	
Next nX

cMSG := ""
For nX:=1 to Len(aGriCavDup)
		If Empty(cMSG)
			cMSG := "Duplicados na tela atual:" + chr(13)+chr(10) 
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
If SubString(CNUMEMP,1,8) == "01010101"
	For nX := 1 To Len(aNumCav)


		//EXECUTAR SOMENTE PARA ESTES GRUPOS 
		//"0005/0006/0034/0035/0036"
		dbSelectArea("SB1")
		dbSetOrder(1)
		dbSeek(xFilial("SB1")+ AllTrim(GdFieldGet("D3_COD",nX)) )
		
		IF AllTrim(SB1->B1_GRUPO) $ cGPExec

			cQuery  := "  SELECT B8_PRODUTO,B1_DESC,B8_YCAVALE,B8_LOTECTL,B8_NUMLOTE,B8_YCAVALE+B8_LOTECTL+B8_NUMLOTE CHAVE,B8_LOCAL,B8_SALDO 
			cQuery  += "    FROM SB8010 SB8 INNER JOIN SB1010 SB1 ON (B8_PRODUTO = B1_COD)
			cQuery  += "   WHERE SB8.D_E_L_E_T_ = ''
			cQuery  += "     AND SB1.D_E_L_E_T_ = ''
			cQuery  += "     AND B8_YCAVALE = '"+aNumCav[nX]+"'
			cQuery  += "     AND B8_ORIGLAN = 'BD'
					
			tcQuery cQuery alias TRB new
			dbSelectArea("TRB")
			dbgotop()
			Do While !EOF()
			
				/*
				cavaletes incompletos
				*/
				IF !aScan(aCols,{|x|x[nPosCava]+x[nPosLOTE]+x[nPosSUBL] == TRB->CHAVE })  
					aAdd(aTodCav,{ TRB->CHAVE , AllTrim(TRB->B1_DESC) , aNumCav[nX] , TRB->B8_LOTECTL , TRB->B8_NUMLOTE} )
				Else
					if GDDeleted(aScan(aCols,{|x|x[nPosCava]+x[nPosLOTE]+x[nPosSUBL] == TRB->CHAVE }))
						aAdd(aTodCav,{ TRB->CHAVE , AllTrim(TRB->B1_DESC) , aNumCav[nX] , TRB->B8_LOTECTL , TRB->B8_NUMLOTE} )
					EndIf 
				EndIf
				
				/*
				Sem Saldo
				*/	
				iF TRB->B8_SALDO == 0  
					aAdd(aCavZero,{ TRB->CHAVE ,AllTrim(TRB->B8_PRODUTO)+"-"+ AllTrim(TRB->B1_DESC) , aNumCav[nX] , TRB->B8_LOTECTL , TRB->B8_NUMLOTE} )
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
			
				IF !aScan(aCols,{|x|x[nPosCava]+x[nPosLOTE]+x[nPosSUBL] == TRB->CHAVE })  
					aAdd(aTodCav,{ TRB->CHAVE , AllTrim(TRB->B1_DESC) , aNumCav[nX] , TRB->B8_LOTECTL , TRB->B8_NUMLOTE} )
				Else
					if GDDeleted(aScan(aCols,{|x|x[nPosCava]+x[nPosLOTE]+x[nPosSUBL] == TRB->CHAVE }))
						aAdd(aTodCav,{ TRB->CHAVE , AllTrim(TRB->B1_DESC) , aNumCav[nX] , TRB->B8_LOTECTL , TRB->B8_NUMLOTE} )
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
		cMSG +=     "  ->" + AllTrim(aTodCav[nX][2]) + " Cav.[" + Alltrim(aTodCav[nX][3]) + "] Lote[" + Alltrim(aTodCav[nX][4]) + "] SubLote.[" + Alltrim(aTodCav[nX][5]) + "]"+ chr(13)+chr(10)   
	Next nX

	If !Empty(cMSG)
		Alert(cMSG)
		lRet := .F.
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
		Alert(cMSG)
		lRet := .F.
		Return(lRet) 
	EndIf

EndIf
/*
****************************************************************
Conferencia se existe estes Lote/SubLotes em um PVenda salvo
****************************************************************
*/


For nX := 1 To Len(aGriLSPv)
	 	
	//EXECUTAR SOMENTE PARA ESTES GRUPOS 
	//"0005/0006/0034/0035/0036"
	dbSelectArea("SB1")
	dbSetOrder(1)
	dbSeek(xFilial("SB1")+ AllTrim(GdFieldGet("D3_COD",nX)) )
	
	IF AllTrim(SB1->B1_GRUPO) $ cGPExec .AND. !Empty(aGriLSPv[nX][1])
	 	cQuery  := " SELECT C6_NUM,C6_ITEM,C6_LOTECTL,C6_NUMLOTE ,C6_DESCRI 
	 	cQuery  += "   FROM SC6010 SC6 INNER JOIN SC5010 SC5 ON (C5_FILIAL = C6_FILIAL AND C5_NUM = C6_NUM)
	 	cQuery  += "  WHERE SC6.D_E_L_E_T_ = ''
	 	cQuery  += "    AND SC5.D_E_L_E_T_ = ''
	 	cQuery  += "    AND C5_TIPO = 'N'
	 	cQuery  += " 	AND C6_LOTECTL = '"+aGriLSPv[nX][1]+"'
	 	cQuery  += " 	AND C6_NUMLOTE = '"+aGriLSPv[nX][2]+"'
	 	//cQuery  += "    AND C6_NUM <> '"+AllTrim(M->C5_NUM)+"'
	 	
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
	lRet := .F.
	Return(lRet) 
EndIf

	
Return(lRet)
