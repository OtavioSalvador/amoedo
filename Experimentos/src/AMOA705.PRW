#include "PROTHEUS.CH"
#include "RWMAKE.CH"
#INCLUDE 'FONT.CH'
#INCLUDE 'COLORS.CH'
#INCLUDE "TOPCONN.CH"

 
/*------------------------------------------------------------------------
| Funcao    | AMOA705 | Otavio Salvador                | Data | 07/07/18  |
|-------------------------------------------------------------------------|
| Descricao | Envia email de contratos por vencer em ?? meses             |
|-------------------------------------------------------------------------|
| Uso       | AMOEDO - Chamado pelo GCT -> Processamento schedulado       |
|           |                                                             |
 ------------------------------------------------------------------------*/

User Function AMOA705()
    Local _cHTML      := ""
	Local cAlias      := GetNextAlias()
	Local cEOF        := CHR(13)+chr(10)
	Local _cAssunto   := "Aviso de vencimento de contrato - Novo Teste"
	Local _cRemetente := "otavio.bigboss@gmail.com"
 
	_cHTML := '<!DOCTYPE html>'
	_cHTML += '<html>'
    _cHTML += '<head>'
    _cHTML += '<title>'+_cAssunto+'</title>'
    _cHTML += '   <style>'
    _cHTML += '        table, th, td{'
    _cHTML += '             border:1px solid black;'
    _cHTML += '             border-collapse:collapse;' 
    _cHTML += '             background-color: #F7F096;'
    _cHTML += '            }'
    _cHTML += '        th, td{'
    _cHTML += '             padding:5px;'
    _cHTML += '            }'
    _cHTML += '   </style>'
    _cHTML += '</head>'
    _cHTML += '<body>'
    _cHTML += '     <table>'
    _cHTML += '          <tr>'
    _cHTML += '             <th>Filial</th>'
    _cHTML += '             <th>Vencimento</th>'
    _cHTML += '             <th>Contrato No.</th>'
    _cHTML += '             <th>Endereço</th>'
    _cHTML += '          </tr>'    
     
     
//	Tabela CN9 para buscar Contratos com vencimento menores que 7 meses.
    cQuery := " SELECT  CN9_FILIAL, CN9_DTFIM, CN9_NUMERO, CN9_END " + cEof
    cQuery += " FROM " + RetSQLName("CN9400") + " CN9 " + cEof
    cQuery += " WHERE CN9.D_E_L_E_T_ = ''   " + cEof
    cQuery += "   AND substring(CN9_DTFIM,1,6) = '"+substr(DTOS(dDataBase+210),1,6)+"'" + cEof 
    cQuery += "   AND CN9_TPCTO IN ("+SuperGetMV("MV_TPCTO",.F.,"'003','004','009'")+")" + cEof
    //cQuery += "   AND CN9_TPCTO IN ('003','004','009')" + cEof
    cQuery += " ORDER BY 1,2,3 " + cEof

	memowrit("C:\temp\AMOA705.sql",cQuery)

    cQuery := changeQuery(cQuery)

    dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAlias,.T.,.F.)

    //TcQuery(cQuery,,cAlias)
    (cAlias)->( dbGoTop() )
    
    _cFilialAnt := (cAlias)->CN9_FILIAL
	
msgstop(substr((cAlias)->CN9_DTFIM,1,6)+CHR(13)+;
        SUBSTR( DTOS(dDataBase+210),1,6 ))	
	
    While (cAlias)->( !Eof() )
    
         _cHTML += '             <tr>'
         _cHTML += '               <td>'+(cAlias)->CN9_FILIAL +'</td>'         
         _cHTML += '               <td>'+DTOC(STOD((cAlias)->CN9_DTFIM)) +'</td>'
         _cHTML += '               <td>'+(cAlias)->CN9_NUMERO +'</td>'
         _cHTML += '               <td>'+(cAlias)->CN9_END +'</td>'                  
         _cHTML += '             </tr>'    

		(cAlias)->( dbSkip() )
		if _cFilialAnt <> (cAlias)->CN9_FILIAL
		   _cFilialAnt := (cAlias)->CN9_FILIAL
		   _cHTML += '<br/>'
		endif   
  	Enddo
  	
    _cHTML += '      </Table'
    _cHTML += '</body>'    
    _cHTML += '</html>'    
  	
    // Envia o e-mail
	U_FEnvMail(_cRemetente, _cAssunto, _cHTML)
    
