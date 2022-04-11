#INCLUDE "PROTHEUS.CH"
#INCLUDE "RESTFUL.CH"
#include "rwmake.ch"
#include "tbiconn.ch"
#INCLUDE "TOPCONN.CH"

//-------------------------------------------------------------------
/*
*/
//-------------------------------------------------------------------
WSRESTFUL WSCadPrd DESCRIPTION "Api REST para solicitação de cadastro de produtos"
*****************************************************************************************************************
*
*
****
    WSDATA page        AS INTEGER OPTIONAL
    WSDATA pageSize    AS INTEGER OPTIONAL
    
    WSDATA cStatusC    AS STRING  OPTIONAL
    WSDATA cUsuario    AS STRING  OPTIONAL
    WSDATA cKeyPrd     AS STRING  OPTIONAL

    WSDATA nCodSPrd    AS INTEGER OPTIONAL

    //consultas
    WSMETHOD GET  ConGrupo  DESCRIPTION 'Consulta Grupo de produtos'   WSSYNTAX '/ConGrupo'  PATH 'ConGrupo'   PRODUCES APPLICATION_JSON
    WSMETHOD GET  ConNCM    DESCRIPTION 'Consulta NCM'                 WSSYNTAX '/ConNCM'    PATH 'ConNCM'     PRODUCES APPLICATION_JSON
    WSMETHOD GET  ConTipo   DESCRIPTION 'Consulta Tipo de produtos'    WSSYNTAX '/ConTipo'   PATH 'ConTipo'    PRODUCES APPLICATION_JSON
    WSMETHOD GET  ConUM     DESCRIPTION 'Consulta Unidade de Medida'   WSSYNTAX '/ConUM'     PATH 'ConUM'      PRODUCES APPLICATION_JSON
    //inclusão e alteração
    WSMETHOD POST IncProd   DESCRIPTION 'Consulta Unidade de Medida'   WSSYNTAX '/IncProd'   PATH 'IncProd'    PRODUCES APPLICATION_JSON
    WSMETHOD POST EncProd   DESCRIPTION 'Consulta Unidade de Medida'   WSSYNTAX '/EncProd'   PATH 'EncProd'    PRODUCES APPLICATION_JSON
    WSMETHOD GET  DelProd   DESCRIPTION 'Consulta Unidade de Medida'   WSSYNTAX '/DelProd'   PATH 'DelProd'    PRODUCES APPLICATION_JSON
    //Dados da grade
    WSMETHOD GET  RetDados  DESCRIPTION 'Retorno dados de solicitações' WSSYNTAX '/RetDados'  PATH 'RetDados'  PRODUCES APPLICATION_JSON
    WSMETHOD GET  RetCadPrd DESCRIPTION 'Retorno dados Produtos'        WSSYNTAX '/RetCadPrd' PATH 'RetCadPrd' PRODUCES APPLICATION_JSON

END WSRESTFUL

WSMETHOD GET RetCadPrd WSRECEIVE cKeyPrd WSRESTFUL WSCadPrd
*****************************************************************************************************************
*
*
****
Local lRet   := .T.

Local aArea  := GetArea()
Local aList  := {}
Local nAux   := 0
Local cQuery := ""
Local cError := ""

Local oJson
Local cJson  := ""

Default self:cKeyPrd := ""


Self:SetContentType("application/json")
oJson   := JsonObject():New()
cError  := oJson:FromJson(cJson)


cQuery := " SELECT B1_COD CODIGO,B1_DESC DESCRICAO,B1_ENDAPRO ENDERECO,B2_LOCAL+'-'+RTRIM(LTRIM(NNR_DESCRI)) ALOCAL,B2_QATU QUANTIDADE
cQuery += "   FROM SB1010 SB1 INNER JOIN SB2010 SB2 ON(B1_COD = B2_COD)
cQuery += "                   INNER JOIN NNR010 NNR ON(B2_LOCAL = NNR_CODIGO)
cQuery += "   WHERE SB1.D_E_L_E_T_ = ''
cQuery += "     AND SB2.D_E_L_E_T_ = ''
cQuery += " 	AND NNR.D_E_L_E_T_ = ''
cQuery += "     AND B1_MSBLQL <> '1'
cQuery += "     AND B1_COD + B1_DESC LIKE '%"+Upper(self:cKeyPrd)+"%'
cQuery += " ORDER BY B1_COD ,B2_LOCAL

