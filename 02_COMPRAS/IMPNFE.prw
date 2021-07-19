#INCLUDE "RWMAKE.CH"

User Function IMPNFE()

	Local aAreaSE1:=SE1->(GetArea())


	Local lRet := .F.
	Private dDtCusto := CtoD('')                

	/*
	**************************************************************************************
	* P.E.p/ grav.dos campos: SF1->F1_OBSERV, F1_PESOLIQ,F1_PESOBRU,F1_VOLUME E F1_ESPECIE
	**************************************************************************************


	@ 100,000 TO 400,500 DIALOG oDlg1 TITLE "Dados adicionais para Nota Fiscal de Entrada"

	@ 008,010 SAY "Data Referência Para Custo" SIZE 100,30
	@ 035,010 SAY "Data Custo:" SIZE 100,30


	@ 035,055 GET dDtCusto Picture "99/99/9999" SIZE 070,30

	@ 135,160 BUTTON "_Ok " SIZE 35,15 ACTION Processa({|| Grava()},,"Gravando....")
	@ 135,210 BUTTON "_Sair" SIZE 35,15 ACTION Close(oDlg1)

	ACTIVATE DIALOG oDlg1 CENTERED
	*/ 
Return(.T.)

/*
*********************************
* FUNÇÃO PARA GRAVAÇÃO DOS DADOS
*********************************
*/

Static Function Grava()


	SF1->F1_DTCUSTO	:= dDtCusto

	Close(oDlg1)

Return