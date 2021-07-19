#INCLUDE "rwmake.ch"   
#include "protheus.ch"  
#INCLUDE "topconn.ch"

/*                                          
Programa ...: M185GRV.Prw
Uso ........: Ponto de Entrada (GRAVAÇÃO na baixa de requisição) baixa direta
Data .......: 10/12/19
Feito por ..: Bruno Lage Ferreira.
*/

User Function M185GRV()
***********************************************************************************************************
*  
*
***    
Local cNumeroBx := AllTrim(SCP->CP_NUM)
Local aM185GRV  := GetArea()

If SubString(CNUMEMP,1,2) == "01" 
	Do While cNumeroBx == AllTrim(SCP->CP_NUM)
		
		dbSelectArea("ZA1")
		dbSetorder(2)
		If dbSeek(xFilial("ZA1")+ AllTrim(SubsTr(AllTrim(SCP->CP_OBS),4,27 )) )
			
			RecLock( 'ZA1', .f. )	
				Replace ZA1->ZA1_STATUS With .F.
				Replace ZA1->ZA1_USUBX  With SUBSTR(CUSUARIO,7,15)
				Replace ZA1->ZA1_DTBX   With dDataBase
			MsUnLock()
		
		EndIf
		
		dbSelectArea("SCP")
		dbSkip()
	EndDo
EndIf

RestArea(aM185GRV)

Return(.t.)
