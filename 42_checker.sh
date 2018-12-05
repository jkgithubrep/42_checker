#############
# VARIABLES #
#############

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

clone_dest_path=~/goinfre


#############
# FUNCTIONS #
#############

# Print number of asterisks specify as parameter
print_asterisks(){
	local i=0
	local nbc=`echo -n "$1" | wc -c | bc`
	while [ $i -lt $nbc ]
	do
		printf "*"
		((i+=1))
	done
	printf "\n"
}

# Print header
print_header(){
	printf "\n"
	print_asterisks "$1"
	printf "* %s *\n" "$1"
	print_asterisks "$1"
}

# Print error message
print_error(){
	printf "${RED}%s${NC}\n" "$1"
}

# Print message ok
print_ok(){
	printf "${GREEN}%s${NC}\n" "$1"
}

# Print stats in visual format
print_stats(){
	scale=3
	limit=`echo "$1/$scale" | bc`
	count=0
	while [ $count -lt $limit ]
	do
		printf "${GREEN}+${NC}"
		(( count+=1 ))
	done
	printf "\n"
}

# Check that at least one parameter is in options_list
check_option(){
	while [ "$#" -gt 0 ]
	do
		for option in $options_list
		do
			[ "$option" = $1 ] && echo 1 && return 1
		done
		shift
	done
	echo 0
	return 0
}

# Check that all parameters are in options_list
check_all_options(){
	nb_arg="$#"
	count=0
	while [ "$#" -gt 0 ]
	do
		for option in $options_list
		do
			[ "$option" = $1 ] && (( count+=1 ))
		done
		shift
	done
	[ $count -lt $nb_arg ] && echo 0 || echo 1
}


#########
# USAGE #
#########

# Get params
params="$*"

