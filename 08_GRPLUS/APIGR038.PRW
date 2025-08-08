#Include 'Protheus.ch'
#Include 'Parmtype.ch'
#Include "FWMVCDEF.CH"
 
 //https://tdn.totvs.com/display/public/framework/FWRestModel+-+API+RESTful+dos+modelos+de+dados+do+Protheus


/*
Programa ...: APIGR038.Prw
Uso ........: MODELO WEBSERVICE DO INCLUSAO DE OP
Data .......: 2025-07-29
Feito por ..: Bruno Lage Ferreira 
*/

 
Class mYRestGROA038 From FwRestModel
    Method Activate()
    Method DeActivate()
EndClass

Method Activate() Class mYRestGROA038
Return _Super:Activate()

Method DeActivate() Class mYRestGROA038
Return _Super:DeActivate()


PUBLISH USER MODEL REST NAME GROA038 SOURCE GROA038 RESOURCE OBJECT mYRestGROA038  
