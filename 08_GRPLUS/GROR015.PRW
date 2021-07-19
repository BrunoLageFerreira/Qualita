#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch"

//-------------------------------------------------------------------
/*/ { Protheus.doc } GROR015
Impressão de Etiqueta

@author Kenny Roger Martins
@since 11/04/2017
@version 1.0
/*/
//-------------------------------------------------------------------

User Function GROR015()
**********************************************************************
*
*
****	
Local cSql      := ""
Local qQuery    := ""	
Local cPergunte := Padr("GROR015",10)	

	//U_TOTVSES()
	
	AtuSx1(cPergunte)

	If Pergunte(cPergunte, .T.)
	
		cSql := "     SELECT * ,(SELECT TOP 1 D1_DOC " + CHR(10)
		cSql += " 				 FROM SD1010 " + CHR(10)
		cSql += " 				 			WHERE D_E_L_E_T_ = ''" + CHR(10) 
		cSql += " 				 			  AND D1_SERIE = '2' " + CHR(10)
		cSql += " 				 			  AND D1_UM = 'M2'" + CHR(10)
		cSql += " 				 			  AND D1_LOTECTL = SB8.B8_LOTECTL " + CHR(10)
		cSql += " 				 			  AND D1_NUMLOTE = SB8.B8_NUMLOTE " + CHR(10)
		cSql += " 				 ) NFT, " + CHR(10)
		
	
		cSql += " 				 (SELECT TOP 1 D1_LOTEFOR " + CHR(10)
 		cSql += " 				 				FROM SD1010 " + CHR(10)
		cSql += " 				 				WHERE D_E_L_E_T_ = '' " + CHR(10)
		cSql += " 				 					AND LEFT(D1_COD,2) = 'BL' " + CHR(10)
 		cSql += " 				 					AND dbo.F_LOTECTL(D1_LOTECTL) = dbo.F_LOTECTL(SB8.B8_LOTECTL) " + CHR(10)
		cSql += " 				 					AND D1_LOTEFOR <> '' " + CHR(10)
 		cSql += " 				 		 ) BLOCO_PEDREIRA " + CHR(10)
		
		
		
		cSql += "       FROM " + RETSQLNAME("SB8") + " SB8 " + CHR(10)
		cSql += " INNER JOIN " + RETSQLNAME("SB1") + " SB1 " + CHR(10)
		cSql += "         ON SB1.B1_FILIAL  = '" + xFilial("SB1") + "' " + CHR(10)	
		cSql += "        AND SB1.B1_COD     = SB8.B8_PRODUTO " + CHR(10)	
		cSql += "        AND SB1.D_E_L_E_T_ = '' " + CHR(10) 
		cSql += " INNER JOIN " + RETSQLNAME("SBM") + " SBM " + CHR(10)
		cSql += "         ON SBM.BM_FILIAL  = '" + xFilial("SBM") + "' " + CHR(10)	
		cSql += "        AND SBM.BM_GRUPO   = SB1.B1_GRUPO " + CHR(10)	
		cSql += "        AND SBM.BM_YTIPO   IN ('C','L') " + CHR(10)			
		cSql += "        AND SBM.D_E_L_E_T_ = '' " + CHR(10) 
		cSql += " INNER JOIN " + RETSQLNAME("SB5") + " SB5 " + CHR(10)
		cSql += "         ON SB5.B5_FILIAL  = '" + xFilial("SB5") + "' " + CHR(10)	
		cSql += "        AND SB5.B5_COD     = SB8.B8_PRODUTO " + CHR(10)		
		cSql += "        AND SB5.D_E_L_E_T_ = '' " + CHR(10) 
		cSql += "      WHERE SB8.B8_FILIAL  = '" + xFilial("SB8") + "' " + CHR(10)
		cSql += "        AND SB8.B8_PRODUTO BETWEEN '" + MV_PAR01 + "' AND '" + MV_PAR02 + "' " + CHR(10) 
		cSql += "        AND SB8.B8_LOTECTL BETWEEN '" + MV_PAR03 + "' AND '" + MV_PAR04 + "' " + CHR(10) 
		cSql += "        AND SB8.B8_NUMLOTE BETWEEN '" + MV_PAR05 + "' AND '" + MV_PAR06 + "' " + CHR(10) 

		
		//cSql += "        AND SB8.B8_SALDO   > 0 " + CHR(10) 
	

		cSql += "        AND SB8.D_E_L_E_T_ = '' " + CHR(10) 
		
		TCQUERY cSQL NEW ALIAS qQUERY
	
		MsAguarde({|| setEtiqueta(qQUERY) },"Impressão de etiqueta...","Aguarde...")
	
		qQUERY->(DbCloseArea())	
		
	EndIf
			
