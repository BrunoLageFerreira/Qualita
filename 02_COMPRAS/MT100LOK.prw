#INCLUDE "RWMAKE.CH"

/*
MT100LOK()
//.AND. cTipo <> "B"
*/

User Function MT100LOK() 
*******************************************************************************************
*
*
***
Local aMT100LOK    := GetArea()
Local lRet         := .T.
Local cLoteInterno := ""
Local lRetBLFera   := .F. 
Local iXD := AScan(aHeader, { |x| Alltrim(x[2]) == 'D1_CONTA'})




/*
SOMENTE PARA NOTA FISCAL 
*/
If FUNNAME() <> "MATA116" .And. SubString(CNUMEMP,1,2) == "01" 
	/*
	NOTAS DE BLOCOS NA QUALITA NAO USA IMPORTADOR XML
	porem pode ser usados no gpplus 
	*/
	If SubString(CNUMEMP,1,2) == "01" .And. l103Auto == .T. .And. SubString(gdFieldGet("D1_COD"),1,2) = "BL" .And. (AllTrim(CA100FOR) <> '000165') .And. (AllTrim(cEspecie) <> 'CTE')
	//If SubString(CNUMEMP,1,2) == "01" .And. SubString(gdFieldGet("D1_COD"),1,2) = "BL" .And. AllTrim(CA100FOR) <> '000165'
	
		If MsgYesNo("Esta é uma nota fiscal retorno de exposição/feiras ou exportações? [S]Sim ou [N]Não ?")
			lRetBLFera := .T.  
		EndIF

		If lRetBLFera == .F.
			Aviso("Aviso!","As notas de blocos não podem ser lançadas pelo importador XML! - Qualita! MT100LOK-02")
			
			//Aviso(gdFieldGet("D1_FORNECE"))
			//Aviso('000165')
			Return(.F.)
		EndIf
	EndIf

	/*
	SOMENTE PARA QUALITA
	*/
	IF cTipo <> "C"
		IF SubString(CNUMEMP,1,2) == "01" .And. lRetBLFera == .F. 
			If SubString(gdFieldGet("D1_COD"),1,2) = "BL" .And. (AllTrim(cEspecie) <> 'CTE') 
		
				/*
				Lote do fornecedor
				D1_YCOMBRU,D1_YALTBRU,D1_YESPBRU,D1_YTOTBRU,D1_YCOMLIQ,D1_YALTLIQ,D1_YESPLIQ,D1_YTOTLIQ
				*/
				If 	EMPTY(gdFieldGet("D1_YPESOBR")) .Or.;
					EMPTY(gdFieldGet("D1_YPESOLQ")) .Or.;
					EMPTY(gdFieldGet("D1_YCOMBRU")) .Or.;
					EMPTY(gdFieldGet("D1_YALTBRU")) .Or.; 
					EMPTY(gdFieldGet("D1_YESPBRU")) .Or.;
					EMPTY(gdFieldGet("D1_YTOTBRU")) .Or.; 
					EMPTY(gdFieldGet("D1_YCOMLIQ")) .Or.;
					EMPTY(gdFieldGet("D1_YALTLIQ")) .Or.;
					EMPTY(gdFieldGet("D1_YESPLIQ")) .Or.;
					EMPTY(gdFieldGet("D1_YTOTLIQ")) 
					
					Alert("Verifique os campos de Comprimento X Altura X Espessura, peso líquido e bruto. Não podem estar em branco!")
					lRet := .F.
					Return(lRet)
				EndIf
		
				/*
				Lote do Fornecedor
				*/
				If Empty(gdFieldGet("D1_LOTEFOR")) .And. AllTrim(CA100FOR) == '000165'
					//GDFieldPut ( "D1_LOTEFOR", gdFieldGet("D1_LOTECTL") )
					GDFieldPut ( "D1_LOTEFOR", "" )
				ElseIf Empty(gdFieldGet("D1_LOTEFOR"))
					Alert("Lote do Fornecedor não pode ficar em branco!")
					lRet := .F.
					Return(lRet)
				EndIf
				
				dbSelectArea("SF4")
				dbSetOrder(1)
				If dbSeek(xFilial("SF4") + AllTrim(gdFieldGet("D1_TES")))
					/*
					Somente tes que controla estoque
					*/
					If SF4->F4_ESTOQUE = "S"
						/*
						Lote sequencial Qualita
						*/
						If Empty(gdFieldGet("D1_LOTECTL"))
							Processa({ || cLoteInterno := MCriaLote()}, "Gerando Lote Interno","Processando...", .T.)     
							GDFieldPut ( "D1_LOTECTL", cLoteInterno  )
							lRet := .T.
						EndIf
						
					EndIf
					
				EndIf
				
			EndIF	
		EndIF
	ENDIF
	
	IF SubString(CNUMEMP,1,2) == "01"  .AND. lRetBLFera == .T. .AND. ( EMPTY(gdFieldGet("D1_YCOMBRU")) .Or.;
							 	 EMPTY(gdFieldGet("D1_YALTBRU")) .Or.; 
							 	 EMPTY(gdFieldGet("D1_YESPBRU")) .Or.;
							 	 EMPTY(gdFieldGet("D1_YTOTBRU")) .Or.; 
							 	 EMPTY(gdFieldGet("D1_YCOMLIQ")) .Or.;
								 EMPTY(gdFieldGet("D1_YALTLIQ")) .Or.;
								 EMPTY(gdFieldGet("D1_YESPLIQ")) .Or.;
								 EMPTY(gdFieldGet("D1_YTOTLIQ")) ) 
	
		dbSelectArea("SD1")
		dbSetOrder(24)
		If dbSeek(xFilial("SD1") + gdFieldGet("D1_YOP") + gdFieldGet("D1_COD") + gdFieldGet("D1_LOTECTL") + gdFieldGet("D1_NUMLOTE")  )
		
			GDFieldPut ( "D1_YCOMBRU", SD1->D1_YCOMBRU  )
			GDFieldPut ( "D1_YALTBRU", SD1->D1_YALTBRU  )
			GDFieldPut ( "D1_YESPBRU", SD1->D1_YESPBRU  )
			GDFieldPut ( "D1_YTOTBRU", SD1->D1_YTOTBRU  )
			GDFieldPut ( "D1_YCOMLIQ", SD1->D1_YCOMLIQ  )
			GDFieldPut ( "D1_YALTLIQ", SD1->D1_YALTLIQ  )
			GDFieldPut ( "D1_YESPLIQ", SD1->D1_YESPLIQ  )
			GDFieldPut ( "D1_YTOTLIQ", SD1->D1_YTOTLIQ  )
			GDFieldPut ( "D1_LOTEFOR", SD1->D1_LOTEFOR  )
				
		EndIf 
	
	EndIf

RestArea(aMT100LOK)

EndIf
	
Return(lRet)


Static Function MCriaLote()
*******************************************************************************************
*
*
***
Local cValorLote := GetMv("MV_NLOTEQ")

	ProcRegua(2) 
	
	cValorLote := Soma1(cValorLote)
	PutMv("MV_NLOTEQ",cValorLote)
	
	IncProc("Criando Lote:" + cValorLote) 
	Sleep( 2000 ) 
	
	IncProc("Criando Lote:" + cValorLote)
	Sleep( 2000 ) 
	
	IF gdFieldGet("D1_TES") $ "170/173"
		AVISO("Operação de Drawback", "Operação de drawback! O lote interno será gerado com sigla [DW] + NÚMERO." , { "Fechar" }, 1)
		cValorLote := "DW" + cValorLote	
	ENDiF
	
Return(cValorLote)
