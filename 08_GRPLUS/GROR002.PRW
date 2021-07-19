#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "RPTDEF.CH"

#DEFINE	TAM_CUSTOM 0 	//Tamanho customizavel pelo usuario, informado em nHeight/nWidth. Aplicavel apenas em impressoes do tipo PDF. oficio 2 216 x 330
#DEFINE	TAM_CARTA 1 	//Letter   	216mm x 279mm  637 x 823
#DEFINE	TAM_TABLOID 3 	//Tabloid  	279mm x 432mm  823 x 1275
#DEFINE	TAM_EXECUTIVE 7	//Executive 184mm x 267mm  543 x 788
#DEFINE	TAM_A3 8		//A3     	297mm x 420mm  876 x 1240
#DEFINE	TAM_A4 9		//A4     	210mm x 297mm  620 x 876
#DEFINE pMoeda1 "@E 999,999.99"
#DEFINE pMoeda2 "@E 999,999,999.99"
#DEFINE __NTAM1  10
#DEFINE __NTAM2  25
#DEFINE __NTAM3  40
#DEFINE __NTAM4  10
#DEFINE __NTAM5  20
#DEFINE __NTAM6  10
#DEFINE __NTAM7  5
#DEFINE __NTAM8  15
#DEFINE __NTAM9  15
#DEFINE __NTAM10 15
#DEFINE EXTPDF ".pdf"
#DEFINE EXTREL ".rel"

//-------------------------------------------------------------------
/*/ { Protheus.doc } GROR002
Relatorio Proforma Invoice - Pedido de VEnda

@author Diego Muniz Cerqueira
@since 21/11/2016
@version 1.0
/*/
//-------------------------------------------------------------------
User Function GROR002(lWeb)

	Default lWeb := .F.

	If lWeb
		Return Execute(lWeb)
	Else
		Processa({|| Execute(lWeb)}, "Aguarde...", "Gerando proforma invoice...", .F.)
	EndIf
		
Return Nil

