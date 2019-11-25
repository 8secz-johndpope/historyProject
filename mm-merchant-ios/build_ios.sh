#!/bin/bash

JENKINS_WORKSPACE="$WORKSPACE"
WORKSPACE="merchant-ios.xcworkspace"
PROJECT_FILE="merchant-ios.xcodeproj/project.pbxproj"
PLIST_FILE="merchant-ios/Info-storefront.plist"
SCHEME="storefront-ios"

XcodeVersion="9.0"
PLATFORM="prod"
PARENT_ARCHIVE_DIR=""
#修改打包版本号
SET_VERSION_NUMBER=0

until [ $# -eq 0 ]
do
	if [ $1 == "-platform" ]; then
		PLATFORM=$2
		shift
	elif  [ $1 == "-xcode-version" ]; then
		XcodeVersion=$2
		shift
	elif  [ $1 == "-archive" ]; then
		PARENT_ARCHIVE_DIR=$2
		shift
	elif [ $1 == "-setvnumber" ]; then
        SET_VERSION_NUMBER=$2
        shift
    else
        echo "invalid parameter！exit!\n"
        echo "=========================================================="
        echo "=  You can exec the script like that:                    ="
        echo "=  #sh build_ios.sh -archive out_path -platform prod     ="
        echo "=                       -setvnumber 1231                 ="
        echo "=========================================================="
        exit
    fi
	shift
done
echo "platform $PLATFORM"


TIMESTAMP=`date +%Y-%m-%d:%H:%M:%S`
EXPORT_IPA_NAME="storefront-ios.ipa"

#定义修改plist的脚本
function modify_info_plist() {

	until [ $# -eq 0 ] 
	do 
		case $1 in
	   		-k) key_string=$2 
				echo "need change item key is $key_string"
				shift 
	   			;; # 
	   		-f) info_file=$2 
				echo "plist info path at $info_file"
				shift 
	   			;; # 
	   		-s) replace_string=$2
				echo "need change item value to $replace_string"
				shift 
	   			;; # 
		esac
		shift 
	done 

	if [ ! -f  "$info_file" ]; then 
		echo "info plist 文件未找到"
        exit 1
    fi

    key_item="<key>$key_string<\/key>"
	key_row=`sed -n -e "/$key_item/=" $info_file`
	value_row=$[key_row + 1]
	old_value=`sed -n "$value_row p" $info_file`
	new_value="<string>$replace_string</string>"
	sed -i "" "s#$old_value#$new_value#g" "$info_file"
	echo "modify $key_string value from $old_value to $new_value"
}


# git commit count
CURRENT_DIR_PATH="$(dirname $0)"
CURRENT_DIR_PATH="${CURRENT_DIR_PATH/\./$(pwd)}"
GIT_COMMIT_COUNT=`git rev-list HEAD | wc -l | sed -e 's/ *//g' | xargs -n1 printf %d`
echo "--> git commit ${GIT_COMMIT_COUNT}"
if [ $SET_VERSION_NUMBER > 0 ]; then
	GIT_COMMIT_COUNT=$SET_VERSION_NUMBER
fi
echo "--> set version number ${GIT_COMMIT_COUNT}"


# modify build version
# <key>CFBundleVersion</key>
# <string>1141</string>
APP_VERSION_NUM_KEY="<key>CFBundleVersion<"
APP_VERSION_NUM_KEY_NUM=`sed -n -e "/$APP_VERSION_NUM_KEY/=" $PLIST_FILE`
APP_VERSION_NUM_KEY_NUM=$[APP_VERSION_NUM_KEY_NUM + 1]
echo $APP_VERSION_NUM_KEY_NUM
BUILD_VERSION=`sed -n "${APP_VERSION_NUM_KEY_NUM}p" $PLIST_FILE`
BUILD_VERSION="${BUILD_VERSION#*>}"
BUILD_VERSION="${BUILD_VERSION%<*}"

