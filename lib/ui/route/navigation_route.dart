enum NavigationRoute {
  mainRoute("/main"),
  cameraRoute("/camera"),
  analyzeRoute("/analyze"),;

  const NavigationRoute(this.name);
  final String name;
}