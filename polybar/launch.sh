for m in $(polybar --list-monitors | cut -d":" -f1); do
  echo "Montior is $m"
  MONITOR=$m polybar --reload main &
done
