#include 'TopConn.CH'
#include 'RWMAKE.CH'
#include 'TbiConn.CH'
#INCLUDE "PROTHEUS.CH"      
/*
Programa ...: Testasx1.Prw
Uso ........: Testa de os parametros para o SX1
Data .......: 08/06/2007
Feito por ..: Bruno Lage Ferreira
Copyright @1998-2001,2007
Atualizado..: Bruno Lage Ferreira 21/09/2007
*/ 

User Function Testasx1(cPerg,aPerg,lDel) 
*****************************************************************************
* Testa de os parametros para o SX1 foram cadastrados.
* Caso contrario eles serao criados
* aPerguntas -> 1 - Grupo                  C  06  0
*               2 - Descricao da Pergunta  C  20  0
*               3 - Tipo                   C  01  0
*               4 - Tamanho                N  02  0
*               5 - Decimal                N  01  0
*               6 - Get/Choice             G/C
*               7 - Validacao              C  20  0
*               8 - F3                     C  03  0
*               9 ... 13 - Cont. da choice C  15  0
*
********

Private nXZ,nXY                          

                         
If lDel == .F.             
	 dbSelectArea("SX1")
	 dbSetOrder(1)
	 If dbSeek(cPerg)   
	     Do While !EOF() .And. (AllTrim(SX1->X1_GRUPO) == AllTrim(cPerg) )
				dbSelectArea("SX1")  
				RecLock("SX1",.f.)
					dbDelete()    
				MsUnLock()  
			dbSkip()
		EndDo
	EndIF
EndIF

For nxZ := 1 To Len(aPerg)
    dbSelectArea("SX1")
    RecLock("SX1",!dbSeek(cPerg+StrZero(nxZ,2)))
    Replace  X1_Grupo   With  cPerg
    Replace  X1_Ordem   With  StrZero(nxZ,2)
    Replace  X1_Pergunt With  aPerg[nxZ,2]
    Replace  X1_Variavl With  "Mv_Ch"+IIf(nxZ <=9,AllTrim(Str(nxZ)),Chr(nxZ + 55))
    Replace  X1_Tipo    With  aPerg[nxZ,3]
    Replace  X1_Tamanho With  aPerg[nxZ,4]
    Replace  X1_Decimal With  aPerg[nxZ,5]
    Replace  X1_GSC     With  aPerg[nxZ,6]
    Replace  X1_Valid   With  aPerg[nxZ,7]
    Replace  X1_F3      With  aPerg[nxZ,8]
    Replace  X1_Var01   With  "Mv_Par"+StrZero(nxZ,2)
    If (aPerg[nxZ,6] == "C")
       For nxY := 9 To 13
           If (aPerg[nxZ,nxY] == "")
              Exit
           Else
              Do Case
                 Case ((nxY - 8) == 1)
                      Replace X1_Def01 With aPerg[nxZ,nxY]
                 Case ((nxY - 8) == 2)
                      Replace X1_Def02 With aPerg[nxZ,nxY]
                 Case ((nxY - 8) == 3)
                      Replace X1_Def03 With aPerg[nxZ,nxY]
                 Case ((nxY - 8) == 4)
                      Replace X1_Def04 With aPerg[nxZ,nxY]
                 Case ((nxY - 8) == 5)
                      Replace X1_Def05 With aPerg[nxZ,nxY]
              EndCase
           EndIf
        Next
    EndIf 
    MsUnLock()  
Next

Return


User Function MFNextLoja(cAlias,cCodPesq)
*****************************************************************************************
*
*
*
***
Local cRet    := ""
Local cQuery  := ""
Local aArea   := GetArea()

If cAlias = "SA1"
    cQuery := " SELECT ISNULL(MAX(A1_LOJA),'00') AS ULT_LOJA
	cQuery += "   FROM SA1010
	cQuery += "  WHERE D_E_L_E_T_ <> '*'
    cQuery += "    AND A1_COD = '"+AllTrim(cCodPesq)+"'
Else
    cQuery := " SELECT ISNULL(MAX(A2_LOJA),'00') AS ULT_LOJA
	cQuery += "   FROM SA2010
	cQuery += "  WHERE D_E_L_E_T_ <> '*'
    cQuery += "    AND A2_COD = '"+AllTrim(cCodPesq)+"'
EndIf 

TcQuery cQuery Alias TRB_ULT New

dbSelectArea("TRB_ULT")
dbGoTop()

cRet := Soma1(alltrim(TRB_ULT->ULT_LOJA))

dbSelectArea("TRB_ULT")
dbCloseArea()
     
RestArea(aArea)

Return(cRet)