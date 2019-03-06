#!/bin/bash

# SOURCE: https://www.shellscript.sh/tips/banner/

banner()
{
  echo "+------------------------------------------+"
  printf "| %-40s |\n" "`date`"
  echo "|                                          |"
  printf "|`tput bold` %-40s `tput sgr0`|\n" "$@"
  echo "+------------------------------------------+"
}

# Example usage
# banner "Starting the Job"
# sleep 3

# banner "Copying files"
# cp -v /etc/hosts /tmp
# cp -v /etc/passwd /tmp
# sleep 4

# banner "Downloading article"
# curl https://www.shellscript.sh/tips/banner/ > /tmp/banner.html
# sleep 5

# banner "Finished."
