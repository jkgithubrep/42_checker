# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Check files headers for non matching names

printf "*****************\n"
printf "* CHECK HEADERS *\n"
printf "*****************\n"
printf "Check files headers for non matching names....\n"
{
find . -type f -name "*.[ch]"  -exec sh -c 'basename {} > file_name_check_jk.txt' \;  -exec  sh -c 'head -n 4 {} | tail -n 1 | tr -d " " | cut -d : -f 1 | cut -c 3- > file_header_check_jk.txt' \; -exec sh -c "diff file_name_check_jk.txt file_header_check_jk.txt || echo '⟹  file: \033[36m'{}'\033[0m' '\033[31mERROR\033[0m'" \; && rm file_name_check_jk.txt file_header_check_jk.txt
} 1> results.txt
if [ -s results.txt ]; then
	printf "${RED}Oups! Non matching names found:${NC}\n"
	cat results.txt
else
	printf "${GREEN}Good! No non matching names found!${NC}\n"
	rm results.txt
fi
