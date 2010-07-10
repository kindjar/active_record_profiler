ActiveRecord::Schema.define(:version => 0) do
  create_table :dummy_logs, :force => true do |t|
    t.string :title
    t.integer :maximum, :default => 0, :null => false
    t.timestamps
  end
end
