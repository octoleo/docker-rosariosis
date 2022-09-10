#!/bin/bash
set -Eeuo pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

# you can pass the versions (of Rosariosis) to this file for the initial/re-build
versions=("$@")
if [ ${#versions[@]} -eq 0 ]; then
  # get the folders from the current root directory of the project as the versions
  # if no versions where passed to the file
  # this is the standard (2021) way fo doing this
  # see (https://github.com/docker-library/php/blob/master/versions.sh#L38)
  versions=(*/)
  # was assume the folders to be correct
  # and will serve as the rule
  # so the json is build from that
  json='{}'
else
  # with the initial/re-build the versions.json is manually set
  json="$(<versions.json)"
fi
# always make sure the folder / slash is removed
versions=("${versions[@]%/}")

# we use the versions help until the API is improved (with local overriding options)
if [ -f .versions-helper.json ]; then
   versionsHelper="$(<.versions-helper.json)"
elif [ -f versions-helper.json ]; then
   versionsHelper="$(<versions-helper.json)"
else
  echo "versions-helper.json file not found!"
  exit 1
fi
# now we loop over the (Rosariosis) versions
for version in "${versions[@]}"; do
  # continue only if we have a value
  if [[ -z "$version" ]] || [ "$version" = "conf" ]; then
    continue
  fi

  export version
  doc='{}'

  # lets get the full version
  fullVersion=$(echo $versionsHelper | jq -r '.[env.version].version')
  export fullVersion

  # lets see if we have a tar URL
  package=$(echo $versionsHelper | jq -r '.[env.version].package')

  # when not found we load sha512 from API
  if [ "${package}" = 'null' ]; then
    # set the full URL for the IMAGES
    package="https://gitlab.com/francoisjacquet/rosariosis/-/archive/v${fullVersion}/rosariosis-v${fullVersion}.tar.bz2"
  fi
  # we get the sha from the package
  curl -o rosariosis.tar.bz2 -SL "${package}" &>/dev/null
  # get the hash
  sha512=$(sha512sum rosariosis.tar.bz2 | cut -d " " -f 1)
  # remove the file
  rm rosariosis.tar.bz2

  # set the hash to the JSON
  if [ -n "$sha512" ] && [ -n "$package" ]; then
    export sha512
    export package
    doc="$(jq <<<"$doc" -c '.sha512 = env.sha512')"
    doc="$(jq <<<"$doc" -c '.package = env.package')"
  fi

  # get the default php version
  defaultPHP=$(echo $versionsHelper | jq -r '.[env.version].php')
  # get the PHP versions
  phpVersions=$(echo $versionsHelper | jq -r '.[env.version].phpVersions | keys[]' | jq -R -s -c '. / "\n" - [""]')
  # get the default variant
  defaultVariant=$(echo $versionsHelper | jq -r '.[env.version].variant')
  # get the variants
  variants=$(echo $versionsHelper | jq -r '.[env.version].variants')
  # get the aliases
  aliases=$(echo $versionsHelper | jq -r '.[env.version].aliases')

  # echo some version details
  echo "### Rosariosis $version.x details"
  echo "# Version => $fullVersion"
  echo "# PHP     => $phpVersions"
  echo "# sha512  => $sha512"

  # build this fullVersion matrix
  # and add it to the JSON
  json="$(
    jq <<<"$json" -c \
      --argjson doc "$doc" \
      --argjson phpVersions "$phpVersions" \
      --argjson aliases "$aliases" \
      --argjson variants "$variants" \
      --arg defaultPHP "$defaultPHP" \
      --arg defaultVariant "$defaultVariant" '
			.[env.version] = {
				version: env.fullVersion,
				php: $defaultPHP,
				phpVersions: $phpVersions,
				variant: $defaultVariant,
				variants: $variants,
				aliases: $aliases,
			} + $doc
		'
  )"
done

# store the JSON to the file system
jq <<<"$json" -S . >versions.json
