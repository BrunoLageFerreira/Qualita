#Include 'Protheus.ch'
#Include 'Rwmake.ch'
#include 'Fileio.ch'
 
//   +----------------------------------------------------------------------------------------------------------------------+
//   |  MV_CELZAP : "5527981049976"                                                                                         |
//   |  MV_CHAVZAP: "A9CostEuLiQpiCC5IH7w"                                                                                  |
//   |  MV_HTTPZAP: 13005                                                                                                   |
//   +----------------------------------------------------------------------------------------------------------------------+
//   | USER FUNCTION |          DESCRIÇÃO                          |             PARAMETROS                                 |
//   +----------------------------------------------------------------------------------------------------------------------+
//   | U_ENVMGZAP    | ENVIA MENSAGEM NO WHATSAPP                  |    C - NUM.CELULAR ; C - MENSAGEM     ; C - REFERENCIA |
//   +----------------------------------------------------------------------------------------------------------------------+
//   | U_ENVPGZAP    | ENVIA PERGUNTA NO WHATSAPP                  |    C - NUM.CELULAR ; C - MENSAGEM     ; C - REFERENCIA |
//   |               |                                             |    C - OPÇÕES                                          |
//   +----------------------------------------------------------------------------------------------------------------------+
//   | U_SWENARWAP    | ENVIA ARQUIVO NO WHATSAPP                   |    C - NUM.CELULAR ; C - MENSAGEM     ; C - REFERENCIA |
//   |               |                                             |    C - NOM.ARQUIVO ; C - TIPO.ARQUIVO ; C - CAMINHO    |               
//   +----------------------------------------------------------------------------------------------------------------------+
//   | U_SWREMGWAP    | VERIF SE MENSAGEM FOI LIDA                  |    C - NUM.PROTOCOLO                                   |
//   +----------------------------------------------------------------------------------------------------------------------+
//   | U_RECPGZAP    | VERIF SE PERGUNTA FOI LIDA E/OU RESPONDIDA  |    C - NUM.PROTOCOLO                                   |
//   +----------------------------------------------------------------------------------------------------------------------+
//   | U_RECRSZAP    | VERIF SE HOUVE ALGUMA REQUISIÇÃO            |                                                        |
//   +----------------------------------------------------------------------------------------------------------------------+

//Alert("Email enviado com sucesso!")
//U_SWENARWAP("5533984022125","PROFORMA","PROFORMA","RQ0003","PDF","\RELINWEB\RQ0003.pdf")
//U_SWENARWAP("5511982108065","Aprovação da Proforma:" , "PROFORMA"+ "1234","RQ0003","PDF","\RELINWEB\FaturaVivo_012020.pdf")
//U_SWENARWAP("5533984022125","PROFORMA","PROFORMA","\RQ0003.PDF","PDF","\RELINWEB")            
//U_SWREMGWAP("092F12FF-BD41-40A9-8F19-DB9624B997BF")                                                                                                                                                                                                                                                                                                                                     

//U_SWENV("5533984022125","TXT_MSG","5533984022125")
 
 
/*
consulta protocolo
http://api.meuaplicativo.vip:13012/services/question_search?line=5527995295180&AccessKey=Yp522crJhANr0PZo0kCX&protocol=87F621CF-B190-4366-8732-D6C5F4EDB873

user api

U_ENVMGZAP(TXT_NUMCELULAR,TXT_MENSAGEM,TXT_REFERENCIA) ;      ; C - 

Linha: 				MV_CELZAP  = 5527995295180
Porta: 				MV_HTTPZAP = 13012
Chave de Acesso: 	MV_CHAVZAP = Yp522crJhANr0PZo0kCX

Q-Liberação Faturamento
5527995295180-1587589430@g.us

Q-N2 - Liberação Compras
5527995295180-1594316108@g.us

Q-N1 - Liberação Compras
5527995295180-1587589523@g.us 
 
 */

/*
#DEFINE V_CELZAP    "5527995295180"
#DEFINE V_CHAVZAP   "Yp522crJhANr0PZo0kCX"
#DEFINE V_HTTPZAP   "13012"
*/
 
