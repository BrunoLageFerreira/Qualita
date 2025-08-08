#Include 'Protheus.ch'
#Include 'Parmtype.ch'
#Include "FWMVCDEF.CH"

/*
Programa ...: APIGR045.Prw
Uso ........: MODELO WEBSERVICE DO APONTAMENTO
Data .......: 2025-07-29
Feito por ..: Bruno Lage Ferreira 
*/
 
Class mYRestGROA045 From FwRestModel
    Method Activate()
    Method DeActivate()
EndClass

Method Activate() Class mYRestGROA045
Return _Super:Activate()

Method DeActivate() Class mYRestGROA045
Return _Super:DeActivate()


PUBLISH USER MODEL REST NAME GROA045 SOURCE GROA045 RESOURCE OBJECT mYRestGROA045  
