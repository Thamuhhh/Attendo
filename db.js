const Datastore = require('nedb-promises');
const path = require('path');

const db = {
  students: Datastore.create({ filename: path.join(__dirname, 'data', 'students.db'), autoload: true }),
  attendance: Datastore.create({ filename: path.join(__dirname, 'data', 'attendance.db'), autoload: true })
};

db.students.ensureIndex({ fieldName: 'name' });
db.attendance.ensureIndex({ fieldName: ['studentId', 'date'], unique: true });

db.fees = Datastore.create({ filename: path.join(__dirname, 'data', 'fees.db'), autoload: true });
db.fees.ensureIndex({ fieldName: ['studentId', 'month', 'year'], unique: true });

db.institutions = Datastore.create({ filename: path.join(__dirname, 'data', 'institutions.db'), autoload: true });
db.institutions.ensureIndex({ fieldName: 'email', unique: true });

module.exports = db;
