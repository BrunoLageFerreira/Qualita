#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
#INCLUDE "TOPCONN.CH"

/*                                          
Programa ...: MANSEGUROS.Prw
Uso ........: Endereçamento OSC
Data .......: 07/04/20
Feito por ..: Bruno Lage Ferreira.
*/


User Function MANSEGUROS()  
/****************************************************************************************************
*
*
****/      
Local _astru     :={}
Local _afields   :={}     
Local _carq             
Private arotina  :={}   
Private cCadastro 
Private cMark    :=GetMark()

aRotina   := { 	{ "Marcar Todos [F5]","U_SMARCAR" 		, 0, 4},;               
				{ "Desmarcar Todos"  ,"U_SDESMAR"  		, 0, 4},;  
				{ "Filtra Dados [F4]","u_SMfiltDados"  	, 0, 3},;
				{ "Grava Dados  [F6]","u_SMGravMov" 	, 0, 1},;
				{ "Inverter Todos   ","U_SMARKALL" 		, 0, 4}}   

cCadastro := "Manutenção ( OSC - Operação de Seguro de Crédito )"

SetKey(VK_F4,{||u_SMfiltDados()})
SetKey(VK_F5,{||U_SMARCAR()})
SetKey(VK_F6,{||u_SMGravMov()})

 				
// Estrutura da tabela temporaria
AADD(_astru,{"OK"		,"C",002,0})
AADD(_astru,{"PREFIXO"	,"C",003,0})
AADD(_astru,{"NUMERO"   ,"C",009,0})
AADD(_astru,{"PARCELA"	,"C",003,0})
AADD(_astru,{"INVOICE"	,"C",010,0})
AADD(_astru,{"CLIENTE"	,"C",006,0})
AADD(_astru,{"LOJA"		,"C",002,0})
AADD(_astru,{"NOME"	    ,"C",120,0})
AADD(_astru,{"SEGURA"	,"C",006,0})
AADD(_astru,{"LJSEGURA"	,"C",002,0})
AADD(_astru,{"NOMESEGU" ,"C",120,0})
AADD(_astru,{"VALOR"	,"N",012,2})
AADD(_astru,{"RECNO1"	,"N",012,0})


// cria a tabela temporária
_carq:="T_"+Criatrab(,.F.)
MsCreate(_carq,_astru,"TOPCONN") 
// atribui a tabela temporária ao alias TRBSEG
dbUseArea(.T.,"TOPCONN",_cARq,"TRBSEG",.T.,.F.)

AADD(_afields,{"OK"			,"","X"	   		})
AADD(_afields,{"PREFIXO"	,"","PREFIXO"	})
AADD(_afields,{"NUMERO"		,"","NUMERO"	})
AADD(_afields,{"PARCELA"	,"","PARCELA"	})
AADD(_afields,{"INVOICE"	,"","INVOICE"	})
AADD(_afields,{"CLIENTE"    ,"","CLIENTE"	})
AADD(_afields,{"LOJA"	    ,"","LOJA"		})
AADD(_afields,{"NOME"		,"","NOME CLIENTE"})
AADD(_afields,{"SEGURA"     ,"","ID SEGURADORA"})
AADD(_afields,{"LJSEGURA"   ,"","LJ SEGURADORA"})
AADD(_afields,{"NOMESEGU"	,"","NOME SEGURADORA"})
AADD(_afields,{"VALOR"   	,"","VALOR"		})
//AADD(_afields,{"RE"   	,"","REC"		})

DBSELECTAREA("TRBSEG")

//MarkBrow( 'TRB', 'OK',,_afields,, cMark,'u_MarkAll()',,,,'u_Mark()',{|| u_MarkAll()}) 
MarkBrow( 'TRBSEG', 'OK',,_afields,, cMark,'u_SMarkAll()',,,,'u_SMark()',{|| })

DbCloseArea()      				

// fecha a tabela temporária
MsErase(_carq+GetDBExtension(),,"TOPCONN")	
// apaga a tabela temporária

Return()

User Function SMGravMov()
********************************************************************************
*
*
***
Local oMark    := GetMarkBrow()
Local cQuery   := ""
Local lEmpty   := .F.
Local cNomeSeg := ""

Private aPerg := {}
Private cPerg := "GRAVSEGURO"

Aadd(aPerg,{cPerg,"Seguradora   ?"		,"C",06,00,"G","","ZS1","","","","","",""})
Aadd(aPerg,{cPerg,"Loja         ?" 	    ,"C",02,00,"G","","","","","","","",""})   

U_Testasx1(cPerg,aPerg,.F.)

If ! Pergunte(cPerg,.T.)
	Return()
EndIf

If Empty(mv_par01) .Or. Empty(mv_par02)

