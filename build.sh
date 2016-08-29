#!/bin/bash

mkdir dist
cd lib/
cat head.sh core.sh services.sh install.sh new.sh plugins.sh startpage.sh setup.sh manager.sh > ../dist/manager
chmod +x ../dist/manager
cd ..
