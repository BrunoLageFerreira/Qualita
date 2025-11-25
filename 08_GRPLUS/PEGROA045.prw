#INCLUDE "protheus.CH"
#INCLUDE "FWMVCDEF.CH"
#Include "Parmtype.ch"
#INCLUDE "TOTVS.CH"
#INCLUDE "FWEditPanel.CH"
#INCLUDE "TOPCONN.CH"

/*
{Protheus.doc} UGROA045
@Author  (TOTVS) / Bruno Lage/ 
@since 04/11/2022
@version 2.0
GR_HABOPPA - Parametro para desativar aba de produto acabado
--serrada = 2687 dia 15
--beneficiamento =2749 dia 17
*/
User Function UGROA045()
/**************************************************************************************************************
*
*
***/
Local aArea        := GetArea()
Local aParam       := PARAMIXB
Local lRet         := .T.
Local nret         := 0
Local nI           := 0
Local nX           := 0
Local oModel       := FWModelActive()
Local oModeLZGH 
Local oModelZGI 
Local oModelSH6
Local cQuery       := ''

Local cPerg1  := "XAPPAPONTA"

Private oObj       := ''
Private cIdPonto   := ''
Private cIdModel   := ''

If aParam <> NIL
	oObj       := aParam[1]
	cIdPonto   := aParam[2]
	cIdModel   := aParam[3]


	If cIdPonto == 'MODELCOMMITNTTS'
		DbSelectArea("ZGI")
		DbSetOrder(1)
		DbSeek(xFilial("ZGI")+ZH7->ZH7_NUM)
		Do while !Eof() .and. ZGI_FILIAL==xFilial("ZGI") .and. ZGI_OP == ZH7->ZH7_NUM
			SB1->(DbSetOrder(1))
			If SB1->(DbSeek(xFilial("SB1")+ZGI->ZGI_PRODUT))
				If "MAO DE OBRA"  $ SB1->B1_DESC .and. !Empty(SB1->B1_CCCUSTO)//Produto de mao de obra com centro de custos informado
					If Alltrim(ZH7->ZH7_PROCES) == 'S'
						nret := fTempoS()
					Else
						nret := ftempo()
					EndIf
					Reclock("ZGI",.F.)
					ZGI->ZGI_QTDE := nret
					ZGI->(MsUnlock())

				EndIf
			EndIf
			/*
			Pergunte(cPerg1,.F.)	
			if !EMPTY(mv_par01)

				cQuery := " UPDATE SIGAEIS..APP005_OP_CAB
				cQuery += "    SET CAB_NUMOP = '"+ AllTrim(ZH7->ZH7_NUM) + "'"
				cQuery += "  FROM SIGAEIS..APP005_OP_CAB WHERE CAB_D_E_L_E_T_ = '' AND CAB_ID = "+AllTrim(Str(mv_par01))
				
				TcSQLExec(cQuery)
			EndIf
			*/
			DbSelectArea("ZGI")
			DbSkip()
		EndDo

	ElseIf cIdPonto == 'MODELVLDACTIVE'
		/*
		cQuery := "DELETE FROM MP_SYSTEM_PROFILE WHERE D_E_L_E_T_ = '' AND P_PROG = 'XAPPAPONTA'"
		TcSQLExec(cQuery)
		cQuery := "DELETE FROM SX1010 WHERE D_E_L_E_T_ = '' AND X1_GRUPO = 'XAPPAPONTA'"
		TcSQLExec(cQuery)
		*/
		//Private nIDGlob := 0
	ElseIf cIdPonto == 'BUTTONBAR'
			//ApMsgInfo('Adicionando Botao na Barra de Botoes (BUTTONBAR).' + CRLF + 'ID ' + cIdModel )
		if inclui
			lRet := { {'Import. Apontamento', 'Import. Apontamento', { || u_APPApont()}, 'Import. Apontamento' } }
		EndIf

	ElseIf cIdPonto == 'MODELPRECOMMIT'
		//Local oModelZGH := oModel:GetModel("ZGHDETAIL") // Operações
		//Local oModelSH6 := oModel:GetModel("SH6DETAIL") // Paradas - Hora improdutiva
		//Local oModelZGI := oModel:GetModel("ZGIDETAIL") // Insumos
		//Local oModelMOD := oModel:GetModel("MODDETAIL") // Custo indireto
		//Local oModelZGK := oModel:GetModel("ZGKDETAIL") // Mão-de-Obra
		//Local oModelZGL := oModel:GetModel("ZGLDETAIL") // Ferramenta
		//Local oModelZHL := oModel:GetModel("ZGLDETAIL") // Operações x Produto Acabado
		oModeLZGH := oModel:GetModel("ZGHDETAIL") 
		oModelSH6 := oModel:GetModel("SH6DETAIL") 
		/*
		Validação do SH6 na Confirmação do apontamento
		Motivo das paradas improdutivas.
		*/		
		For nI := 1 to oModelSH6:length()
			oModelSH6:GoLine(nI)
			If !(oModelSH6:IsDeleted()) // se a linha não estiver deletada
				If !Empty(oModelSH6:GetValue("H6_TEMPO")) // se existe tempo de parada calculado
					If Empty(oModelSH6:GetValue("H6_MOTIVO")) // se o motivo estive em branco 
						//Alert("O motivo da parada deve ser sempre preenchido!")
						
						oModel:SetErrorMessage("",,oModel:GetId(),"","GROA044","O motivo da parada deve ser sempre preenchido!")

						lRet := .f.
						Return(lRet)
					EndIf
				EndIf
			EndIf
		Next

		For nI := 1 to oModeLZGH:length()
			//valida a primeira linha do apontamento para verificar a data do estoque
			oModelZGH:GoLine(1)	
			
			IF ZH7->ZH7_EMISSA > GETMV("MV_ULMES") .Or. oModeLZGH:GetValue("ZGH_DATFIM")  > GETMV("MV_ULMES")
				//ZH7->ZH7_EMISSA
				IF Alltrim(M->ZH7_PROCES) == 'S'
					IF Empty(oModeLZGH:GetValue("ZGH_HRINI")) .OR.  Empty(oModeLZGH:GetValue("ZGH_HRFIM"))
						//Alert("O horímetro inicial e final devem ser prenchidos!")
						oModel:SetErrorMessage("",,oModel:GetId(),"","GROA044","O horímetro inicial e final devem ser prenchidos!")
						lRet := .F.
						Return(lRet)
					EndIf
				EndIf 

				If Empty(oModeLZGH:GetValue("ZGH_TOTHOR"))
					oModeLZH7 := oModel:GetModel("ZH7MASTER") 
					oModelZH7:SetValue("ZH7_XID",0)
				EndIf

				//loop do linha conforme nI := ModeLZGH:length()
				oModelZGH:GoLine(nI)
					
				oModelZGI := oModel:GetModel("ZGIDETAIL")
				oView := FwViewactive()
				For nX := 1 To oModeLZGI:Length()
					oModeLZGI:GoLine(nX)
					//Aqui estamos prercorrendo os insumos da operação
					If !(oModelZGI:IsDeleted())
						lRet := u_UGR045V(oModeLZGI:GetValue("ZGI_PRODUT"),oModeLZGI:GetValue("ZGI_LOCAL"),oModeLZGI:GetValue("ZGI_QTDE"),oModel)
						If  lRet == .F.
							//FwFldPut("ZGI_QTDE", 0,nX,oModeLZGI)
							oModeLZGI:SetValue("ZGI_QTDE",0)
						EndIf
					EndIf
					//cCodProd := oModeLZGI:GetValue("ZGI_PRODUT")
					//Alert("Teste para mostrar os produtos de insumo"+cCodProd)
				Next
				oModeLZGI:GoLine(1)
				//oView:Refresh("ZGIDETAIL")
				If !isBlind()
					oView:Refresh("ZGIDETAIL")
				EndIf

			Else
				//Alert("O formulário não pode ser alterado! O estoque já encontra-se fechado.")
				oModel:SetErrorMessage("",,oModel:GetId(),"","GROA044","O formulário não pode ser alterado! O estoque já encontra-se fechado.")
				oModel:GetModel("ZGHDETAIL"):SetOnlyView(.T.) 
				oModel:GetModel("ZGHDETAIL"):SetNoDeleteLine(.T.) 
				oModel:GetModel("ZGHDETAIL"):SetNoInsertLine(.T.) 
				oModel:GetModel("ZGHDETAIL"):SetNoUpdateLine(.T.)
				lRet := .f.
			EndIf
		Next
		//if MsgYesNo("Deseja cotinuar ?")
		//	lRet := .f.
		//EndIF
	ElseIf cIdPonto == 'MODELPOS'

	EndIf

EndIf

