#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
#INCLUDE "topconn.ch"          

/*
Programa ...: F070BTOK() F070BxLt()
Uso ........: Validacao Baixa do contas a receber
Data .......: 19-06-2019
Feito por ..: Bruno Lage Ferreira
Copyright @1998-2001,2019
*/

User Function F070BxLt()
***********************************************************************************
*
*
***
PRIVATE oListBoxFES

lRet := fTransBx(nValEstrang,dBaixa,.F.)

Return(lRet)

User Function F070BTOK()
***********************************************************************************
*
*
***
Local lRet := .T.
PRIVATE oListBoxFES

If AllTrim(cMotBx) <> "DACAO"
	lRet := fTransBx(nValEstrang,dBaixa,.F.)
EndIf 

Return(lRet)

User Function fEsLTCom()
***********************************************************************************
*
*
***
Local aArea      := GetArea()  
Local cQuery     := ""

PRIVATE OOK	   := LoadBitmap(GetResources(), "LBOK")
PRIVATE ONO	   := LoadBitmap(GetResources(), "LBNO")

// Privates das ListBoxes
PRIVATE aListBoxFES := {}
//PRIVATE oListBoxFES


cQuery := " SELECT R_E_C_N_O_ AS RECNO , ZS5_PREFIX,ZS5_NUM ,ZS5_TIPO ,ZS5_PAR  , ZS5_VLR   ,ZS5_DESPE    ,ZS5_DBAIXA, ZS5_TIME 
cQuery += "   FROM ZS5010 
cQuery += "  WHERE D_E_L_E_T_ = '' 
cQuery += "    AND ZS5_NUM    = '"+SE1->E1_NUM+"'  
cQuery += "    AND ZS5_PREFIX = '"+SE1->E1_PREFIXO+"'
cQuery += "    AND ZS5_FILIAL = '"+SE1->E1_FILIAL+"'
cQuery += "    AND ZS5_PAR    = '"+SE1->E1_PARCELA+"'
cQuery += "    AND ZS5_TIPO   = '"+SE1->E1_TIPO+"'
cQuery += "    AND ZS5_CLIENT = '"+SE1->E1_CLIENTE+"'
cQuery += "    AND ZS5_LOJA   = '"+SE1->E1_LOJA+"'
cQuery += "    AND ZS5_COMPES = 'S' 
cQuery += " ORDER BY ZS5_NUM

TcQuery cQuery Alias TMP_FIM_EST New
dbSelectArea("TMP_FIM_EST")

If !EOF()
	STELAESTCOM()
Else
	Alert("Não foi encontrado transfêrencias para este título.")
EndIf

dbSelectArea("TMP_FIM_EST")
dbCloseArea()

RestArea(aArea)
Return()

Static Function STELAESTCOM() 
***********************************************************************************
*
*
***
PRIVATE _oInforFin				// Dialog Principal
                       

DEFINE MSDIALOG _oInforFin TITLE "Estorno de Transferências Compensadas:" FROM u_MGETTELA(178),u_MGETTELA(181) TO u_MGETTELA(403),u_MGETTELA(967) PIXEL

	// Cria Componentes Padroes do Sistema
	@ u_MGETTELA(093),u_MGETTELA(308) Button "Cancelar" Size u_MGETTELA(037),u_MGETTELA(012) ACTION(Close(_oInforFin))           PIXEL OF _oInforFin
	@ u_MGETTELA(093),u_MGETTELA(351) Button "Estornar" Size u_MGETTELA(037),u_MGETTELA(012) ACTION(fDelEST()) PIXEL OF _oInforFin

		@ u_MGETTELA(003),u_MGETTELA(005) ListBox oListBoxFES Fields ;
		HEADER "","RECNO","PREFIXO","NUMERO","TIPO","PARCELA","VLR BAIXA","VLR DESPESA","DT BAIXA","DT EXECUÇÃO" ;
		Size u_MGETTELA(383),u_MGETTELA(088) Of _oInforFin Pixel;
		ColSizes 08,20,40,40,40,40,40,40,40,40
		
		
	// Chamadas das ListBox do Sistema
	fListFinEst()
	
	oListBoxFES:bLDblClick := {|| fClickMark(oListBoxFES:nAT) }

ACTIVATE MSDIALOG _oInforFin CENTERED 

Return()

Static Function fDelEST()
/*****************************************************************************************************************
* 
* 
*
***/
Local nx := 0

