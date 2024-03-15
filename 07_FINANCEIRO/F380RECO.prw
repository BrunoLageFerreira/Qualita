#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
#INCLUDE "topconn.ch"          

/*
Programa ...: F380RECO.Prw 
Data .......: 26/02/2024
Feito por ..: Bruno Lage Ferreira
Copyright ..: @1998-2001,2024

MV_USUREC customizado para usuarios nao validar a data limite
MV_DATAREC data limite da rec 
*/

User Function F380VLD()
/**********************************************************************************************************************
*
*
***/
Local lRet := .T.
Local dDataIni := PARAMIXB[2]

If dDataIni > GetMv("MV_DATAREC")
	lRet := .T.
Else
	Alert("Data de bloqueio financeiro! Confira a permissão da liberação com a Controladoria.")
	lRet := .F.
EndIf 

Return(lRet)


                                                                                                                                                                                                                      