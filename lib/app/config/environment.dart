enum Environment { dev, staging, prod }

class Env {
  static Environment current = Environment.dev;

  static bool get isProd => current == Environment.prod;
}