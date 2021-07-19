#INCLUDE "RWMAKE.CH"

USER FUNCTION MT103NFE()


	Local lRet := .F.
	Private dDtCusto := CtoD('')

	/*
	**************************************************************************************
	* P.E.p/ grav.dos campos: SF1->F1_OBSERV, F1_PESOLIQ,F1_PESOBRU,F1_VOLUME E F1_ESPECIE
	**************************************************************************************


	dDtCusto := M->DdEmissao
	@ 100,000 TO 200,500 DIALOG oDlg1 TITLE "Dados adicionais para Nota Fiscal de Entrada"

	@ 010,010 SAY "Data Refer�ncia Para Custo" SIZE 100,30
	@ 020,010 SAY "Data Custo:" SIZE 100,30


	@ 020,055 GET dDtCusto Picture "99/99/9999" SIZE 070,30

	@ 35,100 BUTTON "_Ok " SIZE 35,15 ACTION Processa({|| Grava()},,"Gravando....")

	ACTIVATE DIALOG oDlg1 CENTERED

	*/
Return(.T.)

/*
*********************************
* FUN��O PARA GRAVA��O DOS DADOS
*********************************
*/

Static Function Grava()
	//DbSelectArea("SF1")
	//DbSetOrder(1)
	Reclock("SF1",.F.)
	SF1->F1_DTCUSTO := dDtCusto
	SF1->F1_EMINFE := dDtCusto
	//Msunlock()
	Close(oDlg1)

Return