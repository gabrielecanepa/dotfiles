# Usage: $command & spinner [$speed]
#        sleep 2 & spinner 0.2
spinner() {
  while kill -0 $! 2>/dev/null
    do for c in / - \\ \|
      do printf "\r$c"
      sleep ($1 || 0.1)
    done
  done
}
