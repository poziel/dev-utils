class Console {
  static reset = '\x1b[0m'
  static cyan = '\x1b[36m'
  static gray = '\x1b[90m'
  static green = '\x1b[32m'
  static yellow = '\x1b[33m'
  static red = '\x1b[31m'

  static write(prefix, message, color) {
    if (prefix) {
      console.log(`${color}${prefix} ${message}${Console.reset}`)
      return
    }

    console.log(`${color}${message}${Console.reset}`)
  }

  static section(message) {
    console.log()
    Console.write('==', message, Console.cyan)
  }

  static info(message) {
    Console.write('[INFO]', message, Console.gray)
  }

  static success(message) {
    Console.write('[OK]', message, Console.green)
  }

  static warning(message) {
    Console.write('[WARN]', message, Console.yellow)
  }

  static error(message) {
    Console.write('[ERROR]', message, Console.red)
  }
}

module.exports = Console
