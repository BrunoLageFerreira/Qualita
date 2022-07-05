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
|Modulo            | Financeiro                                              |
+------------------+---------------------------------------------------------+
|Nome              | AutPag                                                  |
+------------------+---------------------------------------------------------+
|Descricao         | Manutencao de Solicita��es de Pagamento                 |
+------------------+---------------------------------------------------------+
|Autor             | Bruno Lage Ferreira                                     |
+------------------+---------------------------------------------------------+
|Data de Criacao   | 23/01/2012                                              |
+------------------+---------------------------------------------------------+
|   ATUALIZACOES                                                             |
+-------------------------------------------+-----------+-----------+--------+
|   Descricao detalhada da atualizacao      |Nome do    | Analista  |Data da |
|                                           |Solicitante| Respons.  |Atualiz.|
+-------------------------------------------+-----------+-----------+--------+
|                                           |           |           |        |
| MV_USRSOL                                 |           |           |        |
+-------------------------------------------+-----------+-----------+--------+
*/

User Function AutPag()
************************************************************************************************
*
*
*
***

	//+------------------------------------------------------+
	//| Declara��o de Vari�veis                              |
	//+------------------------------------------------------+
	Local cFiltra := "Z2_USRINCL == '"+Substr(cUsuario,7,15)+"' "

	Private aIndexSZ2 := {}

	Private cCadastro := "Solicita��es de Pagamento"

	Private aRotina := { 	{"Pesquisar"	,"PesqBrw"	,0,1} ,;
							{"Visualizar"	,"AxVisual"	,0,2} ,;
							{"Incluir"		,"U_Inclui"	,0,3} ,;
							{"Alterar"		,"U_Altera"	,0,4} ,;
							{"Excluir"		,"U_Deleta"	,0,5} ,;
							{"Legenda"		,"U_Legend"	,0,7} ,;
							{"Autorizar"	,"U_Autori"	,0,7} ,;
							{"Imprimir"		,"U_Imprim"	,0,7} ,;
							{"Relat�rio"	,"U_REL0028",0,7} ,;
							{"Rejeitar"		,"U_Rejeit"	,0,7} ,;
							{"Estornar"		,"U_Estorn"	,0,7}	}

	Private aCores := {}

	AADD(aCores,{"Z2_STATUS == '3'" ,"BR_PRETO"		}) //Rejeitado
	AADD(aCores,{"Z2_STATUS == '2'" ,"BR_VERMELHO"	}) //J� Autorizado
	AADD(aCores,{"Z2_STATUS == '1'" ,"BR_VERDE" 	}) //A autorizar


	Private cDelFunc := ".T." // Validacao para a exclusao. Pode-se utilizar ExecBlock

	Private cString := "SZ2"

	
	dbSelectArea("SZ2")
	dbSetOrder(1)


	//Somente para Qualita
	If SubString(CNUMEMP,1,2) == "01" 
		Private bFiltraBrw:= { || FilBrowse(cString,@aIndexSZ2,@cFiltra) }
		
		If !(RetCodUsr() $ GetMV("MV_USRSOL"))
			Eval( bFiltraBrw )
		EndIf
		
	EndIf
	 
	dbSelectArea(cString)
	mBrowse( 6,1,22,75,cString,,,,,,aCores)
	//mBrowse( 6,1,22,75,cString,,,,,,aCores,,,,,,,,cFiltra)
	
	EndFilBrw( cString , @aIndexSZ2 ) 


Return


User Function REL0028()
************************************************************************************************
*
*
*
***
Local cQuery   := ""
Local cUserRel := Substr(cUsuario,7,15)
Private aPerg  := {}
Private cPerg  := "MINREL0028"
                  
Aadd(aPerg,{cPerg,"Emiss�o de         ?","D",08,00,"G","","","","","","","",""})  
Aadd(aPerg,{cPerg,"Emiss�o At�        ?","D",08,00,"G","","","","","","","",""})  
Aadd(aPerg,{cPerg,"Vencimento de      ?","D",08,00,"G","","","","","","","",""})  
Aadd(aPerg,{cPerg,"Vencimento Ate     ?","D",08,00,"G","","","","","","","",""})  

