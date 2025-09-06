#!/bin/bash
#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

start-master.sh -p 7077
start-worker.sh spark://spark-iceberg:7077

start-history-server.sh
start-thriftserver.sh  --driver-java-options "-Dderby.system.home=/tmp/derby"

echo "Starting Spark Connect Server..."
$SPARK_HOME/sbin/start-connect-server.sh \
  --packages org.apache.spark:spark-connect_2.12:3.5.6 \
  --conf spark.connect.grpc.binding.port=15002 \
  --conf spark.master=spark://spark-iceberg:7077 &

sleep 5

# Set up directories for Marimo
export HOME=${HOME:-/home/iceberg}
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}
export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
export MARIMO_ROOT=${MARIMO_ROOT:-/home/iceberg/notebooks}
export MARIMO_LOG=${MARIMO_LOG:-/opt/spark/logs/marimo.out}

# Create necessary directories
mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$MARIMO_ROOT"
mkdir -p "$(dirname "$MARIMO_LOG")"

# Change to MARIMO_ROOT directory
cd "$MARIMO_ROOT"

echo "Starting Marimo on 0.0.0.0:8888 with root=$MARIMO_ROOT (log: $MARIMO_LOG)"

# Entrypoint, for example notebook, pyspark or spark-sql
if [[ $# -gt 0 ]] ; then
    if [[ "$1" == "marimo-notebook" ]]; then
        # Custom marimo startup with proper logging and directory setup
        marimo edit "$MARIMO_ROOT" --host 0.0.0.0 --port 8888 --headless > "$MARIMO_LOG" 2>&1 &
        wait
    else
        eval "$1"
    fi
fi
