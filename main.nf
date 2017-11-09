#!/usr/bin/env nextflow
/*
vim: syntax=groovy
-*- mode: groovy;-*-
========================================================================================
               QBIC-RNASeq-Workflow    B E S T    P R A C T I C E
========================================================================================
 RNASeq Workflow (imgag/megSAP). Started in November 2017.
 #### Homepage / Documentation
 https://github.com/qbicsoftware/qbic-workflow-nf-rnaseq
 #### Authors
 Alexander Peltzer <alexander.peltzer@qbic.uni-tuebingen.de>
----------------------------------------------------------------------------------------
*/

//Version of the pipeline

version=1.0

def helpMessage() {
    log.info"""
    =========================================
    QBIC-RNASeq-Workflow  v${version}
    =========================================
    Usage:

    
 """
}

//Help message if nothing else is specified

params.help = false

if(params.help){
	helpMessage()
	exit 0
}

//Check NF version similar to NGI-RNAseq, thanks guys!

nf_required_version = '0.25.0'
try {
    if( ! nextflow.version.matches(">= $nf_required_version") ){
        throw GroovyException('Nextflow version too old')
    }
} catch (all) {
    log.error "====================================================\n" +
              "  Nextflow version $nf_required_version required! You are running v$workflow.nextflow.version.\n" +
              "  Pipeline execution will continue, but things may break.\n" +
              "  Please run `nextflow self-update` to update Nextflow.\n" +
              "============================================================"
}

//We're using the same defaults as in the original workflow specification here




DATA = config['data']
RESULT = config['result']
LOGS = config['logs']
REF = config['ref']
ETC = config['etc']
SNAKEDIR = config['src']




params.folder = false
params.name = false
params.system = false
params.steps = "ma,vc,an,cn" //db import not for us, just at IMGAG
params.backup = false
params.lofreq = false
params.threads = '2'
params.thres = '20'
params.clip_overlap = false
params.no_abra = false
params.out_folder = 'default'
params.log = false
params.conf = false
params.tdx = false
params.email = false
params.multiqc_config = "$baseDir/conf/multiqc_config.yaml"

multiqc_config = file(params.multiqc_config)


//Validate inputs


//TBD


//Header log info

log.info "========================================="
log.info " QBIC-megSAP-NGS : v${version}"
log.info "========================================="


def summary = [:]
summary['Folder']     = params.folder
summary['Name']        = params.name
summary['System']    = params.system
summary['Steps']       = params.steps
summary['Backup'] = params.backup
summary['Low Frequency'] = params.lofreq
summary['Threads'] = params.threads
summary["Threshold"] = params.thres
summary["Clip Overlap"] = params.clip_overlap
summary["Logfile"] = params.log
summary["Special configuration"] = params.conf
summary["TDX"] = params.tdx

if(params.email) summary['E-Mail address'] = params.email
log.info summary.collect { k,v -> "${k.padRight(15)}: $v" }.join("\n")
log.info "========================================="


/*
Run megSAP-analyze.php with selected parameters on input file(s)
*/


process qbic_megsap_single_sample_analysis {
	tag "$name"
	publishDir "${params.out_folder}", mode: 'copy',
      saveAs: {filename -> 
              if(filename.indexOf(".bam") == -1) "$params.out_folder/$filename"
         else if(filename.indexOf(".bai") == -1) "$params.out_folder/$filename"
         else if(filename.indexOf(".gsvar") == -1) "$params.out_folder/$filename"
         else if(filename.indexOf(".qcml") == -1)  "$params.out_folder/$filename"
         else "$filename"
      }

	//publishDirs etc?

	input:
	val folder_path from params.folder
	val sample_id from params.name
	val threads from params.threads
	val steps from params.steps
  val system from params.system

	output:

	script:
	"""
	php /megSAP/src/Pipelines/analyze.php -folder ${folder_path} -name ${sample_id} -threads ${threads} -steps ${steps} -system ${system}

	"""

/*-folder <string>         Analysis data folder.
  		-name <string>           Base file name, typically the processed sample ID (e.g. 'GS120001_01').

	Optional parameters:
  		-system <infile>         Processing system INI file (determined from NGSD via the 'name' by default).
  		-steps <string>          Comma-separated list of steps to perform:
        		                 ma=mapping, vc=variant calling, an=annotation, db=import into NGSD, cn=copy-number analysis.
                		         Default is: 'ma,vc,an,db,cn'.
  		-backup                  Backup old analysis files to old_[date] folder.
  		-lofreq                  Add low frequency variant detection.
  		-threads <int>           The maximum number of threads used.
      		                     Default is: '2'.
  		-thres <int>             Splicing region size used for annotation (flanking the exons).
       		                     Default is: '20'.
  		-clip_overlap            Soft-clip overlapping read pairs.
  		-no_abra                 Skip realignment with ABRA.
  		-out_folder <string>     Folder where analysis results should be stored. Default is same as in '-folder' (e.g. Sample_xyz/).
                           Default is: 'default'.

	Special parameters:
  		--log <file>             Enables logging to the specified file.
  		--conf <file>            Uses the given configuration file.
  		--tdx                    Writes a Tool Defition XML file.
  		--email                  Sends you an e-mail on success/fail/etc (NOT YET IMPLEMENTED)

  		*/

}