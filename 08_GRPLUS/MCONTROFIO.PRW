#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"

/*
Programa ...: MCONTROFIO.Prw
Uso ........: TROCA DE FIOS
Data .......: 16/04/2019
Feito por ..: Bruno Lage Ferreira 
*/

User Function MCONTROFIO()
****************************************************************************************************************
* /*    Programa inicial da tabela ZT1 */  
*
****
	Local aCores := {{ "ZT1->ZT1_TIPO == 'S'" , "CARGA"                }, ;  // Viagem Aberta
	                 { "ZT1->ZT1_TIPO == 'E'" , "IC_TOOLBARSTATUS_RED" }}    // Viagem Fechada
	
	Private cCadastro := OemToAnsi("Controle de Ve�culos")        
	
	If U_GrupUser("000012") .Or. U_GrupUser("000000")
		Private aRotina := {{"Pesquisar"            ,"AxPesqui"     ,0,1},;
							{"Visualizar"           ,"AxVisual"     ,0,2},;
							{"Alterar"              ,"u_AVeiculo()" ,0,4},;							
							{"Sa�da (Check-Out)"    ,"u_MAxCaDAI()" ,0,3},;
							{"Entrada (Check-In)"   ,"u_MAxCaDAI()" ,0,4},;  
							{"Rel. Cont. Ve�culos"  ,"u_RelInWeb('RLM0007','Controle de Ve�culos')"     ,0,3},;  
							{"Legenda"              ,"u_MLEGZT1()"  ,0,4}}   
			
	Else
		Private aRotina := {{"Pesquisar"            ,"AxPesqui"     ,0,1},;
							{"Visualizar"           ,"AxVisual"     ,0,2},;
							{"Sa�da (Check-Out)"    ,"u_MAxCaDAI()" ,0,3},;
							{"Entrada (Check-In)"   ,"u_MAxCaDAI()" ,0,4},;    
							{"Rel. Cont. Ve�culos"  ,"u_RelInWeb('RLM0007','Controle de Ve�culos')"     ,0,3},;  
							{"Legenda"              ,"u_MLEGZT1()"  ,0,4}}   
		
	
	EndIf

	
						
	Private aCampo :={}
						
	dbSelectArea("ZT1")
	dbSetOrder(1)
	
	mBrowse(6,1,22,75,"ZT1",,,,,,aCores)
	
Return()  