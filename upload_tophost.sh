set -xu

_dstftp="ftp.ervisa-micukaj.com"
_user="ervisa-micukaj.com"

if [ ! -z "$STATIC_DIR" ] ; then
  _staticdir="$STATIC_DIR"
else
  _staticdir="$(dirname $0)/public/"
fi


lftp -c "set ftp:list-options -a;
set ssl:verify-certificate no;
open 'ftp://${_user}@${_dstftp}';
lcd ${_staticdir}/;
mirror --reverse \
       --delete \
       --verbose \
       --ignore-time \
       --exclude-glob a-dir-to-exclude/ \
       --exclude-glob a-file-to-exclude \
       --exclude-glob a-file-group-to-exclude* \
       --exclude-glob other-files-to-exclude"

