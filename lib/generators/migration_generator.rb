class ActsAsTaggableMigrationGenerator < Rails::Generators::Base
  def create_migration_file
    create_file "db/migrations/initializer.rb", File.open('schema.rb').read
  end
end
