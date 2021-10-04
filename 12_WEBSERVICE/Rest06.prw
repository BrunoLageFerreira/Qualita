#INCLUDE "PROTHEUS.CH"
#INCLUDE "RESTFUL.CH"
#include "rwmake.ch"
#include "tbiconn.ch"
#INCLUDE "TOPCONN.CH"


/*/{Protheus.doc} User Function SalesOrder
    (Api REST para consulta de pedidos de venda)
    @type  Function
    @author Leandro Lemos
    @since 08/05/2020
    @version P12 
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    (examples)
    @see (links_or_references)
    https://tdn.totvs.com/pages/releaseview.action?pageId=6784012

Data        Analista        Alteração
20/092020   Leandro Lemos   POST - Alterado tratamento do retorno de erros, removido tratamento para numeração dos pedidos, 
                            o campo C5_NUM ja tem GETSXENUM() no iniciador 
                            Adicionado verbo PUT

https://erplabs.com.br/api-rest-no-protheus-03-verbo-post-e-put-api-de-pedido-de-venda/
  
  exemplo get:
                            http://192.168.1.40:8086/rest/api/v3/salesorder2?cSalesOrder=016850

 exmEplo PUT E POST:
 Os testes foram realizados pelo PostMan, basta adicionar o Json abaixo na aba Body e marcar “raw”,
  a diferença da estrutura de POST para PUT é o campo NUM que deve ser informado no Header. Ex.: “NUM”:”000001?,

{   
    "CLIENTE":"000011",
    "LOJACLI":"1",
    "CONDPAG":"030",
    "TPFRETE":"R",
    "MENNOTA":"Mensagem para nota",
    "NATUREZ":"10101001",
    "TIPO":"B",
    "Items":
    [
      {
        "ITEM":"01",
        "PRODUTO":"CHAV00310",
        "QTDVEN":1,
        "PRCVEN":100,
        "VALOR":100,
        "TES":"5R2",
        "CONTA":"",
        "CC":"2M01N010105346",
        "PROJPMS":"",
        "REVISAO":"",
        "TASKPMS":""
      },
      {
        "ITEM":"02",
        "PRODUTO":"CHAV00055",
        "QTDVEN":1,
        "PRCVEN":100,
        "VALOR":100,
        "TES":"5R2",
        "CONTA":"",
        "CC":"2M01N010105346",
        "PROJPMS":"",
        "REVISAO":"",
        "TASKPMS":""
 
      }
    ]
}


TESTE OTAWA
EM http://192.168.1.46:8086/rest/api/v3/salesorder2?cSalesOrder=016850
/*/

WSRESTFUL SalesOrder2 DESCRIPTION "Api REST para consulta de pedidos de venda"

    WSDATA page        AS INTEGER OPTIONAL
    WSDATA pageSize    AS INTEGER OPTIONAL
    WSDATA cSalesOrder AS STRING  OPTIONAL
    //WSDATA cSearchKey AS STRING OPTIONAL

    WSMETHOD GET  salesOrder     DESCRIPTION 'Consulta pedidos de venda'    WSSYNTAX '/api/v3/salesorder2' PRODUCES APPLICATION_JSON
    WSMETHOD POST incSalesOrder  DESCRIPTION 'Submete pedidos de venda'     WSSYNTAX '/api/v3/salesorder2' PRODUCES APPLICATION_JSON
    WSMETHOD PUT  editSalesOrder DESCRIPTION 'Edita pedidos de venda'       WSSYNTAX '/api/v3/salesorder2' PRODUCES APPLICATION_JSON
END WSRESTFUL

//-------------------------------------------------------------------
/*/{Protheus.doc} GET / salesorder
Retorna a lista de pedidos.

@param cSearchKey , caracter, chave de pesquisa utilizada em diversos campos
 Page , numerico, numero da pagina 
 PageSize , numerico, quantidade de registros por pagina

@return cResponse , caracter, JSON contendo a lista de pedidos
/*/
//-------------------------------------------------------------------

WSMETHOD GET salesOrder WSRECEIVE cSalesOrder, page, pageSize WSREST SalesOrder2

