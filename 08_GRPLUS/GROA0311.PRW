#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
#INCLUDE "TOPCONN.CH"

/*
Ponto de entrada que permite alterar o conteúdo da
totalizador da nota fiscal de entrada B1_POSIPI
*/

User Function GROA0311()
***********************************************************************************************************
*
*
***

    Local nX := 1

    DbSelectArea("SX3")
    DbSetOrder(2)

    If DbSeek("B1_POSIPI")
        
        aAdd(aHeadSD1, {;
            SX3->X3_TITULO,;
            SX3->X3_CAMPO,;
            SX3->X3_PICTURE,;
            SX3->X3_TAMANHO,;
            SX3->X3_DECIMAL,;
            "ALLWAYSTRUE()",;
            ,;
            SX3->X3_TIPO,;
            SX3->X3_F3,;
            "";
        })

    EndIf

    For nX := 1 To Len(aColSD1)

        // Inclui nova coluna de delete
        aAdd(aColSD1[nX], .F.)
        // Atualiza conteúdo do campo que antes era de delete
        aColSD1[nX][Len(aColSD1[nX]) - 1] := Posicione("SB1", 1, xFilial("SB1") + aColSD1[nX][1], "B1_POSIPI")

    Next

Return Nil
