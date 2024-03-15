#include "topconn.ch"
#include "totvs.ch"
#include "FWMVCDEF.CH"

/*                                          
Programa ...: GROA56IN.Prw
Uso ........: Ponto P.E atualizção padrão no formato MVC
Data .......: 2024-02-28
Feito por ..: Bruno Lage Ferreira.
*/

User Function GROA56IN()
********************************************************************************
*
*
***
Local oModel       := PARAMIXB[1]
Local nOper     
Local cCavalete 
Local cPerda 
Local cEndereco
Local nPesoBru  
Local nPesoLiq
Local cQuery
Local aRetExIn

Local cLoteFoto
Local cChapFoto

Local i := 0

nOper        := oModel:nOperation
cCavalete    := oModel:GetValue("ALIMASTER", "ZG3_CODIGO")
cEndereco    := oModel:GetValue("ALIMASTER", "ZG3_XENDER")
nPesoBru     := oModel:GetValue("ALIMASTER", "ZG3_PESOBR")
nPesoLiq     := oModel:GetValue("ALIMASTER", "ZG3_PESOLQ")
cPerda       := oModel:GetValue("ALIMASTER", "ZG3_XPERDA")

cLoteFoto    := AllTrim(oModel:GetValue("ALIMASTER", "ZG3_LOTFOT"))
cChapFoto    := AllTrim(oModel:GetValue("ALIMASTER", "ZG3_CHFOTO"))
aGdLotCha    := {} 

oModelZPB    := oModel:GetModel("ALIDETAIL")

aRetExIn := {.T.,.f.,"",cCavalete}

If nOper == MODEL_OPERATION_INSERT .Or. nOper == MODEL_OPERATION_UPDATE

    //validação do cabeçalho, Peso Bruto como exemplo não pode ser 0 se não da erro nem Pesoliq maior que o Peso Bruto
    if (nPesoLiq > nPesoBru)
        Return  {.F.,.f.,"Peso Bruto Invalido, favor corrigir",cCavalete} 
    Endif

    //Montagem do array de todos o lotes e sublotes 
    For i := 1 to oModelZPB:length()
        oModelZPB:GoLine(i)
        If !oModelZPB:IsDeleted()
            //ZPB_NUMLOT
            //ZPB_LOTECT
            If AllTrim(oModelZPB:GetValue("ZPB_LOTECT")) + AllTrim(oModelZPB:GetValue("ZPB_NUMLOT")) <> ""
                aAdd(aGdLotCha,{AllTrim(oModelZPB:GetValue("ZPB_LOTECT")) + AllTrim(oModelZPB:GetValue("ZPB_NUMLOT")) } )  
            EndIf
        EndIf
    Next i

    If cPerda <> "S"
        If Len(aGdLotCha) > 0
            If ascan(aGdLotCha,{|x| x[1]== cLoteFoto + cChapFoto}) == 0
                Return  {.F.,.f.,"O Lote + Chapa da (FOTO), não foram encontrados nos itens do bundle!",cCavalete} 
            EndIf
        ElseiF (cLoteFoto + cChapFoto <> "")
            Return  {.F.,.f.,"O Lote + Chapa da (FOTO), não foram encontrados nos itens do bundle!",cCavalete} 
        EndIf
    EndIf

    If !Empty(cEndereco)
        cQuery := " SELECT ZE1_BLQ,ZE1_ENDERE FROM ZE1010 WHERE D_E_L_E_T_ = '' AND ZE1_ENDERE='" + AllTrim(cEndereco) + "'"
        tcQuery cQuery alias TRB new

        dbSelectArea("TRB")
        dbgotop()
        
        If EOF()
                dbSelectArea("TRB") 
                dbCloseArea()
                Return  {.F.,.f.,"Endereço não encontrado!",cEndereco}
        Else
                Do While !EOF()
                    
                    If TRB->ZE1_BLQ == '2'
                        dbSelectArea("TRB") 
                        dbCloseArea()
                        Return  {.F.,.f.,"Endereço bloqueado para produtos acabados!",cEndereco}
                    EndIf
                                            
                    dbSelectArea("TRB") 
                    dbSkip()
                EndDo
        EndIf

        dbSelectArea("TRB") 
        dbCloseArea()
    EndIf
Endif

Return aRetExIn