USER FUNCTION SWENARWAP(cNumCel,cMsg,cReference,cNomArq,cTpArquivo,cCaminho)
Local oSWWAPP
Local cProtocolo
Local oJson	:= JsonObject():new()

//Local cTexto := ""
//Local nFSize

DEFAULT cReference  := " "

//Instancio a Classe que faz ligação com a API NETiZAP
//oSWWAPP  := NETIZAP():New(SuperGetMv("MV_CELZAP"),SuperGetMv("MV_CHAVZAP"),SuperGetMv("MV_HTTPZAP"))
oSWWAPP  := SWWAPP():New("5527995295180"        ,"Yp522crJhANr0PZo0kCX"  ,"13012"                )

// Define as propriedades minimas para envio de mensagem
//Define o numero destino
oSWWAPP:SetDestiny(cNumCel)

// Informa o texto da mensagem
oSWWAPP:SetText(EncodeUTF8(cMsg))

// Define a Referencia, forma identificar a mensagem para uso posterior
oSWWAPP:SetReference(cReference)

oSWWAPP:SetFile(cNomArq,cTpArquivo,LoadFile64(cCaminho))

// Realiza o envio da mensagem
If oSWWAPP:FileSend()
	// Pega o JSON de retorno da requisiçao
	// Cada mensagem enviada retorna um identificador de protocolo
	// no formato "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX".
	cProtocolo := oSWWAPP:GetResponse()
Else
	// Em caso de falha no envio, recupera o erro
	MSgStop(oSWWAPP:GetLastError(),'FileSend() - Falha no envio da requisição')
Endif

//Coloco o JSON vindo da classe NETiZAP no objeto oJson desta função
cErro := oJson:fromJSON(cProtocolo)

//Verifico se ocorreu algum erro no metodo fromJSON
If Len(AllTrim(cErro)) == 0
	//Ja trato o JSON e retorno apenas o protocolo para facilitar no uso da USER FUNCTION
	cProtocolo:=oJson:GetJsonObject("result")
else
	MsgStop(oSWWAPP:GetLastError(),'oJson:fromJSON(cProtocolo) - Falha na inserção de dados com a classe JsonObject()')
EndIf

RETURN cProtocolo



STATIC Function LoadFile64(cFile)
/********************************************************************************
*
*
****/
Local nH, nSize, cBuffer := ""

nH := fopen(cFile)
If nH < 0 
	USerException("LoadFile64 error - File ["+cfile+"] - Open Error "+cValToChar(ferror()))
Endif

nSize := fSeek(nH,0,2)
If nSize <= 0 
	USerException("LoadFile64 error - File ["+cfile+"] - Invalid Empty File ")
Endif

fseek(nh,0)
fRead(nH,@cBuffer,nSize)
fClose(nH)