# Check if there is a git repository to clone
clone=0
if [ $# -gt 1 ] && [ $1 == "git" ] && [ $2 == "clone" ] && [ "$3" != "" ]; then
	[ "$4" = "" ] && clone_name=`basename $3` || clone_name="$4"
	printf "Cloning ${MAGENTA}%s${NC} in ${MAGENTA}%s${NC}...\n" "$3" "$clone_dest_path"
	git clone "$3" "$clone_dest_path/$clone_name"
	[ "$?" -eq 0 ] && params="-e" || exit
	clone=1
	cd "$clone_dest_path/$clone_name"
fi

# Display usage
options_list="-a --author -c --contrib -d --headers -e --all -g --git -h --help -n --norminette -m --makefiles"
all_in_list=`check_all_options $*`
if [ $clone = 0 ] && ( [ $# -eq 0 ] || ( [ $# -gt 0 ] && [ "$all_in_list" -eq 0 ] )); then
	printf "Usage: sh 42_checker [options] | [git clone repo dest]\n"
	printf "Options:\n"
	printf "%s\n" " -a, --author			Check for author file."
	printf "%s\n" " -c, --contrib			Check project contributors."
	printf "%s\n" " -d, --headers			Check matching headers with file name."
	printf "%s\n" " -e, --all			Check everything."
	printf "%s\n" " -g, --git			Check git logs."
	printf "%s\n" " -h, --help			Print this message and exit."
	printf "%s\n" " -n, --norminette		Check norminette."
	printf "%s\n" " -m, --makefiles		Check makefiles."
	exit
fi

##########
# CHECKS #
##########

### Check author file ###

options_list="-a --author -e --all"
is_in_list=`check_option $params`
if [ $is_in_list -eq "1" ]; then
	print_header "CHECK AUTHOR FILE"
	has_author=`find . -maxdepth 1 -type f -name "author" -o -name "auteur" | wc -l | bc`
	if [ $has_author -eq 0 ]; then
		print_error "⟹  Oups! Author file not found."
	else
		print_ok "⟹  Good! Author file found"
		printf "%s\n" "Printing author file content..."
		find . -maxdepth 1 -type f -name "author" -o -name "auteur" -exec cat -e {} \;
	fi
	printf "\n"
fi

### Check norminette ###

options_list="-n --norminette -e --all"
is_in_list=`check_option $params`
if [ $is_in_list -eq "1" ]; then
	print_header "CHECK NORMINETTE"
	norminette | grep -E -B1 --color=auto "^(Error|Warning)" | grep -v "^--" | grep -E -v "Not a valid file" | grep -E -B1 --color=auto "^(Error|Warning)"
	norm_res=`norminette | grep -E --color=auto "^(Error|Warning)" | grep -E -v "Not a valid file" | wc -l | bc`
	if [ $norm_res -ne 0 ]; then
		print_error "⟹  Oups! Norminette test failed."
	else
		print_ok "⟹  Good! Norminette test succeeded."
	fi
	printf "\n"
fi

### Check files headers for non matching names ###

options_list="-d --headers -e --all"
is_in_list=`check_option $params`
if [ $is_in_list -eq "1" ]; then
	print_header "CHECK HEADERS"
	printf "Check files headers for non matching names....\n"
	{
	find . -type f -name "*.[ch]"  -exec sh -c 'basename {} > file_name_check_jk.txt' \;  -exec  sh -c 'head -n 4 {} | tail -n 1 | tr -d " " | cut -d : -f 1 | cut -c 3- > file_header_check_jk.txt' \; -exec sh -c "diff file_name_check_jk.txt file_header_check_jk.txt || echo '⟹  file: \033[36m'{}'\033[0m' '\033[31mERROR\033[0m'" \; && rm -f file_name_check_jk.txt file_header_check_jk.txt
	} 1> results.txt
	if [ -s results.txt ]; then
		print_error "⟹  Oups! Non matching names found:"
		cat results.txt
	else
		print_ok "⟹  Good! No non matching names found!"
		rm results.txt
	fi
	printf "\n"
fi


### Check project contributors ###

options_list="-c --contrib -e --all"
is_in_list=`check_option $params`
if [ $is_in_list -eq "1" ]; then
	print_header "CHECK CONTRIBUTORS"
	printf "Check number of .c files created by each contributor to the project...\n"
	printf "Type the name of the directories to exclude: "
	read dir_excluded
	nb_dir=`echo $dir_excluded | tr -d '\n' | wc -w | bc`
	directory="directory"
	[ $nb_dir -gt 1 ] && directory="directories"
	printf "%d %s will be excluded from search" $nb_dir $directory
	[ $nb_dir -gt 0 ] && printf " (${MAGENTA}%s${NC})\n" "$dir_excluded" || printf "\n"
	[ $nb_dir -gt 1 ] && dir_excluded=`echo $dir_excluded | sed -e 's/ *$//g' -e 's/ / --exclude-dir=/g' | tr -d '\n'`
	contributors=`grep -E -r -h "By:" --exclude-dir=$dir_excluded --include "*.c" . | tr -d ' ' | cut -d : -f 2 | cut -d '<' -f 1 | sort | uniq | tr '\n' ' ' | sed -e 's/ *$//g'`
	for name in $contributors
	do
		nb_occ=`grep -E -r -h "By: $name" --exclude-dir=$dir_excluded --include "*.c" . | wc -l | bc`
		printf "\nFiles created by ${MAGENTA}%s${NC}:\n" $name
		grep -r -l "By: $name"  --exclude-dir=$dir_excluded --include "*.c" . | column
		echo $name $nb_occ >> contributors.txt
	done
	[ -f contributors.txt ] && total_files=`awk '{s+=$2} END {print s}' contributors.txt` || total_files=0
	printf "\n"
	printf "⟹  Stats:\n"
	printf "Total number of .c files found: "
	[ $total_files -ne 0 ] && print_ok $total_files || print_error $total_files
	if [ -f contributors.txt ]; then
		(echo "User files pct scale"
		while read line
		do
			nb=`echo $line | awk '{print $2}'`
			user=`echo $line | awk '{print $1}'`
			[ $total_files -ne 0 ] && pct=`expr 200 \* $nb \/ $total_files \% 2 + 100 \* $nb \/ $total_files` #Faster implementation for rounding division
			printf "${MAGENTA}%s${NC} %s %s%s " $user $nb $pct "%"
			print_stats $pct
		done < contributors.txt) | cat -e
	fi
	[ ! -f contributors.txt ] && print_error "⟹  Oups! No contributors found." || printf "\n"
	rm -f contributors.txt
fi

### Check git info ###

options_list="-g --git -e --all"
is_in_list=`check_option $params`
if [ $is_in_list -eq "1" ]; then
	print_header "CHECK GIT"
	printf "Check git log history...\n"
	contributors=`git log | grep Author | tr -d ' ' | cut -d '<' -f 2 | cut -d '@' -f 1 | sort | uniq | tr '\n' ' ' | sed -e 's/ *$//g'`
	for name in $contributors
	do
		nb_occ=`git log | grep Author | grep $name | wc -l | bc`
		echo $name $nb_occ >> contributors.txt
	done
	[ -f contributors.txt ] && total_commits=`awk '{s+=$2} END {print s}' contributors.txt` || total_commits=0
	printf "Total number of commits: "
	[ $total_commits -ne 0 ] && print_ok $total_commits || print_error $total_commits
	if [ -f contributors.txt ]; then
		while read line
		do
			nb=`echo $line | awk '{print $2}'`
			user=`echo $line | awk '{print $1}'`
			#[ $total_commits -ne 0 ] && pct=`awk "BEGIN { pc=100*${nb}/${total_commits}; i=int(pc); print (pc-i<0.5)?i:i+1 }"`
			[ $total_commits -ne 0 ] && pct=`expr 200 \* $nb \/ $total_commits \% 2 + 100 \* $nb \/ $total_commits` #Faster implementation for rounding division
			printf "${MAGENTA}%s${NC} %s  %s%s " $user $nb $pct "%"
			print_stats $pct
		done < contributors.txt
	fi
	[ ! -f contributors.txt ] && print_error "⟹  Oups! No contributors found." || printf "\n"
	rm -f contributors.txt
fi

### Check Makefiles ###

options_list="-m --makefiles -e --all"
is_in_list=`check_option $params`
if [ $is_in_list -eq "1" ]; then
	print_header "CHECK MAKEFILES"
	printf "Check that Makefiles work as expected (no relink, dependencies,...)\n"
	makefiles=`find . -type f -name "[Mm]akefile" -exec dirname {} \;`
	nb_makefiles=`echo $makefiles | wc -w | bc`
	printf "Number of Makefiles found: "
	[ $nb_makefiles -ne 0 ] && print_ok $nb_makefiles || print_error $nb_makefiles
	for makefile in $makefiles
	do
		printf "Testing ${MAGENTA}$makefile/Makefile${NC}...\n"
		relink=`make --silent -C $makefile fclean; make -C $makefile > /dev/null 2>&1; make -C $makefile | grep -E "(\.o|\.c)" | wc -l | bc`
		printf "> Relink? "
		[ "$relink" -ne 0 ] && print_error "RELINK" || print_ok "NO RELINK"
	done
fi
