module FastlaneCI
  # Represents a build, part of a project, usually many builds per project
  # One build is identified using the `build.project.id` + `build.number`
  class Build
    # Note, BUILD_STATUSES determine how a build is persisted and how the information is pushed to remote.
    # Example: on success/failure/pending, we automatically update status local + remote
    # With missing_fastfile, we ultimately set a `:failure` when we send a status update to github
    BUILD_STATUSES = [
      :success,
      :pending,
      :missing_fastfile,
      :failure,
      :ci_problem
    ]

    # A reference to the project this build is associated with
    attr_reader :project

    # @return [Integer]
    attr_reader :number

    # @return [String]
    attr_reader :status

    # @return [DateTime] Start time
    attr_reader :timestamp

    # @return [Integer]
    attr_accessor :duration

    # @return [String] The git sha of the commit this build was run for
    attr_reader :sha

    # @return [Array(Artifact)] The artifacts generated by the build.
    attr_accessor :artifacts

    # @return [String] An optional message to go along with the build, will show up as part of the build status on
    # GitHub
    attr_accessor :description

    # @return [String] the trigger type that triggered this particular build
    attr_accessor :trigger

    # The attributes below are relevant to be stored, as it might change in the course of a project
    # and we want the ability to re-trigger historic builds

    # @return [String] the lane name (without platform) that was used for this particular build
    attr_accessor :lane

    # @return [String] the platform name (without lane) that was used for this particular build
    attr_accessor :platform

    # @return [Hash] the parameters that were passed on this particular build
    # TODO: We currently don't use/store/support parameters (yet) https://github.com/fastlane/ci/issues/783
    attr_accessor :parameters

    # @return [String] contains all information to check out that specific remote, branch, sha, ref again
    #                  this information will be used when re-running an old build
    #                  see https://github.com/fastlane/ci/issues/481 for more details
    attr_accessor :git_fork_config

    def initialize(
      project: nil,
      number: nil,
      status: nil,
      timestamp: nil,
      duration: nil,
      sha: nil,
      description: nil,
      trigger: nil,
      lane: nil,
      platform: nil,
      parameters: nil,
      git_fork_config: nil
    )
      @project = project
      @number = number
      @status = status
      @timestamp = timestamp
      @duration = duration
      @sha = sha
      @artifacts = []
      @description = description
      @trigger = trigger
      @lane = lane
      @platform = platform
      @parameters = parameters
      @git_fork_config = git_fork_config
    end

    # Most cases we don't want people doing this, but there are a couple valid reasons, make it explicit
    def update_project!(new_project)
      @project = new_project
    end

    def status=(new_value)
      return if new_value.nil? # as during init we might init with 0 when filling in JSON values
      new_value = new_value.to_sym
      raise "Invalid build status '#{new_value}'" unless BUILD_STATUSES.include?(new_value)
      @status = new_value
    end

    def link_to_remote_commit
      project.repo_config.link_to_remote_commit(sha)
    end

    # This method will return the branch name (if available)
    # and automatically fallback to the short (8 char) git sha. Either way
    # you'll have something nice to show to the user
    def human_friendly_branch_information
      # TODO: self.git_fork_config will never be `nil`, this is just here to be
      #       "backwards compatibile" for now. Let's remove this with the launch
      #       of fastlane.ci Beta. The `.branch` check must still be here
      if git_fork_config && git_fork_config.branch.to_s.length > 0
        return git_fork_config.branch
      end

      return sha[0...7]
    end
  end
end
