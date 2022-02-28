import Vino.Movement.Components.FloorJumpCallbackComponent;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackComponent;
class ADrumhead : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UActorImpactedCallbackComponent Impacts;

	UPROPERTY()
	UCurveFloat BounceScaleCurve;

	TArray<AHazePlayerCharacter> PlayerArray;

	float BounceTimerMax = 0.25;
	float BounceAlpha = 0.f;
	float BounceSpeed = 3.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FActorJumpedFromDelegate OnActorJumpedFrom;
		OnActorJumpedFrom.BindUFunction(this, n"JumpedFrom");
		BindOnActorJumpedFrom(this, OnActorJumpedFrom);

		Impacts.OnActorDownImpactedByPlayer.AddUFunction(this, n"PlayerLandedOnDrumHead");
		Impacts.OnDownImpactEndingPlayer.AddUFunction(this, n"PlayerNoLongerOnDrum");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		BounceAlpha += DeltaTime * BounceSpeed;
		Mesh.SetRelativeScale3D(FVector(1.f, 1.f, BounceScaleCurve.GetFloatValue(BounceAlpha)));

		if (PlayerArray.Num() <= 0)
			return;

		for (AHazePlayerCharacter Player : PlayerArray)
		{
			if (BounceAlpha > 0.1f && BounceAlpha < .9f)
			{
				Player.SetCapabilityActionState(n"DrumBounce", EHazeActionState::Active);
			} else 	
			{
				Player.SetCapabilityActionState(n"DrumBounce", EHazeActionState::Inactive);
			}
		}
	}

	UFUNCTION()
	void JumpedFrom(AHazePlayerCharacter Player, UPrimitiveComponent Prim)
	{
		Print("BounceAlpha: " + BounceAlpha, 2.0f);

		if (BounceAlpha > 0.1f && BounceAlpha < .9f)
		{
			Player.AddCapability(n"DrumBounceCapability");
			Player.SetCapabilityActionState(n"DrumBounce", EHazeActionState::ActiveForOneFrame);
		}
	}

	UFUNCTION()
	void PlayerLandedOnDrumHead(AHazePlayerCharacter Player, const FHitResult& Hit)
	{
		Player.AddCapability(n"DrumBounceCapability");
		PlayerArray.AddUnique(Player);
		if (BounceAlpha > 1)
			BounceAlpha = 0.f;
	}

	UFUNCTION()
	void PlayerNoLongerOnDrum(AHazePlayerCharacter Player)
	{
		PlayerArray.Remove(Player);
		Player.SetCapabilityActionState(n"DrumBounce", EHazeActionState::Inactive);
	}
}