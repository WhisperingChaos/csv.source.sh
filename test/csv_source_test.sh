#!/bin/bash
compose_executable(){
  local -r callFromDir="$( dirname "$1" )"

  local -r callSourcer="$callFromDir"'/config_sh/vendor/sourcer/sourcer.sh'
  local -r myRoot="$callFromDir"'/csv_source_test_sh'
  local mod
  for mod in $( "$callSourcer" "$myRoot"); do
    source "$mod"
  done
}


test_csv_field_get(){

  local -i unsetValues=0
  local vendorNameRegex=''
  local dateValue=''
  local amtValue=''
  csv_field_get 'BJS Gas*' unsetValues vendorNameRegex dateValue
  assert_true '[[ $unsetValues -eq 1 ]]' 
  assert_true '[[ "$vendorNameRegex" == '"'"'BJS Gas*'"'"' ]]'
  assert_true '[[ -z "$datevalue" ]]'
  assert_true '[[ -z "$amtValue" ]]'

  local -i unsetValues=0
  local vendorNameRegex=''
  local dateValue='NullifyAfterCall'
  local amtValue='ShouldBeThisValueAfterCall'
  csv_field_get 'BJS Gas*,,' unsetValues vendorNameRegex vendorNameHelp amtValue
  assert_true '[[ $unsetValues -eq 1 ]]' 
  assert_true '[[ "$vendorNameRegex" == '"'"'BJS Gas*'"'"' ]]'
  assert_true '[[ -z "$datevalue" ]]'
  assert_true '[[ "$amtValue" == '"'"'ShouldBeThisValueAfterCall'"'"' ]]'

  local -i unsetValues=0
  local vendorNameRegex=''
  local dateValue=''
  local amtValue=''
  csv_field_get 'BJS Gas*,10/10,125.00' unsetValues vendorNameRegex dateValue amtValue
  assert_true '[[ $unsetValues -eq 0 ]]' 
  assert_true '[[ "$vendorNameRegex" == '"'"'BJS Gas*'"'"' ]]'
  assert_true '[[ "$dateValue" == '"'"'10/10'"'"' ]]'
  assert_true '[[ "$amtValue" == '"'"'125.00'"'"' ]]'

  local -i unsetValues=0
  local vendorNameRegex=''
  local dateValue=''
  local amtValue=''
  csv_field_get '"BJS Gas*",10/10,"125.00"' unsetValues vendorNameRegex dateValue
  assert_true '[[ $unsetValues -eq 0 ]]' 
  assert_true '[[ "$vendorNameRegex" == '"'"'BJS Gas*'"'"' ]]'
  assert_true '[[ "$dateValue" == '"'"'10/10'"'"' ]]'
  assert_true '[[ -z "$amtValue" ]]'

  local -i unsetValues=0
  local vendorNameRegex=''
  local dateValue=''
  local amtValue=''
  csv_field_get '"BJS ""Gas*",10/10,"125.00"' unsetValues vendorNameRegex dateValue amtValue
  assert_true '[[ $unsetValues -eq 0 ]]' 
  assert_true '[[ "$vendorNameRegex" == '"'"'BJS "Gas*'"'"' ]]'
  assert_true '[[ "$dateValue" == '"'"'10/10'"'"' ]]'
  assert_true '[[ "$amtValue" == '"'"'125.00'"'"' ]]'


  local -i unsetValues=0
  local vendorNameRegex=''
  local dateValue=''
  local amtValue=''
  csv_field_get 'BJS ((((++)(*&^%$##@[])))),10/10,1.00' unsetValues vendorNameRegex dateValue amtValue
  assert_true '[[ $unsetValues -eq 0 ]]' 
  assert_true '[[ "$vendorNameRegex" == '"'"'BJS ((((++)(*&^%$##@[]))))'"'"' ]]'
  assert_true '[[ "$dateValue" == '"'"'10/10'"'"' ]]'
  assert_true '[[ "$amtValue" == '"'"'1.00'"'"' ]]'

  local -i unsetValues=0
  local vendorNameRegex=''
  local dateValue=''
  local amtValue=''
  csv_field_get '"BJS,,,",10/10,1.00' unsetValues vendorNameRegex dateValue amtValue
  assert_true '[[ $unsetValues -eq 0 ]]' 
  assert_true '[[ "$vendorNameRegex" == '"'"'BJS,,,'"'"' ]]'
  assert_true '[[ "$dateValue" == '"'"'10/10'"'"' ]]'
  assert_true '[[ "$amtValue" == '"'"'1.00'"'"' ]]'

  local -i unsetValues=0
  local vendorNameRegex=''
  local dateValue=''
  local amtValue=''
  eval local $csv_field_REMAINDER\=\'\'
  csv_field_get '"BJS,,,",10/10,1.00' unsetValues vendorNameRegex $csv_field_REMAINDER dateValue amtValue
  assert_true '[[ $unsetValues -eq 0 ]]' 
  assert_true '[[ "$vendorNameRegex" == '"'"'BJS,,,'"'"' ]]'
  eval local remainder=\"\$$csv_field_REMAINDER\"
  assert_true '[[ "$remainder" == '"'"'10/10,1.00'"'"' ]]'
  assert_true '[[ "$dateValue" == '"'"'10/10'"'"' ]]'
  assert_true '[[ "$amtValue" == '"'"'1.00'"'"' ]]'

  local -i unsetValues=0
  local vendorNameRegex=''
  local dateValue=''
  local amtValue=''
  eval local $csv_field_REMAINDER\=\'\'
  csv_field_get '"BJS,,,",10/10,1.00' unsetValues vendorNameRegex dateValue amtValue $csv_field_REMAINDER 
  assert_true '[[ $unsetValues -eq 1 ]]' 
  assert_true '[[ "$vendorNameRegex" == '"'"'BJS,,,'"'"' ]]'
  assert_true '[[ "$dateValue" == '"'"'10/10'"'"' ]]'
  assert_true '[[ "$amtValue" == '"'"'1.00'"'"' ]]'
  eval local remainder=\"\$$csv_field_REMAINDER\"
  assert_true '[[ -z "$remainder" ]]'

  local -i unsetValues=0
  local vendorNameRegex=''
  assert_output_true \
    test_csv_field_get_fail_regex \
    --- \
    csv_field_get "\"," unsetValues vendorNameRegex

  local -i unsetValues=0
  local vendorNameRegex=''
  assert_false 'csv_field_get "\"" unsetValues vendorNameRegex 2>/dev/null'

  local -i unsetValues=0
  local vendorNameRegex=''
  assert_true 'csv_field_get "" unsetValues vendorNameRegex 2>/dev/null'
}
test_csv_field_get_fail_regex(){
cat <<'error'
msgType='Error' msg='CSV row fails to match trim regex. row='\''",'  csv_field_TRIM_REGEX='^((([^,"]+)([,]|$))|(["](([^"]|(""))*)["])([,]|$)|([,]))''
error
}


main(){
  compose_executable "$0"

  test_csv_field_get

  assert_return_code_set
}

main
