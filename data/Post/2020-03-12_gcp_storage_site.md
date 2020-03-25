---
title: Hosting static site in Google Cloud Storage
slug: gcp-storage-site
summary: Site hosted on Google Cloud Storage bucket and built from sources in Git with Cloud Build.
author: bcow
published: 2020-03-25
---

# Static site

## The Why

In addition to being lightning fast, by even yesterdays standards, static sites are more secure than dynamic websites rendered from database contents on the fly as there is no content management system to DDoS or breach. The downside being that there is an additional compilation stage to get your page published, but this can be automated away easily.

Also, I like to do things in "weird" ways to challenge myself and learn few new skills of my trade whenever I can.

## The How

My site now runs in Google Cloud. To be more precise few GCP components are used:

* Storage buckets to hold and serve the actual web content over HTTP, but also as a utility buckets by the Cloud Build api as well.
* Cloud Build to execute Python and Statik to compile the html that are then served from the storage bucket.
* Cloud Source linked to [Github repository](https://github.com/braincow/bcow-me-website) to provide mirroring and trigger for Cloud Build.

The site is rendered using [Statik](https://getstatik.com/) compiler that uses Markdown as input and renders full HTML sites out based on data model that you define! This separates Statik from the rest like Hyde or Jekyll and others.

### Storage

In GCP you can host a subdomain in a storage bucket if you:

1. Own the domain and have it verified in search console. *
2. Create a bucket with a name e.g. gs://www.bcow.me
3. Set IAM for the bucket to allow world readable objects

_*)More info in the Google's [tutorial about static site hosting in GCP](https://cloud.google.com/storage/docs/hosting-static-website)._

My implemention details for these (expect the domain validation part) can be found from the [repository](https://github.com/braincow/bcow-me-website) from which this website is actually built from. There however lays no surprises when compared to the Googles own tutorial on the matter expect that my _Makefile_ holds the commands used to provisions the bucket and for configuring it. Please, feel free to disect it for more info.

### Automated build

Ah, now we are getting to the tasty part of this story. The site is compiled from the source Markdown files into HTML pages and related files that are then copied to storage bucket. This happens via the magic of Cloud Build. Cloud Build is a powerful CI/CD pipeline pruduct that comes as a standard in GCP.

Initial actions that happen from the build jobs point of view are:

1. Git push to master branch triggers Cloud Build job.
2. Cloud Build reads in cloudbuild.yaml and executes steps with in.

Steps that are actually taken by Cloud Build are:

1. Use official Python 3.7 Debian 10 Docker image, install Statik on it and execute it
2. Synchronize all rendered files, pictures and etc from public/ folder that Statik created to the remote GCP Storage Bucket and delete all files in it that do not exist on the source.
3. Synchronize all additional files from static/ folder to the bucket, but do not delete any files like in previous step.

The end result is always clean, mean and lean static web site hosted directly from Google's storage.

## Future improvements

Unfortunately GCP Storage does not support HTTPS on custom domains and requires GCP Load Balancer that uses Storage buckets as its backing storage if you want it enabled for your site. This seems like a next good subject for a post once I have it setup and tested first.
