#Include "rwmake.ch"
#Include "Colors.ch"
#Include "Protheus.ch" 
#Include "Topconn.ch"

/*
Programa ...: MOBALTARR.Prw
Uso ........: MOBALTARR USADO PARA ALTERAR O RETORNO PADRÃO DO ARRAY DO ITENS SALESFORCE
Data .......: 2023-03-01
Feito por ..: Bruno Lage Ferreira
Copyright @1998-2001,2023
Atualizado..: 

Nome do Arquivo:		
REF/SALESFORCE
*/    

User Function MOBALTARR()
/*****************************************************************************************************************************************
*
*
***/
Local aCabAux  := paramixb[1]
Local aIteAux  := paramixb[2]
Local nOpcx    := paramixb[3]
Local aOrdCab  := {}   //{"C5_CLIENTE","C5_NATUREZ"} 
Local aOrdIte  := {"C6_NUM","C6_ITEM","C6_PRODUTO","C6_DESCRI","C6_LOCAL","C6_YCAVALE","C6_YCLASSI","C6_LOTECTL","C6_NUMLOTE","C6_QTDVEN","C6_PRCVEN","C6_PRUNIT","C6_VALOR","C6_VALDESC","C6_ENTREG","C6_UM","C6_TES","C6_CLI","C6_LOJA","C6_XOFERTA","C6_XPESO"} 
Local aCabec   := {}
Local aItens   := {}
Local aLiItens := {}
Local nPosCab  := 0
Local nPosIte  := 0
Local i,j      := 0



//Reordenar cabeçalho
For i := 1 to len(aOrdCab)
    nPosCab := aScan(aCabAux, {|x| AllTrim(x[1]) == aOrdCab[i]})
    if(nPosCab > 0)
        AADD( aCabec, aCabAux[nPosCab] )
        aDel(aCabAux,nPosCab)
        aSize(aCabAux,Len(aCabAux)-1)
    EndIf
Next

For i := 1 to len(aCabAux)
    AADD( aCabec, aCabAux[i] )
Next

//Reordenando os itens
For j := 1 to len(aIteAux)
    
    aItens := {}

    for i := 1 to len(aOrdIte)

        nPosIte := aScan(aIteAux[j], {|x| AllTrim(x[1]) == aOrdIte[i]})

        if(nPosIte > 0)
            AADD( aItens, aIteAux[j,nPosIte] )
            aDel(aIteAux[j],nPosIte)
            aSize(aIteAux[j],Len(aIteAux[j])-1)
        EndIf

    next

    For i := 1 to len(aIteAux[j])
        AADD( aItens, aIteAux[j,i] )
    Next

    AADD( aLiItens, aItens )

Next

Return {aCabec,aLiItens}