Return Encode64(cBuffer)
 
 /*
 ******************************corrido 
 
    Local oSWWAPP
    Local cProtocolo
    Local oJson := JsonObject():new()
    
    Local cTexto := ""
    Local aFiles := {}
    Local aSizes := {}
    Private cStrE64 := ""
    
    DEFAULT cReference  := " "
 
    //Instancio a Classe que faz ligação com a API SWWAPP
    //oSWWAPP  := SWWAPP():New(SuperGetMv("MV_CELZAP"),SuperGetMv("MV_CHAVZAP"),SuperGetMv("MV_HTTPZAP"))
    oSWWAPP  := SWWAPP():New("5527995295180"        ,"Yp522crJhANr0PZo0kCX"  ,"13012"                ) 
    // Define as propriedades minimas para envio de mensagem
 
    //Define o numero destino
    oSWWAPP:SetDestiny(cNumCel)
 
    // Informa o texto da mensagem
    oSWWAPP:SetText(EncodeUTF8(cMsg))
 
    // Define a Referencia, forma identificar a mensagem para uso posterior
    oSWWAPP:SetReference(cReference)
 
    //Informo o nome escolhido do arquivo, o tipo e o caminho fisico onde ele se encontra.
    //OBS. cCaminho deve estar no formato \NOME_REAL_ARQUIVO.EXTENÇÂO exemplo: \filetosend.pdf
    //OBS².cCaminho segue a partir do ROOTPATH do appserver
    //oSWWAPP:SetFile(cNomArq,cTpArquivo,Encode64(MemoRead(cCaminho)))
    ADir(cCaminho, aFiles, aSizes)//Verifica o tamanho do arquivo, parâmetro exigido na FRead.
    nHandle := fopen(cCaminho , FO_READWRITE + FO_SHARED )
    cString := ""
    FRead( nHandle, cString, aSizes[1] ) //Carrega na variável cString, a string ASCII do arquivo.
    
    //Bruno Lage 
    fClose(nHandle)
    
    cTexto    := Encode64(cString) //Converte o arquivo para BASE64
    cStrE64   := Encode64(cString)
    
    //bruno Lage 
    //Decode64(cTexto,"c:\\temp\\validador.pdf",.F.)
        
    oSWWAPP:SetFile(cNomArq,cTpArquivo,cTexto) 
 
    // Realiza o envio da mensagem
    If oSWWAPP:FileSend()
 
        // Pega o JSON de retorno da requisiçao
        // Cada mensagem enviada retorna um identificador de protocolo
        // no formato "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX".
        cProtocolo := oSWWAPP:GetResponse()
 
    Else
 
        // Em caso de falha no envio, recupera o erro
        MSgStop(oSWWAPP:GetLastError(),'FileSend() - Falha no envio da requisição')
 
    Endif
 
    //Coloco o JSON vindo da classe SWWAPP no objeto oJson desta função
    cErro := oJson:fromJSON(cProtocolo)
 
    //Verifico se ocorreu algum erro no metodo fromJSON
    If Len(AllTrim(cErro)) == 0
        //Ja trato o JSON e retorno apenas o protocolo para facilitar no uso da USER FUNCTION
        cProtocolo:=oJson:GetJsonObject("result")
    else
        MsgStop(oSWWAPP:GetLastError(),'oJson:fromJSON(cProtocolo) - Falha na inserção de dados com a classe JsonObject()')
    EndIf
    
    
RETURN cProtocolo
*/

//   +------------------------------------------------------------------------------+
//   |  Descrição:    Envia mensagem passada por parametro para o numero, tambem      |
//   |  passado por parametro                                                                       |
//   +------------------------------------------------------------------------------+
//   |  Retorna um JSON com o protocolo, exemplo:                                   |
//   |  {"result":"5D0F246F-DF3A-418F-9E65-E1BA954329C0"}                             |
//   +------------------------------------------------------------------------------+
 
USER FUNCTION SWENV(cNumCel,cMsg,cReference)
    Local oSWWAPP
    Local cProtocolo
    Local oJson := JsonObject():new()
    DEFAULT cReference  := " "
 
    //Instancio a Classe que faz ligação com a API SWWAPP
    //oSWWAPP  := SWWAPP():New(SuperGetMv("MV_CELZAP"),SuperGetMv("MV_CHAVZAP"),SuperGetMv("MV_HTTPZAP"))
    oSWWAPP  := SWWAPP():New("5527995295180"        ,"Yp522crJhANr0PZo0kCX"  ,"13012"                )
    
    // Define as propriedades minimas para envio de mensagem
 
    //Define o numero destino
    oSWWAPP:SetDestiny(cNumCel)
 
    // Informa o texto da mensagem
    oSWWAPP:SetText(EncodeUTF8(cMsg))
 
    // Define a Referencia, forma identificar a mensagem para uso posterior
    oSWWAPP:SetReference(cReference)
 
    // Realiza o envio da mensagem
    If oSWWAPP:MessageSend()
 
        // Pega o JSON de retorno da requisiçao
        // Cada mensagem enviada retorna um identificador de protocolo
        // no formato "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX".
        cProtocolo := oSWWAPP:GetResponse()
 
    Else
 
        // Em caso de falha no envio, recupera o erro
        MSgStop(oSWWAPP:GetLastError(),'MessageSend() - Falha no envio da requisição')
 
    Endif
 
    //Coloco o JSON vindo da classe SWWAPP no objeto oJson desta função
    cErro := oJson:fromJSON(cProtocolo)
 
    //Verifico se ocorreu algum erro no metodo fromJSON
    If Len(AllTrim(cErro)) == 0
        //Ja trato o JSON e retorno apenas o protocolo para facilitar no uso da USER FUNCTION
        cProtocolo:=oJson:GetJsonObject("result")
    else
        MsgStop(oSWWAPP:GetLastError(),'oJson:fromJSON(cProtocolo) - Falha na inserção de dados com a classe JsonObject()')
    EndIf
