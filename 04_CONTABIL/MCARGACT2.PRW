#include 'rwmake.ch'
#INCLUDE "REPORT.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "TBICONN.CH"

User Function CARGACT2()

	Local cLinha := ""  
	Local nLinha := 0
	Local aDados := {}
	Local nTamLinha := 0
	Local nTamArq:= 0
	Local cTitulo1		:= "Selecione o arquivo"
	Local cExtens     	:= "Arquivo CSV | *.csv"

	cArqImpor := cGetFile(cExtens,cTitulo1,,"C:\Contass",.T.)

	//Valida arquivo
	If !file(cArqImpor)
		Aviso("Arquivo","Arquivo não selecionado ou invalido.",{"Sair"},1)
		Return
	Else     
		//+---------------------------------------------------------------------+
		//| Abertura do arquivo texto                                           |
		//+---------------------------------------------------------------------+
		nHdl := fOpen(cArqImpor)

		If nHdl == -1 
			IF FERROR()== 516 
				ALERT("Feche a planilha que gerou o arquivo.")
			EndIF
		EndIf

		//+---------------------------------------------------------------------+
		//| Verifica se foi possível abrir o arquivo                            |
		//+---------------------------------------------------------------------+
		If nHdl == -1
			cMsg := "O arquivo de nome "+cArqImpor+" nao pode ser aberto! Verifique os parametros."
			MsgAlert(cMsg,"Atencao!")
			Return
		Endif

		//+---------------------------------------------------------------------+
		//| Posiciona no Inicio do Arquivo                                      |
		//+---------------------------------------------------------------------+
		FSEEK(nHdl,0,0)

		//+---------------------------------------------------------------------+
		//| Traz o Tamanho do Arquivo TXT                                       |
		//+---------------------------------------------------------------------+
		nTamArq:=FSEEK(nHdl,0,2)

		//+---------------------------------------------------------------------+
		//| Posicona novamemte no Inicio                                        |
		//+---------------------------------------------------------------------+
		FSEEK(nHdl,0,0)

		//+---------------------------------------------------------------------+
		//| Fecha o Arquivo                                                     |
		//+---------------------------------------------------------------------+
		fClose(nHdl)
		FT_FUse(cArqImpor)  //abre o arquivo 
		FT_FGOTOP()         //posiciona na primeira linha do arquivo      
		nTamLinha := Len(FT_FREADLN()) //Ve o tamanho da linha
		FT_FGOTOP()

		//+---------------------------------------------------------------------+
		//| Verifica quantas linhas tem o arquivo                               |
		//+---------------------------------------------------------------------+
		nLinhas := nTamArq/nTamLinha

		ProcRegua(nLinhas)

		aDados:={}  
		While !FT_FEOF() //Ler todo o arquivo enquanto não for o final dele

			//            IncProc('Importando Linha: ' + Alltrim(Str(nCont)) )
			IncProc('Importando Linha: ')

			clinha := FT_FREADLN() 

			aadd(aDados,Separa(cLinha,";",.T.))

			FT_FSKIP()
		EndDo

		FT_FUse()
		fClose(nHdl)

		/*
		If FERASE(cArqImpor) == -1
			MsgStop('Falha na deleção do Arquivo')
		Endif
		*/
	EndIf

	ProcRegua(len(aDados))

	For i := 1 to len(aDados)
		
		cData     := aDados[i,1]
		cContaDeb := Alltrim(aDados[i,2])
		cContaCrd := Alltrim(aDados[i,3])
		nValor	  := VAL(REPLACE(REPLACE((aDados[i,4]),'.',''),',','.'))
		cHistor   := aDados[i,5]
		cCCD	  := Alltrim(aDados[i,6])	
		cCCC      := Alltrim(aDados[i,7])

		cItemD	  := ""	
		cItemC    := ""

		Processa({|| IncluiCT2(cData, cContaDeb, cContaCrd, cItemD, cItemC, cHistor, nValor, i, cCCD, cCCC)}, "Aguarde", "Importando lancamento -> " + Alltrim(Str(i)) + ' de ' + Alltrim(Str(len(aDados))), .T.)

	Next

	Aviso("Atenção","Importação com exito!",{"Ok"},1)

