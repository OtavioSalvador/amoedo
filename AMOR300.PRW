#include "PROTHEUS.CH"
#include "RWMAKE.CH"
/*------------------------------------------------------------------------
| Funcao    | AMOR300 | Otavio Salvador                | Data | 03/07/18  |
|-------------------------------------------------------------------------|
| Descricao | Listagem dos Contratos.                                     |
|-------------------------------------------------------------------------|
| Uso       | AMOEDO - Chamado pelo GCT -> Relatórios                     |
|           |                                                             |
 ------------------------------------------------------------------------*/
user function AMOR300()
	
local oReport
local aArea   := GetArea()
private cPerg := Padr("AMOR300",Len(SX1->X1_GRUPO))
	
PutSx1(cPerg,"01","Filial De?       "  ,"","","mv_ch1","C",4 ,0,0,"G","","   ","","","mv_par01")
PutSx1(cPerg,"02","Filial Ate?      "  ,"","","mv_ch2","C",4 ,0,0,"G","","   ","","","mv_par02")
PutSx1(cPerg,"03","Tp.Contrato De?  "  ,"","","mv_ch3","C",3 ,0,0,"G","","   ","","","mv_par03")
PutSx1(cPerg,"04","Tp.Contrato Ate? "  ,"","","mv_ch4","C",3 ,0,0,"G","","   ","","","mv_par04")

Pergunte(cPerg, .F.)
	
oReport := ReportDef()
oReport:PrintDialog()
	
RestArea(aArea)
	
return


/*------------------------------------------------------------------------
| Funcao    | ReportDef | Otavio Salvador              | Data | 03/07/18  |
|-------------------------------------------------------------------------|
| Descricao | Definição layout relatório.                                 |
|-------------------------------------------------------------------------|
| Uso       | AMOEDO                                                      |
 ------------------------------------------------------------------------*/
static function ReportDef()
	
local oReport
local oSection0    
local cTitulo := "Contratos"
	
dbSelectArea("SX3")
SX3->(dbSetOrder(2))

oReport := TReport():New("AMOR300",cTitulo,cPerg,{|oReport| __PRPrint(oReport)},cTitulo,.T.,,.T.,,.T.,,)
oReport:SetPortrait() // SetLandscape() SetPortrait() 
  
//oReport:HideParamPage()   // Desabilita a impressao da pagina de parametros.
oReport:nFontBody	:= 09   // Define o tamanho da fonte.
oReport:SetLineHeight(48)

oSection0 := TRSection():New(oReport,cTitulo)
	                                                                                                                                                                                                                  
TRCell():New(oSection0,"CN9_FILIAL" ,"CN9",(SX3->(dbSeek("CN9_FILIAL")),X3Titulo()),,04,.F.,{||cCN9_FILIAL}  ,,.T.,,,,)
TRCell():New(oSection0,"CN9_TPCTO"  ,"CN9","Tipo"                                  ,,TamSX3("CN9_TPCTO")[1]  ,.F.,{||cCN9_TPCTO}  ,,.T.,,,,)
TRCell():New(oSection0,"POSICIONE('CN1',1,XFILIAL('CN1')+CN9_TPCTO,'CN1_DESCRI')" ,"CN9","Desc.Tipo",,TamSX3("CN9_DESC")[1] ,.F.,{||cCN9_DESC}    ,,.T.,,,,)
TRCell():New(oSection0,"CN9_NUMERO" ,"CN9",(SX3->(dbSeek("CN9_NUMERO")),X3Titulo()),,TamSX3("CN9_NUMERO")[1] ,.F.,{||cCN9_NUMERO}  ,,.T.,,,,) 
TRCell():New(oSection0,"CN9_DTFIM"  ,"CN9",(SX3->(dbSeek("CN9_DTFIM")) ,X3Titulo()),,10                      ,.F.,{||cCN9_DTFIM}   ,,.T.,,,,)
TRCell():New(oSection0,"CN9_SITUAC" ,"CN9",(SX3->(dbSeek("CN9_SITUAC")),X3Titulo()),,15                      ,.F.,{||cCN9_SITUAC}  ,,.T.,,,,)

return oReport


/*------------------------------------------------------------------------
| Funcao    | __PRPrint | Otavio Salvador              | Data | 03/07/18  |
|-------------------------------------------------------------------------|
| Descricao | Impressão do relatório.                                     |
|-------------------------------------------------------------------------|
| Uso       | AMOEDO                                                      |
 ------------------------------------------------------------------------*/
static function __PRPrint(oReport)
	
local oSection0    := oReport:Section(1)
local cEmpAux      := '40'
local cFilAux      := ""
local cEmpBkp      := cEmpAnt
local cFilBkp      := cFilAnt
local cQuery       := ""
local x,y,w
local cEOL         := chr(13)+chr(10)

private cAlias     := GetNextAlias()
  
dbSelectArea("SM0")
SM0->(dbGoTop())
while !SM0->(Eof())
    if SM0->M0_CODIGO == cEmpAux
       cFilAux := SM0->M0_CODFIL
       exit
    endif
    SM0->(dbSkip())
