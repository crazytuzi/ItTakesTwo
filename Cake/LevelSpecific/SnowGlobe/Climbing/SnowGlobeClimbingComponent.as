import Cake.LevelSpecific.SnowGlobe.Climbing.SnowGlobeClimbingMagneticComponent;
import Cake.LevelSpecific.SnowGlobe.Climbing.SnowGlobeClimbingGripComponent;
class USnowGlobeClimbingComponent : UActorComponent
{
	USnowGlobeClimbingMagneticComponent ActiveMagneticComponent;
	USnowGlobeClimbingMagneticComponent LastMagneticComponent;
	USnowGlobeClimbingMagneticComponent PlayerMagneticComponent;
	USnowGlobeClimbingGripComponent PlayerGripComponent;

	FHitResult GripHitData;
	AHazePlayerCharacter Player;
	
	UPROPERTY()
	bool bHasGrip;

	bool bCanJump;
	bool bIsSwinging;
	bool bIsSplineLocked;

	float GripJumpForce = 2250.f;
	float SwingJumpForce = 2750.f;

	FVector SplineRightVector;

	UPROPERTY(Category = "Animation")
	UHazeLocomotionStateMachineAsset LocomotionAssetMay;

	UPROPERTY(Category = "Animation")
	UHazeLocomotionStateMachineAsset LocomotionAssetCody;

	UPROPERTY(Category = "Effects")
	UNiagaraSystem GripEffect;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(GetOwner());
		PlayerMagneticComponent = USnowGlobeClimbingMagneticComponent::GetOrCreate(Player);
		PlayerMagneticComponent.SetRelativeLocation(Player.GetActorCenterLocation() -Player.GetActorLocation());
		PlayerMagneticComponent.bIsPositive = Player.IsCody();
		PlayerMagneticComponent.bIsActive = false;
	}

	USnowGlobeClimbingMagneticComponent GetMagneticComponent()
	{	
		USnowGlobeClimbingMagneticComponent ClosestMagneticComponent;

		TArray<AActor> OverlappedActors;
		TArray<EObjectTypeQuery> Types;
		Types.Add(EObjectTypeQuery::WorldDynamic);
		Types.Add(EObjectTypeQuery::PlayerCharacter);
		TArray<AActor> IgnoreActors;
		IgnoreActors.Add(Player);
		System::SphereOverlapActors(Player.GetActorCenterLocation(), PlayerMagneticComponent.Radius, Types, AActor::StaticClass(), IgnoreActors, OverlappedActors);

		float ClosestDistance = 0.f;

		for(AActor Actor : OverlappedActors)
		{ 			
			USnowGlobeClimbingMagneticComponent Comp = USnowGlobeClimbingMagneticComponent::Get(Actor);
			if(Comp != nullptr && Comp.bIsActive && PlayerMagneticComponent.bIsPositive != Comp.bIsPositive)
			{
				float Distance = (Player.GetActorCenterLocation() - Comp.GetWorldLocation()).Size();

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
	}

	USnowGlobeClimbingGripComponent GetGrip()
	{
		USnowGlobeClimbingGripComponent ClosestGripComponent;
		TArray<AActor> ActorsToIgnore;
		TArray<FHitResult> Hits;
		ActorsToIgnore.Add(Player);

		System::SphereTraceMulti(Player.GetActorCenterLocation(), Player.GetActorCenterLocation() + FVector( 0, 0, 0.1f), 100.f, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hits, true, DrawTime = 0.f);

		Print("Hits: "+ Hits.Num(), 1.f);

		float ClosestDistance = 0.f;
		
		for(FHitResult Hit : Hits)
		{
			USnowGlobeClimbingGripComponent GripComponent = USnowGlobeClimbingGripComponent::Get(Hit.Actor);
			if(GripComponent != nullptr)
			{
				System::DrawDebugLine(Player.GetActorCenterLocation(), Hit.ImpactPoint);
				float Distance = (Player.GetActorCenterLocation() - Hit.ImpactPoint).Size();
				if(Distance < ClosestDistance || ClosestDistance == 0.f)
				{
					ClosestDistance = Distance;
					ClosestGripComponent = GripComponent;
					GripHitData = Hit;					
				}
			}
		}
		//bHasGrip = (ClosestGripComponent != nullptr);
		PlayerGripComponent = ClosestGripComponent;
		return ClosestGripComponent;
	}

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