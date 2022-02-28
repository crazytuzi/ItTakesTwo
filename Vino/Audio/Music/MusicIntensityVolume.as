import Vino.Audio.Music.MusicIntensityLevelComponent;

class AMusicIntensityVolume : AVolume
{
	// Music intensity level which will be set when enabled and at least one player is inside volume
	UPROPERTY()
	EMusicIntensityLevel Intensity = EMusicIntensityLevel::Ambient;

	// Volume will set music intensity when at least one player is inside it and it is enabled.
	UPROPERTY(BlueprintReadOnly)
	bool bEnabled = true;

	UMusicIntensityLevelComponent MusicIntensityComp = nullptr;
	TArray<AHazePlayerCharacter> OverlappingPlayers;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AHazeMusicManagerActor MusicManager = UHazeAkComponent::GetMusicManagerActor();
		if (MusicManager != nullptr)
			MusicIntensityComp = UMusicIntensityLevelComponent::Get(MusicManager);

		if (bEnabled)
		{
			bEnabled = false; // Force overlap update
			Enable();
		}
	}

	UFUNCTION(meta = (KeyWords = "Set"))
	void Enable()
	{
		if (bEnabled)
			return;

		bEnabled = true;
		TArray<AActor> Overlappers;
		GetOverlappingActors(Overlappers, AHazePlayerCharacter::StaticClass());
		for (AActor Actor : Overlappers)
		{
			ActorBeginOverlap(Actor);
		}
	}

	UFUNCTION(meta = (KeyWords = "Set"))
	void Disable()
	{
		if (!bEnabled)
			return;
			
		bEnabled = false;
		for (AHazePlayerCharacter Player : OverlappingPlayers)
		{
			ActorEndOverlap(Player);
		}		
	}

    UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
		if (!bEnabled)
			return;

		if (MusicIntensityComp == nullptr)
			return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		if (OverlappingPlayers.Num() == 0)
			MusicIntensityComp.ApplyIntensity(Intensity, this);
		OverlappingPlayers.AddUnique(Player);
    }

    UFUNCTION(BlueprintOverride)
    void ActorEndOverlap(AActor OtherActor)
    {
		if (MusicIntensityComp == nullptr)
			return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		OverlappingPlayers.Remove(Player);
		if (OverlappingPlayers.Num() == 0)
			MusicIntensityComp.ClearIntensityByInstigator(this);
    }
}