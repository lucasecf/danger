# http://devcenter.bitrise.io/docs/available-environment-variables
require "danger/request_sources/github/github"
require "danger/request_sources/gitlab"

module Danger
  # ### CI Setup
  #
  # Add a script step to your workflow:
  #
  # ```yml
  # - script@1.1.2:
  #     inputs:
  #    - content: |-
  #        bundle install
  #        bundle exec danger
  # ```
  #
  # ### Token Setup
  #
  # Add the `DANGER_GITHUB_API_TOKEN` to your workflow's [Secret App Env Vars](https://blog.bitrise.io/anyone-even-prs-can-have-secrets).
  #
  # ### bitbucket server and bitrsie
  #
  # Danger will read the environment variable GIT_REPOSITORY_URL to construct the Bitbucket Server API URL 
  # finding the project and repo slug in the GIT_REPOSITORY_URL variable. This GIT_REPOSITORY_URL variable 
  # comes from the App Settings tab for your Bitrsie App. If you are manually setting a repo URL in the 
  # Git Clone Repo step, you may need to set adjust this propery in the settings tab, maybe even fake it.
  # The patterns used are `(%r{\.com/(.*)})` and `(%r{\.com:(.*)})` and .split(/\.git$|$/) to remove ".git" if the URL contains it.  
  #
  class Bitrise < CI
    def self.validates_as_ci?(env)
      env.key? "BITRISE_IO"
    end

    def self.validates_as_pr?(env)
      return !env["BITRISE_PULL_REQUEST"].to_s.empty?
    end

    def supported_request_sources
      @supported_request_sources ||= [
        Danger::RequestSources::GitHub,
        Danger::RequestSources::GitLab,
        Danger::RequestSources::BitbucketServer,
        Danger::RequestSources::BitbucketCloud
      ]
    end

    def initialize(env)
      self.pull_request_id = env["BITRISE_PULL_REQUEST"]
      self.repo_url = env["GIT_REPOSITORY_URL"]
      
      matcher_url = self.repo_url
      self.repo_slug = repo_slug_from(self.repo_url)
    end

    def repo_slug_from(url)
      begin
        # Try to pars the URL as a valid URI. This should cover the cases of http/https/ssh URLs.
        uri = URI.parse(url)
        return uri.path.delete_prefix("/").delete_suffix(".git")
      rescue URI::InvalidURIError
        # In case of invalid URI try the parse as a git URL. git@github.com:organization/repo.git
        matcher_url = url
        repo_matches = matcher_url.match(%r{([\/:])(([^\/]+\/)+[^\/]+?)(\.git$|$)})[2]
        return repo_matches unless repo_matches.nil?
      end
    end
  end
end
