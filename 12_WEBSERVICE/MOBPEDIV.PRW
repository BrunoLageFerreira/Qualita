#Include "rwmake.ch"
#Include "Colors.ch"
#Include "Protheus.ch" 
#Include "Topconn.ch"

/*
Programa ...: MOBPEDIV.Prw
Uso ........: MOBPEDIV USADO PARA ALTERAR O RETORNO PADRÃO DA API SALESFORCE
Data .......: 2022-08-15
Feito por ..: Bruno Lage Ferreira
Copyright @1998-2001,2022
Atualizado..: 24/08/2022

Nome do Arquivo:
*/    
User Function MOBPEDIV()
*********************************************************************************************************************
*
*
***
Local cNum   := Paramixb[1] // Número do pedido
//Local nOpcx  := Paramixb[2] // Opção informada.

Local cJson  := ''//'PED-Q@' + cNum + '@'
    
cJson := '{'
//cJson += '"chvped" : "PED-Q@'+xfilial("SC5")+'-'+cNum+'@",'
cJson += '"chvped" : "PED-Q@010101-'+cNum+'@",'
cJson += '"numped" : "'+cNum+'"'
cJson += '}'

Return cJson
