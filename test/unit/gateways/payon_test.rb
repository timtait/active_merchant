require_relative '../../test_helper'
require 'mocha/test_unit'

class PayonTest < Test::Unit::TestCase

  @@success_message = { 
    'CONNECTOR_TEST' => "Successful Processing - Request successfully processed in 'Merchant in Connector Test Mode'",
    'INTEGRATOR_TEST' => "Successful Processing - Request successfully processed in 'Merchant in Integrator Test Mode'",
  }

  def setup
    @gateway = PayonGateway.new(fixtures(:payon))
    @gateway.logger = Logger.new(STDOUT) 
    @gateway.logger.level = Logger::DEBUG

    @credit_card = credit_card('4200000000000000', month: 05, year: 2022)
    @declined_card = credit_card('4444444444444444', month: 05, year: 2022)
    @mode = 'CONNECTOR_TEST'
    set_options
  end

  def test_failed_purchase
    @gateway.expects(:ssl_post).returns(failed_purchase_response)

    response = @gateway.purchase(@amount, @credit_card, @options)
    assert_failure response
  end

  def test_successful_purchase
    @gateway.expects(:ssl_post).returns(successful_purchase_response)

    response = @gateway.purchase(@amount, @credit_card, @options)
    assert_success response

    assert_equal @@success_message[@mode], response.message
    assert response.test?
  end

private
  def test_successful_authorize
  end

  def test_failed_authorize
  end

  def test_successful_capture
  end

  def test_failed_capture
  end

  def test_successful_refund
  end

  def test_failed_refund
  end

  def test_successful_void
  end

  def test_failed_void
  end

  def test_successful_verify
  end

  def test_successful_verify_with_failed_void
  end

  def test_failed_verify
  end


  def successful_purchase_response
    "PROCESSING.RISK_SCORE=100&P3.VALIDATION=ACK&NAME.GIVEN=blabla&CLEARING.DESCRIPTOR=6311.1334.3650+activeMerchant+Order+Number+1920.6604516506195&PROCESSING.CONNECTORDETAIL.ConnectorTxID3=26K00001&PROCESSING.CONNECTORDETAIL.ConnectorTxID1=261858&TRANSACTION.CHANNEL=8a8294174725bf9a01472662d87a0169&PROCESSING.REASON.CODE=00&ADDRESS.CITY=Munich&FRONTEND.REQUEST.CANCELLED=false&PROCESSING.CODE=CC.DB.90.00&PROCESSING.REASON=Successful+Processing&FRONTEND.MODE=DEFAULT&CLEARING.FXSOURCE=INTERN&CLEARING.AMOUNT=1.50&PROCESSING.RESULT=ACK&NAME.SALUTATION=NONE&PRESENTATION.USAGE=Order+Number+1920.6604516506195&POST.VALIDATION=ACK&CLEARING.CURRENCY=EUR&FRONTEND.SESSION_ID=&PROCESSING.STATUS.CODE=90&PRESENTATION.CURRENCY=EUR&PAYMENT.CODE=CC.DB&PROCESSING.RETURN.CODE=000.100.112&CONTACT.IP=88.77.23.45&NAME.FAMILY=Longsen&PROCESSING.STATUS=NEW&FRONTEND.CC_LOGO=images%2Fvisa_mc.gif&PRESENTATION.AMOUNT=1.50&IDENTIFICATION.UNIQUEID=8a82944947582925014759da7b6c4387&IDENTIFICATION.TRANSACTIONID=Ruby-RemoteTest+140596179581.7898&IDENTIFICATION.SHORTID=6311.1334.3650&CLEARING.FXRATE=1.0&PROCESSING.TIMESTAMP=2014-07-21+16%3A56%3A36&ADDRESS.COUNTRY=DE&ADDRESS.STATE=BY&RESPONSE.VERSION=1.0&TRANSACTION.MODE=CONNECTOR_TEST&TRANSACTION.RESPONSE=SYNC&PROCESSING.RETURN=Request+successfully+processed+in+%27Merchant+in+Connector+Test+Mode%27&ADDRESS.STREET=Leopoldstr.+1&CLEARING.FXDATE=2014-07-21+16%3A56%3A36&ADDRESS.ZIP=80798"    
    
=begin    
    %(
      Easy to capture by setting the DEBUG_ACTIVE_MERCHANT environment variable
      to "true" when running remote tests:

      $ DEBUG_ACTIVE_MERCHANT=true ruby -Itest \
        test/remote/gateways/remote_payon_test.rb \
        -n test_successful_purchase
    )
=end    
  end

  def failed_purchase_response
    "TRANSACTION.CHANNEL=8a8294174725bf9a01472662d87a0169&PRESENTATION.CURRENCY=EUR&IDENTIFICATION.UNIQUEID=8a82944a475852dc01475fa95e497177&PAYMENT.CODE=CC.DB&FRONTEND.CC_LOGO=images%2Fvisa_mc.gif&PROCESSING.STATUS=REJECTED_VALIDATION&ADDRESS.STREET=Leopoldstr.+1&CONTACT.IP=178.10.199.190&FRONTEND.MODE=DEFAULT&FRONTEND.REQUEST.CANCELLED=false&PROCESSING.RETURN=invalid+creditcard%2C+bank+account+number+or+bank+name&PROCESSING.REASON=Account+Validation&ADDRESS.STATE=BY&PROCESSING.STATUS.CODE=70&TRANSACTION.MODE=CONNECTOR_TEST&POST.VALIDATION=ACK&PROCESSING.TIMESTAMP=2014-07-22+20%3A00%3A41&NAME.GIVEN=Longbob&ADDRESS.CITY=Munich&PROCESSING.RETURN.CODE=100.100.101&RESPONSE.VERSION=1.0&TRANSACTION.RESPONSE=SYNC&P3.VALIDATION=ACK&PROCESSING.CODE=CC.DB.70.40&FRONTEND.SESSION_ID=&PROCESSING.REASON.CODE=40&NAME.FAMILY=Longsen&PRESENTATION.USAGE=Order+Number+468.64471554756165&IDENTIFICATION.SHORTID=2415.3695.0946&NAME.SALUTATION=NONE&PROCESSING.RESULT=NOK&PRESENTATION.AMOUNT=1.50&IDENTIFICATION.TRANSACTIONID=Ruby-RemoteTest+140605924064.47388&ADDRESS.COUNTRY=DE&ADDRESS.ZIP=80798"
  end

  def successful_authorize_response
  end

  def failed_authorize_response
  end

  def successful_capture_response
  end

  def failed_capture_response
  end

  def successful_refund_response
  end

  def failed_refund_response
  end

  def successful_void_response
  end

  def failed_void_response
  end

  def set_options
      @options['TRANSACTION.MODE'] = @mode
      @options['PRESENTATION.USAGE'] = "Order Number #{Time.now.to_f.divmod(2473)[1]}"
      @options['IDENTIFICATION.TRANSACTIONID'] = "Ruby-RemoteTest #{Time.now.to_f * 100}"
      @options[:address] = {
        :street => "Leopoldstr. 1",
        :zip => "80798",
        :city => "Munich",
        :state => "BY",
        :country => "DE",
      }
  end
end