# get build version
#<key>CFBundleShortVersionString</key>
#<string>5.0.1</string>
APP_VERSION_KEY="<key>CFBundleShortVersionString<"
APP_VERSION_KEY_NUM=`sed -n -e "/${APP_VERSION_KEY}/=" $PLIST_FILE`
APP_VERSION_KEY_NUM=$[APP_VERSION_KEY_NUM + 1]
echo $APP_VERSION_KEY_NUM
APP_VERSION=`sed -n "${APP_VERSION_KEY_NUM}p" $PLIST_FILE`
APP_VERSION="${APP_VERSION#*>}"
APP_VERSION="${APP_VERSION%<*}"
echo "build $APP_VERSION($BUILD_VERSION) ipa"


# 仅仅在 发布release 包的时候做 build自增的逻辑
# if [[ "$PLATFORM" == "release" ]]; then

# 	echo "========================git environment!========================"
# 	git branch
# 	git status
# 	echo "================================================================"

# 	# if [ $SET_VERSION_NUMBER > 0 ]; then
# 	# 	# 自增build
# 	# 	BUILD_VERSION=$[BUILD_VERSION + 1]
# 	# fi

# 	echo "==========================git command!=========================="
# 	temp_branch=`git rev-parse HEAD`
# 	git checkout master
# 	git merge "$temp_branch"
# 	git status -sb
# 	git merge --abort
# 	git status -sb
# 	currnet_head=`git rev-parse HEAD`
# 	if [[ "$temp_branch" != "$currnet_head" ]]; then
# 		echo "终止打包，无法正常merge到master，请确保发布分支为最新节点"
# 		echo "================================================================"
# 		exit -1
# 	fi
# 	git push origin master
# 	git checkout "$temp_branch"
# 	echo "================================================================"
# fi

# 标记本次打包的git节点号
CURRENT_COMMIT_ID=`git rev-parse HEAD`
modify_info_plist -k "GIT_HEAD_COMMIT_ID" -f "$PLIST_FILE" -s "${CURRENT_COMMIT_ID}"
if [[ "$PLATFORM" == "release" ]]; then
	modify_info_plist -k "SHOW_GIT_COMMIT_ID" -f "$PLIST_FILE" -s "HIDE"
else
	modify_info_plist -k "SHOW_GIT_COMMIT_ID" -f "$PLIST_FILE" -s "SHOW"
fi

#取时间、版本区分目录
DATE_FORMAT=$(date '+%Y-%m-%d')-$(date '+%H%M%S')

# ./archives/app_version/date_format/
ARCHIVE_DIR="$CURRENT_DIR_PATH/archives/$APP_VERSION/$DATE_FORMAT"
if [ ! -d "$ARCHIVE_DIR" ]; then
    mkdir -pv "$ARCHIVE_DIR"
fi
echo "build out dir:$ARCHIVE_DIR"

#who
id -un

select_xcode()
{
	if [ "$XcodeVersion"  == "8.2.1" ]; then
		sudo xcode-select -s /Applications/Xcode\ 8.2.1.app/Contents/Developer 
	else
		sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
	fi
}

#release,prod,prod-hk,dev,mobile,uat-ws,mint,demo,test,next,load,enterprise.prod,diagnostics
#analytics,verify,twg,twg_dev
if [ "$PLATFORM" == "release" ]; then
	ipa_name="mm.release.ipa"
    team="U252KK9378"
    bundle_identifier="com.mm.storefront"
    url_schemes="ds6df3ae2e6b3a0c30"
    flag="-DMM_PLATFORM_PROD";
    export_plist="ExportPlist-AppStore.plist"
    thinning_plist="ExportPlist-Thinning.plist"
elif [ "$PLATFORM" == "prod" ]; then
	ipa_name="mm.prod.ipa"
	team="EZJ536ER6V"
	bundle_identifier="com.mm.enterprise.storefront"
	url_schemes="dsfb7101bfdcc2c4d7"
	flag="-DMM_PLATFORM_PROD";
	export_plist="ExportPlist-Enterprise.plist"
	bundle_display_name="美美(Prod)"
    thinning_plist="ExportPlist-Enterprise-Thinning.plist"
