#!/bin/bash

cd lib/
cat head.sh core.sh services.sh install.sh new.sh plugins.sh startpage.sh setup.sh manager.sh > ../manager
chmod +x ../manager
cd ..
