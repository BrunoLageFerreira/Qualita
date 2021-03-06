#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"

/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �REL0036   � Autor � AP6 IDE            � Data �  08/01/13   ���
�������������������������������������������������������������������������͹��
���Descricao � Codigo gerado pelo AP6 IDE.                                ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       � AP6 IDE                                                    ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/

User Function Rel0036()
/*************************************************************************************
*
*
*****/

//���������������������������������������������������������������������Ŀ
//� Declaracao de Variaveis                                             �
//�����������������������������������������������������������������������

Local cDesc1       := "Este programa tem como objetivo imprimir relatorio "
Local cDesc2       := "de acordo com os parametros informados pelo usuario."
Local cDesc3       := "Relat�rio de Contas Pagas"
Local cPict        := ""
Local titulo       := "Relat�rio de Contas Pagas Por Natureza"
Local nLin         := 80

Local Cabec1       := ""
Local Cabec2       := ""
Local imprime      := .T.
Local aOrd := {}
Private lEnd       := .F.
Private lAbortPrint:= .F.
Private CbTxt      := ""
Private limite     := 80
Private tamanho    := "P"
Private nomeprog   := "REL0036" // Coloque aqui o nome do programa para impressao no cabecalho
Private nTipo      := 18
Private aReturn    := { "Zebrado", 1, "Administracao", 2, 2, 1, "", 1}
Private nLastKey   := 0
Private cbtxt      := Space(10)
Private cbcont     := 00
Private CONTFL     := 01
Private m_pag      := 01
Private wnrel      := "REL0036" // Coloque aqui o nome do arquivo usado para impressao em disco
Private cPerg	   := "GPREL0036"

Pergunte(cPerg,.T.)

Private cString    := "QSE2"
Private cQuery	   := "Select * From "+RetSqlName("SE2")
		
		If mv_par04 = 1
			//cQuery	+= " Where E2_BAIXA   >= '"+DToS(mv_par01)+"' And E2_BAIXA   <= '"+DToS(mv_par02)+"' And E2_NATUREZ >= '"+mv_par03+"' And E2_NATUREZ <= '"+mv_par04+"' And D_E_L_E_T_ != '*'"
			cQuery	+= " Where D_E_L_E_T_ = '' AND E2_PREFIXO <> 'AUT' AND  E2_BAIXA   >= '"+DToS(mv_par01)+"' And E2_BAIXA   <= '"+DToS(mv_par02)+"' And E2_NATUREZ IN (SELECT DISTINCT ZGR_NATURE FROM "+ RetSqlName("ZGR") +" WHERE D_E_L_E_T_ = '' AND  ZGR_CODIGO IN('"+mv_par03+"'))
		Else 
			//cQuery	+= " Where E2_EMISSAO >= '"+DToS(mv_par01)+"' And E2_EMISSAO <= '"+DToS(mv_par02)+"' And E2_NATUREZ >= '"+mv_par03+"' And E2_NATUREZ <= '"+mv_par04+"' And D_E_L_E_T_ != '*'"
			cQuery	+= " Where D_E_L_E_T_ = '' AND E2_PREFIXO <> 'AUT' AND  E2_EMISSAO >= '"+DToS(mv_par01)+"' And E2_EMISSAO <= '"+DToS(mv_par02)+"' And E2_NATUREZ IN (SELECT DISTINCT ZGR_NATURE FROM "+ RetSqlName("ZGR") +"  WHERE D_E_L_E_T_ = '' AND  ZGR_CODIGO IN('"+mv_par03+"'))
		EndIf
		
		cQuery	+= " Order By E2_NATUREZ"
		cQuery	:= ChangeQuery(cQuery)
DbUseArea(.T.,"QSE2",TcGenQry(,,cQuery),"QSE2",.T.,.T.)

DbSelectArea("QSE2")


//���������������������������������������������������������������������Ŀ
//� Monta a interface padrao com o usuario...                           �
//�����������������������������������������������������������������������

wnrel := SetPrint(cString,NomeProg,"",@titulo,cDesc1,cDesc2,cDesc3,.F.,,.T.,Tamanho,,.T.)

If nLastKey == 27
	Return
Endif

SetDefault(aReturn,cString)

If nLastKey == 27
	Return
Endif

nTipo := If(aReturn[4]==1,15,18)

//���������������������������������������������������������������������Ŀ
//� Processamento. RPTSTATUS monta janela com a regua de processamento. �
//�����������������������������������������������������������������������

RptStatus({|| RunReport(Cabec1,Cabec2,Titulo,nLin) },Titulo)
Return

/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Fun��o    �RUNREPORT � Autor � AP6 IDE            � Data �  08/01/13   ���
�������������������������������������������������������������������������͹��
���Descri��o � Funcao auxiliar chamada pela RPTSTATUS. A funcao RPTSTATUS ���
���          � monta a janela com a regua de processamento.               ���
�������������������������������������������������������������������������͹��
���Uso       � Programa principal                                         ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/

Static Function RunReport(Cabec1,Cabec2,Titulo,nLin)
/*******************************************************************************************
*
*
****/
Local cNatureza  := Space(10)
Local nTotalNatG := 0
Local nTotalNat	 := 0
Local nTotal	 := 0

DbSelectArea(cString)

