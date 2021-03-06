#include 'protheus.ch'

/* 

*/
#define SWWAPP_ADVPL_BUILD   'NetiZap AdvPL 1.0.0'
#define SWWAPP_DEFAULT_HOST  'http://api.meuaplicativo.vip'
#define SWWAPP_DEFAULT_PORT  13005

// --------------------------------------------------
CLASS SWWAPP FROM LONGNAMECLASS
/********************************************************************************************
*
*
****/
	DATA cHostBase
	DATA nPortBase
	DATA cLastError
	DATA nLastStatus
	DATA cHeaderRet
	DATA cResponse
	DATA cLine
	DATA cDestiny
	DATA cReference
	DATA cText
	DATA cQuestion
	DATA cApp
	DATA cAccessKey
	DATA nTimeOutMS
	DATA cFileName
	DATA cFileType
	DATA cFileStream
	DATA cProtocol
	DATA aHeadOut
	DATA cAuthBasic
	DATA bLogBlock

	METHOD NEW()				// Cria um nova inst�ncia da classe
	METHOD SetLine()			// Informa o numero da linha de origem da chamada 
	METHOD SetAccessKey()       // Informa a chave de acesso associada a linha de origem
	METHOD SetPort()			// Informa a porta do provedor de sevi�os HTTP ( default = 12005 ) 
	METHOD Reset()				// Limpa as propriedades para uma nova requisi�ao 
	METHOD SetLogger()			// Informa um Bloco de Codigo de Callback para registro de LOG

	// Parametros para uso dos servi�os 
	METHOD SetDestiny() 		// Informa o numero do destinatario para opera��es *Send()
	METHOD SetReference()		// Informa um valor de referencia opcional para opera��es *Send()
	METHOD SetText()			// Informa um texto para opera��es *Send()
	METHOD SetQuestion()		// Informa as respostas v�lidas para a opera��o QuestioSend()
	METHOD SetFile()			// Informa um tipo, conteudo e nome de arquivo para a opera��o FileSend()
	METHOD SetProtocol()		// Informa um numero de protocolo de mensagems para MessageSearch e QuestionSearch
	METHOD SetTimeOutMS()		// Define o TimeOut em milissegundos para retorno de chamada de API 

	// Servi�os oferecidos	
	METHOD MessageSend()		// Envio de mensagens para um destinatario ou grupo 
	METHOD QuestionSend()		// Envio de uma pergunta com respostas predefinidas
	METHOD FileSend()			// Envio de mensagem com arquivo anexo 
	METHOD MessageSearch()		// Confirma se uma mensagem foi lida e/ou recebida 
	METHOD QuestionSearch()		// Confirma se uma pergunta enviada foi lida e/ou respondida
	METHOD GroupSearch()		// Busca por grupos 
	METHOD BroadcastSearch()	// Busca por listas de trannsmissao
	METHOD CheckCredits()		// Consulta status de creditos da API 
	METHOD RequestsStart()		// Consulta requisi��es realizadas

	// Miscel�nea
	METHOD GetResponse()		// Recupera o corpo da resposta da ultima requisi��o HTTP 
	METHOD GetHeaderResponse()  // Recupera o HEader HTTP de resposta da ultima requisi��o HTTP 
	METHOD GetStatus()          // Recupera o codigo HTTP de retorno  da ultima requisi��o HTTP 
	METHOD GetLastError()		// Recupera o �ltim erro da classe SWWAPP
	METHOD ValidBase()			// Valida os parametros minimos comuns que devem ser informados 

ENDCLASS

// --------------------------------------------------
// Cria a instancia da classe de integra��o com os valores default
// Permite receber 
METHOD NEW(cLine,cAccessKey,nPort) CLASS SWWAPP           
/********************************************************************************************
*
*
****/
::cHostBase   := SWWAPP_DEFAULT_HOST
::nPortBase   := SWWAPP_DEFAULT_PORT
::cApp        := SWWAPP_ADVPL_BUILD
::cAuthBasic  := 'Authorization: Basic '+Encode64("user:api")
::nTimeOutMS  := (20*1000)
::bLogBlock   := NIL
::cLine       := ''
::cAccessKey  := ''


