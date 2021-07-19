#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
#INCLUDE "topconn.ch"


/*                                          
Programa ...: MPROPCP.Prw
Uso ........: Provisão do PCP
Data .......: 08/09/2020
Feito por ..: Bruno Lage Ferreira.
*/

User Function MPROPCP()
****************************************************************************************************
*
*
***


Private aIndexZS7 := {}

Private cCadastro := "Provisão do PCP"

Private aRotina := { 	{"Pesquisar"	,"PesqBrw"			,0,1} ,;
						{"Visualizar"	,"AxVisual"			,0,2} ,;
						{"Incluir"		,"AxInclui"			,0,3} ,;
						{"Alterar"		,"AxAltera"			,0,4} ,;
						{"Excluir"		,"AxDeleta"			,0,5} ,;
						{"Replicar Mês"	,"U_MREPLPROV()"	,0,7} ,;
						{"Legenda"		,"U_LePROPCP()"		,0,7} }




Private aCores := {}

AADD(aCores,{"ZS7_ANO + ZS7_MES <  LEFT(dtos(dDataBase),6) " ,"BR_PRETO"	}) //Rejeitado
AADD(aCores,{"ZS7_ANO + ZS7_MES >  LEFT(dtos(dDataBase),6) " ,"BR_AZUL"	    }) //Já Autorizado
AADD(aCores,{"ZS7_ANO + ZS7_MES == LEFT(dtos(dDataBase),6) " ,"BR_VERDE" 	}) //A autorizar


Private cDelFunc := ".T." // Validacao para a exclusao. Pode-se utilizar ExecBlock

Private cString := "ZS7"


dbSelectArea("ZS7")
dbSetOrder(1)


dbSelectArea(cString)
mBrowse( 6,1,22,75,cString,,,,,,aCores)
//mBrowse( 6,1,22,75,cString,,,,,,aCores,,,,,,,,cFiltra) 

Return()


User Function LePROPCP()
************************************************************************************************
*
*
*
***
Local aLegenda := {}

AADD(aLegenda,{"BR_VERDE" 	,"MES ATUAL" 		})
AADD(aLegenda,{"BR_AZUL"    ,"MES FUTURO" 		})
AADD(aLegenda,{"BR_PRETO" 	,"HISTORIO "     	})

BrwLegenda(cCadastro, "Legenda", aLegenda)

Return()

User Function MREPLPROV()
************************************************************************************************
*
*
*
***
Local aPerg  := {}
Local cPerg  := "MREPLIPROV"
Local cQuery := ""

Aadd(aPerg,{cPerg,"Ano de Origem?","C",04,00,"G","","","","","","","",""})
Aadd(aPerg,{cPerg,"Mês de Origem?","C",02,00,"G","","","","","","","",""})     

Aadd(aPerg,{cPerg,"Ano de Destino?","C",04,00,"G","","","","","","","",""})
Aadd(aPerg,{cPerg,"Mês de Destino?","C",02,00,"G","","","","","","","",""})     

U_Testasx1(cPerg,aPerg,.t.) 

If ! Pergunte(cPerg,.T.)
	Return
EndIf


dbSelectArea("ZS7")
dbSetOrder(1)
If dbSeek(mv_par03+mv_par04)
	Alert("Já existe na base dados referêntes a este mês.")
	Return()
EndIf

cQuery := " SELECT	ZS7_FILIAL,
cQuery += " 		ZS7_TPMATE,
cQuery += " 		ZS7_DESCRI,
cQuery += " 		ZS7_MES,
cQuery += " 		ZS7_ANO,
cQuery += " 		ZS7_02,
cQuery += " 		ZS7_03
cQuery += "  FROM ZS7010
cQuery += " WHERE ZS7_ANO+ZS7_MES = '" + mv_par01 + mv_par02 +"'
cQuery += "   AND D_E_L_E_T_ = ''


TcQuery cQuery Alias TMP_PROPCP New
		
dbSelectArea("TMP_PROPCP")     
dbGoTop()

Do While !EOF()         

	IF RecLock("ZS7",.T.)
		Replace ZS7->ZS7_ANO     With mv_par03
		Replace ZS7->ZS7_MES     With mv_par04
		Replace ZS7->ZS7_TPMATE  With TMP_PROPCP->ZS7_TPMATE
		Replace ZS7->ZS7_DESCRI  With TMP_PROPCP->ZS7_DESCRI
		Replace ZS7->ZS7_02      With TMP_PROPCP->ZS7_02
		Replace ZS7->ZS7_03      With TMP_PROPCP->ZS7_03
		MsUnLock()
	EndIf
    	
	dbSelectArea("TMP_PROPCP")
	dbSkip()
EndDo                    

dbSelectArea("TMP_PROPCP")
dbCloseArea()

AVISO("Salvando...", "Dados salvo com sucesso!" , { "Fechar" }, 1)


Return()