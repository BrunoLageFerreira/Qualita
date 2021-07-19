#include 'TopConn.CH'
#include 'RWMAKE.CH'
#include 'TbiConn.CH'
#INCLUDE "PROTHEUS.CH"      

/*                                          
Programa ...: MPFEST.Prw
Uso ........: Programa para zerar a quantidade nao invetariada no dia da database
Data .......: 22/11/18
Feito por ..: Bruno Lage Ferreira.
*/

User Function MPFEST()
***********************************************************************************************************
*  
*
*** 
// Variaveis Locais da Funcao
Private cEdit1	 := GetMv("MV_DBLQMOV")
Private cEdit2	 := Space(25)
Private oEdit1
Private oEdit2

// Variaveis Private da Funcao
Private _oDlg				// Dialog Principal

// Verifica se o usuário é o Administrador do sistema ou usuários autorizados. 
/*
If !Alltrim(__cUserID) $ GetMv("MV_USERLIB") 
     Alert("Somente o Administrador ou usuários autorizados podem executar esta rotina.") 
     Return 
EndIf  
*/


DEFINE MSDIALOG _oDlg TITLE "Auxiliar de fechamento de estoque" FROM u_MGETTELA(306),u_MGETTELA(471) TO u_MGETTELA(483),u_MGETTELA(687) PIXEL

	@ u_MGETTELA(003),u_MGETTELA(002) TO u_MGETTELA(036),u_MGETTELA(105) LABEL "Data do último movimento:" PIXEL OF _oDlg
		@ u_MGETTELA(016),u_MGETTELA(061) Button "Salvar" Size u_MGETTELA(037),u_MGETTELA(012) ACTION(PutMv("MV_DBLQMOV",cEdit1),Alert("Salvo com Sucesso!"))  PIXEL OF _oDlg
		@ u_MGETTELA(019),u_MGETTELA(005) MsGet oEdit1 Var cEdit1 Size u_MGETTELA(047),u_MGETTELA(009) COLOR CLR_BLACK PIXEL OF _oDlg
	
	@ u_MGETTELA(045),u_MGETTELA(002) TO u_MGETTELA(083),u_MGETTELA(104) LABEL "Diferença de fechamento: " PIXEL OF _oDlg
		//@ u_MGETTELA(061),u_MGETTELA(008) Say "Almoxarificado:" Size u_MGETTELA(037),u_MGETTELA(008) COLOR CLR_BLACK PIXEL OF _oDlg
		//@ u_MGETTELA(071),u_MGETTELA(009) MsGet oEdit2 Var cEdit2 Size u_MGETTELA(028),u_MGETTELA(009) COLOR CLR_BLACK PIXEL OF _oDlg
		@ u_MGETTELA(067),u_MGETTELA(061) Button "Rel. Diferenças"  Size u_MGETTELA(037),u_MGETTELA(012) ACTION(U_relinweb("RQ0077")) PIXEL OF _oDlg

		//@ u_MGETTELA(075),u_MGETTELA(061) Button "Exec ZERA" Size u_MGETTELA(037),u_MGETTELA(012) ACTION(U_MZeraSB7()) PIXEL OF _oDlg

ACTIVATE MSDIALOG _oDlg CENTERED 

Return(.T.)

User function ZERAQTD()
***********************************************************************************************************
*  
*
***  

Private aPerg := {}
Private cPerg := "MPFESTINV0"
                  
Aadd(aPerg,{cPerg,"Data               ?","D",08,00,"G","","","","","","","",""})  
Aadd(aPerg,{cPerg,"Documento          ?","C",09,00,"G","","","","","","","",""})
Aadd(aPerg,{cPerg,"Local              ?","C",02,00,"G","","","","","","","",""})
Aadd(aPerg,{cPerg,"Deletar Inv. Zerado?","N",01,00,"C","","","Sim","Nao","","","",""})

/*
Aadd(aPerg,{cPerg,"Ate a Data        ?","D",08,00,"G","naovazio",""   ,"","","","","",""})
Aadd(aPerg,{cPerg,"Filtro            ?","N",01,00,"C","","","Resolvidos","Nao Resolvidos","Ambos","","",""})
Aadd(aPerg,{cPerg,"Do Grupo          ?","C",04,00,"G","","SBM","","","","","",""})
Aadd(aPerg,{cPerg,"Ate o Grupo       ?","C",04,00,"G","","SBM","","","","","",""})
Aadd(aPerg,{cPerg,"Produto Atacadista?","N",01,00,"C","","","Sim","Nao","Ambos","","",""})
//Aadd(aPerg,{cPerg,"Armazém            ?","C",02,0,"G","","",""    ,""      ,"","","",""})
//ExecBlock("TestaSX1",.F.,.F.,{cPerg,aPerg})
*/

