#INCLUDE "Protheus.ch"
#INCLUDE "RwMake.ch"
#INCLUDE "topconn.ch" 
#INCLUDE "Colors.ch" 
#INCLUDE "JPEG.CH"

/*
Programa        : Programa MSUPPESQ.prw
Objetivo        : Pesquisa de Produtos
Autor           : Bruno Lage Ferreira	
Data/Hora       : 12/02/2006 11:29
Obs.            : XUSB1 
*/

User Function MSUPPESQ(cPStart)
/*****************************************************************************************
* Programa principal 
*
***/              
Local lRet := .F.

Private oEdit1
Private oEdit2
Private oEdit3
   
Private cEdit1	 := IIf(Empty(cPStart),Space(15),cPStart)
Private cEdit2	 := Space(60)
Private cEdit3	 := Space(04)

Private oBoxLib

// Definindo os objetos de marcação
Private oNoMarked   := LoadBitmap( GetResources(), "LBNO" )
Private oMarked     := LoadBitmap( GetResources(), "LBOK" )

//Inicializando o aGrd com valores minimos 
Private aGrd := {{LoadBitmap(GetResources(), "BR_CINZA"   ),oNoMarked,"","","",0,"","","","",""}} 

Private aArrCor := {}     
Private cCodRet := ""

//Carregando as cores utilizadas 
aAdd(aArrCor,LoadBitmap(GetResources(), "BR_VERDE" )) // 1
aAdd(aArrCor,LoadBitmap(GetResources(), "BR_CINZA" )) // 2 
aAdd(aArrCor,LoadBitmap(GetResources(), "BR_LARANJA"))// 3

SetKey(VK_F9 , {|| MsgRun("Processando registros...","",{|| CursorWait(), fPeProGr(cEdit1,cEdit2,cEdit3),oBoxLib:SetFocus(),CursorArrow()})})
SetKey(VK_F10, {|| fReCoPro(cCodRet),Close(_oDlg) })

/*	
SetKey(VK_F6, {|| fConEst(xFilial("SB2")) })
SetKey(VK_F8, {|| MsgRun("Visualizando registro...","",{|| CursorWait(), fVisProd(cEdit1),CursorArrow()}) })
*/
DEFINE MSDIALOG _oDlg TITLE "Pesquisa de Produtos" FROM U_MGETTELA(219),U_MGETTELA(180) TO U_MGETTELA(613),U_MGETTELA(966+200) PIXEL

	// Cria Componentes Padroes do Sistema
	@ U_MGETTELA(001),U_MGETTELA(009) Say "Código:" Size U_MGETTELA(020),U_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlg
	@ U_MGETTELA(001),U_MGETTELA(078) Say "Descrição:" Size U_MGETTELA(027),U_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlg
	@ U_MGETTELA(000),U_MGETTELA(323) Say "Grupo:" Size U_MGETTELA(018),U_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlg
	
	@ U_MGETTELA(010),U_MGETTELA(009) MsGet oEdit1 Var cEdit1              Size U_MGETTELA(060),U_MGETTELA(009) COLOR CLR_BLACK PIXEL OF _oDlg
	@ U_MGETTELA(010),U_MGETTELA(078) MsGet oEdit2 Var cEdit2 Picture "@!" Size U_MGETTELA(235),U_MGETTELA(009) COLOR CLR_BLACK PIXEL OF _oDlg
		//oEdit2:SetFocus()
	@ U_MGETTELA(010),U_MGETTELA(323) MsGet oEdit3 Var cEdit3 F3("SBM")    Size U_MGETTELA(062),U_MGETTELA(009) COLOR CLR_BLACK PIXEL OF _oDlg
	
	@ U_MGETTELA(177),U_MGETTELA(201) Button "Visualizar" 		Action(MsgRun("Visualizando registro...","",{|| CursorWait(), fVisProd(cEdit1)              ,CursorArrow() }))   Size U_MGETTELA(037),U_MGETTELA(012) PIXEL OF _oDlg
	@ U_MGETTELA(177),U_MGETTELA(252) Button "Pesquisar [F9]"  	Action(MsgRun("Processando registros...","",{|| CursorWait(), fPeProGr(cEdit1,cEdit2,cEdit3),CursorArrow() }))   Size U_MGETTELA(037),U_MGETTELA(012) PIXEL OF _oDlg
	@ U_MGETTELA(177),U_MGETTELA(301) Button "Estoque"    		Action(fConEst(aGrd[oBoxLib:nAt,9])) 																		     Size U_MGETTELA(037),U_MGETTELA(012) PIXEL OF _oDlg
	@ U_MGETTELA(177),U_MGETTELA(347) Button "OK [F10]"         Action(fReCoPro(cCodRet),Close(_oDlg)) 																		  	 Size U_MGETTELA(037),U_MGETTELA(012) PIXEL OF _oDlg

	@ U_MGETTELA(026),U_MGETTELA(009) ListBox oBoxLib  Fields Headers 	" "			,; 
																		" "			,;
																		"Codigo"	,;
																		"Descricao"	,;
																		"UM"		,;
																		"Grupo"		,;
																		"Local"		,;
																		"Qtd Atual"	,;
																		"Filial"    ,;
																		"Nome"      ,;
																		"End.Aproximado";
		Size U_MGETTELA(376+100),U_MGETTELA(145) ON DBLCLICK (FLocaArr(aGrd[oBoxLib:nAt,3])) Pixel Of _oDlg
	  	
		oBoxLib:SetArray(aGrd)
		oBoxLib:bLine := {|| {  aGrd[oBoxLib:nAt,01],;
								aGrd[oBoxLib:nAt,02],;
								aGrd[oBoxLib:nAt,03],;
								aGrd[oBoxLib:nAt,04],;
								aGrd[oBoxLib:nAt,05],;
								aGrd[oBoxLib:nAt,06],;
								aGrd[oBoxLib:nAt,07],;
								aGrd[oBoxLib:nAt,08],;
								aGrd[oBoxLib:nAt,09],;
								aGrd[oBoxLib:nAt,10],;
								aGrd[oBoxLib:nAt,11];
								}}
								
		If !Empty(cPStart)
			fPeProGr(cEdit1,cEdit2,cEdit3)
			FLocaArr(cEdit1) 
		EndIf

