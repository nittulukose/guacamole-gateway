#!/bin/bash
set -e

service dbus start
xrdp-sesman
exec xrdp --nodaemon
