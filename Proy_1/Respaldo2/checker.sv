// Checker
// Instituto Tecnologico de Costa Rica (www.tec.ac.cr)
// Escuela de Ingeniería Electrónica
// Prof: Ing. Ronny Garcia Ramirez. (rgarcia@tec.ac.cr)
// Estudiantes: -Enmanuel Araya Esquivel. (emanuelarayaesq@gmail.com)
//              -Randall Vargas Chaves. (randallv07@gmail.com)
// Curso: EL-5511 Verificación funcional de circuitos integrados
// Este Script esta estructurado en System Verilog
// Propósito General: Diseño de pruebas en capas para un BUS de datos
// Modulo: es el responsable de verificar si las acciones que el DUT 
// ejecuta en sus salidas son coherentes con el comportamiento esperado
// según su especificación

////////////////////////////////////////////////////////////////////////////////////////////////////
// Checker: este objeto es responsable de verificar que el comportamiento del DUT sea el esperado //
////////////////////////////////////////////////////////////////////////////////////////////////////
class checker #(parameter pckg_sz = 32, parameter bits=1, parameter drvrs=5);
  trans_bus #(.pckg_sz(pckg_sz), .drvrs(drvrs)) transaccion; //transacción del agente
  trans_bus #(.pckg_sz(pckg_sz), .drvrs(drvrs)) emul_queue[drvrs][$]; //Esta cola va a se usada como golden reference para el bus
  trans_monitor #(.pckg_sz(pckg_sz)) mntr_trans; //Transacción del monitor
  trans_sb   #(.pckg_sz(pckg_sz)) to_sb; // transacción usada para enviar al checker desde el monitor

  //Llamado de mailboxes
  dcm driver_checker_mailbox; // mailbox es el que comunica con el driver con el checker
  mcm monitor_checker_mailbox; // mailbox es el que comunica con el monitor con el checker
  csm checker_scoreboard_mailbox; // mailbox es el que comunica el checker con el scoreboard

  //Se generan Queues para almacenar datos
  function new();
    for (int i = 0 ; i <drvrs ; i++) begin
      emul_queue[i] = {};
    end
  endfunction 

  //Se inicializa el checker y se guardan las transacciones del agente
  task guardar;
    $display("[%g]  El checker fue inicializado",$time);
    forever begin
      driver_checker_mailbox.get(transaccion);
      $display("[%g]  Checker: Se recibe trasacción desde el driver/Agente",$time);
      emul_queue[transaccion.dato_rec].push_back(transaccion);    
    end 
  endtask
  //Compara datos enviados por agente contra los recibidos por el monitor
  task comparar; 
    forever begin
      to_sb = new(); //Transacciones de Scoreboard
      monitor_checker_mailbox.get(mntr_trans);
      $display("[%g]  Checker: Se recibe trasacción desde el monitor",$time);
      for(int i=0; i<emul_queue[mntr_trans.dato_rec_mnt].size(); i++)begin // Recorre las transacciones
        if(emul_queue[mntr_trans.dato_rec_mnt][i].dato==mntr_trans.dato)begin // Las compara con lo que se obtiene en monitor
          to_sb.dato_env=emul_queue[mntr_trans.dato_rec_mnt][i].dato;
          to_sb.dato_rec=mntr_trans.dato;
          to_sb.tiempo_env=emul_queue[mntr_trans.dato_rec_mnt][i].tiempo;
          to_sb.tiempo_rec=mntr_trans.tiempo;
          to_sb.calc_laten();
          to_sb.tipo=emul_queue[mntr_trans.dato_rec_mnt][i].tipo;
          to_sb.dato_env=emul_queue[mntr_trans.dato_rec_mnt][i].dato_env;
          to_sb.dev_rec=mntr_trans.dato_rec_mnt;
          to_sb.print("Checker: Transacción completa");
          checker_scoreboard_mailbox.put(to_sb); // Guarda los resultados y los envia en el mailbox
          i=emul_queue[mntr_trans.dato_rec_mnt].size();  	
        end
      end
    end
  endtask
endclass 