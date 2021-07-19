#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
#INCLUDE "topconn.ch"          

/*
Programa ...: F380CPOS.Prw 
Data .......: 19/03/2021
Feito por ..: Bruno Lage Ferreira
Copyright @1998-2001,2021
*/ 

User Function F380CPOS()
/**********************************************************************************************************************
*
*
*
***/
Local aCPOCust := {} 
Local nX       := 0

For nX := 1 to Len(PARAMIXB[1])
    If nx == 4
        aAdd(aCPOCust,{ "E5_DTCANBX"        ,, OemToAnsi("Dt.Can BX") })
        aAdd(aCPOCust,{ PARAMIXB[1][nX][1]  ,, PARAMIXB[1][nX][3] })
    Else
        aAdd(aCPOCust, aClone(PARAMIXB[1][nX])   )  
    EndIf
Next nX 

Return(aCPOCust)
