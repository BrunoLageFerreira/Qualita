#INCLUDE "rwmake.ch"   
#include "protheus.ch"  
#INCLUDE "topconn.ch"

/*                                          
Programa ...: M105BUT.Prw
Uso ........: Ponto de Entrada (botao na baixa de requisição para impordar dados da nota fiscal) baixa direta
Data .......: 12/04/19
Feito por ..: Bruno Lage Ferreira.
*/

User Function M105BUT()
***********************************************************************************************************
*  
*
***    
Local   aButNew  := {}

Aadd(aButNew, {'Imp. Itens (NF)',{||ImpNfEntr()},"Imp. Itens (NF)","Imp. Itens (NF)"}) //"Explode 1o nivel da estrutura"	
	
Return(aButNew)

User Function MT105MNU()
***********************************************************************************************************
*  
*
*** 
Public aPesNota := {}

Return

Static Function ImpNfEntr()
***********************************************************************************************************
*  
*
***
Local aEstrutura:= {}
Local aColsPE   := {}
Local aAreaSD4	:= SD4->(GetArea())
Local aAreaSDC	:= SDC->(GetArea())
Local aAreaSG1	:= SG1->(GetArea())
Local lSugSemSld:= .F.
Local lOk		:= .F.
Local nPercOP 	:= 0
Local nPosCod   := 0
Local i			:= 0
Local nP		:= 0
Local nX		:= 0
Local nItAt     := 0
Local cLocProc  := GetMv("MV_LOCPROC")
Local aSaveCols := aClone(aCols)
Local oDlg
Local nRetorno  := 0
Local aIteNota  := {}

Private cProdEst	:= space(15)//Criavar("CP_PRODUTO",.F.)
Private cNFENT		:= space(30)//Criavar("CP_DOC",.F.)
Private nQtdOrigEs	:= 1
Private nEstru		:= 0


//F1_FILIAL, F1_DOC, F1_SERIE, F1_FORNECE, F1_LOJA, F1_TIPO, R_E_C_N_O_, D_E_L_E_T_
DEFINE MSDIALOG oDlg FROM  140,000 TO 300,400 TITLE OemToAnsi("Informe nota fiscal para importar itens") PIXEL //"Informe produto com estrutura"
//@ 10,15 TO 63,185 LABEL Alltrim(RetTitle("CP_OP"))+" - "+Alltrim(RetTitle("CP_PRODUTO"))+" - "+Alltrim(RetTitle("CP_QUANT")) OF oDlg PIXEL
@ 20,20 MSGET cNFENT F3 "USF1" Picture PesqPict("SF1","F1_DOC")   SIZE 70,9 OF oDlg PIXEL
//@ 35,20 MSGET cProdEst F3 "SB1" Picture PesqPict("SCP","CP_PRODUTO") When( lSugSemSld := If(Empty(cOpEst),.F.,lSugSemSld),oSugerSld:lVisible:=!Empty(cOpEst),SysRefresh(),.T.) Valid (NaoVazio() .Or. ExistCpo("SB1",cProdEst)) SIZE 70,9 OF oDlg PIXEL
//@ 35,95 MSGET nQtdOrigEs Picture PesqPict("SCP","CP_QUANT") Valid (Positivo() .And. NaoVazio()) SIZE 60,9 OF oDlg PIXEL
//@ 50,20 CHECKBOX oSugerSld Var lSugSemSld PROMPT OemtoAnsi(STR0034)	SIZE 150,10 OF oDlg PIXEL //"Sugere itens sem saldo"
DEFINE SBUTTON FROM 67,131 TYPE 1 ACTION (oDlg:End(),lOk:=.T.)  ENABLE OF oDlg
DEFINE SBUTTON FROM 67,158 TYPE 2 ACTION (oDlg:End(),lOk:=.F.)  ENABLE OF oDlg
ACTIVATE MSDIALOG oDlg CENTERED 

