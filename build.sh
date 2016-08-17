#!/bin/bash

cp -r www build/payload/

cd lib/
cat head.sh core.sh services.sh new.sh install.sh setup.sh manager.sh > ../build/payload/manager
chmod +x ../build/payload/manager
cd ..

########################################################################

ARCHIVEFILE=test.bsx
cd build/
echo "create selfextract"
cd payload
tar cf ../payload.tar ./*
cd ..

if [ -e "payload.tar" ]; then
    gzip payload.tar

    if [ -e "payload.tar.gz" ]; then
        mkdir -p ../dist
        cat decompress payload.tar.gz > ../dist/$ARCHIVEFILE
        chmod +x ../dist/$ARCHIVEFILE
    else
        echo "payload.tar.gz does not exist"
        exit 1
    fi
else
    echo "payload.tar does not exist"
    exit 1
fi

echo "$ARCHIVEFILE created"
echo -e "\ncleanup"
set -x
rm -rf payload/www payload/manager payload.tar.gz
set +x
exit 0
