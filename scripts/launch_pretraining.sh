#!/bin/bash

NGPUS=1
NNODES=1
MASTER=""
CONFIG=""

while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | sed 's/^[^=]*=//g'`
    if [[ "$VALUE" == "$PARAM" ]]; then
        shift
        VALUE=$1
    fi
    case $PARAM in
        -h|--help)
            echo "USAGE: ./launch_node_torch_imagenet.sh"
            echo "  -h,--help           Display this help message"
            echo "  -N,--ngpus [int]    Number of GPUs per node (default: 1)"
            echo "  -n,--nnodes [int]   Number of nodes this script is launched on (default: 1)"
            echo "  -m,--master [str]   Address of master node (default: \"\")"
            echo "  -c,--config [path]  Config file for training (default: \"\")"
            echo "  -i,--input  [path]  Input data directory (default: \"\")"
            echo "  -o,--output [path]  Output data directoy (default: \"\")"
            exit 0
        ;;
        -N|--ngpus)
            NGPUS=$VALUE
        ;;
        -n|--nnodes)
            NNODES=$VALUE
        ;;
        -m|--master)
            MASTER=$VALUE
        ;;
        -c|--config)
            CONFIG=$VALUE
        ;;
        -i|--input)
            INPUT=$VALUE
        ;;
        -o|--output)
            OUTPUT=$VALUE
        ;;
        *)
          echo "ERROR: unknown parameter \"$PARAM\""
          exit 1
        ;;
    esac
    shift
done

source /lus/theta-fs0/software/thetagpu/conda/pt_master/2020-11-25/mconda3/setup.sh
conda activate bert-pytorch

if [[ -z "${OMPI_COMM_WORLD_RANK}" ]]; then
    LOCAL_RANK=$MV2_COMM_WORLD_RANK
else
    LOCAL_RANK=${OMPI_COMM_WORLD_RANK}
fi

NUM_THREADS=$(grep ^cpu\\scores /proc/cpuinfo | uniq |  awk '{print $4}')
export OMP_NUM_THREADS=$((NUM_THREADS / NGPUS))

which python
#which nvcc
#nvcc --version

echo Launching torch.distributed: nproc_per_node=$NGPUS, nnodes=$NNODES, master_addr=$MASTER, local_rank=$LOCAL_RANK, OMP_NUM_THREADS=$OMP_NUM_THREADS, host=$HOSTNAME


python -m torch.distributed.launch \
   --nproc_per_node=$NGPUS --nnodes=$NNODES --node_rank=$LOCAL_RANK --master_addr=$MASTER \
   run_pretraining.py --config_file=$CONFIG --input_dir=$INPUT --output_dir $OUTPUT
