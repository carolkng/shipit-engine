module Shipit
  class DeploySpec
    class FileSystem < DeploySpec
      include NpmDiscovery
      include LernaDiscovery
      include PypiDiscovery
      include RubygemsDiscovery
      include CapistranoDiscovery
      include BundlerDiscovery
      include KubernetesDiscovery

      def initialize(app_dir, env)
        @app_dir = Pathname(app_dir)
        @env = env
      end

      def cacheable
        DeploySpec.new(cacheable_config)
      end

      def file(path, root: false)
        if root || directory.blank?
          @app_dir.join(path)
        else
          Pathname.new(File.join(@app_dir, directory, path))
        end
      end

      private

      def cacheable_config
        (config || {}).deep_merge(
          'merge' => {
            'require' => pull_request_required_statuses,
            'ignore' => pull_request_ignored_statuses,
            'revalidate_after' => revalidate_pull_requests_after.try!(:to_i),
            'max_divergence' => {
              'commits' => max_divergence_commits.try!(:to_i),
              'age' => max_divergence_age.try!(:to_i),
            },
          },
          'ci' => {
            'hide' => hidden_statuses,
            'allow_failures' => soft_failing_statuses,
            'require' => required_statuses,
          },
          'machine' => {
            'environment' => discover_machine_env.merge(machine_env),
            'directory' => directory,
            'cleanup' => true,
          },
          'review' => {
            'checklist' => review_checklist,
            'monitoring' => review_monitoring,
            'checks' => review_checks,
          },
          'plugins' => plugins,
          'dependencies' => {'override' => dependencies_steps},
          'deploy' => {
            'override' => deploy_steps,
            'variables' => deploy_variables.map(&:to_h),
            'max_commits' => maximum_commits_per_deploy,
            'interval' => pause_between_deploys,
          },
          'rollback' => {'override' => rollback_steps},
          'fetch' => fetch_deployed_revision_steps,
          'tasks' => cacheable_tasks,
        )
      end

      def cacheable_tasks
        discover_task_definitions.map { |k, c| [k, coerce_task_definition(c)] }.to_h
      end

      def config(*)
        @config ||= load_config
        super
      end

      def load_config
        read_config(file("shipit.#{@env}.yml", root: true)) ||
          read_config(file('shipit.yml', root: true))
      end

      def read_config(path)
        SafeYAML.load(path.read) if path.exist?
      end
    end
  end
end