tcQuery cQuery alias TBDADOS new
dbSelectArea("TBDADOS")
dbgotop()

//cJsonCC := ''
Do While !EOF()
    nAux := nAux + 1

    aAdd( aList , JsonObject():New() )

    aList[nAux]["CODIGO"]       := AllTrim(TBDADOS->CODIGO)
    aList[nAux]["DESCRICAO"]    := EncodeUTF8(AllTrim(TBDADOS->DESCRICAO))
    aList[nAux]["ENDERECO"]     := AllTrim(TBDADOS->ENDERECO)
    aList[nAux]["LOCAL"]        := AllTrim(TBDADOS->ALOCAL)
    aList[nAux]["QUANTIDADE"]   := TBDADOS->QUANTIDADE
    
    dbSelectArea("TBDADOS") 
    dbSkip()
EndDo

dbSelectArea("TBDADOS") 
dbCloseArea()	

oJson['DADOS'] := aList
cJson:= FwJsonSerialize( oJson )
FreeObj(oJson)

Self:SetResponse( cJson ) 
RestArea(aArea)

Return(lRet)


WSMETHOD GET DelProd WSRECEIVE nCodSPrd WSRESTFUL WSCadPrd
*****************************************************************************************************************
* /*Encerramento ou alteração da solicitação*/
*
****
Local lRet  := .T.

Local aArea := GetArea()
Local cQuery := ""

Local oJson

Local cJson     := ""
Local cError    

Default SELF:nCodSPrd := ""

    //Definindo o conteúdo como JSON, e pegando o content e dando um parse para ver se a estrutura está ok
    Self:SetContentType("application/json")
    oJson   := JsonObject():New()
    //cError  := oJson:FromJson(cJson)
 
    //Se tiver algum erro no Parse, encerra a execução
    IF !Empty(cError)
        SetRestFault(500,'Parser Json Error. (Erro no Json)"')
        lRet    := .F.
    Else
        nCodSPrd      := oJson:GetJsonObject('RECNO')

        cQuery += "  DELETE FROM APP_CADASTRO_PRODUTOS  
        cQuery += "   WHERE RECNO = " + AllTrim(STR(SELF:nCodSPrd))

        cError := AllTrim(str(TcSqlExec(cQuery)))

        FreeObj(oJson)
        Self:SetContentType("application/json")
        oJson   := JsonObject():New()

        IF cError <> '0'
            oJson['RETURN:'] := "Erro na exclusao da solicitacao! "
        else
            oJson['RETURN:'] := "Solicitacao excluida com sucesso!"
        EndIf
        
        cJson:= FwJsonSerialize( oJson )
        Self:SetResponse( cJson ) //-- Seta resposta

        lRet    := .T.
    EndIf
 
    RestArea(aArea)
    FreeObj(oJson)
Return(lRet)

WSMETHOD POST EncProd WSRECEIVE WSRESTFUL WSCadPrd
*****************************************************************************************************************
* /*Encerramento ou alteração da solicitação*/
*
****
Local lRet  := .T.

Local aArea   := GetArea()
Local cQuery  := ""
Local cQuery1 := ""
Local nAux   := 1
Local aList  := {}

Local oJson
Local cCodProtheus,cOBSReturn,nCodSPrd

