#include "protheus.ch"
#include "topconn.ch"
/*
{Protheus.doc} A330DECC
PE C.custo 
@author Nilton (TOTVS)
@since 14/07/2022
@version 1.0
*/
User Function A330DECC()
	Local cCod      := PARAMIXB[1]
	Local dDataFim  := PARAMIXB[2]
	Local cGrupo    := PARAMIXB[3]
	Local lGrupo    := PARAMIXB[4]
	Local atemp
	Local nqte      := 0
	Local cperiodo  := PADL(Alltrim(Str(Month(dDataFim))),2,"0") + "/"+Alltrim(Str(Year(dDataFim)))
	atemp := fA330Sal(cCod,dDataFim,cGrupo,lGrupo) //Funcao padrao TOTVS calculo custo
	//B1_TIPO = 'MO'
	If Posicione("SB1",1,xFilial("SB1")+CCODPESQ,"B1_TIPO") == "MO"
		If Posicione("SB1",1,xFilial("SB1")+CCODPESQ,"B1_PRV1") > 0 //Achou valor fixo para valorizar
			nqte := ABS(fQtdSB2(CCODPESQ))
			atemp[1] := nqte * Posicione("SB1",1,xFilial("SB1")+CCODPESQ,"B1_PRV1")
		ElseIf Posicione("SZG",1,xFilial("SZG")+cperiodo+cCod,"ZG_VALOR") > 0
			atemp[1] := Posicione("SZG",1,xFilial("SZG")+cperiodo+cCod,"ZG_VALOR")
		EndIf
	EndIf
Return atemp
/*
{Protheus.doc} fA330Sal
Funcao padrao para trazer o valor do centro de custos
@author Nilton (TOTVS)
@since 14/07/2022
@version 1.0
*/
Static Function fA330Sal(cCod,dDataFim,cGrupo,lgrupo)
	Local aSaldos[5]
	Local ncont := 0
	Local dDataIni := GetMV("MV_ULMES")
	AFILL(aSaldos,0)
	cCod := padr(cCod,Len(CTT->CTT_CUSTO))
	For nCont := 1 To 5
		// Verifica se moeda devera ser considerada
		If nCont # 1 .And. !(Str(nCont,1,0) $ cMV_MOEDACM)
			Loop
		EndIf
		//-- Somo o saldo atual DEBITO - CREDITO
		cQuery := "SELECT SUM(CQ3.CQ3_DEBITO) DEBITO, SUM(CQ3.CQ3_CREDIT) CREDITO "
		cQuery += " FROM "+RetSqlName("CQ3")+" CQ3 "
		cQuery += " WHERE EXISTS(SELECT CT1_CONTA FROM "+RetSqlName("CT1")
		cQuery += " WHERE CT1_FILIAL = '" + xFilial("CT1") + "' AND "
		//-- Considera grupo na filtragem caso tenha conteudo definido
		If !Empty(cGrupo) .And. lGrupo
			cQuery += " CT1_GRUPO = '"+cGrupo+"' AND "
		EndIf
		cQuery += "CT1_CONTA = CQ3.CQ3_CONTA AND D_E_L_E_T_ = ' ') AND "
		If !lCusEmp
			cQuery += "	CQ3.CQ3_FILIAL ='"+xFilial("CQ3")+"' AND "
		Else
			If FWSM0Layout() <> "FF"
				cQuery += cFuncSubs+"(CQ3.CQ3_FILIAL,1,"+cvaltochar(len(fwcodemp()))+") = '"+FwCodEmp()+"' And "
			EndIf
		EndIf
		cQuery += " CQ3.CQ3_CCUSTO = '" + cCod + "' AND "
		cQuery += "CQ3.CQ3_MOEDA ='"+StrZero(nCont,2)+"' AND "
		cQuery += "CQ3.CQ3_TPSALD ='1' AND "
		cQuery += "CQ3.D_E_L_E_T_ = ' ' AND "
		cQuery += "CQ3.CQ3_DATA >= '"+DTOS(dDataIni+1)+"' AND "
		cQuery += "CQ3.CQ3_DATA <= '"+DTOS(dDataFim)+"'"
		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"SLDATU",.T.,.F.)
		aSaldos[nCont] 	+= (SLDATU->DEBITO - SLDATU->CREDITO)
		DbCloseArea()
	Next nCont
Return aSaldos
/*
{Protheus.doc} fQtdSB2
Trazer a quantidade encontrada como saldo final do MOD/CCUSTO
@author Nilton (TOTVS)
@since 14/07/2022
@version 1.0
*/
Static Function fQtdSB2(cCod)
Local aArea    := GetArea()
Local cSql     := ""
Local nret     := 0

csql := " SELECT SUM(B2_QFIM) TOTPESO"+CHR(10)
csql += " from " + RetSqlName("SB2")+" SB2 WITH (NOLOCK)"+CHR(10)
csql +=  " where SB2.B2_FILIAL =  '"+xFilial("SB2")+"' " +CHR(10)
csql +=  " and SB2.B2_COD = '"+cCod+"'"+CHR(10)
csql +=  " and SB2.D_E_L_E_T_ = ' '  "+CHR(10)
TcQuery csql New Alias "ctrabalho"
DbGotop()

If !eof()
	nret := ctrabalho->TOTPESO
EndIf

ctrabalho->(DbCloseArea())
RestArea(aArea)
Return(nret)
