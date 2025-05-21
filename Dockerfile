# Sử dụng hình ảnh Ubuntu 22.04 làm base
FROM nvidia/cuda:12.2.2-base-ubuntu22.04

# Thiết lập biến môi trường để tránh tương tác trong quá trình cài đặt
ENV DEBIAN_FRONTEND=noninteractive

# Cập nhật danh sách gói và cài đặt các gói cần thiết
RUN apt-get update && \
    apt-get install -y \
        software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y \
        python3.10 \
        python3.10-venv \
        python3.10-distutils \
        python3-pip \
        wget \
        git \
        libgl1 \
        libreoffice \
        fonts-noto-cjk \
        fonts-wqy-zenhei \
        fonts-wqy-microhei \
        ttf-mscorefonts-installer \
        fontconfig \
        libglib2.0-0 \
        libxrender1 \
        libsm6 \
        libxext6 \
        poppler-utils \
        && rm -rf /var/lib/apt/lists/*

# Đặt Python 3.10 làm mặc định
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1

# Tạo môi trường ảo cho MinerU
RUN python3 -m venv /opt/mineru_venv

# Sao chép repository local vào container
COPY . /app/mineru

# Cài đặt magic-pdf và cấu hình
RUN /bin/bash -c "cp /app/mineru/magic-pdf.template.json /root/magic-pdf.json && \
    source /opt/mineru_venv/bin/activate && \
    pip3 install --upgrade pip && \
    pip3 install -U /app/mineru[magic-pdf,full]"

# Cài đặt huggingface_hub và chạy script tải model
RUN /bin/bash -c "source /opt/mineru_venv/bin/activate && \
    pip3 install huggingface_hub && \
    python3 /app/mineru/download_models_hf.py && \
    sed -i 's|cpu|cuda|g' /root/magic-pdf.json"

# Đặt thư mục làm việc
WORKDIR /app/mineru

# Đặt entrypoint để kích hoạt môi trường ảo và chạy lệnh
ENTRYPOINT ["/bin/bash", "-c", "source /opt/mineru_venv/bin/activate && exec \"$@\"", "--"]