# Should be removed once https://github.com/SchemaPlus/schema_plus_core/issues/22 is fixed

module SchemaPlus
  module Core
    class SchemaDump
      class Table < KeyStruct[:name, :pname, :options, :columns, :indexes, :statements, :trailer, :alt]
        def options
          @options
        end

        def build_value_option(key, value)
          if value.is_a?(Symbol)
            value = ":#{value}"
          else
            value = "%q{#{value}}"
          end

          "#{key}: #{value}"
        end

        def options=(values)
          if values.present?
            hash = eval("{#{values}}")

            hash.delete(:id)
            hash.delete(:default)

            values = hash.map { |k,v| build_value_option(k, v) }.join(", ")
          end

          @options = values
        end
      end
    end
  end
end