RestArea(aArea)
//Final deo programa
Return(lRet)


User Function DADOSOP(oModelZH8,oModelZH9,aDadosOp)
/*******************************************************************************************************************
*
*
****/
Local aMatPrim  := {}
Local aMatAcab  := {}
Local i,nY,nX   := 0
Local oModel    := Nil

aMatPrim  := aDadosOp[1]
aMatAcab  := aDadosOp[2]

	oModelZH8:AddLine()
	nLine := oModelZH8:Length()
	oModelZH8:GoLine(nLine)

	//Adicionando os dados da materia prima ao modelo
	For nX := 1 To Len(aMatPrim)
		For nY := 1 To Len(aMatPrim[nX])
			__lAuto := .T.
			oModelZH8:SetValue(aMatPrim[nX][nY][1],aMatPrim[nX][nY][2])
		Next
	Next

	//Adicionando os produtos acabados
	For nX := 1 To Len(aMatAcab)
		oModelZH9:AddLine()
		nLine := oModelZH9:Length()
		oModelZH9:GoLine(nLine)

		For nY := 1 To Len(aMatAcab[nX])
			oModelZH9:SetValue(aMatAcab[nX,nY,1],  aMatAcab[nX,nY,2])
		Next
	Next

Return


User Function APPApont()
/****************************************************************************************************************
*
*
***/
Local oModel := FWModelActive()
Local cQuery := ""
Local cCodId := 0
Local lValid := .F.
Local nRegZGH:= 0
Local nRegSH6:= 0
Local oView  

Local nX     := 0
Local nJ     := 0

Local oModeLZH7 := oModel:GetModel("ZH7MASTER")
Local oModelZGI := oModel:GetModel("ZGIDETAIL")
Local oModelZH8 := oModel:GetModel("ZH8DETAIL")
Local oModelZH9 := oModel:GetModel("ZH9DETAIL")

Local oModelSH6 := oModel:GetModel("SH6DETAIL") // Paradas - Hora improdutiva
Local oModelZGH := oModel:GetModel("ZGHDETAIL") // Operações
Local oModelMOD := oModel:GetModel("MODDETAIL") // Custo indireto
Local oModelZGK := oModel:GetModel("ZGKDETAIL") // Mão-de-Obra
Local oModelZGL := oModel:GetModel("ZGLDETAIL") // Ferramenta
Local oModelZHL := oModel:GetModel("ZHLDETAIL") // Operações x Produto Acabado

Local nRegZGI
Local nI 
Local aDadosOp  := {}
Local aMatPri   := {}
Local aMatPriSal:= {}
Local aMatAcab  := {}

Local aMatPriItem, aMatAcabFiltrado, aDadosTemp
Local nItemPri, nItemAcab

Private aPerg  := {}
Private cPerg  := "XAPPAPONTA"

Aadd(aPerg,{cPerg,"Digite o número ID?","N",9,00,"G","","","","","","","",""})     

U_Testasx1(cPerg,aPerg,.F.) 

If ! Pergunte(cPerg,.t.)
	Return
EndIf

