#include "protheus.ch"
#include "rwmake.ch"
#include "tbiconn.ch"  
#INCLUDE "TOTVS.CH"

/*
Programa ...: Dolar.Prw
Uso ........: Atualiza��o do sistema de moedas automaticamente
Data .......: 18/04/2002
Feito por ..: Bruno Lage Ferreira
Copyright @1998-2001,2019


SELECT M2_MOEDA2 D_USD_COMPRA,YE_VLCON_C D_USD_VENDA 
 FROM SYE050 SYE INNER JOIN SM2050 SM2 ON (M2_DATA = YE_DATA)
WHERE SYE.D_E_L_E_T_ = '' 
  AND SM2.D_E_L_E_T_ = ''
  AND YE_MOEDA = 'USD' 
  AND YE_DATA ='20191024'
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
If Select("SX2")==0 // Testa se est� sendo rodado do menu 
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

fDolar(CtoD("11/02/21"))
fDolar(dDataRef)

Return


Static Function fDolar(dDataRef)
************************************************************************************************************
*
*
*
**************
 
DO CASE
	CASE Dow(dDataRef) == 1    // Se for domingo
		cFile := DTOS(dDataRef - 2)+".csv" 
		_pula := 2
	CASE Dow(dDataRef) == 7            // Se for s�bado
		cFile := DTOS(dDataRef - 1)+".csv"
		_pula := 1
	CASE Dow(dDataRef) == 2            // Se for segunda
		cFile := DTOS(dDataRef - 3)+".csv"
		_pula := 3
	OTHERWISE                          // Se for dia normal
		cFile := DTOS(dDataRef - 1)+".csv"
		_pula := 0 
ENDCASE 
	
// Pega o dia anterior, mas se este dia anterior n�o tiver o arquivo vai at� 7 dias antes
datai:=ddataref

While .T.
    
	cTexto  :=  HTTPGET('https://www4.bcb.gov.br/download/fechamento/'+cFile)  	//cTexto  :=  HTTPGET('http://www5.bcb.gov.br/download/'+cFile)	
	
	ConOut(">>>> Atualizando Moeda pelo Site do Banco Central...")
	ConOut('>>>> https://www4.bcb.gov.br/download/fechamento/'+cFile)
	
	
	
	cLinha := Memoline(cTexto,81,j)
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

// Nao faz pois n�o acha arquivo no site do Banco Central
If ddatabase - datai > 7 .and. lAutoDolar
	If lAutoDolar
		Qout("N�o encontrado arquivo no Site do Banco Central: "+cFile)
	ELSE
		// Caso n�o seja job, informa na a atualiza��o
		Apmsginfo("N�o encontrado arquivo no Site do Banco Central: "+cFile)
	Endif
	Return
Endif

cQuery := "SELECT TOP 1 M2_MOEDA4 FROM " + RetSQLName("SM2") + " WHERE M2_DATA<='"+DToS(dDataRef)+"' AND M2_MOEDA3>0 ORDER BY M2_DATA DESC "
dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "TRB", .F., .T.)
dbSelectArea("TRB")
dbGoTop()
_vlufir := IIF(!eof(),m2_moeda4,0)
dbCloseArea()    
    
DbSelectArea("SM2")
DbSetOrder(1)       
DbGotop()
		
DbSelectArea("SYE")
DbSetOrder(2) //ye_filial, ye_moeda, ye_data, r_e_c_n_o_, d_e_l_e_t_
DbGotop()


//  Conta o n�mero de linhas do arquivo baixado (linhas com 81 caracteres)
nLinhas := MLCount(cTexto, 81)  

If lAutoDolar
	//Conout(DtoC(dDatabase)+" - "+TIME()+" "+cTexto)
EndIf
  

For j := 1 to nLinhas     
	// Extrai a linha atual do arquivo e joga na vari�vel

	cLinha  := Memoline(cTexto,81,j)

    
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
	   
	// Se a moeda for Dolar Americano...

	IF Subst(cLinha,12,3)=="220" .AND. Val(cVenda) <> 0
/*
If cData == "18/09/2015"
	xxx:=0   
	(alert(nlinhas))
	alert(cData)
	alert(dData) 
	alert(   cVenda )
	alert(val(cVenda))
EndIf
*/  
                                                      
		If lAutoDolar
			Conout(DtoC(dDatabase)+" - "+TIME()+" Atualizou SM2 - DOLAR")
		EndIf
		// Procura pela data, se j� existir cria novo registro, sen�o edita
		dbSelectArea("SM2")
		IF SM2->( DbSeek(DTOS(dDataBase)) )
			Reclock("SM2",.F.)
			
		ELSE
			Reclock("SM2",.T.)
			Replace M2_DATA   With dDataBase //dData
			//Replace M2_FILIAL With xFilial("SM2")
			
		
		ENDIF
		/*
		Se For Qualit�
		*/
		If SubString(CNUMEMP,1,2) == "01"
			Replace M2_MOEDA2  With Val(cCompra)
		Else
			Replace M2_MOEDA2  With Val(cVenda)
		EndIf
	
		Replace M2_INFORM  With "S"
		Replace M2_MOEDA4  With _vlufir
		//Replace M2_MOEDA3  With 1.23456
		MsUnlock("SM2")            

		// Atualiza a tabela SYE do sigaeic

		DbSelectArea("SYE")

		// Procura pela data, se j� existir cria novo registro, sen�o edita
		IF SYE-> (DbSeek (xfilial('SYE')+"USD"+(DTOS(dDataBase))) ) .AND. Val(cVenda) <> 0
			Reclock("SYE",.F.)
		ELSE
			Reclock("SYE",.T.)
			Replace YE_DATA   With dDataBase           	
		ENDIF
				
		Replace YE_MOEDA   With "USD"
		Replace YE_VLCON_C With Val(cCompra)
		MsUnlock("SYE")  	   

		// Se a moeda for EURO...	
	ELSEIF Subst(cLinha,12,3)=="978" .AND. Val(cVenda) <> 0
		If lAutoDolar
			Conout(DtoC(dDatabase)+" - "+TIME()+" Atualizou SM2 - EURO")
		EndIf
		dbSelectArea("SM2")
		IF SM2-> (DbSeek(DTOS(dDataBase)) )
			Reclock("SM2",.F.)
		ELSE
			Reclock("SM2",.T.)
			//Replace M2_FILIAL With xFilial("SM2")
			Replace M2_DATA   With dDataBase
		ENDIF                        
		Replace M2_MOEDA4 With _vlufir			
		Replace M2_MOEDA3 With Val(cCompra)
		Replace M2_INFORM With "S"
		MsUnlock("SM2")

		// Atualiza a tabela SYE do sigaeic

		// Procura pela data, se j� existir cria novo registro, sen�o edita
		dbSelectArea("SYE")
		IF SYE-> (DbSeek (xfilial('SYE')+"EUR"+(DTOS(dDataBase))) ).AND. Val(cVenda) <> 0
			Reclock("SYE",.F.)
		ELSE
			Reclock("SYE",.T.)
			Replace YE_FILIAL With xFilial("SYE")
			Replace YE_DATA   With dDataBase	
		ENDIF
				
		Replace YE_MOEDA   With "EUR"
		Replace YE_VLCON_C With Val(cCompra)
		MsUnlock("SYE")
	ENDIF				
NEXT

If lAutoDolar
	RpcClearEnv()
	Conout(DtoC(dDatabase)+" - "+TIME()+" FIM do JOB Atualizacao de Moedas")
Else
	// Caso n�o seja job, informa na a atualiza��o
	
	Alert ("Atualiza��o de moedas efetuada com sucesso!")
Endif

Return
