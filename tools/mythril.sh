#!/usr/bin/env bash
#set -x

if [ ! -d "contracts" ]; then
	echo "error: script needs to be run from project root './tools/mythril.sh'"
	exit 1
fi

echo '
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "MarketPlace: "
myth analyze contracts/MarketPlace.sol --solc-json mythril.config.json --solv 0.8.16 --max-depth 10 --execution-timeout 900  --solver-timeout 900 &&
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" ' |
docker run --rm -v "$PWD":/project -i --workdir=/project --entrypoint=sh mythril/myth