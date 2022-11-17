#!/bin/bash

if [[ "$1" != "" ]] ; then
	dir="$1"
else
	dir="."
fi

# if $1 is a path then it sets dir to that path -- I did not include a check for if the path is legitimate
# because the path is usually autofilled by pressing TAB 
# in the case it's incorrect the script just exits, the user is not kept on hold

echo ================== FASTASCAN ==================

tot_count_seq=0
tot_seq_length=0
there_are_binary=0

if [[ "$(find "$dir" \( -name "*fasta" -o -name "*fa" \))" == "" ]] ; then 
# if the directory doesn't not have any files this is printed

	echo Directory does not contain any fasta/fa files.
	# I found that this doesn't really need to be included, if there are no fasta/fa files it just returns TOTAL 0 0
	# but just as a precautionary measure I included it, in case for different OS it's a different case 
else
# if the directory contains fasta/fa files, then ... 

	echo FILE$'\t'count_seq$'\t'seq_length$'\t'type
	# my idea was to organise the information in a tabular manner 
	# the coulmn names are printed: FILE count_seq seq_length type
	
	for FILE in $(find "$dir" \( -name "*fasta" -o -name "*fa" \)) ; do	
	
	# for each fasta/fa file the counts are reset after the run 
		count_seq=0
		seq_length=0
		is_prot=0
		is_nuc=0
		
		count_seq=$(grep -ao '^>' $FILE | wc -l)
		# seq number is counted by the > character if it's in the first line (seq title)
		# this is because some files (./proteins/scly_proteins.ncbi.fa) had > twice, so it would be counted as two instead of one seq 
		
		# -o converts each ">" found into a character and enters a new line ; then wc -l counts the number of lines ei. the number of ">"
		# -a is used because some files were binary and a warining was printed; so, -a skips that warning 
		
		line_length=$(grep -av '^>' $FILE | grep -aoi [A-Z] | wc -l)
		seq_length=$(($seq_length+$line_length))
		# in lines that are not the seq title (-v switch), the A-Z is counted disregarding case because some files had lowercase characters in some regions
		
		nuc=$(grep -av '^>' $FILE | grep -aoi [CGTAN] | wc -l)
		is_nuc=$(($is_nuc+$nuc))
		# the number of 'nucleotides' is counted disregardnig case; N (nucleotide) is included

		if [[ $count_seq -ne 0 ]] ; then 
		# if there are seq titles in the file
			if [[ $seq_length -gt $is_nuc ]] ; then
				type="prot"
				# if there are more A-Z then CGTAN in non-title-lines, it's a protein 
			elif [[ $seq_length -eq $is_nuc ]] ; then
				type="nuc"
				# if the total length is only made up of CGTAN it's a nucleotide seq
				# WEAKNESS: this means that a hypothetical protein made up of CGTAN would be classified as a nucletoide seq as well 
			fi
		
		elif [[ $count_seq -eq 0 ]] && [[ $line_length -ne 0 ]] ; then
		# if it's a fasta/fa file with no seq title but it has a lenght, it's a binary file
			type="binary->(num_char:$seq_length)"
			# the "seq_lenght" is printed 
			seq_length=0
			# but it's not taken into concideration when calculating the total
			# because a binary file does not contain a seqence, so we can't talk about a seq_lenght
			# WEAKNESS: any file that does not have a seq_title but has a sequence will be classified as a binary file 
			there_are_binary=1
			# the 'switch' for binary files is 'turned on'
		else
			type="N/A"
			# in case it doesn't have a seq_title nor a lenght we can't know what type of file it is 
		fi
		
		tot_count_seq=$(($tot_count_seq+$count_seq))
		tot_seq_length=$(($tot_seq_length+$seq_length))
		# totals of file are calculated
		
		echo $FILE$'\t'$count_seq$'\t'$seq_length$'\t'$type
		# results are printed in a tab separated format
		# each file is a record with variables name, count_seq, seq_length and type 
	done 
	# the ittiration through all the files is finished
	
	echo TOTAL$'\t'$tot_count_seq$'\t'$tot_seq_length 
	# the totals are printed
	echo ===============================================
	
	if [[ $there_are_binary -eq 1 ]] ; then
		# if there are binary files 
		echo '# note that num_char of binary files is NOT included in TOTAL'
		# for unambiguity user is informed that TOTAL does not contain scores of binary files 
	fi
	
	# the first seqence title is printed
	echo $'\n'The following is an example of a sequence title:
	grep -h ">" $(find "$dir" \( -name "*fasta" -o -name "*fa" \)) | head -n 1 | awk -F "" '{print substr($0, 2)}'
	
fi


if [[ "$(find "$dir" -type l \( -name "*fasta" -o -name "*fa" \))" != "" ]] ; then 
# if there are linked fasta/fa files, then .... 

	echo $'\n'The following are link-files:
	# they're printed
	find "$dir" -type l \( -name "*fasta" -o -name "*fa" \)
	echo '# note that the scores of the link files ARE inclued in TOTAL'
	# user is informed that the count_seq and seq_length of the link files are included in TOTAL value 
fi




