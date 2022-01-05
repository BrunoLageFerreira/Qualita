#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"

/*
Programa ...: LstMULPag.Prw
Uso ........: Lista multi tabelas de Pagamento
Data .......: 30/09/2021
Feito por ..: Bruno Lage Ferreira 
*/

USER FUNCTION LstMULPag(cListAtu)
/*******************************************************************************************************
*
*
****/
LOCAL _CSQL 			:= ""
LOCAL _NOPC 			:= 0
LOCAL _CNOME			:= Space(30)
LOCAL lRet              := .f.
//Local cReturn			:= ""

PRIVATE CINDEXNAME	    := ''
PRIVATE CINDEXKEY 	    := ''
PRIVATE CFILTER 		:= ''

PRIVATE ALB1 			:= {}
PRIVATE OLB1
PRIVATE OOK				:= LOADBITMAP(GETRESOURCES(), "LBOK")
PRIVATE ONO				:= LOADBITMAP(GETRESOURCES(), "LBNO")

PUBLIC __cReturn		:= ""


_cSql	:= " SELECT	E4_CODIGO,
_cSql	+= "        E4_COND,
_cSql	+= "    	E4_DESCRI ,
_cSql	+= "    	R_E_C_N_O_
_cSql	+= " From
_cSql	+= "    "+RetSqlName("SE4")
_cSql	+= " Where
_cSql	+= "        D_E_L_E_T_ = ''
_cSql	+= " Order By
_cSql	+= "   E4_CODIGO

	_CSQL := CHANGEQUERY(_CSQL)
	DBUSEAREA(.T.,"TOPCONN",TCGENQRY(,,_CSQL),"SE4TMP")
	
	ALB1:= {}
	
	WHILE !SE4TMP->(EOF())
		
		AADD(ALB1,	{		IIF((SE4TMP->E4_CODIGO $ cListAtu),"*"," ")	,;
							SE4TMP->E4_CODIGO									,;
							SE4TMP->E4_COND 									,;
							SE4TMP->E4_DESCRI})
		
		SE4TMP->(DBSKIP())
	ENDDO                   
	
	SE4TMP->(DBCLOSEAREA())
	
	IF LEN(ALB1) = 0
		MSGINFO("Não existem dados para os parâmetros fornecidos!")
	ELSE
		DEFINE MSDIALOG _ODLGNF TITLE "Selecione a Condição de Pagamento:" FROM U_MGETTELA(178),U_MGETTELA(181) TO U_MGETTELA(548),U_MGETTELA(885) PIXEL
			@ U_MGETTELA(007),U_MGETTELA(005) 	LISTBOX OLB1 ;
								FIELDS HEADER	""				,;
												"Código"		,;
												"DIAS  "		,;
												"Descrição"		;
								SIZE U_MGETTELA(345),U_MGETTELA(163) OF _ODLGNF PIXEL				;
								COLSIZES	15	,;
											15	,;
											15	,;
											40
			OLB1:SETARRAY(ALB1)
			OLB1:BLINE := {|| {IIF(	ALB1[OLB1:NAT,01] = ' ',ONO,OOK)	,;
									ALB1[OLB1:NAT,02]					,;
									ALB1[OLB1:NAT,03]					,;
									ALB1[OLB1:NAT,04] }}
			
			OLB1:BLDBLCLICK := {|| ALB1[OLB1:NAT,01] := fVMTabClick() }
			
			//@ U_MGETTELA(172),U_MGETTELA(010) SAY "Nome da Tabela " PIXEL OF _ODLGNF
			//@ U_MGETTELA(171),U_MGETTELA(040) MSGET oNome VAR _CNOME PICTURE "@!" WHEN .T. SIZE U_MGETTELA(100),U_MGETTELA(8) PIXEL OF _ODLGNF
			
			//@ U_MGETTELA(172),U_MGETTELA(150) BUTTON "Procurar"        SIZE U_MGETTELA(050),U_MGETTELA(012) ACTION (SEARCHNOME(_CNOME)) 		PIXEL OF _ODLGNF
			//@ U_MGETTELA(172),U_MGETTELA(200) BUTTON "Marcar Todos"    SIZE U_MGETTELA(050),U_MGETTELA(012) ACTION (MARCTODOS()) 				PIXEL OF _ODLGNF
			@ U_MGETTELA(172),U_MGETTELA(250) BUTTON "Salvar"          SIZE U_MGETTELA(050),U_MGETTELA(012) ACTION (_NOPC:= 1,_ODLGNF:END())	PIXEL OF _ODLGNF
			@ U_MGETTELA(172),U_MGETTELA(300) BUTTON "Fechar "         SIZE U_MGETTELA(050),U_MGETTELA(012) ACTION (_NOPC:= 2,_ODLGNF:END())	PIXEL OF _ODLGNF
		ACTIVATE MSDIALOG _ODLGNF CENTERED
		
		IF _NOPC = 1
			
			FOR _NI := 1 TO LEN(ALB1)
				IF ALB1[_NI,1] = '*'
					__cReturn += "'" + ALB1[_NI,2] + "',"
				ENDIF
			NEXT
			__cReturn := substr(__cReturn,1,Len(__cReturn)-1)
			lRet := .T.
		ENDIF
	ENDIF

//M->A1_XCONDPG := __cReturn

RETURN(lRet)

Static Function fVMTabClick()
/*********************************************************************************************************************
* Valida se uma tabela preço com a mesma classificação ja foi escolhida 
* Só pode haver uma tabela de preço com a mesma classificação
****/
Local nMark  := OLB1:NAT
Local cTipo  := ALB1[OLB1:NAT,03]
Local cLoadT := "" 
Local cRet   := ""

FOR _NI := 1 TO LEN(ALB1)
	If ALB1[_NI,01] == '*'
		cLoadT := IIF(ALB1[_NI,02] $ cLoadT, cLoadT , cLoadT + ALB1[_NI,03] )
	EndIf
NEXT

If ALB1[OLB1:NAT,01] == '*'  
	cRet := ' '
ElseIf ALB1[OLB1:NAT,02] $ cLoadT
	cRet := ' '
	Alert("Esta tabela não pode ser selecionara pois já possui uma tabela cadastrada com esta classifição!")
Else
	cRet := IIF(ALB1[OLB1:NAT,01]=' ','*',' ')
EndIf

OLB1:REFRESH()

Return(cRet)
