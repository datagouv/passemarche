class AddAttestsNoExclusionMotifsToMarketApplications < ActiveRecord::Migration[8.1]
  def up
    add_column :market_applications, :attests_no_exclusion_motifs, :boolean, default: false, null: false

    MarketApplication.reset_column_information
    MarketApplication.find_each do |application|
      new_value = application.subject_to_prohibition != true
      application.update_column(:attests_no_exclusion_motifs, new_value) # rubocop:disable Rails/SkipsModelValidations
    end
  end

  def down
    remove_column :market_applications, :attests_no_exclusion_motifs
  end
end