U_Testasx1(cPerg,aPerg,.T.) 

If ! Pergunte(cPerg,.T.)
	Return
EndIf

/*
Se for para deletar os arquivos zerados
*/
If mv_par04 = 1
	If MsgBox("Deseja apagar o inventário com quantidade zerada?","Atenção","YESNO")
		  cSqlDel := ""
		  cSqlDel += " DELETE
		  cSqlDel += "   FROM " + RetSqlName("SB7") 
 		  cSqlDel += " WHERE B7_DATA = '"+DTOS(mv_par01)+"'" 
 		  cSqlDel += " AND B7_FILIAL = '"+xFilial('SB7')+"' "
   		  cSqlDel += " AND B7_DOC = '"+mv_par02+"'"
   		  cSqlDel += " AND B7_QUANT = 0
   		  cSqlDel += " AND B7_LOCAL = '"+mv_par03+"'"
		  
		  TCSqlExec(cSqlDel)
	EndIf
	
	Alert("Registros apagados com sucesso!")
	
	Return()             
EndIf

If MsgBox("Deseja imprimir o relatório de verificação auxiliar?","Atenção","YESNO")
	  RelZeraX()
EndIf


If MsgBox("Este programa inventaria com quantidade 0 produtos que não foram "+CHR(13)+;
             "inventariados.ATENÇÃO o parametro [Data], deverá ser a data em"+CHR(13)+"que foi realizada a contagem","Atenção","YESNO")
	  Processa( {|| u_MZeraSB7()} )
EndIf

return() 

Static function RelZeraX()
***********************************************************************************************************
*  
*
***
/*
TABELA DE DADOS PRINCIPAIS
*/
If SubString(CNUMEMP,1,2) == "05"
	cTabela   := "TB_RIM0022"
ELSE
	cTabela   := "TB_RQ0022"
EndIf

If TcCanOpen(cTabela)  
   lOk := TcDelFile(cTabela)   
Else  
	MsgInfo("Talbela "+cTabela+" nao encontrada.")
Endif	 

cQuery := " SELECT B1_DESC,TB_TEMP.* INTO "+cTabela+" FROM (
cQuery += " 	SELECT  B2_COD,B2_FILIAL,B2_LOCAL,B7_DOC,B7_QUANT,CAST(B7_DATA AS DATE)B7_DATA 
cQuery += " 	FROM   " + RetSqlName("SB7") + " SB7 INNER JOIN " + RetSqlName("SB2") + " SB2 
cQuery += " 		   ON (B7_COD = B2_COD AND B7_FILIAL = B2_FILIAL AND B7_LOCAL = B2_LOCAL) 
cQuery += " 	AND SB2.D_E_L_E_T_ <> '*' 
cQuery += " 	AND SB7.D_E_L_E_T_ <> '*' 
cQuery += "     AND B2_LOCAL = '"+mv_par03+"'
cQuery += "     AND B7_DATA = '"+DTOS(mv_par01)+"' "
cQuery += "     AND B7_FILIAL = '"+xFilial('SB7')+"' "
cQuery += " 				)TB_TEMP INNER JOIN " + RetSqlName("SB1") + "  ON (B1_COD = B2_COD)
cQuery += " WHERE D_E_L_E_T_ = ''
cQuery += " ORDER BY B2_COD DESC

TcSQLExec(cQuery)	

/*
TABELA DE DIFERENCAS 
*/
If SubString(CNUMEMP,1,2) == "05"
	cTabela   := "TB_RIM0022E"
ELSE
	cTabela   := "TB_RQ0022E"
EndIf


If TcCanOpen(cTabela)  
   lOk := TcDelFile(cTabela)   
Else  
	MsgInfo("Talbela "+cTabela+" nao encontrada.")
Endif	

