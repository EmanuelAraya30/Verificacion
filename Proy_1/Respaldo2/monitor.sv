// Monitor
// Instituto Tecnologico de Costa Rica (www.tec.ac.cr)
// Escuela de Ingeniería Electrónica
// Prof: Ing. Ronny Garcia Ramirez. (rgarcia@tec.ac.cr)
// Estudiantes: -Enmanuel Araya Esquivel. (emanuelarayaesq@gmail.com)
//              -Randall Vargas Chaves. (randallv07@gmail.com)
// Curso: EL-5511 Verificación funcional de circuitos integrados
// Este Script esta estructurado en System Verilog
// Propósito General: Diseño de pruebas en capas para un BUS de datos
// Modulo: Este objeto es responsable de leer las señales de salida del DUT.

 //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 // fifo_monitor: este objeto es responsable simular una fifo para obtener los datos de salida del DUT y pasarlos al Checker //
 //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class fifo_monitor #(parameter bits = 1, parameter drvrs = 5, parameter pckg_sz = 32, parameter broadcast = {8{1'b1}});
    virtual bus_if #(.bits(bits), .drvrs(drvrs), .pckg_sz(pckg_sz), .broadcast(broadcast))vif; // Se genera la conexión por medio de interface
    // Se establecen entrada y salidas de una fifo
    bit pop;
    bit push;
    bit pndng;
    bit [pckg_sz-1:0] D_pop;
    bit [pckg_sz-1:0] D_push;
    bit [pckg_sz-1:0] c [$];
    int id;
    
    // Se genera un constructor para los diferentes ID
    function new(int ID);
        this.pop = 0;
        this.push = 0;
        this.pndng = 0;
        this.D_pop = 0;
        this.c = {};
        this.id=ID;  
    endfunction

    // Función de push
    task PUSH();
        forever begin
            @(posedge vif.clk);
            push=vif.push[0][id];
        end
    endtask

    // Función que actualiza el dato push
    task D_PUSH();
        forever begin
            @(posedge vif.clk);
            D_push=vif.D_push[0][id]; // Revisar el bus_if
            if(push==1)begin
                c.push_back(D_push);
                pndng = 1;
            end
        end
    endtask
	
	//Función de pop
	function void POP();
		D_pop=c.pop_front();
		if(c.size()==0)begin
			pndng =0;
		end
	endfunction	

endclass

 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 // monitor_hijo: Estos monitores se generan por cada driver para recibir las señales de salida y envian al monitor_padre //
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class monitor_hijo #(parameter drvrs = 5, parameter bits = 1, parameter pckg_sz = 32);
    fifo_monitor #(.bits(bits), .drvrs(drvrs), .pckg_sz(pckg_sz)) FiFo_out;  // Se genera instancia de clase fifo_monitor
    trans_monitor #(.pckg_sz(pckg_sz)) trans_mntr; // Se inicia la transacción del monitor
    mcm monitor_checker_mailbox; // Se genera el mailbox       
    int id;

    // Genera un constructor por cada ID
    function new(int ID);
        this.id = ID;
        this.FiFo_out = new(ID);
    endfunction

    //Se inicializa el monitor
    task inicia();
        $display("[%g]  El Monitor [%g] inicializado", $time, id);
        fork
            FiFo_out.PUSH();
            FiFo_out.D_PUSH();
        join_none

        forever begin   
            trans_mntr=new;
            @(posedge FiFo_out.vif.clk);
            if (FiFo_out.pndng == 1) begin
                FiFo_out.POP();
                trans_mntr.tiempo = $time;
                trans_mntr.dato_rec_mnt = id;
                @(posedge FiFo_out.vif.clk);
                trans_mntr.dato = FiFo_out.D_push;
                monitor_checker_mailbox.put(trans_mntr);
                trans_mntr.print("Monitor: Transaccion recibida");
            end
            @(posedge FiFo_out.vif.clk);
        end
    endtask

endclass

 ////////////////////////////////////////////////////////////////////
 // monitor_padre: Genera a los monitores hijos y los conecta a el //
 ////////////////////////////////////////////////////////////////////
class monitor_padre #(parameter bits = 1, parameter drvrs = 5, parameter pckg_sz = 32);
    monitor_hijo #(.bits(bits), .drvrs(drvrs), .pckg_sz(pckg_sz)) FiFo_son [drvrs];//Genera instancia de la clase hijo 
    int id;
    // Genera un constructor por cada ID que seran los hijos
    function new();
        for(int i=0; i<drvrs; i++)begin
            FiFo_son[i]=new(i);
        end
    endfunction

    //Ejecuta a los hijos creados
    task inicia();
        for(int i = 0; i < drvrs; i++)begin
            fork
                automatic int j = i;
                begin
                    FiFo_son[j].inicia();
                end
            join_none
        end 
    endtask
endclass