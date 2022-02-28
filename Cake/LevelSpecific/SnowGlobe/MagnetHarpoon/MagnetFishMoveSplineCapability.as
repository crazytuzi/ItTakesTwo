import Cake.LevelSpecific.SnowGlobe.MagnetHarpoon.MagnetFishActor;
class UMagnetFishMoveSplineCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MagnetFishMoveSplineCapability");
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
		if (MagnetFish.MagnetFishState == EMagnetFishState::OnSpline)
        	return EHazeNetworkActivation::ActivateLocal;
        
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (MagnetFish.MagnetFishState != EMagnetFishState::OnSpline)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		MagnetFish.FollowComp.ActivateSplineMovement(MagnetFish.FishSpline.Spline.GetPositionAtStart());
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (HasControl())
		{
			MagnetFish.PlayRateMultiplier = 1.f;

			MagnetFish.FollowComp.UpdateSplineMovement((MagnetFish.Speed + MagnetFish.SpeedAddition) * DeltaTime, MagnetFish.SystemPos);

			MagnetFish.TargetLoc = MagnetFish.SystemPos.WorldLocation;
			MagnetFish.TargetRot = MagnetFish.SystemPos.WorldForwardVector.Rotation();

			FHazeSplineSystemPosition FuturePosition;
			FuturePosition = MagnetFish.SystemPos;
			FuturePosition.Move(50.f);

			float CurrentDot = MagnetFish.ActorRotation.ForwardVector.DotProduct(FuturePosition.WorldForwardVector);
			MagnetFish.TargetDot = 1 - CurrentDot;
			
			MagnetFish.PlayRateMultiplier += MagnetFish.TargetDot * 20.f;

			MagnetFish.SyncFloat.SetValue(MagnetFish.PlayRateMultiplier);

			MagnetFish.SpeedAddition = MagnetFish.Speed * MagnetFish.TargetDot;
		}
		else
		{
			MagnetFish.PlayRateMultiplier = MagnetFish.SyncFloat.Value;
		}
	}
}