Local cJson     := Self:GetContent()
Local cError    

    //Definindo o conteúdo como JSON, e pegando o content e dando um parse para ver se a estrutura está ok
    Self:SetContentType("application/json")
    oJson   := JsonObject():New()
    cError  := oJson:FromJson(cJson)
 
    //Se tiver algum erro no Parse, encerra a execução
    IF !Empty(cError)
        SetRestFault(500,'Parser Json Error. (Erro no Json)"')
        lRet    := .F.
    Else
        cCodProtheus  := AllTrim(oJson:GetJsonObject('CODPROTHEUS'))
        cOBSReturn    := AllTrim(oJson:GetJsonObject('OBSRETORNO'))
        nCodSPrd      := oJson:GetJsonObject('RECNO')

        cQuery := " UPDATE APP_CADASTRO_PRODUTOS
        cQuery += "    SET STATUS= 'ENCERRADO', CODPROTHEUS = '"+SUBSTR(cCodProtheus,1,15)+"', DATARETORNO = (SELECT CAST(GETDATE() AS datetime)), OBSRETORNO='"+cOBSReturn+"',USERETORNO='"+UPPER(UsrFullName(__cUserID))+"'
        cQuery += "  WHERE RECNO = " + AllTrim(Str(nCodSPrd))

        cError := AllTrim(str(TcSqlExec(cQuery)))

        FreeObj(oJson)
        Self:SetContentType("application/json")
        oJson   := JsonObject():New()

        IF cError <> '0'
            oJson['RETURN:'] := "Erro no encerramento da solicitacao! " + cError + "Detalhes: " + cQuery
        else
            cQuery1 := " SELECT TOP 100 
            cQuery1 += "     STATUS,
            cQuery1 += "     RECNO,
            cQuery1 += "     CAST(CAST(DATASOLICITACAO AS date) AS varchar(10)) + ' ' + CAST(CAST(DATASOLICITACAO AS TIME) AS varchar(8))   DATASOLICITACAO ,
            cQuery1 += "     NOME_PRODUTO,
            cQuery1 += "     NOME_CIENTIFICO,
            cQuery1 += "     TIPO,
            cQuery1 += "     ALMOXARIFADO,
            cQuery1 += "     GRUPO,
            cQuery1 += "     UNID_MEDIDA,
            cQuery1 += "     NCM,
            cQuery1 += "     ORIGEM,
            cQuery1 += "     USUARIO,
            cQuery1 += "     EMAIL,
            cQuery1 += "     OBS,
            cQuery1 += "     USERETORNO,
            cQuery1 += "     CODPROTHEUS,
            cQuery1 += "     CAST(CAST(DATARETORNO AS date) AS varchar(10)) + ' ' + CAST(CAST(DATARETORNO AS TIME) AS varchar(8)) DATARETORNO, 
            cQuery1 += "     OBSRETORNO
            cQuery1 += "   FROM APP_CADASTRO_PRODUTOS 
            cQuery1 += "  WHERE RECNO = " + AllTrim(Str(nCodSPrd))
            cQuery1 += " ORDER BY RECNO

            tcQuery cQuery1 alias TBDADOS1 new
            dbSelectArea("TBDADOS1")
            dbgotop()

            //cJsonCC := ''

                aAdd( aList , JsonObject():New() )

                aList[nAux]["RECNO"]            := TBDADOS1->RECNO
                aList[nAux]["STATUS"]           := AllTrim(TBDADOS1->STATUS)
                aList[nAux]["DATASOLICITACAO"]  := TBDADOS1->DATASOLICITACAO
                aList[nAux]["DATARETORNO"]      := TBDADOS1->DATARETORNO
                aList[nAux]["ALMOXARIFADO"]     := AllTrim(TBDADOS1->ALMOXARIFADO)
                aList[nAux]["DESCRICAO"]        := AllTrim(TBDADOS1->NOME_PRODUTO)
                aList[nAux]["USUARIO"]          := AllTrim(TBDADOS1->USUARIO)
                aList[nAux]["TIPO"]             := AllTrim(TBDADOS1->TIPO)
                aList[nAux]["GRUPO"]            := AllTrim(TBDADOS1->GRUPO)
                aList[nAux]["OBS"]              := AllTrim(TBDADOS1->OBS)
                aList[nAux]["UNIDADE"]          := AllTrim(TBDADOS1->UNID_MEDIDA)
                aList[nAux]["NCM"]              := AllTrim(TBDADOS1->NCM)
                aList[nAux]["ORIGEM"]           := AllTrim(TBDADOS1->ORIGEM)
                aList[nAux]["CIENTIFICO"]       := AllTrim(TBDADOS1->NOME_CIENTIFICO)
                aList[nAux]["EMAIL"]            := AllTrim(TBDADOS1->EMAIL)
                aList[nAux]["CODPROTHEUS"]      := AllTrim(TBDADOS1->CODPROTHEUS)
                aList[nAux]["OBSRETORNO"]       := AllTrim(TBDADOS1->OBSRETORNO)
                aList[nAux]["USERETORNO"]       := AllTrim(TBDADOS1->USERETORNO)

                

            dbSelectArea("TBDADOS1")
            dbCloseArea()	     

            oJson['DADOS'] := aList
            

        EndIf
        
        cJson:= FwJsonSerialize( oJson )
        Self:SetResponse( cJson ) //-- Seta resposta

        lRet    := .T.
    EndIf
 
    RestArea(aArea)
    FreeObj(oJson)
