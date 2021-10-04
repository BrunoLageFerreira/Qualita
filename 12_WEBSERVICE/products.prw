#INCLUDE "PROTHEUS.CH"
#INCLUDE "RESTFUL.CH"
#include "rwmake.ch"
#include "tbiconn.ch"
#INCLUDE "TOPCONN.CH"

//-------------------------------------------------------------------
// temporario fls
/*/{Protheus.doc} products
Declaração do ws producs
@since 25/04/2019
@version 1.0
/*/
//-------------------------------------------------------------------
WSRESTFUL products DESCRIPTION 'endpoint products API' //FORMAT "application/json,text/html"
    WSDATA Page     AS INTEGER OPTIONAL
    
 	//WSMETHOD GET GetListProd DESCRIPTION "Retorna uma lista de produtos" WSSYNTAX "/api/v3/products"  PRODUCES APPLICATION_JSON //; //WSSYNTAX "/rest/products" ;
    WSMETHOD GET GetTeste    DESCRIPTION "Retorna um teste"              WSSYNTAX "/api/v3/Prdteste"  PRODUCES APPLICATION_JSON //; //WSSYNTAX "/rest/products" ;

        //PATH "/rest/products" ;//PATH "/api/v1/products" ;
END WSRESTFUL
***********************************************************************************************************************

WsMethod GET WsService products
 Local cUser := ''
 Local nUser

::SetContentType( 'application/json' )

@{Route}
 @{When '/users'}
 cUser := '['
 For nUser := 1 to Len(aUsers)
 cUser += '{"id":'+ aUsers[nUser][1]+;
 ',"name":"'+aUsers[nUser][2]+;
 '","age":'+aUsers[nUser][3]+'}'
 cUser += if(nUser < Len(aUsers),',','')
 Next nUser
 cUser += ']'
 ::SetResponse(cUser)
 @{When '/users/{id}'}
 nUser := aScan(aUsers,{|x| x[1] == @{Param 2} })
 If nUser > 0
 cUser := '{"id":'+ aUsers[nUser][1]+;
 ',"name":"'+aUsers[nUser][2]+;
 '","age":'+aUsers[nUser][3]+'}'
 ::SetResponse(cUser)
 Else
 SetRestFault(400,'Ops')
 Return .F.
 EndIf
 @{Default}
 SetRestFault(400,"Ops")
 Return .F. 
 @{EndRoute}

Return .T.




***********************************************************************************************************************
WSMETHOD GET GetListProd WSRECEIVE  page, pageSize WSREST products
Local cQrySB1       := GetNextAlias()
Local nRecord       := 0
Local aRegProdut    := {}
Local cJsonProd     := ""

Local lRet := .T.

Local oJsonProd     := JsonObject():New()
Default self:page := 1
Default self:pageSize := 0

/*
Query 
*/
cQuery := "SELECT B1_COD,B1_DESC,B1_GRUPO FROM SB1010 WHERE D_E_L_E_T_ = ''
TcQuery cQuery Alias cQrySB1 New
dbSelectArea("cQrySB1")
	
If ( cQrySB1 )->( ! Eof() )
	COUNT TO nRecord

	(cQrySB1)->( DBGoTop() )

	oJsonSales['hasNext'] := .T.
	self:pageSize := 10

	While (cQrySB1)->(!Eof())

		aAdd( aRegProdut , JsonObject():New() )
        nPos := Len(aRegProdut)

		aRegProdut[nPos]['CODIGO']      := TRIM((cQrySB1)->B1_COD)
        aRegProdut[nPos]['DESCRICAO']   := TRIM((cQrySB1)->B1_DESC)
        aRegProdut[nPos]['GRUPO']       := TRIM((cQrySB1)->B1_GRUPO)
        
		(cQrySB1)->(DBSkip())
	EndDo

(cQrySB1)->( DBCloseArea() )

ENDIF

oJsonSales['PRODUTOS'] := aRegProdut

//-------------------------------------------------------------------
// Serializa objeto Json
//-------------------------------------------------------------------
cJsonProd:= FwJsonSerialize( oJsonProd )

//-------------------------------------------------------------------
// Elimina objeto da memoria
//-------------------------------------------------------------------
FreeObj(oJsonProd)

Self:SetResponse( cJsonProd ) //-- Seta resposta

RETURN(lRet)




//-------------------------------------------------------------------
/*/{Protheus.doc} GET ProdList
Método GET com id ProdList
@author Anderson Toledo
@since 25/04/2019
@version 1.0
/*/
//-------------------------------------------------------------------
//WSMETHOD GET ProdList WSREST products
//Return getPrdList(self)
//-------------------------------------------------------------------
/*/{Protheus.doc} GET getPrdList
Função para tratamento da requisição GET
@author Anderson Toledo
@since 25/04/2019
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function getPrdList( oWS )
   Local lRet  as logical
   Local oProd as object
   DEFAULT oWS:Page      := 1  
   lRet        := .T.
   //PrdAdapter será nossa classe que implementa fornecer os dados para o WS
   // O primeiro parametro indica que iremos tratar o método GET
   oProd := PrdAdapter():new( 'GET' )
  
   //o método setPage indica qual página deveremos retornar
   //ex.: nossa consulta tem como resultado 100 produtos, e retornamos sempre uma listagem de 10 itens por página.
   // a página 1 retorna os itens de 1 a 10
   // a página 2 retorna os itens de 11 a 20
   // e assim até chegar ao final de nossa listagem de 100 produtos 
   //oProd:setPage(oWS:Page)
   // setPageSize indica que nossa página terá no máximo 10 itens
   //oProd:setPageSize(10)
   // Esse método irá processar as informações
   oProd:GetListProd()
   //Se tudo ocorreu bem, retorna os dados via Json
   If oProd:lOk
       oWS:SetResponse(oProd:getJSONResponse())
   Else
   //Ou retorna o erro encontrado durante o processamento
       SetRestFault(oProd:GetCode(),oProd:GetMessage())
       lRet := .F.
   EndIf
   //faz a desalocação de objetos e arrays utilizados
   oProd:DeActivate()
   oProd := nil
   
Return lRet