// Pode receber a linha de origem e a chave de acesso no construtor
// Esses parametros sao necess�rios para qualquer requisi��o 
If !empty(cLine)
	::cLine       := cLine
Endif

If !empty(cAccessKey)
	::cAccessKey  := cAccessKey
Endif

IF !empty(nPort)
	::nPortBase := nPort
Endif

// Inicializa todas as demais propriedades relacionadas a API 
::cLastError   := ''
::cHeaderRet   := ''
::cResponse    := ''
::cDestiny     := ''
::cReference   := ''
::cText        := ''
::cQuestion    := ''
::cFileName    := ''
::cFileType    := ''
::cFileStream  := ''
::cProtocol    := ''

// Monta o header HTTP de sa�da, comum a todas as requisi��es
::aHeadOut := {}
aadd(::aHeadOut,'Content-Type: application/x-www-form-urlencoded')
aadd(::aHeadOut,::cAuthBasic)
aadd(::aHeadOut,'Accept-Charset: UTF-8')
aadd(::aHeadOut,'User-Agent: Mozilla/4.0 (compatible; Protheus '+GetBuild()+')')

Return self

// Seta um Bloco de Codigo para grava�ao de log de chamadas da API 
METHOD SetLogger(bLogBlock) CLASS SWWAPP
/********************************************************************************************
*
*
****/
::bLogBlock := bLogBlock
REturn

// --------------------------------------------------
// Reseta as propriedades usadas para envio de requisi��es
METHOD RESET() CLASS SWWAPP
/********************************************************************************************
*
*
****/
::cLastError   := ''
::cHeaderRet   := ''
::cResponse    := ''
::cDestiny     := ''
::cReference   := ''
::cText        := ''
::cQuestion    := ''
::cFileName    := ''
::cFileType    := ''
::cFileStream  := ''
::cProtocol    := ''

Return

// --------------------------------------------------
// Informa a chave de acesso para o servi�o
METHOD SetAccessKey(cAccessKey) CLASS SWWAPP
/********************************************************************************************
*
*
****/
::cAccessKey := alltrim(cAccessKey)
Return

// --------------------------------------------------
// Informa a porta HTTP do servidor da API 
METHOD SetPort(nPort) CLASS SWWAPP
/********************************************************************************************
*
*
****/
::nPortBase := nPort
Return

// --------------------------------------------------
// Informa a linha de origem registrada para o servi�o
METHOD SetLine(cLine) CLASS SWWAPP
/********************************************************************************************
*
*
****/
::cLine := alltrim(cLine)
Return

// --------------------------------------------------
// Informa o numero de telefone de destino 
METHOD SetDestiny(cDestiny) CLASS SWWAPP
/********************************************************************************************
*
*
****/
::cDestiny := alltrim(cDestiny)
Return

// --------------------------------------------------
// Informa um valor de referencia para uso posterior
METHOD SetReference(cReference) CLASS SWWAPP
/********************************************************************************************
*
*
****/
::cReference := alltrim(cReference)
Return

// --------------------------------------------------
// Informa o texto da mensagem 
METHOD SetText(cText) CLASS SWWAPP
/********************************************************************************************
*
*
****/
::cText := alltrim(cText)
Return

// --------------------------------------------------
// Informa resposta(s) para envio de uma quest�o 
METHOD SetQuestion(cQuestion) CLASS SWWAPP
/********************************************************************************************
*
*
****/
::cQuestion := alltrim(cQuestion)
Return

// --------------------------------------------------
// Informa um arquivo a ser enviado 
METHOD SetFile(cFileName,cFileType,cFileStream) CLASS SWWAPP
/********************************************************************************************
*
*
****/
::cFileName := alltrim(cFileName)
::cFileType := alltrim(Upper(cFileType))
::cFileStream := cFileStream
Return

// --------------------------------------------------
// Reconfigura o timeout de retorno de requisi��o 
// Default = 20000 ( 20 segundos ) 
METHOD SETTIMEOUTMS(nTimeOutMS)  CLASS SWWAPP
/********************************************************************************************
*
*
****/
::nTimeOutMS := nTimeOutMS
Return