Return Nil


Static Function setEtiqueta(qQUERY)
**********************************************************************
*
*
****
Local cCodBar   := ""
Local cLote     := ""
Local cDescpro  := ""
Local cMedida   := ""

Local nQuant	:= 1
Local cImpress  := "" //"PDFCreator"
Local cModBarr  := AllTrim(GetNewPar("GR_MODBARR", "CODE128"))                                   
Local cLogo 	:= "lgrl99.bmp"
Local cCima     := "cima.bmp"
Local cBaixo    := "baixo.bmp"
Local oFont06	:= TFont():New('Consolas',,06,,.F.,,,,.T.,.F.,.F.)
Local oFont06N	:= TFont():New('Consolas',,06,,.T.,,,,.T.,.F.,.F.)
Local oFont08	:= TFont():New('Consolas',,08,,.F.,,,,.T.,.F.,.F.)
Local oFont08N	:= TFont():New('Consolas',,08,,.T.,,,,.T.,.F.,.F.)
Local oFont10	:= TFont():New('Consolas',,10,,.F.,,,,.T.,.F.,.F.)
Local oFont10N	:= TFont():New('Consolas',,10,,.T.,,,,.T.,.F.,.F.)
Local oFont12	:= TFont():New('Consolas',,12,,.F.,,,,.T.,.F.,.F.)
Local oFont12N	:= TFont():New('Consolas',,12,,.T.,,,,.T.,.F.,.F.)
Local oFont14N	:= TFont():New('Consolas',,14,,.T.,,,,.T.,.F.,.F.)
Local cCodAuto  := GetNewPar("GR_CODAUTO", "")	
Local nDirecao  := 1

Local lAdjustToLegacy := .F.
Local lDisableSetup   := .F.

	MsProcTxt("Iniciando impressão...")

	Private oPrinter := FWMSPrinter():New("produto"+Alltrim(__cUserID)+".etq", IMP_SPOOL, lAdjustToLegacy, "/spool/", lDisableSetup,,, Alltrim(cImpress))

	oPrinter:SetMargin(001,001,001,001)

	// Direção da seta.

	If MV_PAR07 == 1
		nDirecao := 2
	Else
		nDirecao := MV_PAR07
	EndIf
		
	While qQUERY->(!(EOF()))
	
		If Empty(cCodAuto)
	
			cCodBar  := U_GETCODBAR(qQUERY->B5_YTIPMAT, qQUERY->B8_LOTECTL, qQUERY->B8_NUMLOTE)
			
			If Left(cCodBar,1)=="W" 
				cCodBar := "D"+cCodBar 
			EndIF

		Else

			If Empty(qQUERY->(B8_YCODBAR))
			
				cCodBar  := &(cCodAuto)

				SB8->(DbGoTo(qQUERY->(R_E_C_N_O_)))
				
				RecLock("SB8", .F.)
				SB8->B8_YCODBAR := cCodBar
				SB8->(MsUnLock())

				ConfirmSX8()

			Else

				cCodBar := qQUERY->(B8_YCODBAR)

			EndIf

		EndIf
		
		cLote    := AllTrim(qQUERY->B8_LOTECTL) + "/" + AllTrim(qQUERY->B8_NUMLOTE) 
		cMedida  := AllTrim(Transform(qQUERY->B8_YCOMLIQ, "@E 999.99")) + " x " + AllTrim(Transform(qQUERY->B8_YALTLIQ, "@E 999.99")) + " = " + AllTrim(Transform(qQUERY->B8_YCOMLIQ * qQUERY->B8_YALTLIQ, "@E 999.99"))		

		MsProcTxt("Imprimindo etiqueta " + cCodBar + "...")

		oPrinter:StartPage()

		oPrinter:Code128B(022, 030, cCodBar, 022)

		oPrinter:Say(030, 040, cCodBar, oFont08N)

		oPrinter:Say(012, 152, cLote, oFont14N)

		oPrinter:Say(022, 152, "NFT  | BLOCO", oFont10N)

		oPrinter:Say(030, 152, CVALTOCHAR(VAL(qQUERY->NFT)) + "-" + StrZero(Val(qQUERY->B8_NUMLOTE), 3) + " | " + AllTrim(qQUERY->BLOCO_PEDREIRA)  , oFont10N)
		
		If Mod(nDirecao,2) == 0
			oPrinter:SayBitmap(008, 284, cCima , 08, 22)
		Else
			oPrinter:SayBitmap(008, 284, cBaixo, 08, 22)
		EndIf		

		nDirecao += 1

		oPrinter:EndPage()
					
		qQUERY->(DbSkip())
		
	EndDo
		
	oPrinter:Preview()
	//oPrinter:Print()

