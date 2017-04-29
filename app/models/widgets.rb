class Widget
  include DataMapper::Resource

  storage_names[:default] = "widgets"

  property :id, Serial, :key => true, :index => true
  property :name           , String , :required => true
  property :description    , Text   , :required => false
  property :column         , String , :required => true
  property :column_position, Integer, :required => true, :default => 0
  property :position       , Integer, :required => true, :default => 0
  property :minimized      , Boolean, :required => true, :default => false
  property :property       , Json   , :required => true, :default => {}.to_json

  belongs_to :user

  def change_position_best
    column_position=0
    position=0
    min=-1

    widgets = Widget.all(:user => self.user).group_by { |x| x.column_position }
    widgets[0] = [] if widgets[0].nil?
    widgets[1] = [] if widgets[1].nil?
    
    [widgets[0], widgets[1]].each_with_index do |x, i|
      if (min<0 or (min>x.length and i!=self.column_position) or (min>(x.length-1) and i==self.column_position))
        column_position=i
        if x.length>0
          position=x.sort{|a1,a2| a1.position<=>a2.position}.last.position + 1
        else
          position=0
        end
        if i==self.column_position
          min=x.length-1
        else
          min=x.length
        end
      end
    end

    update(:column_position=> column_position, :position => position)

    change_position(column_position, position)
  end

  def change_position(column_position, position)
    #we have to update rest of elements in the column
    position2=position
    Widget.all(:user => self.user, :column_position => column_position, :position.gte => position).each do |w|
      w.update(:position => position2+1)    
      position2=position2+1
    end
    self.update(:column_position => column_position, :position => position)
  end

  def range
    self.property["range"].blank? ? 'last_24' : self.property["range"]
  end

  def direction
    self.property["direction"].blank? ? 'in' : self.property["direction"]
  end
  
  def metric
    self.property["metric"].blank? ? 'kbps' : self.property["metric"]
  end
  
  def graph_type
    self.property["graph_type"].blank? ? 'area' : self.property["graph_type"]
  end

end
