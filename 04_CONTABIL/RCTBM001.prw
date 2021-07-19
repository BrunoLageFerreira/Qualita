#include "RWMAKE.ch"
#include "Colors.ch"
#include "Font.ch"
#Include "HBUTTON.CH"
#include "Topconn.ch"
#Include "Protheus.ch"
#include "tbiconn.ch"

/*  
Programa ...: RCTBM001.Prw
Uso ........: Processamento de carga inicial para geracao dos CTH 
              contabeis e ponto de entrada para inclusao de clientes 
              e fornecedores
Data .......: 05/01/2015
Feito por ..: Bruno Lage Ferreira   (33)8402-2125
Copyright ..: @1998-2001,2015 

Menu sigactb.xnu          
Obs.:
Estes programas podem ser usados pelo CTD ou CTH.
****************************************************************************
<MenuItem Status="Enable">
	<Title lang="pt">Carga Item Cont. Cli/For</Title>
	<Title lang="es">Carga Item Cont. Cli/For</Title>
	<Title lang="en">Carga Item Cont. Cli/For</Title>
	<Function>RCTBM001</Function>
	<Type>03</Type>
	<Tables>CTD</Tables>
	<Access>xxxxxxxxxx</Access>
	<Module>34</Module>
	<Owner>0</Owner>
</MenuItem>
****************************************************************************
*/                              

User Function MCTDFOR()          
************************************************************************************************
* // Vinculo ao ponto de entrada M020INC()
* // Inclusao no Item Contabil. //Fornecedor
***                              
dbSelectarea("CTH")
dbSetorder(1)
IF CTH->(Dbseek(xFilial("CTH")+"F"+SA2->(A2_COD+A2_LOJA)))
	_lGrv :=.f.
ELSE
	_lGrv :=.t.
ENDIF

If RecLock("CTH",_lGrv)
	CTH->CTH_FILIAL := xFilial("CTH")
	CTH->CTH_CLVL   := "F"+SA2->(A2_COD+A2_LOJA)
	CTH->CTH_DESC01 := SA2->A2_NOME
	CTH->CTH_CLASSE := "2"
	CTH->CTH_NORMAL := "1"
	CTH->CTH_BLOQ   := "2"
	CTH->CTH_DTEXIS := CtoD("01/01/2015")
	CTH->CTH_CLVLLP   := CTH->CTH_CLVL
	//CTH->CTH_CLOBRG := "2"
	//CTH->CTH_ACCLVL := "1"  
	CTH->CTH_BOOK   := "AUTO"
	MsUnlock("CTH")
EndIf

Return()            

User Function MCTDCLI()                       
************************************************************************************************
* // Vinculo ao ponto de entrada M030INC()
* // Inclusao no Item Contabil. //Cliente
***                   
dbSelectarea("CTH")
dbSetorder(1)
IF CTH->(Dbseek(xFilial("CTH")+"C"+SA1->(A1_COD+A1_LOJA)))
	_lGrv :=.f.
ELSE
	_lGrv :=.t.
ENDIF

If RecLock("CTH",_lGrv)
	CTH->CTH_FILIAL := xFilial("CTH")
	CTH->CTH_CLVL   := "C"+SA1->(A1_COD+A1_LOJA)
	CTH->CTH_DESC01 := SA1->A1_NOME
	CTH->CTH_CLASSE := "2"
	CTH->CTH_NORMAL := "2"
	CTH->CTH_BLOQ   := "2"
	CTH->CTH_DTEXIS := CtoD("01/01/2015")
	CTH->CTH_CLVLLP   := CTH->CTH_CLVL
	//CTH->CTH_CLOBRG := "2"
	//CTH->CTH_ACCLVL := "1"
	CTH->CTH_BOOK   := "AUTO"
	MsUnlock("CTH")
EndIf

Return()

User Function RCTBM001()        
************************************************************************************************
*
* /* Programa Princial*/
***                   
Local cQry := ''

If msgyesno("Confirma o Reprocessamento dos Itens Contabeis?")
  cQry := "DELETE FROM "+RetSqlName("CTH") + " Where CTH_BOOK  = 'AUTO' "
  TCSqlExec(cQry)
  TCSqlExec("commit")
  Processa({|| RunItem() },"Processando item...")
endif  

Return()

Static Function RunItem() 
************************************************************************************************
*
* /* Execucao */
***                   
Local nCont:=0      
        
/*
Clientes
*/
cQry := " SELECT DISTINCT 'C'+A1_COD+A1_LOJA AS CODIGO,
cQry += "  A1_NOME NOME,
cQry += " 'SA1' XALIAS,
cQry += " R_E_C_N_O_ XRECNO
cQry += " FROM "+RetSqlName("SA1") 
cQry += " WHERE D_E_L_E_T_ = ' '
 
