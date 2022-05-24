#include "protheus.ch"
#include "rwmake.ch"
#include "tbiconn.ch"  
#INCLUDE "TOTVS.CH"

/*
Programa ...: Dolar.Prw
Uso ........: Atualização do sistema de moedas automaticamente
Data .......: 18/04/2002
Feito por ..: Bruno Lage Ferreira
Copyright @1998-2001,2019


SELECT M2_MOEDA2 D_USD_COMPRA,YE_VLCON_C D_USD_VENDA 
 FROM SYE050 SYE INNER JOIN SM2050 SM2 ON (M2_DATA = YE_DATA)
WHERE SYE.D_E_L_E_T_ = '' 
  AND SM2.D_E_L_E_T_ = ''
  AND YE_MOEDA = 'USD' 
  AND YE_DATA ='20191024'


1  = REAL
2  = DOLLAR  					- 220 USD
3  = EURO   					- 978 EUR
4  = DOLÁR CANADENSE – (C$)		- 165 CAD
5  = LIBRA – (£)				- 540 GBP
6  = RENMINBI DA CHINA – (RMB)	- 796 CNH
7  = DONG VIETNÃ –  (D) OU (?)	- 260 VND
8  = RIAL – (QAR)				- 820 SAR
9  = RUBLO RUSSO – (RUB)		- 830 RUB
10 = PESO MEXICANO – (Mex$)		- 741 MXN 

*/ 

User Function Dolar()  //Dolar(dDataRef)
************************************************************************************************************
*
*
*
**************

Private cFile
Private cTexto
Private nLinhas 
Private cLinha, cData, cCompra, cVenda, dData
Private j
Private lAutoDolar := .f.  
Private _feriado
Private _ano
Private _pula := 0   
Private cQuery01, cQuery02

Private aDatas   := {}
Private lFeriado := .F. 
Private dDataRef		