dbSelectArea("TRBSEG")
	dbGoTop()	
	While (!Eof())
	
		dbSelectArea("TRBSEG")
		If IsMark( 'OK', cMark )

			If !Empty(TRBSEG->SEGURA) 
				If MsgYesNo("Deseja [X] - Remover os dados da seguradora de crédito? (Sim ou Não)" )
					DBSELECTAREA("TRBSEG")	
					RECLOCK("TRBSEG",.F.) 				
						TRBSEG->SEGURA	:= ""
						TRBSEG->LJSEGURA:= ""
						TRBSEG->NOMESEGU:= ""
					MSUNLOCK()
				
					/*
					Cadastra a segurada no título a receber
					*/
					cQuery := " UPDATE SE1010
					cQuery += "   SET E1_CODSEG = '' ,E1_LOJASEG = '' 
					cQuery += "  	FROM SE1010 SE1 
					cQuery += " WHERE SE1.D_E_L_E_T_ = ''
					cQuery += "   AND E1_PREFIXO = '"+ TRBSEG->PREFIXO     +"'
					cQuery += "   AND E1_NUM     = '"+ TRBSEG->NUMERO      +"'
					cQuery += "   AND E1_PARCELA = '"+ TRBSEG->PARCELA     +"'
					cQuery += "   AND E1_XINVOIC = '"+ TRBSEG->INVOICE     +"'
					cQuery += "   AND E1_CLIENTE = '"+ TRBSEG->CLIENTE     +"'
					cQuery += "   AND E1_LOJA    = '"+ TRBSEG->LOJA        +"'
					cQuery += "   AND R_E_C_N_O_ =  "+ STR(TRBSEG->RECNO1) 
									
					TcSQLExec(cQuery)
				EndIf
			Else
				Alert("dados da seguradora em branco!")
			EndIf
			
		EndIf
			
		DbSelectArea("TRBSEG")
		DBSKIP()
	EndDo
	
	Return()
EndIf


If MsgYesNo("Deseja [ ] - Alterar os dados da seguradora de crédito ?" )

	dbSelectArea("TRBSEG")
	dbGoTop()	
	While (!Eof())
	
		dbSelectArea("TRBSEG")
		If IsMark( 'OK', cMark )
		
			dbSelectArea("ZS2")
			dbSetOrder(1)     
			If !u_SExitSeg(TRBSEG->CLIENTE , TRBSEG->LOJA) 

				Alert("Seguradora de crédito não encontrada para este cliente! (Limite por Cliente ou Limite por Grupo)")
			
			Else
			
				dbSelectArea("ZS2")
				dbSetOrder(1)
				If dbSeek(xFilial("ZS2") + TRBSEG->CLIENTE + TRBSEG->LOJA)
					cNomeSeg := ZS2->ZS2_NOMESE
				EndIf
				
				dbSelectArea("SA1")
				dbSetOrder(1)
				If dbSeek(xFilial("SA1") + TRBSEG->CLIENTE + TRBSEG->LOJA)
					IF !EMPTY(SA1->A1_GRPVEN)
						dbSelectArea("ZS4")
						dbSetOrder(1)
						If dbSeek(xFilial("ZS4") + SA1->A1_GRPVEN + AllTrim(mv_par01) + AllTrim(mv_par02))
							cNomeSeg := ZS4->ZS4_NOMESE
						Else
							Alert("Seguradora de crédito não encontrada para este cliente! (Limite por Grupo)")
							Return()
						EndIf
					EndIf
				EndIf
								
				DBSELECTAREA("TRBSEG")	
				RECLOCK("TRBSEG",.F.) 				
					TRBSEG->SEGURA	:= mv_par01
					TRBSEG->LJSEGURA:= mv_par02
					TRBSEG->NOMESEGU:= cNomeSeg
				MSUNLOCK()
				cNomeSeg := ""
			
				/*
				Cadastra a segurada no título a receber
				*/
				cQuery := " UPDATE SE1010
				cQuery += "   SET E1_CODSEG = '"+mv_par01+"' ,E1_LOJASEG = '"+mv_par02+"' 
				cQuery += "  	FROM SE1010 SE1 
				cQuery += " WHERE SE1.D_E_L_E_T_ = ''
				cQuery += "   AND E1_PREFIXO = '"+ TRBSEG->PREFIXO    +"'
				cQuery += "   AND E1_NUM     = '"+ TRBSEG->NUMERO     +"'
				cQuery += "   AND E1_PARCELA = '"+ TRBSEG->PARCELA    +"'
				cQuery += "   AND E1_XINVOIC = '"+ TRBSEG->INVOICE    +"'
				cQuery += "   AND E1_CLIENTE = '"+ TRBSEG->CLIENTE    +"'
				cQuery += "   AND E1_LOJA    = '"+ TRBSEG->LOJA       +"'
				cQuery += "   AND R_E_C_N_O_ =  "+ STR(TRBSEG->RECNO1)
								
				TcSQLExec(cQuery)
			EndIf

		EndIf
			
		DbSelectArea("TRBSEG")
		DBSKIP()
	EndDo

 MarkBRefresh( )
 
 // atualiza o browse
 oMark:oBrowse:Gotop()

