#!/bin/bash
#SBATCH --account=pawsey1228
#SBATCH --partition=work
#SBATCH --job-name=02_trimmomatic_test
#SBATCH --cpus-per-task=6
#SBATCH --ntasks=1
#SBATCH --mem=10G
#SBATCH --time=1:00:00
#SBATCH --array=1-8:2
#SBATCH --output=slurm_logs/02_trimmomatic.%A_%a.out
#SBATCH --error=slurm_logs/02_trimmomatic.%A_%a.err

### NOTE: this array config assumes files are in the list order
### ind1_L001_R1.fq.gz
###	ind1_L001_R2.fq.gz
### ind1_L002_R1.fq.gz
###	ind1_L002_R2.fq.gz
###	ind2_L001_R1.fq.gz
###	ind2_L001_R2.fq.gz
###	ind2_L002_R1.fq.gz
###	ind2_L002_R2.fq.gz, etc
### and pulls all the R1 file names based on this assumption

### NOTE: '--array=1-240:2' means the job will be iterated over 240 files in increments of two
### i.e., file1, file3 ... file239 in the array
### this should correspond to all the _R1 reads
### check how many files you have with 'ls raw_reads/ | wc -l'

### NOTE: output files can be compressed by trimmomatic
### but it's slow af so don't bother unless you're short on space
### TESTING WITH v0.4's parallel zipping 

module load singularity/4.1.0-nohost

# list of files generated with 
# ls *.fastq.gz > filenames.txt

config=filenames.txt

# where on /scratch are we putting all our data?
SCRATCH_DIR=/scratch/pawsey1132/atims/l_punc_popgen/bpa_0ab79612_20260512T0521

# where do the input and output files go?
RAW_READS_DIR=raw_reads
TRIM_DIR=trimmomatic_output

# create directories for output data
if ! [ -d ${SCRATCH_DIR}/${TRIM_DIR} ]; then
    mkdir ${SCRATCH_DIR}/${TRIM_DIR}
fi

# create symlinks for easier viewing
if ! [ -d ${TRIM_DIR} ]; then
    ln -s ${SCRATCH_DIR}/${TRIM_DIR} ${TRIM_DIR}
fi

echo $SLURM_ARRAY_TASK_ID

# file path and name of R1 file we're working on
FILE1=${RAW_READS_DIR}/$(basename $(awk -F"\t" -v id="${SLURM_ARRAY_TASK_ID}" 'NR==id {print $1}' $config))

echo $FILE1

    # name R1 input file 
	file1=$FILE1

    # name R2 input file by swapping _R1 for _R2
	file2=$(echo ${FILE1}| sed -r 's/_R1/_R2/g')

    # add outdir, swap file suffixes to name output files
	out1="${TRIM_DIR}/$(basename --suffix=.fastq.gz $file1).trim_pe.fastq.gz"
	out1se="${TRIM_DIR}/$(basename --suffix=.fastq.gz $file1).trim_se.fastq.gz"

	out2="${TRIM_DIR}/$(basename --suffix=.fastq.gz $file2).trim_pe.fastq.gz"
	out2se="${TRIM_DIR}/$(basename --suffix=.fastq.gz $file2).trim_se.fastq.gz"


### change the trimmomatic params depending onhow the raw read qc comes out
### ILLUMINACLIP:TruSeq3-PE-2-GGGGG.fa = searches for these adapters: 
### https://github.com/usadellab/Trimmomatic/blob/v0.40/adapters/TruSeq3-PE-2-GGGGG.fa
### 7:25:8:1:true = maximum mismatch count to still consider it a match:
### palindrome clip threshold
### simple clip threshold
### minimum adapter length in palindrome mode
### Keep both reads
### starting point: 2:30:10:2:True

### HEADCROP: remove this many bases from the start of each read
### base on raw multiqc output graph of base % by position

### LEADING: TRAILING: drop any bases at the start/end below this quality

### SLIDINGWINDOW:20:28 - scan with sliding window 20, cut when average base quality drops below 28

### MINLEN: drop any reads shorter than this


singularity exec \
    docker://quay.io/biocontainers/trimmomatic:0.40--hdfd78af_0 \
	trimmomatic PE $file1 $file2 $out1 $out1se $out2 $out2se \
	ILLUMINACLIP:NexteraPE-PE-GGGGG.fa:2:30:10:2:True \
	LEADING:6 TRAILING:6 SLIDINGWINDOW:4:30 MINLEN:50 \
	-threads 6

