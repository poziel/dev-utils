class Console:
    """Small ANSI-colored console output helpers."""

    RESET = "\033[0m"
    CYAN = "\033[36m"
    GRAY = "\033[90m"
    GREEN = "\033[32m"
    YELLOW = "\033[33m"
    RED = "\033[31m"

    @staticmethod
    def _write(prefix: str, message: str, color: str) -> None:
        if prefix:
            print(f"{color}{prefix} {message}{Console.RESET}")
            return

        print(f"{color}{message}{Console.RESET}")

    @staticmethod
    def section(message: str) -> None:
        print()
        Console._write("==", message, Console.CYAN)

    @staticmethod
    def info(message: str) -> None:
        Console._write("[INFO]", message, Console.GRAY)

    @staticmethod
    def success(message: str) -> None:
        Console._write("[OK]", message, Console.GREEN)

    @staticmethod
    def warning(message: str) -> None:
        Console._write("[WARN]", message, Console.YELLOW)

    @staticmethod
    def error(message: str) -> None:
        Console._write("[ERROR]", message, Console.RED)
