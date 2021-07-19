#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
#INCLUDE "TOPCONN.CH"

/*                                          
Programa ...: MCLASSIFI.Prw
Uso ........: CLASSIFICAÇÃO
Data .......: 14/09/19
Feito por ..: Bruno Lage Ferreira.
*/

User Function MCLASSIFI()  
/**********************************************************************************************************************************************
*
*
****/      
Local _astru     :={}
Local _afields   :={}     
Local _carq             
Private arotina  :={}   
Private cCadastro 
Private cMark    :=GetMark()

aRotina   := { 	{ "Marcar Todos [F5]","U_MARCARF" 		, 0, 4},;               
				{ "Desmarcar Todos"  ,"U_DESMARCLA"  	, 0, 4},;  
				{ "Filtra Dados [F4]","U_MfiltCLASS"  	, 0, 3},;
				{ "Grava Dados  [F6]","U_MGravCLASS" 	, 0, 1},;
				{ "Inverter Todos   ","U_MARKALLCLA" 	, 0, 4}}   

cCadastro := "Alteração de Classificação de Produtos"

SetKey(VK_F4,{||u_MfiltCLASS()})
SetKey(VK_F5,{||U_MARCARF()})
SetKey(VK_F6,{||u_MGravCLASS()})
 				
// Estrutura da tabela temporaria
AADD(_astru,{"OK"		,"C",002,0})
AADD(_astru,{"CAVALETE"	,"C",006,0})
AADD(_astru,{"LOTE"		,"C",010,0})
AADD(_astru,{"CHAPA"	,"C",004,0})
AADD(_astru,{"PRODUTO"	,"C",015,0})
AADD(_astru,{"NOME"		,"C",120,0})
AADD(_astru,{"CLASSIF"	,"C",020,0})
AADD(_astru,{"DATAM"	,"D",008,0})
AADD(_astru,{"USUARIO"	,"C",030,0})


// cria a tabela temporária
_carq:="T_"+Criatrab(,.F.)
MsCreate(_carq,_astru,"TOPCONN") 
// atribui a tabela temporária ao alias TRB
dbUseArea(.T.,"TOPCONN",_cARq,"TRB",.T.,.F.)

AADD(_afields,{"OK"			,"","X"	   		})
AADD(_afields,{"CAVALETE"	,"","CAVALETE"	})
AADD(_afields,{"LOTE"		,"","LOTE"		})
AADD(_afields,{"CHAPA"		,"","CHAPA"		})
AADD(_afields,{"PRODUTO"	,"","PRODUTO"	})
AADD(_afields,{"NOME"		,"","NOME"		})
AADD(_afields,{"CLASSIF"	,"","CLASSIFICAÇÃO"	})
AADD(_afields,{"DATAM"		,"","DATA MOVIMENTO"})
AADD(_afields,{"USUARIO"	,"","USUARIO"	})


DBSELECTAREA("TRB")

//MarkBrow( 'TRB', 'OK',,_afields,, cMark,'u_MarkAll()',,,,'u_MarkCLASS()',{|| u_MarkAll()}) 
MarkBrow( 'TRB', 'OK',,_afields,, cMark,'u_MarkAllCLA()',,,,'u_MarkCLASS()',{|| })

DbCloseArea()      				

// fecha a tabela temporária
MsErase(_carq+GetDBExtension(),,"TOPCONN")	
// apaga a tabela temporária

Return()


User Function MGravCLASS()
/*********************************************************************************************************************************************
*
*
***/
Local oMark := GetMarkBrow()
Local cCLassif := ""
Local cClassId  := ""
Local cQuery:=""

Private aPerg := {}
Private cPerg := "MGRAVCLASS"

Aadd(aPerg,{cPerg,"Classificação  ?","N",01,00,"C","","","STANDARD","COMMERCIAL","PREMIUM","SAMPLE","",""})

U_Testasx1(cPerg,aPerg,.T.)

If ! Pergunte(cPerg,.T.)
	Return()
EndIf

If Empty(mv_par01)
	Alert("Endereço não pode ser em branco!")
	Return()
EndIf


