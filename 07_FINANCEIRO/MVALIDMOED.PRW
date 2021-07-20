#include "rwmake.ch"

/*                                          
Programa ...: MVALIDMOED.Prw
Uso ........: Validação de moedas no titulo de recebimento específico para RA outras moedas
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
Validação Padrão do campo 
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
