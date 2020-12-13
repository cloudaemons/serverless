const CopyWebpackPlugin = require('copy-webpack-plugin')
const nodeExternals = require('webpack-node-externals')

module.exports = {
  externals: [nodeExternals()],
  plugins: [
    new CopyWebpackPlugin({
      patterns: [
        { from: '.next', to: '.next' },
        { from: 'public', to: 'public' }
      ]
    })
  ]
}