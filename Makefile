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
	statik --watch

cloudbuild: auth
	gcloud --project=$(GCLOUD_PROJECT) builds submit \
		--substitutions=_BUCKET=$(BUCKET)

create-bucket: auth
	gsutil mb -p $(GCLOUD_PROJECT) -b on -c standard -l europe-north1 $(BUCKET)

bucket-config: auth
	# set default directory index file
	gsutil web set -m index.html $(BUCKET)
	# set the 404 file
	gsutil web set -e 404.html $(BUCKET)