Local aListSales := {}
Local aLast := {}

Local cQrySC5       := GetNextAlias()
Local cJsonCli      := ''
Local cSalesOrder   := ''
Local cSearch       := ''
Local cWhere        := "  AND SC5.C5_FILIAL = '"+xFilial('SC5')+"' AND SC6.C6_FILIAL = '"+xFilial('SC6')+"'"
Local cPedido       := ''


Local lRet := .T.

Local nCount := 0
Local nStart := 1
Local nReg := 0



Local oJsonSales := JsonObject():New()


Default self:cSalesOrder  := ''
Default self:page := 1
Default self:pageSize := 100

//-------------------------------------------------------------------
// Tratativas para a chave de busca
//Existem outras maneira de trabalhar com filtro, por hora vou manter dessa forma
//-------------------------------------------------------------------

If !Empty(self:cSalesOrder)
    cSearch := AllTrim( Upper( Self:cSalesOrder ) )
    cWhere += " AND ( SC5.C5_NUM = " + cSearch + ")
EndIf

cWhere := '%'+cWhere+'%'

//-------------------------------------------------------------------
// Query para selecionar pedidos
//-------------------------------------------------------------------

BeginSQL Alias cQrySC5
SELECT SC5.C5_CLIENTE,SC5.C5_LOJACLI,SC5.C5_CONDPAG,SC5.C5_TPFRETE,SC5.C5_MENNOTA,SC5.C5_NATUREZ,SC5.R_E_C_N_O_ C5_RECNO,
SC5.C5_FILIAL ,SC5.C5_NUM,SC5.C5_LIBEROK,SC5.C5_NOTA,SC5.C5_BLQ, 
C6_NUM,C6_ITEM,C6_PRODUTO,C6_DESCRI,C6_PRCVEN,C6_QTDVEN,C6_VALOR,C6_LOTECTL,C6_NUMLOTE,C6_TES,C6_NOTA,C6_SERIE,SC6.C6_CONTA,SC6.C6_CC,SC6.C6_PROJPMS,SC6.R_E_C_N_O_ C6_RECNO
FROM %Table:SC5% SC5
INNER JOIN %Table:SC6% SC6 ON SC5.C5_NUM = SC6.C6_NUM
WHERE SC5.%NotDel%
AND SC6.%NotDel%
%exp:cWhere%
ORDER BY SC5.C5_NUM,SC6.C6_ITEM
EndSQL

//conout(cQrySC5)

If ( cQrySC5 )->( ! Eof() )

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
    ( cQrySC5 )->( DBGoTop() )

    //-------------------------------------------------------------------
    // Valida a exitencia de mais paginas
    //-------------------------------------------------------------------
    If nReg > self:pageSize
        oJsonSales['hasNext'] := .T.
    Else
        oJsonSales['hasNext'] := .F.
    EndIf
Else
    //-------------------------------------------------------------------
    // Nao encontrou registros
    //-------------------------------------------------------------------
    oJsonSales['hasNext'] := .F.
EndIf


