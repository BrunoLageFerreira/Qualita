#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
#INCLUDE "topconn.ch"          


/* ####################################################################### *\
|| #           PONTO DE ENTRADA UTILIZADO PELO IMPORTADOR GATI           # ||
|| #                                                                     # ||
|| #  É EXECUTADO DEPOIS QUE A NOTA É EXCLUÍDA PARA FAZER O XML VOLTAR   # ||
|| #                  PARA A TELA INICIAL DO IMPORTADOR                  # ||
\* ####################################################################### */

/*
SO funciona na qualita pois foi incapsulado o ponto original para o GrPlus
Não pode usar o MT103FIM

Caso tenha que descompilar o MT103FIM 
deve tambem aplicar novamnte o pacth do GrPlus pois ele utiliza por padrão este ponto.
Deve-se sempre ser compilado o GMT130FIM
*/

/*
Programa ...: FAPAGAPROV.Prw 
Data .......: 06/05/2020
Feito por ..: Bruno Lage Ferreira
Copyright @1998-2001,2020
*/ 

User Function GMT103FIM()
/**********************************************************************************************************************
*
*
*
***/
Local aGMT103FIM := GetArea()
Local cQuery    := ""
Local nOpcao    := PARAMIXB[1]   // Opção Escolhida pelo usuario no aRotina
Local nConfirma := PARAMIXB[2]   // Se o usuario confirmou a operação de gravação da NFE
Local Usuario   := ""
Local xInvoice  := "          "
Local oEdit1


ConOut("*****************************")
ConOut("GMT103FIM() - NÃO COMPILAR NO PORTAL GRPLUS Informativo dos parametros")
ConOut(CNUMEMP)
ConOut(SUBSTR(CUSUARIO,7,15)+" "+TRIM(DTOC(DATE()))+" "+TRIM(TIME())+" "+TRIM(COMPUTERNAME()))
ConOut(nConfirma )
ConOut(nOpcao)
ConOut("*****************************")


/*
Inclui o nome do usuario que adicionou a nota fiscal
*/
Usuario := SUBSTR(CUSUARIO,7,15)+" "+TRIM(DTOC(DATE()))+" "+TRIM(TIME())+" "+TRIM(COMPUTERNAME())

IF INCLUI  
	
	dbSelectArea("SF1")
	If SF1->(RecLock("SF1",.F.)) 
		If nConfirma == 1 .and. nOpcao == 3 
		   
		    ConOut("*****************************")
		    ConOut(Usuario)   
	    	ConOut("GMT103FIM() Entrou")
	    	ConOut("*****************************")
	    	
	    	//Replace F1_INCUSER With cUserName     
	    	Replace F1_INCUSER With Usuario 
			Replace F1_ESPECI4 With SED->ED_CODIGO
			//Replace F1_NATUREZ With SED->ED_CODIGO
		Else
			ConOut("*****************************")
		    ConOut(Usuario)   
	    	ConOut("GMT103FIM() Nao entrou")
	    	ConOut("*****************************")
		EndIf

		SF1->(MsUnLock()) 
	EndIf
ENDIF


/*
Chamada para Conexção NFe
*/
U_GTPE002()

