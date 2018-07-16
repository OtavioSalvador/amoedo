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
    Local _lPassa     := .T. 
    Local _cTipo
	Local cAlias      := GetNextAlias()
	Local cEOF        := CHR(13)+chr(10)
	Local _cAssunto   := "Aviso de Vencimento de Contrato - Em Teste" 
	Local _cRemetente := SuperGetMV("MV_CN9REM",.F.,"flavio.simoes@amoedo.com.br,otavio.salvador@amoedo.com.br,liegep@amoedo.com.br")
    //Local _cRemetente := "otavio.salvador@amoedo.com.br,otavio.bigboss@gmail.com"  
    
    // Montagem do HTML para o envio...
	_cHTML := '<!DOCTYPE html>'
	_cHTML += '<html>'
    _cHTML += '<head>'
    _cHTML += '<title>'+_cAssunto+'</title>'
    _cHTML += '   <style>'
    _cHTML += '			table, th, td{'
    _cHTML += '             border:1px solid black;'
    _cHTML += '             border-collapse:collapse;' 
    _cHTML += '             background-color: #C9D2D9;'
    _cHTML += '         }'
    _cHTML += '			th, td{'
    _cHTML += '             padding:5px;'
    _cHTML += '         }'
    _cHTML += '			#cabec{'
    _cHTML += '             width: 600px;'
    _cHTML += '             height: 30px;'
    _cHTML += '             color: #FE0000;'
    _cHTML += '             text-align:left;'
    _cHTML += '             font-size: 26px;'
    _cHTML += '             text-shadow: 1px 2px #5F5F5D; '
    _cHTML += '             -moz-text-shadow: 1px 2px #5F5F5D;'
    _cHTML += '             -webkit-text-shadow: 1px 2px #5F5F5D;'
    _cHTML += '          }'   
    _cHTML += '   </style>'
    _cHTML += '</head>'
    _cHTML += '<body>'
    _cHTML += '     <div id="cabec">'+_cAssunto+'</div><br/>'
    _cHTML += '     <table>'
    _cHTML += '          <tr>'
    _cHTML += '             <th>Filial</th>'
    _cHTML += '             <th>Vencimento</th>'
    _cHTML += '             <th>Contrato No.</th>'
    _cHTML += '             <th>Endereço</th>'
    _cHTML += '             <th>Tipo</th>'
    _cHTML += '          </tr>'    
     
    // 7 MESES = 210
    // 3 MESES = 90  
    // 
    
    //	Tabela CN9 para buscar Contratos com vencimento menores que 7 meses.
    cQuery := " SELECT  CN9_FILIAL, CN9_DTFIM, CN9_NUMERO, CN9_END, CN1_CCTO " + cEof
    cQuery += " FROM " + RetSQLName("CN9400") + " CN9 " + cEof
    cQuery += "    , " + RetSQLName("CN1400") + " CN1 " + cEof
    cQuery += " WHERE CN9.D_E_L_E_T_ = ''   " + cEof
    cQuery += "   AND CN1_FILIAL = CN9_FILIAL  " + cEof
    cQuery += "   AND CN1_CODIGO = CN9_TPCTO  " + cEof
    
    cQuery += "   AND substring(CN9_DTFIM,1,6) = ( CASE " + cEof
    cQuery += "          	WHEN CN1_CCTO = '1' THEN '"+substr(DTOS(dDataBase+SuperGetMV('MV_CN9QTS',.F.,30)),1,6)+"'" + cEof  
    cQuery += "          	WHEN CN1_CCTO = '2' THEN '"+substr(DTOS(dDataBase+SuperGetMV('MV_CN9QTL',.F.,30)),1,6)+"'" + cEof
    cQuery += "          	WHEN CN1_CCTO = '3' THEN '"+substr(DTOS(dDataBase),1,6)+"'" + cEof
    cQuery += "          ELSE ' ' " + cEof  
    cQuery += "          END )  " + cEof
     
    cQuery += "   AND CN1_CCTO IN ('1','2') " + cEof
    cQuery += " ORDER BY 1,5,2,3 " + cEof

	memowrit("C:\temp\AMOA705.sql",cQuery)

    cQuery := changeQuery(cQuery)

    dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAlias,.T.,.F.)

    //TcQuery(cQuery,,cAlias)
    (cAlias)->( dbGoTop() )

  	if (cAlias)->( Eof() )
  	  _lPassa   := .F.
  	  MsgStop("Não há eMail a enviar !")
  	endif
    
    _cFilialAnt := (cAlias)->CN9_FILIAL
	
    While (cAlias)->( !Eof() )
          do Case
             case (cAlias)->CN1_CCTO == '1' ; _cTipo := 'Servico'
             case (cAlias)->CN1_CCTO == '2' ; _cTipo := 'Locacao'
             case (cAlias)->CN1_CCTO == '3' ; _cTipo := 'Outros'             
          endcase
    
         _cHTML += '             <tr>'
         _cHTML += '               <td>'+(cAlias)->CN9_FILIAL +'</td>'         
         _cHTML += '               <td>'+DTOC(STOD((cAlias)->CN9_DTFIM)) +'</td>'
         _cHTML += '               <td>'+(cAlias)->CN9_NUMERO +'</td>'
         _cHTML += '               <td>'+(cAlias)->CN9_END +'</td>'
         _cHTML += '               <td>'+ _cTipo + '</td'         
         _cHTML += '             </tr>'    

		(cAlias)->( dbSkip() )
		if _cFilialAnt <> (cAlias)->CN9_FILIAL
		   _cFilialAnt := (cAlias)->CN9_FILIAL
		   _cHTML += '<br>'
		endif   
  	Enddo
  	
    _cHTML += '      </Table'
    _cHTML += '</body>'    
    _cHTML += '</html>'    
  	
  	if _lPassa 
  		// Envia o e-mail
  		U_FEnvMail(_cRemetente, _cAssunto, _cHTML)
  	endif	
    
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
    Local cFrom        := SuperGetMV("MV_CN9ENV",.F.,"contratos@amoedo.com.br")
    Local cUser        := SubStr(cFrom, 1, At('@', cFrom)-1)
    Local cPass        := SuperGetMV("MV_CN9PSS",.F.,"!Mail@0800")
    Local cSrvFull     := SuperGetMV("MV_CN9SRV",.F.,"smtp-rec.amoedo.com.br:587")
    Local cServer      := Iif(':' $ cSrvFull, SubStr(cSrvFull, 1, At(':', cSrvFull)-1), cSrvFull)
    Local nPort        := Iif(':' $ cSrvFull, Val(SubStr(cSrvFull, At(':', cSrvFull)+1, Len(cSrvFull))), 587)
    Local nTimeOut     := SuperGetMV("MV_CN9TIME",.F.,120)
    Local cLog         := ""
    Default cPara      := ""
    Default cAssunto   := ""
    Default cCorpo     := ""
    Default aAnexos    := {}
    Default lMostraLog := .F.
    Default lUsaTLS    := .F.

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
     
    RestArea(aArea)
    