# 需要转成企业包，release作为发布包存在    
# elif [ "$PLATFORM" == "prod" ]; then
# 	ipa_name="mm.prod.ipa"
#     team="U252KK9378"
#     bundle_identifier="com.mm.storefront"
#     url_schemes="ds6df3ae2e6b3a0c30"
#     flag="-DMM_PLATFORM_PROD";
#     export_plist="ExportPlist-Prod.plist"
#     thinning_plist="ExportPlist-Thinning.plist"
# elif [ "$PLATFORM" == "prod-hk" ]; then
# 	ipa_name="mm.prod-hk.ipa"
#     team="U252KK9378"
#     bundle_identifier="com.mm.storefront"
#     url_schemes="ds6df3ae2e6b3a0c30"
#     flag="-DMM_PLATFORM_HK_PROD";
#     export_plist="ExportPlist-Prod.plist"
#     thinning_plist="ExportPlist-Thinning.plist"
elif [ "$PLATFORM" == "mobile" ]; then
    ipa_name="mm.mobile.ipa"
    team="U252KK9378"
    bundle_identifier="com.mm.storefront"
    url_schemes="ds6df3ae2e6b3a0c30"
    flag="-DMM_PLATFORM_MOBILE";
    export_plist="ExportPlist-Prod.plist"
    thinning_plist="ExportPlist-Thinning.plist"
    bundle_display_name="美美(Mobile)"
elif [ "$PLATFORM" == "mint" ]; then
	ipa_name="mm.mint.ipa"
	team="EZJ536ER6V"
	bundle_identifier="com.mm.enterprise.storefront"
	url_schemes="dsfb7101bfdcc2c4d7"
	flag="-DMM_PLATFORM_MINT";
	export_plist="ExportPlist-Enterprise.plist"
	bundle_display_name="美美(MINT)"
    thinning_plist="ExportPlist-Enterprise-Thinning.plist"
elif [ "$PLATFORM" == "test" ]; then
	ipa_name="mm.test.ipa"
    team="U252KK9378"
    bundle_identifier="com.mm.storefront"
    url_schemes="ds6df3ae2e6b3a0c30"
	flag="-DMM_PLATFORM_TEST";
    export_plist="ExportPlist-Prod.plist"
	bundle_display_name="美美(TEST) $BUILD_NUMBER"
    thinning_plist="ExportPlist-Thinning.plist"
elif [ "$PLATFORM" == "next" ]; then
	ipa_name="mm.next.ipa"
	team="EZJ536ER6V"
	bundle_identifier="com.mm.enterprise.storefront"
	url_schemes="dsfb7101bfdcc2c4d7"
	flag="-DMM_PLATFORM_NEXT";
	export_plist="ExportPlist-Enterprise.plist"
	bundle_display_name="美美(Next)"
    thinning_plist="ExportPlist-Enterprise-Thinning.plist"
else
	echo "Server either [release | prod | mint | next | mobile | test]"
	exit
fi

echo ""
echo " === Build Info === "
echo "Branch : $Branch"
echo "PLATFORM : $PLATFORM"
echo "team : $team"
echo "bundle_identifier : $bundle_identifier"
echo "url_schemes : $url_schemes"
echo "flag : $flag"
echo "export_plist : $export_plist"
echo "bundle_display_name : $bundle_display_name"
echo "Upload : $Upload"
echo " === END ==="
echo ""


build_path="$ARCHIVE_DIR"
archive_path="$build_path/storefront-ios.xcarchive"
export_path="$build_path"



#ssl_cert_path="/Users/mj/Documents/devMymmMob.pem"

pwd

