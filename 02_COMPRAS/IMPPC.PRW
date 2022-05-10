#INCLUDE "TopConn.CH"
#INCLUDE "RWMAKE.CH"
#INCLUDE "PROTHEUS.CH"   
#INCLUDE "TBICONN.CH"


/*
+----------+-----------+----------+-------------------------+------+-----------+
|Programa  | ImpPc     | Autor    | BRUNO LAGE FERREIRA     |Data  |11.02.2020 |
+----------+-----------+----------+-------------------------+------+-----------+
|Descricao | Impressão de Relatorio Pedido de Compras                          |
+----------+-------------------------------------------------------------------+
| USO      | Compras				                     					   |
+----------+-------------------------------------------------------------------+
|           ALTERACOES FEITAS DESDE A CRIACAO                                  |
+----------+-----------+-------------------------------------------------------+
|Autor     | Data      | Descricao                                             |
+----------+-----------+-------------------------------------------------------+
|          |           |                                                       |
+----------+-----------+-------------------------------------------------------+
Q-Liberação Faturamento
5527995295180-1587589430@g.us

Q-N2 - Liberação Compras
5527995295180-1594316108@g.us

Q-N1 - Liberação Compras
5527995295180-1587589523@g.us
*/

User Function MT121BRW()
/**********************************************************************************
* Adição do novo menu personalizado para impressao do pedido de compras.
*
****/
Local aSubMnu := {}

	AAdd(aSubMnu,	{ "Nível 01" , "U_fPCWAAPP('1')", 0 , 6, 0, nil})  	    
	AAdd(aSubMnu,	{ "Nível 02" , "U_fPCWAAPP('2')", 0 , 6, 0, nil})  		

	aAdd(aRotina,{"(NEW) Ped.Compra","u_ImpPc(1)" , 0, 2, 0, Nil }) //"New Ped. Compra"

	/*
	Somente para Qualitá
	*/
	If SubString(CNUMEMP,1,2) == "01"
		AAdd(aRotina,{ "Enviar Ped.Compra WhatsApp" , aSubMnu, 0 , 6, 0, nil})  		   										//"pedido de compra
	EndIf

Return 


User Function fPCWAAPP(cOpcao)
****************************************************************************************************************
*    
*
****

/*
Atualiza os dados do relatorio mantendo 
sempre o atual. O tempo de execução este caso nao necessita abrir o relatorio na tela
*/
u_ImpPc(2)

