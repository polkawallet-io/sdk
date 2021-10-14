var extend = require('util-extend')
var get = require('simple-get')
var async = require('async')
var mime = require('mime')
var progress = require('progress-stream')
var fs = require('fs')
var path = require('path')
var Emitter = require('events').EventEmitter
var pkg = require('./package.json')
var pumpify = require('pumpify')

function Upload () {
  var self = this
  var opts = this.opts
  var cb = this.cb

  if (!opts.assets || opts.assets.length === 0) return cb(new Error('Must specify at least one asset to upload'))
  if (!opts.token && !opts.auth) return cb(new Error('You must define either a token or username/password'))
  var files = []

  async.eachSeries(opts.assets, function (asset, callback) {
    var fileName = asset.name || path.basename(asset)
    asset = asset.path || asset
    var uploadUri = opts.url.split('{')[0] + '?name=' + fileName

    var stat

    try {
      stat = fs.statSync(asset)
    } catch (e) {
      return cb(e)
    }

    self.emit('upload-asset', fileName)

    var rd = fs.createReadStream(asset)

    var progressOpts = { length: stat.size, time: 100 }
    var prog = progress(progressOpts, function (p) {
      self.emit('upload-progress', fileName, p)
    })

    var form = {
      method: 'POST',
      url: uploadUri,
      headers: {
        'Content-Type': mime.getType(fileName),
        'Content-Length': stat.size,
        'User-Agent': 'gh-release-assets ' + pkg.version + ' (https://github.com/hypermodules/gh-release-assets)'
      },
      body: pumpify(rd, prog)
    }

    if (opts.token) { form.headers.Authorization = 'token ' + opts.token }
    if (opts.auth) { form.auth = opts.auth }

    get(form, function (err, res) {
      if (err) return callback(err)

      self.emit('uploaded-asset', fileName)
      files.push(fileName)
      callback()
    })
  }, function (err) {
    if (err) {
      cb(err)
    } else {
      cb(null, files)
    }
  })
}

function UploadAsset (opts, cb) {
  var Uploader = extend(new Emitter(), { upload: Upload })
  var uploader = Object.create(Uploader)
  uploader.opts = opts || {}
  uploader.cb = cb || function noop () {}
  uploader.upload()
  return uploader
}

module.exports = UploadAsset
