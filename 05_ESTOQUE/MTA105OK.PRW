#INCLUDE "Rwmake.ch"
#INCLUDE "topconn.ch"

/*            
BRUNO LAGE FERREIRA
SIGAWISE

06/12/2019 - 
05/04/2022 - If !IsBlind()  para funcionar via aplicativo do MNT
*/
            
User Function MTA105OK()
*****************************************************************************************
* //VALIDA DADOS NA GRAÇÃO DA GERAÇÃO DOS DADOS RAT. C.C.
*
*****
Local lRet := .T.

If !IsBlind()    
	If !funname() $ "MNTA420/MNTA300/MNTA990/MNTA295/MNTA265/MNTA410/MNTA120/MNTA902/MNTA365"
		If Len(ACPISGS) == 0
			Aviso("Aviso!","Preencha o centro de custos na tela de rateios! OUTRAS AÇOES > RAT CC ",{"OK"})
			lRet := .F.
		EndIf
		//Aviso("Aviso!","O sistema criou um S.Almoxarifado. Preencha o CC na tela de rateios! OUTRAS AÇOES > RAT CC ",{"OK"})
	EndIf 
ENDIF

Return(lRet)
