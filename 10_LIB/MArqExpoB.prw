#include "protheus.ch"
#include "rwmake.ch"
#include "tbiconn.ch"  
#INCLUDE "TOTVS.CH"
#INCLUDE "TopConn.CH"

/*
Programa ...: MArqExpoB.Prw
Uso ........: Programa para enviar o arquivo BI exportação base para sigaeis
Data .......: 04/01/2021
Feito por ..: Bruno Lage Ferreira
Copyright @1998-2001,2021
*/ 

User function MArqExpoB()
***********************************************************************************************************
*  
*
***  
//Local _aDados := {}                         //Array com os campos enviados no TXT.
Local nHandle      := 0                       //Handle do arquivo texto.
Local cArqImp      := ""                      //Arquivo Txt a ser lido.
Local cNomeArquivo := ""
Private aPerg      := {}
Private cPerg      := "IMPEXPBASE"

Aadd(aPerg,{cPerg,"Digite o ano do arqvivo? (04)","C",04,00,"G","","","","","","","",""})

U_Testasx1(cPerg,aPerg,.t.) 

If ! Pergunte(cPerg,.T.)
	Return
EndIf

//Alert(mv_par01)

cArqImp := cGetFile("Arquivo .csv |*.csv","Selecione o Arquivo CSV do Ponto.",0,"",.T.,GETF_LOCALFLOPPY + GETF_LOCALHARD + GETF_NETWORKDRIVE)
If (nHandle := FT_FUse(cArqImp))== -1
     MsgInfo("Erro ao tentar abrir arquivo.","Atenção")
     Return(.T.)
EndIf

If ! ApMsgYesNo("Confirma a importacao do arquivo " + cArqImp +" ???", "Confirmar")
     Return(.T.)
EndIf

CpyT2S( cArqImp, "\dirdoc\Arquivo_de_export", .t. )

cNomeArquivo := RetFileName(cArqImp) + ".csv"

fErase("D:\TOTVS 12\Microsiga\protheus_data\dirdoc\Arquivo_de_export\EXP_"+ mv_par01 +".csv")
//Alert("apagou")
fRename("D:\TOTVS 12\Microsiga\protheus_data\dirdoc\Arquivo_de_export\"+cNomeArquivo, "D:\TOTVS 12\Microsiga\protheus_data\dirdoc\Arquivo_de_export\EXP_"+ mv_par01 +".csv")
//Alert("renomeou")


TCSPExec("SP_EXPORTBASE",mv_par01)

MsgInfo("Arquivo importado com sucesso!","Atenção")



Return(.T.)
