# Build TkG's pacman packages

```yaml
name: Frog-Worker-linux58

...

jobs:
  pkgbuild:
    runs-on: ubuntu-latest
    container:
      image: archlinux
      options: --privileged
      volumes:
        - /sys/fs/cgroup:/sys/fs/cgroup
    steps:
    - name: Checkout
      uses: actions/checkout@v2
    - name: Makepkg Build and Check
      id: makepkg
      uses: Tk-Glitch/tkg-builer@master
    - name: Print Package Files
      run: |
        echo "Successfully created the following package archive"
        echo "Package: ${{ steps.makepkg.outputs.pkgfile0 }}"
    - name: Upload Package Archive
      uses: actions/upload-artifact@v2
      with:
        name: ${{ steps.makepkg.outputs.pkgfile0 }}
        path: ${{ steps.makepkg.outputs.pkgfile0 }}  
 
```

## Arguments

- `PKGBUILD` PKGBUILD subdir - **Required for nested PKGBUILD files, for example `wine-tkg-git/proton-tkg/PKGBUILD`**
- `OUTDIR` Output directory to store the built package - not required - default=`$HOME/arch-packages`
