module ActiveAdminTheme
  module Inputs
    # f.input :customer, as: :searchable_select
    # filter :customer, as: :searchable_select
    #
    # Renders a <select> holding only the selected record(s); the
    # active_admin_theme/searchable_select module upgrades it and loads the
    # rest from the endpoint of a `searchable_select_options` declaration.
    #
    # Options:
    #   url:                 endpoint (string, or lambda run in the view). Defaults to the
    #                        options action of the association's resource.
    #   resource:            model class or ActiveAdmin resource to take the endpoint (and,
    #                        without an association, the selected records) from.
    #   options_name:        which searchable_select_options to use, :all by default.
    #   placeholder:         text shown while nothing is selected.
    #   depends_on:          input method of the parent select, e.g. :country_id (form) or
    #                        :country_id_eq (filter). The child stays disabled until the
    #                        parent has a value, then sends it as `depends_param`.
    #   depends_param:       query param carrying the parent value, `q[<depends_on>_eq]` by default.
    #   depends_placeholder: text shown while the child waits for its parent.
    module SearchableSelectBehavior
      OPTION_KEYS = %i[url resource options_name placeholder depends_on depends_param depends_placeholder].freeze

      def formtastic_options
        super + OPTION_KEYS
      end

      def input_html_options
        html = super
        html.merge(data: (html[:data] || {}).merge(searchable_select_data))
      end

      # Only the selected records: the rest come from the endpoint, so the
      # association's whole table is never rendered into the page.
      def collection_from_association
        klass = searchable_select_class
        values = Array(object.public_send(input_name)).flatten.compact_blank if object && klass
        return [] if values.blank?

        klass.where(klass.primary_key => values)
      end

      private

      def searchable_select_data
        data = {searchable_select: true, searchable_select_url: searchable_select_url}
        data[:placeholder] = options[:placeholder] if options[:placeholder]
        if (parent = options[:depends_on])
          data[:searchable_select_parent_name] = "#{object_name}[#{parent}]"
          data[:searchable_select_parent_param] = options[:depends_param] || (Ransack::Predicate.detect_from_string(parent.to_s) ? "q[#{parent}]" : "q[#{parent}_eq]")
          data[:searchable_select_parent_placeholder] = options[:depends_placeholder] if options[:depends_placeholder]
        end
        data
      end

      def searchable_select_url
        url = options[:url]
        return template.instance_exec(&url).to_s if url.respond_to?(:call)
        return url.to_s if url

        resource = searchable_select_resource
        raise ArgumentError, "searchable_select input :#{method} needs url: or an association to a registered resource" unless resource

        resource.searchable_select_path(options[:options_name] || :all)
      end

      def searchable_select_resource
        target = options[:resource] || searchable_select_class
        return target if target.is_a?(ActiveAdmin::Resource)

        namespace = template.respond_to?(:active_admin_namespace) ? template.active_admin_namespace : ActiveAdmin.application.namespace(:admin)
        namespace.resource_for(target) if target
      end

      def searchable_select_class
        target = options[:resource]
        return target.resource_class if target.is_a?(ActiveAdmin::Resource)
        return target if target

        reflection.klass if reflection && !reflection.polymorphic?
      end
    end
  end
end

module ActiveAdmin
  module Inputs
    class SearchableSelectInput < ::Formtastic::Inputs::SelectInput
      include ActiveAdminTheme::Inputs::SearchableSelectBehavior
    end

    module Filters
      class SearchableSelectInput < ::ActiveAdmin::Inputs::Filters::SelectInput
        include ActiveAdminTheme::Inputs::SearchableSelectBehavior

        # The filter's `collection` plucks a column's distinct values when there is one.
        def pluck_column
          collection_from_association.map { |record| [send_or_call(label_method, record), send_or_call(value_method, record)] }
        end
      end
    end
  end
end