RETURN cProtocolo
 

//   +------------------------------------------------------------------------------+
//   |  Descrição: Envia uma mensagem com opções para o numero passado                  |
//   |  Parametro cOpcoes tem que ser no formato : "'[OPCAO1;OPCAO2;OPCAO3]'"       |
//   +------------------------------------------------------------------------------+
//   |  Retorna um JSON com o protocolo, exemplo:                                   |
//   |  {"result":"5A80CE9D-621C-4533-AE40-CFB4C45C307B"}                             |
//   +------------------------------------------------------------------------------+
 
USER FUNCTION ENVPGZAP(cNumCel, cMsg, cReference, cOpcoes)
  //Local oSWWAPP  := SWWAPP():New(SuperGetMv("MV_CELZAP"),SuperGetMv("MV_CHAVZAP"),SuperGetMv("MV_HTTPZAP"))
    Local oSWWAPP  := SWWAPP():New("5527995295180"        ,"Yp522crJhANr0PZo0kCX"  ,"13012"                )
    Local cProtocolo
    Local cErro
    Local oJson := JsonObject():new()
    DEFAULT cReference  := " "
 
    //Define o numero destino
    oSWWAPP:SetDestiny(cNumCel)
 
    // Informa o texto da mensagem
    oSWWAPP:SetText(EncodeUTF8(cMsg))
 
    // Define a Referencia, forma identificar a mensagem para uso posterior
    oSWWAPP:SetReference(cReference)
 
    //Determino as repostas validas
    oSWWAPP:SetQuestion(cOpcoes)
 
    // Realiza o envio da mensagem
    If oSWWAPP:QuestionSend()
 
        // Pega o JSON de retorno da requisiçao
        // Cada mensagem enviada retorna um identificador de protocolo
        // no formato "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX".
        cProtocolo := oSWWAPP:GetResponse()
 
    Else
 
        // Em caso de falha no envio, recupera o erro
        MSgStop(oSWWAPP:GetLastError(),'QuestionSend() - Falha no envio da requisição')
 
    Endif
    //Coloco o JSON vindo da classe SWWAPP no objeto oJson desta função
    cErro := oJson:fromJSON(cProtocolo)
 
    //Verifico se ocorreu algum erro no metodo fromJSON
    If Len(AllTrim(cErro)) == 0
        //Ja trato o JSON e retorno apenas o protocolo para facilitar no uso da USER FUNCTION
        cProtocolo:=oJson:GetJsonObject("result")
    else
        MsgStop(oSWWAPP:GetLastError(),'oJson:fromJSON(cProtocolo) - Falha na inserção de dados com a classe JsonObject()')
    EndIf
RETURN cProtocolo
 

//   +------------------------------------------------------------------------------+
//   |  Descrição: Função para verificar se a mensagem do protocolo passado por     |
//   |  parametro foi lida/ e ou recebida.                                          |
//   +------------------------------------------------------------------------------+
//   |  Retorna um JSON, exemplo:                                                   |
//   |  {"reference":"","sent":"true","sent_datehour":"2020-01-24T09:51:25",        |
//   |  "destiny":"5511xxxxxxxxx","error":"false"}                                  |
//   +------------------------------------------------------------------------------+

USER FUNCTION SWREMGWAP(cProtocolo)
  //Local oSWWAPP  := SWWAPP():New(SuperGetMv("MV_CELZAP"),SuperGetMv("MV_CHAVZAP"),SuperGetMv("MV_HTTPZAP"))
    Local oSWWAPP  := SWWAPP():New("5527995295180"        ,"Yp522crJhANr0PZo0kCX"  ,"13012"                )
    Local cResponse
 
    // Informa o protococolo da mensagem a ser pesquisada
    oSWWAPP:SetProtocol(cProtocolo)
 
    //Realizo a Procura da mensagem
    If oSWWAPP:MessageSearch()
 
        //Armazeno o JSON retornado em caso de sucesso
        cResponse := oSWWAPP:GetResponse()
 
    Else
     
        MsgStop(oSWWAPP:GetLastError(),'MessageSearch() - Falha no envio da requisição')
 
    Endif
 