// --------------------------------------------------
// Informa um numero de protocolo de mensagem para uma opera��o 
METHOD SETPROTOCOL(cProtocol)  CLASS SWWAPP
/********************************************************************************************
*
*
****/
::cProtocol := alltrim(cProtocol)
Return

// --------------------------------------------------
// Realiza o envio de uma mensagem 
// Requer o numero do telefone de destino e a mensagem 
// Permite setar um valor de referencia para uso posterior
METHOD MessageSend() CLASS SWWAPP
/********************************************************************************************
*
*
****/
Local cUrlPost
Local cUrlParms
Local cPostParms
Local nTimer

::cLastError := ''

// Valida��o das propriedades necess�rias 
IF !::ValidBase('MessageSend()')
	Return .F.
Endif         

If empty(::cDestiny)
	::cLastError := 'MessageSend() ERROR - Destiny is missing'
	Return .F.
Endif

If empty(::cText)
	::cLastError := 'MessageSend() ERROR - Text is missing'
	Return .F.
Endif

// Monta url/host para a requisi��o
cUrlPost := ::cHostBase + ":" + cValToChar(::nPortBase) + "/services/message_send"

// Monta o Corpo do Post / Formulario 
cPostParms := 'App='+UrlEncode(::cApp)
cPostParms += '&AccessKey='+UrlEncode(::cAccessKey)

// Monta os parametros para URL / GET 
cUrlParms := 'line=' + UrlEncode(::cLine)
cUrlParms += '&destiny=' + UrlEncode(::cDestiny)
cUrlParms += '&reference=' + UrlEncode(::cReference)
cUrlParms += '&text=' + UrlEncode(::cText)

// Submete a requisi�ao 
::cHeaderRet := ''
nTimer := seconds()
::cResponse := HTTPPOST(cUrlPost,cUrlParms,cPostParms,::nTimeOutMS,::aHeadOut,@::cHeaderRet)
nTimer := seconds()-nTimer

IF valtype(::bLogBlock)=='B'
	Eval(::bLogBlock,cUrlPost,cUrlParms,cPostParms,::cHeaderRet,::cResponse,nTimer) 
Endif

// Recupera o status da requisi��o 
::nLastStatus := HttpGetStatus(@::cLastError)

// Avalia se a requisi��o foi submetida e se o retorno � v�lido
If ::nLastStatus != 200         
	::cLastError := 'HTTP ERROR ('+cValToChar(::nLastStatus)+') : '+ ::cLastError
	Return .F.
Endif

Return .T.

// --------------------------------------------------
// Envio de uma pergunta ao destinatario 
// Requer a linha de destino, a mensagem, a(s) resposta(s) v�lidas
METHOD QuestionSend() CLASS SWWAPP
/********************************************************************************************
*
*
****/
Local cUrlPost
Local cUrlParms
Local cPostParms

::cLastError := ''

// Valida��o das propriedades necess�rias 
IF !::ValidBase('QuestionSend()')
	Return .F.
Endif         

If empty(::cDestiny)
	::cLastError := 'QuestionSend() ERROR - Destiny is missing'
	Return .F.
Endif

If empty(::cText)
	::cLastError := 'QuestionSend() ERROR - Text is missing'
	Return .F.
Endif

If empty(::cQuestion)
	::cLastError := 'QuestionSend() ERROR - Question is missing'
	Return .F.
Endif

// Monta url/host para a requisi��o
cUrlPost := ::cHostBase + ":" + cValToChar(::nPortBase) + "/services/question_send"

// Monta o Corpo do Post / Formulario 
cPostParms := 'App='+UrlEncode(::cApp)
cPostParms += '&AccessKey='+UrlEncode(::cAccessKey)

// Monta os parametros para URL / GET 
cUrlParms := 'line=' + ::cLine
cUrlParms += '&destiny=' + ::cDestiny
cUrlParms += '&reference=' + ::cReference
cUrlParms += '&text=' + UrlEncode(::cText)
cUrlParms += '&question=' + UrlEncode(::cQuestion)

