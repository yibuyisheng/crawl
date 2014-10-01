config = require "./config"
winston = require "winston"
logger = new (winston.Logger)(
  transports: [
    new (winston.transports.Console)()
    new winston.transports.File(
      filename: config.logPath
      json: false
    )
  ]
  exceptionHandlers: [
    new (winston.transports.Console)()
    new winston.transports.File(
      filename: config.exceptionLogPath
      json: false
    )
  ]
  exitOnError: true
)

# 如果出错了，就把出错信息发送到指定用户的邮箱
nodemailer = require "nodemailer"
smtpTransport = nodemailer.createTransport("SMTP",
  service: "Gmail"
  auth:
    user: config.sender
    pass: config.password
)
sendMail = (msg) ->
  # smtpTransport.sendMail
  #   from: "<" + config.sender + ">"
  #   to: config.recievers
  #   subject: "爬虫出错啦！！！"
  #   html: msg
  # , (error, response) ->
  #   if error
  #     logger.log "warn", "send mail failed! error: %j, %j", error, response
  #   else
  #     logger.log "info", "send error information successfully!"
  #   return

  # return

logger.on "logging", (transport, level, msg, meta) ->
  return  if level isnt "error"
  if config.env is "production"
    sendMail JSON.stringify(
      transport: transport
      level: level
      msg: msg
      meta: meta
    )
  return

module.exports = logger