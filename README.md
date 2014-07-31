# EWN Content Structure API

## Introduction

Cleans up the HTML of EWN articles and returns paragraph data, as well as processed markdown for the entire article.

This markdown can then be passed to the Markdown/Markup API for processing for various device views.

## Endpoints

### GET /

Fetches an EWN URL and returns the processed results.

#### Parameters

- url (required): URL of an article or feature article on ewn.co.za
- exclude (optional): a comma-separated list of paragraph types to exclude from the processed output

### POST

Takes an HTML chunk and processes it against the same rules as the GET endpoint.

#### Parameters

- html (required): the article markup. Please note; this excludes any container elements, and refers only to the inner HTML content.
- exclude (optional): a comma-separated list of paragraph types to exclude from the processed output

## Technical

Ruby
Sinatra

- In project root, run 'bundle install' (requires Ruby)
- 'rackup'