RETURN cResponse
 

//   +--------------------------------------------------------------------------------+
//   |  Descrição: Função para verificar se houve a resposta da pergunta enviada.     |
//   |                                                                                |
//   +--------------------------------------------------------------------------------+
//   |  Retorna um JSON, exemplo de um caso onde eu respondi a pergunta com um "Sim": |
//   |  {"reference":"","sent":"true","sent_datehour":"2020-01-24T10:02:28",          |
//   |   "destiny":"5511xxxxxxxxx","error":"false","question_answer":"true",          |
//   |  "question_answer_correct":"true","question_response":"Sim",                   |
//   |  "question_expired":"false"}                                                   |
//   +--------------------------------------------------------------------------------+
 
USER FUNCTION RECPGZAP(cProtocolo)
  //Local oSWWAPP  := SWWAPP():New(SuperGetMv("MV_CELZAP"),SuperGetMv("MV_CHAVZAP"),SuperGetMv("MV_HTTPZAP"))
    Local oSWWAPP  := SWWAPP():New("5527995295180"        ,"Yp522crJhANr0PZo0kCX"  ,"13012"                )  
    Local cResponse
 
    // Informa o protococolo da mensagem a ser pesquisada
    oSWWAPP:SetProtocol(cProtocolo)
 
    //Procuro pela pergunta
    If oSWWAPP:QuestionSearch()
 
        //Armazeno o JSON retornado em caso de sucesso
        cResponse := oSWWAPP:GetResponse()
 
    Else
 
        MsgStop(oSWWAPP:GetLastError(),'QuestionSearch() - Falha no envio da requisição')
 
    Endif
RETURN cResponse
 

//   +----------------------------------------------------------------------------------------+
//   |  Descrição:    Função para verificar se alguem requisitou um inicio de conversa        |
//   |  Retornará um ARRAY com X objetos JSON onde cada um virá no seguinte formato:          |
//   |  {"message_datehour_first":"2020-01-08T14:24:21","phone":"5511xxxxxxxxx",              |
//   |  "messages_count":1,"messages":[{"datehour":"2020-01-08T14:24:21",                     |
//   |  ,"message":"TESTE","id":"10609"}],"message_datehour_last":"2020-01-08T14:24:21"}.     |
//   |                                                                                        |
//   |  X == NUMERO DE REQUISIÇÕES EM ABERTO(MENSAGENS ENVIADAS POR USUARIOS PARA O NUMERO    |
//   |  DO CHAT BOT QUE AINDA NÃO FORAM RESPONDIDAS POR ELE)                                  |
//   +----------------------------------------------------------------------------------------+
//   |                                                                                        |
//   +----------------------------------------------------------------------------------------+
 
USER FUNCTION RECRSZAP()
  //Local oSWWAPP  := SWWAPP():New(SuperGetMv("MV_CELZAP"),SuperGetMv("MV_CHAVZAP"),SuperGetMv("MV_HTTPZAP"))
    Local oSWWAPP  := SWWAPP():New("5527995295180"        ,"Yp522crJhANr0PZo0kCX"  ,"13012"                )
    Local cResponse
    Local cErro
    Local oJson := JsonObject():new()
    Local aArray:={}
 
    //Realizo o Request
    If oSWWAPP:RequestsStart()
 
        //Armazeno o JSON retornado em caso de sucesso
        cResponse := oSWWAPP:GetResponse()
    Else
        MsgStop(oSWWAPP:GetLastError(),'RequestsStart() - Falha no envio da requisição')
    ENDIF
 
    //Coloco o JSON vindo da classe SWWAPP no objeto oJson desta função
    cErro := oJson:fromJSON(cResponse)
 
    //Verifico se ocorreu algum erro no metodo fromJSON
    If Len(AllTrim(cErro)) == 0
        aArray:=oJson:GetJsonObject("root")
    else
        MsgStop(oSWWAPP:GetLastError(),'oJson:fromJSON(cResponse) - Falha na inserção de dados com a classe JsonObject()')
    EndIf
RETURN aArray

