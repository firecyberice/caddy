#!/bin/bash
ARCHIVEFILE=test.bsx

mkdir -p build/payload
cp -r www build/payload/

cd lib/
cat head.sh core.sh services.sh new.sh install.sh setup.sh manager.sh > ../build/payload/manager
chmod +x ../build/payload/manager
cd ..

cd build/
cat << EOM > payload/installer
#!/bin/bash
echo "Running Installer"
echo -e "\n"
echo "install in \${CDIR}"
echo -e "\n"
mkdir -p \${CDIR}/caddy
mv www \${CDIR}/caddy/
mv manager \${CDIR}/

#mv caddy ${CDIR}/
# cd $CDIR
#./manager setup

EOM
chmod +x payload/installer

cat << EOM > decompress
#!/bin/bash
echo ""
echo "Self Extracting Installer"
echo ""

export TMPDIR=\$(mktemp -d /tmp/selfextract.XXXXXX)

ARCHIVE=\$(awk '/^__ARCHIVE_BELOW__/ {print NR + 1; exit 0; }' \$0)

tail -n+\$ARCHIVE \$0 | tar xzv -C \$TMPDIR

export CDIR=\$(pwd)
cd \$TMPDIR
./installer

cd \$CDIR
rm -rf \$TMPDIR

exit 0

__ARCHIVE_BELOW__
EOM
chmod +x decompress

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
# echo -e "\ncleanup"
# set -x
# rm -rf payload/www payload/manager payload.tar.gz
# set +x
exit 0
