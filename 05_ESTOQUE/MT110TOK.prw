#include "protheus.ch"
#include "rwmake.ch"
#include "tbiconn.ch"  
#INCLUDE "TOTVS.CH"

/*
Programa ...: MT110TOK.Prw
Uso ........: Programa Chamado 979 aviso de maquina parada
Data .......: 01/04/2021
Feito por ..: Bruno Lage Ferreira
Copyright @1998-2001,2021
*/

User Function  MT110TOK()
/********************************************************************************************
*
*
*
****/
Local nPosXTipo   := aScan(aHeader,{|x| AllTrim(x[2]) == 'C1_XTIPO'  })
Local nPosProdu   := aScan(aHeader,{|x| AllTrim(x[2]) == 'C1_PRODUTO'})
Local nPosDescr   := aScan(aHeader,{|x| AllTrim(x[2]) == 'C1_DESCRI' })
Local nPosObser   := aScan(aHeader,{|x| AllTrim(x[2]) == 'C1_OBS'    })

Local lValido     := .T.
Local nNumAlert   := ""
Local MsgHtml     := ""

MsgHtml     := 'Aviso de M�quina parada!'+ "<br>" + 'C�digo S.Compra:' + cA110Num + "<br> Lista: <br>"

For nX:=1 to len(aCols)
    If AllTrim(aCols[nX][nPosXTipo]) == "01"

        nNumAlert   := cA110Num        
        MsgHtml     +=  " ->" + AllTrim(aCols[nX][nPosProdu])    + " - " + AllTrim(aCols[nX][nPosDescr]) + "<br>"
        
    EndIf 
Next nX

If !Empty(nNumAlert)
    If SubString(CNUMEMP,1,2) == "01"
        TCSPExec("SP_SENDMAIL",'ITINGA',"compras.es@grupoqualita.com.br",'Aviso de M�quina parada! C�digo S.Compra:' + nNumAlert ,  MsgHtml ,'')
        //Alert("Email de alerta M�quina parada enviado! S.C.="+nNumAlert)
    EndIf
EndIf

Return(lValido)