iF !Empty(mv_par01)
    cCodId    := mv_par01    
	nIdGlobal := mv_par01

	//**********************************************************************************************			
	//VERIFICA SE EXISTE O REGISTRO JA IMPORTADO
	//**********************************************************************************************
	cQuery := " SELECT ZH7_NUM 
	cQuery += "   FROM DADOSADV_Q..ZH7010 
	cQuery += "  WHERE D_E_L_E_T_ = ''
	cQuery += "    AND ZH7_XID = "+Trim(Str(cCodId))

	TCQUERY cQuery NEW ALIAS REG_IMP

	dbSelectArea("REG_IMP")
	dbGoTop()
	If !EOF()
		Alert("Este registo foi encontrado na OP:" + AllTrim(REG_IMP->ZH7_NUM) + " .O registro não pode ser importado 2 vezes.")
		dbSelectArea("REG_IMP")
		DbCloseArea()
		Return()
	EndIf
	dbSelectArea("REG_IMP")
	DbCloseArea()

	//**********************************************************************************************			
	//SERRADA OU MATERIA PRIMA 
	//**********************************************************************************************
	aMatPri  := {}
	aMatAcab := {}
	
	If oModelZH7:GetValue("ZH7_PROCES") == "S"
		//Adicionando a materia prima
		cQuery := " SELECT DENSE_RANK() OVER (ORDER BY DLS_CODPRO, DLS_LOTE) AS ZH8_ITEM,
		cQuery += " 	   DLS_CODPRO 		ZH8_CODMAT ,
		cQuery += " 	   TRIM(B1_DESC)    ZH8_DESCMT ,
		cQuery += " 	   CAB_COD_ENG_PRO  ZH8_ENGENH ,
		cQuery += " 	   TRIM(ZG7_DESCRI) ZH8_DESCEN ,
		cQuery += " 	   TRIM(DLS_LOTE)   ZH8_LOTECT ,
		cQuery += " 	   TRIM(DLS_CHAPA)  ZH8_NUMLOT ,
		cQuery += " 	   TRIM(B1_LOCPAD)  ZH8_LOCAL  ,
		cQuery += " 	   TRIM(B1_UM)      ZH8_UM     ,
		cQuery += " 	   (SELECT B8_YCOMLIQ FROM DADOSADV_Q..SB8010 WHERE D_E_L_E_T_ = '' AND B8_PRODUTO = TRIM(B1_COD) AND B8_LOTECTL = TRIM(DLS_LOTE) AND LEFT(B8_PRODUTO,2) = 'BL' ) ZH8_COMLIQ,
		cQuery += " 	   (SELECT B8_YALTLIQ FROM DADOSADV_Q..SB8010 WHERE D_E_L_E_T_ = '' AND B8_PRODUTO = TRIM(B1_COD) AND B8_LOTECTL = TRIM(DLS_LOTE) AND LEFT(B8_PRODUTO,2) = 'BL' ) ZH8_ALTLIQ,
		cQuery += " 	   (SELECT B8_YESPLIQ FROM DADOSADV_Q..SB8010 WHERE D_E_L_E_T_ = '' AND B8_PRODUTO = TRIM(B1_COD) AND B8_LOTECTL = TRIM(DLS_LOTE) AND LEFT(B8_PRODUTO,2) = 'BL' ) ZH8_ESPLIQ,
		cQuery += " 	   (SELECT B8_YTOTLIQ FROM DADOSADV_Q..SB8010 WHERE D_E_L_E_T_ = '' AND B8_PRODUTO = TRIM(B1_COD) AND B8_LOTECTL = TRIM(DLS_LOTE) AND LEFT(B8_PRODUTO,2) = 'BL' ) ZH8_TOTLIQ,
		cQuery += " 	   (SELECT B8_YCOMBRU FROM DADOSADV_Q..SB8010 WHERE D_E_L_E_T_ = '' AND B8_PRODUTO = TRIM(B1_COD) AND B8_LOTECTL = TRIM(DLS_LOTE) AND LEFT(B8_PRODUTO,2) = 'BL' ) ZH8_COMBRU,
		cQuery += " 	   (SELECT B8_YALTBRU FROM DADOSADV_Q..SB8010 WHERE D_E_L_E_T_ = '' AND B8_PRODUTO = TRIM(B1_COD) AND B8_LOTECTL = TRIM(DLS_LOTE) AND LEFT(B8_PRODUTO,2) = 'BL' ) ZH8_ALTBRU,
		cQuery += " 	   (SELECT B8_YESPBRU FROM DADOSADV_Q..SB8010 WHERE D_E_L_E_T_ = '' AND B8_PRODUTO = TRIM(B1_COD) AND B8_LOTECTL = TRIM(DLS_LOTE) AND LEFT(B8_PRODUTO,2) = 'BL' ) ZH8_ESPBRU,
		cQuery += " 	   (SELECT B8_YTOTBRU FROM DADOSADV_Q..SB8010 WHERE D_E_L_E_T_ = '' AND B8_PRODUTO = TRIM(B1_COD) AND B8_LOTECTL = TRIM(DLS_LOTE) AND LEFT(B8_PRODUTO,2) = 'BL' ) ZH8_TOTBRU,
		cQuery += "        TRIM(DLS_SCOMPLOTE) COMPLEMTO,DLS_SCOMINT COMPRIMENTO,DLS_SALTINT ALTURA,DLS_SLARGINT ESPESSURA
		cQuery += "   FROM SIGAEIS..APP005_OP_DLS DLS INNER JOIN DADOSADV_Q..SB1010 SB1 ON (B1_COD = DLS_CODPRO )
		cQuery += " 								  INNER JOIN SIGAEIS..APP005_OP_CAB OPCAB ON (CAB_ID = DLS_ID_CAB)
		cQuery += " 								  INNER JOIN DADOSADV_Q..ZG7010 ZG7 ON (TRIM(ZG7_CODIGO) = TRIM(CAB_COD_ENG_PRO) )
		cQuery += "  WHERE DLS.DLS_D_E_L_E_T_ = ''
		cQuery += "    AND OPCAB.CAB_D_E_L_E_T_  = ''
		cQuery += "    AND ZG7.D_E_L_E_T_ = ''
		cQuery += "    AND SB1.D_E_L_E_T_ = ''
		cQuery += "    AND DLS_ID_CAB = "+Trim(Str(cCodId))
		cQuery += " ORDER BY 1
	Else 
		cQuery := " SELECT  DENSE_RANK() OVER (ORDER BY DLS_CODPRO, DLS_LOTE,DLS_CHAPA) AS ZH8_ITEM,
		cQuery += " 	   	DLS_CODPRO 							ZH8_CODMAT,
		cQuery += " 		TRIM(B1_DESC)						ZH8_DESCMT,
		cQuery += " 		CAB_COD_ENG_PRO						ZH8_ENGENH,
		cQuery += " 		TRIM(ZG7_DESCRI)					ZH8_DESCEN,
		cQuery += " 		TRIM(DLS_LOTEORI)					ZH8_LOTECT,
		cQuery += " 		TRIM(DLS_CHAPA)						ZH8_NUMLOT,
		cQuery += " 		TRIM(B1_LOCPAD)						ZH8_LOCAL ,
		cQuery += " 		TRIM(B1_UM)							ZH8_UM	  ,
		cQuery += "			DLS_ALTLIQ							ZH8_ALTLIQ,
		cQuery += "			DLS_COMLIQ							ZH8_COMLIQ,
		cQuery += "			DLS_ESPLIQ							ZH8_ESPLIQ,
		cQuery += "			ROUND(DLS_ALTLIQ * DLS_COMLIQ,5)	ZH8_TOTLIQ,
		cQuery += "			DLS_ALTBRU							ZH8_ALTBRU,
		cQuery += "			DLS_COMBRU							ZH8_COMBRU,
		cQuery += "			DLS_ESPBRU							ZH8_ESPBRU,
		cQuery += "			ROUND(DLS_ALTBRU * DLS_COMBRU,5)	ZH8_TOTBRU,
		cQuery += "			TRIM(DLS_SCOMPLOTE) COMPLEMTO,DLS_SCOMINT COMPRIMENTO,DLS_SALTINT ALTURA,DLS_SLARGINT ESPESSURA
		cQuery += " FROM SIGAEIS..APP005_OP_DLS DLS INNER JOIN DADOSADV_Q..SB1010 SB1 ON (B1_COD = DLS_CODPRO )
		cQuery += " 			 					INNER JOIN SIGAEIS..APP005_OP_CAB OPCAB ON (CAB_ID = DLS_ID_CAB)
		cQuery += " 			 					INNER JOIN DADOSADV_Q..ZG7010 ZG7 ON (TRIM(ZG7_CODIGO) = TRIM(CAB_COD_ENG_PRO) )
		cQuery += " WHERE DLS.DLS_D_E_L_E_T_ = ''
		cQuery += "   AND OPCAB.CAB_D_E_L_E_T_  = ''
		cQuery += "   AND ZG7.D_E_L_E_T_ = ''
		cQuery += "   AND SB1.D_E_L_E_T_ = ''
		cQuery += "   AND DLS_ID_CAB = "+Trim(Str(cCodId))
		cQuery += " ORDER BY 1
	EndIf 

	TCQUERY cQuery NEW ALIAS MAT_PRIMA

	//Verifica se o produto do SIP esta com saldo se não tiver alertar para alterar o codigo MP
	//isso acontece se o SIP esta atrasado. 
	aMatPriSal:={}
	dbSelectArea("MAT_PRIMA")
	dbGoTop()
	Do While !EOF()
		
		cQuery := " SELECT TOP 1 * 
		cQuery += "   FROM SB8010 
		cQuery += "  WHERE D_E_L_E_T_ = '' 
		cQuery += "    AND B8_LOTECTL = '"+MAT_PRIMA->ZH8_LOTECT+"' 
		cQuery += "	   AND B8_NUMLOTE = '"+MAT_PRIMA->ZH8_NUMLOT+"'
		cQuery += "	   AND B8_SALDO   > 0
		cQuery += "  ORDER BY R_E_C_N_O_

		TCQUERY cQuery NEW ALIAS MP_C_SALDO

		dbSelectArea("MP_C_SALDO")
		dbGoTop()
		//IF AllTrim(MP_C_SALDO->B8_PRODUTO) <> AllTrim(MAT_PRIMA->ZH8_CODMAT) 
			

		AADD(aMatPriSal,{ 	{"ZH8_ITEM"   ,StrZero(MAT_PRIMA->ZH8_ITEM,2,0)},; 
							{"ZH8_CODMAT" ,AllTrim(MP_C_SALDO->B8_PRODUTO) },;
							{"ZH8_COMLIQ" ,MP_C_SALDO->B8_YCOMLIQ },; 
							{"ZH8_ALTLIQ" ,MP_C_SALDO->B8_YALTLIQ },; 
							{"ZH8_ESPLIQ" ,MP_C_SALDO->B8_YESPLIQ },; 
							{"ZH8_TOTLIQ" ,MP_C_SALDO->B8_YTOTLIQ },;
							{"ZH8_COMBRU" ,MP_C_SALDO->B8_YCOMBRU },; 
							{"ZH8_ALTBRU" ,MP_C_SALDO->B8_YALTBRU },; 
							{"ZH8_ESPBRU" ,MP_C_SALDO->B8_YESPBRU },; 
							{"ZH8_TOTBRU" ,MP_C_SALDO->B8_YTOTBRU },;
							{"ZH8_COMORI" ,MP_C_SALDO->B8_YCOMLIQ },; 
							{"ZH8_ALTORI" ,MP_C_SALDO->B8_YALTLIQ },; 
							{"ZH8_ESPORI" ,MP_C_SALDO->B8_YESPLIQ },; 
							{"ZH8_TOTORI" ,MP_C_SALDO->B8_YTOTLIQ }; //Quantidade Liquida 
						}; 
			)
		//EndIf
			
		dbSelectArea("MP_C_SALDO")
		DbCloseArea()

		dbSelectArea("MAT_PRIMA")
		dbSkip()
	EndDo

	//If!Empty(aMatPriSal)
	//	Alert("Durante o processamento foi encontrado no S.I.P diferenças de Códigos de produtos (Com/Sem) Saldo. Alteração Automatica realizada!")
	//EndIf 

	dbSelectArea("MAT_PRIMA")
	dbGoTop()
	Do While !EOF()
		// Procura o item correspondente no array aMatPriSal
		cNovoCod  := ""
		cAvisoDes := ""

		vZH8_COMLIQ	:= 0
		vZH8_ALTLIQ	:= 0
		vZH8_ESPLIQ	:= 0
		vZH8_TOTLIQ	:= 0
		vZH8_COMBRU	:= 0
		vZH8_ALTBRU	:= 0
		vZH8_ESPBRU	:= 0
		vZH8_TOTBRU	:= 0
		vZH8_COMORI	:= 0
		vZH8_ALTORI	:= 0
		vZH8_ESPORI	:= 0
		vZH8_TOTORI	:= 0

		For nX := 1 To Len(aMatPriSal)
			If AllTrim(aMatPriSal[nX][1,2]) == StrZero(MAT_PRIMA->ZH8_ITEM,2,0)
				cNovoCod    := AllTrim(aMatPriSal[nX][2,2])
				
				vZH8_COMLIQ	:= aMatPriSal[nX][3 ,2]
				vZH8_ALTLIQ	:= aMatPriSal[nX][4 ,2]
				vZH8_ESPLIQ	:= aMatPriSal[nX][5 ,2]
				vZH8_TOTLIQ	:= aMatPriSal[nX][6 ,2]
				vZH8_COMBRU	:= aMatPriSal[nX][7 ,2]
				vZH8_ALTBRU	:= aMatPriSal[nX][8 ,2]
				vZH8_ESPBRU	:= aMatPriSal[nX][9 ,2]
				vZH8_TOTBRU	:= aMatPriSal[nX][10,2]
				vZH8_COMORI	:= aMatPriSal[nX][11,2]
				vZH8_ALTORI	:= aMatPriSal[nX][12,2]				
				vZH8_ESPORI	:= aMatPriSal[nX][13,2]
				vZH8_TOTORI	:= aMatPriSal[nX][14,2]
				Exit
			EndIf
		Next nX

		// Se encontrou código com saldo, substitui o código original
		If AllTrim(aMatPriSal[nX][2,2]) <> AllTrim(MAT_PRIMA->ZH8_CODMAT)
			cCodMat   := cNovoCod
			cAvisoDes := "<--[**CODIGO ALTERADO**] -"
		Else
			cCodMat 	:= TRIM(MAT_PRIMA->ZH8_CODMAT)
		EndIf
		
		AADD(aMatPri,{ 	{"ZH8_ITEM"   ,StrZero(MAT_PRIMA->ZH8_ITEM,2,0)},; 
						{"ZH8_CODMAT" ,TRIM(cCodMat              ) },; 
						{"ZH8_DESCMT" ,cAvisoDes+TRIM(MAT_PRIMA->ZH8_DESCMT) },; 
						{"ZH8_ENGENH" ,TRIM(MAT_PRIMA->ZH8_ENGENH) },; 
						{"ZH8_DESCEN" ,TRIM(MAT_PRIMA->ZH8_DESCEN) },; 
						{"ZH8_LOTECT" ,TRIM(MAT_PRIMA->ZH8_LOTECT) },; 
						{"ZH8_NUMLOT" ,TRIM(MAT_PRIMA->ZH8_NUMLOT) },; 
						{"ZH8_LOCAL"  ,TRIM(MAT_PRIMA->ZH8_LOCAL ) },; 
						{"ZH8_UM"     ,TRIM(MAT_PRIMA->ZH8_UM    ) },; 
						{"ZH8_COMLIQ" ,vZH8_COMLIQ 				   },; 
						{"ZH8_ALTLIQ" ,vZH8_ALTLIQ 				   },; 
						{"ZH8_ESPLIQ" ,vZH8_ESPLIQ 				   },; 
						{"ZH8_TOTLIQ" ,vZH8_TOTLIQ 				   },;
						{"ZH8_COMBRU" ,vZH8_COMBRU 				   },; 
						{"ZH8_ALTBRU" ,vZH8_ALTBRU 				   },; 
						{"ZH8_ESPBRU" ,vZH8_ESPBRU 				   },; 
						{"ZH8_TOTBRU" ,vZH8_TOTBRU 				   },;
						{"ZH8_COMORI" ,vZH8_COMORI 				   },; 
						{"ZH8_ALTORI" ,vZH8_ALTORI 				   },; 
						{"ZH8_ESPORI" ,vZH8_ESPORI 				   },; 
						{"ZH8_TOTORI" ,vZH8_TOTORI 				   },; //Quantidade Liquida	
						{"ZH8_COMPLE" ,MAT_PRIMA->COMPLEMTO  	   },; //INTERA 
						{"ZH8_COMITL" ,MAT_PRIMA->COMPRIMENTO	   },; //INTERA 
						{"ZH8_ALTITL" ,MAT_PRIMA->ALTURA 	 	   },; //INTERA 
						{"ZH8_ESPITL" ,MAT_PRIMA->ESPESSURA  	   },; //INTERA 
						{"ZH8_COMITB" ,MAT_PRIMA->COMPRIMENTO	   },; //INTERA 
						{"ZH8_ALTITB" ,MAT_PRIMA->ALTURA     	   },; //INTERA 
						{"ZH8_ESPITB" ,MAT_PRIMA->ESPESSURA  	   };  //INTERA 
						}; 
					)	

		dbSelectArea("MAT_PRIMA")
		dbSkip()
	EndDo 

	dbSelectArea("MAT_PRIMA")
	DbCloseArea()

	If oModelZH7:GetValue("ZH7_PROCES") == "S"
		//Query Produto acabado
		cQuery := " WITH Grupos AS (
		cQuery += "     SELECT 
		cQuery += "         BL_PRODUTO,
		cQuery += "         BL_LOTE,
		cQuery += "         BL_ESPESSURA,
		cQuery += "         CASE 
		cQuery += "             WHEN BL_ESPESSURA = '03CM' THEN '030'
		cQuery += "             WHEN BL_ESPESSURA = '02CM' THEN '020'
		cQuery += "             WHEN BL_ESPESSURA = '01CM' THEN '010'
		cQuery += "         END AS COD_ESP,
		cQuery += "         CAB_COD_ENG_PRO,
		cQuery += "         BL_COM,
		cQuery += "         BL_ALT,
		cQuery += "         MIN(BL_CHAPA) AS BL_CHAPA_INI,
		cQuery += "         COUNT(*) AS QTD_CHAPAS
		cQuery += "     FROM SIGAEIS..APP005_OP_DLS_BL AS BL
		cQuery += "     INNER JOIN SIGAEIS..APP005_OP_CAB AS OPCAB 
		cQuery += "         ON CAB_ID = BL_ID_CAB
		cQuery += "     WHERE BL.BL_D_E_L_E_T_ = ''
		cQuery += "       AND OPCAB.CAB_D_E_L_E_T_ = ''
		cQuery += "       AND BL_ID_CAB = "+Trim(Str(cCodId))
		cQuery += "     GROUP BY 
		cQuery += "         BL_PRODUTO, 
		cQuery += "         BL_LOTE, 
		cQuery += "         BL_ESPESSURA,
		cQuery += "         CAB_COD_ENG_PRO,
		cQuery += "         BL_COM,
		cQuery += "         BL_LARG,
		cQuery += "         BL_ALT
		cQuery += " )
		cQuery += " SELECT
		cQuery += "     DENSE_RANK() OVER (ORDER BY G.BL_PRODUTO, G.BL_LOTE) AS ZH9_ITEM,
		cQuery += "     ROW_NUMBER() OVER (
		cQuery += "         PARTITION BY G.BL_PRODUTO, G.BL_LOTE
		cQuery += "         ORDER BY G.BL_ESPESSURA
		cQuery += "     ) AS ZH9_SEQUEN,
		cQuery += " 
		cQuery += "     ZGData.B1_COD    AS ZH9_CODPA,
		cQuery += "     ZGData.B1_UM     AS ZH9_UM,
		cQuery += " 	ZGData.B1_DESC   AS ZH9_DESCPA,
		cQuery += "     G.BL_LOTE        AS ZH9_LOTECT,
		cQuery += "     ZGData.B1_LOCPAD AS ZH9_LOCAL,
		cQuery += "     
		cQuery += "     G.QTD_CHAPAS AS ZH9_QUANTI,
		cQuery += "     G.BL_COM AS ZH9_COMLIQ,
		cQuery += "     G.BL_ALT AS ZH9_ALTLIQ,
		cQuery += "     CASE 
		cQuery += " 		WHEN G.COD_ESP = '010' THEN 0.010
		cQuery += " 		WHEN G.COD_ESP = '020' THEN 0.020
		cQuery += " 		WHEN G.COD_ESP = '030' THEN 0.030
		cQuery += " 	END
		cQuery += " 	AS ZH9_ESPLIQ,
		cQuery += "     ROUND(G.BL_COM * G.BL_ALT, 5) AS ZH9_TOTLIQ,
		cQuery += " 
		cQuery += "     SB8.B8_YCOMBRU AS ZH9_COMBRU,
		cQuery += "     SB8.B8_YALTBRU AS ZH9_ALTBRU,
		cQuery += "     CASE 
		cQuery += " 		WHEN G.COD_ESP = '010' THEN 0.010
		cQuery += " 		WHEN G.COD_ESP = '020' THEN 0.020
		cQuery += " 		WHEN G.COD_ESP = '030' THEN 0.030
		cQuery += " 	END
		cQuery += " 	AS ZH9_ESPBRU,
		cQuery += "     ROUND(SB8.B8_YCOMBRU * SB8.B8_YALTBRU, 5) AS ZH9_TOTBRU,
		cQuery += " 
		cQuery += "     G.BL_CHAPA_INI
		cQuery += " FROM Grupos AS G
		cQuery += " 
		cQuery += " OUTER APPLY (
		cQuery += "     SELECT DISTINCT TOP 1 
		cQuery += "         SB1.B1_COD,
		cQuery += "         SB1.B1_UM,
		cQuery += "         SB1.B1_LOCPAD,
		cQuery += " 		SB1.B1_DESC
		cQuery += "     FROM DADOSADV_Q..ZG7010 AS ZG7
		cQuery += "     INNER JOIN DADOSADV_Q..ZG9010 AS ZG9 ON ZG7.ZG7_CODIGO = ZG9.ZG9_ROTEIR
		cQuery += "     INNER JOIN DADOSADV_Q..ZGA010 AS ZGA ON ZGA.ZGA_ROTEIR = ZG9.ZG9_ROTEIR AND ZGA.ZGA_PRODMP = ZG9.ZG9_PRODUT
		cQuery += "     INNER JOIN DADOSADV_Q..SB1010 AS SB1 ON SB1.B1_COD = ZGA.ZGA_PRODUT
		cQuery += "     INNER JOIN DADOSADV_Q..SB5010 AS SB5 ON SB1.B1_COD = SB5.B5_COD
		cQuery += "     WHERE ZG7.D_E_L_E_T_ = ''
		cQuery += "       AND ZG9.D_E_L_E_T_ = ''
		cQuery += "       AND ZGA.D_E_L_E_T_ = ''
		cQuery += "       AND SB1.D_E_L_E_T_ = ''
		cQuery += "       AND SB5.D_E_L_E_T_ = ''
		cQuery += "       AND SB5.B5_YCODMED = G.COD_ESP
		cQuery += "       AND ZGA.ZGA_PRODMP = G.BL_PRODUTO
		cQuery += "       AND ZG7.ZG7_CODIGO = G.CAB_COD_ENG_PRO
		cQuery += " ) AS ZGData
		cQuery += " OUTER APPLY (
		cQuery += "     SELECT TOP 1 
		cQuery += "         SB8.B8_YCOMBRU, 
		cQuery += "         SB8.B8_YALTBRU
		cQuery += "     FROM DADOSADV_Q..SB8010 AS SB8
		cQuery += "     WHERE SB8.D_E_L_E_T_ = ''
		cQuery += "       AND SB8.B8_PRODUTO = TRIM(G.BL_PRODUTO)
		cQuery += "       AND SB8.B8_LOTECTL = TRIM(G.BL_LOTE)
		cQuery += "       AND LEFT(SB8.B8_PRODUTO, 2) = 'BL'
		cQuery += " ) AS SB8
		cQuery += " ORDER BY 
		cQuery += "     G.BL_PRODUTO,
		cQuery += "     G.BL_LOTE,
		cQuery += "     ZH9_SEQUEN;
	Else
		cQuery := " WITH Grupos AS (
		cQuery += "      SELECT 
		cQuery += "          DLS_CODPRO  BL_PRODUTO,
		cQuery += "          DLS_LOTEORI BL_LOTE,
		cQuery += "          DLS_ESPLIQ  BL_ESPESSURA,
		cQuery += "          CASE 
		cQuery += "              WHEN DLS_ESPLIQ = 0.03 THEN '030'
		cQuery += "              WHEN DLS_ESPLIQ = 0.02 THEN '020'
		cQuery += "              WHEN DLS_ESPLIQ = 0.01 THEN '010'
		cQuery += "          END AS COD_ESP,
		cQuery += "          CAB_COD_ENG_PRO,
		cQuery += "          DLS_COMLIQ BL_COM,
		cQuery += "          DLS_ALTLIQ BL_ALT,
		cQuery += " 		 DLS_ALTBRU BL_ALTB,
		cQuery += " 		 DLS_COMBRU BL_COMPB,
		cQuery += "          DLS_CHAPA AS BL_CHAPA_INI,
		cQuery += "          1 AS QTD_CHAPAS
		cQuery += "      FROM SIGAEIS..APP005_OP_DLS AS DLS
		cQuery += "      INNER JOIN SIGAEIS..APP005_OP_CAB AS OPCAB 
		cQuery += "          ON CAB_ID = DLS_ID_CAB
		cQuery += "      WHERE DLS.DLS_D_E_L_E_T_ = ''
		cQuery += "        AND OPCAB.CAB_D_E_L_E_T_ = ''
		cQuery += "        AND DLS_ID_CAB = "+Trim(Str(cCodId))
		cQuery += "  )
		cQuery += "  SELECT
		cQuery += "      DENSE_RANK() OVER (ORDER BY G.BL_PRODUTO, G.BL_LOTE,G.BL_CHAPA_INI) AS ZH9_ITEM,
		cQuery += "      ROW_NUMBER() OVER (
		cQuery += "          PARTITION BY G.BL_PRODUTO, G.BL_LOTE,G.BL_CHAPA_INI
		cQuery += "          ORDER BY G.BL_ESPESSURA
		cQuery += "      ) AS ZH9_SEQUEN,
		cQuery += "  
		cQuery += "      ZGData.B1_COD							AS ZH9_CODPA,
		cQuery += "      ZGData.B1_UM							AS ZH9_UM,
		cQuery += "  	 ZGData.B1_DESC							AS ZH9_DESCPA,
		cQuery += "      G.BL_LOTE								AS ZH9_LOTECT,
		cQuery += "      ZGData.B1_LOCPAD						AS ZH9_LOCAL,
		cQuery += "      G.QTD_CHAPAS							AS ZH9_QUANTI,
		cQuery += "      G.BL_COM								AS ZH9_COMLIQ,
		cQuery += "      G.BL_ALT								AS ZH9_ALTLIQ,
		cQuery += "      CASE 
		cQuery += "  		WHEN G.COD_ESP = '010' THEN 0.010
		cQuery += "  		WHEN G.COD_ESP = '020' THEN 0.020
		cQuery += "  		WHEN G.COD_ESP = '030' THEN 0.030
		cQuery += "  	 END									AS ZH9_ESPLIQ,
		cQuery += "      ROUND(G.BL_COM * G.BL_ALT, 5)			AS ZH9_TOTLIQ,
		cQuery += "  
		cQuery += "      G.BL_COMPB								AS ZH9_COMBRU,
		cQuery += "      G.BL_ALTB								AS ZH9_ALTBRU,
		cQuery += "      CASE 
		cQuery += "  		WHEN G.COD_ESP = '010' THEN 0.010
		cQuery += "  		WHEN G.COD_ESP = '020' THEN 0.020
		cQuery += "  		WHEN G.COD_ESP = '030' THEN 0.030
		cQuery += "  	END										AS ZH9_ESPBRU,
		cQuery += "      ROUND(G.BL_COMPB * G.BL_ALTB, 5)		AS ZH9_TOTBRU,
		cQuery += "  
		cQuery += "      G.BL_CHAPA_INI
		cQuery += "  FROM Grupos AS G
		cQuery += "  
		cQuery += "  OUTER APPLY (
		cQuery += "   SELECT DISTINCT TOP 1 
		cQuery += "          SB1.B1_COD,
		cQuery += "          SB1.B1_LOCPAD,
		cQuery += "  		 SB1.B1_DESC,
		cQuery += "  		 SB1.B1_UM
		cQuery += "      FROM DADOSADV_Q..ZG7010 AS ZG7
		cQuery += "      INNER JOIN DADOSADV_Q..ZG9010 AS ZG9 ON ZG7.ZG7_CODIGO = ZG9.ZG9_ROTEIR
		cQuery += "      INNER JOIN DADOSADV_Q..ZGA010 AS ZGA ON ZGA.ZGA_ROTEIR = ZG9.ZG9_ROTEIR AND ZGA.ZGA_PRODMP = ZG9.ZG9_PRODUT
		cQuery += "      INNER JOIN DADOSADV_Q..SB1010 AS SB1 ON SB1.B1_COD = ZGA.ZGA_PRODUT
		cQuery += "      INNER JOIN DADOSADV_Q..SB5010 AS SB5 ON SB1.B1_COD = SB5.B5_COD
		cQuery += "      WHERE ZG7.D_E_L_E_T_ = ''
		cQuery += "        AND ZG9.D_E_L_E_T_ = ''
		cQuery += "        AND ZGA.D_E_L_E_T_ = ''
		cQuery += "        AND SB1.D_E_L_E_T_ = ''
		cQuery += "        AND SB5.D_E_L_E_T_ = ''
		cQuery += "        AND SB5.B5_YCODMED = G.COD_ESP
		cQuery += "        AND ZGA.ZGA_PRODMP = G.BL_PRODUTO
		cQuery += "        AND ZG7.ZG7_CODIGO = G.CAB_COD_ENG_PRO
		cQuery += "  ) AS ZGData
		cQuery += "  
		cQuery += "  OUTER APPLY (
		cQuery += "      SELECT TOP 1 
		cQuery += "          SB8.B8_YCOMBRU, 
		cQuery += "          SB8.B8_YALTBRU
		cQuery += "      FROM DADOSADV_Q..SB8010 AS SB8
		cQuery += "      WHERE SB8.D_E_L_E_T_ = ''
		cQuery += "        AND SB8.B8_PRODUTO = TRIM(G.BL_PRODUTO)
		cQuery += "        AND SB8.B8_LOTECTL = TRIM(G.BL_LOTE)
		cQuery += "  	   AND SB8.B8_NUMLOTE = TRIM(G.BL_CHAPA_INI)
		cQuery += "  ) AS SB8
		cQuery += "  ORDER BY 
		cQuery += "      G.BL_PRODUTO,
		cQuery += "      G.BL_LOTE,
		cQuery += "      ZH9_SEQUEN		
	EndIf

	TCQUERY cQuery NEW ALIAS PROD_ACABA

	dbSelectArea("PROD_ACABA")
	dbGoTop()
	Do While !EOF()

			If oModelZH7:GetValue("ZH7_PROCES") == "S"
				AADD(aMatAcab, {{"ZH9_ITEM"   ,StrZero(PROD_ACABA->ZH9_ITEM  ,2)},; 
								{"ZH9_SEQUEN" ,StrZero(PROD_ACABA->ZH9_SEQUEN,3)},; 
								{"ZH9_CODPA"  ,TRIM(PROD_ACABA->ZH9_CODPA) },; 
								{"ZH9_UM"     ,TRIM(PROD_ACABA->ZH9_UM)    },; 
								{"ZH9_DESCPA" ,TRIM(PROD_ACABA->ZH9_DESCPA)},; 
								{"ZH9_LOTECT" ,TRIM(PROD_ACABA->ZH9_LOTECT)},; 
								{"ZH9_LOCAL"  ,TRIM(PROD_ACABA->ZH9_LOCAL) },; 
								{"ZH9_SUBINI" ,TRIM(PROD_ACABA->BL_CHAPA_INI) },; 
								{"ZH9_QUANTI" ,PROD_ACABA->ZH9_QUANTI},; 
								{"ZH9_COMLIQ" ,PROD_ACABA->ZH9_COMLIQ},; 
								{"ZH9_ALTLIQ" ,PROD_ACABA->ZH9_ALTLIQ},; 
								{"ZH9_ESPLIQ" ,PROD_ACABA->ZH9_ESPLIQ},; 
								{"ZH9_TOTLIQ" ,PROD_ACABA->ZH9_TOTLIQ},; 
								{"ZH9_COMBRU" ,PROD_ACABA->ZH9_COMBRU},; 
								{"ZH9_ALTBRU" ,PROD_ACABA->ZH9_ALTBRU},; 
								{"ZH9_ESPBRU" ,PROD_ACABA->ZH9_ESPBRU},; 
								{"ZH9_TOTBRU" ,PROD_ACABA->ZH9_TOTBRU} ; 
							}; 
					)
			Else
				AADD(aMatAcab, {{"ZH9_ITEM"   ,StrZero(PROD_ACABA->ZH9_ITEM  ,2)},; 
								{"ZH9_SEQUEN" ,StrZero(PROD_ACABA->ZH9_SEQUEN,3)},; 
								{"ZH9_CODPA"  ,TRIM(PROD_ACABA->ZH9_CODPA) },; 
								{"ZH9_UM"     ,TRIM(PROD_ACABA->ZH9_UM)    },; 
								{"ZH9_DESCPA" ,TRIM(PROD_ACABA->ZH9_DESCPA)},; 
								{"ZH9_LOTECT" ,TRIM(PROD_ACABA->ZH9_LOTECT)},; 
								{"ZH9_LOCAL"  ,TRIM(PROD_ACABA->ZH9_LOCAL) },; 
								{"ZH9_NUMLOT" ,TRIM(PROD_ACABA->BL_CHAPA_INI)},;  //Quando é uma continuação de Bloco INTERA (CHAPA INICIAL COLOCAR AQUI)				
								{"ZH9_QUANTI" ,PROD_ACABA->ZH9_QUANTI},; 
								{"ZH9_COMLIQ" ,PROD_ACABA->ZH9_COMLIQ},; 
								{"ZH9_ALTLIQ" ,PROD_ACABA->ZH9_ALTLIQ},; 
								{"ZH9_ESPLIQ" ,PROD_ACABA->ZH9_ESPLIQ},; 
								{"ZH9_TOTLIQ" ,PROD_ACABA->ZH9_TOTLIQ},; 
								{"ZH9_COMBRU" ,PROD_ACABA->ZH9_COMBRU},; 
								{"ZH9_ALTBRU" ,PROD_ACABA->ZH9_ALTBRU},; 
								{"ZH9_ESPBRU" ,PROD_ACABA->ZH9_ESPBRU},; 
								{"ZH9_TOTBRU" ,PROD_ACABA->ZH9_TOTBRU} ; 
							}; 
					)
			EndIf

		dbSelectArea("PROD_ACABA")
		dbSkip()
	EndDo 

	dbSelectArea("PROD_ACABA")
	DbCloseArea()

	For nX := 1 To Len(aMatPri)
		nItemPri := Val(aMatPri[nX, 1, 2]) // ZH8_ITEM
		aMatPriItem := {}
		aDadosTemp  := {}
		aMatPriItem := { aMatPri[nX] }     // monta um conjunto com apenas esse item
		aMatAcabFiltrado := {}             // zera o array de acabados

		// Filtra produtos acabados correspondentes a este item
		For nJ := 1 To Len(aMatAcab)
			nItemAcab := Val(aMatAcab[nJ, 1, 2]) // ZH9_ITEM
			If nItemAcab == nItemPri
				AADD(aMatAcabFiltrado, aMatAcab[nJ])
			EndIf
		Next nJ

		// Se encontrou produtos acabados relacionados, chama a rotina
		If Len(aMatAcabFiltrado) > 0
			aDadosTemp := { aMatPriItem, aMatAcabFiltrado }
			U_DADOSOP(@oModelZH8, @oModelZH9, aDadosTemp)
		EndIf
	Next nX

	oModelZH8:GoLine(1)
	oModelZH9:GoLine(1)

	//**********************************************************************************************			
	//CABEÇALHO OPERAÇÕES
	//**********************************************************************************************
	//ZGH
	/*

	*/
	cQuery := "	SELECT DISTINCT
	cQuery += "    ZG8_SEQUEN,ZG8_ORDEM,ZG8_OPERAC,ZG8_QTDHOR,ZG6_DESCRI,OPCAB.*
    cQuery += " FROM SIGAEIS..APP005_OP_CAB OPCAB  								  
	cQuery += " 							  INNER JOIN DADOSADV_Q..ZG8010 ZG8 ON (TRIM(CAB_COD_ENG_PRO) = TRIM(ZG8_ROTEIR) )
	cQuery += " 							  INNER JOIN DADOSADV_Q..ZG6010 ZG6 ON (ZG6_CODIGO = ZG8_OPERAC)
    cQuery += " WHERE OPCAB.CAB_D_E_L_E_T_  = ''
	cQuery += " AND ZG8.D_E_L_E_T_ = ''
	cQuery += " AND ZG6.D_E_L_E_T_ = ''
    cQuery += " AND CAB_ID = "+Trim(Str(cCodId))
	cQuery += " AND (ZG8_OPERAC = (SELECT CAB_SOPERACAO FROM SIGAEIS..APP005_OP_CAB FIO WHERE FIO.CAB_D_E_L_E_T_ = '' AND CAB_ID =" + Trim(Str(cCodId)) + " )
	cQuery += " 		OR
	cQuery += " 		(ZG8_SEQUEN = '01' AND ZG8_ORDEM = '01'))
	cQuery += "  ORDER BY 1,2

    //cQuery := "SELECT * FROM SIGAEIS..APP005_OP_CAB WHERE CAB_D_E_L_E_T_ = '' AND CAB_ID     = "+Trim(Str(cCodId))
    TCQUERY cQuery NEW ALIAS OP_CAB

	dbSelectArea("OP_CAB")
	dbGoTop()
	oModeLZH7 := oModel:GetModel("ZH7MASTER") 
	//Datas da OP
	oModelZH7:SetValue("ZH7_EMISSA",sToD(OP_CAB->CAB_DTINI     ) )
	oModelZH7:SetValue("ZH7_DATPRI",sToD(OP_CAB->CAB_DTINI     ) )
	oModelZH7:SetValue("ZH7_DATPRF",sToD(OP_CAB->CAB_DTFIM     ) )

	Do While !Eof()

		nRegZGH   := nRegZGH + 1

		dbSelectArea("OP_CAB")
		dbSkip()
	EndDo 

	dbSelectArea("OP_CAB")
	dbGoTop()
	If !EOF() 
		oModeLZGH := oModel:GetModel("ZGHDETAIL")
		oView := FwViewactive()

		//If oModel:getOperation() == MODEL_OPERATION_UPDATE
		nX := 0
		For nX := 1 To nRegZGH

			If nX == 1
				oModelZGH:GoLine(nX)
			Else
				oModelZGH:AddLine()
			EndIf

			oModelZGH:SetValue("ZGH_SEQUEN",AllTrim(OP_CAB->ZG8_SEQUEN))
			oModelZGH:SetValue("ZGH_ORDEM" ,AllTrim(OP_CAB->ZG8_ORDEM))
			oModelZGH:SetValue("ZGH_OPERAC",AllTrim(OP_CAB->ZG8_OPERAC))
			oModelZGH:SetValue("ZGH_RECURS",AllTrim(OP_CAB->CAB_CODEQUIP_REC))

			oModelZGH:SetValue("ZGH_DATAPO",sToD(OP_CAB->CAB_DTINI     ))
			oModelZGH:SetValue("ZGH_DATINI",sToD(OP_CAB->CAB_DTINI     ))
			oModelZGH:SetValue("ZGH_HORINI",AllTrim(OP_CAB->CAB_HORINI ))
			oModelZGH:SetValue("ZGH_DATFIM",sToD(OP_CAB->CAB_DTFIM     ))
			oModelZGH:SetValue("ZGH_HORFIM",AllTrim(OP_CAB->CAB_HORFIM ))
			
			oModelZGH:SetValue("ZGH_HRINI",OP_CAB->CAB_HORIMINI )
			oModelZGH:SetValue("ZGH_HRFIM",OP_CAB->CAB_HORIMFIM )

			dbSelectArea("OP_CAB")
			dbSkip()
		Next

		oModeLZH7 := oModel:GetModel("ZH7MASTER") 
		oModelZH7:SetValue("ZH7_XID"   ,cCodId)	

		dbSelectArea("OP_CAB")
		dbGoTop()
		oModelZH7:SetValue("ZH7_RECURS",AllTrim(OP_CAB->CAB_CODEQUIP_REC) )
		
		cCodEng := AllTrim( AllTrim(OP_CAB->CAB_COD_ENG_PRO))	

		oView:Refresh("ZH7MASTER")

		oModelZGH:GoLine(1)
		If !isBlind()
			oView:Refresh("ZGHDETAIL")
		EndIf

		oModelZGH:GoLine(1)

	Endif

	//
	//**********************************************************************************************			
	//// Operações x Produto Acabado
	//**********************************************************************************************
	oModelZHL := oModel:GetModel("ZHLDETAIL")
	nRegZHL   := oModelZHL:Length()

	For nI := 1 To nRegZHL
		oModelZHL:GoLine(nI)
		If !oModelZHL:IsDeleted()
			oModelZHL:DeleteLine()  // Deleta a linha atual
		EndIf
	Next nI
	oModelZHL:GoLine(1)

	//**********************************************************************************************			
	//PARADAS 
	//**********************************************************************************************
    cQuery := "SELECT * FROM SIGAEIS..APP005_OP_PAR WHERE PAR_D_E_L_E_T_ = '' AND PAR_ID_CAB = "+Trim(Str(cCodId))+ " ORDER BY PAR_ID"
    TCQUERY cQuery NEW ALIAS OP_PAR

	dbSelectArea("OP_PAR")
	dbGoTop()

	If !EOF() 
		oModeLSH6 := oModel:GetModel("SH6DETAIL")
		nRegSH6   := oModelSH6:Length()

		oView := FwViewactive()
		Do While !Eof()

			nX := oModelSH6:Length()
		
			if Empty(oModelSH6:GetValue("H6_MOTIVO"))
				oModelSH6:GoLine(nX)
			Else
				oModelSH6:AddLine()
			EndIf
			
			oModelSH6:SetValue("H6_RECURSO", AllTrim(OP_PAR->PAR_RECURSO		))
			oModelSH6:SetValue("H6_MOTIVO" , AllTrim(OP_PAR->PAR_CODMOTIVO		))
			oModelSH6:SetValue("H6_DTAPONT", sTod(AllTrim(OP_PAR->PAR_DTAPONT)	))
			oModelSH6:SetValue("H6_DATAINI", sTod(AllTrim(OP_PAR->PAR_DATAINI)	))
			oModelSH6:SetValue("H6_HORAINI", AllTrim(OP_PAR->PAR_HORAINI		))
			oModelSH6:SetValue("H6_DATAFIN", StoD(AllTrim(OP_PAR->PAR_DATAFIN)	))
			oModelSH6:SetValue("H6_HORAFIN", AllTrim(OP_PAR->PAR_HORAFIN		)) 
			oModelSH6:SetValue("H6_OPERADO", LEFT(AllTrim(OP_PAR->PAR_OPERADOR),10))
			//oModelSH6:SetValue("H6_OBSERVA", AllTrim(OP_PAR->PAR_RECURSO))

			dbSelectArea("OP_PAR")
			dbSkip()

			oModelSH6:GoLine(1)
			If !isBlind()
				oView:Refresh("SH6DETAIL")
			EndIf

		EndDo 
	EndIf

	//
	//**********************************************************************************************			
	//CUSTOS INDIRETOS
	//**********************************************************************************************
	//oModel:SetRelation('MODDETAIL', {{'ZGI_FILIAL','FwXFilial("ZGI")'}, {'ZGI_OP','ZH7_NUM'}, {'ZGI_SEQUEN','ZGH_SEQUEN'} }, ZGI->( IndexKey( 1 ) ) )

	oModeLZGI := oModel:GetModel("ZGIDETAIL")

	nX := oModelZGH:Length()
	For nX := 1 To nRegZGH	

		oModelZGH:GoLine(nX)

		If oModelZGH:GetValue("ZGH_SEQUEN") == '01' .AND. oModelZGH:GetValue("ZGH_ORDEM") == '01'
			cQuery := "  SELECT *   
			cQuery += "    FROM DADOSADV_Q..ZGB010  ZGB INNER JOIN DADOSADV_Q..SB1010 SB1 ON (ZGB_PRODUT = B1_COD)
			cQuery += "   WHERE ZGB.D_E_L_E_T_ = ''    
			cQuery += "     AND SB1.D_E_L_E_T_ = ''
			cQuery += " 	AND SB1.B1_TIPO = 'MO'
			cQuery += " 	AND ZGB_ROTEIR = '"+ cCodEng +"' 
			cQuery += " 	AND ZGB_SEQUEN = '"+ AllTrim( oModelZGH:GetValue("ZGH_SEQUEN") ) +"'
		Else

			cQuery := "  SELECT *   
			cQuery += "    FROM DADOSADV_Q..ZGB010  ZGB INNER JOIN DADOSADV_Q..SB1010 SB1 ON (ZGB_PRODUT = B1_COD)
			cQuery += "   WHERE ZGB.D_E_L_E_T_ = ''    
			cQuery += "     AND SB1.D_E_L_E_T_ = ''
			cQuery += " 	AND SB1.B1_TIPO = 'MO'
			cQuery += " 	AND ZGB_ROTEIR = '"+ cCodEng +"' 
			cQuery += " 	AND ZGB_SEQUEN = '"+ AllTrim( oModelZGH:GetValue("ZGH_SEQUEN") ) +"'
			cQuery += "     AND ZGB_PRODUT = '"+ AllTrim(OP_CAB->CAB_SPRODUTO) +"'
		EndIf

		TCQUERY cQuery NEW ALIAS INS_IND

		dbSelectArea("INS_IND")
		dbGoTop()

		oModelMOD := oModel:GetModel("MODDETAIL")
		nY:=0
		Do While !Eof()
			
			nY := nY + 1

			If nY == 1
				oModelMOD:GoLine(1)
			Else
				oModelMOD:AddLine()
			EndIf
			//oModelZGH:GoLine(nRegZGI)
			oModelMOD:SetValue("ZGI_PRODUT", AllTrim(INS_IND->ZGB_PRODUT	))
			oModelMOD:SetValue("ZGI_QTDE"  , 1		)
			oModelMOD:SetValue("ZGI_LOCAL" , AllTrim(INS_IND->ZGB_LOCAL		))
			oModelMOD:SetValue("ZGI_UM"    , AllTrim(INS_IND->ZGB_UM		))
		
			dbSelectArea("INS_IND")
			dbSkip()
		EndDo 

		INS_IND->(DbCloseArea())

	Next nX

	If !isBlind()
		oView:Refresh("MODDETAIL")
	EndIf


	//
	//**********************************************************************************************			
	//INSUMOS
	//**********************************************************************************************
	cQuery := "SELECT * FROM SIGAEIS..APP005_OP_INS WHERE INS_ID_CAB = "+Alltrim(Str(cCodId))+ " AND INS_D_E_L_E_T_='' ORDER BY INS_ID"
    TCQUERY cQuery NEW ALIAS OP_INS

	dbSelectArea("OP_INS")
	dbGoTop()

	If !EOF() 

		// Monta um array com os produtos retornados pela query
		aProdutos := {}

		While !EOF()
			AAdd(aProdutos, {AllTrim(OP_INS->INS_PRODUTO),OP_INS->INS_QTDTOT,.F.}) // campo do produto em OP_INS

			dbSelectArea("OP_INS")
			dbSkip()
		EndDo

		// Pega o modelo da grid
		oModelZGI := oModel:GetModel("ZGIDETAIL")
		nRegZGI   := oModelZGI:Length()

		For nI := 1 To Len(aProdutos)
			If nI == 1
				oModelZGI:GoLine(nI)
				oModelZGI:SetValue("ZGI_PRODUT", aProdutos[nI][1] )
				oModelZGI:SetValue("ZGI_QTDE"  , aProdutos[nI][2] )
				oModelZGI:SetValue("ZGI_LOCAL" , "20"             )
			Else
				oModelZGI:AddLine()
				oModelZGI:SetValue("ZGI_PRODUT", aProdutos[nI][1] )
				oModelZGI:SetValue("ZGI_QTDE"  , aProdutos[nI][2] )
				oModelZGI:SetValue("ZGI_LOCAL" , "20"             )
			EndIf
		Next

		/*
		iF nRegZGI == 1 .AND. AllTrim(oModelZGI:GetValue("ZGI_PRODUT")) == "" .And. Len(aProdutos) <> 0

			For nI := 1 To Len(aProdutos)
				If nI == 1
					oModelZGI:GoLine(nI)
					oModelZGI:SetValue("ZGI_PRODUT", aProdutos[nI][1] )
					oModelZGI:SetValue("ZGI_QTDE"  , aProdutos[nI][2] )
					oModelZGI:SetValue("ZGI_LOCAL" , "20"             )
				Else
					oModelZGI:AddLine()
					oModelZGI:SetValue("ZGI_PRODUT", aProdutos[nI][1] )
					oModelZGI:SetValue("ZGI_QTDE"  , aProdutos[nI][2] )
					oModelZGI:SetValue("ZGI_LOCAL" , "20"             )
				EndIf
			Next
			//oModelZGI:GoLine(1)
		Else
			// Percorre a grid de trás para frente
			For nI := nRegZGI To 1 Step -1
				oModelZGI:GoLine(nI)

				If !oModelZGI:IsDeleted()
					cProdGrid := AllTrim(oModelZGI:GetValue("ZGI_PRODUT"))

					// Busca o produto da grid dentro do array
					nPos := AScan(aProdutos, {|x| x[1] == cProdGrid })

					If nPos == 0
						// Produto não existe na query ? deletar linha
						oModelZGI:DeleteLine()
					Else
						// Produto existe ? atualizar quantidade
						oModelZGI:SetValue("ZGI_QTDE", aProdutos[nPos][2])
						aProdutos[nPos][3] := .T.
					EndIf
				EndIf
			Next

			// Depois de percorrer a grid, verifica se existe produto no array que não está na grid
			For nI := 1 To Len(aProdutos)
				// Procura o produto do array na grid
				If aProdutos[nI][3] == .F.
					// Se não encontrou na grid, precisa adicionar
					oModelZGI:AddLine()
					oModelZGI:SetValue("ZGI_PRODUT", aProdutos[nI][1])
					oModelZGI:SetValue("ZGI_QTDE"  , aProdutos[nI][2])
				EndIf
			Next
		EndIf
		*/
		// Atualiza a tela se não estiver em modo cego
		oView := FwViewActive()
		If !IsBlind()
			oView:Refresh("ZGIDETAIL")
		EndIf

	Else
		//SE NÃO HOUVER NENHUM INSUMO APONTADO NA OP 
		//O SISTEMA DEVE DELETAR TODAS AS LINHAS
		oModelZGI := oModel:GetModel("ZGIDETAIL") // Grid de Insumos
		nRegZGI   := oModelZGI:Length()           // Número de linhas

		// Loop de trás para frente para evitar problemas ao deletar linhas
		For nI := nRegZGI TO 1 STEP -1
			oModelZGI:GoLine(nI)
			If !oModelZGI:IsDeleted()
				oModelZGI:DeleteLine()  // Deleta a linha atual
			EndIf
		Next

		// Atualiza a tela se não estiver em modo cego
		oView := FwViewActive()
		If !IsBlind()
			oView:Refresh("ZGIDETAIL")
		EndIf

	EndIf

	OP_CAB->(DbCloseArea())
    OP_PAR->(DbCloseArea())
	OP_INS->(DbCloseArea())
	
	oModelZH8:GoLine(1)
	oModelZH9:GoLine(1)
	oModelZGI:GoLine(1)
	oModelSH6:GoLine(1) 
	oModelZGH:GoLine(1) 
	oModelZGI:GoLine(1) 
	oModelMOD:GoLine(1) 
	
    lValid := .T.
