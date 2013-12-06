## New Relic HornetQ monitoring Plugin

The New Relic HornetQ Plugin enables monitoring of HornetQ, reporting the following data for all queues on a hornetq instance:

* Queue Depth
* Queue Rate

### Requirements

The HornetQ monitoring Plugin for New Relic requires the following:

* A New Relic account. Signup for a free account at http://newrelic.com
* This should be installed and configured to poll a given HornetQ instance. For multiple instances of HornetQ, it is advised to run a local one for each.

### Instructions for running the HornetQ agent

1. Install this gem from RubyGems:

    `sudo gem install newrelic_hornetq_agent`

2. Install config, execute

    `sudo newrelic_hornetq_agent install` - it will create `/etc/newrelic/newrelic_hornetq_agent.yml` file for you.

3. Edit the `/etc/newrelic/newrelic_hornetq_agent.yml` file generated in step 2. 
 
    3.1. replace `YOUR_LICENSE_KEY_HERE` with your New Relic license key. Your license key can be found under Account Settings at https://rpm.newrelic.com, see https://newrelic.com/docs/subscriptions/license-key for more help.

    3.2. add the hornetq connection string: 'hostname:port' or 'service:jmx:rmi:///jndi/rmi://localhost:port/jmxrmi' where port is the JMX port exposed with mbean access

    3.3. add the javaopts for things like SSL cert trust, ie: '-Djavax.net.ssl.trustStore=/etc/ssl/certs/java/hornetq.jks -Djavax.net.ssl.trustStorePassword=yourtrustpassword'

4. Execute

    `newrelic_hornetq_agent run`
  
5. Go back to the Plugins list and after a brief period you will see the HornetQ Plugin listed in your New Relic account


## Keep this process running

You can use services like these to manage this process and run it as a daemon.

- [Upstart](http://upstart.ubuntu.com/)
- [Systemd](http://www.freedesktop.org/wiki/Software/systemd/)
- [Runit](http://smarden.org/runit/)
- [Monit](http://mmonit.com/monit/)

Also you can use [foreman](https://github.com/ddollar/foreman) for daemonization. 

Foreman can be useful if you want to use [Heroku](https://www.heroku.com/) for run your agent. Just add Procfile and push to Heroku. 

`monitor_daemon: newrelic_hornetq_agent run -c config/newrelic_plugin.yml`

## Support

Please use Github issues for support.
