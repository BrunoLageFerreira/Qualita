#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
#INCLUDE "TOPCONN.CH"

/*                                          
Programa ...: GROA056M.Prw
Uso ........: Ponto P.E atualizção padrão no formato MVC
Data .......: 14/09/19
Feito por ..: Bruno Lage Ferreira.
*/

User Function GROA056M()
********************************************************************************
*
*
***
Local aParam     := PARAMIXB
Local xRet       := .T.
Local oObj       := ''
Local cIdPonto   := ''
Local cIdModel   := ''
Local lIsGrid    := .F.

Local nLinha     := 0
Local nQtdLinhas := 0
Local cMsg       := ''
Local cQuery     := ''

If aParam <> NIL
      
       oObj       := aParam[1]
       cIdPonto   := aParam[2]
       cIdModel   := aParam[3]
       lIsGrid    := ( Len( aParam ) > 3 )
      
       If lIsGrid
             //nQtdLinhas := oObj:GetQtdLine()
             //nLinha     := oObj:nLine
       EndIf
      
       If     cIdPonto == 'MODELPOS'
      			       	 
       /*
       cMsg := 'Chamada na validação total do modelo (MODELPOS).' + CRLF
       cMsg += 'ID ' + cIdModel + CRLF
       
       If !( xRet := ApMsgYesNo( cMsg + 'Continua ?' ) )
              Help( ,, 'Help',, 'O MODELPOS retornou .F.', 1, 0 )
       EndIf
       */
       ElseIf cIdPonto == 'FORMPOS'
       
              If !Empty(m->ZG3_XENDER)
                     cQuery := " SELECT ZE1_BLQ,ZE1_ENDERE FROM ZE1010 WHERE D_E_L_E_T_ = '' AND ZE1_ENDERE='" + AllTrim(m->ZG3_XENDER) + "'"
                     tcQuery cQuery alias TRB new

			dbSelectArea("TRB")
			dbgotop()
                     
                     If EOF()
                            Alert("Endereço não encontrado!")
                            dbSelectArea("TRB") 
			       dbCloseArea()
				Return(.F.)
                     Else
                            Do While !EOF()
                                   
                                   If TRB->ZE1_BLQ == '2'
					       Alert("Endereço bloqueado para produtos acabados!")
					       Return(.f.)
				       EndIf
                                                        
                                   dbSelectArea("TRB") 
                                   dbSkip()
                            EndDo
			EndIf

			dbSelectArea("TRB") 
			dbCloseArea()
              EndIf

       
             /*
             cMsg := 'Chamada na validação total do formulário (FORMPOS).' + CRLF
             cMsg += 'ID ' + cIdModel + CRLF
            
             If      cClasse == 'FWFORMGRID'
                    cMsg += 'É um FORMGRID com ' + Alltrim( Str( nQtdLinhas ) ) + ;
                    		'     linha(s).' + CRLF
                    cMsg += 'Posicionado na linha ' + Alltrim( Str( nLinha     ) ) + CRLF
             ElseIf cClasse == 'FWFORMFIELD'
                    cMsg += 'É um FORMFIELD' + CRLF
             EndIf
            
             If !( xRet := ApMsgYesNo( cMsg + 'Continua ?' ) )
                    Help( ,, 'Help',, 'O FORMPOS retornou .F.', 1, 0 )
             EndIf
            */
       ElseIf cIdPonto == 'FORMLINEPRE'
             If aParam[5] == 'ALTERA'
             
             EndIf
             /*
             If aParam[5] == 'DELETE'
             		cMsg := 'Chamada na pre validação da linha do formulário (FORMLINEPRE).' + CRLF
                    cMsg += 'Onde esta se tentando deletar uma linha' + CRLF
                    cMsg += 'É um FORMGRID com ' + Alltrim( Str( nQtdLinhas ) ) +;
                    		' linha(s).' + CRLF
                    cMsg += 'Posicionado na linha ' + Alltrim( Str( nLinha     ) ) +; CRLF
                    cMsg += 'ID ' + cIdModel + CRLF
                   
                    If !( xRet := ApMsgYesNo( cMsg + 'Continua ?' ) )
                           Help( ,, 'Help',, 'O FORMLINEPRE retornou .F.', 1, 0 )
                    EndIf
             EndIf
            */
       ElseIf cIdPonto == 'FORMLINEPOS'
       		 /*
       		 cMsg := 'Chamada na validação da linha do formulário (FORMLINEPOS).' +; CRLF
             cMsg += 'ID ' + cIdModel + CRLF
             cMsg += 'É um FORMGRID com ' + Alltrim( Str( nQtdLinhas ) ) + ;
             		 ' linha(s).' + CRLF
             cMsg += 'Posicionado na linha ' + Alltrim( Str( nLinha     ) ) + CRLF
            
             If !( xRet := ApMsgYesNo( cMsg + 'Continua ?' ) )
                    Help( ,, 'Help',, 'O FORMLINEPOS retornou .F.', 1, 0 )
             EndIf
            */
       ElseIf cIdPonto == 'MODELCOMMITTTS'
            /*
            ApMsgInfo('Chamada apos a gravação total do modelo e dentro da transação (MODELCOMMITTTS).' + CRLF + 'ID ' + cIdModel )
            */
       ElseIf cIdPonto == 'MODELCOMMITNTTS'
       		
            //ApMsgInfo('Chamada apos a gravação total do modelo e fora da transação (MODELCOMMITNTTS).' + CRLF + 'ID ' + cIdModel)
            
            //Comentado para ser usado somente na
            //BRUNO E CAMILA CONVERSA PELO TELEFONE  
            //rotina MMOVVESTEND.PRW 02/06/2021
            /*
            If !Empty(ZG3->ZG3_XDTMOV)
	              cQuery:=" UPDATE SB8010
		       cQuery+="   SET B8_XDTMOVE ='" + DTOS(ZG3->ZG3_XDTMOV ) + "',B8_XENDERE='" + Alltrim(ZG3->ZG3_XENDER) + "',B8_XPUSUAR='" + AllTrim(ZG3->ZG3_XPUSUA) + "'
			cQuery+="  	FROM SB8010 SB8 
			cQuery+=" WHERE SB8.D_E_L_E_T_ = ''
			cQuery+="   AND B8_YCAVALE = '" + ZG3->ZG3_CODIGO + "'
			
			TcSQLExec(cQuery)
            EndIf
            */
            
            /*
            cQuery:=" UPDATE SB8010
			cQuery+="   SET B8_YPESOBR = "+ STR(M->ZG3_PESOBR)
			cQuery+="  	FROM SB8010 SB8 
			cQuery+=" WHERE SB8.D_E_L_E_T_ = ''
			cQuery+="   AND B8_YCAVALE = '"+ZG3->ZG3_CODIGO+"'
			cQuery+="   AND B8_ORIGLAN = 'BD'
			
			TcSQLExec(cQuery)
        
            cQuery:=" UPDATE SB8010
			cQuery+="   SET B8_YPESOLQ = "+ STR(M->ZG3_PESOLQ)
			cQuery+="  	FROM SB8010 SB8 
			cQuery+=" WHERE SB8.D_E_L_E_T_ = ''
			cQuery+="   AND B8_YCAVALE = '"+ZG3->ZG3_CODIGO+"'
			cQuery+="   AND B8_ORIGLAN = 'BD'
			
			TcSQLExec(cQuery)
			*/
            
             //ElseIf cIdPonto == 'FORMCOMMITTTSPRE'
            
       ElseIf cIdPonto == 'FORMCOMMITTTSPOS'
            
       
       		/*
       		ApMsgInfo('Chamada apos a gravação da tabela do formulário (FORMCOMMITTTSPOS).' + CRLF + 'ID ' + cIdModel)
            */
       ElseIf cIdPonto == 'MODELCANCEL'
       		/*cMsg := 'Chamada no Botão Cancelar (MODELCANCEL).' + CRLF + 'Deseja Realmente Sair ?'
            
             If !( xRet := ApMsgYesNo( cMsg ) )
                    Help( ,, 'Help',, 'O MODELCANCEL retornou .F.', 1, 0 )
             EndIf
            */
       ElseIf cIdPonto == 'BUTTONBAR'
			/*
			ApMsgInfo('Adicionando Botao na Barra de Botoes (BUTTONBAR).' + CRLF + 'ID ' + cIdModel )
			xRet := { {'Merda', 'Merda', { || Alert( 'merdou' ) }, 'Este botao merda' } }
			*/        
       EndIf

EndIf

Return xRet
