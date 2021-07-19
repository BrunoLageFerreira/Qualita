#include "protheus.ch"
#include "rwmake.ch"
#include "tbiconn.ch"  
#INCLUDE "TOTVS.CH"

/*
Programa ...: DoAfterLoginlar.Prw
Uso ........: Habilita o Shift F7
Data .......: 24/05/2021
Feito por ..: Bruno Lage Ferreira
Copyright @1998-2001,2021
*/

User Function AfterLogin()
    SetKey(K_SH_F7,  { || u_relin() })     //Shift + F7
Return

