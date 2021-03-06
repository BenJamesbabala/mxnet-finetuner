#!/usr/bin/env bash

# Generate test image record files.
# Settings other than image_size are read from config.yml
#
# Usage:
#   $ util/gen_test.sh <config.yml> <image_size>
#   $ util/gen_test.sh /config/config.yml 224

set -u

CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$CUR_DIR/functions"

CONFIG_FILE="$1"
RESIZE="$2"

python3 -c 'import sys, yaml, json; json.dump(yaml.safe_load(sys.stdin), sys.stdout, indent=2)' < "$CONFIG_FILE" > config.json
config=$(jq -Mc '.' config.json)

TEST="/images/test"
DATA_TEST="/data/test"

NUM_THREAD=$(get_conf "$config"  ".common.num_threads" "4")
QUALITY=$(get_conf "$config"  ".data.quality" "95")
CENTER_CROP=$(get_conf "$config"  ".data.center_crop" "0")

echo "RESIZE=$RESIZE"

if [[ $CENTER_CROP = 1 ]]; then
  CENTER_CROP="True"
else
  CENTER_CROP="False"
fi
echo "CENTER_CROP=$CENTER_CROP"

# Generate test image list from test directory.
python3 -u /mxnet/tools/im2rec.py --list True --recursive True --shuffle False \
                                 "images-test-${RESIZE}" "${TEST}/"

# Check whether test images exist.
TEST_IMAGES_NUM=$(echo "$(cat "images-test-${RESIZE}.lst" | wc -l)")
if [[ "$TEST_IMAGES_NUM" = 0 ]]; then
  echo 'Error: Test images do not exist.' 1>&2
  echo 'Please put test images in images/test direcotory.' 1>&2
  exit 1
fi

# Generate test image record file.
python3 -u /mxnet/tools/im2rec.py --resize "${RESIZE}" --quality "${QUALITY}" --shuffle False \
                                 --num-thread "${NUM_THREAD}" --center-crop "${CENTER_CROP}" \
                                 "images-test-${RESIZE}" "${TEST}/"
mv images-test* "${DATA_TEST}"

# Create labels.txt
find ${TEST}/* -type d | awk -F/ '{print NR-1, $NF}' > ${DATA_TEST}/labels.txt
