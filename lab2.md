# Workshop Lab 2

## States and Rendering

### Create your first state

`/srv/salt/nginx/init.sls`:

```
nginx_installed:
  pkg.installed:
    - name: nginx
```

Run it!
Note that the state system identifies `/srv/salt/nginx/init.sls` identically to `/srv/salt/nginx.sls`:
`salt \*minion1 state.apply nginx`

You should see a list of installed packages followed by a summary looking like this:

```
Summary for lab0-minion1
------------
Succeeded: 1 (changed=1)
Failed:    0
------------
Total states run:     1
Total run time:  38.034 s
```

### Now manage the service

You'll find that the nginx service isn't running yet.  Use either of:
`salt \*minion1 service.status nginx` or
`salt \*minion1 cmd.run 'systemctl status nginx'`

You should see something like:

```
lab0-minion1:
    False
```

or

```
lab0-minion1:
    ----------
    ● nginx.service - The nginx HTTP and reverse proxy server
       Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled
       Active: inactive (dead)
```

Let's modify nginx/init.sls to reflect the state we want the service to be in following installation.

`/srv/salt/nginx/init.sls`:

```
nginx_installed:
  pkg.installed:
    - name: nginx

nginx_running:
  service.running:
    - name: nginx
    - enable: True
```

Apply state again:

`salt \*minion1 state.apply nginx`

Observe that no changes were required for `nginx_installed` to succeed, but changes were made to the service status, including a comment regarding its enabled status:

```
          ID: nginx_running
    Function: service.running
        Name: nginx
      Result: True
     Comment: Service nginx has been enabled, and is running
     Started: 02:44:09.104688
    Duration: 546.007 ms
     Changes:   
              ----------
              nginx:
                  True
```

The summary reflects the number of states that succeeded, as well as the number that required changes in order to succeed.

### A note on idempotence

While salt doesn't directly require idempotence (the property of certain operations by which they can be applies multiple times without changing the result beyond the initial application), the state system thrives on being able to assess whether or not changes are required rather than imperatively carrying out commands regardless of the current system state.

Because it is computationally less expensive to observe that no changes are necessary than to attempt to carry them out anyway, it is possible to write lengthy salt states that assert the a configuration, make changes or additions to the salt state, and carry out the rest of the operation without having to start over every time.  Writing states piecemeal in this manner is a good and healthy practice.

### What about templating?

We don't want to always do the exact same thing to every machine in the environment.  After all, part of salt's responsibility is to abstract a number of system characteristics so that as an operator, I don't have to remember everything about every machine in the environment.  Here we will leverage salt's rendering system to be able to add and manage content that is specific to machines and roles.

Create `/srv/salt/nginx/index.jinja`.  This jinja template will replace the contents of `index.html` (currently located in `/usr/share/nginx/html/index.html`).

Note specifically that our jinja blocks denoted by `{% %}` and `{{ }}` do an amount of assessment of system properties (in this case in the form of examining the minion's `id` grain to determine its minion ID), and then allow us to insert the variable elsewhere.  While in this case we're doing this in HTML, this applies to state files as well.

```
{% set id = salt.grains.get('id') %}
<html>
<head>
<title>Salt Lab Nginx</title>
</head>

<body>
<p>Hello from {{ id }}!</p>
</body>
</html>
```

Before we add this to the nginx configuration, let's ensure that this renders properly and is customized to the machine as we expect it to be.

When invoking these, remember that while you're rendering from the master initially, you will see different results when the minion renders the same data.

`salt-call slsutil.renderer /srv/salt/nginx/index.jinja`

You should see something like:

```
local:
    <html> <head> <title>Salt Lab Nginx</title> </head>
    <body> <p>Hello from lab0-master!</p> </body> </html>
```

(Note there will be some newline interpretation differences when not taking an extra step through the returner and outputter.)

Let's apply this to our nginx configuration:

`/srv/salt/nginx/init.sls`:

```
nginx_installed:
  pkg.installed:
    - name: nginx

nginx_content_present:
  file.managed:
    - name: /usr/share/nginx/html/index.html
    - source: salt://nginx/index.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: nginx_installed

nginx_running:
  service.running:
    - name: nginx
    - enable: True
```

Now apply state with `salt \*minion1 state.apply nginx`.

You'll notice the state run includes a file.managed with an enormous diff (because of the former content), but you should be able to see in the changes dict that the minion has asserted its local understanding of its ID grain.

```
          ID: nginx_content_present
    Function: file.managed
        Name: /usr/share/nginx/html/index.html
      Result: True
     Comment: File /usr/share/nginx/html/index.html updated
     Started: 02:44:08.953205
    Duration: 108.8 ms
     Changes:   
              ----------
              diff:
                 ...
```

### View your handiwork!

By now your machines should be listening on port 80 to present a legitimate and customized web service.  Check your public IP address and browse to the IP:

`salt \*minion1 cmd.run 'curl -s ifconfig.co`

```
lab0-minion1:
    3.138.37.165
```