class InplaceController < ApplicationController
  
  def update_entity_tags
    @entity = Entity.find(params[:entity_id])
    
    if authorized? :tagging, @entity.collection
      @entity.tag_list += params[:value].split(/,\s*/) unless params[:value].blank?
      
      if @entity.save
        render :text => @entity.tag_list
      else
        render json: @entity.errors, status: 406
      end
    else
      render :nothing => true, :status => 403
    end
  end
  
end