U_Testasx1(cPerg,aPerg,.T.) 

If ! Pergunte(cPerg,.T.)
	Return
EndIf

/*
TABELA DE DADOS PRINCIPAIS
*/
cTabela   := "TB_RXX0028"

If TcCanOpen(cTabela)  
   lOk := TcDelFile(cTabela)   
Else  
	MsgInfo("Talbela "+cTabela+" nao encontrada.")
Endif	 

cQuery   := " SELECT Z2_NUM NumTITULO,
cQuery   += " 	   SED.ED_DESCRIC NaturezaDESC,
cQuery   += " 	   (RTRIM(LTRIM(Z2_FORNECE))+'-'+RTRIM(LTRIM(Z2_LOJA))) CODFOR,
cQuery   += " 	   Z2_NOMFOR NomeFOR,
cQuery   += " 	   Z2_TIPO TipoTitulo,
cQuery   += " 	   LTRIM(RTRIM(CAST(Z2_DESCRIC AS VARCHAR(200)))) Z2_DESCRIC ,  
cQuery   += " 	   CAST(Z2_EMISSAO AS DATE) EMISSAO,
cQuery   += " 	   CAST(Z2_VENCREA AS DATE) VENCIMENTO,
cQuery   += " 	   Z2_CCC CCUSTO,
cQuery   += " 	   Z2_SOLICIT SOLICITANTES,
cQuery   += " 	   Z2_VALOR VALOR,
cQuery   += " 	   CAST('"+DTOS(mv_par01)+"' AS DATE) EMISSAODE,
cQuery   += " 	   CAST('"+DTOS(mv_par02)+"' AS DATE) EMISSAOATE,
cQuery   += " 	   CAST('"+DTOS(mv_par03)+"' AS DATE) VENCIDE,
cQuery   += " 	   CAST('"+DTOS(mv_par04)+"' AS DATE) VENCIATE,
cQuery   += "      '" + cUserRel + "' USUARIO
cQuery   += "   INTO "+cTabela 
cQuery   += " 	   			FROM " + RetSqlName("SZ2") + " SZ2 INNER JOIN " + RetSqlName("SED") + " SED 
cQuery   += " 						 ON (SED.ED_CODIGO = SZ2.Z2_NATUREZ) 
cQuery   += " 						 AND Z2_EMISSAO >='"+DTOS(mv_par01)+"'  AND Z2_EMISSAO  <='"+DTOS(mv_par02)+"'			
cQuery   += " 						 AND Z2_VENCREA  >='"+DTOS(mv_par03)+"' AND Z2_VENCREA  <='"+DTOS(mv_par04)+"'
cQuery   += " 						 AND SZ2.D_E_L_E_T_=''
cQuery   += " 						 AND SED.D_E_L_E_T_=''
cQuery   += " 						 AND SZ2.Z2_USRINCL='"+cUserRel+"'
cQuery   += " 	ORDER BY  Z2_VENCTO,Z2_NUM,ED_DESCRIC

TcSQLExec(cQuery)	

u_RelInWeb("RXX0028")

Return()