# Modify project settings for builds
sed -i '' -E "s/DevelopmentTeam = [^;]*;/DevelopmentTeam = $team;/g" "$PROJECT_FILE"
sed -i '' -E "s/DEVELOPMENT_TEAM = [^;]*;/DEVELOPMENT_TEAM = $team;/g" "$PROJECT_FILE"
sed -i '' -E "s/-DMM_PLATFORM_PROD/$flag/g" "$PROJECT_FILE"
sed -i '' -E "s/PRODUCT_BUNDLE_IDENTIFIER = [^;]*;/PRODUCT_BUNDLE_IDENTIFIER = $bundle_identifier;/g" "$PROJECT_FILE"
sed -i '' -E "s/ds6df3ae2e6b3a0c30/$url_schemes/g" "$PLIST_FILE"

# Modify code for TuTu the filter and beauty library
if [ "$bundle_identifier" == "com.mm.enterprise.storefront" ]; then
	sed -i '' -E "s/\"master\":\".*\"/\"master\":\"O3dwbUQ9t+7CI\/DDBhBPu\/Nd11\/S91BkZhkbcZpGlYYTM\/jg8R4vnZfRv2vFIDVI1nZ9YRU3nZZY+pxvAnkRv4j6fKHOsR3zOfSxC8CcL\/+z\/vjJooDAV0llY3XgI1kKK\/FdmMeJxidlohoTIqi+rnAONjh1DgpklENlJ9EC7L1q3s+DLhU8E\/xIYiFX7Z4yKvRrxSpeZmt\/z1KEyDkjnx3jxmLc2d\/vWkCIhuxEZJZUJ2oDhzQsSjQfGBV6do\/ScPrJCe9LbJXLjheu7QJaPfje9Cbhn8a5xgAXoPqA6v78fBWNV5a9DPfPSSY0woQpkUMD+feAjEuRdOQEM3B\/HAG\/hlxVuvJw6Q9u62nDVazPGq5KOgNE2euj5eY+OZp3u2SSuRDGge6El9vBhF2GOJoFT4OsEtzRnWWrEt+fw8QloNy2EPS09LifdOMW7RLVIXo4OhYnZey5A+fMJkdFKIZFQSn6dtFtoXaeivKi8vQJ\/CeMrDJaGQvfOt4q+dwOugJcv5Wzlej8fMutjkmxAgLJ4sSIQzjlUb4DKbWTnOaJOZJ\/XlmfAnJ2\/fOG6Q0l4DwBseI8RDcg6VCbVN\/sGeIw\/0b\/YqXKCUyO7wwiVTQ97Q9K3REV0V9mclnzx2oAkHZYK+8rN+jO+Cm73EHEd3X4dgX\/hM7mClSN2mX0BPxQ6wcJETbdmRGfE8HrVJz0P5yurUbhU+d5cdGmiVnILRzXnpA93ja9esUR\/oaLI3qRMNtatdq5rJZmSyNfsuLRVKnw9GbRUozK+MIhEvsTUuJSxSGeu8yDau1k2jalc1H2ycYBSfIJgq3UbFA68K+kqBRI1w\/uslXqyftu4u\/WIaTEAjbWrg6RKRuCAGPah8An\/pZdxeEsf\/gaJVv2S8+8HDmTRNXJPNCqHJrtKaCG5n0dJM4NGw7dDCq6hJhalY1Ne8ZB2edCDVyxQADUrFwMyatwEYt9XQnSTE+bDmjcRoXc0UdHiWlxMMXe\/cVfiY54YVJo4kOuagoIWehs+4uE2xmzdbJ9sw3LPFRifxMVLKu1sx0SvotaG5oKyvwfSYASolwBnJaP3CzyKyvauXzLTks1PEzQyGrUaUAgSwq\/oleFDjEICjs1K0QCcm3jWnbT99D7VhtVCeNTAfW5r8jnpekH\/UXzvFzX9DhbQ1Z\/jioDueLvDa5MZP5Bi4WFuLKfny3yxU4J6M2zzpJCPXWl4bW4t4OvkE7uGTfcIIFd9WZUdW3oSKmvVbIiBcDxChj7pEmsZjqktaX7p9WYd1qTUDVW8SzyQqYJa9GliMYD4CcsCLWECtm7uac16pt6d73TyqgEEdQ7JfcGchKHinQNUc9ZETxxBmXVztTYwELwzHjfWFyyiPz3uTppEGBT5ROrMpx3Q\/\/i6S7eqOqPsmNnm2G\/6nqWQy+1ymrS0epZ+Fk4FuvWDT6l3NFkybPHVJAqryOXddYtCOfOJ+vt3G7A0CDB39BC52\"/g" "merchant-ios/Assets/TuSDK.bundle/others/lsq_tusdk_configs.json"
