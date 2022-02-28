import Vino.Bounce.BounceComponent;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackComponent;
import Cake.LevelSpecific.PlayRoom.Circus.Cannon.CannonTargetOscillation;
import Vino.Pickups.PlayerPickupComponent;
class ABouncyBaloonActor : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = BounceComp)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = BounceParent)
	UBounceComponent BounceComp;

	UPROPERTY(DefaultComponent, Attach = Oscillation)
	USceneComponent BounceParent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent balloonPopAudioEvent;

	UPROPERTY(DefaultComponent)
	UCannonTargetOscillation Oscillation;

	UPROPERTY()
	bool bShouldPop;
	
	UPROPERTY()
	UNiagaraSystem BalloonSplashEffect;

	UPROPERTY()
	TSubclassOf<UHazeCapability> BouncyCapabilityType;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Capability::AddPlayerCapabilityRequest(BouncyCapabilityType.Get());

		if (bShouldPop)
		{
			UActorImpactedCallbackComponent Comp = UActorImpactedCallbackComponent::GetOrCreate(this);
			if(Comp != nullptr)
			{
				Comp.OnActorDownImpactedByPlayer.AddUFunction(this, n"OnPlayerLanded");
			}
		}
	}

	UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason Reason)
	{
		Capability::RemovePlayerCapabilityRequest(BouncyCapabilityType.Get());
	}

	UFUNCTION()
	void OnPlayerLanded(AHazePlayerCharacter ImpactingPlayer, const FHitResult& Hit)
	{
		Niagara::SpawnSystemAtLocation(BalloonSplashEffect, ActorLocation, ActorRotation);
		Mesh.SetHiddenInGame(true);
		SetActorEnableCollision(false);
		
		ImpactingPlayer.SetCapabilityAttributeValue(n"VerticalVelocity", 1600.f);
		ImpactingPlayer.SetCapabilityActionState(n"Bouncing", EHazeActionState::Active);

		UHazeAkComponent::HazePostEventFireForget(balloonPopAudioEvent, this.GetActorTransform());
	}
}