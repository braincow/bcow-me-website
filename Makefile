GCLOUD_CONFIG=default
GCLOUD_PROJECT=bcow-me
BUCKET=gs://www.bcow.me

auth:
	gcloud config configurations activate $(GCLOUD_CONFIG)

all: clean build watch

clean:
	rm -rf public

build:
	statik

watch:
	statik --watch --host 127.0.0.1 --port 8080

cloudbuild: auth
	gcloud --project=$(GCLOUD_PROJECT) builds submit . \
		--substitutions=_BUCKET=$(BUCKET)

create-bucket: auth
	# create the bucket
	gsutil mb -p $(GCLOUD_PROJECT) -b on -c standard -l europe-north1 $(BUCKET)
	# make it public
	gsutil iam ch allUsers:objectViewer $(BUCKET)
	# set default directory index file
	gsutil web set -m index.html $(BUCKET)
	# set the 404 file
	gsutil web set -e 404.html $(BUCKET)

sync-bucket: auth
	gsutil -m rsync -r public/ $(BUCKET)