// Submete a requisi�ao 
::cHeaderRet := ''
nTimer := seconds()
::cResponse := HTTPPOST(cUrlPost,cUrlParms,cPostParms,::nTimeOutMS,::aHeadOut,@::cHeaderRet)
nTimer := seconds()-nTimer

IF valtype(::bLogBlock)=='B'
	Eval(::bLogBlock,cUrlPost,cUrlParms,cPostParms,::cHeaderRet,::cResponse,nTimer) 
Endif

// Recupera o status da requisi��o 
::nLastStatus := HttpGetStatus(@::cLastError)

// Avalia se a requisi��o foi submetida e se o retorno � v�lido
If ::nLastStatus != 200         

	IF empty(::cLastError)
		::cLastError := 'Unknow Error on HTTPPOST'
	Endif

	Return .F.
Endif

Return .T.

// --------------------------------------------------
// Envio de mensagem com arquivo anexo 
// Requer a linha de destino, a mensagem, o tipo do arquivo, 
// o conteudo (bin�rio) e o nome do arquivo a ser informado na memsagem 
METHOD FileSend() CLASS SWWAPP
/********************************************************************************************
*
*
****/
Local cUrlPost
Local cUrlParms
Local cPostParms

::cLastError := ''

// Valida��o das propriedades necess�rias 
IF !::ValidBase('FileSend()')
	Return .F.
Endif         

If empty(::cDestiny)
	::cLastError := 'FileSend() ERROR - Destiny is missing'
	Return .F.
Endif

If empty(::cText)
	::cLastError := 'FileSend() ERROR - Text is missing'
	Return .F.
Endif

If empty(::cFileType)
	::cLastError := 'FileSend() ERROR - File Type is missing'
	Return .F.
Endif

If empty(::cFileStream)
	::cLastError := 'FileSend() ERROR - File Stream is missing'
	Return .F.
Endif

// Monta url/host para a requisi��o
cUrlPost := ::cHostBase + ":" + cValToChar(::nPortBase) + "/services/file_send"

// Monta o Corpo do Post / Formulario 
cPostParms := 'app='      + URLEncode(::cApp)
cPostParms += '&key='     + URLEncode(::cAccessKey)
cPostParms += '&text='    + UrlEncode(::cText)
cPostParms += '&type='    + URLEncode(::cFileType)
cPostParms += '&stream='  + UrlEncode(::cFileStream)
cPostParms += '&filename='+ UrlEncode(::cFileName)

// Monta os parametros para URL / GET 
cUrlParms := 'line='       + ::cLine
cUrlParms += '&destiny='   + ::cDestiny
cUrlParms += '&reference=' + ::cReference

// Submete a requisi�ao 
::cHeaderRet := ''
nTimer := seconds()
::cResponse := HTTPPOST(cUrlPost,cUrlParms,cPostParms,::nTimeOutMS,::aHeadOut,@::cHeaderRet)
nTimer := seconds()-nTimer

IF valtype(::bLogBlock) == 'B'
	Eval(::bLogBlock,cUrlPost,cUrlParms,cPostParms,::cHeaderRet,::cResponse,nTimer) 
Endif

// Recupera o status da requisi��o 
::nLastStatus := HttpGetStatus(@::cLastError)

// Avalia se a requisi��o foi submetida e se o retorno � v�lido
If ::nLastStatus != 200         
	IF empty(::cLastError)
		::cLastError := 'Unknow Error on HTTPPOST'
	Endif
	Return .F.
Endif

Return .T.

// --------------------------------------------------
// Busca pelo status de uma determinada mensagem enviada
// Requer o numero do protocolo da mensagem, retornado pelo MEssageSend()
METHOD MessageSearch() CLASS SWWAPP
/********************************************************************************************
*
*
****/
Local cUrlGet
Local cUrlParms

::cLastError := ''

// Valida��o das propriedades necess�rias 
IF !::ValidBase('MessageSearch()')
	Return .F.
Endif         

If empty(::cProtocol)
	::cLastError := 'MessageSearch() ERROR - Protocol is missing'
	Return .F.
Endif

