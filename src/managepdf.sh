#!/usr/bin/env bash

CURR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )";
[ -d "${CURR_DIR}" ] || { echo "FATAL: no current dir (maybe running in zsh?)";  exit 1; }

source "${CURR_DIR}/options.bash"

pdf_split () {
    shift # delete option

    FILE=$1
    OUTPUT=${FILE%.pdf}

    NB="$(pdftk "${FILE}" dump_data | grep "NumberOfPages" | cut -d":" -f2)"
    NBR="$(printf "%03d" "${NB}")"

    for i in $(seq -w "${NBR}"); do pdftk "${FILE}" cat "$i" output "${OUTPUT}_$i.pdf"; done
}

pdf_join () {
    shift # delete option

    OUTPUT="$1"
    shift

    echo "pdftk" "$@" "cat output ${OUTPUT}"

    # shellcheck disable=SC2068
    pdftk $@ cat output "${OUTPUT}"
}


function main() {
    addOption -j --join  flagTrue help="${BASH_SOURCE[0]##*/} --join final.pdf f1.pdf f2.pdf ..."
    addOption -s --split flagTrue help="${BASH_SOURCE[0]##*/} --split file.pdf"
    parseOptions "$@"

    # shellcheck disable=SC2154
    [ "${join}" = false ] \
	&& [ "${split}" = false ] \
	&& __showHelp__

    [ "${split}" = true ] && pdf_split "$@"
    [ "${join}" = true ] && pdf_join "$@"
}

main "$@"