ConOut( ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>   Atualizando taxa de moedas ..." )
// Seta os parametros para rodar via JOB (e colocar log)
If Select("SX2")==0 // Testa se está sendo rodado do menu 
	PREPARE ENVIRONMENT EMPRESA "05" FILIAL "01" TABLES "SM2", "SYE", "SX5", "SY2"
	Conout(DtoC(dDatabase)+" - "+TIME()+" Iniciando JOB de Atualizacao de Moedas...")
	lAutoDolar := .T.
EndIf 

// LIMPA REGISTROS DELETADOS DO SM2 E SYE PARA EVITAR ERRO CHAVE UNICA
cQuery01 := "DELETE FROM " + RetSQLName("SM2") + " WHERE D_E_L_E_T_ = '*' "
cQuery02 := "DELETE FROM " + RetSQLName("SYE") + " WHERE D_E_L_E_T_ = '*' "
                   
// Executa as queries...
TcSQLExec(cquery01)
TcSQLExec(cquery02)  

dDataRef := dDataBase 

/*
If !lAutoDolar
    
	ConOut("Entrou")
	dDataRefI := CtoD("01/01/16")
	Do While .t.
		If dDataRefI > ddatabase
			Exit
		EndIf
		fDolar(dDataRefI)
		dDataRefI ++	
	EndDo
	
Else
	ConOut("Nao Entrou")
	fDolar(dDataRef)

EndIf
*/

//fDolar(CtoD("11/02/21"))
fDolar(dDataRef)

Return


Static Function fDolar(dDataRef)
************************************************************************************************************
*
*
*
**************
Local nX := 1
 
DO CASE
	CASE Dow(dDataRef) == 1    // Se for domingo
		cFile := DTOS(dDataRef - 2)+".csv" 
		_pula := 2
	CASE Dow(dDataRef) == 7            // Se for sábado
		cFile := DTOS(dDataRef - 1)+".csv"
		_pula := 1
	CASE Dow(dDataRef) == 2            // Se for segunda
		cFile := DTOS(dDataRef - 3)+".csv"
		_pula := 3
	OTHERWISE                          // Se for dia normal
		cFile := DTOS(dDataRef - 1)+".csv"
		_pula := 0 
ENDCASE 
	
// Pega o dia anterior, mas se este dia anterior não tiver o arquivo vai até 7 dias antes
datai:=ddataref

While .T.
    
	cTexto  :=  HTTPGET('https://www4.bcb.gov.br/download/fechamento/'+cFile)  	//cTexto  :=  HTTPGET('http://www5.bcb.gov.br/download/'+cFile)	
	
	ConOut(">>>> Atualizando Moeda pelo Site do Banco Central...")
	ConOut('>>>> https://www4.bcb.gov.br/download/fechamento/'+cFile)
	
	
	
	cLinha := Memoline(cTexto,81,nX)
	IF (LEFT(CLINHA,2)<'01' .OR. LEFT(CLINHA,2)>'31') .OR. ;
		(SUBSTR(CLINHA,4,2)<'01' .OR. SUBSTR(CLINHA,4,2)>'12')
		datai:=datai-1
		cFile := DTOS(datai)+".csv"                                                

		If !lAutoDolar .or. (ddatabase - datai > 7 .and. lAutoDolar )
			exit
		Endif  

	Else
		Exit                                                                            
	Endif                                                                              
End

// Nao faz pois não acha arquivo no site do Banco Central
If ddatabase - datai > 7 .and. lAutoDolar
	If lAutoDolar
		Qout("Não encontrado arquivo no Site do Banco Central: "+cFile)
	ELSE
		// Caso não seja job, informa na a atualização
		Apmsginfo("Não encontrado arquivo no Site do Banco Central: "+cFile)
	Endif
	Return
Endif
/*
cQuery := "SELECT TOP 1 M2_MOEDA4 FROM " + RetSQLName("SM2") + " WHERE M2_DATA<='"+DToS(dDataRef)+"' AND M2_MOEDA3>0 ORDER BY M2_DATA DESC "
dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "TRB", .F., .T.)
dbSelectArea("TRB")
dbGoTop()
_vlufir := IIF(!eof(),m2_moeda4,0)
dbCloseArea()    
*/
DbSelectArea("SM2")
DbSetOrder(1)       
DbGotop()
		
DbSelectArea("SYE")
DbSetOrder(2) //ye_filial, ye_moeda, ye_data, r_e_c_n_o_, d_e_l_e_t_
DbGotop()


//  Conta o número de linhas do arquivo baixado (linhas com 81 caracteres)
nLinhas := MLCount(cTexto, 81)  

If lAutoDolar
	//Conout(DtoC(dDatabase)+" - "+TIME()+" "+cTexto)
EndIf
  

For nX := 1 to nLinhas     
	// Extrai a linha atual do arquivo e joga na variável

	cLinha  := Memoline(cTexto,81,nX)

    
	If lAutoDolar
		//Conout(DtoC(dDatabase)+" - "+TIME()+" "+cLinha)
	EndIf

	cData   := Substr(cLinha,1,10)
	dData   := dDataref  

//	If !lAutoDolar
		dData := CtoD(cData)  
//	EndIf
	
	cCompra := StrTran(Substr(cLinha,22,10),",",".")
	cVenda  := StrTran(Substr(cLinha,22+11,10),",",".")
	   
	//2  Se a moeda for Dolar Americano...
	IF Subst(cLinha,12,3)=="220" .AND. Val(cVenda) <> 0
                                              
		If lAutoDolar
			Conout(DtoC(dDatabase)+" - "+TIME()+" Atualizou SM2 - DOLAR")
		EndIf
		// Procura pela data, se já existir cria novo registro, senão edita
		dbSelectArea("SM2")
		IF SM2->( DbSeek(DTOS(dDataBase)) )
			Reclock("SM2",.F.)
			
		ELSE
			Reclock("SM2",.T.)
			Replace M2_DATA   With dDataBase //dData
			//Replace M2_FILIAL With xFilial("SM2")
		ENDIF
		/*
		Se For Qualitá
		*/
		If SubString(CNUMEMP,1,2) == "01"
			Replace M2_MOEDA2  With Val(cCompra)
		Else
			Replace M2_MOEDA2  With Val(cVenda)
		EndIf
	
		Replace M2_INFORM  With "S"
		MsUnlock("SM2")            

		// Atualiza a tabela SYE do sigaeic
		// Procura pela data, se já existir cria novo registro, senão edita
		DbSelectArea("SYE")
		IF SYE-> (DbSeek (xfilial('SYE')+"USD"+(DTOS(dDataBase))) ) .AND. Val(cVenda) <> 0
			Reclock("SYE",.F.)
		ELSE
			Reclock("SYE",.T.)
			Replace YE_DATA   With dDataBase           	
		ENDIF	
		Replace YE_MOE_FIN  With "2"
		Replace YE_MOEDA    With "USD"
		Replace YE_VLCON_C  With Val(cCompra)
		MsUnlock("SYE")  	   

	// 3 Se a moeda for EURO...	
	ELSEIF Subst(cLinha,12,3)=="978" .AND. Val(cVenda) <> 0
		If lAutoDolar
			Conout(DtoC(dDatabase)+" - "+TIME()+" Atualizou SM2 - EURO")
		EndIf
		dbSelectArea("SM2")
		IF SM2-> (DbSeek(DTOS(dDataBase)) )
			Reclock("SM2",.F.)
		ELSE
			Reclock("SM2",.T.)
			Replace M2_DATA   With dDataBase
		ENDIF                        			
		Replace M2_MOEDA3 With Val(cCompra)
		Replace M2_INFORM With "S"
		MsUnlock("SM2")

		// Atualiza a tabela SYE do sigaeic
		// Procura pela data, se já existir cria novo registro, senão edita
		dbSelectArea("SYE")
		IF SYE-> (DbSeek (xfilial('SYE')+"EUR"+(DTOS(dDataBase))) ).AND. Val(cVenda) <> 0
			Reclock("SYE",.F.)
		ELSE
			Reclock("SYE",.T.)
			Replace YE_FILIAL With xFilial("SYE")
			Replace YE_DATA   With dDataBase	
		ENDIF
		Replace YE_MOE_FIN  With "3"
		Replace YE_MOEDA   With "EUR"
		Replace YE_VLCON_C With Val(cCompra)
		MsUnlock("SYE")
	
	// 4  = DOLÁR CANADENSE – (C$)		- 165 CAD
	ELSEIF Subst(cLinha,12,3)=="165" .AND. Val(cVenda) <> 0
		If lAutoDolar
			Conout(DtoC(dDatabase)+" - "+TIME()+" Atualizou SM2 - DOLÁR CANADENSE")
		EndIf
		dbSelectArea("SM2")
		IF SM2-> (DbSeek(DTOS(dDataBase)) )
			Reclock("SM2",.F.)
		ELSE
			Reclock("SM2",.T.)
			Replace M2_DATA   With dDataBase
		ENDIF                        			
		Replace M2_MOEDA4 With Val(cCompra)
		Replace M2_INFORM With "S"
		MsUnlock("SM2")

		// Atualiza a tabela SYE do sigaeic
		// Procura pela data, se já existir cria novo registro, senão edita
		dbSelectArea("SYE")
		IF SYE-> (DbSeek (xfilial('SYE')+"CAD"+(DTOS(dDataBase))) ).AND. Val(cVenda) <> 0
			Reclock("SYE",.F.)
		ELSE
			Reclock("SYE",.T.)
			Replace YE_FILIAL With xFilial("SYE")
			Replace YE_DATA   With dDataBase	
		ENDIF
		Replace YE_MOE_FIN  With "4"
		Replace YE_MOEDA   With "CAD"
		Replace YE_VLCON_C With Val(cCompra)
		MsUnlock("SYE")
	
	// 5  = LIBRA – (£)					- 540 GBP 
	ELSEIF Subst(cLinha,12,3)=="540" .AND. Val(cVenda) <> 0
		If lAutoDolar
			Conout(DtoC(dDatabase)+" - "+TIME()+" Atualizou SM2 - LIBRA – (£)	")
		EndIf
		dbSelectArea("SM2")
		IF SM2-> (DbSeek(DTOS(dDataBase)) )
			Reclock("SM2",.F.)
		ELSE
			Reclock("SM2",.T.)
			Replace M2_DATA   With dDataBase
		ENDIF                        		
		Replace M2_MOEDA5 With Val(cCompra)
		Replace M2_INFORM With "S"
		MsUnlock("SM2")

		// Atualiza a tabela SYE do sigaeic
		// Procura pela data, se já existir cria novo registro, senão edita
		dbSelectArea("SYE")
		IF SYE-> (DbSeek (xfilial('SYE')+"GBP"+(DTOS(dDataBase))) ).AND. Val(cVenda) <> 0
			Reclock("SYE",.F.)
		ELSE
			Reclock("SYE",.T.)
			Replace YE_FILIAL With xFilial("SYE")
			Replace YE_DATA   With dDataBase	
		ENDIF
		Replace YE_MOE_FIN  With "5"		
		Replace YE_MOEDA   With "GBP"
		Replace YE_VLCON_C With Val(cCompra)
		MsUnlock("SYE")
	
	// 6  = RENMINBI DA CHINA – (RMB)	- 796 CNH
	ELSEIF Subst(cLinha,12,3)=="796" .AND. Val(cVenda) <> 0
		If lAutoDolar
			Conout(DtoC(dDatabase)+" - "+TIME()+" Atualizou SM2 - RENMINBI DA CHINA – (RMB)	")
		EndIf
		dbSelectArea("SM2")
		IF SM2-> (DbSeek(DTOS(dDataBase)) )
			Reclock("SM2",.F.)
		ELSE
			Reclock("SM2",.T.)
			Replace M2_DATA   With dDataBase
		ENDIF                        			
		Replace M2_MOEDA6 With Val(cCompra)
		Replace M2_INFORM With "S"
		MsUnlock("SM2")

		// Atualiza a tabela SYE do sigaeic
		// Procura pela data, se já existir cria novo registro, senão edita
		dbSelectArea("SYE")
		IF SYE-> (DbSeek (xfilial('SYE')+"CNH"+(DTOS(dDataBase))) ).AND. Val(cVenda) <> 0
			Reclock("SYE",.F.)
		ELSE
			Reclock("SYE",.T.)
			Replace YE_FILIAL With xFilial("SYE")
			Replace YE_DATA   With dDataBase	
		ENDIF
		Replace YE_MOE_FIN  With "6"		
		Replace YE_MOEDA   With "CNH"
		Replace YE_VLCON_C With Val(cCompra)
		MsUnlock("SYE")
	
	// 7  = DONG VIETNÃ –  (D) OU (?)	- 260 VND
	ELSEIF Subst(cLinha,12,3)=="260" .AND. Val(cVenda) <> 0
		If lAutoDolar
			Conout(DtoC(dDatabase)+" - "+TIME()+" Atualizou SM2 - DONGUE VIETNÃ 	")
		EndIf
		dbSelectArea("SM2")
		IF SM2-> (DbSeek(DTOS(dDataBase)) )
			Reclock("SM2",.F.)
		ELSE
			Reclock("SM2",.T.)
			Replace M2_DATA   With dDataBase
		ENDIF                        			
		Replace M2_MOEDA7 With Val(cCompra)
		Replace M2_INFORM With "S"
		MsUnlock("SM2")

		// Atualiza a tabela SYE do sigaeic
		// Procura pela data, se já existir cria novo registro, senão edita
		dbSelectArea("SYE")
		IF SYE-> (DbSeek (xfilial('SYE')+"VND"+(DTOS(dDataBase))) ).AND. Val(cVenda) <> 0
			Reclock("SYE",.F.)
		ELSE
			Reclock("SYE",.T.)
			Replace YE_FILIAL With xFilial("SYE")
			Replace YE_DATA   With dDataBase	
		ENDIF
		Replace YE_MOE_FIN  With "7"		
		Replace YE_MOEDA   With "VND"
		Replace YE_VLCON_C With Val(cCompra)
		MsUnlock("SYE")

	// 8  = RIAL – (QAR)				- 820 SAR
	ELSEIF Subst(cLinha,12,3)=="820" .AND. Val(cVenda) <> 0
		If lAutoDolar
			Conout(DtoC(dDatabase)+" - "+TIME()+" Atualizou SM2 - RIAL – (QAR)	")
		EndIf
		dbSelectArea("SM2")
		IF SM2-> (DbSeek(DTOS(dDataBase)) )
			Reclock("SM2",.F.)
		ELSE
			Reclock("SM2",.T.)
			Replace M2_DATA   With dDataBase
		ENDIF                        			
		Replace M2_MOEDA8 With Val(cCompra)
		Replace M2_INFORM With "S"
		MsUnlock("SM2")

		// Atualiza a tabela SYE do sigaeic
		// Procura pela data, se já existir cria novo registro, senão edita
		dbSelectArea("SYE")
		IF SYE-> (DbSeek (xfilial('SYE')+"SAR"+(DTOS(dDataBase))) ).AND. Val(cVenda) <> 0
			Reclock("SYE",.F.)
		ELSE
			Reclock("SYE",.T.)
			Replace YE_FILIAL With xFilial("SYE")
			Replace YE_DATA   With dDataBase	
		ENDIF
		Replace YE_MOE_FIN  With "8"		
		Replace YE_MOEDA   With "SAR"
		Replace YE_VLCON_C With Val(cCompra)
		MsUnlock("SYE")
	
	// 9  = RUBLO RUSSO – (RUB)			- 830 RUB
	ELSEIF Subst(cLinha,12,3)=="830" .AND. Val(cVenda) <> 0
		If lAutoDolar
			Conout(DtoC(dDatabase)+" - "+TIME()+" Atualizou SM2 - RUBLO RUSSO – (RUB)	")
		EndIf
		dbSelectArea("SM2")
		IF SM2-> (DbSeek(DTOS(dDataBase)) )
			Reclock("SM2",.F.)
		ELSE
			Reclock("SM2",.T.)
			Replace M2_DATA   With dDataBase
		ENDIF                        			
		Replace M2_MOEDA9 With Val(cCompra)
		Replace M2_INFORM With "S"
		MsUnlock("SM2")

		// Atualiza a tabela SYE do sigaeic
		// Procura pela data, se já existir cria novo registro, senão edita
		dbSelectArea("SYE")
		IF SYE-> (DbSeek (xfilial('SYE')+"RUB"+(DTOS(dDataBase))) ).AND. Val(cVenda) <> 0
			Reclock("SYE",.F.)
		ELSE
			Reclock("SYE",.T.)
			Replace YE_FILIAL With xFilial("SYE")
			Replace YE_DATA   With dDataBase	
		ENDIF
		Replace YE_MOE_FIN  With "9"		
		Replace YE_MOEDA   With "RUB"
		Replace YE_VLCON_C With Val(cCompra)
		MsUnlock("SYE")
	
	// 10 = PESO MEXICANO – (Mex$)		- 741 MXN 
	ELSEIF Subst(cLinha,12,3)=="741" .AND. Val(cVenda) <> 0
		If lAutoDolar
			Conout(DtoC(dDatabase)+" - "+TIME()+" Atualizou SM2 - PESO MEXICANO 	")
		EndIf
		dbSelectArea("SM2")
		IF SM2-> (DbSeek(DTOS(dDataBase)) )
			Reclock("SM2",.F.)
		ELSE
			Reclock("SM2",.T.)
			Replace M2_DATA   With dDataBase
		ENDIF                        			
		Replace M2_MOEDA10 With Val(cCompra)
		Replace M2_INFORM With "S"
		MsUnlock("SM2")

		// Atualiza a tabela SYE do sigaeic
		// Procura pela data, se já existir cria novo registro, senão edita
		dbSelectArea("SYE")
		IF SYE-> (DbSeek (xfilial('SYE')+"MXN"+(DTOS(dDataBase))) ).AND. Val(cVenda) <> 0
			Reclock("SYE",.F.)
		ELSE
			Reclock("SYE",.T.)
			Replace YE_FILIAL With xFilial("SYE")
			Replace YE_DATA   With dDataBase	
		ENDIF
		Replace YE_MOE_FIN  With "10"		
		Replace YE_MOEDA   With "MXN"
		Replace YE_VLCON_C With Val(cCompra)
		MsUnlock("SYE")

	ENDIF				
NEXT

If lAutoDolar
	RpcClearEnv()
	Conout(DtoC(dDatabase)+" - "+TIME()+" FIM do JOB Atualizacao de Moedas")
Else
	// Caso não seja job, informa na a atualização
	
	Alert ("Atualização de moedas efetuada com sucesso!")
Endif

Return
