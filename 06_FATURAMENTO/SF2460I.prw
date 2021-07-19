#include "rwmake.ch"
#include "TOPCONN.CH"

/*                                          
Programa ...: SF2460I.Prw
Uso ........: Ponto de Entrada (Geracao da NF Saída)
Data .......: 25/07/16
Feito por ..: Bruno Lage Ferreira.
*/

User Function SF2460I()
	*************************************************************************************************************
	*
	*
	***
	Local _cAlias := GetArea()

	ConOut("******************************************" )
	ConOut("Inicio P.E = SF2460I " )
	ConOut("******************************************" )

	/*
	dbSelectArea("SC6")
	dbSetOrder(4)
	dbSeek(xFilial("SC6") + SF2->F2_Doc + SF2->F2_Serie)

	While (! Eof()) .And. ;
	(SC6->C6_Filial == xFilial("SC6")) .And. ;
	(SC6->C6_Nota   == SF2->F2_Doc)    .And. ;
	(SC6->C6_Serie  == SF2->F2_Serie)

	dbSelectArea("SD2")
	dbSetOrder(3) //D2_FILIAL, D2_DOC, D2_SERIE, D2_CLIENTE, D2_LOJA, D2_COD, D2_ITEM
	If dbSeek(SC6->C6_FILIAL + SC6->C6_NOTA +SC6->C6_SERIE + SC6->C6_CLIENTE + SC6->C6_LOJA + SC6->C6_PRODUTO )
	dbSelectArea("SD2")   

	ConOut(" - Gravando: " + SC6->C6_PRODUTO )

	RecLock("SD2",.F.)
	Replace SD2->D2_QTDBLOC WITH SC6->C6_QTDBLOC
	MSUnLock()		
	EndIf   

	dbSelectArea("SC6")
	dbSkip()
	EndDo      
	*/     

	RestArea(_cAlias)

	ConOut("******************************************" )
	ConOut("Final P.E = SF2460I ")
	ConOut("******************************************" )

Return()