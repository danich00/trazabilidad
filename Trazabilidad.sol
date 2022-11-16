// Version de solidity del Smart Contract
// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.16;
// Informacion del Smart Contract
// Nombre: Reserva
// Logica: Implementa subasta de productos entre varios participantes

// Declaracion del Smart Contract - Trazabilidad
contract Trazabilidad {
     // ----------- Variables (datos) -----------
    // Información de la Entrega
    enum  Status {ACCEPTED,READY,CLOK,RPOK,CLKO,RPKO,CANCEL,REALIZADA}
    enum  Role {CLIENTE,REPARTIDOR,VENDEDOR}
    
    struct Entrega {
        uint8  numEntrega;
        string  description;
        uint  price;
        uint256 timestamp;
        Status status;
        mapping (Role => address) mapRole; 
    }
   
    uint  priceTrasporte;
    uint8 public numCalculado;
    mapping (uint => Entrega) mapEntrega;

    address payable public owner;
    address payable public contractaddress;
    uint fondostotales = address(this).balance;

    //Constantes Status
    string private ACCEPTED = "ACCEPTED";
    string private READY = "READY";
    string private CLOK = "CLOK";
    string private RPOK = "RPOK";
    string private CLKO = "CLKO";
    string private RPKO = "RPKO";
    string private CANCEL = "CANCEL";
    string private REALIZADA = "REALIZADA";

    //Eventos
    // ----------- Eventos (pueden ser emitidos por el Smart Contract) -----------
    event Msg(string _message);
    event MsgEntrada (string _message ,address _repartidor, address _cliente,uint precio, string _descipcion);
    event MsgEntradaXNumEnt (uint8 _numentrada ,string _descipcion,uint _precio, string _status, address _cliente, address _repartidor, address _vendedor);
    event MsgPrecio(string _message, uint _precio);
    // ----------- Constructor -----------
    // Uso: Inicializa el Smart Contract - Reserva
    constructor() {
        
        // Inicializo el valor a las variables (datos)
        owner = payable(msg.sender);
        contractaddress = payable(address(this));
        numCalculado = 0;
        priceTrasporte = 0.001 ether;
        // Se emite un Evento
        emit Msg("Contrato entraga creada sin Entragas");
    }

    // ------------  Modificadore ------------
    // Modificador
    // Nombre: isRepartidor
    // Uso: Comprueba que es el repartidor de la entrega
    modifier isRepartidor(uint numEnt) {
        require(mapEntrega[numEnt].mapRole[Role.REPARTIDOR] == msg.sender ,"No tienes rol de repartidor o no estas signado como tal");
        _;
   }
    // Modificador
    // Nombre: isCliente
    // Uso: Comprueba que es el cleinte de la entrega
    modifier isCliente (uint numEnt){
        require(mapEntrega[numEnt].mapRole[Role.CLIENTE] == msg.sender ,"No eres cliente de la entrega o no estas asignado como tal");
        _;
   }
    // Modificador
    // Nombre: isOwner
    // Uso: Comprueba que es el owner del contrato
    modifier isOwner {
        require(msg.sender == owner,"No eres creador del contrato");
        _;
   }
   // Modificador
    // Nombre: isNot0x000000
    // Uso: Comprueba que es 0x000000
    modifier isNot0x000000 (address addr) {
        require(addr != address(0), "Not valid address");
        _;
   }

    // ------------ Funciones que modifican datos (set) ------------

    // Funcion
    // Nombre: repartidorFirmaSalida
    // Uso:    Reaprtidor firma la salida al contrato si se cumplen las conciciones
    function repartidorFirmaSalida(uint numEnt) public isRepartidor(numEnt) {
        require(numEnt > 0 && numEnt <= numCalculado,"El Numero de entrega no es correcto");
        require(mapEntrega[numEnt].status == Status.ACCEPTED,"EL estado de la Entraga tiene que estar a ACCEPTED");
        mapEntrega[numEnt].status = Status.READY;
        mapEntrega[numEnt].timestamp = block.timestamp;
        emit Msg("La entrega a salido hacia su destino");
        
    }
    // Funcion
    // Nombre: repartidorFirmaLLlegada
    // Uso:    Reprtidor firma la llegada en contrato y se cumplen las conciciones
    function repartidorFirmaLlegada(uint numEnt) public isRepartidor(numEnt) {
        require(numEnt > 0 && numEnt <= numCalculado,"El Numero de entrega no es correcto");
        require(mapEntrega[numEnt].status == Status.READY,"EL estado de la Entraga tiene que estar a READY");
        mapEntrega[numEnt].status = Status.RPOK;
        mapEntrega[numEnt].timestamp = block.timestamp;
        emit Msg("El repartidor ha firmado la llega al destino");
    }
    // Funcion
    // Nombre: clienteFirmaRecepcion
    // Uso:    cliente firma la recepcion del producto si se cumplen las conciciones y sus fondos se envian al contrato
    function clienteFirmaRecepcion(uint numEnt) payable public isCliente(numEnt) {
        require(numEnt > 0 && numEnt <= numCalculado,"El Numero de entrega no es correcto");
        require(msg.value == mapEntrega[numEnt].price, "El precio introducido no se corresponde con el precio del producto");
        mapEntrega[numEnt].status = Status.CLOK;
        //Cuando el cliente da el Ok sus fondos se transfieren al contrato
            
        emit Msg("El Cliente ha firmado la recepcion de Producto");

    }

    // Funcion
    // Nombre: vendedorRecicePago
    // Uso:   vendedor Recoge el pago y se cumplen las conciciones
    function vendedorRecibePago(uint _numEnt) payable public isOwner{
        require(_numEnt > 0 && _numEnt <= numCalculado,"El Numero de entrega no es correcto");
        //Si el status es CLOK y RPOK a REALIZADA
        require(mapEntrega[_numEnt].status == Status.CLOK,"El Cliente no ha firmado la recepcion");
        mapEntrega[_numEnt].status = Status.REALIZADA;
        mapEntrega[_numEnt].timestamp = block.timestamp;

        //Pago al repartidor el precio
        payable(mapEntrega[_numEnt].mapRole[Role.REPARTIDOR]).transfer(priceTrasporte);
        
        //Pago al vendedor
        payable(mapEntrega[_numEnt].mapRole[Role.VENDEDOR]).transfer(mapEntrega[_numEnt].price - priceTrasporte);
        emit Msg("El vendedor recoje el pago y se paga el trasporte");
    }

    //Funcion cliente no firma recepcion se devuelve el dinero del contrato al vendedor menos la comison del repartidor


    //Funcion repartidor no firma llegada se le penaliza al repartidor y se devuelve el dinero al vendedor


    //Funcion cancelar solo cliente o vendedor y no estado Ready XXOK se devuelve la pasta


    // Funcion
    // Nombre: crearEntrega
    // Uso: crear Entrega y añadir al mapping
    function crearEntrega(
        address repartidor, 
        address cliente, 
        uint precio,
        string calldata description) 
        public payable isOwner {
        numCalculado ++ ;
        uint precioEther = precio * (10 ** 18);
        mapEntrega[numCalculado].numEntrega = numCalculado;
        mapEntrega[numCalculado].description = description;
        mapEntrega[numCalculado].price = precioEther;
        mapEntrega[numCalculado].timestamp = block.timestamp;
        mapEntrega[numCalculado].status = Status.ACCEPTED;
        mapEntrega[numCalculado].mapRole[Role.REPARTIDOR] = repartidor;
        mapEntrega[numCalculado].mapRole[Role.CLIENTE] = cliente;
        mapEntrega[numCalculado].mapRole[Role.VENDEDOR] = owner;
        emit MsgEntrada ("Entrega creada: " ,repartidor, cliente, msg.value, description);
    }   

    // Funcion
    // Nombre: CanceladaEntrada
    // Uso: Se cancela la entrega
    function canceladaEntrada(uint numEnt) payable public isOwner(){
        require(numEnt > 0 && numEnt <= numCalculado,"El Numero de entrega no es correcto");
        require(mapEntrega[numEnt].status == Status.ACCEPTED, "El estado no es el adecuado para poder Cancelar la entrega");
        mapEntrega[numEnt].status = Status.CANCEL;
        mapEntrega[numEnt].timestamp = block.timestamp;
        emit MsgEntrada ("Entrega Cancelada",
        mapEntrega[numEnt].mapRole[Role.REPARTIDOR],
        mapEntrega[numEnt].mapRole[Role.CLIENTE], 
        mapEntrega[numEnt].price, 
        mapEntrega[numEnt].description);
    }

    // Funcion
    // Nombre: panico
    // Uso: Se devuelve el dinero del contrato al owner
    function panico() public isOwner(){
        
        owner.transfer(address(this).balance);
        emit Msg("Funcion de panico Realizada se devuelven los fondos del Contrato al owner");
    }

    // Funcion get
    // Nombre: viewEntrega
    // Uso: Ver entrega por numEntrega
    function viewEntrega(uint numEnt) public isOwner() {
        require(numEnt > 0 && numEnt <= numCalculado,"El Numero de entrega no es correcto");
        emit MsgEntradaXNumEnt (
            mapEntrega[numEnt].numEntrega ,
            mapEntrega[numEnt].description,
            mapEntrega[numEnt].price,
            viewEntregaStatus(numEnt), 
            mapEntrega[numEnt].mapRole[Role.CLIENTE], 
            mapEntrega[numEnt].mapRole[Role.REPARTIDOR],
            mapEntrega[numEnt].mapRole[Role.VENDEDOR]);
    }
    
    // Funcion get
    // Nombre: fondoscontratos
    // Uso: Ver fondos contrato
    function fondoscontratos() public view isOwner returns(uint){
        return (address(this).balance);
    }

    // Funcion get
    // Nombre: verPrecio
    // Uso: Consultar el precio de un producto
    function verPrecio(uint numEnt) public view isOwner returns(uint){
        return mapEntrega[numEnt].price;
    }

    // Funcion view
    // Nombre: viewEntregaStatus
    // Uso: Ver El status de la entrega por numEntrega
    // Status {ACCEPTED,READY,CLOK,RPOK,CLKO,RPKO,CANCEL,REALIZADA}
    function viewEntregaStatus(uint numEnt) public view returns(string memory){
        require(numEnt > 0 && numEnt <= numCalculado,"El Numero de entrega no es correcto");
        if (mapEntrega[numEnt].status == Status.ACCEPTED){
            return ACCEPTED;
        }else if(mapEntrega[numEnt].status == Status.READY){
            return READY;
        }else if(mapEntrega[numEnt].status == Status.CLOK){
            return CLOK;
        }else if(mapEntrega[numEnt].status == Status.RPOK){
            return RPOK;
        }else if(mapEntrega[numEnt].status == Status.CLKO){
            return CLKO;
        }else if(mapEntrega[numEnt].status == Status.RPKO){
            return RPKO;
        }else if(mapEntrega[numEnt].status == Status.CANCEL){
            return CANCEL;
        }else{
            return REALIZADA;
        }
        
    }

}
