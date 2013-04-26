class AddRowIndexToPoints < ActiveRecord::Migration
  def change
    add_column :points, :row_index, :integer
  end
end
