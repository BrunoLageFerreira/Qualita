#include 'protheus.ch'
#include 'parmtype.ch'
//VENCIMENTO FINANCEIRO
//MV_UCONPGL

User Function mXdtVal(cProg)
***********************************************************************************
*//M->E2_VENCTO >= (STOD(FWTIMEUF(GETMV("MV_ESTADO"))[1])+5)
*//IIF(RetCodUsr()$"000003/000031/000028" .OR. "PA"$M->E2_TIPO,.T.,M->E2_VENCTO >= (STOD(FWTIMEUF(GETMV("MV_ESTADO"))[1])+5)) 
***
Local lRet    := .T.
Local amXdtVal:= GetArea()
Local cULiberado := GetMV("MV_UCONPGL")

	If AllTrim(FunName()) $ "MATA103/MATA116/U_GATI001" 
		IF (!RetCodUsr() $ cULiberado )
			IF cProg = "MT103FIN"
				IF aLocCols[1][2] < (STOD(FWTIMEUF(GETMV("MV_ESTADO"))[1])+5)
					lRet := .F.
				EndIf
			Else
				IF M->E2_VENCTO < (STOD(FWTIMEUF(GETMV("MV_ESTADO"))[1])+5)
					lRet := .F.
				EndIf
			EndIf
		EndIf

	ElseIf (AllTrim(FunName()) $ "AUTPAG/IMPORT") 
		IF( !AllTrim(M->E2_TIPO) $ "PA/GUI/FOL")
			IF (!RetCodUsr() $ cULiberado )
				IF M->E2_VENCTO < (STOD(FWTIMEUF(GETMV("MV_ESTADO"))[1])+5)
					lRet := .F.
				EndIf
			EndIf
		EndIf
	Else

		IF( AllTrim(M->E2_TIPO) <> "PA")
			IF (!RetCodUsr() $ cULiberado ) 
				IF M->E2_VENCTO < (STOD(FWTIMEUF(GETMV("MV_ESTADO"))[1])+5)
					lRet := .F.
				EndIf
			EndIf
		EndIf

	EndIF
	
	RestArea(amXdtVal)

Return(lRet)
