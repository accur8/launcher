#!/bin/bash


echo hello stdout
echo hello stderr 1>&2

sleep 1

echo hello stdout
echo hello stderr 1>&2

