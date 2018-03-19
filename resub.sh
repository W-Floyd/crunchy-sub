#!/bin/bash

if [ -e ./crunchyroll ]; then
    source ./crunchyroll
fi

until [ "${#}" = '0' ]; do
    export "${1}"
    shift
done

while read -r __program; do
    if ! which "${__program}" &> /dev/null; then
        echo "'${__program}' not installed."
        exit
    fi
done <<< 'awk-csv-parser'

__pushd () {
    pushd "${1}" &> /dev/null
}

__popd () {
    popd &> /dev/null
}

# modified from https://github.com/xvoland/Extract
extract () {
 if [ -z "${1}" ]; then
    # display usage if no parameters given
    echo "Usage: extract <path/file_name>.<zip|rar|bz2|gz|tar|tbz2|tgz|Z|7z|xz|ex|tar.bz2|tar.gz|tar.xz>"
    echo "       extract <path/file_name_1.ext> [path/file_name_2.ext] [path/file_name_3.ext]"
 else
    until [ "${#}" = '0' ]; do
      if [ -e "${n}" ] ; then
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
    shift
    done
fi
}

__mkdir () {
if ! [ -d "${1}" ]; then
    mkdir -p "${1}"
fi
}

# list_subs 'Sub Name'
list_subs () {
    local __sub_title="${1}"
    local __url="$(grep "<strong>${__sub_title}</strong>" < "${__site_file}" | sed -e 's#.*<a href="#http://kitsunekko.net#' -e 's/" class=.*//')"
    wget "${__url}" -qO - | grep '<tr><td>' | sed -e 's#.*<a href="#http://kitsunekko.net/#' -e 's/" class=.*//'
}

# download_subs 'Sub Name'
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
            __pushd "${__url_dir}"
            # I know, it'll only ever be one file, but old habits die hard...
            find ./ | while read -r __file; do
                extract "${__file}"
            done
            
            __popd
            
        fi
    done
}

# list_downloaded_subs 'Sub Name' 'hash'
list_downloaded_subs () {
    local __sub_title="${1}"
    local __sub_hash="${2}"
    local __sub_dir="${__download_dir_subs}/${__sub_title}"
    local __url_dir="${__sub_dir}/${__sub_hash}"
    find "${__url_dir}" | grep -E '\.(aqt|cvd|dks|jss|mpl|txt|pjs|rt|smi|srt|ssa|ass|sub|idx|svcd|usf|psb|ttxt)$'   
}

# list_hashes 'Sub Name'
list_hashes () {
    local __sub_title="${1}"
    local __sub_dir="${__download_dir_subs}/${__sub_title}"
    find "${__sub_dir}/" -maxdepth 1 -type d | sed "s#${__sub_dir}/##" | sort | uniq | sed '/^$/d'
}

# download_episodes 'crunchy-url-name'
download_episodes () {
    local __video_title="${1}"
    local __video_dir="${__download_dir_videos}/${__video_title}"
    __mkdir "${__video_dir}"
    __pushd "${__video_dir}"
    if ! [ -e '.downloaded' ]; then
        if [ -z "${crunchy_email}" ] || [ -z "${crunchy_password}" ]; then
            youtube-dl 'http://www.crunchyroll.com/'"${__video_title}" --all-subs --embed-subs --download-archive .downloaded.txt --no-post-overwrites
        else
            youtube-dl 'http://www.crunchyroll.com/'"${__video_title}" -u "${crunchy_email}" -p "${crunchy_password}" --all-subs --embed-subs --download-archive .downloaded.txt --no-post-overwrites
        fi
        find . | grep -E '\.mp4' | while read -r __file; do
            ffmpeg -nostdin -i "${__file}" \
            -vcodec copy \
            -acodec copy \
            -map 0 /tmp/output.mkv
            mv /tmp/output.mkv "$(sed 's/\.mp4$//' <<< "${__file}").mkv"
            rm "${__file}"
        done
        touch '.downloaded'
    fi
    __popd
}

# list_all_subs 'Sub Name'
list_all_subs () {
    local __sub_title="${1}"
    list_hashes "${__sub_title}" | while read -r __hash; do
        list_downloaded_subs "${__sub_title}" "${__hash}" | sort -V
    done
}

# list_all_episodes 'crunchy-url-name'
list_all_episodes () {
    local __video_title="${1}"
    local __video_dir="${__download_dir_videos}/${__video_title}"
    find "${__video_dir}" | grep -E '\.mkv$' | sort -V
}

# assign_subs 'crunchy-url-name' 'Sub Name'
assign_subs () {
    local __video_title="${1}"
    local __video_dir="${__download_dir_videos}/${__video_title}"
    local __processed_file="${__video_dir}/.subbed"
    touch "${__processed_file}"
    local __sub_title="${2}"
    local __sub_dir="${__download_dir_subs}/${__sub_title}"

    local n=0

    while read -r __video_file; do

        ((n++))

        if grep -Fx "${__video_file}" < "${__processed_file}" &> /dev/null; then
            continue
        fi

        local __sub_list="$(list_all_subs "${__sub_title}")"

        local __matching_sub_list="$(

        # All possible matching patterns to find sub files.
        grep " 0*${n} " <<< "${__sub_list}"
        grep " 0*${n}\.0 " <<< "${__sub_list}"
        grep -E "(E|e)(P|p)0*${n}_" <<< "${__sub_list}"

        )"

        table=()

        while read -r __matching_sub; do

            table+=(TRUE "${__matching_sub}")

        done <<< "${__matching_sub_list}"

        __subs=()

        while read -r __sub_file; do
            __subs+=('--language' '0:eng' "${__sub_file}" )
        done < <(
            if ! ( [ "${zenity}" = 'false' ] || [ "${zenity}" = 'no' ] || [ "${zenity}" = '0' ] ); then
                zenity --list --checklist \
                --text="${__video_file}" \
                --column="Select"  \
                --column="File"  \
                "${table[@]}" 2>/dev/null | sed 's/|/\n/'
            else
                echo "${__matching_sub_list}"
            fi
        )

        echo "Adding subs to '$(basename "${__video_file}")'"
        mkvmerge -o /tmp/output.mkv "${__video_file}" "${__subs[@]}" &> /dev/null
        mv /tmp/output.mkv "${__video_file}"

        echo "${__video_file}" >> "${__processed_file}"

    done <<< "$(list_all_episodes "${__video_title}")"

}

__download_dir='downloads'
__download_dir_subs="${__download_dir}/sub"
__download_dir_videos="${__download_dir}/video"

__mkdir "${__download_dir}"

__show_file='shows.csv'
__site_file='subs.html'

echo 'Downloading Sub Page'
wget 'http://kitsunekko.net/dirlist.php?dir=subtitles%2F' -qO - > "${__site_file}"

awk-csv-parser -o '\n' "${__show_file}" | sed '/^$/d' | while mapfile -t -n 2 ary && ((${#ary[@]})); do
    crunchy_url_name="${ary[0]}"
    sub_title="${ary[1]}"
    echo "Crunchy Title: ${crunchy_url_name}"
    echo "Sub Title: ${sub_title}"
    download_subs "${sub_title}"
    download_episodes "${crunchy_url_name}"
    assign_subs "${crunchy_url_name}" "${sub_title}"
done

exit
