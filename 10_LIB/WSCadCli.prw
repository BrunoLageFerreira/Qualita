#INCLUDE "PROTHEUS.CH"
#INCLUDE "RESTFUL.CH"
#include "rwmake.ch"
#include "tbiconn.ch"
#INCLUDE "TOPCONN.CH"

//-------------------------------------------------------------------
/*
*/
//-------------------------------------------------------------------
WSRESTFUL WSCadCli DESCRIPTION "Api REST para Cadastro de Cliente"
*****************************************************************************************************************
*
*
****
    WSDATA page        AS INTEGER OPTIONAL
    WSDATA pageSize    AS INTEGER OPTIONAL
    
    WSDATA cStatusC    AS STRING  OPTIONAL
    WSDATA cUsuario    AS STRING  OPTIONAL
    WSDATA cKeyPrd     AS STRING  OPTIONAL

    WSDATA cCodiCli     AS STRING OPTIONAL
    WSDATA cLojaCli     AS STRING OPTIONAL

        //inclusão e alteração
    WSMETHOD POST IncCli   DESCRIPTION 'IncCli'   WSSYNTAX '/IncCli'   PATH 'IncCli'    PRODUCES APPLICATION_JSON
   

END WSRESTFUL

WSMETHOD POST IncCli WSRECEIVE WSRESTFUL WSCadCli
*****************************************************************************************************************
* /*Inclusão ou abertura de um novo produto*/
*
****
Local cNumCli := ""
Local lRet  := .T.

Local aArea := GetArea()
Local cQuery := ""

Local oJson

Local aCli  := {}

//Local nOpcAuto  := MODEL_OPERATION_INSERT
Local lRet      := .T.

Local cNumCli   := ""
Local cCodMun   := ""

Local aAI0Auto := {}
Local nOpcAuto := 3//MODEL_OPERATION_INSERT

Local   cDescErro   := ""
Local   cDescricao,cCientifico,cTipo,cGrupo,cNCM,cUNIDADE,cOrigem,cOBS

Local cJson     := Self:GetContent()
Local cError    

Private lMsErroAuto := .F.