For nX:=1 to Len(aListBoxFES)
	If aListBoxFES[nX][1] == OOK
		
		IF !EMPTY(aListBoxFES[nX][09])
			dbSelectArea("ZS5")
			dbGoTo(aListBoxFES[nX][2])
			
			IF RecLock("ZS5",.F.)
				ZS5->ZS5_VLRBX  := ZS5->ZS5_VLRBX - aListBoxFES[nX][7]
				ZS5->ZS5_DBAIXA := cTod("")
				ZS5->ZS5_TIME   := ""	
				ZS5_VLULBX      := ZS5_VLULBX  - aListBoxFES[nX][7]
				ZS5_COMPES      := ""
				MsUnLock()
			EndIf
			
			IF RecLock("SE1",.F.)
				SE1->E1_XVLRTRA := SE1->E1_XVLRTRA + aListBoxFES[nX][7]
				MsUnLock()
			EndIf
							
			AVISO("Estornando...", "Dados excluídos com sucesso! Código:" +  aListBoxFES[nX][4] , { "Fechar" }, 1)
			
			aListBoxFES[nX][09] := cTod("")
			aListBoxFES[nX][10] := ""
			
			oListBoxFES:REFRESH()
		EndIf
		
	EndIf
Next nX

Return()

Static Function fClickMark(nLinha)
/*********************************************************************************************************************
*  
* 
*
***/
Local _NI := 0 
For _NI := 1 To Len(aListBoxFES)
	If _NI == nLinha
		aListBoxFES[_NI][1] := iif(aListBoxFES[_NI][1]==ONO,OOK,ONO)
	Else
		aListBoxFES[_NI][1] := ONO
	EndIf
Next

oListBoxFES:REFRESH()

Return()

Static Function fListFinEst()
/*****************************************************************************************************************
* //
* //
* 
*****/

	dbSelectArea("TMP_FIM_EST")
	Do While !EOF()
			
		Aadd(aListBoxFES,{	ONO,;
							TMP_FIM_EST->RECNO           ,;
							TMP_FIM_EST->ZS5_PREFIX      ,;
							TMP_FIM_EST->ZS5_NUM         ,;
							TMP_FIM_EST->ZS5_TIPO        ,;
							TMP_FIM_EST->ZS5_PAR         ,;
							TMP_FIM_EST->ZS5_VLR         ,;
							TMP_FIM_EST->ZS5_DESPE       ,;
							StoD(TMP_FIM_EST->ZS5_DBAIXA),;
							TMP_FIM_EST->ZS5_TIME        ;
							})
							
		dbSelectArea("TMP_FIM_EST")
		dbSkip()
	EndDo
	
	if Empty(aListBoxFES)
	
		Aadd(aListBoxFES,{		ONO,;
								"",;
								"",;
								"",;
								"",;
								"",;
								0 ,;
								0 ,;
								StoD(""),;
								"";
								})
	
	EndIf 

	oListBoxFES:SetArray(aListBoxFES)
	
	oListBoxFES:bLine := {|| {;
					aListBoxFES[oListBoxFES:nAT,01],;
					aListBoxFES[oListBoxFES:nAT,02],;
					aListBoxFES[oListBoxFES:nAT,03],;
					aListBoxFES[oListBoxFES:nAT,04],;
					aListBoxFES[oListBoxFES:nAT,05],;
					aListBoxFES[oListBoxFES:nAT,06],;
					aListBoxFES[oListBoxFES:nAT,07],;
					aListBoxFES[oListBoxFES:nAT,08],;
					aListBoxFES[oListBoxFES:nAT,09],;
					aListBoxFES[oListBoxFES:nAT,10]}}
	
Return()




User Function fBxLTCom()
***********************************************************************************
*
*
***
Local cQuery := ""

Local aPerg	:= {}
Local cPerg := "BXPORCOMPE"
			   

