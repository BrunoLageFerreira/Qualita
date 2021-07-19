#INCLUDE "RWMAKE.CH"
/* ####################################################################### *\
|| #           PONTO DE ENTRADA UTILIZADO PELO IMPORTADOR GATI           # ||
|| #                                                                     # ||
|| #  É EXECUTADO DEPOIS QUE A NOTA É EXCLUÍDA PARA FAZER O XML VOLTAR   # ||
|| #                  PARA A TELA INICIAL DO IMPORTADOR                  # ||
\* ####################################################################### */

/*
SO funciona na qualita pois foi incapsulado o ponto original para o GrPlus
Não pode usar o MT103FIM
ESTE E PARA ITINGA
*/

User Function MT103FIM()

Local nOpcao    := PARAM[1]   // Opção Escolhida pelo usuario no aRotina
Local nConfirma := PARAMIXB[2]   // Se o usuario confirmou a operação de gravação da NFE
Local Usuario


U_GTPE002()

ConOut("*****************************")
ConOut("MT103FIM() NÃO USAR NO GRPLUS Informativo dos parametros")
ConOut(CNUMEMP)
ConOut(SUBSTR(CUSUARIO,7,15)+" "+TRIM(DTOC(DATE()))+" "+TRIM(TIME())+" "+TRIM(COMPUTERNAME()))
ConOut(nConfirma )
ConOut(nOpcao)
ConOut("*****************************")

Usuario := SUBSTR(CUSUARIO,7,15)+" "+TRIM(DTOC(DATE()))+" "+TRIM(TIME())+" "+TRIM(COMPUTERNAME())

IF INCLUI  
	If RecLock("SF1",.F.) 
		If nConfirma == 1 .and. nOpcao == 3 
		   
		    ConOut("*****************************")
		    ConOut(Usuario)   
	    	ConOut("GMT103FIM() Entrou")
	    	ConOut("*****************************")
	    	
	    	//Replace F1_INCUSER With cUserName     
	    	Replace F1_INCUSER With Usuario 
			Replace F1_ESPECI4 With SED->ED_CODIGO
			//Replace F1_NATUREZ With SED->ED_CODIGO
		Else
			ConOut("*****************************")
		    ConOut(Usuario)   
	    	ConOut("GMT103FIM() Nao entrou")
	    	ConOut("*****************************")
	    	
		
		EndIf
	
		MsUnLock()
	EndIf
ENDIF


Return(.T.)
