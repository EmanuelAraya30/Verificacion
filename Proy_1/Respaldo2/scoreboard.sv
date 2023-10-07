// Scoreboard
// Instituto Tecnologico de Costa Rica (www.tec.ac.cr)
// Escuela de Ingeniería Electrónica
// Prof: Ing. Ronny Garcia Ramirez. (rgarcia@tec.ac.cr)
// Estudiantes: -Enmanuel Araya Esquivel. (emanuelarayaesq@gmail.com)
//              -Randall Vargas Chaves. (randallv07@gmail.com)
// Curso: EL-5511 Verificación funcional de circuitos integrados
// Este Script esta estructurado en System Verilog
// Propósito General: Diseño de pruebas en capas para un BUS de datos
// Modulo: Recibe las transacciones que genera el agente y las almacena
// en una estructura de datos, que luego es usado por el checker.

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Scoreboard: Este objeto se encarga de llevar un estado del comportamiento de la prueba y es capa de generar reportes //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class score_board #(parameter pckg_sz=16, parameter bits=1, parameter drvrs=5);
csm checker_scoreboard_mailbox;
rm reporte_mailbox;
trans_sb #(.pckg_sz(pckg_sz))transacciones_i; 
trans_sb #(.pckg_sz(pckg_sz))scoreboard[$]; // esta es la estructura dinámica que maneja el scoreboard  
trans_sb #(.pckg_sz(pckg_sz)) auxiliar_trans;
reporte reporte_inst;

//Definición de variables
int ret_drvrs[drvrs]; //Retardo x driver
int cont_intruct_term[drvrs]; //contador de instrucciones x terminal
int retardo_total = 0; 
int inst_x_drvrs[drvrs]; // intrucciones x driver
int cont_intruct = 0; //contador de instrucciones
int cont_inst_bw = 0;
int inicio = 0; //para calcular el tiempo inicial
int tiempo_init = 0; //tiempo inicial
int tiempo_fin = 0; // tiempo final
int retardo_promedio; // Medira el retardo promedio
int ret_prom_drvrs[drvrs]; // Medira el retardo promedio de  cada driver
int reporte; // Guarda lo del reporte
int AB_max; // Guarda lo del ancho de banda maximo
int AB_min; // Guarda lo del ancho de banda minimo



task run;
  $display("[%g] El Score Board fue inicializado",$time);
  forever begin
    #5
    if(checker_scoreboard_mailbox.num()>0)begin // Ve que haya transacción esperando
      checker_scoreboard_mailbox.get(transacciones_i); // Toma la transacción
      transacciones_i.print("Score Board: transacción recibida desde el checker");
      retardo_total = retardo_total + transacciones_i.laten; // Calcula retardo general
      ret_drvrs[transacciones_i.dev_rec] = ret_drvrs[transacciones_i.dev_rec] + transacciones_i.laten;  // Calcula retardo por drvr  
      cont_intruct++; //aumenta el contador
      inst_x_drvrs[transacciones_i.dev_rec]++;
	  cont_inst_bw++;
      tiempo_fin = transacciones_i.tiempo_rec;

      if(inicio == 1) begin//Reinicia el tiempo de transacción
        tiempo_init = transacciones_i.tiempo_env;
        inicio = 0;
      end
      scoreboard.push_back(transacciones_i);
    end 
    else begin
      if(reporte_mailbox.num()>0)begin // Ve que haya transacción esperando
        reporte_mailbox.get(reporte_inst); // La captura
        case(reporte_inst)
        reporte_prom: begin  // Se realiza el reporte de retardo promedio
            $display("[%g]Score Board: Recibida Orden Retardo Promedio", $time);
            retardo_promedio = retardo_total/cont_intruct;
            $display("[%g] Score board: el retardo promedio es: %0.3f", $time, retardo_promedio);
            for (int i = 0; i < drvrs; i++) begin
              ret_prom_drvrs[i] = ret_drvrs[i]/cont_intruct_term[i] ;
              $display("[%g] Score board: el retardo promedio en driver [%g] es: %0.3f", $time, i, ret_prom_drvrs[i]);
            end
          end
          reporte_bw_max: begin // Se realiza el reporte de ancho de banda máximo
            $display("[%g]Score Board: Recibida Orden Reporte de ancho de banda maximo", $time);
            AB_max = $fopen("AB_max.csv", "a");// Guarda en .csv
            $fwrite(AB_max, "%0d,%0d,%0.3f\n", pckg_sz, drvrs, (cont_intruct*pckg_sz*1000)/(tiempo_fin-tiempo_init));
            $fclose(AB_max); 
          end
          reporte_bw_min: begin // Se realiza el reporte de ancho de banda minimo
            $display("[%g]Score Board: Recibida Orden Reporte de ancho de banda minimo", $time);
            AB_min = $fopen("AB_min.csv", "a");// Guarda en .csv
            $fwrite(AB_min, "%0d,%0d,%0.3f\n", pckg_sz, drvrs, (cont_intruct*pckg_sz*1000)/(tiempo_fin-tiempo_init));
            $fclose(AB_min); 
          end
          reporte_transac: begin // Se realiza el reporte de transacción
            $display("[%g]Score Board: Recibida Orden Reporte de transaccion", $time);
            reporte = $fopen("reporte.csv", "w"); // Guarda en .csv
            $fwrite(reporte, "Dato recibido, Dato enviado, Tx, Rx, latencia, tipo\n");
            for(int i=0;i<cont_intruct;i++) begin
              auxiliar_trans = scoreboard.pop_front;
              $fwrite(reporte, "%0h, %0h, %0g, %0g, %0g, %0s\n", auxiliar_trans.dato_rec, auxiliar_trans.dato_env, auxiliar_trans.dev_env, auxiliar_trans.dev_rec, auxiliar_trans.laten, auxiliar_trans.tipo);
            end
            $fclose(reporte);
          end
        endcase
     end
    end
  end
endtask

endclass