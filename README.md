Kaspersky Endpoint Security Linux (re)installation.
=======================================================================

General instructions:
-------------
1. Install the `ansible` package with your package manager
2. Clone this git repository: `git clone https://github.com/comexr/kesl-installer.git`
3. Enter the directory: `cd kesl-installer`
4. Execute the script: `ansible-playbook playbook.yml`

Ubuntu one-liner:
-------------
```
sudo apt install -y ansible git && git clone https://github.com/comexr/kesl-installer.git && cd kesl-installer && ansible-playbook playbook.yml
```
