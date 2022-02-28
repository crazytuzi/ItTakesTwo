import Cake.LevelSpecific.Basement.ParentBlob.ParentBlobPlayerComponent;
import Cake.LevelSpecific.Basement.SeekerSection.FearSeeker;

class UFearSeekerScanCapability : UHazeCapability
{
	/*default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	AFearSeeker FearSeeker;

	float TimeSinceLastScan = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		FearSeeker = Cast<AFearSeeker>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (FearSeeker.bPlayerSpotted)
        	return EHazeNetworkActivation::DontActivate;

		if (TimeSinceLastScan <= FearSeeker.StopTimeAtScanPoint)
			return EHazeNetworkActivation::DontActivate;

		if (!FearSeeker.bScanning)
			return EHazeNetworkActivation::DontActivate;
        
		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (FearSeeker.bPlayerSpotted)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (!FearSeeker.bScanning)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (TimeSinceLastScan <= FearSeeker.StopTimeAtScanPoint)
			return EHazeNetworkDeactivation::DeactivateFromControl;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		TimeSinceLastScan += DeltaTime;
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (GetActiveParentBlobActor() == nullptr)
			return;

		FVector DirToScanPoint = FearSeeker.ScanPoints[FearSeeker.CurrentScanIndex].ActorLocation - FearSeeker.ActorLocation;
		DirToScanPoint.Normalize();

		FVector ConstrainedDirToScanPoint = Math::ConstrainVectorToPlane(DirToScanPoint, FVector::UpVector);
		FRotator TargetRot = ConstrainedDirToScanPoint.Rotation();
		FRotator CurRot = FMath::RInterpConstantTo(FearSeeker.ActorRotation, TargetRot, DeltaTime, FearSeeker.ScanRotationSpeed);
		CurRot.Pitch = FearSeeker.ActorRotation.Pitch;
		CurRot.Roll = FearSeeker.ActorRotation.Roll;
		FearSeeker.SetActorRotation(CurRot);

		if (FearSeeker.ScanPoints.Num() == 1)
			return;

		if (FMath::IsNearlyEqual(CurRot.Yaw, TargetRot.Yaw, 0.1f))
		{
			FearSeeker.OnScanPointReached.Broadcast(FearSeeker.ScanPoints[FearSeeker.CurrentScanIndex]);

			if (FearSeeker.CurrentScanIndex == FearSeeker.ScanPoints.Num() - 1)
			{
				FearSeeker.CurrentScanIndex--;
				FearSeeker.bIncrementingScan = false;
			}
			else if (FearSeeker.CurrentScanIndex == 0)
			{
				FearSeeker.CurrentScanIndex++;
				FearSeeker.bIncrementingScan = true;
			}
			else if (FearSeeker.bIncrementingScan)
			{
				FearSeeker.CurrentScanIndex++;
			}
			else
			{
				FearSeeker.CurrentScanIndex--;
			}

			TimeSinceLastScan = 0.f;
		}
	}*/
}