cQuery := " SELECT B2_FILIAL,B2_COD,B1_DESC,B2_LOCAL,B2_QATU
cQuery += "   INTO " + cTabela
cQuery += "   FROM " + RetSqlName("SB2") + " SB2 INNER JOIN " + RetSqlName("SB1") + "  SB1 ON (B1_COD = B2_COD)
cQuery += "  WHERE SB2.D_E_L_E_T_ = '' 
/*
If SubString(CNUMEMP,1,2) == "01"
	cQuery += "  AND B1_COD NOT IN (
	cQuery += "  				'33070002',
	cQuery += "  				'33070015',
	cQuery += "  				'33070036',
	cQuery += "  				'33070020',
	cQuery += "  				'33070001',
	cQuery += "  				'33060205',
	cQuery += "  				'33060127',
	cQuery += "  				'33060209',
	cQuery += "  				'33060210',
	cQuery += "  				'33060207',
	cQuery += "  				'33060208',
	cQuery += "  				'33090001',
	cQuery += "  				'33060101',
	cQuery += "  				'33060171',
	cQuery += "  				'33000175',
	cQuery += "  				'33000061',
	cQuery += "  				'33000063',
	cQuery += "  				'33000062',
	cQuery += "  				'11020002',
	cQuery += "  				'11020003',
	cQuery += "  				'11020020',
	cQuery += "  				'11030001',
	cQuery += "  				'11030003',
	cQuery += "  				'11030026',
	cQuery += "  				'33060196',
	cQuery += "  				'33060055'
	cQuery += "  			  )
EndIf
*/
cQuery += "    AND NOT EXISTS(
cQuery += " 				SELECT  B2_FILIAL,B2_COD,B2_LOCAL from "+ iif(SubString(CNUMEMP,1,2) == "05","TB_RIM0022","TB_RQ0022")  +" E WHERE E.B2_FILIAL = SB2.B2_FILIAL AND E.B2_COD = SB2.B2_COD AND E.B2_LOCAL = SB2.B2_LOCAL				
cQuery += " 				)
cQuery += "    AND B2_FILIAL = '"+xFilial('SB7')+"' "
cQuery += "    AND B2_LOCAL = '"+mv_par03+"'
cQuery += "    AND B2_QATU <> 0
cQuery += "    AND B1_RASTRO <> 'L'
cQuery += " ORDER BY B2_COD,B2_LOCAL

TcSQLExec(cQuery)

If SubString(CNUMEMP,1,2) == "05"
	u_RelInWeb("RIM0022")
Else
	u_RelInWeb("RQ0022")
EndIf

RETURN()

User function MZeraSB7()
***********************************************************************************************************
*  
*
***
Local cQuery := ""

/*
cQuery := "SELECT DISTINCT  SB1.B1_COD,SB1.B1_TIPO, ISNULL(SB7.B7_COD,'NNNNNN') AS B7_COD " 
cQuery += "FROM   " + RetSqlName("SB7") + " SB7 RIGHT JOIN "+RetSqlName("SB1")+" SB1 " 
cQuery += "       ON B7_COD = B1_COD "
cQuery += "AND SB1.D_E_L_E_T_ <> '*' " 
cQuery += "AND SB7.D_E_L_E_T_ <> '*' "
cQuery += "AND B7_DATA = '"+DTOS(mv_par01)+"' "
cQuery += "AND B7_FILIAL = '"+xFilial('SB7')+"' "
cQuery += "ORDER BY B7_COD DESC "
*/

If SubString(CNUMEMP,1,2) == "05"
	cQuery := "SELECT B1_COD,B2_LOCAL,B1_TIPO FROM TB_RIM0022E INNER JOIN "+RetSqlName("SB1")+" SB1 ON (B1_COD = B2_COD) WHERE D_E_L_E_T_ = ''
ELSE
	cQuery := "SELECT B1_COD,B2_LOCAL,B1_TIPO FROM TB_RQ0022E INNER JOIN "+RetSqlName("SB1")+" SB1 ON (B1_COD = B2_COD) WHERE D_E_L_E_T_ = ''
EndIf

tcQuery cQuery alias TRB new
//alert (cQuery)
dbSelectArea("TRB")
dbgotop()
c := 0
//alert(mv_par01 + 15)
do while !EOF() 
    c:=c+1 
    //alert(TRB->B1_COD+" "+TRB->B1_DESC+" "+TRB->B1_TIPO+" "+TRB->B7_COD)
    IncProc(Alltrim(TRB->B1_COD)+"- DOC:"+mv_par02+"...")
  	
  	RecLock("SB7",.t.)
		SB7->B7_FILIAL  := xFilial("SB7")
		SB7->B7_COD     := TRB->B1_COD
		SB7->B7_LOCAL   := TRB->B2_LOCAL
		SB7->B7_QUANT   := 0
		SB7->B7_DATA    := ctoD("18/01/2021")
		SB7->B7_DOC     := "20210117D" 
		SB7->B7_TIPO    := TRB->B1_TIPO
		SB7->B7_DTVALID := ctoD("18/01/2021")+365 // ddatabase
		SB7->B7_STATUS  := "1"
		SB7->B7_ORIGEM  := "ZERAX"
	MsUnLock()
	
	dbSelectArea("TRB")
	dbSkip()
enddo
dbSelectArea("TRB") 
dbCloseArea()
 
Alert("Total de registros incluídos! " + STR(c) + ".")

Return()
