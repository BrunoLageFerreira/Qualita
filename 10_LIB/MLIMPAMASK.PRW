#include "protheus.ch"
#include "rwmake.ch"
#include "tbiconn.ch"  
#INCLUDE "TOTVS.CH"
#INCLUDE "topconn.ch"


/*
Programa ...: MLIMPAMASK.Prw
Uso ........: Busca de dados sem os pontos 
Data .......: 21/10/2019
Feito por ..: Bruno Lage Ferreira
Copyright @1998-2001,2019
*/ 

User Function MLIMPAMASK(cTabela,cCodigo,cCPO) 
************************************************************************************************************
* U_MLIMPAMASK("SED","")
* U_MLIMPAMASK("SED",M->ZB_NATFIN,"ZB_NATFIN")                                                                                    
*
***
Local cCodRet := "" 
Local cQuery  := ""

If cTabela == "SED"
	cQuery   := " SELECT TOP 1 ED_CODIGO COD FROM " + RetSqlName("SED") + " WHERE D_E_L_E_T_ = '' 
	cQuery   += " 	 AND (REPLACE(ED_CODIGO,'.','') LIKE '"+AllTrim(cCodigo)+"' OR ED_CODIGO = RTRIM(LTRIM('"+AllTrim(cCodigo)+"'))  )
EndIf 

If cTabela == "CTT"
	cQuery   := " SELECT TOP 1 CTT_CUSTO COD FROM " + RetSqlName("CTT") + " WHERE D_E_L_E_T_ = ''
	cQuery   += "    AND (REPLACE(CTT_CUSTO,'.','') LIKE '"+AllTrim(cCodigo)+"' OR CTT_CUSTO = RTRIM(LTRIM('"+AllTrim(cCodigo)+"'))  )
EndIf
                                                          
tcQuery cQuery alias TRB new
dbSelectArea("TRB")
dbgotop()

M->&cCPO := TRB->COD

dbSelectArea("TRB") 
dbCloseArea()

Return(.t.)