//-------------------------------------------------------------------
// Alimenta array de pedidos
//-------------------------------------------------------------------
While ( cQrySC5 )->( ! Eof() )
    cPedido := ''
    cPedido := (cQrySC5)->C5_NUM

    nCount++

    If nCount >= nStart

        aAdd( aListSales , JsonObject():New() )
        nPos := Len(aListSales)
        aListSales[nPos]['NUM']       := (cQrySC5)->C5_NUM
        aListSales[nPos]['CLIENTE']   := TRIM((cQrySC5)->C5_CLIENTE)
        aListSales[nPos]['LOJACLI']   := TRIM((cQrySC5)->C5_LOJACLI)
        aListSales[nPos]['CONDPAG']   := TRIM((cQrySC5)->C5_CONDPAG)
        aListSales[nPos]['TPFRETE']   := TRIM((cQrySC5)->C5_TPFRETE)
        aListSales[nPos]['MENNOTA']   := TRIM(EncodeUTF8((cQrySC5)->C5_MENNOTA))
        aListSales[nPos]['NATUREZ']   := TRIM((cQrySC5)->C5_NATUREZ)
        aListSales[nPos]['RECNO']     := cValtoChar((cQrySC5)->C5_RECNO)

        While (cPedido == (cQrySC5)->C5_NUM)
            Aadd(aLast,JsonObject():new())
            nPosItem := Len(aLast)
            aLast[nPosItem]['NUM']      := (cQrySC5)->C5_NUM
            aLast[nPosItem]['ITEM']     := (cQrySC5)->C6_ITEM
            aLast[nPosItem]['PRODUT']   := TRIM((cQrySC5)->C6_PRODUTO)
            
            aLast[nPosItem]['LOTECTL']   := TRIM((cQrySC5)->C6_LOTECTL)
            aLast[nPosItem]['NUMLOTE']   := TRIM((cQrySC5)->C6_NUMLOTE)

            aLast[nPosItem]['DESCRI']   := TRIM(EncodeUTF8(((cQrySC5)->C6_DESCRI)))
            aLast[nPosItem]['QTDVEN']   := (cQrySC5)->C6_QTDVEN
            aLast[nPosItem]['PRCVEN']   := (cQrySC5)->C6_PRCVEN
            aLast[nPosItem]['VALOR']    := (cQrySC5)->C6_VALOR
            aLast[nPosItem]['TES']      := TRIM((cQrySC5)->C6_TES)
            aLast[nPosItem]['NOTA']     := TRIM((cQrySC5)->C6_NOTA)
            aLast[nPosItem]['SERIE']    := TRIM((cQrySC5)->C6_SERIE)
            aLast[nPosItem]['CONTA']    := TRIM((cQrySC5)->C6_CONTA)
            aLast[nPosItem]['CC']       := TRIM((cQrySC5)->C6_CC)
            aLast[nPosItem]['PROJPMS']  := TRIM((cQrySC5)->C6_PROJPMS)
            aLast[nPosItem]['RECNO']    := cValtoChar((cQrySC5)->C6_RECNO)
            (cQrySC5)->(DBSkip())
        End
        //Adiciono o Iten na ultima posição do array aListSales, em seguida limpo array temporario de itens
        aListSales[Len(aListSales)]['SALESITENS'] := aLast
        aLast := {}

        If Len(aListSales) >= self:pageSize
            Exit
        EndIf
        //Se estiver buscando por paginas, sera skipado os registros até iniciar a pagina passada pelo parâmetro Page
    Else
        (cQrySC5)->(DBSkip())
    EndIf

End

( cQrySC5 )->( DBCloseArea() )

oJsonSales['SALES'] := aListSales

//-------------------------------------------------------------------
// Serializa objeto Json
//-------------------------------------------------------------------
cJsonCli:= FwJsonSerialize( oJsonSales )

//-------------------------------------------------------------------
// Elimina objeto da memoria
//-------------------------------------------------------------------
FreeObj(oJsonSales)

Self:SetResponse( cJsonCli ) //-- Seta resposta

Return( lRet )

/*/{Protheus.doc} User Function incSalesOrder
    (Verbo POST para adição de pedidos de venda)
    @type  Function
    @author Leandro Lemos
    @since 20/09/2020
    @version P12
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    (examples)
    @see (links_or_references)

/*/

WSMETHOD POST incSalesOrder WSRECEIVE WSRESTFUL SalesOrder2
Local lRet      := .T.
Local aArea     := GetArea()
Local aCabec
Local aItens    := {}
Local aLinha    := {}
Local oJson
Local oItems
Local cJson     := Self:GetContent()
Local cError    := ''
Local cErrorAuto:= ''
Local nX        := 0
Local cAlias    := ''
Local aLog      := {}
Local nOpc      := 3

// variável de controle interno da rotina automatica que informa se houve erro durante o processamento
Private lMsErroAuto := .F.
// força a gravação das informações de erro em array para manipulação da gravação ao invés de gravar direto no arquivo temporário 
Private lAutoErrNoFile := .T.

