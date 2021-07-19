#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
#INCLUDE "topconn.ch"          

/*
Programa ...: FA040DEL() 
Uso ........: Grava dados adicionais na SE1 para contabilização do Abatimento ab-
Data .......: 25/06/2021
Feito por ..: Bruno Lage Ferreira
Copyright @1998-2001,2021
*/


User Function FA040DEL()
***********************************************************************************
* EXCLUSÃO DO AB-
*
***
Local aArea := GetArea()

/*
EXCLUSÃO DO AB-
*/ 
IF M->E1_TIPO == "AB-"
    dbSelectArea("SE1")
    dbSetOrder(2) 
    IF dbSeek(SE1->E1_FILIAL + SE1->E1_CLIENTE + SE1->E1_LOJA + SE1->E1_PREFIXO + SE1->E1_NUM + SE1->E1_PARCELA )
        SE1->(RecLock("SE1",.F.))
            E1_XVLABAT := 0
            E1_XSEQABA := ""
        SE1->(MsUnlock()) 
    EndIf

EndIf

RestArea(aArea)
Return()

