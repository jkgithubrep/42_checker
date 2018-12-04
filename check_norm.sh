# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

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

print_header(){
	printf "\n"
	print_asterisks "$1"
	printf "* %s *\n" "$1"
	print_asterisks "$1"
}

print_error(){
	printf "${RED}%s${NC}\n" "$1"
}

print_ok(){
	printf "${GREEN}%s${NC}\n" "$1"
}

# Check author file
print_header "CHECK AUTHOR FILE"
has_author=`find . -maxdepth 1 -type f -name "author" -o -name "auteur" -exec sh -c "cat -e {} | wc -l | bc" \;`
if [ $has_author -eq 0 ]; then
	print_error "⟹  Oups! Author file not found."
else
	print_ok "⟹  Good! Author file found:"
	find . -maxdepth 1 -type f -name "author" -o -name "auteur" -exec sh -c "cat -e {} " \;
fi


# Check norminette

print_header "CHECK NORMINETTE"
norminette | grep -E -B1 --color=auto -e "^(Error|Warning)" | grep -v "^--" | grep -E -v "Not a valid file" | grep -E -B1 --color=auto -e "^(Error|Warning)"
norm_res=`norminette | grep -E -B1 --color=auto -e "^(Error|Warning)" | grep -v "^--" | grep -E -v "Not a valid file" | grep -E -B1 --color=auto -e "^(Error|Warning)" | wc -l | bc`
if [ $norm_res -ne 0 ]; then
	print_error "⟹  Oups! Norminette test failed."
else
	print_ok "⟹  Good! Norminette test succeeded."
fi

# Check files headers for non matching names

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

# Check project contributors
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
	grep -r -l "By: $name"  --exclude-dir=$dir_excluded --include "*.c" .
	echo $name $nb_occ >> contributors.txt
done
[ -f contributors.txt ] && total_files=`awk '{s+=$2} END {print s}' contributors.txt` || total_files=0
printf "\n"
printf "⟹  Stats:\n"
printf "Total number of .c files found: "
[ $total_files -ne 0 ] && print_ok $total_files || print_error $total_files
i=1
if [ -f contributors.txt ]; then
	while read line
	do
		nb=`echo $line | awk '{print $2}'`
		[ $total_files -ne 0 ] && pct=`echo "scale=2; ($nb/$total_files)" | bc`
		pct=`echo "($pct * 100)/1" | bc`
		printf "%s %s%s " "$line" $pct "%"
		print_stats $pct
		(( i+=1 ))
	done < contributors.txt
fi
[ ! -f contributors.txt ] && print_error "⟹  Oups! No contributors found." || printf "\n"
rm -f contributors.txt

# Check git info
print_header "CHECK GIT"
printf "Check git log history...\n"
contributors=`git log | grep Author | tr -d ' ' | cut -d '<' -f 2 | cut -d '@' -f 1 | sort | uniq | tr '\n' ' ' | sed -e 's/ *$//g'`
for name in $contributors
do
	nb_occ=`git log | grep Author | grep $name | wc -l | bc`
	printf "Nb of commits by ${MAGENTA}%s${NC}: ${GREEN}%s${NC}\n" $name $nb_occ
	echo $name $nb_occ >> contributors.txt
done
[ -f contributors.txt ] && total_commits=`awk '{s+=$2} END {print s}' contributors.txt` || total_commits=0
if [ -f contributors.txt ]; then
	while read line
	do
		nb=`echo $line | awk '{print $2}'`
		[ $total_files -ne 0 ] && pct=`echo "scale=2; ($nb/$total_files)" | bc`
		pct=`echo "($pct * 100)/1" | bc`
		printf "%s %s%s " "$line" $pct "%"
		print_stats $pct
		(( i+=1 ))
	done < contributors.txt
fi
[ ! -f contributors.txt ] && print_error "⟹  Oups! No contributors found." || printf "\n"
rm -f contributors.txt

