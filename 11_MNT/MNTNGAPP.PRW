#Include "rwmake.ch"
#Include "Colors.ch"
#Include "Protheus.ch" 
#Include "Topconn.ch"


/*
Programa ...: MNTNGAPP.Prw
Uso ........: Ponto de entrada pausa no recebimento dados vindo do app da manuten��o
Data .......: 2023-03-03
Feito por ..: Arlindo Pelissari
Copyright @1998-2001,2023
Atualizado..: 

Nome do Arquivo:
*/    
User Function MNTNG()
/**********************************************************************************************************************
*
*
****/
Local cId := PARAMIXB[1] //Indica o momento da chamada do PE
Local oWS
Local oParser

 
    If cId != 'COMPANY_GROUP_IGNORE'
        oWS := PARAMIXB[2] //Objeto com refer�ncia ao webservice
    EndIf

    If cId == "CREATE_VALID_ORDER"  //valida inclus�o e altera��o da ordem
        If FWJsonDeserialize(oWS:GetContent(), @oParser)

            If Empty( oParser:observation ) //verifica campo observa��o foi passado vazio
                Return "Campo observa��o deve ser informado."
            EndIf
            
        EndIf

    ElseIf cId == "FINISH_VALID_ORDER"
     
        If FWJsonDeserialize(oWS:GetContent(), @oParser)

            If Empty( oParser:observation ) //verifica campo observa��o foi passado vazio
                Return "Campo observa��o deve ser informado."
            EndIf
            
        EndIf

    EndIf
    
Return()