package de.hampager.dapnet.call_service;

public final class App {

	private static final String SERVICE_VERSION;

	static {
		// Read service version from package
		String ver = App.class.getPackage().getImplementationVersion();
		SERVICE_VERSION = ver != null ? ver : "UNKNOWN";
	}

	public static void main(String[] args) {
	}

	/**
	 * Gets the service version.
	 * 
	 * @return Service version string.
	 */
	public static String getVersion() {
		return SERVICE_VERSION;
	}

}
