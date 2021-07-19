#INCLUDE "Protheus.CH"
    
/*
Programa ...: LCD530S1.Prw
Uso ........: Contabilidade Siga CTB
Data .......: 17/07/2012
Feito por ..: Bruno Lage Ferreira
Copyright @1998-2001,2012
Atualizado..: 24/08/2020  
                   
Nome do Arquivo:
L 	= Lancamento Padrao
CD 	= Conta Debito
530 = Lancamento codigo 530
S1  = Sequencia 001
*/     

User Function LCD530S1()
*************************************************************************************************
*
*
***     
Local cRet := ""   

IF(SUBSTR(SE2->E2_ORIGEM,1,4) <> "FINA")	
	cRet :=  SA2->A2_CONTA
	
	If Empty(cRet)
		cRet :=  SED->ED_CONTA
	EndIf
	
	IF AllTrim(SE2->E2_TIPO) $ 'FOL/INS/FGT/131/132/'  
		cRet :=  SED->ED_CONTA
	EndIf                      
Else
	cRet :=  SA2->A2_CONTA
	
	If Empty(cRet)
		cRet :=  SED->ED_CONTA
	EndIf
	
	IF AllTrim(SE2->E2_TIPO) $ 'FOL/INS/FGT/131/132/'  
		cRet :=  SED->ED_CONTA
	EndIf    
EndIf


Return(cRet) 