Return


/*------------------------------------------------------------------------
| Funcao    | zEnvMail | Otavio Salvador               | Data | 07/07/18  |
|-------------------------------------------------------------------------|
| Descricao | Envia email de contratos                                    |
|-------------------------------------------------------------------------|
| Uso       | AMOEDO - Chamado pelo GCT -> Processamento schedulado       |
|           |                                                             |
 ------------------------------------------------------------------------*/
USER Function FEnvMail(cPara, cAssunto, cCorpo, aAnexos, lMostraLog, lUsaTLS)
    Local aArea        := GetArea()
    Local nAtual       := 0
    Local lRet         := .T.
    Local oMsg         := Nil
    Local oSrv         := Nil
    Local nRet         := 0
    Local cFrom        := "otavio.salvador@amoedo.com.br"  //Alltrim(GetMV("MV_RELACNT"))
    Local cUser        := SubStr(cFrom, 1, At('@', cFrom)-1)
    Local cPass        := "Falange_11"     //Alltrim(GetMV("MV_RELPSW"))
    Local cSrvFull     := "smtp-rec.amoedo.com.br:587"  //Alltrim(GetMV("MV_RELSERV"))
    Local cServer      := Iif(':' $ cSrvFull, SubStr(cSrvFull, 1, At(':', cSrvFull)-1), cSrvFull)
    Local nPort        := Iif(':' $ cSrvFull, Val(SubStr(cSrvFull, At(':', cSrvFull)+1, Len(cSrvFull))), 587)
    Local nTimeOut     := 120  //GetMV("MV_RELTIME")
    Local cLog         := ""
    Default cPara      := ""
    Default cAssunto   := ""
    Default cCorpo     := ""
    Default aAnexos    := {}
    Default lMostraLog := .F.
    Default lUsaTLS    := .F.
