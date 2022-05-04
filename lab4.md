# Workshop Lab 4

## External Pillar and Targeting

### Create extpillar CSV

While pillar information can come from a number of places, in this lab let's manage a source of extpillar information to underscore the ability to integrate with a CMDB such as Netbox.  In particular, given a sufficiently large operating environment and quantity of operators, the ability to maintain a centralized source of truth for machine configurations becomes increasingly important, and increasingly more difficult to implement over time if you have not already done so.

Though a spreadsheet (CSV in this case) is not the ideal CMDB, for practical purposes it's more than we have in most environments, so let's start here.

Salt's csvpillar module expects to provide pillar information in columnar format according to the explicit minion ID provided in the first column.  The first row, then, defines key names for the data in the subsequent records.

Insert csv file into `/opt/pillar.csv`:

```
id,role,secret
lab0-minion1,web,IAmAWebserver
lab0-minion2,lb,IAmALoadBalancer
```

__Note:__ As with all sources of pillar data, it is imperative that you maintain strict control over the identity of this pillar file.  While grain data can be modified by the individual minion, in the salt context only the master and targeted minion should know this pillar data.  To keep it that way, ensure (for example) that all contents of `/srv/pillar` as well as any extpillar sources, are readable only to root and are not replicated elsewhere.

### Supply Extpillar configuration

Now we need to configure the master to look at the CSV for pillar data.

The `ext_pillar` master opt defines the identity of external pillar modules that should be employed, and their properties.  See reference for the csvpillar pillar module (https://docs.saltproject.io/en/latest/ref/pillar/all/salt.pillar.csvpillar.html).

Let's add our configuration in `/etc/salt/master.d/extpillar.conf`:

```
ext_pillar:
  - csv: /opt/pillar.csv
```

Now, in order for the master to begin using the pillar module, it is recommended to restart the salt-master service with:

`systemctl restart salt-master`

### Confirm the presence of pillar information

You should now be able to retrieve pillar data as seen by individual minions.  Let's look at the entire pillar contents for minion1:

`salt \*minion1 pillar.items`

```
lab0-minion1:
    ----------
    id:
        lab0-minion1
    role:
        web
    secret:
        IAmAWebserver
```

It's important to point out that in some cases, the minion may not have refreshed its full cache of pillar information.  In order to do this and confirm with subsequent steps, compel the minion(s) to refresh their pillar data:

`salt \* saltutil.refresh_pillar`

```
lab0-minion1:
    True
lab0-minion2:
    True
```

You should now be able to request specific pieces of pillar information from minions:

`salt \*minion1 pillar.item secret`:

```
lab0-minion1:
    ----------
    secret:
        IAmAWebserver
```

### Practical Application

It's important to remember that pillar data runs through an extra round of encryption to maintain privacy of the data between the master and individual minions.  Thus, while it is an excellent way to provide personalized information to minions, it is important not to overuse this.  Considerable sprawl (in conventional file_roots pillar usage, >thousands of pillar files) becomes cryptographically expensive as pillar is rendered for individual minions.  However, when performing operations such as determining which machines should have implicit access to secret information, it's beneficial and recommendable to define access according to certain pillar data, as there is no way for a minion to define its own pillar information.

Let's say we now want to define a specific target using the `role` pillar data we populated.

`salt -I 'role:web' pillar.item secret`

```
lab0-minion1:
    ----------
    secret:
        IAmAWebserver
```

While this isn't groundbreaking, it's important that we know we're able to target machines by a piece of information they already have that cannot be manipulated on the local minion.  As a result, when we later need to be able to determine which devices have access to particular secrets (database passwords, vault tokens, etc), we can rely on a method that prevents undue disclosure of information.

__Note:__ Pillar targeting DOES expose the used pillar key and value to everyone subscribed to the event bus.  Keep this in mind; use nonprivate pillar data to do your targeting (target using explicit identifying information, not using protected information).

#### See more on the usage of extpillar such as Netbox:

https://docs.saltproject.io/en/latest/ref/pillar/all/salt.pillar.netbox.html