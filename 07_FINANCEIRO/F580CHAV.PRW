#include "rwmake.ch"
#include "TOPCONN.CH"
#Include 'Protheus.ch'

/*                                          
Programa ...: F580CHAV.Prw
Uso ........: Ponto de Entrada (ORDENA��O TELA DE LIBERA��O)
Data .......: 30/05/23
Feito por ..: Bruno Lage Ferreira.
*/


User Function F580CHAV()
*************************************************************************************************************
*
*
*** 
Local  cChave		:= "E2_FILIAL+E2_NUM+E2_PARCELA+E2_TIPO"

Return(cChave)