require 'aws-sdk-dynamodb'
require 'aws-sdk-s3'
require 'jekyll'

module Jekyll
  class DynamoS3AlbumGenerator < Generator
    safe true
    priority :highest

    def generate(site)
      # Initialize DynamoDB and S3 clients
      dynamodb = Aws::DynamoDB::Client.new(region: 'your-region')
      s3 = Aws::S3::Client.new(region: 'your-region')
      s3_resource = Aws::S3::Resource.new(client: s3)

      # Specify your DynamoDB table name
      table_name = 'YourDynamoDBTableName'

      # Query DynamoDB for albums
      resp = dynamodb.scan(table_name: table_name)
      albums = resp.items

      # Generate an album page for each album
      albums.each do |album|
        album_name = album['album_name']
        client_name = album['client_name']
        # Construct the S3 bucket and object key prefix
        bucket_name = 'your-s3-bucket-name'
        object_key_prefix = "clients/#{client_name}/albums/#{album_name}/"

        # List objects in the album's S3 directory
        objects = s3.list_objects(bucket: bucket_name, prefix: object_key_prefix).contents

        # Build image URLs
        image_urls = objects.map do |object|
          s3_resource.object(bucket_name: bucket_name, key: object.key).public_url
        end

        # Use Jekyll's Page class to generate a new album page
        album_page = PageWithoutAFile.new(site, site.source, '_layouts', 'album.html')
        album_page.data['title'] = album_name
        album_page.data['images'] = image_urls
        album_page.output

        # Add the generated page to the site pages
        site.pages << album_page
      end
    end
  end
end
