#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
#INCLUDE "TOPCONN.CH"

/*                                          
Programa ...: MarkEnd.Prw
Uso ........: Endereçamento
Data .......: 26/08/19
Feito por ..: Bruno Lage Ferreira.
*/

User Function MarkEnd()  
/****************************************************************************************************
*
*
****/      
Local _astru     :={}
Local _afields   :={}     
Local _carq             
Private arotina  :={}   
Private cCadastro 
Private cMark    := GetMark()


aRotina   := { 	{ "Marcar Todos [F5]","U_MARCAR" 		, 0, 4},;               
				{ "Desmarcar Todos"  ,"U_DESMAR"  		, 0, 4},;  
				{ "Filtra Dados [F4]","u_MfiltDados"  	, 0, 3},;
				{ "Grava Dados  [F6]","u_MGravMovEst" 	, 0, 1},;
				{ "Rel.Endereçamento","u_RelInWeb('RQ0014')"	, 0, 3},;
				{ "Rel.End/Tabela"   ,"u_RelInWeb('RQ0052')"	, 0, 3},;
				{ "Etiqueta Endereço","u_RelInWeb('RQ0045')"	, 0, 3},;
				{ "Rel.Registros"    ,"u_MFRQ0015()"	, 0, 3},;
				{ "Inverter Todos   ","U_MARKALL" 		, 0, 4}}   

cCadastro := "Endereçamento de Estoque:"

SetKey(VK_F4,{||u_MfiltDados()})
SetKey(VK_F5,{||U_MARCAR()})
SetKey(VK_F6,{||u_MGravMovEst()})

 				
// Estrutura da tabela temporaria
AADD(_astru,{"OK"		,"C",002,0})
AADD(_astru,{"CAVALETE"	,"C",006,0})
AADD(_astru,{"LOTE"		,"C",010,0})
AADD(_astru,{"CHAPA"	,"C",004,0})
AADD(_astru,{"PRODUTO"	,"C",015,0})
AADD(_astru,{"NOME"		,"C",120,0})
AADD(_astru,{"ENDERECO"	,"C",020,0})
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
AADD(_afields,{"ENDERECO"	,"","ENDERECO"	})
AADD(_afields,{"DATAM"		,"","DATA MOVIMENTO"})
AADD(_afields,{"USUARIO"	,"","USUARIO"	})

DBSELECTAREA("TRB")

//MarkBrow( 'TRB', 'OK',,_afields,, cMark,'u_MarkAll()',,,,'u_Mark()',{|| u_MarkAll()}) 
MarkBrow( 'TRB', 'OK',,_afields,, cMark,'u_MarkAll()',,,,'u_Mark()',{|| })

DbCloseArea()      				

// fecha a tabela temporária
MsErase(_carq+GetDBExtension(),,"TOPCONN")	
// apaga a tabela temporária

//Alert("Favor não usar mais esta rotina! Usar agora a rotina de cavaletes no próprio Protheus.")

Return()

User Function MFRQ0015()
********************************************************************************
*
*
***

/*
TABELA DE DIFERENCAS 
*/
cTabela   := "TB_RQ0015"

If TcCanOpen(cTabela)  
   lOk := TcDelFile(cTabela)   
Else  
	MsgInfo("Tabela "+cTabela+" não encontrada.")
Endif	

cQuery := " SELECT  '"+SUBSTR(CUSUARIO,7,15)+"' USUARIO,
cQuery += " 		Cast(getdate() as date)  DATA,
cQuery += " 		B8_XENDERE,								   
cQuery += " 		COUNT(*)	 QTD_BUNDLE,
cQuery += " 		dbo.FBUNDLE_END(B8_XENDERE) BUNDLES
cQuery += " 		INTO  " + cTabela
cQuery += " 		FROM (
cQuery += " 				SELECT	DISTINCT B8_XENDERE,
cQuery += " 						B8_YCAVALE
cQuery += " 					FROM SB8010 
cQuery += " 					WHERE D_E_L_E_T_=''
cQuery += " 					AND B8_XPUSUAR = '"+SUBSTR(CUSUARIO,7,15)+"'"
cQuery += " 					AND CAST(B8_XDTMOVE AS DATE) = cast(getdate() as date)
cQuery += " 					AND B8_SALDO <> 0
cQuery += " 				)TB_ENDE
cQuery += " WHERE B8_XENDERE <> ''
cQuery += " GROUP BY B8_XENDERE

