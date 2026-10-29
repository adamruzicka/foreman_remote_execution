# frozen_string_literal: true

require 'test_plugin_helper'

class ExecutionActionTest < ActiveSupport::TestCase
  class AlternativeAction; end

  test 'providers use the existing aggregate action by default' do
    assert_equal Actions::RemoteExecution::RunHostsJob,
      RemoteExecutionProvider.execution_action(stub)
  end

  test 'the composer triggers the action selected by the provider' do
    job_invocation = stub
    provider = mock('provider')
    provider.expects(:execution_action).with(job_invocation).returns(AlternativeAction)
    template = stub(:provider => provider)
    invocation = stub(:template => template)
    invocations = [invocation]
    job_invocation.stubs(:pattern_template_invocations).returns(invocations)

    composer = JobInvocationComposer.allocate
    composer.stubs(:job_invocation).returns(job_invocation)
    composer.stubs(:generate_description)
    composer.stubs(:save).returns(true)
    triggering = mock('triggering')
    composer.stubs(:triggering).returns(triggering)
    triggering.expects(:trigger).with(AlternativeAction, job_invocation)

    composer.trigger
  end

  test 'mixed-provider invocations retain the default aggregate action' do
    providers = [mock('first provider'), mock('second provider')]
    invocations = providers.map { |provider| stub(template: stub(provider: provider)) }
    job_invocation = stub(pattern_template_invocations: invocations)
    composer = JobInvocationComposer.allocate
    composer.stubs(:job_invocation).returns(job_invocation)
    composer.stubs(:generate_description)
    composer.stubs(:save).returns(true)
    triggering = mock('triggering')
    composer.stubs(:triggering).returns(triggering)
    triggering.expects(:trigger).with(Actions::RemoteExecution::RunHostsJob, job_invocation)
    providers.each { |provider| provider.expects(:execution_action).never }

    composer.trigger
  end
end
