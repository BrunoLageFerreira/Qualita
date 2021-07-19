#INCLUDE "TopConn.CH"
#INCLUDE "RWMAKE.CH"
#INCLUDE "PROTHEUS.CH"   
#INCLUDE "TBICONN.CH"
            
/*
Programa ...: MCONTNUM.Prw
Uso ........: CONTROLE DE NUMERACAO 
Data .......: 11/02/2019
Feito por ..: Bruno Lage Ferreira
Copyright @1998-2001,2019
*/ 

User Function MCONTNUM(cAlias,cVarEmp)
*************************************************************************************************
* U_MCONTNUM("SA1","01")
*
***
Local aUltNum :={}
Local cUltNum :=""
	
aUltNum := TCSPExec("SP_MCONTNUM",cAlias,cVarEmp)
cUltNum := soma1(aUltNum[1])

Return(cUltNum)