cQry += " UNION 
        
/*
Fornecedores 
*/
cQry += " SELECT DISTINCT 'F'+A2_COD+A2_LOJA AS CODIGO,
cQry += " A2_NOME NOME,
cQry += " 'SA2' XALIAS,
cQry += " R_E_C_N_O_ XRECNO
cQry += " FROM "+RetSqlName("SA2") 
cQry += " WHERE D_E_L_E_T_ = ' '
cQry += " AND A2_COD NOT IN ('UNIAO','ESTADO','MUNIC','INPS','99999999')

cQry += " ORDER BY CODIGO      
      
//cQry := ChangeQuery(cQry)
dbUseArea(.T., "TOPCONN", TCGenQry(,,cQry), 'QRY', .F., .T.)
QRY->(dbGoTop())

DBGotop()
dbEval({|| nCont++})
ProcRegua(nCont)
DBGotop() 

CTH->(dbSetOrder(1))

While !QRY->(Eof())
    IncProc()
	If !CTH->(dbSeek(xFilial('CTH')+QRY->CODIGO))      
		dbSelectArea("CTH")
		If RecLock("CTH",.T.)
			CTH->CTH_FILIAL := xFilial("CTH")
			CTH->CTH_CLVL   := QRY->CODIGO
			CTH->CTH_DESC01 := QRY->NOME
			CTH->CTH_CLASSE := "2"
			CTH->CTH_NORMAL := IF(SUBSTR(QRY->CODIGO,1,1)=="F","1","2")
			CTH->CTH_BLOQ   := "2"
			CTH->CTH_DTEXIS := CtoD("01/01/2015")
			CTH->CTH_CLVLLP := CTH->CTH_CLVL
			//CTH->CTH_CLOBRG := "2"
			//CTH->CTH_ACCLVL := "1"
			CTH->CTH_BOOK   := "AUTO"
			MsUnlock("CTH")
		EndIf
	EndIf
	QRY->(dbSkip())
EndDo
  
QRY->(dbCloseArea())  

Return()   


//====================================================================================================================\\
/*/{Protheus.doc} MCT1FOR

Função chamada para incluir a conta contabil do fornecedor de forma automática

@author Bruno Lage 
@since 27/06/17
@version P11
@source MATA020

@type function

@param Nil, Nil, Não recebe parâmetros
@return Nil, Não tem retorno

@obs Chamada pelo PE M020INC

/*/
//====================================================================================================================\\

