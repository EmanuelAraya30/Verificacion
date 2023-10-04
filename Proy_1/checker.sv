////////////////////////////////////////////////////////////////////////////////////////////////////
// Checker/scoreboard: este objeto es responsable de verificar que el comportamiento del DUT sea el esperado //
////////////////////////////////////////////////////////////////////////////////////////////////////
class checker #(parameter pckg_sz = 32, parameter bits=1, parameter drvrs=5);
  trans_bus #(.pckg_sz(pckg_sz), .drvrs(drvrs)) transaccion; //transacción recibida en el mailbox 
  trans_bus #(.width(width), .n_term(n_term)) emul_queue[drvrs][$]; //this queue is going to be used as golden reference for the fifo
  trans_monitor #(parameter pckg_sz = 32) mntr_trans;
  trans_sb   #(.pckg_sz(pckg_sz)) to_sb; // transacción usada para enviar al checker desde el monitor

  //Llamado de mailboxes
  trans_drv_chk_mbx drv_chk_mbx; 
  trans_mntr_chkr_mbx mntr_chkr_mbx; // Este mailbox es el que comunica con el monitor con el checker
  trans_chkr_sb_mbx  chkr_sb_mbx; // Este mailbox es el que comunica el checker con el scoreboard

  //Se generan Queues para almacenar datos
  function new();
    for (i = 0 ; i <drvrs ; i++) begin
      emul_queue[i] = {};
    end
  endfunction 

  task save;
    $display("[%g]  El checker fue inicializado",$time);
    forever begin
      drv_chk_mbx.get(transaccion);
      $display("[%g]  Checker: Se recibe trasacción desde el driver/Agente",$time);
      emul_queue[transaccion.Rx].push_back(transaccion);    
    end 
  endtask

  task match; //Compara los datos enviados contra los recibidos
    forever begin
      to_sb = new();
      mntr_chkr_mbx.get(mntr_trans);
      $display("[%g]  Checker: Se recibe trasacción desde el monitor",$time);
      for(int i=0; i<emul_queue[mntr_trans.Rx_mnt].size(); i++)begin //Recorre cada posicion
        if(emul_queue[emul_queue.Rx_mnt][i].dato==mntr_trans.dato)begin //compara
          to_sb.dato_env=emul_queue[mntr_trans.Rx_mnt][i].dato;
          to_sb.dato_rec=mntr_trans.dato;
          to_sb.tiempo_env=emul_queue[mntr_trans.Rx_mnt][i].tiempo;
          to_sb.tiempo_rec=mntr_trans.tiempo;
          to_sb.calc_latencia();
          to_sb.tipo=emul_queue[mntr_trans.Rx_mnt][i].tipo;
          to_sb.dev_env=emul_queue[mntr_trans.Rx_mnt][i].dev_env;
          to_sb.dev_rec=mntr_trans.Rx_mnt;
          to_sb.print("Checker: Transacción completa");
          chkr_sb_mbx.put(to_sb);//envia la transaccion al scoreboard
          i=emul_queue[mntr_trans.Rx_mnt].size();  	
        end
        
      end
    end

  endtask
endclass 
