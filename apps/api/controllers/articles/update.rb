module Api
  module Controllers
    module Articles
      class Update
        include Api::Action

        def call(params)
          self.body = 'OK'
        end
      end
    end
  end
end
