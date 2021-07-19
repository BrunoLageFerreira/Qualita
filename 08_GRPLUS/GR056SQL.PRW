#INCLUDE "Protheus.ch"
#INCLUDE "RwMake.ch"
#INCLUDE "topconn.ch"

/*
Programa ...: GR056SQL.Prw
Uso ........: Validação para edição de cavaletes
Data .......: 01/07/2021
Feito por ..: Bruno Lage Ferreira
Copyright @1998-2001,2021
*/ 

User Function GR056SQL()
************************************************************************************************
*
*
*****
Local cCavalete := PARAMIXB[1]
Local cSql      := PARAMIXB[2]

cSql := "   SELECT COUNT(C6_FILIAL) CONTADOR, C6_NUM "    
cSql += "     FROM " + RetSqlName("SC6") + " SC6 "    
cSql += "    WHERE SC6.C6_FILIAL  = '" + xFilial("SC6") + "' "    
cSql += "      AND SC6.C6_YCAVALE = '" + AllTrim(cCavalete) + "' "    
cSql += "      AND C6_NOTA = ''   
cSql += "      AND SC6.D_E_L_E_T_ = ''"    
cSql += " GROUP BY C6_NUM "

Return cSql
