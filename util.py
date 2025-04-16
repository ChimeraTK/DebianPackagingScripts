# SPDX-FileCopyrightText: Deutsches Elektronen-Synchrotron DESY, MSK, ChimeraTK Project <chimeratk-support@desy.de>
# SPDX-License-Identifier: LGPL-3.0-or-later

import sys
import requests
import zlib
import lzma


def downloadAndUnpack(url: str, localFile: str) -> bool:
    print(f"Downloading {url}", file=sys.stderr)
    try:
        with requests.get(url, stream=True) as request:
            request.raise_for_status()
            with open(localFile, 'wb') as f:
                d = None
                if url.endswith('.gz'):
                    d = zlib.decompressobj(zlib.MAX_WBITS | 32)
                elif url.endswith('.xz'):
                    d = lzma.LZMADecompressor()
                for chunk in request.iter_content(chunk_size=8192):
                    if d:
                        f.write(d.decompress(chunk))
                    else:
                        f.write(chunk)

                # zlib needs flushing, xz doesn't
                if d and hasattr(d, 'flush'):
                    f.write(d.flush())
        return True
    except Exception as e:
        print(f"Failed to download {url}: {e}", file=sys.stderr)
        return False
