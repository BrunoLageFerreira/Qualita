#Include "rwmake.ch"
#Include "Colors.ch"
#Include "Protheus.ch"  
#Include "Topconn.ch"
    
/*
Programa ...: MA900MNU.Prw
Uso ........: ACERTO FISCAL
Data .......: 02/09/2021
Feito por ..: Bruno Lage Ferreira
Copyright @1998-2001,2021
Atualizado..: 24/08/2021

MATA900

Nome do Arquivo:
MV_ULIVLIB
*/    

User Function MA900MNU()
***********************************************************************************
*
*//IIF(MV_ULIVLIB 
***
Local lRet          := .T.
Local aAreaMA900MNU := GetArea()
Local cULiberado    := GetMV("MV_ULIVLIB")

	IF (!RetCodUsr() $ cULiberado )

        aRotina := {	{ "Pesquisar","AxPesqui"	, 0 , 1,0,.F.},; 
                        { "Visualizar","A900Visual"	, 0 , 5,0,NIL} }
	
    EndIf

	RestArea(aAreaMA900MNU)

Return(lRet)
