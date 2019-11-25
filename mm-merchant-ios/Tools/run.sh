BASEDIR=$(dirname "$0")
python "$BASEDIR/route_class.py" > "$BASEDIR/../merchant-ios/Classes/Constant/RouterURL.swift"