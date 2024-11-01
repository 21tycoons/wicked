module Magician::Controller::Concerns::Steps
  PROTECTED_STEPS = [Magician::FINISH_STEP, Magician::FIRST_STEP,
                     Magician::MIDDLE_STEP, Magician::LAST_STEP]

  extend ActiveSupport::Concern

  def jump_to(go_to_step, options = {})
    @skip_to_step           = go_to_step
    @magician_redirect_params = options
  end

  def skip_step(options = {})
    @skip_to_step           = @next_step
    @magician_redirect_params = options
  end

  def step
    @step
  end

  # will return true if step passed in is the currently rendered step
  def current_step?(step_name)
    return false unless current_and_given_step_exists?(step_name)
    step == step_name
  end

  # will return true if the step passed in has already been executed by the wizard
  def past_step?(step_name)
    return false unless current_and_given_step_exists?(step_name)
    current_step_index > step_index_for(step_name)
  end

  # will return true if the step passed in has not been executed by the wizard
  def future_step?(step_name)
    return false unless current_and_given_step_exists?(step_name)
    current_step_index < step_index_for(step_name)
  end

  # will return true if the last step is the step passed in
  def previous_step?(step_name)
    return false unless current_and_given_step_exists?(step_name)
    (current_step_index - 1)  == step_index_for(step_name)
  end

  # will return true if the next step is the step passed in
  def next_step?(step_name)
    return false unless current_and_given_step_exists?(step_name)
    (current_step_index + 1)  == step_index_for(step_name)
  end

  module ClassMethods
    def steps(*args)
      options = args.extract_options!
      steps   = args
      check_protected!(steps)
      prepend_before_action(options) do
        self.steps = steps.dup
      end
    end

    def check_protected!(wizard_steps)
      string_steps = wizard_steps.map(&:to_s)
      if protected_step = PROTECTED_STEPS.detect { |protected| string_steps.include?(protected) }
        msg = "Protected step detected: '#{protected_step}' is used internally by Wicked please rename your step"
        raise Magician::ProtectedStepError, msg
      end
    end
  end

  def steps=(wizard_steps)
    @wizard_steps = wizard_steps
  end

  def steps
    @wizard_steps
  end
  alias :wizard_steps :steps
  alias :steps_list   :steps

  def previous_step(current_step = nil)
    return @previous_step if current_step.nil?
    index =  steps.index(current_step)
    step  =  steps.at(index - 1) if index.present? && index != 0
    step ||= steps.first
  end

  def next_step(current_step = nil)
    return @next_step if current_step.nil?
    index = steps.index(current_step)
    step  = steps.at(index + 1) if index.present?
    step  ||= Magician::FINISH_STEP
  end

  private

    def step_index_for(step_name)
      steps.index(step_name)
    end

    def current_step_index
      step_index_for(step)
    end

    def current_and_given_step_exists?(step_name)
      current_step_index.present? && steps.index(step_name).present?
    end
end