fi

# Modify code for analytics build
if [ "$PLATFORM" == "analytics" ]; then
	sed -i '' -E "s/self.analyticsRecords.count >= 100/self.analyticsRecords.count >= 1/g" "merchant-ios/Classes/Manager/AnalyticsManager.swift"
    sed -i '' -E "s/\.gzippedDataWithCompressionLevel\(0\.3\)//g" "merchant-ios/Classes/Service/AnalyticsService.swift"
fi

# Modify code for TWG build
if [ "$PLATFORM" == "twg" ]; then
    sed -i '' -E "s/NSBundle\.mainBundle\(\)\.localizedStringForKey\(key, value: nil, table: Context.getCc\(\)\.lowercaseString\)/NSBundle\.mainBundle\(\)\.localizedStringForKey\(key, value: nil, table: \"en\"\.lowercaseString\)/g" "merchant-ios/Classes/Extension/StringExtension.swift"
fi

if [ "$bundle_display_name" != "" ]; then 
	sed -i '' -E "s/<string>美美<\/string>/<string>$bundle_display_name<\/string>/g" "$PLIST_FILE"
fi

select_xcode;

# Build
echo "xcodebuild -workspace $WORKSPACE -scheme $SCHEME archive -archivePath $archive_path"
xcodebuild -workspace "$WORKSPACE" -scheme "$SCHEME" archive -archivePath "$archive_path"

# to ipa CODE_SIGN_IDENTITY="iPhone Distribution: WWE  Group Limited" PROVISIONING_PROFILE="bd8c8cd9-ac79-4d12-9abf-0f6a21f8c8e4"
echo "xcodebuild -exportArchive -allowProvisioningUpdates -allowProvisioningDeviceRegistration -exportOptionsPlist $export_plist -archivePath $archive_path -exportPath $export_path"
xcodebuild -exportArchive -allowProvisioningUpdates -allowProvisioningDeviceRegistration -exportOptionsPlist "$export_plist" -archivePath "$archive_path" -exportPath "$export_path"

# 拷贝到archive目录
#cp -v "$export_path/$EXPORT_IPA_NAME" "$ARCHIVE_DIR/mm.$PLATFORM.ipa"

# 提交到app store
if [[ "$PLATFORM" == "release" ]]; then
	echo "/Applications/Xcode.app/Contents/Applications/Application Loader.app/Contents/Frameworks/ITunesSoftwareService.framework/Support/altool --upload-app -f '$export_path/$EXPORT_IPA_NAME' -t ios -u mymm.apple@gmail.com -p"
	/Applications/Xcode.app/Contents/Applications/Application\ Loader.app/Contents/Frameworks/ITunesSoftwareService.framework/Support/altool --upload-app -f "$export_path/$EXPORT_IPA_NAME" -t ios -u apple@mymm.com -p MyMM@ois26A

	# echo "============================打标签==============================="
	# git checkout master
	# git tag -d "${APP_VERSION}"
	# git push origin ":refs/tags/${APP_VERSION}" 
	# git tag 
	# git tag "${APP_VERSION}"
	# git push origin "${APP_VERSION}"
	# #运程已经存在tag
	# git checkout "$temp_branch"
	# echo "================================================================"

fi


if [ "$PARENT_ARCHIVE_DIR" != "" ]; then
	cp -v "$export_path/$EXPORT_IPA_NAME" "$PARENT_ARCHIVE_DIR/mm.$PLATFORM.ipa"
fi

