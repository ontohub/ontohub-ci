# Ontohub Continuous Integration
This Dockerfile sets up an instance of Jenkins with all dependencies for Ontohub testing.
Jenkins itself must be configured manually, though, via its web interface.

The Jenkins configuration is stored in a Docker volume that mounts to `/data` inside the container.
Also, `jenkins`'s home directory `/home/jenkins` is a Docker volume. This results in persisted data, even if the Docker container is restarted.

# Installation
For the installation, we assume, this git repository is located at `/home/ontohub/ontohub-ci`. To install, simply run
```bash
docker build -t ontohub-ci /home/ontohub/ontohub-ci
```
*NOTE: There are problems with the permissions on the data directory. See Seciton [Caveats](#caveats).*

# Starting Jenkins
```bash
DATA_DIR=/home/ontohub/ontohub-ci-data
docker run -d -P -v $DATA_DIR:/data ontohub-ci
```
The jenkins Port 8080 inside the container will be mapped to another port of the host.
To see which port is used, run `docker ps`. Let's assume, the port is `49153`.
Then you can get to the web interface by opening `http://hostname:49153` and start [configuring jenkins](#configuring-jenkins).


# Caveats
Because of the Docker volume `/data`, there is a problem with user permissions:
Quite at the end of the Dockerfile, we run the command
```
sudo chown -R jenkins:jenkins /data
```
which has no effect before starting the instance for the first time. That's why the permissions on the mounted data directory `/home/ontohub/ontohub-ci-data` are wrong. As a workaround one can do the following:
  1. Remove all the commands in the Dockerfile after the `sudo chown -R jenkins:jenkins /data`
  2. Build the container with the command from the section [Installation](#installation)
  3. Run the container with the command from the section [Starting Jenkins](#starting-jenkins)
  4. Put the last three commands back into the Dockerfile
  5. Repeat steps 2 and 3.

Now, the container should be setup and running with the correct permissions.

# Configuring Jenkins
## Installing Plugins
  1. In the jenkins web interface, go to "Manage Jenkins" / "Manage Plugins" / "Available"
    * If there are no plugins available, go to "Manage Jenkins" / "Manage Plugins" / "Advanced" and click on "Check now" in the lower right corner to get a new plugin list.
  2. Install the following plugins
    * **AnsiColor** colorizes the console output.
    * **Github Authentication plugin** allows for OAuth via GitHub.
    * **GitHub plugin** adds general GitHub integration.
    * **GitHub pull request builder plugin** adds support for GitHub webooks, i.e. to build automatically when a pull request is opened or someone pushed into a pull requst.
    * **Notification Plugin** enables comminication with [gitter](https://gitter.im). See gitter integration settings for further instructions. (The Jenkins Notification plugin has a bug, so if you encounter a `IndexOutOfBoundsException`, make sure you configure the project to send at least one log line. The default is 0.)

## Security
There are two steps required to fully integrate Jenkins with GitHub.
First a GitHub user needs administrator permissions on the repository, and second, this user's information needs to be entered in Jenkins.

For the first part, create a repository admin user `ontohub-ci`.
  1. Login as this user and go to ["Personal Settings" / "Applications" / "Register new application"](https://github.com/settings/applications/new)
  2. Enter information on the application
    * Name: choose one.
    * Homepage URL: http://hostname:49153/
    * Authorization Callback URL: http://hostname:49153/securityRealm/finishLogin
  3. Register application.
  4. Remember the Client ID and the Client Secret.
  5. Go to ["Personal Settings" / "Applications" / "Generate new token"](https://github.com/settings/tokens/new)
    * Choose a name
    * Check *only* "public_repo" and "read:org"
  6. Generate token
  7. Remember the OAuth token. Once you close the page, you will not be able to see it again.

To use GitHub OAuth, go to "Manage Jenkins" / "Configure Global Security"
  1. Check "Enable Security"
  2. Security Realm
    * Access Control: Github Authentication Plugin
  3. Global Github OAuth Settings
    * GitHub Web URI: https://github.com
    * GitHub API URI: https://api.github.com
    * Client ID: The previously created Client ID
    * Client Sectet: The previously created Client Secret
  4. Authorization
    * Github Commiter Authorization Strategy
  5. Github Authorization Settings
    * Enter "Admin User Names"
    * Enter "Participant in Organization"
    * Check "Use Github repository permissions"
    * Check "Grant READ permissions to all Authenticated Users"
    * Check "Grant CREATE Job permissions to all Authenticated Users"
    * Check "Grant READ permissions for /github-webhook"
  6. Save

## Plugins
Go to "Manage Jenkins" / "Configure System"
  * Git plugin
    * Enter "user.name" and "user.email"
  * GitHub Web Hook
    * Select "Let Jenkins auto-manage hook URLs"
    * Enter Username `ontohub-ci`
    * Enter previously generated OAuth token
  * GitHub Pull Request Builder
    * GitHub server api URL: https://api.github.com
    * Access Token: same OAuth token as in "GitHub Web Hook"
    * Admin list: GitHub users who can start a (test) job by commenting on a pull request.

## Jobs
For a job that is run automatically by pull requests, do the following:
  1. "New Item"
    * Choose a name **without spaces**.
    * Choose Freestyle Project
    * OK
  2. Configure the project
    * GitHub project: https://github.com/ontohub/ontohub/
    * Check "This build is parameterized"
      * Add a String parameter
        * Name: `sha1`
        * Default Value: staging (or whatever branch is the one you merge into)
    * Source Code Management
      * Git
      * Repository URL: https://github.com/ontohub/ontohub.git
      * Branch Specifier: `${sha1}`
    * Build Triggers
      * Check "GitHub Pull Request Builder"
      * Enter the admin list (who can trigger a build by commenting on the pull request).
      * Check "Use github hooks for build triggering".
    * Build Environment
      * Check "Color ANSI Console Output" (xterm)
    * Build
      * Set build status to "pending" on GitHub commit
      * Add build step (Execute Shell)
        * Enter the shell script to run ([see at the bottom of this section](#shell-script))
    * Post-build actions
      * Set build status on GitHub commit

### Shell script
```bash
#!/bin/bash
source ~/.bashrc
sudo hets -update
bundle install -j4
redis-cli flushdb
bundle exec rake db:migrate:reset
RAILS_ENV=test bundle exec rake db:migrate:reset || true
SPEC_OPTS="--color" CUCUMBER_OPTS="--color" ELASTIC_TEST_PORT=9200 DISPLAY=localhost:1.0 xvfb-run bundle exec rake
```