User Function MCT1FOR()

	//+----------------------------------------------------------+
	//| Declaração de Variáveis                                  |
	//+----------------------------------------------------------+
	Local aAreaOld	:= GetArea()
	Local cBaseCTA	:= "21101"
	Local cUltCTA	:= ""
	Local cUltRed	:= ""
	Local cQuery	:= ""
	Local cQueryA2	:= ""
	Local cCtaRef	:= PadR("2.01.01.03.01",TamSx3("CVD_CTAREF")[1])
	Local cCtaSup	:= PadR("2.01.01.03",TamSx3("CVD_CTAREF")[1])
	Local cMsgStop	:= ""
	Local lGravou	:= .T.

	//+----------------------------------------------------------+
	//| Fecha areas de trabalho abertas                          |
	//+----------------------------------------------------------+	
	If Select("MAXCTA") > 0
		dbSelectArea("MAXCTA")
		dbCloseArea()
	EndIf

	If Select("CTAFOR") > 0
		dbSelectArea("CTAFOR")
		dbCloseArea()
	EndIf

	//+----------------------------------------------------------+
	//| Verifica se ja tem fornecedor com esta base de CNPJ      |
	//| para pegar a conta contabil dele                         |
	//+----------------------------------------------------------+	
	cQueryA2 := "SELECT A2_CONTA "
	cQueryA2 += "FROM " + RetSqlName("SA2") + " SA2 "
	cQueryA2 += "WHERE D_E_L_E_T_ <> '*' "
	cQueryA2 += " AND ((A2_TIPO = 'J' AND LEFT(A2_CGC,8) = '"+Substr(SA2->A2_CGC,1,8)+"') OR (A2_TIPO <> 'J' AND A2_CGC = '"+SA2->A2_CGC+"')) "

	TcQuery cQueryA2 New Alias "CTAFOR"
	
	DbSelectArea("CTAFOR")
	DbGoTop()

	If CTAFOR->(!Eof()) .AND. !Empty(CTAFOR->A2_CONTA)

		cUltCTA := CTAFOR->A2_CONTA

	Else 

		//+----------------------------------------------------------+
		//| Query para buscar ultimos CT1_CONTA e CT1_RES            |
		//| Foram feitos filtros para tratar lixos na base           |
		//+----------------------------------------------------------+
		cQuery := "SELECT MAX(CT1_CONTA) ULCTA, MAX(CT1_RES) ULTRES " + CRLF
		cQuery += "FROM " + RetSqlName("CT1")+ " CT1 " + CRLF 
		cQuery += "WHERE D_E_L_E_T_ <> '*' " + CRLF  
		cQuery += "	AND LEFT(CT1_CONTA,5) = '"+cBaseCTA+"' " + CRLF 
		cQuery += "	AND CT1_CONTA NOT IN ('211010465','2110109999')  " + CRLF 

		TcQuery cQuery New Alias MAXCTA
		
		DbSelectArea("MAXCTA")
		DbGoTop()
		
		//+----------------------------------------------------------+
		//| Se trouxer resultados, coleta e grava na CT1             |
		//+----------------------------------------------------------+
		If MAXCTA->(!Eof())
			
			cUltCTA	:= Soma1(Alltrim(MAXCTA->ULCTA))
			cUltRED	:= Soma1(Alltrim(MAXCTA->ULTRES)) 

			//+---------------------+
			//| Grava os Dados      |
			//+---------------------+
			DbSelectArea("CT1")

			If Reclock("CT1",.T.)
			
				CT1_FILIAL	:= xFilial("CT1")
				CT1_CONTA	:= cUltCTA
				CT1_CTASUP  := "21101"  //MAX: 18/01/2018
				CT1_DESC01	:= SA2->A2_NOME
				CT1_RES		:= cUltRED
				CT1_CLASSE	:= '2'
				CT1_DTEXIS	:= CTOD("01/01/1980")
				CT1_BLOQ	:= '2'
				CT1_NORMAL	:= '2'
				CT1_NTSPED	:= '02'
				CT1_NATCTA	:= '02'
				MsUnlock("CT1")
				
				//+----------------------------------------------------------+
				//| Dados da Amarracao Conta x Referencial                   |
				//+----------------------------------------------------------+	
				If Reclock("CVD",.T.)


					CVD->CVD_FILIAL := xFilial('CVD')
					CVD->CVD_CONTA 	:= cUltCTA     
					CVD->CVD_ENTREF := PadR('10',TamSx3('CVD_ENTREF')[1])         //MAX: 18/01/2018
					CVD->CVD_CTAREF	:= cCtaRef 
					CVD->CVD_TPUTIL := 'A' 	
					CVD->CVD_CODPLA := PadR('004',TamSx3('CVD_CODPLA')[1])        //MAX: 18/01/2018   
					CVD->CVD_CLASSE := '2'
					CVD->CVD_NATCTA := '02'
					CVD->CVD_CTASUP := cCtaSup
					CVD->CVD_CUSTO	:= '' 

					MsUnlock("CVD")

				Else

					cMsgStop := "Nao conseguiu gravar amarracao plano de contas x Referencial" 
					ConOut(cMsgStop)
					MsgStop(cMsgStop)

				EndIf

			Else

				lGravou := .F.
				cMsgStop := "Nao conseguiu gravar conta contabil e amarracao plano de contas x Referencial"
				ConOut(cMsgStop)
				MsgStop(cMsgStop)

			EndIf	
		
		EndIf

	EndIf

	//+----------------------------------------------------+
	//| Grava a conta contabil no fornecedor               |
	//+----------------------------------------------------+
	If lGravou

		If Reclock("SA2",.F.)
		
			SA2->A2_CONTA	:= cUltCTA
			
			SA2->(MsUnlock())

		Else

			cMsgStop := "Nao foi possivel gravar a conta contabil no cadastro do fornecedor (A2_CONTA)"
			ConOut(cMsgStop)
			MsgStop(cMsgStop)
		
		EndIf

	EndIf	
	
   	//+----------------------------------------------------------+
	//| Fecha areas de trabalho abertas                          |
	//+----------------------------------------------------------+	
	If Select("MAXCTA") > 0
		dbSelectArea("MAXCTA")
		dbCloseArea()
	EndIf

	If Select("CTAFOR") > 0
		dbSelectArea("CTAFOR")
		dbCloseArea()
	EndIf		
	
	//+----------------------------------------------------------+
	//| Restaura a posição de memoria e ponteiro de arquivos     |
	//+----------------------------------------------------------+	
	RestArea(aAreaOld) 
	
	//+----------------------------------------------------------+
	//| Limpa Variaveis e memoria                                |
	//+----------------------------------------------------------+
	aAreaOld := aSize(aAreaOld,0)
	aAreaOld := Nil		

Return
