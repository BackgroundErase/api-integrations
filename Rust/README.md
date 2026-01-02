
## Generate api token 
You must have a business subscription that can be found at https://backgrounderase.net/pricing. To generate the token navigate to
https://backgrounderase.net/account and scroll to the bottom of the page.



```bash
git clone --no-checkout https://github.com/PramaLLC/ben-api-other-integrations.git
cd ben-api-other-integrations
git sparse-checkout init --cone
git sparse-checkout set Rust
git checkout main   # or replace 'main' with the repo's default branch if different
cd Rust
```

or 

```bash
svn export https://github.com/PramaLLC/ben-api-other-integrations/trunk/Rust
cd Rust
```

Get input image:
```bash
curl -L -o input.jpg \
  https://raw.githubusercontent.com/PramaLLC/ben-api-other-integrations/main/input.jpg
```

Usage:

src/main.rs Cargo.toml
