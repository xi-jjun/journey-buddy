require 'aws-sdk-s3'

class S3BucketManager
  S3_BUCKET_NAME = ENV['AWS_S3_BUCKET_NAME']
  S3_BUCKET_REGION = ENV['AWS_S3_REGION']
  S3_BASE_URL = ENV['AWS_S3_BUCKET_BASE_URL']

  class << self
    def upload_file_to_s3(file_info)
      return {} unless file_info.present?

      file_name = "#{SecureRandom.uuid}#{file_info[:extension]}"
      result = upload(file_info[:file], file_name)
      raise 'S3 upload fail' unless result == true

      {
        file_url: "#{S3_BASE_URL}/#{file_name}",
        created_at: Time.now
      }
    rescue StandardError => e
      Rails.logger.warn("S3 Bucket upload fail #{e.message}")
      {}
    end

    private

    def upload(file, key)
      s3_client = Aws::S3::Client.new(region: S3_BUCKET_REGION)
      response = s3_client.put_object(body: file, bucket: S3_BUCKET_NAME, key: key)

      response.etag.present? # 존재하면 성공
    rescue StandardError => e
      false
    end
  end
end
