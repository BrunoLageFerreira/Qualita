#INCLUDE "rwmake.ch"
#Include "PROTHEUS.Ch"
#Include "Topconn.ch"

User Function ImpSDQ()

	Private oLeTxt

	//旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
	//� Montagem da tela de processamento.                                  �
	//읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
	@ 200,1 TO 380,380 DIALOG oLeTxt TITLE OemToAnsi("Leitura de Arquivo Texto")
	@ 02,10 TO 080,190
	@ 10,018 Say " Este programa ira ler o conteudo de um arquivo texto, conforme"
	@ 18,018 Say " os parametros definidos pelo usuario, com os registros do arquivo"
	@ 26,018 Say " SDQ                                                           "

	@ 70,128 BMPBUTTON TYPE 01 ACTION OkLeTxt()
	@ 70,158 BMPBUTTON TYPE 02 ACTION Close(oLeTxt)

	Activate Dialog oLeTxt Centered
	
Return

Static Function OkLeTxt

	//旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
	//� Abertura do arquivo texto                                           �
	//읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�

	Private cArqTxt := "c:\reavcusto.csv"
	Private nHdl    := FT_FUse(cArqTxt) //fOpen(cArqTxt,68)

	Private cEOL    := "CHR(13)+CHR(10)"
	If Empty(cEOL)
		cEOL := CHR(13)+CHR(10)
	Else
		cEOL := Trim(cEOL)
		cEOL := &cEOL
	Endif

	If nHdl == -1
		MsgAlert("O arquivo de nome "+cArqTxt+" nao pode ser aberto! Verifique os parametros.","Atencao!")
		Return
	Endif

	//旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
	//� Inicializa a regua de processamento                                 �
	//읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�

	Processa({|| RunCont() },"Processando...")
Return

Static Function RunCont

	Local nTamFile, nTamLin, cBuffer, nBtLidos, aBuffer

	aBuffer := {}

	ProcRegua(FT_FLASTREC()) // Numero de registros a processar

	FT_FGOTOP()         // Posiciona na primeira linha do arquivo

	While !FT_FEOF()

		cBuffer := FT_FREADLN()
		IncProc()

		//旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
		//� Grava os campos obtendo os valores da linha lida do arquivo texto.  �
		//읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
		lMSHelpAuto := .T. // para mostrar os erro na tela
		lMsErroAuto := .F.

		aBuffer := Separa(cBuffer,";",.T.)

		cFilial:= aBuffer[1]
		cCodigo:= aBuffer[2]
		cCM1   := Val(aBuffer[3])
		cLocal := aBuffer[5]

		Reclock("SDQ",.T.)

		SDQ->DQ_FILIAL	:= cFilial
		SDQ->DQ_COD		:= cCodigo
		SDQ->DQ_CM1		:= cCM1
		SDQ->DQ_LOCAL	:= cLocal
		SDQ->DQ_DATA	:= STOD("20120930")


		MsUnLock()

		FT_FSKIP()

	EndDo

	FT_FUSE()

	fClose(nHdl)
	Close(oLeTxt)

Return
