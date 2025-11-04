# frozen_string_literal: true

module Candidate
  class DeleteFile < ApplicationOrganizer
    organize DeleteAttachedFile, DeleteUnattachedBlob
  end
end
