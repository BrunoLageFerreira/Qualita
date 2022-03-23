#INCLUDE "PROTHEUS.CH"
#INCLUDE "RESTFUL.CH"
#include "rwmake.ch"
#include "tbiconn.ch"
#INCLUDE "TOPCONN.CH"

//-------------------------------------------------------------------
/*

*/
//-------------------------------------------------------------------
WSRESTFUL wBaixaEstoque DESCRIPTION "Api REST para baixa de estoque"
*****************************************************************************************************************
*
*
****
    WSDATA page        AS INTEGER OPTIONAL
    WSDATA pageSize    AS INTEGER OPTIONAL
    
    WSDATA cCodProd    AS STRING  OPTIONAL
    WSDATA cCC         AS STRING  OPTIONAL
    WSDATA cQtdbaixa   AS STRING  OPTIONAL
 
    WSMETHOD GET incOrderbx  DESCRIPTION 'Submete baixa de estoque'     WSSYNTAX '/incOrderbx'  PATH 'incOrderbx'   PRODUCES APPLICATION_JSON

END WSRESTFUL


WSMETHOD GET incOrderbx WSRECEIVE cCodProd , cQtdbaixa , cCC WSREST wBaixaEstoque
*****************************************************************************************************************
*
*
****
Local lRet              := .T.
Local aArea             := GetArea()
Local aLog              :={}
Local cErro             := ""

Local oJson
Local cJson             := Self:GetContent()
Local cError            := ''

Local _aCab1            := {}
Local _aItem            := {}
Local _atotitem         := {}
                                                                                                                      
Default self:cCodProd   := ''
Default self:cQtdbaixa  := ''

Private lMsHelpAuto     := .t. // se .t. direciona as mensagens de help
Private lMsErroAuto     := .f. //necessario a criacao
Private lAutoErrNoFile  := .T.


Self:SetContentType("application/json")
oJson   := JsonObject():New()
cError  := oJson:FromJson(cJson)

ConOut(Self:cCodProd)
ConOut(Self:cQtdbaixa)
ConOut(Self:cCC)

RPCSetType(3)
RpcSetEnv("01","01","","","EST","MATA241",{"SD3","SB1"})

/******************************************
* Validação do Centro de Custos
*
*****/
If Empty(Self:cCC) .Or. !ExistCPO( "CTT", AllTrim(Self:cCC))
    oJson['RETURN:'] := EncodeUTF8("Centro de Custo não encontrado ou em branco!")
        
    cJson:= FwJsonSerialize( oJson )
    FreeObj(oJson)
    Self:SetResponse( cJson ) //-- Seta resposta

    RpcClearEnv()
    RestArea(aArea)

    Return(.F.)
EndIf 
/******************************************
* Validação da Quantidade
*
*****/
iF Empty(Self:cQtdbaixa) .Or. val(Self:cQtdbaixa)==0

    oJson['RETURN:'] := EncodeUTF8("Quantidade não pode ser zerada!")
        
    cJson:= FwJsonSerialize( oJson )
    FreeObj(oJson)
    Self:SetResponse( cJson ) 

    RpcClearEnv()
    RestArea(aArea)

    Return(.F.)
EndIf
/******************************************
* Validação do cadastro de Produtos
*
*****/
DbSelectArea("SB1")
dbSetorder(1)
If !dbSeek(xFilial("SB1") + AllTrim(Self:cCodProd) ,.t.)
    oJson['RETURN:'] := EncodeUTF8("Produto não encontrado!")
        
    cJson:= FwJsonSerialize( oJson )
    FreeObj(oJson)
    Self:SetResponse( cJson ) //-- Seta resposta

    RpcClearEnv()
    RestArea(aArea)

    Return(.F.)
EndIf
/******************************************
* Montagem dos dados de baixa
*
*****/                                                                                                               
_aCab1 := { {"D3_TM"      ,"501"              ,nil},;
            {"D3_CC"      ,Self:cCC           ,nil},;
            {"D3_EMISSAO" ,dDataBase          ,nil}}

_aItem:={   {"D3_COD"     ,SB1->B1_COD        ,nil},;
            {"D3_UM"      ,SB1->B1_UM         ,nil},;
            {"D3_QUANT"   ,VAl(Self:cQtdbaixa),nil},;
            {"D3_LOCAL"   ,SB1->B1_LOCPAD     ,nil}}
        
aadd(_atotitem,_aitem)

MSExecAuto({|x,y,z| MATA241(x,y,z)},_aCab1,_atotitem,3)

/******************************************
* Controle de retorno apos a baixa
*
*****/
If lMsErroAuto
    aLog        := GetAutoGRLog()
    //Aqui só me interessa a primeira linha do erro
    cErro += RTRIM(aLog[1])
    //Montando JSON de retorno
    cJson := '{"RETURN":"FALSE"';
           + ',"MESSAGE":"'  + EncodeUTF8(substring(cErro,1,200)) +'"}'

    oJson['RETURN:'] := EncodeUTF8(substring(cErro,1,200))
        
    cJson:= FwJsonSerialize( oJson )
    FreeObj(oJson)
    Self:SetResponse( cJson ) //-- Seta resposta

    RpcClearEnv()
    RestArea(aArea)

    return(.F.)
else
    oJson['RETURN:'] := "Baixado com sucesso!"
    cJson:= FwJsonSerialize( oJson )
    FreeObj(oJson)
    Self:SetResponse( cJson ) //-- Seta resposta
endIf


RpcClearEnv()
RestArea(aArea)
Return(lRet)
