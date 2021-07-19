#Include "TopConn.ch"  
#Include "Rwmake.ch"

/*
Programa ...: MudaVend.Prw
Uso ........: Programa para mudar vendedor para outro vendedor automaticamente
Data .......: 17/03/2021
Feito por ..: Bruno Lage Ferreira 
*/

User Function MA030ROT()
/******************************************************************************************************
*
*
****/
Local aRotinaRet := {}

aAdd(aRotinaRet,{"Altera Vendedor","U_MudaVend()", 0 , 3, 0, .F.})	//"Muda Vendedor no cadastro"

Return(aRotinaRet)


User Function MudaVend()
/******************************************************************************************************
*
*
****/
Local   cQuery := ""
Private aPerg  := {}
Private cPerg  := "MUDAVENDED"

Aadd(aPerg,{cPerg,"Vendedor Atual   ?","C",06,00,"G","","SA3","","","","","",""})     
Aadd(aPerg,{cPerg,"Vendedor Destido ?","C",06,00,"G","","SA3","","","","","",""})     

U_Testasx1(cPerg,aPerg,.t.) 

If ! Pergunte(cPerg,.T.)
	Return
EndIf

iF !Empty(mv_par01) .And. !Empty(mv_par02)
    cQuery := " UPDATE " + RetSqlName("SA1")  
    cQuery += "    SET A1_VEND = '"+ mv_par02 +"'
    cQuery += "  FROM " + RetSqlName("SA1")
    cQuery += "  WHERE D_E_L_E_T_ <> '*'
    cQuery += "    AND A1_VEND = '"+ mv_par01 +"'
                
    TcSQLExec(cQuery)
    Alert("Alteração executada com sucesso!")
Else
    Alert("Alteração não executada!")
EndIf

Return()