/*
Grava a forma de pagamento no titulo confome esta na condição de pagamento 
*/
IF !EMPTY(SF1->F1_COND) .And. INCLUI
	cQuery := " SELECT R_E_C_N_O_ RECNO, 
	cQuery += " 	   E2_FILIAL       ,
	cQuery += " 	   E2_PREFIXO      ,
	cQuery += " 	   E2_TIPO         ,
	cQuery += " 	   E2_NUM          ,
	cQuery += " 	   E2_PARCELA      ,
	cQuery += " 	   E2_EMISSAO      ,
	cQuery += " 	   E2_VENCTO       ,
	cQuery += " 	   E2_VENCREA      ,
	cQuery += " 	   E2_BAIXA        ,
	cQuery += " 	   E2_VALOR 
	cQuery += "   FROM " + RetSqlName("SE2") + " SE2 
	cQuery += "  WHERE E2_FORNECE = '"+ SF1->F1_FORNECE +"' 
	cQuery += "    AND E2_LOJA    = '"+ SF1->F1_LOJA    +"' 
	cQuery += "    AND E2_NUM     = '"+ SF1->F1_DOC     +"'
	cQuery += "    AND E2_PREFIXO = '"+ SF1->F1_SERIE   +"'
	cQuery += "    AND D_E_L_E_T_ = ''
	cQuery += "    AND E2_BAIXA   = '' 

	dbSelectArea("SE4")
	dbSetOrder(1)
	dbSeek(xFilial("SE4")+AllTrim(SF1->F1_COND))

	TcQuery cQuery Alias TMP_FIMPG New
	dbSelectArea("TMP_FIMPG")
	
	Do While !EOF()	
		ConOut("*************************************************")
		ConOut("*************************************************")
		ConOut("***Atualização Forma de Pagamento********OK******")
		ConOut("*************************************************")
		ConOut("*************************************************")
	
		dbSelectArea("SE2")
		dbGoto(TMP_FIMPG->RECNO) 
		SE2->(reclock("SE2", .F.))
			//Alert("Apagou:" + SE2->E2_NUM)
			//DbDelete()  
			Replace SE2->E2_FORMPAG  With AllTrim(SE4->E4_FORMA)	
		SE2->(msUnLock())
		
		dbSelectArea("TMP_FIMPG")
		dbSkip()
	EndDo

	dbSelectArea("TMP_FIMPG")
	dbCloseArea()
EndIf


/*
Pergunta ao usuário se deseja inserir a Invoice no titulo a pagar.
*/
IF !EMPTY(SF1->F1_COND) .And. (INCLUI) .And. (nConfirma == 1)
	cQuery := " SELECT R_E_C_N_O_ RECNO, 
	cQuery += " 	   E2_FILIAL       ,
	cQuery += " 	   E2_PREFIXO      ,
	cQuery += " 	   E2_TIPO         ,
	cQuery += " 	   E2_NUM          ,
	cQuery += " 	   E2_PARCELA      ,
	cQuery += " 	   E2_EMISSAO      ,
	cQuery += " 	   E2_VENCTO       ,
	cQuery += " 	   E2_VENCREA      ,
	cQuery += " 	   E2_BAIXA        ,
	cQuery += " 	   E2_VALOR 
	cQuery += "   FROM " + RetSqlName("SE2") + " SE2 
	cQuery += "  WHERE E2_FORNECE = '"+ SF1->F1_FORNECE +"' 
	cQuery += "    AND E2_LOJA    = '"+ SF1->F1_LOJA    +"' 
	cQuery += "    AND E2_NUM     = '"+ SF1->F1_DOC     +"'
	cQuery += "    AND E2_PREFIXO = '"+ SF1->F1_SERIE   +"'
	cQuery += "    AND D_E_L_E_T_ = ''
	cQuery += "    AND E2_BAIXA   = '' 
	
	DEFINE MSDIALOG _oDlg TITLE "Invoice no título a pagar: (Logística)." FROM U_MGETTELA(393),U_MGETTELA(670) TO U_MGETTELA(501),U_MGETTELA(1117) PIXEL
		// Cria as Groups do Sistema
		@ U_MGETTELA(001),U_MGETTELA(006) TO U_MGETTELA(044),U_MGETTELA(172) LABEL "" PIXEL OF _oDlg
	
		// Cria Componentes Padroes do Sistema
		@ U_MGETTELA(013),U_MGETTELA(011) Say "Informe o número da invoice fornecido pela Logística:" Size U_MGETTELA(129),U_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlg
		@ U_MGETTELA(025),U_MGETTELA(012) MsGet oEdit1 Var xInvoice Size U_MGETTELA(060),U_MGETTELA(009) COLOR CLR_BLACK PIXEL OF _oDlg
		@ U_MGETTELA(031),U_MGETTELA(177) Button "OK" Size U_MGETTELA(037),U_MGETTELA(012) ACTION (_oDlg:End()) PIXEL OF _oDlg
	ACTIVATE MSDIALOG _oDlg CENTERED 

	TcQuery cQuery Alias TMP_FIMINVO New
	dbSelectArea("TMP_FIMINVO")
	
	Do While !EOF()	.And. !Empty(xInvoice)
		ConOut("*************************************************")
		ConOut("*************************************************")
		ConOut("***Atualização E2_XINVOI         ********OK******")
		ConOut("*************************************************")
		ConOut("*************************************************")
	
		dbSelectArea("SE2")
		dbGoto(TMP_FIMINVO->RECNO) 
		SE2->(reclock("SE2", .F.))
			//Alert("Apagou:" + SE2->E2_NUM)
			//DbDelete()  
			Replace SE2->E2_XINVOI  With AllTrim(xInvoice)	
		SE2->(msUnLock())
		
		dbSelectArea("TMP_FIMINVO")
		dbSkip()
	EndDo

	dbSelectArea("TMP_FIMINVO")
	dbCloseArea()