If MsgYesNo("Esta é uma rotina para facilitar as baixas das transferências por compesação. Deseja continuar? [S]-Sim ou [N]-Não ?" )  
	/*
	cQuery      := " SELECT	DISTINCT SE1.R_E_C_N_O_ SE1_RECNNO,
	cQuery      += " 		E5_DATA,
	cQuery      += " 		E5_NUMERO ,
	cQuery      += " 		E5_VLMOED2
	cQuery      += "   FROM SE5010 SE5 INNER JOIN ZS5010 ZS5
	cQuery      += "        ON (E5_NUMERO = ZS5_NUM AND E5_PREFIXO = ZS5_PREFIX AND E5_TIPO = ZS5_TIPO AND ZS5_CLIENT = E5_CLIFOR AND ZS5_LOJA = E5_LOJA AND ZS5_PAR = E5_PARCELA)
	cQuery      += " 	              INNER JOIN SE1010 SE1
	cQuery      += "        ON (E1_NUM = ZS5_NUM AND E1_PREFIXO = ZS5_PREFIX AND E1_TIPO = ZS5_TIPO AND ZS5_CLIENT = E1_CLIENTE AND ZS5_LOJA = E1_LOJA AND ZS5_PAR = E1_PARCELA)
	cQuery      += "  WHERE SE5.D_E_L_E_T_ = '' 
	cQuery      += "    AND ZS5.D_E_L_E_T_ = ''
	cQuery      += "    AND SE1.D_E_L_E_T_ = ''
	cQuery      += "    AND E5_DTCANBX = '' 
	cQuery      += "    AND E5_SITUACA = '' 
	cQuery      += "    AND E5_IDENTEE <> ''
	cQuery      += "    AND ZS5_DBAIXA = ''
	cQuery      += "    AND E1_BAIXA <> ''
	*/
	
	
	Aadd(aPerg,{cPerg,"Data da compensação           ?","D",08,00,"G","","","","","","","",""})	
	Aadd(aPerg,{cPerg,"Moeda usada (1 ou 2)          ?","C",01,00,"G","","","","","","","",""})
	
	U_Testasx1(cPerg,aPerg,.t.)	
		
	If Pergunte("BXPORCOMPE")	
		
		IF MV_PAR02 == '1'
			cQuery      := " SELECT SUM(E5_VALOR)	VLR
	    Else
	    	cQuery      := " SELECT SUM(E5_VLMOED2)	VLR
	    EndIf
	    
	    cQuery      += " FROM SE5010 
	    cQuery      += " WHERE D_E_L_E_T_ = '' 
		cQuery      += " AND E5_NUMERO  = '"+ SE1->E1_NUM +"'
		cQuery      += " AND E5_PREFIXO = '"+ SE1->E1_PREFIXO +"'
		cQuery      += " AND E5_TIPO    = '"+ SE1->E1_TIPO +"'
		cQuery      += " AND E5_CLIFOR  = '"+ SE1->E1_CLIENTE +"'
		cQuery      += " AND E5_LOJA    = '"+ SE1->E1_LOJA +"'
		cQuery      += " AND E5_PARCELA = '"+ SE1->E1_PARCELA +"'
	    cQuery      += " AND E5_DTCANBX = '' 
	    cQuery      += " AND E5_SITUACA = '' 
	    cQuery      += " AND E5_IDENTEE <> ''
	    cQuery      += " AND E5_TIPODOC <> 'CM'
	    cQuery      += " AND E5_DATA    = '"+DToS(MV_PAR01)+"'
		
		TcQuery cQuery Alias TMP_BXAUT New
		dbSelectArea("TMP_BXAUT")
		If !EOF()
			MsgAlert(SE1->E1_XINVOIC, "NÚMERO DA INVOICE")
			fTransBx( TMP_BXAUT->VLR , MV_PAR01 , .T. )	
		EndIf
			
		dbSelectArea("TMP_BXAUT")
		dbCloseArea()
		
		Alert("Processamento finalizado!")
	
	EndIf
	
EndIf

Return 


Static Function fTransBx(nValorBaixa,dInfBaixa,lTPCall)
***********************************************************************************
*
*
***
Local lNExec     := .F.
Local lRet       := .F.
Local dtUpdate   := ""
Local cQuery     := ""
Local _NI        := 0

