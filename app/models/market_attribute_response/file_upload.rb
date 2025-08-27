class MarketAttributeResponse::FileUpload < MarketAttributeResponse
  def value_file
    value&.dig('file')
  end

  def value_file=(file)
    # Handle file uploads by storing file info in the JSONB value
    if file.present?
      self.value = (value || {}).merge('file' => {
        'name' => file.original_filename,
        'content_type' => file.content_type,
        'size' => file.size
      })
    end
  end
end