Return(lRet)

WSMETHOD POST IncProd WSRECEIVE WSRESTFUL WSCadPrd
*****************************************************************************************************************
* /*Inclusão ou abertura de um novo produto*/
*
****
Local lRet  := .T.

Local aArea := GetArea()
Local cQuery := ""

Local oJson


Local   cDescricao,cCientifico,cTipo,cGrupo,cNCM,cUNIDADE,cOrigem,cOBS

Local cJson     := Self:GetContent()
Local cError    

    //Definindo o conteúdo como JSON, e pegando o content e dando um parse para ver se a estrutura está ok
    Self:SetContentType("application/json")
    oJson   := JsonObject():New()
    cError  := oJson:FromJson(cJson)
 
    //Se tiver algum erro no Parse, encerra a execução
    IF !Empty(cError)
        SetRestFault(500,'Parser Json Error. (Erro no Json)"')
        lRet    := .F.
    Else

        cDescricao  := EncodeUTF8(AllTrim(Upper(oJson:GetJsonObject('DESCRICAO'))))
        cCientifico := EncodeUTF8(AllTrim(Upper(oJson:GetJsonObject('CIENTIFICO'))))
        cTipo       := EncodeUTF8(AllTrim(Upper(oJson:GetJsonObject('TIPO'))))
        cGrupo      := EncodeUTF8(AllTrim(Upper(oJson:GetJsonObject('GRUPO'))))
        cNCM        := EncodeUTF8(AllTrim(Upper(oJson:GetJsonObject('NCM'))))
        cUNIDADE    := EncodeUTF8(AllTrim(Upper(oJson:GetJsonObject('UNIDADE'))))
        cOrigem     := EncodeUTF8(AllTrim(Upper(oJson:GetJsonObject('ORIGEM'))))
        cOBS        := EncodeUTF8(AllTrim(Upper(oJson:GetJsonObject('OBS'))))

        cQuery := " INSERT APP_CADASTRO_PRODUTOS (DATASOLICITACAO                     , RECNO                                        ,STATUS     ,NOME_PRODUTO    ,NOME_CIENTIFICO  ,TIPO       ,ALMOXARIFADO,GRUPO       ,UNID_MEDIDA   ,NCM        ,ORIGEM       ,USUARIO   , EMAIL ,OBS     ) 
        cQuery += "                        VALUES((SELECT CAST(GETDATE() AS datetime)),(SELECT COUNT(*)+1 FROM APP_CADASTRO_PRODUTOS),'PENDENTE' ,'"+cDescricao+"','"+cCientifico+"','"+cTipo+"','01'        ,'"+cGrupo+"','"+cUNIDADE+"','"+cNCM+"' ,'"+cOrigem+"','"+UPPER(cUserName)+"' ,'"+UsrRetMail(__cUserID)+"','"+cOBS+"')

        cError := AllTrim(str(TcSqlExec(cQuery)))

        FreeObj(oJson)
        Self:SetContentType("application/json")
        oJson   := JsonObject():New()

        IF cError <> '0'
            oJson['RETURN:'] := "Erro na inclusão do produto!"
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

WSMETHOD GET RetDados WSRECEIVE cStatusC,cUsuario WSRESTFUL WSCadPrd
*****************************************************************************************************************
*
*
****
Local lRet   := .T.

Local aArea  := GetArea()
Local aList  := {}
Local nAux   := 0
Local cQuery := ""
Local cError := ""

Local oJson
Local cJson  := ""

Default self:cStatusC  := ""
Default self:cUsuario  := ""

Self:SetContentType("application/json")
oJson   := JsonObject():New()
cError  := oJson:FromJson(cJson)

