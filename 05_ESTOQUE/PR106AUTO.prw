#include "protheus.ch"
#include "rwmake.ch"
#include "tbiconn.ch"  
#INCLUDE "TOTVS.CH"

/*                                          
Programa ...: PR106AUTO.Prw
Uso ........: Gera pre-requisição 
Data .......: 20-09-2022
Feito por ..: Bruno Lage Ferreira.

MaSAPreReq
*/

User Function PR106AUTO()
/****************************************************************************************************
*
*
****/    
Local aemp := {"01","01"}


PREPARE ENVIRONMENT EMPRESA aemp[1] filial aemp[2] USER 'Administrador' PASSWORD 'xpacD99label' TABLES "SB2","SCQ","SC1","SAI" MODULO "EST"

Pergunte("MTA106",.F.)
If AliasInDic("SCW")
     cFiltraSCP := "CP_STATSA <> 'B' "
Else  
     cFiltraSCP := ""
EndIf

PARAMIXB1   := .F.
PARAMIXB2   := MV_PAR01==1
PARAMIXB3   := If(Empty(cFiltraSCP), {|| .T.}, {|| &cFiltraSCP})
PARAMIXB4   := MV_PAR02==1
PARAMIXB5   := MV_PAR03==1
PARAMIXB6   := MV_PAR04==1
PARAMIXB7   := MV_PAR05
PARAMIXB8   := MV_PAR06
PARAMIXB9   := MV_PAR07==1
PARAMIXB10  := MV_PAR08==1
PARAMIXB11  := MV_PAR09
PARAMIXB12  := .T.

MaSAPreReq(PARAMIXB1,PARAMIXB2,PARAMIXB3,PARAMIXB4,PARAMIXB5,PARAMIXB6,PARAMIXB7,PARAMIXB8,PARAMIXB9,PARAMIXB10,PARAMIXB11,PARAMIXB12)

RESET ENVIRONMENT

Return Nil
