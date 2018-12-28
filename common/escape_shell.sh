escape_shell() {
   echo "$@" | sed -e 's/"/"\\""/g' -e 's/`/\\`/g' -e 's/.*/"&"/'
}
