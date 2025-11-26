class RemoveSubjectToProhibitionFromMarketApplications < ActiveRecord::Migration[8.1]
  def change
    remove_column :market_applications, :subject_to_prohibition, :boolean
  end
end
