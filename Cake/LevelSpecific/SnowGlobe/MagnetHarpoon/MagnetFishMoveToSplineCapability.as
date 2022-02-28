import Cake.LevelSpecific.SnowGlobe.MagnetHarpoon.MagnetFishActor;

class UMagnetFishMoveToSplineCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MagnetFishSplineMoveCapability");
	default CapabilityTags.Add(n"MagnetFish");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AMagnetFishActor MagnetFish;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		MagnetFish = Cast<AMagnetFishActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!HasControl())
			return EHazeNetworkActivation::DontActivate;
		
		if (MagnetFish.MagnetFishState == EMagnetFishState::GoingToSpline)
        	return EHazeNetworkActivation::ActivateLocal;
        
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (MagnetFish.MagnetFishState != EMagnetFishState::GoingToSpline)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (MagnetFish.Velocity.Size() > 10.f)
		{
			MagnetFish.Gravity -= (MagnetFish.Gravity * 5.75f) * DeltaTime;
			FVector GravityVelocity(0.f, 0.f, MagnetFish.Gravity);
			MagnetFish.Velocity -= GravityVelocity * DeltaTime;
			MagnetFish.Velocity -= (MagnetFish.Velocity * 15.5f) * DeltaTime;
			FVector NextLoc = MagnetFish.ActorLocation + MagnetFish.Velocity * DeltaTime;
			MagnetFish.ActorLocation = NextLoc;	

			MagnetFish.AccelLocMove.SnapTo(0.f);	
			MagnetFish.AccelRotMove.SnapTo(MagnetFish.ActorRotation);	
			MagnetFish.TargetLoc = MagnetFish.ActorLocation;
			MagnetFish.TargetRot = MagnetFish.ActorRotation;
		}
		else
		{
			FVector Direction = MagnetFish.StartPos - MagnetFish.ActorLocation;
			Direction.Normalize();
			MagnetFish.TargetRot = FRotator::MakeFromX(Direction);

			MagnetFish.TargetLoc = MagnetFish.StartPos;

			float Distance = (MagnetFish.ActorLocation - MagnetFish.StartPos).Size();

			if (Distance <= 5.f)
				MagnetFish.NetFishOnSpline();
		}
	}
}