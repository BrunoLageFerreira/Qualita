#INCLUDE "Protheus.ch"
#INCLUDE "RwMake.ch"
#INCLUDE "topconn.ch"

/*
Programa ...: MTROCVEN.Prw
Uso ........: Troca vendedor da Nota Fiscal para efeito de Comissao
Data .......: 17/12/2009
Feito por ..: Bruno Lage Ferreira
Copyright @1998-2001,2010


*/ 

User Function MTROCVEN()
**********************************************************************************************************
* /* Programa principal */  
*
***
Private cEdit1	 := Space(09)
Private cEdit2	 := Space(03)
Private cEdit3	 := Space(25)
Private cEdit4	 := Space(25)
Private cEdit5	 := Space(25)

Private oEdit1
Private oEdit2
Private oEdit3
Private oEdit4
Private oEdit5

Private _oDlg			

DEFINE MSDIALOG _oDlg TITLE "Troca de Vendedor na NF-eletrônica" FROM U_MGETTELA(324),U_MGETTELA(254) TO U_MGETTELA(601),U_MGETTELA(722) PIXEL
    
	@ U_MGETTELA(003),U_MGETTELA(010) Say "Programa para troca do Ag. de Vendas para efeito de comissão." Size U_MGETTELA(153),U_MGETTELA(008) COLOR CLR_RED PIXEL OF _oDlg
	
	@ U_MGETTELA(015),U_MGETTELA(009) TO U_MGETTELA(075),U_MGETTELA(188) LABEL " Vendedor Atual: " PIXEL OF _oDlg	
		@ U_MGETTELA(028),U_MGETTELA(019) Say "Número da Nota:" Size U_MGETTELA(042),U_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlg
		@ U_MGETTELA(037),U_MGETTELA(018) MsGet oEdit1  Var cEdit1 valid(MbuscNFE()) Picture("999999999") Size U_MGETTELA(060),U_MGETTELA(009) COLOR CLR_BLACK PIXEL OF _oDlg

		@ U_MGETTELA(028),U_MGETTELA(085) Say "Série:" Size U_MGETTELA(015),U_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlg
		@ U_MGETTELA(037),U_MGETTELA(084) MsGet oEdit2 Var cEdit2 valid(MbuscNFE())  Picture("999")       Size U_MGETTELA(024),U_MGETTELA(009) COLOR CLR_BLACK PIXEL OF _oDlg

		@ U_MGETTELA(050),U_MGETTELA(019) Say "Vendedor Atual:" Size U_MGETTELA(040),U_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlg
		@ U_MGETTELA(058),U_MGETTELA(018) MsGet oEdit3 Var cEdit3 when(.F.) Size U_MGETTELA(165),U_MGETTELA(009) COLOR CLR_BLACK PIXEL OF _oDlg
    
   @ U_MGETTELA(078),U_MGETTELA(009) TO U_MGETTELA(133),U_MGETTELA(188) LABEL " Novo Vendedor: " PIXEL OF _oDlg
		@ U_MGETTELA(088),U_MGETTELA(019) Say "Código do Vendedor:" Size U_MGETTELA(052),U_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlg
		@ U_MGETTELA(097),U_MGETTELA(019) MsGet oEdit4 Var cEdit4 F3 "SA3" valid(MbuscVen()) Size U_MGETTELA(038),U_MGETTELA(009) COLOR CLR_BLACK PIXEL OF _oDlg
		@ U_MGETTELA(109),U_MGETTELA(019) Say "Nome do Vendedor:" Size U_MGETTELA(049),U_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlg
		@ U_MGETTELA(117),U_MGETTELA(018) MsGet oEdit5 Var cEdit5 Size U_MGETTELA(163),U_MGETTELA(009) COLOR CLR_BLACK PIXEL OF _oDlg
	
	@ U_MGETTELA(102),U_MGETTELA(192) Button "Trocar" Action(MTroVen()) Size U_MGETTELA(037),U_MGETTELA(012) PIXEL OF _oDlg
	@ U_MGETTELA(119),U_MGETTELA(192) Button "Fechar" Action(Close(_oDlg)) Size U_MGETTELA(037),U_MGETTELA(012) PIXEL OF _oDlg

