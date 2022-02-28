import Cake.LevelSpecific.SnowGlobe.Magnetic.SnowCannon.ShotBySnowCannonComponent;
import Vino.Pickups.PlayerPickupComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPerchAndBoostComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.SnowCannon.MagneticSnowProjectile;

class UMagneticSnowCannonMagnetFreeFallCapability : UHazeCapability
{
	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;
	
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;

	AHazeActor CurrentActor;
	UShotBySnowCannonComponent ShotComp;
	UMagneticPerchAndBoostComponent PerchAndBoostComp;

	bool bDestroy = false;

	float CurrentSpeed;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		CurrentActor = Cast<AHazeActor>(Owner);
		ShotComp = UShotBySnowCannonComponent::GetOrCreate(CurrentActor);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(ShotComp.CurrentState != EMagneticBasePadState::Falling)
		    return EHazeNetworkActivation::DontActivate;        
        else
			return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& Params)
	{
		if (bDestroy)
		{
			Params.AddActionState(n"ShouldDestroy");
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{	
		if (ShotComp.CurrentState == EMagneticBasePadState::Idle)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(IsActioning(n"SlideReset"))
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if(bDestroy)
		{
			return EHazeNetworkDeactivation::DeactivateFromControl;
		}
        else
            return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PerchAndBoostComp = UMagneticPerchAndBoostComponent::Get(Owner);
		CurrentSpeed = ShotComp.SlideSpeed;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(DeactivationParams.GetActionState(n"ShouldDestroy"))
			Owner.SetCapabilityActionState(n"ShouldDestroy", EHazeActionState::Active);

		PerchAndBoostComp = nullptr;
		bDestroy = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TArray<AActor> ActorsToIgnore;
		ActorsToIgnore.Add(Game::GetCody());
		ActorsToIgnore.Add(Game::GetMay());

		UPlayerPickupComponent MayPickupComp = UPlayerPickupComponent::Get(Game::GetMay());
		UPlayerPickupComponent CodyPickupComp = UPlayerPickupComponent::Get(Game::GetCody());
		
		if(MayPickupComp.CurrentPickup != nullptr)
			ActorsToIgnore.Add(MayPickupComp.CurrentPickup);
		if(CodyPickupComp.CurrentPickup != nullptr)
			ActorsToIgnore.Add(CodyPickupComp.CurrentPickup);

		FHitResult Hit;
		FVector DownVector = -FVector::UpVector;
		FVector DeltaMovement = DownVector * CurrentSpeed;
		if(CurrentSpeed <= ShotComp.FallSpeed)
		{
			CurrentSpeed += ShotComp.AccelerationSpeed * DeltaTime;
			FMath::Clamp(CurrentSpeed, ShotComp.SlideSpeed, ShotComp.FallSpeed);
		}

		System::SphereTraceSingle(CurrentActor.ActorLocation, CurrentActor.ActorLocation + DownVector * 50.0f, 100.0f, ETraceTypeQuery::Visibility, true, ActorsToIgnore, EDrawDebugTrace::ForOneFrame, Hit, true);

		if (HasControl())
		{
			if(Hit.bBlockingHit)
			{
				if(Hit.Actor != ShotComp.IceWall.Actor)
				{
					if(Cast<AMagneticSnowProjectile>(Hit.Actor) == nullptr)
					{
						bDestroy = true;
						return;
					}
				}
			}
		}

		CurrentActor.AddActorWorldOffset(DeltaMovement * DeltaTime);
		CurrentActor.AddActorLocalRotation(ShotComp.RotationToRotate * ShotComp.RotationSpeed * DeltaTime);
		
	}
}