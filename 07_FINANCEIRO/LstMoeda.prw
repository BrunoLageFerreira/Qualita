#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"

/*
Programa ...: LSTMOEDA.Prw
Uso ........: Single Lista Moedas pela data atual
Data .......: 23/05/2022
Feito por ..: Bruno Lage Ferreira 

CONSULTA PADRÃO LMOEDA
*/

USER FUNCTION SLTMOEDA(cListAtu)
/*******************************************************************************************************
*
*
****/
LOCAL _CSQL 			:= ""
LOCAL lRet              := .f.
Local cTipoRet 			:= ValType(cListAtu)

PRIVATE _ODLGNF    

PRIVATE CINDEXNAME	    := ''
PRIVATE CINDEXKEY 	    := ''
PRIVATE CFILTER 		:= ''

PRIVATE ALB1 			:= {}
PRIVATE OLB1
PRIVATE OOK				:= LOADBITMAP(GETRESOURCES(), "LBOK")
PRIVATE ONO				:= LOADBITMAP(GETRESOURCES(), "LBNO")

PUBLIC __cReturn		:= ""

    _cSql	:= " SELECT  '1' ID_MOEDA,
    _cSql	+= " 		(REPLACE(CAST(CAST( GETDATE() AS DATE) AS VARCHAR(10)),'-','')) DATA,
    _cSql	+= " 		'BRL' REF_BC,
    _cSql	+= " 		'REAL' DESCRICAO,
	_cSql	+= "		'BRASIL' PAIS,
    _cSql	+= " 		1 COTACAO_ATUAL, 
    _cSql	+= " 		0 R_E_C_N_O_
    _cSql	+= " UNION ALL
    _cSql	+= " SELECT	YE_MOE_FIN,
    _cSql	+= " 		(REPLACE(CAST(CAST( GETDATE() AS DATE) AS VARCHAR(10)),'-','')) DATA,
    _cSql	+= " 		YE_MOEDA,
    _cSql	+= " 		(SELECT X6_DEFPOR FROM SX6010  WHERE D_E_L_E_T_ = '' AND X6_VAR = 'MV_MOEDA' + LTRIM(RTRIM(YE_MOE_FIN)) ) DESCRICAO,
	_cSql	+= " 	CASE 
	_cSql	+= "		WHEN RTRIM(LTRIM(YE_MOE_FIN)) = '2'  THEN 'EUA'
	_cSql	+= "		WHEN RTRIM(LTRIM(YE_MOE_FIN)) = '3'  THEN 'UNIAO EUROPEIA'
	_cSql	+= "		WHEN RTRIM(LTRIM(YE_MOE_FIN)) = '4'  THEN 'CANADA'
	_cSql	+= "		WHEN RTRIM(LTRIM(YE_MOE_FIN)) = '5'  THEN 'REINO UNIDO'
	_cSql	+= "		WHEN RTRIM(LTRIM(YE_MOE_FIN)) = '6'  THEN 'CHINA'
	_cSql	+= "		WHEN RTRIM(LTRIM(YE_MOE_FIN)) = '7'  THEN 'VIETNA'
	_cSql	+= "		WHEN RTRIM(LTRIM(YE_MOE_FIN)) = '8'  THEN 'ARÁBIA SAUDITA'
	_cSql	+= "		WHEN RTRIM(LTRIM(YE_MOE_FIN)) = '9'  THEN 'RUSSIA'
	_cSql	+= "		WHEN RTRIM(LTRIM(YE_MOE_FIN)) = '10' THEN 'MEXICO'
	_cSql	+= "	END PAIS,
    _cSql	+= " 		YE_VLCON_C COTACAO_ATUAL,
    _cSql	+= " 		R_E_C_N_O_
    _cSql	+= "   FROM "+RetSqlName("SYE") 
    _cSql	+= "  WHERE YE_DATA = (REPLACE(CAST(CAST( GETDATE() AS DATE) AS VARCHAR(10)),'-','')) 
    _cSql	+= "  ORDER BY R_E_C_N_O_

	DBUSEAREA(.T.,"TOPCONN",TCGENQRY(,,_CSQL),"SYETMP")
	
	ALB1:= {}
	
	WHILE !SYETMP->(EOF())
		
		AADD(ALB1,	{		 		" "											,;
									SYETMP->ID_MOEDA							,;
                                    STOD(SYETMP->DATA)							,;
                                    SYETMP->REF_BC 								,;
                                    AllTrim(SYETMP->DESCRICAO)				    ,;
									AllTrim(SYETMP->PAIS)					    ,;
                                    SYETMP->COTACAO_ATUAL						;  
					};
			)
		
		SYETMP->(DBSKIP())
	ENDDO                   
	
	SYETMP->(DBCLOSEAREA())
	
	IF LEN(ALB1) = 0
		MSGINFO("Não existem dados para os parâmetros fornecidos!")
	ELSE
		DEFINE MSDIALOG _ODLGNF TITLE "Selecione a Moeda:" FROM U_MGETTELA(178),U_MGETTELA(181) TO U_MGETTELA(548),U_MGETTELA(885) PIXEL
			@ U_MGETTELA(007),U_MGETTELA(005) 	LISTBOX OLB1      ;
								FIELDS HEADER	""				 ,;
												"ID      "		 ,;
												"DATA"   		 ,;
                                                "BANCO CENTRAL " ,;
                                                "NOME DA MOEDA " ,;
												"PAÍS ORIGEM  "  ,; 
												"COTACAO_ATUAL"	 ;
								SIZE U_MGETTELA(345),U_MGETTELA(163) OF _ODLGNF PIXEL				;
								COLSIZES	5	,;
											15	,;
											5	,;
                                            25	,;
											25	,;
                                            25	,;
											5
			OLB1:SETARRAY(ALB1)
			OLB1:BLINE := {|| {IIF(	ALB1[OLB1:NAT,01] = ' ',ONO,OOK)	,;
									ALB1[OLB1:NAT,02]					,;
									ALB1[OLB1:NAT,03]					,;
                                    ALB1[OLB1:NAT,04]					,;
                                    ALB1[OLB1:NAT,05]					,;
									ALB1[OLB1:NAT,06]					,;
									ALB1[OLB1:NAT,07] }}
			
			OLB1:BLDBLCLICK := {|| __cReturn := iif(cTipoRet='N',val(AllTrim(fVMTabClick())),AllTrim(fVMTabClick()))   , lRet:=.T. , _ODLGNF:END() }
			
			@ U_MGETTELA(172),U_MGETTELA(300) BUTTON "Fechar "         SIZE U_MGETTELA(050),U_MGETTELA(012) ACTION (_ODLGNF:END())	PIXEL OF _ODLGNF
		ACTIVATE MSDIALOG _ODLGNF CENTERED
		
	ENDIF

RETURN(lRet)

Static Function fVMTabClick()
/*********************************************************************************************************************
* 
*
****/
Local nMark  := OLB1:NAT
Local _NI    := 0


FOR _NI := 1 TO LEN(ALB1)
	If  _NI == nMark
		ALB1[_NI,01] := '*'
		__cReturn := ALB1[_NI,2]
		OLB1:REFRESH()
	EndIf
NEXT

Return(__cReturn)
