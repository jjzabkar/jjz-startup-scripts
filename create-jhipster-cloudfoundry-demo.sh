#! /bin/sh
#
# Creates and deploys a JHipster app to CloudFoundry.
#
# See: https://jhipster.github.io/cloudfoundry.html
#
# yo jhipster:cloudfoundry
APP_NAME=''
function installCloudFoundryDependencies(){ 
	brew tap pivotal/tap;
	brew install cloudfoundry-cli;
	which cf || (echo "cf required" && exit 1 );
}

# would like to use; not sure how.  ./.yo-rc.json
YEOMAN_CONFIG='{
    "node": true,
    "esnext": true,
    "bitwise": true,
    "camelcase": true,
    "curly": true,
    "eqeqeq": true,
    "immed": true,
    "indent": 4,
    "latedef": true,
    "newcap": true,
    "noarg": true,
    "quotmark": "single",
    "regexp": true,
    "undef": true,
    "unused": true,
    "strict": true,
    "trailing": true,
    "smarttabs": true,
    "white": true,
    "predef": ["angular"]
}';


function createJHipsterApp(){
	#https://jkutner.github.io/2015/05/25/jhipster-heroku-git.html
	which yo || (echo "yeoman required" && exit 1 );
	#create jhipster app (prompts)
	yo jhipster || exit 1 ;
	#initialize git repo
	git init;
	#update gitignore
	echo "*~" >> .gitignore ; #jedit
	echo "#*#" >> .gitignore ; #jedit
	echo "tmp/" >> .gitignore ;
	# NOWORKY: Induces Heroku timeout errors since it lengthens the build > 60 seconds.
	echo "node_modules/" >> .gitignore;
	#echo "; Specific node_modules required to shorten Heroku build time (avoid 60s timeout)" >> .gitignore;
	#echo "node_modules/bower/" >> .gitignore; # 36 MB; required to shorten build time (avoid 60s timeout)
	#echo "node_modules/generator-jhipster/" >> .gitignore; # 65 MB; required to shorten build time (avoid 60s timeout)
	#echo "node_modules/grunt-browser-sync/" >> .gitignore; # 33 MB; required to shorten build time (avoid 60s timeout)
	#echo "node_modules/grunt-contrib-imagemin/" >> .gitignore; # 50 MB; required to shorten build time (avoid 60s timeout)
	#echo "node_modules/yo/" >> .gitignore; # 21 MB; required to shorten build time (avoid 60s timeout)
	echo "src/main/webapp/bower_components/" >> .gitignore;
	echo "target/" >> .gitignore ;
	git add .gitignore;
	git commit -m "Updated .gitignore with jhipster ignores";
	git add node_modules/;
	git commit -m "Added node_modules/ to reduce build time on destination";
	git add .;
	git commit -m "Created JHipster app";
} # createJHipsterApp ;


function deployToCloudFoundry(){
	# Assume: CF CLI
	which cf || (echo "cloudfoundry required" && exit 1 );
	cf orgs || (echo "error: cloudfoundry login, 'orgs' required" && exit 1);
	if [[ ! -f "./bower.json" || ! -f "./Gruntfile.js" || ! -f "./pom.xml" ]] ; then echo "createJHipsterApp required"; exit 1 ; fi ;
	yo jhipster:cloudfoundry || exit 1 ; # prompts
} # deployToCloudFoundry ; 


function addServiceNewRelic(){
	which jq || (echo "jq required" && exit 1 );
	APP_NAME=`cat .yo-rc.json | jq -r '."generator-jhipster"."baseName"'`;
	SERVICE_NAME="${APP_NAME}-newrelic";
	cf create-service newrelic standard ${SERVICE_NAME};
	cf bind-service ${APP_NAME} ${SERVICE_NAME};
	cf restage ${APP_NAME};	
} # function addServiceNewRelic()


function addEntityFoo(){
	yo jhipster:entity foo; #prompts
	git add .;
	git commit -m "Added entity 'foo'";
	mvn -Pprod package;
	#cf push -f ./deploy/cloudfoundry/manifest.yml -p target/*.war;
	# per: https://jhipster.github.io/cloudfoundry.html
}


installCloudFoundryDependencies ;
createJHipsterApp ;
addEntityFoo ;
deployToCloudFoundry ;
addServiceNewRelic ;

