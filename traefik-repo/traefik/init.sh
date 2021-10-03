#!/bin/bash

[ ! -f .env ] && cp .env.example .env

touch data/acme.json
chmod 600 data/acme.json
