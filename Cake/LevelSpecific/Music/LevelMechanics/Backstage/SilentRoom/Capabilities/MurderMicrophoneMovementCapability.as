import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.Capabilities.MurderMicrophone;

class UMurderMicrophoneMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	
	default CapabilityDebugCategory = n"LevelSpecific";

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 3;

	AMurderMicrophone Snake;
	UMurderMicrophoneTargetingComponent TargetingComp;
	UMurderMicrophoneMovementComponent MoveComp;
	UMurderMicrophoneSettings Settings;

	FHazeAcceleratedVector AcceleratedTargetLocation;

	bool bLastHasControl = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Snake = Cast<AMurderMicrophone>(Owner);
		TargetingComp = UMurderMicrophoneTargetingComponent::Get(Owner);
		MoveComp = UMurderMicrophoneMovementComponent::Get(Owner);
		Settings = UMurderMicrophoneSettings::GetSettings(Owner);
		AcceleratedTargetLocation.SnapTo(Snake.SnakeHeadLocation);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		// movement is instead performed inside the eating player capability
		if(Snake.CurrentState == EMurderMicrophoneHeadState::EatingPlayer)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AcceleratedTargetLocation.SnapTo(MoveComp.UpdatedComponent.WorldLocation);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Snake.HasTarget())
			MoveComp.SetTargetFacingDirection(Snake.DirectionToTarget);

		if(HasControl())
		{
			if(!bLastHasControl)
				AcceleratedTargetLocation.SnapTo(MoveComp.UpdatedComponent.WorldLocation);

			FMurderMicrophoneMovementInfo MovementInfo;
			MoveComp.Move(DeltaTime, MovementInfo);

			if(ShouldConstrainMovement())
				MoveComp.ConstrainMovement(MovementInfo);

			AcceleratedTargetLocation.AccelerateTo(MovementInfo.FinalLocation, 0.15f, DeltaTime);
			Snake.HeadOffset.SetWorldLocation(AcceleratedTargetLocation.Value);
			Snake.ReplicatedLocation.SetValue(MovementInfo.FinalLocation);
		}
		else
		{
			Snake.HeadOffset.SetWorldLocation(FMath::VInterpTo(Snake.HeadOffset.WorldLocation, Snake.ReplicatedLocation.Value, DeltaTime, 10.0f));
		}

		MoveComp.UpdateFacingRotation(DeltaTime);
		Snake.HeadOffset.SetWorldRotation(MoveComp.FacingRotationCurrent);

		//const FQuat FacingRotation = FQuat::Slerp(Snake.HeadOffset.WorldRotation.Quaternion(), TargetFacingRotation, Settings.RotationSpeed * DeltaTime);

		//Snake.HeadOffset.SetWorldRotation(FacingRotation);

		Snake.UpdateSpline(DeltaTime);
		const float TargetTile = Snake.GetTargetTileMaterial();
		Snake.CurrentTileMaterial = FMath::FInterpTo(Snake.CurrentTileMaterial, TargetTile, DeltaTime, 1.1f);
		Snake.BodyComponent.SetScalarParameterValueOnMaterialIndex(0, n"Tiling X", Snake.CurrentTileMaterial);

		//Snake.BodyComponent.TileMaterial = Snake.CurrentTileMaterial;
		//System::DrawDebugSphere(Snake._TargetLocation, 200.0f, 12, FLinearColor::Blue);

		bLastHasControl = HasControl();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Snake.CurrentState == EMurderMicrophoneHeadState::EatingPlayer)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	bool ShouldConstrainMovement() const
	{
		if(Snake.CurrentState == EMurderMicrophoneHeadState::EatingPlayer)
			return false;
		if(Snake.CurrentState == EMurderMicrophoneHeadState::Killed)
			return false;
		if(Snake.CurrentState == EMurderMicrophoneHeadState::Retreat)
			return false;
		return true;
	}
}
