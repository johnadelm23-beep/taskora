allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

fun configureAndroidSdk(p: Project) {
    val android = p.extensions.findByName("android") ?: return
    try {
        val method = android.javaClass.getMethod("compileSdkVersion", Int::class.javaPrimitiveType)
        method.invoke(android, 36)
    } catch (_: Throwable) {
        try {
            val method = android.javaClass.getMethod("setCompileSdk", Int::class.javaObjectType)
            method.invoke(android, 36)
        } catch (_: Throwable) {}
    }
}

subprojects {
    if (state.executed) {
        configureAndroidSdk(this)
    } else {
        afterEvaluate {
            configureAndroidSdk(this)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
