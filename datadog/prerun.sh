#!/usr/bin/env bash

echo "The dyno and dynotype tags have been disabled"
sed -i -e 's/^  - dyno:.*$/# &/' "$DATADOG_CONF"
sed -i -e 's/^  - dynotype:.*$/# &/' "$DATADOG_CONF"
