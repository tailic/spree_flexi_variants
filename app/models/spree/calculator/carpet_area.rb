module Spree
  class Calculator::CarpetArea < Calculator
    preference :min_width,              :integer, default: 1
    preference :max_width,              :integer, default: 5

    preference :min_height,             :integer, default: 1
    preference :max_height,             :integer, default: 14

    preference :widths,                 :string,  default: '4,5'
    preference :min_pricing_area,       :integer, default: 1

    preference :overedging_multiplier,  :decimal

    GLATTSCHNITT = :glattschnitt
    RAUMMASS = :raummass
    TYPES = [:glattschnitt, :raummass]

    def self.description
      'Carpet Area Calculator (Based on Price Type)'
    end

    def self.register
      super
      ProductCustomizationType.register_calculator(self)
    end

    def create_options
      [
       CustomizableProductOption.create(name: 'Width',      presentation: 'Width'),
       CustomizableProductOption.create(name: 'Height',     presentation: 'Height'),
       CustomizableProductOption.create(name: 'Type',       presentation: 'Type'),
       CustomizableProductOption.create(name: 'Overedging', presentation: 'Overedging')
      ]
    end

    # as object we always get line items, as calculable we have Coupon, ShippingMethod
    def compute(product_customization, variant = nil)
      unless valid_configuration? product_customization
        set_option(product_customization, 'Width', 0)
        set_option(product_customization, 'Height', 0)
        set_option(product_customization, 'Type', 'Leider gab es einen Fehler bei der Eingabe. Bitte wenden Sie sich an unseren Kundenservice.')
        return 0
      end

      width       = get_option(product_customization, 'Width').value.gsub(',', '.').to_d
      height      = get_option(product_customization, 'Height').value.gsub(',', '.').to_d
      type        = get_option(product_customization, 'Type').value.to_sym
      type        = TYPES.include?(type) ? type : TYPES.first
      overedging  = get_option(product_customization, 'Overedging').try(:value)
      overedging_price = overedging ? (2 * (width + height) * preferred_overedging_multiplier) : 0.00

      price = variant.amount_in(:EUR, Spree::PriceCategory.find_by(name: type))
      base_price = variant.amount_in(:EUR, Spree::PriceCategory.find_by(name: 'glattschnitt'))

      res = [(width * height), (preferred_min_pricing_area || 0)].max * price
      (res - base_price) + overedging_price
    end

    def valid_configuration?(product_customization)
      required = %w(Width Height Type)
      return false if !options_include?(required, product_customization)

      width       = get_option(product_customization, 'Width').value
      height      = get_option(product_customization, 'Height').value
      type        = get_option(product_customization, 'Type').value.to_sym
      overedging  = get_option(product_customization, 'Overedging').try(:value)

      valid_type = TYPES.include?(type)
      return false if !valid_type

      valid_width = if type == GLATTSCHNITT
                      preferred_widths.split(',').map(&:to_d).include? width.gsub(',','.').to_d
                    else
                      width.gsub(',','.').to_d.between? preferred_min_width, preferred_max_width
                    end

      valid_height = height.gsub(',','.').to_d.between? preferred_min_height, preferred_max_height

      return false if !valid_height || !valid_width

      return false if preferred_overedging_multiplier.present? && preferred_overedging_multiplier > 0 && overedging == 1 #prevent overedging if multiplier is 0


      return true
    end


    private
    def options_include?(required, product_customization)
      (required - all_options(product_customization)).empty?
    end

    def all_options(product_customization)
      product_customization.customized_product_options.map {|cpo| cpo.customizable_product_option.name }
    end

    def get_option(product_customization, name)
      product_customization.customized_product_options.detect {|cpo| cpo.customizable_product_option.name == name }
    end

    def set_option(product_customization, name, value)
      product_customization.customized_product_options.detect {|cpo| cpo.customizable_product_option.name == name && cpo.update_attribute(:value, value)}
    end

  end
end
