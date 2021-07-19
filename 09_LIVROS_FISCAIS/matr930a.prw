#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"

/*
Programa ...: MATR930A.Prw
Uso ........: campo observações matr930
Data .......: 10/05/2019
Feito por ..: Bruno Lage Ferreira 
*/

User Function MATR930A()
****************************************************************************************************************
* /*    Programa inicial */  
*
****
Local aOBSERV := ParamIXB[1] 
LOCAL cRet    := ""
LOCAL aArea   := GetArea()
LOCAL cSeek1  := ""
LOCAL cSeek2  := ""

If empty(F3_TIPO) 
	cSeek1 := ""
ElseIf F3_TIPO $ "DB"
	SA1->(dbSeek(xFilial("SA1") + (aArea[1])->F3_CLIEFOR + (aArea[1])->F3_LOJA ))
	cSeek1 := Substr(SA1->A1_NOME,1,30)
Else             
	SA2->(dbSeek(xFilial("SA2") + (aArea[1])->F3_CLIEFOR + (aArea[1])->F3_LOJA ))
	cSeek1 := Substr(SA2->A2_NOME,1 ,17)
	cSeek2 := Substr(SA2->A2_NOME,18,17)
EndIf  
 
If !Empty(LEN(aOBSERV))
	AADD(aOBSERV,{AllTrim(cSeek1),.t.})
	iF !EMPTY(cSeek2)
		AADD(aOBSERV,{AllTrim(cSeek2),.t.})
	EndIf
	//aOBSERV[1][1] := AllTrim(cSeek1)  
Else
	AADD(aOBSERV,{cSeek1,.t.}) 
	iF !EMPTY(cSeek2)
		AADD(aOBSERV,{AllTrim(cSeek2),.t.})
	EndIf
EndIf


RestArea(aArea)
	
Return(aOBSERV)  