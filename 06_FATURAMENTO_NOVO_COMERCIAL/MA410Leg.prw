#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"

/*
Programa ...: MA410Leg.Prw
Uso ........: Alteração da legenda
Data .......: 01/12/2021
Feito por ..: Bruno Lage Ferreira 
*/

User Function MA410Leg()
/*******************************************************************************************************
*
*
****/
Local aRet    := PARAMIXB

aRet[4][2] := "Pedido de Venda com Bloqueio Comercial." 
aRet[5][2] := "Pedido de Venda com Bloqueio Financeiro." 

Return(aRet)
