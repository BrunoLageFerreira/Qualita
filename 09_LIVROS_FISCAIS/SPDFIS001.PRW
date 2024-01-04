#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"

/*
Programa ...: MATR930A.Prw
Uso ........: campo observações matr930
Data .......: 10/05/2019
Feito por ..: Bruno Lage Ferreira 
*/

User Function SPDFIS001()
****************************************************************************************************************
* /*    Programa inicial */  
*
****
Local aTipo := ParamIXB[1]


/*
aTipo    :=    { {"ME|PA|MC","00"},;
                       {"MP","01"},;
                       {"MO","09"} }
*/

//ALERT("Ponto de entrada SPDFIS001")
//AADD(aTipo,{"XX","00"})

//aTipo[2][1] := "PI"

Return(aTipo)

