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
Local cId := ParamIXB[1]
Local cNome := ParamIXB[2]

//ApMsgAlert("Usuário "+ cId + " - " + Alltrim(cNome)+" efetuou login às "+Time())

Return()


User Function PSWDATE()
    Local _aParixb := PARAMIXB
    Local _lRet := .T.
 
 //   VarInfo('_aParixb', _aParixb , , .F. )
     
Return(_lRet)

