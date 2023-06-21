#Include "Protheus.ch"

/*/{Protheus.doc} M145ARDEL
// Ponto de entrada utilizado pelo importador da ConexãoNF-e para retornar a situação do XML para não
importado após a exclusão do aviso de recebimento
@author ConexãoNF-e
@since 11/07/2022
@version 1.0
@return Nil, Nulo
@see (https://atendimento.conexaonfe.com.br/kb/)
/*/
User Function M145ARDEL()
Local lRet := .T.

    // Ponto de chamada ConexãoNF-e sempre como primeira instrução 
    lRet := U_GTPE018()

    //If
    //    Regra existente
    //    [...]
    //EndIf

Return lRet
