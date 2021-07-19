#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
#INCLUDE "topconn.ch"


/*                                          
Programa ...: MPREVEND.Prw
Uso ........: Meta de Venda 
Data .......: 08/09/2020
Feito por ..: Bruno Lage Ferreira.

DETALHES
PERGUNTA E LEGENDA COMPARTILHADA FAVOR VERIFICAR ANTES DE ALTERAR
SZ7 - PROVISÃO DO PCP
*/

User Function MPREVEND()
****************************************************************************************************
*
*
***


Private aIndexZSB := {}

Private cCadastro := "Previsão de Vendas "

Private aRotina := { 	{"Pesquisar"	,"PesqBrw"			,0,1} ,;
						{"Visualizar"	,"AxVisual"			,0,2} ,;
						{"Incluir"		,"AxInclui"			,0,3} ,;
						{"Alterar"		,"AxAltera"			,0,4} ,;
						{"Excluir"		,"AxDeleta"			,0,5} ,;
						{"Replicar Mês"	,"U_MREPLPREV()"	,0,7} ,;
						{"Legenda"		,"U_LePROPCP()"		,0,7} }// LEGENDA COMPARTILHADA

Private aCores := {}

AADD(aCores,{"ZSB_ANO + ZSB_MES <  LEFT(dtos(dDataBase),6) " ,"BR_PRETO"	}) //Rejeitado
AADD(aCores,{"ZSB_ANO + ZSB_MES >  LEFT(dtos(dDataBase),6) " ,"BR_AZUL"	    }) //Já Autorizado
AADD(aCores,{"ZSB_ANO + ZSB_MES == LEFT(dtos(dDataBase),6) " ,"BR_VERDE" 	}) //A autorizar


Private cDelFunc := ".T." // Validacao para a exclusao. Pode-se utilizar ExecBlock

Private cString := "ZSB"


dbSelectArea("ZSB")
dbSetOrder(1)


dbSelectArea(cString)
mBrowse( 6,1,22,75,cString,,,,,,aCores)
//mBrowse( 6,1,22,75,cString,,,,,,aCores,,,,,,,,cFiltra) 

Return()


User Function MREPLPREV()
************************************************************************************************
*
*
*
***
Local aPerg  := {}
Local cPerg  := "MREPLIPROV" // PERGUNTA COMPARTILHADA VERIFICAR
Local cQuery := ""

Aadd(aPerg,{cPerg,"Ano de Origem?","C",04,00,"G","","","","","","","",""})
Aadd(aPerg,{cPerg,"Mês de Origem?","C",02,00,"G","","","","","","","",""})     

Aadd(aPerg,{cPerg,"Ano de Destino?","C",04,00,"G","","","","","","","",""})
Aadd(aPerg,{cPerg,"Mês de Destino?","C",02,00,"G","","","","","","","",""})     

U_Testasx1(cPerg,aPerg,.t.) 

If ! Pergunte(cPerg,.T.)
	Return
EndIf


dbSelectArea("ZSB")
dbSetOrder(1)
If dbSeek(mv_par03+mv_par04)
	Alert("Já existe na base dados referêntes a este mês.")
	Return()
EndIf

cQuery := " SELECT	ZSB_FILIAL,
cQuery += " 		ZSB_TPVEND,
cQuery += " 		ZSB_DESCRI,
cQuery += " 		ZSB_MES,
cQuery += " 		ZSB_ANO,
cQuery += " 		ZSB_02,
cQuery += " 		ZSB_03,
cQuery += " 		ZSB_CONTA,
cQuery += " 		ZSB_VLR01,
cQuery += " 		ZSB_VLR02,
cQuery += " 		ZSB_VLR03
cQuery += "  FROM ZSB010
cQuery += " WHERE ZSB_ANO+ZSB_MES = '" + mv_par01 + mv_par02 +"'
cQuery += "   AND D_E_L_E_T_ = ''

TcQuery cQuery Alias TMP_PROVEND New
		
dbSelectArea("TMP_PROVEND")     
dbGoTop()

Do While !EOF()         

	IF RecLock("ZSB",.T.)
		Replace ZSB->ZSB_ANO     With mv_par03
		Replace ZSB->ZSB_MES     With mv_par04
		Replace ZSB->ZSB_TPVEND  With TMP_PROVEND->ZSB_TPVEND
		Replace ZSB->ZSB_DESCRI  With TMP_PROVEND->ZSB_DESCRI
		Replace ZSB->ZSB_02      With TMP_PROVEND->ZSB_02
		Replace ZSB->ZSB_03      With TMP_PROVEND->ZSB_03
		Replace ZSB->ZSB_CONTA   With TMP_PROVEND->ZSB_CONTA // numero de container
		Replace ZSB->ZSB_VLR01   With TMP_PROVEND->ZSB_VLR01 // valor do ticked medido
		Replace ZSB->ZSB_VLR02   With TMP_PROVEND->ZSB_VLR02 // meta em dolar
		Replace ZSB->ZSB_VLR03   With TMP_PROVEND->ZSB_VLR03 // não usado
		MsUnLock()
	EndIf
    	
	dbSelectArea("TMP_PROVEND")
	dbSkip()
EndDo                    

dbSelectArea("TMP_PROVEND")
dbCloseArea()

AVISO("Salvando...", "Dados salvo com sucesso!" , { "Fechar" }, 1)

Return()