If MsgYesNo("Deseja alterar a classificação do produtos ?" )

	DBSELECTAREA("TRB")
	dbGoTop()	
	While (!Eof())
	
		/*
		Verifica se o produto possui saldo 
		antes de entrar no update
		*/
		cQuery:=" SELECT B8_SALDO
		cQuery+="   FROM SB8010 SB8 
		cQuery+="  WHERE SB8.D_E_L_E_T_ = ''
	    cQuery+="    AND B8_PRODUTO = '"+TRB->PRODUTO+"'
	    cQuery+="    AND B8_LOTECTL = '"+TRB->LOTE   +"'
	    cQuery+="    AND B8_NUMLOTE = '"+TRB->CHAPA  +"'
	    cQuery+="    AND LEFT(B8_PRODUTO,2) IN ('CH','AM') 
	    cQuery+="    AND B8_SALDO <> 0
	    cQuery+="    AND B8_ORIGLAN <> 'BD'
	    
	    TcQuery cQuery Alias TRB_UPD New
	    
	    dbSelectArea("TRB_UPD")
	    dbGoTop()
	   
		IF TRB_UPD->B8_SALDO <> 0
		
			DBSELECTAREA("TRB")
	
			If mv_par01 == 1
				cCLassif := "STANDARD"
				cClassId := "S"
			ElseIf mv_par01 == 2
				cCLassif := "COMMERCIAL"
				cClassId := "C"
			ElseIf mv_par01 == 3
				cCLassif := "PREMIUM"
				cClassId := "P"
			ElseIf mv_par01 == 4
				cCLassif := "SAMPLE"
				cClassId := "A"
			EndIf
			
			If IsMark( 'OK', cMark )
				DBSELECTAREA("TRB")	
				RECLOCK("TRB",.F.) 				
					TRB->CLASSIF 	:= cCLassif
					TRB->DATAM 		:= dDataBase
					TRB->USUARIO 	:= SUBSTR(CUSUARIO,7,15)
				MSUNLOCK()
				
				cQuery:=" UPDATE SB8010
				cQuery+="   SET B8_XDTMOVE ='"+dToS(dDataBase)+"',B8_YCLASSI='"+Alltrim(cClassId)+"',B8_XPUSUAR='"+SUBSTR(CUSUARIO,7,15)+"'
				cQuery+="  	FROM SB8010 SB8 
				cQuery+=" WHERE SB8.D_E_L_E_T_ = ''
				cQuery+="   AND B8_PRODUTO = '"+TRB->PRODUTO+"'
				cQuery+="   AND B8_LOTECTL = '"+TRB->LOTE   +"'
				cQuery+="   AND B8_NUMLOTE = '"+TRB->CHAPA  +"'
				cQuery+="   AND LEFT(B8_PRODUTO,2) IN ('CH','AM') 
				cQuery+="   AND B8_SALDO <> 0
				cQuery+="   AND B8_ORIGLAN <> 'BD'
			
				TcSQLExec(cQuery)
			EndIf
			
		Else
			Alert("Este registro já não possui mais saldo! PRODUTO:" + TRB->PRODUTO + " LOTE:" +TRB->LOTE   + " SUBLOTE:" + TRB->CHAPA  )
		EndIf
		
		/*
		Destroi a area temporaria de consulta de saldo antes do update
		*/
		dbSelectArea("TRB_UPD")
		DBCloseArea()
		
		DbSelectArea("TRB")
		DBSKIP()
	EndDo

 MarkBRefresh( )
 
 // atualiza o browse
 oMark:oBrowse:Gotop()

EndIf

Return()

User Function MfiltCLASS()
/*********************************************************************************************************************************************
*
*
***/
Local cQuery := ""
Local aLote    := {}
Local aChapa   := {}

Private aPerg := {}
Private cPerg := "MALTCLASSI"

//Aadd(aPerg,{cPerg,"Empresa/Filial Destino?","C",06,00,"G","","SM0","","","","","",""})     
Aadd(aPerg,{cPerg,"Lote Qualitá (Separar usando [,])?"	,"C",99,00,"G","","","","","","","",""})     
Aadd(aPerg,{cPerg,"Chapa (Separar usando [,])?"		,"C",99,00,"G","","","","","","","",""})