cQuery := " SELECT TOP 100 
cQuery += "     STATUS,
cQuery += "     RECNO,
cQuery += "     CAST(CAST(DATASOLICITACAO AS date) AS varchar(10)) + ' ' + CAST(CAST(DATASOLICITACAO AS TIME) AS varchar(8))   DATASOLICITACAO ,
cQuery += "     NOME_PRODUTO,
cQuery += "     NOME_CIENTIFICO,
cQuery += "     TIPO,
cQuery += "     ALMOXARIFADO,
cQuery += "     GRUPO,
cQuery += "     UNID_MEDIDA,
cQuery += "     NCM,
cQuery += "     ORIGEM,
cQuery += "     USUARIO,
cQuery += "     EMAIL,
cQuery += "     OBS,
cQuery += "     USERETORNO,
cQuery += "     CODPROTHEUS,
cQuery += "     CAST(CAST(DATARETORNO AS date) AS varchar(10)) + ' ' + CAST(CAST(DATARETORNO AS TIME) AS varchar(8)) DATARETORNO, 
cQuery += "     OBSRETORNO
cQuery += "   FROM APP_CADASTRO_PRODUTOS 
cQuery += "  WHERE STATUS  LIKE '%"+ self:cStatusC +"%'
cQuery += "    AND USUARIO LIKE '%"+ UPPER(self:cUsuario) +"%'
cQuery += " ORDER BY RECNO

tcQuery cQuery alias TBDADOS new
dbSelectArea("TBDADOS")
dbgotop()

//cJsonCC := ''
Do While !EOF()
    nAux := nAux + 1

    aAdd( aList , JsonObject():New() )

    aList[nAux]["RECNO"]            := TBDADOS->RECNO
    aList[nAux]["STATUS"]           := AllTrim(TBDADOS->STATUS)
    aList[nAux]["DATASOLICITACAO"]  := TBDADOS->DATASOLICITACAO
    aList[nAux]["DATARETORNO"]      := TBDADOS->DATARETORNO
    aList[nAux]["ALMOXARIFADO"]     := AllTrim(TBDADOS->ALMOXARIFADO)
    aList[nAux]["DESCRICAO"]        := AllTrim(TBDADOS->NOME_PRODUTO)
    aList[nAux]["USUARIO"]          := AllTrim(TBDADOS->USUARIO)
    aList[nAux]["TIPO"]             := AllTrim(TBDADOS->TIPO)
    aList[nAux]["GRUPO"]            := AllTrim(TBDADOS->GRUPO)
    aList[nAux]["OBS"]              := AllTrim(TBDADOS->OBS)
    aList[nAux]["UNIDADE"]          := AllTrim(TBDADOS->UNID_MEDIDA)
    aList[nAux]["NCM"]              := AllTrim(TBDADOS->NCM)
    aList[nAux]["ORIGEM"]           := AllTrim(TBDADOS->ORIGEM)
    aList[nAux]["CIENTIFICO"]       := AllTrim(TBDADOS->NOME_CIENTIFICO)
    aList[nAux]["EMAIL"]            := AllTrim(TBDADOS->EMAIL)
    aList[nAux]["CODPROTHEUS"]      := AllTrim(TBDADOS->CODPROTHEUS)
    aList[nAux]["OBSRETORNO"]       := AllTrim(TBDADOS->OBSRETORNO)
    aList[nAux]["USERETORNO"]       := AllTrim(TBDADOS->USERETORNO)
    
    dbSelectArea("TBDADOS") 
    dbSkip()
EndDo

dbSelectArea("TBDADOS") 
dbCloseArea()	

oJson['DADOS'] := aList
cJson:= FwJsonSerialize( oJson )
FreeObj(oJson)

Self:SetResponse( cJson ) 

RestArea(aArea)

Return(lRet)


WSMETHOD GET ConUM WSRECEIVE page WSREST WSCadPrd
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
Local cQuery            := ""

Default self:page       := ''

cQuery := " SELECT RTRIM(LTRIM(B1_UM)) CODIGO,
cQuery += "        RTRIM(LTRIM(B1_UM)) +'-'+(SELECT RTRIM(LTRIM(AH_UMRES)) FROM SAH010 WHERE D_E_L_E_T_ = '' AND AH_UNIMED = B1_UM) DESCRI
cQuery += "   FROM SB1010 SB1 
cQuery += "  WHERE SB1.D_E_L_E_T_ = ''
cQuery += "    AND B1_LOCPAD = '01'
cQuery += " GROUP BY B1_UM