EndIf

Return()

User Function SMfiltDados()
********************************************************************************
*
*
***
Local cQuery := ""
Private aPerg := {}
Private cPerg := "MMOVSEGURO"
          
//Aadd(aPerg,{cPerg,"Empresa/Filial Destino?","C",06,00,"G","","SM0","","","","","",""})     
Aadd(aPerg,{cPerg,"Cliente   ?"		,"C",06,00,"G","","SA1","","","","","",""})
Aadd(aPerg,{cPerg,"Loja      ?" 	,"C",02,00,"G","","","","","","","",""})     
Aadd(aPerg,{cPerg,"Invoice   ?"		,"C",10,00,"G","","","","","","","",""})
Aadd(aPerg,{cPerg,"Número    ?"		,"C",09,00,"G","","","","","","","",""})
Aadd(aPerg,{cPerg,"Já Assegurada ?"	,"N",01,00,"C","","","Sim","Nao","","","",""})
Aadd(aPerg,{cPerg,"Com Saldo ?"	,"N",01,00,"C","","","Sim","Nao","","","",""})

U_Testasx1(cPerg,aPerg,.F.)

If ! Pergunte(cPerg,.T.)
	Return()
EndIf
 

cQuery := " SELECT	E1_PREFIXO, 
cQuery += " 		E1_NUM,
cQuery += " 		E1_PARCELA,
cQuery += " 		E1_XINVOIC,
cQuery += " 		E1_CLIENTE,
cQuery += " 		E1_LOJA,
cQuery += " 		E1_NOMCLI,
cQuery += " 		E1_CODSEG,
cQuery += " 		E1_LOJASEG,
cQuery += " 		ISNULL((SELECT ZS1_NOMES FROM ZS1010 WHERE D_E_L_E_T_ = '' AND ZS1_COD = E1_CODSEG AND ZS1_LOJA = E1_LOJASEG),'') AS NOME_SEGU,
cQuery += " 		E1_VALOR,
cQuery += " 		R_E_C_N_O_
cQuery += "   FROM SE1010 SE1 
cQuery += "  WHERE SE1.D_E_L_E_T_ = ''

If !Empty(mv_par01) .OR. !Empty(mv_par02)
	cQuery += " 	AND E1_CLIENTE + E1_LOJA ='" + AllTrim(mv_par01) + AllTrim(mv_par02) +"'"
EndIf

If !Empty(mv_par03)
	cQuery += " 	AND E1_XINVOIC LIKE '%" + AllTrim(mv_par03) + "%'"
Else
	cQuery += " 	AND E1_XINVOIC <> '' "
EndIf

If !Empty(mv_par04)  
	cQuery += " 	AND E1_NUM LIKE '%" + AllTrim(mv_par04) + "%'"
EndIf

If mv_par05 = 1  
	cQuery += " 	AND E1_CODSEG <> ''"
EndIf

If mv_par06 = 1  
	cQuery += "    AND E1_SALDO <> 0
EndIf

cQuery += " ORDER BY	E1_CLIENTE,
cQuery += " 			E1_LOJA,
cQuery += " 			E1_NUM


TcQuery cQuery Alias TRB_SEGURO New


DBSELECTAREA("TRBSEG")	
While (!Eof())

	RECLOCK("TRBSEG",.F.) 
	dbdelete()
	MSUNLOCK()
	
	DbSelectArea("TRBSEG")
	DBSKIP()
EndDo


dbSelectArea("TRB_SEGURO")
dbGoTop()
While (!Eof())

	//SUBSTR(CUSUARIO,7,15)

	DBSELECTAREA("TRBSEG")	
	RECLOCK("TRBSEG",.T.) 					
		TRBSEG->PREFIXO	:= TRB_SEGURO->E1_PREFIXO
		TRBSEG->NUMERO	:= TRB_SEGURO->E1_NUM
		TRBSEG->PARCELA	:= TRB_SEGURO->E1_PARCELA
		TRBSEG->INVOICE	:= TRB_SEGURO->E1_XINVOIC
		TRBSEG->CLIENTE	:= TRB_SEGURO->E1_CLIENTE
		TRBSEG->LOJA	:= TRB_SEGURO->E1_LOJA
		TRBSEG->NOME	:= TRB_SEGURO->E1_NOMCLI
		TRBSEG->SEGURA	:= TRB_SEGURO->E1_CODSEG
		TRBSEG->LJSEGURA:= TRB_SEGURO->E1_LOJASEG
		TRBSEG->NOMESEGU:= TRB_SEGURO->NOME_SEGU
		TRBSEG->VALOR	:= TRB_SEGURO->E1_VALOR
		TRBSEG->RECNO1	:= TRB_SEGURO->R_E_C_N_O_
	MSUNLOCK()    

	dbSelectArea("TRB_SEGURO")
	DBSKIP()