ACTIVATE MSDIALOG _oDlg CENTERED 


SetKey(VK_F9,Nil)
SetKey(VK_F10,Nil)
 
/*
SetKey(VK_F9,Nil)
SetKey(VK_F6,Nil) 
SetKey(VK_F8,Nil)
*/

IF !Empty(cCodRet)
	lRet := .T.                       
	dbSelectArea("SB1")
	dbSetOrder(1)                                   
	dbSeek( xFilial("SB1") + cCodRet )		
Else
	lRet := .F.	    
EndIf	

Return(lRet)          


Static Function fVisProd(cCodRet)
/*****************************************************************************************
*  Sair
*
***/   

IF Empty(cCodRet)
	Return(.t.)
EndIf

dbSelectArea("SB1")
dbSetOrder(1)
dbSeek(xFilial("SB1")+AllTrim(cCodRet))
A010Visul("SB1" )

Return(.t.)
                   
Static Function fReCoPro(cCodRet)
/*****************************************************************************************
*  Sair
*
***/   
                                
IF !Empty(cCodRet)	
	lRet := .T.                       
	dbSelectArea("SB1")
	dbSetOrder(1)                                   
	dbSeek( xFilial("SB1") + cCodRet )		
Else
	lRet := .F.	    
EndIf	

Return

Static Function fVerFoto()
/*****************************************************************************************
*  Funcao visualização das fotos 
*
***/                                          
Local oDlgFoto  
Local oBmp			                      
Local cCodPro := ""
Local nX      := 0


For nX := 1 To Len(aGrd)                           
	If aGrd[nX,2] == oMarked
		cCodPro := aGrd[nX,3]
	EndIf 
Next nX                 

