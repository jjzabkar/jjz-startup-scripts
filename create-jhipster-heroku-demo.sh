#! /bin/sh
#
# Creates and deploys a JHipster app to Heroku.
#
# See: https://jkutner.github.io/2015/05/25/jhipster-heroku-git.html
#
HEROKU_APP_NAME=''

function installJHipsterDependencies(){ 
	#https://jhipster.github.io/installation.html
	#Assume Java
	which java || (echo "java required" && exit 1 );
	#Assume maven
	which mvn || (echo "mvn required" && exit 1 );
	#Assume Git
	which git || (echo "git required" && exit 1 );
	#Assume Brew
	which brew || (echo "brew required" && exit 1 );
	#NodeJS
	brew install npm;
	brew upgrade npm;
		#Yeoman
		npm install -g yo;
		#Bower
		npm install -g bower;
		#Grunt
		npm install -g grunt-cli
		#Gulp
		npm install -g gulp
		#JHipster
		npm install -g generator-jhipster
	#Spring boot:
	brew tap pivotal/tap;
	brew install springboot;
	brew upgrade springboot;
};	


function createJHipsterApp(){
	#https://jkutner.github.io/2015/05/25/jhipster-heroku-git.html
	#pushd ~/Documents/git/jhipster-heroku-demo
	which yo || (echo "yeoman required" && exit 1 );
	#initialize git repo
	#git init;
	#create jhipster app (prompts)
	yo jhipster || exit 1 ;
	#update gitignore
	echo "*~" >> .gitignore ; #jedit
	echo "#*#" >> .gitignore ; #jedit
	echo "tmp/" >> .gitignore ; 
	echo "node_modules/" >> .gitignore;
	echo "src/main/webapp/bower_components/" >> .gitignore;
	echo "target/" >> .gitignore ; 
	git add .gitignore;
	git commit -m "Updated .gitignore with jhipster ignores";
	git add .;
	git commit -m "Created JHipster app";
} # createJHipsterApp ;


function prepareForHeroku(){
	# Assume: Heroku Toolbelt
	which heroku || (echo "heroku toolbelt required" && exit 1 );
	# Make sure the right heroku-accounts is installed
	heroku plugins:install https://github.com/heroku/heroku-accounts.git
	# Assume: Heroku Account
	heroku accounts || (echo "heroku account required" && exit 1 );
	if [[ ! -f "./bower.json" || ! -f "./Gruntfile.js" || ! -f "./pom.xml" ]] ; then echo "createJHipsterApp required"; exit 1 ; fi ;
	yo jhipster:heroku || exit 1 ; #prompts
	#git add .;
	#git commit -m "Prepared for Heroku"
	# heroku apps:destroy --app jhipsterherokudemojjz --confirm jhipsterherokudemojjz

	#remote:        https://sheltered-journey-3212.herokuapp.com/ deployed to Heroku
	#remote: 
	#-----> Done
	#
	#Your app should now be live. To view it run
	#	heroku open
	#And you can view the logs with this command
	#	heroku logs --tail
	#After application modification, repackage it with
	#	mvn package -Pprod -DskipTests
	#And then re-deploy it with
	#	mvn package -Pprod -DskipTests=true && heroku deploy:jar --jar target/*.war
	
	git add .;
	git commit -m "Prepared for Heroku";
	#To see app name:
	git remote -v;
	HEROKU_APP_NAME=`git remote -v | grep heroku | cut -f 2 | sed -e 's/\.git.*//g' | sed -e 's/.*\.com.//g'`
}


XML_PROFILE='<profiles>
<profile>
<id>heroku</id>
  <build>
    <plugins>
      <plugin>
      <artifactId>maven-clean-plugin</artifactId>
      <version>2.5</version>
      <executions>
        <execution>
          <id>clean-build-artifacts</id>
          <phase>install</phase>
          <goals><goal>clean</goal></goals>
          <configuration>
            <excludeDefaultDirectories>true</excludeDefaultDirectories>
            <filesets>
              <fileset>
                <directory>node_modules</directory>
              </fileset>
              <fileset>
                <directory>.heroku/node</directory>
              </fileset>
              <fileset>
                <directory>target</directory>
                <excludes>
                  <exclude>*.war</exclude>
                </excludes>
              </fileset>
            </filesets>
          </configuration>
        </execution>
      </executions>
      </plugin>
    </plugins>
  </build>
</profile>';
function updatePomXml(){
	TMP_FILE=./pom.xml~;
	while read LINE
	do
		if [ "${LINE}" == "<profiles>" ] ; then 
			echo "${XML_PROFILE}" >> $TMP_FILE;
		else
			echo "$LINE" >> $TMP_FILE;
		fi
	done <"./pom.xml"	
	rm ./pom.xml && mv $TMP_FILE ./pom.xml ;
}


function deployWithGit(){
	# Check that your Git repo has the Heroku remote
	git remote | grep heroku || (echo "git heroku remote required" && exit 1 );
	if [ "${HEROKU_APP_NAME}" == "" ] ; then echo "HEROKU_APP_NAME required"; exit 1 ; fi ;
	# Add JHipster build packs
	# TODO: add " --app ${HEROKU_APP_NAME} "?
	heroku buildpacks:add https://github.com/heroku/heroku-buildpack-nodejs.git
	heroku buildpacks:add https://github.com/heroku/heroku-buildpack-java.git
	# define the Maven options such that the correct profiles a
	heroku config:set MAVEN_CUSTOM_OPTS="-Pprod,heroku -DskipTests"
	# prepare the NPM configuration so that Heroku can use Bower and Grunt
	npm install bower grunt-cli --save
	# Since we saw this error in the UI
	npm install iconv --save
	
	updatePomXml ; # possible: XML CLI? brew install xmlstarlet
	
	git add package.json pom.xml;
	git commit -m "Update for Heroku Git"
	git push heroku master;
	heroku open
} # end deployWithGit()


installJHipsterDependencies ;
createJHipsterApp ;
prepareForHeroku ;
deployWithGit ;