TcSQLExec(cQuery)

u_RelInWeb('RQ0015')

Return()

User Function MGravMovEst()
********************************************************************************
*
*
***
Local oMark := GetMarkBrow()
Local cQuery:=""

Private aPerg := {}
Private cPerg := "MGRAVMOVES"


//Aadd(aPerg,{cPerg,"Endereço De  ?"		,"C",06,00,"G","","ZE1","Vazio() .or. ExistCpo('ZE1')","","","","",""})

Aadd(aPerg,{cPerg,"Endereço De  ?"		,"C",06,00,"G","","ZE1","","","","","",""})

U_Testasx1(cPerg,aPerg,.T.)

If ! Pergunte(cPerg,.T.)
	Return()
EndIf

If Empty(mv_par01)
	//Alert("Endereço não pode ser em branco!")
	//Return()
EndIf

dbSelectArea("ZE1")
dbSetOrder(1)
If !dbSeek(xFilial("ZE1")+AllTrim(mv_par01))
	Alert("Endereço não encontrado!")
	Return()
EndIf

dbSelectArea("ZE1")
dbSetOrder(1)
If dbSeek(xFilial("ZE1")+AllTrim(mv_par01))		
	If ZE1->ZE1_BLQ == '2'
		Alert("Endereço bloqueado para produtos acabados!")
		Return()
	EndIf
EndIf

If MsgYesNo("Deseja alterar os dados de endereçamento ?" )

	dbSelectArea("TRB")
	dbGoTop()	
	While (!Eof())
		
		If IsMark( 'OK', cMark )
			dbSelectArea("TRB")	
			RecLock("TRB",.F.) 				
				TRB->ENDERECO 	:= mv_par01
				TRB->DATAM 		:= dDataBase
				TRB->USUARIO 	:= SUBSTR(CUSUARIO,7,15)
			MsUnLock()
		
			/*
			Limpa o local atual caso exita
			
			cQuery:=" UPDATE SB8010
			cQuery+="   SET B8_XDTMOVE ='',B8_XENDERE='',B8_XPUSUAR=''
			cQuery+="  	FROM SB8010 SB8 WITH ( NOLOCK )
			cQuery+=" WHERE SB8.D_E_L_E_T_ = ''
			cQuery+="   AND B8_PRODUTO = '"+ TRB->PRODUTO  +"'
			cQuery+="   AND B8_LOTECTL = '"+ TRB->LOTE     +"'
			cQuery+="   AND B8_NUMLOTE = '"+ TRB->CAVALETE +"'
			cQuery+="   AND LEFT(B8_PRODUTO,2) IN ('CH','AM') 
			//cQuery+="   AND B8_SALDO <> 0
		
			TcSQLExec(cQuery)
			*/
			/*
			Atualiza o novo endereço 

			PLSQuery
			*/
			cQuery:=" UPDATE SB8010
			cQuery+="   SET B8_XDTMOVE ='"+dToS(dDataBase)+"',B8_XENDERE='"+Alltrim(mv_par01)+"',B8_XPUSUAR='"+SUBSTR(CUSUARIO,7,15)+"'
			cQuery+="  	FROM SB8010 SB8 WITH ( NOLOCK )
			cQuery+=" WHERE SB8.D_E_L_E_T_ = ''
			cQuery+="   AND B8_PRODUTO = '"+ TRB->PRODUTO  +"'
			cQuery+="   AND B8_LOTECTL = '"+ TRB->LOTE     +"'
			cQuery+="   AND B8_NUMLOTE = '"+ TRB->CAVALETE +"'
			cQuery+="   AND LEFT(B8_PRODUTO,2) IN ('CH','AM') 
			//cQuery+="   AND B8_SALDO <> 0
		
			TcSQLExec(cQuery)
			
			/*
			limpa a informção no cavalete
			
			cQuery:=" UPDATE ZG3010
			cQuery+="    SET ZG3_XDTMOV ='',ZG3_XENDER='',ZG3_XPUSUA=''
			cQuery+="   FROM ZG3010 ZG3 WITH ( NOLOCK )
			cQuery+="  WHERE ZG3.D_E_L_E_T_ = ''
			cQuery+="    AND ZG3_CODIGO = '"+ TRB->CAVALETE +"'
		
			TcSQLExec(cQuery)
			*/
			/*
			Grava o novo endereço no cavalete
			*/
			cQuery:=" UPDATE ZG3010 
			cQuery+="    SET ZG3_XDTMOV ='"+dToS(dDataBase)+"',ZG3_XENDER='"+Alltrim(mv_par01)+"',ZG3_XPUSUA='"+SUBSTR(CUSUARIO,7,15)+"'
			cQuery+="   FROM ZG3010 ZG3 WITH ( NOLOCK )
			cQuery+="  WHERE ZG3.D_E_L_E_T_ = ''
			cQuery+="    AND ZG3_CODIGO = '"+ TRB->CAVALETE +"'
		
			TcSQLExec(cQuery)
		EndIf
			
		DbSelectArea("TRB")
		DBSKIP()
	EndDo

 MarkBRefresh( )
 
 // atualiza o browse
 oMark:oBrowse:Gotop()