Else
    Alert("Código em Branco, ação não executada!")
EndIf 

Return(lValid)


User Function UGR045V(cCodPro,cCodDep,nQtd,oModel)
/**************************************************************************************************************
*  VALIDAÇÃO = ZGI_QTDE ZGI_PRODUT ZGI_LOCAL // 
*  Esta validação é chamada no campo ZGI_QTDE  para validar o estoque.
*  u_UGR045V(trim(FWFldGet("ZGI_PRODUT")),trim(FWFldGet("ZGI_LOCAL")),FWFldGet("ZGI_QTDE") )
***/
Local lRet := .T.
Local nSaldoAtu := 0

dbSelectArea("SB2")
dbSetOrder(1)
dbSeek(xFilial("SB2") + cCodPro + cCodDep) 
nSaldoAtu := CalcEst( cCodPro,cCodDep,dDataBASE,xFilial("SB2")) [1] 

If nSaldoAtu < nQtd
	lRet := .F.
	//Alert("Quantidade indisponível!")
	oModel:SetErrorMessage("",,oModel:GetId(),"","GROA044","Quantidade indisponível!")
	//VALOR ENCONTRADO NO SALDO
	FwFldPut("ZGI_QTDE", nSaldoAtu)

	If !Empty(cCodPro)
		dbSelectArea("SB1")
		dbSetOrder(1)
		dbSeek(xFilial("SB1")+ cCodPro)
		If SB1->B1_RASTRO = 'N'
			MaViewSB2(cCodPro,xFilial("SB1"))
		Else
			F4Lote(,,,   '',cCodPro,cCodDep,NIL,'',1)
		EndIf
	EndIf
