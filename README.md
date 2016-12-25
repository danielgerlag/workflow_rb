# WorkflowRb  [![Build Status](https://travis-ci.org/danielgerlag/workflow_rb.svg?branch=master)](https://travis-ci.org/danielgerlag/workflow_rb)

WorkflowRb is a light weight workflow engine for Ruby.  It supports pluggable persistence and concurrency providers to allow for multi-node clusters.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'workflow_rb'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install workflow_rb

## Basic Concepts

### Steps

A workflow consists of a series of connected steps.  Each step produces an outcome value and subsequent steps are triggered by subscribing to a particular outcome of a preceeding step.  The default outcome of *nil* can be used for a basic linear workflow.
Steps are usually defined by inheriting from the StepBody abstract class and implementing the *run* method.  They can also be created inline while defining the workflow structure.

First we define some steps

```ruby
class HelloWorld < WorkflowRb::StepBody
  def run(context)
    puts 'Hello world'
    WorkflowRb::ExecutionResult.NextStep
  end
end
```

Then we define the workflow structure by composing a chain of steps.

```ruby
class HelloWorld_Workflow
  ID = 'hello world'
  VERSION = 1
  DATA_CLASS = nil

  def build(builder)
    builder
        .start_with(HelloWorld)
        .then(GoodbyeWorld)
  end
end

```
The ID and VERSION constants are used to identify the workflow definition. 

You can also define your steps inline

```ruby
class HelloWorld_Workflow
  ID = 'hello world'
  VERSION = 1
  DATA_CLASS = nil

  def build(builder)
    builder
        .start_step do |context|
          puts 'Hello world'
          WorkflowRb::ExecutionResult.NextStep
        end
        .then_step do |context|
          puts 'Goodbye world'
          WorkflowRb::ExecutionResult.NextStep
        end
  end
end

```

Each running workflow is persisted to the chosen persistence provider between each step, where it can be picked up at a later point in time to continue execution.  The outcome result of your step can instruct the workflow host to defer further execution of the workflow until a future point in time or in response to an external event.

The first time a particular step within the workflow is called, the persistence_data property on the context object is *nil*.  The *ExecutionResult* produced by the *run* method can either cause the workflow to proceed to the next step by providing an outcome value, instruct the workflow to sleep for a defined period or simply not move the workflow forward.  If no outcome value is produced, then the step becomes re-entrant by setting persistence_data, so the workflow host will call this step again in the future buy will populate the persistence_data with it's previous value.

For example, this step will initially run with *nil* persistence_data and put the workflow to sleep for 1 hour, while setting the persistence_data to *'something'*.  1 hour later, the step will be called again but context.persistence_data will now contain the object constructed in the previous iteration, and will now produce an outcome value of *nil*, causing the workflow to move forward.

```ruby
class MySleepStep < WorkflowRb::StepBody
  def run(context)
    if context.persistence_data
      WorkflowRb::ExecutionResult.NextStep
    else
      WorkflowRb::ExecutionResult.Sleep(Time.now + 3600, 'something')
    end
  end
end
```

### Passing data between steps

Each step is intended to be a black-box, therefore they support inputs and outputs.  These inputs and outputs can be mapped to a data class that defines the custom data relevant to each workflow instance.

The following sample shows how to define inputs and outputs on a step, it then shows how define a workflow with a typed class for internal data and how to map the inputs and outputs to attributes on the custom data class.

```ruby
# Define some steps
class AddNumbers < WorkflowRb::StepBody
  attr_accessor :input1
  attr_accessor :input2
  attr_accessor :answer

  def run(context)
    @answer = @input1 + @input2
    WorkflowRb::ExecutionResult.NextStep
  end
end

class CustomMessage < WorkflowRb::StepBody
  attr_accessor :message

  def run(context)
    puts @message
    WorkflowRb::ExecutionResult.NextStep
  end
end

# Define a class to hold workflow data
class MyData
  attr_accessor :value1
  attr_accessor :value2
  attr_accessor :value3
end


# Define a workflow to put the steps together
class DataSample_Workflow
  ID = 'data-sample'
  VERSION = 1
  DATA_CLASS = MyData

  def build(builder)
    builder
        .start_with(AddNumbers)
          .input(:input1) {|data| data.value1}
          .input(:input2) {|data| data.value2}
          .output(:value3) {|step| step.answer}
        .then(CustomMessage)
          .input(:message) {|data| "The answer is #{data.value3}"}
  end
end

```

