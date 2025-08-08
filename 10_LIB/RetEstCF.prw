#include "RWMAKE.ch"
#include "Colors.ch"
#include "Font.ch"
#Include "HBUTTON.CH"
#include "Topconn.ch"
#Include "Protheus.ch"
#include "tbiconn.ch"
#include "totvs.ch"

/*
Programa ...: RetEstCF.Prw
Uso ........: Valida o estado do cliente ou fornecedor
Data .......: 09/11/2024
Feito por ..: Bruno Lage Ferreira   (33)8402-2125
Email.......: sigawise@gmail.com
Copyright ..: @1998-2001,2024
*/

User Function RetEstCF(cCodLoja,cTipoNf)
************************************************************************************************
*
* /* Programa Princial*/
***
Local cCodEstado := ""

If AllTrim(cTipoNF) $ "DB"
    cCodEstado := POSICIONE("SA1",1,XFILIAL("SA1")+cCodLoja,"A1_EST")
else
    cCodEstado := POSICIONE("SA2",1,XFILIAL("SA2")+cCodLoja,"A2_EST")
EndIf 

Return(cCodEstado) 
