# Dev Containers

Dev Containers make it easy to edit the GamutRF code and run it inside the GamutRF Docker Container. All of the configuration files for this are in the **.devcontainer** directory.

More information on Dev Containers: https://code.visualstudio.com/docs/devcontainers/containers

Once the container has started, run the following command in the VS Code Terminal to start it:
`python3 -c "from gamutrf.scan import *; main()"  --logaddr=0.0.0.0 --logport=10000 --igain=40 --freq-start=7e8 --freq-end=9e8 --samp-rate=20.48e6 --nfft=1024 --tune-dwell-ms=0 --tune-step-fft=512 --db_clamp_floor=-150 --fft_batch_size=256 --mqtt_server=mqtt --no-compass --peak_fft_range=50 --use_external_gps --use_external_heading --n_image=7 --no-vkfft --rotate_secs=60 --colormap=20`