////////////////////////////////////////////////////////////////////////////////////////////////////
// Checker/scoreboard: este objeto es responsable de verificar que el comportamiento del DUT sea el esperado //
////////////////////////////////////////////////////////////////////////////////////////////////////
class checker #(parameter pckg_sz = 32, parameter bits=1, parameter drvrs=5);
  trans_bus #(.pckg_sz(pckg_sz), .drvrs(drvrs)) transaccion; //transacción recibida en el mailbox 
  trans_bus #(.pckg_sz(pckg_sz), .drvrs(drvrs)) emul_queue[drvrs][$]; //this queue is going to be used as golden reference for the fifo
  trans_monitor #(.pckg_sz(pckg_sz)) mntr_trans;
  trans_sb   #(.pckg_sz(pckg_sz)) to_sb; // transacción usada para enviar al checker desde el monitor

  //Llamado de mailboxes
  dcm driver_checker_mailbox; 
  mcm monitor_checker_mailbox; // Este mailbox es el que comunica con el monitor con el checker
  csm checker_scoreboard_mailbox; // Este mailbox es el que comunica el checker con el scoreboard

  //Se generan Queues para almacenar datos
  function new();
    for (int i = 0 ; i <drvrs ; i++) begin
      emul_queue[i] = {};
    end
  endfunction 

  task save;
    $display("[%g]  El checker fue inicializado",$time);
    forever begin
      driver_checker_mailbox.get(transaccion);
      $display("[%g]  Checker: Se recibe trasacción desde el driver/Agente",$time);
      emul_queue[transaccion.dato_rec].push_back(transaccion);    
    end 
  endtask

  task match; //Compara los datos enviados contra los recibidos
    forever begin
      to_sb = new();
      monitor_checker_mailbox.get(mntr_trans);
      $display("[%g]  Checker: Se recibe trasacción desde el monitor",$time);
      for(int i=0; i<emul_queue[mntr_trans.dato_rec_mnt].size(); i++)begin //Recorre cada posicion
        if(emul_queue[mntr_trans.dato_rec_mnt][i].dato==mntr_trans.dato)begin //compara
          to_sb.dato_env=emul_queue[mntr_trans.dato_rec_mnt][i].dato;
          to_sb.dato_rec=mntr_trans.dato;
          to_sb.tiempo_env=emul_queue[mntr_trans.dato_rec_mnt][i].tiempo;
          to_sb.tiempo_rec=mntr_trans.tiempo;
          to_sb.calc_laten();
          to_sb.tipo=emul_queue[mntr_trans.dato_rec_mnt][i].tipo;
          to_sb.dato_env=emul_queue[mntr_trans.dato_rec_mnt][i].dato_env;
          to_sb.dev_rec=mntr_trans.dato_rec_mnt;
          to_sb.print("Checker: Transacción completa");
          checker_scoreboard_mailbox.put(to_sb);//envia la transaccion al scoreboard
          i=emul_queue[mntr_trans.dato_rec_mnt].size();  	
        end
        
      end
    end

  endtask
endclass 