class Commit < ActiveRecord::Base
  belongs_to :stack
  has_many :deploys
  belongs_to :author, class_name: "User"
  belongs_to :committer, class_name: "User"

  def self.from_github(commit, state = nil)
    new(
      :sha       => commit.sha,
      :state     => state,
      :message   => commit.commit.message,
      :author    => User.find_or_create_from_github(commit.author || commit.commit.author),
      :committer => User.find_or_create_from_github(commit.committer || commit.commit.committer),
    )
  end

  def pull_request_url
    "https://github.com/#{stack.repo_owner}/#{stack.repo_name}/pull/#{pull_request_id}"
  end

  def pull_request_id
    parsed && parsed['pr_id']
  end

  def pull_request_title
    parsed && parsed['pr_title']
  end

  def pull_request?
    !!parsed
  end

  def self.from_param(param)
    find_by_sha(sha)
  end

  def to_param
    sha
  end

  def short_sha
    sha[0..9]
  end

  def parsed
    @parsed ||= message.match(/\AMerge pull request #(?<pr_id>\d+) from [\w\/]+\n\n(?<pr_title>.*)/)
  end
end
