#include 'TopConn.CH'
#include 'RWMAKE.CH'
#include 'TbiConn.CH'
#INCLUDE "PROTHEUS.CH"    
  
/*                                          
Programa ...: MNTA990A.Prw
Uso ........: PROGRAMA PARA VALIDACAO DA TELA DE PROGRAMÇÃO DE MANUTENÇÃO MNT
Data .......: 16/06/2021
Feito por ..: Bruno Lage Ferreira 
*/

User Function MNTA990A()
***********************************************************************************************************
*  Modulo de MANUTENÇÃO mnt
*
*** 

oScrDlg1 := PARAMIXB[1]

oBtnInsuPr := TBtnBmp():NewBar("ng_ico_imp","ng_ico_imp",,,,{|| u_RelInWeb("RQ0033","Mapa de Compras X Solicitações")  },,oScrDlg1,,,"Mapa de Compras X Solicitações",,,,,"") "
oBtnInsuPr:Align := CONTROL_ALIGN_TOP
oBtnInsuPr:lVisible := .T.

Return oScrDlg1