//Definindo o conteúdo como JSON, e pegando o content e dando um parse para ver se a estrutura está ok
Self:SetContentType("application/json")
oJson   := JsonObject():New()
cError  := oJson:FromJson(cJson)
//Se tiver algum erro no Parse, encerra a execução
IF .NOT. Empty(cError)
    SetRestFault(500,'Parser Json Error')
    lRet    := .F.
Else

    IF (AllTrim(oJson:GetJsonObject('TIPO')) == 'N')
        cAlias := 'SA1'
    ElseIF (AllTrim(oJson:GetJsonObject('TIPO')) == 'B')
        cAlias := 'SA2'
    Else
        cError := "Tipo de pedido invalido, informe N ou B"
        cJsonRet := '{"RETURN":"FALSE"';
            + ',"MESSAGE":"'  + EncodeUTF8(substring(cError,1,200)) +'"}'

        SetRestFault(500,cJsonRet,.T.,/* nStatus */,/* cDetailMsg */,'erplabs.com.br',/* aDetails */)
        lRet := .F.

        RestArea(aArea)
        Return(lRet)
    EndIF

    //Antes de iniciar é validade se o cliente ou fornecedor existe
    DbSelectArea(cAlias)
    (cAlias)->(dbSetOrder(1))
    IF ((cAlias)->(dbSeek(FWxFilial(cAlias)+PadR(oJson:GetJsonObject('CLIENTE'),TamSX3("A1_COD")[1])+PadR(oJson:GetJsonObject('LOJACLI'),TamSX3("A1_LOJA")[1]))))
        aCabec  := {}
        aItens  := {}

        /*
        N-> Pedidos Normais.
        B-> Apres. Fornec. qdo material p/Benef.
        */
        //Numeração removida para geração automatica da rotina
        //O inicializador padrão do campo C5_NUM já tenha a função GetSXENum()
        //aAdd(aCabec,{"C5_NUM",  cPedido,    NIL})
        aAdd(aCabec,{"C5_TIPO",     AllTrim(oJson:GetJsonObject('TIPO'))   ,        NIL})
        aAdd(aCabec,{"C5_CLIENTE",  AllTrim(oJson:GetJsonObject('CLIENTE')),        NIL})
        aAdd(aCabec,{"C5_LOJACLI",  AllTrim(oJson:GetJsonObject('LOJACLI')),        NIL})
        aAdd(aCabec,{"C5_CLIENT",   AllTrim(oJson:GetJsonObject('CLIENTE')),        NIL})
        aAdd(aCabec,{"C5_LOJAENT",  AllTrim(oJson:GetJsonObject('LOJACLI')),        NIL})
        aAdd(aCabec,{"C5_TPFRETE",  AllTrim(oJson:GetJsonObject('TPFRETE')),        NIL})
        aAdd(aCabec,{"C5_CONDPAG",  AllTrim(oJson:GetJsonObject('CONDPAG')),        NIL})
        aAdd(aCabec,{"C5_MENNOTA",  AllTrim(oJson:GetJsonObject('MENNOTA')),        NIL})
        aAdd(aCabec,{"C5_NATUREZ",  AllTrim(oJson:GetJsonObject('NATUREZ')),        NIL})

        // CAMPOS OBRIGATÓRIOS   ANTARES - ANALISE ERRO    
        aAdd(aCabec,{"C5_NUMPCOM",  '0',        NIL})        
        aAdd(aCabec,{"C5_DTCLI",  dDatabase,        NIL})

        
        aAdd(aCabec,{"C5_DTCLIEN",  dDatabase+23,        NIL})

        //aAdd(aCabec,{"C5_ZTPENTR",  '1',        NIL})  // PROBLEMA NESSE CAMPO OBRIGATÓRIO
        //aAdd(aCabec,{"C5_ZTPENTR",   4 ,        NIL}) // PROBLEMA
        


