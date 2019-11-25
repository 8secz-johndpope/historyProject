BASEDIR=$(dirname "$0")
python "$BASEDIR/translation_cht.py"  > "$BASEDIR/../merchant-ios/Languages/cht.strings"
python "$BASEDIR/translation_chs.py"  > "$BASEDIR/../merchant-ios/Languages/chs.strings"
python "$BASEDIR/translation_en.py"  > "$BASEDIR/../merchant-ios/Languages/en.strings"