#include "rwmake.ch"
#include "TOPCONN.CH"
#Include 'Protheus.ch'

/*                                          
Programa ...: F040CPO.Prw
Uso ........: Ponto de Entrada (ALTERACAO DO CR)
Data .......: 17/11/19
Feito por ..: Bruno Lage Ferreira.
*/

User function F040CPO()
/*******************************************************************************
*
*
*
****/
//Estrutura do aCpos original da rotina,
//contendo os campos que foram definidos
//para serem edit�veis na altera��o do t�tulo
Local aAux := aClone( ParamIxb )

//Array para retorno dos campos que poder�o ser editados
//na altera��o de um t�tulo a receber
Local aRet := {}

aAdd( aAux, 'E1_VEND1' )
aRet := aClone( aAux )

Return(aRet)