#INCLUDE "rwmake.ch"
#include "protheus.ch"                                                                               

/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �NOVO4     � Autor � AP6 IDE            � Data �  06/08/12   ���
�������������������������������������������������������������������������͹��
���Descricao � Codigo gerado pelo AP6 IDE.                                ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       � AP6 IDE                                                    ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/
User Function DESCPDV()

	//���������������������������������������������������������������������Ŀ
	//� Posicione de clientes ou Fornecedores conforme F1_TIPO             
	//  POSICIONE("SA2",1,XFILIAL("SA2")+SF1->F1_FORNECE+SF1->F1_LOJA,"SA2->A2_NOME")
	//�����������������������������������������������������������������������

	Private cDescPDv := ""

	IF !(SC5-> C5_TIPO $ "D,B")   //Se for nota de devolucao
		cDescPDv := Posicione("SA1",1,XFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_NOME")    // Retorna o nome do Cliente
	ELSE
		cDescPDv := POSICIONE("SA2",1,XFILIAL("SA2")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A2_NOME")	   // Retorna o nome do Fornecedor      
	ENDIF

Return cDescPDv


User Function MOEDAPDV()

	//���������������������������������������������������������������������Ŀ
	//� Posicione de clientes ou Fornecedores conforme F1_TIPO             
	//  POSICIONE("SA2",1,XFILIAL("SA2")+SF1->F1_FORNECE+SF1->F1_LOJA,"SA2->A2_NOME")
	//�����������������������������������������������������������������������

	Local   cCNPJ   := ""
	Local   cDescPDv := ""
	 

	IF !(M->C5_TIPO $ "D,B")   //Se for nota de devolucao
		cDescPDv := Posicione("SA1",1,XFilial("SA1")+M->C5_CLIENTE+M->C5_LOJACLI,"A1_YMOEDA")    // Retorna o nome do Cliente
	ELSE
		cCNPJ := POSICIONE("SA2",1,XFILIAL("SA2")+M->C5_CLIENTE+M->C5_LOJACLI,"A2_CGC")
		IF Empty(cCNPJ)
			cDescPDv := 2
		Else
			cDescPDv := 1
		EndIf      
	ENDIF

Return cDescPDv
