---
title: Hosting static site in Google Cloud Storage
slug: gcp-storage-site
summary: Site hosted on Google Cloud Storage bucket and built from sources in Git with Cloud Build.
author: bcow
published: 2020-03-12
---

# Static site

## The Why

In addition to being lightning fast, by todays standards, static sites are more secure as there is no content management system to DoS or breach. The downside being that there is an additional compilation stage to get your page published, but this can be automated away, mostly.

Also, I like to do things in "weird" ways to challenge myself and learn few new skills here & there.

## The How

My site now runs in Google Cloud. To be more precise few GCP components are used:

* Storage, to hold and serve the actual web content over HTTP.
* Cloud Build, to execute Python and Statik to compile the html that are then served from the storage bucket.
* Cloud Source, linked to Github [repository](https://github.com/braincow/bcow-me-website) to provide mirroring and trigger for Cloud Build.

### Storage

In GCP you can host a subdomain in a storage bucket if you:

1. Own the domain and have it verified in search console
2. Create a bucket with a name e.g. _gs://www.bcow.me_
3. Set IAM for the bucket to allow world readable objects

More info in the Google's [tutorial about static site hosting in GCP](https://cloud.google.com/storage/docs/hosting-static-website).

My implemention details for these (expect the domain validation part) can be found from the [repository](https://github.com/braincow/bcow-me-website) from which this website is actually built from. There however lays no surprises when compared to the Googles own tutorial on the matter expect that my _Makefile_ holds the commands used to provisions the bucket and for configuring it. Please, feel free to disect it for more info.

### Automated build

Ah, now we are getting to the tasty part of this story. The site is compiled from the source Markdown files into HTML pages and related files that are then 
