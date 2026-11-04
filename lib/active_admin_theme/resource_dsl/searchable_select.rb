module ActiveAdminTheme
  module SearchableSelect
    # searchable_select_options(:customers, scope: -> { Customer.all }, label: :name, search: :name_cont, per_page: 25)
    #
    # Adds a collection action `<name>_options` to the resource. It answers
    # GET ?term=foo&page=2 with {results: [{id:, text:}], has_more: true} and
    # serves the `searchable_select` form and filter inputs. Extra `q[...]`
    # params are applied as Ransack filters, which is how a dependent select
    # sends its parent's value.
    module ResourceDSL
      # name:     the source's name, `all` by default; the action is `<name>_options`.
      # scope:    lambda run in the controller, defaults to the resource's scoped_collection.
      # label:    method name or lambda(record); defaults to the first of Formtastic's label methods the record has.
      # search:   Ransack predicate (:name_cont) or lambda(scope, term); defaults to a *_cont on the first label column.
      # value:    method name or lambda(record) for the option value, `id` by default.
      # order:    anything `reorder` takes, or lambda(scope); defaults to the label column, then the primary key.
      # per_page: page size.
      def searchable_select_options(name = :all, scope: nil, label: nil, search: nil, value: :id, order: nil, per_page: 25)
        source = {action: :"#{name}_options", scope:, label:, search:, value:, order:, per_page:}
        config.searchable_select_sources[name.to_sym] = source

        collection_action source[:action], method: :get do
          authorize! ActiveAdmin::Authorization::READ, active_admin_config.resource_class
          render json: ActiveAdminTheme::SearchableSelect.page(self, source)
        end
      end
    end

    module ResourceExtension
      def searchable_select_sources
        @searchable_select_sources ||= {}
      end

      def searchable_select_path(name = :all)
        source = searchable_select_sources[name.to_sym]
        raise ArgumentError, "#{resource_name} has no searchable_select_options :#{name}" unless source

        "#{route_collection_path}/#{source[:action]}"
      end
    end

    class << self
      # Runs inside the resource controller's collection action.
      def page(controller, source)
        params = controller.params
        authorization = controller.send(:active_admin_authorization)
        scope = source[:scope] ? controller.instance_exec(&source[:scope]) : controller.send(:scoped_collection)
        scope = authorization.scope_collection(scope, ActiveAdmin::Authorization::READ)
        scope = scope.all
        klass = scope.klass
        filters = params[:q].respond_to?(:to_unsafe_h) ? params[:q] : {}
        scope = scope.ransack(filters, auth_object: authorization).result

        term = params[:term].to_s.strip
        scope = apply_search(controller, scope, klass, source, term, authorization) if term.present?
        scope = apply_order(controller, scope, klass, source)

        per_page = source[:per_page]
        page = [params[:page].to_i, 1].max
        records = scope.offset((page - 1) * per_page).limit(per_page + 1).to_a
        {
          results: records.first(per_page).map { |record| {id: call(controller, source[:value], record), text: label(controller, source, record).to_s} },
          has_more: records.size > per_page
        }
      end

      private

      def label_methods
        Formtastic::FormBuilder.collection_label_methods
      end

      def label_column(klass, source)
        names = [source[:label], *label_methods].select { |name| name.is_a?(Symbol) || name.is_a?(String) }
        names.find { |name| klass.column_names.include?(name.to_s) }
      end

      def label(controller, source, record)
        return call(controller, source[:label], record) if source[:label]

        call(controller, label_methods.find { |name| record.respond_to?(name) }, record)
      end

      def call(controller, method_or_proc, record)
        method_or_proc.respond_to?(:call) ? controller.instance_exec(record, &method_or_proc) : record.public_send(method_or_proc)
      end

      def apply_search(controller, scope, klass, source, term, authorization)
        search = source[:search]
        return controller.instance_exec(scope, term, &search) if search.respond_to?(:call)

        unless search
          column = label_column(klass, source)
          raise ArgumentError, "searchable_select_options for #{klass.name} needs search:, none of #{label_methods.join(", ")} is a column" unless column

          search = "#{column}_cont"
        end
        scope.ransack({search => term}, auth_object: authorization).result
      end

      def apply_order(controller, scope, klass, source)
        order = source[:order]
        return controller.instance_exec(scope, &order) if order.respond_to?(:call)
        return scope.reorder(order) if order

        column = label_column(klass, source)
        scope.reorder((column ? {column.to_s => :asc} : {}).merge(klass.primary_key => :asc))
      end
    end
  end
end

ActiveAdmin::Resource.include ActiveAdminTheme::SearchableSelect::ResourceExtension
ActiveAdmin::ResourceDSL.include ActiveAdminTheme::SearchableSelect::ResourceDSL
