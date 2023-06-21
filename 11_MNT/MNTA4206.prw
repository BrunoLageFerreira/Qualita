#Include 'Protheus.ch'

/*

Arlindo 23/02/2022 - 
#3844 - Aplicar Fonte Centro de Custo OS Corretiva
Gatilho
TJ_CODBEMIF(U_MNT420CUST)  

*/


User Function MNTA4206()
/*****************************************************************************************************************************************
*
*
***/
         AAdd(aChoice,"TJ_CCUSTO")
         AAdd(aChoice,"TJ_OBSERVA")
Return (.T.)

/*
Arlindo 27/02/2022 - 
#3856 - Campo centro de custo
Gatilho
TJ_CODBEMIF

*/
User Function QMNT420CUS()
/*****************************************************************************************************************************************
*
*
***/
Local CentroCCU := ""

IF M->TJ_TIPOOS="B"     
    CentroCCU := POSICIONE('ST9',1,XFILIAL('ST9')+M->TJ_CODBEM,"T9_CCUSTO")
ELSE
    CentroCCU := POSICIONE('TAF',1,XFILIAL('TAF')+M->TJ_CODBEM,"TAF_CCUSTO")
ENDIF

Return (CentroCCU)



User Function MNTA4207()
/*****************************************************************************************************************************************
*
*
***/

 
Local lRet := .T.
    
    IF EMPTY(M->TJ_OBSERVA)
        
           ALERT("PREENCHER A OBSERVAÇÃO")
           lRet := .F.
         
    ENDIF
     
Return lRet
