# Terraforming PKS GCP

This Repo is based on  [https://github.com/pivotal-cf/terraforming-gcp](https://github.com/pivotal-cf/terraforming-gcp), the work at (https://github.com/making/terraforming-pks-gcp) and (https://github.com/dbbaskette/terraforming-pks-gcp).  The Concourse Pipline work has been completed and modified to keep from having to download a 3GB file locally to then just send it back up.

### Prerequisites - Mac

The prerequisites can all installed on your local system via brew, so if you don't have brew....go get it.   Your system needs the `gcloud` cli, fly-cli (concourse) as well as `gettext`, and of course, `Docker.  Here are the OS-X installation commands:

```bash
brew update
brew install Caskroom/cask/google-cloud-sdk
brew install gettext
wget https://github.com/concourse/concourse/releases/download/v4.1.0/fly_darwin_amd64
mv fly_darwin_amd64 /usr/local/bin/fly
chmod +x fly
```
### Prerequisites - GCP VM

You can also just create a GCP small VM, clone the repo there, and install the needed tools using `sudo apt-get`. I've had much better success with an ubuntu based image than the default. The main advantage of using a GCP VM is that all downloads and uploads happen in GCP and therefore much faster. Also - you can close your computer and let the installation continue. Or better yet - monitor the progress from your phone! :)

(http://url/to/img.png)

If you go down that route - I HIGHLY recommend attaching a static IP to your VM, since concourse tends to go crazy when it's IP changes (you won't be able to login, and changing the parameters in a running concourse docker container is not fun).

### GCP Account

##### MAKE SURE YOU HAVE ENOUGH __RESOURCE QUOTA IN THE REGION OF DEPLOYMENT__ TO CREATE THE INFRASTRUCTURE AND A PKS CLUSTER.   (CPU/RAM/STORAGE,etc)
1) If this is the first time you have used the account on your system, you will have to run these commands:
```
gcloud auth login
gcloud config set project ${PROJECT_ID}
```

You will need to enable the following Google Cloud APIs:
* Compute Engine API
* Identity and Access Management
* Cloud Resource Manager

### Service Account

You will need a key file for your service account to allow terraform to deploy resources. If you don't have one, you can create a service account and a key for it:

```
export PROJECT_ID=XXXXXXXX
export ACCOUNT_NAME=YYYYYYYY
gcloud iam service-accounts create ${ACCOUNT_NAME} --display-name "PKS Account"
gcloud iam service-accounts keys create "terraform.key.json" --iam-account "${ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
gcloud projects add-iam-policy-binding ${PROJECT_ID} --member "serviceAccount:${ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" --role 'roles/owner'
```


### Var File

I have tried to limit the number of variables you are required to provide to get going.  
You Just fill in out a variables.txt text file.

**For security purposes, I do not include variables.txt in this repo**. There is a risk of populating this file with secrets such as your GCP service account and accidently push that back into git. This is very risky. Therefore - you should create a file called variables.txt under a "secrets" directory in your home directory (~/secrets/variables.txt). The parameters needed in this file are listed below:

```
PIVNET_API_TOKEN="<REDACTED - get it from "edit profile" in network.pivotal.io>"
TERRAFORM_BUCKET="<SHOULD_BE_UNIQUE>"
GCP_PROJECT_ID="<REDACTED>"
GCP_SERVICE_ACCOUNT_KEY_PATH="<FULL_PATH_TO_KEY_JSON. MAKE SURE THIS KEY.JSON PATH IS OUTSIDE THE GIT REPO DIRCTORY SO IT WILL NOT BE PUSHED BY MISTAKE!>"
PKS_ENV_PREFIX="pksgcp"
PKS_VERSION="1.2.0"
PKS_CLI_USERNAME="admin"
STEMCELL_FILENAME="light-bosh-stemcell-97.18-google-kvm-ubuntu-xenial-go_agent.tgz - THIS IS STILL NOT AUTOMATED ENOUGH, PLEASE CHOOSE THE CORRECT STEMCELL NAME FROM PIVOTAL NETWORK"
PKS_CLI_PASSWORD="<CHOOSE_COMPLEX_PASSWORD!>"
PKS_INITIAL_CLUSTER_NAME="pks-demo1"
PKS_INITIAL_CLUSTER_SIZE="small"
GCP_REGION="us-central1"     # Can be changed to local region
GCP_ZONE_1="us-central1-a"   # Can be changed to zones within local region
GCP_ZONE_2="us-central1-b"   # Can be changed to zones within local region
GCP_ZONE_3="us-central1-c"   # Can be changed to zones within local region
OPSMAN_IMAGE_URL="https://storage.googleapis.com/ops-manager-us/pcf-gcp-2.3-build.170.tar.gz"
CONCOURSE_URL="External URL or localhost,  FOR EXAMPLE http://23.11.3.35:8080 or http://127.0.0.1:8080"
CONCOURSE_PASSWORD="<CHOOSE_COMPLEX_PASSWORD!>"
POSTGRES_PASSWORD="<CHOOSE_COMPLEX_PASSWORD!>"
OPSMAN_PASSWORD="<CHOOSE_COMPLEX_PASSWORD!>"
OPSMAN_DECRYPT_PASSWORD-"<CHOOSE_COMPLEX_PASSWORD!>"
PRODUCT_VERSION="97\..*"
```
### Running

Note: please make sure you have populated the `variables.txt` file above as mentioned.

### Standing up environment

From the `./ci` subdirectory:
```
./run-pipeline.sh
```

### Monitoring Progress

The script will launch multiple containers and bring up a Concourse instance and the load and start the pipeline.   After a few seconds, the script will complete and show a URL to access the pipeline within Concourse. Note that if you use an external URL the IP should ofcourse be different.

[http://127.0.0.1:8080/teams/main/pipelines/deploy-pks](http://127.0.0.1:8080/teams/main/pipelines/deploy-pks)

Username:  concourse
Password:  as set in variables.txt CONCOURSE_PASSWORD

The Last Step of the Pipeline, SHOW-NEXT-INSTRUCTIONS, has a task that displays the procedures for creating a K8S cluster.   You should be able to cut and past from that screen.

These is also an Optional Task available that will create a cluster for you. Note that this will create a **large 9 node cluster!**

### Tearing down environment

To tear down the installation, simply trigger the wipe-env task.   There might be a few cluster specific things to clean up.  If the task fails, you can clean those things up manually and then trigger it again. If ops-man was not created poroperly, wipe-env will not work in it's current state.   You will have to delete ALL object manually.  Sometimes objects are easy to miss, so it's also recommended to change the prefix of the next deployment and the bucket name.    This will ensure you don't have any conflicts.
