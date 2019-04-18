#!/bin/sh

# ----- VARIABLES -----

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'


# ----- FUNCTIONS -----

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

# Print warning message
print_warn(){
	printf "${YELLOW}%s${NC}\n" "$1"
}

# Print stats in visual format
print_stats(){
	local scale=3
	local limit=`echo "$1/$scale" | bc`
	local count=0
	while [ $count -lt $limit ]
	do
		printf "${GREEN}+${NC}"
		(( count+=1 ))
	done
	printf "\n"
}

display_usage(){
	printf "Usage: sh 42_checker [options] [git_repo_url clone_name]\n"
	printf "Options:\n"
	printf "%s\n" " -e, --all               Check everything."
	printf "%s\n" " -r, --clone             Clone repository given as parameters before checking everything."
	printf "%s\n" " -h, --help              Print this message and exit."
	printf "%s\n" " -a, --author            Check for author file."
	printf "%s\n" " -n, --norminette        Check norminette."
	printf "%s\n" " -d, --headers           Check matching headers with file name."
	printf "%s\n" " -m, --makefiles         Check makefiles."
	printf "%s\n" " -c, --contrib           Check project contributors."
	printf "%s\n" " -g, --git-logs          Check git logs."
}

clone_repo(){
	local repo="$1"
	local date=`date "+%y%m%d%H%M%S"`
	CLONE_NAME="${DEST_FOLD}_$date"
	printf "Cloning ${MAGENTA}%s${NC} in ${MAGENTA}%s${NC}...\n" "$repo" "$CLONE_DEST_PATH"
	git clone "$repo" "$CLONE_DEST_PATH/$CLONE_NAME"
	[ $? -ne 0 ] && exit
}

check_author_file(){
	print_header "CHECK AUTHOR FILE"
	local has_author=`find . -maxdepth 1 -type f -name "author" -o -name "auteur" | wc -l | bc`
	if [ $has_author -eq 0 ]; then
		print_error "⟹  Oups! Author file not found."
	else
		print_ok "⟹  Good! Author file found"
		printf "%s\n" "Printing author file content..."
		find . -maxdepth 1 -type f -name "author" -o -name "auteur" -exec cat -e {} \;
	fi
	printf "\n"
}

check_norminette(){
	print_header "CHECK NORMINETTE"
	norminette | grep -E -B1 --color=auto "^(Error|Warning)" | grep -v "^--" | grep -E -v "Not a valid file" | grep -E -B1 --color=auto "^(Error|Warning)"
	local norm_res=`norminette | grep -E --color=auto "^(Error|Warning)" | grep -E -v "Not a valid file" | wc -l | bc`
	if [ $norm_res -ne 0 ]; then
		print_error "⟹  Oups! Norminette test failed."
	else
		print_ok "⟹  Good! Norminette test succeeded."
	fi
	printf "\n"
}

check_file_headers(){
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
	fi
	rm -f results.txt
	printf "\n"
}

check_makefiles(){
	print_header "CHECK MAKEFILES"
	printf "Check that Makefiles work as expected (no relink, no wildcards...)\n"
	local makefiles=`find . -type f -name "[Mm]akefile" -exec dirname {} \;`
	local nb_makefiles=`echo $makefiles | wc -w | bc`
	printf "Number of Makefiles found: "
	[ $nb_makefiles -ne 0 ] && print_ok $nb_makefiles || print_error $nb_makefiles
	for makefile in $makefiles
	do
		printf "Testing ${MAGENTA}$makefile/Makefile${NC}...\n"
		printf "> Relink? "
		local relink=`make --silent -C $makefile fclean > /dev/null 2>&1; make --silent -C $makefile > /dev/null 2>&1; make -C $makefile | grep -E "(\.o|\.c)" | wc -l | bc`
		[ "$relink" -ne 0 ] && print_error "YES" || print_ok "NO"
		printf "> Wildcards? "
		makefile_path=`find $makefile -maxdepth 1 -type f -name "[Mm]akefile" | tr -d '\n'`
		wildcard=`tail -n +12 $makefile_path | grep '\*.*\.c' | wc -l | bc`
		[ $wildcard -ne 0 ] && print_error "YES" || print_ok "NO"
#		printf "> Recompile? "
#		src_files=`make --silent -C $makefile fclean && make -C $makefile | grep -E -o "\b\w*\.o" | sort | uniq | sed 's/\.o/\.c/g'`
#		fail_recompile=0
#		for src in $src_files
#		do
#			if [ $fail_recompile -eq 0 ]; then
#				make --silent -C $makefile
#				find . -type f -name "$src" -exec touch {} \;
#				nb_obj_recompiled=`make -C $makefile | grep -E -o "\b\w*\.o" | sort | uniq | wc -l | bc`
#				if [ "$nb_obj_recompiled" -eq 0 ]; then
#					fail_recompile=1
#					echo $src >> srcs_errors.txt
#				fi
#			fi
#		done
#		if [ "$fail_recompile" -eq 1 ]; then
#			print_error "NO"
#			srcs_errors=`cat srcs_errors.txt | tr '\n' ' ' | sed 's/ *$//g'`
#			rm -f srcs_errors.txt
#			printf "Errors: (%s)\n" "$srcs_errors"
#		else
#			print_ok "YES"
#		fi
	done
}

