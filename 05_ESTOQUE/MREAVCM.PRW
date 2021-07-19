#include"Protheus.ch"
#include"tbiconn.ch"

/*                                          
Programa ...: MREAVCM.Prw
Uso ........: REAVALIACAO DO CUSTO MEDIO EXECAUTO
Data .......: 29/03/2021
Feito por ..: Bruno Lage Ferreira
*/

USER function MREAVCM()
*************************************************************************************************
*
*
***
local aItem := {}

PRIVATE lMsErroAuto := .F.

//prepare environment empresa "99" filial "01"
 
 AAdd(aItem,{"DQ_COD","P002 ",Nil})
 AAdd(aItem,{"DQ_LOCAL","01" ,Nil})
 AAdd(aItem,{"DQ_DATA",dDATABASE ,Nil})
 AAdd(aItem,{"DQ_CM1",150 ,Nil})
 AAdd(aItem,{"DQ_CM2",0 ,Nil})
 AAdd(aItem,{"DQ_CM3",0 ,Nil})
 AAdd(aItem,{"DQ_CM4",0 ,Nil})
 

 //Reavaliação Custo Médio
 MSExecAuto({|x,y,z| MATA338(x,y)},aItem,3)//3-Inclusão, 4-Alteração e 5-Exclusão 

 If !lMsErroAuto 
    ConOut("Incluido com sucesso! ") 
 Else 
    ConOut("Erro na inclusao!")
 EndIf
    
ConOut("Fim : "+Time())

//reset environment
 
Return Nil
