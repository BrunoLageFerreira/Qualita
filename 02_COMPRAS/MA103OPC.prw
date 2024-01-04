#INCLUDE "rwmake.ch"
#include "protheus.ch"  

/* 
Desenvolvido para Itinga Minegaracao/Qualita
Bruno Lage
Data : 21/03/2019
*/


User Function MA103OPC()
**************************************************************************************
*	/**/
*
***
Local   aRet := {}
  
	//Aadd(aRet ,{"COMPLEMENTOS FISCAIS"  ,"a910Compl"     , 0 , 4 ,0 ,NIL})	
	Aadd(aRet ,{"PDF FINANCEIROS"       ,"u_MAddPDFTit()", 0 , 4 ,0 ,NIL})
	
	Aadd(aRet ,{"Reserva Lotes"         ,"u_ReservaLt()", 0 , 4 ,0 ,NIL})

	Aadd(aRet ,{"Rateio Custo Serviço"  ,"U_GROA015"     , 0 , 2 ,0 ,NIL})
	
	
	If SubString(CNUMEMP,1,2) == "01"
		Aadd(aRet ,{"CONTROLE BX DIRETA" ,"u_CBXDIRETA()" , 0 , 4 ,0 ,NIL})
	EndIf
	
	Aadd(aRet ,{"Estorna Classificação"	 ,"u_MVALIDEST()" 	 , 0 , 5, 0, nil})


Return(aRet)



User Function ReservaLt()
*******************************************************************************************
*
*
***
Local cValorLote := GetMv("MV_NLOTEQ")

	
cValorLote := Soma1(cValorLote)
PutMv("MV_NLOTEQ",cValorLote)
	

AVISO("Reserva de Lote", "Gerado o lote Qualitá: ["+ cValorLote+ "]. Use o sublotes/chapas com 001,002,003... de maneira subsequente." , { "Fechar" }, 1)

	
Return()

User Function MVALIDEST()
**************************************************************************************
*	/**/
*
***
Local lRet := .T.
Local aArea:= GetArea()

IF dDatabase <> SF1->F1_DTDIGIT
	Alert("Você não pode excluir a NF fora da data de entrada original. Data digitada:" + dToC(SF1->F1_DTDIGIT))
	lRet := .F.
Else
	A140EstCla()
EndIf

RestArea(aArea)

Return(lRet)


User Function CBXDIRETA()
***********************************************************************************************************
*  // Controle de baixas Direas
*
***  

// Variaveis Locais da Funcao
Private cEdit1	 := Space(25)
Private cEdit2	 := Space(25)
Private cEdit3	 := Space(25)
Private cEdit4	 := Space(30)
Private cEdit5	 := Space(25)
Private cEdit6	 := Space(25)
Private cEdit7	 := Space(25)
Private cMemo1	 := ""

Private lCheckBox1	 := .T.
Private oCheckBox1

Private oEdit1
Private oEdit2
Private oEdit3
Private oEdit4
Private oEdit5
Private oEdit6
Private oEdit7
Private oMemo1

// Variaveis Private da Funcao
Private _oDlg				// Dialog Principal
Private lChaveOk := .F.

dbSelectArea("ZA1")
dbSetOrder(2)
If dbSeek(xFilial("ZA1") + SF1->F1_FILIAL + SF1->F1_DOC + SF1->F1_SERIE + SF1->F1_FORNECE + SF1->F1_LOJA + SF1->F1_TIPO  )
	lChaveOk := .f.	
	
	cEdit1	    := ZA1->ZA1_USUAIN
	cEdit2	    := ZA1->ZA1_DTINC
	cEdit3	    := ZA1->ZA1_HORAIN
	lCheckBox1  := ZA1->ZA1_STATUS
	cEdit4	    := ZA1->ZA1_INDEX
	cMemo1      := ZA1->ZA1_OBS
	
	cEdit5	    := ZA1->ZA1_USUBX
	cEdit6	    := ZA1->ZA1_DTBX
	//cEdit7	 := 
	
Else
	lChaveOk := .t.
	
	cEdit1	 := SUBSTR(CUSUARIO,7,15)
	cEdit2	 := dDataBase
	cEdit3	 := TRIM(TIME())
	lCheckBox1 := .T.
	cEdit4	 := SF1->F1_FILIAL + SF1->F1_DOC + SF1->F1_SERIE + SF1->F1_FORNECE + SF1->F1_LOJA + SF1->F1_TIPO
