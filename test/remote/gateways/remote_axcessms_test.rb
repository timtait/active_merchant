require 'test_helper'

class RemoteAxcessmsTest < Test::Unit::TestCase

  @@success_message = { 
    'CONNECTOR_TEST' => "Successful Processing - Request successfully processed in 'Merchant in Connector Test Mode'",
    'INTEGRATOR_TEST' => "Successful Processing - Request successfully processed in 'Merchant in Integrator Test Mode'",
  }
  
  def setup
    @@stop_auto_run = true
    @gateway = AxcessmsGateway.new(fixtures(:axcessms))
    
    @gateway = AxcessmsGateway.new(
    {
      :sender => "8a8294174725bf9a014726623f190163",
      :login => "8a8294174725bf9a014726623f1b0167",
      :password => "wZ9Fqrhd",
      :channel => "8a8294174725bf9a01472662d87a0169",
    })
    
    
    @gateway.logger = Logger.new(STDOUT) 
    @gateway.logger.level = Logger::DEBUG

    @amount = 150
    @credit_card = credit_card('4200000000000000', month: 05, year: 2022)
    @declined_card = credit_card('4444444444444444', month: 05, year: 2022)
    @mode = 'INTEGRATOR_TEST'
    set_options
  end

  def test_successful_void
    auth = @gateway.authorize(@amount, @credit_card, @options)
    assert_success auth
    @gateway.logger.info("#{__method__.to_s} - message - #{auth.message}, code - #{auth.params['PROCESSING.RETURN.CODE']}")
    assert_equal @@success_message[@mode], auth.message

    assert void = @gateway.void(auth.authorization)
    assert_success void
    @gateway.logger.info("#{__method__.to_s} - message - #{void.message}, code - #{void.params['PROCESSING.RETURN.CODE']}")
    assert_equal @@success_message[@mode], void.message
  end

  def test_successful_refund
    purchase = @gateway.purchase(@amount, @credit_card, @options)
    assert_success purchase
    assert_equal @@success_message[@mode], purchase.message
    @gateway.logger.info("#{__method__.to_s} -  message - #{purchase.message}, code - #{purchase.params['PROCESSING.RETURN.CODE']}")

    assert refund = @gateway.refund(nil, purchase.authorization)
    assert_success refund
    @gateway.logger.info("#{__method__.to_s} - message - #{refund.message}, code - #{refund.params['PROCESSING.RETURN.CODE']}")
    assert_equal @@success_message[@mode], refund.message
  end

  def test_successful_partial_refund
    purchase = @gateway.purchase(@amount, @credit_card, @options)
    assert_success purchase
    @gateway.logger.info("#{__method__.to_s} - message - #{purchase.message}, code - #{purchase.params['PROCESSING.RETURN.CODE']}")
    assert_equal @@success_message[@mode], purchase.message

    assert refund = @gateway.refund(@amount-50, purchase.authorization)
    assert_success refund
    @gateway.logger.info("#{__method__.to_s} - message - #{refund.message}, code - #{refund.params['PROCESSING.RETURN.CODE']}")
    assert_equal @@success_message[@mode], refund.message
    @gateway.logger.info("-------------------------------------------------------------------------------------------------------------------------------------------")
  end

  def test_successful_authorize_and_capture
    auth = @gateway.authorize(@amount, @credit_card, @options)
    assert_success auth
    @gateway.logger.info("#{__method__.to_s} - message - #{auth.message}, code - #{auth.params['PROCESSING.RETURN.CODE']}")
    assert_equal @@success_message[@mode], auth.message

    assert capture = @gateway.capture(nil, auth.authorization)
    @gateway.logger.info("#{__method__.to_s} - message - #{capture.message}, code - #{capture.params['PROCESSING.RETURN.CODE']}")
    assert_success capture
    assert_equal @@success_message[@mode], capture.message
  end

  def test_successful_purchase
    response = @gateway.purchase(@amount, @credit_card, @options)
    assert_success response
    @gateway.logger.info("#{__method__.to_s} - message - #{response.message}, code - #{response.params['PROCESSING.RETURN.CODE']}")

    assert_equal @@success_message[@mode], response.message
  end

  def test_successful_partial_capture
    auth = @gateway.authorize(@amount, @credit_card, @options)
    assert_success auth
    @gateway.logger.info("#{__method__.to_s} - message - #{auth.message}, code - #{auth.params['PROCESSING.RETURN.CODE']}")
    assert_equal @@success_message[@mode], auth.message

    assert capture = @gateway.capture(@amount-30, auth.authorization)
    @gateway.logger.info("#{__method__.to_s} - message - #{capture.message}, code - #{capture.params['PROCESSING.RETURN.CODE']}")
    assert_success capture
    assert_equal @@success_message[@mode], capture.message
  end

  def test_failed_bigger_capture_then_authorised
    auth = @gateway.authorize(@amount, @credit_card, @options)
    assert_success auth
    @gateway.logger.info("#{__method__.to_s} - message - #{auth.message}, code - #{auth.params['PROCESSING.RETURN.CODE']}")

    assert capture = @gateway.capture(@amount+30, auth.authorization)
    @gateway.logger.info("#{__method__.to_s} - message - #{capture.message}, code - #{capture.params['PROCESSING.RETURN.CODE']}")
    assert_failure capture
  end

  def test_failed_capture
    response = @gateway.capture(nil, '')
    @gateway.logger.info("#{__method__.to_s} - message - #{response.message}, code - #{response.params['PROCESSING.RETURN.CODE']}")
    assert_failure response
  end

  def test_failed_capture_wrong_refid
    auth = @gateway.authorize(@amount, @credit_card, @options)
    assert_success auth
    @gateway.logger.info("#{__method__.to_s} - message - #{auth.message}, code - #{auth.params['PROCESSING.RETURN.CODE']}")

    auth.authorization['IDENTIFICATION.UNIQUEID'] += "a" 
    assert capture = @gateway.capture(@amount, auth.authorization)
    @gateway.logger.info("#{__method__.to_s} - message - #{capture.message}, code - #{capture.params['PROCESSING.RETURN.CODE']}")
    assert_failure capture
  end

  def test_failed_refund
    response = @gateway.refund(nil, '')
    @gateway.logger.info("#{__method__.to_s} - message - #{response.message}, code - #{response.params['PROCESSING.RETURN.CODE']}")
    assert_failure response
  end

  def test_failed_void
    response = @gateway.void('')
    @gateway.logger.info("#{__method__.to_s} - message - #{response.message}, code - #{response.params['PROCESSING.RETURN.CODE']}")
    assert_failure response
  end

  def test_failed_purchase
    response = @gateway.purchase(@amount, @declined_card, @options)
    @gateway.logger.info("#{__method__.to_s} - message - #{response.message}, code - #{response.params['PROCESSING.RETURN.CODE']}")
    assert_failure response
    #assert_equal 'REPLACE WITH FAILED PURCHASE MESSAGE', response.message
  end

  def test_invalid_login
    f = Marshal.load(Marshal.dump(@gateway.auth_data))
    f[:password] << "11" 
    g = AxcessmsGateway.new(f)
    g.logger = Logger.new(STDOUT) 
    g.logger.level = Logger::DEBUG
    response = g.purchase(@amount, @credit_card, @options)
    @gateway.logger.info("#{__method__.to_s} - message - #{response.message}, code - #{response.params['PROCESSING.RETURN.CODE']}")
    assert_failure response
  end

  def test_failed_authorize
    response = @gateway.authorize(@amount, @declined_card, @options)
    @gateway.logger.info("#{__method__.to_s} - message - #{response.message}, code - #{response.params['PROCESSING.RETURN.CODE']}")
    assert_failure response
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