If SubString(CNUMEMP,1,2) == "01" .And. SE1->E1_MOEDA <> 1

	PRIVATE cEdit1	 := "NÚMERO:" + SE1->E1_NUM + " INVOICE:" + SE1->E1_XINVOIC + " - CLIENTE:" + SE1->E1_CLIENTE + "/" + SE1->E1_LOJA + " - " + AllTrim(SE1->E1_NOMCLI) + " SALDO: ["+ ALLTRIM(STR(SE1->E1_SALDO)) +"]"
	PRIVATE cEdit2	 := nValorBaixa //nValEstrang
	PRIVATE cEdit3	 := 0
	
	PRIVATE oEdit1
	PRIVATE oEdit2
	PRIVATE oEdit3
	
	PRIVATE aListBoxFin := {}
	PRIVATE oListBoxFin 
	
	// Variaveis Private da Funcao
	PRIVATE _oDlg				// Dialog Principal
	
	PRIVATE OOK	   := LoadBitmap(GetResources(), "LBOK")
	PRIVATE ONO	   := LoadBitmap(GetResources(), "LBNO")
	
	Private oVerde  	:= LoadBitmap( GetResources(), "BR_VERDE")
	Private oAzul  		:= LoadBitmap( GetResources(), "BR_AZUL")
	Private oVermelho	:= LoadBitmap( GetResources(), "BR_VERMELHO")



	dbSelectArea("ZS5")
	dbSetorder(1)
	IF dbSeek(xFilial("ZS5") + SE1->E1_PREFIXO + SE1->E1_NUM + SE1->E1_PARCELA + SE1->E1_CLIENTE + SE1->E1_LOJA + SE1->E1_TIPO) 
	
		DEFINE MSDIALOG _oDlg TITLE "Controle Internacional de Transferências:" FROM u_MGETTELA(333),u_MGETTELA(275) TO u_MGETTELA(734),u_MGETTELA(795) PIXEL
			
			// Cria Componentes Padroes do Sistema
			@ u_MGETTELA(006),u_MGETTELA(005) Say "Informações:" Size u_MGETTELA(042),u_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlg
			@ u_MGETTELA(006),u_MGETTELA(052) MsGet oEdit1 Var cEdit1 when(.f.) Size u_MGETTELA(200),u_MGETTELA(009) COLOR CLR_BLACK PIXEL OF _oDlg
			@ u_MGETTELA(021),u_MGETTELA(006) Say "Valor a baixar:" Size u_MGETTELA(046),u_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlg
			@ u_MGETTELA(021),u_MGETTELA(052) MsGet oEdit2 Var cEdit2 when(.f.) Size u_MGETTELA(057),u_MGETTELA(009) picture("@E 999,999.99")  COLOR CLR_BLACK PIXEL OF _oDlg
			@ u_MGETTELA(021),u_MGETTELA(114) Say "Valor Selecionado:" Size u_MGETTELA(055),u_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlg
			@ u_MGETTELA(021),u_MGETTELA(165) MsGet oEdit3 Var cEdit3 when(.f.) Size u_MGETTELA(087),u_MGETTELA(009) picture("@E 999,999.99")  COLOR CLR_BLACK PIXEL OF _oDlg
			
			@ u_MGETTELA(180),u_MGETTELA(200) Button "Ok"  Size u_MGETTELA(037),u_MGETTELA(012) ACTION( IIF(cEdit2 <> cEdit3 ,Alert("Ajuste os valores entre as transferências!"), lNExec := .T. ),Close(_oDlg) ) PIXEL OF _oDlg
			
			@ u_MGETTELA(035),u_MGETTELA(006) ListBox oListBoxFin Fields ;
				HEADER " ","Id","Transf.Data","Transf.Valor","Despesas Bco","VLR A RECEBER";
				Size u_MGETTELA(247),u_MGETTELA(140) Of _oDlg Pixel;
				ColSizes 05,05,50,50,50,50
		
			oListBoxFin:bLDblClick := {|| FEditInf(aListBoxFin[oListBoxFin:nAT,02],nValorBaixa) } 
		
			// Chamadas das ListBox do Sistema
			fListFin1()
			//FTotais()
		
		ACTIVATE MSDIALOG _oDlg CENTERED 
		
		
		IF lNExec == .T.
			dtUpdate := dTos(date()) + Space(1) + Time()
			For _NI := 1 To Len(aListBoxFin)
				dbSelectArea("ZS5")
				dbGoTo(aListBoxFin[_NI][2])
				IF aListBoxFin[_NI][6] <> 0
					IF RecLock("ZS5",.F.)
						ZS5->ZS5_VLRBX  := ZS5->ZS5_VLRBX + aListBoxFin[_NI][6]
						ZS5->ZS5_DBAIXA := dInfBaixa
						ZS5->ZS5_TIME   := dtUpdate
						ZS5_VLULBX      := aListBoxFin[_NI][6]
						ZS5_COMPES      := IIF(lTPCall==.T.,'S','')
						MsUnLock()
					EndIf
					
					/*
					Atualizando o saldo da se1
					*/
					/*
					cQuery := " SELECT SUM(ZS5_VLR - ZS5_VLRBX) SALDO FROM ZS5010
					cQuery += "  WHERE D_E_L_E_T_ = ''
					cQuery += "    AND ZS5_NUM    = '"+ SE1->E1_NUM      +"'
					cQuery += "    AND ZS5_FILIAL = '"+ SE1->E1_FILIAL   +"'
					cQuery += "    AND ZS5_PREFIX = '"+ SE1->E1_PREFIXO  +"'
					cQuery += "    AND ZS5_PAR    = '"+ SE1->E1_PARCELA  +"'
					cQuery += "    AND ZS5_TIPO   = '"+ SE1->E1_TIPO     +"'
					cQuery += "    AND ZS5_CLIENT = '"+ SE1->E1_CLIENTE  +"'
					cQuery += "    AND ZS5_LOJA   = '"+ SE1->E1_LOJA     +"'
					*/
					IF RecLock("SE1",.F.)
						SE1->E1_XVLRTRA := SE1->E1_XVLRTRA - aListBoxFin[_NI][6]
						MsUnLock()
					EndIf
										
				EndIf
			Next
			//Alert("Baixa realizada com sucesso!")		
			
			lRet := .T.
		EndIf
	
	Else
		Alert("Não pode ser realizado a báixa deste título porque não foi encontrato transferencias!")
		lRet := .f.
	EndIf