EndDo

DbSelectArea("TRBSEG")
DbGotop()

DBSELECTAREA("TRB_SEGURO")
DBCloseArea()

U_sDesMar()

Return()


User Function SMarcar()
********************************************************************************
*// Função para marcar todos os registros do browse
*
***                              
Local oMark := GetMarkBrow()
DbSelectArea("TRBSEG")
DbGotop()


While !Eof()	
	If u_SExitSeg(TRBSEG->CLIENTE , TRBSEG->LOJA)
		DbSelectArea("TRBSEG")
		IF RecLock( 'TRBSEG', .F. )		
			TRBSEG->OK := cMark		
			MsUnLock()	
		EndIf	
	EndIf
	DbSelectArea("TRBSEG")
	dbSkip()
Enddo

// atualiza o browse
MarkBRefresh() 

// força o posicionamento do browse no primeiro registro
oMark:oBrowse:Gotop()	
 
Return()


 
User Function SDesMar()
********************************************************************************
*// Função para desmarcar todos os registros do browse
*
***
Local oMark := GetMarkBrow()
dbSelectArea("TRBSEG")
dbGotop()

While !Eof()	
 	IF RecLock( 'TRBSEG', .F. )		
 		TRBSEG->OK := SPACE(2)		
 		MsUnLock()	
 	EndIf	
 	dbSelectArea("TRBSEG")
 	dbSkip()
Enddo
 
 MarkBRefresh()		
 
 // atualiza o browse
 oMark:oBrowse:Gotop()	
 // força o posicionamento do browse no primeiro registro
Return
 
User Function SExitSeg(cCodCli,cCodLj)
 ********************************************************************************
*// Função para verificar se existe alguma seguradora cadastrada para o cliente. Obrigatorio pelo menos uma.
*
***
lRet := .F.

/*
ZS2_FILIAL, ZS2_CODCLI, ZS2_LOJACL, ZS2_CODSEG, ZS2_LOJASE, R_E_C_N_O_, D_E_L_E_T_
ZS2_FILIAL, ZS2_CODSEG, ZS2_LOJASE, ZS2_CODCLI, ZS2_LOJACL, R_E_C_N_O_, D_E_L_E_T_
*/

dbSelectArea("ZS2")
dbSetOrder(1)
If dbSeek(xFilial("ZS2") + cCodCli + cCodLj)
	lRet := .T.
	Return (lRet)
EndIf

dbSelectArea("SA1")
dbSetOrder(1)
If dbSeek(xFilial("SA1") + cCodCli + cCodLj)
	IF !EMPTY(SA1->A1_GRPVEN)
		dbSelectArea("ZS4")
		dbSetOrder(1)
		If dbSeek(xFilial("ZS4") + SA1->A1_GRPVEN)
			lRet := .T.
			Return (lRet)
		EndIf
	EndIf
EndIf

Return (lRet)
 
User Function SMark()
********************************************************************************
*// Função para grava marca no campo se não estiver marcado ou limpar a marca se estiver marcado
*
***
If u_SExitSeg(TRBSEG->CLIENTE , TRBSEG->LOJA)

 	dbSelectArea("TRBSEG")
	 If IsMark( 'OK', cMark )	
		 RecLock( 'TRBSEG', .F. )	
		 	Replace TRBSEG->OK With Space(2)	
		 MsUnLock()
	 Else	
		 RecLock( 'TRBSEG', .F. )	
		 	Replace TRBSEG->OK With cMark	
		 MsUnLock()
	 EndIf
Else
	 Alert("Este cliente não possui nenhuma seguradora cadastrada!")
	 
	 dbSelectArea("TRBSEG")
	 RecLock( 'TRBSEG', .F. )	
	 	Replace TRBSEG->OK With Space(2)	
	 MsUnLock()

EndIf
 
Return 
 
 
User Function SMarkAll()   
********************************************************************************
*// Função para gravar\limpar marca em todos os registros
*
*** 
 Local oMark := GetMarkBrow()
 dbSelectArea('TRBSEG')
 dbGotop()

 While !Eof()	
	 u_sMark()
	 dbSelectArea('TRBSEG')	
	 dbSkip()
 End
 
 MarkBRefresh( )
 
 // atualiza o browse
 oMark:oBrowse:Gotop()	
 // força o posicionamento do browse no primeiro registro
 
Return