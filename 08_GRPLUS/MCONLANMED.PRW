#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"

/*
Programa ...: MCONLANMED.Prw
Uso ........: TROCA DE FIOS
Data .......: 16/04/2019
Feito por ..: Bruno Lage Ferreira 
*/

User Function MCONLANMED()
****************************************************************************************************************
* /*    Programa inicial da tabela ZT1 */  
*
****

	Local aCores := {{ "Z11->Z11_TIPOLA == 'T'" , "BR_AZUL"        }, ;  // TROCA 
	                 { "Z11->Z11_TIPOLA == 'M'" , "BR_PRETO"  }}    // MEDIÇÃO
	
	Private cCadastro := OemToAnsi("Fio Diamantado")        
	
	/*If U_GrupUser("000012") .Or. U_GrupUser("000000")
		Private aRotina := {{"Pesquisar"            ,"AxPesqui"     ,0,1},;
							{"Visualizar"           ,"AxVisual"     ,0,2},;
							{"Alterar"              ,"u_AVeiculo()" ,0,4},;							
							{"Saída (Check-Out)"    ,"u_MAxCaDAI()" ,0,3},;
							{"Entrada (Check-In)"   ,"u_MAxCaDAI()" ,0,4},;  
							{"Rel. Cont. Veículos"  ,"u_RelInWeb('RLM0007','Controle de Veículos')"     ,0,3},;  
							{"Legenda"              ,"u_MLEGZT1()"  ,0,4}}   
			
	Else
		Private aRotina := {{"Pesquisar"            ,"AxPesqui"     ,0,1},;
							{"Visualizar"           ,"AxVisual"     ,0,2},;
							{"Saída (Check-Out)"    ,"u_MAxCaDAI()" ,0,3},;
							{"Entrada (Check-In)"   ,"u_MAxCaDAI()" ,0,4},;    
							{"Rel. Cont. Veículos"  ,"u_RelInWeb('RLM0007','Controle de Veículos')"     ,0,3},;  
							{"Legenda"              ,"u_MLEGZT1()"  ,0,4}}   
		
	
	EndIf*/


	Private 	aRotina := {{"Pesquisar"            ,"AxPesqui"     ,0,1},;
							{"Visualizar"           ,"AxVisual"     ,0,2},;
							{"Incluir" 			   	,"AxInclui" 	,0,3},;
							{"Alterar"   			,"AxAltera" 	,0,4},;    
							{"Rel. Movimento"       ,"u_RelInWeb('RLM0007','Relatório de Movimentos')"     ,0,3},;  
							{"Legenda"              ,"u_MLEGZ11()"  ,0,3}}   
		
	
						
	Private aCampo :={}
						
	dbSelectArea("Z11")
	dbSetOrder(1)
	
	mBrowse(6,1,22,75,"Z11",,,,,,aCores)
	
Return()  


User Function MLEGZ11()
****************************************************************************************************************
* /*Legendas */  
*
****
	Local aLegenda := {}
	
	Aadd(aLegenda, {"BR_AZUL"   ,"Troca de Fios"      })
	Aadd(aLegenda, {"BR_PRETO"  ,"Medição de Pérolas" })
	
	BrwLegenda(cCadastro, "Legenda", aLegenda)
	              
Return()    