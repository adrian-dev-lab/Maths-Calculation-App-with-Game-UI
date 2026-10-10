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
    // Android test tasks require sources and build outputs on the same drive.
    // Pub-cache plugins can live on a different Windows drive from this app.
    val sameDrive = project.projectDir.toPath().root == newBuildDir.asFile.toPath().root
    val newSubprojectBuildDir: Directory = if (sameDrive) {
        newBuildDir.dir(project.name)
    } else {
        project.layout.projectDirectory.dir("build")
    }
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
    delete(subprojects.map { it.layout.buildDirectory })
}