Return Nil

/*---------+----------+-------+-----------------------+------+------------+
|Função    |AtuSx1    | Autor |KENNY ROGER MARTINS    | Data | 27.04.2017 |
+----------+----------+-------+-----------------------+------+------------+
|Descrição |Cria perguntas                                                |
+----------+--------------------------------------------------------------+
|Uso       |Gestão de Rochas Ornamentais                                  |
+----------+-------------------------------------------------------------*/
Static Function AtuSx1(cPerg)

	Local aDados := {}
	
	aAdd( aDados, {cPerg,'01','Material De ?',        '','','MV_CH0','C',15,0,0,'G','','MV_PAR01','','','','','','','','','','','','','','','','','','','','','','','','','SB1','','','','',''} )
	aAdd( aDados, {cPerg,'02','Material Até ?',       '','','MV_CH0','C',15,0,0,'G','','MV_PAR02','','','','ZZZZZZZZZZZZZZZ','','','','','','','','','','','','','','','','','','','','','SB1','','','','',''} )
	aAdd( aDados, {cPerg,'03','Lote De ?',            '','','MV_CH0','C',10,0,0,'G','','MV_PAR03','','','','','','','','','','','','','','','','','','','','','','','','','','','','','',''} )
	aAdd( aDados, {cPerg,'04','Lote Ate ?',           '','','MV_CH0','C',10,0,0,'G','','MV_PAR04','','','','ZZZZZZZZZZ','','','','','','','','','','','','','','','','','','','','','','','','','',''} )
	aAdd( aDados, {cPerg,'05','SubLote De ?',         '','','MV_CH0','C',06,0,0,'G','','MV_PAR05','','','','','','','','','','','','','','','','','','','','','','','','','','','','','',''} )
	aAdd( aDados, {cPerg,'06','SubLote Ate ?',        '','','MV_CH0','C',06,0,0,'G','','MV_PAR06','','','','ZZZZZZ','','','','','','','','','','','','','','','','','','','','','','','','','',''} )
	aAdd( aDados, {cPerg,'07','Direção da Seta ?',    '','','MV_CH0','C',01,0,0,'C','','MV_PAR07','Automático','','','','','Para Cima','','','','','Para Baixo','','','','','','','','','','','','','','','','','','',''} )	
	//aAdd( aDados, {cPerg,'07','Somente com Saldo',    '','','MV_CH0','N',01,0,0,'C','','MV_PAR08','Sim','','','','','Não','','','','','','','','','','','','','','','','','','','','','','','',''} )

	U_AtuSx1(aDados)	

Return Nil
