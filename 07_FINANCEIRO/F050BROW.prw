#include "rwmake.ch"
#include "TOPCONN.CH"
#Include 'Protheus.ch'

/*                                          
Programa ...: F050BROW.Prw
Uso ........: Ponto de Entrada (ALTERACAO DO CP)
Data .......: 11/10/16
Feito por ..: Bruno Lage Ferreira.
*/


/*
User Function F050MCP()
*************************************************************************************************************
*
*
***    

Local aCPO := paramixb

AADD(aCPO,"E2_VALOR")	

Return(aCPO)
*/

User Function F050BROW()
*************************************************************************************************************
*
*
***    
	Local aRotinaX := {}

	//aadd(aRotinaX,{"Alterar","FA050ALTER",0,4})
	aadd(aRotinaX,{"Prov/Venc","u_AlterProvi()",0,4})
	aadd(aRotinaX,{"Valor"    ,"u_AlteraVlr()" ,0,4})
	aadd(aRotinaX,{"Natureza" ,"u_AlteraNat()" ,0,4})

	IF FUNNAME() == "FINA050"
		aRotina[4][2] := aRotinaX
	Else
		/*
		For nX := 1 To Len(aRotina)
			If aRotina[nX][1] == "Alterar"
				aRotina[4][1] := "Prov/Venc/Nat"
				aRotina[4][2] := "u_AlterProvi()"
			EndIf 
		Next Nx
		*/
	EndIf

Return()   

User Function AlteraNat()                                 
*************************************************************************************************************
*
*
*** 
Local cEdit1	 := SE2->E2_NATUREZ
Local cNatOrig	 := SE2->E2_NATUREZ
Local oEdit1

// Variaveis Private da Funcao
Private _oDlg				// Dialog Principal
// Variaveis que definem a Acao do Formulario                    

If !Empty(SE2->E2_BAIXA) 
	Alert("Este título já possui báixa(s) e não poderá sofrer alterações!")
	Return()
EndIf


	DEFINE MSDIALOG _oDlg TITLE "Altera natureza do Título:"   FROM u_MGETTELA(223),u_MGETTELA(173) TO u_MGETTELA(359),u_MGETTELA(520) PIXEL
	
		// Cria as Groups do Sistema
		@ u_MGETTELA(003),u_MGETTELA(005) TO u_MGETTELA(044),u_MGETTELA(168) LABEL "" PIXEL OF _oDlg
	
		// Cria Componentes Padroes do Sistema
		@ u_MGETTELA(015),u_MGETTELA(089) MsGet oEdit1 Var cEdit1 Size u_MGETTELA(060),u_MGETTELA(009) F3("SED") COLOR CLR_BLACK PIXEL OF _oDlg
		@ u_MGETTELA(016),u_MGETTELA(014) Say "Nova Natureza:" Size u_MGETTELA(066),u_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlg
		@ u_MGETTELA(047),u_MGETTELA(131) Button "Ok" Size u_MGETTELA(037),u_MGETTELA(012)  ACTION( fGravNat(cEdit1,cNatOrig))  PIXEL OF _oDlg
			
	ACTIVATE MSDIALOG _oDlg CENTERED


Return(.T.)

Static Function fGravNat(cNatNew,cNatAnt)
/************************************************************************************
*
*
****/
Local cQuery := ""

cQuery := "	SELECT COUNT(*) QTD
cQuery += "	  FROM " + RetSqlName("SE2") +" SE2 
cQuery += "						INNER JOIN " + RetSqlName("SED") +" SED
cQuery += "							ON (RTRIM(LTRIM(ED_CODIGO)) = RTRIM(LTRIM(E2_NATUREZ)) )
cQuery += "				        INNER JOIN " + RetSqlName("SEV") +" SEV
cQuery += "							ON (E2_FILIAL = EV_FILIAL AND E2_NUM = EV_NUM AND E2_PREFIXO = EV_PREFIXO AND E2_FORNECE = EV_CLIFOR AND E2_LOJA = EV_LOJA AND E2_TIPO = EV_TIPO AND EV_PARCELA= E2_PARCELA)
cQuery += "						WHERE		SE2.D_E_L_E_T_ = ''
cQuery += "								AND SED.D_E_L_E_T_ = ''
cQuery += "								AND SEV.D_E_L_E_T_ = ''
cQuery += "								AND E2_NUM      = '"+ SE2->E2_NUM     +"'
cQuery += "								AND E2_EMISSAO  = '"+ DTOS(SE2->E2_EMISSAO) +"'
cQuery += "								AND E2_FORNECE  = '"+ SE2->E2_FORNECE +"'
cQuery += "								AND E2_LOJA	    = '"+ SE2->E2_LOJA    +"'
cQuery += "								AND E2_PREFIXO  = '"+ SE2->E2_PREFIXO +"'
cQuery += "								AND E2_TIPO     = '"+ SE2->E2_TIPO    +"'
cQuery += "	GROUP BY E2_FILIAL ,EV_FILIAL , E2_NUM , EV_NUM , E2_PREFIXO , EV_PREFIXO ,E2_FORNECE , EV_CLIFOR , E2_LOJA , EV_LOJA , E2_TIPO , EV_TIPO , EV_PARCELA, E2_PARCELA
cQuery += "	HAVING COUNT(*) >1

TcQuery cQuery Alias TMP_QTDSEV New
dbSelectArea("TMP_QTDSEV")

