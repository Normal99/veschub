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

subprojects {
    val p = this
    fun applyCompileSdk() {
        if (p.extensions.findByName("android") != null) {
            val androidExt = p.extensions.getByName("android") as com.android.build.gradle.BaseExtension
            androidExt.compileSdkVersion(36)
        }
    }
    if (p.state.executed) {
        applyCompileSdk()
    } else {
        p.afterEvaluate { applyCompileSdk() }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
