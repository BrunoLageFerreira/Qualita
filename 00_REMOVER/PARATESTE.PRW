#include "rwmake.ch"
#include "tbiconn.ch"
User Function GravaErro()
Local nX     := 0
Local nCount := 0   
Local cLogFile := "" 

//nome do arquivo de log a ser gravado
Local aLog 	 := {}
Local aVetor := {}
Local nHandle
Local lRet := .F.   

// vari�vel de controle interno da rotina automatica que informa se houve erro durante o processamento
PRIVATE lMsErroAuto := .F.

// vari�vel que define que o help deve ser gravado no arquivo de log e que as informa��es est�o vindo � partir da rotina autom�tica.
Private lMsHelpAuto	:= .T.    

// for�a a grava��o das informa��es de erro em array para manipula��o da grava��o ao inv�s de gravar direto no arquivo tempor�rio 
Private lAutoErrNoFile := .T. 

Prepare Environment Empresa "01" Filial "01" Modulo "FAT"

//+------------------------- -------------------------------------+//| Teste de Inclusao |//+------------------------------------- -------------------------+

For nCount := 1 To 3	
	aVetor:= {{"B1_COD"     ,"99"+Alltrim(Str(nCount)),Nil},;
 	          {"B1_DESC"    ,"Teste"        ,Nil},;
		      {"B1_UM"      ,"UN"           ,Nil},;
 		      {"B1_LOCPAD"  ,"01"           ,Nil}}
   	lMsErroAuto := .F.    	
	lRet := .F.	
	AutoGrLog("Teste de gera��o do arquivo de log "+Alltrim(Str(nCount)))	
	AutoGrLog("")		
	MSExecAuto( {|x,y| MATA010(x, y) }, aVetor, 3 )	
	AutoGrLog(Replicate("-", 20))	

	If lMsErroAuto		
		cLogFile := "C:\TESTE"+Alltrim(Str(nCount))+".LOG"		
		//fun��o que retorna as informa��es de erro ocorridos durante o processo da rotina autom�tica		
		aLog := GetAutoGRLog()
	                                 				
		//efetua o tratamento para validar se o arquivo de log j� existe		
		If !File(cLogFile)			
			If (nHandle := MSFCreate(cLogFile,0)) <> -1				
				lRet := .T.			
			EndIf		
		Else			
		If (nHandle := FOpen(cLogFile,2)) <> -1				
			FSeek(nHandle,0,2)				
			lRet := .T.			
		EndIf		
	EndIf		

        If	lRet
            //grava as informa��es de log no arquivo especificado			
            For nX := 1 To Len(aLog)				
            FWrite(nHandle,aLog[nX]+CHR(13)+CHR(10))			
            Next nX			
            FClose(nHandle)		
        EndIf	
	EndIf
Next

If !lMsErroAuto	
	ConOut("Incluido com sucesso! ") 
Else	
	ConOut("Erro na inclusao !")
EndIf

Return
