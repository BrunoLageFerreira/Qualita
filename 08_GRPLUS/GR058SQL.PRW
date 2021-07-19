#INCLUDE "Protheus.ch"
#INCLUDE "RwMake.ch"
#INCLUDE "topconn.ch"

/*
Programa ...: GR058SQL.Prw
Uso ........: Filtro para tela de transferencia não pegar os Bundles
Data .......: 11/01/2021
Feito por ..: Bruno Lage Ferreira
Copyright @1998-2001,2021
*/ 

User Function GR058SQL()
*********************************************************************************************************
*
*
***
Local cWhere := PARAMIXB[1]

cWhere += " AND SB8.B8_ORIGLAN <> 'BD' "

Return cWhere