User Function Autori()
************************************************************************************************
*
*
*
***

	PRIVATE lMsErroAuto := .F.

	//+------------------------------------------------------+
	//| Se o c�digo do usu�rio corrente estiver contido no   |
	//| par�metro MV_USRSOL, � porque ele tem permiss�o para |
	//| autorizar as solicita��es                            |
	//+------------------------------------------------------+
	If !(RetCodUsr() $ GetMV("MV_USRSOL"))
		MsgStop("Voc� n�o tem permiss�o para autorizar solicita��es","Erro")
		Return .F.
	EndIf

	//+------------------------------------------------------+
	//| Se a solicita��o estiver dispon�vel para autoriza��o |
	//+------------------------------------------------------+
	If SZ2->Z2_STATUS == "1"

		//+------------------------------------------------------+
		//| Verifica se j� existe o t�tulo autorizado no Contas a|
		//| pagar. Se j� existir, exibe mensagem e aborta        |
		//+------------------------------------------------------+
		DbSelectArea("SE2")
		DbSetOrder(1)
		//E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA 
		If DbSeek(xFilial("SE2")+SZ2->Z2_PREFIXO+SZ2->Z2_NUM+"  "+SZ2->Z2_TIPO+SZ2->Z2_FORNECE+SZ2->Z2_LOJA)

			MsgStop("� necess�rio deletar o titulo que j� foi autorizado no Contas a Pagar","Erro")
			DbCloseArea("SE2")
			Return .F.

			//+------------------------------------------------------+
			//| Se n�o existir, insere o t�tulo                      |
			//+------------------------------------------------------+
		Else

			aVet := {}
			aDadosBco := {}

			AADD(aVet,{"E2_FILIAL " 	,SZ2->Z2_FILIAL		,Nil} )
			AADD(aVet,{"E2_PREFIXO" 	,SZ2->Z2_PREFIXO	,Nil} )
			AADD(aVet,{"E2_NUM    " 	,SZ2->Z2_NUM 		,Nil} )
			AADD(aVet,{"E2_TIPO"    	,SZ2->Z2_TIPO		,Nil} )
			AADD(aVet,{"E2_NATUREZ" 	,SZ2->Z2_NATUREZ	,Nil} )
			If Alltrim(SZ2->Z2_TIPO) == "PA"
				Pergunte("AUTPA",.T.)	
				AADD(aVet,{"AUTBANCO"	 	,MV_PAR01		,Nil} )
				AADD(aVet,{"AUTAGENCIA"	 	,MV_PAR02		,Nil} )
				AADD(aVet,{"AUTCONTA" 	 	,MV_PAR03		,Nil} )
			Endif
			AADD(aVet,{"E2_FORNECE" 	,SZ2->Z2_FORNECE	,Nil} )
			AADD(aVet,{"E2_LOJA   " 	,SZ2->Z2_LOJA		,Nil} )
			AADD(aVet,{"E2_NOMFOR " 	,LEFT(SZ2->Z2_NOMFOR,20)		,Nil} )
			
			If Alltrim(SZ2->Z2_TIPO) == "PA"
				AADD(aVet,{"E2_EMISSAO" 	,dDataBase			,Nil} )
			Else
				AADD(aVet,{"E2_EMISSAO" 	,SZ2->Z2_EMISSAO	,Nil} )
			EndIf
			
			AADD(aVet,{"E2_VENCTO"		,SZ2->Z2_VENCTO		,Nil} )
			AADD(aVet,{"E2_VENCREA"		,SZ2->Z2_VENCREA	,Nil} )
			AADD(aVet,{"E2_VALOR"		,SZ2->Z2_VALOR		,Nil} )
			AADD(aVet,{"E2_MOEDA"		,SZ2->Z2_MOEDA		,Nil} )
			AADD(aVet,{"E2_TXMOEDA"		,SZ2->Z2_TXMOEDA	,Nil} )
			AADD(aVet,{"E2_CCD"			,SZ2->Z2_CCC		,Nil} )
			AADD(aVet,{"E2_HIST"		,SZ2->Z2_DESCRIC    ,Nil} )
			
			//Somente para Qualita
			If SubString(CNUMEMP,1,2) == "01" 
				AADD(aVet,{"E2_XINVOI"		,SZ2->Z2_XINVOI		,Nil} )
			EndIf
			
			AADD(aVet,{"E2_ORIGEM"		,"FINA050" 			,Nil} )

			SETFUNNAME("AUTPAG") 

			//FINA050(aVet,3,3, , )
			MsExecAuto( { |x,y,z| FINA050(x,y,z)}, aVet,, 3)  // 3 - Inclusao, 4 - Altera��o, 5 - Exclus�o

			If lMsErroAuto
				MostraErro()
			Else
				AVISO("Aprovado!", "T�tulo aprovado com sucesso!" , { "Fechar" }, 1)
				//Alert("T�tulo inclu�do com sucesso!")
			Endif


			//+----------------------------------------------------------+
			//| Muda Status para Autorizada e grava o respons�vel e data |
			//+----------------------------------------------------------+
			If Reclock("SZ2",.F.)
				SZ2->Z2_STATUS	:= "2"
				SZ2->Z2_DATALIB := dDataBase
				SZ2->Z2_APROVA	:= UsrFullName(__cUserID)
				SZ2->(MsUnlock())
			EndIf

			dbCloseArea("SE2")

		EndIf

	Else
		MsgStop("Esta autorizacao ja foi finalizada","Erro")
		Return .F.
	EndIf

