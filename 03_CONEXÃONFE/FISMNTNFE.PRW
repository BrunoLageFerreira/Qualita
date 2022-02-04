#include "rwmake.ch"

// ############################################################################################
// Projeto: 
// Modulo : Faturamento
// Fonte  : FISMNTNFE
// ---------+----------------------+-----------------------------------------------------------
// Data     | Autor                | Descricao
// ---------+----------------------+-----------------------------------------------------------
// 19/08/16 | Evaldo Cevinscki Jr. | P.E. para disparar o envio das nfes para conexão nfe
// ---------+----------------------+-----------------------------------------------------------
User Function FISMNTNFE()
	Local aArea := GetArea()
	Local cIdNfe	:= PARAMIXB[1]
	Local aNfeInf	:= PARAMIXB[2]
	Local cCodRetNfe:= aNfeInf[1][9]                     			

	If cCodRetNfe  == "100"
		//U_GATI007()
	Endif

	RestArea(aArea)

Return 