//Busca os itens no JSON, percorre eles e adiciona no array da SC6
        oItems  := oJson:GetJsonObject('Items')
        For nX  := 1 To Len (oItems)
            aLinha  := {}
            aAdd(aLinha,{"C6_ITEM",     AllTrim(oItems[nX]:GetJsonObject('ITEM')),              NIL})
            aAdd(aLinha,{"C6_PRODUTO",  AllTrim(oItems[nX]:GetJsonObject('PRODUTO')),           NIL})
            aAdd(aLinha,{"C6_QTDVEN",   oItems[nX]:GetJsonObject('QTDVEN'),                     NIL})
            aAdd(aLinha,{"C6_PRCVEN",   oItems[nX]:GetJsonObject('PRCVEN'),                     NIL})
            aAdd(aLinha,{"C6_VALOR",    oItems[nX]:GetJsonObject('VALOR'),                      NIL})
            aAdd(aLinha,{"C6_TES",      AllTrim(oItems[nX]:GetJsonObject('TES')),               NIL})
            aAdd(aLinha,{"C6_ENTREG",   (ddatabase - 1),                                        NIL})
            //Campos opcionais
            IIF(!EMPTY(oItems[nX]:GetJsonObject('CONTA')),  aAdd(aLinha,{"C6_CONTA",     AllTrim(oItems[nX]:GetJsonObject('CONTA')),         NIL}),)
            IIF(!EMPTY(oItems[nX]:GetJsonObject('CC')),     aAdd(aLinha,{"C6_CC",        AllTrim(oItems[nX]:GetJsonObject('CC')),            NIL}),'')
            
            //Só grava os dados de projeto se for enviado projeto, tarefa e edt
            if ALLTRIM(SuperGetMV("AP_RESTPMS",.F., 'N' ))=="S"
                IF (!EMPTY(oItems[nX]:GetJsonObject('PROJPMS')) .and. !EMPTY(oItems[nX]:GetJsonObject('REVISAO')) .and. !EMPTY(oItems[nX]:GetJsonObject('TASKPMS')))
                    aAdd(aLinha,{"C6_PROJPMS",   AllTrim(oItems[nX]:GetJsonObject('PROJPMS')),       NIL})
                    aAdd(aLinha,{"C6_REVISAO",    AllTrim(oItems[nX]:GetJsonObject('REVISAO')),      NIL})
                    aAdd(aLinha,{"C6_TASKPMS",   AllTrim(oItems[nX]:GetJsonObject('TASKPMS')),       NIL})
                EndIF
            EndIF

            aAdd(aItens,aLinha)
        Next nX
        //Chama a inclusão automática de pedido de venda
        MsExecAuto({|x, y, z| mata410(x, y, z)},aCabec,aItens,nOpc)
        //Caso haja erro inicia o tratamento e retorno do mensagem
        IF lMsErroAuto
            aLog        := GetAutoGRLog()
            //Aqui só me interessa a primeira linha do erro
            cErrorAuto += RTRIM(aLog[1])
            //Montando JSON de retorno
            //cJsonRet := '{"RETURN":"FALSE"';
                //    + ',"MESSAGE":"'  + EncodeUTF8(substring(cErrorAuto,1,200)) +'"}'
            
            CONOUT(cErrorAuto) // ADD FLS
            //Retornando erro para o client            
            //SetRestFault(400,cErrorAuto,.T.,/* nStatus */,/* cDetailMsg */,'EXECAUTO MATA410',aLog)
            SetRestFault(400,cErrorAuto,.T.,/* nStatus */,/* cDetailMsg */,'EXECAUTO MATA410',  )
            //COMENTADO ACIMA FLS  -> SetRestFault(400,cErrorAuto,.T.,/* nStatus */,/* cDetailMsg */,'erplabs.com.br',aLog)
            
            lRet := .F.
        ELSE
            cJsonRet := '{"NUM":"' + SC5->C5_NUM	+ '"';
                + ',"RETURN":"TRUE"';
                + ',"MESSAGE":"'  + "Cadastrado com sucesso."+ '"'+'}'
            Self:SetResponse(cJsonRet)
        EndIF
    ELSE
        cError := "Cliente não encontrado"
        cJsonRet := '{"RETURN":"FALSE"';
            + ',"MESSAGE":"'  + EncodeUTF8(substring(cError,1,200)) +'"}'

        SetRestFault(500,cJsonRet,.T.,/* nStatus */,/* cDetailMsg */,'erplabs.com.br',)
        lRet := .F.
    EndIF
