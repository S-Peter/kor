class Kor::SearchResult

  include ActiveModel::AttributeMethods

  def initialize(attrs = {})
    assign_attributes attrs
  end

  attr_writer :uuids, :ids, :records, :total, :page, :per_page, :raw_records

  def uuids
    @uuids || []
  end

  def ids
    @ids || []
  end

  def total
    @total || 0
  end

  def total_pages
    @total_pages ||= (total / per_page) + 1
  end

  def page
    @page || 1
  end

  def per_page
    @per_page || 20
  end

  def raw_records
    @raw_records || []
  end

  def records
    @records ||= begin
      if @ids.present?
        Entity.where(:id => @ids).to_a.sort do |x, y|
          @ids.index(x.id) <=> @ids.index(y.id)
        end
      elsif @uuids.present?
        Entity.where(:uuid => @uuids).to_a.sort do |x, y|
          @uuids.index(x.uuid) <=> @uuids.index(y.uuid)
        end
      else
        []
      end
    end
  end

  def assign_attributes(attrs)
    attrs.each do |key, value|
      send "#{key}=", value
    end
  end

end