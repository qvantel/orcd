# Setting up Sphinx environment

```sh
$ apt-get install python-pip
$ pip install virtualenv==15.1.0 
$ virtualenv env # create isolated environment for python
$ source env/bin/activate # Activate it
$ pip install -r requirements.txt # Install the dependencies
$ make html # Assuming you are in the docs folder, create the docs.
```

