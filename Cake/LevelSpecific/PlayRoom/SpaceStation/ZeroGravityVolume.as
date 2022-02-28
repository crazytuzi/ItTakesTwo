import Peanuts.Audio.AudioStatics;

event void FZeroGravityVolumeEvent(AHazePlayerCharacter Player);

UCLASS(NotBlueprintable, HideCategories = "Collision Rendering Input Actor LOD Cooking")
class AZeroGravityVolume : AVolume
{
    default Shape::SetVolumeBrushColor(this, FLinearColor::Blue);

    UPROPERTY()
    bool bActive = true;

    UPROPERTY()
    float VerticalSpeed = 2500.f;

    UPROPERTY()
    float HorizontalSpeed = 1650.f;

    UPROPERTY(Category = "Audio Events")
    UAkAudioEvent OnGravityVolumeEnter;

    UPROPERTY(Category = "Audio Events")
    UAkAudioEvent OnGravityVolumeExit;

	UPROPERTY()
	bool bShowTutorial = true;

	UPROPERTY()
	FZeroGravityVolumeEvent OnEntered;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        if (!bActive)
        {
            SetActorEnableCollision(false);
        }
    }

    UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

        if(Player != nullptr)
        {
            Player.SetCapabilityAttributeValue(n"ZeroGVerticalSpeed", VerticalSpeed);
            Player.SetCapabilityAttributeValue(n"ZeroGHorizontalSpeed", HorizontalSpeed);

			if (bShowTutorial)
				Player.SetCapabilityActionState(n"ZeroGTutorial", EHazeActionState::Active);
			else
				Player.SetCapabilityActionState(n"ZeroGTutorial", EHazeActionState::Inactive);
				
            Player.SetCapabilityActionState(n"ZeroG", EHazeActionState::Active);
            UHazeAkComponent::GetOrCreate(Player).HazePostEvent(OnGravityVolumeEnter);
            HazeAudio::SetPlayerPanning(UHazeAkComponent::GetOrCreate(Player), Player);

			OnEntered.Broadcast(Player);
        }
    }

    UFUNCTION(BlueprintOverride)
    void ActorEndOverlap(AActor OtherActor)
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

        if(Player != nullptr)
        {
            Player.SetCapabilityActionState(n"ZeroG", EHazeActionState::Inactive);
            UHazeAkComponent::GetOrCreate(Player).HazePostEvent(OnGravityVolumeExit);
        }
    }

    UFUNCTION()
    void EnableVolume()
    {
        SetActorEnableCollision(true);

        TArray<AActor> OverlappingActors;
        GetOverlappingActors(OverlappingActors, AHazePlayerCharacter::StaticClass());

        for (AActor Actor : OverlappingActors)
        {
            AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
            if (Player != nullptr)
            {
                ActorBeginOverlap(Actor);
            }
        }
    }

	UFUNCTION()
	void DisableVolume()
	{
		SetActorEnableCollision(false);
	}
}