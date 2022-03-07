#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
#Include 'FWMVCDef.ch'

/*
Programa ...: MAUTPESO.Prw
Uso ........: REVALIDA O PESO DOS CAVALETES
Data .......: 25/02/2022
Feito por ..: Bruno Lage Ferreira 
*/

User function MAUTPESO(cCavale)
*************************************************************************************
*
*
***
Local oModelZ      := Nil
Private _lNewZPB   := .T. // Sempre atualizar o peso das chapas
Private lRet       := .F. 

If Empty(cCavale)
    Return lRet
EndIF

ZG3->(DbSetOrder(1))

If (ZG3->(DbSeek(xFilial("ZG3") + cCavale)))
    //Realiza a integracao com o GROA038
    oModelZ := FWLoadModel("GROA056") //Carrega o modelo
    oModelZ:SetOperation(MODEL_OPERATION_UPDATE)
    oModelZ:Activate()	 // Ativa o Modelo

    //Incluindo o mesmo peso para o sistema realizar o recalculo da ZG3 para ZPB
    oModelZ:SetValue("ALIMASTER",'ZG3_PESOLQ', ZG3->ZG3_PESOLQ )

    If oModelZ:VldData()
        If !oModelZ:CommitData()
            ConOut("Erro ao realizar o commit da rotina GROA056 - Pelo RECPZPB")
            lRet := .F.
        End If
    ELSE

        aErro := oModelZ:GetErrorMessage()

        ConOut("Erro na validação dos dados GROA056 - pelo RECPZPB" + chr(10) + aErro[6])
        lRet := .F.

    End If
EndIF

Return lRet
