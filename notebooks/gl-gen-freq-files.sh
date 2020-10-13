#!/bin/bash
# The interpreter used to execute the script

#“#SBATCH” directives that convey submission options:

#SBATCH --job-name=make-freq-files
#SBATCH --mail-user=libbyh@umich.edu
#SBATCH --mail-type=BEGIN,END
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=12:00:00
#SBATCH --account=libbyh1
#SBATCH --partition=largemem
#SBATCH --mem-per-cpu=124GB
#SBATCH --output=/home/%u/%x-%j.log

# The application(s) to execute along with its input arguments and options:
python gen_freq_files.py > gen.txt
