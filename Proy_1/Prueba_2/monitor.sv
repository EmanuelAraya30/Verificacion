// Definición de la cola que simula la fifo a la interfase y y la la salida de conexion al dut 

class monitor_hijo #(parameter pckg_sz=16, parameter drvrs=4, parameter profundidad=8, parameter bits=1);
    fifo #(.pckg_sz(pckg_sz), .profundidad(profundidad)) fifo_o;
    virtual bus_if #(.drvrs(drvrs), .pckg_sz(pckg_sz), .bits(bits)) vif;	
    trans_bus #(.pckg_sz(pckg_sz)) transaction;	

    logic [7:0]Rx; //Destino
    int Tx; //Origen
    bit [pckg_sz-1:0]dato_push;
    bit [pckg_sz-1:0]dato_pop;
    //int r; // Se usa?
    //int listo;

    function new;
        fifo_o=new();
        fifo_o.pndng<=0;
        dato_push = 0;
        dato_pop = 1;		
    endfunction

    task run();
        dato_push = vif.D_push[bits-1][Tx];
        Rx = dato_push[pckg_sz-1:pckg_sz-8];
        if (Rx == Tx && vif.push[bits-1][Tx] == 1)begin
            $display("[%g] Monitor hijo inicializado",$time);
            $display("Destino = %g",Rx);
            $display("Dato = %b",dato_push);
            $display("--------------------------------------------------------------");
            $display("[%g] Monitor_hijo: Dispositivo %g listo para recibir",$time,Tx);
            fifo_o.D_push=vif.D_push[bits-1][Tx];
            fifo_o.push();
            fifo_o.pending();
            fifo_o.pop();
            vif.pndng[bits-1][Tx] <= fifo_o.pndng;
            $display("[%g] Se recibio el mensaje: %b",$time, fifo_o.Data_pop);	//chg	
        end
    endtask
endclass

class monitor #(parameter pckg_sz=16, parameter drvrs=4, parameter profundidad = 8, parameter bits=1); 
    virtual bus_if #(.drvrs(drvrs), .pckg_sz(pckg_sz), .bits(bits)) vif;	
    monitor_hijo #(.drvrs(drvrs),.pckg_sz(pckg_sz),.profundidad(profundidad),.bits(bits)) mntr_hijo[drvrs-1:0];
    trans_bus #(.pckg_sz(pckg_sz)) transaction;	

    function new;
            for (int i=0;i<drvrs; i++)begin
                automatic int k=i;
                fork
                    mntr_hijo[k]=new();
                join_none
            end
    endfunction

    task run();
        $display("[%g] El monitor fue inicializado",$time);
        forever begin
            #1
            for (int i=0; i<drvrs; i++)begin
                automatic int k=i;
                mntr_hijo[k].vif = vif;
                mntr_hijo[k].Tx = k;
                mntr_hijo[k].run();	
            end		
        end
    endtask
endclass 
