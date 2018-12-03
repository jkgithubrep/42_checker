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
