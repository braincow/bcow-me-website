GCLOUD_CONFIG=default
GCLOUD_PROJECT=bcow-me
BUCKET=gs://www.bcow.me

all: clean build watch

auth:
	gcloud config configurations activate $(GCLOUD_CONFIG)

clean:
	rm -rf public

dist-clean: clean
	rm -rf .venv

venv:
	virtualenv -p python3 .venv && \
	source .venv/bin/activate && \
	pip install -r requirements.txt

build:
	source .venv/bin/activate && \
	statik

watch:
	source .venv/bin/activate && \
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

sync-bucket: build
	gsutil -m rsync -r public/ $(BUCKET)
