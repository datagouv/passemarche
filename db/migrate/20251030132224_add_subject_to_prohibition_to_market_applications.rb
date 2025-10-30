class AddSubjectToProhibitionToMarketApplications < ActiveRecord::Migration[8.1]
  def change
    add_column :market_applications, :subject_to_prohibition, :boolean, default: nil # rubocop:disable Rails/ThreeStateBooleanColumn
    add_index :market_applications, :subject_to_prohibition
  end
end
