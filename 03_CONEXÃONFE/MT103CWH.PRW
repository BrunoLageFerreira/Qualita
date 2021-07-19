/* ####################################################################### *\
|| #           PONTO DE ENTRADA UTILIZADO PELO IMPORTADOR GATI           # ||
|| #                                                                     # ||
|| # PONTO DE ENTRADA QUE PERMITE ALTERAR O WHEN DOS CAMPOS DE CABEÇALHO # ||
|| #                         DA PRÉ-NOTA E NOTA                          # ||
\* ####################################################################### */

User Function MT103CWH()
	Local lRet:= .T.

	lRet:= U_GTPE006()

Return lRet