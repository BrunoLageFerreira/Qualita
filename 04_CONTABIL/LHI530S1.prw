#INCLUDE "Protheus.CH"
    
/*
Programa ...: LHI530S1.Prw
Uso ........: Contabilidade Siga CTB
Data .......: 17/07/2012
Feito por ..: Bruno Lage Ferreira
Copyright @1998-2001,2012
Atualizado..: 24/08/2020

Nome do Arquivo:
L 	= Lancamento Padrao
HI 	= Historio do Lancamento
530 = Lancamento codigo 530
S1  = Sequencia 001
*/     

User Function LHI530S1()
*************************************************************************************************
*
*
***     
Local cRet := ""        
          
dbSelectArea("RC1")
dbSetOrder(3)
If dbSeek(xFilial("RC1") + Space(06) + SE2->E2_PREFIXO + SE2->E2_NUM + SE2->E2_PARCELA)
	If !Empty(RC1->RC1_MAT)
		
	  	dbSelectArea("SED")
	  	dbSetOrder(1) 
	  	dbSeek(xFilial("SED") + SE2->E2_NATUREZ)

		cRet := "PAG REF. " + AllTrim(SED->ED_DESCRIC)        		
	  	
	  	dbSelectArea("SRA")
		dbSetOrder(1)
		dbSeek(RC1->RC1_FILTIT + RC1->RC1_MAT)
	  		
	  	cRet := cRet + " " + SRA->RA_NOME		         
	  	
	EndIf
EndIf

Return(cRet)