# Dev Random

|              |                                                                             |
| ------------ | --------------------------------------------------------------------------- |
| name         | dev-random                                                                  |
| type         | Input                                                                       |
| version      | v1.0.0                                                                      |
| docker image | [weevenetwork/dev-random](https://hub.docker.com/r/weevenetwork/dev-random) |
| tags         | Docker, Weeve, MVP                                                          |
| authors      | Marcus Jones                                                                |

## Description

This module and project demonstrates a docker container mounting a device from the host, reading data, and processing data from that device.

# Features

-   Simple and lightweight for testing
-   Strict assertions in shell script for parameters and volumes

# Technical implementation

## Ingress module description

The simple ingress module mounts the linux random device to generate and forward a random hash string.

## Random data device

The /dev/urandom device node in linux generates unlimited random bytes of data. The data is generated from the entropy pool.

Bytes can be collected in various ways, just as from any file;

The `dd` utility can read and convert data from a file. The following command would read 3 bytes of data.

`random="$(dd if=/dev/urandom bs=3 count=1)"`

The `head` utility can read lines of a file. The following command would read 4096 bytes of data.

`random=$(head -n 4096 /dev/urandom)`

## Generate hash string

The `sha256sum` utility hashes input. The utility outputs a `-` characture which can be cut for a clean output.

`echo My data | sha256sum | cut -f 1 -d " "`

## Package into JSON payload

The `jq` utility can be used to package data into a JSON structure. The following command would place a variable `$randomstring` into the key value pair.

`JSON_STRING=$( jq -n -r --arg hs "$randomstring" '{"random hash": $hs}' )`

## Send as HTTP post

The `curl` utility is used to send HTTP data as a POST request. To avoid escaping newline and space characters, the payload (`-d`) is piped in.

`echo $JSON_STRING | curl -d @- -H "Content-Type: application/json" -X POST http://url:port`

# Developing

Recommend to install the [docker-pushrm](https://github.com/christian-korneck/docker-pushrm) plugin to publish READEM.md files.

docker login
