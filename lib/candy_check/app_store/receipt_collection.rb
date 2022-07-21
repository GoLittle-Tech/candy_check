module CandyCheck
  module AppStore
    # Store multiple {Receipt}s in order to perform collective operation on them
    class ReceiptCollection
      # Multiple receipts as in verfication response
      # @return [Array<Receipt>]
      attr_reader :receipts, :pending_renewal_info

      # Initializes a new instance which bases on a JSON result
      # from Apple's verification server
      # @param attributes [Array<Hash>] raw data from Apple's server
      def initialize(attributes, pending_renewal_info = [])
        @receipts = attributes.map { |r| Receipt.new(r) }.sort do |a, b|
          a.purchase_date - b.purchase_date
        end
        @pending_renewal_info = pending_renewal_info
      end

      # Check if the latest expiration date is passed
      # @return [bool]
      def expired?
        expires_at.to_time <= Time.now.utc
      end

      # Check if in trial
      # @return [bool]
      def trial?
        @receipts.last.is_trial_period
      end

      # Get latest expiration date
      # @return [DateTime]
      def expires_at
        @receipts.last.expires_date
      end

      # Get number of overdue days. If this is negative, it is not overdue.
      # @return [Integer]
      def overdue_days
        (Date.today - expires_at.to_date).to_i
      end

      def auto_renewal_status
        pending_renewal_info.map do |renewal_info|
          renewal_info['auto_renew_status'] == '1'
        end.any?
      end

      def auto_renew_product_id
        pending_renewal_info&.first&.dig('auto_renew_product_id')
      end
    end
  end
end
