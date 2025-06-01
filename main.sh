#!/bin/bash

trimP() {
	local str="$1"
	str="${str#"${str%%[![:space:]]*}"}"
	str="${str%"${str##*[![:space:]]}"}"
	str="${str//and/\&\&}"
	str="${str//or/||}"
	echo "$str"
}

parser() {
	local parsed=""
	parsed+=$'\n'
	
	local pline=""
	local block_stack=()
	
	while IFS= read -r line; do
		if [[ $line =~ ^[[:space:]]*\@([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]+(.*)\{$ ]]; then
			block_stack+=(0)
			pline="${BASH_REMATCH[1]}() {"
			local args=(${BASH_REMATCH[2]})
			for i in "${!args[@]}"; do
				pline+=" local ${args[i]}=\"\$$(($i+1))\";"
			done
		elif [[ $line =~ ^[[:space:]]*\:([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*(.*)$ ]]; then
			pline="${BASH_REMATCH[1]} ${BASH_REMATCH[2]}"
		elif [[ $line =~ ^[[:space:]]*\?[[:space:]]*\[[[:space:]]*(.*)[[:space:]]*\][[:space:]]*\{[[:space:]]*$ ]]; then
			local ifp=$(trimP "${BASH_REMATCH[1]}")
			pline="if [[ $ifp ]]; then"
			block_stack+=(1)
		elif [[ $line =~ ^[[:space:]]*\?\![[:space:]]*\[[[:space:]]*(.*)[[:space:]]*\][[:space:]]*\{[[:space:]]*$ ]]; then
			local elifp=$(trimP "${BASH_REMATCH[1]}")
			pline="elif [[ $elifp ]]; then"
		elif [[ $line =~ ^[[:space:]]*\![[:space:]]*\{[[:space:]]*$ ]]; then
			pline="else"
		elif [[ $line =~ ^[[:space:]]*\~[[:space:]]*\[[[:space:]]*(.*)[[:space:]]*\][[:space:]]*\{[[:space:]]*$ ]]; then
			local whilep=$(trimP "${BASH_REMATCH[1]}")
			pline="while [[ $whilep ]]; do"
			block_stack+=(2)
		elif [[ $line =~ ^^[[:space:]]*\+[[:space:]]*\[[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]+in[[:space:]]+(.*)[[:space:]]*\][[:space:]]*\{[[:space:]]*$ ]]; then
			local form=$(trimP "${BASH_REMATCH[1]}")
			local forn=$(trimP "${BASH_REMATCH[2]}")
			if [[ "$forn" =~ ^\$([a-zA-Z_][a-zA-Z0-9_]*)$ ]]; then
  				forn="\"\${${BASH_REMATCH[1]}[@]}\""
			fi
			pline="for $form in $forn; do"
			block_stack+=(2)
		elif [[ $line =~ ^[[:space:]]*\$([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*=[[:space:]]*(.*)$ ]]; then
  			local varn="${BASH_REMATCH[1]}"
  			local varv="${BASH_REMATCH[2]}"
  			pline="$varn=$varv"
		elif [[ $line =~ ^[[:space:]]*local[[:space:]]+\$([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*=[[:space:]]*(.*)$ ]]; then
  			local lvarn="${BASH_REMATCH[1]}"
  			local lvarv="${BASH_REMATCH[2]}"
  			pline="local $lvarn=$lvarv"
		elif [[ $line =~ ^[[:space:]]*\}$ ]]; then
			local index=$((${#block_stack[@]} - 1))
			local block="${block_stack[$index]}"
			if [[ $block == 0 ]]; then
				pline="$line"
				unset block_stack[$index]
			elif [[ $block == 1 ]]; then
				pline="fi"
				unset block_stack[$index]
			elif [[ $block == 2 ]]; then
				pline="done"
				unset block_stack[$index]
			else
				echo "stack error: LLL.mdns.445675467: [usage: f{:**m!>>>}. error in core dimension 0. mismatch error with signature (m?,n?)] in dim0 while processing 'stack'. crash error: gufunc traceback error occured: missing or broken '{'."
			fi
		else
			pline="$line"
		fi
		
		parsed+="$pline"$'\n'
	done
	#echo "$parsed" > ~/Desktop/temp.sh
	tmpfile=$(mktemp)
	echo "$parsed" > "$tmpfile"
	bash "$tmpfile"
	rm "$tmpfile"
}

parse() {
	grep -v '^[[:space:]]*source ' "$0" | parser
  	exit 0
}

if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
	parse
fi
