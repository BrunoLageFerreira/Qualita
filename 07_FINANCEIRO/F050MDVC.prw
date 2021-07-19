#INCLUDE "RWMAKE.CH"

/*
Programa ...: F050MDVC.Prw
Uso ........: F050MDVC.Prw - força para que os pagamentos dos impostos sejam feitos para o mes posterior 
Data .......: 26/03/2020
Feito por ..: Bruno Lage Ferreira
Copyright @1998-2001,2020
*/ 

User function F050MDVC()
*********************************************************************************************************
*
*
****
Local dNextDay  := ParamIxb[1] 
Local cIMposto  := ParamIxb[2]
Local dEmissao  := ParamIxb[3]
Local dEmis1    := ParamIxb[4]
Local dVencRea  := ParamIxb[5]
Local nNextMes  := Month(dEmis1)+1
Local aF050MDVC := GetArea()

If cImposto $ "PIS,CSLL,COFINS,ISS,IRRF,INSS" 
	dNextDay := CTOD("20/" + Iif(nNextMes==13,"01",StrZero(nNextMes,2)) + "/" + Substr(Str(Iif(nNextMes==13,Year(dVencRea)+1,Year(dVencRea))),2))
	
	//ISS POSTERGA A DATA DE VENCIAMENTO
	//OS DEMAIS ANTECIPAM 
	If cImposto $ "ISS"
		dNextday := DataValida(dNextday,.T.)
	Else
		dNextday := DataValida(dNextday,.F.)
	EndIf

EndIf

RestArea(aF050MDVC)

Return(dNextDay)
