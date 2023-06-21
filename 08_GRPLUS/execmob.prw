#INCLUDE "PROTHEUS.CH"



User Function AltPedMB()

	Local aSC5      := {}
	Local aSC6      := {}
	Local aCabec    := {}
	Local aItens    := {}
	Local aLinha    := {}
	Local nX        := 0
	Local nY        := 0
	Local cLogErro  := ""
	Local nCount    := 0
	Local aCabec    := {}
	Local aItens    := {}
	Local aLinha    := {}
	Local lOk       := .T.
	Local nOpcx     := 0
	Local cPedido   := ""
	Local cJsonRet	:= ""
	Local nLen      := 0
	Local nPosItem  := 0
	Local zx := 0

	Private lMsErroAuto	   := .F.
	Private lMsHelpAuto	   := .T.
	Private lAutoErrNoFile := .f. 

	aAdd(aCabec, {"c5_CLIENTE","000279", Nil})
	aAdd(aCabec, {"c5_LOJACLI","01"    , Nil})
	aAdd(aCabec, {"c5_NUM"    ,"005546", Nil})

	aLinha := {}
    //ITEM 01
	aAdd(aLinha, {"c6_ITEM","01", Nil})
	aAdd(aLinha, {"c6_PRODUTO","CHGR0001030PL", Nil})

	aAdd(aLinha, {"c6_YCAVALE","034589" , Nil})
	aAdd(aLinha, {"c6_YCLASSI","P"      , Nil})
	aAdd(aLinha, {"c6_LOTECTL","006105P", Nil})
	aAdd(aLinha, {"c6_QTDVEN",1         , Nil})
	aAdd(aLinha, {"c6_PRCVEN",1         , Nil})
	aAdd(aLinha, {"c6_VALOR",1          , Nil})
	aAdd(aLinha, {"c6_XPESO",0.0, Nil})
	aAdd(aLinha, {"c6_LOCAL","03", Nil})
	aAdd(aLinha, {"c6_NUMLOTE","034589", Nil})
	aAdd(aLinha, {"aUTDELETA","N", Nil})
	aAdd(aLinha, {"c6_XOFERTA","S", Nil})
	aAdd(aItens, aLinha)

    nOpcx := 4 

	MSExecAuto({|a, b, c, d| MATA410(a, b, c, d)}, aCabec, aItens, nOpcx, .F.)

	If !lMsErroAuto

		cPedido := SC5->C5_NUM
        MsgAlert(" incluido com sucesso! ", "ALTERADO")
		ConOut("API_GR => Pedido " + cPedido + " incluido com sucesso! ")

	Else

		
        mostraErro()		

	EndIf


Return
