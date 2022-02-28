import Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingComponent;
import Vino.Movement.Components.MovementComponent;
import Vino.Camera.Actors.FollowViewFocusTrackerCamera;

class UMusicalFlyingHalfLoopExitCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"MusicalFlying");

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 11;

	AHazePlayerCharacter Player;
	UMusicalFlyingComponent FlyingComp;
	UHazeCrumbComponent CrumbComp;
	UHazeMovementComponent MoveComp;

	AFollowViewFocusTrackerCamera ExitCamera;

	UMusicalFlyingSettings Settings;

	FVector TargetMoveDirection;
	FVector PlaneOrigin;
	FVector LocationOnExit;
	FVector LastMoveDirection;
	FQuat RotationCurrent;
	FQuat RotationTowardsExit;

	// Time until we start teh half loop
	float ElapsedReturn = 0;

	// Time until we start rotating towards exit location. 
	float ElapsedApproach = 0;

	float ElapsedExit = 0;
	
	float RotatedAmount = 0;
	float CurrentMul = 1;
	float TempBoost = 0;

	bool bReturnToVolume = false;
	bool bDoHalfLoop = false;
	bool bIsInsideVolume = false;
	bool bWasInsideVolume = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
		FlyingComp = UMusicalFlyingComponent::Get(Owner);
		Settings = UMusicalFlyingSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(FlyingComp.CurrentState != EMusicalFlyingState::Flying)
			return EHazeNetworkActivation::DontActivate;

		if(FlyingComp.ExitVolumeBehavior != EMusicalFlyingExitVolumeBehavior::HalfLoop)
			return EHazeNetworkActivation::DontActivate;

		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;
