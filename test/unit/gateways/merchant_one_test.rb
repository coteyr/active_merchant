require 'test_helper'

class MerchantOneTest < Test::Unit::TestCase

  def setup
    @gateway = MerchantOneGateway.new(fixtures(:merchant_one))
    @credit_card = credit_card
    @amount = 1000
    @options = {
      :order_id => '1',
      :description => 'Store Purchase',
      :billing_address => {
        :first_name =>'Jim'
        :last_name=> 'Smith',
        :address1 =>'1234 My Street',
        :address2 =>'Apt 1',
        :city =>'Tampa',
        :state =>'FL',
        :zip =>'33603',
        :country =>'US',
        :phone =>'(813)421-4331'
      }
    }
    @subscription_id = '2137540003'
  end

  def test_successful_purchase
    @gateway.expects(:ssl_post).returns(successful_purchase_response)
    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_instance_of Response, response
    assert_success response
    assert_equal "281719471", response.authorization
    assert response.test?, response.test.to_s
  end

  def test_successful_authorize
    @gateway.expects(:ssl_post).returns(successful_purchase_response)
    assert response = @gateway.authorize(@amount, @credit_card, @options)
    assert_instance_of Response, response
    assert_success response
    assert_equal '281719471', response.authorization
    assert response.test?, response.test.to_s
  end

  def test_successful_capture
    @gateway.expects(:ssl_post).returns(successful_purchase_response)
    assert response = @gateway.capture(@amount, '281719471', @options)
    assert_instance_of Response, response
    assert_success response
    assert_equal '281719471', response.authorization
    assert response.test?, response.test.to_s
  end

  def test_unsuccessful_request
    @gateway.expects(:ssl_post).returns(failed_purchase_response)

    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_failure response
    assert response.test?, response.test.to_s
  end

  def test_successful_recurring
    @gateway.expects(:ssl_post).returns(successful_recurring_response)
    response = @gateway.recurring(@amount, @credit_card,
      :billing_address => address.merge(:first_name => 'Jim', :last_name => 'Smith'),
      :interval => {
        :length => 10,
        :unit => :days
      }
   )

    assert_instance_of Response, response
    assert response.success?
    assert response.test?
    assert_equal @subscription_id, response.authorization
  end

  def test_successful_update_recurring
    @gateway.expects(:ssl_post).returns(successful_update_recurring_response)

    response = @gateway.update_recurring(:subscription_id => @subscription_id, :amount => @amount * 2)

    assert_instance_of Response, response
    assert response.success?
    assert response.test?
    assert_equal @subscription_id, response.authorization
  end

  def test_successful_cancel_recurring
    @gateway.expects(:ssl_post).returns(successful_cancel_recurring_response)

    response = @gateway.cancel_recurring(@subscription_id)

    assert_instance_of Response, response
    assert response.success?
    assert response.test?
    assert_equal @subscription_id, response.authorization
  end

#  def test_successful_status_recurring
#
#    @gateway.expects(:ssl_post).returns(successful_status_recurring_response)
#
#    response = @gateway.status_recurring(@subscription_id)
#    assert_instance_of Response, response
#    assert response.success?
#    assert response.test?
#    assert_equal @subscription_status, response.params['status']
#  end

private

  def successful_purchase_response
    "response=1&responsetext=SUCCESS&authcode=123456&transactionid=281719471&avsresponse=&cvvresponse=M&orderid=&type=sale&response_code=100"
  end

  def failed_purchase_response
    "response=3&responsetext=DECLINE&authcode=123456&transactionid=281719471&avsresponse=&cvvresponse=M&orderid=&type=sale&response_code=300"
  end

  def successful_status_recurring_response

  end

  def successful_cancel_recurring_response
    "response=1&responsetext=Recurring Transaction Deleted&authcode=&transactionid=2137540003&avsresponse=&cvvresponse=&orderid=&type=&response_code=100&merchant_defined_field_6=&merchant_defined_field_7=&customer_vault_id="
  end
  def successful_update_recurring_response
    "response=1&responsetext=Subscription Updated&authcode=&transactionid=2137540003&avsresponse=&cvvresponse=&orderid=&type=&response_code=100&merchant_defined_field_6=&merchant_defined_field_7=&customer_vault_id="
  end
  def successful_recurring_response
    "response=1&responsetext=Subscription added&authcode=&transactionid=2137540003&avsresponse=&cvvresponse=&orderid=&type=&response_code=100&merchant_defined_field_6=&merchant_defined_field_7=&customer_vault_id="
  end
end
