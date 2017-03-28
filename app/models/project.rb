class Project
  include SetFields
  include Mongoid::Document
  embeds_many :datasources
  
  # Config file
  field :project_config, type: Hash

  # Index and data sources
  field :index_name, type: String
  field :datasources, type: Hash

  # Project details
  field :title, type: String
  field :theme, type: String
  field :favicon, type: String
  field :logo, type: String
  field :info_links, type: Hash
  
  # Load in the config file
  def parse_config(project_file)
    self.project_config = JSON.parse(File.read(project_file))
    load_fields(project_config["display_details"])
    self.index_name = project_config["index_name"]
    load_datasources
  end

  # Load in all the datasources
  def load_datasources
    project_config["data_source_details"].each do |spec_file|
      source = Datasource.new
      source.parse_config(spec_file)
      source.project = self
      source.save
    end
  end
end
