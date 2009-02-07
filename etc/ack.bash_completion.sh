# vim: et ft=sh ts=2 sts=2 sw=2
# By Adam James: atj@pulsewidth.org.uk

_ack()
{
  local cur prev long_options short_options type_options
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  long_options="--all --after-context= --before-context= --content= --count \
  --color --nocolor --env --noenv --follow --nofollow --group --nogroup \
  --with-filename --no-filename --help --ignore-case --ignore-dir= \
  --noignore-dir= --line= --files-with-matches --match --max-count= \
  --man --output= --pager= --passthru --literal --rc= --sort-files \
  --thpppt --unrestricted --invert-match --version --word-regexp"
  short_options="-a -A -B -C -c -f -G -g -H -h -i -l -m= -n -o -Q -u -w -1"
  if type ack &>/dev/null; then
    type_options=$(ack --help=types 2>/dev/null |perl -ne \
      'print "--$1\n--no-$1\n" if /^\s+--\[no\](\S+)\s+/')
  fi

  if [[ "${cur}" == *=* ]]; then
    prev=${cur/=*/}
    cur=${cur/*=/}
    case "${prev}" in
      --ignore-dir) _filedir -d
                    return 0
                    ;;
      --rc)         _filedir
                    return 0
                    ;;
    esac
  elif [[ "${cur}"  == -* ]]; then
    COMPREPLY=( $(compgen -W \
      "${type_options} ${long_options} ${short_options}" -- "${cur}") )
  elif [[ "${prev}" != -* || " ${COMP_WORDS[@]} " == *" -f "* ]]; then
    _filedir
  fi

  return 0
}

complete -F _ack ack
