# Container Image Creation & Export (Developer Guide)

This guide is for developers and advanced users. It explains how to:

- Build a Docker image for the pipeline
- Export it for use on other systems
- Convert it to a Singularity/Apptainer image (from a local tar or Docker Hub)
- Package a release with all necessary files

---

## 1. Build the Docker Image

Build from your Dockerfile in the current directory:

```bash
docker build --no-cache -t sample_variant_qc:latest .
```

> **Note:** `sample_variant_qc` is the image name, and `latest` is the tag.

---

## 2. Export the Docker Image

Save the image to a tar file for transfer or backup:

```bash
docker save -o sample_variant_qc_latest.tar sample_variant_qc:latest
```

To use this on another system with Docker, copy this tar file to the other system, and load it with:

```bash
docker load -i sample_variant_qc_latest.tar
```

---

## 3. Convert Docker Image to Singularity/Apptainer (.sif)

### (A) From a Local Docker Tar File

On the target system with Singularity/Apptainer installed:

```bash
singularity build sample_variant_qc_latest.sif docker-archive://sample_variant_qc_latest.tar
# or
apptainer build sample_variant_qc_latest.sif docker-archive://sample_variant_qc_latest.tar
```

### (B) Directly from Docker Hub

If your image is public on Docker Hub:

```bash
singularity build sample_variant_qc_latest.sif docker://yourdockerhubuser/sample_variant_qc:latest
# or
apptainer build sample_variant_qc_latest.sif docker://yourdockerhubuser/sample_variant_qc:latest
```

---

## 4. Package a Release (Image + Parameters + Scripts + README)

To distribute a complete pipeline package, create a directory and copy all required files:

```bash
mkdir sample_variant_qc_release
cp sample_variant_qc_latest.tar sample_variant_qc_release/
cp parameters.txt sample_variant_qc_release/
cp RUNNER.sh sample_variant_qc_release/
cp README.md sample_variant_qc_release/
# Add any other scripts or docs as needed
```

To create a compressed archive for sharing:

```bash
tar czvf sample_variant_qc_release.tar.gz sample_variant_qc_release/
```

---

## Optional: Clean Up and Test

- **Clean up old Docker resources:**

  ```bash
  docker system prune -af
  ```

- **Test the image by running the pipeline:**

  ```bash
  ./RUNNER.sh --docker
  ./RUNNER.sh --singularity
  ./RUNNER.sh --apptainer
  ```

- **Build and run in one step, logging output:**

  ```bash
  { docker build --no-cache -t sample_variant_qc:latest . && ./RUNNER.sh --docker; } 2>&1 | tee docker_build_and_run.log
  ```

---

## See Also

- [Singularity/Apptainer Install & Conversion Scripts](singularity_install.md)
- [Container Platform Setup for Users](container_install.md)
