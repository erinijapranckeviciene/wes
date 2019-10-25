This folder contains script that generates exome 
report from the input db file. To generate a report 
invoke report-exome.sh with the bcbio-nextgen pipeline
created gemini db file. The report will be written 
to the same folder as gemini db file.
To call:

$sh /projects/analysis/report/report-exome.sh /path/to/the/bcbio_nextgen/gemini_db_file.db

Example:
$sh /projects/analysis/report/report-exome.sh /projects/CCM_transfer/CHEO/NA12878-VR2-2/final.gatk4/2019-09-02_NA12878-VR2-2/VR2-2-ensemble.db

OR change to the directory in which the gemini.db file is and run the command:

$cd /projects/CCM_transfer/CHEO/NA12878-VR2-2/final.gatk4/2019-09-02_NA12878-VR2-2
$sh /projects/analysis/report/report-exome.sh VR2-2-ensemble.db

Similarly for myoslice report use report-myoslice.sh
