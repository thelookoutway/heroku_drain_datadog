#!/usr/bin/env bash

echo "[Datadog Prerun] Tags dyno, dynotype, and appname have been disabled"
sed -i -e 's/^  - dyno:.*$/# &/' "$DATADOG_CONF"
sed -i -e 's/^  - dynotype:.*$/# &/' "$DATADOG_CONF"
sed -i -e 's/^  - appname:.*$/# &/' "$DATADOG_CONF"
