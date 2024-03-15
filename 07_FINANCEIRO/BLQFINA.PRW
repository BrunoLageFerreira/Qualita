#INCLUDE "RWMAKE.CH"
#INCLUDE "protheus.ch"
#INCLUDE "TOPCONN.CH"

/*
Programa ...: BLQFINA.Prw 
Data .......: 26-02-2024
Feito por ..: Bruno Lage Ferreira
Copyright @1998-2001,2024

Usuários Administrador 
MV_USUREC customizado para usuarios nao validar a data limite

MV_DATAREC data limite da rec 
MV_DATAFIN
MV_BXDTFIN
*/ 
User Function BLQFINA() 
/***********************************************************************************************
*
*
***/
// Definição das variáveis do programa. 
Local cCodUsr := RetCodUsr() 
Public _mvDATAFIN  := GetMv("MV_DATAFIN") 
Public _mvBXDTFIN  := GetMv("MV_BXDTFIN") 
Public _mvusuarios := GetMv("MV_USUREC") //Não esqueça de criar este parâmetro
Private oPermBx
Private oMyDlg
Private oEdit1

// Verifica se o usuário é o Administrador do sistema ou usuários autorizados. 
If !Alltrim(cCodUsr) $ _mvusuarios 
     Alert("Somente o Administrador ou usuários autorizados podem executar esta rotina.") 
     Return 
EndIf 

DEFINE MSDIALOG oMyDlg TITLE "Bloqueio de Movimentação Financeira:" FROM U_MGETTELA(224),U_MGETTELA(175) TO U_MGETTELA(574),U_MGETTELA(711) PIXEL
     // Cria as Groups do Sistema
     @ U_MGETTELA(002),U_MGETTELA(004) TO U_MGETTELA(148),U_MGETTELA(259) LABEL "" PIXEL OF oMyDlg
          @ U_MGETTELA(020),U_MGETTELA(011) Say "Movimentações somente a partir de: " Size U_MGETTELA(089),U_MGETTELA(008) COLOR CLR_BLACK PIXEL OF oMyDlg
          @ U_MGETTELA(030),U_MGETTELA(012) MsGet oEdit1     VAR _mvDATAFIN           Size U_MGETTELA(071),U_MGETTELA(009) COLOR CLR_BLACK PIXEL OF oMyDlg
          
          @ U_MGETTELA(059),U_MGETTELA(012) Say "Permite baixas (Pagar/Receber), anteriores a data do bloqueio?"                                                             Size U_MGETTELA(120),U_MGETTELA(008) PIXEL OF oMyDlg
          @ U_MGETTELA(069),U_MGETTELA(012) ComboBox oPermBx VAR IIF(AllTrim(_mvBXDTFIN)=="1","Permite","Não permite") ITEMS {OemToAnsi("Permite"),OemToAnsi("Não permite")} Size U_MGETTELA(072),U_MGETTELA(010) PIXEL OF oMyDlg
          
     @ U_MGETTELA(152),U_MGETTELA(177) Button "Cancelar" ACTION Close(oMyDlg)              Size U_MGETTELA(037),U_MGETTELA(012) PIXEL OF oMyDlg
     @ U_MGETTELA(152),U_MGETTELA(220) Button "Salvar"   ACTION (RunProc(), Close(oMyDlg)) Size U_MGETTELA(037),U_MGETTELA(012) PIXEL OF oMyDlg
ACTIVATE MSDIALOG oMyDlg CENTERED 

Return 

Static Function RunProc() 
/***********************************************************************************************
*
*
***/
// Faz validações e Altera os parâmetros. 
If !Empty(_mvDATAFIN) 
     PutMv("MV_DATAFIN",_mvDATAFIN)
     PutMv("MV_DATAREC",_mvDATAFIN)
EndIf

If oPermBx:nAt == 1
	PutMv("MV_BXDTFIN","1")
Else
	PutMv("MV_BXDTFIN","2")
EndIf 

Return
