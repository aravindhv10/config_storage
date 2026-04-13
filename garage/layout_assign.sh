#!/bin/sh
cd "$(dirname -- "${0}")"
/var/tmp/garage/bin/garage -c "$(realpath ./garage.toml)" layout assign '2a605e9dbeffb269d94e7a45fb48074230dda6ef6eda428ac1332a878df6b1ac' --zone home --capacity 1
/var/tmp/garage/bin/garage -c "$(realpath ./garage.toml)" layout assign 'b5d5fa0f915c8b4bd94ff5ccc86d79b862e9a5cebd059ec207ecb09516096dda' --zone home --capacity 1
