# vim: et ft=sh sts=2 sw=2 ts=2
#
# Copyright 2008-2009 Adam James <atj@pulsewidth.org.uk>
# All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as ack itself.

# ack-grep on Debian distros
type ack &>/dev/null || type ack-grep &>/dev/null && {

shopt -s extglob

__ack_filedir()
{
  local IFS=$'\n\t' flag="-f" tmp

  [[ $1 == "-d" ]] && flag="-d"

  COMPREPLY=( $(compgen ${flag} -- "${cur}" | {
    while read -r tmp; do
      if [[ -d ${tmp} ]]; then
        echo "${tmp// /\\ }/"
      else
        echo "${tmp// /\\ }"
      fi
    done
  } ) )
}

_ack()
{
  COMPREPLY=()
  # --help, --man, --thpppt and --version are final 
  # so we return here if they are present
  [[ "${COMP_WORDS[@]}" == \
    *+([[:space:]])--@(help|man|th+(p)t|version)+([[:space:]])* ]] && return 0

  local cur lngopt shtopt fnlopt typeopt
  cur="${COMP_WORDS[COMP_CWORD]}"

  lngopt='
    --all-types --after-context= --before-context= --context= 
    --count --color --nocolor --env --noenv --flush
    --follow --nofollow --group --nogroup --with-filename
    --no-filename --ignore-case --ignore-dir=
    --noignore-dir= --line= --files-with-matches
    --files-without-matches --match --max-count=
    --output= --pager= --nopager --passthru --print0
    --literal --smart-case --nosmart-case --rc=
    --sort-files --type --type-add --type-set
    --unrestricted --invert-match --word-regexp
    --heading --noheading --break --nobreak --sort-files
  '
  shtopt='
    -a -A -B -C -c
    -f -G -g -H -h
    -i -l -L -m -n
    -o -Q -u -w -1
  '
  fnlopt='--help --man --thpppt --version'

  # try ack-grep first as Debian distributions contain a completely
  # different program called ack.
  typeopt=$(ack-grep --help=types 2>/dev/null || \
            ack --help=types 2>/dev/null |perl -ne \
    'print "--$1 --no$1 " if /^\s+--\[no\](\S+)\s+/' 2>/dev/null)

  case "${cur}" in
    # option with argument
    -*=*)
            # split the option and the argument
            opt=${cur%%=*}
            cur=${cur#*=}

            # special cases
            case "${opt}" in
              --?(no)ignore-dir)  # directory matching
                        #COMPREPLY=( $(compgen -d -- "${cur}") )
                        __ack_filedir -d
                        return 0;;
              --rc)     # file matching
                        #COMPREPLY=( $(compgen -f -- "${cur}") )
                        __ack_filedir
                        return 0;;
              --pager)  # command matching
                        COMPREPLY=( $(compgen -c -- "${cur}") )
                        return 0;;
              *)
                        return 0;;
            esac;;
    # option without argument
    -*)
            [[ "${COMP_CWORD}" == 1 ]] && lngopt="${lngopt} ${fnlopt}"

            COMPREPLY=( $(compgen -W \
              "${lngopt} ${shtopt} ${typeopt}" -- "${cur}") )
            return 0;;
    *)
            [[ "${COMP_WORDS[COMP_CWORD-1]}" != -* || \
               " ${COMP_WORDS[@]} " == *" -f "* ]] && \
              __ack_filedir
              return 0;;
  esac
}
complete -F _ack ack
complete -F _ack ack-grep
}