Return lRet

// Fim da rotina AMOA705.PRW


/*-----------------------------------------------------------------------
| PARAMETROS DEFINIDOS:                                                  |
|------------------------------------------------------------------------|
| MV_CN9QTS N 006 - Quantidade de meses, em dias. Ex. 3 meses = 90 dias  |
|                                                                        |
| MV_CN9QTL N 006 - Quantidade de meses, em dias. Ex. 12 meses = 365 dias|
|                                                                        |
| MV_CN9TPC C 050 - Tipos de contratos Ex. '003','004','009'             |
|                                                                        | 
| MV_CN9PSS C 020 - Senha da conta de email exclusiva para Contratos.    |
|                   Ex. !Mail@0800                                       | 
| MV_CN9ENV  C 050 - Conta de email exclusiva para Contratos.            |
|                   Ex. contratos@amoedo.com.br                          |
| MV_CN9REM C 300 - Emails de quem estão recebento, separados por virgula|
|                   Ex. liegep@amoedo.com.br,fabio.simoes@amoedo.com.br  |
| MV_CN9SRV C  50 - Endereco do servidor. Ex."smtp-rec.amoedo.com.br:587"|
| MV_CN9TIME N 06 - Time Out Ex.120                                      |
 -----------------------------------------------------------------------*/