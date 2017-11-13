crypto = require('crypto')

unless process.argv[4]
  console.error "arguments: name, username, password; 'Mike McKay' mmckay thepassword"

doc = {
   "_id": "user.#{process.argv[3]}"
   "password": (crypto.pbkdf2Sync process.argv[4], "", 1000, 256/8, 'sha256').toString('base64')
   "name": "#{process.argv[2]}"
   "roles": [
       ""
   ],
   "isApplicationDoc": true,
   "collection": "user",
  
}


console.log doc
