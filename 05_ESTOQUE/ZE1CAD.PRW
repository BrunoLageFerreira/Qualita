#INCLUDE "Protheus.ch"
#INCLUDE "RwMake.ch"
#INCLUDE "topconn.ch" 
#INCLUDE "Colors.ch" 
#INCLUDE "JPEG.CH"

/*                                          
Programa ...: AxCadZE1.Prw
Uso ........: Cadastro de Endereços
Data .......: 26/08/19
Feito por ..: Bruno Lage Ferreira.
*/

User Function AxCadZE1()
****************************************************************************************************
*
*
***
AxCadastro("ZE1","Cadastro de Endereços")        

Return()

User function FncChavZE1(cCodEnd)
****************************************************************************************************
*
*
***
Local cQuery := ""
Local lRet   := .t. 

cQuery := " SELECT ZE1_ENDERE, COUNT(*) QTD
cQuery += "   FROM ZE1010 
cQuery += "  WHERE D_E_L_E_T_ = ''
cQuery += "    AND RTRIM(LTRIM(ZE1_ENDERE)) = '"+AllTrim(cCodEnd)+"' 
cQuery += "  GROUP BY ZE1_ENDERE 

dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "TRBZE1", .F., .T.)
dbSelectArea("TRBZE1")
dbgotop()
Do While !EOF()

    lRet   := .f. 
    Alert("Endereço já existe na base de dados. Favor verifique novo código!")

	dbSelectArea("TRBZE1")
	dbSkip()
EndDo

dbSelectArea("TRBZE1") 
dbCloseArea()


Return(lRet)
