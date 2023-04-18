#!/usr/bin/env bash
set -o pipefail
#set -x
#
# Based on:
#
# 1. A 'fat' ansible version
# 2. A regular expression pattern for collections
#
# this script installs the corresponding versions of ansible-core and the
# collection versions that are bundled with the 'fat' ansible.
#
# The net result is a slimmed down code base that is up to 90% smaller compared
# to that of the 'fat' version.

# A good way to start with a minimal venv:
#
# python3 -m venv venv
# . venv/bin/activate
# pip install -U pip wheel yq
#
# And then run this script.
# Override the defaults using environment vars, for example:
#
# ANSIBLE_VERSION=5.10.0 ansible_venv_slim.sh
# COLLECTIONS_PATTERN='^(amazon.aws|ansible.(netcommon|posix|utils)|community.(aws|crypto|docker|general|postgresql))$' ansible_venv_slim.sh


# Fat ansible version
ANSIBLE_VERSION="${ANSIBLE_VERSION:-7.2.0}"

# Regex pattern to match the ansible collection names that we need.
# NOTE: this may need tweaking for different major releases, are things come
# and go.
COLLECTIONS_PATTERN="${COLLECTIONS_PATTERN:-^(ansible.(posix|utils)|community.(crypto|general))$}"


if [[ -z "${VIRTUAL_ENV}" ]]; then
  echo "No activated VIRTUAL_ENV, exiting"
  exit 1
fi

if ! pip show yq >/dev/null 2>&1; then
  echo "No 'yq' found, please install it in this virtualenv (pip3 install yq)"
  echo "exiting"
  exit 1
fi

for i in wget jq; do
  if ! command -v ${i} $>/dev/null; then
    echo "No ${i} command available, please install that"
    exit 1
  fi
done


# This is just a single digit (5, 6, etc)
ansible_main_version="${ANSIBLE_VERSION/.*/}"

fat_base_url="https://raw.githubusercontent.com/ansible-community/ansible-build-data/main/${ansible_main_version}/ansible-${ANSIBLE_VERSION}"
all_deps_url="${fat_base_url}.deps"
# The list of collections that are bundled with the fat ansible version
all_collections_url="${fat_base_url}.yaml"


# First we install the correct ansible-core version
# This is listed in the deps URL
if ! ansible_core_version=$(wget -qO - "${all_deps_url}" | sed -n -E 's/^_ansible_core_version: //p'); then
  echo "Failed fetching the ansible-core version from ${all_deps_url}, exiting"
  exit 1
fi

# FIXME also fetch minimal python vesion from deps file and use that for checking

echo "Instead of fat ansible version ${ANSIBLE_VERSION}, now only installing corresponding ansible-core version ${ansible_core_version}"
pip install ansible-core==${ansible_core_version}


# Next we install the corresponding collections
if ! all_collections=$(wget -qO - "${all_collections_url}"); then
  echo "Failed fetching collections file from ${all_collections_url}, exiting"
  exit 1
fi

# Filter the yaml list of the collections using the regular expression pattern
our_collections=$(
echo "${all_collections}" | yq -y -r "
  { collections:
    .collections | map (
      select(
        .name|test(
          \"${COLLECTIONS_PATTERN}\"
          )
        )
     )
  }"
)

echo -e "\nUsing the supplied pattern ('${COLLECTIONS_PATTERN}'),
cherry picking the versions of those collections that are in fat ansible ${ANIBLE_VERSION}:

$our_collections\n

NOTE: this may pull in dependencies\n"


# Install collections
# We set the collection path to this venv's 'site-packages', the same place as
# where the fat ansible stores them.
# FIXME: add checks that iterate over collections and only install/upgrade/downgrade if version differs.
# Because right now we have to use the 'force' option always, which is not nice...
ANSIBLE_COLLECTIONS_PATH=$("${VIRTUAL_ENV}/bin/python3" -c "import site; print(site.getsitepackages()[0])") \
  "${VIRTUAL_ENV}/bin/ansible-galaxy" collection install --force -r <(echo "${our_collections}")

echo "Done. Confirming installed collections:
$("${VIRTUAL_ENV}/bin/ansible-galaxy" collection list)"
