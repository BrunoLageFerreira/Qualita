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
Local lRet      := .T.
Local nX        := 0
Local nY        := 0
Local cAvisoMsg := ""


If !IsBlind()    
	If !funname() $ "MNTA420/MNTA300/MNTA990/MNTA295/MNTA265/MNTA410/MNTA120/MNTA902/MNTA365"
		If Len(aPesNota) <> 0
			If Len(ACPISGS) == 0
				//Aviso("Aviso!","Preencha o centro de custos na tela de rateios! OUTRAS AÇOES > RAT CC ",{"OK"})
				//lRet := .F.
			EndIf

			For nX := 1  to Len(aPesNota)
				aPesNota[nX][6] := 0
			Next nX

			For nX := 1  to Len(aPesNota)
				For nY := 1  to Len(aCols)
					IF AllTrim(aPesNota[nX][1]) == AllTrim(aCols[nY][2])
						aPesNota[nX][6] := aPesNota[nX][6] + aCols[nY][5]
					EndIf
				Next nY
			Next nX

			cAvisoMsg := "Encontrado diferenças entre a nota e os item de baixas!" + chr(13)+chr(10)
			For nX := 1  to Len(aPesNota)
				If aPesNota[nX][6] <> aPesNota[nX][2]
					lRet := .F.
					dbSelectArea("SB1")
					dbSetOrder(1)
					dbSeek( xFilial("SB1") + AllTrim(aPesNota[nX][1]))
					cAvisoMsg  := cAvisoMsg + " -Item: [" + AllTrim(SB1->B1_DESC) + "] -> Qtd. na Nf-e:" + AllTrim(str(aPesNota[nX][2])) + " Qtd. Baixa:" + AllTrim(str(aPesNota[nX][6])) +" ."+ chr(13)+chr(10) 
				EndIf
			Next nX
			If lRet == .F.
				Aviso("Aviso!",cAvisoMsg,{"OK"})
			EndIf
		EndIf
	EndIf 
EndIf

Return(lRet)

User Function MT105FIM()
*****************************************************************************************
* //Chamado 5361 - ERRO NA HORA DE DA BAIXA
*
*****
Local nOpcap := PARAMIXB

IF TYPE ("aPesNota") == "A"
	aPesNota := {}
endif

Return 
