#!/bin/bash
#SBATCH --account=pawsey1228
#SBATCH --partition=work
#SBATCH --job-name=fastqc_test
#SBATCH --cpus-per-task=48
#SBATCH --ntasks=1
#SBATCH --mem=80G
#SBATCH --time=6:00:00
#SBATCH --output=slurm_logs/01_raw_fastqc.%j.out
#SBATCH --error=slurm_logs/01_raw_fastqc.%j.err


### NOTE: this does one sample per thread at a time
### e.g., 6 threads = 6 processed in one go
### Up the number of threads when you have more files to process

# where on /scratch are we putting all our data?
SCRATCH_DIR=/scratch/pawsey1132/atims/l_punc_popgen/bpa_0ab79612_20260512T0521

# names of input and output directories
# raw short reads should be in ${SCRATCH_DIR}/raw_reads
INPUT_DIR=raw_reads
OUTPUT_DIR=fastqc_raw
MULTIQC_DIR=multiqc_raw

#make directories on /scratch
mkdir ${SCRATCH_DIR}/${OUTPUT_DIR}
mkdir ${SCRATCH_DIR}/${MULTIQC_DIR}


# symlink to working directory for easier viewing
ln -s ${SCRATCH_DIR}/${INPUT_DIR} ${INPUT_DIR}
ln -s ${SCRATCH_DIR}/${OUTPUT_DIR} ${OUTPUT_DIR}
ln -s ${SCRATCH_DIR}/${MULTIQC_DIR} ${MULTIQC_DIR}


module load singularity/4.1.0-nohost

singularity exec \
	docker://quay.io/biocontainers/fastqc:0.11.9--hdfd78af_1 \
	fastqc ${INPUT_DIR}/*.fastq.gz -o ${OUTPUT_DIR}/ -t 48

singularity exec \
	docker://quay.io/biocontainers/multiqc:1.27.1--pyhdfd78af_0 \
	multiqc $OUTPUT_DIR -o $MULTIQC_DIR	