WaitRunSrv( '"D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\wget\wget.exe" -t 1 "http://192.168.1.101:10530/ReportServer/Pages/ReportViewer.aspx?%2fItinga_reports%2fRXX0022&rs:Format=pdf" -O "D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\RXX0022.PDF"' , .t. , "D:\TOTVS 12\Microsiga\protheus_data\RELINWEB\wget\" )
																				
//Grupo de Faturamento Whatsapp
//{"root":[{"id":"5527995295180-1587589523@g.us","descricao":"Q-Liberação Compras"},{"id":"5527995295180-1587589430@g.us","descricao":"Q-Liberação Faturamento"}]}


/*
Oficial
*/
//cProt := U_SWENARWAP("5551997331669",  "Aprovação Ped. de Compras:" +AllTrim(SC7->C7_NUM) + " Usuário:" + SUBSTR(CUSUARIO,7,15)  ,"PC:" +AllTrim(SC7->C7_NUM) ,"RXX0022"           ,"PDF","\RELINWEB\RXX0022.pdf")

/*
Teste
*/
   
If cOpcao == "1" 
	cProt := U_SWENARWAP("5527995295180-1587589523@g.us", "(Nível 1) Aprovação Ped. de Compras:" +AllTrim(SC7->C7_NUM) + " Usuário:" + SUBSTR(CUSUARIO,7,15)     ,"PC:" +AllTrim(SC7->C7_NUM)   ,"RXX0022"           ,"PDF","\RELINWEB\RXX0022.pdf")                     
Else
	cProt := U_SWENARWAP("5527995295180-1594316108@g.us", "(Nível 2) Aprovação sem o nível 1.  Aprovação Ped. de Compras:" +AllTrim(SC7->C7_NUM) + " Usuário:" + SUBSTR(CUSUARIO,7,15)     ,"PC:" +AllTrim(SC7->C7_NUM)   ,"RXX0022"           ,"PDF","\RELINWEB\RXX0022.pdf")
EndIf
        
                  
IF cProt = "" .or. cProt = nil 
	Alert("ERRO!!! O WhatsApp pode estar passando por alguma instabilidade no momento. Aguarde alguns instantes de tente novamente mais tarde!")
	Return()
EndIf                 
                      
If  RecLock("WAM",.T.) 

	Replace WAM_FILIAL  With "" 
	Replace WAM_DATA    With Date()
	Replace WAM_HORA    With Time()
	Replace WAM_ID      With cProt
	Replace WAM_MSG     With "Aprovação Pedido de Compras:" +AllTrim(SC7->C7_NUM) + "Usuário:" + SUBSTR(CUSUARIO,7,15) + " Fornecedor:" + AllTrim(SC7->C7_NOMEFOR)
	//Replace WAM_TELL    With "5551997331669"
	//Replace WAM_TELL    With "5533984022125"
	Replace WAM_INDEX   With SC7->C7_FILIAL + SC7->C7_NUM
	Replace WAM_PERG    With "S"
	Replace WAM_NIVEL   With cOpcao
	//Replace WAM_DATAR   With ""
	//Replace WAM_HORAR   With ""
	//Replace WAM_RESPOSV With ""
	
	IF SubString(CNUMEMP,1,2) == "05"
		Replace WAM_EXEC    With 'ITINGA-PC'
	Else
		Replace WAM_EXEC    With 'QUALITA-PC'
	EndIf
	
   MsUnLock()
EndIf


/*
UPDATE NA SC8 ENVIANDO PARA APROVAÇÃO NO WHATSAPP
*/
cQuery := " UPDATE " + RetSqlName("SC7")  
cQuery += "    SET C7_LIBZAP = 'S'
cQuery += "  FROM " + RetSqlName("SC7")
cQuery += "  WHERE D_E_L_E_T_ <> '*'
cQuery += "    AND C7_NUM = '"+SC7->C7_NUM+"'
			
TcSQLExec(cQuery)

Alert("WhatsApp enviado com sucesso! " + cProt)

Return()

User Function ImpPc(nTipo)
/******************************************************************************************************************************************************************
* criação da tab temp do pedido de venda
*
****/

Local cQuery    := ""
Local cAprov    := ""

	
**************************
**************************
***     BRUNO LAGE    ****
**************************
**************************    

cTabela   := "TB_RXX22"

If TcCanOpen(cTabela)  
   lOk := TcDelFile(cTabela)   
Else  
	MsgInfo("Talbela "+cTabela+" nao encontrada.")
Endif

cQuery := "SELECT CR_APROV FROM " +RetSQLName("SCR")+" WHERE D_E_L_E_T_ = '' AND CR_NUM = '"+ AllTrim(SC7->C7_NUM) +"' AND CR_FILIAL = '"+ AllTrim(SC7->C7_FILIAL) +"'"

TcQuery cQuery Alias TMPAPRO New
		
dbSelectArea("TMPAPRO")     
dbGoTop()
	
cAprov := UPPER(UsrFullName(  TMPAPRO->CR_APROV  ))

dbSelectArea("TMPAPRO")
dbCloseArea()

/*
Aprovação via WhatsApp
*/
If cAprov == "" .And. SubString(CNUMEMP,1,2) == "01"
	
	cQuery := " SELECT * 
	cQuery += "  FROM WAM010
	cQuery += "  WHERE D_E_L_E_T_ = ''
	cQuery += "    AND WAM_EXEC = 'QUALITA-PC'
	cQuery += "	AND WAM_PERG = 'N'
	cQuery += "	AND WAM_DATAR <>''
	cQuery += "    AND WAM_INDEX = '" + AllTrim(SC7->C7_FILIAL)+AllTrim(SC7->C7_NUM) +"'"
	
	TcQuery cQuery Alias TMPAPRO New
	
	dbSelectArea("TMPAPRO")     
	dbGoTop()
	If !EOF()	
		cAprov := "LIBERADO VIA WHATSAPP"
	EndIf
	
	dbSelectArea("TMPAPRO")
	dbCloseArea()
	
EndIf

  	 
cQuery := " SELECT 	
cQuery += " 		'" + UPPER(ALLTRIM(SM0->M0_NOMECOM)) + "' AS EMPRESA,
cQuery += " 		'" + UPPER(ALLTRIM(SM0->M0_CGC))     + "' AS CPNJ,
cQuery += " 		'" + UPPER(ALLTRIM(SM0->M0_TEL))     + "' AS TEL,
cQuery += " 		'" + UPPER(ALLTRIM(SM0->M0_ENDCOB))  + "' AS ENDEREC,
cQuery += " 		'" + UPPER(ALLTRIM(SM0->M0_ESTCOB))  + "' AS ESTADO,
cQuery += " 		'" + UPPER(ALLTRIM(SM0->M0_CIDCOB))  + "' AS CIDADE,
cQuery += " 		'" + UPPER(ALLTRIM(SM0->M0_CEPCOB))  + "' AS CEP_COB,

cQuery += " 		'" + UPPER(ALLTRIM(SM0->M0_ENDENT))  + "' AS ENDEREC_ENT,
cQuery += " 		'" + UPPER(ALLTRIM(SM0->M0_ESTENT))  + "' AS ESTADO_ENT,
cQuery += " 		'" + UPPER(ALLTRIM(SM0->M0_CIDENT))  + "' AS CIDADE_ENT,
cQuery += " 		'" + UPPER(ALLTRIM(SM0->M0_CEPENT))  + "' AS CEP_ENT,

cQuery += " 		'" + UPPER(UsrFullName(SC7->C7_USER)) + "' AS COMPRADOR,

If SubString(CNUMEMP,1,2) == "01"
	cQuery += "			'" + "Diego Sirtori" +"' APROVADOR,
Else
	cQuery += "			'" + IIF(EMPTY(cAprov),UPPER("Airton Novais dos Santos"),cAprov) +"' APROVADOR,
EndIf

cQuery += "  		C7_NUMSC  SOLICITACAO,
cQuery += "			C7_ITEMSC ITEM_SOLICITACAO,

cQuery += "         '" + SubString(CNUMEMP,1,2) + "' AS ID_EMPRESA,"

If SubString(CNUMEMP,1,2) == "01"
	cQuery += "			(	
	cQuery += "			CASE
	cQuery += "							WHEN (SELECT C1_XTIPO FROM " +RetSQLName("SC1")+ " WHERE D_E_L_E_T_ = '' AND C1_FILIAL = C7_FILIAL AND C1_NUM = C7_NUMSC AND C1_ITEM = C7_ITEMSC) = ''   THEN '-' 
	cQuery += "							WHEN (SELECT C1_XTIPO FROM " +RetSQLName("SC1")+ " WHERE D_E_L_E_T_ = '' AND C1_FILIAL = C7_FILIAL AND C1_NUM = C7_NUMSC AND C1_ITEM = C7_ITEMSC) = '01' THEN '01-MAQUINA PARADA' 
	cQuery += "							WHEN (SELECT C1_XTIPO FROM " +RetSQLName("SC1")+ " WHERE D_E_L_E_T_ = '' AND C1_FILIAL = C7_FILIAL AND C1_NUM = C7_NUMSC AND C1_ITEM = C7_ITEMSC) = '02' THEN '02-REQUER ATENCAO' 
	cQuery += "							WHEN (SELECT C1_XTIPO FROM " +RetSQLName("SC1")+ " WHERE D_E_L_E_T_ = '' AND C1_FILIAL = C7_FILIAL AND C1_NUM = C7_NUMSC AND C1_ITEM = C7_ITEMSC) = '03' THEN '03-COMPRA NORMAL' 
	cQuery += "			END
	cQuery += "			) STATUS  ,
Else
	cQuery += "     '03-COMPRA NORMAL' STATUS  ,
EndIf 

cQuery += "			(SELECT CAST(C1_EMISSAO AS DATE) FROM " +RetSQLName("SC1")+ " WHERE D_E_L_E_T_ = '' AND C1_FILIAL = C7_FILIAL AND C1_NUM = C7_NUMSC AND C1_ITEM = C7_ITEMSC) DT_EMISSAO_SC, 
cQuery += "			(SELECT CAST(C1_DATPRF  AS DATE) FROM " +RetSQLName("SC1")+ " WHERE D_E_L_E_T_ = '' AND C1_FILIAL = C7_FILIAL AND C1_NUM = C7_NUMSC AND C1_ITEM = C7_ITEMSC) DT_NECESSIDADE, 
cQuery += "			C7_NUMCOT COTACAO,
cQuery += "			(SELECT DISTINCT CAST(C8_EMISSAO AS DATE) FROM " +RetSQLName("SC8")+ " WHERE D_E_L_E_T_ = '' AND C8_FILIAL = C7_FILIAL AND C8_NUM = C7_NUMCOT AND C8_ITEM = C7_ITEMSC) DT_COTACAO, 
cQuery += "			C7_NUM PEDIDO,
cQuery += "			CAST(C7_EMISSAO AS DATE) DT_PEDIDO,
cQuery += "			C7_ITEM,
cQuery += "			C7_PRODUTO,
cQuery += "			RTRIM(LTRIM(C7_DESCRI)) C7_DESCRI,
cQuery += "			C7_UM,
cQuery += "			C7_QUANT,
cQuery += "			C7_PRECO,
cQuery += "			C7_TOTAL,
cQuery += "			CAST(C7_DATPRF AS DATE)  PREVISAO_ENTREGA,
If SubString(CNUMEMP,1,2) == "01"
	cQuery += "			RTRIM(LTRIM(C7_OBSM)) OBS,
Else
	cQuery += "			RTRIM(LTRIM(ISNULL(CONVERT(VARCHAR(2047), CONVERT(VARBINARY(2047), C7_OBS)),'') )) OBS,
EndIf
cQuery += "			C7_FORNECE,
cQuery += "			SA2.A2_NOME DESCRI_FORN,
cQuery += "			SA2.A2_END ENDERECO,
cQuery += "			SA2.A2_EST UF,
cQuery += "			SA2.A2_MUN MUNICIPIO,
cQuery += "			SA2.A2_BAIRRO BAIRRO,
cQuery += "			A2_CEP CEP,
cQuery += "			SA2.A2_CGC CNPJ,
cQuery += "			SA2.A2_INSCR INSCRICAO,
cQuery += "			(RTRIM(LTRIM(SA2.A2_DDD))+''+RTRIM(LTRIM(SA2.A2_TEL))) TELEFONE,
cQuery += "			C7_VLDESC,
cQuery += "			C7_LOJA,
cQuery += "			C7_CC,
cQuery += "			C7_COND,
cQuery += "			(SELECT RTRIM(LTRIM(E4_DESCRI)) FROM " +RetSQLName("SE4")+ " WHERE D_E_L_E_T_ = '' AND E4_CODIGO =  C7_COND ) E4_DESCRI,
cQuery += "			IIF(C7_MOEDA =1,'REAL',IIF(C7_MOEDA=2,'DOLAR','EURO')) C7_MOEDA,
cQuery += "			C7_VALICM,
cQuery += "			C7_BASEICM,
cQuery += "			C7_ICMSRET,
cQuery += "			C7_VALFRE,
cQuery += "			C7_VALEMB,
cQuery += "			C7_VALIPI,
cQuery += "			C7_DESC1 DESC1,
cQuery += "			C7_DESC2 DESC2,
cQuery += "			C7_DESC3 DESC3,
cQuery += "			C7_FRETE VLRFRETE,
cQuery += "			C7_DESPESA DESPESA,
cQuery += "			C7_SEGURO SEGURO
 
cQuery += " INTO TB_RXX22

cQuery += " FROM " +RetSQLName("SC7")+ " SC7
cQuery += "	  INNER JOIN " +RetSQLName("SA2")+ " SA2 ON
cQuery += "	  ((SA2.A2_COD+SA2.A2_LOJA) = (SC7.C7_FORNECE+SC7.C7_LOJA)) 
cQuery += "	  AND C7_NUM    = '" + AllTrim(SC7->C7_NUM)    + "'
cQuery += "	  AND C7_FILIAL = '" + AllTrim(SC7->C7_FILIAL) + "'
cQuery += "	  AND SC7.D_E_L_E_T_=''
cQuery += "	  AND SA2.D_E_L_E_T_=''
cQuery += " ORDER BY C7_ITEM

TcSQLExec(cQuery)

/*
SHOW DO RELATORIO
*/
If nTipo == 1
	If SubString(CNUMEMP,1,2) == "01"
		u_RelInWeb("RXX0022")
	Else
		u_RelInWeb("RXX0022_I")
	EndIf
EndIf

Return()
