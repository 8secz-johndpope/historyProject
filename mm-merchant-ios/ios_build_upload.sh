WORKSPACE="merchant-ios.xcworkspace"
PROJECT_FILE="merchant-ios.xcodeproj/project.pbxproj"
PLIST_FILE="merchant-ios/Info-storefront.plist"
SCHEME="storefront-ios"
TIMESTAMP=`date +%Y-%m-%d:%H:%M:%S`
EXPORT_IPA_NAME="storefront-ios.ipa"

dir=`pwd`
if [ "$1" == "prod" ]; then
	ipa_name="mm.prod.ipa"
    team="WLS4TQMLYZ"
    bundle_identifier="com.mm.storefront"
    url_schemes="ds6df3ae2e6b3a0c30"
    flag="-DMM_PLATFORM_PROD";
    export_plist="ExportPlist-Prod.plist"
elif [ "$1" == "mobile" ]; then
    ipa_name="mm.mobile.ipa"
    team="WLS4TQMLYZ"
    bundle_identifier="com.mm.storefront"
    url_schemes="ds6df3ae2e6b3a0c30"
    flag="-DMM_PLATFORM_MOBILE";
    export_plist="ExportPlist-Prod.plist"
    bundle_display_name="美美(Mobile)"
elif [ "$1" == "lw" ]; then
	ipa_name="mm.uat-lw.ipa"
	team="EZJ536ER6V"
	bundle_identifier="com.mm.enterprise.storefront"
	url_schemes="dsfb7101bfdcc2c4d7"
	flag="-DMM_PLATFORM_UAT_LW";
	export_plist="ExportPlist-Enterprise.plist"
	bundle_display_name="美美(LW)"
elif [ "$1" == "mint" ]; then
	ipa_name="mm.mint.ipa"
	team="EZJ536ER6V"
	bundle_identifier="com.mm.enterprise.storefront"
	url_schemes="dsfb7101bfdcc2c4d7"
	flag="-DMM_PLATFORM_MINT";
	export_plist="ExportPlist-Enterprise.plist"
	bundle_display_name="美美(MINT)"
elif [ "$1" == "demo" ]; then
	ipa_name="mm.demo.ipa"
	team="EZJ536ER6V"
	bundle_identifier="com.mm.enterprise.storefront"
	url_schemes="dsfb7101bfdcc2c4d7"
	flag="-DMM_PLATFORM_DEMO";
	export_plist="ExportPlist-Enterprise.plist"
	bundle_display_name="美美(DEMO)"
elif [ "$1" == "test" ]; then
	ipa_name="mm.test.ipa"
	team="EZJ536ER6V"
	bundle_identifier="com.mm.enterprise.storefront"
	url_schemes="dsfb7101bfdcc2c4d7"
	flag="-DMM_PLATFORM_TEST";
	export_plist="ExportPlist-Enterprise.plist"
	bundle_display_name="美美(TEST)"
else
	echo "Server either [prod | mint | lw | demo| mobile | test]"
	exit
fi

# == NEED UPDATE == #

project_root="/Users/Ay/Documents/mm-merchant-ios"
build_path="/Users/Ay/Documents/iOS Archive/$team.$flag.$TIMESTAMP"
archive_path="$build_path/storefront-ios.xcarchive"
export_path="$build_path"
ssl_cert_path="/Users/tech/Documents/MayMayTech.pem"
#branch="release/Buffalo-RC-1.0.2"
branch="develop"
build_commit=""
git_reset=1

# == END == # 

echo "ipa_name : $ipa_name"
echo "team : $team"
echo "bundle_identifier : $bundle_identifier"
echo "url_schemes : $url_schemes"
echo "flag : $flag"
echo "export_plist : $export_plist"
echo "archive_path : $archive_path"
echo "export_path : $export_path"

cd "$project_root"

# Switch the source code to specific revision we need
if [ "$build_commit" != "" ]; then 
	git reset -q --hard "$build_commit"
elif [ "$git_reset" == "1" ]; then 
	git reset -q --hard HEAD
	git checkout "$branch"
	git fetch origin
	git pull --log origin "$branch"
fi

# Modify project settings for builds
sed -i '' -E "s/DevelopmentTeam = [^;]*;/DevelopmentTeam = $team;/g" "$PROJECT_FILE"
sed -i '' -E "s/DEVELOPMENT_TEAM = [^;]*;/DEVELOPMENT_TEAM = $team;/g" "$PROJECT_FILE"
sed -i '' -E "s/-DMM_PLATFORM_PROD/$flag/g" "$PROJECT_FILE"
sed -i '' -E "s/PRODUCT_BUNDLE_IDENTIFIER = [^;]*;/PRODUCT_BUNDLE_IDENTIFIER = $bundle_identifier;/g" "$PROJECT_FILE"
sed -i '' -E "s/ds6df3ae2e6b3a0c30/$url_schemes/g" "$PLIST_FILE"

if [ "$bundle_display_name" != "" ]; then 
	sed -i '' -E "s/<string>美美<\/string>/<string>$bundle_display_name<\/string>/g" "$PLIST_FILE"
fi

# Build
xcodebuild -workspace "$WORKSPACE" -scheme "$SCHEME" archive -archivePath "$archive_path"
xcodebuild -exportArchive -exportOptionsPlist "$export_plist" -archivePath "$archive_path" -exportPath "$export_path"

# Upload
scp -i "$ssl_cert_path" "$export_path/$EXPORT_IPA_NAME" "ubuntu@mobile-mm.eastasia.cloudapp.azure.com:/home/ubuntu/ota-server/public/ios/$ipa_name"