EndIf


/*
Chamada para verificar se existe provisões financeiras e solicitar que o usuario apague 
*/
cQuery := " SELECT R_E_C_N_O_ RECNO, 
cQuery += " 	   E2_FILIAL       ,
cQuery += " 	   E2_PREFIXO      ,
cQuery += " 	   E2_TIPO         ,
cQuery += " 	   E2_NUM          ,
cQuery += " 	   E2_PARCELA      ,
cQuery += " 	   E2_EMISSAO      ,
cQuery += " 	   E2_VENCTO       ,
cQuery += " 	   E2_VENCREA      ,
cQuery += " 	   E2_BAIXA        ,
cQuery += " 	   E2_VALOR 
cQuery += "   FROM " + RetSqlName("SE2") + " SE2 
cQuery += "  WHERE E2_FORNECE = '"+SF1->F1_FORNECE+"' 
cQuery += "    AND E2_LOJA    = '"+SF1->F1_LOJA+"' 
cQuery += "    AND D_E_L_E_T_ = '' 
cQuery += "    AND E2_TIPO    = 'PRO'

TcQuery cQuery Alias TMP_FIM New
dbSelectArea("TMP_FIM")	

IF  !EOF() .And. INCLUI
	//Alert("Série:"+ SF1->F1_SERIE)
	If !(AllTrim(SF1->F1_SERIE) == '2')
		u_SWAPAGAPROV()
	EndIf
	
	dbSelectArea("TMP_FIM")
	dbCloseArea()
Else
	dbSelectArea("TMP_FIM")
	dbCloseArea()
EndIf


RestArea(aGMT103FIM)

Return(.T.)


User Function SWAPAGAPROV()
/*****************************************************************************************************************
* Informações Financeiras 
*    
*
***/
Private _oInforFin				// Dialog Principal
                       
PRIVATE OOK	   := LoadBitmap(GetResources(), "LBOK")
PRIVATE ONO	   := LoadBitmap(GetResources(), "LBNO")

// Privates das ListBoxes
Private aListBoxFin := {}
Private oListBoxFin