EndIf
RestArea(aArea)
FreeObj(oJson)
Return(lRet)




/*/{Protheus.doc} User Function editSalesOrder
    (Verbo POST para cadastro de novos pedidos de venda)
    @type  Function
    @author Leandro Lemos
    @since 14/05/2020
    @version P12
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    (examples)
    @see (links_or_references)
Data        Analista        Alteração


    /*/

WSMETHOD PUT editSalesOrder WSRECEIVE WSRESTFUL SalesOrder2
Local lRet      := .T.
Local aArea     := GetArea()
Local aCabec
Local aItens    := {}
Local aLinha    := {}
Local oJson
Local oItems
Local cJson     := Self:GetContent()
Local cError    := ''
Local cErrorAuto:= ''
Local nX        := 0
Local cAlias    := ''
Local aLog      := {}
Local nOpc      := 4

// variável de controle interno da rotina automatica que informa se houve erro durante o processamento
Private lMsErroAuto := .F.
// força a gravação das informações de erro em array para manipulação da gravação ao invés de gravar direto no arquivo temporário 
Private lAutoErrNoFile := .T.

//Definindo o conteúdo como JSON, e pegando o content e dando um parse para ver se a estrutura está ok
Self:SetContentType("application/json")
oJson   := JsonObject():New()
cError  := oJson:FromJson(cJson)
//Se tiver algum erro no Parse, encerra a execução
IF .NOT. Empty(cError)
    SetRestFault(500,'Parser Json Error')
    lRet    := .F.
