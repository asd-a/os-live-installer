#!/bin/bash

set -e

packages=$(grep -Ev '^[[:space:]]*(#|$)' $1)

echo $packages