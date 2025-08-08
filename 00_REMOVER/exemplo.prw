#INCLUDE "PROTHEUS.CH"

// --------------------------------------------------------------------------------
// Declaracao da Classe exemplo
// --------------------------------------------------------------------------------

CLASS exemplo 

    // Declaração dos Métodos da Classe
    METHOD New() CONSTRUCTOR
    METHOD destroy()

ENDCLASS

METHOD new() CLASS exemplo
return(self)       

METHOD destroy() CLASS exemplo
    freeObj(::Self)
return
