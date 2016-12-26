#!/bin/bash

VERSION=$(cat VERSION)
origin=$(pwd)

ARCHIVEFILE="${1:-crpd_${VERSION}.bsx}"

TEMP_DIR=$(mktemp -d /tmp/crpdcompile.XXXXXX)
mkdir -p "${TEMP_DIR}/payload"

echo "create manager script"
cd lib/ || exit
cat head.sh core.sh services.sh templates.sh setup.sh manager.sh > "${TEMP_DIR}/payload/manager"
sed -i -e "s|THISVERSION|\"${VERSION}\"|g" "${TEMP_DIR}/payload/manager"
chmod +x "${TEMP_DIR}/payload/manager"

echo "prepare selfextractor"
cd "${TEMP_DIR}" || exit
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

cd payload || exit
tar cf ../payload.tar ./*
cd ..

if [ -e "payload.tar" ]; then
    gzip payload.tar

    if [ -e "payload.tar.gz" ]; then
        mkdir -p "${origin}/dist"
        cat decompress payload.tar.gz > "${origin}/dist/${ARCHIVEFILE}"
        chmod +x "${origin}/dist/${ARCHIVEFILE}"
        cp payload/manager "${origin}/dist/"
    else
        echo "payload.tar.gz does not exist"
        exit 1
    fi
else
    echo "payload.tar does not exist"
    exit 1
fi

echo "${ARCHIVEFILE} created"
cd "${origin}" || exit
echo -e "\ncleanup"
set -x
tree -L 2 "${TEMP_DIR}"
rm -rf "${TEMP_DIR}"
set +x
exit 0
