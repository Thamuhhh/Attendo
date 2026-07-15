const mongoose = require('mongoose');

async function fixFieldTypes(uri) {
  await mongoose.connect(uri);
  const db = mongoose.connection.db;
  let totalFixed = 0;

  const collections = [
    { name: 'students', fields: ['institutionId'] },
    { name: 'attendances', fields: ['institutionId', 'studentId'] },
    { name: 'fees', fields: ['institutionId', 'studentId'] },
    { name: 'holidays', fields: ['institutionId'] },
  ];

  for (const col of collections) {
    for (const field of col.fields) {
      const docs = await db.collection(col.name).find({ [field]: { $type: 'string' } }).toArray();
      for (const doc of docs) {
        try {
          await db.collection(col.name).updateOne(
            { _id: doc._id },
            { $set: { [field]: new mongoose.Types.ObjectId(doc[field]) } }
          );
          totalFixed++;
        } catch (_) {}
      }
      if (docs.length > 0) console.log(`${col.name}.${field}: fixed ${docs.length}`);
    }
  }

  console.log(`Total fixed: ${totalFixed}`);
  await mongoose.disconnect();
  return totalFixed;
}

if (require.main === module) {
  const uri = process.env.MONGO_URI;
  if (!uri) { console.log('Set MONGO_URI first'); process.exit(1); }
  fixFieldTypes(uri).then(() => process.exit(0)).catch(e => { console.log(e.message); process.exit(1); });
}

module.exports = { fixFieldTypes };
