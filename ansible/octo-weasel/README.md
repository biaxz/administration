## Octo-Weasel - automated performance measuring

Create a file called `hosts` and put the address of the server in there:

```
[performance]
1.2.3.4
```

Provisioning of the server:

```
$ ansible-playbook playbook.yml -i hosts
```

Run the tests:

```
ssh 1.2.3.4
/root/run-performance-test.sh
```

Test results can be found in `/tmp/performance-tests` and have the time stamp of the start in it's name.

Parse the query log (will print not parseable lines and write the result to `results.json`):

```
cd /root
php process.php /PATH/TO/QUERY.log results.json
```