//Alert(cNFENT)

dbSelectArea("SD1")
dbSetOrder(1)
dbSeek(AllTrim(cNFENT))
Do While !EOF() .and. SD1->D1_FILIAL + SD1->D1_DOC + SD1->D1_SERIE + SD1->D1_FORNECE + SD1->D1_LOJA == AllTrim(cNFENT)

	If SD1->D1_QUANT <> 0
		aAdd(aIteNota,{SD1->D1_COD,SD1->D1_QUANT,SD1->D1_LOCAL,AllTrim(cNFENT),SD1->D1_CC,0})
	EndIf
	
	dbSelectArea("SD1")
	dbSkip()
EndDo

If Len(aIteNota) == 0
	Alert("Esta NF não pode ser importada, registro não encontrado!")
EndIf

aPesNota := aIteNota

	// Le somente os itens de primeiro nivel
	For i:=1 to Len(aIteNota)

		nItAt := nItAt + 1 

		nRetorno := Val(FWInputBox("Digite quantos linhas de centro de custos no item:" +AllTrim(str(nItAt ))  +"/"+ AllTrim(str(Len(aIteNota))) , ""))

		For nP := 1 to nRetorno

			SB1->(dbSetOrder(1))
			SB1->(dbSeek(xFilial("SB1") + AllTrim(aIteNota[i][1]) ))

			// Verifica Armazem de Processo 
			//If SB1->B1_LOCPAD <> cLocProc

						// Adiciona item no acols
						AADD(aCols,Array(Len(aHeader)+1))
						// Preenche conteudo do acols
						For nx:=1 to Len(aHeader)
							If IsHeadRec(aHeader[nX][2])
								aCols[Len(aCols)][nX] := 0
							ElseIf IsHeadAlias(aHeader[nX][2])
								aCols[Len(aCols)][nX] := "SCP"
							Else
								cCampo:=Alltrim(aHeader[nx,2])
								aCols[Len(aCols)][nx] := CriaVar(cCampo,.F.)
								If cCampo == "CP_ITEM"
									aCols[Len(aCols)][nX] := STRZERO(Len(aCols),LEN(SCP->CP_ITEM))
								ElseIF cCampo == "CP_DATPRF"
									aCols[Len(aCols)][nX] := dDataBase
								EndIf
							EndIf
						Next nx
						
						
						aCOLS[Len(aCols)][Len(aHeader)+1] := .F.
						// Preenche campos especificos
						GDFieldPut("CP_PRODUTO"	,SB1->B1_COD				,Len(aCols)-1)
						GDFieldPut("CP_UM"		,SB1->B1_UM					,Len(aCols)-1)
						GDFieldPut("CP_SEGUM"	,SB1->B1_SEGUM				,Len(aCols)-1)
						GDFieldPut("CP_QUANT"	,aIteNota[i][2]				,Len(aCols)-1)
						GDFieldPut("CP_QTSEGUM"	,ConvUm(SB1->B1_COD,aIteNota[i][2],0,2),Len(aCols)-1)
						GDFieldPut("CP_LOCAL"	,AllTrim(aIteNota[i][3]),Len(aCols)-1)
						GDFieldPut("CP_CONTA"	,SB1->B1_CONTA				,Len(aCols)-1)
						GDFieldPut("CP_ITEMCTA"	,SB1->B1_ITEMCC				,Len(aCols)-1)
						GDFieldPut("CP_DESCRI"	,SB1->B1_DESC				,Len(aCols)-1)
						GDFieldPut("CP_CC"	    ,aIteNota[i][5]				,Len(aCols)-1)
						GDFieldPut("CP_OBS"	    ,"NF-" + aIteNota[i][4]		,Len(aCols)-1)
				
		Next nP
		
		//EndIf
	Next i
	
	If Len(aCols)=0
		// Restaura aCols
		aCols := aClone(aSaveCols)
    EndIf

Return  
