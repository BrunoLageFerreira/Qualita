#Include 'Protheus.ch'
#Include 'Parmtype.ch'
#Include "FWMVCDEF.CH"
#include "totvs.ch"
#INCLUDE "RESTFUL.CH"
#INCLUDE "APWEBSRV.CH"
#Include "TopConn.ch"  


/*
Programa ...: APIGRPOST.Prw
Uso ........: MODELO POST JSON GENERICO PARA INCLUSÃO / APONTAMENTO / ENCERRAMENTO
Data .......: 2025-07-29
Feito por ..: Bruno Lage Ferreira 
*/
 
 User function APIGRGET( cUrl ,cPath, cJson )
/****************************************************************************************************************
*
*
*
***/
Local aArea         := FWGetArea()
Local aHeader       := {}    
Local oRestClient   := FWRest():New(cUrl)
Local cBasicAuth    := Encode64("Admin" + ":" + "xpacD95label")
Local jResultado
Local jDados        

If APPApont()

    aAdd(aHeader,'User-Agent: Mozilla/4.0 (compatible; Protheus '+GetBuild()+')')
    aAdd(aHeader,'Content-Type: application/json; charset=utf-8')
    aAdd(aHeader,'Authorization: Basic ' + cBasicAuth)

    oRestClient:setPath(cPath)
    If oRestClient:Get(aHeader)
            
        jResultado := JsonObject():New()
        jResultado:FromJson(oRestClient:cResult)

        jDados := jResultado:GetJsonObject("resources")
        
        oRestClient:setPath(jdados[1]:GetJsonObject("pk"))

        If oRestClient:Get(aHeader)
            ShowLog(oRestClient:cResult)
            FWExecView('Alteração','GROA045', MODEL_OPERATION_UPDATE, , { || .T. }, , , )
        Else
            cLastError   := oRestClient:GetLastError()
            cErrorDetail := oRestClient:GetResult()
            Alert(cErrorDetail)
        Endif 

    Else
        cLastError := oRestClient:GetLastError()
        cErrorDetail := oRestClient:GetResult()
        Alert(cErrorDetail)
    Endif  


    FWRestArea(aArea)

EndIF

Return()


 