Else
    cAlias := 'SC5'
    //Antes de iniciar é validade se o cliente ou fornecedor existe
    DbSelectArea(cAlias)
    (cAlias)->(dbSetOrder(1))
    //Se  o pedido existir entra no loop
    IF ((cAlias)->(dbSeek(FWxFilial(cAlias)+PadR(oJson:GetJsonObject('NUM'),TamSX3("C5_NUM")[1]))))
        aCabec  := {}
        aItens  := {}
        /*
        N-> Pedidos Normais.
        B-> Apres. Fornec. qdo material p/Benef.
        */
        //Numeração removida para geração automatica da rotina
        //O inicializador padrão do campo C5_NUM já tenha a função GetSXENum()
        //aAdd(aCabec,{"C5_NUM",  cPedido,    NIL})
        aAdd(aCabec,{"C5_NUM",      AllTrim(oJson:GetJsonObject('NUM'))   ,         NIL})
        aAdd(aCabec,{"C5_TIPO",     AllTrim(oJson:GetJsonObject('TIPO'))   ,        NIL})
        aAdd(aCabec,{"C5_CLIENTE",  AllTrim(oJson:GetJsonObject('CLIENTE')),        NIL})
        aAdd(aCabec,{"C5_LOJACLI",  AllTrim(oJson:GetJsonObject('LOJACLI')),        NIL})
        aAdd(aCabec,{"C5_CLIENT",   AllTrim(oJson:GetJsonObject('CLIENTE')),        NIL})
        aAdd(aCabec,{"C5_LOJAENT",  AllTrim(oJson:GetJsonObject('LOJACLI')),        NIL})
        aAdd(aCabec,{"C5_TPFRETE",  AllTrim(oJson:GetJsonObject('TPFRETE')),        NIL})
        aAdd(aCabec,{"C5_CONDPAG",  AllTrim(oJson:GetJsonObject('CONDPAG')),        NIL})
        aAdd(aCabec,{"C5_MENNOTA",  AllTrim(oJson:GetJsonObject('MENNOTA')),        NIL})
        aAdd(aCabec,{"C5_NATUREZ",  AllTrim(oJson:GetJsonObject('NATUREZ')),        NIL})

        //Busca os itens no JSON, percorre eles e adiciona no array da SC6
        oItems  := oJson:GetJsonObject('Items')
        For nX  := 1 To Len (oItems)
            aLinha  := {}
            aadd(aLinha,{"LINPOS",     "C6_ITEM",                                     StrZero(nX,2)})
            aadd(aLinha,{"AUTDELETA",  "N",                                                     Nil})
            aAdd(aLinha,{"C6_PRODUTO",  AllTrim(oItems[nX]:GetJsonObject('PRODUTO')),           NIL})
            aAdd(aLinha,{"C6_QTDVEN",   oItems[nX]:GetJsonObject('QTDVEN'),                     NIL})
            aAdd(aLinha,{"C6_PRCVEN",   oItems[nX]:GetJsonObject('PRCVEN'),                     NIL})
            aAdd(aLinha,{"C6_VALOR",    oItems[nX]:GetJsonObject('VALOR'),                      NIL})
            aAdd(aLinha,{"C6_TES",      AllTrim(oItems[nX]:GetJsonObject('TES')),               NIL})
            aAdd(aLinha,{"C6_ENTREG",   (ddatabase - 1),                                        NIL})
            //Campos opcionais
            IIF(!EMPTY(oItems[nX]:GetJsonObject('CONTA')),  aAdd(aLinha,{"C6_CONTA",     AllTrim(oItems[nX]:GetJsonObject('CONTA')),         NIL}),)
            IIF(!EMPTY(oItems[nX]:GetJsonObject('CC')),     aAdd(aLinha,{"C6_CC",        AllTrim(oItems[nX]:GetJsonObject('CC')),            NIL}),'')
            //Só grava os dados de projeto se for enviado projeto, tarefa e edt
            IF (!EMPTY(oItems[nX]:GetJsonObject('PROJPMS')) .and. !EMPTY(oItems[nX]:GetJsonObject('REVISAO')) .and. !EMPTY(oItems[nX]:GetJsonObject('TASKPMS')))
                aAdd(aLinha,{"C6_PROJPMS",   AllTrim(oItems[nX]:GetJsonObject('PROJPMS')),       NIL})
                aAdd(aLinha,{"C6_REVISAO",    AllTrim(oItems[nX]:GetJsonObject('REVISAO')),      NIL})
                aAdd(aLinha,{"C6_TASKPMS",   AllTrim(oItems[nX]:GetJsonObject('TASKPMS')),       NIL})
            EndIF

            aAdd(aItens,aLinha)

        Next nX
        //Chama a inclusão automática de pedido de venda
        MsExecAuto({|x, y, z| mata410(x, y, z)},aCabec,aItens,nOpc)
        //Caso haja erro inicia o tratamento e retorno do mensagem
        IF lMsErroAuto
            aLog        := GetAutoGRLog()
            //Aqui só me interessa a primeira linha do erro
            cErrorAuto += RTRIM(aLog[1])
            cErrorAuto := EncodeUTF8(cErrorAuto)
            /* 
            Montando JSON de retorno, só é possivel retornar atraves do SetResponse, sem SetRestFault e retornando True
            cJsonRet := '{"RETURN":"FALSE"';
                   + ',"MESSAGE":"'  + EncodeUTF8(substring(cErrorAuto,1,200)) +'"}'
            Self:SetResponse(cJsonRet)
            lRet := .T.          
             */

            //Retornando erro para o client com SetRestFault
            SetRestFault(400,cErrorAuto,.T.,/* nStatus */,/* cDetailMsg */,'erplabs.com.br',/* aDetails */)
            lRet := .F.
        ELSE
            cJsonRet := '{"NUM":"' + SC5->C5_NUM	+ '"';
                + ',"RETURN":"TRUE"';
                + ',"MESSAGE":"'  + "Alterado com sucesso."+ '"'+'}'
            Self:SetResponse(cJsonRet)
        EndIF
    ELSE
        SetRestFault(500,"Pedido não encontrado",.T.,/* nStatus */,/* cDetailMsg */,'erplabs.com.br',)
        lRet := .F.
    EndIF
EndIf
RestArea(aArea)
FreeObj(oJson)
Return(lRet)
