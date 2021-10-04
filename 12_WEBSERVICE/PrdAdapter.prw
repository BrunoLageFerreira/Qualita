#include 'totvs.ch'
#include 'parmtype.ch'


//-------------------------------------------------------------------
// temporario fls
/*/{Protheus.doc} PrdAdapter
Classe Adapter para o serviço
@since   25/04/2019
@version 1.0
/*/
//-------------------------------------------------------------------
CLASS PrdAdapter FROM FWAdapterBaseV2
	METHOD New()
	METHOD GetListProd()
EndClass
//-------------------------------------------------------------------
/*/{Protheus.doc} New
Método construtor
@param cVerb, verbo HTTP utilizado
@author  Anderson Toledo
@since   25/04/2019
@version 1.0
/*/
//-------------------------------------------------------------------
Method New( cVerb ) CLASS PrdAdapter
	_Super:New( cVerb, .T. )
return
//-------------------------------------------------------------------
/*/{Protheus.doc} GetListProd
Método que retorna uma lista de produtos 
@author  Anderson Toledo
@since   25/04/2019
@version 1.0
/*/
//-------------------------------------------------------------------
//Method GetListProd( ) CLASS PrdAdapter

//-------------------------------------------------------------------
/*/{Protheus.doc} AddMapFields
Função para geração do mapa de campos
@param oSelf, object, Objeto da prórpia classe
@author  Anderson Toledo
@since   25/04/2019
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function AddMapFields( oSelf )
	
	oSelf:AddMapFields( 'CODE'              , 'B1_COD'  , .T., .T., { 'B1_COD', 'C', TamSX3( 'B1_COD' )[1], 0 } )
	oSelf:AddMapFields( 'DESCRIPTION'	    , 'B1_DESC' , .T., .F., { 'B1_DESC', 'C', TamSX3( 'B1_DESC' )[1], 0 } )	
	oSelf:AddMapFields( 'GROUP'		        , 'B1_GRUPO', .T., .F., { 'B1_GRUPO', 'C', TamSX3( 'B1_GRUPO' )[1], 0 } )
	//oSelf:AddMapFields( 'GROUPDESCRIPTION'	, 'BM_DESC' , .T., .F., { 'BM_DESC', 'C', TamSX3( 'BM_DESC' )[1], 0 } )
Return 
//-------------------------------------------------------------------
/*/{Protheus.doc} GetQuery
Retorna a query usada no serviço
@param oSelf, object, Objeto da prórpia classe
@author  Anderson Toledo
@since   25/04/2019
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function GetQuery()
	Local cQuery AS CHARACTER
	
	//Obtem a ordem informada na requisição, a query exterior SEMPRE deve ter o id #QueryFields# ao invés dos campos fixos
	//necessáriamente não precisa ser uma subquery, desde que não contenha agregadores no retorno ( SUM, MAX... )
	//o id #QueryWhere# é onde será inserido o clausula Where informado no método SetWhere()
	cQuery := " SELECT #QueryFields#"
   // cQuery := " SELECT B1_COD, B1_DESC, B1_GRUPO "
    cQuery +=   " FROM " + RetSqlName( 'SB1' ) + " SB1 "
    //cQuery +=   " LEFT JOIN " + RetSqlName( 'SBM' ) + " SBM"
	//cQuery +=       " ON B1_GRUPO = BM_GRUPO"
	//cQuery +=           " AND BM_FILIAL = '"+ FWxFilial( 'SBM' ) +"'"
	//cQuery +=           " AND SBM.D_E_L_E_T_ = ' '"
    //cQuery += " WHERE #QueryWhere#"
	
Return cQuery
