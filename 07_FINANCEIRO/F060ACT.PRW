#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
#INCLUDE "TOPCONN.CH"

/*                                          
Programa ...: F060ACT.Prw
Uso ........: Apos gravação dos dados da transferencia
Data .......: 07/04/20
Feito por ..: Bruno Lage Ferreira.
*/


User Function SACI008()
/****************************************************************************************************
* //
*
****/      
Local lRet      := .T.

If SubString(CNUMEMP,1,2) == "01" 

	/*
	IF  RecLock("SE1",.F.)
			SE1->E1_XUSUTRA := SUBSTR(CUSUARIO,7,15)
			SE1->E1_XDTTRAN := dDataBase
			SE1->E1_XVLRTRA := 0
		MsUnLock()
	EndIf
	*/
	U_fAtuSZS6()

EndIf

Return(lRet)

User Function EncFina070()
/****************************************************************************************************
*
*
****/      
Private aRecTrafBaixa := {}

FINA070()

Return()


User Function FA070CHK()
/****************************************************************************************************
*
*
****/ 
Local lRet := .T. 
If SubString(CNUMEMP,1,2) == "01"
	dbSelectArea("ZS5")
	dbSetorder(1)
	If SE1->E1_MOEDA <> 1
		If !dbSeek(xFilial("ZS5") + SE1->E1_PREFIXO + SE1->E1_NUM + SE1->E1_PARCELA + SE1->E1_CLIENTE + SE1->E1_LOJA + SE1->E1_TIPO)
			Alert("Não existe transferência para este título!")
			lRet := .F.
			Return(lRet)
		EndIf
	EndIf
EndIf
Return(lRet)



User Function F070VREC()
/****************************************************************************************************
* valtype(aRecTrafBaixa)
*
****/      
Local lRet      := .T.
Local aDadosVlr	:= PARAMIXB

If SubString(CNUMEMP,1,2) == "01" 
	If (SE1->E1_XVLRTRA <> 0) .And. (aDadosVlr[1] <> SE1->E1_XVLRTRA)	
		lRet      := .T.
		//Alert("Valor da [transferência: " + AllTrim(STR(SE1->E1_XVLRTRA)) + " ] diferente do valor [Recebido :" + AllTrim(STR(aDadosVlr[1])) + "].")
	EndIf
EndIf

Return(lRet)


User Function F070DTRE()
/****************************************************************************************************
*
*
****/      
Local lRet := .F.

//Alert("F070DTRE")

Return(lRet)


User Function F060ACT()
/****************************************************************************************************
*
*
****/      
Local aDadosF060ACT	:= PARAMIXB[1]
Local lCloseDlg     := .F.

// Variaveis Locais da Funcao
PRIVATE cEdit1	 := SE1->E1_CLIENTE + "/" + SE1->E1_LOJA + " - " + AllTrim(SE1->E1_NOMCLI) + " SALDO: ["+ ALLTRIM(STR(SE1->E1_SALDO)) +"]"
PRIVATE cEdit2	 := SE1->E1_XVLRTRA
PRIVATE cEdit3	 := SE1->E1_XDESBCA

PRIVATE oEdit1
PRIVATE oEdit2
PRIVATE oEdit3

PRIVATE aListBoxFin := {}
PRIVATE oListBoxFin 

// Variaveis Private da Funcao
PRIVATE _oDlg				// Dialog Principal

PRIVATE OOK	   := LoadBitmap(GetResources(), "LBOK")
PRIVATE ONO	   := LoadBitmap(GetResources(), "LBNO")