IF !Empty(cCodPro)
	dbSelectarea("SB1")
	dbSetOrder(1)                         
	If dbSeek(xFilial("SB1")+cCodPro)
  		DEFINE MSDIALOG oDlgFoto TITLE "Foto: " + SB1->B1_DESC FROM U_MGETTELA(178),U_MGETTELA(181) TO U_MGETTELA(395),U_MGETTELA(395) PIXEL 
  			@ U_MGETTELA(004), U_MGETTELA(004) REPOSITORY oBmp SIZE U_MGETTELA(100), U_MGETTELA(100) PIXEL NO BORDER OF oDlgFoto
				oBmp:lAutoSize := .T.
				oBmp:LoadBmp(SB1->B1_BITMAP)
				oBmp:Refresh()			
		ACTIVATE MSDIALOG oDlgFoto CENTERED 			
	EndIf
EndIf

Return


Static Function FLocaArr(cValPes)       
/*****************************************************************************************
* Selecao do produto 
*
***/ 
Local lNotRepet := .T.
Local nX        := 0


For nX := 1 To Len(aGrd)
	iF !Empty(aGrd[nX,3])
		If aGrd[nX,3] == cValPes
			aGrd[nX,2] :=	oMarked 
			cCodRet    :=   aGrd[nX,3]
			
			cEdit1     :=   cCodRet 
			
			If aGrd[nX,8] <= 0 .And. lNotRepet 
				lNotRepet := .F.
				Alert("Este item não possui estoque em algum almoxarifado. Verifique!")
			EndIf
		Else                 
			aGrd[nX,2] :=   oNoMarked
		EndIf 
	EndIf
Next nX      
            
oBoxLib:Refresh() 
oEdit1:Refresh()

Return  

Static Function fPeProGr(cEdVa1,cEdVa2,cEdVa3)       
/*****************************************************************************************
* Funcao de pesquisa dos produtos na grid 
*§
***/ 
Local cQuery  := ""  

If  Len(AllTrim(cEdVa2)) < 3 .and. Empty(cEdVa1)
	Alert("Erro ! Quantiade de caracteres menor que 3! Digite o mínimo de 3 algarismo.")
	Return()
EndIf

cQuery := " SELECT DISTINCT * FROM (

cQuery += " 	 SELECT	RTRIM(LTRIM(B1_COD))  B1_COD,	
cQuery += "  			RTRIM(LTRIM(B1_DESC)) B1_DESC,
cQuery += "  			B1_UM,
cQuery += "  			B1_ENDAPRO,
cQuery += "  			RTRIM(LTRIM(BM_DESC)) BM_DESC,
cQuery += "  			ISNULL(B2_LOCAL,'') + '-' + ISNULL(RTRIM(LTRIM((SELECT NNR_DESCRI FROM " + RetSqlName("NNR") + " NNR  WHERE D_E_L_E_T_ = '' AND NNR_CODIGO = B2_LOCAL AND LEFT(NNR_FILIAL,4) =  LEFT(B2_FILIAL,4) ))),'') LOCALax,
cQuery += "  			ISNULL(B2_QATU,0) B2_QATU,
cQuery += "  			B1_MSBLQL,
cQuery += "  			ISNULL(B2_FILIAL ,'') B2_FILIAL
//cQuery += " 			ISNULL((SELECT B2_FILIAL FROM " + RetSqlName("SB2") + " SB2 WHERE D_E_L_E_T_ = '' AND B2_FILIAL = '" + + "' AND B1_COD = B2_COD ),'"+xFilial("SB2")+"') FILIAL_SB2
cQuery += " 	   FROM " + RetSqlName("SB1") + "  SB1 INNER JOIN " + RetSqlName("SBM") + " SBM 
cQuery += " 		 ON (B1_GRUPO = BM_GRUPO)
cQuery += "  		   FULL JOIN " + RetSqlName("SB2") + " SB2
cQuery += "  		ON (B1_COD = B2_COD)
cQuery += " 	  WHERE SBM.D_E_L_E_T_ <> '*' 
cQuery += " 		AND SB1.D_E_L_E_T_ <> '*' 
cQuery += " 		AND ISNULL(SB2.D_E_L_E_T_,'') <> '*'

If !Empty(cEdVa1)
	cQuery += " 	AND B1_COD LIKE '%"+ Replace(AllTrim(cEdVa1),"'","") +"%'   "
EndIf                                                         
If !Empty(cEdVa2)
	cQuery += " 	AND B1_DESC LIKE '%"+ Replace(AllTrim(cEdVa2),"'","") +"%'   "