Else
	lRet := .T.
EndIf

Return(lRet)



User Function FA070CA2()
/*****************************************************************************************************************
* // Movimento bancario internacional (CANCELAMENTO/ESTORNO)
* //
* 
*****/
Local cQuery := ""

cQuery      := " SELECT	ZS6_RECZS5,
cQuery      += " 		ZS6_VLRBAI,
cQuery      += " 		R_E_C_N_O_ RECNO
cQuery      += "   FROM ZS6010  
cQuery      += " WHERE D_E_L_E_T_ = '' 
cQuery      += "    AND ZS6_RECSE5 = "+AllTrim(str(SE5->(RECNO()))) 

TcQuery cQuery Alias TMP_EST New
dbSelectArea("TMP_EST")

	dbSelectArea("TMP_EST")
	Do While !EOF()
		
		dbSelectArea("ZS6")
		Goto(TMP_EST->RECNO)
		IF RecLock("ZS6",.F.)
				dbDelete()
			MsUnLock()
		EndIf	
		
		dbSelectArea("ZS5")
		dbGoTo(TMP_EST->ZS6_RECZS5)
		IF RecLock("ZS5",.F.)
				ZS5->ZS5_VLRBX  := ZS5->ZS5_VLRBX - TMP_EST->ZS6_VLRBAI
				ZS5_VLULBX      := TMP_EST->ZS6_VLRBAI
				ZS5_DBAIXA      := IIF(ZS5->ZS5_VLRBX == 0, StoD(""),ZS5_DBAIXA)
				MsUnLock()
		EndIf
		
		/*
		Atualizando o saldo da se1
		*/
		dbselectArea("SE1")
		dbSetOrder(2)
		If dbSeek(xFilial("SE1") +  SE5->E5_CLIENTE + SE5->E5_LOJA + SE5->E5_PREFIXO + SE5->E5_NUMERO + SE5->E5_PARCELA + SE5->E5_TIPO )
			IF RecLock("SE1",.F.)
				SE1->E1_XVLRTRA := SE1->E1_XVLRTRA + TMP_EST->ZS6_VLRBAI
				MsUnLock()
			EndIf
		Else
			Alert("Erro Grave de sado na SE1 ")
		EndIf
			
		dbSelectArea("TMP_EST")
		dbSkip()
	EndDo
	
dbSelectArea("TMP_EST")
dbCloseArea()

Return Nil


User Function fAtuSZS6()
/*****************************************************************************************************************
* // Movimento bancario internacional 
* //
* 
*****/
Local cQuery := ""