Return


User Function Altera(cAlias, nReg, nOpc)
************************************************************************************************
*
*
*
***
Local aCampos := {}   


	//+------------------------------------------------------+
	//| Se a solicita��o est�est�                            |
	//+------------------------------------------------------+
	If SZ2->Z2_STATUS <> "1"
		MsgStop("Esta autoriza��o j� foi finalizada e n�o pode sofrer altera��es!","Erro")
		Return .F.
	EndIf

	
	If SubString(CNUMEMP,1,2) <> "01" 
		If SZ2->Z2_USRINCL <> Substr(cUsuario,7,15)
			MsgStop("S� � permitida a altera��o de solicita��es que voc� incluiu","Erro")
			Return .F.
		EndIf
	EndIf

	nOpca := AxAltera(cAlias,nReg   ,nOpc,,)
	

Return nOpca


User Function Estorn()
************************************************************************************************
*
*
*
***

	If !(RetCodUsr() $ GetMV("MV_USRSOL"))
		MsgStop("Voc� n�o tem permiss�o para estornar solicita��es","Erro")
		Return .F.
	EndIf

	If SZ2->Z2_STATUS <> "2"
		MsgStop("Esta autoriza��o ainda n�o foi aprovada e n�o pode ser estornada!","Erro")
		Return .F.
	EndIf

	cMsg := "Esta opera��o n�o apaga a CONTA A PAGAR j� inserida com a autoriza��o anterior" + __ENTER
	cMsg += "Ser� necess�rio deletar a conta gerada no CONTAS A PAGAR manualmente"

	MsgAlert(cMsg,"Aten��o")

	If Reclock("SZ2",.F.)
		SZ2->Z2_STATUS := "1"
		SZ2->(MsUnlock())
	EndIf

Return


User Function Inclui(cAlias, nReg, nOpc)
************************************************************************************************
*
*
*
***

	If(AxInclui("SZ2")==1)

		If Reclock("SZ2",.F.)

			SZ2->Z2_USRINCL := Substr(cUsuario,7,15)
			SZ2->Z2_DTINCLU := dDataBase

		EndIf

	EndIf

Return


User Function Deleta(cAlias, nReg, nOpc)
************************************************************************************************
*
*
*
***

	If SZ2->Z2_STATUS <> "1"
		MsgStop("Esta autoriza��o j� foi finalizada e n�o pode sofrer altera��es!","Erro")
		Return .F.
	EndIf

	nOpca := AxDeleta(cAlias,nReg,nOpc)

Return nOpca


User Function Imprim()
************************************************************************************************
*
*
*
***

	If SZ2->Z2_STATUS == "3"
		MsgStop("Esta solicita��o foi rejeitada e nao pode ser impressa.","Erro")
		Return .F.
	EndIf

	U_AUTPAGR()

Return


User Function Rejeit(cAlias, nReg, nOpc)
************************************************************************************************
*
*
*
***

	If SZ2->Z2_STATUS == "2"
		MsgStop("Esta autoriza��o j� foi finalizada e n�o pode sofrer altera��es!")
		Return .F.
	EndIf
	
	If MsgYesNo("Tem certeza que deseja rejeitar esta solicita��o ? Este processo � permanente e n�o tem volta.","Aten��o")
	
		If Reclock("SZ2",.F.)
	
			SZ2->Z2_STATUS := "3"
			SZ2->(MsUnlock())
	
		EndIf
	
	EndIf

Return


User Function Legend()
************************************************************************************************
*
*
*
***
Local aLegenda := {}

AADD(aLegenda,{"BR_VERDE" 	,"A autorizar" 		})
AADD(aLegenda,{"BR_VERMELHO","Autorizado" 		})
AADD(aLegenda,{"BR_PRETO" 	,"Nao Autorizado" 	})

BrwLegenda(cCadastro, "Legenda", aLegenda)

Return Nil
