#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
#INCLUDE "TOPCONN.CH"

/*
Ponto de entrada que permite alterar o conteúdo da
consulta SQL do fonte GROA002.PRW
*/
USER FUNCTION GR37ACPO()
************************************************************************************************
*
*	//Funcao especifica GR PLUS GR37ACPO
*
***

    Local cCampo    := paramixb[1] // Campo que esta posicionado
    Local lret      := paramixb[2] // retorno

    Local cEdittt   := "B8_XENDERE|B8_YDEFOBS" // aqui incluir os campos customizados, campo B8_YDEFOBS e um campo de exemplo

    //validando o campo .t. o campo aparece, .f. o campo não aparece
    If AllTrim(cCampo) $ cEdittt
		lRet := .T.
	EndIf

RETURN lret
