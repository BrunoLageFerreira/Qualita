#INCLUDE "TopConn.CH"
#INCLUDE "RWMAKE.CH"
#INCLUDE "PROTHEUS.CH"   
#INCLUDE "TBICONN.CH"
            
/*
Programa ...: MT103DCF.Prw
Uso ........: MT103DCF.Prw - Habilita botão Mais Inf. e acrescenta campos na aba DANFE 
Data .......: 16/09/2020
Feito por ..: Bruno Lage Ferreira
Copyright @1998-2001,2020

MV_MRCVLM1
*/ 
User Function MT103DCF()
************************************************************************************************
*
*
****
Local lInclui    := PARAMIXB[1]
Local lAltera    := PARAMIXB[2]
Local lVisual    := PARAMIXB[3]
Local aCamposPar := PARAMIXB[4]
Local aCamposRet := {}	

Local oMarca1
Local cMarca1 := space(60)  
Local oNumer1
Local cNumer1 := space(60)
/*
F1_MARCA1
F1_NUMER1
*/
DEFINE MSDIALOG oDlg TITLE "Informações de Blocos:" FROM 0,0 TO 140,360 OF oMainWnd PIXEL
 
 @ 16,10 SAY RetTitle("F1_MARCA1")    				SIZE 45,09  OF oDlg PIXEL
 @ 14,50 MSGET oMarca1 VAR cMarca1  PICTURE("@!")  	SIZE 60,09  OF oDlg PIXEL

 @ 36,10 SAY RetTitle("F1_NUMER1")    				SIZE 45,09  OF oDlg PIXEL
 @ 34,50 MSGET oNumer1 VAR cNumer1  PICTURE("@!")  	SIZE 60,09  OF oDlg PIXEL 
 
 //DEFINE SBUTTON FROM 50,143 TYPE 1 ACTION GravMot(aCamposRet,cCodigo)ENABLE OF oDlg     
 
 DEFINE SBUTTON FROM 50,143 TYPE 1 ACTION {||oDlg:End()}ENABLE OF oDlg
                                   
ACTIVATE MSDIALOG oDlg CENTERED
 
 //PARAMIXB[4]:={"F1_MOTCANC",cCodigo}
aCamposPar:={{"F1_MARCA1",AllTrim(cMarca1)},{"F1_NUMER1",AllTrim(cNumer1)}}
     
Return aCamposPar