U_Testasx1(cPerg,aPerg,.F.)

If ! Pergunte(cPerg,.T.)
	Return()
EndIf

aLote    := strtokarr (AllTrim(mv_par01), ",")
aChapa   := strtokarr (AllTrim(mv_par02), ",")

cQuery := " SELECT	B8_LOCAL   AS LOCAL,
cQuery += " 		NNR_DESCRI AS LOCAL_DES,		
cQuery += " 		B8_PRODUTO AS PRODUTO,
cQuery += " 		B1_DESC    AS PRODUTO_DESC,
cQuery += " 		CAST(B8_DATA AS DATE) AS FABRIC,
cQuery += " 		RIGHT(RTRIM(LTRIM(B8_PRODUTO)),2) AS TIPO,
cQuery += " 		CASE 
cQuery += " 			WHEN RTRIM(LTRIM(B8_YCLASSI)) = 'S' THEN 'STANDARD'
cQuery += " 			WHEN RTRIM(LTRIM(B8_YCLASSI)) = 'C' THEN 'COMMERCIAL'
cQuery += " 			WHEN RTRIM(LTRIM(B8_YCLASSI)) = 'P' THEN 'PREMIUM'
cQuery += " 			WHEN RTRIM(LTRIM(B8_YCLASSI)) = ''  THEN 'PREMIUM' 
cQuery += " 			WHEN RTRIM(LTRIM(B8_YCLASSI)) = 'A' THEN 'SAMPLE'
cQuery += " 			END CLASSIFICACAO, 
cQuery += " 		B8_YCAVALE AS CAVALETE,
cQuery += " 		B8_LOTECTL AS LOTE,
cQuery += " 		B8_NUMLOTE AS SUBLOTE, 
cQuery += " 		ISNULL((SELECT TOP 1 C6_NUM FROM SC6010 WHERE D_E_L_E_T_ = '' AND B8_LOTECTL = C6_LOTECTL AND B8_NUMLOTE = C6_NUMLOTE AND B8_PRODUTO = C6_PRODUTO ),'') AS PEDIDO_VENDA,
cQuery += " 		IIF(ISNULL((SELECT TOP 1 C6_NUM FROM SC6010 WHERE D_E_L_E_T_ = '' AND B8_LOTECTL = C6_LOTECTL AND B8_NUMLOTE = C6_NUMLOTE AND B8_PRODUTO = C6_PRODUTO ),'')<>'',B8_SALDO,0) AS RESERVADO ,
cQuery += " 		B8_SALDO   AS SALDO,
cQuery += " 		B8_XENDERE ENDERECO, 
cQuery += " 		B8_XDTMOVE DATAM,
cQuery += " 		B8_XPUSUAR USUARIO
cQuery += " 	FROM SB8010 SB8 INNER JOIN NNR010 NNR
cQuery += " 		ON (NNR_CODIGO = B8_LOCAL)
cQuery += " 		INNER  JOIN SB1010 SB1 
cQuery += " 		ON (B1_COD = B8_PRODUTO)
cQuery += " 	WHERE SB8.D_E_L_E_T_ = ''
cQuery += " 	AND SB1.D_E_L_E_T_ = ''
cQuery += " 	AND NNR.D_E_L_E_T_ = ''

If Len(aLote)>0
	For nX:=1 to Len(aLote)
	 	If nX = 1
	 		cQuery += " AND (B8_LOTECTL LIKE '%"+AllTrim(aLote[nX])+"%' "
	 	Else
	 		cQuery += " OR  B8_LOTECTL LIKE '%"+AllTrim(aLote[nX])+"%' "
	 	EndIf
	Next nX
	cQuery += " )"
EndIf

If Len(aChapa)>0
	For nX:=1 to Len(aChapa)
	 	If nX = 1
	 		cQuery += " AND (B8_NUMLOTE LIKE '%"+AllTrim(aChapa[nX])+"%' "
	 	Else
	 		cQuery += " OR  B8_NUMLOTE LIKE '%"+AllTrim(aChapa[nX])+"%' "
	 	EndIf
	Next nX
	cQuery += " )"
