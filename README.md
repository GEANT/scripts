"Miscellaneous" scripts


## ansible\_venv\_slim.sh

Doing `pip install ansible` has started to yield an ever increasing code base
over the last years. This is because the `ansible` package includes many
collections and has become rather 'fat'.
Since almost all users will only need a few collections, an alternative would
be to just do `pip install ansible-core` (which provides all the required
commands), and then manually install the collections that are needed. But how do
you establish which version of `ansible-core` is needed? And which versions of
the collections?

This script will sort that out for you, based on two things:

* The version of the 'fat' `ansible` package. Default: `7.4.0`
* A regular expression that matches the required collection names.
  Default: `^(ansible.(posix|utils)|community.general)$`

### Requirements

* An activated python3 virtualenv
* `wget`
* `jq`
* `yq`

On the Debian family this should be sufficient:


```sh
sudo apt-get update
sudo apt-get install -y wget git python3-venv yq
git clone https://github.com/GEANT/scripts.git
cd scripts
python3 -m venv venv
. venv/bin/activate
pip install -U wheel pip
```

### Usage

```sh
# Using defaults
./ansible_venv_slim.sh

# Different fat ansible version
ANSIBLE_VERSION=6.6.0 ./ansible_venv_slim.sh

# Different collection name pattern
COLLECTIONS_PATTERN='^(amazon.aws|ansible.(netcommon|posix|utils)|community.(aws|crypto|docker|general|postgresql))$' ./ansible_venv_slim.sh
```

Example using the defaults:

```
(venv) vagrant@bookworm:~/scripts$ ./ansible_venv_slim.sh
Instead of fat ansible version 7.4.0, now only installing corresponding ansible-core version 2.14.4
Collecting ansible-core==2.14.4
  Using cached ansible_core-2.14.4-py3-none-any.whl (2.2 MB)
Collecting jinja2>=3.0.0 (from ansible-core==2.14.4)
  Using cached Jinja2-3.1.2-py3-none-any.whl (133 kB)
Requirement already satisfied: PyYAML>=5.1 in ./venv/lib/python3.11/site-packages (from ansible-core==2.14.4) (6.0)
Collecting cryptography (from ansible-core==2.14.4)
  Using cached cryptography-40.0.2-cp36-abi3-manylinux_2_28_x86_64.whl (3.7 MB)
Collecting packaging (from ansible-core==2.14.4)
  Using cached packaging-23.1-py3-none-any.whl (48 kB)
Collecting resolvelib<0.9.0,>=0.5.3 (from ansible-core==2.14.4)
  Using cached resolvelib-0.8.1-py2.py3-none-any.whl (16 kB)
Collecting MarkupSafe>=2.0 (from jinja2>=3.0.0->ansible-core==2.14.4)
  Using cached MarkupSafe-2.1.2-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl (27 kB)
Collecting cffi>=1.12 (from cryptography->ansible-core==2.14.4)
  Using cached cffi-1.15.1-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl (462 kB)
Collecting pycparser (from cffi>=1.12->cryptography->ansible-core==2.14.4)
  Using cached pycparser-2.21-py2.py3-none-any.whl (118 kB)
Installing collected packages: resolvelib, pycparser, packaging, MarkupSafe, jinja2, cffi, cryptography, ansible-core
Successfully installed MarkupSafe-2.1.2 ansible-core-2.14.4 cffi-1.15.1 cryptography-40.0.2 jinja2-3.1.2 packaging-23.1 pycparser-2.21 resolvelib-0.8.1

Using the supplied pattern ('^(ansible.(posix|utils)|community.general)$'),
cherry picking the versions of those collections that are in fat ansible :

collections:
  - name: ansible.posix
    source: https://galaxy.ansible.com
    version: 1.5.1
  - name: ansible.utils
    source: https://galaxy.ansible.com
    version: 2.9.0
  - name: community.general
    source: https://galaxy.ansible.com
    version: 6.5.0


NOTE: this may pull in dependencies

Starting galaxy collection install process
Process install dependency map
Starting collection install process
Downloading https://galaxy.ansible.com/download/ansible-posix-1.5.1.tar.gz to /home/vagrant/.ansible/tmp/ansible-local-3554e4qoneoo/tmprs50b145/ansible-posix-1.5.1-k8day4rq
Installing 'ansible.posix:1.5.1' to '/home/vagrant/scripts/venv/lib/python3.11/site-packages/ansible_collections/ansible/posix'
Downloading https://galaxy.ansible.com/download/ansible-utils-2.9.0.tar.gz to /home/vagrant/.ansible/tmp/ansible-local-3554e4qoneoo/tmprs50b145/ansible-utils-2.9.0-v61ldgw2
ansible.posix:1.5.1 was installed successfully
Installing 'ansible.utils:2.9.0' to '/home/vagrant/scripts/venv/lib/python3.11/site-packages/ansible_collections/ansible/utils'
Downloading https://galaxy.ansible.com/download/community-general-6.5.0.tar.gz to /home/vagrant/.ansible/tmp/ansible-local-3554e4qoneoo/tmprs50b145/community-general-6.5.0-8fltnv90
ansible.utils:2.9.0 was installed successfully
Installing 'community.general:6.5.0' to '/home/vagrant/scripts/venv/lib/python3.11/site-packages/ansible_collections/community/general'
community.general:6.5.0 was installed successfully
Done. Confirming installed collections:

# /home/vagrant/scripts/venv/lib/python3.11/site-packages/ansible_collections
Collection        Version
----------------- -------
ansible.posix     1.5.1
ansible.utils     2.9.0
community.general 6.5.0
```

