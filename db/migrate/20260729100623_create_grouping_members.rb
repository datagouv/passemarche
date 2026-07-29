class CreateGroupingMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :grouping_members do |t|
      t.references :grouping, null: false, foreign_key: true
      t.references :market_application, null: true, foreign_key: true
      t.integer :role, null: false
      t.integer :status, null: false, default: 0
      t.string :siret, null: false
      t.string :email, null: false
      t.string :invitation_token
      t.datetime :invitation_token_created_at

      t.timestamps
    end

    add_index :grouping_members, :invitation_token, unique: true
    add_index :grouping_members, %i[grouping_id siret], unique: true
    add_index :grouping_members, :grouping_id, unique: true, where: 'role = 0',
      name: 'index_grouping_members_on_grouping_id_single_mandataire'
  end
end
