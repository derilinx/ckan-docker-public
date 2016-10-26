# hse-ckan
This is a dockerized CKAN, reworked for fast rebuilds and including extensions as submodules in the repository. In general extensions that are private GitHub repos are included as submodules, and other public ones are downloaded as part of the Docker build.

N.B. Please keep master (time of writing: datadore-ckan-replacement) clean and generic and add customizing CKAN extensions for client-work in a new branch as a submodule (or if they are public, as a revised Dockerfile, though that might make merges a bit more problematic). You can keep up to date with git merges from master (time of writing: datadore-ckan-replacement).

<strong>PLEASE, use https: for git submodules and not git: - otherwise we have problems deploying on servers.</strong>

In addition, please make CKAN upgrades in master (time of writing: datadore-ckan-replacement) using the script in the derilinx/ckan-docker-compose (time of writing: hse-docker) repository, and then merge them into your repository and do a git submodule update.