// Variaveis Private da Funcao
If SubString(CNUMEMP,1,2) == "01" 

	If (aDadosF060ACT[1] == '1' .Or. aDadosF060ACT[1] == 'J' ) .AND. SE1->E1_MOEDA <> 1  
	
	   	Do While lCloseDlg == .F.
			DEFINE MSDIALOG _oDlg TITLE "Controle Internacional de Transferências:" FROM u_MGETTELA(333),u_MGETTELA(275) TO u_MGETTELA(734),u_MGETTELA(795) PIXEL
			
			// Cria Componentes Padroes do Sistema
			@ u_MGETTELA(006),u_MGETTELA(005) Say "INFORMAÇÕES:" Size u_MGETTELA(042),u_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlg
			@ u_MGETTELA(006),u_MGETTELA(052) MsGet oEdit1 Var cEdit1 when(.f.) Size u_MGETTELA(200),u_MGETTELA(009) COLOR CLR_BLACK PIXEL OF _oDlg
			@ u_MGETTELA(021),u_MGETTELA(006) Say "(=) VALOR TRANSF.:" Size u_MGETTELA(046),u_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlg
			@ u_MGETTELA(021),u_MGETTELA(052) MsGet oEdit2 Var cEdit2 when(.f.) Size u_MGETTELA(057),u_MGETTELA(009) picture("@E 999,999.99")  COLOR CLR_BLACK PIXEL OF _oDlg
			@ u_MGETTELA(021),u_MGETTELA(114) Say "(=) DESPES. BANQUEIRO:" Size u_MGETTELA(055),u_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlg
			@ u_MGETTELA(021),u_MGETTELA(165) MsGet oEdit3 Var cEdit3 when(.f.) Size u_MGETTELA(087),u_MGETTELA(009) picture("@E 999,999.99")  COLOR CLR_BLACK PIXEL OF _oDlg
			
			
			@ u_MGETTELA(180),u_MGETTELA(50)  Button "(+) INCLUIR"  Size u_MGETTELA(037),u_MGETTELA(012) ACTION(FEditInf()) PIXEL OF _oDlg
			@ u_MGETTELA(180),u_MGETTELA(100) Button "(-) DELETAR"  Size u_MGETTELA(037),u_MGETTELA(012) ACTION(fDelete())  PIXEL OF _oDlg
			
			@ u_MGETTELA(180),u_MGETTELA(200) Button "Ok"           Size u_MGETTELA(037),u_MGETTELA(012) ACTION(FTotais(),lCloseDlg := .T. ,close(_oDlg))  PIXEL OF _oDlg
			
			@ u_MGETTELA(035),u_MGETTELA(006) ListBox oListBoxFin Fields ;
				HEADER " ","ID","DATA","VALOR","DESPESA","SALDO";
				Size u_MGETTELA(247),u_MGETTELA(140) Of _oDlg Pixel;
				ColSizes 05,05,50,50,50,50
		
			oListBoxFin:bLDblClick := {|| fClickMark(oListBoxFin:nAT) } 
		
			// Chamadas das ListBox do Sistema
			fListFin1()
			FTotais()
	
			ACTIVATE MSDIALOG _oDlg CENTERED 
		EndDo
	
	Else
		IF RecLock("SE1",.F.)
			SE1->E1_XUSUTRA := SUBSTR(CUSUARIO,7,15)
			SE1->E1_XDTTRAN := dDataBase
			SE1->E1_XVLRTRA := 0
			SE1->E1_XDESBCA := 0
			MsUnLock()
		EndIf
	EndIf
	
EndIf

Return Nil

Static Function fClickMark(nLinha)
/*********************************************************************************************************************
*  
* 
*
***/
For _NI := 1 To Len(aListBoxFin)
	If _NI == nLinha
		aListBoxFin[_NI][1] := iif(aListBoxFin[_NI][1]==ONO,OOK,ONO)
	/*Else
		aListBoxFin[_NI][1] := ONO*/
	EndIf
Next

oListBoxFin:REFRESH()

Return()


Static Function fDelete()
/*********************************************************************************************************************
*  
* 
*
***/
For _NI := 1 To Len(aListBoxFin)
	If aListBoxFin[_NI][1] == OOK
	
		dbSelectArea("ZS5")
		dbGoTo(aListBoxFin[_NI][2])
		If Empty(ZS5_DBAIXA)
			IF RecLock("ZS5",.f.)
				dbDelete()
				MsUnLock()
			EndIf
		Else
			Alert("Este título já sofreu baixas!")
		EndIf

	EndIf
Next

fListFin1()
FTotais()

Return()

Static Function FTotais() 
****************************************************************************************************************
*    
*
****
Local nTotalTranf := 0
Local nTotalDesp  := 0
Local dUltData    

For nX:=1 to  Len(aListBoxFin)
	nTotalTranf := nTotalTranf + aListBoxFin[nX][6]
	nTotalDesp  := nTotalDesp  + aListBoxFin[nX][5]
	dUltData    := Iif(aListBoxFin[nX][3]>dUltData,aListBoxFin[nX][3],dUltData)
Next nX

IF RecLock("SE1",.F.)
	SE1->E1_XUSUTRA := SUBSTR(CUSUARIO,7,15)
	SE1->E1_XDTTRAN := dUltData
	SE1->E1_XVLRTRA := nTotalTranf
	SE1->E1_XDESBCA := nTotalDesp
	MsUnLock()
