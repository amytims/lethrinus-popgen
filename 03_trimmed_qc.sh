#!/bin/bash
#SBATCH --account=pawsey1228
#SBATCH --partition=work
#SBATCH --job-name=trimmed_fastqc
#SBATCH --cpus-per-task=48
#SBATCH --ntasks=1
#SBATCH --mem=80G
#SBATCH --time=6:00:00
#SBATCH --output=slurm_logs/03_trimmed_fastqc.%j.out
#SBATCH --error=slurm_logs/03_trimmed_fastqc.%j.err


### NOTE: this does one sample per thread at a time
### e.g., 6 threads = 6 processed in one go
### Up the number of threads when you have more files to process

# where on /scratch are we putting all our data?
SCRATCH_DIR=/scratch/pawsey1132/atims/l_punc_popgen/bpa_0ab79612_20260512T0521

# where do the input and output files go?
TRIM_DIR=trimmomatic_output
TRIMQC_DIR=fastqc_trim
TRIM_MULTIQC_DIR=multiqc_trim

# create directories for output data
if ! [ -d ${SCRATCH_DIR}/${TRIMQC_DIR} ]; then
    mkdir ${SCRATCH_DIR}/${TRIMQC_DIR}
fi

if ! [ -d ${SCRATCH_DIR}/${TRIM_MULTIQC_DIR} ]; then
    mkdir ${SCRATCH_DIR}/${TRIM_MULTIQC_DIR}
fi


# create symlinks ofr easier viewing
if ! [ -d ${TRIMQC_DIR} ]; then
    ln -s ${SCRATCH_DIR}/${TRIMQC_DIR} ${TRIMQC_DIR}
fi

if ! [ -f ${TRIM_MULTIQC_DIR} ]; then
    ln -s ${SCRATCH_DIR}/${TRIM_MULTIQC_DIR} ${TRIM_MULTIQC_DIR}
fi

module load singularity/4.1.0-nohost

singularity exec \
	docker://quay.io/biocontainers/fastqc:0.11.9--hdfd78af_1 \
	fastqc ${TRIM_DIR}/*trim_pe.fastq.gz -o ${TRIMQC_DIR}/ -t 48

singularity exec \
	docker://quay.io/biocontainers/multiqc:1.27.1--pyhdfd78af_0 \
	multiqc $TRIMQC_DIR -o $TRIM_MULTIQC_DIR	
