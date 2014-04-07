Deface::Override.new(:virtual_path => "spree/admin/orders/_shipment_manifest",
                     :name => "replace_admin_order_detail_line_item_lookup",
                     :replace => "erb[silent]:contains('find_line_item_by_variant')",
                     :partial => "spree/admin/orders/shipment_manifest_line_item_lookup")