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

    WSDATA cPesqCC     AS STRING  OPTIONAL
    WSDATA cPesqPrd    AS STRING  OPTIONAL

    WSMETHOD GET incOrderbx  DESCRIPTION 'Submete baixa de estoque'     WSSYNTAX '/incOrderbx'  PATH 'incOrderbx'   PRODUCES APPLICATION_JSON
    WSMETHOD GET ConCCusto   DESCRIPTION 'Consulta Centro de custo'     WSSYNTAX '/ConCCusto'   PATH 'ConCCusto'    PRODUCES APPLICATION_JSON
    WSMETHOD GET ConSldEst   DESCRIPTION 'Consulta Saldo do Estoque'    WSSYNTAX '/ConSldEst'   PATH 'ConSldEst'    PRODUCES APPLICATION_JSON

END WSRESTFUL


WSMETHOD GET ConSldEst WSRECEIVE cPesqPrd WSREST wBaixaEstoque
*****************************************************************************************************************
*
*
****
Local lRet              := .T.
Local aArea             := GetArea()
Local aList             := {}

Local oJson             := JsonObject():New() 
Local cJson             := ""
Local nAux              := 0

Default self:cPesqPrd   := ''


If EMPTY(AllTrim(Self:cPesqPrd))
    oJson['RETURN:'] := EncodeUTF8("Produto em branco! ")
        
    cJson:= FwJsonSerialize( oJson )
    FreeObj(oJson)
    Self:SetResponse( cJson ) //-- Seta resposta

    RpcClearEnv()
    RestArea(aArea)

    Return(.F.)
EndIf


RPCSetType(3)
RpcSetEnv("01","01","","","EST","MATA241",{"","SB1","SB2"})

cQuery := "SELECT B1_COD,R_E_C_N_O_ REC FROM " + RetSqlName( 'SB1' ) + " WHERE D_E_L_E_T_ = '' AND B1_COD = '"+ AllTrim(Self:cPesqPrd) +"'
TcQuery cQuery Alias cQrySB1 New

dbSelectArea("cQrySB1")
dbgotop()
If Eof()
    oJson['RETURN:'] := EncodeUTF8("Produto não encontrado!")

    dbSelectArea("cQrySB1")
    dbCloseArea()

    cJson:= FwJsonSerialize( oJson )
    FreeObj(oJson)
    Self:SetResponse( cJson ) //-- Seta resposta

    RpcClearEnv()
    RestArea(aArea)
    Return(.F.)
EndIf

dbSelectArea("SB1")
dbGoto(cQrySB1->REC)

dbSelectArea("cQrySB1")
dbCloseArea()

dbSelectArea("SB2")
dbSetOrder(1)
dbGoTop()
dbSeek(xFilial("SB2") + Self:cPesqPrd )
While !SB2->( Eof() ) .And. SB2->B2_FILIAL + AllTrim(SB2->B2_COD) == xFilial("SB2") + AllTrim(Self:cPesqPrd)
	    
    nAux := nAux + 1
    conOut(nAux)
    aAdd( aList , JsonObject():New() )
    aList[nAux]['CUSTO']     := SB2->B2_CM1
    aList[nAux]['SALDO']     := SaldoSB2()
    aList[nAux]['LOCAL']     := SB2->B2_LOCAL
    aList[nAux]['ENDER']     := Alltrim(SB1->B1_ENDAPRO)
    aList[nAux]['DESCRICAO'] := Alltrim( EncodeUTF8( SB1->B1_DESC) )
    aList[nAux]['CODIGO']    := AllTrim(SB1->B1_COD)

    DbSelectArea("SB2")
    DBSkip()
EndDO

RpcClearEnv()


oJson['SLDPRODUTO'] := aList
cJson:= FwJsonSerialize( oJson )
FreeObj(oJson)
Self:SetResponse( cJson ) 

RestArea(aArea)
Return(lRet)

WSMETHOD GET ConCCusto WSRECEIVE cPesqCC WSREST wBaixaEstoque
*****************************************************************************************************************
*
*
****
Local lRet              := .T.
Local aArea             := GetArea()
Local cQuery            := ""

Local aList             := {}
Local nAux              := 0
//Local nX                := 0

Local oJsonCC           := JsonObject():New() 
Local cJsonCC           := ""

Default self:cPesqCC    := ''

cQuery := "   SELECT RTRIM(LTRIM(CTT_CUSTO)) CODIGO,
cQuery += "		  RTRIM(LTRIM(CTT_DESC01)) DESCRICAO	
cQuery += "	     FROM CTT010 
cQuery += "		WHERE D_E_L_E_T_ = '' 
cQuery += "		  AND CTT_BLOQ IN ('','2') 
cQuery += "		  AND CTT_CLASSE = '2'
cQuery += "		  AND CTT_CUSTO + CTT_DESC01 LIKE '%" + upper(Self:cPesqCC) + "%'

tcQuery cQuery alias TBWSCC new
dbSelectArea("TBWSCC")
dbgotop()

//cJsonCC := ''
Do While !EOF()
    nAux := nAux + 1

    aAdd( aList , JsonObject():New() )
    aList[nAux]['DESCRICAO'] := Alltrim( EncodeUTF8( TBWSCC->DESCRICAO ) )
    aList[nAux]['CODDESC']   := AllTrim(TBWSCC->CODIGO) +" "+ Alltrim( EncodeUTF8( TBWSCC->DESCRICAO ) )
    aList[nAux]['CODIGO']    := AllTrim(TBWSCC->CODIGO)
    
    dbSelectArea("TBWSCC") 
    DBSkip()
EndDo
//cJsonCC := cJsonCC + ''

dbSelectArea("TBWSCC") 
dbCloseArea()	

oJsonCC['CENTRO_CUSTOS'] := aList
cJsonCC:= FwJsonSerialize( oJsonCC )
FreeObj(oJsonCC)

Self:SetResponse( cJsonCC ) 

RestArea(aArea)
Return(lRet)

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
Default self:cCC        := ''

Private lMsHelpAuto     := .T. // se .t. direciona as mensagens de help
Private lMsErroAuto     := .F. //necessario a criacao
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

cQuery := "SELECT B1_COD,R_E_C_N_O_ REC FROM " + RetSqlName( 'SB1' ) + " WHERE D_E_L_E_T_ = '' AND B1_COD = '"+ AllTrim(Self:cCodProd) +"'
TcQuery cQuery Alias cQrySB1 New

dbSelectArea("cQrySB1")
dbgotop()
If Eof()
    oJson['RETURN:'] := EncodeUTF8("Produto não encontrado!")

    dbSelectArea("cQrySB1")
    dbCloseArea()

    cJson:= FwJsonSerialize( oJson )
    FreeObj(oJson)
    Self:SetResponse( cJson ) //-- Seta resposta

    RpcClearEnv()
    RestArea(aArea)
    Return(.F.)
EndIf

dbSelectArea("SB1")
dbGoto(cQrySB1->REC)

dbSelectArea("cQrySB1")
dbCloseArea()

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