### Multiple outcomes / forking

A workflow can take a different path depending on the outcomes of preceeding steps.  The following example shows a process where first a random number of 0 or 1 is generated and is the outcome of the first step.  Then, depending on the outcome value, the workflow will either fork to (TaskA + TaskB) or (TaskC + TaskD)

```ruby
class RandomStep < WorkflowRb::StepBody
  def run(context)
    WorkflowRb::ExecutionResult.Outcome(rand(2))
  end
end

class ForkSample_Workflow
  ID = 'fork-sample'
  VERSION = 1
  DATA_CLASS = nil

  def build(builder)
    step1 = builder.start_with(RandomStep)
    step1.when(0)
      .then(TaskA)
      .then(TaskB)

    step1.when(1)
      .then(TaskC)
      .then(TaskD)

  end
end
```

### Events

A workflow can also wait for an external event before proceeding.  In the following example, the workflow will wait for an event called *"my-event"* with a key of *0*.  Once an external source has fired this event, the workflow will wake up and continue processing, passing the data generated by the event onto the next step.

```ruby
class EventSample_Workflow
  ID = 'event-sample'
  VERSION = 1
  DATA_CLASS = MyData

  def build(builder)
    builder
        .start_with(HelloWorld)
          .wait_for('my-event', '0')
          .output(:my_value) { |step| step.event_data }
        .then(CustomMessage)
          .input(:message) {|data| "The event data is #{data.my_value}"}
  end
end

...
# External events are published via the host
# All workflows that have subscribed to my-event 0, will be passed "hello"
host.publish_event('my-event', '0', 'hello')
```

### Host

The workflow host is the service responsible for executing workflows.  It does this by polling the persistence provider for workflow instances that are ready to run, executes them and then passes them back to the persistence provider to by stored for the next time they are run.  It is also responsible for publishing events to any workflows that may be waiting on one.


#### Usage

When your application starts, instantiate a *WorkflowHost*, register your workflow definitions and start it  


```ruby
host = WorkflowRb::WorkflowHost.new

# register our workflows with the host
host.register_workflow(HelloWorld_Workflow)

# start the host
host.start

# start a new workflow
host.start_workflow('hello world', 1)

```


### Persistence

Since workflows are typically long running processes, they will need to be persisted to storage between steps.
There are several persistence providers available as seperate gems.

* MemoryPersistenceProvider *(Default provider, for demo and testing purposes)*
* [MongoDB](workflow_rb-mongo)
* [ActiveRecord](workflow_rb-db)

### Multi-node clusters

By default, the WorkflowHost service will run as a single node using the built-in queue and locking providers for a single node configuration.  Should you wish to run a multi-node cluster, you will need to configure an external queueing mechanism and a distributed lock manager to co-ordinate the cluster.  These are the providers that are currently available.

#### Queue Providers

* SingleNodeQueueProvider *(Default built-in provider)*
* RabbitMQ *(coming soon...)*
* Apache ZooKeeper *(coming soon...)*
* 0MQ *(coming soon...)*

#### Distributed lock managers

* SingleNodeLockProvider *(Default built-in provider)*
* Redis Redlock *(coming soon...)*
* Apache ZooKeeper *(coming soon...)*


## Samples

[Hello World](samples/sample01.rb)

[Multiple outcomes](samples/sample06.rb)

[Passing Data](samples/sample02.rb)

[Events](samples/sample04.rb)

[Deferred execution & re-entrant steps](samples/sample05.rb)

## Authors

* **Daniel Gerlag** - *Initial work*

## Ports

[.NET] (https://github.com/danielgerlag/workflow-core)

[Node.js] (https://github.com/danielgerlag/workflow-es)


## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details


