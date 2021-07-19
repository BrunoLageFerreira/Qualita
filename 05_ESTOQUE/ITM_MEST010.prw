#INCLUDE "rwmake.ch"
#Include "PROTHEUS.Ch"
#Include "Topconn.ch"

User Function MEST010

	Private oLeTxt

	dbSelectArea("SB7")
	dbSetOrder(1)

	//���������������������������������������������������������������������Ŀ
	//� Montagem da tela de processamento.                                  �
	//�����������������������������������������������������������������������

	@ 200,1 TO 380,380 DIALOG oLeTxt TITLE OemToAnsi("Leitura de Arquivo Texto")
	@ 02,10 TO 080,190
	@ 10,018 Say " Este programa ira ler o conteudo de um arquivo texto, conforme"
	@ 18,018 Say " os parametros definidos pelo usuario, com os registros do arquivo"
	@ 26,018 Say " SB7                                                           "

	@ 70,128 BMPBUTTON TYPE 01 ACTION OkLeTxt()
	@ 70,158 BMPBUTTON TYPE 02 ACTION Close(oLeTxt)

	Activate Dialog oLeTxt Centered

Return

Static Function OkLeTxt

	//���������������������������������������������������������������������Ŀ
	//� Abertura do arquivo texto                                           �
	//�����������������������������������������������������������������������

	Private cArqTxt := "c:\temp\estoque.csv"
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

	//���������������������������������������������������������������������Ŀ
	//� Inicializa a regua de processamento                                 �
	//�����������������������������������������������������������������������

	Processa({|| RunCont() },"Processando...")
Return

/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Fun��o    � RUNCONT  � Autor � AP5 IDE            � Data �  05/12/11   ���
�������������������������������������������������������������������������͹��
���Descri��o � Funcao auxiliar chamada pela PROCESSA.  A funcao PROCESSA  ���
���          � monta a janela com a regua de processamento.               ���
�������������������������������������������������������������������������͹��
���Uso       � Programa principal                                         ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/

Static Function RunCont

	Local nTamFile, nTamLin, cBuffer, nBtLidos, aBuffer

	aBuffer := {}

	ProcRegua(FT_FLASTREC()) // Numero de registros a processar

	FT_FGOTOP()         // Posiciona na primeira linha do arquivo

	While !FT_FEOF()

		cBuffer := FT_FREADLN()
		IncProc()

		//���������������������������������������������������������������������Ŀ
		//� Grava os campos obtendo os valores da linha lida do arquivo texto.  �
		//�����������������������������������������������������������������������

		dbSelectArea("SB7")

		DbSelectArea("SB1")
		DbSetOrder(1)

		aBuffer := Separa(cBuffer,";",.T.)

		//So faz se achou o produto no cadastro, caso contrario, nao importa.
		If DbSeek(xFilial("SB1")+aBuffer[1])

			DbSelectArea("SB7")

			RecLock("SB7",.T.)
				SB7->B7_FILIAL	:= xFilial("SB7")
				SB7->B7_COD		:= aBuffer[1]
				SB7->B7_LOCAL	:= aBuffer[2]
				SB7->B7_TIPO	:= POSICIONE("SB1",1,XFILIAL("SB1")+aBuffer[1],"B1_TIPO")
				SB7->B7_DOC		:= DTOS(date())
				SB7->B7_QUANT	:= val(aBuffer[3])
				SB7->B7_DATA	:= date()
			MSUnLock()

		EndIf

		FT_FSKIP()

	EndDo

	FT_FUSE()

	fClose(nHdl)
	Close(oLeTxt)

Return
