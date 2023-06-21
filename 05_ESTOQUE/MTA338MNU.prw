#Include "Totvs.ch"
#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
#INCLUDE "topconn.ch"

#DEFINE USADO CHR(0)+CHR(0)+CHR(1)

/*
Programa ...: MTA338MNU.Prw
Uso ........: MENU DO REAVALIAÇÃO DO CUSTO MÉDIO
Data .......: 14/03/2022
Feito por ..: Bruno Lage Ferreira 
*/

User Function MTA338MNU()
********************************************************************************************************
* /*MENU*/
*
****

aAdd(aRotina, {"Cópia de Dados"     ,"Processa({|| U_MMTA338SDQ(3)}, 'Copiando...')"      , 0 , 3, 0,nil})
aAdd(aRotina, {"Deleta Cópia  "     ,"Processa({|| U_MMTA338SDQ(5)}, 'Deletando...')"     , 0 , 3, 0,nil})
aAdd(aRotina, {"Rel. Conf. Custos " ,"U_RELINWEB('RQ0090')" , 0 , 3, 0,nil})

Return()


User Function MMTA338SDQ(nOpcao)
********************************************************************************************************
* /*CÓPIA SDQ*/
*
****
local   aItem  := {}

Local nAtual := 0
Local nTotal := 0

Private aPerg  := {}


Private cPerg  := "PMTA338SDQ"
Private cQuery := ""
PRIVATE lMsErroAuto := .F.

Aadd(aPerg,{cPerg,"Filial de Origem    ?"		,"C",06,00,"G","","SM0","","","","","",""})
Aadd(aPerg,{cPerg,"Filial de Destino   ?"		,"C",06,00,"G","","SM0","","","","","",""})
Aadd(aPerg,{cPerg,"Dia do lançamento   ?" 	    ,"D",08,00,"G","","","","","","","",""})   
Aadd(aPerg,{cPerg,"Último dia do Mês   ?" 	    ,"D",08,00,"G","","","","","","","",""})  
Aadd(aPerg,{cPerg,"Grupo a ser Copiado ?" 	    ,"C",04,00,"G","","SBM","","","","","",""})  
Aadd(aPerg,{cPerg,"Almoxarifado de Origem    ?"	,"C",02,00,"G","","","","","","","",""})
Aadd(aPerg,{cPerg,"Almoxarifado de Destino   ?"	,"C",02,00,"G","","","","","","","",""})


U_Testasx1(cPerg,aPerg,.T.)

If ! Pergunte(cPerg,.T.)
	Return()
EndIf

IF MV_PAR04 <= GetMV("MV_ULMES")
    Alert("O parâmetro (Último dia do Mês   ?) tem que ser maior que o fechamento. Mês tem que estar em aberto!")
    Return()
EndIf

If stod(AnoMes(MV_PAR04) + ALLTRIM(STR(Last_day(MV_PAR04) ))) <> MV_PAR04
    Alert("O parâmetro (Último dia do Mês   ?) não é o último dia do mês!")
    Return()
EndIf

cQuery := "  SELECT	DQ_FILIAL,
cQuery += " 		DQ_COD,
cQuery += " 		DQ_LOCAL,
cQuery += " 		DQ_DATA,
cQuery += " 		DQ_CM1
cQuery += "    FROM SDQ010 SDQ INNER JOIN SB1010 SB1 ON (B1_COD = DQ_COD)
cQuery += "   WHERE SB1.D_E_L_E_T_ = ''
cQuery += "     AND SDQ.D_E_L_E_T_ = ''

if nOpcao == 3
    cQuery += "     AND DQ_DATA    = '"+DTOS(MV_PAR03)+"'
else
    cQuery += "     AND DQ_DATA    = '"+DTOS(MV_PAR04)+"'
EndIf

if nOpcao == 3
    cQuery += "     AND DQ_FILIAL  = '"+MV_PAR01+"'
else
    cQuery += "     AND DQ_FILIAL  = '"+MV_PAR02+"'
EndIf

IF !EMPTY(mv_par05)
    cQuery += " AND B1_GRUPO = '"+MV_PAR05+"'
EndIf

IF !EMPTY(mv_par06)
    cQuery += " AND DQ_LOCAL = '"+MV_PAR06+"'
EndIf

cQuery += " ORDER BY DQ_COD

TcQuery cQuery Alias TMPSDQ New

Count To nTotal
ProcRegua(nTotal)

dbSelectArea("TMPSDQ")     
dbGoTop()
Do While !EOF()         

    nAtual :=  nAtual + 1
    IncProc("Processando registro " + cValToChar(nAtual) + " de " + cValToChar(nTotal) + "...")
          
    aItem := {}

    IF nOpcao == 3
        AAdd(aItem,{"DQ_FILIAL",MV_PAR02        ,Nil})                                                                                                                
    Else
        AAdd(aItem,{"DQ_FILIAL",TMPSDQ->DQ_FILIAL        ,Nil})                                                                                                                
    EndIf     

    IF nOpcao == 3
        AAdd(aItem,{"DQ_LOCAL",MV_PAR07        ,Nil})                                                                                                                
    Else
        AAdd(aItem,{"DQ_LOCAL",MV_PAR06        ,Nil}) 
    EndIf     
    

    AAdd(aItem,{"DQ_COD"   ,TMPSDQ->DQ_COD  ,Nil})
    AAdd(aItem,{"DQ_LOCAL" ,TMPSDQ->DQ_LOCAL,Nil})
    IF nOpcao == 3
        AAdd(aItem,{"DQ_DATA"  ,MV_PAR04        ,Nil})
    Else
        AAdd(aItem,{"DQ_DATA"  ,TMPSDQ->DQ_DATA ,Nil})
    EndIf
    AAdd(aItem,{"DQ_CM1"   ,TMPSDQ->DQ_CM1  ,Nil})

    MSExecAuto({|x,y,z| MATA338(x,y)},aItem,nOpcao)
    
    If lMsErroAuto
        mostraerro()
        lMsErroAuto := .F.
    Endif   
        
    dbSelectArea("TMPSDQ")
    dbSkip()
EndDo                    

dbSelectArea("TMPSDQ")
dbCloseArea()

IF nOpcao == 3
    Aviso("Aviso!","Cópia concluída com sucesso!",{"OK"})
else
    Aviso("Aviso!","Exclusão concluída com sucesso!",{"OK"})
EndiF

Return()