Static Function Execute(lWeb)

	Local cPath        := "c:\temp\"
	Local cPathLogo    := getNewPar("GR_PATLOGO","../../data/devgranito/logo/")
	Local cRelatorio   := "proformaInvoice.html" 	
	Local cPathSrv 	   := lower(getMV("MV_RELT"))
	Local cFileName	   := lower("proformaInvoice_" + criaTrab(nil,.f.))
	Local lSrvUnix     := IsSrvUnix()
	Local cProXDoc	   := getNewPar("GR_PROXDOC","")
	Local oUtil		   := util():new()
	Local cError	   := ""
	Local cPedido	   := ""
	Local cHtml		   := ''
	Local cArqHtml     := "\relatorios\exportacao\proformaInvoice.html"
	Local cRazao	   := ''
	Local cEnd		   := ''
	Local cCidade	   := ''
	Local cEstado	   := ''
	Local cCEP		   := ''
	Local cFone		   := ''
	Local cCnpj		   := ''
	Local cInsc		   := ''
	Local cObs		   := ''
	Local cSite        := Lower(GetMV("GR_SITEREL"))
	Local cSQL		   := ''
	Local qQUERY	   := ''
	Local cHTMLProduto := ''
	Local nContador	   := 1
	Local nTotalPreco  := 0
	Local nTotalDesco  := 0
	Local nTotalQtd    := 0
	Local nTotalCav    := 0
	Local nTtPesoBru   := 0
	Local nTtPesoLiq   := 0
	Local nVlrSeguro   := 0
	Local nVlrFrete    := 0
	Local nTotalChapa  := 0
	Local lHabCalc     := GETNEWPAR("GR_HABCALC", .F.) // Se calcula volume, peso líquido e bruto
	Local lPulaLin     := GETNEWPAR("GR_TAMINVO", .T.) // Se ajusta tamanho da grid de produtos
	Local nHandle      := 0
	Local cJavaScript  := ""
	Local nDesconto    := 0 
	Local nPercDesc	   := 0
	
	Default lWeb := .F.

	U_TOTVSES()

	If lSrvUnix
		cPathSrv := strTran(cPathSrv,"\","/")
	EndIf

	// Carrega Template
	nHandle := FT_FUse(cArqHtml)
	If nHandle == -1
		If lWeb
			Conout("Falha ao abrir o arquivo de layout! Favor verIficar se existe o arquivo " + cArqHtml + ".")
		Else
			MsgStop("Falha ao abrir o arquivo de layout! Favor verIficar se existe o arquivo " + cArqHtml + ".")
		EndIf
		Return Nil
	EndIf
	
	FT_FGOTOP()
	While !FT_FEof()
		cHtml += FT_FReadln()
		FT_FSkip()
	Enddo
	FT_FUse()

	If lWeb
		cPedido := SC5->C5_NUM //paramixb:PEDIDO		
	Else
		ProcRegua(0)	
		IncProc(1)	
		IncProc(1)

		cPedido := SC5->C5_NUM
		CPYS2T("\relatorios\logo.png" , cPath)
		aDir  := Directory(cPath, "D")
		If Len(aDir) = 0
			MakeDir(cPath)	
		EndIf

		cHtml := strTran(cHtml, "DIRLOGO/logo.png", cPathLogo + "logo.png")		
	EndIf

	If getNewPar("GR_LOGOFIL", .F.)
		cHtml := strTran(cHtml, "logo.png", AllTrim(cEmpAnt) + AllTrim(cFilAnt) + ".png")
	EndIf

	cRazao	:= allTrim(RetField('SM0', 1, cEmpAnt + cFilAnt, 'M0_NOMECOM'))
	cEnd	:= allTrim(RetField('SM0', 1, cEmpAnt + cFilAnt, 'M0_EndCOB')) + ", "
	cEnd	+= allTrim(RetField('SM0', 1, cEmpAnt + cFilAnt, 'M0_COMPCOB'))
	cCidade	:= allTrim(RetField('SM0', 1, cEmpAnt + cFilAnt, 'M0_CIDCOB'))
	cEstado	:= allTrim(RetField('SM0', 1, cEmpAnt + cFilAnt, 'M0_ESTCOB'))
	cCEP	:= allTrim(RetField('SM0', 1, cEmpAnt + cFilAnt, 'M0_CEPCOB'))
	cFone	:= allTrim(RetField('SM0', 1, cEmpAnt + cFilAnt, 'M0_TEL'))
	cCnpj	:= allTrim(RetField('SM0', 1, cEmpAnt + cFilAnt, 'M0_CGC'))
	cInsc	:= allTrim(RetField('SM0', 1, cEmpAnt + cFilAnt, 'M0_INSC'))

	cHtml := strTran(cHtml, "{{empresa_emissora}}", cRazao)
	cHtml := strTran(cHtml, "{{Endereco_emissora}}", cEnd)
	cHtml := strTran(cHtml, "{{cep_emissora}}", cCEP)
	cHtml := strTran(cHtml, "{{municipio_emissora}}", cCidade)
	cHtml := strTran(cHtml, "{{uf_emissora}}", cEstado)
	cHtml := strTran(cHtml, "{{telefone_emissora}}", cFone)
	cHtml := strTran(cHtml, "{{site}}", cSite)

	ZGO->(dbSetOrder(1))

		If ZGO->(msSeek(xFilial("ZGO")+cPedido))

			// dados da exportaï¿½ï¿½o
					
			cObs  := AllTrim(ZGO->ZGO_OBSERV)
			
			cHtml := strTran(cHtml, "{{invoice}}", Posicione("SC5", 1, xFilial("SC5") + ZGO->ZGO_PEDIDO, "C5_YINVOIC"))
			cHtml := strTran(cHtml, "{{orcamento}}", Posicione("SC5", 1, xFilial("SC5") + ZGO->ZGO_PEDIDO, "C5_COTACAO"))
			cHtml := strTran(cHtml, "{{po}}", ZGO->ZGO_ORDEM)
			cHtml := strTran(cHtml, "{{booking}}", ZGO->ZGO_RESERV)
	
			cHtml := strTran(cHtml, "{{port_origin}}", Posicione("SY9", 2, xFilial("SY9") + ZGO->ZGO_ORIGEM, "Y9_DESCR"))
			cHtml := strTran(cHtml, "{{port_destination}}", Posicione("SY9", 2, xFilial("SY9") + ZGO->ZGO_DESTIN, "Y9_DESCR"))
			cHtml := strTran(cHtml, "{{destination}}", Posicione("SY9", 2, xFilial("SY9") + ZGO->ZGO_DESFIN, "Y9_DESCR"))
			cHtml := strTran(cHtml, "{{vessel}}", ZGO->ZGO_EMBARC)
			cHtml := strTran(cHtml, "{{freight_forwarder}}", ZGO->ZGO_AGEMAR)
			cHtml := strTran(cHtml, "{{ship_line}}", ZGO->ZGO_ARMADO)
			cHtml := strTran(cHtml, "{{sales_agent}}", " ")
			cHtml := strTran(cHtml, "{{agent_order}}", " ")
			cHtml := strTran(cHtml, "{{incoterm}}", ZGO->ZGO_INCOTE)
			cHtml := strTran(cHtml, "{{ship_date}}", oUtil:getFormatDate(ZGO->ZGO_DATEMB, 'mm/dd/yyyy'))
	
			If !lHabCalc
				cHtml := strTran(cHtml, "{{total_net_weight}}", transform(ZGO->ZGO_PESLIQ, X3Picture("ZGO_PESLIQ")))
				cHtml := strTran(cHtml, "{{total_gross_weight}}", transform(ZGO->ZGO_PESBRU, X3Picture("ZGO_PESBRU")))
			EndIf
	
			cHtml := strTran(cHtml, "{{container}}", ZGO->ZGO_CONTAI)
			cHtml := strTran(cHtml, "{{type}}", ZGO->ZGO_TIPOCO)
			cHtml := strTran(cHtml, "{{credit_memo}}", ZGO->ZGO_CREMEM)
			cHtml := strTran(cHtml, "{{tare}}", transform(ZGO->ZGO_TARA, X3Picture("ZGO_TARA")))
			cHtml := strTran(cHtml, "{{door_seal}}", ZGO->ZGO_LACRE)
			cHtml := strTran(cHtml, "{{top_seal}}", " ")
			cHtml := strTran(cHtml, "{{hts}}", ZGO->ZGO_NCM)
			cHtml := strTran(cHtml, "{{bill_landing}}", ZGO->ZGO_BL)
			
		Endif	

		SC5->(dbSetOrder(1))
		
		If SC5->(msSeek(xFilial("SC5")+cPedido))
		
			// dados do pedido de vEnda
			
			cHtml := strTran(cHtml, "{{date}}", oUtil:getFormatDate(SC5->C5_EMISSAO, 'mm/dd/yyyy') )
			cHtml := strTran(cHtml, "{{insurance}}", transform(SC5->C5_SEGURO, X3Picture("C5_SEGURO")))
			cHtml := strTran(cHtml, "{{freight}}", transform(SC5->C5_FRETE, X3Picture("C5_FRETE")))
			cHtml := strTran(cHtml, "{{extra_expenses}}", transform(SC5->C5_DESPESA, X3Picture("C5_DESPESA")))
			
			nPercDesc  := SC5->C5_DESC1
			nDesconto  := SC5->C5_DESCONT
			nVlrSeguro := SC5->C5_SEGURO
			nVlrFrete  := SC5->C5_FRETE
			
			SE4->(dbSetOrder(1))
			
			If SE4->(msSeek(xFilial("SE4")+SC5->C5_CONDPAG))
			
				cHtml := strTran(cHtml, "{{payment_term}}", SE4->E4_DESCRI)
				
			EndIf
			
		EndIf

		cFkBanco := ""

		SA6->(dbSetOrder(1))
		
		If SA6->(msSeek(xFilial("SA6")+ZGO->(ZGO_BANCO+ZGO_AGENCI+ZGO_NUMCON)))
		
			cFkBanco := SA6->(A6_YCOD + A6_YAGENCI + A6_YNUMCON)
		
			//dados do banco
			
			cHtml := strTran(cHtml, "{{bank_1}}", SA6->A6_YBANEXP)
			cHtml := strTran(cHtml, "{{swIft_1}}", SA6->A6_YCODEXP)
			cHtml := strTran(cHtml, "{{account}}", SA6->A6_YCONEXT)
			cHtml := strTran(cHtml, "{{fedwire}}", SA6->A6_YFEDWIR)
			cHtml := strTran(cHtml, "{{bank_2}}", SA6->A6_YCORRES)
			cHtml := strTran(cHtml, "{{swIft_2}}", SA6->A6_YBICSWI)
			cHtml := strTran(cHtml, "{{iban}}", SA6->A6_YIBAN)
			cHtml := strTran(cHtml, "{{chips_uid}}", SA6->A6_YCHIPSU)
			
		Else
		
			cHtml := strTran(cHtml, "{{bank_1}}", " ")
			cHtml := strTran(cHtml, "{{swIft_1}}", " ")
			cHtml := strTran(cHtml, "{{account}}", " ")
			cHtml := strTran(cHtml, "{{fedwire}}", " ")
			cHtml := strTran(cHtml, "{{bank_2}}", " ")
			cHtml := strTran(cHtml, "{{swIft_2}}", " ")
			cHtml := strTran(cHtml, "{{iban}}", " ")
			cHtml := strTran(cHtml, "{{chips_uid}}", " ")
			
		EndIf
								
		If !Empty(cFkBanco)
		
			If SA6->(msSeek(xFilial("SA6") + cFkBanco))
		
				cHtml := strTran(cHtml, "{{sec_bank_1}}", SA6->A6_YBANEXP)
				cHtml := strTran(cHtml, "{{sec_swIft_1}}", SA6->A6_YCODEXP)
				cHtml := strTran(cHtml, "{{sec_account}}", SA6->A6_YCONEXT)
				cHtml := strTran(cHtml, "{{sec_fedwire}}", SA6->A6_YFEDWIR)
				cHtml := strTran(cHtml, "{{sec_bank_2}}", SA6->A6_YCORRES)
				cHtml := strTran(cHtml, "{{sec_swIft_2}}", SA6->A6_YBICSWI)
				cHtml := strTran(cHtml, "{{sec_iban}}", SA6->A6_YIBAN)
				cHtml := strTran(cHtml, "{{sec_chips_uid}}", SA6->A6_YCHIPSU)
		
			Else
		
				cHtml := strTran(cHtml, "{{sec_bank_1}}", " ")
				cHtml := strTran(cHtml, "{{sec_swIft_1}}", " ")
				cHtml := strTran(cHtml, "{{sec_account}}", " ")
				cHtml := strTran(cHtml, "{{sec_fedwire}}", " ")
				cHtml := strTran(cHtml, "{{sec_bank_2}}", " ")
				cHtml := strTran(cHtml, "{{sec_swIft_2}}", " ")
				cHtml := strTran(cHtml, "{{sec_iban}}", " ")
				cHtml := strTran(cHtml, "{{sec_chips_uid}}", " ")
		
			EndIf	

		Else

			cHtml := strTran(cHtml, "{{sec_bank_1}}", " ")
			cHtml := strTran(cHtml, "{{sec_swIft_1}}", " ")
			cHtml := strTran(cHtml, "{{sec_account}}", " ")
			cHtml := strTran(cHtml, "{{sec_fedwire}}", " ")
			cHtml := strTran(cHtml, "{{sec_bank_2}}", " ")
			cHtml := strTran(cHtml, "{{sec_swIft_2}}", " ")
			cHtml := strTran(cHtml, "{{sec_iban}}", " ")
			cHtml := strTran(cHtml, "{{sec_chips_uid}}", " ")

		EndIf	
		
		SA1->(dbSetOrder(1))
		
		If SA1->(msSeek(xFilial("SA1")+ZGO->(ZGO_CLIENT+ZGO_LOJA)))
		
			//dados do cliente
			
			cHtml := strTran(cHtml, "{{empresa}}", SA1->A1_NOME)
			cHtml := strTran(cHtml, "{{Endereco}}", SA1->A1_End)
			cHtml := strTran(cHtml, "{{cep}}", SA1->A1_CEP)
			cHtml := strTran(cHtml, "{{municipio}}", SA1->A1_MUN)
			cHtml := strTran(cHtml, "{{uf}}", SA1->A1_EST)
			
			SYA->(dbSetOrder(1))
			
			If SYA->(msSeek(xFilial("SYA")+SA1->A1_PAIS))
			
				cHtml := strTran(cHtml, "{{pais}}", SYA->YA_DESCR)
				
			EndIf
			
			cHtml := strTran(cHtml, "{{telefone}}", SA1->A1_TEL)
			cHtml := strTran(cHtml, "{{contato}}", SA1->A1_CONTATO)
			
		EndIf
		
	//EndIf

	//----------------------------------------------------
	// Soma pesos dos cavaletes.
	//----------------------------------------------------

	If lHabCalc

		cSQL := "    SELECT SUM(DISTINCT ZG3_TARA) ZG3_TARA, SUM(DISTINCT ZG3_PESOLQ) ZG3_PESOLQ, SUM(DISTINCT ZG3_PESOBR) ZG3_PESOBR "
		cSQL += "      FROM " + RETSQLNAME("SC6") + " SC6" + CHR(10)
		cSQL += " LEFT JOIN " + RETSQLNAME("SB1") + " SB1" + CHR(10)                        
		cSQL += "        ON SB1.B1_FILIAL  = '" + xFilial("SB1") + "'" + CHR(10)
		cSQL += "       AND SB1.B1_COD     = C6_PRODUTO" + CHR(10)
		cSQL += "       AND SB1.D_E_L_E_T_ = ''" + CHR(10)             
		cSQL += " LEFT JOIN " + RETSQLNAME("SBM") + " SBM" + CHR(10)                        
		cSQL += "        ON SBM.BM_FILIAL  = '" + xFilial("SBM") + "'" + CHR(10)
		cSQL += "       AND SBM.BM_GRUPO   = SB1.B1_GRUPO" + CHR(10)
		cSQL += "       AND SBM.D_E_L_E_T_ = ''" + CHR(10)                
		cSQL += " LEFT JOIN " + RETSQLNAME("SC9") + " SC9" + CHR(10)
		cSQL += "        ON SC9.C9_FILIAL  = '" + xFilial("SC9") + "'" + CHR(10)
		cSQL += "       AND SC9.C9_PEDIDO  = C6_NUM" + CHR(10)
		cSQL += "       AND SC9.C9_ITEM    = C6_ITEM" + CHR(10)
		cSQL += "       AND SC9.C9_PRODUTO = C6_PRODUTO" + CHR(10)
		cSQL += "       AND SC9.C9_LOTECTL = C6_LOTECTL" + CHR(10)
		cSQL += "       AND SC9.C9_NUMLOTE = C6_NUMLOTE" + CHR(10)
		cSQL += "       AND SC9.D_E_L_E_T_ = ''" + CHR(10)                                 
		cSQL += " LEFT JOIN " + RETSQLNAME("SB8") + " SB8" + CHR(10)
		cSQL += "        ON SB8.B8_FILIAL  = '" + xFilial("SB8") + "'" + CHR(10)
		cSQL += "       AND SB8.B8_PRODUTO = C9_PRODUTO" + CHR(10)
		cSQL += "       AND SB8.B8_LOTECTL = C9_LOTECTL" + CHR(10)
		cSQL += "       AND SB8.B8_NUMLOTE = C9_NUMLOTE" + CHR(10)                  
		cSQL += "       AND SB8.D_E_L_E_T_ = ''" + CHR(10)             

		// Consulta cavaletes pra calcular o peso
		cSql += " LEFT JOIN " + RetSqlName("ZG3") + " ZG3 " + Chr(10)
		cSql += "        ON ZG3.ZG3_FILIAL = '" + xFilial("ZG3") + "' "
		cSql += "       AND ZG3.ZG3_CODIGO = SB8.B8_YCAVALE "
		cSql += "       AND ZG3.D_E_L_E_T_ = '' "
					
		cSQL += "     WHERE SC6.C6_FILIAL  = '" + xFilial("SC6") + "'" + CHR(10)
		cSQL += "       AND SC6.C6_NUM  = '" + cPedido + "'" + CHR(10)
		cSQL += "       AND SC6.D_E_L_E_T_ = ''" + CHR(10)
		cSQL += "       AND SC9.C9_QTDLIB > 0" + CHR(10)

		If !(Empty(cProXDoc))

			cSQL += "       AND SBM.BM_YTIPO IN " + cProXDoc + CHR(10)

		EndIf

		cSql += " GROUP BY ZG3_CODIGO"

		TCQUERY cSQL NEW ALIAS qQUERY

		nTtPesoBru := 0
		nTtPesoLiq := 0

		While qQUERY->(!Eof())

			nTtPesoBru  += qQUERY->ZG3_PESOBR
			nTtPesoLiq  += qQUERY->ZG3_PESOLQ

			qQUERY->(DbSkip())

		EndDo

		qQUERY->(DbCloseArea())

	EndIf

	//----------------------------------------------------
	// Consulta produtos do pedido de vEnda.
	//----------------------------------------------------

	cSQL := "    SELECT C6_PRODUTO, B1_PESO, B1_PESBRU, " + CHR(10)
	cSQL += "           CASE" + CHR(10)
	cSQL += "                WHEN EX6_YDESCI <> '' THEN RTRIM(EX6_YDESCI)" + CHR(10)
	cSQL += "                WHEN B5_YCEMEIN <> '' THEN RTRIM(B5_YCEMEIN) Else RTRIM(B5_CEME)" + CHR(10) 
	cSQL += "           End + ' - ' + RTRIM(ISNULL(ZG4_DESCRI,'')) AS B5_CEME, C6_DESCRI," + CHR(10)
	cSQL += "           COUNT(C6_PRODUTO) AS QTD_CHAPA," + CHR(10)
	cSQL += "           COUNT(DISTINCT B8_YCAVALE) AS QTD_CAVALE," + CHR(10)
	cSQL += "     		SUM(DISTINCT C6_QTDVEN) AS C6_QTDVEN," + CHR(10) 
	cSQL += "     		SUM(C9_QTDLIB) AS C9_QTDLIB," + CHR(10) 
	cSQL += "     		SUM(C6_YTOTBRU) as C6_YTOTBRU," + CHR(10)
	cSQL += "     		SUM(C6_YTOTLIQ) as C6_YTOTLIQ," + CHR(10)
	cSQL += "     		ZGO_PESLIQ, ZGO_PESBRU, ZGO_TARA," + CHR(10)

	// Soma peso dos cavaletes
	// cSql += "           SUM(DISTINCT ZG3_TARA) ZG3_TARA, SUM(DISTINCT ZG3_PESOLQ) ZG3_PESOLQ, SUM(DISTINCT ZG3_PESOBR) ZG3_PESOBR, "

	cSQL += "     		SUM(C6_VALDESC) AS C6_VALDESC, C6_PRUNIT, AVG(C6_PRCVEN) AS C6_PRCVEN" + CHR(10)
	cSQL += "      FROM " + RETSQLNAME("SC6") + " SC6" + CHR(10)
	cSQL += " LEFT JOIN " + RETSQLNAME("SB1") + " SB1" + CHR(10)                        
	cSQL += "        ON SB1.B1_FILIAL  = '" + xFilial("SB1") + "'" + CHR(10)
	cSQL += "       AND SB1.B1_COD     = C6_PRODUTO" + CHR(10)
	cSQL += "       AND SB1.D_E_L_E_T_ = ''" + CHR(10)             
	cSQL += " LEFT JOIN " + RETSQLNAME("SBM") + " SBM" + CHR(10)                        
	cSQL += "        ON SBM.BM_FILIAL  = '" + xFilial("SBM") + "'" + CHR(10)
	cSQL += "       AND SBM.BM_GRUPO   = SB1.B1_GRUPO" + CHR(10)
	cSQL += "       AND SBM.D_E_L_E_T_ = ''" + CHR(10)                
	cSQL += " LEFT JOIN " + RETSQLNAME("SB5") + " SB5" + CHR(10)                        
	cSQL += "        ON SB5.B5_FILIAL  = '" + xFilial("SB5") + "'" + CHR(10)
	cSQL += "       AND SB5.B5_COD     = C6_PRODUTO" + CHR(10)
	cSQL += "       AND SB5.D_E_L_E_T_ = ''" + CHR(10)                
	cSQL += " LEFT JOIN " + RETSQLNAME("SC9") + " SC9" + CHR(10)
	cSQL += "        ON SC9.C9_FILIAL  = '" + xFilial("SC9") + "'" + CHR(10)
	cSQL += "       AND SC9.C9_PEDIDO  = C6_NUM" + CHR(10)
	cSQL += "       AND SC9.C9_ITEM    = C6_ITEM" + CHR(10)
	cSQL += "       AND SC9.C9_PRODUTO = C6_PRODUTO" + CHR(10)
	cSQL += "       AND SC9.C9_LOTECTL = C6_LOTECTL" + CHR(10)
	cSQL += "       AND SC9.C9_NUMLOTE = C6_NUMLOTE" + CHR(10)
	cSQL += "       AND SC9.D_E_L_E_T_ = ''" + CHR(10)                                 
	cSQL += " LEFT JOIN " + RETSQLNAME("SB8") + " SB8" + CHR(10)
	cSQL += "        ON SB8.B8_FILIAL  = '" + xFilial("SB8") + "'" + CHR(10)
	cSQL += "       AND SB8.B8_PRODUTO = C9_PRODUTO" + CHR(10)
	cSQL += "       AND SB8.B8_LOTECTL = C9_LOTECTL" + CHR(10)
	cSQL += "       AND SB8.B8_NUMLOTE = C9_NUMLOTE" + CHR(10)                  
	cSQL += "       AND SB8.D_E_L_E_T_ = ''" + CHR(10)             

	// Consulta cavaletes pra calcular o peso
	// cSql += " LEFT JOIN " + RetSqlName("ZG3") + " ZG3 " + Chr(10)
	// cSql += "        ON ZG3.ZG3_CODIGO = SB8.B8_YCAVALE "
	// cSql += "       AND ZG3.D_E_L_E_T_ = '' "
				
	cSQL += " LEFT JOIN " + RETSQLNAME("EX6") + " EX6" + CHR(10)
	cSQL += "        ON EX6.EX6_FILIAL = '" + xFilial("EX6") + "'" + CHR(10)
	cSQL += "       AND EX6.EX6_COD_I  = C6_PRODUTO" + CHR(10)
	cSQL += "       AND EX6.EX6_CLIENT = C6_CLI" + CHR(10)
	cSQL += "       AND EX6.EX6_CLLOJA = C6_LOJA" + CHR(10)
	cSQL += "       AND EX6.EX6_YCLASS = B8_YCLASSI" + CHR(10)
	cSQL += "       AND EX6.D_E_L_E_T_ = ''" + CHR(10)                
	cSQL += " LEFT JOIN " + RETSQLNAME("ZGO") + " ZGO" + CHR(10)
	cSQL += "        ON ZGO.ZGO_FILIAL = '" + xFilial("ZGO") + "'" + CHR(10)
	cSQL += "       AND ZGO.ZGO_PEDIDO = C9_PEDIDO" + CHR(10)
	cSQL += "       AND ZGO.D_E_L_E_T_ = ''" + CHR(10)
	cSQL += " LEFT JOIN " + RETSQLNAME("ZG4") + " ZG4" + CHR(10)
	cSQL += "        ON ZG4.ZG4_FILIAL = '" + xFilial("ZG4") + "'" + CHR(10)
	cSQL += "       AND ZG4.ZG4_CODIGO = B8_YCLASSI" + CHR(10)       
	cSQL += "       AND ZG4.D_E_L_E_T_ = ''" + CHR(10)
	cSQL += "     WHERE SC6.C6_FILIAL  = '" + xFilial("SC6") + "'" + CHR(10)
	cSQL += "       AND SC6.C6_NUM  = '" + cPedido + "'" + CHR(10)
	cSQL += "       AND SC6.D_E_L_E_T_ = ''" + CHR(10)
	cSQL += "       AND SC9.C9_QTDLIB > 0" + CHR(10)

	If !(Empty(cProXDoc))

		cSQL += "       AND SBM.BM_YTIPO IN " + cProXDoc + CHR(10)

	EndIf

	cSQL += "  GROUP BY C6_PRODUTO,  B1_PESO, B1_PESBRU, C6_DESCRI, B5_CEME, ZGO_PESLIQ, ZGO_PESBRU, ZGO_TARA, C6_VALDESC, C6_PRUNIT, ZG4_DESCRI, EX6_YDESCI, B5_YCEMEIN" + CHR(10)
	cSQL += "  ORDER BY C6_DESCRI DESC" + CHR(10)

	TCQUERY cSQL NEW ALIAS qQUERY

	nTotalChapa := 0

	qQUERY->(dbGoTop())

	while qQUERY->(!eof())     

		If "AMOSTRA" $ qQUERY->B5_CEME
		
			cHTMLProduto += "<tr>"
			cHTMLProduto += "<td style='border-right: 1px solid; border-left: 1px solid'>" + cValToChar(nContador++) + "</td>"
			cHTMLProduto += "<td style='text-align:right; border-right: 1px solid'>" + transform(0, X3Picture("C5_DESPESA")) + "</td>"
			cHTMLProduto += "<td style='text-align:right; border-right: 1px solid'>" + transform(0, X3Picture("C5_DESPESA")) + "</td>"
			cHTMLProduto += "<td style='border-right: 1px solid'>" + qQUERY->C6_DESCRI + " " + cValToChar(qQUERY->C6_QTDVEN) + " PCS </td>"	
			cHTMLProduto += "<td style='text-align:right; border-right: 1px solid'>" + transform(qQUERY->C6_PRCVEN, X3Picture("C6_PRCVEN")) + "</td>"
			cHTMLProduto += "<td style='text-align:right; border-right: 1px solid'>" + transform(qQUERY->C6_PRCVEN / 10.764, X3Picture("C6_PRCVEN")) + "</td>"
			cHTMLProduto += "<td style='text-align:right; border-right: 1px solid'>" + transform(qQUERY->C6_QTDVEN*C6_PRCVEN, X3Picture("C6_VALOR")) + "</td>"
			cHTMLProduto += "</tr>"
			
			nTotalPreco  += Round(qQUERY->C6_QTDVEN * C6_PRCVEN, TamSX3("C6_VALOR")[2])
			nTotalDesco  += qQUERY->C6_VALDESC
			nTotalQtd    += 0
			nTotalCav    += 0

			nTtPesoLiq += qQUERY->C9_QTDLIB * qQUERY->B1_PESO
			nTtPesoBru += qQUERY->C9_QTDLIB * qQUERY->B1_PESBRU

			// nTtPesoBru  += 0
			// nTtPesoLiq  += 0
			
		Else

			nTotalChapa += qQUERY->QTD_CHAPA
		
			cHTMLProduto += "<tr>"
			cHTMLProduto += "<td style='border-right: 1px solid; border-left: 1px solid'>" + cValToChar(nContador++) + "</td>"
			cHTMLProduto += "<td style='text-align:right; border-right: 1px solid'>" + transform(qQUERY->C9_QTDLIB, X3Picture("C9_QTDLIB")) + "</td>"
			cHTMLProduto += "<td style='text-align:right; border-right: 1px solid'>" + transform(qQUERY->C9_QTDLIB * 10.764, X3Picture("C9_QTDLIB")) + "</td>"
			cHTMLProduto += "<td style='border-right: 1px solid'>" + qQUERY->B5_CEME + " - (" + cValToChar(qQUERY->QTD_CAVALE) + " BUNDLES) " + cValToChar(qQUERY->QTD_CHAPA) + " SLABS</td>"
			cHTMLProduto += "<td style='text-align:right; border-right: 1px solid'>" + transform(qQUERY->C6_PRUNIT, X3Picture("C6_PRUNIT")) + "</td>"
			cHTMLProduto += "<td style='text-align:right; border-right: 1px solid'>" + transform(qQUERY->C6_PRUNIT / 10.764, X3Picture("C6_PRUNIT")) + "</td>"
			cHTMLProduto += "<td style='text-align:right; border-right: 1px solid'>" + transform(qQUERY->C9_QTDLIB*C6_PRUNIT, X3Picture("C6_PRUNIT")) + "</td>"
			cHTMLProduto += "</tr>"
			nTotalPreco  += Round(qQUERY->C9_QTDLIB * C6_PRUNIT, TamSX3("C6_VALOR")[2])
			nTotalDesco  += qQUERY->C6_VALDESC
			nTotalQtd    += qQUERY->C9_QTDLIB
			nTotalCav    += qQUERY->QTD_CAVALE

			If !lHabCalc
				nTtPesoBru += qQUERY->ZGO_PESBRU
				nTtPesoLiq += qQUERY->ZGO_PESLIQ
			EndIf

			// nTtPesoBru  += qQUERY->ZGO_PESBRU
			// nTtPesoLiq  += qQUERY->ZGO_PESLIQ
			
		EndIf
		
		qQUERY->(dbSkip())
		
	EndDo

	If nContador > 32 .And. lPulaLin

		while nContador%44 != 0
		
			cHTMLProduto += "<tr>"
			cHTMLProduto += "<td style='border-right: 1px solid; border-left: 1px solid'></td>"
			cHTMLProduto += "<td style='border-right: 1px solid'></td>"
			cHTMLProduto += "<td style='text-align:right; border-right: 1px solid'></td>"
			cHTMLProduto += "<td style='text-align:right; border-right: 1px solid'></td>"
			cHTMLProduto += "<td style='text-align:right; border-right: 1px solid'></td>"
			cHTMLProduto += "<td style='text-align:right; border-right: 1px solid'></td>"
			cHTMLProduto += "<td style='text-align:right; border-right: 1px solid'></td>"
			cHTMLProduto += "</tr>"
			
			nContador++
			
		EndDo
		
	ElseIf lPulaLin

		while nContador%23 != 0
		
			cHTMLProduto += "<tr>"
			cHTMLProduto += "<td style='border-right: 1px solid; border-left: 1px solid'></td>"
			cHTMLProduto += "<td style='border-right: 1px solid'></td>"
			cHTMLProduto += "<td style='text-align:right; border-right: 1px solid'></td>"
			cHTMLProduto += "<td style='text-align:right; border-right: 1px solid'></td>"
			cHTMLProduto += "<td style='text-align:right; border-right: 1px solid'></td>"
			cHTMLProduto += "<td style='text-align:right; border-right: 1px solid'></td>"
			cHTMLProduto += "<td style='text-align:right; border-right: 1px solid'></td>"
			cHTMLProduto += "</tr>"
			
			nContador++
			
		EndDo
		
	EndIf

	If At("{{observacao}}", cHtml) > 0

		cHtml := strTran(cHtml, "{{observacao}}", cObs)

	Else
													
		cHTMLProduto += "<tr>"
		cHTMLProduto += "<td style='border-right: 1px solid; border-left: 1px solid'></td>"
		cHTMLProduto += "<td style='border-right: 1px solid'></td>"
		cHTMLProduto += "<td style='text-align:right; border-right: 1px solid'>NOTE:</td>"
		cHTMLProduto += "<td style='text-align:left; border-right: 1px solid'>" + cObs + "</td>"
		cHTMLProduto += "<td style='text-align:right; border-right: 1px solid'></td>"
		cHTMLProduto += "<td style='text-align:right; border-right: 1px solid'></td>"
		cHTMLProduto += "<td style='text-align:right; border-right: 1px solid'></td>"
		cHTMLProduto += "</tr>"
		
	EndIf

	qQUERY->(dbCloseArea())

	cHtml := strTran(cHtml, "{{number_packages}}", cValToChar(nTotalCav))

	cHtml := strTran(cHtml, "{{msg}}", "NO COMPLAINT REGARGING <br>QUALITY WILL BE ACCEPTED <br>AFTER 60 DAYS FROM B/L DATE.")
	cHtml := strTran(cHtml, "{{msg_2}}", "We confirm this is product of Brazil origin.<br>We certIfy that the wood used in our packing is totally free from bark and apparently free form live plant.")

	cHtml := strTran(cHtml, "{{tag_produtos}}", cHTMLProduto)

	cHtml := strTran(cHtml, "{{measures_m2}}", transform(nTotalQtd, "@E 9,999,999.999"))
	cHtml := strTran(cHtml, "{{measures_ft2}}", transform(nTotalQtd * 10.764, "@E 9,999,999.999"))

	nTtDesconto := nDesconto + (nPercDesc * nTotalPreco / 100)

	cHtml := strTran(cHtml, "{{desconto}}", transform(nTtDesconto, "@E 9,999,999.99"))

	cHtml := strTran(cHtml, "{{fob_price}}", transform(nTotalPreco, "@E 9,999,999.99"))
	cHtml := strTran(cHtml, "{{credit_note}}", transform(nTotalDesco, "@E 9,999,999.99"))
	cHtml := strTran(cHtml, "{{total_price}}", transform(nTotalPreco-nTotalDesco-nTtDesconto+nVlrSeguro+nVlrFrete, "@E 9,999,999.99"))
	cHtml := strTran(cHtml, "{{total_extenso}}", StrTran(extenso(nTotalPreco-nTotalDesco-nTtDesconto+nVlrSeguro+nVlrFrete,,2,,"3"), "DOLARES", "DOLLARS"))

	// If lHabCalc
		cHtml := strTran(cHtml, "{{total_net_weight}}", transform(nTtPesoLiq, "@E 9,999,999.999"))
		cHtml := strTran(cHtml, "{{total_gross_weight}}", transform(nTtPesoBru, "@E 9,999,999.999"))
	// EndIf

	cHtml := strTran(cHtml, "{{measures_m2}}", transform(nTotalQtd, "@E 9,999,999.999"))
	cHtml := strTran(cHtml, "{{measures_ft2}}", transform(nTotalQtd * 10.764, "@E 9,999,999.999"))
	cHtml := strTran(cHtml, "{{total_chapa}}", transform(nTotalChapa, "@E 9,999,999"))
	cHtml := strTran(cHtml, "{{observacao}}", cObs)

	oUtil:destroy()

	cHtml := FwCutOff(cHtml) // FwCutOff(<cString >, <lNoAccent >)-> NIL

	If lWeb
		Return( { cFileName + EXTPDF, cError, cHtml } )
	Else

		cJavaScript += "<meta http-equiv='Content-Type' content='application/pdf; charset=utf-8'>
		cJavaScript += "<script src='https://ajax.googleapis.com/ajax/libs/jquery/3.4.1/jquery.min.js'></script>
		cJavaScript += "<script type='text/javascript'>
		cJavaScript += "	function openpdf(){		
		cJavaScript += "		$.ajax({
		cJavaScript += "			method: 'post',
		cJavaScript += "			url: 'http://interno.grplus.com.br/rest/servico/ReportServico.php',
		cJavaScript += '			data: "' + cHtml + '",'
		cJavaScript += "			xhrFields: {
		cJavaScript += "				responseType: 'blob'
		cJavaScript += "			},
		cJavaScript += "			success: function (data) {
		cJavaScript += "				var a = document.createElement('a');
		cJavaScript += "				var url = window.URL.createObjectURL(data);
		cJavaScript += "				a.href = url;
		cJavaScript += "				a.download = 'relatorio.pdf';
		cJavaScript += "				document.body.append(a);
		cJavaScript += "				location.href = url;
		cJavaScript += "			}				
		cJavaScript += "		});
		cJavaScript += "	}
		cJavaScript += "</script>
		cJavaScript += "</head>
		cJavaScript += "<body onload='openpdf()'>
		cJavaScript += EncodeUTF8('<div align="center"><img src="http://interno.grplus.com.br/data/img/load.gif"><h2 style="font-family: Verdana; color: orange">Favor aguardar enquanto o relatório é gerado...</h2></div>')
		cJavaScript += "</body>

		// Grava arquivo alterado
		cArquivoNovo := cPath + cRelatorio
		nHandle := FCreate(cArquivoNovo)		
		FWrite(nHandle, cJavaScript)		
		FClose(nHandle)

		ShellExecute("Open", cArquivoNovo, " /k dir", "C:\temp\", 1 )
	EndIf

Return Nil