EndIf

cQuery += " 	AND LEFT(B8_PRODUTO,2) IN ('CH','AM') 
cQuery += " 	AND B8_SALDO <> 0
cQuery += "     AND B8_ORIGLAN <> 'BD'
cQuery += " ORDER BY B8_YCAVALE,B8_LOTECTL,B8_NUMLOTE


TcQuery cQuery Alias TRB_ESTOQUE New

dbSelectArea("TRB")	
While (!Eof())

	RECLOCK("TRB",.F.) 
	dbdelete()
	MSUNLOCK()
	
	DbSelectArea("TRB")
	DBSKIP()
EndDo

dbSelectArea("TRB_ESTOQUE")
dbGoTop()
While (!Eof())

	DBSELECTAREA("TRB")	
	RECLOCK("TRB",.T.) 					
		TRB->CAVALETE	:= TRB_ESTOQUE->CAVALETE 		
		TRB->LOTE		:= TRB_ESTOQUE->LOTE		
		TRB->CHAPA		:= TRB_ESTOQUE->SUBLOTE
		TRB->PRODUTO 	:= TRB_ESTOQUE->PRODUTO
		TRB->NOME	 	:= TRB_ESTOQUE->PRODUTO_DESC
		TRB->CLASSIF 	:= TRB_ESTOQUE->CLASSIFICACAO
		TRB->DATAM 		:= StoD(TRB_ESTOQUE->DATAM)
		TRB->USUARIO 	:= TRB_ESTOQUE->USUARIO
	MSUNLOCK()    

	dbSelectArea("TRB_ESTOQUE")
	DBSKIP()
EndDo

DbSelectArea("TRB")
DbGotop()

DBSELECTAREA("TRB_ESTOQUE")
DBCloseArea()

U_DesMarCLA()

Return()


User Function MarcarF()
/*********************************************************************************************************************************************
* Função para marcar todos os registros do browse
*
***/                            
Local oMark := GetMarkBrow()
DbSelectArea("TRB")
DbGotop()

While !Eof()	
	IF RecLock( 'TRB', .F. )		
		TRB->OK := cMark		
		MsUnLock()	
	EndIf	
	DbSelectArea("TRB")
	dbSkip()
Enddo

// atualiza o browse
MarkBRefresh() 

// força o posicionamento do browse no primeiro registro
oMark:oBrowse:Gotop()	
 
Return()


 
User Function DesMarCLA()
/*********************************************************************************************************************************************
* Função para marcar todos os registros do browse
*
***/  
Local oMark := GetMarkBrow()
dbSelectArea("TRB")
dbGotop()

While !Eof()	
 	IF RecLock( 'TRB', .F. )		
 		TRB->OK := SPACE(2)		
 		MsUnLock()	
 	EndIf	
 	dbSelectArea("TRB")
 	dbSkip()
Enddo
 
 MarkBRefresh()		
 
 // atualiza o browse
 oMark:oBrowse:Gotop()	
 // força o posicionamento do browse no primeiro registro
Return
 
 
User Function MarkCLASS()
/*********************************************************************************************************************************************
* Função para grava marca no campo se não estiver marcado ou limpar a marca se estiver marcado
*
***/  
 If IsMark( 'OK', cMark )	
	 RecLock( 'TRB', .F. )	
	 Replace TRB->OK With Space(2)	
	 MsUnLock()
 Else	
	 RecLock( 'TRB', .F. )	
	 Replace TRB->OK With cMark	
	 MsUnLock()
 EndIf
 
Return 
 
 
User Function MarkAllCLA()   
/*********************************************************************************************************************************************
* Função para gravar\limpar marca em todos os registros
*
***/  
 Local oMark := GetMarkBrow()
 dbSelectArea('TRB')
 dbGotop()

 While !Eof()	
	 u_MarkCLASS()
	 dbSelectArea('TRB')	
	 dbSkip()
 End
 
 MarkBRefresh( )
 
 // atualiza o browse
 oMark:oBrowse:Gotop()	
 // força o posicionamento do browse no primeiro registro
 
Return()