const mongoose = require('mongoose');

const MONGO_URI = process.env.MONGO_URI || 'mongodb+srv://<user>:<pass>@cluster0.xxxxx.mongodb.net/attendo?retryWrites=true&w=majority';

mongoose.connect(MONGO_URI).then(() => {
  console.log('MongoDB connected');
}).catch(err => {
  console.error('MongoDB connection error:', err.message);
});

module.exports = mongoose;