/*
mSGsTOP("Entrou na funcao FENVMAIL()"+CHR(13)+;
        "MV_RELACNT: "+Alltrim(GetMV("MV_RELACNT"))+chr(13)+;
        "MV_RELPSW: "+Alltrim(GetMV("MV_RELPSW"))+chr(13)+;
        "MV_RELSERV: "+Alltrim(GetMV("MV_RELSERV"))+chr(13)+;
        "MV_RELTIME: "+str(GetMV("MV_RELTIME")))
*/
//Se tiver em branco o destinatário, o assunto ou o corpo do email
    If Empty(cPara) .Or. Empty(cAssunto) .Or. Empty(cCorpo)
        cLog += "001 - Destinatario, Assunto ou Corpo do e-Mail vazio(s)!" + CRLF
        lRet := .F.
    EndIf
     
    If lRet
        //Cria a nova mensagem
        oMsg := TMailMessage():New()
        oMsg:Clear()
         
        //Define os atributos da mensagem
        oMsg:cFrom    := cFrom
        oMsg:cTo      := cPara
        oMsg:cSubject := cAssunto
        oMsg:cBody    := cCorpo
         
        //Percorre os anexos
        For nAtual := 1 To Len(aAnexos)
            //Se o arquivo existir
            If File(aAnexos[nAtual])
             
                //Anexa o arquivo na mensagem de e-Mail
                nRet := oMsg:AttachFile(aAnexos[nAtual])
                If nRet < 0
                    cLog += "002 - Nao foi possivel anexar o arquivo '"+aAnexos[nAtual]+"'!" + CRLF
                EndIf
             
            //Senao, acrescenta no log
            Else
                cLog += "003 - Arquivo '"+aAnexos[nAtual]+"' nao encontrado!" + CRLF
            EndIf
        Next
         
        //Cria servidor para disparo do e-Mail
        oSrv := tMailManager():New()
         
        //Define se irá utilizar o TLS
        If lUsaTLS
            oSrv:SetUseTLS(.T.)
        EndIf
         
        //Inicializa conexão
        nRet := oSrv:Init("", cServer, cUser, cPass, 0, nPort)
        If nRet != 0
            cLog += "004 - Nao foi possivel inicializar o servidor SMTP: " + oSrv:GetErrorString(nRet) + CRLF
            lRet := .F.
        EndIf
         
        If lRet
            //Define o time out
            nRet := oSrv:SetSMTPTimeout(nTimeOut)
            If nRet != 0
                cLog += "005 - Nao foi possivel definir o TimeOut '"+cValToChar(nTimeOut)+"'" + CRLF
            EndIf
             
            //Conecta no servidor
            nRet := oSrv:SMTPConnect()
            If nRet <> 0
                cLog += "006 - Nao foi possivel conectar no servidor SMTP: " + oSrv:GetErrorString(nRet) + CRLF
                lRet := .F.
            EndIf
             
            If lRet
                //Realiza a autenticação do usuário e senha
                nRet := oSrv:SmtpAuth(cFrom, cPass)
                If nRet <> 0
                    cLog += "007 - Nao foi possivel autenticar no servidor SMTP: " + oSrv:GetErrorString(nRet) + CRLF
                    lRet := .F.
                EndIf
                 
                If lRet
                    //Envia a mensagem
                    nRet := oMsg:Send(oSrv)
                    If nRet <> 0
                        cLog += "008 - Nao foi possivel enviar a mensagem: " + oSrv:GetErrorString(nRet) + CRLF
                        lRet := .F.
                    EndIf
                EndIf
                 
                //Disconecta do servidor
                nRet := oSrv:SMTPDisconnect()
                If nRet <> 0
                    cLog += "009 - Nao foi possivel disconectar do servidor SMTP: " + oSrv:GetErrorString(nRet) + CRLF
                EndIf
            EndIf
        EndIf
    EndIf
     
    //Se tiver log de avisos/erros
    If !Empty(cLog)
        cLog := "zEnvMail - "+dToC(Date())+ " " + Time() + CRLF + ;
            "Funcao - " + FunName() + CRLF + CRLF +;
            "Existem mensagens de aviso: "+ CRLF +;
            cLog
        ConOut(cLog)
         
        //Se for para mostrar o log visualmente e for processo com interface com o usuário, mostra uma mensagem na tela
        If lMostraLog .And. ! IsBlind()
            Aviso("Log", cLog, {"Ok"}, 2)
        EndIf
    EndIf
     


/*


    //Cria a nova mensagem
    oMsg := TMailMessage():New()
    oMsg:Clear()
         
    //Define os atributos da mensagem
    oMsg:cFrom    := cFrom
    oMsg:cTo      := cPara
    oMsg:cSubject := cAssunto
    oMsg:cBody    := cCorpo
         
    //Percorre os anexos
    For nAtual := 1 To Len(aAnexos)            
       //Anexa o arquivo na mensagem de e-Mail
       oMsg:AttachFile(aAnexos[nAtual])
    Next
         
    //Cria servidor para disparo do e-Mail
    oSrv := tMailManager():New()
         
    //Define se irá utilizar o TLS
    If lUsaTLS
       oSrv:SetUseTLS(.T.)
    EndIf
         
    //Inicializa conexão
    oSrv:Init("", cServer, cUser, cPass, 0, nPort)
        
    //Define o time out
    oSrv:SetSMTPTimeout(nTimeOut)
        
    //Conecta no servidor
    oSrv:SMTPConnect()

    //Realiza a autenticação do usuário e senha
    oSrv:SmtpAuth(cFrom, cPass)
    
    //Envia a mensagem
    oMsg:Send(oSrv)

    //Disconecta do servidor
    oSrv:SMTPDisconnect()
*/     
    RestArea(aArea)
    
Return lRet

// Fim da rotina AMOA705.PRW