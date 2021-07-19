#INCLUDE "rwmake.ch"   
#include "protheus.ch"  
#INCLUDE "topconn.ch"

/*                                          
Programa ...: MT103FIN.Prw
Uso ........: Ponto de Entrada 
Data .......: 30/04/18
Feito por ..: Bruno Lage Ferreira.
*/

User function MT103FIN()
***********************************************************************************************************
*  
*
***    	
Local lRet       := .t.
Local lDuplic    := .F.
Local aMT103FIN  := GetArea()

Private aLocHead := PARAMIXB[1]      // aHeader do getdados apresentado no folter Financeiro.
Private aLocCols := PARAMIXB[2]      // aCols do getdados apresentado no folter Financeiro.
Private lLocRet  := PARAMIXB[3]      // Flag de validações anteriores padrões do sistema. 


	For nX:=1 to Len(aCols) 
		dbSelectArea("SF4")
		dbSetOrder(1)
		dbSeek(xFilial("SF4")+AllTrim(acols[nX][aScan(aHeader,{|x|alltrim(x[2])=="D1_TES"})]))

		IF SF4->F4_DUPLIC == "S" .OR. lDuplic == .T. 
			lDuplic := .T.
		EndIf

	Next nX

	IF lDuplic == .T.
		/*
		Validacao padrao
		*/
		IF u_mXdtVal("MT103FIN") == .F.
			Alert("Data do vencimento e menor que 05 dias!")
			lRet := .F.
		EndIf
	EndIf

RestArea(aMT103FIN)

return(lRet)