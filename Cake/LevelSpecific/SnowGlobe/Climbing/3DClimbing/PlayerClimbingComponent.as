import Cake.LevelSpecific.SnowGlobe.Climbing.SnowGlobeClimbingMagneticComponent;
import Cake.LevelSpecific.SnowGlobe.Climbing.3DClimbing.Climbing3DMagneticComponent;

class UPlayerClimbingComponent : UActorComponent
{
	UClimbing3DMagneticComponent ActiveMagneticComponent;
	UClimbing3DMagneticComponent LastMagneticComponent;
	UClimbing3DMagneticComponent PlayerMagneticComponent;
	UPlayerClimbingComponent PlayerGripComponent;

	AHazePlayerCharacter Player;

	bool bCanJump;
	bool bIsSwinging;
	bool bIsSplineLocked;

	float SwingJumpForce = 2750.f;

	FVector SplineRightVector;

	UPROPERTY(Category = "Animation")
	UHazeLocomotionStateMachineAsset LocomotionAssetMay;

	UPROPERTY(Category = "Animation")
	UHazeLocomotionStateMachineAsset LocomotionAssetCody;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(GetOwner());
		PlayerMagneticComponent = UClimbing3DMagneticComponent::GetOrCreate(Player);
		PlayerMagneticComponent.SetRelativeLocation(Player.GetActorCenterLocation() -Player.GetActorLocation());
		PlayerMagneticComponent.bIsPositive = Player.IsCody();
		PlayerMagneticComponent.bIsActive = false;
	}

	UClimbing3DMagneticComponent GetMagneticComponent()
	{	
		UClimbing3DMagneticComponent ClosestMagneticComponent;
		float ClosestDistance = 0.f;

		TArray<AActor> OverlappedActors;
		TArray<EObjectTypeQuery> Types;
		Types.Add(EObjectTypeQuery::WorldDynamic);
		Types.Add(EObjectTypeQuery::PlayerCharacter);
		TArray<AActor> IgnoreActors;
		IgnoreActors.Add(Player);
		IgnoreActors.Add(PlayerMagneticComponent.ForceActor);
		System::SphereOverlapActors(Player.GetActorCenterLocation(), PlayerMagneticComponent.Radius, Types, AActor::StaticClass(), IgnoreActors, OverlappedActors);
		for(AActor MetActor : OverlappedActors)
		{ 			
			UClimbing3DMagneticComponent Comp = UClimbing3DMagneticComponent::Get(MetActor);
			if(Comp == nullptr && MetActor.Owner != nullptr)
			{
				Comp = Cast<UClimbing3DMagneticComponent>(MetActor.Owner.GetComponentByClass(UClimbing3DMagneticComponent::StaticClass()));
			}
			if(Comp != nullptr && Comp.bIsActive && PlayerMagneticComponent.bIsPositive != Comp.bIsPositive)
			{
				float Distance = Player.GetActorCenterLocation().Distance(Comp.GetWorldLocation());
				Distance -= Comp.Radius;

				if(Distance <= PlayerMagneticComponent.Radius)
				{				
					if(Distance < ClosestDistance || ClosestDistance == 0.f)
					{
						ClosestDistance = Distance;
						ClosestMagneticComponent = Comp;
					}
				}
			}
		}
		
		ActiveMagneticComponent = ClosestMagneticComponent;
		return ClosestMagneticComponent;

		// TArray<AActor> ActorsToIgnore;
		// TArray<FHitResult> Hits;
		// ActorsToIgnore.Add(Owner);
		// ActorsToIgnore.Add(PlayerMagneticComponent.ForceActor);		

		// System::SphereTraceMulti(Player.GetActorCenterLocation(), Player.GetActorCenterLocation(), PlayerMagneticComponent.Radius, ETraceTypeQuery::TraceTypeQuery_MAX, false, ActorsToIgnore, EDrawDebugTrace::ForOneFrame, Hits, true);
		// for(FHitResult Hit : Hits)
		// {
		// 	UClimbing3DMagneticComponent OtherMagneticComponent = UClimbing3DMagneticComponent::Get(Hit.Actor);
			
		// 	if(OtherMagneticComponent != nullptr && OtherMagneticComponent.bIsActive 
		// 	&& PlayerMagneticComponent.bIsPositive != OtherMagneticComponent.bIsPositive)
		// 	{
		// 		float Distance = (Player.GetActorCenterLocation() - OtherMagneticComponent.GetWorldLocation()).Size();

		// 		if(Distance <= PlayerMagneticComponent.Radius)
		// 		{				
		// 			if(Distance < ClosestDistance || ClosestDistance == 0.f)
		// 			{
		// 				ClosestDistance = Distance;
		// 				ClosestMagneticComponent = OtherMagneticComponent;
		// 			}
		// 		}
		// 	}
		// }

		// ActiveMagneticComponent = ClosestMagneticComponent;
		// return ClosestMagneticComponent;
	}

	// UPlayerClimbingComponent GetGrip()
	// {
	// 	UPlayerClimbingComponent ClosestGripComponent;
	// 	TArray<AActor> ActorsToIgnore;
	// 	TArray<FHitResult> Hits;
	// 	ActorsToIgnore.Add(Player);

	// 	System::SphereTraceMulti(Player.GetActorCenterLocation(), Player.GetActorCenterLocation(), 100.f, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hits, true);
		
	// 	float ClosestDistance = 0.f;
		
	// 	for(FHitResult Hit : Hits)
	// 	{
	// 		UPlayerClimbingComponent GripComponent = UPlayerClimbingComponent::Get(Hit.Actor);
	// 		if(GripComponent != nullptr)
	// 		{
	// 			System::DrawDebugLine(Player.GetActorCenterLocation(), Hit.ImpactPoint);
	// 			float Distance = (Player.GetActorCenterLocation() - Hit.ImpactPoint).Size();
	// 			if(Distance < ClosestDistance || ClosestDistance == 0.f)
	// 			{
	// 				ClosestDistance = Distance;
	// 				ClosestGripComponent = GripComponent;
	// 				GripHitData = Hit;					
	// 			}
	// 		}
	// 	}
	// 	//bHasGrip = (ClosestGripComponent != nullptr);
	// 	PlayerGripComponent = ClosestGripComponent;
	// 	return ClosestGripComponent;
	// }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		/*
		Print(
			"Player: " + Player.GetName() + "\n"
			+ "HasGrip = " + bHasGrip + "\n"
			+ "Swinging = " + bIsSwinging + "\n"
			+ "Can Jump = " + bCanJump + "\n"
			+ "Player Magnet Active = " + PlayerMagneticComponent.bIsActive + "\n"
			+ "Last = " + LastMagneticComponent + "\n"
			+ "Grip Component = " + PlayerGripComponent + "\n"
		);
		*/
	}
}