// Monta url/host para a requisi��o
cUrlGet := ::cHostBase + ":" + cValToChar(::nPortBase) + "/services/message_search"

// Monta os parametros para URL / GET 
cUrlParms := 'line=' + UrlEncode(::cLine)
cUrlParms += '&AccessKey='+UrlEncode(::cAccessKey)
cUrlParms += '&protocol=' + UrlEncode(::cProtocol)

// Submete a requisi�ao 

::cHeaderRet := ''
nTimer := seconds()
::cResponse := HTTPGET(cUrlGet,cUrlParms,::nTimeOutMS,::aHeadOut,@::cHeaderRet)
nTimer := seconds()-nTimer

IF valtype(::bLogBlock)=='B'
	Eval(::bLogBlock,cUrlGet,cUrlParms,"",::cHeaderRet,::cResponse,nTimer) 
Endif

// Recupera o status da requisi��o 
::nLastStatus := HttpGetStatus(@::cLastError)

// Avalia se a requisi��o foi submetida e se o retorno � v�lido
If ::nLastStatus != 200         
	IF empty(::cLastError)
		::cLastError := 'Unknow Error on HTTPPOST'
	Endif
	Return .F.
Endif

Return .T.

// --------------------------------------------------
// Busca pelo status de uma determinada pergunta enviada
// Requer o numero do protocolo da pergunta , retornado pelo QuestionSend()
METHOD QuestionSearch() CLASS SWWAPP
/********************************************************************************************
*
*
****/
Local cUrlGet
Local cUrlParms

::cLastError := ''

// Valida��o das propriedades necess�rias 
IF !::ValidBase('QuestionSearch()')
	Return .F.
Endif         

If empty(::cProtocol)
	::cLastError := 'QuestionSearch() ERROR - Protocol is missing'
	Return .F.
Endif

// Monta url/host para a requisi��o
cUrlGet := ::cHostBase + ":" + cValToChar(::nPortBase) + "/services/question_search"

// Monta os parametros para URL / GET 
cUrlParms := 'line=' + UrlEncode(::cLine)
cUrlParms += '&AccessKey='+UrlEncode(::cAccessKey)
cUrlParms += '&protocol=' + UrlEncode(::cProtocol)

// Submete a requisi�ao 
::cHeaderRet := ''
nTimer := seconds()
::cResponse := HTTPGET(cUrlGet,cUrlParms,::nTimeOutMS,::aHeadOut,@::cHeaderRet)
nTimer := seconds()-nTimer

IF valtype(::bLogBlock)=='B'
	Eval(::bLogBlock,cUrlGet,cUrlParms,"",::cHeaderRet,::cResponse,nTimer) 
Endif

// Recupera o status da requisi��o 
::nLastStatus := HttpGetStatus(@::cLastError)

// Avalia se a requisi��o foi submetida e se o retorno � v�lido
If ::nLastStatus != 200         
	IF empty(::cLastError)
		::cLastError := 'Unknow Error on HTTPPOST'
	Endif
	Return .F.
Endif

Return .T.

// --------------------------------------------------
// Verifica quais os grupos de envio de mensagens est�o registrados 
// para a linha de origem definida. Nao requer parametros
METHOD GroupSearch() CLASS SWWAPP
/********************************************************************************************
*
*
****/
Local cUrlGet
Local cUrlParms

::cLastError := ''

// Valida��o das propriedades necess�rias 
IF !::ValidBase('GroupSearch()')
	Return .F.
Endif         

// Monta url/host para a requisi��o
cUrlGet := ::cHostBase + ":" + cValToChar(::nPortBase) + "/services/group_search"

// Monta os parametros para URL / GET 
cUrlParms := 'line=' + UrlEncode(::cLine)
cUrlParms += '&AccessKey='+UrlEncode(::cAccessKey)

// Submete a requisi�ao 
::cHeaderRet := ''
nTimer := seconds()
::cResponse := HTTPGET(cUrlGet,cUrlParms,::nTimeOutMS,::aHeadOut,@::cHeaderRet)
nTimer := seconds()-nTimer

