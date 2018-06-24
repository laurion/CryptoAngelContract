#!/usr/bin/env bash
echo "Starting network...."
testrpc &
echo "Compiling project..."
truffle compile
echo "Migrating oracle...."
truffle migrate
echo "Starting oracle....."
node oracle.js &
echo "Running first client...."
node client.js &
echo "Running second client..."
node client.js &
