class AuthorityGroupsController < GroupsController
  layout 'normal_small'
  
  skip_before_filter :authorization, :only => [ :download_images, :index, :show ]
  
  def mark
    @authority_group = AuthorityGroup.find(params[:id])
    ids = @authority_group.entities.allowed(current_user, :view).map{|e| e.id}

    current_user.clipboard_add ids
    
    flash[:notice] = I18n.t("objects.marked_entities_success")
    
    redirect_to :action => 'show'
  end
  
  def download_images
    @authority_group = AuthorityGroup.find(params[:id])
    @entities = @authority_group.entities.allowed(current_user, :view).media
    
    zip_download @authority_group, @entities
  end
  
  def add_to
    @authority_group = AuthorityGroup.find(params[:id])
    entity_ids = Kor.array_wrap(params[:entity_ids])
    entities = viewable_entities.find entity_ids
    @authority_group.add_entities(entities)
    
    redirect_to @authority_group
  end

  def remove_from
    @authority_group = AuthorityGroup.find(params[:id])
    entity_ids = Kor.array_wrap(params[:entity_ids])
    entities = viewable_entities.find entity_ids
    @authority_group.remove_entities(entities)

    redirect_to @authority_group
  end
  
  def index
  end

  def show
    @authority_group = AuthorityGroup.find(params[:id])
    @entities = @authority_group.
      entities.
      allowed(current_user, :view).
      paginate(:page => params[:page], :per_page => 16).
      order('created_at DESC')
    render :layout => 'wide'
  end

  def new
    @authority_group = AuthorityGroup.new(authority_group_params)
  end

  def edit
    @authority_group = AuthorityGroup.find(params[:id])
  end
  
  def edit_move
    @authority_group = AuthorityGroup.find(params[:id])
  end

  def create
    @authority_group = AuthorityGroup.new(authority_group_params)

    if @authority_group.save
      flash[:notice] = I18n.t( 'objects.create_success', :o => @authority_group.name )
      redirect_to(@authority_group.authority_group_category || authority_group_categories_path)
    else
      render :action => "new"
    end
  end

  def update
    @authority_group = AuthorityGroup.find(params[:id])

    if @authority_group.update_attributes(authority_group_params)
      flash[:notice] = I18n.t( 'objects.update_success', :o => @authority_group.name )
      redirect_to(@authority_group.authority_group_category || authority_group_categories_path)
    else
      render :action => "edit"
    end
  end

  def destroy
    @authority_group = AuthorityGroup.find(params[:id])
    @authority_group.destroy
    
    if @authority_group.authority_group_category
      redirect_to @authority_group.authority_group_category
    else
      redirect_to authority_group_categories_path
    end
  end
  
  protected
    def authority_group_params
      params.fetch(:authority_group, {}).permit(:name, :lock_version, :authority_group_category_id)
    end

    def generally_authorized?
      current_user.authority_group_admin?
    end
    
end
