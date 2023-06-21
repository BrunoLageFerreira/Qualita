#Include 'Protheus.ch'

/*/{Protheus.doc} MT094CPC.prw
@description 
@author PAZZINI
@since 07/03/16
@version 1.0
@type User function
/*/
User Function MT094CPC()
/************************************************************************************************************************
*
*
****/
Local cCampos := ""

cCampos := "C7_NOMEPC|C7_CC|C7_OBS|C7_OBSM|C7_QUJE|C7_DATPRF|C7_USER|C7_NUMSC|C7_XNOMESC|C7_OBS|C7_OBSM|C7_XMOTPC" 

Return (cCampos)
