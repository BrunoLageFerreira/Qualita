/* ####################################################################### *\
|| #           PONTO DE ENTRADA UTILIZADO PELO IMPORTADOR GATI           # ||
|| #                                                                     # ||
|| #    PONTO DE ENTRADA UTILIZADO PARA CONSIDERAR A DATA DE VENCIMENTO  # ||
|| #          DA DUPLICATA DO CTE INFORMADA NA IMPORTAÇÃO POR LOTE       # ||
|| #                                                                     # ||
\* ####################################################################### */
User Function MTCOLSE2()
Local aSE2 := {}

	// Altera a data de vencimento da duplicata
	aSE2 := U_GTPE013()

	// Regra já existente no ponto de entrada

Return aSE2