Return

Static Function IncluiCT2(cData, cContaDeb, cContaCrd, cItemD, cItemC, cHistor, nValor, i, cCCD, cCCC)

	Local _lOk := .T.
	Local aItens := {}
	Local aCab := {} 
	Local cTipo := ''

	PRIVATE lMsErroAuto := .F.

	If Len(cContaCrd) = 0 .and. Len(cContaDeb) > 0
		cTipo := '1'
	EndIf

	If Len(cContaCrd) > 0 .and. Len(cContaDeb)= 0
		cTipo := '2'
	EndIf

	If Len(cContaCrd) > 0 .and. Len(cContaDeb)> 0
		cTipo := '3'
	EndIf

	aCab := { {'DDATALANC' , ctod(cData) ,NIL},;
	{'CLOTE' ,'333335' ,NIL},;
	{'CSUBLOTE' ,'001' ,NIL},;
	{'CDOC' ,CTBPRXDOC(ctod(cData),'333335','001') ,NIL},;
	{'CPADRAO' ,'' ,NIL},;
	{'NTOTINF' ,0 ,NIL},;
	{'NTOTINFLOT' ,0 ,NIL} }

	aAdd(aItens,{ {'CT2_FILIAL' ,cFilAnt , NIL},;
	{'CT2_LINHA' ,StrZero(i,3,0) , NIL},;
	{'CT2_MOEDLC' ,'01' , NIL},;
	{'CT2_DC' ,cTipo , NIL},;
	{'CT2_DEBITO' ,cContaDeb , NIL},;
	{'CT2_CREDIT' ,cContaCrd , NIL},;
	{'CT2_CCD' ,cCCD , NIL},;
	{'CT2_CCC' ,cCCC , NIL},;
	{'CT2_VALOR' , nValor , NIL},;
	{'CT2_ITEMC' ,cItemC , NIL},;
	{'CT2_ITEMD' ,cItemD , NIL},;
	{'CT2_ORIGEM' ,'MSEXECAUT', NIL},;
	{'CT2_HP' ,'' , NIL},;
	{'CT2_CONVER','15555', NIL},;
	{'CT2_HIST' , cHistor , NIL} } )

	MSExecAuto( {|X,Y,Z| CTBA102(X,Y,Z)} ,aCab ,aItens, 3)

	If lMsErroAuto
		MostraErro()
	Endif

Return

STATIC FUNCTION CTBPRXDOC(DataLote, Lote, SubLote)

	Local aArea    := GetArea()
	Local cProxDoc := "000001"
	Local dDataLanc:= DataLote
	Local cLote    := Lote
	Local cSubLote := SubLote
	Local cQuery   := ""
	Local dDataIni := CTOD("")
	Local dDataFim := CTOD("")   
	dDataIni := FIRSTDAY(dDataLanc)
	dDataFim := LASTDAY(dDataLanc)

	cQuery := "SELECT Max(CTF_DOC) MAXDOC "
	cQuery += "FROM "+RetSqlName("CTF")+" CTF WHERE "
	cQuery += "CTF_DATA BETWEEN '"+DTOS(dDataIni)+"' AND '"+DTOS(dDataFim)+"' AND "
	cQuery += "CTF_LOTE = '"+cLote+"' AND "
	cQuery += "CTF_SBLOTE = '"+cSubLote+"' AND "
	cQuery += "D_E_L_E_T_=' ' "
	cQuery := ChangeQuery(cQuery)

	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"TMPPRXDOC")

	cProxDoc := STRZERO(VAL(("TMPPRXDOC")->MAXDOC),6)

	dbSelectArea("TMPPRXDOC")

	("TMPPRXDOC")->(dbCloseArea())

	cProxDoc := SOMA1(cProxDoc)

	RestArea(aArea)

RETURN cProxDoc