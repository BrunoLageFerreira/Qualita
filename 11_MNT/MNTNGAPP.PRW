#Include "rwmake.ch"
#Include "Colors.ch"
#Include "Protheus.ch" 
#Include "Topconn.ch"


/*
Programa ...: MNTNGAPP.Prw
Uso ........: Ponto de entrada pausa no recebimento dados vindo do app da manutenção
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
        oWS := PARAMIXB[2] //Objeto com referência ao webservice
    EndIf

    If cId == "CREATE_VALID_ORDER"  //valida inclusão e alteração da ordem
        If FWJsonDeserialize(oWS:GetContent(), @oParser)

            If Empty( oParser:observation ) //verifica campo observação foi passado vazio
                Return "Campo observação deve ser informado."
            EndIf
            
        EndIf

    ElseIf cId == "FINISH_VALID_ORDER"
     
        If FWJsonDeserialize(oWS:GetContent(), @oParser)

            If Empty( oParser:observation ) //verifica campo observação foi passado vazio
                Return "Campo observação deve ser informado."
            EndIf
            
        EndIf

    EndIf
    
Return()
