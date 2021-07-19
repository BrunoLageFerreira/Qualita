#INCLUDE "rwmake.ch"
#DEFINE __ENTER Chr(13) + Chr(10)

/*
+----------------------------------------------------------------------------+
|                        FICHA TECNICA DO PROGRAMA                           |
+----------------------------------------------------------------------------+
|   DADOS DO PROGRAMA                                                        |
+------------------+---------------------------------------------------------+
|Tipo              | Rotina                                                  |
+------------------+---------------------------------------------------------+
|Modulo            | Todos                                                   |
+------------------+---------------------------------------------------------+
|Nome              | Controle de Alertas - ContAlert                         |
+------------------+---------------------------------------------------------+
|Descricao         | Controle de Alertas - ContAlert                         |
+------------------+---------------------------------------------------------+
|Autor             | Bruno Lage Ferreira                                     |
+------------------+---------------------------------------------------------+
|Data de Criacao   | 09/11/2020                                              |
+------------------+---------------------------------------------------------+
|   ATUALIZACOES                                                             |
+-------------------------------------------+-----------+-----------+--------+
|   Descricao detalhada da atualizacao      |Nome do    | Analista  |Data da |
|                                           |Solicitante| Respons.  |Atualiz.|
+-------------------------------------------+-----------+-----------+--------+
|                                           |           |           |        |
|                                           |           |           |        |
+-------------------------------------------+-----------+-----------+--------+
*/

User Function ContAlert()
************************************************************************************************
*
*
*
***
//+------------------------------------------------------+
//| Declaração de Variáveis                              |
//+------------------------------------------------------+
Local cFiltra := "ZS9_USUARI == '"+Substr(cUsuario,7,15)+"' "
Private aIndexSZ2 := {}
Private cCadastro := "Controle de Alertas"
Private aRotina := { 	{"Pesquisar"	,"PesqBrw"	,0,1} ,;
						{"Visualizar"	,"AxVisual"	,0,2} ,;
						{"Incluir"		,"AxInclui"	,0,3} ,;
						{"Alterar"		,"AxAltera"	,0,4} ,;
						{"Excluir"		,"AxDeleta"	,0,5} ,;
						{"Legenda"		,"U_MLEGCA"	,0,7} }
						
Private aCores := {}

AADD(aCores,{"ZS9_TIPO == '3'" ,"BR_PINK"   }) //Ambos
AADD(aCores,{"ZS9_TIPO == '2'" ,"BR_VERDE"	}) //WhatsApp
AADD(aCores,{"ZS9_TIPO == '1'" ,"BR_BRANCO" }) //E-mail


Private cDelFunc := ".T." // 

Private cString := "ZS9"


dbSelectArea("ZS9")
dbSetOrder(1)

Private bFiltraBrw:= { || FilBrowse(cString,@aIndexSZ2,@cFiltra) }

Eval( bFiltraBrw )

 
dbSelectArea(cString)
mBrowse( 6,1,22,75,cString,,,,,,aCores)


EndFilBrw( cString , @aIndexSZ2 ) 


Return


User Function MLEGCA()
****************************************************************************************************************
* /*Legendas */  
*
****
	Local aLegenda := {}
	
	Aadd(aLegenda, {"BR_PINK"   ,"E-mail e WhatsApp" })
	Aadd(aLegenda, {"BR_VERDE"  ,"Somente WhatsApp"  })
	Aadd(aLegenda, {"BR_BRANCO" ,"Somente E-mail"    })
	
	BrwLegenda(cCadastro, "Legenda", aLegenda)
	              
Return()  
