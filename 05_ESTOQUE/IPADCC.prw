#include "protheus.ch"
#include "topconn.ch"
/*
{Protheus.doc} IPADCC
Inicializador padrao do D3_cc 
Trazer o centro de custos do recurso nas requisicoes do apontamento de insumos
@author  (TOTVS) Nilton
@since 04/11/2022
@version 1.0

D3_CC - INICIALIZADOR PADRAO

*/
User Function IPADCC()
**************************************************************************
*
*
*****
Local aArea    := GetArea()
Local aAreaZGH := ZGH->(GetArea()) 
Local cret  := "" 
    If Alltrim(Funname())=="GROA045" .and. Left(SD3->D3_CF,2) == "RE" //somente requisicao 
        SB1->(DbSetOrder(1))
        SB1->(DbSeek(xFilial("SB1")+ZGI->ZGI_PRODUT))
        If Empty(SB1->B1_CCCUSTO) //Somente se nao for custo indireto
            ZGH->(DbSetOrder(1))
            If ZGH->(DbSeek(xFilial("ZGH")+ZGI->ZGI_OP+ZGI->ZGI_SEQUEN))
                SH1->(DbSetOrder(1))
                If SH1->(DbSeek(xFilial("SH1")+ZGH->ZGH_RECURS))
                    cret := SH1->H1_CCUSTO 
                EndIf
            EndIf
        EndIf           
    EndIF 
    RestArea(aAreaZGH)
    RestArea(aArea)
Return(cret)             
