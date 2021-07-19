#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
#INCLUDE "topconn.ch"          

/*
Programa ...: SE5FI070() 
Uso ........: Grava dados adicionais na SE5 para contabilização
Data .......: 23/06/2021
Feito por ..: Bruno Lage Ferreira
Copyright @1998-2001,2021

E5_XTXFAT
E1_XSEQABA
E1_XSEQABA 
*/
User Function SE5FI070()
***********************************************************************************
*
*
***
Local aArea := GetArea()

dbSelectArea("SE5")
SE5->(RecLock("SE5",.F.))
    E5_XTXFAT := SE1->E1_TXMOEDA
    //E5_XVLAB  := Round(SE1->E1_TXMOEDA * SomaAbat(SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,"R",SE1->E1_MOEDA,dDataBase,SE1->E1_CLIENTE,SE1->E1_LOJA),2)
SE5->(MsUnlock()) 


dbSelectArea("SE1")
SE1->(RecLock("SE1",.F.))
    E1_XSEQABA := SE5->E5_SEQ
SE1->(MsUnlock()) 

RestArea(aArea)

Return()


/*
Programa ...: FA110SE5() 
Uso ........: Grava dados adicionais na SE5 para contabilização baixa por LOTE
Data .......: 24/06/2021
Feito por ..: Bruno Lage Ferreira
Copyright @1998-2001,2021
*/
User Function FA110SE5()
***********************************************************************************
*
*
***
Local aArea := GetArea()

dbSelectArea("SE5")
SE5->(RecLock("SE5",.F.))
    E5_XTXFAT := SE1->E1_TXMOEDA
    //E5_XVLAB  := Round(SE1->E1_TXMOEDA * SomaAbat(SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,"R",SE1->E1_MOEDA,dDataBase,SE1->E1_CLIENTE,SE1->E1_LOJA),2)
SE5->(MsUnlock()) 


dbSelectArea("SE1")
SE1->(RecLock("SE1",.F.))
    E1_XSEQABA := SE5->E5_SEQ
SE1->(MsUnlock()) 

RestArea(aArea)

Return()