IF valtype(::bLogBlock)=='B'
	Eval(::bLogBlock,cUrlGet,cUrlParms,"",::cHeaderRet,::cResponse,nTimer) 
Endif

// Recupera o status da requisi��o 
::nLastStatus := HttpGetStatus(@::cLastError)

// Avalia se a requisi��o foi submetida e se o retorno � v�lido
If ::nLastStatus != 200         
	IF empty(::cLastError)
		::cLastError := 'Unknow Error on HTTPPOST'
	Endif

	Return .F.
Endif

Return .T.

// --------------------------------------------------
// Consulta as listas de transmiss�o que est�o registrados 
// para a linha de origem definida. Nao requer parametros
METHOD BroadcastSearch() CLASS SWWAPP
/********************************************************************************************
*
*
****/
Local cUrlGet
Local cUrlParms

::cLastError := ''

// Valida��o das propriedades necess�rias 
IF !::ValidBase('BroadcastSearch()')
	Return .F.
Endif         

// Monta url/host para a requisi��o
cUrlGet := ::cHostBase + ":" + cValToChar(::nPortBase) + "/services/broadcast_search"

// Monta os parametros para URL / GET 
cUrlParms := 'line=' + UrlEncode(::cLine)
cUrlParms += '&AccessKey='+UrlEncode(::cAccessKey)


// Submete a requisi�ao 
::cHeaderRet := ''
nTimer := seconds()
::cResponse := HTTPGET(cUrlGet,cUrlParms,::nTimeOutMS,::aHeadOut,@::cHeaderRet)
nTimer := seconds()-nTimer

IF valtype(::bLogBlock)=='B'
	Eval(::bLogBlock,cUrlGet,cUrlParms,"",::cHeaderRet,::cResponse,nTimer) 
Endif

// Recupera o status da requisi��o 
::nLastStatus := HttpGetStatus(@::cLastError)

// Avalia se a requisi��o foi submetida e se o retorno � v�lido
If ::nLastStatus != 200         
	IF empty(::cLastError)
		::cLastError := 'Unknow Error on HTTPPOST'
	Endif
	Return .F.
Endif

Return .T.

// --------------------------------------------------
// Verifica o estado do plano atual junto a SWWAPP
// Nao requer parametros adicionais
METHOD CheckCredits() CLASS SWWAPP
/********************************************************************************************
*
*
****/
Local cUrlGet
Local cUrlParms

::cLastError := ''

// Valida��o das propriedades necess�rias 
IF !::ValidBase('CheckCredits()')
	Return .F.
Endif         

// Monta url/host para a requisi��o
cUrlGet := ::cHostBase + ":" + cValToChar(::nPortBase) + "/services/check_credits"

// Monta os parametros para URL / GET 
cUrlParms := 'line=' + UrlEncode(::cLine)
cUrlParms += '&key='+UrlEncode(::cAccessKey)

// Submete a requisi�ao 
::cHeaderRet := ''
nTimer := seconds()
::cResponse := HTTPGET(cUrlGet,cUrlParms,::nTimeOutMS,::aHeadOut,@::cHeaderRet)
nTimer := seconds()-nTimer

IF valtype(::bLogBlock)=='B'
	Eval(::bLogBlock,cUrlGet,cUrlParms,"",::cHeaderRet,::cResponse,nTimer) 
Endif

// Recupera o status da requisi��o 
::nLastStatus := HttpGetStatus(@::cLastError)


// Avalia se a requisi��o foi submetida e se o retorno � v�lido
If ::nLastStatus != 200         
	IF empty(::cLastError)
		::cLastError := 'Unknow Error on HTTPPOST'
	Endif
	Return .F.
Endif

Return .T.

// --------------------------------------------------
// Consulta o envio de requisi��es j� realizado pela API 
// Nao requer parametros adicionais
METHOD RequestsStart() CLASS SWWAPP
/********************************************************************************************
*
*
****/
Local cUrlGet
Local cUrlParms

::cLastError := ''

// Valida��o das propriedades necess�rias 
IF !::ValidBase('RequestsStart()')
	Return .F.
Endif         

// Monta url/host para a requisi��o
cUrlGet := ::cHostBase + ":" + cValToChar(::nPortBase) + "/reports/requests_start"

