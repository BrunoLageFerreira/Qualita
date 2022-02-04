#INCLUDE "Protheus.ch"
#INCLUDE "RwMake.ch"
#INCLUDE "topconn.ch" 
#INCLUDE "Colors.ch" 
#INCLUDE "JPEG.CH"

/*
Programa        : Programa MT103VCC.prw
Objetivo        : P.Entrada compilado para remover msg de aviso e eventual erro na entrada da NF-e pelo conexção nfe
Autor           : Bruno Lage Ferreira	
Data/Hora       : 03/02/2022 17:30
Obs.            :
Foi feito uma reunião com o com Felipe do conexaonfe e raquel da Qualita para exemplificar o erro
Felipe testou o comportamento do ponto de entrada retornando .F. nas msg. que solucionou o problema.

*/

User Function MT103VCC()
/*****************************************************************************************
* Programa principal 
*
***/  

//AVISO("MT103VCC","MT103VCC",{"OK"},2)

Return({.F.,.F.,.F.,.F.})