ConOut("[Importaçao de Clientes] INICIO!")

    //Definindo o conteúdo como JSON, e pegando o content e dando um parse para ver se a estrutura está ok
    Self:SetContentType("application/json")
    oJson   := JsonObject():New()
    cError  := oJson:FromJson(cJson)
 
    //Se tiver algum erro no Parse, encerra a execução
    IF !Empty(cError)
        SetRestFault(500,'Parser Json Error. (Erro no Json)"')
        lRet    := .F.
    Else
            ///////////////////////////////////////////////////////
            cNumCli  := U_MCONTNUM("SA1","01")

            aCli := {}

            cQuery := "select CC2_MUN FROM CC2010 WHERE D_E_L_E_T_ = '' AND CC2_CODMUN = '"+EncodeUTF8(AllTrim(Upper(oJson:CLIENTE:CODMUN)))+"' AND CC2_EST = '"+EncodeUTF8(AllTrim(Upper(oJson:CLIENTE:EST)))+"'"
            TCQUERY cQuery ALIAS "TRB_MUN" NEW

            dbSelectArea("TRB_MUN")
            dbGoTop()
            cCodMun := TRB_MUN->CC2_MUN
            dbSelectArea("TRB_MUN")
            dbCloseArea()

            /*
            // EXEMPLO 

            {
                "CLIENTE": {
                    "COD"   : "010101",
                    "LOJA"  : "01",
                    "PESSOA": "J",
                    "CNPJ"  : "00000000000000",
                    "NOME"  : "TESTE",
                    "ENDER" : "TESTE",
                    "TIPO"  : "X",
                    "EST"   : "ES",
                    "CODMUN": "121212",
                    "MUNIC" : "VILA VELHA",
                    "BAIRRO": "ITAPUA",
                    "PAIS"  : "BRASIL",
                    "INSCRI": "ISENTO",
                    "VEND1" : "000001",
                    "CDPAIS": "001",
                    "LAT"   : "-20.3196644",
                    "LONG"  : "-40.3384748",
                    "IDMOB" : "TESTE",
                    "DTINTE": "20221208",
                    "DDD"   : "33",
                    "DDI"   : "55",
                    "TELL"  : "984022125",
                    "EMAIL" : "bruno.lage@grupoqualita.com.br",
                    "CEP"   : "29101565"
                    }
            }   
            */

            aAdd(aCli, {"A1_FILIAL"  , xFilial("SA1")          	                              , Nil})
            aAdd(aCli, {"A1_COD"     , cNumCli                 	                              , Nil})
            aAdd(aCli, {"A1_LOJA"    , "01"   	                                              , Nil})
            aAdd(aCli, {"A1_PESSOA"  , EncodeUTF8(AllTrim(Upper(oJson:CLIENTE:PESSOA)))	      , Nil})
            aAdd(aCli, {"A1_NOME"    , EncodeUTF8(AllTrim(Upper(oJson:CLIENTE:NOME)))         , Nil})
            aAdd(aCli, {"A1_NREDUZ"  , EncodeUTF8(AllTrim(Upper(oJson:CLIENTE:NOME)))         , Nil})
            aAdd(aCli, {"A1_END"     , EncodeUTF8(AllTrim(Upper(oJson:CLIENTE:ENDER)))        , Nil})
            aAdd(aCli, {"A1_TIPO"    , EncodeUTF8(AllTrim(Upper(oJson:CLIENTE:TIPO)))         , NIL})
            aAdd(aCli, {"A1_EST"     , EncodeUTF8(AllTrim(Upper(oJson:CLIENTE:EST)))          , Nil})
            aAdd(aCli, {"A1_COD_MUN" , EncodeUTF8(AllTrim(Upper(oJson:CLIENTE:CODMUN)))       , Nil})

            aAdd(aCli, {"A1_BAIRRO"  , EncodeUTF8(AllTrim(Upper(oJson:CLIENTE:BAIRRO)))       , Nil})
            aAdd(aCli, {"A1_CGC"     , EncodeUTF8(AllTrim(Upper(oJson:CLIENTE:CNPJ)))         , Nil})

            If "00000000000000" == EncodeUTF8(AllTrim(Upper(oJson:CLIENTE:CNPJ)))
                aAdd(aCli, {"A1_INSCR"   , "ISENTO"                                           , Nil})
            else
                aAdd(aCli, {"A1_INSCR"   , EncodeUTF8(AllTrim(Upper(oJson:CLIENTE:INSCRI)))   , Nil})
            EndIf 

            aAdd(aCli, {"A1_CODPAIS" , EncodeUTF8(AllTrim(Upper(oJson:CLIENTE:CDPAIS)))       , Nil})
          //aAdd(aCli, {"A1_PAIS"    , EncodeUTF8(AllTrim(Upper(oJson:CLIENTE:CODMUN)))       , Nil})
            
            aAdd(aCli, {"A1_VEND"    , EncodeUTF8(AllTrim(Upper(oJson:CLIENTE:VEND1)))        , Nil})
            

            aAdd(aCli, {"A1_XLAT"    , EncodeUTF8(AllTrim(Upper(oJson:CLIENTE:LAT)))          , Nil})
            aAdd(aCli, {"A1_XLONG"   , EncodeUTF8(AllTrim(Upper(oJson:CLIENTE:LONG)))         , Nil})

            If "00000000000000" == EncodeUTF8(AllTrim(Upper(oJson:CLIENTE:CNPJ)))
                aAdd(aCli, {"A1_YMOEDA"  , 2                                                  , Nil})
            else
                aAdd(aCli, {"A1_YMOEDA"  , 1                                                  , Nil})
            EndIf

            If "00000000000000" == EncodeUTF8(AllTrim(Upper(oJson:CLIENTE:CNPJ)))
                aAdd(aCli, {"A1_NATUREZ"  , "1.1.02.01 "                                      , Nil})
            else
                aAdd(aCli, {"A1_NATUREZ"  , "1.1.01.01"                                       , Nil})
            EndIf
            
            aAdd(aCli, {"A1_DDD"    , EncodeUTF8(AllTrim(Upper(oJson:CLIENTE:DDD)))           , Nil})
            aAdd(aCli, {"A1_DDI"    , EncodeUTF8(AllTrim(Upper(oJson:CLIENTE:DDI)))           , Nil})
            aAdd(aCli, {"A1_TEL"    , EncodeUTF8(AllTrim(Upper(oJson:CLIENTE:TELL)))          , Nil})
            aAdd(aCli, {"A1_EMAIL"  , EncodeUTF8(AllTrim(Upper(oJson:CLIENTE:EMAIL)))         , Nil})
            aAdd(aCli, {"A1_CEP"    , EncodeUTF8(AllTrim(Upper(oJson:CLIENTE:CEP)))           , Nil})

            aAdd(aAI0Auto,{"AI0_SALDO" ,0 ,Nil})

            lMsErroAuto := .F.

            MSExecAuto({|a,b,c| CRMA980(a,b,c)}, aCli, nOpcAuto, aAI0Auto)


            //////////////////////////////////////////////////////
            FreeObj(oJson)
            Self:SetContentType("application/json")
            oJson   := JsonObject():New()

            IF lMsErroAuto
                aLog        := GetAutoGRLog()
                //Aqui só me interessa a primeira linha do erro
                cErro += RTRIM(aLog[1])
                //Montando JSON de retorno
                cJson := '{"RETURN":"FALSE"';
                        + ',"MESSAGE":"'  + EncodeUTF8(substring(cErro,1,200)) +'"}'
            else
                oJson['RETURN:'] := "Produto cadastrado com sucesso!"
            EndIf
            
            cJson:= FwJsonSerialize( oJson )
            Self:SetResponse( cJson ) //-- Seta resposta

            lRet    := .T.
    EndIf
 
    RestArea(aArea)
    FreeObj(oJson)
Return(lRet)
