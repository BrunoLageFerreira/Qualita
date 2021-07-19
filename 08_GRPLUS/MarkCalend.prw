#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
#INCLUDE "topconn.ch"          

/*
Programa ...: MsCalend
Uso ........: INCLUSAO dos dias de trabalho e numero de dias trabalho no previsto
Data .......: 04-12-2020
Feito por ..: Bruno Lage Ferreira
Copyright @1998-2001,2020
*/

User Function MsCalend(cDataRef,cMesRef) 
/***********************************************************************************
*
*
*
******/

Private aDiasMes:={}


DEFINE DIALOG oDlg TITLE "Dias do Mês" FROM 180,180 TO 350,480 PIXEL     
// Cria objeto   
oMsCalend := MsCalend():New(05,05,oDlg,.T.)   
// Define o dia a ser exibido no calendário   

oMsCalend:dDiaAtu := cDataRef
oMsCalend:canMultSel := .F.
// Code-Block para mudança de Dia   
oMsCalend:bChange   := {|| MarkDia( Val(left(dtoc(oMsCalend:dDiaAtu),2)) ) }       
//oMsCalend:bRClicked := {|| MarkDia( Val(left(dtoc(oMsCalend:dDiaAtu),2)) ) }       
// Code-Block para mudança de mes   
oMsCalend:bChangeMes := {|| MarkMes(cDataRef) }  

@ 71,030 Button "Limpar" Action(LimpaMes(cDataRef)) Size 023,012 PIXEL OF oDlg
@ 71,100 Button "OK"     Action(Close(oDlg)) Size 023,012 PIXEL OF oDlg

                
ACTIVATE DIALOG oDlg CENTERED

If !EmpTy(aDiasMes)
	M->ZS8_DIAS   := Len(aDiasMes) 
    M->ZS8_IDDIAS := ArrTokStr(aSort(aDiasMes), ",")
Else
	M->ZS8_DIAS   := 0 
    M->ZS8_IDDIAS := Space(120)
EndIf

Return(cMesRef)


Static Function LimpaMes(cDataRef) 
/***********************************************************************************
*
*
*
******/
	Alert('Marcações limpas!')
	
	oMsCalend:CtrlRefresh()
	oMsCalend:dDiaAtu := cDataRef
	oMsCalend:CtrlRefresh()
	
	oMsCalend:DelAllRestri()
	aDiasMes := {}
Return 



Static Function MarkDia(nDia) 
/***********************************************************************************
*
*
*
******/
oMsCalend:AddRestri(nDia, CLR_HRED, CLR_HRED)
oMsCalend:CtrlRefresh()


If aScan(aDiasMes,StrZero(nDia,2))==0
	aAdd(aDiasMes,StrZero(nDia,2))
EndIf

Return 

Static Function MarkMes(cDataRef) 
/***********************************************************************************
*
*
*
******/
	Alert('Mês não pode ser alterado!')
	
	oMsCalend:CtrlRefresh()
	oMsCalend:dDiaAtu := cDataRef
	oMsCalend:CtrlRefresh()
	
	oMsCalend:DelAllRestri()
	aDiasMes := {}
Return 
