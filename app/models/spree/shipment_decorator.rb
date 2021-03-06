Spree::Shipment.class_eval do
  scope :electronic, lambda { where(:shipping_method_id => Spree::ShippingMethod.electronic.id) }
  scope :physical, lambda { where('shipping_method_id != ?', Spree::ShippingMethod.electronic.id) }

  def electronic?
    shipping_method.id == Spree::ShippingMethod.electronic.id
  end

  def electronic_delivery!
    inventory_units.each do |inventory_unit|
      if inventory_unit.license_keys.empty?
        inventory_unit.electronic_delivery_keys.times do
          Spree::LicenseKey.assign_license_keys!(inventory_unit)
        end
        inventory_unit.reload
      end
    end
  end

  # Modified from spree_core
  # This function is modified to ensure that inventory_units are only shipped
  # when they can be shipped
  def after_ship
    # Begin modified code
    inventory_units.each do |iu|
      iu.ship! if iu.can_ship?
    end
    # End modified code

    send_shipped_email
    touch :shipped_at
  end

  # Modified from spree_core
  # This will only send the e-mail if it is not electronic
  def send_shipped_email
    if electronic?
      Spree::EmailDeliveryMailer.send_license_keys(self).deliver if can_email_deliver?
    else
      Spree::ShipmentMailer.shipped_email(self).deliver
    end
  end

  private
  def can_email_deliver?
    inventory_units.all? { |iu| !iu.license_keys.empty? }
  end
end
