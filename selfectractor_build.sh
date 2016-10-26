#!/bin/bash

ARCHIVEFILE="${1:-selfextracting_caddy-docker_installer.bsx}"
origin=$(pwd)

mkdir -p build_dir/payload

# echo "add payload"
# cp -r www build_dir/payload/


echo "create manager script"
cd lib/
cat head.sh core.sh services.sh install.sh new.sh plugins.sh startpage.sh setup.sh manager.sh > ../build_dir/payload/manager
VERSION=$(cat ../VERSION)
sed -i -e "s|THISVERSION|\"${VERSION}\"|g" ../build_dir/payload/manager
chmod +x ../build_dir/payload/manager
cd ..

echo "prepare selfextractor"
cd build_dir/
echo "Step 1/2 installer"
cat << EOM > payload/installer
#!/bin/bash
echo "Running Installer"
echo -e "\n"
echo "install in \${CDIR}"
echo -e "\n"
# mkdir -p \${CDIR}/caddy
# mv www \${CDIR}/caddy/
mv manager \${CDIR}/

#mv caddy ${CDIR}/
# cd $CDIR
#./manager setup

EOM
chmod +x payload/installer

echo "Step 2/2 decompress"
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
cd $origin
echo -e "\ncleanup"
set -x
tree -L 2 build_dir/
rm -rf build_dir
set +x
exit 0
