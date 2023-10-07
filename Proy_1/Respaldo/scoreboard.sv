class scoreboard #(parameter width=32, parameter bits=1, parameter n_term=5);
  comando_chk_scb_mbx chk_scb_mbx;
  comando_rpt_mbx rpt_mbx;
  trans_scb #(.width(width)) transaccion;
  trans_scb #(.width(width)) trans_aux;
  trans_scb #(.width(width)) cola_scb[$];
  reporte rpt_inst;
  int retardo_term[n_term]; //retardo por cada terminal
  int inst_count_term[n_term]; //ccontador de instrucciones por terminal
  int retardo_total=0; //retardo total
  int inst_count=0; //contador de instrucciones total
  int inst_count_bw=0; //contador de intrucciones para bandwidth max y min
  int first=0;
  int tiempo_inicial=0; //tiempo inicial
  int tiempo_final=0; //tiempo final
   
  
  int rep; 
  int bwmax;
  int bwmin;
  
  int retardo_promedio;
  int retardo_prom_term[n_term];
  
  task run;
    $display("[%g] Scoreboard ha inicializado", $time);

    forever begin
      #5
      if(chk_scb_mbx.num()>0)begin
        chk_scb_mbx.get(transaccion);
        transaccion.print("Scoreboard: Trans_rcb_chk");
        
        retardo_total=retardo_total+transaccion.latencia;
        retardo_term[transaccion.term_recibo]=retardo_term[transaccion.term_recibo]+transaccion.latencia;
        inst_count++;
        inst_count_term[transaccion.term_recibo]++;
        inst_count_bw++;
        tiempo_final=transaccion.tiempo_recibo;
        if(first==1)begin
          tiempo_inicial=transaccion.tiempo_envio;
          first=0;
        end
        cola_scb.push_back(transaccion);
      end else begin
        if(rpt_mbx.num()>0)begin
          rpt_mbx.get(rpt_inst);
          case(rpt_inst)
          	
            reporte_promedio:begin
              $display("[%g]Scoreboard: Retardo promedio", $time);
              retardo_promedio=retardo_total/inst_count;
              $display("[%g] Scoreboard: el retardo promedio es: %0.3f", $time, retardo_promedio);
              for(int i=0;i<n_term; i++)begin
                retardo_prom_term[i]=retardo_term[i]/inst_count_term[i];
                $display("[%g] Scoreboard: el retardo promedio en terminal [%g] es: %0.3f", $time,i, retardo_prom_term[i]);
              end
            end
            reporte_transacciones:begin
              $display("[%g]Scoreboard: Reporte de transacciones", $time);
              rep = $fopen("reporte.csv", "w");
              $fwrite(rep, "Dato recibido,Dato enviado,transmisor,receptor,latencia,tipo\n");
              for(int i=0;i<inst_count;i++) begin
                trans_aux = cola_scb.pop_front;
                $fwrite(rep, "%0h, %0h, %0g, %0g, %0g, %0s\n",trans_aux.dato_recibido, trans_aux.dato_enviado, trans_aux.term_envio,trans_aux.term_recibo, trans_aux.latencia, trans_aux.tipo);
              end
             $fclose(rep);
            end
            
            reporte_bwmax:begin
              
              bwmax = $fopen("bwmax.csv", "a");
              $fwrite(bwmax, "%0d,%0d,%0.3f\n",width ,n_term, (inst_count_bw*width*1000)/(tiempo_final-tiempo_inicial));
              $fclose(bwmax);
              
            end
            
           reporte_bwmin: begin 
             bwmin = $fopen("bwmin.csv", "a");
             $fwrite(bwmin, "%0d,%0d,%0.3f\n",width, n_term, (inst_count_bw*width*1000)/(tiempo_final-tiempo_inicial));
             $fclose(bwmin);
            end
          endcase
        end
      end
    end
  endtask
endclass