The collection size is now:

```sh
(venv) vagrant@bookworm:~/scripts$ du venv/lib/python3.11/site-packages/ansible_collections/* -sch
6.5M	venv/lib/python3.11/site-packages/ansible_collections/ansible
8.0K	venv/lib/python3.11/site-packages/ansible_collections/ansible.posix-1.5.1.info
8.0K	venv/lib/python3.11/site-packages/ansible_collections/ansible.utils-2.9.0.info
24M	venv/lib/python3.11/site-packages/ansible_collections/community
8.0K	venv/lib/python3.11/site-packages/ansible_collections/community.general-6.5.0.info
30M	total
```


For comparison, this is what the collection list looks like after `pip install
ansible`:

```
(venv) vagrant@bookworm:~/scripts$ du venv/lib/python3.11/site-packages/ansible_collections/* -sch
12K	venv/lib/python3.11/site-packages/ansible_collections/__pycache__
5.5M	venv/lib/python3.11/site-packages/ansible_collections/amazon
6.5M	venv/lib/python3.11/site-packages/ansible_collections/ansible
4.0K	venv/lib/python3.11/site-packages/ansible_collections/ansible_community.py
4.0K	venv/lib/python3.11/site-packages/ansible_collections/ansible_release.py
5.6M	venv/lib/python3.11/site-packages/ansible_collections/arista
2.0M	venv/lib/python3.11/site-packages/ansible_collections/awx
9.9M	venv/lib/python3.11/site-packages/ansible_collections/azure
3.4M	venv/lib/python3.11/site-packages/ansible_collections/check_point
300K	venv/lib/python3.11/site-packages/ansible_collections/chocolatey
56M	venv/lib/python3.11/site-packages/ansible_collections/cisco
296K	venv/lib/python3.11/site-packages/ansible_collections/cloud
440K	venv/lib/python3.11/site-packages/ansible_collections/cloudscale_ch
80M	venv/lib/python3.11/site-packages/ansible_collections/community
1.2M	venv/lib/python3.11/site-packages/ansible_collections/containers
864K	venv/lib/python3.11/site-packages/ansible_collections/cyberark
21M	venv/lib/python3.11/site-packages/ansible_collections/dellemc
13M	venv/lib/python3.11/site-packages/ansible_collections/f5networks
121M	venv/lib/python3.11/site-packages/ansible_collections/fortinet
428K	venv/lib/python3.11/site-packages/ansible_collections/frr
180K	venv/lib/python3.11/site-packages/ansible_collections/gluster
9.6M	venv/lib/python3.11/site-packages/ansible_collections/google
288K	venv/lib/python3.11/site-packages/ansible_collections/grafana
1.2M	venv/lib/python3.11/site-packages/ansible_collections/hetzner
900K	venv/lib/python3.11/site-packages/ansible_collections/hpe
2.3M	venv/lib/python3.11/site-packages/ansible_collections/ibm
616K	venv/lib/python3.11/site-packages/ansible_collections/infinidat
816K	venv/lib/python3.11/site-packages/ansible_collections/infoblox
3.8M	venv/lib/python3.11/site-packages/ansible_collections/inspur
5.7M	venv/lib/python3.11/site-packages/ansible_collections/junipernetworks
1.9M	venv/lib/python3.11/site-packages/ansible_collections/kubernetes
712K	venv/lib/python3.11/site-packages/ansible_collections/lowlydba
1.2M	venv/lib/python3.11/site-packages/ansible_collections/mellanox
14M	venv/lib/python3.11/site-packages/ansible_collections/netapp
3.6M	venv/lib/python3.11/site-packages/ansible_collections/netapp_eseries
2.0M	venv/lib/python3.11/site-packages/ansible_collections/netbox
2.7M	venv/lib/python3.11/site-packages/ansible_collections/ngine_io
3.2M	venv/lib/python3.11/site-packages/ansible_collections/openstack
232K	venv/lib/python3.11/site-packages/ansible_collections/openvswitch
4.7M	venv/lib/python3.11/site-packages/ansible_collections/ovirt
5.0M	venv/lib/python3.11/site-packages/ansible_collections/purestorage
1.5M	venv/lib/python3.11/site-packages/ansible_collections/sensu
728K	venv/lib/python3.11/site-packages/ansible_collections/splunk
1.1M	venv/lib/python3.11/site-packages/ansible_collections/t_systems_mms
2.2M	venv/lib/python3.11/site-packages/ansible_collections/theforeman
4.3M	venv/lib/python3.11/site-packages/ansible_collections/vmware
628K	venv/lib/python3.11/site-packages/ansible_collections/vultr
4.9M	venv/lib/python3.11/site-packages/ansible_collections/vyos
1.8M	venv/lib/python3.11/site-packages/ansible_collections/wti
406M	total
```

### BUGS/TODO

* Only works for ansible 5+
* Use python version in deps and check if venv python satisfies that