EndIf

cEdit2 := nTotalTranf
cEdit3 := nTotalDesp

oEdit2:Refresh()
oEdit3:Refresh()

If nTotalTranf > SE1->E1_VALOR 
	Alert("Total transferido maior que total da invoice. Verifique!")
EndIf 

Return()


Static Function FEditInf() 
****************************************************************************************************************
*    
*
****
Local nEdit11	 := dDataBase
Local oEdit11

Local nEdit21	 := SE1->E1_SALDO
Local oEdit21

Local nEdit31	 := 0
Local oEdit31

Local nEdit41	 := 0
Local oEdit41

Local lNExec     := .F.
Local lNDele     := .F.

Local aAreaSE1   := GetArea()

// Variaveis Private da Funcao
Private _oDlgVlr				// Dialog Principal


dbSelectArea("SE1")
dbSetorder(2)
iF dbSeek(SE1->E1_FILIAL+ SE1->E1_CLIENTE+ SE1->E1_LOJA+ SE1->E1_PREFIXO+ SE1->E1_NUM+ SE1->E1_PARCELA+ "AB-")
	Alert("Encontrado título de abatimento! Valor:" + AllTrim(Str(SE1->E1_SALDO)) )
	nEdit21	 := nEdit21 - SE1->E1_SALDO
EndIf

dbSelectArea("SE1")
RestArea(aAreaSE1)

// Variaveis que definem a Acao do Formulario                    
DEFINE MSDIALOG _oDlgVlr TITLE "INCLUIR..."    FROM u_MGETTELA(223),u_MGETTELA(173) TO u_MGETTELA(359),u_MGETTELA(520) PIXEL

	// Cria as Groups do Sistema
	@ u_MGETTELA(003),u_MGETTELA(005) TO u_MGETTELA(044),u_MGETTELA(168) LABEL "" PIXEL OF _oDlgVlr

	// Cria Componentes Padroes do Sistema
	@ u_MGETTELA(010),u_MGETTELA(008) Say "Data:" Size u_MGETTELA(066),u_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlgVlr
	@ u_MGETTELA(010),u_MGETTELA(050) MsGet oEdit11 Var nEdit11            Size u_MGETTELA(35)  ,u_MGETTELA(009)  COLOR CLR_BLACK PIXEL OF _oDlgVlr
	
	@ u_MGETTELA(010),u_MGETTELA(085) Say "Valor:" Size u_MGETTELA(066),u_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlgVlr
	@ u_MGETTELA(010),u_MGETTELA(130) MsGet oEdit21 Var nEdit21            Size u_MGETTELA(35) ,u_MGETTELA(009)  picture("@E 999,999.99") COLOR CLR_BLACK PIXEL OF _oDlgVlr
	
	@ u_MGETTELA(028),u_MGETTELA(008) Say "Despesa:" Size u_MGETTELA(066),u_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlgVlr
	@ u_MGETTELA(028),u_MGETTELA(050) MsGet oEdit31 Var nEdit31            Size u_MGETTELA(35) ,u_MGETTELA(009) picture("@E 999,999.99") COLOR CLR_BLACK PIXEL OF _oDlgVlr
	
	//@ u_MGETTELA(028),u_MGETTELA(085) Say "Desconto: {Vlr}" Size u_MGETTELA(066),u_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlgVlr
	//@ u_MGETTELA(028),u_MGETTELA(130) MsGet oEdit4 Var nEdit4            Size u_MGETTELA(35) ,u_MGETTELA(009) picture("@E 9999.99") COLOR CLR_BLACK PIXEL OF _oDlgVlr
	
	@ u_MGETTELA(047),u_MGETTELA(131) Button "Ok" 		Size u_MGETTELA(037),u_MGETTELA(012)  ACTION( lNExec := .T. , Close(_oDlgVlr))  PIXEL OF _oDlgVlr
	//@ u_MGETTELA(047),u_MGETTELA(085) Button "Deletar" 	Size u_MGETTELA(037),u_MGETTELA(012)  ACTION( lNDele := .T. , Close(_oDlgVlr))  PIXEL OF _oDlgVlr
	
	//@ u_MGETTELA(050),u_MGETTELA(007) Say "O valor irá subistituir todas as chapas do cavalete! "  Size u_MGETTELA(113),u_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlgVlr

ACTIVATE MSDIALOG _oDlgVlr CENTERED


