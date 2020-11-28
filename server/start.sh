#!/bin/bash

BINARY=godot_headless
PACK=moonshot.pck
SERVERNAME=server$1

cp base/$BINARY $SERVERNAME/
cp base/$PACK $SERVERNAME/
cd $SERVERNAME
screen -dmS $SERVERNAME ./$BINARY --main-pack $PACK
