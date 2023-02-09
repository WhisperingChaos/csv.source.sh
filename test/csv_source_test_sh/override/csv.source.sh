###############################################################################
##
##  Purpose
##    Override error reporting with a more verbose messaging mechanism.
##  In
##    $1 - error message text.
##  Out
##    ERROUT - streamed error message text
###############################################################################
csv_field__error(){
  msg_error "$@"
}
