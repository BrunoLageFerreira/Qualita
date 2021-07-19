#include 'TopConn.CH'
#include 'RWMAKE.CH'
#include 'TbiConn.CH'
#INCLUDE "PROTHEUS.CH"    
  
/*                                          
Programa ...: MNTA420P.Prw
Uso ........: ENVIO POR EMAIL APOS SALVAR MANUTENÇÃO CORRETIVA
Data .......: 18/06/2021
Feito por ..: Bruno Lage Ferreira 
*/

User Function MNTA420P()
***********************************************************************************************************
*  Modulo de MANUTENÇÃO mnt
*
*** 
// Parâmetro
nOPCX := ParamIxb[1] // Inclusão, Alteração ou Exclusão

If nOPCX == 3
    //MsgInfo("Inclusão de O.S. Realizada." + M->TJ_ORDEM)
    TCSPEXEC("SP_SENDMAIL_SEPARA_SA",M->TJ_ORDEM,'INCLUSÃO')
ElseIf nOPCX == 4
    //MsgInfo("Alteração de O.S. Realizada." + M->TJ_ORDEM)
    TCSPEXEC("SP_SENDMAIL_SEPARA_SA",M->TJ_ORDEM,'ALTERAÇÃO')
ElseIf nOPCX == 5
    //MsgInfo("Cancelamento de O.S.")
    TCSPEXEC("SP_SENDMAIL_SEPARA_SA",M->TJ_ORDEM,'CANCELAMENTO')
EndIf

Return .T.
