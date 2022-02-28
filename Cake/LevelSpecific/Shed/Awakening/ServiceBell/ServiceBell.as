import Vino.Bounce.BounceComponent;
import Vino.Tilt.TiltComponent;
import Vino.Movement.Capabilities.GroundPound.CharacterGroundPoundFallCapabilty;

class AServiceBell : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UTiltComponent TiltComp;

	UPROPERTY(DefaultComponent, Attach = TiltComp)
	USceneComponent BounceParent;

	UPROPERTY(DefaultComponent, Attach = BounceParent)
	UBounceComponent BounceComp;

	UPROPERTY(DefaultComponent, Attach = BounceComp)
	UStaticMeshComponent Ringer;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent BounceEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent GroundPoundBounceEvent;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAKComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FActorImpactedByPlayerDelegate OnPlayerLanded;
		OnPlayerLanded.BindUFunction(this, n"PlayerLandedOnBouncePad");
		BindOnDownImpactedByPlayer(this, OnPlayerLanded);
	}

	UFUNCTION()
	void BindOnForwardImpactedByPlayer(AHazeActor ImpactedActor, FActorImpactedByPlayerDelegate Delegate)
	{
		if(ImpactedActor != nullptr)
		{
			UActorImpactedCallbackComponent Comp = UActorImpactedCallbackComponent::GetOrCreate(ImpactedActor);
			if(Comp != nullptr)
			{
				Comp.OnActorForwardImpactedByPlayer.AddUFunction(Delegate.GetUObject(), Delegate.GetFunctionName());
			}
		}
	}

	UFUNCTION()
    void PlayerLandedOnBouncePad(AHazePlayerCharacter Player, FHitResult HitResult)
    {
		if (Player.IsAnyCapabilityActive(UCharacterGroundPoundFallCapability::StaticClass()))
		{
			HazeAKComponent.HazePostEvent(GroundPoundBounceEvent);
		}
		else
		{
			HazeAKComponent.HazePostEvent(BounceEvent);
		}
	}
}
