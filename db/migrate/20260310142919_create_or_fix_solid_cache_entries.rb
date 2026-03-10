class CreateOrFixSolidCacheEntries < ActiveRecord::Migration[8.1]
  def change
    unless table_exists?(:solid_cache_entries)
      create_table :solid_cache_entries do |t|
        t.binary :key, limit: 1024, null: false
        t.binary :value, limit: 536_870_912, null: false
        t.datetime :created_at, null: false
        t.integer :key_hash, limit: 8, null: false
        t.integer :byte_size, limit: 4, null: false
      end
    end

    remove_index :solid_cache_entries, :key_hash, if_exists: true
    remove_index :solid_cache_entries, [:key_hash, :byte_size], if_exists: true

    add_index :solid_cache_entries, :key_hash, unique: true
    add_index :solid_cache_entries, [:key_hash, :byte_size]
    add_index :solid_cache_entries, :byte_size, if_not_exists: true
  end
end
