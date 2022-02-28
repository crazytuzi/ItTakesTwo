import Cake.LevelSpecific.Basement.LevelActors.SeekingEye.SeekingEye;
import Cake.LevelSpecific.Basement.ParentBlob.ParentBlobPlayerComponent;

class USeekingEyeScanCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	ASeekingEye SeekingEye;

	float TimeSinceLastScan = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SeekingEye = Cast<ASeekingEye>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!SeekingEye.bAllowPushback)
			return EHazeNetworkActivation::DontActivate;

		if (SeekingEye.bFollowingPlayers)
        	return EHazeNetworkActivation::DontActivate;

		if (TimeSinceLastScan <= SeekingEye.StopTimeAtScanPoint)
			return EHazeNetworkActivation::DontActivate;

		if (!SeekingEye.bScanningAllowed)
			return EHazeNetworkActivation::DontActivate;
        
		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (SeekingEye.bFollowingPlayers)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (!SeekingEye.bScanningAllowed)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (TimeSinceLastScan <= SeekingEye.StopTimeAtScanPoint)
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

		FVector DirToScanPoint = SeekingEye.ScanPoints[SeekingEye.CurrentScanIndex].ActorLocation - SeekingEye.ScanOrigin.WorldLocation;
		DirToScanPoint.Normalize();

		FVector ConstrainedDirToScanPoint = Math::ConstrainVectorToPlane(DirToScanPoint, FVector::UpVector);
		FRotator TargetRot = ConstrainedDirToScanPoint.Rotation();
		FRotator CurRot = FMath::RInterpConstantTo(SeekingEye.ActorRotation, TargetRot, DeltaTime, SeekingEye.ScanRotationSpeed);
		CurRot.Pitch = SeekingEye.ActorRotation.Pitch;
		CurRot.Roll = SeekingEye.ActorRotation.Roll;
		SeekingEye.SetActorRotation(CurRot);

		if (SeekingEye.ScanPoints.Num() == 1)
			return;

		if (FMath::IsNearlyEqual(CurRot.Yaw, TargetRot.Yaw, 0.1f))
		{
			SeekingEye.OnScanPointReached.Broadcast(SeekingEye.ScanPoints[SeekingEye.CurrentScanIndex]);

			if (SeekingEye.CurrentScanIndex == SeekingEye.ScanPoints.Num() - 1)
			{
				SeekingEye.CurrentScanIndex--;
				SeekingEye.bIncrementing = false;
			}
			else if (SeekingEye.CurrentScanIndex == 0)
			{
				SeekingEye.CurrentScanIndex++;
				SeekingEye.bIncrementing = true;
			}
			else if (SeekingEye.bIncrementing)
			{
				SeekingEye.CurrentScanIndex++;
			}
			else
			{
				SeekingEye.CurrentScanIndex--;
			}

			TimeSinceLastScan = 0.f;
		}
	}
}