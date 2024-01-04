#include 'protheus.ch'
#include 'parmtype.ch'

User Function MTA110OK()
***********************************************************************************
*//(STOD(FWTIMEUF(GETMV("MV_ESTADO"))[1]))
* 
***
Local lRet    := .T.

If dDatabase <> STOD(FWTIMEUF(GETMV("MV_ESTADO"))[1])
    Alert("N�o � permitido salvar a S.Compra com data diferente da data real. Hoje � dia:" + DtoC(sTod(FWTIMEUF(GETMV("MV_ESTADO"))[1])) )
    lRet := .F.
EndIf 

//DA110DATA := STOD(FWTIMEUF(GETMV("MV_ESTADO"))[1])

Return(lRet)
