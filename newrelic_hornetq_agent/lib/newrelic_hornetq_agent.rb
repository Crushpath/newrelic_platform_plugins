#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
require "newrelic_plugin"
require 'open3'

module NewRelicHornetQAgent

  VERSION = '1.1.0'

  class Agent < NewRelic::Plugin::Agent::Base

    agent_guid "com.crowdflower.HornetQ"
    agent_config_options :java, :javaopts, :jarname, :jarfile, :jmxrmi
    agent_version NewRelicHornetQAgent::VERSION
    agent_human_labels("HornetQ") { ident }

    attr_reader :ident

    def setup_metrics
    end

    def poll_cycle
      raise "JMX RMI URL " if ! jmxrmi
      java = 'java' if ! java
      jarname = "jmxterm-1.0-alpha-4-uber.jar" if ! jarname
      jarfile = "/tmp/#{jarname}" if ! jarfile

      system("cd /tmp; wget http://downloads.sourceforge.net/cyclops-group/#{jarname}") if ! File.exists?(jarfile)

      aggregate_queue_depth = 0
      aggregate_queue_rate = 0

      command = "#{java} #{javaopts} -jar #{jarfile} -l #{jmxrmi} -v silent -n"
      Open3.popen3(command) do |i, o, e, t|
        i.puts "get -b org.hornetq:module=Core,type=Server QueueNames"
        line = o.gets
        o.gets
        if line =~ /^QueueNames = \[ (.*) \];$/
          queues = $1.split(/, */)
          @queue_rates ||= {}
          queues.each do |queue|
            @queue_rates[queue] ||= NewRelic::Processor::EpochCounter.new
            i.puts "get -b org.hornetq:address=\"#{queue}\",module=Core,name=\"#{queue}\",type=Queue MessageCount"
            line = o.gets
            o.gets
            message_count = $1 if line =~ /^MessageCount = (.*);$/
            queue_depth = message_count.to_i.abs
            i.puts "run -b org.hornetq:address=\"#{queue}\",module=Core,name=\"#{queue}\",type=Queue listMessageCounter"
            line = o.gets
            list_message_counter = JSON.parse($1) if line =~ /^(\{.*\})$/
            queue_processed = list_message_counter["count"].to_i.abs

            aggregate_queue_depth += queue_depth
            report_metric "#{queue}/QueueDepth", "Messages", queue_depth
            puts "#{queue}/QueueDepth as Messages => #{queue_depth} [#{queue_processed}]"
            value = @queue_rates[queue].process(queue_processed)
            aggregate_queue_rate += value
            report_metric "#{queue}/QueueRate", "Messages/Second", value
            puts "#{queue}/QueueRate as Messages/Second => #{value}"
          end
        end
      end
      report_metric "Aggregate/QueueDepth", "Messages", aggregate_queue_depth
      puts "Aggregate/QueueDepth as Messages => #{aggregate_queue_depth}"
      report_metric "Aggregate/QueueRate", "Messages/Second", aggregate_queue_rate
      puts "Aggregate/QueueRate as Messages/Second => #{aggregate_queue_rate}"
    end
  end

  # Register and run the agent
  def self.run
    NewRelic::Plugin::Config.config.agents.keys.each do |agent|
      NewRelic::Plugin::Setup.install_agent agent, NewRelicHornetQAgent
    end

    #
    # Launch the agent (never returns)
    #
    NewRelic::Plugin::Run.setup_and_run
  end

end
