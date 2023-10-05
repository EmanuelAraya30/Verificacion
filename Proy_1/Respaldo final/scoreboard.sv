//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Scoreboard: Este objeto se encarga de llevar un estado del comportamiento de la prueba y es capa de generar reportes //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class score_board #(parameter pckg_sz=16, parameter bits=1, parameter drvrs=5);
csm trans_chkr_sb_mbx;
rm trans_rpt_mbx;
trans_sb #(.pckg_sz(pckg_sz))transacciones_i; 
trans_sb #(.pckg_sz(pckg_sz))scoreboard[$]; // esta es la estructura dinámica que maneja el scoreboard  
trans_sb #(.pckg_sz(pckg_sz)) auxiliar_trans;
reporte reporte_inst;
//Definición de variables
int ret_drvrs[drvrs]; //Retardo x driver
int cont_intruct_term[drvrs]; //contador de instrucciones x terminal
int retardo_total = 0; // Retardo total
//int inst_x_drvrs[drvrs]; // intrucciones x driver
int cont_intruct = 0; //contador de instrucciones
int cont_inst_bw = 0;
int inicio = 0; //para calcular el tiempo inicial
int tiempo_init = 0; //tiempo inicial
int tiempo_fin = 0; // tiempo final

int retardo_promedio;
int ret_prom_drvrs[drvrs];
int reporte;
int AB_max;
int AB_min;



task run;
  $display("[%g] El Score Board fue inicializado",$time);
  forever begin
    #5
    if(trans_chkr_sb_mbx.num()>0)begin
      trans_chkr_sb_mbx.get(transacciones_i);
      transacciones_i.print("Score Board: transacción recibida desde el checker");
      retardo_total = retardo_total + transacciones_i.latencia;
      ret_drvrs[transacciones_i.dev_rec] = ret_drvrs[transacciones_i.dev_rec] + transacciones_i.latencia;  
      cont_intruct++;
      inst_x_drvrs[transacciones_i.dev_rec]++;
	  cont_inst_bw++;
      tiempo_fin = transacciones_i.tiempo_rec;

      if(inicio == 1) begin
        tiempo_init = transacciones_i.tiempo_env;
        inicio = 0;
      end
      scoreboard.push_back(transacciones_i);
    end 
    else begin
      if(trans_rpt_mbx.num()>0)begin
        trans_rpt_mbx.get(orden);
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