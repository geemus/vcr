Feature: Usage with Shoulda

  When using a test framework that provides setup and teardown hooks
  (such as shoulda), you can use `VCR.insert_cassette` and
  `VCR.eject_cassette` to use a cassette for some tests.

  The first argument to `VCR.insert_cassette` should be the cassette
  name; you can follow that with a hash of cassette options.

  Note that you _must_ eject every cassette you insert; if you use
  `VCR.insert_cassette` rather than wrapping code in `VCR.use_cassette`,
  then it is your responsibility to ensure it is ejected, even if
  errors occur.

  Scenario: Use `VCR.insert_cassette` and `VCR.eject_cassette`
    Given a file named "test/test_helper.rb" with:
      """
      require 'test/unit'
      require 'shoulda'
      require 'vcr_cucumber_helpers'

      if ARGV.include?('--with-server')
        start_sinatra_app(:port => 7777) do
          get('/') { "Hello" }
        end
      end

      require 'vcr'

      VCR.config do |c|
        c.stub_with :webmock
        c.cassette_library_dir = 'test/fixtures/vcr_cassettes'
        c.default_cassette_options = { :record => :new_episodes }
      end
      """
    And a file named "test/vcr_example_test.rb" with:
      """
      require 'test_helper'

      class VCRExampleTest < Test::Unit::TestCase
        context 'using a VCR cassette' do
          setup do
            VCR.insert_cassette('shoulda_example')
          end

          should 'make an HTTP request' do
            response = Net::HTTP.get_response('localhost', '/', 7777)
            assert_equal "Hello", response.body
          end

          teardown do
            VCR.eject_cassette
          end
        end
      end
      """
    And the directory "test/fixtures/vcr_cassettes" does not exist
    When I run "ruby -Itest test/vcr_example_test.rb -- --with-server"
    Then it should pass with "1 tests, 1 assertions, 0 failures, 0 errors"
    And the file "test/fixtures/vcr_cassettes/shoulda_example.yml" should contain "body: Hello"

    # Run again without starting the sinatra server so the response will be replayed
    When I run "ruby -Itest test/vcr_example_test.rb"
    Then it should pass with "1 tests, 1 assertions, 0 failures, 0 errors"
