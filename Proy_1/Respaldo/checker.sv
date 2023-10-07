class checker_ #(parameter width=32, parameter bits=1, parameter n_term=5);
  	trans_bus #(.width(width), .n_term(n_term)) transaccion;
  	trans_scb #(.width(width)) to_sb;
  	trans_monitor #(.width(width)) from_mnt;
    	trans_bus #(.width(width), .n_term(n_term)) cola [n_term][$];
  
 	//Se llaman a los mailboxes 
  	comando_drv_chk_mbx drv_chk_mbx;
  	comando_mnt_chk_mbx mnt_chk_mbx;
  	comando_chk_scb_mbx chk_scb_mbx;
  	
  	//Se generan las colas para guardar datos
  
  	function new();
      	 for(int i=0; i<n_term; i++)begin
         cola[i]={};
        end
    
  	endfunction
  
  	task save;//funcion para almacenar el colas que simulan las terminales
      	$display("[%g] Checker ha inicializado",$time); //donde debieron haberse recibido los datos
      	 forever begin
          drv_chk_mbx.get(transaccion);
          $display("[%g] Checker: Trans_rcb_drv",$time);
          cola[transaccion.term_recibo].push_back(transaccion); //almacena la transaccion en la cola 
         end    						      //correspondiente
    endtask
  
  
  	task match;//funcion para compara los datos recibidos y enviados
         forever begin //Agrega todos los datos necesarios para el scoreboard
         to_sb=new();
         mnt_chk_mbx.get(from_mnt); 
         $display("[%g] Checker: Trans_rcb_mnt",$time);
         for(int i=0; i<cola[from_mnt.terminal_recibo].size(); i++)begin //Recorre cada posicion
           if(cola[from_mnt.terminal_recibo][i].dato==from_mnt.dato)begin //compara
             	to_sb.dato_enviado=cola[from_mnt.terminal_recibo][i].dato;
             	to_sb.dato_recibido=from_mnt.dato;
             	to_sb.tiempo_envio=cola[from_mnt.terminal_recibo][i].tiempo;
             	to_sb.tiempo_recibo=from_mnt.tiempo;
             	to_sb.calc_latencia();
            	to_sb.tipo=cola[from_mnt.terminal_recibo][i].tipo;
             	to_sb.term_envio=cola[from_mnt.terminal_recibo][i].term_envio;
             	to_sb.term_recibo=from_mnt.terminal_recibo;
             	to_sb.print("Checker: Trans_comp");
             	chk_scb_mbx.put(to_sb);//envia la transaccion al scoreboard
            	i=cola[from_mnt.terminal_recibo].size();  	
           end
           
         end
        
       end
    endtask
        
endclass