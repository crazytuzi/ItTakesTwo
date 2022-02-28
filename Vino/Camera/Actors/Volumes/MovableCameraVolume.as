class AMovableCameraVolume : AActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBoxComponent Box;
	default Box.SetBoxExtent(FVector(200.f, 200.f, 200.f));
	default Box.SetCollisionProfileName(n"NoCollision");

	UPROPERTY(DefaultComponent, ShowOnActor)
	UHazeCameraSettingsComponent Settings;

	TArray<AHazePlayerCharacter> OverlappingPlayers;
	float BoundingSphereRadius;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// We assume box will not change size in runtime, fix if necessary
		BoundingSphereRadius = Box.WorldTransform.TransformVector(Box.BoxExtent).Size();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// Simple overlap check against players. Note that we do not sweep as entering
		// and exiting a camera volume the same tick would have no effect anyway.
		// If we get a lot of these, we'll have to optimize but it should be fine for now.
		const TArray<AHazePlayerCharacter>& Players = Game::GetPlayers();
		for (AHazePlayerCharacter Player : Players)
		{
			if (IsOverlapping(Player))
			{
				if (!OverlappingPlayers.Contains(Player))
				{
					// Start overlapping
					OverlappingPlayers.Add(Player);
					Settings.Apply(UHazeActiveCameraUserComponent::Get(Player));
				}
				else if (Settings.ShouldUpdate())
				{
					// Overlapping, update settings if they have conditions that may change in runtime
					Settings.Update(UHazeActiveCameraUserComponent::Get(Player));
				}
			}
			else
			{
				if (OverlappingPlayers.Contains(Player))
				{
					// Stop overlapping
					OverlappingPlayers.Remove(Player);
					Settings.Clear(UHazeActiveCameraUserComponent::Get(Player));
				}
			}
		}
		//System::DrawDebugBox(Box.WorldLocation, Box.ScaledBoxExtent, FLinearColor::Yellow, Box.WorldRotation);
	}

	bool IsOverlapping(AHazePlayerCharacter Player)
	{
		float PlayerRadius = Player.CapsuleComponent.CapsuleRadius * Player.CapsuleComponent.WorldScale.X;
		if ((Player.ActorLocation - ActorLocation).SizeSquared() > FMath::Square(BoundingSphereRadius + PlayerRadius))
			return false;

		// Inside of bounding sphere
		FVector LocalPlayerLoc = Box.WorldTransform.InverseTransformPosition(Player.ActorLocation);
		if (FMath::Abs(LocalPlayerLoc.X) > Box.UnscaledBoxExtent.X + PlayerRadius)
			return false; 
		if (FMath::Abs(LocalPlayerLoc.Y) > Box.UnscaledBoxExtent.Y + PlayerRadius)
			return false; 
		if (FMath::Abs(LocalPlayerLoc.Z) > Box.UnscaledBoxExtent.Z + PlayerRadius)
			return false; 

		// inside box
		return true;
	}
}