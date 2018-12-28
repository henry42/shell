is_root(){
  if [ $EUID -ne 0 ]; then
      return 1
  fi
}