IF lNExec = .T.

		IF RecLock("ZS5",.T.)
			ZS5->ZS5_FILIAL := SE1->E1_FILIAL
			ZS5->ZS5_PREFIX := SE1->E1_PREFIXO
			ZS5->ZS5_NUM    := SE1->E1_NUM
			ZS5->ZS5_PAR    := SE1->E1_PARCELA
			ZS5->ZS5_TIPO   := SE1->E1_TIPO
			ZS5->ZS5_CLIENT := SE1->E1_CLIENTE
			ZS5->ZS5_LOJA   := SE1->E1_LOJA 
			ZS5->ZS5_DTRANS := nEdit11
			ZS5->ZS5_VLR    := nEdit21
			ZS5->ZS5_DESPE  := nEdit31
			MsUnLock()
		EndIf
		
		fListFin1()
		FTotais()
EndIf


Return()


Static Function fListFin1()
/*****************************************************************************************************************
* //
* //
* 
*****/
Local cQuery      := ""

aListBoxFin := {}

cQuery := " SELECT R_E_C_N_O_ RECNO, 
cQuery += " 	   ZS5_FILIAL      ,
cQuery += " 	   ZS5_PREFIX      ,
cQuery += " 	   ZS5_NUM         ,
cQuery += " 	   ZS5_PAR         ,
cQuery += " 	   ZS5_TIPO        ,
cQuery += " 	   ZS5_CLIENT      ,
cQuery += " 	   ZS5_LOJA        ,
cQuery += " 	   ZS5_DTRANS      ,
cQuery += " 	   ZS5_VLR         ,
cQuery += " 	   ZS5_DESPE 	   ,
cQuery += " 	   ZS5_VLRBX 	   
cQuery += "   FROM " + RetSqlName("ZS5") + " SZ5 
cQuery += "  WHERE ZS5_FILIAL    = '"+ SE1->E1_FILIAL  +"' 
cQuery += "    AND ZS5_PREFIX    = '"+ SE1->E1_PREFIXO +"' 
cQuery += "    AND ZS5_NUM       = '"+ SE1->E1_NUM     +"'
cQuery += "    AND ZS5_PAR       = '"+ SE1->E1_PARCELA+"'
cQuery += "    AND ZS5_TIPO      = '"+ SE1->E1_TIPO    +"'
cQuery += "    AND ZS5_CLIENT    = '"+ SE1->E1_CLIENTE +"'
cQuery += "    AND ZS5_LOJA      = '"+ SE1->E1_LOJA    +"'
cQuery += "    AND D_E_L_E_T_ = '' 

TcQuery cQuery Alias TMP_FIM New
dbSelectArea("TMP_FIM")

	dbSelectArea("TMP_FIM")
	Do While !EOF()
			
		Aadd(aListBoxFin,{	ONO														,;
							TMP_FIM->RECNO           								,;
							StoD(TMP_FIM->ZS5_DTRANS)								,;
							TMP_FIM->ZS5_VLR         								,;
							TMP_FIM->ZS5_DESPE       								,;
							TMP_FIM->ZS5_VLR - TMP_FIM->ZS5_VLRBX      				;
							})
							
		dbSelectArea("TMP_FIM")
		dbSkip()
	EndDo
	
	if Empty(aListBoxFin)
		Aadd(aListBoxFin,{		ONO,;
								0,;
								StoD(""),;
								0,;
								0,;
								0;
								})
	EndIf 

	oListBoxFin:SetArray(aListBoxFin)
	
	oListBoxFin:bLine := {|| {;
					aListBoxFin[oListBoxFin:nAT,01],;
					aListBoxFin[oListBoxFin:nAT,02],;
					aListBoxFin[oListBoxFin:nAT,03],;
					aListBoxFin[oListBoxFin:nAT,04],;
					aListBoxFin[oListBoxFin:nAT,05],;
					aListBoxFin[oListBoxFin:nAT,06]}}

oListBoxFin:REFRESH()

dbSelectArea("TMP_FIM")
dbCloseArea()

Return()


Static Function fGravTransf(nVlrTransf,nVlrDesp)
***********************************************************************************
*
*
***
IF RecLock("SE1",.F.)
		SE1->E1_XUSUTRA := SUBSTR(CUSUARIO,7,15)
		SE1->E1_XDTTRAN := dDataBase
		SE1->E1_XVLRTRA := nVlrTransf
		SE1->E1_XDESBCA := nVlrDesp
	MsUnLock()
EndIf

AVISO("Tranferência", "Transferência gravada com sucesso!", { "Fechar" }, 1)
Close(_oDlg)

Return()