EndIf

Return()

User Function MfiltDados()
********************************************************************************
*
*
***
Local cQuery := ""
Private aPerg := {}
Private cPerg := "MMOVESTOQS"
       
             
//Aadd(aPerg,{cPerg,"Empresa/Filial Destino?","C",06,00,"G","","SM0","","","","","",""})     
Aadd(aPerg,{cPerg,"Cavalete ?"		,"C",06,00,"G","","","","","","","",""})
Aadd(aPerg,{cPerg,"Lote Qualitá ?"	,"C",06,00,"G","","","","","","","",""})     
Aadd(aPerg,{cPerg,"Chapa de  ?"		,"C",03,00,"G","","","","","","","",""})
Aadd(aPerg,{cPerg,"Chapa Ate ?"		,"C",03,00,"G","","","","","","","",""})

U_Testasx1(cPerg,aPerg,.F.)

If ! Pergunte(cPerg,.T.)
	Return()
EndIf
 

cQuery := " SELECT	B8_LOCAL   AS LOCAL,
cQuery += " 		NNR_DESCRI AS LOCAL_DES,		
cQuery += " 		B8_PRODUTO AS PRODUTO,
cQuery += " 		B1_DESC    AS PRODUTO_DESC,
cQuery += " 		CAST(B8_DATA AS DATE) AS FABRIC,
cQuery += " 		RIGHT(RTRIM(LTRIM(B8_PRODUTO)),2) AS TIPO,
cQuery += " 		IIF(B8_YCLASSI='','P',RTRIM(LTRIM(B8_YCLASSI))) AS CLASSIFICACAO,
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
If !Empty(mv_par01)
	cQuery += " 	AND B8_YCAVALE='"+AllTrim(mv_par01)+"'"
EndIf
If !Empty(mv_par02)
	cQuery += " 	AND B8_LOTECTL='"+AllTrim(mv_par02)+"'"
EndIf
If !Empty(mv_par03) .And. !Empty(mv_par04) 
	cQuery += " 	AND B8_NUMLOTE BETWEEN '"+AllTrim(mv_par03)+"' AND '" + AllTrim(mv_par04)+"'"
EndIf
cQuery += " 	AND LEFT(B8_PRODUTO,2) IN ('CH','AM') 
cQuery += " 	AND B8_SALDO <> 0
cQuery += " ORDER BY B8_YCAVALE,B8_LOTECTL,B8_NUMLOTE


TcQuery cQuery Alias TRB_ESTOQUE New


DBSELECTAREA("TRB")	
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
		TRB->ENDERECO 	:= TRB_ESTOQUE->ENDERECO
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

U_DesMar()

Return()


User Function Marcar()
********************************************************************************
*// Função para marcar todos os registros do browse
*
***                              
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


 
User Function DesMar()
********************************************************************************
*// Função para desmarcar todos os registros do browse
*
***
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
 
 
User Function Mark()
********************************************************************************
*// Função para grava marca no campo se não estiver marcado ou limpar a marca se estiver marcado
*
***
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
 
 
User Function MarkAll()   
********************************************************************************
*// Função para gravar\limpar marca em todos os registros
*
*** 
 Local oMark := GetMarkBrow()
 dbSelectArea('TRB')
 dbGotop()

 While !Eof()	
	 u_Mark()
	 dbSelectArea('TRB')	
	 dbSkip()
 End
 
 MarkBRefresh( )
 
 // atualiza o browse
 oMark:oBrowse:Gotop()	
 // força o posicionamento do browse no primeiro registro
 
Return
