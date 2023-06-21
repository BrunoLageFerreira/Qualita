#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
#INCLUDE "topconn.ch"          

/*
Programa ...: FA040INC
Uso ........: INCLUSAO DO TITULO A RECEBER
Data .......: 23-11-2020
Feito por ..: Bruno Lage Ferreira
Copyright @1998-2001,2020
*/
 
User Function FA040INC()
/*********************************************************************************************************
*
*
****/
Local aArea    := GetArea()
Local lRet     := .T.
Local nValAbat := M->E1_VALOR

/*
INCLUSAO DO AB-
*/ 
IF M->E1_TIPO == "AB-"

    M->E1_NATUREZ := "1.2.11.03"

	dbSelectArea("SE1")
    dbSetOrder(2)
    IF dbSeek(SE1->E1_FILIAL + SE1->E1_CLIENTE + SE1->E1_LOJA + SE1->E1_PREFIXO + SE1->E1_NUM + SE1->E1_PARCELA )
        SE1->(RecLock("SE1",.F.))
            E1_XVLABAT := Round(SE1->E1_TXMOEDA * nValAbat,2)
			E1_XSEQABA := ""
			//E1_NATUREZ := "1.2.11.03"
        SE1->(MsUnlock()) 
    EndIf
EndIf

If !Alltrim(FUNNAME()) $ "FINA460/FINA630"  
	If EMPTY(M->E1_HIST)
		lRet  := .F.
	    MsgInfo("Campo histórico do título em branco!", "Atenção")
	EndIf
EndIf
 
RestArea(aArea)

Return(lRet)


User Function FA040ALT()
/*********************************************************************************************************
*
*
****/
Local aArea    := GetArea()
Local lRet     := .T.

Local nValAbat := M->E1_VALOR

/*
Alteraçao DO AB-
*/ 
dbSelectArea("SE1")
dbSetOrder(2)
IF dbSeek(SE1->E1_FILIAL + SE1->E1_CLIENTE + SE1->E1_LOJA + SE1->E1_PREFIXO + SE1->E1_NUM + SE1->E1_PARCELA )
	Do while !EOF() .And. (;
							SE1->E1_FILIAL + SE1->E1_CLIENTE + SE1->E1_LOJA + SE1->E1_PREFIXO + SE1->E1_NUM + SE1->E1_PARCELA;
							== ;
							m->E1_FILIAL   + m->E1_CLIENTE   + m->E1_LOJA   + m->E1_PREFIXO   + m->E1_NUM   + m->E1_PARCELA ;
						  )

		if SE1->E1_TIPO <> "AB-"
			SE1->(RecLock("SE1",.F.))
				E1_XVLABAT := Round(SE1->E1_TXMOEDA * nValAbat,2)
				E1_XSEQABA := ""
			SE1->(MsUnlock()) 
		EndIf

		dbSelectArea("SE1")
		dbSkip()
	EndDo
EndIf

If !Alltrim(FUNNAME()) $ "FINA460/FINA630" 
	If EMPTY(M->E1_HIST)
		lRet  := .F.
	    MsgInfo("Campo histórico do título em branco!", "Atenção")
	EndIf
EndIf
 
RestArea(aArea)

Return(lRet)