TcQuery cQuery Alias cQry New
dbSelectArea("cQry")
dbGoTop()
While !Eof() 
	    
    nAux := nAux + 1
    conOut(nAux)
    aAdd( aList , JsonObject():New() )
    aList[nAux]['DESCRI']     := ALLTRIM(EncodeUTF8(cQry->DESCRI))
    aList[nAux]['CODIGO']     := ALLTRIM(cQry->CODIGO)

    dbSelectArea("cQry")
    dbSkip()
EndDO

dbSelectArea("cQry")
dbCloseArea()

oJson['DADOS'] := aList
cJson:= FwJsonSerialize( oJson )
FreeObj(oJson)
Self:SetResponse( cJson ) 

RestArea(aArea)
Return(lRet)

WSMETHOD GET ConTipo WSRECEIVE page WSREST WSCadPrd
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
Local cQuery            := ""

Default self:page       := ''

cQuery += " SELECT  RTRIM(LTRIM(X5_CHAVE)) CODIGO,
cQuery += " 		RTRIM(LTRIM(X5_CHAVE)) + '-' + UPPER(X5_DESCRI ) DESCRI
cQuery += "   FROM SX5010
cQuery += "  WHERE D_E_L_E_T_ = ''
cQuery += "    AND X5_TABELA = '02'

TcQuery cQuery Alias cQry New
dbSelectArea("cQry")
dbGoTop()
While !Eof() 
	    
    nAux := nAux + 1
    conOut(nAux)
    aAdd( aList , JsonObject():New() )
    aList[nAux]['DESCRI']     := ALLTRIM(EncodeUTF8(cQry->DESCRI))
    aList[nAux]['CODIGO']     := ALLTRIM(cQry->CODIGO)

    dbSelectArea("cQry")
    dbSkip()
EndDO

dbSelectArea("cQry")
dbCloseArea()

oJson['DADOS'] := aList
cJson:= FwJsonSerialize( oJson )
FreeObj(oJson)
Self:SetResponse( cJson ) 

RestArea(aArea)
Return(lRet)

WSMETHOD GET ConNCM WSRECEIVE page WSREST WSCadPrd
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
Local cQuery            := ""

Default self:page       := ''

cQuery := " SELECT  YD_TEC CODIGO,
cQuery += "          RTRIM(LTRIM(YD_TEC)) + '-' + RTRIM(LTRIM(YD_DESC_P)) DESCRI
cQuery += "    FROM SYD010
cQuery += "   WHERE D_E_L_E_T_ = '' 
cQuery += "     AND YD_DESC_P <> ''   

TcQuery cQuery Alias cQry New
dbSelectArea("cQry")
dbGoTop()
While !Eof() 
	    
    nAux := nAux + 1
    conOut(nAux)
    aAdd( aList , JsonObject():New() )
    aList[nAux]['DESCRI']     := ALLTRIM(EncodeUTF8(cQry->DESCRI))
    aList[nAux]['CODIGO']     := ALLTRIM(cQry->CODIGO)

    dbSelectArea("cQry")
    dbSkip()
EndDO

dbSelectArea("cQry")
dbCloseArea()

oJson['DADOS'] := aList
cJson:= FwJsonSerialize( oJson )
FreeObj(oJson)
Self:SetResponse( cJson ) 

RestArea(aArea)
Return(lRet)

WSMETHOD GET ConGrupo WSRECEIVE page WSREST WSCadPrd
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
Local cQuery            := ""

Default self:page       := ''

cQuery := " SELECT BM_GRUPO CODIGO,
cQuery += " 	   RTRIM(LTRIM(BM_GRUPO)) + '-' + RTRIM(LTRIM(BM_DESC)) DESCRI
cQuery += "  FROM SBM010
cQuery += "  WHERE D_E_L_E_T_ = ''

TcQuery cQuery Alias cQry New
dbSelectArea("cQry")
dbGoTop()
While !Eof() 
	    
    nAux := nAux + 1
    conOut(nAux)
    aAdd( aList , JsonObject():New() )
    aList[nAux]['DESCRI']     := ALLTRIM(EncodeUTF8(cQry->DESCRI))
    aList[nAux]['CODIGO']     := ALLTRIM(cQry->CODIGO)

    dbSelectArea("cQry")
    dbSkip()
EndDO

dbSelectArea("cQry")
dbCloseArea()

oJson['DADOS'] := aList
cJson:= FwJsonSerialize( oJson )
FreeObj(oJson)
Self:SetResponse( cJson ) 

RestArea(aArea)
Return(lRet)
