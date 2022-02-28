import Cake.LevelSpecific.SnowGlobe.SnowFolk.SnowFolkProximityComponent;

class USnowFolkGreetComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(NotVisible)
	AHazeActor Folk;
	UPROPERTY(NotVisible)
	USnowFolkProximityComponent ProximityComp;
	UPROPERTY(NotVisible)
	UHazeSkeletalMeshComponentBase SkeletalMesh;

	UPROPERTY(Category = "Greet")
	bool bDisableGreeting = false;
	UPROPERTY(Category = "Greet")
	float MinInterval = 240.f;
	UPROPERTY(Category = "Greet", Meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float GreetChance = 0.2f;
	UPROPERTY(Category = "Greet")
	float GreetAngle = 45.f;
	UPROPERTY(Category = "Greet")
	TArray<UAnimSequence> GreetAnimations;

	private float ResetTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Folk = Cast<AHazeActor>(Owner);
		ProximityComp = USnowFolkProximityComponent::Get(Owner);
		SkeletalMesh = UHazeSkeletalMeshComponentBase::Get(Owner);

		ProximityComp.OnEnterProximity.AddUFunction(this, n"HandlePlayerEnterProximity");
	}

	UFUNCTION()
	void Greet(int AnimationIndex)
	{
		if (!HasControl())
			return;

		NetGreet(AnimationIndex);
	}

	UFUNCTION(NetFunction)
	void NetGreet(int AnimationIndex)
	{
		if (AnimationIndex < 0 || AnimationIndex >= GreetAnimations.Num())
			return;

		ResetTime = Time::GameTimeSeconds + MinInterval;

		FHazePlaySlotAnimationParams Params;
		Params.Animation = GreetAnimations[AnimationIndex];

		if (SkeletalMesh.WasRecentlyRendered(0.f))
		{
			SkeletalMesh.PlaySlotAnimation(FHazeAnimationDelegate(), 
				FHazeAnimationDelegate(), 
				Params);
		}
	}

	UFUNCTION()
	private void HandlePlayerEnterProximity(AHazePlayerCharacter Player, bool bFirstEnter)
	{
		if (!HasControl() || !CanGreet())
			return;

		FVector Direction = (Player.ActorLocation - Owner.ActorLocation).GetSafeNormal();
		float AngleToPlayer = FMath::RadiansToDegrees(FMath::Acos(Direction.DotProduct(Owner.ActorForwardVector)));
		if (AngleToPlayer > GreetAngle)
			return;

		if (FMath::RandRange(0.f, 1.f) < GreetChance)
		{
			int AnimationIndex = FMath::RandRange(0, GreetAnimations.Num() - 1);
			Greet(AnimationIndex);
		}
	}

	private bool CanGreet()
	{
		if (bDisableGreeting)
			return false;

		if (GreetAnimations.Num() == 0)
			return false;
			
		if (ResetTime >= Time::GameTimeSeconds)
			return false;

		if (Folk.IsAnyCapabilityActive(n"SnowFolkSnowballFight"))
			return false;

		if (Folk.IsAnyCapabilityActive(n"SnowFolkImpactCapability"))
			return false;

		return true;
	}
}