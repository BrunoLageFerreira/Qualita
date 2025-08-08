#INCLUDE "RWMAKE.CH"
/* ####################################################################### *\
|| #           PONTO DE ENTRADA UTILIZADO PELO IMPORTADOR GATI           # ||
|| #                                                                     # ||
|| #         FORÇA A INCLUSÃO DA CHAVE NO CONHECIMENTO DE FRETE          # ||
\* ####################################################################### */

User Function MT116GRV()
/**********************************************************************************************************************
*
*
*******/
Local Usuario   := ""
//Ponto de entrada para o Conexão NF-e
U_GTPE008()

ConOut("*****************************")
ConOut("MT116GRV()")
ConOut(SUBSTR(CUSUARIO,7,15)+" "+TRIM(DTOC(DATE()))+" "+TRIM(TIME())+" "+TRIM(COMPUTERNAME()))
ConOut("*****************************")

Usuario := SUBSTR(CUSUARIO,7,15)+" "+TRIM(DTOC(DATE()))+" "+TRIM(TIME())+" "+TRIM(COMPUTERNAME())

IF INCLUI  
	If RecLock("SF1",.F.) 

		ConOut("*****************************")
		ConOut(Usuario)   
		ConOut("MT116GRV() Entrou")
		ConOut("*****************************")
	
		Replace F1_INCUSER With Usuario 
		MsUnLock()
	EndIf
ENDIF

Return
