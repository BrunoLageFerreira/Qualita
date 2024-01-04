#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
#INCLUDE "TOPCONN.CH"

/*                                          
Programa ...: FA450BUT.Prw
Uso ........: BLOQUEIA A AÇÃO DE CANCELAMENTO DO FINA450
Data .......: 29/08/23
Feito por ..: Bruno Lage Ferreira.
*/

user function FA450BUT()
/****************************************************************************************************
* //
*
****/     
Local aRotina:=ParamIxb[1]

arotina[4][2] := "Alert('Funcionalidade desativada. Use a função estornar!')"

Return(aRotina)
