# vim: et ft=sh sts=2 sw=2 ts=2
#
# Copyright 2008-2009 Adam James <atj@pulsewidth.org.uk>
# All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as ack itself.
#
# This file requires functions from the bash-completion package, which is
# available at http://bash-completion.alioth.debian.org
#
#
# Thanks to John Purnell for pointing out some missed options.

# ack-grep on Debian distros
have ack || have ack-grep && {

# please accept my apologies for polluting the environment!
__ack_types=$(ack-grep --help=types 2>/dev/null || ack --help=types 2>/dev/null | \
  perl -ne 'print "$1 no$1 " if /^\s+--\[no\](\S+)\s+/' 2>/dev/null)

__ack_typeopts=""

for type in $__ack_types ; do
  __ack_typeopts="${__ack_typeopts} --${type}"
done

_ack() {
  local lngopt shtopt clropt
  local cur prev

  COMPREPLY=()
  cur=$(_get_cword "=")
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  _expand || return 0

  # these options are final
  if [[ ${COMP_WORDS[@]} == *+([[:space:]])--@(help|man|th+([pt])+(t)|version)+([[:space:]])* ]] ; then
    return 0
  fi

  lngopt='
    --after-context=
    --all-types
    --before-context=
    --break
    --nobreak
    --color
    --nocolor
    --colour
    --nocolour
    --color-filename=
    --color-match=
    --column
    --context=
    --count
    --env
    --noenv
    --files-with-matches
    --files-without-matches
    --flush
    --follow
    --nofollow
    --group
    --nogroup
    --heading
    --noheading
    --ignore-case
    --ignore-dir=
    --noignore-dir=
    --invert-match
    --line=
    --literal
    --match
    --max-count=
    --no-filename
    --output=
    --pager=
    --nopager
    --passthru
    --print0
    --recurse
    --norecurse
    --rc=
    --smart-case
    --nosmart-case
    --sort-files
    --type=
    --type-add
    --type-set
    --unrestricted
    --with-filename
    --word-regexp
  '
  fnlopt='
    --help
    --man
    --thpppt
    --version
  '
  shtopt='
    -a -A -B -C -c
    -f -G -g -H -h
    -i -l -L -m -n
    -o -Q -r -R -u
    -v -w -1
  '
  clropt='
    clear
    reset
    dark
    bold
    underline
    underscore
    blink
    reverse
    concealed
    black
    red
    green
    yellow
    blue
    magenta
    on_black
    on_red
    on_green
    on_yellow
    on_blue
    on_magenta
    on_cyan
    on_white
  '

  # these options require an argument
  if [[ "${prev}" == -@(A|B|C|G|g|-match) ]] ; then
    return 0
  fi

  case "${cur}" in
    --?*=*)
          _split_longopt || return 0

          case "${prev}" in
            --?(no)ignore-dir) # directory completion
                      _filedir -d
                      return 0;;
            --pager) # command completion
                      COMPREPLY=( $(compgen -c -- "${cur}") )
                      return 0;;
                      --rc) # file completion
                      _filedir
                      return 0;;
            --color-@(filename|match)) # color completion
                      COMPREPLY=( $(compgen -W "${clropt}" -- "${cur}") )
                      return 0;;
            --type) # type completion
                      COMPREPLY=( $(compgen -W "${__ack_types}" -- "${cur}") )
                      return 0;;
          esac;;
    -*)
          # -a and -u negate the use of type options
          if [[ " ${COMP_WORDS[@]} " == *" -a "* || " ${COMP_WORDS[@]} " == *" -u "* ]] ; then
            if [[ "${COMP_CWORD}" -eq 1 ]] ; then
              COMPREPLY=( $(compgen -W \
                "${lngopt} ${shtopt} ${fnlopt}" -- "${cur}") )
            else
              COMPREPLY=( $(compgen -W \
                "${lngopt} ${shtopt}" -- "${cur}") )
            fi
          else
            if [[ "${COMP_CWORD}" -eq 1 ]] ; then
              COMPREPLY=( $(compgen -W \
                "${lngopt} ${shtopt} ${fnlopt} ${__ack_typeopts}" -- "${cur}") )
            else
              COMPREPLY=( $(compgen -W \
                "${lngopt} ${shtopt} ${__ack_typeopts}" -- "${cur}") )
            fi
          fi
          return 0;;
    *)
          if [[ " ${COMP_WORDS[@]} " == *" -f "* ]] ; then
            _filedir -d
          elif [[ "${prev}" != -* ]] ; then
            _filedir
          fi
          return 0;;
  esac
}
complete -F _ack ${nospace} ack
complete -F _ack ${nospace} ack-grep
}
