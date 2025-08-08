#Include 'Protheus.ch'
#Include 'Parmtype.ch'
#Include "FWMVCDEF.CH"
 
 //https://tdn.totvs.com/display/public/framework/FWRestModel+-+API+RESTful+dos+modelos+de+dados+do+Protheus


/*
Programa ...: APIGR044.Prw
Uso ........: MODELO WEBSERVICE DO ENCERRAMENTO
Data .......: 2025-07-29
Feito por ..: Bruno Lage Ferreira 
*/

 
Class mYRestGROA044 From FwRestModel
    Method Activate()
    Method DeActivate()
EndClass

Method Activate() Class mYRestGROA044
Return _Super:Activate()

Method DeActivate() Class mYRestGROA044
Return _Super:DeActivate()


PUBLISH USER MODEL REST NAME GROA044 SOURCE GROA044 RESOURCE OBJECT mYRestGROA044  
