# frozen_string_literal: true

module Admin
  module CsvImportHandling
    private

    def run_dry_import(token)
      result = ImportSocleDeBaseCsvService.call(csv_file: upload_store.path_for(token), dry_run: true)

      if result.success?
        @changes = result.changes
        @statistics = result.statistics
      else
        redirect_to admin_socle_de_base_index_path, alert: t('admin.socle_de_base.import.error', message: result.errors.join(', '))
      end
    end

    def import_from_token(token)
      return redirect_to admin_socle_de_base_index_path, alert: t('admin.socle_de_base.import.expired') unless upload_store.exists?(token)

      result = ImportSocleDeBaseCsvService.call(csv_file: upload_store.path_for(token))
      upload_store.delete(token)
      redirect_after_import(result)
    end

    def import_csv(csv_file)
      result = ImportSocleDeBaseCsvService.call(csv_file: csv_file.tempfile)
      redirect_after_import(result)
    end

    def redirect_after_import(result)
      if result.success?
        redirect_to admin_socle_de_base_index_path, notice: format_statistics(result.statistics)
      else
        redirect_to admin_socle_de_base_index_path, alert: t('admin.socle_de_base.import.error', message: result.errors.join(', '))
      end
    end

    def format_statistics(stats)
      t('admin.socle_de_base.import.success',
        created: stats[:created],
        updated: stats[:updated],
        soft_deleted: stats[:soft_deleted],
        skipped: stats[:skipped])
    end

    def upload_store
      @upload_store ||= ImportUploadStore.new
    end
  end
end
