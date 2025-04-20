enum NetworkErrorType {
  cancel,
  parsing,
  badRequest, //400
  unauthorized, //401
  forbidden, //403
  noData, //404
  unprocessable, //422
  badConnection,
  server, //500
  other,
  operation,
}
