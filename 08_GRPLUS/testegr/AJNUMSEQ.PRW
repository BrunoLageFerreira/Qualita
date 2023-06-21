#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TOTVS.CH"
#include "tbiconn.ch"

/*
Programa para corrigir o NUMSEQ das transferências de bundle realizadas pelo GR+

Executar query para conferir:

SELECT D3_USUARIO, D3_CF, D3_EMISSAO, D3_COD, D3_LOTECTL, D3_NUMLOTE, D3_PROJPMS, D3_TASKPMS, MIN(D3_DOC) D3_DOC, MIN(D3_NUMSEQ) D3_NUMSEQ, MIN(SD3.R_E_C_N_O_) MENOR, MAX(SD3.R_E_C_N_O_) MAIOR,
(SELECT SUM(D3_QUANT) FROM SD3990 WHERE D3_PROJPMS = SD3.D3_PROJPMS AND D3_TASKPMS = SD3.D3_TASKPMS AND D3_CF='DE4' GROUP BY D3_PROJPMS, D3_TASKPMS) ENTRADA_METROS,
(SELECT COUNT(D3_FILIAL) FROM SD3990 WHERE D3_PROJPMS = SD3.D3_PROJPMS AND D3_TASKPMS = SD3.D3_TASKPMS AND D3_CF='DE4' GROUP BY D3_PROJPMS, D3_TASKPMS) ENTRADA_UNIDADES,
(SELECT SUM(D3_QUANT) FROM SD3990 WHERE D3_PROJPMS = SD3.D3_PROJPMS AND D3_TASKPMS = SD3.D3_TASKPMS AND D3_CF='RE4' GROUP BY D3_PROJPMS, D3_TASKPMS) SAIDA_METROS,
(SELECT COUNT(D3_FILIAL) FROM SD3990 WHERE D3_PROJPMS = SD3.D3_PROJPMS AND D3_TASKPMS = SD3.D3_TASKPMS AND D3_CF='RE4' GROUP BY D3_PROJPMS, D3_TASKPMS) SAIDA_UNIDADES
FROM SD3990 SD3 WHERE D_E_L_E_T_='' AND LEN(D3_NUMLOTE)=6 AND D3_EMISSAO LIKE '202302%' 
GROUP BY D3_USUARIO, D3_CF, D3_EMISSAO, D3_COD, D3_LOTECTL, D3_NUMLOTE, D3_PROJPMS, D3_TASKPMS ORDER BY MIN(R_E_C_N_O_) 

Executar query para identificar o registro com divergência:

SELECT D3_USUARIO, D3_FILIAL, D3_TM, D3_COD, D3_QUANT, D3_CF, D3_LOCAL, D3_DOC, D3_EMISSAO, D3_NUMSEQ, D3_CHAVE, D3_LOTECTL, D3_NUMLOTE, D3_NUMSERI, D3_PROJPMS, D3_TASKPMS, D3_YCAVALE, R_E_C_N_O_
FROM SD3990 
WHERE R_E_C_N_O_ BETWEEN 280829 AND 381873 AND D3_LOTECTL LIKE '006164%' 
ORDER BY R_E_C_N_O_
*/

