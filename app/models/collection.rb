class Collection < ActiveRecord::Base

  has_many :entities
  has_many :grants, :dependent => :destroy
  has_many :credentials, :through => :grants
  has_one :owner, :class_name => 'User', :foreign_key => :collection_id
  
  scope :personal, lambda { joins(:owner) }
  scope :non_personal, lambda {
    personal_ids = joins(:owner).select('collections.id').map{|c| c.id}
    personal_ids.empty? ? all : where("id NOT IN (?)", personal_ids)
  }

  validates :name,
    :presence => true,
    :uniqueness => true,
    :white_space => true  

  after_save :update_personals

  def update_personals
    if personal? && propagate && @grants_by_policy_buffer
      collections = self.class.joins(:owner).where("collections.id != ?", self.id)
      
      collections.each do |collection|
        params = {}
      
        @grants_by_policy_buffer.each do |policy, credential_ids|
          own_c_id = self.owner.credential_id.to_s
          other_c_id = collection.owner.credential_id.to_s
          
          if credential_ids.include? own_c_id
            params[policy] = credential_ids - [own_c_id] + [other_c_id]
          end
        end
        
        Collection.find(collection.id).update_attributes(:grants_by_policy => params, :propagate => false)
      end
    end
  end
  
  attr_writer :propagate
  
  def propagate
    @propagate = (@propagate == false ? false : true)
  end
  
  def empty?
    entities.empty?
  end
  
  def personal?
    !!owner
  end
  
  def list_name
    name
  end

  # TODO: move all auth stuff to Kor::Auth
  
  def grant(policies, options = {})
    policies = case policies
      when :all then self.policies
      when Symbol then [policies]
      when String then [policies]
      else
        policies
    end

    options[:to] = case options[:to]
      when nil then []
      when Credential then [options[:to]]
      else
        options[:to]
    end
  
    policies.each do |policy|
      options[:to].each do |credential|
        self.grants << Grant.new(policy: policy, credential: credential)
      end
    end
  end

  def revoke(policies, options = {})
    policies = case policies
      when :all then self.policies
      when Symbol then [policies]
      when String then [policies]
      else
        policies
    end

    options[:from] = case options[:from]
      when nil then []
      when Credential then [options[:from]]
      else
        options[:from]
    end

    self.grants.
      with_policy(policies).
      with_credential(options[:from]).
      destroy_all
  end
  
  def grants_by_policy
    grants.group_by do |grant|
      grant.policy
    end
  end
  
  def grants_by_policy=(value)
    @grants_by_policy_buffer = value
  
    policies.each do |policy|
      if grants_by_policy[policy]
        grants_by_policy[policy].each do |old_grant|
          new_credentials = value[policy] || []
          old_grant.destroy unless new_credentials.include?(old_grant.id.to_s)
        end
      end
      
      if value[policy]
        value[policy].each do |new_id|
          existing = grants_by_policy[policy] || []
          unless existing.map{|g| g.id.to_s}.include? new_id
            Grant.create(:collection => self, :policy => policy, :credential_id => new_id)
          end
        end
      end
    end
  end
  
  def policies
    self.class.policies
  end
  
  def self.policies
    ['view', 'edit', 'create', 'delete', 'download_originals', 'tagging', 'view_meta']
  end
  
  def authorized_user_groups(policies)
    grants.with_policy(policies).map{|g| g.credential}
  end
  
end
