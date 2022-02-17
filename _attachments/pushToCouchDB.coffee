fs = require 'fs'
PouchDB = require 'pouchdb-core'
.plugin(require('pouchdb-adapter-http'))


( =>
  database_location = process.argv[2] # "http://admin:password@localhost:5984"
  database_name = process.argv[3] # "zanzibar"
  db = new PouchDB("#{database_location}/#{database_name}")

  id = "_design/plugin-#{database_name}"
  filename = "plugin-bundle.js"
  pluginBundle = fs.readFileSync('plugin-bundle.js')
  rev = (await db.get(id).catch (error) => Promise.resolve(null))?._rev

  console.log "Creating design doc: #{id}, with file #{filename} in #{db.name}"
  db.putAttachment id, filename, rev, pluginBundle, "application/javascript"
    .catch (error) -> console.error error
)()