EndIf     

            
DEFINE MSDIALOG _oDlg TITLE "Controle de baixa direta" FROM U_MGETTELA(526),U_MGETTELA(779) TO U_MGETTELA(855),U_MGETTELA(1312) PIXEL

	// Cria as Groups do Sistema
	@ U_MGETTELA(000),U_MGETTELA(004) TO U_MGETTELA(058),U_MGETTELA(262) LABEL " Dados: " PIXEL OF _oDlg

		// Cria Componentes Padroes do Sistema
		@ U_MGETTELA(009),U_MGETTELA(011) Say " Usuário: " Size U_MGETTELA(021),U_MGETTELA(008) COLOR CLR_BLUE PIXEL OF _oDlg
		@ U_MGETTELA(008),U_MGETTELA(085) Say " Data:    " Size U_MGETTELA(015),U_MGETTELA(008) COLOR CLR_BLUE PIXEL OF _oDlg		
		@ U_MGETTELA(009),U_MGETTELA(163) Say " Hora:    " Size U_MGETTELA(013),U_MGETTELA(008) COLOR CLR_BLUE PIXEL OF _oDlg
		@ U_MGETTELA(019),U_MGETTELA(011) MsGet oEdit1 Var cEdit1 Size U_MGETTELA(060),U_MGETTELA(009) WHEN(.F.) COLOR CLR_BLUE PIXEL OF _oDlg
		@ U_MGETTELA(019),U_MGETTELA(085) MsGet oEdit2 Var cEdit2 Size U_MGETTELA(060),U_MGETTELA(009) WHEN(.F.) COLOR CLR_BLUE PIXEL OF _oDlg
		@ U_MGETTELA(019),U_MGETTELA(163) MsGet oEdit3 Var cEdit3 Size U_MGETTELA(034),U_MGETTELA(009) WHEN(.F.) COLOR CLR_BLUE PIXEL OF _oDlg
		@ U_MGETTELA(019),U_MGETTELA(206) CheckBox oCheckBox1 Var lCheckBox1 Prompt " Pendente? " Size U_MGETTELA(048),U_MGETTELA(008) WHEN(.F.) PIXEL OF _oDlg
		
		@ U_MGETTELA(032),U_MGETTELA(011) Say " Chave de pesquisa: " Size U_MGETTELA(047),U_MGETTELA(008) COLOR CLR_BLUE PIXEL OF _oDlg
		@ U_MGETTELA(042),U_MGETTELA(011) MsGet oEdit4 Var cEdit4 Size U_MGETTELA(240),U_MGETTELA(009) WHEN(.F.) COLOR CLR_BLUE PIXEL OF _oDlg
	
	@ U_MGETTELA(060),U_MGETTELA(005) Say " Observações: " Size U_MGETTELA(035),U_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlg
		@ U_MGETTELA(068),U_MGETTELA(005) GET oMemo1 Var cMemo1 MEMO Size U_MGETTELA(256),U_MGETTELA(045) WHEN(lChaveOk) PIXEL OF _oDlg

	@ U_MGETTELA(117),U_MGETTELA(006) TO U_MGETTELA(157),U_MGETTELA(209) LABEL " Confirmação das baixas: " PIXEL OF _oDlg	
		@ U_MGETTELA(133),U_MGETTELA(012) Say " Usuário: " Size U_MGETTELA(021),U_MGETTELA(008) COLOR CLR_RED PIXEL OF _oDlg
		@ U_MGETTELA(134),U_MGETTELA(085) Say " Data:    " Size U_MGETTELA(015),U_MGETTELA(008) COLOR CLR_RED PIXEL OF _oDlg
		//@ U_MGETTELA(134),U_MGETTELA(164) Say " Hora:    " Size U_MGETTELA(015),U_MGETTELA(008) COLOR CLR_RED PIXEL OF _oDlg
		@ U_MGETTELA(144),U_MGETTELA(011) MsGet oEdit5 Var cEdit5 Size U_MGETTELA(060),U_MGETTELA(009) WHEN(.F.) COLOR CLR_RED PIXEL OF _oDlg
		@ U_MGETTELA(144),U_MGETTELA(085) MsGet oEdit6 Var cEdit6 Size U_MGETTELA(060),U_MGETTELA(009) WHEN(.F.) COLOR CLR_RED PIXEL OF _oDlg
		//@ U_MGETTELA(144),U_MGETTELA(163) MsGet oEdit7 Var cEdit7 Size U_MGETTELA(037),U_MGETTELA(009) WHEN(.F.) COLOR CLR_RED PIXEL OF _oDlg
	
	@ U_MGETTELA(124),U_MGETTELA(223) Button " Excluir " Action(CBXDIRGRAVA(2,lChaveOk),_oDlg:End() ) Size U_MGETTELA(037),U_MGETTELA(012) PIXEL OF _oDlg
	@ U_MGETTELA(144),U_MGETTELA(223) Button " Salvar  " Action(CBXDIRGRAVA(1,lChaveOk),_oDlg:End() ) Size U_MGETTELA(037),U_MGETTELA(012) PIXEL OF _oDlg

