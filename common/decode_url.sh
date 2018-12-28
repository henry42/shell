decode_url() {
   printf "$(sed 's/+/ /g;s/%\(..\)/\\x\1/g;' <<< "$@")\n";
}
