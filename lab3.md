# Workshop Lab 3

## Highstate and Topfile

### Create the topfile for the base environment

The topfile describes which salt states should be asserted against machines in our environment.  As with other aspects of salt, the typical targeting and state tree concepts apply here; as a result you can control very granularly which elements of configuration or protected data should be applied to which parts of your environment.

Inside each targeting identifier is the list of states that should be asserted against that target.

`/srv/salt/top.sls`:

```
base:
  '*minion2':
    - nginx
```

### Let's run highstate

We can assert highstate by simply invoking `state.apply` (or `state.sls`) against a target with no additional arguments.

```
salt \*minion2 state.apply
```

You should see the same output we received during the initial installation stages against minion1.  Subsequent state runs should require no new changes.

We can use this to codify the expected configuration of machines in our environment, and, from the perspective of configuration drift, apply highstate as a policy to combat configuration drift on an ongoing basis.