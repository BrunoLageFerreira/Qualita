#include "rwmake.ch"

/*                                          
Programa ...: MVALIDMOED.Prw
Uso ........: Valida��o de moedas no titulo de recebimento espec�fico para RA outras moedas
Data .......: 20/07/2021
Feito por ..: Bruno Lage Ferreira.
*/

User Function MVALIDMOED()
****************************************************************************************************
*
*
***
lRet := .F.

/*
Valida��o Padr�o do campo 
*/
If WTxMoe(M->E1_MOEDA) 
    lRet := .T.
Else 
    If (M->E1_TIPO == "RA" .AND. M->E1_MOEDA <> 1)
        lRet := .T.
    else
        lRet := WTxMoe(M->E1_MOEDA)
    EndIf
EndIf

Return(lRet)
