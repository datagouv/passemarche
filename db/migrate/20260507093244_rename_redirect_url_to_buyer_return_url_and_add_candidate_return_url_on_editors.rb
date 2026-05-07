class RenameRedirectUrlToBuyerReturnUrlAndAddCandidateReturnUrlOnEditors < ActiveRecord::Migration[8.1]
  def change
    rename_column :editors, :redirect_url, :buyer_return_url
    add_column :editors, :candidate_return_url, :string
  end
end