DEFINE MSDIALOG _oInforFin TITLE "Apagar Provisões Financeiras:" FROM u_MGETTELA(178),u_MGETTELA(181) TO u_MGETTELA(403),u_MGETTELA(967) PIXEL

	// Cria Componentes Padroes do Sistema
	@ u_MGETTELA(093),u_MGETTELA(308) Button "Cancelar" Size u_MGETTELA(037),u_MGETTELA(012) ACTION(Close(_oInforFin)) PIXEL OF _oInforFin
	@ u_MGETTELA(093),u_MGETTELA(351) Button "Apagar" Size u_MGETTELA(037),u_MGETTELA(012)   ACTION(fDelPRO(),Close(_oInforFin)) PIXEL OF _oInforFin

		@ u_MGETTELA(003),u_MGETTELA(005) ListBox oListBoxFin Fields ;
		HEADER "","RECNO","PREFIXO","NUMERO","TIPO","PARCELA","VALOR","EMISSAO NF","VENCIMENTO","VENCIMENTO REAL" ;
		Size u_MGETTELA(383),u_MGETTELA(088) Of _oInforFin Pixel;
		ColSizes 08,20,40,40,40,40,40,40,40,40
		
		oListBoxFin:bLDblClick := {|| fClickMark(oListBoxFin:nAT) } 
		
	// Chamadas das ListBox do Sistema
	fListFin1()

ACTIVATE MSDIALOG _oInforFin CENTERED 

Return(.T.)

Static Function fClickMark(nLinha)
/*********************************************************************************************************************
*  
* 
*
***/
For _NI := 1 To Len(aListBoxFin)
	If _NI == nLinha
		aListBoxFin[_NI][1] := iif(aListBoxFin[_NI][1]==ONO,OOK,ONO)
	Else
		aListBoxFin[_NI][1] := ONO
	EndIf
Next

oListBoxFin:REFRESH()

Return()


Static Function fDelPRO()
/*****************************************************************************************************************
* 
* 
*
***/
Local lGravou  := .F.
Local cCodTitu := ""

For nX:=1 to Len(aListBoxFin)
	If aListBoxFin[nX][1] == OOK
		
		dbSelectArea("SE2")
		dbGoto(aListBoxFin[nX][2]) 
		SE2->(reclock("SE2", .F.))
			//Alert("Apagou:" + SE2->E2_NUM)
			DbDelete()  
		SE2->(msUnLock())
		
		AVISO("Deletando...", "Dados excluídos com sucesso! Código:" +  SE2->E2_NUM , { "Fechar" }, 1)
		
	EndIf
Next nX

Return()

Static Function fListFin1()
/*****************************************************************************************************************
* //
* //
* 
*****/

	dbSelectArea("TMP_FIM")
	Do While !EOF()
			
		Aadd(aListBoxFin,{	ONO,;
							TMP_FIM->RECNO           ,;
							TMP_FIM->E2_PREFIXO      ,;
							TMP_FIM->E2_NUM          ,;
							TMP_FIM->E2_TIPO         ,;
							TMP_FIM->E2_PARCELA      ,;
							TMP_FIM->E2_VALOR        ,;
							StoD(TMP_FIM->E2_EMISSAO),;
							StoD(TMP_FIM->E2_VENCTO) ,;
							StoD(TMP_FIM->E2_VENCREA);
							})
							
		dbSelectArea("TMP_FIM")
		dbSkip()
	EndDo
	
	if Empty(aListBoxFin)
	
		Aadd(aListBoxFin,{		ONO,;
								"",;
								"",;
								"",;
								"",;
								"",;
								"",;
								StoD(""),;
								StoD(""),;
								sToD("");
								})
	
	EndIf 

	oListBoxFin:SetArray(aListBoxFin)
	
	oListBoxFin:bLine := {|| {;
					aListBoxFin[oListBoxFin:nAT,01],;
					aListBoxFin[oListBoxFin:nAT,02],;
					aListBoxFin[oListBoxFin:nAT,03],;
					aListBoxFin[oListBoxFin:nAT,04],;
					aListBoxFin[oListBoxFin:nAT,05],;
					aListBoxFin[oListBoxFin:nAT,06],;
					aListBoxFin[oListBoxFin:nAT,07],;
					aListBoxFin[oListBoxFin:nAT,08],;
					aListBoxFin[oListBoxFin:nAT,09],;
					aListBoxFin[oListBoxFin:nAT,10]}}
	
Return()