end
	
if cFilAux == ""
   MsgStop("Empresa Informada é Inválida!")
   return
endif
	
cEmpAnt := cEmpAux
cFilAnt := cFilAux
	
cQuery := " SELECT " + cEOL 
cQuery += "        CN9_FILIAL  " + cEOL
cQuery += "      , CN9_TPCTO " + cEOL 
cQuery += "      , CN1_DESCRI AS CN9_DESC " + cEOL
cQuery += "      , CN9_NUMERO " + cEOL
cQuery += "      , CN9_DTFIM " + cEOL
cQuery += "      , CN9_SITUAC " + cEOL
     
cQuery += " FROM "+RetSqlName("CN9400")+" CN9 " + cEOL
cQuery += "    , "+RetSqlName("CN1400")+" CN1 " + cEOL

cQuery += " WHERE CN9.D_E_L_E_T_ = '' " + cEOL
cQuery += "   AND CN1.D_E_L_E_T_ = '' " + cEOL
  
cQuery += "   AND CN9_FILIAL = CN1_FILIAL " + cEOL
cQuery += "   AND CN9_TPCTO = CN1_CODIGO " + cEOL
  
cQuery += "   AND CN9_FILIAL BETWEEN '"+mv_par01+"' AND '"+mv_par02+"' " + cEOL
cQuery += "   AND CN9_TPCTO  BETWEEN '"+mv_par03+"' AND '"+mv_par04+"' " + cEOL
  
cQuery += " ORDER BY 1,2 " + cEOL
	 
MemoWrite("C:\TEMP\AMOR300.SQL", cQuery)  

cQuery := changeQuery(cQuery)
	
if Select(cAlias) > 0
   dbSelectArea(cAlias)
   (cAlias)->(dbCloseArea())
endIf
	
dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAlias,.T.,.F.)
	
dbSelectArea(cAlias)
(cAlias)->(dbGoTop())
	
oReport:SetMeter((cAlias)->(RecCount()))

if (cAlias)->(!EOF())
   oReport:SkipLine(1)
   oReport:PrintText(Padc("Listagem dos Contratos",125),oReport:Row(),0,,,,.T.)
   oReport:SkipLine(1)
   oReport:Line(oReport:Row(),15,oReport:Row(),oReport:PageWidth()-35,)
   oSection0:Init()
   
   cCN9_FILIAL_ANT := (cAlias)->CN9_FILIAL
   cCN9_TPCTO_ANT  := (cAlias)->CN9_TPCTO
   
   do while (cAlias)->(!EOF())
       cCN9_FILIAL := (cAlias)->CN9_FILIAL 
       cCN9_TPCTO  := (cAlias)->CN9_TPCTO
       cCN9_DESC   := (cAlias)->CN9_DESC
       cCN9_NUMERO := (cAlias)->CN9_NUMERO      
       cCN9_DTFIM  := DTOC( STOD( (cAlias)->CN9_DTFIM  ) )
       do Case
          Case (cAlias)->CN9_SITUAC == '01'
               cCN9_SITUAC := "Cancelado"
          Case (cAlias)->CN9_SITUAC == '02'
               cCN9_SITUAC := "Elaboração" 
          Case (cAlias)->CN9_SITUAC == '03'
               cCN9_SITUAC := "Emitido" 
          Case (cAlias)->CN9_SITUAC == '04'
               cCN9_SITUAC := "Aprovação" 
          Case (cAlias)->CN9_SITUAC == '05'
               cCN9_SITUAC := "Vigente" 
          Case (cAlias)->CN9_SITUAC == '06'
               cCN9_SITUAC := "Paralisa." 
          Case (cAlias)->CN9_SITUAC == '07'
               cCN9_SITUAC := "Sol. Finalização" 
          Case (cAlias)->CN9_SITUAC == '08'
               cCN9_SITUAC := "Finali." 
          Case (cAlias)->CN9_SITUAC == '09'
               cCN9_SITUAC := "Revisão" 
          Case (cAlias)->CN9_SITUAC == '10'
               cCN9_SITUAC := "Revisado" 
       otherwise
               cCN9_SITUAC := ""        
       Endcase
       
       oSection0:PrintLine()
       
       (cAlias)->( dbSkip() )
       if cCN9_FILIAL_ANT <> (cAlias)->CN9_FILIAL
          cCN9_FILIAL_ANT := (cAlias)->CN9_FILIAL
          oReport:SkipLine(1)
       endif 
       
       if cCN9_TPCTO_ANT <> (cAlias)->CN9_TPCTO
          cCN9_TPCTO_ANT := (cAlias)->CN9_TPCTO
          oReport:SkipLine(1)
       endif 
         
   enddo
endif
cEmpAnt := cEmpBkp
cFilAnt := cFilBkp

if Select(cAlias) > 0
   dbSelectArea( cAlias )
   dbCloseArea()
endIf

	
return 


// Fim do programa AMOR300.PRW