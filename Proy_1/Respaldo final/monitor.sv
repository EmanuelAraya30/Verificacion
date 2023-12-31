 ///////////////////////////////////////////////////////////////////////////////
 // Monitor: este objeto es responsable de leer las señales de salida del DUT //
 ///////////////////////////////////////////////////////////////////////////////

class fifo_monitor #(parameter bits = 1, parameter drvrs = 5, parameter pckg_sz = 32, parameter broadcast = {8{1'b1}});
    virtual bus_if #(.bits(bits), .drvrs(drvrs), .pckg_sz(pckg_sz), .broadcast(broadcast))vif;



    bit pop;
    bit push;
    bit pndng;
    bit [pckg_sz-1:0] D_pop;
    bit [pckg_sz-1:0] D_push;
    bit [pckg_sz-1:0] c [$];
    int id;
    
    //Se realiza un constructor por cada ID que se registre
    function new(int ID);
        this.pop = 0;
        this.push = 0;
        this.pndng = 0;
        this.D_pop = 0;
        this.c = {};
        this.id=ID;  
    endfunction

    task PUSH();
        forever begin
            @(posedge vif.clk);
            push=vif.push[0][id];
        end
    endtask

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
	
	
	
	function void POP();
		D_pop=c.pop_front();
		if(c.size()==0)begin
			pndng =0;
		end
	endfunction	

endclass



class monitor_hijo #(parameter drvrs = 5, parameter bits = 1, parameter pckg_sz = 32);

    fifo_monitor #(.bits(bits), .drvrs(drvrs), .pckg_sz(pckg_sz)) FiFo_out;
    trans_monitor #(.pckg_sz(pckg_sz)) trans_mntr;
    mcm monitor_checker_mailbox;

    
    int id;

    function new(int ID);
        this.id = ID;
        this.FiFo_out = new(ID);
    endfunction

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

class monitor_padre #(parameter bits = 1,
                      parameter drvrs = 5,
                      parameter pckg_sz = 32);

    monitor_hijo #(.bits(bits), .drvrs(drvrs), .pckg_sz(pckg_sz)) FiFo_son [drvrs];


    
    int id;

    function new();
        for(int i=0; i<drvrs; i++)begin
            FiFo_son[i]=new(i);
        end
    endfunction

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