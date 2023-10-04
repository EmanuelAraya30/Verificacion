//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Scoreboard: Este objeto se encarga de llevar un estado del comportamiento de la prueba y es capa de generar reportes //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class score_board #(parameter pckg_sz=16, parameter drvrs=5, parameter pckg_sz=32);
trans_chkr_sb_mbx  chkr_sb_mbx;
trans_rpt_mbx rpt_mbx;
trans_sb #(.pckg_sz(pckg_sz))transaccion_entrante; 
trans_sb #(.pckg_sz(pckg_sz))scoreboard[$]; // esta es la estructura dinámica que maneja el scoreboard  
trans_sb #(.pckg_sz(pckg_sz)) auxiliar_trans;
rpt rpt_tipo;
//Definición de variables
int ret_drvrs[drvrs]; //Retardo x driver
int inst_x_drvrs[drvrs]; // intrucciones x driver
int cont_intruct = 0; //contador de instrucciones
int cont_intruct_term[drvrs]; //contador de instrucciones x terminal
int inicio = 0; //para calcular el tiempo inicial
int tiempo_init = 0; //tiempo inicial
int tiempo_fin = 0; // tiempo final
int retardo_total = 0; // Retardo total
int retardo_promedio;
int ret_prom_drvrs[drvrs];
int reporte;
int AB_max;
int AB_min;



task run;
  $display("[%g] El Score Board fue inicializado",$time);
  forever begin
    #5
    if(chkr_sb_mbx.num()>0)begin
      chkr_sb_mbx.get(transaccion_entrante);
      transaccion_entrante.print("Score Board: transacción recibida desde el checker");
      retardo_total = retardo_total + transaccion_entrante.latencia;
      ret_drvrs[transaccion_entrante.dev_rec] = ret_drvrs[transaccion_entrante.dev_rec] + transaccion_entrante.latencia;  
      cont_intruct++:
      inst_x_drvrs[transaccion_entrante.dev_rec]++;
      tiempo_fin = transaccion_entrante.tiempo_rec;

      if(inicio == 1) begin
        tiempo_init = transaccion_entrante.tiempo_env;
        inicio = 0;
      end
      scoreboard.push_back(transaccion_entrante);
    end 
    else begin
      if(rpt_mbx.num()>0)begin
        rpt_mbx.get(orden);
        case(orden)
        rpt_prom: begin
            $display("[%g]Score Board: Recibida Orden Retardo Promedio", $time);
            retardo_promedio = retardo_total/cont_intruct;
            $display("[%g] Score board: el retardo promedio es: %0.3f", $time, retardo_promedio);
            for (int i = 0; i < drvrs; i++) begin
              ret_prom_drvrs[i] = ret_drvrs[i]/cont_intruct_term[i] ;
              $display("[%g] Score board: el retardo promedio en driver [%g] es: %0.3f", $time, i, ret_prom_drvrs[i]);
            end
          end
          rpt_bw_max: begin
            $display("[%g]Score Board: Recibida Orden Reporte de ancho de banda maximo", $time);
            AB_max = $fopen("AB_max.csv", "a");
            $fwrite(AB_max, "%0d,%0d,%0.3f\n", pckg_sz, drvrs, (cont_intruct*pckg_sz*1000)/(tiempo_fin-tiempo_init));
            $fclose(AB_max); 
          end
          rpt_bw_min: begin
            $display("[%g]Score Board: Recibida Orden Reporte de ancho de banda minimo", $time);
            AB_min = $fopen("AB_min.csv", "a");
            $fwrite(AB_min, "%0d,%0d,%0.3f\n", pckg_sz, drvrs, (cont_intruct*pckg_sz*1000)/(tiempo_fin-tiempo_init));
            $fclose(AB_min); 
          end
          rpt_transac: begin
            $display("[%g]Score Board: Recibida Orden Reporte de transaccion", $time);
            reporte = $fopen("reporte.csv", "w");
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