cQuery      := " SELECT ZS5_FILIAL,
cQuery      += " 		ZS5_PREFIX,
cQuery      += " 		ZS5_NUM,
cQuery      += " 		ZS5_PAR,
cQuery      += " 		ZS5_TIPO,
cQuery      += " 		ZS5_CLIENT,
cQuery      += " 		ZS5_LOJA,
cQuery      += " 		ZS5_DTRANS,
cQuery      += " 		ZS5_VLR,
cQuery      += " 		ZS5_DESPE,
cQuery      += " 		ZS5_USERGI,
cQuery      += " 		ZS5_USERGA,
cQuery      += " 		ZS5_DBAIXA,
cQuery      += " 		ZS5_VLULBX,
cQuery      += " 		R_E_C_N_O_ RECNO
cQuery      += "   FROM ZS5010 
cQuery      += "  WHERE D_E_L_E_T_ = '' 
cQuery      += "    AND ZS5_NUM    = '"+ZS5->ZS5_NUM+"'
cQuery      += "    AND ZS5_PREFIX = '"+ZS5->ZS5_PREFIX+"'
cQuery      += "    AND ZS5_PAR    = '"+ZS5->ZS5_PAR+"'
cQuery      += "    AND ZS5_TIPO   = '"+ZS5->ZS5_TIPO+"'
cQuery      += "    AND ZS5_CLIENT = '"+ZS5->ZS5_CLIENT+"'
cQuery      += "    AND ZS5_LOJA   = '"+ZS5->ZS5_LOJA+"' 
cQuery      += "    AND ZS5_DBAIXA = '"+DTOS(SE5->E5_DATA)+"'
cQuery      += "    AND ZS5_TIME = ( SELECT MAX(ZS5_TIME) FROM ZS5010 WHERE D_E_L_E_T_ = ''  )

TcQuery cQuery Alias TMP_ZS5 New
dbSelectArea("TMP_ZS5")

	dbSelectArea("TMP_ZS5")
	Do While !EOF()
		
		IF RecLock("ZS6",.T.)
			ZS6->ZS6_FILIAL := xFilial("ZS6") 
			ZS6->ZS6_RECSE5 := SE5->(RECNO()) 
			ZS6->ZS6_SEGSE5 := SE5->E5_SEQ
			ZS6->ZS6_RECZS5 := TMP_ZS5->RECNO
			ZS6->ZS6_VLRBAI := TMP_ZS5->ZS5_VLULBX
			MsUnLock()
		EndIf		
		
		dbSelectArea("TMP_ZS5")
		dbSkip()
	EndDo
	
dbSelectArea("TMP_ZS5")
dbCloseArea()

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
cQuery += " 	   ZS5_VLRBX       ,
cQuery += " 	   ZS5_DESPE 
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
	
			
		Aadd(aListBoxFin,{	IIF(TMP_FIM->ZS5_VLRBX==0, oVerde, IIF( TMP_FIM->ZS5_VLRBX <> TMP_FIM->ZS5_VLR , oAzul , oVermelho) ) ,;
							TMP_FIM->RECNO           ,;
							StoD(TMP_FIM->ZS5_DTRANS),;
							TMP_FIM->ZS5_VLR - TMP_FIM->ZS5_VLRBX         ,;
							TMP_FIM->ZS5_DESPE       ,;
							0         				;
							})
							
		dbSelectArea("TMP_FIM")
		dbSkip()
	EndDo
	
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

Static Function FEditInf(nLinhaRec,nValorBaixa) 
****************************************************************************************************************
*    
*
****
Local nEdit11	 := dDataBase
Local oEdit11

Local nEdit21	 := 0
Local oEdit21

Local nEdit31	 := 0
Local oEdit31

Local nEdit41	 := 0
Local oEdit41

Local lNExec     := .F.
Local lNDele     := .F.

Local nValAtu    := 0
Local _NI        := 0

// Variaveis Private da Funcao
Private _oDlgVlr				// Dialog Principal

For _NI := 1 To Len(aListBoxFin)
	nValAtu := nValAtu + aListBoxFin[_NI][6]
Next

