#INCLUDE "PROTHEUS.CH"               

/*
Programa ...: MGETTELA.Prw
Uso ........: Resolucao do monitor
Data .......: 18/04/2007
Feito por ..: Bruno Lage Ferreira
Copyright @1998-2001,2007
*/ 

User Function MGETTELA(nTam)                                                         
	*************************************************************************************************
	* /* Resolucao do monitor */
	*
	***
	Local nHRes		
	
	ConOut("**************************************************")
	ConOut("**************************************************")
	ConOut("*************   MGETTELA(nTam)  ******************")
	ConOut("**************************************************")
	ConOut("**************************************************")
	ConOut(IsBlind())
	
	If !IsBlind()
		
		nHRes := oMainWnd:nClientWidth
			
		If nHRes == 640	
			nTam *= 0.8                                                                
		ElseIf (nHRes == 798).Or.(nHRes == 800)	
			nTam *= 1                                                                  
		Else	                                      
			nTam *= 1.28                                                              
		EndIf                                                                        
	
		If "MP8" $ oApp:cVersion                                                      
			If (Alltrim(GetTheme()) == "FLAT") .Or. SetMdiChild()                      
				nTam *= 0.90                                                            
			EndIf                                                                      
		EndIf       
		
	EndIf                  
	                                            
Return Int(nTam) 