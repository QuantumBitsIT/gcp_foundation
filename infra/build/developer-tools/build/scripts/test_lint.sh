#! /bin/bash
# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -u

# Import helper functions from Docker container
# shellcheck disable=SC1091
source /usr/local/bin/task_helper_functions.sh

# All tests should execute regardless of failures so we can report at the end.
# Perform 'set +e' after sourcing task_helper_functions.sh in case someone has
# 'set -e' inside a module-specific task_helper_functions.sh file.
set +e

# constants
# Store working dir as module-swapper needs to be executed in this dir.
CWD="${PWD}"
rval=0
failed_tests=()
tests=(
  check_generate_modules
  check_documentation
  check_whitespace
  check_shell
  check_headers
  check_python
  check_tflint
  check_terraform
  check_metadata
)

if [[ -z "${DISABLE_MODULE_SWAPPER:-}" ]]; then
  module-swapper
fi

function restore {
  cd "${CWD}"
  module-swapper -restore >/dev/null 2>&1
  exit 1
}
trap restore INT

for test in "${tests[@]}"; do
  if ! "${test}"; then
    failed_tests+=("${test}")
    ((rval++))
  fi
done
module-swapper -restore >/dev/null 2>&1

if [[ "${#failed_tests[@]}" -ne 0 ]]; then
  # shellcheck disable=SC2145  # Output all elements of the array
  echo "Error: The following tests have failed: ${failed_tests[@]}"
  exit "${rval}"
fi
