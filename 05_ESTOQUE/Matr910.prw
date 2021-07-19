#INCLUDE "MATR910.CH"
#INCLUDE "PROTHEUS.CH"
/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������Ŀ��
���Fun��o    � MATR910  � Autor � Nereu Humberto Junior � Data � 11.07.06 ���
�������������������������������������������������������������������������Ĵ��
���Descri��o � Kardex fisico - financeiro                                 ���
�������������������������������������������������������������������������Ĵ��
��� Uso      � Generico                                                   ���
�������������������������������������������������������������������������Ĵ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
User Function Matr910()
	Local oReport

	//If FindFunction("TRepInUse") .And. TRepInUse()
	//������������������������������������������������������������������������Ŀ
	//�Interface de impressao                                                  �
	//��������������������������������������������������������������������������
	//	oReport:= ReportDef()
	//	oReport:PrintDialog()
	//Else
	MATR910R3()
	//EndIf

Return
/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������Ŀ��
���Programa  �ReportDef � Autor �Nereu Humberto Junior  � Data �11.07.2006���
�������������������������������������������������������������������������Ĵ��
���Descri��o �A funcao estatica ReportDef devera ser criada para todos os ���
���          �relatorios que poderao ser agendados pelo usuario.          ���
���          �                                                            ���
�������������������������������������������������������������������������Ĵ��
���Retorno   �ExpO1: Objeto do relat�rio                                  ���
�������������������������������������������������������������������������Ĵ��
���Parametros�Nenhum                                                      ���
���          �                                                            ���
�������������������������������������������������������������������������Ĵ��
���   DATA   � Programador   �Manutencao efetuada                         ���
�������������������������������������������������������������������������Ĵ��
���          �               �                                            ���
��������������������������������������������������������������������������ٱ�
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/
Static Function ReportDef()

	Local oReport 
	Local oSection1
	Local oSection2
	Local oSection3
	Local oCell         
	Local aOrdem    := {}
	Local aSB1Cod   := {}
	Local aSB1Ite   := {}
	Local cPicB2Qt  := PesqPictQt("B2_QATU" ,18)
	Local cTamB2Qt  := TamSX3('B2_QATU')[1]
	Local cPicB2Cust:= PesqPict("SB2","B2_CM1",18)
	Local cTamB2Cust:= TamSX3('B2_CM1')[1]
	Local cPicD1Qt  := PesqPict("SD1","D1_QUANT" ,18)
	Local cTamD1Qt  := TamSX3('D1_QUANT')[1]
	Local cPicD1Cust:= PesqPict("SD1","D1_CUSTO",18)
	Local cTamD1Cust:= TamSX3('D1_CUSTO')[1]
	Local cPicD2Qt  := PesqPict("SD2","D2_QUANT" ,18)
	Local cTamD2Qt  := TamSX3('D2_QUANT')[1]
	LOCAL cPicD2Cust:= PesqPict("SD2","D2_CUSTO1",18)
	Local cTamD2Cust:= TamSX3('D2_CUSTO1')[1]
	Local lVEIC 	:= UPPER(GETMV("MV_VEICULO"))=="S"
	Local nTamSX1 	:= Len(SX1->X1_GRUPO)
	Local cTamD1CF  := TamSX3('D1_CF')[1]
	Local nTamData 	:= IIF(__SetCentury(),10,8)
	Local lVer116   := (VAL(GetVersao(.F.)) == 11 .And. GetRpoRelease() >= "R6" .Or. VAL(GetVersao(.F.))  > 11)
	//��������������������������������������������������������������Ŀ
	//� Verifica se utiliza custo unificado por Empresa/Filial       �
	//����������������������������������������������������������������
	Local lCusUnif := IIf(FindFunction("A330CusFil"),A330CusFil(),GetMV("MV_CUSFIL",.F.))

	//��������������������������������������������������������������Ŀ
	//� Ajusta perguntas no SX1 a fim de preparar o relatorio p/     �
	//� custo unificado por empresa                                  �
	//����������������������������������������������������������������
	If lCusUnif
		MTR910CUnf(lCusUnif)
	EndIf
	//��������������������������������������������������������������Ŀ
	//� Ajusta perguntas no SX1 									 �
	//����������������������������������������������������������������
	AjustaSX1()
	//��������������������������������������������������������������Ŀ
	//� Remove grupo de perguntas incluido                           �
	//����������������������������������������������������������������
	dbSelectArea("SX1")
	dbSetOrder(1)
	If dbSeek(PADR("MTR910",nTamSX1)+"22")
		RecLock("SX1",.F.)
		dbDelete()
		MsUnlock()
	EndIf
	//��������������������������������������������������������������Ŀ
	//� Ajustar o SX1 para SIGAVEI, SIGAPEC e SIGAOFI                �
	//����������������������������������������������������������������
	aSB1Cod	:= TAMSX3("B1_COD")
	aSB1Ite	:= TAMSX3("B1_CODITE")

	If lVEIC

		dbSelectArea("SX1")
		dbSetOrder(1)
		dbSeek(PADR("MTR910",nTamSX1))
		Do While SX1->X1_GRUPO == PADR("MTR910",nTamSX1) .And. !SX1->(Eof())
			If "PRODU" $ Upper(SX1->X1_PERGUNT) .And. Upper(SX1->X1_TIPO) == "C" .And. ;
			(SX1->X1_TAMANHO <> aSB1Ite[1] .Or. Upper(SX1->X1_F3) <> "VR4")

				RecLock("SX1",.F.)
				SX1->X1_TAMANHO := aSB1Ite[1]
				SX1->X1_F3 := "VR4"
				dbCommit()
				msUnLock()
			EndIf
			dbSkip()
		EndDo
		dbCommitAll()
	Else
		dbSelectArea("SX1")
		dbSetOrder(1)
		dbSeek(PADR("MTR910",nTamSX1))
		Do While SX1->X1_GRUPO == PADR("MTR910",nTamSX1) .And. !SX1->(Eof())
			If "PRODU" $ Upper(SX1->X1_PERGUNT) .And. Upper(SX1->X1_TIPO) == "C" .And. ;
			(SX1->X1_TAMANHO <> aSB1Cod[1] .Or. Upper(SX1->X1_F3) <> "SB1")

				RecLock("SX1",.F.)
				SX1->X1_TAMANHO := aSB1Cod[1]
				SX1->X1_F3 := "SB1"
				dbCommit()
				msUnLock()
			EndIf
			dbSkip()
		EndDo
		dbCommitAll()
	EndIf
	//������������������������������������������������������������������������Ŀ
	//�Criacao do componente de impressao                                      �
	//�                                                                        �
	//�TReport():New                                                           �
	//�ExpC1 : Nome do relatorio                                               �
	//�ExpC2 : Titulo                                                          �
	//�ExpC3 : Pergunte                                                        �
	//�ExpB4 : Bloco de codigo que sera executado na confirmacao da impressao  �
	//�ExpC5 : Descricao                                                       �
	//�                                                                        �
	//��������������������������������������������������������������������������
	oReport:= TReport():New("MATR910",STR0003,"MTR910", {|oReport| ReportPrint(oReport,oSection1)},STR0001+" "+STR0002) //"Kardex Fisico-Financeiro (DIA)"##"Este programa emitir� uma rela��o com as movimenta��es"##"dos produtos Selecionados,Ordenados por Dia."
	oReport:SetLandscape()    
	oReport:SetTotalInLine(.F.)

	Pergunte("MTR910",.F.)

	Aadd( aOrdem, STR0004 ) // " Codigo Produto "
	Aadd( aOrdem, STR0005 ) // " Tipo do Produto"
	//��������������������������������������������������������������Ŀ
	//� Definicao da Secao 1 - Dados do Produto                      �
	//����������������������������������������������������������������
	oSection1 := TRSection():New(oReport,STR0062,{"SB1","SB2"},aOrdem) //"Produto (Parte 1)"
	oSection1 :SetTotalInLine(.F.)
	oSection1 :SetReadOnly()
	oSection1 :SetLineStyle()

	If lVeic
		TRCell():New(oSection1,"B1_CODITE","SB1",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	Endif
	TRCell():New(oSection1,"cProduto","   ",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	oSection1:Cell("cProduto"):GetFieldInfo("B1_COD")
	TRCell():New(oSection1,"B1_DESC","SB1",/*Titulo*/,/*Picture*/,30,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"B1_UM","SB1",STR0056,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"cTipo","   ",STR0057,"@!",2,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"B1_GRUPO","SB1",STR0058,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"nCusMed","   ",STR0059,cPicB2Cust,cTamB2Cust,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"nQtdSal","   ",STR0054,cPicB2Qt,cTamB2Qt,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"nVlrSal","   ",STR0055,cPicB2Cust,cTamB2Cust,/*lPixel*/,/*{|| code-block de impressao }*/)
	//��������������������������������������������������������������Ŀ
	//� Definicao da Secao 2 - Cont. dos dados do Produto            �
	//����������������������������������������������������������������
	oSection2 := TRSection():New(oSection1,STR0063,{"SB1","SB2","NNR"}) //"Produto (Parte 2)"
	oSection2 :SetTotalInLine(.F.)
	oSection2 :SetReadOnly()
	oSection2 :SetLineStyle()

	If lVeic
		TRCell():New(oSection2,"cProduto","   ",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
		oSection2:Cell("cProduto"):GetFieldInfo("B1_COD")
		TRCell():New(oSection2,"B1_UM","SB1",STR0056,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
		TRCell():New(oSection2,"cTipo","   ",STR0057,"@!",2,/*lPixel*/,/*{|| code-block de impressao }*/)
		TRCell():New(oSection2,"B1_GRUPO","SB1",STR0058,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	Endif	
	If cPaisLoc<>"CHI"
		TRCell():New(oSection2,"B1_POSIPI","SB1",STR0060,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	Endif	

	If lVer116
		TRCell():New(oSection2,"NNR_DESCRI","NNR",STR0061,/*Picture*/,/*Tamanho*/,/*lPixel*/, {|| If(lCusUnif , MV_PAR08 , Posicione("NNR",1,xFilial("NNR")+MV_PAR08,"NNR_DESCRI")) })
	Else
		TRCell():New(oSection2,"B2_LOCALIZ","SB2",STR0061,/*Picture*/,/*Tamanho*/,/*lPixel*/, {|| If(lCusUnif , MV_PAR08 , SB2->B2_LOCALIZ) })
	EndIf
	//��������������������������������������������������������������Ŀ
	//� Definicao da Secao 3 - Movimentos                            �
	//����������������������������������������������������������������
	oSection3 := TRSection():New(oSection2,STR0064,{"SD1","SD2","SD3"}) //"Movimenta��o dos Produtos"
	oSection3 :SetHeaderPage()
	oSection3 :SetTotalInLine(.F.)
	oSection3 :SetTotalText(STR0017) //"T O T A I S  :"
	oSection3 :SetReadOnly()

	TRCell():New(oSection3,"dDtMov","   ",STR0038+CRLF+STR0039,/*Picture*/,nTamData,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection3,"cTES","   ",STR0040,"@!",/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection3,"cCF","   ",STR0041,"@!",cTamD1CF,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection3,"cDoc","   ",STR0042+CRLF+STR0043,"@!",/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection3,"nENTQtd","   ",STR0044+CRLF+STR0045,cPicD1Qt,cTamD1Qt,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection3,"nENTCus","   ",STR0044+CRLF+STR0046,cPicD1Cust,cTamD1Cust,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection3,"nCusMov","   ",STR0047+CRLF+STR0048,cPicB2Cust,cTamB2Cust,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection3,"nSAIQtd","   ",STR0049+CRLF+STR0045,cPicD2Qt,cTamD2Qt,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection3,"nSAICus","   ",STR0049+CRLF+STR0046,cPicD2Cust,cTamD2Cust,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection3,"nSALDQtd","   ",STR0050+CRLF+STR0045,cPicB2Qt,cTamB2Qt,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection3,"nSALDCus","   ",STR0050+CRLF+STR0051,cPicB2Cust,cTamB2Cust,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection3,"cCCPVPJOP","   ",STR0052+CRLF+STR0053,"@!",/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)

	// Definir o formato de valores negativos (para o caso de devolucoes)
	oSection3:Cell("nENTQtd"):SetNegative("PARENTHESES")
	oSection3:Cell("nENTCus"):SetNegative("PARENTHESES")
	oSection3:Cell("nSAIQtd"):SetNegative("PARENTHESES")
	oSection3:Cell("nSAICus"):SetNegative("PARENTHESES")

	TRFunction():New(oSection3:Cell("nENTQtd")	,NIL,"SUM"		,/*oBreak*/,"",cPicD1Qt		,{|| oSection3:Cell("nENTQtd"):GetValue(.T.) },.T.,.F.) 
	TRFunction():New(oSection3:Cell("nENTCus")	,NIL,"SUM"		,/*oBreak*/,"",cPicD1Cust	,{|| oSection3:Cell("nENTCus"):GetValue(.T.) },.T.,.F.) 

	TRFunction():New(oSection3:Cell("nSAIQtd")	,NIL,"SUM"		,/*oBreak*/,"",cPicD2Qt		,{|| oSection3:Cell("nSAIQtd"):GetValue(.T.) },.T.,.F.) 
	TRFunction():New(oSection3:Cell("nSAICus")	,NIL,"SUM"		,/*oBreak*/,"",cPicD2Cust	,{|| oSection3:Cell("nSAICus"):GetValue(.T.) },.T.,.F.) 

	TRFunction():New(oSection3:Cell("nSALDQtd")	,NIL,"ONPRINT"	,/*oBreak*/,"",cPicB2Qt		,{|| oSection3:Cell("nSALDQtd"):GetValue(.T.) },.T.,.F.) 
	TRFunction():New(oSection3:Cell("nSALDCus")	,NIL,"ONPRINT"	,/*oBreak*/,"",cPicB2Cust	,{|| oSection3:Cell("nSALDCus"):GetValue(.T.) },.T.,.F.) 

	oSection3:SetNoFilter("SD1")
	oSection3:SetNoFilter("SD2")
	oSection3:SetNoFilter("SD3")
Return(oReport)

/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������Ŀ��
���Programa  �ReportPrin� Autor �Nereu Humberto Junior  � Data �21.06.2006���
�������������������������������������������������������������������������Ĵ��
���Descri��o �A funcao estatica ReportDef devera ser criada para todos os ���
���          �relatorios que poderao ser agendados pelo usuario.          ���
���          �                                                            ���
�������������������������������������������������������������������������Ĵ��
���Retorno   �Nenhum                                                      ���
�������������������������������������������������������������������������Ĵ��
���Parametros�ExpO1: Objeto Report do Relat�rio                           ���
���          �                                                            ���
�������������������������������������������������������������������������Ĵ��
���   DATA   � Programador   �Manutencao efetuada                         ���
�������������������������������������������������������������������������Ĵ��
���          �               �                                            ���
��������������������������������������������������������������������������ٱ�
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/
Static Function ReportPrint(oReport,oSection)

	Static lIxbConTes := NIL
	Local oSection1:= oReport:Section(1) 
	Local oSection2:= oReport:Section(1):Section(1)  
	Local oSection3:= oReport:Section(1):Section(1):Section(1)  
	Local nOrdem   := oReport:Section(1):GetOrder() 
	Local cSelectD1 := '', cWhereD1 := ''
	Local cSelectD2 := '', cWhereD2 := ''
	Local cSelectD3 := '', cWhereD3 := ''
	Local cSelectVe := '', cUnion := '%%'
	Local aDadosTran:={},lContinua := .F.
	Local cProdAnt  := ""
	Local cLocalAnt := ""
	Local nCusMed   := 0
	Local lFirst1   := .T.
	Local aSalAtu   := { 0,0,0,0,0,0,0 }
	Local aSalAlmox := {}
	Local nGEntrada := 0, nGSaida :=0
	Local nRec1,nRec2,nRec3,nSavRec,dCntData
	Local cPicB2Cust:= PesqPict("SB2","B2_CM"+Str(mv_par11,1),18)
	Local cPicD1Cust:= PesqPict("SD1","D1_CUSTO"+IIF(mv_par11 == 1 ,"",Str(mv_par11,1)),18)
	Local cPicD2Cust:= PesqPict("SD2","D2_CUSTO"+Str(mv_par11,1),18)
	Local cPicB2Qt  := PesqPictQt("B2_QATU" ,18)
	Local cPicB2Qt2 := PesqPictQt("B2_QTSEGUM" ,18)
	Local cCusto, lImpLivro, lImpTermos, cCond1, cCond2
	Local nAcho,i,aGrupos:={},cAlias
	Local cTRBSD1	:= CriaTrab(,.f.)
	Local cTRBSD2	:= Subs(cTrbSD1,1,7)+"A"
	Local cTRBSD3	:= Subs(cTrbSD1,1,7)+"B"
	Local nInd,cIndice	:="",cCampo1,cCampo2,cCampo3,cCampo4
	Local cNumSeqTr := "" , nRegTr := 0
	Local cSeqIni 	:= Replicate("z",6)
	Local nTotRegs  := 0
	Local nTamSX1 := Len(SX1->X1_GRUPO)
	// Indica se esta listando relatorio do almox. de processo
	Local lLocProc:= mv_par08 == GetMv("MV_LOCPROC")
	// Indica se deve imprimir movimento invertido (almox. de processo)
	Local lInverteMov :=.F.
	Local lPriApropri :=.T.
	//��������������������������������������������������������������Ŀ
	//� Verifica se existe ponto de entrada                          �
	//����������������������������������������������������������������
	Local lTesNEst := .F.
	//��������������������������������������������������������������Ŀ
	//� Codigo do produto importado - NAO DEVE SER LISTADO           �
	//����������������������������������������������������������������
	Local cProdImp := GETMV("MV_PRODIMP")
	//��������������������������������������������������������������Ŀ
	//� Variaveis tipo Local para SIGAVEI, SIGAPEC e SIGAOFI         �
	//����������������������������������������������������������������
	Local cArq1 := ""
	Local nInd1 := 0

	Local nRecTrf1 := 0
	Local nRecTrf2 := 0
	Local aRecTRF  := {}

	Local cWhereB1A:= " " 
	Local cWhereB1B:= " " 
	Local cWhereB1C:= " " 
	Local cWhereB1D:= " " 

	Local cQueryB1A:= " " 
	Local cQueryB1B:= " " 
	Local cQueryB1C:= " " 
	Local cQueryB1D:= " " 
	Local bBloco  := { |nV,nX| Trim(nV)+IIf(Valtype(nX)='C',"",Str(nX,1)) }
	Local lVEIC := UPPER(GETMV("MV_VEICULO"))=="S"
	Local lImpSMov := .F.
	Local lImpS3   := .F.
	Local cFilUser := oSection:GetAdvplExp()

	//�����������������������������������������������������Ŀ
	//� Variavel utilizada para inicar a pagina do relatorio�
	//�������������������������������������������������������
	Local n_pag     := mv_par12   
	#IFNDEF TOP
	Local cCondicao := ""
	#ELSE
	Local cAliasTop := ""
	#ENDIF

	Local cProdMNT := GetMv("MV_PRODMNT")
	Local cProdTER := GetMv("MV_PRODTER")
	Local aProdsMNT := {}
	Local nX

	cProdMNT := cProdMNT + Space(15-Len(cProdMNT))
	cProdTER := cProdTER  + Space(15-Len(cProdTER))

	//��������������������������������������������������������������Ŀ
	//� Verifica se utiliza custo unificado por Empresa/Filial       �
	//����������������������������������������������������������������
	Private lCusUnif := IIf(FindFunction("A330CusFil"),A330CusFil(),GetMV("MV_CUSFIL",.F.))
	lCusUnif:=lCusUnif .And. mv_par08 == Repl("*",TamSX3("B2_LOCAL")[1])
	Private lDev := .F. // Flag que indica se nota � devolu�ao (.T.) ou nao (.F.)
	Private aDriver := ReadDriver()
	//��������������������������������������������������������������Ŀ
	//� Impressao de Termo / Livro                                   �
	//����������������������������������������������������������������
	Do Case
		Case mv_par15==1 ; lImpLivro:=.t. ; lImpTermos:=.f.
		Case mv_par15==2 ; lImpLivro:=.t. ; lImpTermos:=.t.
		Case mv_par15==3 ; lImpLivro:=.f. ; lImpTermos:=.t.
	EndCase
	oReport:SetPageNumber(n_pag)     
	oReport:SetTitle(STR0013+mv_par08)
	If nOrdem == 1
		oReport:SetTitle( oReport:Title()+Alltrim(STR0014+STR0004+STR0015+AllTrim(GetMv("MV_SIMB"+Ltrim(Str(mv_par11))))+")"))
	Else
		oReport:SetTitle( oReport:Title()+Alltrim(STR0014+STR0005+STR0015+AllTrim(GetMv("MV_SIMB"+Ltrim(Str(mv_par11))))+")"))	
	Endif	
	oReport:SetTitle( oReport:Title()+AllTrim(IIf(mv_par16==1,OemToAnsi(STR0030),OemToAnsi(STR0031))))

	If lVeic
		oSection1:Cell("cProduto"):Disable()
		oSection1:Cell("B1_UM"):Disable()
		oSection1:Cell("cTipo"):Disable()
		oSection1:Cell("B1_GRUPO"):Disable()
	Endif

	dbSelectArea("SD1")   // Itens de Entrada
	nTotRegs += LastRec()

	dbSelectArea("SD2")   // Itens de Saida
	nTotRegs += LastRec()

	dbSelectArea("SD3")   // movimentacoes internas (producao/requisicao/devolucao)
	nTotRegs += LastRec()

	dbSelectArea("SB2")  // Saldos em estoque
	dbSetOrder(1)
	nTotRegs += LastRec()

	lIxbConTes := IF(lIxbConTes == NIL,ExistBlock("MTAAVLTES"),lIxbConTes)

	//������������������������������������������������������������������������Ŀ
	//�Filtragem do relat�rio                                                  �
	//��������������������������������������������������������������������������
	#IFDEF TOP
	//������������������������������������������������������������������������Ŀ
	//�Transforma parametros Range em expressao SQL                            �	
	//��������������������������������������������������������������������������
	MakeSqlExpr(oReport:uParam)

	cAliasTop := GetNextAlias()    

	//������������������������������������������������������������������������Ŀ
	//�Query do relat�rio da secao 1                                           �
	//��������������������������������������������������������������������������
	oReport:Section(1):BeginQuery()	

	//������������������������������������������������������������������������Ŀ
	//�Complemento do SELECT da tabela SD1                                     �
	//��������������������������������������������������������������������������
	cSelectD1 := "% D1_CUSTO"
	If mv_par11 > 1
		cSelectD1 += Str(mv_par11,1,0) // Coloca a Moeda do Custo
	EndIf
	cSelectD1 += " CUSTO,"
	cSelectD1 += "%"
	//������������������������������������������������������������������������Ŀ
	//�Complemento do SELECT da tabela SB1 para MV_VEICULO                     �
	//��������������������������������������������������������������������������	
	cSelectVe := "%" 
	cSelectVe += ","
	IF lVEIC
		cSelectVe += "SB1.B1_CODITE B1_CODITE,"	
	ENDIF
	cSelectVe += "%" 
	//������������������������������������������������������������������������Ŀ
	//�Complemento do Where da tabela SD1                                      �
	//��������������������������������������������������������������������������	
	cWhereD1 := "%" 
	cWhereD1 += "AND" 
	If !lCusUnif
		cWhereD1 += " D1_LOCAL = '" + mv_par08 + "' AND"
	EndIf
	cWhereD1 += "%" 
	//������������������������������������������������������������������������Ŀ
	//�Complemento do SELECT da tabela SD2                                     �
	//��������������������������������������������������������������������������
	cSelectD2 := "% D2_CUSTO"
	cSelectD2 += Str(mv_par11,1,0) // Coloca a Moeda do Custo
	cSelectD2 += " CUSTO,"
	cSelectD2 += "%"	
	//������������������������������������������������������������������������Ŀ
	//�Complemento do Where da tabela SD1                                      �
	//��������������������������������������������������������������������������	
	cWhereD2 := "%" 
	cWhereD2 += "AND" 
	If !lCusUnif
		cWhereD2 += " D2_LOCAL = '" + mv_par08 + "' AND"
	EndIf
	cWhereD2 += "%"    
	//������������������������������������������������������������������������Ŀ
	//�Complemento do SELECT da tabelas SD3                                    �
	//��������������������������������������������������������������������������
	cSelectD3 := "% D3_CUSTO"
	cSelectD3 += Str(mv_par11,1,0) // Coloca a Moeda do Custo
	cSelectD3 +=	" CUSTO," 
	cSelectD3 += "%"    
	//������������������������������������������������������������������������Ŀ
	//�Complemento do WHERE da tabela SD3                                      �
	//��������������������������������������������������������������������������
	cWhereD3 := "%"
	If SuperGetMV('MV_D3ESTOR', .F., 'N') == 'N'
		cWhereD3 += " D3_ESTORNO <> 'S' AND"
	EndIf
	If SuperGetMV('MV_D3SERVI', .F., 'N') == 'N' .And. IntDL()
		cWhereD3 += " ( (D3_SERVIC = '   ') OR (D3_SERVIC <> '   ' AND D3_TM <= '500')  "
		cWhereD3 += " OR  (D3_SERVIC <> '   ' AND D3_TM > '500' AND D3_LOCAL ='"+SuperGetMV('MV_CQ', .F., '98')+"') ) AND"
	EndIf
	If !lCusUnif .And. !lLocProc
		cWhereD3 += " D3_LOCAL = '"+mv_par08+"' AND" 
	EndIf
	If	!lVEIC
		cWhereD3+= " SB1.B1_COD >= '"+mv_par01+"' AND SB1.B1_COD <= '"+mv_par02+"' AND"
	Else
		cWhereD3+= " SB1.B1_CODITE >= '"+mv_par01+"' AND SB1.B1_CODITE <= '"+mv_par02+"' AND"
	EndIf	
	cWhereD3 += " SB1.B1_FILIAL = '"+xFilial("SB1")+"' AND SB1.B1_TIPO >= '"+mv_par03+"' AND SB1.B1_TIPO <= '"+mv_par04+"' AND"
	cWhereD3 += " SB1.B1_GRUPO >= '"+mv_par18+"' AND SB1.B1_GRUPO <= '"+mv_par19+"' AND SB1.B1_COD <> '"+cProdimp+"' AND "
	cWhereD3 += " SB1.D_E_L_E_T_=' ' AND"
	cWhereD3 += "%"	
	//������������������������������������������������������������������������Ŀ
	//�Complemento do WHERE da tabela SB1 para todos os selects                �
	//��������������������������������������������������������������������������
	cWhereB1A:= "%" 
	cWhereB1B:= "%" 
	cWhereB1C:= "%" 
	cWhereB1D:= "%" 	
	If	!lVEIC
		cWhereB1A+= " AND SB1.B1_COD >= '"+mv_par01+"' AND SB1.B1_COD <= '"+mv_par02+"'"
		cWhereB1B+= " AND SB1.B1_COD = SB1EXS.B1_COD"
		cWhereB1C+= " SB1.B1_FILIAL = '"+xFilial("SB1")+"' AND SB1.B1_TIPO >= '"+mv_par03+"' AND SB1.B1_TIPO <= '"+mv_par04+"' AND"
		cWhereB1D+= " SB1EXS.B1_FILIAL = '"+xFilial("SB1")+"' AND SB1EXS.B1_COD >= '"+mv_par01+"' AND SB1EXS.B1_COD <= '"+mv_par02+"' AND SB1EXS.B1_TIPO >= '"+mv_par03+"' AND SB1EXS.B1_TIPO <= '"+mv_par04+"' AND"
	Else
		cWhereB1A+= " AND SB1.B1_CODITE >= '"+mv_par01+"' AND SB1.B1_CODITE <= '"+mv_par02+"'"
		cWhereB1B+= " AND SB1.B1_COD = SB1EXS.B1_COD"
		cWhereB1C+= " SB1.B1_FILIAL = '"+xFilial("SB1")+"' AND SB1.B1_TIPO >= '"+mv_par03+"' AND SB1.B1_TIPO <= '"+mv_par04+"' AND"
		cWhereB1D+= " SB1EXS.B1_FILIAL = '"+xFilial("SB1")+"' AND SB1EXS.B1_CODITE >= '"+mv_par01+"' AND SB1EXS.B1_CODITE <= '"+mv_par02+"' AND SB1EXS.B1_TIPO >= '"+mv_par03+"' AND SB1EXS.B1_TIPO <= '"+mv_par04+"' AND"
	EndIf	
	cWhereB1C += " SB1.B1_GRUPO >= '"+mv_par18+"' AND SB1.B1_GRUPO <= '"+mv_par19+"' AND SB1.B1_COD <> '"+cProdimp+"' AND "
	cWhereB1C += " SB1.D_E_L_E_T_=' '"
	cWhereB1D += " SB1EXS.B1_GRUPO >= '"+mv_par18+"' AND SB1EXS.B1_GRUPO <= '"+mv_par19+"' AND SB1EXS.B1_COD <> '"+cProdimp+"' AND "
	cWhereB1D += " SB1EXS.D_E_L_E_T_=' '"	

	cQueryB1A:= Subs(cWhereB1A,2)
	cQueryB1B:= Subs(cWhereB1B,2)
	cQueryB1C:= Subs(cWhereB1C,2)
	cQueryB1D:= Subs(cWhereB1D,2)

	cWhereB1A+= "%" 
	cWhereB1B+= "%" 
	cWhereB1C+= "%" 
	cWhereB1D+= "%" 	
	//��������������������������������������������������������Ŀ
	//� So inclui as condicoes a seguir qdo lista produtos sem �
	//� movimento                                              �
	//����������������������������������������������������������
	cQueryD1 := " FROM "
	cQueryD1 += RetSqlName("SB1") + " SB1"
	cQueryD1 += (", " + RetSqlName("SD1")+ " SD1 ")
	cQueryD1 += (", " + RetSqlName("SF4")+ " SF4 ")
	cQueryD1 += " WHERE SB1.B1_COD = D1_COD"
	cQueryD1 += (" AND D1_FILIAL = '"+xFilial("SD1")+"'")
	cQueryD1 += (" AND F4_FILIAL = '" + xFilial("SF4") + "'")
	cQueryD1 += (" AND SD1.D1_TES = F4_CODIGO AND F4_ESTOQUE = 'S'")
	cQueryD1 += (" AND D1_DTDIGIT >= '" + DTOS(mv_par05) + "'")
	cQueryD1 += (" AND D1_DTDIGIT <= '" + DTOS(mv_par06) + "'")
	cQueryD1 +=  " AND D1_ORIGLAN <> 'LF'"
	If !lCusUnif
		cQueryD1 += " AND D1_LOCAL = '" + mv_par08 + "'"
	EndIf
	//������������������������������������������������������Ŀ
	//� N�o imprimir o produto MANUTENCAO (MV_PRDMNT) qdo integrado com MNT.       �
	//��������������������������������������������������������
	If MTR910IsMNT() 
		If FindFunction("NGProdMNT")
			aProdsMNT := aClone(NGProdMNT())
			For nX := 1 To Len(aProdsMNT)
				cQueryD1 += " AND SB1.B1_COD <> '" + aProdsMNT[nX] + "'"
			Next nX
		Else
			cQueryD1 += " AND SB1.B1_COD <> '" + cProdMNT + "'"
			cQueryD1 += " AND SB1.B1_COD <> '" + cProdTER + "'"
		EndIf
	EndIf	
	cQueryD1 += " AND SD1.D_E_L_E_T_=' ' AND SF4.D_E_L_E_T_=' '"

	cQueryD2 := " FROM "
	cQueryD2 += RetSqlName("SB1") + " SB1 , "+ RetSqlName("SD2")+ " SD2 , "+ RetSqlName("SF4")+" SF4 "
	cQueryD2 += " WHERE SB1.B1_COD = D2_COD AND D2_FILIAL = '"+xFilial("SD2")+"'"
	cQueryD2 += " AND F4_FILIAL = '"+xFilial("SF4")+"' AND SD2.D2_TES = F4_CODIGO AND F4_ESTOQUE = 'S'"
	cQueryD2 += " AND D2_EMISSAO >= '"+DTOS(mv_par05)+"' AND D2_EMISSAO <= '"+DTOS(mv_par06)+"'"
	cQueryD2 += " AND D2_ORIGLAN <> 'LF'"
	If !lCusUnif
		cQueryD2 += " AND D2_LOCAL = '"+mv_par08+"'"
	EndIf
	//������������������������������������������������������Ŀ
	//� N�o imprimir o produto MANUTENCAO (MV_PRDMNT) qdo integrado com MNT.       �
	//��������������������������������������������������������
	If MTR910IsMNT() 
		If FindFunction("NGProdMNT")
			aProdsMNT := aClone(NGProdMNT())
			For nX := 1 To Len(aProdsMNT)
				cQueryD2 += " AND SB1.B1_COD <> '" + aProdsMNT[nX] + "'"
			Next nX
		Else
			cQueryD2 += " AND SB1.B1_COD <> '" + cProdMNT + "'"
			cQueryD2 += " AND SB1.B1_COD <> '" + cProdTER + "'"
		EndIf
	EndIf	
	cQueryD2 += " AND SD2.D_E_L_E_T_=' ' AND SF4.D_E_L_E_T_=' '"	

	cQueryD3 := " FROM "
	cQueryD3 += RetSqlName("SB1") + " SB1 , "+ RetSqlName("SD3")+ " SD3 "
	cQueryD3 += " WHERE SB1.B1_COD = D3_COD AND D3_FILIAL = '"+xFilial("SD3")+"' "
	cQueryD3 += " AND D3_EMISSAO >= '"+DTOS(mv_par05)+"' AND D3_EMISSAO <= '"+DTOS(mv_par06)+"'"
	If SuperGetMV('MV_D3ESTOR', .F., 'N') == 'N'
		cQueryD3 += " AND D3_ESTORNO <> 'S'"
	EndIf
	If SuperGetMV('MV_D3SERVI', .F., 'N') == 'N' .And. IntDL()
		cQueryD3 += " AND ( (D3_SERVIC = '   ') OR (D3_SERVIC <> '   ' AND D3_TM <= '500')  "
		cQueryD3 += " OR  (D3_SERVIC <> '   ' AND D3_TM > '500' AND D3_LOCAL ='"+SuperGetMV('MV_CQ', .F., '98')+"') )"
	EndIf					
	If !lCusUnif .And. !lLocProc
		cQueryD3 += " AND D3_LOCAL = '"+mv_par08+"'"
	EndIf
	//������������������������������������������������������Ŀ
	//� N�o imprimir o produto MANUTENCAO (MV_PRDMNT) qdo integrado com MNT.       �
	//��������������������������������������������������������
	If MTR910IsMNT() 
		If FindFunction("NGProdMNT")
			aProdsMNT := aClone(NGProdMNT())
			For nX := 1 To Len(aProdsMNT)
				cQueryD3 += " AND SB1.B1_COD <> '" + aProdsMNT[nX] + "'"
			Next nX
		Else
			cQueryD3 += " AND SB1.B1_COD <> '" + cProdMNT + "'"
			cQueryD3 += " AND SB1.B1_COD <> '" + cProdTER + "'"
		EndIf
	EndIf	
	cQueryD3 += " AND SD3.D_E_L_E_T_=' '"	

	cQuerySub:= "SELECT 1 "

	If mv_par07 == 1
		cQuery2 := " AND NOT EXISTS (" + cQuerySub + cQueryD1
		cQuery2 += cQueryB1B
		cQuery2 += " AND "
		cQuery2 += cQueryB1C
		cQuery2 += ") AND NOT EXISTS ("
		cQuery2 += cQuerySub + cQueryD2
		cQuery2 += cQueryB1B
		cQuery2 += " AND "
		cQuery2 += cQueryB1C
		cQuery2 += ") AND NOT EXISTS ("
		cQuery2 += cQuerySub + cQueryD3
		cQuery2 += cQueryB1B
		cQuery2 += " AND "
		cQuery2 += cQueryB1C + ")"

		cUnion := "%"
		cUnion += " UNION SELECT 'SB1'"		// 01
		cUnion += ", SB1EXS.B1_COD"			// 02
		cUnion += ", SB1EXS.B1_TIPO"		// 03
		cUnion += ", SB1EXS.B1_UM"			// 04
		cUnion += ", SB1EXS.B1_GRUPO"		// 05
		cUnion += ", SB1EXS.B1_DESC"		// 06
		cUnion += ", SB1EXS.B1_POSIPI"		// 07
		cUnion += ", ''"					// 08
		cUnion += ", ''"					// 09
		cUnion += ", ''"					// 10
		cUnion += ", ''"					// 11
		cUnion += ", ''"					// 12
		cUnion += ", ''"					// 13
		cUnion += ", ''"					// 14
		cUnion += ", 0"						// 15
		cUnion += ", 0"						// 16
		cUnion += ", ''"					// 17
		cUnion += ", ''"					// 18
		cUnion += ", ''"					// 19
		cUnion += ", ''"					// 20
		cUnion += ", ''"					// 21
		cUnion += ", ''"					// 22
		cUnion += ", ''"					// 23
		cUnion += ", ''"					// 24
		cUnion += ", 0"						// 25
		cUnion += ", ''"					// 26
		If lVEIC
			cUnion += ", SB1EXS.B1_CODITE CODITE"	// 27
		EndIf
		cUnion += ", ''"					// 28
		cUnion += ", 0"						// 29
		cUnion += " FROM "+RetSqlName("SB1") + " SB1EXS WHERE"
		cUnion += cQueryB1D
		cUnion += cQuery2
		cUnion += "%"
	EndIf

	cOrder := "%"
	If nOrdem == 1
		If ! lVEIC
			cOrder += " 2,9,"
		Else
			cOrder += " 27, 9,"
		EndIf	
	ElseIf nOrdem == 2
		If ! lVEIC
			cOrder += " 3,2,9,"
		Else
			cOrder += " 3, 27, 9,"
		EndIf	
	EndIf
	If mv_par16 == 1
		//		cOrder += "17,12"+IIf(lVEIC,',29',',28')
		cOrder += "12"+IIf(lVEIC,',29',',28')
	Else
		If lCusUnif
			cOrder += "8,12"+IIf(lVEIC,',29',',28')
		Else
			//			cOrder += "17,8,12"+IIf(lVEIC,',29',',28')
			cOrder += "8"+IIf(lVEIC,',29',',28')
		EndIf
	EndIf	
	cOrder += "%"

	BeginSql Alias cAliasTop

		SELECT 	'SD1' ARQ, 				//-- 01 ARQ
		SB1.B1_COD PRODUTO, 	//-- 02 PRODUTO
		SB1.B1_TIPO TIPO, 		//-- 03 TIPO
		SB1.B1_UM,   			//-- 04 UM
		SB1.B1_GRUPO,      	//-- 05 GRUPO
		SB1.B1_DESC,      		//-- 06 DESCR
		SB1.B1_POSIPI, 		//-- 07
		D1_SEQCALC SEQCALC,    //-- 08
		D1_DTDIGIT DATA,		//-- 09 DATA
		D1_TES TES,			//-- 10 TES
		D1_CF CF,				//-- 11 CF
		D1_NUMSEQ SEQUENCIA,	//-- 12 SEQUENCIA
		D1_DOC DOCUMENTO,		//-- 13 DOCUMENTO
		D1_SERIE SERIE,		//-- 14 SERIE
		D1_QUANT QUANTIDADE,	//-- 15 QUANTIDADE
		D1_QTSEGUM QUANT2UM,	//-- 16 QUANT2UM
		D1_LOCAL ARMAZEM,		//-- 17 ARMAZEM
		' ' PROJETO,			//-- 18 PROJETO
		' ' OP,				//-- 19 OP
		' ' CC,				//-- 20 OP
		D1_FORNECE FORNECEDOR,	//-- 21 FORNECEDOR
		D1_LOJA LOJA,			//-- 22 LOJA
		' ' PEDIDO,            //-- 23 PEDIDO
		D1_TIPO TIPONF,		//-- 24 TIPO NF
		%Exp:cSelectD1%		//-- 25 CUSTO 
		' ' TRT 				//-- 26 TRT
		%Exp:cSelectVe%        //-- 27 CODITE
		D1_LOTECTL LOTE, 	    //-- 28 LOTE					 
		SD1.R_E_C_N_O_ NRECNO  //-- 29 RECNO

		FROM %table:SB1% SB1,%table:SD1% SD1,%table:SF4% SF4

		WHERE SB1.B1_COD     =  SD1.D1_COD		AND  	SD1.D1_FILIAL  =  %xFilial:SD1%		AND
		SF4.F4_FILIAL  =  %xFilial:SF4%  	AND 	SD1.D1_TES     =  SF4.F4_CODIGO		AND
		SF4.F4_ESTOQUE =  'S'				AND 	SD1.D1_DTDIGIT >= %Exp:mv_par05%   AND
		SD1.D1_DTDIGIT <= %Exp:mv_par06%	AND		SD1.D1_ORIGLAN <> 'LF'				   
		%Exp:cWhereD1%
		SD1.%NotDel%						AND 	SF4.%NotDel%                           
		%Exp:cWhereB1A%                   AND
		%Exp:cWhereB1C%

		UNION

		SELECT 'SD2',	     			
		SB1.B1_COD,	        	
		SB1.B1_TIPO,		    
		SB1.B1_UM,				
		SB1.B1_GRUPO,		    
		SB1.B1_DESC,		    
		SB1.B1_POSIPI,
		D2_SEQCALC,
		D2_EMISSAO,				
		D2_TES,					
		D2_CF,					
		D2_NUMSEQ,				
		D2_DOC,					
		D2_SERIE,				
		D2_QUANT,				
		D2_QTSEGUM,				
		D2_LOCAL,				
		' ',					
		' ',					
		' ',					
		D2_CLIENTE,				
		D2_LOJA,				
		D2_PEDIDO,
		D2_TIPO,				
		%Exp:cSelectD2%			
		' ' 					
		%Exp:cSelectVe%
		D2_LOTECTL,
		SD2.R_E_C_N_O_ SD2RECNO 	// 29

		FROM %table:SB1% SB1,%table:SD2% SD2,%table:SF4% SF4

		WHERE	SB1.B1_COD     =  SD2.D2_COD		AND	SD2.D2_FILIAL  = %xFilial:SD2%		AND
		SF4.F4_FILIAL  = %xFilial:SF4% 		AND	SD2.D2_TES     =  SF4.F4_CODIGO		AND
		SF4.F4_ESTOQUE =  'S'				AND	SD2.D2_EMISSAO >= %Exp:mv_par05%	AND
		SD2.D2_EMISSAO <= %Exp:mv_par06%	AND	SD2.D2_ORIGLAN <> 'LF'				   
		%Exp:cWhereD2%
		SD2.%NotDel%						AND SF4.%NotDel%						   
		%Exp:cWhereB1A%                     AND
		%Exp:cWhereB1C%

		UNION		

		SELECT 	'SD3',	    			
		SB1.B1_COD,	    	    
		SB1.B1_TIPO,		    
		SB1.B1_UM,				
		SB1.B1_GRUPO,	     	
		SB1.B1_DESC,		    
		SB1.B1_POSIPI,
		D3_SEQCALC,
		D3_EMISSAO,				
		D3_TM,					
		D3_CF,					
		D3_NUMSEQ,				
		D3_DOC,					
		' ',					
		D3_QUANT,				
		D3_QTSEGUM,				
		D3_LOCAL,				
		D3_PROJPMS,
		D3_OP,					
		D3_CC,
		' ',					
		' ',					
		' ',					
		' ',									
		%Exp:cSelectD3%			
		D3_TRT 
		%Exp:cSelectVe%
		D3_LOTECTL,
		SD3.R_E_C_N_O_ SD3RECNO 	// 29

		FROM %table:SB1% SB1,%table:SD3% SD3

		WHERE	SB1.B1_COD     =  SD3.D3_COD 		AND SD3.D3_FILIAL  =  %xFilial:SD3%		AND
		SD3.D3_EMISSAO >= %Exp:mv_par05%	AND	SD3.D3_EMISSAO <= %Exp:mv_par06%	AND
		%Exp:cWhereD3% 	
		SD3.%NotDel% 


		%Exp:cUnion%			

		ORDER BY %Exp:cOrder%

	EndSql 

	//������������������������������������������������������������������������Ŀ
	//�Metodo EndQuery ( Classe TRSection )                                    �
	//�                                                                        �
	//�Prepara o relat�rio para executar o Embedded SQL.                       �
	//�                                                                        �
	//�ExpA1 : Array com os parametros do tipo Range                           �
	//�                                                                        �
	//��������������������������������������������������������������������������
	oReport:Section(1):EndQuery(/*Array com os parametros do tipo Range*/)

	//������������������������������������������������������������������������Ŀ
	//�Inicio da impressao do fluxo do relat�rio                               �
	//��������������������������������������������������������������������������
	dbSelectArea(cAliasTop)
	oReport:SetMeter(nTotRegs)

	TcSetField(cAliasTop,DATA ,"D", TamSx3("D1_DTDIGIT")[1], TamSx3("D1_DTDIGIT")[2] )

	While !oReport:Cancel() .And. !(cAliasTop)->(Eof()) .And. lImpLivro

		If oReport:Cancel()
			Exit
		EndIf

		//��������������������������������������������������������������Ŀ
		//� Considera filtro escolhido                                   �
		//����������������������������������������������������������������
		If !Empty(cFilUser) .And. SUBSTR(cFilUser,2,2) == "B1"
			dbSelectArea("SB1")
			SB1->(dbSetOrder(1))
			SB1->(dbSeek(xFilial("SB1")+(cAliasTop)->PRODUTO))
			If !(&(cFilUser))
				dbSelectArea(cAliasTop)	 	    
				dbSkip()
				Loop
			EndIf  
		ElseIf !Empty(cFilUser) .And. SUBSTR(cFilUser,2,2) == "B2"
			dbSelectArea("SB2")
			SB2->(dbSetOrder(1))
			SB2->(dbSeek(xFilial("SB2")+(cAliasTop)->PRODUTO))
			If !(&(cFilUser))
				dbSelectArea(cAliasTop)	 	    
				dbSkip()
				Loop
			EndIf    
		EndIf

		dbSelectArea(cAliasTop)
		oReport:IncMeter()
		//��������������������������������������������������Ŀ
		//� Se nao encontrar no arquivo de saldos ,nao lista �
		//����������������������������������������������������
		dbSelectArea("SB2")
		If !dbSeek(xFilial("SB2")+(cAliasTop)->PRODUTO+If(lCusUnif,"",mv_par08))
			dbSelectArea(cAliasTop)
			dbSkip()
			Loop
		EndIf
		// Nao lista de saldo for igual a zero
		If mv_par20 == 2 .And. SB2->B2_QATU == 0
			dbSelectArea(cAliasTop)
			dbSkip()
			Loop
		EndIf
		// Nao lista de saldo for negativo
		If mv_par21 == 2 .And. SB2->B2_QATU < 0
			dbSelectArea(cAliasTop)
			dbSkip()
			Loop
		EndIf

		dbSelectArea(cAliasTop)
		cProdAnt  := (cAliasTop)->PRODUTO
		cLocalAnt := SB2->B2_LOCAL
		lFirst:=.F.

		//������������������������������������������������Ŀ
		//� Calcula o Saldo Inicial do Produto             �
		//��������������������������������������������������
		If lCusUnif
			aArea:=GetArea()
			aSalAtu  := { 0,0,0,0,0,0,0 }
			dbSelectArea("SB2")
			dbSetOrder(1)
			dbSeek(cSeek:=xFilial("SB2")+(cAliasTOP)->PRODUTO)
			While !Eof() .And. B2_FILIAL+B2_COD == cSeek
				aSalAlmox := CalcEst((cAliasTOP)->PRODUTO,SB2->B2_LOCAL,mv_par05)
				For i:=1 to Len(aSalAtu)
					aSalAtu[i] += aSalAlmox[i]
				Next i
				dbSkip()
			End
			RestArea(aArea)
		Else
			aSalAtu := CalcEst((cAliasTOP)->PRODUTO,mv_par08,mv_par05)
		EndIf

		If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
			aGrupos[nAcho][4] += aSalAtu[mv_par11+1]
		Else
			AADD(aGrupos,{(cAliasTOP)->TIPO,0,0,aSalAtu[mv_par11+1]})
		EndIf

		//������������������������������������������������Ŀ
		//� Calcula o Custo Medio do Produto               �
		//��������������������������������������������������
		If AsalAtu[1] > 0
			nCusmed := aSalAtu[mv_par11+1]/aSalAtu[1]
		ElseIf AsalAtu[1] == 0 .and. AsalAtu[mv_par11+1] == 0
			nCusMed := 0
		Else
			SB2->(dbSeek(xFilial("SB2") + (cAliasTOP)->PRODUTO + (cAliasTOP)->ARMAZEM))
			nCusmed := &("SB2->B2_CM" + Str(mv_par11,1))
		EndIf
		MR910ImpS1(aSalAtu,nCusMed,cAliasTop,lVEIC,lCusUnif,oSection1,oSection2)
		lFirst1 := .F.

		oSection3:Init() 
		While !oReport:Cancel() .And. !(cAliasTop)->(Eof()) .And. (cAliasTop)->PRODUTO = cProdAnt
			oReport:IncMeter()
			lContinua := .F.
			lImpSMov  := .F.
			lImpS3    := .F.
			If Alltrim((cAliasTop)->ARQ) $ "SD1/SD2"
				lFirst:=.T.
				SF4->(dbSeek(xFilial("SF4")+(cAliasTop)->TES))
				//��������������������������������������������������������������Ŀ
				//� Despreza Notas Fiscais Lancadas Pelo Modulo do Livro Fiscal  �
				//����������������������������������������������������������������
				//��������������������������������������������������������������Ŀ
				//� Executa ponto de entrada para verificar se considera TES que �
				//� NAO ATUALIZA saldos em estoque.                              �
				//����������������������������������������������������������������
				If lIxbConTes .And. SF4->F4_ESTOQUE != "S"
					lTesNEst := ExecBlock("MTAAVLTES",.F.,.F.)
					lTesNEst := If(ValType(lTesNEst) # "L",.F.,lTesNEst)
				EndIf
				If SF4->F4_ESTOQUE != "S" .And. !lTesNEst
					dbSkip()
					Loop
				EndIf
			ElseIf Alltrim((cAliasTop)->ARQ) == "SD3"
				lFirst:=.T.
				//����������������������������������������������������������������Ŀ
				//� Quando movimento ref apropr. indireta, so considera os         �
				//� movimentos com destino ao almoxarifado de apropriacao indireta.�
				//������������������������������������������������������������������
				lInverteMov:=.F.
				If (cAliasTop)->ARMAZEM != cLocalAnt .Or. lCusUnif
					If !(Substr((cAliasTop)->CF,3,1) == "3")
						If !lCusUnif
							dbSkip()
							Loop
						EndIf
					ElseIf lPriApropri
						lInverteMov:=.T.
					EndIf
				EndIf
				//����������������������������������������������������������������Ŀ
				//� Caso seja uma transferencia de localizacao verifica se lista   �
				//� o movimento ou nao                                             �
				//������������������������������������������������������������������
				If mv_par17 == 2 .And. Substr((cAliasTop)->CF,3,1) == "4"
					cNumSeqTr := (cAliasTOP)->(PRODUTO+SEQUENCIA+ARMAZEM)
					aDadosTran:={(cAliasTOP)->TES,(cAliasTOP)->QUANTIDADE,(cAliasTOP)->CUSTO,(cAliasTOP)->QUANT2UM,(cAliasTOP)->TIPO,;
					(cAliasTOP)->DATA,(cAliasTOP)->CF,(cAliasTOP)->SEQUENCIA,(cAliasTOP)->DOCUMENTO,(cAliasTOP)->PRODUTO,;
					(cAliasTOP)->OP,(cAliasTOP)->PROJETO,(cAliasTOP)->CC,(cAliasTOP)->ARQ}
					dbSkip()
					If (cAliasTOP)->(PRODUTO+SEQUENCIA+ARMAZEM) == cNumSeqTr
						dbSkip()
						Loop
					Else
						lContinua := .T.
						If lFirst
							oSection3:Cell("dDtMov"):SetValue(STOD(aDadosTran[6]))			
							oSection3:Cell("cTES"):SetValue(aDadosTran[1])										
							If ( cPaisLoc=="BRA" )
								oSection3:Cell("cCF"):Show()
								oSection3:Cell("cCF"):SetValue(aDadosTran[7])
								/*
								If	lInverteMov
								@Li , 018 PSay "*"
								EndIf
								*/
							Else
								oSection3:Cell("cCF"):Hide()
								oSection3:Cell("cCF"):SetValue("   ")
							EndIf
							If mv_par09 $ "Ss"
								oSection3:Cell("cDoc"):SetValue(aDadosTran[8])			
							Else
								oSection3:Cell("cDoc"):SetValue(aDadosTran[9])			
							Endif
						EndIf
						If aDadosTran[1] <= "500"
							oSection3:Cell("nENTQtd"):Show()
							oSection3:Cell("nENTCus"):Show()
							oSection3:Cell("nCusMov"):Show()

							oSection3:Cell("nENTQtd"):SetValue(aDadosTran[2])			
							oSection3:Cell("nENTCus"):SetValue(aDadosTran[3])			
							oSection3:Cell("nCusMov"):SetValue(aDadosTran[3] / aDadosTran[2])			

							oSection3:Cell("nSAIQtd"):Hide()
							oSection3:Cell("nSAICus"):Hide()
							oSection3:Cell("nSAIQtd"):SetValue(0)			
							oSection3:Cell("nSAICus"):SetValue(0)			

							aSalAtu[1] += aDadosTran[2]
							aSalAtu[mv_par11+1] += aDadosTran[3]
							aSalAtu[7] += aDadosTran[4]

							If (nAcho := ASCAN(aGrupos,{|x| aDadosTran[5] == x[1]})) > 0
								aGrupos[nAcho][2]+=aDadosTran[3]
								aGrupos[nAcho][4]+=aDadosTran[3]
							Else
								AADD(aGrupos,{aDadosTran[5],aDadosTran[3],0,aSalAtu[mv_par11+1]})
							EndIf
						Else
							oSection3:Cell("nENTQtd"):Hide()
							oSection3:Cell("nENTCus"):Hide()
							oSection3:Cell("nENTQtd"):SetValue(0)
							oSection3:Cell("nENTCus"):SetValue(0)

							oSection3:Cell("nCusMov"):Show()
							oSection3:Cell("nSAIQtd"):Show()
							oSection3:Cell("nSAICus"):Show()

							oSection3:Cell("nCusMov"):SetValue(aDadosTran[3] / aDadosTran[2])			
							oSection3:Cell("nSAIQtd"):SetValue(aDadosTran[2])			
							oSection3:Cell("nSAICus"):SetValue(aDadosTran[3])			

							aSalAtu[1] -= aDadosTran[2]
							aSalAtu[mv_par11+1] -= aDadosTran[3]
							aSalAtu[7] -= aDadosTran[4]
							If (nAcho := ASCAN(aGrupos,{|x| aDadosTran[5] == x[1]})) > 0
								aGrupos[nAcho][3]+=aDadosTran[3]
								aGrupos[nAcho][4]-=aDadosTran[3]
							Else
								AADD(aGrupos,{aDadosTran[5],0,aDadosTran[3],-(aSalAtu[mv_par11+1])})
							EndIf
						EndIf
					EndIf
				EndIf
			EndIf	
			If lFirst .And. !lContinua
				oSection3:Cell("dDtMov"):SetValue(STOD(DATA))			
				oSection3:Cell("cTES"):SetValue(TES)														
				If ( cPaisLoc=="BRA" )
					oSection3:Cell("cCF"):Show()
					oSection3:Cell("cCF"):SetValue(CF)					
					/*
					If	lInverteMov
					@Li , 018 PSay "*"
					EndIf
					*/
				Else
					oSection3:Cell("cCF"):Hide()
					oSection3:Cell("cCF"):SetValue("   ")				
				EndIf
				If mv_par09 $ "Ss"
					oSection3:Cell("cDoc"):SetValue(SEQUENCIA)			
				Else
					oSection3:Cell("cDoc"):SetValue(DOCUMENTO)						
				Endif	
			EndIf

			Do Case
				Case Alltrim((cAliasTop)->ARQ) == "SD1" .And. !lContinua
				lDev:=MTR910Dev(cAliasTop)
				If (cAliasTOP)->TES <= "500" .And. !lDev
					If (cAliasTOP)->TIPONF != "C"
						oSection3:Cell("nCusMov"):SetValue((cAliasTOP)->CUSTO / (cAliasTOP)->QUANTIDADE)
						oSection3:Cell("nCusMov"):Show()
					Else
						oSection3:Cell("nCusMov"):SetValue(0)
						oSection3:Cell("nCusMov"):Hide()
					EndIf

					oSection3:Cell("nENTQtd"):Show()
					oSection3:Cell("nENTCus"):Show()

					oSection3:Cell("nENTQtd"):SetValue((cAliasTOP)->QUANTIDADE)			
					oSection3:Cell("nENTCus"):SetValue((cAliasTOP)->CUSTO)			

					oSection3:Cell("nSAIQtd"):Hide()
					oSection3:Cell("nSAICus"):Hide()						
					oSection3:Cell("nSAIQtd"):SetValue(0)
					oSection3:Cell("nSAICus"):SetValue(0)

					aSalAtu[1] += (cAliasTOP)->QUANTIDADE
					aSalAtu[mv_par11+1] += (cAliasTOP)->CUSTO
					aSalAtu[7] += (cAliasTOP)->QUANT2UM
					If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
						aGrupos[nAcho][2]+=(cAliasTOP)->CUSTO
						aGrupos[nAcho][4]+=(cAliasTOP)->CUSTO
					Else
						AADD(aGrupos,{(cAliasTOP)->TIPO,(cAliasTOP)->CUSTO,0,aSalAtu[mv_par11+1]})
					EndIf
				Else
					If (cAliasTOP)->TIPONF != "C"
						oSection3:Cell("nCusMov"):SetValue((cAliasTOP)->CUSTO / (cAliasTOP)->QUANTIDADE)			
						oSection3:Cell("nCusMov"):Show()
					Else
						oSection3:Cell("nCusMov"):SetValue(0)									
						oSection3:Cell("nCusMov"):Hide()
					EndIf

					oSection3:Cell("nENTQtd"):Hide()
					oSection3:Cell("nENTCus"):Hide()
					oSection3:Cell("nENTQtd"):SetValue(0)
					oSection3:Cell("nENTCus"):SetValue(0)

					oSection3:Cell("nSAIQtd"):Show()
					oSection3:Cell("nSAICus"):Show()

					If lDev

						oSection3:Cell("nSAIQtd"):SetValue((cAliasTOP)->QUANTIDADE * -1)
						oSection3:Cell("nSAICus"):SetValue((cAliasTOP)->CUSTO * -1)

						aSalAtu[1] += (cAliasTOP)->QUANTIDADE
						aSalAtu[mv_par11+1] += (cAliasTOP)->CUSTO
						aSalAtu[7] += (cAliasTOP)->QUANT2UM
						If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
							aGrupos[nAcho][3]-=(cAliasTOP)->CUSTO
							aGrupos[nAcho][4]+=(cAliasTOP)->CUSTO
						Else
							AADD(aGrupos,{(cAliasTOP)->TIPO,0,-((cAliasTOP)->CUSTO),aSalAtu[mv_par11+1]})
						EndIf
					Else
						oSection3:Cell("nSAIQtd"):SetValue((cAliasTOP)->QUANTIDADE)			
						oSection3:Cell("nSAICus"):SetValue((cAliasTOP)->CUSTO)																

						aSalAtu[1] -= (cAliasTOP)->QUANTIDADE
						aSalAtu[mv_par11+1] -= (cAliasTOP)->CUSTO
						aSalAtu[7] -= (cAliasTOP)->QUANT2UM
						If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
							aGrupos[nAcho][3]+=(cAliasTOP)->CUSTO
							aGrupos[nAcho][4]-=(cAliasTOP)->CUSTO
						Else
							AADD(aGrupos,{(cAliasTOP)->TIPO,0,(cAliasTOP)->CUSTO,-(aSalAtu[mv_par11+1])})
						EndIf
					EndIf
				EndIf
				Case Alltrim((cAliasTop)->ARQ) = "SD2" .And. !lContinua
				lDev:=MTR910Dev(cAliasTop)
				If (cAliasTOP)->TES <= "500" .Or. lDev
					If lDev

						oSection3:Cell("nENTQtd"):Show()
						oSection3:Cell("nENTCus"):Show()

						oSection3:Cell("nENTQtd"):SetValue((cAliasTOP)->QUANTIDADE * -1)
						oSection3:Cell("nENTCus"):SetValue((cAliasTOP)->CUSTO * -1)

						aSalAtu[1] -= (cAliasTOP)->QUANTIDADE
						aSalAtu[mv_par11+1] -= (cAliasTOP)->CUSTO
						aSalAtu[7] -= (cAliasTOP)->QUANT2UM
						If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
							aGrupos[nAcho][2]-=(cAliasTOP)->CUSTO
							aGrupos[nAcho][4]-=(cAliasTOP)->CUSTO
						Else
							AADD(aGrupos,{(cAliasTOP)->TIPO,-((cAliasTOP)->CUSTO),0,-(aSalAtu[mv_par11+1])})
						EndIf
					Else
						oSection3:Cell("nENTQtd"):Show()
						oSection3:Cell("nENTCus"):Show()

						oSection3:Cell("nENTQtd"):SetValue((cAliasTOP)->QUANTIDADE)			
						oSection3:Cell("nENTCus"):SetValue((cAliasTOP)->CUSTO)										

						aSalAtu[1] += (cAliasTOP)->QUANTIDADE
						aSalAtu[mv_par11+1] += (cAliasTOP)->CUSTO
						aSalAtu[7] += (cAliasTOP)->QUANT2UM
						If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
							aGrupos[nAcho][2]+=(cAliasTOP)->CUSTO
							aGrupos[nAcho][4]+=(cAliasTOP)->CUSTO
						Else
							AADD(aGrupos,{(cAliasTOP)->TIPO,(cAliasTOP)->CUSTO,0,aSalAtu[mv_par11+1]})
						EndIf
					EndIf

					If (cAliasTOP)->TIPONF != "C"
						oSection3:Cell("nCusMov"):SetValue((cAliasTOP)->CUSTO / (cAliasTOP)->QUANTIDADE)																
						oSection3:Cell("nCusMov"):Show()
					Else
						oSection3:Cell("nCusMov"):SetValue(0)
						oSection3:Cell("nCusMov"):Hide()
					EndIf
					oSection3:Cell("nSAIQtd"):Hide()
					oSection3:Cell("nSAICus"):Hide()
					oSection3:Cell("nSAIQtd"):SetValue(0)
					oSection3:Cell("nSAICus"):SetValue(0)
				Else
					If (cAliasTOP)->TIPONF != "C"
						oSection3:Cell("nCusMov"):SetValue((cAliasTOP)->CUSTO / (cAliasTOP)->QUANTIDADE)																
						oSection3:Cell("nCusMov"):Show()
					Else
						oSection3:Cell("nCusMov"):SetValue(0)																						
						oSection3:Cell("nCusMov"):Hide()
					EndIf						

					oSection3:Cell("nENTQtd"):Hide()
					oSection3:Cell("nENTCus"):Hide()
					oSection3:Cell("nENTQtd"):SetValue(0)
					oSection3:Cell("nENTCus"):SetValue(0)

					oSection3:Cell("nSAIQtd"):Show()
					oSection3:Cell("nSAICus"):Show()

					oSection3:Cell("nSAIQtd"):SetValue((cAliasTOP)->QUANTIDADE)			
					oSection3:Cell("nSAICus"):SetValue((cAliasTOP)->CUSTO)																						

					aSalAtu[1] -= (cAliasTOP)->QUANTIDADE
					aSalAtu[mv_par11+1] -= (cAliasTOP)->CUSTO
					aSalAtu[7] -= (cAliasTOP)->QUANT2UM
					If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
						aGrupos[nAcho][3]+=(cAliasTOP)->CUSTO
						aGrupos[nAcho][4]-=(cAliasTOP)->CUSTO
					Else
						AADD(aGrupos,{(cAliasTOP)->TIPO,0,(cAliasTOP)->CUSTO,-(aSalAtu[mv_par11+1])})
					EndIf
				EndIf
				Case Alltrim((cAliasTop)->ARQ) == "SD3" .And. !lContinua
				lDev := .F.
				If	lInverteMov
					If (cAliasTOP)->TES > "500"

						oSection3:Cell("nENTQtd"):Show()
						oSection3:Cell("nENTCus"):Show()
						oSection3:Cell("nCusMov"):Show()

						oSection3:Cell("nENTQtd"):SetValue((cAliasTOP)->QUANTIDADE)			
						oSection3:Cell("nENTCus"):SetValue((cAliasTOP)->CUSTO)			
						oSection3:Cell("nCusMov"):SetValue((cAliasTOP)->CUSTO / (cAliasTOP)->QUANTIDADE)										

						oSection3:Cell("nSAIQtd"):Hide()
						oSection3:Cell("nSAICus"):Hide()							
						oSection3:Cell("nSAIQtd"):SetValue(0)
						oSection3:Cell("nSAICus"):SetValue(0)														

						aSalAtu[1] += (cAliasTOP)->QUANTIDADE
						aSalAtu[mv_par11+1] += (cAliasTOP)->CUSTO
						aSalAtu[7] += (cAliasTOP)->QUANT2UM
						If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
							aGrupos[nAcho][2]+=(cAliasTOP)->CUSTO
							aGrupos[nAcho][4]+=(cAliasTOP)->CUSTO
						Else
							AADD(aGrupos,{(cAliasTOP)->TIPO,(cAliasTOP)->CUSTO,0,aSalAtu[mv_par11+1]})
						EndIf
					Else
						oSection3:Cell("nENTQtd"):Hide()
						oSection3:Cell("nENTCus"):Hide()
						oSection3:Cell("nENTQtd"):SetValue(0)
						oSection3:Cell("nENTCus"):SetValue(0)

						oSection3:Cell("nCusMov"):Show()
						oSection3:Cell("nSAIQtd"):Show()
						oSection3:Cell("nSAICus"):Show()

						oSection3:Cell("nCusMov"):SetValue((cAliasTOP)->CUSTO / (cAliasTOP)->QUANTIDADE)			
						oSection3:Cell("nSAIQtd"):SetValue((cAliasTOP)->QUANTIDADE)			
						oSection3:Cell("nSAICus"):SetValue((cAliasTOP)->CUSTO)										

						aSalAtu[1] -= (cAliasTOP)->QUANTIDADE
						aSalAtu[mv_par11+1] -= (cAliasTOP)->CUSTO
						aSalAtu[7] -= (cAliasTOP)->QUANT2UM
						If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
							aGrupos[nAcho][3]+=(cAliasTOP)->CUSTO
							aGrupos[nAcho][4]-=(cAliasTOP)->CUSTO
						Else
							AADD(aGrupos,{(cAliasTOP)->TIPO,0,(cAliasTOP)->CUSTO,-(aSalAtu[mv_par11+1])})
						EndIf
					EndIf 
					If lCusUnif
						lPriApropri:=.F.
					EndIf
				Else
					If (cAliasTOP)->TES <= "500"

						oSection3:Cell("nENTQtd"):Show()
						oSection3:Cell("nENTCus"):Show()
						oSection3:Cell("nCusMov"):Show()

						oSection3:Cell("nENTQtd"):SetValue((cAliasTOP)->QUANTIDADE)			
						oSection3:Cell("nENTCus"):SetValue((cAliasTOP)->CUSTO)			
						oSection3:Cell("nCusMov"):SetValue((cAliasTOP)->CUSTO / (cAliasTOP)->QUANTIDADE)																	

						oSection3:Cell("nSAIQtd"):Hide()
						oSection3:Cell("nSAICus"):Hide()							
						oSection3:Cell("nSAIQtd"):SetValue(0)
						oSection3:Cell("nSAICus"):SetValue(0)

						aSalAtu[1] += (cAliasTOP)->QUANTIDADE
						aSalAtu[mv_par11+1] += (cAliasTOP)->CUSTO
						aSalAtu[7] += (cAliasTOP)->QUANT2UM
						If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
							aGrupos[nAcho][2]+=(cAliasTOP)->CUSTO
							aGrupos[nAcho][4]+=(cAliasTOP)->CUSTO
						Else
							AADD(aGrupos,{(cAliasTOP)->TIPO,(cAliasTOP)->CUSTO,0,aSalAtu[mv_par11+1]})
						EndIf
					Else

						oSection3:Cell("nENTQtd"):Hide()
						oSection3:Cell("nENTCus"):Hide()
						oSection3:Cell("nENTQtd"):SetValue(0)
						oSection3:Cell("nENTCus"):SetValue(0)

						oSection3:Cell("nCusMov"):Show()
						oSection3:Cell("nSAIQtd"):Show()
						oSection3:Cell("nSAICus"):Show()

						oSection3:Cell("nCusMov"):SetValue((cAliasTOP)->CUSTO / (cAliasTOP)->QUANTIDADE)			
						oSection3:Cell("nSAIQtd"):SetValue((cAliasTOP)->QUANTIDADE)			
						oSection3:Cell("nSAICus"):SetValue((cAliasTOP)->CUSTO)																	

						aSalAtu[1] -= (cAliasTOP)->QUANTIDADE
						aSalAtu[mv_par11+1] -= (cAliasTOP)->CUSTO
						aSalAtu[7] -= (cAliasTOP)->QUANT2UM
						If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
							aGrupos[nAcho][3]+=(cAliasTOP)->CUSTO
							aGrupos[nAcho][4]-=(cAliasTOP)->CUSTO
						Else
							AADD(aGrupos,{(cAliasTOP)->TIPO,0,(cAliasTOP)->CUSTO,-(aSalAtu[mv_par11+1])})
						EndIf
					EndIf
					If lCusUnif
						lPriApropri:=.T.
					EndIf
				EndIf
			EndCase
			If lFirst
				oSection3:Cell("nSALDQtd"):SetValue(aSalAtu[1])			
				oSection3:Cell("nSALDCus"):SetValue(aSalAtu[mv_par11+1])			
			EndIf
			Do Case
				Case Alltrim((cAliasTop)->ARQ) == "SD3" .And. !lContinua
				If Empty((cAliasTOP)->OP) .And. Empty((cAliasTOP)->PROJETO)
					oSection3:Cell("cCCPVPJOP"):SetValue('CC'+(cAliasTOP)->CC)			
				ElseIf !Empty((cAliasTOP)->PROJETO)
					oSection3:Cell("cCCPVPJOP"):SetValue('PJ'+(cAliasTOP)->PROJETO)
				ElseIf !Empty((cAliasTOP)->OP)
					oSection3:Cell("cCCPVPJOP"):SetValue('OP'+(cAliasTOP)->OP)
				EndIf
				Case Alltrim((cAliasTop)->ARQ) == "SD1" .And. !lContinua
				oSection3:Cell("cCCPVPJOP"):SetValue('F-'+(cAliasTOP)->FORNECEDOR)
				Case Alltrim((cAliasTop)->ARQ) == "SD2" .And. !lContinua
				oSection3:Cell("cCCPVPJOP"):SetValue('P-'+(cAliasTOP)->PEDIDO)					
				Case lContinua .And. aDadosTran[14] == "SD3"
				If Empty(aDadosTran[11]) .And. Empty(aDadosTran[12])
					oSection3:Cell("cCCPVPJOP"):SetValue('CC'+aDadosTran[13])	
				ElseIf !Empty(aDadosTran[12])
					oSection3:Cell("cCCPVPJOP"):SetValue('PJ'+aDadosTran[12])
				ElseIf !Empty(aDadosTran[11])
					oSection3:Cell("cCCPVPJOP"):SetValue('OP'+aDadosTran[11])
				EndIf
			EndCase

			If lFirst
				oSection3:PrintLine()
			Endif	

			If !lInverteMov .Or. (lInverteMov .And. lPriApropri)
				If !lContinua //Acerto para utilizar o Array aDadosTran[]
					dbSkip()
				EndIf
			EndIf
		EndDo

		If lFirst
			oReport:PrintText(STR0018+TransForm(aSalAtu[7],cPicB2Qt2),,oSection3:Cell('nSAICus'):ColPos()) //"QTD. NA SEGUNDA UM: "											
			lImpS3 := .T.
		Else
			If !MTR910IsMNT()
				oReport:PrintText(STR0019)	//"NAO HOUVE MOVIMENTACAO PARA ESTE PRODUTO"
				oReport:ThinLine()
				lImpSMov := .T.
			Else
				If FindFunction("NGProdMNT")
					aProdsMNT := aClone(NGProdMNT())
					If aScan(aProdsMNT, {|x| AllTrim(x) == AllTrim(SB1->B1_COD) }) == 0
						oReport:PrintText(STR0019)	//"NAO HOUVE MOVIMENTACAO PARA ESTE PRODUTO"
						oReport:ThinLine()
						lImpSMov := .T.
					EndIf
				ElseIf SB1->B1_COD <> cProdMNT .and. SB1->B1_COD <> cProdTER
					oReport:PrintText(STR0019)	//"NAO HOUVE MOVIMENTACAO PARA ESTE PRODUTO"
					oReport:ThinLine()
					lImpSMov := .T.
				EndIf
			EndIf	
		EndIf

		oSection1:Finish()
		oSection2:Finish()
		If !lImpSMov .And. lImpS3
			oSection3:Finish()				
		Endif	
	EndDo
	dbSelectArea(cAliasTop)

	If !Empty(aGrupos)
		oReport:SkipLine()    
		oReport:PrintText(STR0020) //"R E S U M O"
		oReport:SkipLine()    
		dbSelectArea("SX5")
		For i:=1 to Len(aGrupos)
			dbSeek(xFilial("SX5")+"02"+aGrupos[i][1])
			oReport:PrintText(X5Descri(),oReport:Row())
			oReport:PrintText(TransForm(aGrupos[i][2],cPicD1Cust),oReport:Row(),oSection3:Cell('nENTCus'):ColPos())														
			oReport:PrintText(TransForm(aGrupos[i][3],cPicD2Cust),oReport:Row(),oSection3:Cell('nSAICus'):ColPos())
			oReport:PrintText(TransForm(aGrupos[i][4],cPicB2Cust),oReport:Row(),oSection3:Cell('nSALDCus'):ColPos())			
			oReport:SkipLine()    
		Next i
	EndIf	

	#ELSE
	//��������������������������������������������������������������Ŀ
	//� Seta ordens dos arquivos de movimentos e monta IndRegua      �
	//����������������������������������������������������������������
	If mv_par16 == 1
		If lCusUnif
			dbSelectArea("SD1")
			cIndice:="D1_FILIAL+D1_COD+DTOS(D1_DTDIGIT)+D1_NUMSEQ"
			IndRegua("SD1",cTrbSD1,cIndice,,DBFilter())
			nInd := RetIndex("SD1")
			#IFNDEF TOP
			dbSetIndex(cTrbSD1+OrdBagExt())
			#ENDIF
			dbSetOrder(nInd+1)

			dbSelectArea("SD2")
			cIndice:="D2_FILIAL+D2_COD+DTOS(D2_EMISSAO)+D2_NUMSEQ"
			IndRegua("SD2",cTrbSD2,cIndice,,DBFilter())
			nInd := RetIndex("SD2")
			#IFNDEF TOP
			dbSetIndex(cTrbSD2+OrdBagExt())
			#ENDIF
			dbSetOrder(nInd+1)

			dbSelectArea("SD3")
			cIndice:="D3_FILIAL+D3_COD+DTOS(D3_EMISSAO)+D3_NUMSEQ"
			IndRegua("SD3",cTrbSD3,cIndice,,DBFilter())
			nInd := RetIndex("SD3")
			#IFNDEF TOP
			dbSetIndex(cTrbSD3+OrdBagExt())
			#ENDIF
			dbSetOrder(nInd+1)
		Else
			dbSelectArea("SD1")
			dbSetOrder(7)
			dbSelectArea("SD2")
			dbSetOrder(6)
			dbSelectArea("SD3")
			dbSetOrder(7)
			If lLocProc
				cIndice:="D3_FILIAL+D3_COD+DTOS(D3_EMISSAO)+D3_NUMSEQ"
				IndRegua("SD3",cTrbSD3,cIndice,,DBFilter(),STR0029)	//"Selecionando Registros"
				nInd := RetIndex("SD3")
				#IFNDEF TOP
				dbSetIndex(cTrbSD3+OrdBagExt())
				#ENDIF
				dbSetOrder(nInd+1)
			EndIf
		EndIf
	Else
		dbSelectArea("SD1")
		If lCusUnif
			cIndice:="D1_FILIAL+D1_COD+DTOS(D1_DTDIGIT)+D1_SEQCALC+D1_NUMSEQ"
		Else
			cIndice:="D1_FILIAL+D1_COD+D1_LOCAL+DTOS(D1_DTDIGIT)+D1_SEQCALC+D1_NUMSEQ"
		EndIf
		IndRegua("SD1",cTrbSD1,cIndice,,DBFilter(),STR0029)	//"Selecionando Registros"
		nInd := RetIndex("SD1")
		#IFNDEF TOP
		dbSetIndex(cTrbSD1+OrdBagExt())
		#ENDIF
		dbSetOrder(nInd+1)

		dbSelectArea("SD2")
		If lCusUnif
			cIndice:="D2_FILIAL+D2_COD+DTOS(D2_EMISSAO)+D2_SEQCALC+D2_NUMSEQ"
		Else
			cIndice:="D2_FILIAL+D2_COD+D2_LOCAL+DTOS(D2_EMISSAO)+D2_SEQCALC+D2_NUMSEQ"
		EndIf
		IndRegua("SD2",cTrbSD2,cIndice,,DBFilter(),STR0029)	//"Selecionando Registros"
		nInd := RetIndex("SD2")
		#IFNDEF TOP
		dbSetIndex(cTrbSD2+OrdBagExt())
		#ENDIF
		dbSetOrder(nInd+1)

		dbSelectArea("SD3")
		If lCusUnif
			cIndice:="D3_FILIAL+D3_COD+DTOS(D3_EMISSAO)+D3_SEQCALC+D3_NUMSEQ"
		Else
			If lLocProc
				cIndice:="D3_FILIAL+D3_COD+DTOS(D3_EMISSAO)+D3_SEQCALC+D3_NUMSEQ"
			Else
				cIndice:="D3_FILIAL+D3_COD+D3_LOCAL+DTOS(D3_EMISSAO)+D3_SEQCALC+D3_NUMSEQ"
			EndIf
		EndIf
		IndRegua("SD3",cTrbSD3,cIndice,,DBFilter(),STR0029)	//"Selecionando Registros"
		nInd := RetIndex("SD3")
		#IFNDEF TOP
		dbSetIndex(cTrbSD3+OrdBagExt())
		#ENDIF
		dbSetOrder(nInd+1)
	EndIf

	dbSelectArea("SB1")
	If ! lVEIC
		If nOrdem == 1
			dbSetOrder(1)
			cOrder := IndexKey()
		ElseIf nOrdem == 2
			dbSetOrder(2)
			cOrder := IndexKey()
		EndIf
	Else
		If nOrdem == 1
			cOrder := "B1_FILIAL+B1_CODITE"
		ElseIf nOrdem == 2
			cOrder := "B1_FILIAL+B1_TIPO+B1_CODITE"
		EndIf	
	EndIf	
	//������������������������������������������������������������������������Ŀ
	//�Transforma parametros Range em expressao Advpl                          �
	//��������������������������������������������������������������������������
	MakeAdvplExpr(oReport:uParam)

	cCondicao := 'B1_FILIAL == "'+xFilial("SB1")+'".And.' 
	cCondicao += 'B1_TIPO >= "'+mv_par03+'".And.B1_TIPO <="'+mv_par04+'".And.'
	If ! lVEIC
		cCondicao += 'B1_COD >= "'+mv_par01+'".And.B1_COD <="'+mv_par02+'".And.'
	Else
		cCondicao += 'B1_CODITE >= "'+mv_par01+'".And.B1_CODITE <="'+mv_par02+'".And.'
	Endif	
	cCondicao += 'B1_GRUPO >= "'+mv_par18+'".And.B1_GRUPO <="'+mv_par19+'".And.'	
	cCondicao += 'B1_COD <> "'+Substr(cProdImp,1,Len(B1_COD))+'"'

	oReport:Section(1):SetFilter(cCondicao,cOrder)

	dbSelectArea("SB1")
	oReport:SetMeter(nTotRegs)

	While !oReport:Cancel() .And. SB1->(!Eof()) .And. lImpLivro

		If oReport:Cancel()
			Exit
		EndIf

		oReport:IncMeter()

		dbSelectArea("SB2")
		//��������������������������������������������������Ŀ
		//� Se nao encontrar no arquivo de saldos ,nao lista �
		//����������������������������������������������������
		If !dbSeek(xFilial("SB2")+SB1->B1_COD+IF(lCusUnif,"",mv_par08))
			dbSelectArea("SB1")
			dbSkip()
			Loop
		EndIf

		// Nao lista de saldo for igual a zero
		If mv_par20 == 2 .And. SB2->B2_QATU == 0
			dbSelectArea("SB1")
			dbSkip()
			Loop
		EndIf

		// Nao lista de saldo for negativo
		If mv_par21 == 2 .And. SB2->B2_QATU < 0
			dbSelectArea("SB1")
			dbSkip()
			Loop
		EndIf

		aSalAtu   := { 0,0,0,0,0,0,0 }
		//������������������������������������������������Ŀ
		//� Calcula o Saldo Inicial do Produto             �
		//��������������������������������������������������
		If lCusUnif
			aArea:=GetArea()
			dbSelectArea("SB2")
			dbSetOrder(1)
			dbSeek(xFilial("SB2")+SB1->B1_COD)
			While !Eof() .And. B2_FILIAL+B2_COD == xFilial("SB2")+SB1->B1_COD
				aSalAlmox := CalcEst(SB1->B1_COD,SB2->B2_LOCAL,mv_par05)
				For i:=1 to Len(aSalAtu)
					aSalAtu[i] += aSalAlmox[i]
				Next i
				dbSkip()
			End
			RestArea(aArea)
		Else
			aSalAtu := CalcEst(SB1->B1_COD,mv_par08,mv_par05)
		EndIf

		cProdAnt  := SB1->B1_COD
		cLocalAnt := mv_par08
		dCntData  := mv_par05
		nRec1 := nRec2 := nRec3 := 0
		nCusMed   := 0
		lFirst1   := .T.

		dbSelectArea("SF1")
		dbSetOrder(1)
		dbSelectArea("SF2")
		dbSetOrder(1)
		dbSelectArea("SD1")
		dbSeek(xFilial("SD1")+SB1->B1_COD+If(lCusUnif,"",mv_par08)+dtos(dcntData),.T.)
		dbSelectArea("SD2")
		dbSeek(xFilial("SD2")+SB1->B1_COD+If(lCusUnif,"",mv_par08)+dtos(dcntData),.T.)
		dbSelectArea("SD3")
		dbSeek(xFilial("SD3")+SB1->B1_COD+If(lCusUnif.Or.lLocProc,"",mv_par08)+dtos(dcntData),.T.)

		oSection3:Init() 
		While .T.
			lImpSMov := .F.
			lImpS3   := .F.
			dbSelectArea("SD1")
			If !Eof() .And. D1_FILIAL == xFilial("SD1") .And. D1_DTDIGIT == dCntData .And. D1_COD == cProdAnt .And. If(lCusUnif,.T.,D1_LOCAL == cLocalAnt)

				//��������������������������������������������������������������Ŀ
				//� Despreza Notas Fiscais Lancadas Pelo Modulo do Livro Fiscal  �
				//����������������������������������������������������������������
				If D1_ORIGLAN $ "LF"
					dbSkip()
					Loop
				EndIf

				//������������������������������������������������Ŀ
				//� Verifica se o TES atualiza estoque             �
				//��������������������������������������������������
				dbSelectArea("SF4")
				dbSeek(xFilial("SF4")+SD1->D1_TES)
				dbSelectArea("SD1")
				//��������������������������������������������������������������Ŀ
				//� Executa ponto de entrada para verificar se considera TES que �
				//� NAO ATUALIZA saldos em estoque.                              �
				//����������������������������������������������������������������
				If lIxbConTes .And. SF4->F4_ESTOQUE != "S"
					lTesNEst := ExecBlock("MTAAVLTES",.F.,.F.)
					lTesNEst := If(ValType(lTesNEst) # "L",.F.,lTesNEst)
				EndIf
				If (SF4->F4_ESTOQUE != "S" .And. !lTesNEst)
					dbSkip()
					Loop
				EndIf
				cSeqIni := IIF(mv_par16==1,D1_NUMSEQ,D1_SEQCALC+D1_NUMSEQ)
				cAlias := Alias()
			EndIf

			dbSelectArea("SD3")
			If !Eof() .And. D3_FILIAL == xFilial("SD3") .And. D3_EMISSAO == dCntData .And. D3_COD == cProdAnt .And. If(lCusUnif.Or.lLocProc,.T.,D3_LOCAL == cLocalAnt)
				//����������������������������������������������������������������Ŀ
				//� Quando movimento ref apropr. indireta, so considera os         �
				//� movimentos com destino ao almoxarifado de apropriacao indireta.�
				//������������������������������������������������������������������
				lInverteMov:=.F.
				If !D3Valido()
					dbSkip()
					Loop
				EndIf
				If D3_LOCAL != cLocalAnt .Or. lCusUnif
					If !(Substr(D3_CF,3,1) == "3")
						If !lCusUnif
							dbSkip()
							Loop
						EndIf
					ElseIf lPriApropri
						lInverteMov:=.T.
					EndIf
				EndIf
				//����������������������������������������������������������������Ŀ
				//� Caso seja uma transferencia de localizacao verifica se lista   �
				//� o movimento ou nao                                             �
				//������������������������������������������������������������������
				nRecTrf1 := 0
				nRecTrf2 := 0
				If mv_par17 == 2 .And. Substr(D3_CF,3,1) == "4"
					If Len(aRecTRF)>0 .And. (aScan(aRecTRF, SD3->(Recno()))>0)
						SD3->(dbSkip())
						Loop
					EndIf
					cNumSeqTr := SD3->D3_COD+SD3->D3_NUMSEQ+SD3->D3_LOCAL//"E9"
					nRegTr    := Recno()
					aAreaSD3  := GetArea()
					SD3->(dbSetOrder(4))
					SD3->(dbGoTo(nRegTr))
					nRecTrf1 := SD3->(Recno())
					dbSkip()
					If SD3->D3_COD+SD3->D3_NUMSEQ+SD3->D3_LOCAL == cNumSeqTr//SD3->D3_CHAVE == cNumSeqTr
						nRecTrf2 := SD3->(Recno())
						aAdd(aRecTRF, nRecTrf1)
						aAdd(aRecTRF, nRecTrf2)
						RestArea(aAreaSD3)
						Loop
					Else
						RestArea(aAreaSD3)
					EndIf
				EndIf
				If mv_par16 == 1
					If D3_NUMSEQ < cSeqIni
						cSeqIni := D3_NUMSEQ
						cAlias := Alias()
					EndIf
				Else
					If D3_SEQCALC+D3_NUMSEQ < cSeqIni
						cSeqIni := D3_SEQCALC+D3_NUMSEQ
						cAlias := Alias()
					EndIf
				EndIf
			EndIf

			dbSelectArea("SD2")
			If !Eof() .And. D2_FILIAL == xFilial("SD2") .And. D2_EMISSAO == dCntData .And. D2_COD == cProdAnt .And. If(lCusUnif,.T.,D2_LOCAL == cLocalAnt)

				//��������������������������������������������������������������Ŀ
				//� Despreza Notas Fiscais Lancadas Pelo Modulo do Livro Fiscal  �
				//����������������������������������������������������������������
				If D2_ORIGLAN == "LF"
					dbSkip()
					Loop
				EndIf

				//������������������������������������������������Ŀ
				//� Verifica se o TES atualiza estoque             �
				//��������������������������������������������������
				dbSelectArea("SF4")
				dbSeek(xFilial("SF4")+SD2->D2_TES)
				dbSelectArea("SD2")
				//��������������������������������������������������������������Ŀ
				//� Executa ponto de entrada para verificar se considera TES que �
				//� NAO ATUALIZA saldos em estoque.                              �
				//����������������������������������������������������������������
				If lIxbConTes .And. SF4->F4_ESTOQUE != "S"
					lTesNEst := ExecBlock("MTAAVLTES",.F.,.F.)
					lTesNEst := If(ValType(lTesNEst) # "L",.F.,lTesNEst)
				EndIf
				If (SF4->F4_ESTOQUE != "S" .And. !lTesNEst)
					dbSkip()
					Loop
				EndIf
				If mv_par16 == 1
					If D2_NUMSEQ < cSeqIni
						cSeqIni := D2_NUMSEQ
						cAlias := Alias()
					EndIf
				Else
					If D2_SEQCALC+D2_NUMSEQ < cSeqIni
						cSeqIni := D2_SEQCALC+D2_NUMSEQ
						cAlias := Alias()
					EndIf
				EndIf
			EndIf

			If !Empty(cAlias)
				dbSelectArea(cAlias)
				cCampo1 := Subs(cAlias,2,2)+IIF(cAlias=="SD1","_DTDIGIT","_EMISSAO")
				cCampo2 := Subs(cAlias,2,2)+"_TES"
				cCampo3 := Subs(cAlias,2,2)+"_CF"
				cCampo4 := Subs(cAlias,2,2)+IIF(mv_par09 $ "Ss","_NUMSEQ","_DOC" )

				If lFirst1
					//������������������������������������������������Ŀ
					//� Calcula o Custo Medio do Produto               �
					//��������������������������������������������������
					If aSalAtu[1] > 0 .And. aSalAtu[mv_par11+1] > 0
						nCusMed := aSalAtu[mv_par11+1]/aSalAtu[1]
					ElseIf aSalAtu[1] == 0 .And. aSalAtu[mv_par11+1] == 0
						nCusMed := 0
					Else
						nCusMed := &(Eval(bBloco,"SB2->B2_CM",mv_par11))
					EndIf
					MR910ImpS1(aSalAtu,nCusMed,"",lVEIC,lCusUnif,oSection1,oSection2)
					lFirst1 := .F.
				EndIf

				oSection3:Cell("dDtMov"):SetValue(&cCampo1)			
				If cAlias == "SD3"
					oSection3:Cell("cTES"):SetValue(D3_TM)															
				Else
					oSection3:Cell("cTES"):SetValue(&cCampo2)																				
				EndIf

				If ( cPaisLoc=="BRA" )
					oSection3:Cell("cCF"):Show()
					oSection3:Cell("cCF"):SetValue(&cCampo3)					
				Else
					oSection3:Cell("cCF"):Hide()
					oSection3:Cell("cCF"):SetValue("   ")				
				EndIf				

				oSection3:Cell("cDoc"):SetValue(&cCampo4)							

				Do Case
					Case cAlias = "SD1"
					lDev:=MTR910Dev()
					If D1_TES <= "500" .And. !lDev
						If SF1->F1_TIPO != "C"
							oSection3:Cell("nCusMov"):SetValue((&(Eval(bBloco,"D1_CUSTO",iif(mv_par11==1," ",mv_par11))) / D1_QUANT))																	
							oSection3:Cell("nCusMov"):Show()
						Else
							oSection3:Cell("nCusMov"):SetValue(0)																						
							oSection3:Cell("nCusMov"):Hide()
						EndIf						

						oSection3:Cell("nENTQtd"):Show()
						oSection3:Cell("nENTCus"):Show()

						oSection3:Cell("nENTQtd"):SetValue(D1_QUANT)			
						oSection3:Cell("nENTCus"):SetValue(&(Eval(bBloco,"D1_CUSTO",iif(mv_par11==1," ",mv_par11))))			

						oSection3:Cell("nSAIQtd"):Hide()
						oSection3:Cell("nSAICus"):Hide()							
						oSection3:Cell("nSAIQtd"):SetValue(0)
						oSection3:Cell("nSAICus"):SetValue(0)

						aSalAtu[1] += D1_QUANT
						nGEntrada += &(Eval(bBloco,"D1_CUSTO",iif(mv_par11==1," ",mv_par11)))
						aSalAtu[mv_par11+1] += &(Eval(bBloco,"D1_CUSTO",iif(mv_par11==1," ",mv_par11)))
						aSalAtu[7] += D1_QTSEGUM
					Else
						If SF1->F1_TIPO != "C"
							oSection3:Cell("nCusMov"):SetValue((&(Eval(bBloco,"D1_CUSTO",iif(mv_par11==1," ",mv_par11))) / D1_QUANT))																	
							oSection3:Cell("nCusMov"):Show()
						Else
							oSection3:Cell("nCusMov"):SetValue(0)																						
							oSection3:Cell("nCusMov"):Hide()
						EndIf						
						oSection3:Cell("nENTQtd"):Hide()
						oSection3:Cell("nENTCus"):Hide()							
						oSection3:Cell("nENTQtd"):SetValue(0)
						oSection3:Cell("nENTCus"):SetValue(0)

						oSection3:Cell("nSAIQtd"):Show()
						oSection3:Cell("nSAICus"):Show()														

						If lDev
							oSection3:Cell("nSAIQtd"):SetValue(D1_QUANT * -1)			
							oSection3:Cell("nSAICus"):SetValue(&(Eval(bBloco,"D1_CUSTO",iif(mv_par11==1," ",mv_par11))) * -1)
						Else
							oSection3:Cell("nSAIQtd"):SetValue(D1_QUANT)			
							oSection3:Cell("nSAICus"):SetValue(&(Eval(bBloco,"D1_CUSTO",iif(mv_par11==1," ",mv_par11))))																			
						EndIf
						If !lDev
							aSalAtu[1] -= D1_QUANT
							nGSaida+= &(Eval(bBloco,"D1_CUSTO",iif(mv_par11==1," ",mv_par11)))
							aSalAtu[mv_par11+1] -= &(Eval(bBloco,"D1_CUSTO",iif(mv_par11==1," ",mv_par11)))
							aSalAtu[7] -= D1_QTSEGUM
						Else
							aSalAtu[1] += D1_QUANT
							nGSaida-= &(Eval(bBloco,"D1_CUSTO",iif(mv_par11==1," ",mv_par11)))
							aSalAtu[mv_par11+1] += &(Eval(bBloco,"D1_CUSTO",iif(mv_par11==1," ",mv_par11)))
							aSalAtu[7] += D1_QTSEGUM
						EndIf
					EndIf
					nRec1++

					Case cAlias = "SD2"
					lDev:=MTR910Dev()
					If D2_TES <= "500" .Or. lDev
						oSection3:Cell("nSAIQtd"):Hide()
						oSection3:Cell("nSAICus"):Hide()
						oSection3:Cell("nSAIQtd"):SetValue(0)
						oSection3:Cell("nSAICus"):SetValue(0)

						oSection3:Cell("nENTQtd"):Show()
						oSection3:Cell("nENTCus"):Show()
						If lDev
							oSection3:Cell("nENTQtd"):SetValue(D2_QUANT * -1)			
							oSection3:Cell("nENTCus"):SetValue(&(Eval(bBloco,"D2_CUSTO",mv_par11)) * -1)
						Else
							oSection3:Cell("nENTQtd"):SetValue(D2_QUANT)			
							oSection3:Cell("nENTCus"):SetValue(&(Eval(bBloco,"D2_CUSTO",mv_par11)))																																	
						EndIf
						If SF2->F2_TIPO != "C"
							oSection3:Cell("nCusMov"):SetValue((&(Eval(bBloco,"D2_CUSTO",mv_par11)) / D2_QUANT))																	
							oSection3:Cell("nCusMov"):Show()
						Else
							oSection3:Cell("nCusMov"):SetValue(0)																						
							oSection3:Cell("nCusMov"):Hide()
						EndIf						
						If !lDev
							aSalAtu[1] += D2_QUANT
							nGEntrada+= &(Eval(bBloco,"D2_CUSTO",mv_par11))
							aSalAtu[mv_par11+1] += &(Eval(bBloco,"D2_CUSTO",mv_par11))
							aSalAtu[7] += D2_QTSEGUM
						Else
							//������������������������������������������������Ŀ
							//�Se for devolucao, subtrai nos valores de entrada�
							//��������������������������������������������������
							aSalAtu[1] -= D2_QUANT
							nGEntrada-= &(Eval(bBloco,"D2_CUSTO",mv_par11))
							aSalAtu[mv_par11+1] -= &(Eval(bBloco,"D2_CUSTO",mv_par11))
							aSalAtu[7] -= D2_QTSEGUM
						EndIf
					Else
						oSection3:Cell("nENTQtd"):Hide()
						oSection3:Cell("nENTCus"):Hide()
						oSection3:Cell("nENTQtd"):SetValue(0)
						oSection3:Cell("nENTCus"):SetValue(0)

						oSection3:Cell("nSAIQtd"):Show()
						oSection3:Cell("nSAICus"):Show()

						If SF2->F2_TIPO != "C"
							oSection3:Cell("nCusMov"):SetValue((&(Eval(bBloco,"D2_CUSTO",mv_par11)) / D2_QUANT))																	
							oSection3:Cell("nCusMov"):Show()
						Else
							oSection3:Cell("nCusMov"):SetValue(0)																						
							oSection3:Cell("nCusMov"):Hide()
						EndIf													

						oSection3:Cell("nSAIQtd"):SetValue(D2_QUANT)			
						oSection3:Cell("nSAICus"):SetValue(&(Eval(bBloco,"D2_CUSTO",mv_par11)))

						aSalAtu[1] -= D2_QUANT
						nGSaida+=  &(Eval(bBloco,"D2_CUSTO",mv_par11))
						aSalAtu[mv_par11+1] -= &(Eval(bBloco,"D2_CUSTO",mv_par11))
						aSalAtu[7] -= D2_QTSEGUM
					EndIf
					nRec2++

					Otherwise
					If !D3Valido()
						dbSkip()
						Loop
					EndIf

					//����������������������������������������������������������������Ŀ
					//� Caso seja uma transferencia de localizacao verifica se lista   �
					//� o movimento ou nao                                             �
					//������������������������������������������������������������������
					If mv_par17 == 2 .And. Substr(D3_CF,3,1) == "4"
						cNumSeqTr := SD3->D3_COD+SD3->D3_NUMSEQ+SD3->D3_LOCAL
						nRegTr    := Recno()
						dbSkip()
						If SD3->D3_COD+SD3->D3_NUMSEQ+SD3->D3_LOCAL == cNumSeqTr
							dbSkip()
							Loop
						Else
							dbGoto(nRegTr)
						EndIf
					EndIf
					lDev := .F.
					If	lInverteMov
						If D3_TM > "500"

							oSection3:Cell("nENTQtd"):Show()
							oSection3:Cell("nENTCus"):Show()
							oSection3:Cell("nCusMov"):Show()

							oSection3:Cell("nENTQtd"):SetValue(D3_QUANT)			
							oSection3:Cell("nENTCus"):SetValue(&(Eval(bBloco,"D3_CUSTO",mv_par11)))			
							oSection3:Cell("nCusMov"):SetValue((&(Eval(bBloco,"D3_CUSTO",mv_par11)) / D3_QUANT))										

							oSection3:Cell("nSAIQtd"):Hide()
							oSection3:Cell("nSAICus"):Hide()							
							oSection3:Cell("nSAIQtd"):SetValue(0)
							oSection3:Cell("nSAICus"):SetValue(0)																						

							aSalAtu[1] += D3_QUANT
							nGEntrada  += &(Eval(bBloco,"D3_CUSTO",mv_par11))
							aSalAtu[mv_par11+1] += &(Eval(bBloco,"D3_CUSTO",mv_par11))
							aSalAtu[7] += D3_QTSEGUM
						Else	
							oSection3:Cell("nENTQtd"):Hide()
							oSection3:Cell("nENTCus"):Hide()
							oSection3:Cell("nENTQtd"):SetValue(0)
							oSection3:Cell("nENTCus"):SetValue(0)

							oSection3:Cell("nCusMov"):Show()
							oSection3:Cell("nSAIQtd"):Show()
							oSection3:Cell("nSAICus"):Show()

							oSection3:Cell("nCusMov"):SetValue((&(Eval(bBloco,"D3_CUSTO",mv_par11)) / D3_QUANT))			
							oSection3:Cell("nSAIQtd"):SetValue(D3_QUANT)			
							oSection3:Cell("nSAICus"):SetValue(&(Eval(bBloco,"D3_CUSTO",mv_par11)))																		

							aSalAtu[1] -= D3_QUANT
							nGSaida	  += &(Eval(bBloco,"D3_CUSTO",mv_par11))
							aSalAtu[mv_par11+1] -= &(Eval(bBloco,"D3_CUSTO",mv_par11))
							aSalAtu[7] -= D3_QTSEGUM
						EndIf
						If lCusUnif
							lPriApropri:=.F.
						EndIf
					Else
						If D3_TM <= "500"

							oSection3:Cell("nENTQtd"):Show()
							oSection3:Cell("nENTCus"):Show()
							oSection3:Cell("nCusMov"):Show()

							oSection3:Cell("nENTQtd"):SetValue(D3_QUANT)			
							oSection3:Cell("nENTCus"):SetValue(&(Eval(bBloco,"D3_CUSTO",mv_par11)))			
							oSection3:Cell("nCusMov"):SetValue((&(Eval(bBloco,"D3_CUSTO",mv_par11)) / D3_QUANT))										

							oSection3:Cell("nSAIQtd"):Hide()
							oSection3:Cell("nSAICus"):Hide()							
							oSection3:Cell("nSAIQtd"):SetValue(0)
							oSection3:Cell("nSAICus"):SetValue(0)																						

							aSalAtu[1] += D3_QUANT
							nGEntrada+= &(Eval(bBloco,"D3_CUSTO",mv_par11))
							aSalAtu[mv_par11+1] += &(Eval(bBloco,"D3_CUSTO",mv_par11))
							aSalAtu[7] += D3_QTSEGUM
						Else
							oSection3:Cell("nENTQtd"):Hide()
							oSection3:Cell("nENTCus"):Hide()
							oSection3:Cell("nENTQtd"):SetValue(0)
							oSection3:Cell("nENTCus"):SetValue(0)

							oSection3:Cell("nCusMov"):Show()
							oSection3:Cell("nSAIQtd"):Show()
							oSection3:Cell("nSAICus"):Show()

							oSection3:Cell("nCusMov"):SetValue((&(Eval(bBloco,"D3_CUSTO",mv_par11)) / D3_QUANT))			
							oSection3:Cell("nSAIQtd"):SetValue(D3_QUANT)			
							oSection3:Cell("nSAICus"):SetValue(&(Eval(bBloco,"D3_CUSTO",mv_par11)))																										

							aSalAtu[1] -= D3_QUANT
							nGSaida+=  &(Eval(bBloco,"D3_CUSTO",mv_par11))
							aSalAtu[mv_par11+1] -= &(Eval(bBloco,"D3_CUSTO",mv_par11))
							aSalAtu[7] -= D3_QTSEGUM
						EndIf
						If lCusUnif
							lPriApropri:=.T.
						EndIf
					EndIf
					nRec3++
				EndCase

				oSection3:Cell("nSALDQtd"):SetValue(aSalAtu[1])			
				oSection3:Cell("nSALDCus"):SetValue(aSalAtu[mv_par11+1])							

				If cPaisLoc <> "CHI"
					Do Case
						Case cAlias = "SD3"  && movimentos (SD3)
						If Empty(D3_OP) .And. Empty(D3_PROJPMS)
							oSection3:Cell("cCCPVPJOP"):SetValue('CC'+D3_CC)			
						ElseIf !Empty(D3_PROJPMS)
							oSection3:Cell("cCCPVPJOP"):SetValue('PJ'+D3_PROJPMS)			
						ElseIf !Empty(D3_OP)
							oSection3:Cell("cCCPVPJOP"):SetValue('OP'+D3_OP)
						EndIf
						Case cAlias = "SD1"  && compras    (SD1)
						oSection3:Cell("cCCPVPJOP"):SetValue('F-'+D1_FORNECE)
						Case cAlias = "SD2"  && vendas     (SD2)
						If D2_TIPO == "B"
							oSection3:Cell("cCCPVPJOP"):SetValue('F-'+D2_CLIENTE)
						Else
							oSection3:Cell("cCCPVPJOP"):SetValue('C-'+D2_CLIENTE)
						EndIf
					EndCase
				EndIf
				cSeqIni := Replicate("z",6)
				cAlias := ""

				If !lImpSMov 
					oSection3:PrintLine()
				Endif	

				If !lInverteMov .Or. (lInverteMov .And. lPriApropri)
					dbSkip()
				EndIf
			Else
				dCntData++
			EndIf

			nAcho:=ASCAN(aGrupos,{|x| SB1->B1_TIPO == x[1]})
			If nAcho > 0
				aGrupos[nAcho][2]+=nGEntrada
				aGrupos[nAcho][3]+=nGSaida
			Else
				AADD(aGrupos,{SB1->B1_TIPO,nGEntrada,nGSaida,0})
				nAcho := Len(aGrupos)
			EndIf

			nGEntrada := 0
			nGSaida   := 0

			If dCntData > mv_par06
				If nRec1 > 0 .or. nRec2 > 0 .or. nRec3 > 0
					nAcho:=ASCAN(aGrupos,{|x| SB1->B1_TIPO == x[1]})
					If nAcho > 0
						aGrupos[nAcho][4]+=aSalAtu[mv_par11+1]
					Else
						AADD(aGrupos,{SB1->B1_TIPO,0,0,aSalAtu[mv_par11+1]})
						nAcho := Len(aGrupos)
					EndIf
					oReport:PrintText(STR0018+AllTrim(TransForm(aSalAtu[7],cPicB2Qt2)),,oSection3:Cell('nSAICus'):ColPos()) //"QTD. NA SEGUNDA UM: "											
					lImpS3   := .T.
				Else
					//��������������������������������������������������������Ŀ
					//� Verifica se deve ou nao listar os produtos s/movimento �
					//����������������������������������������������������������
					If mv_par07 == 1
						nAcho:=ASCAN(aGrupos,{|x| SB1->B1_TIPO == x[1]})
						If nAcho > 0
							aGrupos[nAcho][4]+=aSalAtu[mv_par11+1]
						Else
							AADD(aGrupos,{SB1->B1_TIPO,0,0,aSalAtu[mv_par11+1]})
							nAcho := Len(aGrupos)
						EndIf
						//������������������������������������������������Ŀ
						//� Calcula o Custo Medio do Produto               �
						//��������������������������������������������������
						If aSalAtu[1] > 0 .And. aSalAtu[mv_par11+1] > 0
							nCusMed := aSalAtu[mv_par11+1]/aSalAtu[1]
						ElseIf aSalAtu[1] == 0 .And. aSalAtu[mv_par11+1] == 0
							nCusMed := 0
						Else
							nCusMed := &(Eval(bBloco,"SB2->B2_CM",mv_par11))
						EndIf
						MR910ImpS1(aSalAtu,nCusMed,"",lVEIC,lCusUnif,oSection1,oSection2)

						If !MTR910IsMNT()
							oReport:PrintText(STR0019)	//"NAO HOUVE MOVIMENTACAO PARA ESTE PRODUTO"
							oReport:ThinLine()
							lImpSMov := .T.
						Else
							If FindFunction("NGProdMNT")
								aProdsMNT := aClone(NGProdMNT())
								If aScan(aProdsMNT, {|x| AllTrim(x) == AllTrim(SB1->B1_COD) }) == 0
									oReport:PrintText(STR0019)	//"NAO HOUVE MOVIMENTACAO PARA ESTE PRODUTO"
									oReport:ThinLine()
									lImpSMov := .T.
								EndIf
							ElseIf SB1->B1_COD <> cProdMNT .and. SB1->B1_COD <> cProdTER
								oReport:PrintText(STR0019)	//"NAO HOUVE MOVIMENTACAO PARA ESTE PRODUTO"
								oReport:ThinLine()
								lImpSMov := .T.
							EndIf
						EndIf

					EndIf
				EndIf
				Exit
			EndIf

		EndDo

		oSection1:Finish()
		oSection2:Finish()
		If !lImpSMov .And. lImpS3
			oSection3:Finish()							
		Endif	

		dbSelectArea("SB1")
		dbSkip()

	EndDo

	If !Empty(aGrupos)

		oReport:SkipLine()    
		oReport:PrintText(STR0020) //"R E S U M O"
		oReport:SkipLine()    		

		cAlias:=Alias()
		dbSelectArea("SX5")
		For i:=1 to Len(aGrupos)
			dbSeek(xFilial("SX5")+"02"+aGrupos[i][1])
			oReport:PrintText(X5Descri(),oReport:Row())
			oReport:PrintText(TransForm(aGrupos[i][2],cPicD1Cust),oReport:Row(),oSection3:Cell('nENTCus'):ColPos())														
			oReport:PrintText(TransForm(aGrupos[i][3],cPicD2Cust),oReport:Row(),oSection3:Cell('nSAICus'):ColPos())
			oReport:PrintText(TransForm(aGrupos[i][4],cPicB2Cust),oReport:Row(),oSection3:Cell('nSALDCus'):ColPos())						
			oReport:SkipLine()    
		Next i
		dbSelectArea(cAlias)
	EndIf

	#ENDIF		

	//��������������������������������������������������������������Ŀ
	//� Impressao de Termos Abertura e Encerramento                  �
	//����������������������������������������������������������������

	If lImpTermos // Impressao dos Termos

		If !lImpLivro 
			oReport:HideHeader() 
			oReport:HideFooter() 
			oReport:HideParamPage()
		Endif

		cArqAbert:=GetMv("MV_LMOD3AB")
		cArqEncer:=GetMv("MV_LMOD3EN")

		dbSelectArea("SM0")
		aVariaveis:={}

		For i:=1 to FCount()
			If FieldName(i)=="M0_CGC"
				AADD(aVariaveis,{FieldName(i),Transform(FieldGet(i),"@R 99.999.999/9999-99")})
			Else
				If FieldName(i)=="M0_NOME"
					Loop
				EndIf
				AADD(aVariaveis,{FieldName(i),FieldGet(i)})
			EndIf
		Next

		dbSelectArea("SX1")
		dbSeek(PADR("MTR910",nTamSX1)+"01")

		While SX1->X1_GRUPO==PADR("MTR910",nTamSX1)
			AADD(aVariaveis,{Rtrim(Upper(X1_VAR01)),&(X1_VAR01)})
			dbSkip()
		EndDo

		If !File(cArqAbert)
			aSavSet:=__SetSets()
			//Editor de Termos de Livros
			cArqAbert:=CFGX024(,OemToAnsi(STR0021))		//" Edi��o do Termo de Abertura "
			__SetSets(aSavSet)
			Set(24,Set(24),.t.)
		EndIf

		If !File(cArqEncer)
			aSavSet:=__SetSets()
			// Editor de Termos de Livros
			cArqEncer:=CFGX024(,OemToAnsi(STR0022)) 		//" Edi��o do Termo de Encerramento "
			__SetSets(aSavSet)
			Set(24,Set(24),.t.)
		EndIf

		cDriver:=aDriver[4]
		oReport:HideHeader()
		If cArqAbert#NIL
			oReport:EndPage()
			ImpTerm(cArqAbert,aVariaveis,&cDriver,,,.T.,oReport)
		EndIf

		If cArqEncer#NIL
			oReport:EndPage()
			ImpTerm(cArqEncer,aVariaveis,&cDriver,,,.T.,oReport)
		EndIf

	EndIf

Return NIL
/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������Ŀ��
���Fun��o    �MATR910R3 � Autor � Paulo Boschetti       � Data � 11.11.92 ���
�������������������������������������������������������������������������Ĵ��
���Descri��o � Kardex fisico - financeiro (Antigo)                        ���
�������������������������������������������������������������������������Ĵ��
��� Uso      � Generico                                                   ���
�������������������������������������������������������������������������Ĵ��
���         ATUALIZACOES SOFRIDAS DESDE A CONSTRU�AO INICIAL.             ���
�������������������������������������������������������������������������Ĵ��
���Programador � Data   � BOPS �  Motivo da Alteracao                     ���
�������������������������������������������������������������������������Ĵ��
���Rodrigo     �24/06/98�XXXXXX�Acerto no tamanho do documento para 12    ���
���            �        �      �posicoes                                  ���
���Rodrigo Sart�05/11/98�XXXXXX� Acerto p/ Bug Ano 2000                   ���
���Bruno Sobies�18/12/98�Melhor�Exclucao impressao do CF nas localizacoes ���
���Rodrigo Sart�18/01/99�08994A�Inclusao da pergunta Lista p/ NumSeq/Calc ���
���Cesar       �25/03/99�20051A�Alteracao do Lay-Out p/ Sair #OP Completa ���
���Patricia Sal|24/11/99�25325A�Acerto das pictures.                      ���
���Paulo August�07/12/99�Melhor�Acerto do Lay-Out para o Chile            ���
�������������������������������������������������������������������������Ĵ��
���Marcos Hirak�17/05/04�XXXXXX�Imprimir B1_CODITE quando for gestao de   ���
���            �        �      �Concessionarias ( MV_VEICULO = "S").      ���
���            �        �      �                                          ���
��������������������������������������������������������������������������ٱ�
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������Ŀ��
���Descri��o � PLANO DE MELHORIA CONTINUA                                 ���
�������������������������������������������������������������������������Ĵ��
���ITEM PMC  � Responsavel              � Data                            ���
�������������������������������������������������������������������������Ĵ��
���      01  �Marcos V. Ferreira        �09/08/2006 - Bops: 00000094182   ���
���      02  �Erike Yuri da Silva       �21/12/2005                       ���
���      03  �Marcos V. Ferreira        �23/05/2006 - Bops: 00000100000   ���
���      04  �Marcos V. Ferreira        �23/05/2006 - Bops: 00000100000   ���
���      05  �                          �                                 ���
���      06  �Marcos V. Ferreira        �09/08/2006 - Bops: 00000094182   ���
���      07  �                          �                                 ���
���      08  �                          �                                 ���
���      09  �                          �                                 ���
���      10  �Erike Yuri da Silva       �21/12/2005                       ���
��������������������������������������������������������������������������ٱ�
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/
Static Function Matr910R3()
	//��������������������������������������������������������������Ŀ
	//� Define Variaveis                                             �
	//����������������������������������������������������������������
	LOCAL cDesc1    := STR0001	//"Este programa emitir� uma rela��o com as movimenta��es"
	LOCAL cDesc2    := STR0002	//"dos produtos Selecionados,Ordenados por Dia."
	LOCAL cDesc3    := ""
	LOCAL titulo    := OemToAnsi(STR0003)	//"Kardex Fisico-Financeiro (DIA)"
	LOCAL wnrel     := "MATR910"
	LOCAL Tamanho   := "G"
	LOCAL cString   := "SB1"
	LOCAL lRet		:= .T.
	LOCAL nTamSX1   := Len(SX1->X1_GRUPO)

	//��������������������������������������������������������������Ŀ
	//� Variaveis tipo Local para SIGAVEI, SIGAPEC e SIGAOFI         �
	//����������������������������������������������������������������
	LOCAL aArea1	:= Getarea()

	//��������������������������������������������������������������Ŀ
	//� Variaveis tipo Private para SIGAVEI, SIGAPEC e SIGAOFI       �
	//����������������������������������������������������������������
	PRIVATE lVEIC   := UPPER(GETMV("MV_VEICULO"))=="S"
	PRIVATE aSB1Cod := {}
	PRIVATE aSB1Ite := {}
	PRIVATE nCOL1	:= 0

	PRIVATE aOrd    := {OemToAnsi(STR0004),OemToAnsi(STR0005)}		//" Codigo Produto "###" Tipo do Produto"
	PRIVATE aReturn := { OemToAnsi(STR0006), 1,OemToAnsi(STR0007), 1, 2, 1, "",1 }		//"Zebrado"###"Administracao"
	PRIVATE aLinha  := { },nLastKey := 0
	PRIVATE cPerg   := "MTR910"
	PRIVATE bBloco  := { |nV,nX| Trim(nV)+IIf(Valtype(nX)='C',"",Str(nX,1)) }
	PRIVATE aDriver := ReadDriver()
	//��������������������������������������������������������������Ŀ
	//� Verifica se utiliza custo unificado por Empresa/Filial       �
	//����������������������������������������������������������������
	PRIVATE lCusUnif := IIf(FindFunction("A330CusFil"),A330CusFil(),GetMV("MV_CUSFIL",.F.))

	//��������������������������������������������������������������Ŀ
	//� Ajusta perguntas no SX1 a fim de preparar o relatorio p/     �
	//� custo unificado por empresa                                  �
	//����������������������������������������������������������������
	If lCusUnif
		MTR910CUnf(lCusUnif)
	EndIf

	//��������������������������������������������������������������Ŀ
	//� Ajusta perguntas no SX1 									 �
	//����������������������������������������������������������������
	AjustaSX1()

	//��������������������������������������������������������������Ŀ
	//� Remove grupo de perguntas incluido                           �
	//����������������������������������������������������������������
	dbSelectArea("SX1")
	dbSetOrder(1)
	If dbSeek(PADR("MTR910",nTamSX1)+"22")
		RecLock("SX1",.F.)
		dbDelete()
		MsUnlock()
	EndIf

	//��������������������������������������������������������������Ŀ
	//� Ajustar o SX1 para SIGAVEI, SIGAPEC e SIGAOFI                �
	//����������������������������������������������������������������
	aSB1Cod	:= TAMSX3("B1_COD")
	aSB1Ite	:= TAMSX3("B1_CODITE")

	If lVEIC

		dbSelectArea("SX1")
		dbSetOrder(1)
		dbSeek(PADR(cPerg,nTamSX1))
		Do While SX1->X1_GRUPO == PADR(cPerg,nTamSX1) .And. !SX1->(Eof())
			If "PRODU" $ Upper(SX1->X1_PERGUNT) .And. Upper(SX1->X1_TIPO) == "C" .And. ;
			(SX1->X1_TAMANHO <> aSB1Ite[1] .Or. Upper(SX1->X1_F3) <> "VR4")

				RecLock("SX1",.F.)
				SX1->X1_TAMANHO := aSB1Ite[1]
				SX1->X1_F3 := "VR4"
				dbCommit()
				msUnLock()

			EndIf
			dbSkip()
		EndDo
		dbCommitAll()
		RestArea(aArea1)
	Else
		dbSelectArea("SX1")
		dbSetOrder(1)
		dbSeek(PADR(cPerg,nTamSX1))
		Do While SX1->X1_GRUPO == PADR(cPerg,nTamSX1) .And. !SX1->(Eof())
			If "PRODU" $ Upper(SX1->X1_PERGUNT) .And. Upper(SX1->X1_TIPO) == "C" .And. ;
			(SX1->X1_TAMANHO <> aSB1Cod[1] .Or. Upper(SX1->X1_F3) <> "SB1")

				RecLock("SX1",.F.)
				SX1->X1_TAMANHO := aSB1Cod[1]
				SX1->X1_F3 := "SB1"
				dbCommit()
				msUnLock()

			EndIf
			dbSkip()
		EndDo
		dbCommitAll()
		RestArea(aArea1)
	EndIf

	Pergunte("MTR910",.F.)

	//��������������������������������������������������������������Ŀ
	//� Variaveis utilizadas para parametros                         �
	//� mv_par01        // Do produto                                �
	//� mv_par02        // Ate o produto                             �
	//� mv_par03        // Do tipo                                   �
	//� mv_par04        // Ate o tipo                                �
	//� mv_par05        // Da data                                   �
	//� mv_par06        // Ate a data                                �
	//� mv_par07        // Lista produtos s/movim                    �
	//� mv_par08        // Qual Local (almoxarifado)                 �
	//� mv_par09        // (D)ocumento/(S)equencia                   �
	//� mv_par10        // Saldo a considerar : Atual / Fechamento   �
	//� mv_par11        // Moeda Selecionada (1 a 5)                 �
	//� mv_par12        // Pagina Inicial                            �
	//� mv_par13        // Qtd de Paginas                            �
	//� mv_par14        // Nr do Livro                               �
	//� mv_par15        // Livro/Livro+termos/Termos                 �
	//� mv_par16        // Seq.de Digitacao /Calculo                 �
	//� mv_par17        // Lista Transf Locali (Sim/Nao)             �
	//� mv_par18        // Do Grupo                                  �
	//� mv_par19        // Ate o Grupo                               �
	//� mv_par20        // Prods com Saldo Zero - (Lista/Nao Lista)  �
	//� mv_par21        // Prods com Saldo Neg. - (Lista/Nao Lista)  �
	//����������������������������������������������������������������

	//��������������������������������������������������������������Ŀ
	//� Envia controle para a funcao SETPRINT                        �
	//����������������������������������������������������������������

	wnrel:=SetPrint(cString,wnrel,cPerg,@titulo,cDesc1,cDesc2,cDesc3,.F.,aOrd,.f.,Tamanho)

	If nLastKey = 27
		dbClearFilter()
		lRet := .F.
	EndIf

	If lRet

		SetDefault(aReturn,cString)

		If nLastKey = 27
			dbClearFilter()
			lRet := .F.
		EndIf

		If lRet
			RptStatus({|lEnd| R910Imp(@lEnd,wnRel,tamanho,titulo)},titulo)
		EndIf

	EndIf		

Return NIL

/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������Ŀ��
���Fun��o    � R910IMP  � Autor � Rodrigo de A. Sartorio� Data � 16.11.95 ���
�������������������������������������������������������������������������Ĵ��
���Descri��o � Chamada do Relatorio                                       ���
�������������������������������������������������������������������������Ĵ��
���Sintaxe   � R910Imp(ExpL1,ExpC1,ExpC2,ExpC3)		                        ���
�������������������������������������������������������������������������Ĵ��
���Parametros� ExpL1 = var. p/ controle de interrupcao pelo usuario 	    ���
���          � ExpC1 = codigo do relatorio                                ���
���          � ExpC2 = codigo ref. ao tamanho do relatorio (P/M/G)        ���
���          � ExpC3 = titulo do relatorio                                ���
�������������������������������������������������������������������������Ĵ��
��� Uso      � MATR910			                                              ���
��������������������������������������������������������������������������ٱ�
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
Static Function R910Imp(lEnd,WnRel,tamanho,titulo)
	Static lIxbConTes   := NIL
	LOCAL aDadosTran:={},lContinua := .F.
	LOCAL nTipo     := 0
	LOCAL nTam      :=18
	LOCAL cProdAnt  := ""
	LOCAL cLocalAnt := ""
	LOCAL nCusMed   := 0
	LOCAL lFirst1   := .T.
	LOCAL aSalAtu   := { 0,0,0,0,0,0,0 }
	Local aSalAlmox := {}
	LOCAL nEntrada  := 0, nSaida  :=0
	LOCAL nCEntrada := 0, nCSaida :=0
	LOCAL nGEntrada := 0, nGSaida :=0
	LOCAL nRec1,nRec2,nRec3,nSavRec,dCntData
	LOCAL cPicB2Qt  := PesqPictQt("B2_QATU" ,18)
	LOCAL cPicB2Qt2 := PesqPictQt("B2_QTSEGUM" ,18)
	LOCAL cPicD1Qt  := PesqPict("SD1","D1_QUANT" ,18)
	LOCAL cPicD2Qt  := PesqPict("SD2","D2_QUANT" ,18)
	LOCAL cPicD3Qt  := PesqPict("SD3","D3_QUANT" ,18)
	LOCAL cPicB2Cust:= PesqPict("SB2","B2_CM"+Str(mv_par11,1),18)
	LOCAL cPicD1Cust:= PesqPict("SD1","D1_CUSTO"+IIF(mv_par11 == 1 ,"",Str(mv_par11,1)),18)
	LOCAL cPicD2Cust:= PesqPict("SD2","D2_CUSTO"+Str(mv_par11,1),18)
	LOCAL cPicD3Cust:= PesqPict("SD3","D3_CUSTO"+Str(mv_par11,1),18)
	LOCAL lDev  // Flag que indica se nota � devolu�ao (.T.) ou nao (.F.)
	LOCAL cCusto, lImpLivro, lImpTermos, cCond1, cCond2
	LOCAL nAcho,i,aGrupos:={},cAlias
	LOCAL cTRBSD1	:= CriaTrab(,.f.)
	LOCAL cTRBSD2	:= Subs(cTrbSD1,1,7)+"A"
	LOCAL cTRBSD3	:= Subs(cTrbSD1,1,7)+"B"
	LOCAL nInd,cIndice	:="",cCampo1,cCampo2,cCampo3,cCampo4
	LOCAL cNumSeqTr := "" , nRegTr := 0
	LOCAL cSeqIni 	:= Replicate("z",6)
	LOCAL nTotRegs  := 0
	// Indica se esta listando relatorio do almox. de processo
	LOCAL lLocProc:= mv_par08 == GetMv("MV_LOCPROC")
	// Indica se deve imprimir movimento invertido (almox. de processo)
	LOCAL lInverteMov :=.F.
	LOCAL lPriApropri :=.T.

	Local nTamSX1 := Len(SX1->X1_GRUPO)
	//��������������������������������������������������������������Ŀ
	//� Verifica se existe ponto de entrada                          �
	//����������������������������������������������������������������
	LOCAL lTesNEst := .F.

	//��������������������������������������������������������������Ŀ
	//� Codigo do produto importado - NAO DEVE SER LISTADO           �
	//����������������������������������������������������������������
	LOCAL cProdImp := GETMV("MV_PRODIMP")

	//��������������������������������������������������������������Ŀ
	//� Variaveis tipo Local para SIGAVEI, SIGAPEC e SIGAOFI         �
	//����������������������������������������������������������������
	LOCAL cArq1 := ""
	LOCAL nInd1 := 0

	LOCAL cAliasTop:="KARDEXSQL"

	LOCAL nRecTrf1 := 0
	LOCAL nRecTrf2 := 0
	LOCAL aRecTRF  := {}

	LOCAL cQueryB1A:= "" 
	LOCAL cQueryB1B:= "" 
	LOCAL cQueryB1C:= "" 
	LOCAL cQueryB1D:= "" 

	LOCAL cProdMNT := GetMv("MV_PRODMNT")
	LOCAL cProdTER := GetMv("MV_PRODTER")
	Local aProdsMNT := {}
	Local nX

	cProdMNT := cProdMNT + Space(15-Len(cProdMNT))
	cProdTER := cProdTER + Space(15-Len(cProdTER))

	If	!lVEIC
		cQueryB1A:= " AND SB1.B1_COD >= '"+mv_par01+"' AND SB1.B1_COD <= '"+mv_par02+"'"
		cQueryB1B:= " AND SB1.B1_COD = SB1EXS.B1_COD"
		cQueryB1C:= " SB1.B1_FILIAL = '"+xFilial("SB1")+"' AND SB1.B1_TIPO >= '"+mv_par03+"' AND SB1.B1_TIPO <= '"+mv_par04+"' AND"
		cQueryB1D:= " SB1EXS.B1_FILIAL = '"+xFilial("SB1")+"' AND SB1EXS.B1_COD >= '"+mv_par01+"' AND SB1EXS.B1_COD <= '"+mv_par02+"' AND SB1EXS.B1_TIPO >= '"+mv_par03+"' AND SB1EXS.B1_TIPO <= '"+mv_par04+"' AND"
	Else
		cQueryB1A:= " AND SB1.B1_CODITE >= '"+mv_par01+"' AND SB1.B1_CODITE <= '"+mv_par02+"'"
		cQueryB1B:= " AND SB1.B1_COD = SB1EXS.B1_COD"
		cQueryB1C:= " SB1.B1_FILIAL = '"+xFilial("SB1")+"' AND SB1.B1_TIPO >= '"+mv_par03+"' AND SB1.B1_TIPO <= '"+mv_par04+"' AND"
		cQueryB1D:= " SB1EXS.B1_FILIAL = '"+xFilial("SB1")+"' AND SB1EXS.B1_CODITE >= '"+mv_par01+"' AND SB1EXS.B1_CODITE <= '"+mv_par02+"' AND SB1EXS.B1_TIPO >= '"+mv_par03+"' AND SB1EXS.B1_TIPO <= '"+mv_par04+"' AND"
	EndIf	

	cQueryB1C      += " SB1.B1_GRUPO >= '"+mv_par18+"' AND SB1.B1_GRUPO <= '"+mv_par19+"' AND SB1.B1_COD <> '"+cProdimp+"' AND "
	cQueryB1C      += " SB1.D_E_L_E_T_=' '"
	cQueryB1D      += " SB1EXS.B1_GRUPO >= '"+mv_par18+"' AND SB1EXS.B1_GRUPO <= '"+mv_par19+"' AND SB1EXS.B1_COD <> '"+cProdimp+"' AND "
	cQueryB1D      += " SB1EXS.D_E_L_E_T_=' '"

	lIxbConTes := IF(lIxbConTes == NIL,ExistBlock("MTAAVLTES"),lIxbConTes)

	//��������������������������������������������������������������Ŀ
	//� Verifica se utiliza custo unificado por empresa              �
	//����������������������������������������������������������������
	lCusUnif:=lCusUnif .And. mv_par08 == Repl("*",TamSX3("B2_LOCAL")[1])

	//��������������������������������������������������������������Ŀ
	//� Variaveis utilizadas para Impressao do Cabecalho e Rodape    �
	//����������������������������������������������������������������
	PRIVATE cbtxt := SPACE(10)
	PRIVATE cbcont:= 0
	PRIVATE li    := 80
	PRIVATE m_pag := mv_par12

	PRIVATE cabec1  := STR0008+IIF(mv_par09 $ "Dd", STR0009,STR0010) +iif(cPaisLoc<>"CHI",STR0011,STR0033)		//"    OPERACAO      "###"   DOCUMENTO   "###"   SEQUENCIA   "###" |               E  N  T  R  A  D  A  S             |         CUSTO MEDIO   |                  S  A  I  D  A  S                |                   S   A   L   D   O             |P.V.,FOR,"
	PRIVATE cabec2  := IIF(cPaisLoc == "CHI",STR0032,STR0012)
	titulo  := STR0013+mv_par08		//"KARDEX FISICO-FINANCEIRO (DIA) L O C A L :"

	//�������������������������������������������������������������������Ŀ
	//� Inicializa os codigos de caracter Comprimido/Normal da impressora �
	//���������������������������������������������������������������������
	nTipo  := IIF(aReturn[4]==1,15,18)

	//������������������������������������������������������������Ŀ
	//� Adiciona a ordem escolhida ao titulo do relatorio          �
	//��������������������������������������������������������������
	If Type("NewHead")#"U"
		NewHead += STR0014+AllTrim(aOrd[aReturn[8]])+STR0015+AllTrim(GetMv("MV_SIMB"+Ltrim(Str(mv_par11))))+")"		//" (Por "###" ,em "
	Else
		Titulo  += STR0014+AllTrim(aOrd[aReturn[8]])+STR0015+AllTrim(GetMv("MV_SIMB"+Ltrim(Str(mv_par11))))+")"		//" (Por "###" ,em "
	EndIf

	//������������������������������������������������������������Ŀ
	//� Adiciona seq de impressao escolhida ao titulo do relatorio �
	//��������������������������������������������������������������
	titulo  +=IIf(mv_par16==1,OemToAnsi(STR0030),OemToAnsi(STR0031))	// "(SEQUENCIA)"###"(CALCULO)"

	dbSelectArea("SB2")
	dbSetOrder(1)

	//��������������������������������������������������������������Ŀ
	//� Impressao de Termo / Livro                                   �
	//����������������������������������������������������������������
	Do Case
		Case mv_par15==1 ; lImpLivro:=.t. ; lImpTermos:=.f.
		Case mv_par15==2 ; lImpLivro:=.t. ; lImpTermos:=.t.
		Case mv_par15==3 ; lImpLivro:=.f. ; lImpTermos:=.t.
	EndCase

	#IFDEF TOP
	If !(TcSrvType()=="AS/400") .And. !("POSTGRES" $ TCGetDB())
		If lImpLivro

			dbSelectArea("SD1")           // Itens de Entrada
			nTotRegs += LastRec()

			dbSelectArea("SD2")           // Itens de Saida
			nTotRegs += LastRec()

			dbSelectArea("SD3")           // movimentacoes internas (producao/requisicao/devolucao)
			nTotRegs += LastRec()

			dbSelectArea("SB2")			  // Saldos em estoque
			dbSetOrder(1)
			nTotRegs += LastRec()

			//                            1,                 2,               3,        4,           5,          6,            7,                 8,              9,        10,      11,                 12,              13,            14,                 15,                 16,              17,   18,   19                    20,          21,       22,            23,      24
			// cQueryD1:= "SELECT 'SD1' ARQ,SB1.B1_COD PRODUTO,SB1.B1_TIPO TIPO,SB1.B1_UM,SB1.B1_GRUPO,SB1.B1_DESC,SB1.B1_POSIPI,D1_SEQCALC SEQCALC,D1_DTDIGIT DATA,D1_TES TES,D1_CF CF,D1_NUMSEQ SEQUENCIA,D1_DOC DOCUMENTO,D1_SERIE SERIE,D1_QUANT QUANTIDADE,D1_QTSEGUM QUANT2UM,D1_LOCAL ARMAZEM,'' PROJETO,'' OP,'' CC,D1_FORNECE FORNECEDOR,D1_LOJA LOJA,'' PEDIDO,D1_TIPO TIPONF,D1_CUSTO"

			cQuerySub:= "SELECT 1 "

			cQueryD1P := "SELECT 'SD1' ARQ"				// 01
			cQueryD1P += ", SB1.B1_COD PRODUTO"			// 02
			cQueryD1P += ", SB1.B1_TIPO TIPO"			// 03
			cQueryD1P += ", SB1.B1_UM"					// 04
			cQueryD1P += ", SB1.B1_GRUPO"				// 05
			cQueryD1P += ", SB1.B1_DESC"				// 06
			cQueryD1P += ", SB1.B1_POSIPI"				// 07
			cQueryD1P += ", D1_SEQCALC SEQCALC"			// 08
			cQueryD1P += ", D1_DTDIGIT DATA"			// 09
			cQueryD1P += ", D1_TES TES"					// 10
			cQueryD1P += ", D1_CF CF"					// 11
			cQueryD1P += ", D1_NUMSEQ SEQUENCIA"		// 12
			cQueryD1P += ", D1_DOC DOCUMENTO"			// 13
			cQueryD1P += ", D1_SERIE SERIE"				// 14
			cQueryD1P += ", D1_QUANT QUANTIDADE"		// 15
			cQueryD1P += ", D1_QTSEGUM QUANT2UM"		// 16
			cQueryD1P += ", D1_LOCAL ARMAZEM"			// 17
			cQueryD1P += ", '' PROJETO"					// 18
			cQueryD1P += ", '' OP"						// 19
			cQueryD1P += ", '' CC"						// 20
			cQueryD1P += ", D1_FORNECE FORNECEDOR"		// 21
			cQueryD1P += ", D1_LOJA LOJA"				// 22
			cQueryD1P += ", '' PEDIDO"					// 23
			cQueryD1P += ", D1_TIPO TIPONF"				// 24
			cQueryD1P += ", D1_CUSTO"					// 25
			// COLOCA A MOEDA DO CUSTO
			If mv_par11 > 1
				cQueryD1P += Str(mv_par11,1,0)			// 25
			EndIf
			cQueryD1P += " CUSTO"
			cQueryD1P += ", '' TRT" 					// 26
			IF lVEIC
				cQueryD1P += ", SB1.B1_CODITE B1_CODITE"	// 27
			ENDIF
			cQueryD1P += ", D1_LOTECTL LOTE"	    	// 28
			cQueryD1P += ", SD1.R_E_C_N_O_ NRECNO"		// 29

			cQueryD1 := " FROM "
			// cQueryD1 += RetSqlName("SB1") + " SB1 , "+ RetSqlName("SD1")+ " SD1 , "+ RetSqlName("SF4")+" SF4 "
			cQueryD1 += RetSqlName("SB1") + " SB1"
			cQueryD1 += (", " + RetSqlName("SD1")+ " SD1 ")
			cQueryD1 += (", " + RetSqlName("SF4")+ " SF4 ")
			cQueryD1 += " WHERE SB1.B1_COD = D1_COD"
			cQueryD1 += (" AND D1_FILIAL = '"+xFilial("SD1")+"'")
			// cQueryD1 += " AND F4_FILIAL = '"+xFilial("SF4")+"' AND SD1.D1_TES = F4_CODIGO AND F4_ESTOQUE = 'S'"
			cQueryD1 += (" AND F4_FILIAL = '" + xFilial("SF4") + "'")
			cQueryD1 += (" AND SD1.D1_TES = F4_CODIGO AND F4_ESTOQUE = 'S'")
			// cQueryD1 += " AND D1_DTDIGIT >= '"+DTOS(mv_par05)+"' AND D1_DTDIGIT <= '"+DTOS(mv_par06)+"'"
			cQueryD1 += (" AND D1_DTDIGIT >= '" + DTOS(mv_par05) + "'")
			cQueryD1 += (" AND D1_DTDIGIT <= '" + DTOS(mv_par06) + "'")
			cQueryD1 +=  " AND D1_ORIGLAN <> 'LF'"
			If !lCusUnif
				cQueryD1 += " AND D1_LOCAL = '" + mv_par08 + "'"
			EndIf
			//������������������������������������������������������Ŀ
			//� N�o imprimir o produto MANUTENCAO (MV_PRDMNT) qdo integrado com MNT.       �
			//��������������������������������������������������������
			If MTR910IsMNT() 
				If FindFunction("NGProdMNT")
					aProdsMNT := (NGProdMNT())
					For nX := 1 To Len(aProdsMNT)
						cQueryD1 += " AND SB1.B1_COD <> '" + aProdsMNT[nX] + "'"
					Next nX
				Else
					cQueryD1 += " AND SB1.B1_COD <> '" + cProdMNT + "'"
					cQueryD1 += " AND SB1.B1_COD <> '" + cProdTER + "'"
				EndIf
			EndIf	
			cQueryD1 += " AND SD1.D_E_L_E_T_=' ' AND SF4.D_E_L_E_T_=' '"

			// cQueryD2 := " SELECT 'SD2',SB1.B1_COD,SB1.B1_TIPO,SB1.B1_UM,SB1.B1_GRUPO,SB1.B1_DESC,SB1.B1_POSIPI,D2_SEQCALC,D2_EMISSAO,D2_TES,D2_CF,D2_NUMSEQ,D2_DOC,D2_SERIE,D2_QUANT,D2_QTSEGUM,D2_LOCAL,'','',D2_CLIENTE,D2_LOJA,D2_PEDIDO,D2_TIPO,D2_CUSTO"
			cQueryD2P := " SELECT 'SD2'"
			cQueryD2P += ", SB1.B1_COD"
			cQueryD2P += ", SB1.B1_TIPO"
			cQueryD2P += ", SB1.B1_UM"
			cQueryD2P += ", SB1.B1_GRUPO"
			cQueryD2P += ", SB1.B1_DESC"
			cQueryD2P += ", SB1.B1_POSIPI"
			cQueryD2P += ", D2_SEQCALC"
			cQueryD2P += ", D2_EMISSAO"
			cQueryD2P += ", D2_TES"
			cQueryD2P += ", D2_CF"
			cQueryD2P += ", D2_NUMSEQ"
			cQueryD2P += ", D2_DOC"
			cQueryD2P += ", D2_SERIE"
			cQueryD2P += ", D2_QUANT"
			cQueryD2P += ", D2_QTSEGUM"
			cQueryD2P += ", D2_LOCAL"
			cQueryD2P += ", ''"
			cQueryD2P += ", ''"
			cQueryD2P += ", ''"
			cQueryD2P += ", D2_CLIENTE"
			cQueryD2P += ", D2_LOJA"
			cQueryD2P += ", D2_PEDIDO"
			cQueryD2P += ", D2_TIPO"
			cQueryD2P += ", D2_CUSTO"
			// COLOCA A MOEDA DO CUSTO
			cQueryD2P += Str(mv_par11,1,0)
			cQueryD2P += ", ''"
			If lVEIC
				cQueryD2P += ", SB1.B1_CODITE"	
			EndIf
			cQueryD2P += ", D2_LOTECTL"	
			cQueryD2P += ", SD2.R_E_C_N_O_ SD2RECNO"	// 29

			cQueryD2 := " FROM "
			cQueryD2 += RetSqlName("SB1") + " SB1 , "+ RetSqlName("SD2")+ " SD2 , "+ RetSqlName("SF4")+" SF4 "
			cQueryD2 += " WHERE SB1.B1_COD = D2_COD AND D2_FILIAL = '"+xFilial("SD2")+"'"
			cQueryD2 += " AND F4_FILIAL = '"+xFilial("SF4")+"' AND SD2.D2_TES = F4_CODIGO AND F4_ESTOQUE = 'S'"
			cQueryD2 += " AND D2_EMISSAO >= '"+DTOS(mv_par05)+"' AND D2_EMISSAO <= '"+DTOS(mv_par06)+"'"
			cQueryD2 += " AND D2_ORIGLAN <> 'LF'"
			If !lCusUnif
				cQueryD2 += " AND D2_LOCAL = '"+mv_par08+"'"
			EndIf
			//������������������������������������������������������Ŀ
			//� N�o imprimir o produto MANUTENCAO (MV_PRDMNT) qdo integrado com MNT.       �
			//��������������������������������������������������������
			If MTR910IsMNT() 
				If FindFunction("NGProdMNT")
					aProdsMNT := aClone(NGProdMNT())
					For nX := 1 To Len(aProdsMNT)
						cQueryD2 += " AND SB1.B1_COD <> '" + aProdsMNT[nX] + "'"
					Next nX
				Else
					cQueryD2 += " AND SB1.B1_COD <> '" + cProdMNT + "'"
					cQueryD2 += " AND SB1.B1_COD <> '" + cProdTER + "'"
				EndIf
			EndIf	
			cQueryD2 += " AND SD2.D_E_L_E_T_=' ' AND SF4.D_E_L_E_T_=' '"

			// cQueryD3 := " SELECT 'SD3',SB1.B1_COD,SB1.B1_TIPO,SB1.B1_UM,SB1.B1_GRUPO,SB1.B1_DESC,SB1.B1_POSIPI,D3_SEQCALC,D3_EMISSAO,D3_TM,D3_CF,D3_NUMSEQ,D3_DOC,'',D3_QUANT,D3_QTSEGUM,D3_LOCAL,D3_OP,D3_CC,'','','','',D3_CUSTO"
			cQueryD3P := " SELECT 'SD3'"
			cQueryD3P += ", SB1.B1_COD"
			cQueryD3P += ", SB1.B1_TIPO"
			cQueryD3P += ", SB1.B1_UM"
			cQueryD3P += ", SB1.B1_GRUPO"
			cQueryD3P += ", SB1.B1_DESC"
			cQueryD3P += ", SB1.B1_POSIPI"
			cQueryD3P += ", D3_SEQCALC"
			cQueryD3P += ", D3_EMISSAO"
			cQueryD3P += ", D3_TM"
			cQueryD3P += ", D3_CF"
			cQueryD3P += ", D3_NUMSEQ"
			cQueryD3P += ", D3_DOC"
			cQueryD3P += ", ''"
			cQueryD3P += ", D3_QUANT"
			cQueryD3P += ", D3_QTSEGUM"
			cQueryD3P += ", D3_LOCAL"
			cQueryD3P += ", D3_PROJPMS"
			cQueryD3P += ", D3_OP"
			cQueryD3P += ", D3_CC"
			cQueryD3P += ", ''"
			cQueryD3P += ", ''"
			cQueryD3P += ", ''"
			cQueryD3P += ", ''"
			cQueryD3P += ", D3_CUSTO"
			// COLOCA A MOEDA DO CUSTO
			cQueryD3P += Str(mv_par11,1,0)
			cQueryD3P += ", D3_TRT"
			If lVEIC
				cQueryD3P += ", SB1.B1_CODITE"	
			EndIf
			cQueryD3P += ", D3_LOTECTL"	
			cQueryD3P += ", SD3.R_E_C_N_O_ SD3RECNO"		// 29

			cQueryD3 := " FROM "
			cQueryD3 += RetSqlName("SB1") + " SB1 , "+ RetSqlName("SD3")+ " SD3 "
			cQueryD3 += " WHERE SB1.B1_COD = D3_COD AND D3_FILIAL = '"+xFilial("SD3")+"' "
			cQueryD3 += " AND D3_EMISSAO >= '"+DTOS(mv_par05)+"' AND D3_EMISSAO <= '"+DTOS(mv_par06)+"'"
			If SuperGetMV('MV_D3ESTOR', .F., 'N') == 'N'
				cQueryD3 += " AND D3_ESTORNO <> 'S'"
			EndIf
			If SuperGetMV('MV_D3SERVI', .F., 'N') == 'N' .And. IntDL()
				cQueryD3 += " AND ( (D3_SERVIC = '   ') OR (D3_SERVIC <> '   ' AND D3_TM <= '500')  "
				cQueryD3 += " OR  (D3_SERVIC <> '   ' AND D3_TM > '500' AND D3_LOCAL ='"+SuperGetMV('MV_CQ', .F., '98')+"') )"
			EndIf					
			If !lCusUnif .And. !lLocProc
				cQueryD3 += " AND D3_LOCAL = '"+mv_par08+"'"
			EndIf
			//������������������������������������������������������Ŀ
			//� N�o imprimir o produto MANUTENCAO (MV_PRDMNT) qdo integrado com MNT.       �
			//��������������������������������������������������������
			If MTR910IsMNT() 
				If FindFunction("NGProdMNT")
					aProdsMNT := (NGProdMNT())
					For nX := 1 To Len(aProdsMNT)
						cQueryD3 += " AND SB1.B1_COD <> '" + aProdsMNT[nX] + "'"
					Next nX
				Else
					cQueryD3 += " AND SB1.B1_COD <> '" + cProdMNT + "'"
					cQueryD3 += " AND SB1.B1_COD <> '" + cProdTER + "'"
				EndIf
			EndIf	
			cQueryD3 += " AND SD3.D_E_L_E_T_=' '"

			// cQuery := cQueryD1 + cQueryB1A + " AND " + cQueryB1C + " UNION " + cQueryD2 + cQueryB1A + " AND " + cQueryB1C+" UNION "+cQueryD3+cQueryB1A+" AND "+cQueryB1C
			cQuery := cQueryD1P + cQueryD1
			cQuery += cQueryB1A
			cQuery += " AND "
			cQuery += cQueryB1C
			cQuery += " UNION "
			cQuery += cQueryD2P + cQueryD2
			cQuery += cQueryB1A
			cQuery += " AND "
			cQuery += cQueryB1C
			cQuery += " UNION "
			cQuery += cQueryD3P + cQueryD3
			cQuery += cQueryB1A
			cQuery += " AND "
			cQuery += cQueryB1C
			//��������������������������������������������������������Ŀ
			//� So inclui as condicoes a seguir qdo lista produtos sem �
			//� movimento                                              �
			//����������������������������������������������������������
			If mv_par07 == 1
				// cQuery2:= cQueryD1+cQueryB1B+" AND "+cQueryB1C+" UNION "+cQueryD2+cQueryB1B+" AND "+cQueryB1C+" UNION "+cQueryD3+cQueryB1B+" AND "+cQueryB1C
				cQuery2 := " AND NOT EXISTS (" + cQuerySub + cQueryD1
				cQuery2 += cQueryB1B
				cQuery2 += " AND "
				cQuery2 += cQueryB1C
				cQuery2 += ") AND NOT EXISTS ("
				cQuery2 += cQuerySub + cQueryD2
				cQuery2 += cQueryB1B
				cQuery2 += " AND "
				cQuery2 += cQueryB1C
				cQuery2 += ") AND NOT EXISTS ("
				cQuery2 += cQuerySub + cQueryD3
				cQuery2 += cQueryB1B
				cQuery2 += " AND "
				cQuery2 += cQueryB1C + ")"
				//                                       1,            2,             3,           4,              5,             6,               7, 8, 9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24
				// cQuery += " UNION SELECT 'SB1',SB1EXS.B1_COD,SB1EXS.B1_TIPO,SB1EXS.B1_UM,SB1EXS.B1_GRUPO,SB1EXS.B1_DESC,SB1EXS.B1_POSIPI,'','','','','','','',0 , 0,'','','','','','','',0 "
				cQuery += " UNION SELECT 'SB1'"		// 01
				cQuery += ", SB1EXS.B1_COD"			// 02
				cQuery += ", SB1EXS.B1_TIPO"		// 03
				cQuery += ", SB1EXS.B1_UM"			// 04
				cQuery += ", SB1EXS.B1_GRUPO"		// 05
				cQuery += ", SB1EXS.B1_DESC"		// 06
				cQuery += ", SB1EXS.B1_POSIPI"		// 07
				cQuery += ", ''"					// 08
				cQuery += ", ''"					// 09
				cQuery += ", ''"					// 10
				cQuery += ", ''"					// 11
				cQuery += ", ''"					// 12
				cQuery += ", ''"					// 13
				cQuery += ", ''"					// 14
				cQuery += ", 0"						// 15
				cQuery += ", 0"						// 16
				cQuery += ", ''"					// 17
				cQuery += ", ''"					// 18
				cQuery += ", ''"					// 19
				cQuery += ", ''"					// 20
				cQuery += ", ''"					// 21
				cQuery += ", ''"					// 22
				cQuery += ", ''"					// 23
				cQuery += ", ''"					// 24
				cQuery += ", 0"						// 25
				cQuery += ", ''"					// 26
				If lVEIC
					cQuery += ", SB1EXS.B1_CODITE CODITE"	// 27
				EndIf
				cQuery += ", ''"					// 28
				cQuery += ", 0"						// 29

				cQuery += " FROM "+RetSqlName("SB1") + " SB1EXS WHERE"
				cQuery += cQueryB1D
				cQuery += cQuery2
			EndIf
			If aReturn[8]==1
				If ! lVEIC
					cQuery += " ORDER BY 2,9,"
				Else
					cQuery += " ORDER BY 27, 9,"
				EndIf	
			ElseIf aReturn[8] == 2
				If ! lVEIC
					cQUery += " ORDER BY 3,2,9,"
				Else
					cQuery += " ORDER BY 3, 27, 9,"
				EndIf	
			EndIf
			If mv_par16 == 1
				//				cQuery += "17,12"+IIf(lVEIC,',29',',28')
				cQuery += "12"+IIf(lVEIC,',29',',28')
			Else
				If lCusUnif
					cQuery+="8,12"+IIf(lVEIC,',29',',28')
				Else
					//					cQuery+="17,8,12"+IIf(lVEIC,',29',',28')
					cQuery+="8"+IIf(lVEIC,',29',',28')
				EndIf
			EndIf
			cQuery:=ChangeQuery(cQuery)
			MsAguarde({|| dbUseArea(.T.,"TOPCONN",TCGenQry(,,cQuery),cAliasTOP,.F.,.T.)},STR0029)
			dbSelectArea(cAliasTop)
			SetRegua(nTotRegs)
			While !Eof()
				If lEnd
					@PROW()+1,001 PSay STR0016		//"CANCELADO PELO OPERADOR"
					Exit
				EndIf
				IncRegua()
				//��������������������������������������������������Ŀ
				//� Se nao encontrar no arquivo de saldos ,nao lista �
				//����������������������������������������������������
				dbSelectArea("SB2")
				If !dbSeek(xFilial("SB2")+(cAliasTop)->PRODUTO+If(lCusUnif,"",mv_par08))
					dbSelectArea(cAliasTop)
					dbSkip()
					Loop
				EndIf
				// Nao lista de saldo for igual a zero
				If mv_par20 == 2 .And. SB2->B2_QATU == 0
					dbSelectArea(cAliasTop)
					dbSkip()
					Loop
				EndIf
				// Nao lista de saldo for negativo
				If mv_par21 == 2 .And. SB2->B2_QATU < 0
					dbSelectArea(cAliasTop)
					dbSkip()
					Loop
				EndIf

				dbSelectArea(cAliasTop)
				cProdAnt  := (cAliasTop)->PRODUTO
				cLocalAnt := SB2->B2_LOCAL
				nEntrada:=nSaida:=0
				nCEntrada:=nCSaida:=0
				lFirst:=.F.

				//������������������������������������������������������������������������Ŀ
				//� Filtra Registros de Acordo com a Pasta  Filtro da Janela de Impressao  �
				//��������������������������������������������������������������������������
				If !Empty(aReturn[7])
					dbSelectArea("SB1")
					dbSetOrder(1)
					If dbSeek(xFilial("SB1")+alltrim(cProdAnt))
						If !&(aReturn[7])
							dbSelectArea(cAliasTop)
							(cAliasTop)->(dbSkip())
							Loop
						EndIf
					Else
						dbSelectArea(cAliasTop)
						(cAliasTop)->(dbSkip())
						Loop
					EndIf
					dbSelectArea(cAliasTop)
				EndIf

				If li > 58
					cabec(titulo,cabec1,cabec2,wnrel,Tamanho,nTipo)
				EndIf

				//������������������������������������������������Ŀ
				//� Calcula o Saldo Inicial do Produto             �
				//��������������������������������������������������
				If lCusUnif
					aArea:=GetArea()
					aSalAtu  := { 0,0,0,0,0,0,0 }
					dbSelectArea("SB2")
					dbSetOrder(1)
					dbSeek(cSeek:=xFilial("SB2")+(cAliasTOP)->PRODUTO)
					While !Eof() .And. B2_FILIAL+B2_COD == cSeek
						aSalAlmox := CalcEst((cAliasTOP)->PRODUTO,SB2->B2_LOCAL,mv_par05)
						For i:=1 to Len(aSalAtu)
							aSalAtu[i] += aSalAlmox[i]
						Next i
						dbSkip()
					End
					RestArea(aArea)
				Else
					aSalAtu := CalcEst((cAliasTOP)->PRODUTO,mv_par08,mv_par05)
				EndIf

				If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
					aGrupos[nAcho][4] += aSalAtu[mv_par11+1]
				Else
					AADD(aGrupos,{(cAliasTOP)->TIPO,0,0,aSalAtu[mv_par11+1]})
				EndIf

				//������������������������������������������������Ŀ
				//� Calcula o Custo Medio do Produto               �
				//��������������������������������������������������
				If AsalAtu[1] > 0
					nCusmed := aSalAtu[mv_par11+1]/aSalAtu[1]
				ElseIf AsalAtu[1] == 0 .and. AsalAtu[mv_par11+1] == 0
					nCusMed := 0
				Else
					SB2->(dbSeek(xFilial("SB2") + (cAliasTOP)->PRODUTO + (cAliasTOP)->ARMAZEM))
					nCusmed := &("SB2->B2_CM" + Str(mv_par11,1))
				EndIf
				MR910ImpCb(aSalAtu,nCusMed,@Li,cPicB2Qt,cPicB2Cust, cAliasTop)
				lFirst1 := .F.

				While !Eof() .And. (cAliasTop)->PRODUTO = cProdAnt
					IncRegua()
					lContinua := .F.
					If Alltrim((cAliasTop)->ARQ) $ "SD1/SD2"
						lFirst:=.T.
						SF4->(dbSeek(xFilial("SF4")+(cAliasTop)->TES))
						//��������������������������������������������������������������Ŀ
						//� Despreza Notas Fiscais Lancadas Pelo Modulo do Livro Fiscal  �
						//����������������������������������������������������������������
						//��������������������������������������������������������������Ŀ
						//� Executa ponto de entrada para verificar se considera TES que �
						//� NAO ATUALIZA saldos em estoque.                              �
						//����������������������������������������������������������������
						If lIxbConTes .And. SF4->F4_ESTOQUE != "S"
							lTesNEst := ExecBlock("MTAAVLTES",.F.,.F.)
							lTesNEst := If(ValType(lTesNEst) # "L",.F.,lTesNEst)
						EndIf
						If SF4->F4_ESTOQUE != "S" .And. !lTesNEst
							dbSkip()
							Loop
						EndIf
					ElseIf Alltrim((cAliasTop)->ARQ) == "SD3"
						lFirst:=.T.
						//����������������������������������������������������������������Ŀ
						//� Quando movimento ref apropr. indireta, so considera os         �
						//� movimentos com destino ao almoxarifado de apropriacao indireta.�
						//������������������������������������������������������������������
						lInverteMov:=.F.
						If (cAliasTop)->ARMAZEM != cLocalAnt .Or. lCusUnif
							If !(Substr((cAliasTop)->CF,3,1) == "3")
								If !lCusUnif
									dbSkip()
									Loop
								EndIf
							ElseIf lPriApropri
								lInverteMov:=.T.
							EndIf
						EndIf
						//����������������������������������������������������������������Ŀ
						//� Caso seja uma transferencia de localizacao verifica se lista   �
						//� o movimento ou nao                                             �
						//������������������������������������������������������������������
						If mv_par17 == 2 .And. Substr((cAliasTop)->CF,3,1) == "4"
							cNumSeqTr := (cAliasTOP)->(PRODUTO+SEQUENCIA+ARMAZEM)
							aDadosTran:={(cAliasTOP)->TES,(cAliasTOP)->QUANTIDADE,(cAliasTOP)->CUSTO,(cAliasTOP)->QUANT2UM,(cAliasTOP)->TIPO,;
							(cAliasTOP)->DATA,(cAliasTOP)->CF,(cAliasTOP)->SEQUENCIA,(cAliasTOP)->DOCUMENTO,(cAliasTOP)->PRODUTO,;
							(cAliasTOP)->OP,(cAliasTOP)->PROJETO,(cAliasTOP)->CC,(cAliasTOP)->ARQ}
							dbSkip()
							If (cAliasTOP)->(PRODUTO+SEQUENCIA+ARMAZEM) == cNumSeqTr
								dbSkip()
								Loop
							Else
								lContinua := .T.
								If li > 58
									cabec(titulo,cabec1,cabec2,wnrel,Tamanho,nTipo)
								EndIf
								If lFirst
									@Li ,000 PSay STOD(aDadosTran[6])
									@Li ,011 PSay aDadosTran[1]
									If ( cPaisLoc=="BRA" )
										@Li ,015 PSay allTrim(aDadosTran[7])
										If	lInverteMov
											@Li , 018 PSay "*"
										EndIf
									EndIf
									@Li , 020 PSay PadR(IIf(mv_par09 $ "Ss",aDadosTran[8],aDadosTran[9]),12)+" |"
								EndIf
								If aDadosTran[1] <= "500"
									@Li ,038 PSay aDadosTran[2] Picture cPicD3Qt
									@Li ,062 PSay aDadosTran[3] Picture cPicD3Cust
									@Li ,083 PSay "|"
									@Li ,085 PSay aDadosTran[3] / aDadosTran[2] Picture cPicB2Cust
									@Li ,104 PSay "|"
									nEntrada	  += aDadosTran[2]
									aSalAtu[1] += aDadosTran[2]
									nCEntrada  += aDadosTran[3]
									aSalAtu[mv_par11+1] += aDadosTran[3]
									aSalAtu[7] += aDadosTran[4]
									If (nAcho := ASCAN(aGrupos,{|x| aDadosTran[5] == x[1]})) > 0
										aGrupos[nAcho][2]+=aDadosTran[3]
										aGrupos[nAcho][4]+=aDadosTran[3]
									Else
										AADD(aGrupos,{aDadosTran[5],aDadosTran[3],0,aSalAtu[mv_par11+1]})
									EndIf
								Else
									@Li ,083 PSay "|"
									@Li ,085 PSay aDadosTran[3] / aDadosTran[2] Picture cPicB2Cust
									@Li ,104 PSay "|"
									@Li ,108 PSay aDadosTran[2] Picture cPicD3Qt
									@Li ,132 PSay aDadosTran[3] Picture cPicD3Cust
									nSaida	  += aDadosTran[2]
									aSalAtu[1] -= aDadosTran[2]
									nCSaida	  += aDadosTran[3]
									aSalAtu[mv_par11+1] -= aDadosTran[3]
									aSalAtu[7] -= aDadosTran[4]
									If (nAcho := ASCAN(aGrupos,{|x| aDadosTran[5] == x[1]})) > 0
										aGrupos[nAcho][3]+=aDadosTran[3]
										aGrupos[nAcho][4]-=aDadosTran[3]
									Else
										AADD(aGrupos,{aDadosTran[5],0,aDadosTran[3],-(aSalAtu[mv_par11+1])})
									EndIf
								EndIf
							EndIf
						EndIf
					EndIf	
					If li > 58 .And. !lContinua
						cabec(titulo,cabec1,cabec2,wnrel,Tamanho,nTipo)
					EndIf
					If lFirst .And. !lContinua
						@Li ,000 PSay STOD(DATA)
						@Li ,011 PSay TES
						If ( cPaisLoc=="BRA" )
							@Li ,015 PSay allTrim(CF)
							If	lInverteMov
								@Li , 018 PSay "*"
							EndIf
						EndIf
						@Li , 020 PSay PadR(IIF(mv_par09 $ "Ss",SEQUENCIA,DOCUMENTO),12)+" |"
					EndIf

					Do Case
						Case Alltrim((cAliasTop)->ARQ) == "SD1" .And. !lContinua
						lDev:=MTR910Dev(cAliasTop)
						If (cAliasTOP)->TES <= "500" .And. !lDev
							@Li ,038 PSay (cAliasTOP)->QUANTIDADE Picture cPicD1Qt
							@Li ,062 PSay (cAliasTOP)->CUSTO Picture cPicD1Cust
							@Li ,083 PSay "|"
							If (cAliasTOP)->TIPONF != "C"
								@Li ,085 PSay (cAliasTOP)->CUSTO / (cAliasTOP)->QUANTIDADE Picture cPicB2Cust
							EndIf
							@Li ,104 PSay "|"
							nEntrada   += (cAliasTOP)->QUANTIDADE
							aSalAtu[1] += (cAliasTOP)->QUANTIDADE
							nCEntrada  += (cAliasTOP)->CUSTO
							aSalAtu[mv_par11+1] += (cAliasTOP)->CUSTO
							aSalAtu[7] += (cAliasTOP)->QUANT2UM
							If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
								aGrupos[nAcho][2]+=(cAliasTOP)->CUSTO
								aGrupos[nAcho][4]+=(cAliasTOP)->CUSTO
							Else
								AADD(aGrupos,{(cAliasTOP)->TIPO,(cAliasTOP)->CUSTO,0,aSalAtu[mv_par11+1]})
							EndIf
						Else
							@Li ,083 PSay "|"
							If (cAliasTOP)->TIPONF != "C"
								@Li ,085 PSay (cAliasTOP)->CUSTO / (cAliasTOP)->QUANTIDADE Picture cPicB2Cust
							EndIf
							@Li ,104 PSay "|"
							If lDev
								@Li ,108 PSay Space((nTam-1)-Len(Alltrim(Transform((cAliasTOP)->QUANTIDADE,cPicD1Qt))))+"("+Alltrim(Transform((cAliasTOP)->QUANTIDADE,cPicD1Qt))+")"
								cCusto:=Transform((cAliasTOP)->CUSTO,cPicD1Cust)
								@Li ,132 PSay Space((nTam-1)-Len(Alltrim(cCusto)))+"("+Alltrim(cCusto)+")"
								nSaida 	  -= (cAliasTOP)->QUANTIDADE
								aSalAtu[1] += (cAliasTOP)->QUANTIDADE
								nCSaida	  -=(cAliasTOP)->CUSTO
								aSalAtu[mv_par11+1] += (cAliasTOP)->CUSTO
								aSalAtu[7] += (cAliasTOP)->QUANT2UM
								If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
									aGrupos[nAcho][3]-=(cAliasTOP)->CUSTO
									aGrupos[nAcho][4]+=(cAliasTOP)->CUSTO
								Else
									AADD(aGrupos,{(cAliasTOP)->TIPO,0,-((cAliasTOP)->CUSTO),aSalAtu[mv_par11+1]})
								EndIf
							Else
								@Li	,108 PSay (cAliasTOP)->QUANTIDADE Picture cPicD1Qt
								@Li ,132 PSay (cAliasTOP)->CUSTO Picture cPicD1Cust
								nSaida 	  += (cAliasTOP)->QUANTIDADE
								aSalAtu[1] -= (cAliasTOP)->QUANTIDADE
								nCSaida	  +=(cAliasTOP)->CUSTO
								aSalAtu[mv_par11+1] -= (cAliasTOP)->CUSTO
								aSalAtu[7] -= (cAliasTOP)->QUANT2UM
								If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
									aGrupos[nAcho][3]+=(cAliasTOP)->CUSTO
									aGrupos[nAcho][4]-=(cAliasTOP)->CUSTO
								Else
									AADD(aGrupos,{(cAliasTOP)->TIPO,0,(cAliasTOP)->CUSTO,-(aSalAtu[mv_par11+1])})
								EndIf
							EndIf
						EndIf
						Case Alltrim((cAliasTop)->ARQ) = "SD2" .And. !lContinua
						lDev:=MTR910Dev(cAliasTop)
						If (cAliasTOP)->TES <= "500" .Or. lDev
							If lDev
								@Li ,038 PSay Space((nTam-1)-Len(Alltrim(Transform((cAliasTOP)->QUANTIDADE,cPicD2Qt))))+"("+Alltrim(Transform((cAliasTOP)->QUANTIDADE,cPicD2Qt))+")"
								cCusto:=Transform((cAliasTOP)->CUSTO,cPicD2Cust)
								@Li ,062 PSay Space((nTam-1)-Len(Alltrim(cCusto)))+"("+Alltrim(cCusto)+")"
								nEntrada   -= (cAliasTOP)->QUANTIDADE
								aSalAtu[1] -= (cAliasTOP)->QUANTIDADE
								nCEntrada  -= (cAliasTOP)->CUSTO
								aSalAtu[mv_par11+1] -= (cAliasTOP)->CUSTO
								aSalAtu[7] -= (cAliasTOP)->QUANT2UM
								If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
									aGrupos[nAcho][2]-=(cAliasTOP)->CUSTO
									aGrupos[nAcho][4]-=(cAliasTOP)->CUSTO
								Else
									AADD(aGrupos,{(cAliasTOP)->TIPO,-((cAliasTOP)->CUSTO),0,-(aSalAtu[mv_par11+1])})
								EndIf
							Else
								@Li ,038 PSay (cAliasTOP)->QUANTIDADE Picture cPicD2Qt
								@Li ,062 PSay (cAliasTOP)->CUSTO Picture cPicD2Cust
								nEntrada   += (cAliasTOP)->QUANTIDADE
								aSalAtu[1] += (cAliasTOP)->QUANTIDADE
								nCEntrada  += (cAliasTOP)->CUSTO
								aSalAtu[mv_par11+1] += (cAliasTOP)->CUSTO
								aSalAtu[7] += (cAliasTOP)->QUANT2UM
								If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
									aGrupos[nAcho][2]+=(cAliasTOP)->CUSTO
									aGrupos[nAcho][4]+=(cAliasTOP)->CUSTO
								Else
									AADD(aGrupos,{(cAliasTOP)->TIPO,(cAliasTOP)->CUSTO,0,aSalAtu[mv_par11+1]})
								EndIf
							EndIf
							@Li ,083 PSay "|"
							If (cAliasTOP)->TIPONF != "C"
								@Li ,085 PSay (cAliasTOP)->CUSTO / (cAliasTOP)->QUANTIDADE Picture cPicB2Cust
							EndIf
							@Li ,104 PSay "|"
						Else
							@Li ,083 PSay "|"
							If (cAliasTOP)->TIPONF != "C"
								@Li ,085 PSay (cAliasTOP)->CUSTO / (cAliasTOP)->QUANTIDADE Picture cPicB2Cust
							EndIf
							@Li ,104 PSay "|"
							@Li ,108 PSay (cAliasTOP)->QUANTIDADE Picture cPicD2Qt
							@Li ,132 PSay (cAliasTOP)->CUSTO Picture cPicD2Cust
							nSaida     += (cAliasTOP)->QUANTIDADE
							aSalAtu[1] -= (cAliasTOP)->QUANTIDADE
							nCSaida	  +=  (cAliasTOP)->CUSTO
							aSalAtu[mv_par11+1] -= (cAliasTOP)->CUSTO
							aSalAtu[7] -= (cAliasTOP)->QUANT2UM
							If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
								aGrupos[nAcho][3]+=(cAliasTOP)->CUSTO
								aGrupos[nAcho][4]-=(cAliasTOP)->CUSTO
							Else
								AADD(aGrupos,{(cAliasTOP)->TIPO,0,(cAliasTOP)->CUSTO,-(aSalAtu[mv_par11+1])})
							EndIf
						EndIf
						Case Alltrim((cAliasTop)->ARQ) == "SD3" .And. !lContinua
						If	lInverteMov
							If (cAliasTOP)->TES > "500"
								@Li ,038 PSay (cAliasTOP)->QUANTIDADE Picture cPicD3Qt
								@Li ,062 PSay (cAliasTOP)->CUSTO Picture cPicD3Cust
								@Li ,083 PSay "|"
								@Li ,085 PSay (cAliasTOP)->CUSTO / (cAliasTOP)->QUANTIDADE Picture cPicB2Cust
								@Li ,104 PSay "|"
								nEntrada  += (cAliasTOP)->QUANTIDADE
								aSalAtu[1] += (cAliasTOP)->QUANTIDADE
								nCEntrada  +=  (cAliasTOP)->CUSTO
								aSalAtu[mv_par11+1] += (cAliasTOP)->CUSTO
								aSalAtu[7] += (cAliasTOP)->QUANT2UM
								If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
									aGrupos[nAcho][2]+=(cAliasTOP)->CUSTO
									aGrupos[nAcho][4]+=(cAliasTOP)->CUSTO
								Else
									AADD(aGrupos,{(cAliasTOP)->TIPO,(cAliasTOP)->CUSTO,0,aSalAtu[mv_par11+1]})
								EndIf
							Else
								@Li ,083 PSay "|"
								@Li ,085 PSay (cAliasTOP)->CUSTO / (cAliasTOP)->QUANTIDADE Picture cPicB2Cust
								@Li ,104 PSay "|"
								@Li ,108 PSay (cAliasTOP)->QUANTIDADE Picture cPicD3Qt
								@Li ,132 PSay (cAliasTOP)->CUSTO Picture cPicD3Cust
								nSaida	  += (cAliasTOP)->QUANTIDADE
								aSalAtu[1] -= (cAliasTOP)->QUANTIDADE
								nCSaida	  += (cAliasTOP)->CUSTO
								aSalAtu[mv_par11+1] -= (cAliasTOP)->CUSTO
								aSalAtu[7] -= (cAliasTOP)->QUANT2UM
								If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
									aGrupos[nAcho][3]+=(cAliasTOP)->CUSTO
									aGrupos[nAcho][4]-=(cAliasTOP)->CUSTO
								Else
									AADD(aGrupos,{(cAliasTOP)->TIPO,0,(cAliasTOP)->CUSTO,-(aSalAtu[mv_par11+1])})
								EndIf
							EndIf 
							If lCusUnif
								lPriApropri:=.F.
							EndIf
						Else
							If (cAliasTOP)->TES <= "500"
								@Li ,038 PSay (cAliasTOP)->QUANTIDADE Picture cPicD3Qt
								@Li ,062 PSay (cAliasTOP)->CUSTO Picture cPicD3Cust
								@Li ,083 PSay "|"
								@Li ,085 PSay (cAliasTOP)->CUSTO / (cAliasTOP)->QUANTIDADE Picture cPicB2Cust
								@Li ,104 PSay "|"
								nEntrada	  += (cAliasTOP)->QUANTIDADE
								aSalAtu[1] += (cAliasTOP)->QUANTIDADE
								nCEntrada  +=  (cAliasTOP)->CUSTO
								aSalAtu[mv_par11+1] += (cAliasTOP)->CUSTO
								aSalAtu[7] += (cAliasTOP)->QUANT2UM
								If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
									aGrupos[nAcho][2]+=(cAliasTOP)->CUSTO
									aGrupos[nAcho][4]+=(cAliasTOP)->CUSTO
								Else
									AADD(aGrupos,{(cAliasTOP)->TIPO,(cAliasTOP)->CUSTO,0,aSalAtu[mv_par11+1]})
								EndIf
							Else
								@Li ,083 PSay "|"
								@Li ,085 PSay (cAliasTOP)->CUSTO / (cAliasTOP)->QUANTIDADE Picture cPicB2Cust
								@Li ,104 PSay "|"
								@Li ,108 PSay (cAliasTOP)->QUANTIDADE Picture cPicD3Qt
								@Li ,132 PSay (cAliasTOP)->CUSTO Picture cPicD3Cust
								nSaida	  += (cAliasTOP)->QUANTIDADE
								aSalAtu[1] -= (cAliasTOP)->QUANTIDADE
								nCSaida	  += (cAliasTOP)->CUSTO
								aSalAtu[mv_par11+1] -= (cAliasTOP)->CUSTO
								aSalAtu[7] -= (cAliasTOP)->QUANT2UM
								If (nAcho := ASCAN(aGrupos,{|x| (cAliasTOP)->TIPO == x[1]})) > 0
									aGrupos[nAcho][3]+=(cAliasTOP)->CUSTO
									aGrupos[nAcho][4]-=(cAliasTOP)->CUSTO
								Else
									AADD(aGrupos,{(cAliasTOP)->TIPO,0,(cAliasTOP)->CUSTO,-(aSalAtu[mv_par11+1])})
								EndIf
							EndIf
							If lCusUnif
								lPriApropri:=.T.
							EndIf
						EndIf
					EndCase
					If lFirst
						@ Li,153 PSay "|"
						@ Li,157 PSay aSalAtu[1] Picture cPicB2Qt
						@ Li,177 PSay aSalAtu[mv_par11+1] Picture cPicB2Cust
						@ Li,195 PSay "|"
					EndIf
					Do Case
						Case Alltrim((cAliasTop)->ARQ) == "SD3" .And. !lContinua
						If Empty((cAliasTOP)->OP) .And. Empty((cAliasTOP)->PROJETO)
							@ LI,197 PSay 'CC'+(cAliasTOP)->CC
						ElseIf !Empty((cAliasTOP)->PROJETO)
							@ LI,197 PSay 'PJ'+(cAliasTOP)->PROJETO
						ElseIf !Empty((cAliasTOP)->OP)
							@ LI,207 PSay 'OP'+(cAliasTOP)->OP
						EndIf
						Case Alltrim((cAliasTop)->ARQ) == "SD1" .And. !lContinua
						@ LI,207 PSay 'F-'+(cAliasTOP)->FORNECEDOR
						Case Alltrim((cAliasTop)->ARQ) == "SD2" .And. !lContinua
						@ LI,207 PSay 'P-'+(cAliasTOP)->PEDIDO
						Case lContinua .And. aDadosTran[14] == "SD3"
						If Empty(aDadosTran[11]) .And. Empty(aDadosTran[12])
							@ LI,197 PSay 'CC'+aDadosTran[13]
						ElseIf !Empty(aDadosTran[12])
							@ LI,197 PSay 'PJ'+aDadosTran[12]
						ElseIf !Empty(aDadosTran[11])
							@ LI,207 PSay 'OP'+aDadosTran[11]
						EndIf
					EndCase
					Li++

					If !lInverteMov .Or. (lInverteMov .And. lPriApropri)
						If !lContinua //Acerto para utilizar o Array aDadosTran[]
							dbSkip()
						EndIf
					EndIf
				EndDo

				If lFirst
					Li ++
					@ li,000 PSay STR0017	//"T O T A I S  :"
					@ Li,038 PSay nEntrada	Picture cPicD1Qt
					@ Li,062 PSay nCEntrada	Picture cPicD1Cust
					@ Li,108 PSay nSaida	Picture cPicD2Qt
					@ Li,132 PSay nCSaida	Picture cPicD2Cust
					@ Li,157 PSay aSalAtu[1] Picture cPicB2Qt
					@ Li,177 PSay aSalAtu[mv_par11+1] Picture cPicB2Cust
					Li++
					@ Li,135 PSay STR0018	//"QTD. NA SEGUNDA UM: "
					@ Li,157 PSay aSalAtu[7] Picture cPicB2Qt2
					Li++
					@Li ,  0 PSay __PrtThinLine()
					Li++
				Else
					If !MTR910IsMNT()
						Li--
						@Li ,  0 PSay STR0019	//"NAO HOUVE MOVIMENTACAO PARA ESTE PRODUTO"
						Li++
						@Li ,  0 PSay __PrtThinLine()
						Li++
					Else
						If FindFunction("NGProdMNT")
							aProdsMNT := aClone(NGProdMNT())
							If aScan(aProdsMNT, {|x| AllTrim(x) == AllTrim(SB1->B1_COD) }) == 0
								Li--
								@Li ,  0 PSay STR0019	//"NAO HOUVE MOVIMENTACAO PARA ESTE PRODUTO"
								Li++
								@Li ,  0 PSay __PrtThinLine()
								Li++
							EndIf
						ElseIf SB1->B1_COD <> cProdMNT .and. SB1->B1_COD <> cProdTER
							Li--
							@Li ,  0 PSay STR0019	//"NAO HOUVE MOVIMENTACAO PARA ESTE PRODUTO"
							Li++
							@Li ,  0 PSay __PrtThinLine()
							Li++
						EndIf
					EndIf	
				EndIf
			EndDo
			dbSelectArea(cAliasTop)
			dbCloseArea()

			If !Empty(aGrupos)
				Li++
				@ Li,005 PSay STR0020		//"R E S U M O"
				Li++
				Li++
				dbSelectArea("SX5")
				For i:=1 to Len(aGrupos)
					If li > 53
						cabec(titulo,cabec1,cabec2,wnrel,Tamanho,nTipo)
					EndIf
					dbSeek(xFilial("SX5")+"02"+aGrupos[i][1])
					@ Li,000 PSay X5Descri()
					@ Li,063 PSay aGrupos[i][2] Picture cPicD1Cust
					@ Li,132 PSay aGrupos[i][3] Picture cPicD2Cust
					@ Li,177 PSay aGrupos[i][4] Picture cPicB2Cust
					Li++
				Next i
			EndIf
		EndIf // lImpLivro
	Else
		#ENDIF
		//��������������������������������������������������������������Ŀ
		//� Seta ordens dos arquivos de movimentos e monta IndRegua      �
		//����������������������������������������������������������������
		If mv_par16 == 1
			If lCusUnif
				dbSelectArea("SD1")
				cIndice:="D1_FILIAL+D1_COD+DTOS(D1_DTDIGIT)+D1_NUMSEQ"
				IndRegua("SD1",cTrbSD1,cIndice,,DBFilter())
				nInd := RetIndex("SD1")
				#IFNDEF TOP
				dbSetIndex(cTrbSD1+OrdBagExt())
				#ENDIF
				dbSetOrder(nInd+1)

				dbSelectArea("SD2")
				cIndice:="D2_FILIAL+D2_COD+DTOS(D2_EMISSAO)+D2_NUMSEQ"
				IndRegua("SD2",cTrbSD2,cIndice,,DBFilter())
				nInd := RetIndex("SD2")
				#IFNDEF TOP
				dbSetIndex(cTrbSD2+OrdBagExt())
				#ENDIF
				dbSetOrder(nInd+1)

				dbSelectArea("SD3")
				cIndice:="D3_FILIAL+D3_COD+DTOS(D3_EMISSAO)+D3_NUMSEQ"
				IndRegua("SD3",cTrbSD3,cIndice,,DBFilter())
				nInd := RetIndex("SD3")
				#IFNDEF TOP
				dbSetIndex(cTrbSD3+OrdBagExt())
				#ENDIF
				dbSetOrder(nInd+1)
			Else
				dbSelectArea("SD1")
				dbSetOrder(7)
				dbSelectArea("SD2")
				dbSetOrder(6)
				dbSelectArea("SD3")
				dbSetOrder(7)
				If lLocProc
					cIndice:="D3_FILIAL+D3_COD+DTOS(D3_EMISSAO)+D3_NUMSEQ"
					IndRegua("SD3",cTrbSD3,cIndice,,DBFilter(),STR0029)	//"Selecionando Registros"
					nInd := RetIndex("SD3")
					#IFNDEF TOP
					dbSetIndex(cTrbSD3+OrdBagExt())
					#ENDIF
					dbSetOrder(nInd+1)
				EndIf
			EndIf
		Else
			dbSelectArea("SD1")
			If lCusUnif
				cIndice:="D1_FILIAL+D1_COD+DTOS(D1_DTDIGIT)+D1_SEQCALC+D1_NUMSEQ"
			Else
				cIndice:="D1_FILIAL+D1_COD+D1_LOCAL+DTOS(D1_DTDIGIT)+D1_SEQCALC+D1_NUMSEQ"
			EndIf
			IndRegua("SD1",cTrbSD1,cIndice,,DBFilter(),STR0029)	//"Selecionando Registros"
			nInd := RetIndex("SD1")
			#IFNDEF TOP
			dbSetIndex(cTrbSD1+OrdBagExt())
			#ENDIF
			dbSetOrder(nInd+1)

			dbSelectArea("SD2")
			If lCusUnif
				cIndice:="D2_FILIAL+D2_COD+DTOS(D2_EMISSAO)+D2_SEQCALC+D2_NUMSEQ"
			Else
				cIndice:="D2_FILIAL+D2_COD+D2_LOCAL+DTOS(D2_EMISSAO)+D2_SEQCALC+D2_NUMSEQ"
			EndIf
			IndRegua("SD2",cTrbSD2,cIndice,,DBFilter(),STR0029)	//"Selecionando Registros"
			nInd := RetIndex("SD2")
			#IFNDEF TOP
			dbSetIndex(cTrbSD2+OrdBagExt())
			#ENDIF
			dbSetOrder(nInd+1)

			dbSelectArea("SD3")
			If lCusUnif
				cIndice:="D3_FILIAL+D3_COD+DTOS(D3_EMISSAO)+D3_SEQCALC+D3_NUMSEQ"
			Else
				If lLocProc
					cIndice:="D3_FILIAL+D3_COD+DTOS(D3_EMISSAO)+D3_SEQCALC+D3_NUMSEQ"
				Else
					cIndice:="D3_FILIAL+D3_COD+D3_LOCAL+DTOS(D3_EMISSAO)+D3_SEQCALC+D3_NUMSEQ"
				EndIf
			EndIf
			IndRegua("SD3",cTrbSD3,cIndice,,DBFilter(),STR0029)	//"Selecionando Registros"
			nInd := RetIndex("SD3")
			#IFNDEF TOP
			dbSetIndex(cTrbSD3+OrdBagExt())
			#ENDIF
			dbSetOrder(nInd+1)
		EndIf

		dbSelectArea("SB1")
		If ! lVEIC

			If aReturn[8]==1
				dbSetOrder(1)
				dbseek(xFilial("SB1")+mv_par01,.T.)
				cCond1:="B1_COD"
				cCond2:="mv_par02"
			ElseIf aReturn[8] == 2
				dbSetOrder(2)
				dbseek(xFilial("SB1")+mv_par03,.T.)
				cCond1:="B1_TIPO"
				cCond2:="mv_par04"
			EndIf
		Else
			cArq1	:= CriaTrab( nil,.F. )
			If aReturn[8]==1
				IndRegua('SB1',cArq1,"B1_FILIAL+B1_CODITE")
				nInd1	:= RetIndex('SB1')
				#IFNDEF TOP
				dbSetIndex(cArq1 + OrdBagExt())
				#ENDIF
				dbSetOrder(nInd1 + 1)
				dbseek(xFilial("SB1")+mv_par01,.T.)
				cCond1:="B1_CODITE"
				cCond2:="mv_par02"
			ElseIf aReturn[8] == 2
				IndRegua('SB1',cArq1,"B1_FILIAL+B1_TIPO+B1_CODITE")
				nInd1	:= RetIndex('SB1')
				#IFNDEF TOP
				dbSetIndex(cArq1 + OrdBagExt())
				#ENDIF
				dbSetOrder(nInd1 + 1)
				dbseek(xFilial("SB1")+mv_par03,.T.)
				cCond1:="B1_TIPO"
				cCond2:="mv_par04"
			EndIf	
		EndIf	
		SetRegua(Lastrec()) // Cria Regua

		While !Eof() .and. B1_FILIAL == xFilial("SB1") .and. &cCond1 <= &cCond2 .And. lImpLivro

			If lEnd
				@PROW()+1,001 PSay STR0016		//"CANCELADO PELO OPERADOR"
				EXIT
			EndIf

			IncRegua()

			// Filtra por Tipo
			If B1_TIPO < mv_par03 .or. B1_TIPO > mv_par04
				dbSkip()
				Loop
			Endif

			If ! lVEIC
				If B1_COD < mv_par01 .or. B1_COD > mv_par02
					dbSkip()
					Loop
				EndIf
			Else
				If B1_CODITE < mv_par01 .or. B1_CODITE > mv_par02
					dbSkip()
					Loop
				EndIf
			EndIf	

			// Nao lista produto de importacao
			If B1_COD == Substr(cProdImp,1,Len(B1_COD))
				dbSkip()
				Loop
			EndIf

			// Filtra por Grupo
			If B1_GRUPO < mv_par18 .or. B1_GRUPO > mv_par19
				dbSkip()
				Loop
			EndIf

			dbSelectArea("SB2")
			//��������������������������������������������������Ŀ
			//� Se nao encontrar no arquivo de saldos ,nao lista �
			//����������������������������������������������������
			If !dbSeek(xFilial("SB2")+SB1->B1_COD+IF(lCusUnif,"",mv_par08))
				dbSelectArea("SB1")
				dbSkip()
				Loop
			EndIf

			// Nao lista de saldo for igual a zero
			If mv_par20 == 2 .And. SB2->B2_QATU == 0
				dbSelectArea("SB1")
				dbSkip()
				Loop
			EndIf

			// Nao lista de saldo for negativo
			If mv_par21 == 2 .And. SB2->B2_QATU < 0
				dbSelectArea("SB1")
				dbSkip()
				Loop
			EndIf

			nEntrada:=nSaida:=0
			nCEntrada:=nCSaida:=0
			aSalAtu   := { 0,0,0,0,0,0,0 }

			//������������������������������������������������Ŀ
			//� Calcula o Saldo Inicial do Produto             �
			//��������������������������������������������������
			If lCusUnif
				aArea:=GetArea()
				dbSelectArea("SB2")
				dbSetOrder(1)
				dbSeek(xFilial("SB2")+SB1->B1_COD)
				While !Eof() .And. B2_FILIAL+B2_COD == xFilial("SB2")+SB1->B1_COD
					aSalAlmox := CalcEst(SB1->B1_COD,SB2->B2_LOCAL,mv_par05)
					For i:=1 to Len(aSalAtu)
						aSalAtu[i] += aSalAlmox[i]
					Next i
					dbSkip()
				End
				RestArea(aArea)
			Else
				aSalAtu := CalcEst(SB1->B1_COD,mv_par08,mv_par05)
			EndIf

			cProdAnt  := SB1->B1_COD
			cLocalAnt := mv_par08
			dCntData  := mv_par05
			nRec1 := nRec2 := nRec3 := 0
			nCusMed   := 0
			lFirst1   := .T.

			dbSelectArea("SF1")
			dbSetOrder(1)
			dbSelectArea("SF2")
			dbSetOrder(1)
			dbSelectArea("SD1")
			dbSeek(xFilial("SD1")+SB1->B1_COD+If(lCusUnif,"",mv_par08)+dtos(dcntData),.T.)
			dbSelectArea("SD2")
			dbSeek(xFilial("SD2")+SB1->B1_COD+If(lCusUnif,"",mv_par08)+dtos(dcntData),.T.)
			dbSelectArea("SD3")
			dbSeek(xFilial("SD3")+SB1->B1_COD+If(lCusUnif.Or.lLocProc,"",mv_par08)+dtos(dcntData),.T.)

			While .T.
				dbSelectArea("SD1")

				If !Eof() .And. D1_FILIAL == xFilial("SD1") .And. D1_DTDIGIT == dCntData .And. D1_COD == cProdAnt .And. If(lCusUnif,.T.,D1_LOCAL == cLocalAnt)

					//��������������������������������������������������������������Ŀ
					//� Despreza Notas Fiscais Lancadas Pelo Modulo do Livro Fiscal  �
					//����������������������������������������������������������������
					If D1_ORIGLAN $ "LF"
						dbSkip()
						Loop
					EndIf

					//������������������������������������������������Ŀ
					//� Verifica se o TES atualiza estoque             �
					//��������������������������������������������������
					dbSelectArea("SF4")
					dbSeek(xFilial("SF4")+SD1->D1_TES)
					dbSelectArea("SD1")
					//��������������������������������������������������������������Ŀ
					//� Executa ponto de entrada para verificar se considera TES que �
					//� NAO ATUALIZA saldos em estoque.                              �
					//����������������������������������������������������������������
					If lIxbConTes .And. SF4->F4_ESTOQUE != "S"
						lTesNEst := ExecBlock("MTAAVLTES",.F.,.F.)
						lTesNEst := If(ValType(lTesNEst) # "L",.F.,lTesNEst)
					EndIf
					If (SF4->F4_ESTOQUE != "S" .And. !lTesNEst)
						dbSkip()
						Loop
					EndIf
					cSeqIni := IIF(mv_par16==1,D1_NUMSEQ,D1_SEQCALC+D1_NUMSEQ)
					cAlias := Alias()
				EndIf

				dbSelectArea("SD3")
				If !Eof() .And. D3_FILIAL == xFilial("SD3") .And. D3_EMISSAO == dCntData .And. D3_COD == cProdAnt .And. If(lCusUnif.Or.lLocProc,.T.,D3_LOCAL == cLocalAnt)
					//����������������������������������������������������������������Ŀ
					//� Quando movimento ref apropr. indireta, so considera os         �
					//� movimentos com destino ao almoxarifado de apropriacao indireta.�
					//������������������������������������������������������������������
					lInverteMov:=.F.
					If !D3Valido()
						dbSkip()
						Loop
					EndIf
					If D3_LOCAL != cLocalAnt .Or. lCusUnif
						If !(Substr(D3_CF,3,1) == "3")
							If !lCusUnif
								dbSkip()
								Loop
							EndIf
						ElseIf lPriApropri
							lInverteMov:=.T.
						EndIf
					EndIf
					//����������������������������������������������������������������Ŀ
					//� Caso seja uma transferencia de localizacao verifica se lista   �
					//� o movimento ou nao                                             �
					//������������������������������������������������������������������
					nRecTrf1 := 0
					nRecTrf2 := 0
					If mv_par17 == 2 .And. Substr(D3_CF,3,1) == "4"
						If Len(aRecTRF)>0 .And. (aScan(aRecTRF, SD3->(Recno()))>0)
							SD3->(dbSkip())
							Loop
						EndIf
						cNumSeqTr := SD3->D3_COD+SD3->D3_NUMSEQ+SD3->D3_LOCAL//"E9"
						nRegTr    := Recno()
						aAreaSD3  := GetArea()
						SD3->(dbSetOrder(4))
						SD3->(dbGoTo(nRegTr))
						nRecTrf1 := SD3->(Recno())
						dbSkip()
						If SD3->D3_COD+SD3->D3_NUMSEQ+SD3->D3_LOCAL == cNumSeqTr//SD3->D3_CHAVE == cNumSeqTr
							nRecTrf2 := SD3->(Recno())
							aAdd(aRecTRF, nRecTrf1)
							aAdd(aRecTRF, nRecTrf2)
							RestArea(aAreaSD3)
							Loop
						Else
							RestArea(aAreaSD3)
						EndIf
					EndIf
					If mv_par16 == 1
						If D3_NUMSEQ < cSeqIni
							cSeqIni := D3_NUMSEQ
							cAlias := Alias()
						EndIf
					Else
						If D3_SEQCALC+D3_NUMSEQ < cSeqIni
							cSeqIni := D3_SEQCALC+D3_NUMSEQ
							cAlias := Alias()
						EndIf
					EndIf
				EndIf

				dbSelectArea("SD2")
				If !Eof() .And. D2_FILIAL == xFilial("SD2") .And. D2_EMISSAO == dCntData .And. D2_COD == cProdAnt .And. If(lCusUnif,.T.,D2_LOCAL == cLocalAnt)

					//��������������������������������������������������������������Ŀ
					//� Despreza Notas Fiscais Lancadas Pelo Modulo do Livro Fiscal  �
					//����������������������������������������������������������������
					If D2_ORIGLAN == "LF"
						dbSkip()
						Loop
					EndIf

					//������������������������������������������������Ŀ
					//� Verifica se o TES atualiza estoque             �
					//��������������������������������������������������
					dbSelectArea("SF4")
					dbSeek(xFilial("SF4")+SD2->D2_TES)
					dbSelectArea("SD2")
					//��������������������������������������������������������������Ŀ
					//� Executa ponto de entrada para verificar se considera TES que �
					//� NAO ATUALIZA saldos em estoque.                              �
					//����������������������������������������������������������������
					If lIxbConTes .And. SF4->F4_ESTOQUE != "S"
						lTesNEst := ExecBlock("MTAAVLTES",.F.,.F.)
						lTesNEst := If(ValType(lTesNEst) # "L",.F.,lTesNEst)
					EndIf
					If (SF4->F4_ESTOQUE != "S" .And. !lTesNEst)
						dbSkip()
						Loop
					EndIf
					If mv_par16 == 1
						If D2_NUMSEQ < cSeqIni
							cSeqIni := D2_NUMSEQ
							cAlias := Alias()
						EndIf
					Else
						If D2_SEQCALC+D2_NUMSEQ < cSeqIni
							cSeqIni := D2_SEQCALC+D2_NUMSEQ
							cAlias := Alias()
						EndIf
					EndIf
				EndIf


				If !Empty(cAlias)
					dbSelectArea(cAlias)
					cCampo1 := Subs(cAlias,2,2)+IIF(cAlias=="SD1","_DTDIGIT","_EMISSAO")
					cCampo2 := Subs(cAlias,2,2)+"_TES"
					cCampo3 := Subs(cAlias,2,2)+"_CF"
					cCampo4 := Subs(cAlias,2,2)+IIF(mv_par09 $ "Ss","_NUMSEQ","_DOC" )

					If li > 53
						cabec(titulo,cabec1,cabec2,wnrel,Tamanho,nTipo)
					EndIf

					If lFirst1
						//������������������������������������������������Ŀ
						//� Calcula o Custo Medio do Produto               �
						//��������������������������������������������������
						If aSalAtu[1] > 0 .And. aSalAtu[mv_par11+1] > 0
							nCusMed := aSalAtu[mv_par11+1]/aSalAtu[1]
						ElseIf aSalAtu[1] == 0 .And. aSalAtu[mv_par11+1] == 0
							nCusMed := 0
						Else
							nCusMed := &(Eval(bBloco,"SB2->B2_CM",mv_par11))
						EndIf
						MR910ImpCb(aSalAtu,nCusMed,@Li,cPicB2Qt,cPicB2Cust)
						lFirst1 := .F.
					EndIf

					@Li ,   0 PSay &cCampo1
					If cAlias == "SD3"
						@Li ,011 PSay D3_TM
					Else
						@Li ,011 PSay &cCampo2
					EndIf
					If ( cPaisLoc=="BRA" )
						@Li , 015 PSay &cCampo3
						If	lInverteMov
							@Li , 018 PSay "*"
						EndIf
					EndIf
					@Li , 020 PSay PadR(&cCampo4,12)+" |"
					Do Case
						Case cAlias = "SD1"
						lDev:=MTR910Dev(cAliasTop)
						If D1_TES <= "500" .And. !lDev
							@ Li,038 PSay D1_QUANT Picture cPicD1Qt
							@ Li,062 PSay &(Eval(bBloco,"D1_CUSTO",iif(mv_par11==1," ",mv_par11))) Picture cPicD1Cust
							@ Li,083 PSay "|"
							If SF1->F1_TIPO != "C"
								@ Li,085 PSay (&(Eval(bBloco,"D1_CUSTO",iif(mv_par11==1," ",mv_par11))) / D1_QUANT) Picture cPicB2Cust
							EndIf
							@ Li,104 PSay "|"
							nEntrada	+= D1_QUANT
							aSalAtu[1] += D1_QUANT
							nCEntrada += &(Eval(bBloco,"D1_CUSTO",iif(mv_par11==1," ",mv_par11)))
							nGEntrada += &(Eval(bBloco,"D1_CUSTO",iif(mv_par11==1," ",mv_par11)))
							aSalAtu[mv_par11+1] += &(Eval(bBloco,"D1_CUSTO",iif(mv_par11==1," ",mv_par11)))
							aSalAtu[7] += D1_QTSEGUM
						Else
							@ Li,083 PSay "|"
							If SF1->F1_TIPO != "C"
								@ Li,085 PSay (&(Eval(bBloco,"D1_CUSTO",iif(mv_par11==1," ",mv_par11))) / D1_QUANT) Picture cPicB2Cust
							EndIf
							@ Li,104 PSay "|"
							If lDev
								@ Li,108 PSay Space(17-Len(Alltrim(Transform(D1_QUANT,cPicD1Qt))))+"("+Alltrim(Transform(D1_QUANT,cPicD1Qt))+")"
								cCusto:=Transform(&(Eval(bBloco,"D1_CUSTO",iif(mv_par11==1," ",mv_par11))),cPicD1Cust)
								@ Li,132 PSay Space(17-Len(Alltrim(cCusto)))+"("+Alltrim(cCusto)+")"
							Else
								@ Li,108 PSay D1_QUANT Picture cPicD1Qt
								@ Li,132 PSay &(Eval(bBloco,"D1_CUSTO",iif(mv_par11==1," ",mv_par11))) Picture cPicD1Cust
							EndIf
							If !lDev
								nSaida+= D1_QUANT
								aSalAtu[1] -= D1_QUANT
								nCSaida+= &(Eval(bBloco,"D1_CUSTO",iif(mv_par11==1," ",mv_par11)))
								nGSaida+= &(Eval(bBloco,"D1_CUSTO",iif(mv_par11==1," ",mv_par11)))
								aSalAtu[mv_par11+1] -= &(Eval(bBloco,"D1_CUSTO",iif(mv_par11==1," ",mv_par11)))
								aSalAtu[7] -= D1_QTSEGUM
							Else
								nSaida-= D1_QUANT
								aSalAtu[1] += D1_QUANT
								nCSaida-= &(Eval(bBloco,"D1_CUSTO",iif(mv_par11==1," ",mv_par11)))
								nGSaida-= &(Eval(bBloco,"D1_CUSTO",iif(mv_par11==1," ",mv_par11)))
								aSalAtu[mv_par11+1] += &(Eval(bBloco,"D1_CUSTO",iif(mv_par11==1," ",mv_par11)))
								aSalAtu[7] += D1_QTSEGUM
							EndIf
						EndIf
						nRec1++

						Case cAlias = "SD2"
						lDev:=MTR910Dev(cAliasTop)
						If D2_TES <= "500" .Or. lDev
							If lDev
								@ Li,038 PSay Space(17-Len(Alltrim(Transform(D2_QUANT,cPicD2Qt))))+"("+Alltrim(Transform(D2_QUANT,cPicD2Qt))+")"
								cCusto:=Transform(&(Eval(bBloco,"D2_CUSTO",mv_par11)),cPicD2Cust)
								@ Li,062 PSay Space(17-Len(Alltrim(cCusto)))+"("+Alltrim(cCusto)+")"
							Else
								@ Li,038 PSay D2_QUANT Picture cPicD2Qt
								@ Li,062 PSay &(Eval(bBloco,"D2_CUSTO",mv_par11)) Picture cPicD2Cust
							EndIf
							@ Li,083 PSay "|"
							If SF2->F2_TIPO != "C"
								@ Li,085 PSay (&(Eval(bBloco,"D2_CUSTO",mv_par11)) / D2_QUANT) Picture cPicB2Cust
							EndIf
							@ Li,104 PSay "|"
							If !lDev
								nEntrada+= D2_QUANT
								aSalAtu[1] += D2_QUANT
								nCEntrada+= &(Eval(bBloco,"D2_CUSTO",mv_par11))
								nGEntrada+= &(Eval(bBloco,"D2_CUSTO",mv_par11))
								aSalAtu[mv_par11+1] += &(Eval(bBloco,"D2_CUSTO",mv_par11))
								aSalAtu[7] += D2_QTSEGUM
							Else
								//������������������������������������������������Ŀ
								//�Se for devolucao, subtrai nos valores de entrada�
								//��������������������������������������������������
								nEntrada-= D2_QUANT
								aSalAtu[1] -= D2_QUANT
								nCEntrada-= &(Eval(bBloco,"D2_CUSTO",mv_par11))
								nGEntrada-= &(Eval(bBloco,"D2_CUSTO",mv_par11))
								aSalAtu[mv_par11+1] -= &(Eval(bBloco,"D2_CUSTO",mv_par11))
								aSalAtu[7] -= D2_QTSEGUM
							EndIf
						Else
							@ Li,083 PSay "|"
							If SF2->F2_TIPO != "C"
								@ Li,085 PSay (&(Eval(bBloco,"D2_CUSTO",mv_par11)) / D2_QUANT) Picture cPicB2Cust
							EndIf
							@ Li,104 PSay "|"
							@ Li,108 PSay D2_QUANT Picture cPicD2Qt
							@ Li,132 PSay &(Eval(bBloco,"D2_CUSTO",mv_par11)) Picture cPicD2Cust
							nSaida+= D2_QUANT
							aSalAtu[1] -= D2_QUANT
							nCSaida+=  &(Eval(bBloco,"D2_CUSTO",mv_par11))
							nGSaida+=  &(Eval(bBloco,"D2_CUSTO",mv_par11))
							aSalAtu[mv_par11+1] -= &(Eval(bBloco,"D2_CUSTO",mv_par11))
							aSalAtu[7] -= D2_QTSEGUM
						EndIf
						nRec2++

						Otherwise
						If !D3Valido()
							dbSkip()
							Loop
						EndIf

						//����������������������������������������������������������������Ŀ
						//� Caso seja uma transferencia de localizacao verifica se lista   �
						//� o movimento ou nao                                             �
						//������������������������������������������������������������������
						If mv_par17 == 2 .And. Substr(D3_CF,3,1) == "4"
							cNumSeqTr := SD3->D3_COD+SD3->D3_NUMSEQ+SD3->D3_LOCAL
							nRegTr    := Recno()
							dbSkip()
							If SD3->D3_COD+SD3->D3_NUMSEQ+SD3->D3_LOCAL == cNumSeqTr
								dbSkip()
								Loop
							Else
								dbGoto(nRegTr)
							EndIf
						EndIf

						If	lInverteMov
							If D3_TM > "500"
								@Li ,038 PSay D3_QUANT Picture cPicD3Qt
								@Li ,062 PSay &(Eval(bBloco,"D3_CUSTO",mv_par11)) Picture cPicD3Cust
								@Li ,083 PSay "|"
								@Li ,085 PSay (&(Eval(bBloco,"D3_CUSTO",mv_par11)) / D3_QUANT) Picture cPicB2Cust
								@Li ,104 PSay "|"
								nEntrada	  += D3_QUANT
								aSalAtu[1] += D3_QUANT
								nCEntrada  += &(Eval(bBloco,"D3_CUSTO",mv_par11))
								nGEntrada  += &(Eval(bBloco,"D3_CUSTO",mv_par11))
								aSalAtu[mv_par11+1] += &(Eval(bBloco,"D3_CUSTO",mv_par11))
								aSalAtu[7] += D3_QTSEGUM
							Else	
								@Li ,083 PSay "|"
								@Li ,085 PSay (&(Eval(bBloco,"D3_CUSTO",mv_par11)) / D3_QUANT) Picture cPicB2Cust
								@Li ,104 PSay "|"
								@Li ,108 PSay D3_QUANT Picture cPicD3Qt
								@Li ,132 PSay &(Eval(bBloco,"D3_CUSTO",mv_par11)) Picture cPicD3Cust
								nSaida	  += D3_QUANT
								aSalAtu[1] -= D3_QUANT
								nCSaida	  += &(Eval(bBloco,"D3_CUSTO",mv_par11))
								nGSaida	  += &(Eval(bBloco,"D3_CUSTO",mv_par11))
								aSalAtu[mv_par11+1] -= &(Eval(bBloco,"D3_CUSTO",mv_par11))
								aSalAtu[7] -= D3_QTSEGUM
							EndIf
							If lCusUnif
								lPriApropri:=.F.
							EndIf
						Else
							If D3_TM <= "500"
								@ Li,038 PSay D3_QUANT  Picture cPicD3Qt
								@ Li,062 PSay &(Eval(bBloco,"D3_CUSTO",mv_par11)) Picture cPicD3Cust
								@ Li,083 PSay "|"
								@ Li,085 PSay (&(Eval(bBloco,"D3_CUSTO",mv_par11)) / D3_QUANT) Picture cPicB2Cust
								@ Li,104 PSay "|"
								nEntrada+= D3_QUANT
								aSalAtu[1] += D3_QUANT
								nCEntrada+= &(Eval(bBloco,"D3_CUSTO",mv_par11))
								nGEntrada+= &(Eval(bBloco,"D3_CUSTO",mv_par11))
								aSalAtu[mv_par11+1] += &(Eval(bBloco,"D3_CUSTO",mv_par11))
								aSalAtu[7] += D3_QTSEGUM
							Else
								@ Li,083 PSay "|"
								@ Li,085 PSay (&(Eval(bBloco,"D3_CUSTO",mv_par11)) / D3_QUANT) Picture cPicB2Cust
								@ Li,104 PSay "|"
								@ Li,108 PSay D3_QUANT  Picture cPicD3Qt
								@ Li,132 PSay &(Eval(bBloco,"D3_CUSTO",mv_par11)) Picture cPicD3Cust
								nSaida+= D3_QUANT
								aSalAtu[1] -= D3_QUANT
								nCSaida+=  &(Eval(bBloco,"D3_CUSTO",mv_par11))
								nGSaida+=  &(Eval(bBloco,"D3_CUSTO",mv_par11))
								aSalAtu[mv_par11+1] -= &(Eval(bBloco,"D3_CUSTO",mv_par11))
								aSalAtu[7] -= D3_QTSEGUM
							EndIf
							If lCusUnif
								lPriApropri:=.T.
							EndIf
						EndIf
						nRec3++
					EndCase
					@ Li,153 PSay "|"
					@ Li,157 PSay aSalAtu[1] Picture cPicB2Qt
					@ Li,177 PSay aSalAtu[mv_par11+1] Picture cPicB2Cust
					@ Li,195 PSay "|"
					If cPaisLoc <> "CHI"
						Do Case
							Case cAlias = "SD3"  && movimentos (SD3)
							If Empty(D3_OP) .And. Empty(D3_PROJPMS)
								@ LI,197 PSay 'CC'+D3_CC
							ElseIf !Empty(D3_PROJPMS)
								@ LI,197 PSay 'PJ'+D3_PROJPMS
							ElseIf !Empty(D3_OP)
								@ LI,207 PSay 'OP'+D3_OP
							EndIf
							Case cAlias = "SD1"  && compras    (SD1)
							@ LI,207 PSay 'F-'+D1_FORNECE
							Case cAlias = "SD2"  && vendas     (SD2)
							If D2_TIPO == "B"
								@ LI,207 PSay 'F-'+D2_CLIENTE
							Else
								@ LI,207 PSay 'C-'+D2_CLIENTE
							EndIf
						EndCase
					EndIf
					Li++
					cSeqIni := Replicate("z",6)
					cAlias := ""
					If !lInverteMov .Or. (lInverteMov .And. lPriApropri)
						dbSkip()
					EndIf
				Else
					dCntData++
				EndIf

				nAcho:=ASCAN(aGrupos,{|x| SB1->B1_TIPO == x[1]})
				If nAcho > 0
					aGrupos[nAcho][2]+=nGEntrada
					aGrupos[nAcho][3]+=nGSaida
				Else
					AADD(aGrupos,{SB1->B1_TIPO,nGEntrada,nGSaida,0})
					nAcho := Len(aGrupos)
				EndIf

				nGEntrada := 0
				nGSaida   := 0

				If dCntData > mv_par06
					If nRec1 > 0 .or. nRec2 > 0 .or. nRec3 > 0
						nAcho:=ASCAN(aGrupos,{|x| SB1->B1_TIPO == x[1]})
						If nAcho > 0
							aGrupos[nAcho][4]+=aSalAtu[mv_par11+1]
						Else
							AADD(aGrupos,{SB1->B1_TIPO,0,0,aSalAtu[mv_par11+1]})
							nAcho := Len(aGrupos)
						EndIf
						Li ++
						@ li,000 PSay STR0017	//"T O T A I S  :"
						@ Li,038 PSay nEntrada  Picture cPicD1Qt
						@ Li,062 PSay nCEntrada Picture cPicD1Cust
						@ Li,108 PSay nSaida    Picture cPicD2Qt
						@ Li,132 PSay nCSaida   Picture cPicD2Cust
						@ Li,157 PSay aSalAtu[1] Picture cPicB2Qt
						@ Li,177 PSay aSalAtu[mv_par11+1] Picture cPicB2Cust
						Li++
						@ Li,135 PSay STR0018   //"QTD. NA SEGUNDA UM: "
						@ Li,157 PSay aSalAtu[7] Picture cPicB2Qt2
						Li++
						@ Li,000 PSay __PrtThinLine()
						Li++
					Else
						//��������������������������������������������������������Ŀ
						//� Verifica se deve ou nao listar os produtos s/movimento �
						//����������������������������������������������������������
						If mv_par07 == 1
							nAcho:=ASCAN(aGrupos,{|x| SB1->B1_TIPO == x[1]})
							If nAcho > 0
								aGrupos[nAcho][4]+=aSalAtu[mv_par11+1]
							Else
								AADD(aGrupos,{SB1->B1_TIPO,0,0,aSalAtu[mv_par11+1]})
								nAcho := Len(aGrupos)
							EndIf
							If li > 53
								cabec(titulo,cabec1,cabec2,wnrel,Tamanho,nTipo)
							EndIf
							//������������������������������������������������Ŀ
							//� Calcula o Custo Medio do Produto               �
							//��������������������������������������������������
							If aSalAtu[1] > 0 .And. aSalAtu[mv_par11+1] > 0
								nCusMed := aSalAtu[mv_par11+1]/aSalAtu[1]
							ElseIf aSalAtu[1] == 0 .And. aSalAtu[mv_par11+1] == 0
								nCusMed := 0
							Else
								nCusMed := &(Eval(bBloco,"SB2->B2_CM",mv_par11))
							EndIf
							MR910ImpCb(aSalAtu,nCusMed,@Li,cPicB2Qt,cPicB2Cust)

							If !MTR910IsMNT()
								@Li ,  0 PSay STR0019	//"NAO HOUVE MOVIMENTACAO PARA ESTE PRODUTO"
								Li++
								@Li ,  0 PSay __PrtThinLine()
								Li++
							Else
								If FindFunction("NGProdMNT")
									aProdsMNT := aClone(NGProdMNT())
									If aScan(aProdsMNT, {|x| AllTrim(x) == AllTrim(SB1->B1_COD) }) == 0
										@Li ,  0 PSay STR0019	//"NAO HOUVE MOVIMENTACAO PARA ESTE PRODUTO"
										Li++
										@Li ,  0 PSay __PrtThinLine()
										Li++
									EndIf
								ElseIf SB1->B1_COD <> cProdMNT .and. SB1->B1_COD <> cProdTER
									@Li ,  0 PSay STR0019	//"NAO HOUVE MOVIMENTACAO PARA ESTE PRODUTO"
									Li++
									@Li ,  0 PSay __PrtThinLine()
									Li++
								EndIf
							EndIf	
						EndIf
					EndIf
					Exit
				EndIf

			EndDo

			dbSelectArea("SB1")
			dbSkip()

		EndDo

		If !Empty(aGrupos)
			Li++
			@ Li,005 PSay STR0020		//"R E S U M O"
			Li++
			Li++
			cAlias:=Alias()
			dbSelectArea("SX5")
			For i:=1 to Len(aGrupos)
				If li > 53
					cabec(titulo,cabec1,cabec2,wnrel,Tamanho,nTipo)
				EndIf
				dbSeek(xFilial("SX5")+"02"+aGrupos[i][1])
				@ Li,000 PSay X5Descri()
				@ Li,063 PSay aGrupos[i][2] Picture cPicD1Cust
				@ Li,132 PSay aGrupos[i][3] Picture cPicD2Cust
				@ Li,177 PSay aGrupos[i][4] Picture cPicB2Cust
				Li++
			Next i
			dbSelectArea(cAlias)
		EndIf

		#IFDEF TOP
	EndIf	
	#ENDIF

	If li != 80 .and. lImpLivro
		roda(cbcont,cbtxt,Tamanho)
	EndIf

	//��������������������������������������������������������������Ŀ
	//� Impressao de Termos Abertura e Encerramento                  �
	//����������������������������������������������������������������

	If lImpTermos // Impressao dos Termos

		cArqAbert:=GetMv("MV_LMOD3AB")
		cArqEncer:=GetMv("MV_LMOD3EN")

		dbSelectArea("SM0")
		aVariaveis:={}

		For i:=1 to FCount()
			If FieldName(i)=="M0_CGC"
				AADD(aVariaveis,{FieldName(i),Transform(FieldGet(i),"@R 99.999.999/9999-99")})
			Else
				If FieldName(i)=="M0_NOME"
					Loop
				EndIf
				AADD(aVariaveis,{FieldName(i),FieldGet(i)})
			EndIf
		Next

		dbSelectArea("SX1")
		dbSeek(PADR("MTR910",nTamSX1)+"01")

		While SX1->X1_GRUPO==PADR("MTR910",nTamSX1)
			AADD(aVariaveis,{Rtrim(Upper(X1_VAR01)),&(X1_VAR01)})
			dbSkip()
		EndDo

		If !File(cArqAbert)
			aSavSet:=__SetSets()
			//Editor de Termos de Livros
			cArqAbert:=CFGX024(,OemToAnsi(STR0021))		//" Edi��o do Termo de Abertura "
			__SetSets(aSavSet)
			Set(24,Set(24),.t.)
		EndIf

		If !File(cArqEncer)
			aSavSet:=__SetSets()
			// Editor de Termos de Livros
			cArqEncer:=CFGX024(,OemToAnsi(STR0022)) 		//" Edi��o do Termo de Encerramento "
			__SetSets(aSavSet)
			Set(24,Set(24),.t.)
		EndIf

		cDriver:=aDriver[4]
		If cArqAbert#NIL
			ImpTerm(cArqAbert,aVariaveis,&cDriver)
		EndIf

		If cArqEncer#NIL
			ImpTerm(cArqEncer,aVariaveis,&cDriver)
		EndIf

	EndIf

	dbSelectArea("SB1")
	dbClearFilter()
	If !Empty(cArq1) .AND. File(cArq1 + OrdBagExt())
		RetIndex('SB1')
		FERASE(cArq1 + OrdBagExt())
	EndIf
	dbSetOrder(1)

	dbSelectArea("SB2")
	dbSetOrder(1)

	dbSelectArea("SD1")
	If mv_par16 == 2 .Or. lCusUnif
		RetIndex("SD1")
		Ferase(cTrbSD1+OrdBagExt())
	EndIf
	dbSetOrder(1)

	dbSelectArea("SD2")
	If mv_par16 == 2 .Or. lCusUnif
		RetIndex("SD2")
		Ferase(cTrbSD2+OrdBagExt())
	EndIf
	dbSetOrder(1)

	dbSelectArea("SD3")
	If mv_par16 == 2 .Or. lCusUnif
		RetIndex("SD3")
		Ferase(cTrbSD3+OrdBagExt())
	EndIf
	dbSetOrder(1)

	If aReturn[5] = 1
		Set Printer To
		dbCommitAll()
		ourspool(wnrel)
	EndIf

	MS_FLUSH()
RETURN

/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������Ŀ��
���Fun��o    �MR910ImpCb� Autor � Eveli Morasco         � Data � 28/11/92 ���
�������������������������������������������������������������������������Ĵ��
���Descri��o � Imprime o cabecalho do item                                ���
�������������������������������������������������������������������������Ĵ��
���Sintaxe   � MR910ImpCb(ExpA1,ExpN1,@ExpN2)                             ���
�������������������������������������������������������������������������Ĵ��
���Parametros� ExpA1 = Array com informacoes do saldo inicial do item     ���
���          �   [1] = Saldo inicial em quantidade                        ���
���          �   [2] = Saldo inicial em valor                             ���
���          �   [3] = Saldo inicial na 2a unidade de medida              ���
���          � ExpN1 = Custo medio do item                                ���
���          � ExpN2 = Numero da linha corrente de impressao              ���
���          � ExpN3 = Picture Do Campo                                   ���
�������������������������������������������������������������������������Ĵ��
��� Uso      � MATR910                                                    ���
��������������������������������������������������������������������������ٱ�
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
Static Function MR910ImpCb(aSalAtu,nCusMed,Li,cPicB2Qt,cPicB2Cust, cAliasTop) 
	Local lVer116   := (VAL(GetVersao(.F.)) == 11 .And. GetRpoRelease() >= "R6" .Or. VAL(GetVersao(.F.))  > 11)

	#IFDEF TOP
	If !(TcSrvType()=="AS/400") .And. !("POSTGRES" $ TCGetDB())
		If ! lVEIC
			@ Li,000 PSay (cAliasTop)->PRODUTO
			@ Li,019 PSay SubStr((cAliasTop)->B1_DESC,1,30)
			@ Li,056 PSay STR0023+(cAliasTop)->B1_UM			//"UM : "
			@ Li,068 PSay STR0024+(cAliasTop)->TIPO	   		//"TIPO : "
			@ Li,083 PSay STR0025+(cAliasTop)->B1_GRUPO		//"GRUPO : "
			@ Li,115 PSay STR0026								//"Custo Medio : "
			@ Li,132 PSay nCusMed	Picture cPicB2Cust
			@ Li,157 PSay aSalAtu[1] Picture cPicB2Qt
			@ Li,177 PSay aSalAtu[mv_par11+1] Picture cPicB2Cust
			Li++
			If cPaisLoc<>"CHI"
				@ Li,000 PSay STR0027						//"Posicao IPI : "
				@ Li,015 PSay (cAliasTop)->B1_POSIPI Picture "@R 9999.9999.99"
			EndIf

			dbSelectArea("SB2")
			dbSeek(xFilial("SB2")+(cAliasTop)->PRODUTO+If(lCusUnif,"",mv_par08))
			If lVer116
				@ Li,035 PSay STR0028+ If(lCusUnif , MV_PAR08 , Posicione("NNR",1,xFilial("NNR")+MV_PAR08,"NNR_DESCRI")) //"Localizacao : "
			Else
				@ Li,035 PSay STR0028+ If(lCusUnif , MV_PAR08 , SB2->B2_LOCALIZ) //"Localizacao : "
			EndIf
		Else
			@ Li,000 PSay (cAliasTop)->B1_CODITE
			@ Li,PCOL() + 2 PSay SubStr((cAliasTop)->B1_DESC,1,30)	// SB1->B1_DESC
			//	@ Li,056 PSay STR0023+SB1->B1_UM					//"UM : "
			//	@ Li,068 PSay STR0024+SB1->B1_TIPO					//"TIPO : "
			//	@ Li,083 PSay STR0025+SB1->B1_GRUPO					//"GRUPO : "
			@ Li,115 PSay STR0026									//"Custo Medio : "
			@ Li,132 PSay nCusMed	Picture cPicB2Cust
			@ Li,157 PSay aSalAtu[1] Picture cPicB2Qt
			@ Li,177 PSay aSalAtu[mv_par11+1] Picture cPicB2Cust
			Li++
			@ Li,000 PSay (cAliasTop)->PRODUTO // SB1->B1_COD
			@ Li,PCOL() + 2 PSay STR0023 + (cAliasTop)->B1_UM	 	// SB1->B1_UM			//"UM : "
			@ Li,PCOL() + 2 PSay STR0024 + (cAliasTop)->TIPO     	// SB1->B1_TIPO			//"TIPO : "
			@ Li,PCOL() + 2 PSay STR0025 + (cAliasTop)->B1_GRUPO 	// SB1->B1_GRUPO		//"GRUPO : "
			If cPaisLoc<>"CHI"
				@ Li,PCOL() + 2 PSay STR0027						//"Posicao IPI : "
				@ Li,PCOL() + 2 PSay (cAliasTop)->B1_POSIPI /* SB1->B1_POSIPI */ Picture "@R 9999.9999.99"
			EndIf
			If lVer116
				@ Li,PCOL() + 2 PSay STR0028+ If(lCusUnif , MV_PAR08 , Posicione("NNR",1,xFilial("NNR")+MV_PAR08,"NNR_DESCRI")) //"Localizacao : " 
			Else		
				@ Li,PCOL() + 2 PSay STR0028+ If(lCusUnif , MV_PAR08 , SB2->B2_LOCALIZ) //"Localizacao : "
			EndIf
		EndIf

		dbSelectArea(cAliasTop)
	Else	
		#ENDIF

		If ! lVEIC
			@ Li,000 PSay SB1->B1_COD
			@ Li,019 PSay SubStr(SB1->B1_DESC,1,30)
			@ Li,056 PSay STR0023+SB1->B1_UM			//"UM : "
			@ Li,068 PSay STR0024+SB1->B1_TIPO			//"TIPO : "
			@ Li,083 PSay STR0025+SB1->B1_GRUPO			//"GRUPO : "
			@ Li,115 PSay STR0026						//"Custo Medio : "
			@ Li,132 PSay nCusMed	Picture cPicB2Cust
			@ Li,157 PSay aSalAtu[1] Picture cPicB2Qt
			@ Li,177 PSay aSalAtu[mv_par11+1] Picture cPicB2Cust
			Li++
			If cPaisLoc<>"CHI"
				@ Li,000 PSay STR0027						//"Posicao IPI : "
				@ Li,015 PSay SB1->B1_POSIPI Picture "@R 9999.9999.99"
			EndIf
			If lVer116
				@ Li,035 PSay STR0028+ If(lCusUnif , MV_PAR08 , Posicione("NNR",1,xFilial("NNR")+MV_PAR08,"NNR_DESCRI")) //"Localizacao : "
			Else
				@ Li,035 PSay STR0028+ If(lCusUnif , MV_PAR08 , SB2->B2_LOCALIZ) //"Localizacao : "		
			EndIf
		Else
			@ Li,000 PSay SB1->B1_CODITE
			@ Li,PCOL() + 2 PSay SB1->B1_DESC
			//	@ Li,056 PSay STR0023+SB1->B1_UM			//"UM : "
			//	@ Li,068 PSay STR0024+SB1->B1_TIPO			//"TIPO : "
			//	@ Li,083 PSay STR0025+SB1->B1_GRUPO			//"GRUPO : "
			@ Li,115 PSay STR0026							//"Custo Medio : "
			@ Li,132 PSay nCusMed	Picture cPicB2Cust
			@ Li,157 PSay aSalAtu[1] Picture cPicB2Qt
			@ Li,177 PSay aSalAtu[mv_par11+1] Picture cPicB2Cust
			Li++
			@ Li,000 PSay SB1->B1_COD
			@ Li,PCOL() + 2 PSay STR0023+SB1->B1_UM			//"UM : "
			@ Li,PCOL() + 2  PSay STR0024+SB1->B1_TIPO			//"TIPO : "
			@ Li,PCOL() + 2  PSay STR0025+SB1->B1_GRUPO		//"GRUPO : "
			If cPaisLoc<>"CHI"
				@ Li,PCOL() + 2 PSay STR0027					//"Posicao IPI : "
				@ Li,PCOL() + 2 PSay SB1->B1_POSIPI Picture "@R 9999.9999.99"
			EndIf
			If lVer116
				@ Li,PCOL() + 2 PSay STR0028+ If(lCusUnif , MV_PAR08 , Posicione("NNR",1,xFilial("NNR")+MV_PAR08,"NNR_DESCRI")) //"Localizacao : "
			Else 
				@ Li,PCOL() + 2 PSay STR0028+ If(lCusUnif , MV_PAR08 , SB2->B2_LOCALIZ) //"Localizacao : "		
			EndIf
		EndIf

		#IFDEF TOP
	EndIf
	#ENDIF

	Li += 2
RETURN

/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������Ŀ��
���Fun��o    � MTR910val� Autor � Paulo Boschetti       � Data � 22.12.92 ���
�������������������������������������������������������������������������Ĵ��
���Descri��o �                                                            ���
�������������������������������������������������������������������������Ĵ��
��� Uso      � Generico                                                   ���
��������������������������������������������������������������������������ٱ�
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
Static Function Mtr910val()
	Local lRet := .T.

	If mv_par09 $ "dsDS"
		lRet := .T.
	Else
		lRet := .F.
	EndIf

Return lRet

/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������Ŀ��
���Fun��o    � MTR910Dev� Autor � Rodrigo de A. Sartorio� Data � 25.04.96 ���
�������������������������������������������������������������������������Ĵ��
���Descri��o �Avalia se item pertence a uma nota de devolu�ao             ���
�������������������������������������������������������������������������Ĵ��
��� Uso      � MATR910                                                    ���
��������������������������������������������������������������������������ٱ�
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
Static Function MTR910Dev(cAliasTop)
	Static lListaDev := NIL
	LOCAL lRet:=.F.
	LOCAL cAlias:=Alias()


	// Identifica se lista dev. na mesma coluna
	lListaDev := If(ValType(lListaDev)#"L",GetMV("MV_LISTDEV"),lListaDev)


	#IFDEF TOP
	If !(TcSrvType()=="AS/400") .And. !("POSTGRES" $ TCGetDB())
		If lListaDev .And. (cAliasTop)->ARQ == "SD1"
			dbSelectArea("SF1")
			If dbSeek(xFilial("SF1")+(cAliasTop)->DOCUMENTO+(cAliasTop)->SERIE+(cAliasTop)->FORNECEDOR+(cAliasTop)->LOJA) .And. (cAliasTop)->TIPONF == "D"
				lRet:=.T.
			EndIf
		ElseIf lListaDev .And. (cAliasTop)->ARQ == "SD2"
			dbSelectArea("SF2")
			If dbSeek(xFilial("SF2")+(cAliasTop)->DOCUMENTO+(cAliasTop)->SERIE+(cAliasTop)->FORNECEDOR+(cAliasTop)->LOJA) .And. (cAliasTop)->TIPONF == "D"
				lRet:=.T.
			EndIf
		EndIf
		dbSelectArea(cAliasTop)
	Else	
		#ENDIF
		If lListaDev .And. cAlias == "SD1"
			dbSelectArea("SF1")
			If dbSeek(xFilial("SF1")+SD1->D1_DOC+SD1->D1_SERIE+SD1->D1_FORNECE+SD1->D1_LOJA) .And. SF1->F1_TIPO == "D"
				lRet:=.T.
			EndIf
		ElseIf lListaDev .And. cAlias == "SD2"
			dbSelectArea("SF2")
			If dbSeek(xFilial("SF2")+SD2->D2_DOC+SD2->D2_SERIE+SD2->D2_CLIENTE+SD2->D2_LOJA) .And. SF2->F2_TIPO == "D"
				lRet:=.T.
			EndIf
		EndIf
		dbSelectArea(cAlias)

		#IFDEF TOP
	EndIf
	#ENDIF

Return lRet

/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������Ŀ��
���Fun��o    �MTR910CUnf � Autor �Rodrigo de A. Sartorio � Data �26/06/00 ���
�������������������������������������������������������������������������Ĵ��
���Descri��o �Ajusta grupo de perguntas p/ Custo Unificado                ���
�������������������������������������������������������������������������Ĵ��
���Sintaxe   � MTR910Cunf(ExpL1)					                      ���
�������������������������������������������������������������������������Ĵ��
���Parametros� ExpL1 = Custo Unificado								 	  ���
�������������������������������������������������������������������������Ĵ��
��� Uso      � MATR910                                                    ���
��������������������������������������������������������������������������ٱ�
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
Static Function MTR910CUnf(lCusUnif)
	Local aSvAlias:=GetArea()
	Local nTamSX1 :=Len(SX1->X1_GRUPO)
	dbSelectArea("SX1")
	If dbSeek(PADR("MTR910",nTamSX1)+"08",.F.)
		If !("MTR910VAlm" $ X1_VALID)
			RecLock("SX1",.F.)
			If Empty(X1_VALID)
				Replace X1_VALID With "MTR910VAlm"
			Else
				Replace X1_VALID With X1_VALID+".And.MTR910VAlm"
			EndIf
			MsUnlock()
		EndIf
		If lCusUnif .And. X1_CNT01 !=  Repl("*",TamSX3("B2_LOCAL")[1])
			RecLock("SX1",.F.)
			Replace X1_CNT01 With  Repl("*",TamSX3("B2_LOCAL")[1])
			MsUnlock()
		EndIf
	EndIf
	RestArea(aSvAlias)
Return(NIL)

/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������Ŀ��
���Fun��o    �MTR910VAlm � Autor �Rodrigo de A. Sartorio � Data �26/06/00 ���
�������������������������������������������������������������������������Ĵ��
���Descri��o �Valida Almoxarifado do KARDEX com relacao a custo unificado ���
�������������������������������������������������������������������������Ĵ��
���Retorno   � .T. / .F.                                                  ���
�������������������������������������������������������������������������Ĵ��
��� Uso      � MATR910                                                    ���
��������������������������������������������������������������������������ٱ�
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
Static Function MTR910VAlm()
	LOCAL lRet:=.T.
	LOCAL cConteudo:=&(ReadVar())
	LOCAL nOpc:=2
	//��������������������������������������������������������������Ŀ
	//� Verifica se utiliza custo unificado por Empresa/Filial       �
	//����������������������������������������������������������������
	LOCAL lCusUnif := IIf(FindFunction("A330CusFil"),A330CusFil(),GetMV("MV_CUSFIL",.F.))
	If lCusUnif .And. cConteudo != Repl("*",TamSX3("B2_LOCAL")[1])
		nOpc := Aviso(STR0034,STR0035,{STR0036,STR0037})	//"Aten��o"###"Ao alterar o almoxarifado o custo medio unificado sera desconsiderado."###"Confirma"###"Abandona"
		If nOpc == 2
			lRet:=.F.
		EndIf
	EndIf
Return lRet
/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������Ŀ��
���Fun�ao    � AjustaSX1� Autor � Marcos V. Ferreira    � Data �29/08/2005���
�������������������������������������������������������������������������Ĵ��
���Descri��o � Altera descricao da pergunta no SX1                        ���
�������������������������������������������������������������������������Ĵ��
��� Uso      � MATR910			                                          ���
��������������������������������������������������������������������������ٱ�
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/
Static Function AjustaSX1()

	Local aArea := { Alias(), IndexOrd() } , aPerg:={}
	Local aTamSX3:= TamSX3("B2_LOCAL")
	Local cPerg := "MTR910"        
	Local nTamSX1 := Len(SX1->X1_GRUPO)

	Aadd(aPerg,{"So Livro","Solo Libro","Only Book"})
	Aadd(aPerg,{"So Termos","Solo Actas","Terms Only"})

	dbSelectArea("SX1")
	dbSetOrder(1)
	If dbSeek(PADR(cPerg,nTamSX1)+"15")
		RecLock("SX1",.F.)
		Replace X1_DEF01 	with aPerg[1][1]
		Replace X1_DEFSPA1	with aPerg[1][2]
		Replace X1_DEFENG1 	with aPerg[1][3]
		Replace X1_DEF03 	with aPerg[2][1]
		Replace X1_DEFSPA3	with aPerg[2][2]
		Replace X1_DEFENG3 	with aPerg[2][3]
		MsUnLock()
	EndIf

	aPerg := {}
	Aadd(aPerg,{"Digitacao","Digitacion","Typing"})
	Aadd(aPerg,{"Calculo","Calculo","Calculation"})

	dbSelectArea("SX1")
	dbSetOrder(1)

	If dbSeek(PADR(cPerg,nTamSX1)+"07") .And. SX1->X1_TIPO == "C"
		RecLock("SX1",.F.)
		Replace X1_TIPO     with "N"
		Replace X1_PRESEL   with 1
		Replace X1_GSC   	with "C"
		Replace X1_DEF01    with "Sim"
		Replace X1_DEFSPA1  with "Si"
		Replace X1_DEFENG1  with "Yes"
		Replace X1_DEF02    with "Nao"
		Replace X1_DEFSPA2  with "No"
		Replace X1_DEFENG2  with "No"
		Replace X1_CNT01    with " "
		MsUnLock()
	EndIf

	//����������������������������������������������������������������������Ŀ
	//� Ajusta tamanho da get de pergunta do armazem se diferente de B2_LOCAL�
	//������������������������������������������������������������������������
	If dbSeek(PADR(cPerg,nTamSX1)+"08") .And. SX1->X1_TIPO == "C" .And. SX1->X1_TAMANHO != aTamSX3[1]
		RecLock("SX1",.F.)
		Replace X1_TAMANHO with aTamSX3[1]
		MsUnLock()
	EndIf

	If dbSeek(PADR(cPerg,nTamSX1)+"16")
		RecLock("SX1",.F.)
		Replace X1_DEF01 	with aPerg[1][1]
		Replace X1_DEFSPA1	with aPerg[1][2]
		Replace X1_DEFENG1 	with aPerg[1][3]
		Replace X1_DEF02 	with aPerg[2][1]
		Replace X1_DEFSPA2	with aPerg[2][2]
		Replace X1_DEFENG2 	with aPerg[2][3]
		MsUnLock()
	EndIf

	dbSelectArea( aArea[1] )
	dbSetOrder( aArea[2] )
Return

/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������Ŀ��
���Fun��o    �MR910ImpS1� Autor � Nereu Humberto Junior � Data � 12/07/06 ���
�������������������������������������������������������������������������Ĵ��
���Descri��o � Imprime secoes 1 e 2 (Dados do produto)                    ���
�������������������������������������������������������������������������Ĵ��
���Sintaxe   � MR910ImpS1(ExpA1,ExpN1,ExpC1,ExpL1,ExpL2,ExpO1,ExpO2)	  ���
�������������������������������������������������������������������������Ĵ��
���Parametros� ExpA1 = Array com informacoes do saldo inicial do item     ���
���          �   [1] = Saldo inicial em quantidade                        ���
���          �   [2] = Saldo inicial em valor                             ���
���          �   [3] = Saldo inicial na 2a unidade de medida              ���
���          � ExpN1 = Custo medio do item                                ���
���          � ExpC1 = Alias                                              ���
���          � ExpL1 = Veiculo                                            ���
���          � ExpL2 = Custo Unificado                                    ���
���          � ExpO1 = Secao 1                                            ���
���          � ExpO2 = Secao 2                                            ���
�������������������������������������������������������������������������Ĵ��
��� Uso      � MATR910                                                    ���
��������������������������������������������������������������������������ٱ�
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
Static Function MR910ImpS1(aSalAtu,nCusMed,cAliasTop,lVEIC,lCusUnif,oSection1,oSection2)

	Local aArea := GetArea()

	oSection1:Init()
	oSection2:Init()

	oSection1:Cell("nCusMed"):SetValue(nCusMed)
	oSection1:Cell("nQtdSal"):SetValue(aSalAtu[1])
	oSection1:Cell("nVlrSal"):SetValue(aSalAtu[mv_par11+1])			

	#IFDEF TOP
	oSection1:Cell("cProduto"):SetValue((cAliasTop)->PRODUTO)			
	oSection1:Cell("cTipo"):SetValue((cAliasTop)->TIPO	)
	If lVEIC
		oSection2:Cell("cProduto"):SetValue((cAliasTop)->PRODUTO)			
		oSection2:Cell("cTipo"):SetValue((cAliasTop)->TIPO	)
	Endif

	dbSelectArea("SB2")
	dbSeek(xFilial("SB2")+(cAliasTop)->PRODUTO+If(lCusUnif,"",mv_par08))
	#ELSE 
	oSection1:Cell("cProduto"):SetValue(SB1->B1_COD)			
	oSection1:Cell("cTipo"):SetValue(SB1->B1_TIPO)
	If lVEIC
		oSection2:Cell("cProduto"):SetValue(SB1->B1_COD)			
		oSection2:Cell("cTipo"):SetValue(SB1->B1_TIPO)
	Endif
	#ENDIF

	oSection1:PrintLine()
	oSection2:PrintLine()

	RestArea(aArea)

RETURN


/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������Ŀ��
���Fun��o    �MTR910IsMNT� Autor � Lucas                � Data � 03.10.06 ���
�������������������������������������������������������������������������Ĵ��
���Descri��o � Verifica se h� integra��o com o modulo SigaMNT/NG          ���
�������������������������������������������������������������������������Ĵ��
��� Uso      � MATR910                                                    ���
��������������������������������������������������������������������������ٱ�
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
Static Function MTR910IsMNT()
	Local aArea
	Local aAreaSB1
	Local aProdsMNT := {}
	Local cProdMNT	 := ""
	Local nX := 0
	Local lIntegrMNT := .F.

	//Esta funcao encontra-se no modulo Manutencao de Ativos (NGUTIL05.PRX), e retorna os produtos (pode ser MAIS de UM), dos parametros de
	//Manutencao - "M" (MV_PRODMNT) / Terceiro - "T" (MV_PRODTER) / ou Ambos - "*" ou em branco
	If FindFunction("NGProdMNT")
		aProdsMNT := aClone(NGProdMNT("M"))
		If Len(aProdsMNT) > 0
			aArea	 := GetArea()
			aAreaSB1 := SB1->(GetArea())

			SB1->(dbSelectArea( "SB1" ))
			SB1->(dbSetOrder(1))
			For nX := 1 To Len(aProdsMNT)
				If SB1->(dbSeek( xFilial("SB1") + aProdsMNT[nX] ))
					lIntegrMNT := .T.
					Exit
				EndIf 
			Next nX

			RestArea(aAreaSB1)
			RestArea(aArea)
		EndIf
	Else //Se a funcao nao existir, processa com o parametro aceitando 1 (UM) Produto
		cProdMNT	 := GetMv("MV_PRODMNT")
		cProdMNT := cProdMNT + Space(15-Len(cProdMNT))
		If !Empty(cProdMNT)
			aArea	 := GetArea()
			aAreaSB1 := SB1->(GetArea())
			SB1->(dbSelectArea( "SB1" ))
			SB1->(dbSetOrder(1))
			If SB1->(dbSeek( xFilial('SB1') + cProdMNT ))
				lIntegrMNT := .T.
			EndIf 
			RestArea(aAreaSB1)
			RestArea(aArea)
		EndIf
	EndIf
Return( lIntegrMNT )