check_contributors(){
	print_header "CHECK CONTRIBUTORS"
	printf "Check number of .c files created by each contributor to the project...\n"
	printf "Type the name of the directories to exclude (leave empty or ex: dirname1 dirname2 ...): "
	read dir_excluded
	local nb_dir=`echo $dir_excluded | tr -d '\n' | wc -w | bc`
	local directory="directory"
	[ $nb_dir -gt 1 ] && directory="directories"
	printf "%d %s will be excluded from search" $nb_dir $directory
	[ $nb_dir -gt 0 ] && printf " (${MAGENTA}%s${NC})\n" "$dir_excluded" || printf "\n"
	[ $nb_dir -gt 1 ] && dir_excluded=`echo $dir_excluded | sed -e 's/ *$//g' -e 's/ / --exclude-dir=/g' | tr -d '\n'`
	local contributors=`grep -E -r -h "By:" --exclude-dir=$dir_excluded --include "*.c" . | tr -d ' ' | cut -d : -f 2 | cut -d '<' -f 1 | sort | uniq | tr '\n' ' ' | sed -e 's/ *$//g'`
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
		(echo "USER FILES % SCALE"
		while read line
		do
			nb=`echo $line | awk '{print $2}'`
			user=`echo $line | awk '{print $1}'`
			[ $total_files -ne 0 ] && pct=`expr 200 \* $nb \/ $total_files \% 2 + 100 \* $nb \/ $total_files` #Faster implementation for rounding division
			scale=`print_stats $pct`
			echo  "$user" "$nb" "$pct%" "$scale"
		done < contributors.txt) | column -t
	fi
	[ ! -f contributors.txt ] && print_error "⟹  Oups! No contributors found." || printf "\n"
	rm -f contributors.txt
}

check_git_info(){
	print_header "CHECK GIT"
	printf "Check git log history...\n"
	local contributors=`git log | grep Author | tr -d ' ' | cut -d '<' -f 2 | cut -d '@' -f 1 | sort | uniq | tr '\n' ' ' | sed -e 's/ *$//g'`
	for name in $contributors
	do
		nb_occ=`git log | grep Author | grep $name | wc -l | bc`
		echo $name $nb_occ >> contributors.txt
	done
	[ -f contributors.txt ] && total_commits=`awk '{s+=$2} END {print s}' contributors.txt` || total_commits=0
	printf "Total number of commits: "
	[ $total_commits -ne 0 ] && print_ok $total_commits || print_error $total_commits
	if [ -f contributors.txt ]; then
		(echo "USER FILES % SCALE"
		while read line
		do
			nb=`echo $line | awk '{print $2}'`
			user=`echo $line | awk '{print $1}'`
			[ $total_commits -ne 0 ] && pct=`expr 200 \* $nb \/ $total_commits \% 2 + 100 \* $nb \/ $total_commits` #Faster implementation for rounding division
			scale=`print_stats $pct`
			echo  "$user" "$nb" "$pct%" "$scale"
		done < contributors.txt) | column -t
	fi
	[ ! -f contributors.txt ] && print_error "⟹  Oups! No contributors found." || printf "\n"
	rm -f contributors.txt
}

parse_parameters(){
	[ $# -eq 0 ] && ERR=true && return
	while [ "$#" -gt 1 ]
	do
		param="$1"
		if [ $param = "-e" ] || [ $param = "--all" ]; then
			ALL=true
			return
		elif [ $param = "-r" ] || [ $param = "--clone" ]; then
			CLONE=true
		elif [ $param = "-h" ] || [ $param = "--help" ]; then
			HELP=true
		elif [ $param = "-a" ] || [ $param =  "--author" ]; then
			AUTHOR=true
		elif [ $param = "-n" ] || [ $param = "--norm" ]; then
			NORM=true
		elif [ $param = "-d" ] || [ $param = "--headers" ]; then
			HEADERS=true
		elif [ $param = "-m" ] || [ $param = "--makefiles" ]; then
			MAKEFILES=true
		elif [ $param = "-c" ] || [ $param = "--contrib" ]; then
			CONTRIB=true
		elif [ $param = "-g" ] || [ $param = "--git" ]; then
			GIT=true
		else
			ERR=true
			return
		fi
		shift
	done
	if ! $ERR && $HELP || $AUTHOR || $NORM || $HEADERS || $MAKEFILES || $CONTRIB || $GIT; then
		ALL=false
	fi	
	REPO=$1
}

# ----- SCRIPT -----

DEST_FOLD=`whoami`
CLONE_DEST_PATH="/tmp/$DEST_FOLD"

PARAMS_LIST="$@"

# Options
ERR=false
ALL=true
CLONE=false
HELP=false
AUTHOR=false
NORM=false
HEADERS=false
MAKEFILES=false
CONTRIB=false
GIT=false
REPO=""

parse_parameters $PARAMS_LIST

if $ERR || $HELP; then
	display_usage	
	exit;
fi
	
if $CLONE; then
	clone_repo $REPO
	cd "$CLONE_DEST_PATH/$CLONE_NAME"
else
	cd $REPO 2> /dev/null
	if [ $? -ne 0 ];then
		print_error "Path not valid."
		print_error "Don't forget to add -r option if you want to clone a repository."
		exit
	fi
fi

if $ALL || $AUTHOR; then
	check_author_file
fi

if $ALL || $NORM; then
	check_norminette
fi

if $ALL || $HEADERS; then
	check_file_headers
fi

if $ALL || $MAKEFILES; then
	check_makefiles
fi

if $ALL || $CONTRIB; then
	check_contributors
fi

if $ALL || $GIT; then
	check_git_info
fi