For _NI := 1 To Len(aListBoxFin)
	If aListBoxFin[_NI][2] == nLinhaRec
	
		nEdit11 := aListBoxFin[_NI][3]
		
		If nValAtu =0 
			nEdit21 := aListBoxFin[_NI][4]
		Else
			nEdit21 := nValorBaixa - nValAtu  //nValEstrang - nValAtu
		EndIf
		
		// Variaveis que definem a Acao do Formulario                    
		DEFINE MSDIALOG _oDlgVlr TITLE "Baixar..."    FROM u_MGETTELA(223),u_MGETTELA(173) TO u_MGETTELA(359),u_MGETTELA(520) PIXEL
		
			// Cria as Groups do Sistema
			@ u_MGETTELA(003),u_MGETTELA(005) TO u_MGETTELA(044),u_MGETTELA(168) LABEL "" PIXEL OF _oDlgVlr
		
			// Cria Componentes Padroes do Sistema
			@ u_MGETTELA(010),u_MGETTELA(008) Say "Data:" Size u_MGETTELA(066),u_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlgVlr
			@ u_MGETTELA(010),u_MGETTELA(050) MsGet oEdit11 Var nEdit11            Size u_MGETTELA(35)  ,u_MGETTELA(009)  When(.F.) COLOR CLR_BLACK PIXEL OF _oDlgVlr
			
			@ u_MGETTELA(010),u_MGETTELA(085) Say "Valor:" Size u_MGETTELA(066),u_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlgVlr
			@ u_MGETTELA(010),u_MGETTELA(130) MsGet oEdit21 Var nEdit21            Size u_MGETTELA(35) ,u_MGETTELA(009)   valid(fValid21A(nEdit21,nLinhaRec,nValorBaixa))  picture("@E 999,999.99")  COLOR CLR_BLACK PIXEL OF _oDlgVlr
			
			//@ u_MGETTELA(028),u_MGETTELA(008) Say "Despesa:" Size u_MGETTELA(066),u_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlgVlr
			//@ u_MGETTELA(028),u_MGETTELA(050) MsGet oEdit31 Var nEdit31            Size u_MGETTELA(35) ,u_MGETTELA(009) picture("@E 999,999.99") COLOR CLR_BLACK PIXEL OF _oDlgVlr
			
			//@ u_MGETTELA(028),u_MGETTELA(085) Say "Desconto: {Vlr}" Size u_MGETTELA(066),u_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlgVlr
			//@ u_MGETTELA(028),u_MGETTELA(130) MsGet oEdit4 Var nEdit4            Size u_MGETTELA(35) ,u_MGETTELA(009) picture("@E 9999.99") COLOR CLR_BLACK PIXEL OF _oDlgVlr
			
			@ u_MGETTELA(047),u_MGETTELA(131) Button "Ok" 		Size u_MGETTELA(037),u_MGETTELA(012)  ACTION( lNExec := .T. , Close(_oDlgVlr))  PIXEL OF _oDlgVlr
			//@ u_MGETTELA(047),u_MGETTELA(085) Button "Deletar" 	Size u_MGETTELA(037),u_MGETTELA(012)  ACTION( lNDele := .T. , Close(_oDlgVlr))  PIXEL OF _oDlgVlr
			
			//@ u_MGETTELA(050),u_MGETTELA(007) Say "O valor irá subistituir todas as chapas do cavalete! "  Size u_MGETTELA(113),u_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlgVlr
		
		ACTIVATE MSDIALOG _oDlgVlr CENTERED
	
	
	EndIf
Next

IF lNExec = .T.

	cEdit3 := 0

	For _NI := 1 To Len(aListBoxFin)
		If aListBoxFin[_NI][2] == nLinhaRec
				aListBoxFin[_NI][6] := nEdit21
				oListBoxFin:REFRESH()
		EndIf
		cEdit3 := cEdit3 + aListBoxFin[_NI][6] //+ aListBoxFin[_NI][5]
		
	Next
	
	oEdit3:REFRESH()
	oListBoxFin:REFRESH()
	
EndIf

Return()


Static Function fValid21A(nEdit21,nLinhaRec,nValorBaixa)
****************************************************************************************************************
*    
*
****
Local nTotal := 0
Local lRet   := .t.
Local _NI    := 0

For _NI := 1 To Len(aListBoxFin)
	If aListBoxFin[_NI][2] == nLinhaRec
			If nEdit21 > aListBoxFin[_NI][4]
				Alert('Valor não pode superar a transferência.')
				lRet := .F.
				Return(lRet) 
			EndIf
	EndIf
	
	nTotal := nTotal + aListBoxFin[_NI][6]
	If (nTotal + nEdit21) > nValorBaixa
		Alert('Valor não pode superar o total da baixa:' + AllTrim(Str(nValorBaixa)) )
		lRet := .F.
		Return(lRet)
	EndIf
Next

Return(lRet) 
