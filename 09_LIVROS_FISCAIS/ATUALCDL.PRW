#INCLUDE "PROTHEUS.CH"
#INCLUDE "RWMAKE.CH"
#INCLUDE "TOPCONN.CH"
                            
/*
/*
Programa ...: AtualCDL.Prw
Uso ........: Preenche o campo de complementos da exportação
Data .......: 01/08/2019
Feito por ..: Bruno Lage Ferreira 
*/
*/

User Function AtualCDL()
****************************************************************************************************
*
*
*****
Local cCodEmb   
Local cLocEmb   
Local cUFemb 
Local lCancela := .T.   


If ! pergunte("ATUALCDL",.T.)
     Return
EndIf

cLocEmb := MV_PAR04
cUFemb  := MV_PAR05
   
cQuery := "SELECT * FROM " + RETSQLNAME("SD2")
cQuery += " WHERE D2_FILIAL = '" + MV_PAR01 + "' AND D2_DOC = '" + MV_PAR02 + "' AND D2_SERIE = '" + MV_PAR03 + "' AND D_E_L_E_T_ <> '*'"
TcQuery cQuery New Alias "QSD2"

If QSD2->(Eof())
    Alert("Nota fiscal não encontrada para esta filial")
    QSD2->(dbCloseArea())
    Return
Endif	  

cQuery01 := "DELETE FROM " + RetSQLName("CDL") + " WHERE CDL_FILIAL = '" + MV_PAR01 + "' AND CDL_DOC = '" + MV_PAR02 + "' AND CDL_SERIE = '" + MV_PAR03 + "' AND D_E_L_E_T_ <> '*' "
TcSQLExec(cquery01)     

cQCDL := "SELECT * FROM " + RETSQLNAME("CDL")
cQCDL += " WHERE CDL_FILIAL = '" + MV_PAR01 + "' AND CDL_DOC = '" + MV_PAR02 + "' AND CDL_SERIE = '" + MV_PAR03 + "' AND D_E_L_E_T_ <> '*' ORDER BY CDL_ITEMNF"
TcQuery cQCDL New Alias "QCDL"
If QCDL->(EOF())

  While ! QSD2->(Eof()) 
      cData := QSD2->D2_EMISSAO
      RecLock("CDL",.T.)
      Replace CDL_FILIAL With QSD2->D2_FILIAL
      Replace CDL_DOC    With QSD2->D2_DOC
      Replace CDL_SERIE  With QSD2->D2_SERIE
      Replace CDL_ESPEXP With "SPED"
      Replace CDL_NFEXP  With QSD2->D2_DOC  
      Replace CDL_SEREXP With QSD2->D2_SERIE          
      Replace CDL_EMIEXP With ctod(substr(cDATA,7,2)+"/"+substr(cDATA,5,2)+"/"+substr(cDATA,1,4))
      Replace CDL_ITEMNF With QSD2->D2_ITEM
      Replace CDL_PRODNF With QSD2->D2_COD                                                            
      Replace CDL_ESPEC  With "SPED"
      Replace CDL_CLIENT With QSD2->D2_CLIENTE
      Replace CDL_LOJA   With QSD2->D2_LOJA
      Replace CDL_PAIS   With POSICIONE("SA1",1,XFILIAL("SA1")+QSD2->D2_CLIENTE+QSD2->D2_LOJA,"SA1->A1_PAIS")
      Replace CDL_UFEMB  With cUFemb
      Replace CDL_LOCEMB With cLocEmb
      Replace CDL_QTDEXP With QSD2->D2_QUANT 
      
      Replace CDL_NUMDE  With MV_PAR06      
      Replace CDL_DTDE   With MV_PAR07
      
      Replace CDL_NATEXP With "0"
      Replace CDL_INDDOC With "0"        

      Replace CDL_NRREG  With MV_PAR08
      Replace CDL_DTREG  With MV_PAR09

      Replace CDL_CHCEMB With MV_PAR10
      Replace CDL_DTCHC  With MV_PAR11
                  
      Replace CDL_DTAVB  With MV_PAR12
       
      Replace CDL_TPCHC  With "12"
      Replace CDL_NRMEMO With "999999999"                 
      MsUnlock()
      QSD2->(dbSkip())
   End   
EndIf

QSD2->(dbCloseArea())
QCDL->(dbCloseArea())

Alert("Dados gravados com sucesso!")

u_AtualCDL()
     
Return()