/*
		if(FlyingComp.FlyingVolume == nullptr)
			return EHazeNetworkActivation::DontActivate;
*/
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		OutParams.AddVector(n"LocationOnExit", Owner.ActorCenterLocation);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Owner.BlockCapabilities(CapabilityTags::Collision, this);
		CrumbComp.IncludeCustomParamsInActorReplication(FVector::ZeroVector, FRotator::ZeroRotator, this);
		LocationOnExit = ActivationParams.GetVector(n"LocationOnExit");
		TempBoost = 3000;
		RotatedAmount = 0;
		//FlyingComp.FlyingVolume.GetClosestPlaneFromPoint(LocationOnExit, PlaneOrigin, TargetMoveDirection);
		RotationCurrent = TargetMoveDirection.ToOrientationQuat();
		Player.MeshOffsetComponent.OffsetRotationWithTime(TargetMoveDirection.Rotation(), 1.0f);
		
		if(FlyingComp.ExitVolumeCameraSettings != nullptr)
		{
			Player.ApplyCameraSettings(FlyingComp.ExitVolumeCameraSettings, FHazeCameraBlendSettings(2.5f), this, EHazeCameraPriority::Script);
		}
		
		if(ExitCamera == nullptr)
		{
			ExitCamera = AFollowViewFocusTrackerCamera::Spawn(Player.ViewLocation, Player.ViewRotation);
		}
		else
		{
			ExitCamera.SetActorLocationAndRotation(Player.ViewLocation, Player.ViewRotation);
		}

		ExitCamera.ActivateCamera(Player, CameraBlend::Normal(1.0f), this);

		bReturnToVolume = false;
		bDoHalfLoop = false;
		bIsInsideVolume = false;
		ElapsedReturn = 2;
		ElapsedExit = 0.5f;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			bIsInsideVolume = IsInsideVolume();
			
			if(bIsInsideVolume)
				ElapsedExit -= DeltaTime;

			ElapsedReturn -= DeltaTime;

			if(!bDoHalfLoop && !bReturnToVolume && ElapsedReturn < 0)
			{
				bDoHalfLoop = true;
				
			}
			else if(bDoHalfLoop && !bReturnToVolume && FMath::IsNearlyEqual(RotatedAmount, -180.0f))
			{
				bReturnToVolume = true;
				bDoHalfLoop = false;
				TargetMoveDirection = TargetMoveDirection * -1.0f;
				Owner.SetCapabilityActionState(n"ActivateBarrellRollNoBoost", EHazeActionState::ActiveForOneFrame);
				const FVector DirectionToPlaneOrigin = (LocationOnExit - Owner.ActorCenterLocation).GetSafeNormal();
				Player.MeshOffsetComponent.OffsetRotationWithTime(TargetMoveDirection.Rotation(), 0.5f);
				FRotator TargetRelativeRotation = DirectionToPlaneOrigin.Rotation();
				ElapsedApproach = 0.6f;
				MoveComp.SetTargetFacingDirection(TargetMoveDirection, 1.0f);
			}

			TempBoost *= FMath::Pow(0.25f, DeltaTime);
		}

		if(bReturnToVolume)
		{
			ElapsedApproach -= DeltaTime;
		}

		if (MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"MusicalFlyingHalfLoopExit");
			CalculateFrameMove(FrameMove, DeltaTime);
			MoveComp.Move(FrameMove);
			CrumbComp.LeaveMovementCrumb();
		}

		bWasInsideVolume = bIsInsideVolume;
	}

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{	
		if (HasControl())
		{			
			float Mul = 1.2f;
			float HeightDiff = LocationOnExit.Z - Owner.ActorCenterLocation.Z;

			if(bDoHalfLoop)
			{
				float V = FMath::Sin(FMath::DegreesToRadians(RotatedAmount)) * -1.0f;
				float RotationMul = FMath::EaseOut(1.0f, 0.4f, V, 5);
				RotatedAmount = FMath::Max(RotatedAmount - ((200 * RotationMul) * DeltaTime), -180.0f);
				FQuat RotCurr = RotationCurrent * FQuat(FVector::RightVector, FMath::DegreesToRadians(RotatedAmount));

				Player.MeshOffsetComponent.OffsetRotationWithSpeed(RotCurr.Rotator());
				Mul = FMath::EaseOut(1.1f, 0.4f, V, 2);
			}
			else if(bReturnToVolume && !bIsInsideVolume && ElapsedApproach < 0.0f)
			{
				// Let's rotate slowly against the center of our exit PlaneOrigin
				FVector DirectionToExit = (LocationOnExit - Owner.ActorCenterLocation).GetSafeNormal();
				RotationTowardsExit = FQuat::Slerp(Player.Mesh.ForwardVector.ToOrientationQuat(), DirectionToExit.ToOrientationQuat(), 6.1f * DeltaTime);
				Player.MeshOffsetComponent.OffsetRotationWithTime(RotationTowardsExit.Rotator());
			}
			
			if(!bWasInsideVolume && bIsInsideVolume)
			{
				// Check how much we are looking up/down on pitch
				const float AbsPitchDot = FMath::Abs(LastMoveDirection.DotProduct(MoveComp.WorldUp));

				// We set a startup facing direction for MusicalFLyingCapability that can re-activate if the player is still holding down the fly button
				if(AbsPitchDot < 0.65f)
				{
					// Unless we are flying downwards a lot, coming for a top plane exit location we plane the direction out so the player will not continue crashing down.
					Player.MeshOffsetComponent.OffsetRotationWithTime(LastMoveDirection.ConstrainToPlane(FVector::UpVector).Rotation(), 0.35f);
				}
			}

			const FVector MoveDirection = Player.Mesh.ForwardVector;
			CurrentMul = FMath::FInterpTo(CurrentMul, Mul, DeltaTime, 5.0f);
			
			FVector Velocity = MoveDirection * ((Settings.FlyingSpeed + TempBoost) * CurrentMul) * DeltaTime;
			CrumbComp.SetCustomCrumbRotation(Player.Mesh.WorldRotation);

			FrameMove.ApplyTargetRotationDelta();
			FrameMove.ApplyDelta(Velocity);
			
			FrameMove.OverrideStepDownHeight(0.f);
			FrameMove.OverrideGroundedState(EHazeGroundedState::Airborne);

			LastMoveDirection = MoveDirection;
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			Player.MeshOffsetComponent.OffsetRotationWithSpeed(ConsumedParams.CustomCrumbRotator);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (FlyingComp.CurrentState != EMusicalFlyingState::Flying)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(FlyingComp.ExitVolumeBehavior != EMusicalFlyingExitVolumeBehavior::HalfLoop)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(bIsInsideVolume && ElapsedExit < 0)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.UnblockCapabilities(CapabilityTags::Collision, this);
		FlyingComp.StartupFacingDirection = LastMoveDirection;
		Player.ClearCameraSettingsByInstigator(this, 2.0f);
		FlyingComp.ExitVolumeBehavior = EMusicalFlyingExitVolumeBehavior::Nothing;
		Player.MeshOffsetComponent.ResetRotationWithTime(0.5f);
		ExitCamera.DeactivateCamera(Player, 2);
		FlyingComp.NoInputDelay = 1.5f;
		CrumbComp.RemoveCustomParamsFromActorReplication(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		if(ExitCamera != nullptr)
		{
			ExitCamera.DestroyActor();
			ExitCamera = nullptr;
		}
	}

	bool IsInsideVolume() const
	{
		if(!bReturnToVolume)
			return false;

		//return FlyingComp.FlyingVolume.BrushComponent.IsOverlappingActor(Owner);
		return false;
	}
}
