#!/bin/bash

parser() {
	local parsed=""
	
	local pline=""
	local in_func=0
	
	while IFS= read -r line; do
		if [[ $in_func == 0 && $line =~ ^@([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]+(.*)\{$ ]]; then
			in_func=1
			pline="${BASH_REMATCH[1]}() {"
			local args=(${BASH_REMATCH[2]})
			for i in "${!args[@]}"; do
				pline+=" local ${args[i]}=\"\$$(($i+1))\";"
			done
		elif [[ $line =~ ^\:([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*(.*)$ ]]; then
			pline="${BASH_REMATCH[1]} ${BASH_REMATCH[2]}"
		else
			if [[ $in_func == 1 && $line =~ ^\}$ ]]; then
				in_func=0
			fi
			pline="$line"
		fi
		
		parsed+="$pline"$'\n'
	done
	bash <<< "$parsed"
}

parse() {
  	awk -v lib="$(basename "${BASH_SOURCE[0]}")" '!($0 ~ "^source .*" lib "$")' "${BASH_SOURCE[2]}" | parser
  	exit 0
}

echo ${BASH_SOURCE[@]}
echo hello


if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
	parse
fi