if TMP_QTDSEV->QTD > 1

	dbSelectArea("TMP_QTDSEV")
	dbCloseArea()    

	AVISO("Erro na Alteração", "Este título possui mais de 1 natureza. Para esta manutenção é nessário exclui a NF-e!", { "Fechar" }, 1)
	Return()
EndIf
	                   
dbSelectArea("TMP_QTDSEV")
dbCloseArea()        

cQuery := "	UPDATE " + RetSqlName("SEV") +" 
cQuery += "	   SET EV_NATUREZ = '"+cNatNew+"'
cQuery += "	  FROM " + RetSqlName("SE2") +" SE2 
cQuery += "						INNER JOIN " + RetSqlName("SED") +" SED
cQuery += "							ON (RTRIM(LTRIM(ED_CODIGO)) = RTRIM(LTRIM(E2_NATUREZ)) )
cQuery += "				        INNER JOIN " + RetSqlName("SEV") +" SEV
cQuery += "							ON (E2_FILIAL = EV_FILIAL AND E2_NUM = EV_NUM AND E2_PREFIXO = EV_PREFIXO AND E2_FORNECE = EV_CLIFOR AND E2_LOJA = EV_LOJA AND E2_TIPO = EV_TIPO AND EV_PARCELA= E2_PARCELA)
cQuery += "						WHERE		SE2.D_E_L_E_T_ = ''
cQuery += "								AND SED.D_E_L_E_T_ = ''
cQuery += "								AND SEV.D_E_L_E_T_ = ''
cQuery += "								AND E2_NUM      = '"+ SE2->E2_NUM     +"'
cQuery += "								AND E2_EMISSAO  = '"+ DTOS(SE2->E2_EMISSAO) +"'
cQuery += "								AND E2_FORNECE  = '"+ SE2->E2_FORNECE +"'
cQuery += "								AND E2_LOJA	    = '"+ SE2->E2_LOJA    +"'
cQuery += "								AND E2_PREFIXO  = '"+ SE2->E2_PREFIXO +"'
cQuery += "								AND E2_TIPO     = '"+ SE2->E2_TIPO    +"'

TcSQLExec(cQuery)

IF RecLock("SE2",.F.)
	Replace SE2->E2_NATUREZ  With cNatNew
	MsUnLock()
EndIf

AVISO("Nova natureza", "Natureza alterada com sucesso!", { "Fechar" }, 1)

axVisual("SE2",Recno(),1)

Close(_oDlg)

Return()



User Function AlteraVlr()                                 
*************************************************************************************************************
*
*
*** 
Local cEdit1	 := SE2->E2_VALOR
Local oEdit1

// Variaveis Private da Funcao
Private _oDlg				// Dialog Principal
// Variaveis que definem a Acao do Formulario                    

If !Empty(SE2->E2_BAIXA) 
	Alert("Este título já possui báixa(s) e não poderá sofrer alterações!")
	Return()
EndIf


	DEFINE MSDIALOG _oDlg TITLE "Altera Valor do Título:"   FROM u_MGETTELA(223),u_MGETTELA(173) TO u_MGETTELA(359),u_MGETTELA(520) PIXEL
	
		// Cria as Groups do Sistema
		@ u_MGETTELA(003),u_MGETTELA(005) TO u_MGETTELA(044),u_MGETTELA(168) LABEL "" PIXEL OF _oDlg
	
		// Cria Componentes Padroes do Sistema
		@ u_MGETTELA(015),u_MGETTELA(089) MsGet oEdit1 Var cEdit1 Size u_MGETTELA(060),u_MGETTELA(009) picture("@E 999,999,999.99") COLOR CLR_BLACK PIXEL OF _oDlg
		@ u_MGETTELA(016),u_MGETTELA(014) Say "Novo Valor:" Size u_MGETTELA(066),u_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlg
		@ u_MGETTELA(047),u_MGETTELA(131) Button "Ok" Size u_MGETTELA(037),u_MGETTELA(012)  ACTION( fGravValor(cEdit1))  PIXEL OF _oDlg
			
	ACTIVATE MSDIALOG _oDlg CENTERED


Return(.T.)

Static Function fGravValor(nVlr)
/************************************************************************************
*
*
****/
IF RecLock("SE2",.F.)
	Replace SE2->E2_VALOR  With nVlr
	Replace SE2->E2_SALDO  With nVlr
	Replace SE2->E2_VLCRUZ With nVlr
	MsUnLock()
EndIf

AVISO("Novo Valor", "Valor Alterado com Sucesso!", { "Fechar" }, 1)

axVisual("SE2",Recno(),1)

Close(_oDlg)

Return()

User Function AlterProvi()   
*************************************************************************************************************
*
*
*** 
Local aCampos := {}   

	IF EMPTY(SE2->E2_BAIXA)
		aAdd(aCampos,"E2_PROVISA")
		aAdd(aCampos,"E2_VENCTO") 
		aAdd(aCampos,"E2_VENCREA")	
		//aAdd(aCampos,"E2_VALOR")  
		aAdd(aCampos,"E2_CCD")    
		aAdd(aCampos,"E2_ACRESC") 
		aAdd(aCampos,"E2_NATUREZ")
		aAdd(aCampos,"E2_DECRESC")
		aAdd(aCampos,"E2_HIST")   
	EndIf
	
	aAdd(aCampos,"E2_PROVISA")
	
	axAltera("SE2",Recno(),4,,aCampos)

Return()