EndIf

Return(lRet)


Static Function ftempoS()
/**************************************************************************************************************
*
*
***/
Local aArea := GetArea()
Local nret  := 0

DbSelectArea("ZGH")
DbSetOrder(1)
DbSeek(xFilial("ZGH")+ZGI->ZGI_OP+ZGI->ZGI_SEQUEN )
Do while !Eof() .and. ZGH_FILIAL == xFilial("ZGH") .and. ZGH_OP == ZGI->ZGI_OP .and. ZGH_SEQUEN == ZGI->ZGI_SEQUEN
	nret += ZGH->ZGH_HRFIM - ZGH->ZGH_HRINI
	DbSkip()
EndDo
RestArea(aArea)

Return(ABS(nret))

Static Function ftempo()
/**************************************************************************************************************
*
*
***/
Local aArea := GetArea()
Local cSql  := ""
Local nret  := 0
	
csql := " SELECT ZGH_TOTHRA"
csql += " from " + RetSqlName("ZGH")+" ZGH WITH(NOLOCK) "
csql +=  " where ZGH.ZGH_FILIAL =  '"+xFilial("ZGH")+"' "
csql +=  " and ZGH.ZGH_OP = '" + ZGI->ZGI_OP +"'"
csql +=  " and ZGH.ZGH_SEQUEN = '" + ZGI->ZGI_SEQUEN +"'"
csql +=  " and ZGH.D_E_L_E_T_ = ' '  "

TcQuery csql New Alias "ctrabalho"
DbGotop()
	
Do while !Eof()
	nret :=  SomaHoras( nret, ctrabalho->ZGH_TOTHRA )
	DbSkip()
EndDo

ctrabalho->(DbCloseArea())
csql := " SELECT H6_TEMPO,H6_TIPO  "
csql += " from " + RetSqlName("SH6")+" SH6 WITH(NOLOCK)"
csql +=  " where SH6.H6_FILIAL =  '"+xFilial("SH6")+"' "
csql +=  " and SH6.H6_OP = '" + ZH7->ZH7_NUM +"'"
csql +=  " and SH6.D_E_L_E_T_ = ' '  "
TcQuery csql New Alias "ctrabalho"
DbGotop()

Do while !Eof()
	If ctrabalho->H6_TIPO="I"
		nret :=  SubHoras( nret, ctrabalho->H6_TEMPO )
	EndIf
	DbSkip()
EndDo
ctrabalho->(DbCloseArea())
RestArea(aArea)

Return(ABS( ((((nret - int(nret)) * 100)/60) )  + int(nret) ))
