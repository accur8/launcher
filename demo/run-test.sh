#!/bin/bash


echo hello stdout

sleep 1
echo hello stderr 1>&2

sleep 1
echo hello stdout

sleep 1
echo hello stderr 1>&2