ACTIVATE MSDIALOG _oDlg CENTERED 

Return(.T.)


Static Function CBXDIRGRAVA(nTipo,lChaveOk)
***********************************************************************************************************
*  // Controle de baixas direas Grava
*
***  
//Alert(nTipo)

If nTipo = 1
	 RecLock( 'ZA1', .T. )	
	  	Replace ZA1->ZA1_FILIAL With xFilial("ZA1")
		Replace ZA1->ZA1_STATUS With lCheckBox1 
		Replace ZA1->ZA1_USUAIN With AllTrim(cEdit1)
		Replace ZA1->ZA1_DTINC  With cEdit2
		Replace ZA1->ZA1_HORAIN With SubStr(cEdit3,1,5)
		Replace ZA1->ZA1_INDEX  With AllTrim(cEdit4)
		Replace ZA1->ZA1_OBS    With UPPER(AllTrim(cMemo1))
	 MsUnLock()
	 AVISO("Salvando...", "Dados salvo com sucesso!" , { "Fechar" }, 1)
EndIf

If nTipo = 2 .AND. lChaveOk == .F.
	 RecLock( 'ZA1', .F. )	
	 	DbDelete()
	 MsUnLock()
	 AVISO("Deletando...", "Dados excluídos com sucesso!" , { "Fechar" }, 1)
EndIf

Return(.T.)


User Function MAddPDFTit()
**************************************************************************************
*	/**/
*
***
Local nCont  := 0
Local nContx := 0
Local cMsgAlert := ""

	/*
	Contagem de quantos 
	titulos possuem a nota.
	*/
	dbSelectArea("SE2")
	dbSetOrder(6) 
	dbSeek( SF1->F1_FILIAL + SF1->F1_FORNECE + SF1->F1_LOJA + SF1->F1_SERIE + SF1->F1_DOC  )

	Do While ( SF1->F1_FILIAL + SF1->F1_FORNECE + SF1->F1_LOJA + SF1->F1_SERIE + SF1->F1_DOC  ) == ( SE2->E2_FILIAL + SE2->E2_FORNECE + SE2->E2_LOJA + SE2->E2_PREFIXO + SE2->E2_NUM)
		nCont := nCont + 1
		dbSelectArea("SE2")
		dbSkip()
	EndDo
	
	/*
	Mensagem para ser exibida durante a 
	adição dos anexos
	*/
	dbSelectArea("SE2")
	dbSetOrder(6) 
	If dbSeek( SF1->F1_FILIAL + SF1->F1_FORNECE + SF1->F1_LOJA + SF1->F1_SERIE + SF1->F1_DOC  )	
		Do While ( SF1->F1_FILIAL + SF1->F1_FORNECE + SF1->F1_LOJA + SF1->F1_SERIE + SF1->F1_DOC  ) == ( SE2->E2_FILIAL + SE2->E2_FORNECE + SE2->E2_LOJA + SE2->E2_PREFIXO + SE2->E2_NUM)
	
				nContx := nContx + 1
				cMsgAlert := ""
				cMsgAlert += "Foi encontrado 0" + AllTrim(Str(nCont)) +" parcela(s).[0" + AllTrim(Str(nCont))+"/0"+  AllTrim(Str(nContx))+"]" + chr(13)+chr(10)   
				cMsgAlert += "Adicione os arquivos PDF conforme seguência abaixo:" + chr(13)+chr(10)   
				cMsgAlert += "PDF da Nota fiscal na Primeira linha. NF: " + SF1->F1_DOC + chr(13)+chr(10)
				If nCont <> 1
					cMsgAlert += "PDF do boleto Parcela [" +SE2->E2_PARCELA + "] no segundo anexo." + chr(13)+chr(10)
				Else
					cMsgAlert += "PDF do boleto no segundo anexo." + chr(13)+chr(10)
				EndIf
				AVISO("Adicionando PDF,s", cMsgAlert , { "Fechar" }, 1)
				MsDocument('SE2',SE2->(RecNo()), 4,)
		
			dbSelectArea("SE2")
			dbSkip()
		EndDo
	Else
		Alert("Não foi encontrado títulos financeiros para anexar os PDF´s!")
	EndIf
	
Return() 