User Function ufNunSeq()

	Local cSql       := ""
    Local cTipo      := ""
	Local qCavaletes := ""
    Local qChapas    := ""
    Local qValida    := ""
    Local lValida    := .T.

    PREPARE ENVIRONMENT EMPRESA '01' FILIAL '010101' MODULO 'EST'

    ConOut("Iniciando...")

	cSql := "    SELECT * "
	cSql += "      FROM " + RetSqlName("SD3") + " SD3 "
    cSql += " LEFT JOIN " + RetSqlName("SD3") + " CONTRA "
	cSql += "        ON CONTRA.D3_FILIAL  = SD3.D3_FILIAL "
    cSql += "       AND CONTRA.D3_CF      = 'RE4' "
	cSql += "       AND CONTRA.D3_EMISSAO = SD3.D3_EMISSAO "
	cSql += "       AND CONTRA.D3_USUARIO = SD3.D3_USUARIO "
	cSql += "       AND CONTRA.D3_DOC     = SD3.D3_DOC "
	cSql += "       AND CONTRA.D3_NUMSEQ  = SD3.D3_NUMSEQ "
	cSql += "       AND CONTRA.D_E_L_E_T_ = '' "
    cSql += "     WHERE SD3.D3_EMISSAO BETWEEN '20230201' AND '20230331' "
    cSql += "       AND SD3.D3_CF       = 'DE4' "
    cSql += "       AND SD3.D3_LOTECTL <> '' "
    cSql += "       AND SD3.D3_NUMLOTE <> '' "
	cSql += "       AND SD3.D_E_L_E_T_  = '' "
	cSql += "       AND CONTRA.D3_FILIAL IS NULL "
    cSql += "  ORDER BY SD3.R_E_C_N_O_ "

	TCQUERY cSql NEW ALIAS qCavaletes

    While qCavaletes->(!Eof())

        ConOut("Processando cavalete => " + qCavaletes->(D3_CF + D3_EMISSAO + D3_COD + D3_LOTECTL + D3_NUMLOTE))
        
        cSql := "   SELECT * "
        cSql += "     FROM " + RetSqlName("SD3") + " SD3 "
        cSql += "    WHERE D3_EMISSAO BETWEEN '20230201' AND '20230331' "
        cSql += "      AND D3_CF       = 'RE4' "
        cSql += "      AND D3_USUARIO  = '" + qCavaletes->D3_USUARIO + "' "
        cSql += "      AND D3_EMISSAO  = '" + qCavaletes->D3_EMISSAO + "' "
        cSql += "      AND D3_COD      = '" + qCavaletes->D3_COD + "' "
        cSql += "      AND D3_LOCAL    = '" + qCavaletes->D3_LOCAL + "' "
        cSql += "      AND D3_QUANT    = " + cValToChar(qCavaletes->D3_QUANT)

        // DE4 = Montagem de cavalete
        // RE4 = Desmontagem de cavalete
        
        If Len(AllTrim(qCavaletes->D3_NUMLOTE)) == 3 // Desmontagem
            cSql += " AND D3_LOTECTL LIKE '" + AllTrim(qCavaletes->D3_LOTECTL) + "%'"
        Else
            cSql += " AND D3_LOTECTL LIKE '" + SubStr(AllTrim(qCavaletes->D3_LOTECTL), 1, Len(AllTrim(qCavaletes->D3_LOTECTL)) - 1) + "'"
        EndIf

        cSql += "      AND R_E_C_N_O_  > " + cValToChar(qCavaletes->R_E_C_N_O_)
        cSql += "      AND D_E_L_E_T_  = '' "
        cSql += " ORDER BY R_E_C_N_O_ "

        TCQUERY cSql NEW ALIAS qChapas

        If qChapas->(!Eof())

            If (qChapas->(D3_NUMSEQ) <> qCavaletes->(D3_NUMSEQ))

                SD3->(DbGoTo(qCavaletes->R_E_C_N_O_))
                
                RecLock("SD3")
                SD3->D3_NUMSERI := qCavaletes->(D3_NUMLOTE)
                SD3->D3_PROJPMS := qCavaletes->(D3_DOC)
                SD3->D3_TASKPMS := qCavaletes->(D3_NUMSEQ)
                SD3->(MsUnLock())

                SD3->(DbGoTo(qChapas->R_E_C_N_O_))
                
                RecLock("SD3")
                SD3->D3_NUMSERI := qCavaletes->(D3_NUMLOTE)
                SD3->D3_PROJPMS := qCavaletes->(D3_DOC)
                SD3->D3_TASKPMS := qCavaletes->(D3_NUMSEQ)
                SD3->(MsUnLock())

            EndIf

        EndIf

        qChapas->(DbCloseArea())

        qCavaletes->(DbSkip())

    EndDo

    qCavaletes->(DbCloseArea())

    ConOut("Finalizado com sucesso!")

Return Nil



User Function ufCorrige()

	Local cSql       := ""
	Local qCavaletes := ""

    PREPARE ENVIRONMENT EMPRESA '01' FILIAL '010101' MODULO 'EST'

    SD5->(DbSetOrder(2))    

    ConOut("Iniciando...")

	cSql := "   SELECT * "
	cSql += "     FROM " + RetSqlName("SD3") + " SD3 "
	cSql += "    WHERE D3_EMISSAO BETWEEN '20230201' AND '20230331' 
    cSql += "      AND D3_PROJPMS <> '' "
	cSql += "      AND D_E_L_E_T_  = '' "
    cSql += " ORDER BY R_E_C_N_O_ "

	TCQUERY cSql NEW ALIAS qCavaletes

    While qCavaletes->(!Eof())

        If (SD5->(DbSeek(qCavaletes->(D3_FILIAL + D3_COD + D3_LOCAL + D3_LOTECTL + D3_NUMLOTE + D3_NUMSEQ))))

            RecLock("SD5")
            SD5->D5_DOC    := qCavaletes->D3_PROJPMS
            SD5->D5_NUMSEQ := qCavaletes->D3_TASKPMS
            SD5->(MsUnLock())

            SD3->(DbGoTo(qCavaletes->R_E_C_N_O_))
            RecLock("SD3")
            SD3->D3_DOC     := qCavaletes->D3_PROJPMS
            SD3->D3_NUMSEQ  := qCavaletes->D3_TASKPMS
            SD3->D3_NUMSERI := ""
            SD3->D3_PROJPMS := ""
            SD3->D3_TASKPMS := ""
            SD3->(MsUnLock())

            // ConOut("SD5 corrigida => " + qCavaletes->(D3_FILIAL + D3_COD + D3_LOCAL + D3_LOTECTL + D3_NUMLOTE + D3_NUMSEQ))

        Else 

            ConOut("Atencao, nao encontrou relacionamento na SD5 => " + qCavaletes->(D3_FILIAL + D3_COD + D3_LOCAL + D3_LOTECTL + D3_NUMLOTE + D3_NUMSEQ))

        EndIf

        qCavaletes->(DbSkip())

    EndDo

    qCavaletes->(DbCloseArea())

    ConOut("Finalizado com sucesso!")

Return Nil