ACTIVATE MSDIALOG _oDlg CENTERED 

Return(.T.)                                                         

Static Function MbuscNFE()     
**********************************************************************************************************
* /* Busca Nota */  
*
***              
	If Len(AllTrim(cEdit1)) == 6
		cEdit1 := cEdit1      
	Else
		cEdit1 := cEdit1
	EndIf
	
	dbSelectArea("SF2")
	dbSetOrder(1)
	If dbSeek(xFilial("SF2")+cEdit1+cEdit2)
		dbSelectArea("SA3")
		dbSetOrder(1) 
		If dbSeek(xFilial("SA3") + SF2->F2_VEND1 )
			cEdit3 := SA3->A3_COD + "-" + SA3->A3_NOME
			oEdit3:Refresh()
		EndIf
	EndIf
	
Return(.t.)

Static Function MbuscVen()     
**********************************************************************************************************
* /* Busca Vend */  
*
***         
     
	dbSelectArea("SA3")
	dbSetOrder(1) 
	If dbSeek(xFilial("SA3") + cEdit4 )
		cEdit5 := SA3->A3_COD + "-" + SA3->A3_NOME
		oEdit5:Refresh()
	EndIf
	
Return(.t.)                                                                                                                                                

Static Function MTroVen()     
**********************************************************************************************************
* /* Busca Vend */                                                                                 	
*
*** 
Local cMSGWEB := "" 
Local cQuery  := ""                                   
        
	If Len(AllTrim(cEdit1)) == 6
		cEdit1 := cEdit1      
	Else
		cEdit1 := cEdit1
	EndIf
	
	dbSelectArea("SF2")
	dbSetOrder(1)
	If dbSeek(xFilial("SF2")+cEdit1+cEdit2)
		RecLock("SF2",.F.)
			SF2->F2_VEND1 := cEdit4 
		MsUnlock()   
	EndIf                                        
	  
	cQuery  := " UPDATE " + RetSqlName("SE1") 
	cQuery  += "    SET E1_VEND1 = '"+cEdit4+"' 
	cQuery  += "   FROM " + RetSqlName("SE1")
	cQuery  += "  WHERE D_E_L_E_T_ = '' 
	cQuery  += "    AND E1_FILIAL  = '"+xFilial("SE1")+"'
	cQuery  += "    AND E1_CLIENTE = '"+SF2->F2_CLIENTE+"'
	cQuery  += "    AND E1_LOJA    = '"+SF2->F2_LOJA+"'
	cQuery  += "    AND E1_PREFIXO = '"+SF2->F2_PREFIXO+"'
	cQuery  += "    AND E1_NUM     = '"+SF2->F2_DOC+"' 
	
	TcSQLExec(cQuery)
				
	cQuery  := " UPDATE " + RetSqlName("SC5") 
	cQuery  += " SET C5_VEND1 = '"+cEdit4+"'
	cQuery  += " FROM " + RetSqlName("SC5") 
	cQuery  += " WHERE D_E_L_E_T_ = ''
	cQuery  += " AND C5_NUM = (SELECT DISTINCT E1_PEDIDO 
	cQuery  += "                 FROM SE1010 
	cQuery  += "                WHERE D_E_L_E_T_ = '' 
	cQuery  += "                  AND E1_FILIAL  = '"+xFilial("SE1")+"'
	cQuery  += "                  AND E1_CLIENTE = '"+SF2->F2_CLIENTE+"'
	cQuery  += "                  AND E1_LOJA    = '"+SF2->F2_LOJA+"'
	cQuery  += "                  AND E1_PREFIXO = '"+SF2->F2_PREFIXO+"'
	cQuery  += "                  AND E1_NUM     = '"+SF2->F2_DOC+"')

	TcSQLExec(cQuery)
			                                                   
	cMSGWEB := "O usuário " + AllTrim( Upper(Substr(cUsuario,7,15)) ) + " alterou a NF-E:" + cEdit1 + "/" + cEdit2 + " do Vend.:" + AllTrim(cEdit3) + " para o " +  AllTrim(cEdit5)

	Alert(cMSGWEB + ". Vendedor gravado com sucesso!")
	
Return(.t.)