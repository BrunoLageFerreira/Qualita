#INCLUDE "TopConn.CH"
#INCLUDE "RWMAKE.CH"
#INCLUDE "PROTHEUS.CH"   
#INCLUDE "TBICONN.CH"

/*                                          
Programa ...: F580CHAV.Prw
Uso ........: Ponto de Entrada (ORDENAÇÃO TELA DE LIBERAÇÃO)
Data .......: 30/05/23
Feito por ..: Bruno Lage Ferreira.
*/


User Function F580CHAV()
*************************************************************************************************************
*
*
*** 
Local  cChave		:= "E2_FILIAL+E2_NUM+E2_PARCELA+E2_TIPO"

Return(cChave)

/*
User Function F580FAUT()
*************************************************************************************************************
*
*
*** 
Local cQueF580 := ""
Local cFilter1 := PARAMIXB[1]

//Alert(cQuery)

cTabela   := "TB_F580DB"

If TcCanOpen(cTabela)  
   lOk := TcDelFile(cTabela)   
Else  
	MsgInfo("Talbela "+cTabela+" nao encontrada.")
Endif

cQueF580  := REPLACE(cQuery,' FROM SE2010 SE2 ',' INTO TB_F580DB FROM SE2010 SE2 ')
cQueF580  := cQueF580 + ' WHERE ' + PARAMIXB[1]

TcSQLExec(cQueF580)

Return(cFilter1)
*/
