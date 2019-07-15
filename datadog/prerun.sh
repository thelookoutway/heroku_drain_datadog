#!/usr/bin/env bash

echo "Tags dyno, dynotype, and appname have been disabled"
sed -i -e 's/^  - dyno:.*$/# &/' "$DATADOG_CONF"
sed -i -e 's/^  - dynotype:.*$/# &/' "$DATADOG_CONF"
sed -i -e 's/^  - appname:.*$/# &/' "$DATADOG_CONF"
