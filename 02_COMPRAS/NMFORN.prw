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

User Function NMFORN()

	//���������������������������������������������������������������������Ŀ
	//� Posicione de clientes ou Fornecedores conforme F1_TIPO             
	//  POSICIONE("SA2",1,XFILIAL("SA2")+SF1->F1_FORNECE+SF1->F1_LOJA,"SA2->A2_NOME")
	//�����������������������������������������������������������������������

	Private cNMFORN := ""

	IF SF1-> F1_TIPO == "D"   //Se for nota de devolucao
		cNMFORN := POSICIONE("SA1",1,XFILIAL("SA1")+SF1->F1_FORNECE+SF1->F1_LOJA,"SA1->A1_NOME") // Retorna o nome do Cliente
		IF(AllTrim(SF1->F1_NMFORN) == "")
			RecLock("SF1",.F.)
			SF1->F1_NMFORN := cNMFORN
			MsUnlock()
		EndIf
	ELSE
		cNMFORN := POSICIONE("SA2",1,XFILIAL("SA2")+SF1->F1_FORNECE+SF1->F1_LOJA,"SA2->A2_NREDUZ") // Retorna o nome do Fornecedor      
		IF(AllTrim(SF1->F1_NMFORN) == "")
			RecLock("SF1",.F.)
			SF1->F1_NMFORN := cNMFORN
			MsUnlock()	
		EndIf
	ENDIF

Return cNMFORN