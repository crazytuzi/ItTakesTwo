import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingComponent;
import Vino.Camera.Actors.FollowViewFocusTrackerCamera;

class UMusicalFlyingLoopCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"MusicalFlying");
	default CapabilityTags.Add(n"MusicalAirborne");

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 1;

	AHazePlayerCharacter Player;
	UHazeCrumbComponent CrumbComp;
	UHazeMovementComponent MoveComp;
	UMusicalFlyingComponent FlyingComp;
	UMusicalFlyingSettings Settings;

	AFollowViewFocusTrackerCamera LoopCamera;

	// Save the rotation on activate for use in tick.
	FQuat MeshRotationOnActivate;

	float Elapsed = 0;
	float ElapsedTarget = 0.3f;	// Valid time for attempting to fly uppwards which is the interval we are looking for in order to activate loop.
	float LastX = 0;
	float LastSize = 0;
	float PitchTarget = 0;
	float PitchCurrent = 0;

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

		if(FlyingComp.ExitVolumeBehavior != EMusicalFlyingExitVolumeBehavior::Nothing)
			return EHazeNetworkActivation::DontActivate;

		if(!IsActioning(n"ActivateBarrellRollNoBoost"))
			return EHazeNetworkActivation::DontActivate;

		if(!HasValidStickInput())
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CrumbComp.IncludeCustomParamsInActorReplication(FVector::ZeroVector, FRotator::ZeroRotator, this);
		ConsumeAction(n"ActivateBarrellRollNoBoost");
		FlyingComp.bDoLoop = true;
		PrintToScreen("Player.Mesh.WorldRotation.Pitch " + Player.Mesh.WorldRotation.Pitch, 5);
		PitchTarget = 360.0f - Player.Mesh.WorldRotation.Pitch;
		PitchCurrent = 0;
		PrintToScreen("PitchTarget " + PitchTarget, 5);
		MeshRotationOnActivate = Player.Mesh.WorldRotation.Quaternion();

		if(LoopCamera == nullptr)
		{
			LoopCamera = AFollowViewFocusTrackerCamera::Spawn(Player.ViewLocation, Player.ViewRotation);
		}
		else
		{
			LoopCamera.SetActorLocationAndRotation(Player.ViewLocation, Player.ViewRotation);
		}

		LoopCamera.ActivateCamera(Player, CameraBlend::Normal(0.5f), this);

		if(FlyingComp.LoopCameraSettings != nullptr)
		{
			Player.ApplyCameraSettings(FlyingComp.LoopCameraSettings, FHazeCameraBlendSettings(1.5f), this, EHazeCameraPriority::Script);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		PitchCurrent = FMath::Min(PitchCurrent + (100 * DeltaTime), PitchTarget);
		PrintToScreen("PitchCurrent " + PitchCurrent);

		if (MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"MusicalFlyingLoop");
			CalculateFrameMove(FrameMove, DeltaTime);
			MoveComp.Move(FrameMove);
			CrumbComp.LeaveMovementCrumb();
		}
	}

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{
		if(HasControl())
		{
			FQuat LoopRotation = MeshRotationOnActivate * FQuat(FVector::RightVector, FMath::DegreesToRadians(-PitchCurrent));
			Player.MeshOffsetComponent.OffsetRotationWithTime(LoopRotation.Rotator());
			const FVector MoveDirection = Player.Mesh.ForwardVector;

			FVector Velocity = MoveDirection * Settings.FlyingSpeed * DeltaTime;
			CrumbComp.SetCustomCrumbRotation(Player.Mesh.WorldRotation);

			FrameMove.ApplyTargetRotationDelta();
			FrameMove.ApplyDelta(Velocity);
			
			FrameMove.OverrideStepDownHeight(0.f);
			FrameMove.OverrideGroundedState(EHazeGroundedState::Airborne);
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
		if(FMath::IsNearlyEqual(PitchTarget, PitchCurrent))
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(FlyingComp.CurrentState != EMusicalFlyingState::Flying)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(FlyingComp.ExitVolumeBehavior != EMusicalFlyingExitVolumeBehavior::Nothing)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		LoopCamera.DeactivateCamera(Player, 2);
		Player.ClearCameraSettingsByInstigator(this, 1.0f);
		FlyingComp.bDoLoop = false;
		CrumbComp.RemoveCustomParamsFromActorReplication(this);
		FlyingComp.StartupFacingDirection = Player.Mesh.ForwardVector;
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		if(LoopCamera != nullptr)
		{
			LoopCamera.DestroyActor();
			LoopCamera = nullptr;
		}
	}

	bool HasValidStickInput() const
	{
		return Elapsed > 0.f && LastX < 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		FVector2D Input = FlyingComp.FlyingInput;

		if(FMath::IsNearlyZero(LastSize) && Input.X < 0.f)
		{
			Elapsed = ElapsedTarget;
		}

		PrintToScreen("HasValidStickInput() " + HasValidStickInput());
		Elapsed -= DeltaTime;
		LastX = Input.X;
		LastSize = Input.SizeSquared();
	}
}
