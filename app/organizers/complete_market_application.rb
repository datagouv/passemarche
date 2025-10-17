# frozen_string_literal: true

class CompleteMarketApplication < ApplicationOrganizer
  organize MarkApplicationAsCompleted,
    GenerateAttestationPdf,
    GenerateBuyerAttestationPdf,
    GenerateDocumentsPackage
end
