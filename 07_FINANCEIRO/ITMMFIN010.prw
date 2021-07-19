/*
+----------------------------------------------------------------------------+
|                        FICHA TECNICA DO PROGRAMA                           |
+----------------------------------------------------------------------------+
|   DADOS DO PROGRAMA                                                        |
+------------------+---------------------------------------------------------+
|Tipo              | Rotina para gerar numero sequencial CNAB                |
+------------------+---------------------------------------------------------+
|Modulo            | Financeiro                                              |
+------------------+---------------------------------------------------------+
|Nome              | ITMMFIN010                                              |
+------------------+---------------------------------------------------------+
|Descricao         | Rotinas para gerar numero sequencial por Filial, gravan-|
|                  | do valor por parametro									 |
+------------------+---------------------------------------------------------+
|Autor             | Márcio Chaves                                           |
+------------------+---------------------------------------------------------+
|Data de Criacao   | 31/01/2013                                              |
+------------------+---------------------------------------------------------+
|   ATUALIZACOES                                                             |
+-------------------------------------------+-----------+-----------+--------+
|   Descricao detalhada da atualizacao      |Nome do    | Analista  |Data da |
|                                           |Solicitante| Respons.  |Atualiz.|
+-------------------------------------------+-----------+-----------+--------+
|                                           |           |           |        |
|                                           |           |           |        |
+-------------------------------------------+-----------+-----------+--------+
*/

User Function ITMMFIN010()

	//nSeq:= SUPERGETMV("MV_SEQCNAB")
	//	PutMv("MV_SEQCNAB",Soma1(nSeq))

	DBSELECTAREA("SX6")
	DBSETORDER(1)
	cFil1:= ""  //TLM
	cFil2:= XFILIAL("SX6")
	IF Empty(cFil2) //TLM
		cFil2:= xFilial("SE1") //TLM
	EndIF //TLM	
	IF Left(cFil2,2) == "01"
		cFil1 := "010101"
	ElseIF Left(cFil2,2) == "02"
		cFil1 := "020101"	 	
	ElseIF Left(cFil2,2) == "03"
		cFil1 := "030301"	 	
	ElseIF Left(cFil2,2) == "04"
		cFil1 := "040401"
	ElseIF Left(cFil2,2) == "05"
		cFil1 := "050501"
	ElseIF Left(cFil2,2) == "06"
		cFil1 := "060601"	 		 		 		 	
	EndIf
	DBSEEK(cFil1+"MV_SEQCNAB")
	nSeq:=Alltrim(SX6->X6_CONTEUD)
	RecLock("SX6",.F.)
	SX6->X6_CONTEUD := Soma1(nSeq)
	MsUnlock()

Return(nSeq)                             