// Monta os parametros para URL / GET 
cUrlParms := 'line=' + UrlEncode(::cLine)
cUrlParms += '&AccessKey='+UrlEncode(::cAccessKey)

// Submete a requisi�ao GET
::cHeaderRet := ''
nTimer := seconds()
::cResponse := HTTPGET(cUrlGet,cUrlParms,::nTimeOutMS,::aHeadOut,@::cHeaderRet)
nTimer := seconds()-nTimer

IF valtype(::bLogBlock)=='B'
	Eval(::bLogBlock,cUrlGet,cUrlParms,"",::cHeaderRet,::cResponse,nTimer) 
Endif

// Recupera o status da requisi��o 
::nLastStatus := HttpGetStatus(@::cLastError)

// Avalia se a requisi��o foi submetida e se o retorno � v�lido
If ::nLastStatus != 200         
	IF empty(::cLastError)
		::cLastError := 'Unknow Error on HTTPPOST'
	Endif
	Return .F.
Endif

Return .T.

// --------------------------------------------------
// Obtem a string com a resposta da ultima chamada de API realizada
METHOD GetResponse() CLASS SWWAPP
/********************************************************************************************
*
*
****/
Return ::cResponse

// --------------------------------------------------
// Obtem o Header HTTP de retorno da ultima chamada de API realizada 
METHOD GetHeaderResponse() CLASS SWWAPP
/********************************************************************************************
*
*
****/
Return ::cHeaderRet

// --------------------------------------------------
// Obtem a descri��o do �ltimo erro da API 
// Observa��o : Um erro � definido quando n�o foi poss�vel 
// o envio de uma requisi��o, ou houve um retorno inesperado. 
// Cada chamada possui o seu formato de retorno, com um JSON
// informando se a opera��o foi realizada com sucesso ou n�o 
METHOD GetLastError() CLASS SWWAPP
/********************************************************************************************
*
*
****/
Return ::cLastError

// --------------------------------------------------
// Retorna o ultimo status HTTP de uma chamada de API 
METHOD GetStatus() CLASS SWWAPP
/********************************************************************************************
*
*
****/
Return ::nLastStatus

// --------------------------------------------------
// Valida os argumentos b�sicos para envio de qualquer mensagem 
// Precisa pelo menos da linha de origem e da access key 
METHOD ValidBase(cMethod) CLASS SWWAPP
/********************************************************************************************
*
*
****/
If empty(::cLine)
	::cLastError := cMethod+' ERROR - Line is missing.'
	Return .F.
Endif

IF empty(::cAccessKey)
	::cLastError := cMethod+' ERROR - AccessKey is missing.'
	Return .F.
Endif

Return .T. 

// --------------------------------------------------
// Realiza a codifica��o de dados para URL e/ou POST 
STATIC Function URLEncode(cValue)
/********************************************************************************************
*
*
****/
Local nI , cRet := '', cChar

For nI := 1 to len(cValue)
	cChar := substr(cValue,nI,1)
	IF asc(cChar) < 32 
		IF asc(cChar) == 13 // ( CR - Ignora ) 
			LOOP		
		ElseIF asc(cChar) == 10 // ( LF - TRoca para "\n" ) 
			cRet += '\n' 
		Else
			// Converte para hexadecimal, formato %HH
			cRet += '%'+PADL(Upper(__DecToHex(asc(cChar))),2,'0')
	    Endif
	ElseIf cChar >= ' ' .and. cChar <= '/'
		// Converte para hexadecimal, formato %HH
		cRet += '%'+PADL(Upper(__DecToHex(asc(cChar))),2,'0')
	ElseIf cChar >= '0' .and. cChar <= '9'
		cRet += cChar
	ElseIf cChar >= 'A' .and. cChar <= 'Z'
		cRet += cChar
	ElseIf cChar >= 'a' .and. cChar <= 'z'
		cRet += cChar
	Else
		// Converte para hexadecimal, formato %HH
		cRet += '%'+PADL(Upper(__DecToHex(asc(cChar))),2,'0')
	Endif
Next

Return cRet