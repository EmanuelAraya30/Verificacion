source /mnt/vol_NFS_rh003/estudiantes/archivos_config/synopsys_tools.sh


for width in  32
        do
        for n_term in 4 8 16
        do
        printf "\x60define PRMT \n" > parameters.sv
        printf "parameter width = %d;\nparameter n_term = %d;\n" $width $n_term  >> parameters.sv
        vcs -Mupdate parameters.sv testbench.sv  -o salida  -full64 -sverilog  -kdb -debug_acc+all -debug_region+cell+encrypt -l log_test +lint=TFIPC-L
        ./salida +ntb_random_seed=20
        if $?; then
        printf "\n\n\n\n\nError in run n_term=%d, width=%d\n\n\n\n" $width $n_term
                                return 1
                        fi
        done
done

