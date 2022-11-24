#!/bin/bash +x

echo ""
echo "=========================================================="
JAVA_8_HOME=${JAVA_8_HOME%/}
JAVA_11_HOME=${JAVA_11_HOME%/}
echo "    JAVA 8 Home: $JAVA_8_HOME"
echo "    JAVA 11 Home: $JAVA_11_HOME"

echo "=========================================================="
echo "Building carbon-consent-management"
echo "=========================================================="

git clone https://github.com/ImalshaG/carbon-consent-management.git
cd carbon-consent-management
git checkout 3.0.x

DEPENDENCY_VERSION=$(mvn -q -Dexec.executable=echo -Dexec.args='${project.version}' --non-recursive exec:exec)
echo "Dependency Version: $DEPENDENCY_VERSION"

export JAVA_HOME=$JAVA_8_HOME
mvn clean install -Dmaven.test.skip=true --batch-mode | tee mvn-build.log

echo ""
echo "Dependency repo $REPO build complete."
echo "Built version: $DEPENDENCY_VERSION"
echo "=========================================================="
echo ""

REPO_BUILD_STATUS=$(cat mvn-build.log | grep "\[INFO\] BUILD" | grep -oE '[^ ]+$')

REPO_FINAL_RESULT=$(
  echo "==========================================================="
  echo "$REPO BUILD $REPO_BUILD_STATUS"
  echo "=========================================================="
  echo ""
  echo "Built version: $DEPENDENCY_VERSION"
  )

REPO_BUILD_RESULT_LOG_TEMP=$(echo "$REPO_FINAL_RESULT" | sed 's/$/%0A/')
REPO_BUILD_RESULT_LOG=$(echo $REPO_BUILD_RESULT_LOG_TEMP)
echo "::warning::$REPO_BUILD_RESULT_LOG"

if [ "$REPO_BUILD_STATUS" != "SUCCESS" ]; then
  echo "$REPO BUILD not successfull. Aborting."
  echo "::error::$REPO BUILD not successfull. Check artifacts for logs."
  exit 1
fi

cd ..

  echo "=========================================================="
  echo "Cloning product-ipk"
  echo "=========================================================="

  git clone https://github.com/ImalshaG/identity-k8s-access-runtime.git
  cd identity-k8s-access-runtime

  echo "Updating dependency versions in product-ipk..."
  echo "=========================================================="
  echo ""

  sed -i "s/<carbon.consent.mgt.version>2.5.0</carbon.consent.mgt.version>/<carbon.consent.mgt.version>3.0.0-SNAPSHOT</carbon.consent.mgt.version>/" pom.xml

  export JAVA_HOME=$JAVA_11_HOME
  cat pom.xml
  mvn clean install -Dmaven.test.skip=true --batch-mode | tee mvn-build.log

  PR_BUILD_STATUS=$(cat mvn-build.log | grep "\[INFO\] BUILD" | grep -oE '[^ ]+$')
#  PR_TEST_RESULT=$(sed -n -e '/\[INFO\] Results:/,/\[INFO\] Tests run:/ p' mvn-build.log)

  PR_BUILD_FINAL_RESULT=$(
    echo "==========================================================="
    echo "product-ipk BUILD $PR_BUILD_STATUS"
    echo "=========================================================="
    echo ""
#    echo "$PR_TEST_RESULT"
  )

  PR_BUILD_RESULT_LOG_TEMP=$(echo "$PR_BUILD_FINAL_RESULT" | sed 's/$/%0A/')
  PR_BUILD_RESULT_LOG=$(echo $PR_BUILD_RESULT_LOG_TEMP)
  echo "::warning::$PR_BUILD_RESULT_LOG"

  PR_BUILD_SUCCESS_COUNT=$(grep -o -i "\[INFO\] BUILD SUCCESS" mvn-build.log | wc -l)
  if [ "$PR_BUILD_SUCCESS_COUNT" != "1" ]; then
    echo "PR BUILD not successfull. Aborting."
    echo "::error::PR BUILD not successfull. Check artifacts for logs."
    exit 1
  fi
fi

echo ""
echo "=========================================================="
echo "Build completed"
echo "=========================================================="
echo ""
