var React = require('react-native');
var Platform = React.Platform;

if (Platform.OS === 'android') {
  module.exports = require('./index.android');
} else if (Platform.OS === 'ios') {
  module.exports = require('./index.ios');
}