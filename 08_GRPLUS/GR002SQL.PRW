#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
#INCLUDE "TOPCONN.CH"

/*
Ponto de entrada que permite alterar o conteúdo da
consulta SQL do fonte GROA002.PRW
*/

User Function GR002SQL()
***********************************************************************************************************
*
*
***
Local cSqlOld := Substr(PARAMIXB[1],1,AT('ORDER BY',PARAMIXB[1]) -1 )
Local cSqlNew := ""
Local aPerg   := {}
Local cPerg   := "GR002SQLSW"

Local aCava   := {}
Local aCodi   := {}
Local aLote   := {}
Local aDesc   := {}
Local cCavMob := ""

Aadd(aPerg,{cPerg,"Cavaletes [,]?","C",99,00,"G","","","","","","","",""})      
Aadd(aPerg,{cPerg,"Código    [,]?","C",99,00,"G","","","","","","","",""})
Aadd(aPerg,{cPerg,"Lote      [,]?","C",99,00,"G","","","","","","","",""})
Aadd(aPerg,{cPerg,"Descrição [,]?","C",99,00,"G","","","","","","","",""})

U_Testasx1(cPerg,aPerg,.t.) 

/*
INTEGRAÇÃO MOBGRAN
*/

/*
Apaga o Profile do usuário
*/
cQuery  := " SELECT * FROM ZSA010 WHERE D_E_L_E_T_ = '' AND ZSA_IDMOBP = '"+AllTrim(M->C5_XIDMOB)+" ' AND ZSA_STATUS ='ATIVA'
		
tcQuery cQuery alias TRB new

dbSelectArea("TRB")
dbgotop()

Do While !EOF()

	cCavMob := cCavMob  + Alltrim(TRB->ZSA_NUMCAV) + ","

	dbSelectArea("TRB") 
	dbSkip()
EndDo


cCavMob := Iif(substring(cCavMob,len(cCavMob),1)==",",substring(cCavMob,1,len(cCavMob) - 1),cCavMob)

dbSelectArea("TRB") 
dbCloseArea()	

If !Empty(cCavMob)
	SetMVValue("GR002SQLSW","MV_PAR01",cCavMob) 
else
	SetMVValue("GR002SQLSW","MV_PAR01",space(99)) 
EndIf

If ! Pergunte(cPerg,.T.)
	Return(PARAMIXB[1])
EndIf

If Len(AllTrim(mv_par01)) == 99
	Alert("Número de bundle muito grande! Será usado uma variável interna para complementar todos os dados.")
	aCava   := strtokarr(AllTrim(cCavMob), ",")
Else
	aCava   := strtokarr(AllTrim(mv_par01), ",")
EndIf

aCodi   := strtokarr(AllTrim(mv_par02), ",")
aLote   := strtokarr(AllTrim(mv_par03), ",")
aDesc   := strtokarr(AllTrim(mv_par04), ",")
  
cSqlNew := " SELECT * FROM (
cSqlNew += cSqlOld
cSqlNew += " ) TB_FILTRADA
cSqlNew += " WHERE C6_PRODUTO <> ''
//cSqlNew += "   AND C6_LOCAL = '03'

If Len(aCava)>0
	For nX:=1 to Len(aCava)
	 	If nX = 1
	 		cSqlNew += " AND ( C6_YCAVALE LIKE '%"+AllTrim(aCava[nX])+"%' "
	 	Else
	 		cSqlNew += " OR C6_YCAVALE LIKE '%"+AllTrim(aCava[nX])+"%' "
	 	EndIf
	Next nX
	cSqlNew += " )"
EndIf

If Len(aCodi)>0
	For nX:=1 to Len(aCodi)
	 	If nX = 1
	 		cSqlNew += " AND ( C6_PRODUTO LIKE '%"+AllTrim(aCodi[nX])+"%' "
	 	Else
	 		cSqlNew += " OR C6_PRODUTO LIKE '%"+AllTrim(aCodi[nX])+"%' "
	 	EndIf
	Next nX
	cSqlNew += " )"
EndIf

If Len(aLote)>0
	For nX:=1 to Len(aLote)
	 	If nX = 1
	 		cSqlNew += " AND ( C6_LOTECTL LIKE '%"+AllTrim(aLote[nX])+"%' "
	 	Else
	 		cSqlNew += " OR C6_LOTECTL LIKE '%"+AllTrim(aLote[nX])+"%' "
	 	EndIf
	Next nX
	cSqlNew += " )"
EndIf

If Len(aDesc)>0
	For nX:=1 to Len(aDesc)
	 	If nX = 1
	 		cSqlNew += " AND ( C6_DESCRI LIKE '%"+AllTrim(aDesc[nX])+"%' "
	 	Else
	 		cSqlNew += " OR C6_DESCRI LIKE '%"+AllTrim(aDesc[nX])+"%' "
	 	EndIf
	Next nX
	cSqlNew += " )"
EndIf

cSqlNew += " ORDER BY  C6_LOTECTL, C6_NUMLOTE,C6_PRODUTO

Return(cSqlNew)
