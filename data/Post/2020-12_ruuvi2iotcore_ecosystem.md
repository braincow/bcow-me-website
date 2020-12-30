---
title: Ruuvi tag Bluetooth beacons to GCP IoT Core
slug: ruuvi-tag-to-gcp-iotcore
summary: Collecting data for fun and profit
author: bcow
published: 2020-12-30
---

# Ruuvi tag Bluetooth beacons to GCP IoT Core

Or "how to survive the pandemic while keeping one's sanity by staying active".

## Foreword
EHLO everyone,

During these trying times, with [the human malware](https://en.wikipedia.org/wiki/Coronavirus_disease_2019) and [everything else](https://en.wikipedia.org/wiki/2020), we have all struggled with boredom. As collective humanity, we could be doing better, and while trying to avoid the deadly plague being spread around like glitter we have found ourselves in dire need of something to do while socially distancing. During the springtime when the lockdowns were in effect all around the world it almost seemed like we all suddenly as a species decided to bake bread, knit stuff, lose weight and exercise, or even dig our way through the piles of written fiction we collected that we never had time to read (allegedly!) before. Many new and old Netflix, Disney+, Youtube Premium, Amazon Prime Video, and etc accounts were scoured through of content after which, in many cases, our minds were lead to apathy, loose of interest in physical exercise, and finally into a cornucopia of different snacks with the end result of negating most of the collectively lost kilograms (or pounds if you still speak in colonial terms) of human fat tissue. Then summer finally arrived and for a while, things seemed to be back to normal, but in reality, we were, again collectively, mass hallucinating the lull and therefore when the fall inevitably arrived and the not so completely un-flu like human malware started to spread again like a rancid, years old, mustard on a sandwich we were all out of ideas or things to do; Well I was anyway.

That is my excuse for what follows (or followed), but mostly I tend to defend my spurt of insanity with the fact that I actually [do work in "the biz" as Cloud Consultant](https://wwww.solita.fi) so I need to hone my skills. Right? RIGHT!?

## Solution architecture

Before moving any further I believe it is best to share my current architecture (or what ended up being the current one):

[![My ruuvi2iotcore architecture in GCP](/assets/post_images/cover_ruuvi2iotcore_architecture.png "My ruuvi2iotcore architecture in GCP")](/assets/post_images/ruuvi2iotcore_architecture.png)

What we have here is a complete cloud-native approach to collecting Ruuvi tag beacons instead of self-hosting the database on-premises and running the software for doing the analysis, dashboarding, and access controls of the data.

### The Ruuvitags

For a while now I have had these [Ruuvi tags](https://www.ruuvi.com). I bought them out on a whim and never got around to collecting the data out of them except on occasionally glancing over at the mobile [Ruuvi Station](https://lab.ruuvi.com/ruuvi-station/) app the company provides. This worked for a while well enough for me until some update, either to Android or to the app itself, broke the background data collection. The app kept only a few day's worths of data anyway so long period data acquisition and analysis was not possible either. Actually, an analysis was not possible in any way as the app lacked all other features except the display of recorded values and few graphs for the small number of days the app did collect them for.

Ruuvi tags are these smallish IoT ready sensor packages neatly productized and [assembled around the Nordic Semiconductor nRF52832 IC](https://ruuvi.com/ruuvitag-specs/). Ruuvi tag is a relatively "stupid" device that, with standard weather station firmware, take some readings with its onboard sensors and then transmits them encoded into a vendor data section of a Bluetooth beacon. By capturing these beacons and decoding the information from the vendor data the data can be collected and stored centrally.

There are a lot of open-source projects out there to do just that, to centrally collect Ruuvi tag Bluetooth beacons, but all of them seemed to rely on locally hosting the data warehouse and collection software. I wanted to create something different (and simultaneously to fool around with GCP IoT Core.)

So I had three (3) tags and a Raspberry Pi 2 (It is an older device, but checks out sir!) laying around so after mounting the tags to their designated locations I fired up the Raspberry Pi and got to work.

### ruuvi2iotcore, Raspberry Pi and the power of the cloud

[Rust](https://www.rust-lang.org/) is a great systems programming language. I have been learning it for couple of years now and ruuvi2iotcore might be the most complex piece of software I've ever written with it.

[ruuvi2iotcore](https://github.com/braincow/ruuvi2iotcore) is a tool I released some time ago that when running on my [Raspberry Pi](https://www.raspberrypi.org/) 2 at home listens for the Bluetooth beacons from the Ruuvi tags, decodes the measurements and sends them as JSON over MQTT to IoT Core. Obviously, since my Raspberry Pi is so old I needed a Bluetooth USB dongle and a WLAN dongle to make it wireless as well, but the later revisions of the Pi do have integrated wireless chipset so no need for that if you build this setup from scratch with one.

As ruuvi2iotcore can run on almost any GNU/Linux host that has a Bluetooth interface it does not need to be run on Raspberry Pi, but it can instead even be an old laptop or another dedicated box. (You decide your implementation details based on your budget and/or what hardware you have at hand.)

Tags and the Pi are the only portions of this data collection platform that need to be hosted on-site. In this case at my flat. Tags are mounted at, where ever, and the Pi sits neatly hidden away in a bookshelf somewhere. Once the JSON message is sent to [IoT Core](https://cloud.google.com/iot-core) rest is handled by the cloud. This is exceptionally neat because I do not have to worry about free space for my database or operating system or software updates or anything like that except for the occasional firmware update for the tags, Raspberry Pi OS updates ([Fedora Linux](https://fedoramagazine.org/install-fedora-on-a-raspberry-pi/)) and ruuvi2iotcore releases. The latter obviously happens frequently as I actively develop the software, but the end-users searching for a more stable experience should use the official releases instead of the Git "main" branch anyway.

### Google Cloud Platform

#### Cloud IoT Core

IoT Core is an MQTT broker / HTTP REST endpoint that can be used to standardize many usual tasks and relevant processes when dealing with IoT devices.

ruuvi2iotcore acts as a "device gateway" in IoT Core meaning that all Ruuvi tags are configured as devices to the device registry, but since they are low power devices that lack the capability of communicating over the Internet directly they are instead associated with a gateway that relays information in their behalf. This way the bookkeeping of your fleet of IoT devices is handled by IoT core and you do not need to write software code yourself to create this inventory nor maintain it.

IoT Core also is a "simple" service, it does not store the data sent in nor does it analyze it in any way except for some internal error handling, etc. You need to pipe the information sent in, to other cloud services to utilize it. This is why I love GCP so much, it follows the POSIX thinking of writing one tool to do one job exceptionally well and letting other tools take over from there. In my architecture that is the Pub/Sub service.

#### Cloud Pub/Sub

[Cloud Pub/Sub](https://cloud.google.com/pubsub) is in essence message ingestion and delivery service. Message queuing with a few additional bells & whistles.

Once the message arrives in a Pub/Sub topic from the Clout IoT Core it contains information about the device sending in the data (this is where the inventory aspect of the Cloud IoT Core comes in handy) and the message payload itself received over MQTT from the gateway (ruuvi2iotcore) relayed in behalf of a Ruuvi tag.

This is where the message waits for further action which happens immediately as there is a subscription to the topic from a Cloud Function already in place.

#### Cloud Function

Serverless - if you work in the industry you probably have heard the term, maybe even used serverless stack before. Again one of those things that make the life of a modern operator so easy. No need to maintain any server infrastructure. Just deploy your code and it automatically scales based on load and other variables but also is highly available. It is almost like magic.

So once the Bluetooth beacon has reached the Pub/Sub topic as a JSON formatted message it triggers a cloud function called ["ps2bq"](https://github.com/braincow/gcp-cloudfunctions/tree/main/ps2bq). This simple Python script takes the JSON payload and using Google provided Python libraries stores the contents into the BigQuery dataset.

#### BigQuery

[BigQuery](https://cloud.google.com/bigquery) is a hosted data warehousing solution native to GCP even though it can be made multi-cloud these days as well. Think of Snowflake as an analog if you work in the data sciences biz and are familiar with it or, if not, then think about a hosted database since I use it as one for the most parts.

The JSON formatted data is stored in a dataset table and is archived there for later use. This is the long time storage of the data collected from my Ruuvi tags now.

Due to stupid limitation/design decision in Google Data Studio (about this later), there is a need to normalize the data in BigQuery before Data Studio can reliably plot it on the time axis. This is because there can be multiple beacons from the same Ruuvi tag per minute, but that is nothing that BigQuery cant handle. As an example following SQL query can be executed and set-up as a view in BigQuery that Data Studio will then use, for example:

```sql
select timestamp_trunc(timestamp, minute) as timestamp, address, any_value(data.data) as data from ruuvitag.data group by timestamp, address order by timestamp;
```

#### Cloud Monitoring

I noticed while developing ruuvi2iotcore that sometimes the Bluetooth stack would get stuck or the software would spaz out in unknown ways. Therefore I again utilized the power of the cloud to create some auto-healing capabilities into the solution. I have released a couple of versions of ruuvi2iotcore since then that have for the most part fixed these issues, but I left the monitoring in place just because I find the solution being so damn pretty.

As it happens I already created a feature to send in remote commands from IoT Core to the ruuvi2iotcore software. One of these commands is a reset command that forces it to clean its internal state if possible and to restart from an almost empty state. What was needed was a way to send this signal automatically to ruuvi2iotcore when we see no new beacons being published by IoT Core to the rest of my data ingestion stack. 

We can use the [Cloud Monitoring](https://cloud.google.com/monitoring) to see if Pub/Sub topic is acknowledging messages on the expected rate. Meaning that messages are coming in and the cloud function is processing them and storing them to BigQuery. If the rate is below the expected threshold we trigger another Pub/Sub topic that has a second cloud function called ["ruuvi2iotcore_reset"](https://github.com/braincow/gcp-cloudfunctions/tree/main/ruuvi2iotcore_reset) subscribed to it. What the function essentially does is that if an event is triggered with an "open" state, meaning that it is a new alert, it issues the reset command through IoT Core API to the ruuvi2iotcore application running on my Raspberry Pi. Software reset should then take care of the problem.

#### Data dashboarding in Google Data studio

[Google Datastudio](https://marketingplatform.google.com/about/data-studio/) is actually meant as a companion for the Google Analytics platform, but it can dashboard many other data sets as well and combine data from many locations like any data dashboarding tool should. It has its limitations though and it does not really shine for scientific analysis, but it works and is "free to use" so that's why I went with it. If you have a lot of data it can, however, start to cost something so be aware of this.

With Datastudio I dashboarded the relevant weather data from BigQuery streamed in from my Ruuvi tags and I can select different metrics like temperature and air humidity to be plotted for example. I can compare different readings from different tags across different time windows. Relatively simple stuff.

[![Ruuvi tag data plotted](/assets/post_images/cover_ruuviathome_dashboard.jpeg "Ruuvi tag data plotted")](/assets/post_images/ruuviathome_dashboard.jpeg)

#### IRC Bot, latest data

The what!? You ask.

Well, you young whippersnappers out there might not know that IRC is still alive and kicking and will eat any Discord server or Slack workspace for breakfast.

In all seriousness, I needed a cloud function ["ruuvitag_latest"](https://github.com/braincow/gcp-cloudfunctions/tree/main/ruuvitag_latest) for a completely different feature I am planning, but to test it I integrated it into my IRC bot first so that in addition to the Data Studio dashboard I could easily query the latest values from my bot as well. This REST API that the cloud function provides can be queried publicly so it needed also authentication to prevent unauthorized users from abusing it. Luckily, again, the power of the cloud comes to our rescue. GCP has a concept of "service accounts" that can authenticate as users and can be assigned privileges through Cloud IAM to cloud resources. This is why my bot has a service account associated with it and it uses it to authenticate all requests it makes to my latest data REST API.

Once I had the latest data cloud function created I needed to write a plugin for my bot. Currently, I am fooling around with [Sopel IRC bot](https://github.com/sopel-irc/sopel). Since Sopel is written in Python it is really easy to write plugins for it. So the [ruuvitag plugin](https://github.com/braincow/sopel-plugins) was born. After configuring the plugin with the service account key file and API endpoint it needs to query to get the data, the rest is handled by the bot itself.

[![Bot response](/assets/post_images/cover_ruuvitag_bot.png "Bot response")](/assets/post_images/ruuvitag_bot.png)

## Now what?

Well, this was an exercise and learning experience on my part. I don't know if I ever iterate this particular solution any further or not, but I do have actual relevant use cases for IoT Core in mind for the future. Otherwise, I do use Google Cloud Platform and adjacent services all the time in my work so if I come up with new and fun ways to extend this architecture further I shall tell you about it (maybe) as I learn of them.

All code snippets and information presented here are free to use unless otherwise licensed. I take no responsibility for anything if you mess up something. The power of the cloud does require you to understand that cloud is a service and when misused the service has a cost. For me, these costs are currently around ~7€ per month to run, but more tags and/or with weird configurations or too large resource allocations can make it significantly higher for you.

Keep on learning new things while staying safe with the human malware and everything else. See you in 2021.
