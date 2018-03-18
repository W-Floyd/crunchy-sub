#!/bin/bash

while read -r __program; do
    if ! which "${__program}" &> /dev/null; then
        echo "'${__program}' not installed."
        exit
    fi
done <<< 'awk-csv-parser'

source ./crunchyroll

# modified from https://github.com/xvoland/Extract
extract () {
 if [ -z "$1" ]; then
    # display usage if no parameters given
    echo "Usage: extract <path/file_name>.<zip|rar|bz2|gz|tar|tbz2|tgz|Z|7z|xz|ex|tar.bz2|tar.gz|tar.xz>"
    echo "       extract <path/file_name_1.ext> [path/file_name_2.ext] [path/file_name_3.ext]"
 else
    for n in "${@}"
    do
      if [ -f "${n}" ] ; then
          case "${n}" in
            *.tar.bz2|*.tar.gz|*.tar.xz|*.tbz2|*.tgz|*.txz|*.tar) 
                         tar xvf "${n}"       ;;
            *.lzma)      unlzma ./"${n}"      ;;
            *.bz2)       bunzip2 ./"${n}"     ;;
            *.rar)       unrar x -ad ./"${n}" ;;
            *.gz)        gunzip ./"${n}"      ;;
            *.zip)       unzip ./"${n}"       ;;
            *.z)         uncompress ./"${n}"  ;;
            *.7z|*.arj|*.cab|*.chm|*.deb|*.dmg|*.iso|*.lzh|*.msi|*.rpm|*.udf|*.wim|*.xar)
                         7z x ./"${n}"        ;;
            *.xz)        unxz ./"${n}"        ;;
            *.exe)       cabextract ./"${n}"  ;;
            *.aqt|*.cvd|*.dks|*.jss|*.mpl|*.txt|*.pjs|*.rt|*.smi|*.srt|*.ssa|*.ass|*.sub|*.idx|*.svcd|*.usf|*.psb|*.ttxt)
                         echo "File '${n}' is a direct sub file."
                         ;;
            *)
                         echo "extract: '${n}' - unknown archive method"
                         return 1
                         ;;
          esac
      else
          echo "'${n}' - file does not exist"
          return 1
      fi
    done
fi
}

__mkdir () {
if ! [ -d "${1}" ]; then
    mkdir -p "${1}"
fi
}

# list_subs 'sub name'
list_subs () {
    local __sub_title="${1}"
    local __url="$(grep "<strong>${__sub_title}</strong>" < "${__site_file}" | sed -e 's#.*<a href="#http://kitsunekko.net#' -e 's/" class=.*//')"
    wget "${__url}" -qO - | grep '<tr><td>' | sed -e 's#.*<a href="#http://kitsunekko.net/#' -e 's/" class=.*//'
}

# download_subs 'sub name'
download_subs () {
    local __sub_title="${1}"
    local __sub_dir="${__download_dir_subs}/${__sub_title}"
    __mkdir "${__sub_dir}"
    list_subs "${__sub_title}" | while read -r __url; do
        local __sub_hash="$(sha1sum <<< "${__url}" | sed 's/ .*//')"
        local __url_dir="${__sub_dir}/${__sub_hash}"
        __mkdir "${__url_dir}"
        if [ -z "$(ls -A "${__url_dir}")" ]; then
            wget --directory-prefix="${__url_dir}" "${__url}"
            pushd "${__url_dir}"
            # I know, it'll only ever be one file, but old habits die hard...
            find ./ | while read -r __file; do
                extract "${__file}"
            done
            
            popd
            
        fi
    done
}

# list_downloaded_subs 'sub name' 'hash'
list_downloaded_subs () {
    local __sub_title="${1}"
    local __sub_hash="${2}"
    local __sub_dir="${__download_dir_subs}/${__sub_title}"
    local __url_dir="${__sub_dir}/${__sub_hash}"
    find "${__url_dir}" | grep -E '\.(aqt|cvd|dks|jss|mpl|txt|pjs|rt|smi|srt|ssa|ass|sub|idx|svcd|usf|psb|ttxt)$'   
}

# list_hashes 'sub name'
list_hashes () {
    local __sub_title="${1}"
    local __sub_dir="${__download_dir_subs}/${__sub_title}"
    find "${__sub_dir}/" -maxdepth 1 -type d | sed "s#${__sub_dir}/##" | sort | uniq | sed '/^$/d'
}

# download_videos 'crunchy-name'
download_videos () {
    local __video_title="${1}"
    local __video_dir="${__download_dir_videos}/${__video_title}"
    __mkdir "${__video_dir}"
    pushd "${__video_dir}"
    youtube-dl 'http://www.crunchyroll.com/'"${__video_title}" -u "${crunchy_email}" -p "${crunchy_password}" --all-subs --embed-subs --download-archive downloaded.txt --no-post-overwrites
    popd
}

# list_all_downloaded_subs 'sub name'
list_all_downloaded_subs () {
    local __sub_title="${1}"
    list_hashes "${__sub_title}" | while read -r __hash; do
        list_downloaded_subs "${__sub_title}" "${__hash}"
    done
}

__download_dir='downloads'
__download_dir_subs="${__download_dir}/sub"
__download_dir_videos="${__download_dir}/video"

__mkdir "${__download_dir}"

__show_file='shows.csv'
__site_file='subs.html'

curl 'http://kitsunekko.net/dirlist.php?dir=subtitles%2F' > "${__site_file}"

awk-csv-parser -o '\n' "${__show_file}" | sed '/^$/d' | while mapfile -t -n 2 ary && ((${#ary[@]})); do
    crunchy_title="${ary[0]}"
    sub_title="${ary[1]}"
    echo "Crunchy Title: ${crunchy_title}"
    echo "Sub Title: ${sub_title}"
    download_subs "${sub_title}"
    download_videos "${crunchy_title}"
    list_all_downloaded_subs "${sub_title}"
done

exit
