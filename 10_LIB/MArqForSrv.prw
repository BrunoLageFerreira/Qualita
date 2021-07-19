#include "protheus.ch"
#include "rwmake.ch"
#include "tbiconn.ch"  
#INCLUDE "TOTVS.CH"

/*
Programa ...: MArqForSrv.Prw
Uso ........: Programa para enviar o arquivo do ponto para o servidor senior
Data .......: 15/01/2020
Feito por ..: Bruno Lage Ferreira
Copyright @1998-2001,2020
*/ 


User function MArqForSrv()
***********************************************************************************************************
*  
*
***  
Local _aDados := {}                         //Array com os campos enviados no TXT.
Local nHandle := 0                          //Handle do arquivo texto.
Local cArqImp := ""                         //Arquivo Txt a ser lido.

cArqImp := cGetFile("Arquivo .txt |*.txt","Selecione o Arquivo TXT do Ponto.",0,"",.T.,GETF_LOCALFLOPPY + GETF_LOCALHARD + GETF_NETWORKDRIVE)
If (nHandle := FT_FUse(cArqImp))== -1
     MsgInfo("Erro ao tentar abrir arquivo.","Atenção")
     Return(.T.)
EndIf

If ! ApMsgYesNo("Confirma a importacao do arquivo " + cArqImp +" ???", "Confirmar")
     Return(.T.)
EndIf

CpyT2S( cArqImp, "\PontoEletronico", .t. )
MsgInfo("Arquivo copiado com sucesso!","Atenção")

Return(.T.)