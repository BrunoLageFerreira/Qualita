#include 'TopConn.CH'
#include 'RWMAKE.CH'
#include 'TbiConn.CH'
#INCLUDE "PROTHEUS.CH"    
  
/*                                          
Programa ...: MNTA420P.Prw
Uso ........: ENVIO POR EMAIL APOS SALVAR MANUTEN��O CORRETIVA
Data .......: 18/06/2021
Feito por ..: Bruno Lage Ferreira 
*/

User Function MNTA420P()
***********************************************************************************************************
*  Modulo de MANUTEN��O mnt
*
*** 
// Par�metro
nOPCX := ParamIxb[1] // Inclus�o, Altera��o ou Exclus�o

If nOPCX == 3
    //MsgInfo("Inclus�o de O.S. Realizada." + M->TJ_ORDEM)
    TCSPEXEC("SP_SENDMAIL_SEPARA_SA",M->TJ_ORDEM,'INCLUS�O')
ElseIf nOPCX == 4
    //MsgInfo("Altera��o de O.S. Realizada." + M->TJ_ORDEM)
    TCSPEXEC("SP_SENDMAIL_SEPARA_SA",M->TJ_ORDEM,'ALTERA��O')
ElseIf nOPCX == 5
    //MsgInfo("Cancelamento de O.S.")
    TCSPEXEC("SP_SENDMAIL_SEPARA_SA",M->TJ_ORDEM,'CANCELAMENTO')
EndIf

Return .T.