EndIf                                                         
If !Empty(cEdVa3)
	cQuery += " 	AND B1_GRUPO = '" + Replace(AllTrim(cEdVa3),"'","") + "'" 
EndIf

cQuery += " 		)TB_TEMP 

//cQuery += " WHERE FILIAL_SB2 = '" + SubString(CNUMEMP,3,6) + "'

cQuery += " ORDER BY B1_COD   

/*	                     
cQuery := " SELECT	RTRIM(LTRIM(B1_COD))  B1_COD,	
cQuery += " 		RTRIM(LTRIM(B1_DESC)) B1_DESC,
cQuery += " 		B1_UM,
cQuery += " 		RTRIM(LTRIM(BM_DESC)) BM_DESC,
cQuery += " 		ISNULL(B2_LOCAL,'') + '-' + ISNULL(RTRIM(LTRIM((SELECT NNR_DESCRI FROM " + RetSqlName("NNR") + " NNR  WHERE D_E_L_E_T_ = '' AND NNR_CODIGO = B2_LOCAL AND LEFT(NNR_FILIAL,4) =  LEFT(B2_FILIAL,4) ))),'') LOCAL,
cQuery += " 		ISNULL(B2_QATU,0) B2_QATU,
cQuery += " 		B1_MSBLQL
cQuery += "   FROM " + RetSqlName("SB1") + "  SB1 INNER JOIN " + RetSqlName("SBM") + " SBM 
cQuery += "     ON (B1_GRUPO = BM_GRUPO)
cQuery += " 	   FULL JOIN " + RetSqlName("SB2") + " SB2
cQuery += " 	ON (B1_COD = B2_COD)
cQuery += "  WHERE SBM.D_E_L_E_T_ <> '*' 
cQuery += "    AND SB1.D_E_L_E_T_ <> '*' 
cQuery += "    AND ISNULL(SB2.D_E_L_E_T_,'') <> '*'
cQuery += "    AND (SB2.B2_FILIAL = '"+xFilial("SB2")+"' OR ISNULL(SB2.B2_FILIAL,'X') = 'X')
//cQuery += "    AND LEFT(B1_COD,2) NOT IN ('BL','AM','CH','FA')
	                     
If !Empty(cEdVa1)
	cQuery += " AND B1_COD LIKE '%"+ AllTrim(cEdVa1) +"%'   "
EndIf                                                         
If !Empty(cEdVa2)
	cQuery += " AND B1_DESC LIKE '%"+ AllTrim(cEdVa2) +"%'   "
EndIf                                                         
If !Empty(cEdVa3)
	cQuery += " AND B1_GRUPO = '" + AllTrim(cEdVa3) + "'" 
EndIf

cQuery += " ORDER BY B1_COD                   
*/             

cQuery := ChangeQuery(cQuery)
TCQUERY cQuery NEW ALIAS "TRB1"                               

aGrd 	:= {}         

cCodRet := ""

dbSelectArea("TRB1")
dbGoTop()
Do While !EoF()      
                         
	If TRB1->B1_MSBLQL = '1'
		nCdCor  := 2
	Else
		nCdCor  := 1
	EndIf           

	If AllTrim(TRB1->LOCALax)== '-'
		nCdCor  := 3
	EndIf

	aAdd(aGrd, {aArrCor[nCdCor]	        ,;
				oNoMarked 		        ,;
				TRB1->B1_COD 	        ,;
				AllTrim(TRB1->B1_DESC)	,; 
				TRB1->B1_UM		        ,;
				Alltrim(TRB1->BM_DESC)	,;
				TRB1->LOCALax 	        ,;
				TRB1->B2_QATU 	        ,;
				TRB1->B2_FILIAL         ,;
				FWFilialName(SubString(CNUMEMP,1,2),TRB1->B2_FILIAL,1),;
				AllTrim(TRB1->B1_ENDAPRO);
				})	
				
	dbSelectArea("TRB1")
	dbSkip()
EndDo          

if Len(aGrd) <= 0
	aGrd := {	{LoadBitmap(GetResources(),"BR_CINZA"),;
				oNoMarked,;
				"",;
				"",;
				"",;
				"",;
				"",;
				0 ,;
				"",;
				"",;
				"";
				}}
EndIf

