#Include "rwmake.ch"
#Include "Colors.ch"
#Include "Protheus.ch"  
#Include "Topconn.ch"

/*
Programa ...: MLPTESNF.Prw
Uso ........: MLPTESNF
Data .......: 23/10/2013
Feito por ..: Bruno Lage Ferreira
Copyright @1998-2001,2013
Atualizado..: 24/08/2020
*/                       
User Function MLPTESNF(cVarFilial,cVarDoc,cVarSerie,cVarFornece,cVarLoja,cVarTes)
***********************************************************************************
*
*
***
Local cRet   := ""     
Local aRet   := {}        
Local lRet   := .F.
Local cQuery := ""            

/*
SQL para verificar os TES cadastrados em cada item da nota fiscal
*/
cQuery := " SELECT DISTINCT D1_TES
cQuery += "    FROM "+ RetSqlName("SF1") +" SF1, "+ RetSqlName("SD1") +" SD1
cQuery += "  WHERE SF1.D_E_L_E_T_ <> '*'
cQuery += "    AND SD1.D_E_L_E_T_ <> '*'
cQuery += "    AND F1_DOC     = D1_DOC
cQuery += "    AND F1_SERIE   = D1_SERIE
cQuery += "    AND F1_FILIAL  = D1_FILIAL
cQuery += "    AND F1_EMISSAO = D1_EMISSAO
cQuery += "    AND F1_FORNECE = D1_FORNECE
cQuery += "    AND F1_LOJA    = D1_LOJA
cQuery += "    AND D1_FILIAL  = '"+ cVarFilial  +"'
cQuery += "    AND D1_DOC     = '"+ cVarDoc     +"' 
cQuery += "    AND D1_SERIE   = '"+ cVarSerie   +"'
cQuery += "    AND D1_FORNECE = '"+ cVarFornece +"' 
cQuery += "    AND D1_LOJA    = '"+ cVarLoja    +"'      

TcQuery cQuery alias QTMP New

dbGoTop()
Do While !Eof()

	aAdd( aRet , AllTrim(QTMP->D1_TES))
                    
	dbSelectArea("QTMP")
	dbSkip()
EndDo	      
     
dbSelectArea("QTMP")
dbCloseArea("QTMP") 
       
For nX := 1 To Len(aRet) 
	If aRet[nX] $ cVarTes
		lRet := .T.
    EndIf
Next nX    

If lRet 
	cRet := "VR.REF.ICMS ST S/COMPRA S/NF "+cVarDoc
Else
	cRet := "VR.REF.COMPRA CONF.NF "+cVarDoc
EndIf

Return(cRet)