//���������������������������������������������������������������������Ŀ
//� SETREGUA -> Indica quantos registros serao processados para a regua �
//�����������������������������������������������������������������������

SetRegua(RecCount())

//���������������������������������������������������������������������Ŀ
//� Posicionamento do primeiro registro e loop principal. Pode-se criar �
//� a logica da seguinte maneira: Posiciona-se na filial corrente e pro �
//� cessa enquanto a filial do registro for a filial corrente. Por exem �
//� plo, substitua o dbGoTop() e o While !EOF() abaixo pela sintaxe:    �
//�                                                                     �
//� dbSeek(xFilial())                                                   �
//� While !EOF() .And. xFilial() == A1_FILIAL                           �
//�����������������������������������������������������������������������

DbGoTop()

While !EoF()
	
	If nLin > 55 // Salto de P�gina. Neste caso o formulario tem 55 linhas...
		Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
		nLin := 6
		If mv_par04 = 1
			@ nLin,00 PSay "Prf   Titulo   Parc Fornecedor                       Vlr Pago     Baixa"
		else
			@ nLin,00 PSay "Prf   Titulo   Parc Fornecedor                       Vlr Pago     Emiss�o"
		endif
		nLin := 8
	Endif
		
	cNatureza	:= QSE2->E2_NATUREZ
	nTotalNat	:= 0
	nTotalNatG  := 0
	
	DbSelectArea("SED")
	DbSetOrder(1)
	DbSeek(xFilial("SED")+QSE2->E2_NATUREZ)
	
	@ nLin,00 PSay "Natureza: "+QSE2->E2_NATUREZ+" - "+SED->ED_DESCRIC
	nLin := nLin + 1
	
	DbSelectArea("QSE2")
	
	While !EoF() .And. QSE2->E2_NATUREZ == cNatureza
		
		//���������������������������������������������������������������������Ŀ
		//� Verifica o cancelamento pelo usuario...                             �
		//�����������������������������������������������������������������������
		
		If lAbortPrint
			@ nLin,00 PSAY "*** CANCELADO PELO OPERADOR ***"
			Exit
		Endif
		
		//���������������������������������������������������������������������Ŀ
		//� Impressao do cabecalho do relatorio. . .                            �
		//�����������������������������������������������������������������������
		
		If nLin > 55 // Salto de P�gina. Neste caso o formulario tem 55 linhas...
			Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
			nLin := 6
			If mv_par04 = 1
				@ nLin,00 PSay "Prf   Titulo   Parc Fornecedor                       Vlr Pago     Baixa"
			else
				@ nLin,00 PSay "Prf   Titulo   Parc Fornecedor                       Vlr Pago     Emiss�o"
			endif
			nLin := 8
		Endif
		
		
		
		If mv_par04 = 1
			@ nLin,02 PSay QSE2->E2_PREFIXO+ " " +QSE2->E2_NUM+ "   " +QSE2->E2_PARCELA+ "  " +QSE2->E2_FORNECE+ "-" +QSE2->E2_LOJA+ " - " +QSE2->E2_NOMFOR+ " " +Transform((QSE2->E2_VALOR - QSE2->E2_SALDO),"@E 999,999.99")+ " " +DToC(SToD(QSE2->E2_BAIXA))
		Else 
			@ nLin,02 PSay QSE2->E2_PREFIXO+ " " +QSE2->E2_NUM+ "   " +QSE2->E2_PARCELA+ "  " +QSE2->E2_FORNECE+ "-" +QSE2->E2_LOJA+ " - " +QSE2->E2_NOMFOR+ " " +Transform((QSE2->E2_VALOR ),"@E 999,999.99")+ " " +DToC(SToD(QSE2->E2_EMISSAO))
		EndIf
		
		
		// Coloque aqui a logica da impressao do seu programa...
		// Utilize PSAY para saida na impressora. Por exemplo:
		// @nLin,00 PSAY SA1->A1_COD
		
		nLin := nLin + 1 // Avanca a linha de impressao
		nTotalNatG += QSE2->E2_VALOR 
		nTotalNat  += QSE2->E2_VALOR - QSE2->E2_SALDO
		nTotal	   += QSE2->E2_VALOR 
		DbSkip() // Avanca o ponteiro do registro no arquivo
	EndDo
	@ nLin,00 PSay "Sub Total (T�tulos Pagos) R$ "+Transform(nTotalNat,"@E 999,999.99")
	nLin := nLin + 1 // Avanca a linha de impressao
	@ nLin,00 PSay "Sub Total (Geral) R$ "+Transform(nTotalNatG,"@E 999,999.99")
	nLin := nLin + 2
EndDo
@ nLin,00 PSay "Total R$ "+Transform(nTotal,"@E 999,999,999.99")

//���������������������������������������������������������������������Ŀ
//� Finaliza a execucao do relatorio...                                 �
//�����������������������������������������������������������������������

SET DEVICE TO SCREEN

//���������������������������������������������������������������������Ŀ
//� Se impressao em disco, chama o gerenciador de impressao...          �
//�����������������������������������������������������������������������

If aReturn[5]==1
	dbCommitAll()
	SET PRINTER TO
	OurSpool(wnrel)
Endif

MS_FLUSH()

Return