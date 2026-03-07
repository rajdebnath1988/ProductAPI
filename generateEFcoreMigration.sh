cd ~/ProductAPI

# Install EF Core tools globally
dotnet tool install --global dotnet-ef
echo 'export PATH="$PATH:$HOME/.dotnet/tools"' >> ~/.bashrc
source ~/.bashrc

# Generate initial migration (MySQL must be running)
dotnet ef migrations add InitialCreate \
  --project src/ProductAPI/ProductAPI.csproj \
  --startup-project src/ProductAPI/ProductAPI.csproj \
  --output-dir Migrations

# Verify migrations folder was created
ls -la src/ProductAPI/Migrations/

