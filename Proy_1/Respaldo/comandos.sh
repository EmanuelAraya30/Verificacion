source /mnt/vol_NFS_rh003/estudiantes/archivos_config/synopsys_tools.sh


for pckg_sz in  32
        do
        for drvrs in 4 8 16
        do
        printf "\x60define PRMT \n" > parameters.sv
        printf "parameter pckg_sz = %d;\nparameter drvrs = %d;\n" $pckg_sz $drvrs  >> parameters.sv
        vcs -Mupdate parameters.sv testbench.sv  -o salida  -full64 -sverilog  -kdb -debug_acc+all -debug_region+cell+encrypt -l log_test +lint=TFIPC-L
        ./salida +ntb_random_seed=20
        if $?; then
        printf "\n\n\n\n\nError in run drvrs=%d, pckg_sz=%d\n\n\n\n" $pckg_sz $drvrs
                                return 1
                        fi
        done
done

