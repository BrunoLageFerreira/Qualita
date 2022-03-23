#INCLUDE "PROTHEUS.CH"
#INCLUDE "RESTFUL.CH"
#include "rwmake.ch"
#include "tbiconn.ch"
#INCLUDE "TOPCONN.CH"

WSRESTFUL WSRESTA1 DESCRIPTION "Exemplo de serviço REST"
 
 WSDATA page AS INTEGER OPTIONAL
 WSDATA pageSize AS INTEGER OPTIONAL
 WSDATA searchKey AS STRING OPTIONAL
 
 WSMETHOD GET customers DESCRIPTION "Retorna lista de clientes" WSSYNTAX "/customers " PATH 'customers' PRODUCES APPLICATION_JSON

END WSRESTFUL

//-------------------------------------------------------------------
/*/{Protheus.doc} GET / customers
Retorna a lista de clientes.

@param SearchKey , caracter, chave de pesquisa utilizada em diversos campos
 Page , numerico, numero da pagina 
 PageSize , numerico, quantidade de registros por pagina

@return cResponse , caracter, JSON contendo a lista de clientes
/*/
//-------------------------------------------------------------------

WSMETHOD GET customers WSRECEIVE searchKey, page, pageSize WSREST WSRESTA1
 
 Local aListCli := {}
 
 Local cAliasSA1 := GetNextAlias()
 Local cJsonCli := ''
 Local cSearchKey := ''
 Local cSearch := ''
 Local cWhere := "AND SA1.A1_FILIAL = '"+xFilial('SA1')+"'"
 
 Local lRet := .T.
 
 Local nCount := 0
 Local nStart := 1
 Local nReg := 0
 Local nAux := 0
 
 Local oJsonCli := JsonObject():New() 
 
 Default self:searchKey := ''
 Default self:page := 1
 Default self:pageSize := 10 

conout("Bruno")
 conout(Self:SearchKey)
 
 //-------------------------------------------------------------------
 // Tratativas para a chave de busca
 //-------------------------------------------------------------------

/*
EXEMPLO PAGINAÇÃO PELO SQL
DECLARE @PageNumber AS INT, 
        @RowspPage  AS INT,
		@RowsCount  AS INT

SET @PageNumber = 274
SET @RowspPage  = 100

SELECT * 
       ,IIF(ROUND(CAST(CAST(REC_TOTAL AS numeric(18,2)) / CAST(@RowspPage AS numeric(18,2)) AS numeric(18,2)),2)>@PageNumber,'S','N')PAG_NEXT
  FROM (
		SELECT (SELECT COUNT(*) FROM SC6010 WHERE D_E_L_E_T_ = '' ) REC_TOTAL,
			   ROW_NUMBER() OVER(ORDER BY C6_NUM) AS REC_ATU,
			   C6_CLI+C6_LOJA CLIENTE, 
			   C6_NUM, 
			   C6_PRODUTO
		 FROM SC6010 NOLOCK
		WHERE D_E_L_E_T_ = ''
		)#TB_A

 ORDER BY ROW_NUMBER() OVER(ORDER BY C6_NUM)
   OFFSET     ((@PageNumber - 1) * @RowspPage) ROWS 
   FETCH NEXT   @RowspPage                     ROWS ONLY

*/



 If !Empty(self:searchKey)
 cSearch := AllTrim( Upper( Self:SearchKey ) )
 cWhere += " AND ( SA1.A1_COD LIKE '%" + cSearch + "%' OR "
 cWhere += " SA1.A1_LOJA LIKE '%" + cSearch + "%' OR "
 cWhere += " SA1.A1_NOME LIKE '%" + FwNoAccent( cSearch ) + "%' OR "
 cWhere += " SA1.A1_NOME LIKE '%" + cSearch + "%' ) " 
 EndIf
 
 cWhere := '%'+cWhere+'%'
 

 //-------------------------------------------------------------------
 // Query para selecionar clientes
 //-------------------------------------------------------------------
 BEGINSQL Alias cAliasSA1
 
 SELECT SA1.A1_COD, SA1.A1_LOJA, SA1.A1_NOME
 FROM %table:SA1% SA1
 WHERE SA1.%NotDel%
 %exp:cWhere%
 
 ENDSQL
 
 If ( cAliasSA1 )->( ! Eof() )
 
 //-------------------------------------------------------------------
 // Identifica a quantidade de registro no alias temporário
 //-------------------------------------------------------------------
 COUNT TO nRecord
 
 //-------------------------------------------------------------------
 // nStart -> primeiro registro da pagina
 // nReg -> numero de registros do inicio da pagina ao fim do arquivo
 //-------------------------------------------------------------------
 If self:page > 1
 nStart := ( ( self:page - 1 ) * self:pageSize ) + 1
 nReg := nRecord - nStart + 1
 Else
 nReg := nRecord
 EndIf
 
 //-------------------------------------------------------------------
 // Posiciona no primeiro registro.
 //-------------------------------------------------------------------
 ( cAliasSA1 )->( DBGoTop() )
 
 //-------------------------------------------------------------------
 // Valida a exitencia de mais paginas
 //-------------------------------------------------------------------
 If nReg > self:pageSize
 oJsonCli['hasNext'] := .T.
 Else
 oJsonCli['hasNext'] := .F.
 EndIf
 Else
 //-------------------------------------------------------------------
 // Nao encontrou registros
 //-------------------------------------------------------------------
 oJsonCli['hasNext'] := .F.
 EndIf
 
 //-------------------------------------------------------------------
 // Alimenta array de clientes
 //-------------------------------------------------------------------
 While ( cAliasSA1 )->( ! Eof() ) 
 
 nCount++
 
 If nCount >= nStart
 
 nAux++ 
 aAdd( aListCli , JsonObject():New() )
 
 aListCli[nAux]['id'] := ( cAliasSA1 )->A1_COD
 aListCli[nAux]['name'] := Alltrim( EncodeUTF8( ( cAliasSA1 )->A1_NOME ) )
 aListCli[nAux]['unit'] := ( cAliasSA1 )->A1_LOJA
 
 If Len(aListCli) >= self:pageSize
 Exit
 EndIf
 
 EndIf
 
 ( cAliasSA1 )->( DBSkip() )
 
 End
 
 ( cAliasSA1 )->( DBCloseArea() )
 
 oJsonCli['clients'] := aListCli
 
 //-------------------------------------------------------------------
 // Serializa objeto Json
 //-------------------------------------------------------------------
 cJsonCli:= FwJsonSerialize( oJsonCli )
 
 //-------------------------------------------------------------------
 // Elimina objeto da memoria
 //-------------------------------------------------------------------
 FreeObj(oJsonCli)

Self:SetResponse( cJsonCli ) //-- Seta resposta

Return( lRet )
