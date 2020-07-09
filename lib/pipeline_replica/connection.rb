# frozen_string_literal: true

module PipelineReplica
  class Connection
    attr_reader :pl_replica

    def initialize(environment)
      host, database =
        if environment.eql?(:production)
          [PL_PROD_DB_HOST, 'jnswire_prod']
        else
          [PL_STAGE_DB_HOST, 'jnswire_staging']
        end
      pl_user = MiniLokiC.read_ini['pl_user']

      @pl_replica = PipelineReplica::Mysql.on(host, database, pl_user['user'], pl_user['password'])
    end

    def close
      @pl_replica.close
    end
  end
end
