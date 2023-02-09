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
  local $csv_field_REMAINDER=''
  csv_field_get '"BJS,,,",10/10,1.00' unsetValues vendorNameRegex csv_field_REMAINDER dateValue amtValue
  assert_true '[[ $unsetValues -eq 0 ]]' 
  assert_true '[[ "$vendorNameRegex" == '"'"'BJS,,,'"'"' ]]'
  assert_true '[[ "${!csv_field_REMAINDER}" == '"'"'10/10,1.00'"'"' ]]'
  assert_true '[[ "$dateValue" == '"'"'10/10'"'"' ]]'
  assert_true '[[ "$amtValue" == '"'"'1.00'"'"' ]]'

  local -i unsetValues=0
  local vendorNameRegex=''
  local dateValue=''
  local amtValue=''
  local $csv_field_REMAINDER=''
  csv_field_get '"BJS,,,",10/10,1.00' unsetValues vendorNameRegex dateValue amtValue csv_field_REMAINDER 
  assert_true '[[ $unsetValues -eq 1 ]]' 
  assert_true '[[ "$vendorNameRegex" == '"'"'BJS,,,'"'"' ]]'
  assert_true '[[ "$dateValue" == '"'"'10/10'"'"' ]]'
  assert_true '[[ "$amtValue" == '"'"'1.00'"'"' ]]'
  assert_true '[[ -z "${!csv_field_REMAINDER}" ]]'

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


test_csv_field__set_empty(){

  assert_true 'csv_field__set_empty'

  local field_1='NotEmpty'
  local field_2='NotEmpty'
  local -i field_3=1
  assert_true 'csv_field__set_empty field_3 field_1 field_2'
  assert_true '[[ -z $field_1 ]]'
  assert_true '[[ -z $field_2 ]]'
  assert_true '[[ "$field_3" == "0" ]]'
}


test_csv_field_get_unset_as_empty(){

  assert_true 'csv_field_get_unset_as_empty'

  local vendorNameRegex='NotEmpty'
  local dateValue='NotEmpty'
  local amtValue='NotEmpty'
  csv_field_get_unset_as_empty '"BJS,,,",10/10,1.00' vendorNameRegex dateValue amtValue
  assert_true '[[ $? ]]'
  assert_true '[[ "$vendorNameRegex" == '"'"'BJS,,,'"'"' ]]'
  assert_true '[[ "$dateValue" == '"'"'10/10'"'"' ]]'
  assert_true '[[ "$amtValue" == '"'"'1.00'"'"' ]]'

  local vendorNameRegex='NotEmpty'
  local $csv_field_REMAINDER='NotEmpty'
  local dateValue='NotEmpty'
  local amtValue='NotEmpty'
  csv_field_get_unset_as_empty '"BJS,,,",10/10' vendorNameRegex csv_field_REMAINDER dateValue amtValue
  assert_true '[[ $? ]]'
  assert_true '[[ "$vendorNameRegex" == '"'"'BJS,,,'"'"' ]]'
  assert_true '[[ "${!csv_field_REMAINDER}" == '"'"'10/10'"'"' ]]'
  assert_true '[[ "$dateValue" == '"'"'10/10'"'"' ]]'
  assert_true '[[ -z "$amtValue" ]]'

  local vendorNameRegex='NotEmpty'
  local $csv_field_REMAINDER='NotEmpty'
  local dateValue='NotEmpty'
  local amtValue='NotEmpty'
  csv_field_get_unset_as_empty '"BJS,,,"' vendorNameRegex csv_field_REMAINDER dateValue amtValue
  assert_true '[[ $? ]]'
  assert_true '[[ "$vendorNameRegex" == '"'"'BJS,,,'"'"' ]]'
  assert_true '[[ -z ${!csv_field_REMAINDER} ]]'
  assert_true '[[ -z $dateValue ]]'
  assert_true '[[ -z $amtValue ]]'
}


test_csv_field_append(){
  local csv
  csv_field_append csv 'hi'
  assert_true '[[ "$csv" == "hi" ]]'

  local csv='oldtail'
  csv_field_append csv 'newtail'
  assert_true '[[ "$csv" == "oldtail,newtail" ]]'

  local csv='oldtail'
  csv_field_append csv 'newmiddle' 'newtail'
  assert_true '[[ "$csv" == "oldtail,newmiddle,newtail" ]]'

  local csv=''
  csv_field_append csv 'h,i'
  local expect='"h,i"'
  assert_true '[[ "$csv" == "$expect" ]]'

  local csv=''
  csv_field_append csv 'h"i'
  local expect='"h""i"'
  assert_true '[[ "$csv" == "$expect" ]]'

  local csv=''
  csv_field_append csv 'h",i'
  local expect='"h"",i"'
  assert_true '[[ "$csv" == "$expect" ]]'

  local csv=''
  csv_field_append csv 'field1' 'field2' 'field3' 
  assert_true '[[ "$csv" == "field1,field2,field3" ]]'

  local csv=''
  local expect='"fie,ld1",field2,"field""3",field4'
  csv_field_append csv 'fie,ld1' 'field2' 'field"3' 'field4' 
  assert_true '[[ "$csv" == "$expect" ]]'

  local csv=''
  assert_true 'csv_field_append csv' 
  assert_true '[[ -z "$csv" ]]'

  assert_false 'csv_field_append 2>/dev/null' 
}


main(){
  compose_executable "$0"

  test_csv_field_get
  test_csv_field__set_empty
  test_csv_field_get_unset_as_empty
  test_csv_field_append

  assert_return_code_set
}

main
