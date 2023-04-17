#!/usr/bin/env bash
#set -x

if [ ! -d "contracts" ]; then
	echo "error: script needs to be run from project root './tools/checkUpgradeable.sh'"
	exit 1
fi

# install slither
which slither-check-upgradeability
if [ $? -ne 0 ]; then
  git clone https://github.com/crytic/slither.git && cd slither || exit 1
  pip3 install .
  cd ..
fi

# copy .env file
if [ ! -f ".env" ]; then
  cp ".env.example" ".env"
fi

# create tmp files
file1=$(mktemp /tmp/crossbell-bridge-slither-check.XXXXX) || exit 2

# slither-check
echo "Web3Entry: " >"$file1"
slither-check-upgradeability . MarketPlace \
--proxy-filename . \
--proxy-name TransparentUpgradeableProxy \
--compile-force-framework 'hardhat' \
--exclude "initialize-target,missing-init-modifier" \
2>>"$file1" 1>&2


# output
lines1=$(sed -n '$=' "$file1")

# if the check fails, there will be 2+ lines in the files
if [ "$lines1" -gt 2 ]
then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "slither-check failed"
  cat "$file1"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 255
else
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "slither-check done"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
fi
