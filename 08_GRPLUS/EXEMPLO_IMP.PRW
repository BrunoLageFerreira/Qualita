#INCLUDE "protheus.CH"
#INCLUDE "FWMVCDEF.CH"
#Include "Parmtype.ch"
#INCLUDE "TOTVS.CH"
#INCLUDE "FWEditPanel.CH"
#INCLUDE "TOPCONN.CH"
#include "tbiconn.ch"

/*/{Protheus.doc} GTADOS
(long_description)
Rotina para preencher os dados na rotina de apontamento de insumo. ela vai preencher os campos na grid
@type user function
@author user
@since 17/10/2025
@version version
@param param_name, param_type, param_descr
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function GTDADOS()

	Local oView  	:= FwViewActive()
	Local oModel    := FWModelActive()
	Local oModelZH7 := oModel:GetModel("ZH7MASTER")
	Local oModelZH8 := oModel:GetModel("ZH8DETAIL")
	Local oModelZH9 := oModel:GetModel("ZH9DETAIL")
	Local nOperatio := oModel:GetOperation()
	Local cCodId    := oModelZH7:GetValue("ZH7_CODID")
	Local aDadosOp  := {}
	Local aMatPri   := {}
	Local aMatAcab  := {}

	If (type("__lAuto")=="L".and. __lAuto)
		__lAuto := .F.
		Return .t.
	EndIf

	//Esse clearData so pode ser utilizado no incluir porque ele limpa os dados da tela.
	//Se for em alterar ele não limpa os dados do banco.
	If nOperatio == MODEL_OPERATION_INSERT
		oModelZH8:ClearData() // Materia prima
		oModelZH9:ClearData() // Materia prima x Produto Acabado
	EndIf

	if cCodId == '001' // Exemplo de uma serrada.

		M->ZH7_RECURS := "ESTE01"
		M->ZH7_DATPRF := STOD("20251017")
		M->ZH7_EMISSA := STOD("20251017")
		M->ZH7_DATPRI := STOD("20251017")

		aMatPri  := {}
		aMatAcab := {}

		//Adicionando a materia prima
		AADD(aMatPri,{{"ZH8_ITEM","01"}, {"ZH8_CODMAT","BLAMOU"}, {"ZH8_DESCMT","BLOCO DE GRANITO AMARELO OURO BRASIL "},;
			{"ZH8_ENGENH","SEBLO2"},{"ZH8_DESCEN", "1.1. SERRADA MULTIFIO PADRÃO"}, {"ZH8_LOTECT","202404B"}, {"ZH8_NUMLOT",""},;
			{"ZH8_LOCAL","02"},{"ZH8_UM","M3"},{"ZH8_COMLIQ",3.150},{"ZH8_ALTLIQ",1.900},{"ZH8_ESPLIQ",0.130},{"ZH8_TOTLIQ",0.778}})

		//Adicionando os produtos acabados.
		AADD(aMatAcab,{{"ZH9_ITEM","01"},{"ZH9_SEQUEN","001"},{"ZH9_CODPA","CHAMOU020B"},{"ZH9_DESCPA","CHAPA DE GRANITO AMARELO OURO BRASIL 2,00 CM BRUTA"};
			,{"ZH9_LOTECT","202404B"},{"ZH9_LOCAL","03"},{"ZH9_QUANTI",2};
			,{"ZH9_COMLIQ",3.150},{"ZH9_ALTLIQ",1.900},{"ZH9_ESPLIQ",0.130},{"ZH9_TOTLIQ",5.985};
			,{"ZH9_COMBRU",3.150},{"ZH9_ALTBRU",1.900},{"ZH9_ESPBRU",0.130},{"ZH9_TOTBRU",5.985}})

		AADD(aMatAcab,{{"ZH9_ITEM","01"},{"ZH9_SEQUEN","002"},{"ZH9_CODPA","CHAMOU020E"},{"ZH9_DESCPA","CHAPA DE GRANITO AMARELO OURO BRASIL 2,00 CM BRUTA"};
			,{"ZH9_LOTECT","202404B"},{"ZH9_LOCAL","03"},{"ZH9_QUANTI",3};
			,{"ZH9_COMLIQ",3.150},{"ZH9_ALTLIQ",1.900},{"ZH9_ESPLIQ",0.130},{"ZH9_TOTLIQ",5.985};
			,{"ZH9_COMBRU",3.150},{"ZH9_ALTBRU",1.900},{"ZH9_ESPBRU",0.130},{"ZH9_TOTBRU",5.985}})

		AADD(aDadosOp,{aMatPri,aMatAcab})

		U_DADOSOP(@oModelZH8,@oModelZH9,aDadosOp)

	Elseif cCodId == '002' // Exemplo de um beneficiamento

		M->ZH7_RECURS := "ESTE01"

		M->ZH7_EMISSA := STOD("20251017")
		M->ZH7_DATPRI := STOD("20251017")
		M->ZH7_DATPRF := STOD("20251020")

		aMatPri  := {}
		aMatAcab := {}

		//Adicionando a materia prima
		AADD(aMatPri,{{"ZH8_ITEM","01"}, {"ZH8_CODMAT","CHAMOU020B"}, {"ZH8_DESCMT","CHAPA DE GRANITO AMARELO OURO BRASIL 2,00 CM BRUTA"},;
			{"ZH8_ENGENH","RESPAD"},{"ZH8_DESCEN", "1.2. RESINAGEM PADRÃO"}, {"ZH8_LOTECT","210302"}, {"ZH8_NUMLOT","028"},;
			{"ZH8_LOCAL","03"},{"ZH8_UM","M2"},{"ZH8_COMLIQ",2.520},{"ZH8_ALTLIQ",1.980},{"ZH8_ESPLIQ",0,.020},{"ZH8_TOTLIQ",4.9896}})

		//Adicionando os produtos acabados.
		AADD(aMatAcab,{{"ZH9_ITEM","01"},{"ZH9_SEQUEN","001"},{"ZH9_CODPA","CHAMOU020P"},{"ZH9_DESCPA","CHAPA DE GRANITO AMARELO OURO BRASIL 2,00 CM POLIDA"};
			,{"ZH9_LOTECT","210302"},{"ZH9_NUMLOT","028"},{"ZH9_LOCAL","03"};
			,{"ZH9_COMLIQ",2.520},{"ZH9_ALTLIQ",1.980},{"ZH9_ESPLIQ",2.000},{"ZH9_TOTLIQ",4.9896};
			,{"ZH9_COMBRU",2.52},{"ZH9_ALTBRU",1.980},{"ZH9_ESPBRU",2.000},{"ZH9_TOTBRU",4.9896}})


		AADD(aDadosOp,{aMatPri,aMatAcab})

		aMatPri  := {}
		aMatAcab := {}
		//Adicionando a materia prima
		AADD(aMatPri,{{"ZH8_ITEM","02"}, {"ZH8_CODMAT","CHAMOU020B"}, {"ZH8_DESCMT","CHAPA DE GRANITO AMARELO OURO BRASIL 2,00 CM BRUTA"},;
			{"ZH8_ENGENH","RESPAD"},{"ZH8_DESCEN", "1.2. RESINAGEM PADRÃO"}, {"ZH8_LOTECT","210302"}, {"ZH8_NUMLOT","029"},;
			{"ZH8_LOCAL","03"},{"ZH8_UM","M2"},{"ZH8_COMLIQ",2.520},{"ZH8_ALTLIQ",1.980},{"ZH8_ESPLIQ",0,.020},{"ZH8_TOTLIQ",4.9896}})

		//Adicionando os produtos acabados.
		AADD(aMatAcab,{{"ZH9_ITEM","02"},{"ZH9_SEQUEN","001"},{"ZH9_CODPA","CHAMOU020P"},{"ZH9_DESCPA","CHAPA DE GRANITO AMARELO OURO BRASIL 2,00 CM POLIDA"};
			,{"ZH9_LOTECT","210302"},{"ZH9_NUMLOT","029"},{"ZH9_LOCAL","03"};
			,{"ZH9_COMLIQ",2.520},{"ZH9_ALTLIQ",1.980},{"ZH9_ESPLIQ",2.000},{"ZH9_TOTLIQ",4.9896};
			,{"ZH9_COMBRU",2.52},{"ZH9_ALTBRU",1.980},{"ZH9_ESPBRU",2.000},{"ZH9_TOTBRU",4.9896}})


		AADD(aDadosOp,{aMatPri,aMatAcab})

		aMatPri  := {}
		aMatAcab := {}

		//Adicionando a materia prima
		AADD(aMatPri,{{"ZH8_ITEM","03"}, {"ZH8_CODMAT","CHAMOU020B"}, {"ZH8_DESCMT","CHAPA DE GRANITO AMARELO OURO BRASIL 2,00 CM BRUTA"},;
			{"ZH8_ENGENH","RESPAD"},{"ZH8_DESCEN", "1.2. RESINAGEM PADRÃO"}, {"ZH8_LOTECT","210302"}, {"ZH8_NUMLOT","030"},;
			{"ZH8_LOCAL","03"},{"ZH8_UM","M2"},{"ZH8_COMLIQ",2.520},{"ZH8_ALTLIQ",1.980},{"ZH8_ESPLIQ",0,.020},{"ZH8_TOTLIQ",4.9896}})

		//Adicionando os produtos acabados.
		AADD(aMatAcab,{{"ZH9_ITEM","03"},{"ZH9_SEQUEN","001"},{"ZH9_CODPA","CHAMOU020P"},{"ZH9_DESCPA","CHAPA DE GRANITO AMARELO OURO BRASIL 2,00 CM POLIDA"};
			,{"ZH9_LOTECT","210302"},{"ZH9_NUMLOT","030"},{"ZH9_LOCAL","03"};
			,{"ZH9_COMLIQ",2.520},{"ZH9_ALTLIQ",1.980},{"ZH9_ESPLIQ",2.000},{"ZH9_TOTLIQ",4.9896};
			,{"ZH9_COMBRU",2.52},{"ZH9_ALTBRU",1.980},{"ZH9_ESPBRU",2.000},{"ZH9_TOTBRU",4.9896}})

		AADD(aDadosOp,{aMatPri,aMatAcab})

		U_DADOSOP(@oModelZH8,@oModelZH9,aDadosOp)

	EndIf

	oView:Refresh("ZH7MASTER")
	oView:Refresh("ZH8DETAIL")
	oView:Refresh("ZH9DETAIL")

Return .T.



/*/{Protheus.doc} DADOSOP
(long_description)
Rotina para adicioanr os dados na op na tela de apontamento. 
Nela passa as materias primas e os produtos acabados.
@type user function
@author user
@since 17/10/2025
@version version
@param param_name, param_type, param_descr
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function DADOSOP(oModelZH8,oModelZH9,aDadosOp)

	Local aMatPrim  := {}
	Local aMatAcab  := {}
	Local i,nY,nX   := 0
	Local oModel    := Nil

	for i := 1 to len(aDadosOp)

		aMatPrim  := aDadosOp[i,1]
		aMatAcab  := aDadosOp[i,2]

		//Adicionando as materias primas
		//oModelZH8:GoLine(i)

		oModelZH8:AddLine()

		//Adicionando os dados da materia prima ao modelo
		For nX := 1 To Len(aMatPrim)
			For nY := 1 To Len(aMatPrim[nX])
				__lAuto := .T.
				oModelZH8:SetValue(aMatPrim[nX][nY][1],aMatPrim[nX][nY][2])
			Next
		Next

		//Adicionando os produtos acabados
		For nX := 1 To Len(aMatAcab)

			//oModelZH9:GoLine(nX)

			oModelZH9:AddLine()

			//oModelZH9:SetValue("ZH9_SEQUEN", StrZero(nX, 3))

			For nY := 1 To Len(aMatAcab[nX])
				oModelZH9:SetValue(aMatAcab[nX,nY,1],  aMatAcab[nX,nY,2])
			Next

			oModelZH9:SetValue('ZH9_UM',     Posicione("SB1", 1, xFilial("SB1") + oModelZH9:GetValue('ZH9_CODPA'), "B1_UM"))

		Next

	next

Return