dbSelectArea("TRB1")
dbCloseArea()  
 
oBoxLib:SetArray(aGrd)  
oBoxLib:bLine := {|| {	aGrd[oBoxLib:nAt,01],;
						aGrd[oBoxLib:nAt,02],;
						aGrd[oBoxLib:nAt,03],;
						aGrd[oBoxLib:nAt,04],;
						aGrd[oBoxLib:nAt,05],;
						aGrd[oBoxLib:nAt,06],;
						aGrd[oBoxLib:nAt,07],;
						aGrd[oBoxLib:nAt,08],;
						aGrd[oBoxLib:nAt,09],;
						aGrd[oBoxLib:nAt,10],;
						aGrd[oBoxLib:nAt,11];
						}}  
oBoxLib:Refresh()             
	
Return

Static Function fConEst(cEmpFil)       
/*****************************************************************************************
* Funcao de consulta estoque
*
***/   
Local cCodPro
Local cCodLocal 
Local nX        := 0
//Local NPOSLOTE  

For nX := 1 To Len(aGrd)                           
	If aGrd[nX,2] == oMarked .and. AllTrim(aGrd[oBoxLib:nAt,7]) == AllTrim(aGrd[nX,7]) 
		cCodPro   := aGrd[nX,3]
		cCodLocal := SUBSTR(aGrd[oBoxLib:nAt,7],1, AT("-",aGrd[oBoxLib:nAt,7]) -1)
	EndIf 
Next nX 

If !Empty(cCodPro)
	dbSelectArea("SB1")
	dbSetOrder(1)
	dbSeek(xFilial("SB1")+ cCodPro)
	If SB1->B1_RASTRO = 'N'
		MaViewSB2(cCodPro,cEmpFil)
	Else
		F4Lote(,,,   '',cCodPro,cCodLocal,NIL,'',1)
	EndIf
EndIf
	
Return
                                                                                                                 

Static Function fConProd()
/*****************************************************************************************
* Função de consulta produtos 
*
***/
Local cCodPro := ""
Local nX      := 0
                   

For nX := 1 To Len(aGrd)                           
	If aGrd[nX,2] == oMarked
		cCodPro := aGrd[nX,3]
	EndIf 
Next nX 
                            
If !Empty(cCodPro)
	dbSelectArea("SB1")
	dbSetOrder(1)
	dbGoTop()
	If DbSeek(xFilial("SB1")+cCodPro)
		A010Visul("SB1",,2)
	EndIf
EndIf
	
Return                                                                                               

Static Function Flegenda()
/******************************************************************************************
* Função Consulta Legendas
*
***/
Local oDlgLeg                                     
Local oListLeg
Local aGrdLeg := {}
                         
aAdd(aGrdLeg,{aArrCor[3 ],"Preço de venda normal."})
aAdd(aGrdLeg,{aArrCor[1 ],"Preço promocional."})
aAdd(aGrdLeg,{aArrCor[5 ],"Tabela de preços não encontrada ou produto não encontrado na tabela de preços."}) 
aAdd(aGrdLeg,{aArrCor[11],"A pesquina não encontrou nenhum resultado"})   


DEFINE MSDIALOG oDlgLeg TITLE "Legenda" FROM U_MGETTELA(275),U_MGETTELA(294) TO U_MGETTELA(468),U_MGETTELA(787) PIXEL	
	@ U_MGETTELA(005),U_MGETTELA(003) ListBox oListLeg Fields HEADER " ","Descrição" Size U_MGETTELA(242),U_MGETTELA(070) ;
		Of oDlgLeg Pixel;
					
		oListLeg:SetArray(aGrdLeg)                                                                                 
		oListLeg:bLine := {|| {	aGrdLeg[oListLeg:nAt,1],;
								aGrdLeg[oListLeg:nAt,2] }}
		oListLeg:lHScroll := .F. 
		oListLeg:lVScroll := .F.
	@ U_MGETTELA(084),U_MGETTELA(208) Button "Fechar" Size U_MGETTELA(037),U_MGETTELA(012) Action (Close(oDlgLeg))PIXEL OF oDlgLeg
ACTIVATE MSDIALOG oDlgLeg CENTERED                                                                               

Return
