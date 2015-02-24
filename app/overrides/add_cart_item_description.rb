Deface::Override.new(:virtual_path => "spree/orders/_line_item",
                         :name => "converted_cart_item_description_722158932",
                         :insert_after => "[data-hook='line_item_description'], #line_item_description[data-hook]",
                         :partial => "spree/orders/cart_item_description")
